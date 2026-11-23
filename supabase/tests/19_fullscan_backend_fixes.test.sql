-- 0019_fullscan_backend_fixes: pgTAP verification of Batch A findings
-- (FS-01, FS-07, FS-08, FS-09, FS-20, FS-21, FS-22, FS-23, FS-24, FS-25, FS-38).
begin;
create extension if not exists pgtap with schema extensions;
select plan(40);

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
  select format('19000000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function tests.j(n int) returns uuid language sql immutable as $$
  select format('b1900000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function tests.c(n int) returns uuid language sql immutable as $$
  select format('c1900000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function tests.m(n int) returns uuid language sql immutable as $$
  select format('d1900000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function tests.checkin(cid uuid, j uuid, at timestamptz default now(), lib boolean default false)
returns void language sql as $$
  insert into public.check_ins (id, journey_id, user_id, local_date, captured_at, photo_path, thumb_path, from_library)
  values (cid, j, auth.uid(), current_date, at,
          format('checkins/%s/%s/%s.jpg', j, auth.uid(), cid),
          format('checkins/%s/%s/%s_t.jpg', j, auth.uid(), cid), lib) $$;
create function tests.code(n int) returns text language sql security definer as $$
  select invite_code from public.journeys where id = tests.j(n) $$;
create function tests.conv(j uuid, member uuid, viewer uuid) returns uuid language sql security definer as $$
  select id from public.conversations where journey_id = j and member_id = member and viewer_id = viewer $$;
create function tests.befriend(a uuid, b uuid) returns void language plpgsql as $$
begin
  perform tests.as_user(a); perform public.send_friend_request(b);
  perform tests.as_user(b); perform public.respond_friend_request(a, true);
end $$;
grant execute on all functions in schema tests to authenticated;

insert into auth.users (id, email)
select tests.u(n), format('fs19_%s@example.test', n) from generate_series(1, 10) n;
insert into public.profiles (id, username, display_name)
select tests.u(n), 'fs19user' || n, 'FS19_' || n from generate_series(1, 10) n;

-- ============================================================================
-- 1. FS-01 & FS-07: messages bucket x-upsert, messages_select privacy, clear purge
-- ============================================================================
do $$ begin
  perform tests.befriend(tests.u(1), tests.u(2));
  perform tests.as_user(tests.u(1));
  perform public.create_journey(tests.j(1), 'solo', 'custom', 'Solo 1', '🏃', null, null, false, current_date - 5, 30, 'UTC');
  perform tests.checkin(tests.c(1), tests.j(1), now());
  perform public.end_journey(tests.j(1));
  perform public.share_journey(tests.j(1), array[tests.u(2)]);
  perform tests.as_user(tests.u(2));
  perform public.open_conversation(tests.j(1), tests.c(1));
end $$;

-- Pre-send_message upload with ON CONFLICT DO UPDATE (x-upsert) as sender u(2)
do $$ begin perform tests.as_user(tests.u(2)); end $$;
select lives_ok(
  format($f$
    insert into storage.objects (bucket_id, name)
    values ('messages', %L), ('messages', %L)
    on conflict (bucket_id, name) do update set updated_at = now()
  $f$,
  format('messages/%s/%s/%s.jpg', tests.conv(tests.j(1), tests.u(1), tests.u(2)), tests.u(2), tests.m(1)),
  format('messages/%s/%s/%s.jpg', tests.conv(tests.j(1), tests.u(1), tests.u(2)), tests.u(2), tests.m(2))),
  'FS-01: sender pre-uploads chat photos with ON CONFLICT DO UPDATE before send_message'
);

do $$ begin perform tests.as_user(tests.u(1)); end $$;
select is(
  (select count(*)::int from storage.objects where bucket_id = 'messages'),
  0,
  'FS-07: recipient cannot read sender pre-uploaded storage objects before send_message creates the row'
);

do $$ begin perform tests.as_user(tests.u(2)); end $$;
select lives_ok(
  format($f$
    select public.send_message(%L, %L, 'photo', 'pic 1', %L),
           public.send_message(%L, %L, 'photo', 'pic 2', %L)
  $f$,
  tests.m(1), tests.conv(tests.j(1), tests.u(1), tests.u(2)),
  format('messages/%s/%s/%s.jpg', tests.conv(tests.j(1), tests.u(1), tests.u(2)), tests.u(2), tests.m(1)),
  tests.m(2), tests.conv(tests.j(1), tests.u(1), tests.u(2)),
  format('messages/%s/%s/%s.jpg', tests.conv(tests.j(1), tests.u(1), tests.u(2)), tests.u(2), tests.m(2))),
  'FS-01: sender commits both photo messages'
);

do $$ begin perform tests.as_user(tests.u(1)); end $$;
select is(
  (select count(*)::int from storage.objects where bucket_id = 'messages'),
  2,
  'FS-07: recipient reads both live chat photo objects'
);

do $$ begin perform tests.as_user(tests.u(1)); perform public.hide_message(tests.m(1)); end $$;
select is(
  (select count(*)::int from storage.objects where bucket_id = 'messages'),
  1,
  'FS-07: hiding a message blocks reading its storage object'
);

do $$ begin perform tests.as_user(tests.u(1));
  perform public.report_content(null, null, 'spam', 'bad photo', tests.m(2)); end $$;
select is(
  (select count(*)::int from storage.objects where bucket_id = 'messages')
  + (select count(*)::int from public.conversation_messages(tests.conv(tests.j(1), tests.u(1), tests.u(2))))
  + (select coalesce(sum((c->>'unread_count')::int), 0)::int from public.my_conversations() c)
  + (public.inbox_counts()->>'unread_messages')::int,
  0,
  'FS-07: reporting a chat photo hides it from messages, storage.objects, my_conversations, and inbox_counts'
);

do $$ begin
  perform tests.as_postgres();
  update public.messages
     set created_at = now() - interval '5 minutes'
   where conversation_id = tests.conv(tests.j(1), tests.u(1), tests.u(2));
  perform tests.as_user(tests.u(1));
  perform public.clear_conversation(tests.conv(tests.j(1), tests.u(1), tests.u(2)));
  perform tests.as_user(tests.u(2));
  perform public.clear_conversation(tests.conv(tests.j(1), tests.u(1), tests.u(2)));
end $$;
select is(
  (select count(*)::int from storage.objects where bucket_id = 'messages'),
  0,
  'FS-07: clearing conversation on both sides blocks even the sender from reading hard-deleted message objects'
);

do $$ begin perform tests.as_postgres(); end $$;
select is(
  (select count(*)::int from public.claim_storage_purge(10)
    where bucket = 'messages'
      and path in (
        format('messages/%s/%s/%s.jpg', tests.conv(tests.j(1), tests.u(1), tests.u(2)), tests.u(2), tests.m(1)),
        format('messages/%s/%s/%s.jpg', tests.conv(tests.j(1), tests.u(1), tests.u(2)), tests.u(2), tests.m(2))
      )),
  2,
  'FS-07: clear_conversation enqueues hard-deleted message media_paths for immediate storage-purge-sweep claim'
);
do $$ begin perform tests.as_postgres(); delete from private.pending_storage_purge; end $$;

-- ============================================================================
-- 2. FS-08: atomic purge_account_data storage queueing & surviving group safety
-- ============================================================================
do $$ begin
  perform tests.as_user(tests.u(7));
  perform public.create_journey(tests.j(70), 'solo', 'custom', 'Dying Solo', '🌱', null, null, false, current_date - 2, 30, 'UTC');
  perform tests.checkin(tests.c(70), tests.j(70), now());
  perform public.create_journey(tests.j(7), 'group', 'custom', 'Surviving Group', '🔥', null, null, false, current_date - 2, 30, 'UTC');
  perform tests.checkin(tests.c(71), tests.j(7), now());
  perform tests.as_user(tests.u(8));
  perform public.join_by_code(tests.code(7));
  perform tests.checkin(tests.c(72), tests.j(7), now());
  perform tests.as_postgres();
  insert into storage.objects (bucket_id, name) values
    ('media', format('checkins/%s/%s/%s.jpg', tests.j(70), tests.u(7), tests.c(70))),
    ('media', format('checkins/%s/%s/%s.jpg', tests.j(7), tests.u(7), tests.c(71))),
    ('media', format('checkins/%s/%s/%s.jpg', tests.j(7), tests.u(8), tests.c(72)));
  delete from auth.users where id = tests.u(7);
end $$;

select is(
  (select count(*)::int from private.pending_storage_purge
    where path = format('checkins/%s/%s/%s.jpg', tests.j(7), tests.u(8), tests.c(72))),
  0,
  'FS-08: surviving group co-member photo is never queued for purge when group owner deletes account'
);
select is(
  (select count(*)::int from public.claim_storage_purge(10)
    where bucket = 'media'
      and path in (
        format('checkins/%s/%s/%s.jpg', tests.j(70), tests.u(7), tests.c(70)),
        format('checkins/%s/%s/%s.jpg', tests.j(7), tests.u(7), tests.c(71))
      )),
  2,
  'FS-08: deleted user solo and personal check-in paths are atomically queued and claimable on account delete'
);
do $$ begin perform tests.as_postgres(); delete from private.pending_storage_purge; end $$;

-- ============================================================================
-- 3. FS-09: send_group_invitation oracle prevention & check_ins UPDATE immutability
-- ============================================================================
do $$ begin
  perform tests.as_user(tests.u(1));
  perform public.create_journey(tests.j(2), 'group', 'custom', 'Couple Group', '💞', null, null, false,
                                current_date - 2, 30, 'UTC', 2, 'private', 'An', 'Binh');
  perform tests.checkin(tests.c(20), tests.j(2), now());
  perform tests.as_user(tests.u(2));
  perform public.join_by_code(tests.code(2));
  perform tests.as_user(tests.u(1));
end $$;

select throws_ok(
  $$ select public.send_group_invitation(tests.j(2), null, '@nonexistent_oracle_probe') $$,
  'P0001', 'full',
  'FS-09: full group raises full before resolving @handle (no username enumeration)'
);

do $$ begin
  perform tests.as_postgres();
  update public.journeys
     set start_date = current_date - 40, duration_days = 10,
         couple_self_name = null, couple_partner_name = null, max_members = 10
   where id = tests.j(2);
  perform tests.as_user(tests.u(1));
end $$;
select throws_ok(
  $$ select public.send_group_invitation(tests.j(2), null, '@nonexistent_oracle_probe') $$,
  'P0001', 'ended',
  'FS-09: duration-expired active group raises ended before resolving @handle'
);

do $$ begin
  perform tests.as_postgres();
  update public.journeys set start_date = current_date - 2, duration_days = 30 where id = tests.j(2);
  perform tests.as_user(tests.u(1));
end $$;
select throws_ok(
  $$ update public.check_ins set captured_at = now() - interval '1 hour' where id = tests.c(20) $$,
  '23514', 'immutable_column',
  'FS-09: check_ins.captured_at is immutable on UPDATE'
);
select throws_ok(
  $$ update public.check_ins set photo_path = photo_path || 'x' where id = tests.c(20) $$,
  '23514', 'immutable_column',
  'FS-09: check_ins.photo_path is immutable on UPDATE'
);
select lives_ok(
  $$ update public.check_ins set caption = 'updated caption' where id = tests.c(20) $$,
  'FS-09: legitimate check_ins.caption UPDATE still succeeds'
);

-- ============================================================================
-- 4. FS-20: send_friend_request rate limit, pending profile visibility, avatar isolation
-- ============================================================================
do $$ begin
  perform tests.as_postgres();
  update public.profiles
     set avatar_path = format('avatars/%s/aaaaaaaa-0000-4000-8000-000000000004.jpg', tests.u(4))
   where id = tests.u(4);
  insert into storage.objects (bucket_id, name)
  values ('media', format('avatars/%s/aaaaaaaa-0000-4000-8000-000000000004.jpg', tests.u(4)));
  perform tests.as_user(tests.u(3));
  perform public.send_friend_request(tests.u(4));
end $$;

select is(
  (select count(*)::int from public.profiles where id = tests.u(4))
  + (select count(*)::int from storage.objects
      where bucket_id = 'media' and name like format('avatars/%s/%%', tests.u(4))),
  0,
  'FS-20: unilateral pending friend request does not unlock target profile or avatar'
);

do $$ begin
  perform tests.as_postgres();
  insert into storage.objects (bucket_id, name) values
    ('media', format('avatars/%s/aaaaaaaa-0000-4000-8000-000000000011.jpg', tests.u(1))),
    ('media', format('avatars/%s/aaaaaaaa-0000-4000-8000-000000000012.jpg', tests.u(1)));
  perform tests.as_user(tests.u(1));
  update public.profiles
     set avatar_path = format('avatars/%s/aaaaaaaa-0000-4000-8000-000000000011.jpg', tests.u(1))
   where id = tests.u(1);
  update public.profiles
     set avatar_path = format('avatars/%s/aaaaaaaa-0000-4000-8000-000000000012.jpg', tests.u(1))
   where id = tests.u(1);
end $$;

do $$ begin perform tests.as_user(tests.u(2)); end $$;
select is(
  (select count(*)::int from storage.objects
    where bucket_id = 'media'
      and name = format('avatars/%s/aaaaaaaa-0000-4000-8000-000000000012.jpg', tests.u(1)))
  - (select count(*)::int from storage.objects
      where bucket_id = 'media'
        and name = format('avatars/%s/aaaaaaaa-0000-4000-8000-000000000011.jpg', tests.u(1))),
  1,
  'FS-20: co-member can only read current avatar_path (old replaced avatar is hidden)'
);

do $$ begin
  perform tests.as_postgres();
  insert into private.rate_events (user_id, kind)
  select tests.u(9), 'friend_request' from generate_series(1, 30);
end $$;
select throws_ok(
  $$ select tests.as_user(tests.u(9)), public.send_friend_request(tests.u(10)) $$,
  'P0001', 'rate_limited',
  'FS-20: direct send_friend_request is rate-limited at 30 per hour'
);

-- ============================================================================
-- 5. FS-21: blocks & expiry in my_conversations, inbox_counts, owner_for_viewer,
--           memberships_select, group invitations, and preview_group_by_code
-- ============================================================================
do $$ begin
  perform tests.as_user(tests.u(2));
  perform public.send_message(tests.m(10), tests.conv(tests.j(1), tests.u(1), tests.u(2)), 'photo', 'before block',
                              format('messages/%s/%s/%s.jpg', tests.conv(tests.j(1), tests.u(1), tests.u(2)), tests.u(2), tests.m(10)));
  insert into storage.objects (bucket_id, name)
  values ('messages', format('messages/%s/%s/%s.jpg', tests.conv(tests.j(1), tests.u(1), tests.u(2)), tests.u(2), tests.m(10)))
  on conflict (bucket_id, name) do nothing;
  perform tests.as_user(tests.u(1));
  perform public.block_user(tests.u(2));
end $$;

select is(
  (select count(*)::int from public.my_conversations())
  + (public.inbox_counts()->>'unread_messages')::int
  + (select count(*)::int from storage.objects where bucket_id = 'messages'),
  0,
  'FS-21: blocking a peer hides the conversation from my_conversations, inbox_counts, and storage.objects'
);

do $$ begin perform tests.as_user(tests.u(2)); end $$;
select is(
  (select count(*)::int from public.memberships where journey_id = tests.j(2) and user_id = tests.u(1))
  + (case when (private.owner_for_viewer(tests.j(2))->>'user_id') = '00000000-0000-0000-0000-000000000000' then 0 else 1 end),
  0,
  'FS-21: memberships_select hides blocked co-members and owner_for_viewer anonymizes blocked owners'
);

do $$ begin
  perform tests.as_user(tests.u(1));
  perform public.unblock_user(tests.u(2));
  -- u(2) is an active member of j(2) and blocks u(5)
  perform tests.as_user(tests.u(2));
  perform public.block_user(tests.u(5));
  perform tests.as_user(tests.u(1));
end $$;
select throws_ok(
  $$ select public.send_group_invitation(tests.j(2), tests.u(5)) $$,
  'P0001', 'not_found',
  'FS-21: send_group_invitation refuses invitee blocked by any active member of the group'
);

do $$ begin
  perform tests.as_user(tests.u(1));
  perform public.send_group_invitation(tests.j(2), tests.u(6));
  -- Now co-member u(2) blocks u(6) after the invitation was sent
  perform tests.as_user(tests.u(2));
  perform public.block_user(tests.u(6));
  perform tests.as_user(tests.u(6));
end $$;
select is(
  json_array_length(public.my_group_invitations())
  + (public.inbox_counts()->>'group_invitations')::int,
  0,
  'FS-21: my_group_invitations and inbox_counts hide invitations when an active co-member blocks the invitee'
);

do $$ begin
  perform tests.befriend(tests.u(1), tests.u(10));
  perform tests.as_user(tests.u(9));
end $$;
select is(
  (public.preview_group_by_code(tests.code(2))->'owner'->>'avatar_path'),
  null,
  'FS-21: preview_group_by_code hides owner/member avatar_path from strangers'
);

-- ============================================================================
-- 6. FS-22: continuing imported journeys (S9, anti-backdating, metrics, joined_at)
-- ============================================================================
do $$ begin
  perform tests.as_user(tests.u(1));
  perform public.create_imported_journey(
    tests.j(22), 'Continuing Trip', '✈️', 'travel',
    current_date - 20, current_date - 5, 'UTC', 'Weight', 'kg', 'memory_collectors', true
  );
end $$;

select throws_ok(
  $$ select public.set_public_link(tests.j(22), true) $$,
  'P0001', 'invalid',
  'FS-22 (S9): active continuing imported journey cannot enable a public link before ending'
);
select throws_ok(
  $$ select public.follow_frame(tests.j(22)) $$,
  'P0001', 'invalid',
  'FS-22 (S9): active continuing imported journey cannot be followed before ending'
);
select lives_ok(
  $$ select tests.checkin(tests.c(220), tests.j(22), now() - interval '10 days', true) $$,
  'FS-22: active continuing imported journey allows initial historical library photos inside [p_first, p_last]'
);
select throws_ok(
  $$ select tests.checkin(tests.c(222), tests.j(22), now() - interval '9 days', false) $$,
  '22008', 'invalid_captured_at',
  'FS-22: active continuing imported journey enforces the 3-day anti-backdating rule on non-library / post-import days'
);

do $$ begin
  perform tests.as_user(tests.u(1));
  perform tests.checkin(tests.c(221), tests.j(22), now() - interval '1 day', false);
  perform public.end_journey(tests.j(22));
end $$;
select throws_ok(
  $$ insert into public.check_in_metrics (checkin_id, journey_id, user_id, metric_value)
     values (tests.c(221), tests.j(22), auth.uid(), 70.0) $$,
  'P0001', 'ended',
  'FS-22: check_in_metrics_before_write rejects writes on an ended continuing imported journey'
);

do $$ begin
  perform tests.as_user(tests.u(1));
  perform public.create_imported_journey(
    tests.j(23), 'Finished Trip', '🏔️', 'travel',
    current_date - 20, current_date - 10, 'UTC', null, null, 'memory_collectors', false
  );
  perform tests.checkin(tests.c(231), tests.j(23), now() - interval '15 days', true);
  perform tests.checkin(tests.c(232), tests.j(23), now() - interval '14 days', true);
end $$;
select is(
  (select completed_days from public.journey_streak(tests.j(23), tests.u(1))),
  2,
  'FS-22: create_imported_journey seeds joined_at from p_first so journey_streak counts historical days'
);

-- ============================================================================
-- 7. FS-23: ended-journey streak preservation, multi-photo sort, layout/color/cover_blurred
-- ============================================================================
do $$ begin
  perform tests.as_user(tests.u(1));
  perform public.create_journey(tests.j(30), 'solo', 'custom', 'Ended Solo', '🔥', null, null, false,
                                current_date - 20, 30, 'UTC');
  perform public.update_journey(tests.j(30), null, 'aesthetic_flexer', 1, 2);
  perform public.create_journey(tests.j(31), 'group', 'custom', 'Ended Group', '🤝', null, null, false,
                                current_date - 20, 30, 'UTC', 2, 'private', 'An', 'Binh');
  perform tests.as_user(tests.u(3));
  perform public.join_by_code(tests.code(31));
  perform tests.as_postgres();
  -- Simulate check-ins from 10 and 11 days ago on both journeys, then end both journeys
  insert into public.check_ins (id, journey_id, user_id, local_date, captured_at, photo_path, thumb_path) values
    (tests.c(301), tests.j(30), tests.u(1), current_date - 11, now() - interval '11 days',
     format('checkins/%s/%s/%s.jpg', tests.j(30), tests.u(1), tests.c(301)),
     format('checkins/%s/%s/%s_t.jpg', tests.j(30), tests.u(1), tests.c(301))),
    (tests.c(302), tests.j(30), tests.u(1), current_date - 10, now() - interval '10 days' + interval '2 hours',
     format('checkins/%s/%s/%s.jpg', tests.j(30), tests.u(1), tests.c(302)),
     format('checkins/%s/%s/%s_t.jpg', tests.j(30), tests.u(1), tests.c(302))),
    -- Earlier captured_at on the same day (current_date - 10) but inserted later with higher UUID
    (tests.c(303), tests.j(30), tests.u(1), current_date - 10, now() - interval '10 days' + interval '1 hour',
     format('checkins/%s/%s/%s.jpg', tests.j(30), tests.u(1), tests.c(303)),
     format('checkins/%s/%s/%s_t.jpg', tests.j(30), tests.u(1), tests.c(303))),
    (tests.c(311), tests.j(31), tests.u(1), current_date - 11, now() - interval '11 days',
     format('checkins/%s/%s/%s.jpg', tests.j(31), tests.u(1), tests.c(311)),
     format('checkins/%s/%s/%s_t.jpg', tests.j(31), tests.u(1), tests.c(311))),
    (tests.c(312), tests.j(31), tests.u(1), current_date - 10, now() - interval '10 days',
     format('checkins/%s/%s/%s.jpg', tests.j(31), tests.u(1), tests.c(312)),
     format('checkins/%s/%s/%s_t.jpg', tests.j(31), tests.u(1), tests.c(312)));
  update public.check_ins
     set partner_photo_path = format('checkins/%s/%s/%s_p.jpg', tests.j(31), tests.u(1), tests.c(311))
   where id = tests.c(311);
  update public.memberships set joined_at = now() - interval '20 days'
   where journey_id in (tests.j(30), tests.j(31));
  update public.memberships set blur_media = true
   where journey_id = tests.j(30) and user_id = tests.u(1);
  perform tests.as_user(tests.u(1));
  perform public.update_journey_story(tests.j(30), 'Story', 'Intro', 'Lessons', tests.c(301));
  perform public.end_journey(tests.j(30));
  perform public.share_journey(tests.j(30), array[tests.u(10)]);
  perform public.request_share_consent(tests.j(31));
  perform public.end_journey(tests.j(31));
  perform public.share_journey(tests.j(31), array[tests.u(10)]);
end $$;

do $$ begin perform tests.as_user(tests.u(10)); end $$;
select is(
  (public.shared_journey(tests.j(30))->>'current_streak')::int,
  2,
  'FS-23: ended solo journey preserves its final streak in shared_journey days after ending'
);
select is(
  (public.shared_journey(tests.j(31))->>'current_streak')::int,
  2,
  'FS-23: ended group journey preserves its final group_streak in shared_journey days after ending'
);
select is(
  coalesce(public.shared_journey(tests.j(31))->>'couple_self_name', '')
  || coalesce(public.shared_journey(tests.j(31))->>'couple_partner_name', '')
  || coalesce(public.shared_journey(tests.j(31))->'photos'->0->>'partner_photo_path', ''),
  '',
  'FS-23 (S29/S30): couple names and partner_photo_path are hidden when a partner co-member has not consented'
);
select results_eq(
  $$ select v->>'layout', (v->>'color')::int, (v->>'cover')::int, (v->>'cover_blurred')::boolean,
            (v->'photos'->1->>'checkin_id')::uuid, (v->'photos'->2->>'checkin_id')::uuid
       from (select public.shared_journey(tests.j(30)) as v) x $$,
  format('values (''aesthetic_flexer'', 2, 1, true, %L::uuid, %L::uuid)', tests.c(303), tests.c(302)),
  'FS-23: shared_journey exposes layout/color/cover/cover_blurred and sorts same-day photos by captured_at asc'
);

-- ============================================================================
-- 8. FS-24: hot-path reports indexes and FK indexes exist
-- ============================================================================
select is(
  (select count(*)::int from pg_indexes
    where schemaname = 'public'
      and indexname in (
        'reports_reporter_checkin_idx',
        'reports_reporter_message_idx',
        'reports_reporter_created_idx',
        'reports_target_checkin_idx',
        'reports_target_user_idx',
        'reports_target_message_idx',
        'reactions_user_idx',
        'memberships_user_all_idx',
        'journeys_cover_checkin_idx',
        'messages_reply_to_checkin_idx',
        'messages_media_path_idx',
        'saved_journeys_journey_idx',
        'journey_share_consents_user_idx',
        'journey_share_consents_requested_by_idx',
        'check_in_metrics_user_idx',
        'check_in_extras_user_idx',
        'message_hides_user_idx',
        'moderation_queue_report_idx',
        'friendships_requested_by_idx',
        'friendships_source_journey_idx',
        'journey_shares_viewer_all_idx',
        'group_invitations_invitee_all_idx'
      )),
  22,
  'FS-24: all 22 reports RLS hot-path, message media_path, and FK indexes are present'
);

-- ============================================================================
-- 9. FS-25: profile_stats() Rule S12 & ended/completed parity
-- ============================================================================
do $$ begin
  perform tests.as_user(tests.u(6));
  -- 1) Imported journey with 2 consecutive days (must NOT count toward longest_streak / current_streak per S12,
  --    but DOES count toward journeys_completed and total_snaps)
  perform public.create_imported_journey(
    tests.j(61), 'Imported 61', '✈️', 'travel',
    current_date - 10, current_date - 5, 'UTC', null, null, null, false
  );
  perform tests.checkin(tests.c(611), tests.j(61), now() - interval '8 days', true);
  perform tests.checkin(tests.c(612), tests.j(61), now() - interval '7 days', true);
  -- 2) Ended live journey with a check-in today (counts toward longest_streak = 1 and journeys_completed,
  --    but NOT current_streak because status = 'ended')
  perform public.create_journey(tests.j(62), 'solo', 'custom', 'Ended Live', '🏁', null, null, false,
                                current_date - 2, 30, 'UTC');
  perform tests.checkin(tests.c(621), tests.j(62), now(), false);
  perform public.end_journey(tests.j(62));
end $$;

select results_eq(
  $$ select total_snaps, longest_streak, current_streak, journeys_completed, journeys_total
       from public.profile_stats() $$,
  $$ values (3, 1, 0, 2, 2) $$,
  'FS-25: profile_stats excludes imported journeys from streaks (S12) and ended journeys from current_streak'
);

-- ============================================================================
-- 10. FS-38: journey_dna_valid NULL trap, whitespace-only titles, report_content dedup,
--            withdraw_share_consent grant revocation
-- ============================================================================
select is(
  public.journey_dna_valid('{"dates":{"start":"2026-05-01","end":null}}'::jsonb) is false
  and public.journey_dna_valid('{"dates":{"start":null}}'::jsonb) is false
  and public.journey_dna_valid('{"dates":{"start":"2026-05-10","end":"2026-05-01"}}'::jsonb) is false
  and public.journey_dna_valid('{"trophy":"   "}'::jsonb) is false
  and public.journey_dna_valid('{"dates":{"start":"2026-05-01","end":"2026-05-10"}}'::jsonb) is true,
  true,
  'FS-38: journey_dna_valid returns false (never NULL) for null/inverted dates and whitespace-only strings'
);

select throws_ok(
  $$ update public.profiles set display_name = '   ' where id = tests.u(6) $$,
  '23514', null,
  'FS-38: profiles.display_name rejects whitespace-only strings'
);

do $$ begin
  perform tests.as_user(tests.u(1));
  if public.report_content(null, null, 'spam', 'msg first', tests.m(10))
     <> public.report_content(null, null, 'harassment', 'msg duplicate', tests.m(10)) then
    raise exception 'expected message report deduplication to return the existing open report id';
  end if;
  perform tests.as_user(tests.u(2));
end $$;
select is(
  public.report_content(tests.c(20), null, 'spam', 'first')
  = public.report_content(tests.c(20), null, 'harassment', 'duplicate'),
  true,
  'FS-38: report_content deduplicates repeated open reports on the same message or check-in target'
);

do $$ declare
  r1 uuid;
  r2 uuid;
begin
  perform tests.as_user(tests.u(2));
  r1 := public.report_content(null, tests.u(1), 'spam', 'first user report');
  perform tests.as_postgres();
  update public.reports set status = 'dismissed' where id = r1;
  perform tests.as_user(tests.u(2));
  r2 := public.report_content(null, tests.u(1), 'harassment', 'new user report after dismissal');
  if r1 = r2 then
    raise exception 'expected new report id after prior user report was dismissed';
  end if;
end $$;
select is(
  (select count(*)::int from public.reports
    where reporter_id = tests.u(2) and target_user_id = tests.u(1)
      and target_checkin_id is null and target_message_id is null),
  2,
  'FS-38: report_content allows a fresh user report after a prior report was dismissed'
);

do $$ begin
  -- u(2) is an active member of group j(2); u(2) consents and shares j(2) with friend u(1), then withdraws consent
  perform tests.as_user(tests.u(2));
  perform public.request_share_consent(tests.j(2));
  perform public.share_journey(tests.j(2), array[tests.u(1)]);
  perform public.withdraw_share_consent(tests.j(2));
  perform tests.as_postgres();
end $$;
select is(
  (select count(*)::int from public.journey_shares
    where journey_id = tests.j(2) and shared_by = tests.u(2) and revoked_at is null)
  + (select case when count(*)::int = 1 then 0 else 1 end
       from public.claim_storage_purge(10)
      where bucket = 'media'
        and path = format('avatars/%s/aaaaaaaa-0000-4000-8000-000000000011.jpg', tests.u(1))),
  0,
  'FS-38 & FS-20: withdraw_share_consent revokes withdrawing member shares and replaced avatar is queued for purge'
);

select * from finish();
rollback;
