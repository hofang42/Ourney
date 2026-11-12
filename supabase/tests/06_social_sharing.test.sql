-- Social v1.3 (0006_social): sharing, public link (S9), strangers + saved, group consents,
-- retold journeys, follow-along, insights / reach.
-- Users: 1 A solo owner, 2 B friend of A, 3 C stranger, 4 D group owner, 5 E group member,
--        6 F friend of D and E, 7 S second stranger, 8 H late group joiner.
begin;
create extension if not exists pgtap with schema extensions;
select plan(101);

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
  select format('61000000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function tests.j(n int) returns uuid language sql immutable as $$
  select format('b6000000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function tests.c(n int) returns uuid language sql immutable as $$
  select format('c6000000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function tests.photo(j uuid, u uuid, c uuid) returns text language sql immutable as $$
  select format('checkins/%s/%s/%s.jpg', j, u, c) $$;
create function tests.checkin(cid uuid, j uuid, at timestamptz) returns void language sql as $$
  insert into public.check_ins (id, journey_id, user_id, local_date, captured_at, photo_path, thumb_path)
  values (cid, j, auth.uid(), current_date, at, tests.photo(j, auth.uid(), cid),
          format('checkins/%s/%s/%s_t.jpg', j, auth.uid(), cid)) $$;
create function tests.react(cid uuid) returns void language sql as $$
  insert into public.reactions (checkin_id, user_id, emoji) values (cid, auth.uid(), '❤️')
  on conflict (checkin_id, user_id) do update set deleted_at = null $$;
create function tests.journey(n int) returns public.journeys language sql security definer as $$
  select * from public.journeys where id = tests.j(n) $$;
create function tests.photo_ids(v json) returns uuid[] language sql immutable as $$
  select coalesce(array_agg((p->>'checkin_id')::uuid order by p->>'checkin_id'), '{}')
    from json_array_elements(v->'photos') p $$;
grant execute on all functions in schema tests to authenticated;

insert into auth.users (id, email) select tests.u(n), format('sh%s@example.test', n) from generate_series(1, 8) n;
insert into public.profiles (id, username, display_name) select tests.u(n), 'shuser' || n, 'SH' || n from generate_series(1, 8) n;

-- ---- setup -------------------------------------------------------------------
-- A: J1 (solo, two check-ins, c2 later hidden in share), J2 (solo, active)
do $$ begin perform tests.as_user(tests.u(1));
  perform public.create_journey(tests.j(1), 'solo', 'custom', 'Walk', '🚶', 'Steps', 'k', false, current_date - 5, 30, 'UTC');
  perform public.create_journey(tests.j(2), 'solo', 'custom', 'Read', '📚', null, null, false, current_date - 5, 30, 'UTC');
  perform tests.checkin(tests.c(1), tests.j(1), now() - interval '1 day');
  perform tests.checkin(tests.c(2), tests.j(1), now());
  insert into public.check_in_metrics (checkin_id, journey_id, user_id, metric_value) values (tests.c(1), tests.j(1), auth.uid(), 42);
end $$;
-- D: group G = j(10) with E; one check-in each
do $$ begin perform tests.as_user(tests.u(4));
  perform public.create_journey(tests.j(10), 'group', 'custom', 'Squad', '🔥', null, null, false, current_date - 5, 30, 'UTC');
  perform tests.checkin(tests.c(10), tests.j(10), now()); end $$;
do $$ begin perform tests.as_user(tests.u(5));
  perform public.join_by_code((tests.journey(10)).invite_code);
  perform tests.checkin(tests.c(11), tests.j(10), now()); end $$;
-- friendships: A-B, D-F, E-F
do $$ begin perform tests.as_user(tests.u(1)); perform public.send_friend_request(tests.u(2)); end $$;
do $$ begin perform tests.as_user(tests.u(2)); perform public.respond_friend_request(tests.u(1), true); end $$;
do $$ begin perform tests.as_user(tests.u(6));
  perform public.send_friend_request(tests.u(4)); perform public.send_friend_request(tests.u(5)); end $$;
do $$ begin perform tests.as_user(tests.u(4)); perform public.respond_friend_request(tests.u(6), true); end $$;
do $$ begin perform tests.as_user(tests.u(5)); perform public.respond_friend_request(tests.u(6), true); end $$;
do $$ begin perform tests.as_postgres(); end $$;
insert into storage.objects (bucket_id, name) values
  ('media', tests.photo(tests.j(1), tests.u(1), tests.c(1))),
  ('media', tests.photo(tests.j(1), tests.u(1), tests.c(2)));

-- ===== hidden_in_share + friend grants ==========================================
do $$ begin perform tests.as_user(tests.u(2)); end $$;
select throws_ok($$ select public.set_hidden_in_share(tests.c(2), true) $$, '42501', 'forbidden',
  'only the author can hide a check-in in shares');
do $$ begin perform tests.as_user(tests.u(1)); end $$;
select lives_ok($$ select public.set_hidden_in_share(tests.c(2), true) $$, 'author hides c2 in shares');
select throws_ok($$ update public.check_ins set hidden_in_share = false where id = tests.c(2) $$, '42501', null,
  'hidden_in_share is not directly writable');
select throws_ok($$ select public.share_journey(tests.j(1), array[tests.u(3)]) $$, '42501', 'forbidden',
  'cannot share with a non-friend');
select lives_ok($$ select public.share_journey(tests.j(1), array[tests.u(2)]) $$, 'A shares J1 with friend B');
select is((public.journey_share_state(tests.j(1))->'viewers'->0->>'user_id')::uuid, tests.u(2),
  'journey_share_state lists the caller''s grants');
select is(public.journey_share_state(tests.j(1))->'hidden_checkin_ids'->>0, tests.c(2)::text,
  'journey_share_state lists hidden check-ins');
select lives_ok($$ select public.end_journey(tests.j(1)) $$, 'A ends J1');

do $$ begin perform tests.as_user(tests.u(2)); end $$;
select results_eq($$ select (s->>'journey_id')::uuid, (s->>'unseen')::boolean, (s->>'saved')::boolean,
                            (s->>'photo_count')::int, s->'shared_by'->>'username' from public.shared_with_me() s $$,
  $$ values (tests.j(1), true, false, 1, 'shuser1') $$, 'shared_with_me: grant, unseen, hidden photo not counted');
select is((public.inbox_counts()->>'new_shares')::int, 1, 'inbox_counts.new_shares');
select public.shared_journey(tests.j(1))::text as view_b \gset
select is((:'view_b'::json)->>'role', 'friend', 'shared_journey: role friend');
select is(tests.photo_ids(:'view_b'::json), array[tests.c(1)], 'viewer cannot see hidden_in_share photos');
select ok(((:'view_b'::json)->>'can_reply')::boolean and ((:'view_b'::json)->>'can_react')::boolean
          and ((:'view_b'::json)->>'can_follow')::boolean and not ((:'view_b'::json)->>'can_add_owner')::boolean,
  'friend can react, reply and follow an ended journey');
select is((:'view_b'::json)->'photos'->0->>'metric_value', '42', 'metric shown when the author does not hide it');
select ok((:'view_b'::json)->>'like_count' is null, 'like_count is null for non-members without show_counts');
select is((:'view_b'::json)->'shared_by'->>'username', 'shuser1', 'shared_by is the granting member');
select is((public.inbox_counts()->>'new_shares')::int, 0, 'opening marks the share seen');
select is((select count(*)::int from storage.objects where name = tests.photo(tests.j(1), tests.u(1), tests.c(1))), 1,
  'friend grantee reads the shared photo');
select is((select count(*)::int from storage.objects where name = tests.photo(tests.j(1), tests.u(1), tests.c(2))), 0,
  'friend grantee cannot read a hidden_in_share photo');
select is((select count(*)::int from public.check_ins), 0, 'grantee still cannot read check_ins rows directly');
select lives_ok($$ select tests.react(tests.c(1)) $$, 'friend reacts on a shared (ended) journey');
select throws_ok($$ select tests.react(tests.c(2)) $$, '42501', null, 'no reaction on a hidden_in_share photo');
select is((select count(*)::int from public.saved_journeys), 0, 'a friend''s like does not save the journey');

do $$ begin perform tests.as_user(tests.u(3)); end $$;
select throws_ok($$ select public.shared_journey(tests.j(1)) $$, '42501', 'forbidden', 'stranger without a grant -> forbidden');
select throws_ok($$ select tests.react(tests.c(1)) $$, '42501', null, 'stranger cannot react without a public link');

-- ===== public link (S9) + strangers ===========================================
do $$ begin perform tests.as_user(tests.u(1)); end $$;
select throws_ok($$ select public.set_public_link(tests.j(2), true) $$, 'P0001', 'invalid', 'S9: active journey cannot get a public link');
select public.set_public_link(tests.j(1), true) as tok \gset
select matches(:'tok'::text, '^[a-z0-9]{40}$', 'ended journey gets a token');
select is(public.set_public_link(tests.j(1), true), :'tok'::text, 'enabling again keeps the token');
select is((tests.journey(1)).visibility::text, 'link', 'solo visibility follows the link');
do $$ begin perform tests.as_user(tests.u(2)); end $$;
select throws_ok($$ select public.set_public_link(tests.j(1), true, true) $$, '42501', 'forbidden', 'non-owner cannot manage the link');

do $$ begin perform tests.as_user(tests.u(3)); end $$;
select throws_ok($$ select public.public_journey_by_token('zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz') $$, 'P0001', 'not_found',
  'unknown token -> not_found');
select public.public_journey_by_token(:'tok')::text as view_c \gset
select is((:'view_c'::json)->>'role', 'stranger', 'public_journey_by_token: role stranger');
select ok(not ((:'view_c'::json)->>'can_reply')::boolean and ((:'view_c'::json)->>'can_add_owner')::boolean
          and ((:'view_c'::json)->>'can_react')::boolean,
  'stranger: no reply, can add owner, can react (allow_public_reactions)');
select is(tests.photo_ids(:'view_c'::json), array[tests.c(1)], 'stranger never gets hidden photos');
select is((:'view_c'::json)->'photos'->0->>'like_count', '0', 'per-photo like_count is 0 without show_counts');
select is((select count(*)::int from storage.objects where name = tests.photo(tests.j(1), tests.u(1), tests.c(1))), 1,
  'signed-in stranger reads photos of a public journey');
select lives_ok($$ select tests.react(tests.c(1)) $$, 'stranger reacts (allow_public_reactions)');
select is((select count(*)::int from public.saved_journeys where journey_id = tests.j(1)), 1, 'S26: stranger like saves the journey');
select results_eq($$ select (s->>'saved')::boolean, s->'shared_by'->>'username' from public.shared_with_me() s $$,
  $$ values (true, 'shuser1') $$, 'saved journey shows in shared_with_me with the owner as shared_by');
select is((select count(*)::int from public.reactions), 1, 'viewer reads only their own reaction');
select is(public.shared_journey(tests.j(1))->>'role', 'stranger', 'saved journey opens by id as stranger');
do $$ begin update public.reactions set deleted_at = now() where checkin_id = tests.c(1) and user_id = auth.uid(); end $$;
select is((select count(*)::int from public.saved_journeys), 0, 'removing the last like unsaves');
select lives_ok($$ select tests.react(tests.c(1)) $$, 'stranger likes again');
select lives_ok($$ select public.send_friend_request(tests.u(1), tests.j(1)) $$, 'stranger sends a request from the public page');

do $$ begin perform tests.as_user(tests.u(1)); end $$;
select results_eq($$ select (c->>'friend_requests')::int, (c->>'public_requests')::int from public.inbox_counts() c $$,
  $$ values (0, 1) $$, 'S27: public-page requests are counted separately');
select lives_ok($$ select public.update_public_settings(tests.j(1), true, false, false) $$, 'owner: show counts, no reactions, no requests');
do $$ begin perform tests.as_user(tests.u(3)); end $$;
select is((public.public_journey_by_token(:'tok')->>'like_count')::int, 2, 'show_counts exposes like_count to strangers');
do $$ begin perform tests.as_user(tests.u(7)); end $$;
select throws_ok($$ select tests.react(tests.c(1)) $$, '42501', null, 'no stranger reactions when allow_public_reactions is off');
select throws_ok($$ select public.send_friend_request(tests.u(1), tests.j(1)) $$, '42501', 'forbidden',
  'no viewer requests when allow_viewer_requests is off');
do $$ begin perform tests.as_user(tests.u(1)); perform public.update_public_settings(tests.j(1), null, null, true); end $$;
do $$ begin perform tests.as_postgres();
  insert into private.rate_events (user_id, kind) select tests.u(7), 'public_friend_request' from generate_series(1, 20); end $$;
do $$ begin perform tests.as_user(tests.u(7)); end $$;
select throws_ok($$ select public.send_friend_request(tests.u(1), tests.j(1)) $$, 'P0001', 'rate_limited',
  'S39: 20 public-page requests per sender per day');
select is(public.public_journey_by_token(:'tok')->>'role', 'stranger', 'second stranger views (no like)');

-- ===== follow-along ============================================================
do $$ begin perform tests.as_user(tests.u(3)); end $$;
select results_eq($$ select f->>'template_id', f->>'owner_name', (f->>'duration_days')::int, f->>'metric_name'
                       from public.follow_frame(tests.j(1)) f $$,
  $$ values ('custom', 'SH1', 30, 'Steps') $$, 'follow_frame copies the frame only');
do $$ begin perform tests.as_user(tests.u(1)); end $$;
select throws_ok($$ select public.follow_frame(tests.j(2)) $$, 'P0001', 'invalid', 'follow_frame needs an ended journey');
do $$ begin perform tests.as_user(tests.u(3));
  perform public.create_journey(tests.j(3), 'solo', 'custom', 'Walk too', '🚶', null, null, false, current_date, 30, 'UTC'); end $$;
select lives_ok($$ select public.mark_followed(tests.j(3), tests.j(1)) $$, 'mark_followed on a fresh own journey');
select throws_ok($$ select public.mark_followed(tests.j(1), tests.j(3)) $$, '42501', 'forbidden', 'mark_followed needs own journey');
do $$ begin perform tests.as_user(tests.u(3));
  perform public.create_journey(tests.j(6), 'solo', 'custom', 'Walk again', '🚶', null, null, false, current_date, 30, 'UTC'); end $$;
select lives_ok($$ select public.mark_followed(tests.j(6), tests.j(1)) $$,
  'a second follow by the same owner (counted once below)');

-- ===== insights ===============================================================
do $$ begin perform tests.as_user(tests.u(1)); end $$;
select public.journey_insights(tests.j(1))::text as ins \gset
select results_eq(format($f$ select (i->>'views')::int, (i->>'likes_from_friends')::int, (i->>'likes_from_strangers')::int,
                            (i->>'started')::int, (i->>'views_this_week')::int, json_array_length(i->'likers')
                       from (select %L::json as i) x $f$, :'ins'),
  $$ values (3, 1, 1, 1, 3, 2) $$, 'journey_insights: distinct viewers, likes split, started, likers');
select ok(position(tests.u(7)::text in :'ins') = 0, 'journey_insights never exposes viewer identities');
select is((:'ins'::json)->'views_by_day'->0->>'count', '3', 'views_by_day counts distinct viewers per day');
select is(public.my_reach(), 3, 'my_reach counts distinct viewers over own journeys');
do $$ begin perform tests.as_user(tests.u(3)); end $$;
select ok(public.public_journey_by_token(:'tok') is not null, 'the same stranger opens the link again');
do $$ begin perform tests.as_user(tests.u(1)); end $$;
select is((public.journey_insights(tests.j(1))->>'views')::int, 3, 'repeat views by the same person do not count');
do $$ begin perform tests.as_user(tests.u(3)); end $$;
select throws_ok($$ select public.journey_insights(tests.j(1)) $$, '42501', 'forbidden', 'only members read insights');
select throws_ok($$ select * from public.journey_views $$, '42501', null, 'journey_views has no client read');

-- ===== revoke ================================================================
do $$ begin perform tests.as_user(tests.u(1)); perform public.unshare_journey(tests.j(1), tests.u(2)); end $$;
do $$ begin perform tests.as_user(tests.u(2)); end $$;
select throws_ok($$ select public.shared_journey(tests.j(1)) $$, '42501', 'forbidden', 'unshared friend loses access');
do $$ begin perform tests.as_user(tests.u(1)); perform public.share_journey(tests.j(1), array[tests.u(2)]); end $$;
do $$ begin perform tests.as_user(tests.u(2)); end $$;
select is((public.inbox_counts()->>'new_shares')::int, 1, 're-grant resets seen_at');
do $$ begin perform tests.as_user(tests.u(2)); perform public.remove_friend(tests.u(1)); end $$;
select throws_ok($$ select public.shared_journey(tests.j(1)) $$, '42501', 'forbidden', 'unfriend revokes the share');
select ok((select revoked_at is not null from public.journey_shares where journey_id = tests.j(1)),
  'unfriend sets revoked_at on the grant');
do $$ begin perform tests.as_user(tests.u(1)); perform public.unshare_journey(tests.j(1), null, true); end $$;
select ok((tests.journey(1)).public_token is null and (tests.journey(1)).visibility = 'private',
  'stop sharing (all) clears the token');
do $$ begin perform tests.as_user(tests.u(3)); end $$;
select throws_ok(format('select public.public_journey_by_token(%L)', :'tok'), 'P0001', 'not_found', 'dead link -> not_found');
select is((select count(*)::int from public.shared_with_me()), 0, 'saved journey disappears once the link is off');

-- ===== retold (imported) journeys =============================================
do $$ begin perform tests.as_user(tests.u(1)); end $$;
select throws_ok($$ select public.create_imported_journey(tests.j(4), 'Trip', '✈️', 'travel', current_date - 10, current_date + 1, 'UTC') $$,
  'P0001', 'invalid', 'imported journey cannot end in the future');
select throws_ok($$ select public.create_imported_journey(tests.j(4), 'Trip', '✈️', 'travel', current_date - 400, current_date - 1, 'UTC') $$,
  'P0001', 'invalid', 'imported journey is at most 366 days');
select results_eq($$ select origin, status::text, visibility::text, duration_days, start_date
                       from public.create_imported_journey(tests.j(4), 'Trip', '✈️', 'travel', current_date - 40, current_date - 20, 'UTC') $$,
  $$ values ('imported', 'ended', 'private', 21, current_date - 40) $$, 'create_imported_journey: ended, private, dated by photos');
select lives_ok($$ select public.create_imported_journey(tests.j(4), 'Trip', '✈️', 'travel', current_date - 40, current_date - 20, 'UTC') $$,
  'create_imported_journey is idempotent');
select lives_ok($$ select tests.checkin(tests.c(4), tests.j(4), now() - interval '30 days') $$,
  'back-dated check-in allowed in an imported journey');
select lives_ok($$ insert into public.check_in_metrics (checkin_id, journey_id, user_id, metric_value)
                   values (tests.c(4), tests.j(4), auth.uid(), 1) $$, 'metric allowed on an imported check-in');
select throws_ok($$ select tests.checkin(tests.c(5), tests.j(4), now() - interval '50 days') $$, '22008', 'invalid_captured_at',
  'imported check-in must fall inside the journey dates');
select throws_ok($$ select tests.checkin(tests.c(6), tests.j(2), now() - interval '30 days') $$, '22008', 'invalid_captured_at',
  'live journeys keep the 3-day rule');
select matches(public.set_public_link(tests.j(4), true), '^[a-z0-9]{40}$', 'imported journeys can get a public link');

-- ===== group consents (S29-S34) ===============================================
do $$ begin perform tests.as_user(tests.u(4)); end $$;
select throws_ok($$ select public.share_journey(tests.j(10), array[tests.u(6)]) $$, 'P0001', 'consent_required',
  'group share needs the caller''s consent first');
select lives_ok($$ select public.request_share_consent(tests.j(10)) $$, 'D asks the group');
select results_eq($$ select c->'member'->>'username', c->>'status' from public.share_consents(tests.j(10)) c $$,
  $$ values ('shuser4', 'accepted'), ('shuser5', 'pending') $$, 'requester accepted, others pending');
select lives_ok($$ select public.share_journey(tests.j(10), array[tests.u(6)]) $$, 'D shares the group with F');
do $$ begin perform tests.as_user(tests.u(5)); end $$;
select is((select count(*)::int from public.my_pending_consents()), 1, 'E has a pending consent');
select is((public.inbox_counts()->>'consent_requests')::int, 1, 'inbox_counts.consent_requests');
do $$ begin perform tests.as_user(tests.u(6)); end $$;
select public.shared_journey(tests.j(10))::text as gv \gset
select is(tests.photo_ids(:'gv'::json), array[tests.c(10)], 'S30: non-consenting author''s photos are hidden');
select is(json_array_length((:'gv'::json)->'members'), 1, 'S34: only consenting members are listed');
select ok((:'gv'::json)->>'current_streak' is not null, 'friends see the group streak');
select throws_ok($$ select tests.react(tests.c(11)) $$, '42501', null, 'no reaction on a non-consenting author''s photo');
do $$ begin perform tests.as_user(tests.u(5)); perform public.respond_share_consent(tests.j(10), true); end $$;
do $$ begin perform tests.as_user(tests.u(6)); end $$;
select is(tests.photo_ids(public.shared_journey(tests.j(10))), array[tests.c(10), tests.c(11)], 'accepting shows the photos');
do $$ begin perform tests.as_user(tests.u(5)); perform public.withdraw_share_consent(tests.j(10)); end $$;
do $$ begin perform tests.as_user(tests.u(6)); end $$;
select is(tests.photo_ids(public.shared_journey(tests.j(10))), array[tests.c(10)], 'S31: withdrawing hides them again');
do $$ begin perform tests.as_user(tests.u(8)); perform public.join_by_code((tests.journey(10)).invite_code); end $$;
select is((select status from public.journey_share_consents where journey_id = tests.j(10) and user_id = tests.u(8)), 'pending',
  'a member joining a shared group gets a pending consent');
do $$ begin perform tests.as_user(tests.u(5)); end $$;
select throws_ok($$ select public.set_public_link(tests.j(10), true) $$, '42501', 'forbidden', 'only the group owner manages the link');
do $$ begin perform tests.as_user(tests.u(4)); end $$;
select throws_ok($$ select public.set_public_link(tests.j(10), true) $$, 'P0001', 'invalid', 'S9: running group cannot get a link');
select lives_ok($$ select public.end_journey(tests.j(10)) $$, 'D ends the group');
select public.set_public_link(tests.j(10), true) as gtok \gset
select ok((tests.journey(10)).visibility = 'group' and (tests.journey(10)).public_token = :'gtok',
  'S32: group keeps visibility group with its own token');
do $$ begin perform tests.as_user(tests.u(3)); end $$;
select public.public_journey_by_token(:'gtok')::text as gs \gset
select ok((:'gs'::json)->>'current_streak' is null and tests.photo_ids(:'gs'::json) = array[tests.c(10)],
  'stranger on a group: no streak, consenting photos only');
select is((:'gs'::json)->'owner'->>'display_name', 'SH4', 'a consenting group owner is named');
do $$ begin perform tests.as_postgres();
  update public.journey_share_consents set status = 'pending' where journey_id = tests.j(10) and user_id = tests.u(4);
  perform tests.as_user(tests.u(3)); end $$;
select ok((public.public_journey_by_token(:'gtok'))->'owner'->>'display_name' = ''
          and (public.public_journey_by_token(:'gtok'))->'owner'->>'user_id' = '00000000-0000-0000-0000-000000000000',
  'a non-consenting group owner stays anonymous');
do $$ begin perform tests.as_postgres();
  update public.journey_share_consents set status = 'accepted' where journey_id = tests.j(10) and user_id = tests.u(4); end $$;
do $$ begin perform tests.as_user(tests.u(1)); end $$;
select throws_ok($$ select public.share_consents(tests.j(10)) $$, '42501', 'forbidden', 'consents readable by members only');

select * from finish();
rollback;
