-- UX-38: block list identity is authorized at block time and redacted on read.
begin;
create extension if not exists pgtap with schema extensions;
select plan(13);

create schema tests;
grant usage on schema tests to authenticated;

create function tests.as_user(u uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', u, 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);
end $$;

create function tests.u(n int) returns uuid language sql immutable as $$
  select format('29000001-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;

create function tests.blocked_row(n int) returns jsonb language sql stable as $$
  select b from jsonb_array_elements(public.my_blocked_people()::jsonb) b
   where b->>'user_id' = tests.u(n)::text $$;

create function tests.redacted_row(n int) returns jsonb language sql stable as $$
  select jsonb_build_object(
    'user_id', tests.u(n), 'username', null, 'display_name', null, 'avatar_path', null
  ) $$;

grant execute on all functions in schema tests to authenticated;

insert into auth.users (id, email)
select tests.u(n), format('blocked%s@example.test', n) from generate_series(1, 8) n;
insert into public.profiles (id, username, display_name, avatar_path)
select tests.u(n), 'blockeduser' || n, 'Blocked User ' || n,
       format('avatars/%s/%s.jpg', tests.u(n), tests.u(n))
  from generate_series(1, 8) n;

-- 2 is a friend, 3 a stranger, 4 will block back, 5 will delete, 6 will be
-- banned, 7 was blocked before snapshots existed, 8 is an unrelated caller.
insert into public.friendships (user_low, user_high, requested_by, status, accepted_at)
select tests.u(1), tests.u(n), tests.u(n), 'accepted', now()
  from unnest(array[2, 4, 5, 6]) n;
insert into public.blocks (blocker_id, blocked_id) values (tests.u(1), tests.u(7));

select ok(
  not has_table_privilege('authenticated', 'private.blocked_profile_names', 'select'),
  'authenticated cannot read stored names directly'
);

do $$ begin perform tests.as_user(tests.u(1));
  perform public.block_user(tests.u(n)) from unnest(array[2, 3, 4, 5, 6]) n;
end $$;

select is(
  tests.blocked_row(2),
  jsonb_build_object('user_id', tests.u(2), 'username', 'blockeduser2',
                     'display_name', 'Blocked User 2', 'avatar_path', null),
  'a known friend has a name and handle without an avatar path'
);
select is(tests.blocked_row(3), tests.redacted_row(3),
  'blocking a stranger by ID returns no private identity and preserves the unblock target');
select is(tests.blocked_row(7), tests.redacted_row(7),
  'a legacy block with no snapshot returns no live profile identity');

do $$ begin perform tests.as_user(tests.u(2)); end $$;
update public.profiles set username = 'renameduser2', display_name = 'Renamed User 2'
 where id = tests.u(2);
do $$ begin perform tests.as_user(tests.u(4));
  perform public.block_user(tests.u(1));
end $$;
select is(tests.blocked_row(1), tests.redacted_row(1),
  'blocking an existing blocker does not show their identity');

reset role;
update public.profiles set deleted_at = now() where id = tests.u(5);
insert into private.user_moderation (user_id, banned_at, ban_reason)
values (tests.u(6), now(), 'Banned test user');

do $$ begin perform tests.as_user(tests.u(1));
  perform public.block_user(tests.u(2)); -- Idempotent retry preserves the snapshot.
end $$;
select is(
  tests.blocked_row(2),
  jsonb_build_object('user_id', tests.u(2), 'username', 'blockeduser2',
                     'display_name', 'Blocked User 2', 'avatar_path', null),
  'live profile changes and block retries preserve the original snapshot'
);
select is(tests.blocked_row(4), tests.redacted_row(4),
  'a reciprocal block redacts a previously visible identity');
select is(tests.blocked_row(5), tests.redacted_row(5),
  'a soft-deleted target redacts a previously visible identity');
select is(tests.blocked_row(6), tests.redacted_row(6),
  'a banned target redacts a previously visible identity');

do $$ begin perform tests.as_user(tests.u(4));
  perform public.unblock_user(tests.u(1));
  perform tests.as_user(tests.u(1));
end $$;
select is(tests.blocked_row(4)->>'username', 'blockeduser4',
  'a reversed block that was lifted no longer hides the original snapshot');

do $$ begin perform tests.as_user(tests.u(8)); end $$;
select is(json_array_length(public.my_blocked_people()), 0,
  'a third party sees no other users'' block rows');

do $$ begin perform tests.as_user(tests.u(1));
  perform public.unblock_user(tests.u(2));
end $$;
select is(tests.blocked_row(2), null::jsonb, 'unblocking removes the row from the list');

do $$ begin perform public.block_user(tests.u(2)); end $$;
select is(tests.blocked_row(2), tests.redacted_row(2),
  'reblocking without the severed friendship cannot expose the previous snapshot');

select * from finish();
rollback;
