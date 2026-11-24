-- 0025_invite_previews: pgTAP tests for public.preview_friend_invite and public.preview_group_invite.
-- Covers: anon & authenticated grants, SECURITY DEFINER + search_path='', valid preview,
-- invalid format, unknown token/code, soft-deleted owner, banned owner, privacy flags,
-- and strict key whitelist (no user_id, email, avatar_path, or journey_id leaked).
begin;
create extension if not exists pgtap with schema extensions;
select plan(26);

create schema tests;
grant usage on schema tests to anon, authenticated, service_role;

create function tests.as_user(u uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', u, 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);
end $$;

create function tests.as_anon() returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', '{"role":"anon"}', true);
  perform set_config('role', 'anon', true);
end $$;

create function tests.as_postgres() returns void language plpgsql as $$
begin
  perform set_config('role', 'postgres', true);
  perform set_config('request.jwt.claims', '', true);
end $$;

create function tests.u(n int) returns uuid language sql immutable as $$
  select format('25000000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;

create function tests.jid(n int) returns uuid language sql immutable as $$
  select format('b2500000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;

create function tests.friend_token(u_num int) returns text language sql security definer as $$
  select token from public.friend_invites where user_id = tests.u(u_num) $$;

create function tests.group_code(j_num int) returns text language sql security definer as $$
  select invite_code from public.journeys where id = tests.jid(j_num) $$;

grant execute on all functions in schema tests to anon, authenticated, service_role;

-- Seed users:
--   1: valid inviter / squad owner (with avatar_path set to ensure it is never leaked)
--   2: squad co-member
--   3: soft-deleted inviter / squad owner
--   4: banned inviter / squad owner
insert into auth.users (id, email)
select tests.u(n), format('ip%s@example.test', n)
  from generate_series(1, 4) n;

insert into public.profiles (id, username, display_name, avatar_path)
values
  (tests.u(1), 'minh_anh', 'Minh Anh', format('avatars/%s/aaaaaaaa-0000-4000-8000-000000000001.jpg', tests.u(1))),
  (tests.u(2), 'thanh_ha', 'Thanh Hà', null),
  (tests.u(3), 'deleted_user', 'Người Đã Xóa', null),
  (tests.u(4), 'banned_user', 'Người Bị Khóa', null);

-- Create friend invites and group journeys before soft-deleting u(3) and banning u(4)
do $$
begin
  perform tests.as_user(tests.u(1));
  perform public.create_friend_invite();
  perform public.create_journey(
    tests.jid(1), 'group', 'english_daily', 'Hội IELTS 7.5', '📚',
    null, null, false, current_date, 30, 'UTC', 8, 'group'
  );

  perform tests.as_user(tests.u(2));
  perform public.join_by_code(tests.group_code(1));

  perform tests.as_user(tests.u(3));
  perform public.create_friend_invite();
  perform public.create_journey(
    tests.jid(3), 'group', 'workout_30', 'Squad Chủ Đã Xóa', '🔥',
    null, null, false, current_date, 30, 'UTC', 10, 'group'
  );

  perform tests.as_user(tests.u(4));
  perform public.create_friend_invite();
  perform public.create_journey(
    tests.jid(4), 'group', 'custom', 'Squad Chủ Bị Khóa', '⚡',
    null, null, false, current_date, 30, 'UTC', 10, 'group'
  );

  perform tests.as_postgres();
  -- Soft-delete u(3)
  update public.profiles set deleted_at = now() where id = tests.u(3);
  -- Ban u(4) via private.user_moderation
  insert into private.user_moderation (user_id, banned_at, ban_reason)
  values (tests.u(4), now(), 'Spam invite links');
end $$;

-- ===== 1. Grants & security definer metadata ==================================
select ok(
  has_function_privilege('anon', 'public.preview_friend_invite(text)', 'execute')
  and has_function_privilege('authenticated', 'public.preview_friend_invite(text)', 'execute'),
  'preview_friend_invite is executable by anon and authenticated'
);

select ok(
  has_function_privilege('anon', 'public.preview_group_invite(text)', 'execute')
  and has_function_privilege('authenticated', 'public.preview_group_invite(text)', 'execute'),
  'preview_group_invite is executable by anon and authenticated'
);

select ok(
  (select bool_and(p.prosecdef and 'search_path=""' = any(p.proconfig))
     from pg_proc p
    where p.oid in (
      'public.preview_friend_invite(text)'::regprocedure,
      'public.preview_group_invite(text)'::regprocedure
    )),
  'both preview RPCs are SECURITY DEFINER with search_path = '''''
);

-- ===== 2. preview_friend_invite as anon =======================================
do $$ begin perform tests.as_anon(); end $$;

select is(
  public.preview_friend_invite(tests.friend_token(1)) ->> 'display_name',
  'Minh Anh',
  'anon preview_friend_invite returns inviter display_name'
);

select is(
  public.preview_friend_invite('  ' || upper(tests.friend_token(1)) || ' ') ->> 'handle',
  'minh_anh',
  'anon preview_friend_invite trims and case-folds token and returns handle'
);

select is(
  public.preview_friend_invite(tests.friend_token(1)) ->> 'avatar_initial',
  'M',
  'anon preview_friend_invite returns uppercase avatar_initial'
);

select is(
  (select array_agg(k order by k)
     from jsonb_object_keys(public.preview_friend_invite(tests.friend_token(1))::jsonb) as k),
  array['avatar_initial', 'display_name', 'handle'],
  'preview_friend_invite leaks no extra keys (no user_id, email, avatar_path, or token)'
);

select ok(
  public.preview_friend_invite(null) is null
  and public.preview_friend_invite('') is null
  and public.preview_friend_invite('short123') is null
  and public.preview_friend_invite('toolong1234567') is null
  and public.preview_friend_invite('bad!token123') is null,
  'preview_friend_invite returns null for invalid token formats'
);

select ok(
  public.preview_friend_invite('zzzzzzzzzzzz') is null,
  'preview_friend_invite returns null for unknown valid-format token'
);

select ok(
  public.preview_friend_invite(tests.friend_token(3)) is null,
  'preview_friend_invite returns null when inviter profile is soft-deleted'
);

select ok(
  public.preview_friend_invite(tests.friend_token(4)) is null,
  'preview_friend_invite returns null when inviter is banned'
);

-- Rotated token stops previewing immediately
do $$
begin
  perform tests.as_postgres();
  insert into public.friend_invites (user_id, token)
  values (tests.u(2), 'aaaaaaaaaaaa')
  on conflict (user_id) do update set token = excluded.token;
  perform tests.as_user(tests.u(2));
  perform public.create_friend_invite();
  perform tests.as_anon();
end $$;

select ok(
  public.preview_friend_invite('aaaaaaaaaaaa') is null,
  'preview_friend_invite returns null for a rotated old token'
);

select is(
  public.preview_friend_invite(tests.friend_token(2)) ->> 'display_name',
  'Thanh Hà',
  'preview_friend_invite resolves the new rotated token'
);

-- ===== 3. preview_group_invite as anon ========================================
do $$ begin perform tests.as_anon(); end $$;

select is(
  public.preview_group_invite(tests.group_code(1)) ->> 'title',
  'Hội IELTS 7.5',
  'anon preview_group_invite returns group title'
);

select is(
  (public.preview_group_invite('  ' || lower(tests.group_code(1)) || ' ') ->> 'member_count')::int,
  2,
  'anon preview_group_invite trims/uppercases code and returns active member_count'
);

select is(
  (public.preview_group_invite(tests.group_code(1)) ->> 'max_members')::int,
  8,
  'anon preview_group_invite returns max_members'
);

select is(
  public.preview_group_invite(tests.group_code(1)) ->> 'inviter_display_name',
  'Minh Anh',
  'anon preview_group_invite returns inviter_display_name'
);

select is(
  (select array_agg(k order by k)
     from jsonb_object_keys(public.preview_group_invite(tests.group_code(1))::jsonb) as k),
  array['inviter_display_name', 'max_members', 'member_count', 'title'],
  'preview_group_invite leaks no extra keys (no id, owner_id, invite_code, avatar_path, or members)'
);

select ok(
  public.preview_group_invite(null) is null
  and public.preview_group_invite('') is null
  and public.preview_group_invite('SHORT') is null
  and public.preview_group_invite('TOOLONG12') is null
  and public.preview_group_invite('BAD!CODE') is null,
  'preview_group_invite returns null for invalid code formats'
);

select ok(
  public.preview_group_invite('ZZZZZZZZ') is null,
  'preview_group_invite returns null for unknown valid-format code'
);

select ok(
  public.preview_group_invite(tests.group_code(3)) is null,
  'preview_group_invite returns null when group owner profile is soft-deleted'
);

select ok(
  public.preview_group_invite(tests.group_code(4)) is null,
  'preview_group_invite returns null when group owner is banned'
);

-- Respects journey share consent withdrawal (owner display_name hidden if consent declined/withdrawn)
do $$
begin
  perform tests.as_postgres();
  insert into public.journey_share_consents (journey_id, user_id, status, requested_by, decided_at)
  values (tests.jid(1), tests.u(1), 'withdrawn', tests.u(1), now());
  perform tests.as_anon();
end $$;

select is(
  public.preview_group_invite(tests.group_code(1)) ->> 'inviter_display_name',
  null,
  'preview_group_invite omits inviter_display_name when owner withdrew share consent'
);

-- Ended journey no longer previews as an active invite
do $$
begin
  perform tests.as_postgres();
  update public.journeys set status = 'ended' where id = tests.jid(1);
  perform tests.as_anon();
end $$;

select ok(
  public.preview_group_invite(tests.group_code(1)) is null,
  'preview_group_invite returns null when the group journey has ended'
);

-- Restore jid(1) active state and verify authenticated blocked caller sees null
do $$
begin
  perform tests.as_postgres();
  update public.journeys set status = 'active' where id = tests.jid(1);
  perform tests.as_user(tests.u(1));
  perform public.block_user(tests.u(2));
  perform tests.as_user(tests.u(2));
end $$;

select ok(
  public.preview_friend_invite(tests.friend_token(1)) is null,
  'authenticated user blocked by inviter gets null from preview_friend_invite'
);

select ok(
  public.preview_group_invite(tests.group_code(1)) is null,
  'authenticated user blocked by group member gets null from preview_group_invite'
);

select * from finish();
rollback;
