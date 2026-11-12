-- Social v1.3 (0006_social): RLS baseline of the new tables, friends, invites, username search.
-- Users: 1..7 (see each block).
begin;
create extension if not exists pgtap with schema extensions;
select plan(43);

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
  select format('60000000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function tests.friend_row(a int, b int) returns public.friendships language sql security definer as $$
  select * from public.friendships
   where user_low = least(tests.u(a), tests.u(b)) and user_high = greatest(tests.u(a), tests.u(b)) $$;
grant execute on all functions in schema tests to authenticated;

insert into auth.users (id, email) select tests.u(n), format('f%s@example.test', n) from generate_series(1, 7) n;
insert into public.profiles (id, username, display_name) select tests.u(n), 'fuser' || n, 'F' || n from generate_series(1, 7) n;

-- ===== baseline: RLS + no direct writes on the new tables ======================
select is(
  (select count(*)::int from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relkind = 'r' and not c.relrowsecurity
      and c.relname in ('friendships', 'friend_invites', 'journey_shares', 'journey_share_consents',
                        'saved_journeys', 'journey_views', 'conversations', 'messages', 'message_hides')),
  0, 'RLS is enabled on every social table');
select ok((select relrowsecurity from pg_class where oid = 'private.rate_events'::regclass),
  'RLS is enabled on private.rate_events');
select ok(
  not has_table_privilege('authenticated', 'public.friendships', 'insert')
  and not has_table_privilege('authenticated', 'public.friendships', 'update')
  and not has_table_privilege('authenticated', 'public.journey_shares', 'insert')
  and not has_table_privilege('authenticated', 'public.journey_share_consents', 'insert')
  and not has_table_privilege('authenticated', 'public.saved_journeys', 'insert')
  and not has_table_privilege('authenticated', 'public.conversations', 'insert')
  and not has_table_privilege('authenticated', 'public.messages', 'insert')
  and not has_table_privilege('authenticated', 'public.message_hides', 'insert'),
  'social tables are written only through RPCs');
select ok(
  not has_table_privilege('authenticated', 'public.friend_invites', 'select')
  and not has_table_privilege('authenticated', 'public.journey_views', 'select'),
  'friend_invites and journey_views are not readable by clients');
select ok(not has_function_privilege('authenticated', 'public.record_journey_view(uuid, text)', 'execute')
          and has_function_privilege('service_role', 'public.record_journey_view(uuid, text)', 'execute'),
  'record_journey_view is service_role only');
select ok(not has_function_privilege('authenticated', 'private.record_view(uuid, text)', 'execute'),
  'private writers are not callable by clients');

-- ===== username search =========================================================
do $$ begin perform tests.as_user(tests.u(1)); end $$;
select is((public.find_user_by_username('@FUser2')->>'user_id')::uuid, tests.u(2),
  'find_user_by_username: exact, case-insensitive, leading @ ignored');
select ok(public.find_user_by_username('fuser2')::jsonb ?& array['user_id', 'username', 'display_name', 'avatar_path'],
  'person JSON has user_id/username/display_name/avatar_path');
select ok(public.find_user_by_username('fuser1') is null, 'never returns the caller');
select ok(public.find_user_by_username('fuser') is null, 'no prefix match');
do $$ begin perform tests.as_user(tests.u(7)); end $$;
select lives_ok($$ select public.find_user_by_username('nobody' || g) from generate_series(1, 30) g $$,
  '30 lookups in an hour are allowed');
select throws_ok($$ select public.find_user_by_username('fuser1') $$, 'P0001', 'rate_limited',
  '31st lookup in an hour -> rate_limited');

-- ===== request / accept / decline =============================================
do $$ begin perform tests.as_user(tests.u(1)); end $$;
select throws_ok($$ select public.send_friend_request(tests.u(1)) $$, 'P0001', 'invalid', 'cannot befriend yourself');
select lives_ok($$ select public.send_friend_request(tests.u(2)) $$, 'u1 sends a request to u2');
select lives_ok($$ select public.send_friend_request(tests.u(2)) $$, 'sending again is idempotent');
select is((select count(*)::int from public.friendships), 1, 'requester reads the pair row');
select is((select f->>'direction' from public.my_friends() f), 'outgoing', 'my_friends: outgoing for the sender');
do $$ begin perform tests.as_user(tests.u(2)); end $$;
select results_eq($$ select f->>'status', f->>'direction', f->>'source', f->'person'->>'username' from public.my_friends() f $$,
  $$ values ('pending', 'incoming', 'direct', 'fuser1') $$, 'my_friends: incoming pending request');
select is((public.inbox_counts()->>'friend_requests')::int, 1, 'inbox_counts.friend_requests counts it');
do $$ begin perform tests.as_user(tests.u(3)); end $$;
select is((select count(*)::int from public.friendships), 0, 'third party cannot read the pair row');
select throws_ok($$ select public.respond_friend_request(tests.u(1), true) $$, 'P0001', 'not_found',
  'only the recipient can answer');
do $$ begin perform tests.as_user(tests.u(2)); end $$;
select lives_ok($$ select public.respond_friend_request(tests.u(1), true) $$, 'u2 accepts');
select is((tests.friend_row(1, 2)).status, 'accepted', 'pair is accepted');
select throws_ok($$ select public.respond_friend_request(tests.u(1), true) $$, 'P0001', 'not_found',
  'nothing pending any more');
select is((public.inbox_counts()->>'friend_requests')::int, 0, 'inbox cleared after accepting');

do $$ begin perform tests.as_user(tests.u(3)); perform public.send_friend_request(tests.u(1)); end $$;
do $$ begin perform tests.as_user(tests.u(1)); end $$;
select lives_ok($$ select public.respond_friend_request(tests.u(3), false) $$, 'u1 declines u3');
select ok((tests.friend_row(1, 3)).deleted_at is not null, 'decline is a soft delete');
do $$ begin perform tests.as_user(tests.u(3)); end $$;
select is((select count(*)::int from public.my_friends()), 0, 'declined request disappears');

do $$ begin perform tests.as_user(tests.u(4)); perform public.send_friend_request(tests.u(1)); end $$;
do $$ begin perform tests.as_user(tests.u(1)); end $$;
select lives_ok($$ select public.send_friend_request(tests.u(4)) $$, 'request back to a pending sender');
select is((tests.friend_row(1, 4)).status, 'accepted', 'crossing requests become friends at once');

-- ===== blocks ==================================================================
do $$ begin perform tests.as_user(tests.u(5)); perform public.block_user(tests.u(1)); end $$;
do $$ begin perform tests.as_user(tests.u(1)); end $$;
select throws_ok($$ select public.send_friend_request(tests.u(5)) $$, 'P0001', 'blocked', 'blocked pair -> blocked');
select ok(public.find_user_by_username('fuser5') is null, 'search hides a blocked user');
do $$ begin perform tests.as_user(tests.u(4)); perform public.block_user(tests.u(1)); end $$;
select ok((tests.friend_row(1, 4)).deleted_at is not null, 'blocking a friend ends the friendship');

-- ===== invite links ============================================================
do $$ begin perform tests.as_user(tests.u(6)); end $$;
select public.create_friend_invite() as tok1 \gset
select matches(:'tok1'::text, '^[a-z0-9]{12}$', 'create_friend_invite returns a 12-char token');
select public.create_friend_invite() as tok2 \gset
select isnt(:'tok1'::text, :'tok2'::text, 'creating again rotates the token');
select throws_ok(format('select public.accept_friend_invite(%L)', :'tok2'), 'P0001', 'invalid', 'own token -> invalid');
do $$ begin perform tests.as_user(tests.u(3)); end $$;
select throws_ok(format('select public.accept_friend_invite(%L)', :'tok1'), 'P0001', 'not_found', 'rotated token -> not_found');
select is((public.accept_friend_invite(:'tok2'))->>'username', 'fuser6', 'accept_friend_invite returns the inviter');
select is((tests.friend_row(3, 6)).status, 'accepted', 'invite makes both friends at once');
do $$ begin perform tests.as_user(tests.u(5)); end $$;
select is((select count(*)::int from public.profiles where id = tests.u(6)), 0, 'non-friend cannot read the profile');
do $$ begin perform tests.as_user(tests.u(3)); end $$;
select is((select count(*)::int from public.profiles where id = tests.u(6)), 1, 'friends can read each other''s profile');

-- ===== remove ==================================================================
select lives_ok($$ select public.remove_friend(tests.u(6)) $$, 'unfriend');
select is((select count(*)::int from public.my_friends()), 0, 'unfriended pair disappears from my_friends');

select * from finish();
rollback;
