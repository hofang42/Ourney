-- 0010_invite_management: revoke, pending list, couple rename, inbox dot.
-- Users: 1 owner, 2 member, 3 invitee, 4 outsider.
begin;
create extension if not exists pgtap with schema extensions;
select plan(19);

create schema tests;
grant usage on schema tests to authenticated;
create function tests.as_user(u uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', u, 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);
end $$;
create function tests.u(n int) returns uuid language sql immutable as $$
  select format('a0000000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function tests.jid() returns uuid language sql immutable as $$
  select 'b1000000-0000-4000-8000-000000000001'::uuid $$;
create function tests.cid() returns uuid language sql immutable as $$
  select 'b1000000-0000-4000-8000-000000000002'::uuid $$;
create function tests.code() returns text language sql security definer as $$
  select invite_code from public.journeys where id = tests.jid() $$;
create function tests.inv(target int) returns uuid language sql security definer as $$
  select id from public.group_invitations where journey_id = tests.jid() and invitee_id = tests.u(target)
   order by created_at desc limit 1 $$;
grant execute on all functions in schema tests to authenticated;

insert into auth.users (id, email) select tests.u(n), format('im%s@example.test', n) from generate_series(1, 4) n;
insert into public.profiles (id, username, display_name) select tests.u(n), 'imgr' || n, 'M' || n from generate_series(1, 4) n;

do $$ begin perform tests.as_user(tests.u(1));
  perform public.create_journey(tests.jid(), 'group', 'custom', 'Hoi', '🔥', null, null, false,
                                current_date - 1, 30, 'UTC', 10, 'private');
  perform public.create_journey(tests.cid(), 'group', 'custom', 'Duo', '💞', null, null, false,
                                current_date, 30, 'UTC', 2, 'private', 'An', 'Binh'); end $$;
do $$ begin perform tests.as_user(tests.u(2)); perform public.join_by_code(tests.code()); end $$;

select ok(not has_function_privilege('anon', 'public.revoke_group_invitation(uuid)', 'execute')
  and not has_function_privilege('anon', 'public.rename_couple(uuid, text, text)', 'execute')
  and has_function_privilege('authenticated', 'public.journey_pending_invitations(uuid)', 'execute'),
  'new RPCs: authenticated only');
select ok(not exists (select 1 from pg_constraint
                       where conrelid = 'public.group_invitations'::regclass
                         and pg_get_constraintdef(oid) like '%''code''%'),
  'the code kind is gone from group_invitations');

-- member 2 invites user 3
do $$ begin perform tests.as_user(tests.u(2)); perform public.send_group_invitation(tests.jid(), tests.u(3)); end $$;
select is(json_array_length(public.journey_pending_invitations(tests.jid())), 1, 'member lists pending invitations');
select is((public.journey_pending_invitations(tests.jid())->0->'invitee'->>'username'), 'imgr3', 'list names the invitee');

do $$ begin perform tests.as_user(tests.u(4)); end $$;
select throws_ok($$ select public.journey_pending_invitations(tests.jid()) $$, '42501', 'forbidden',
  'outsiders cannot list');
select throws_ok($$ select public.revoke_group_invitation(tests.inv(3)) $$, 'P0001', 'not_found',
  'outsider cannot revoke');

-- inbox dot for the invitee
do $$ begin perform tests.as_user(tests.u(3)); end $$;
select is((public.inbox_counts()->>'group_invitations')::int, 1, 'inbox_counts counts group invitations');
select ok((public.inbox_counts()::jsonb) ?& array['friend_requests', 'public_requests', 'new_shares',
  'unread_messages', 'consent_requests'], 'old inbox keys kept');
select throws_ok($$ select public.revoke_group_invitation(tests.inv(3)) $$, 'P0001', 'not_found',
  'the invitee cannot revoke');

-- owner (not the inviter) revokes
do $$ begin perform tests.as_user(tests.u(1)); end $$;
select is((public.journey_pending_invitations(tests.jid())->0->>'can_revoke')::boolean, true, 'owner may revoke');
select lives_ok($$ select public.revoke_group_invitation(tests.inv(3)) $$, 'owner revokes');
select throws_ok($$ select public.revoke_group_invitation(tests.inv(3)) $$, 'P0001', 'not_found',
  'revoking twice is not_found');
select is(json_array_length(public.journey_pending_invitations(tests.jid())), 0, 'revoked is no longer listed');
do $$ begin perform tests.as_user(tests.u(3)); end $$;
select is((public.inbox_counts()->>'group_invitations')::int, 0, 'revoked invitation clears the dot');
select throws_ok($$ select public.accept_group_invitation(tests.inv(3)) $$, 'P0001', 'not_found',
  'a revoked invitation cannot be accepted');
do $$ begin perform tests.as_user(tests.u(2)); end $$;
select lives_ok($$ select public.send_group_invitation(tests.jid(), tests.u(3)) $$, 're-inviting after a revoke works');

-- couple rename
select throws_ok($$ select public.rename_couple(tests.cid(), 'X', 'Y') $$, '42501', 'forbidden',
  'non-owner cannot rename');
do $$ begin perform tests.as_user(tests.u(1)); end $$;
select is((public.rename_couple(tests.cid(), '  Lan ', 'Minh')).couple_self_name, 'Lan', 'owner renames (trimmed)');
select throws_ok($$ select public.rename_couple(tests.jid(), 'A', 'B') $$, 'P0001', 'invalid',
  'not a couple journey');

select * from finish();
rollback;
