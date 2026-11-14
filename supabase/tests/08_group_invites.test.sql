-- 0008_group_invites: code preview (no leaks, throttled) and the invitations feed.
-- Users: 1 owner, 2 invitee, 3 outsider, 4 blocked-by-owner, 5 joiner.
begin;
create extension if not exists pgtap with schema extensions;
select plan(22);

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
  select format('80000000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function tests.jid() returns uuid language sql immutable as $$
  select 'b8000000-0000-4000-8000-000000000001'::uuid $$;
create function tests.code() returns text language sql security definer as $$
  select invite_code from public.journeys where id = tests.jid() $$;
grant execute on all functions in schema tests to authenticated;

insert into auth.users (id, email) select tests.u(n), format('gi%s@example.test', n) from generate_series(1, 6) n;
insert into public.profiles (id, username, display_name) select tests.u(n), 'ginv' || n, 'G' || n from generate_series(1, 6) n;

do $$ begin perform tests.as_user(tests.u(1));
  perform public.create_journey(tests.jid(), 'group', 'custom', 'Hoi IELTS', '🔥', null, null, false,
                                current_date - 1, 30, 'UTC', 10, 'private'); end $$;

-- ===== schema + RLS ==========================================================
select ok((select relrowsecurity from pg_class where oid = 'public.group_invitations'::regclass),
  'RLS is enabled on group_invitations');
select ok(not has_table_privilege('authenticated', 'public.group_invitations', 'insert')
  and not has_table_privilege('authenticated', 'public.group_invitations', 'update')
  and not has_table_privilege('authenticated', 'public.group_invitations', 'delete')
  and has_table_privilege('authenticated', 'public.group_invitations', 'select'),
  'group_invitations is read-only for clients');
select ok(not has_function_privilege('anon', 'public.preview_group_by_code(text)', 'execute')
  and has_function_privilege('authenticated', 'public.accept_group_invitation(uuid)', 'execute'),
  'invite RPCs: authenticated only');

-- ===== preview ===============================================================
do $$ begin perform tests.as_user(tests.u(3)); end $$;
select is((public.preview_group_by_code(tests.code())->>'title'), 'Hoi IELTS', 'outsider previews a valid code');
select is((public.preview_group_by_code(lower(tests.code()))->>'state'), 'open', 'preview normalises case; state open');
select is((public.preview_group_by_code(tests.code())->>'member_count')::int, 1, 'preview shows the member count');
select ok(not ((public.preview_group_by_code(tests.code())::jsonb) ?| array['id', 'invite_code', 'owner_id', 'journey_id']),
  'preview leaks no ids or code');
select is((select count(*)::int from public.memberships where journey_id = tests.jid() and user_id = tests.u(3)), 0,
  'previewing does not join');
select is(public.preview_group_by_code('ZZZZZZZZ'), null, 'unknown code previews as null');
select is(public.preview_group_by_code('bad'), null, 'malformed code previews as null');

-- failed previews share the join throttle (10 failures / hour)
do $$ begin perform tests.as_user(tests.u(5)); end $$;
do $$ begin for i in 1..10 loop perform public.preview_group_by_code('ZZZZZZZ' || i); end loop; end $$;
select throws_ok($$ select public.preview_group_by_code(tests.code()) $$, 'P0001', 'rate_limited',
  'preview is throttled after 10 failed attempts');
select throws_ok($$ select public.join_by_code(tests.code()) $$, 'P0001', 'rate_limited',
  'and the same budget blocks join_by_code');

-- blocked user sees nothing
do $$ begin perform tests.as_user(tests.u(1)); perform public.block_user(tests.u(4)); end $$;
do $$ begin perform tests.as_user(tests.u(4)); end $$;
select is(public.preview_group_by_code(tests.code()), null, 'a user blocked by a member previews as null');

-- ===== invitations ===========================================================
do $$ begin perform tests.as_user(tests.u(3)); end $$;
select throws_ok($$ select public.send_group_invitation(tests.jid(), tests.u(2)) $$, '42501', 'forbidden',
  'only active members can invite');

do $$ begin perform tests.as_user(tests.u(1)); end $$;
select lives_ok($$ select public.send_group_invitation(tests.jid(), null, '@GInv2') $$, 'member invites by handle');
select throws_ok($$ select public.send_group_invitation(tests.jid(), tests.u(2)) $$, 'P0001', 'invalid',
  'a second pending invitation is refused');
select throws_ok($$ select public.send_group_invitation(tests.jid(), tests.u(4)) $$, 'P0001', 'not_found',
  'inviting a blocked user looks like an unknown user');

do $$ begin perform tests.as_user(tests.u(3)); end $$;
select is((select count(*)::int from public.group_invitations), 0, 'RLS hides invitations from third parties');
select is(json_array_length(public.my_group_invitations()), 0, 'feed of a third party is empty');

do $$ begin perform tests.as_user(tests.u(2)); end $$;
select is((public.my_group_invitations()->0->>'title'), 'Hoi IELTS', 'invitee sees the pending invitation');
select ok(not ((public.my_group_invitations()->0)::jsonb ? 'invite_code'), 'the feed never exposes the invite code');
select is(((public.accept_group_invitation((public.my_group_invitations()->0->>'id')::uuid)).id), tests.jid(),
  'accept joins the group via join_by_code');

select * from finish();
rollback;
