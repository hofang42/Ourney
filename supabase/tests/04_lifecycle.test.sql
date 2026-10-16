-- Group lifecycle (SRS §3.1 / 02 §9.1), limits, invites, public link, account deletion.
begin;
create extension if not exists pgtap with schema extensions;
select plan(51);

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
create function tests.uid(n int) returns uuid language sql immutable as $$
  select format('20000000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function tests.jid(n int) returns uuid language sql immutable as $$
  select format('b0000000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function tests.new_journey(n int, k public.journey_kind, vis public.journey_visibility default 'private')
returns public.journeys language sql as $$
  select * from public.create_journey(tests.jid(n), k, 'custom', 'J' || n, '🔥', null, null, false,
                                      current_date - 1, 30, 'UTC', 10, vis) $$;
create function tests.code(n int) returns text language sql security definer as $$
  select invite_code from public.journeys where id = tests.jid(n) $$;
create function tests.checkin(cid uuid, j uuid) returns void language sql as $$
  insert into public.check_ins (id, journey_id, user_id, local_date, captured_at, photo_path, thumb_path)
  values (cid, j, auth.uid(), current_date, now(),
          format('checkins/%s/%s/%s.jpg', j, auth.uid(), cid),
          format('checkins/%s/%s/%s_t.jpg', j, auth.uid(), cid)) $$;
grant execute on all functions in schema tests to authenticated;

insert into auth.users (id, email) select tests.uid(n), format('l%s@example.test', n) from generate_series(1, 14) n;
insert into public.profiles (id, username, display_name) select tests.uid(n), 'luser' || n, 'L' || n from generate_series(1, 14) n;

-- ===== ownership transfer, hide on leave, rejoin ===========================
-- journey 1: owner u1, then u2 joins, then u3 joins (joined_at forced to be ordered)
do $$ begin perform tests.as_user(tests.uid(1)); perform tests.new_journey(1, 'group');
             perform tests.checkin('d1000000-0000-4000-8000-000000000001', tests.jid(1)); end $$;
do $$ begin perform tests.as_user(tests.uid(3)); perform public.join_by_code(tests.code(1)); end $$;
do $$ begin perform tests.as_user(tests.uid(2)); perform public.join_by_code(tests.code(1)); end $$;
do $$ begin perform tests.as_postgres(); end $$;
update public.memberships set joined_at = now() - interval '1 day' where journey_id = tests.jid(1) and user_id = tests.uid(2);
update public.memberships set joined_at = now() - interval '2 days' where journey_id = tests.jid(1) and user_id = tests.uid(1);
insert into storage.objects (bucket_id, name)
values ('media', format('checkins/%s/%s/d1000000-0000-4000-8000-000000000001.jpg', tests.jid(1), tests.uid(1)));

do $$ begin perform tests.as_user(tests.uid(2)); end $$;
select throws_ok($$ select public.delete_journey(tests.jid(1)) $$, '42501', 'forbidden', 'member cannot delete the journey');
select throws_ok($$ select public.end_journey(tests.jid(1)) $$, '42501', 'forbidden', 'member cannot end the journey');
select throws_ok($$ select public.remove_member(tests.jid(1), tests.uid(3)) $$, '42501', 'forbidden', 'member cannot remove members');
select is((select count(*)::int from storage.objects where bucket_id = 'media'), 1, 'member reads owner media before leave');

do $$ begin perform tests.as_user(tests.uid(1)); end $$;
select throws_ok($$ select public.delete_journey(tests.jid(1)) $$, 'P0001', 'not_alone',
  'owner cannot delete while other members remain (only end)');
select lives_ok($$ select public.leave_journey(tests.jid(1)) $$, 'owner leaves');

do $$ begin perform tests.as_postgres(); end $$;
select is((select owner_id from public.journeys where id = tests.jid(1)), tests.uid(2),
  'ownership goes to the earliest joined active member');
select results_eq(
  $$ select user_id, role::text, status::text from public.memberships where journey_id = tests.jid(1) order by user_id $$,
  $$ values (tests.uid(1), 'member', 'left'), (tests.uid(2), 'owner', 'active'), (tests.uid(3), 'member', 'active') $$,
  'roles after owner leaves');
select ok((select deleted_at is not null and hidden_by_leave from public.check_ins where id = 'd1000000-0000-4000-8000-000000000001'),
  'leaver''s check-ins are hidden (soft-deleted, flagged)');

do $$ begin perform tests.as_user(tests.uid(2)); end $$;
select is((select count(*)::int from public.check_ins where deleted_at is null), 0, 'members no longer see the leaver''s check-in');
select is((select count(*)::int from storage.objects where bucket_id = 'media'), 0, 'members no longer read the leaver''s media');
do $$ begin perform tests.as_user(tests.uid(1)); end $$;
select is((select count(*)::int from public.check_ins), 1, 'leaver still sees own check-in row');
select is((select count(*)::int from public.journeys), 0, 'leaver no longer sees the journey');
select throws_ok($$ select tests.checkin('d1000000-0000-4000-8000-000000000002', tests.jid(1)) $$, 'P0001', 'not_found',
  'leaver cannot post');

select lives_ok($$ select public.join_by_code(tests.code(1)) $$, 'leaver rejoins with the code');
do $$ begin perform tests.as_postgres(); end $$;
select ok((select deleted_at is null and not hidden_by_leave from public.check_ins where id = 'd1000000-0000-4000-8000-000000000001'),
  'rejoin restores hidden check-ins');
select ok((select role = 'member' and joined_at < now() - interval '1 day'
             from public.memberships where journey_id = tests.jid(1) and user_id = tests.uid(1)),
  'rejoin keeps the original joined_at and does not restore ownership');

-- remove member + idempotent join
do $$ begin perform tests.as_user(tests.uid(2)); end $$;
select lives_ok($$ select public.remove_member(tests.jid(1), tests.uid(3)) $$, 'owner removes a member');
select is((select status::text from public.memberships where journey_id = tests.jid(1) and user_id = tests.uid(3)), 'left',
  'removed member is marked left');
do $$ begin perform tests.as_user(tests.uid(1)); end $$;
select lives_ok($$ select public.join_by_code(tests.code(1)) $$, 'join_by_code is idempotent for active members');
select is((select id from public.join_by_code('ZZZZZZZZ')), null, 'unknown code -> empty row (not_found)');
select is((select id from public.join_by_code('bad')), null, 'malformed code -> empty row (not_found)');

-- ===== invite rotation ======================================================
do $$ begin perform tests.as_postgres(); end $$;
select tests.code(1) as old_code \gset
do $$ begin perform tests.as_user(tests.uid(1)); end $$;
select throws_ok($$ select public.rotate_invite(tests.jid(1)) $$, '42501', 'forbidden', 'non-owner cannot rotate');
do $$ begin perform tests.as_user(tests.uid(2)); end $$;
select matches(public.rotate_invite(tests.jid(1)), '^[A-Z0-9]{8}$', 'owner rotates the invite code');
do $$ begin perform tests.as_user(tests.uid(4)); end $$;
select is((select id from public.join_by_code(:'old_code')), null, 'old code stops working (not_found)');
select lives_ok($$ select public.join_by_code(tests.code(1)) $$, 'new code works');

-- ===== block prevents join (either direction) ================================
do $$ begin perform tests.as_user(tests.uid(5)); perform public.block_user(tests.uid(2)); end $$;
select throws_ok($$ select public.join_by_code(tests.code(1)) $$, 'P0001', 'blocked', 'blocker cannot join a group with the blocked user');
do $$ begin perform tests.as_user(tests.uid(2)); perform public.block_user(tests.uid(6)); end $$;
do $$ begin perform tests.as_user(tests.uid(6)); end $$;
select throws_ok($$ select public.join_by_code(tests.code(1)) $$, 'P0001', 'blocked', 'blocked user cannot join the blocker''s group');
do $$ begin perform tests.as_user(tests.uid(2)); perform public.unblock_user(tests.uid(6)); end $$;
do $$ begin perform tests.as_user(tests.uid(6)); end $$;
select lives_ok($$ select public.join_by_code(tests.code(1)) $$, 'unblock allows joining again');

-- ===== max 10 members ========================================================
-- journey 1 now has u1,u2,u4,u6 active -> add u7..u12 (10), u13 must fail
do $$ begin for i in 7..12 loop perform tests.as_user(tests.uid(i)); perform public.join_by_code(tests.code(1)); end loop; end $$;
do $$ begin perform tests.as_postgres(); end $$;
select is((select count(*)::int from public.memberships where journey_id = tests.jid(1) and status = 'active'), 10, '10 active members');
do $$ begin perform tests.as_user(tests.uid(13)); end $$;
select throws_ok($$ select public.join_by_code(tests.code(1)) $$, 'P0001', 'full', '11th member -> full');

-- ===== max 3 active journeys =================================================
do $$ begin perform tests.as_user(tests.uid(13));
  perform tests.new_journey(131, 'solo'); perform tests.new_journey(132, 'solo'); perform tests.new_journey(133, 'group'); end $$;
select throws_ok($$ select tests.new_journey(134, 'solo') $$, 'P0001', 'limit', '4th active journey -> limit');
do $$ begin perform tests.as_user(tests.uid(14)); perform tests.new_journey(141, 'group'); end $$;
do $$ begin perform tests.as_user(tests.uid(13)); end $$;
select throws_ok($$ select public.join_by_code(tests.code(141)) $$, 'P0001', 'limit', 'joining as a 4th active journey -> limit');
select lives_ok($$ select public.create_journey(tests.jid(131), 'solo', 'custom', 'J', '🔥', null, null, false, current_date, 30, 'UTC') $$,
  'create_journey is idempotent for the same id (offline retry), even at the limit');
select lives_ok($$ select public.end_journey(tests.jid(131)) $$, 'owner ends a journey');
select lives_ok($$ select tests.new_journey(134, 'solo') $$, 'ending frees a slot');
select throws_ok($$ select tests.checkin('d1300000-0000-4000-8000-000000000001', tests.jid(131)) $$, 'P0001', 'ended',
  'ended journey is read-only');
do $$ begin perform tests.as_user(tests.uid(14)); perform public.end_journey(tests.jid(141)); end $$;
do $$ begin perform tests.as_user(tests.uid(12)); end $$;
select throws_ok($$ select public.join_by_code(tests.code(141)) $$, 'P0001', 'ended', 'cannot join an ended journey');

-- ===== delete only when alone, last leaver archives ===========================
do $$ begin perform tests.as_user(tests.uid(13)); end $$;
select lives_ok($$ select public.delete_journey(tests.jid(132)) $$, 'owner alone may delete');
select ok((select deleted_at is not null from public.journeys where id = tests.jid(132)), 'deleted journey is soft-deleted');
select lives_ok($$ select public.leave_journey(tests.jid(133)) $$, 'sole member leaves a group');
do $$ begin perform tests.as_postgres(); end $$;
select is((select status::text from public.journeys where id = tests.jid(133)), 'archived', 'journey with nobody left is archived');

-- ===== visibility / public link (solo only) ===================================
do $$ begin perform tests.as_user(tests.uid(14)); end $$;
select throws_ok($$ select tests.new_journey(142, 'group', 'link') $$, 'P0001', 'invalid', 'group journey can never be link-visible');
select is((select visibility::text from tests.new_journey(143, 'solo', 'link')), 'link', 'solo journey can be link-visible');
select throws_ok($$ select public.set_public_link(tests.jid(141), true) $$, 'P0001', 'invalid', 'set_public_link rejects groups');
select is(public.set_public_link(tests.jid(143), false), null, 'public link can be revoked');
do $$ begin perform tests.as_postgres(); end $$;
select ok((select visibility = 'private' and public_token is null from public.journeys where id = tests.jid(143)),
  'revoked link clears the token');

-- ===== account deletion =======================================================
-- u2 owns journey 1 (with other members) -> ownership moves to the earliest member (u1);
-- u14 owns solo journey 143 -> deleted with the account.
do $$ begin perform tests.as_postgres(); end $$;
insert into storage.objects (bucket_id, name) values
  ('media', format('avatars/%s/e0000000-0000-4000-8000-000000000001.jpg', tests.uid(14))),
  ('media', format('checkins/%s/%s/e0000000-0000-4000-8000-000000000002.jpg', tests.jid(143), tests.uid(14))),
  ('media', format('checkins/%s/%s/e0000000-0000-4000-8000-000000000003.jpg', tests.jid(1), tests.uid(1)));
select is(
  (select array_agg(p order by p) from public.account_media_paths(tests.uid(14)) p),
  array[format('avatars/%s/e0000000-0000-4000-8000-000000000001.jpg', tests.uid(14)),
        format('checkins/%s/%s/e0000000-0000-4000-8000-000000000002.jpg', tests.jid(143), tests.uid(14))],
  'account_media_paths lists the user''s avatar and check-in objects only');
delete from auth.users where id = tests.uid(2);
select is((select owner_id from public.journeys where id = tests.jid(1)), tests.uid(1),
  'deleting the owner''s account transfers ownership to the earliest joined member');
select is((select count(*)::int from public.memberships where journey_id = tests.jid(1) and role = 'owner' and status = 'active'), 1,
  'exactly one active owner after account deletion');
delete from auth.users where id = tests.uid(14);
select is((select count(*)::int from public.journeys where id in (tests.jid(141), tests.jid(143))), 0,
  'journeys owned by a deleted user with no other active member are removed');

select * from finish();
rollback;
