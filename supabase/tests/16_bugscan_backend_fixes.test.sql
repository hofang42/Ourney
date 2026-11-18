-- 0016_bugscan_backend_fixes: server fixes of the 2026-11-18 bug scan (docs/bug.md).
-- Users: 1 O owner, 2 M member, 3 S stranger, 4 X invitee, 5 F friend of O, 6 Y invitee,
--        7 Z invitee, 8 P consent group owner, 9 R consent requester (deleted), 10 T blocks R.
begin;
create extension if not exists pgtap with schema extensions;
select plan(41);

create schema tests;
grant usage on schema tests to authenticated;
create function tests.as_user(u uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', u, 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);
end $$;
create function tests.as_postgres() returns void language plpgsql as $$
begin
  perform set_config('role', 'postgres', true);
  perform set_config('request.jwt.claims', '', true);
end $$;
create function tests.u(n int) returns uuid language sql immutable as $$
  select format('16000000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function tests.j(n int) returns uuid language sql immutable as $$
  select format('b1600000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function tests.c(n int) returns uuid language sql immutable as $$
  select format('c1600000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function tests.m(n int) returns uuid language sql immutable as $$
  select format('d1600000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function tests.checkin(cid uuid, j uuid, at timestamptz default now()) returns void language sql as $$
  insert into public.check_ins (id, journey_id, user_id, local_date, captured_at, photo_path, thumb_path)
  values (cid, j, auth.uid(), current_date, at, format('checkins/%s/%s/%s.jpg', j, auth.uid(), cid),
          format('checkins/%s/%s/%s_t.jpg', j, auth.uid(), cid)) $$;
create function tests.react(cid uuid) returns void language sql as $$
  insert into public.reactions (checkin_id, user_id, emoji) values (cid, auth.uid(), '❤️')
  on conflict (checkin_id, user_id) do update set deleted_at = null $$;
create function tests.journey(n int) returns public.journeys language sql security definer as $$
  select * from public.journeys where id = tests.j(n) $$;
create function tests.invitation(j uuid, invitee uuid) returns public.group_invitations
language sql security definer as $$
  select * from public.group_invitations where journey_id = j and invitee_id = invitee
   order by created_at desc limit 1 $$;
create function tests.conv(j uuid, member uuid, viewer uuid) returns uuid language sql security definer as $$
  select id from public.conversations where journey_id = j and member_id = member and viewer_id = viewer $$;
create function tests.befriend(a uuid, b uuid) returns void language plpgsql as $$
begin
  perform tests.as_user(a); perform public.send_friend_request(b);
  perform tests.as_user(b); perform public.respond_friend_request(a, true);
end $$;
grant execute on all functions in schema tests to authenticated;

insert into auth.users (id, email) select tests.u(n), format('bs%s@example.test', n) from generate_series(1, 10) n;
insert into public.profiles (id, username, display_name) select tests.u(n), 'bsuser' || n, 'BS' || n from generate_series(1, 10) n;

-- ===== A-B6: couple journeys have two seats =====================================
do $$ begin perform tests.as_user(tests.u(1)); end $$;
select is((public.create_journey(tests.j(3), 'group', 'custom', 'Us', '💞', null, null, false, current_date, 30, 'UTC',
                                 10, 'private', 'An', 'Binh')).max_members, 2,
  'A-B6: create_journey forces max_members = 2 for a couple journey');
select is((public.create_journey(tests.j(8), 'group', 'custom', 'Team', '🔥', null, null, false, current_date, 30, 'UTC')).max_members,
  10, 'A-B6: a plain group keeps max_members');
select lives_ok($q$select public.create_journey(tests.j(9), 'group', 'custom', 'Later', null, null, null, false, current_date, 30, 'UTC')$q$,
  'A-B6: setup plain group for later couple names');
update public.journeys set couple_self_name = 'An', couple_partner_name = 'Binh' where id = tests.j(9);
select is((select max_members from public.journeys where id = tests.j(9)), 2,
  'A-B6: adding couple names later also keeps two seats');

-- ===== J1: ended group with a public link; owner did not consent ================
-- O hides the metric (hide_metric_default), M consents and blurs media.
do $$ begin perform tests.as_user(tests.u(1));
  perform public.create_journey(tests.j(1), 'group', 'custom', 'Squad', '🔥', 'Weight', 'kg', true, current_date - 5, 30, 'UTC'); end $$;
do $$ begin perform tests.as_user(tests.u(2));
  perform public.join_by_code((tests.journey(1)).invite_code);
  perform tests.checkin(tests.c(1), tests.j(1));
  perform public.request_share_consent(tests.j(1)); end $$;
do $$ begin perform tests.as_postgres();
  update public.memberships set blur_media = true where journey_id = tests.j(1) and user_id = tests.u(2); end $$;
do $$ begin perform tests.as_user(tests.u(1));
  perform public.end_journey(tests.j(1)); end $$;
do $$ begin perform tests.as_user(tests.u(1)); end $$;
select public.set_public_link(tests.j(1), true) as tok \gset

do $$ begin perform tests.as_user(tests.u(3)); end $$;
select ok((public.public_journey_by_token(:'tok'))->>'metric_name' is null
          and (public.public_journey_by_token(:'tok'))->>'metric_unit' is null,
  'A-B8: journey_view hides metric_name/unit from strangers when the owner hides the metric');
select ok((public.follow_frame(tests.j(1)))->>'metric_name' is null
          and (public.follow_frame(tests.j(1)))->>'metric_unit' is null,
  'A-B8: follow_frame hides metric_name/unit from non-members too');
select lives_ok($$ select tests.react(tests.c(1)) $$, 'stranger likes a consenting member''s photo (saves the journey)');
select results_eq($$ select (s->>'saved')::boolean, s->'shared_by'->>'user_id', s->'shared_by'->>'display_name'
                       from public.shared_with_me() s $$,
  $$ values (true, '00000000-0000-0000-0000-000000000000', '') $$,
  'A-B3: shared_by of a saved group journey keeps a non-consenting owner anonymous');
select results_eq($$ select s->>'cover_thumb_path', (s->>'cover_blurred')::boolean, (s->>'photo_count')::int
                       from public.shared_with_me() s $$,
  $$ values (null::text, true, 1) $$,
  'C1: shared_with_me never returns the cover thumb of an author who blurs media');
select throws_ok(format('select public.send_friend_request(%L, %L)', tests.u(1), tests.j(1)), '42501', 'forbidden',
  'A-B3: no friend request from a public page to a group owner who has not consented');
select is((select count(*)::int from public.friendships
            where tests.u(1) in (user_low, user_high) and tests.u(3) in (user_low, user_high)), 0,
  'A-B3: and no friendship row was created');

do $$ begin perform tests.as_user(tests.u(2)); end $$;
select is((public.follow_frame(tests.j(1)))->>'metric_name', 'Weight', 'A-B8: members still see the metric name');
select is((public.shared_journey(tests.j(1)))->>'metric_unit', 'kg', 'A-B8: and the unit in the member view');

-- owner consents: everything named again, cover still hidden while M blurs, then shown
do $$ begin perform tests.as_user(tests.u(1)); perform public.respond_share_consent(tests.j(1), true); end $$;
do $$ begin perform tests.as_user(tests.u(3)); end $$;
select is((select s->'shared_by'->>'username' from public.shared_with_me() s), 'bsuser1',
  'A-B3: a consenting owner is named as shared_by');
do $$ begin perform tests.as_postgres();
  update public.memberships set blur_media = false where journey_id = tests.j(1) and user_id = tests.u(2);
  perform tests.as_user(tests.u(3)); end $$;
select results_eq($$ select s->>'cover_thumb_path', (s->>'cover_blurred')::boolean from public.shared_with_me() s $$,
  format($f$ values (%L::text, false) $f$, format('checkins/%s/%s/%s_t.jpg', tests.j(1), tests.u(2), tests.c(1))),
  'C1: an unblurred author''s cover thumb is returned');

-- ===== A-B9 + A-B10: consents =====================================================
do $$ begin perform tests.as_user(tests.u(8));
  perform public.create_journey(tests.j(2), 'group', 'custom', 'Book club', '📚', null, null, false, current_date, 30, 'UTC'); end $$;
do $$ begin perform tests.as_user(tests.u(9)); perform public.join_by_code((tests.journey(2)).invite_code); end $$;
do $$ begin perform tests.as_user(tests.u(10)); perform public.join_by_code((tests.journey(2)).invite_code); end $$;
do $$ begin perform tests.as_user(tests.u(9)); perform public.request_share_consent(tests.j(2)); end $$;
do $$ begin perform tests.as_user(tests.u(10)); perform public.block_user(tests.u(9)); end $$;

do $$ begin perform tests.as_user(tests.u(9)); end $$;
select results_eq($$ select c->'member'->>'username' from public.share_consents(tests.j(2)) c $$,
  $$ values ('bsuser8'), ('bsuser9') $$, 'A-B9: share_consents hides a member blocked with the caller');
do $$ begin perform tests.as_user(tests.u(10)); end $$;
select results_eq($$ select c->'member'->>'username' from public.share_consents(tests.j(2)) c $$,
  $$ values ('bsuser8'), ('bsuser10') $$, 'A-B9: in both directions');
select is((select c->'requested_by'->>'user_id' from public.my_pending_consents() c),
  '00000000-0000-0000-0000-000000000000', 'A-B9: a blocked requester is anonymous in consent_json');
do $$ begin perform tests.as_user(tests.u(8)); end $$;
select is((select count(*)::int from public.share_consents(tests.j(2)) c
            where c->'requested_by'->>'username' = 'bsuser9'), 3,
  'consent_json names the requester otherwise');

-- ===== A-B4: account purge + chat images ==========================================
do $$ begin perform tests.as_postgres();
  insert into public.conversations (id, journey_id, member_id, viewer_id)
  values ('e1600000-0000-4000-8000-000000000001', tests.j(1), tests.u(2), tests.u(9));
  insert into storage.objects (bucket_id, name) values
    ('messages', format('messages/e1600000-0000-4000-8000-000000000001/%s/%s.jpg', tests.u(9), tests.m(1))),
    ('messages', format('messages/e1600000-0000-4000-8000-000000000001/%s/%s.jpg', tests.u(2), tests.m(2))),
    ('messages', format('messages/e1600000-0000-4000-8000-000000000099/%s/%s.jpg', tests.u(2), tests.m(3)));
  insert into private.join_attempts (user_id, success) values (tests.u(9), false);
  insert into private.rate_events (user_id, kind) values (tests.u(9), 'public_friend_request');
  insert into public.journey_views (journey_id, viewer_key, day) values (tests.j(1), tests.u(9)::text, current_date);
end $$;
select results_eq(format('select * from public.account_message_paths(%L)', tests.u(9)),
  format($f$ values (%L::text), (%L::text) $f$,
         format('messages/e1600000-0000-4000-8000-000000000001/%s/%s.jpg', tests.u(2), tests.m(2)),
         format('messages/e1600000-0000-4000-8000-000000000001/%s/%s.jpg', tests.u(9), tests.m(1))),
  'A-B4: account_message_paths lists the user''s sent images and every image of their conversations');
select results_eq(format('select * from public.account_message_paths(%L)', tests.u(5)), 'select null::text where false',
  'A-B4: and nothing of conversations the user is not part of');

delete from auth.users where id = tests.u(9);
select is((select count(*)::int from private.join_attempts where user_id = tests.u(9))
        + (select count(*)::int from private.rate_events where user_id = tests.u(9))
        + (select count(*)::int from public.journey_views where viewer_key = tests.u(9)::text), 0,
  'A-B4: purge_account_data clears join_attempts, rate_events and journey_views');

do $$ begin perform tests.as_user(tests.u(8)); end $$;
select is((select count(*)::int from public.share_consents(tests.j(2)) c
            where c->'requested_by'->>'user_id' = '00000000-0000-0000-0000-000000000000'), 2,
  'A-B10: a deleted requester reads as the anonymous person, never null');
do $$ begin perform tests.as_user(tests.u(10)); end $$;
select ok((select json_typeof(c->'requested_by') = 'object' from public.my_pending_consents() c),
  'A-B10: my_pending_consents keeps requested_by an object');

-- ===== A-B7 + A-B16 + C3: group invitations ======================================
do $$ begin perform tests.as_user(tests.u(2)); perform public.join_by_code((tests.journey(8)).invite_code);
  perform public.send_group_invitation(tests.j(8), tests.u(4)); end $$;
do $$ begin perform tests.as_user(tests.u(1)); perform public.remove_member(tests.j(8), tests.u(2)); end $$;
select is((tests.invitation(tests.j(8), tests.u(4))).status, 'revoked',
  'A-B7: removing a member revokes their pending invitations');
do $$ begin perform tests.as_user(tests.u(4)); end $$;
select throws_ok(format('select public.accept_group_invitation(%L)', (tests.invitation(tests.j(8), tests.u(4))).id),
  'P0001', 'not_found', 'A-B7: the invitee cannot join through it');

do $$ begin perform tests.as_user(tests.u(3)); perform public.join_by_code((tests.journey(8)).invite_code);
  perform public.send_group_invitation(tests.j(8), tests.u(6)); end $$;
do $$ begin perform tests.as_user(tests.u(1)); end $$;
select is(json_array_length(public.journey_pending_invitations(tests.j(8))), 1, 'owner lists the pending invitation');
do $$ begin perform tests.as_user(tests.u(1)); perform public.block_user(tests.u(3)); end $$;
select is(json_array_length(public.journey_pending_invitations(tests.j(8))), 0,
  'C3: invitations sent by a user blocked with the caller are hidden');

-- an inviter who is gone without the revoke (legacy row): accept refuses
do $$ begin perform tests.as_postgres();
  update public.memberships set status = 'left' where journey_id = tests.j(8) and user_id = tests.u(3); end $$;
do $$ begin perform tests.as_user(tests.u(6)); end $$;
select throws_ok(format('select public.accept_group_invitation(%L)', (tests.invitation(tests.j(8), tests.u(6))).id),
  'P0001', 'not_found', 'A-B7: accept needs the inviter to still be an active member');
select is((select count(*)::int from public.memberships where journey_id = tests.j(8) and user_id = tests.u(6)), 0,
  'A-B7: and nobody joined');

do $$ begin perform tests.as_user(tests.u(1)); perform public.send_group_invitation(tests.j(8), tests.u(7)); end $$;
do $$ begin perform tests.as_user(tests.u(7)); end $$;
select is(json_array_length(public.my_group_invitations()), 1, 'Z has a pending invitation');
select lives_ok(format('select public.join_by_code(%L)', (tests.journey(8)).invite_code), 'Z joins by code instead');
select is((tests.invitation(tests.j(8), tests.u(7))).status, 'accepted',
  'A-B16: join_by_code closes the pending invitation');
select ok(json_array_length(public.my_group_invitations()) = 0
          and (public.inbox_counts()->>'group_invitations')::int = 0,
  'A-B16: feed and inbox badge no longer show it');

-- ===== A-B15: group_today with several photos, the latest reported ===============
do $$ begin perform tests.as_user(tests.u(7));
  perform tests.checkin(tests.c(81), tests.j(8), now() - interval '2 minutes');
  perform tests.checkin(tests.c(82), tests.j(8), now() - interval '1 minute'); end $$;
do $$ begin perform tests.as_user(tests.u(1)); perform public.report_content(tests.c(82), null, 'spam'); end $$;
select results_eq(format('select checked_in, checkin_id from public.group_today(%L) where user_id = %L', tests.j(8), tests.u(7)),
  format('values (true, %L::uuid)', tests.c(81)),
  'A-B15: group_today falls back to the latest photo the caller has not reported');
do $$ begin perform tests.as_user(tests.u(1)); perform public.report_content(tests.c(81), null, 'spam'); end $$;
select results_eq(format('select checked_in, checkin_id from public.group_today(%L) where user_id = %L', tests.j(8), tests.u(7)),
  $$ values (true, null::uuid) $$, 'A-B15: all of today reported -> checked_in stays true, no photo (L7)');
do $$ begin perform tests.as_user(tests.u(7)); end $$;
select is((select checkin_id from public.group_today(tests.j(8)) where user_id = tests.u(7)), tests.c(82),
  'A-B15: the author still sees their own latest photo');

-- ===== C2: reply thumbnails in chat ===============================================
do $$ begin
  perform tests.befriend(tests.u(1), tests.u(5));
  perform tests.as_user(tests.u(1));
  perform public.create_journey(tests.j(7), 'solo', 'custom', 'Run', '🏃', null, null, false, current_date - 3, 30, 'UTC');
  perform tests.checkin(tests.c(71), tests.j(7), now() - interval '2 minutes');
  perform tests.checkin(tests.c(72), tests.j(7), now() - interval '1 minute');
  perform public.set_hidden_in_share(tests.c(72), true);
  perform public.end_journey(tests.j(7));
  perform public.share_journey(tests.j(7), array[tests.u(5)]);
  perform tests.as_user(tests.u(5));
  perform public.open_conversation(tests.j(7), tests.c(71));
end $$;
do $$ begin perform tests.as_user(tests.u(5)); end $$;
select isnt(public.send_message(tests.m(71), tests.conv(tests.j(7), tests.u(1), tests.u(5)), 'text', 'nice', null, tests.c(71))
              ->>'reply_to_thumb_path', null, 'C2: a viewer gets the thumb of a photo they can see');
select is(public.send_message(tests.m(72), tests.conv(tests.j(7), tests.u(1), tests.u(5)), 'text', 'and this?', null, tests.c(72))
            ->>'reply_to_thumb_path', null, 'C2: but not of a photo hidden from shares');
do $$ begin perform tests.as_postgres();
  update public.memberships set blur_media = true where journey_id = tests.j(7) and user_id = tests.u(1);
  perform tests.as_user(tests.u(5)); end $$;
select is((select count(*)::int from public.conversation_messages(tests.conv(tests.j(7), tests.u(1), tests.u(5))) x
            where x->>'reply_to_thumb_path' is not null), 0,
  'C2: nor of a blurred author''s photo');
do $$ begin perform tests.as_user(tests.u(1)); end $$;
select is((select count(*)::int from public.conversation_messages(tests.conv(tests.j(7), tests.u(1), tests.u(5))) x
            where x->>'reply_to_thumb_path' is not null), 2,
  'C2: the member side still sees both thumbs');

select * from finish();
rollback;
