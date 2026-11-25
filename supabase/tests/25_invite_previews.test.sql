-- 0025_invite_previews: pgTAP tests for public.preview_friend_invite and public.preview_group_invite.
-- Covers: anon & authenticated grants, SECURITY DEFINER + search_path='' + VOLATILE,
-- private.invite_preview_attempts RLS/grants, valid preview, emoji-prefixed display_name initial,
-- invalid format, unknown token/code, soft-deleted owner, banned owner, privacy flags
-- (pending/withdrawn share consent), strict key whitelist (owner_display_name, no user_id/email/avatar_path/journey_id),
-- authenticated join_attempts + rate_events budget sharing with join_by_code/preview_group_by_code,
-- and anonymous salted SHA-256 IP hash failed-lookup rate limiting.
begin;
create extension if not exists pgtap with schema extensions;
select plan(43);

create schema tests;
grant usage on schema tests to anon, authenticated, service_role;

create function tests.as_user(u uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', u, 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);
end $$;

create function tests.as_anon(p_ip text default '203.0.113.10') returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', '{"role":"anon"}', true);
  perform set_config('request.headers', json_build_object('cf-connecting-ip', p_ip)::text, true);
  perform set_config('role', 'anon', true);
end $$;

create function tests.as_postgres() returns void language plpgsql as $$
begin
  perform set_config('role', 'postgres', true);
  perform set_config('request.jwt.claims', '', true);
  perform set_config('request.headers', '', true);
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
--   5: rate-limit test user (authenticated)
insert into auth.users (id, email)
select tests.u(n), format('ip%s@example.test', n)
  from generate_series(1, 5) n;

insert into public.profiles (id, username, display_name, avatar_path)
values
  (tests.u(1), 'minh_anh', 'Minh Anh', format('avatars/%s/aaaaaaaa-0000-4000-8000-000000000001.jpg', tests.u(1))),
  (tests.u(2), 'thanh_ha', 'Thanh Hà', null),
  (tests.u(3), 'deleted_user', 'Người Đã Xóa', null),
  (tests.u(4), 'banned_user', 'Người Bị Khóa', null),
  (tests.u(5), 'throttled_user', '🐻 Gấu', null);

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

  perform tests.as_user(tests.u(5));
  perform public.create_friend_invite();

  perform tests.as_postgres();
  -- Soft-delete u(3)
  update public.profiles set deleted_at = now() where id = tests.u(3);
  -- Ban u(4) via private.user_moderation
  insert into private.user_moderation (user_id, banned_at, ban_reason)
  values (tests.u(4), now(), 'Spam invite links');
end $$;

-- ===== 1. Grants, volatility & security definer metadata ======================
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
  (select bool_and(p.prosecdef and p.provolatile = 'v' and 'search_path=""' = any(p.proconfig))
     from pg_proc p
    where p.oid in (
      'public.preview_friend_invite(text)'::regprocedure,
      'public.preview_group_invite(text)'::regprocedure
    )),
  'both preview RPCs are VOLATILE, SECURITY DEFINER with search_path = '''''
);

select ok(
  (select relrowsecurity from pg_class where oid = 'private.invite_preview_attempts'::regclass)
  and to_regclass('private.invite_preview_attempts_ip_kind_idx') is not null
  and to_regclass('private.invite_preview_attempts_created_at_idx') is not null
  and not has_table_privilege('anon', 'private.invite_preview_attempts', 'select')
  and not has_table_privilege('authenticated', 'private.invite_preview_attempts', 'select')
  and not has_function_privilege('anon', 'private.caller_ip_hash(text)', 'execute')
  and not has_function_privilege('authenticated', 'private.caller_ip_hash(text)', 'execute'),
  'private.invite_preview_attempts has RLS and cleanup indexes enabled and neither table nor caller_ip_hash is exposed to anon/authenticated'
);

-- ===== 2. preview_friend_invite as anon =======================================
do $$ begin perform tests.as_anon('203.0.113.10'); end $$;

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
  public.preview_friend_invite(tests.friend_token(5)) ->> 'avatar_initial',
  'G',
  'preview_friend_invite extracts clean alphanumeric initial when display_name starts with an emoji'
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
  perform tests.as_anon('203.0.113.10');
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
do $$ begin perform tests.as_anon('203.0.113.10'); end $$;

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
  public.preview_group_invite(tests.group_code(1)) ->> 'owner_display_name',
  'Minh Anh',
  'anon preview_group_invite returns owner_display_name'
);

select is(
  (select array_agg(k order by k)
     from jsonb_object_keys(public.preview_group_invite(tests.group_code(1))::jsonb) as k),
  array['max_members', 'member_count', 'owner_display_name', 'title'],
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

-- Respects journey share consent pending/declined/withdrawn (owner_display_name hidden unless accepted)
do $$
begin
  perform tests.as_postgres();
  insert into public.journey_share_consents (journey_id, user_id, status, requested_by)
  values (tests.jid(1), tests.u(1), 'pending', tests.u(2));
  perform tests.as_anon('203.0.113.10');
end $$;

select is(
  public.preview_group_invite(tests.group_code(1)) ->> 'owner_display_name',
  null,
  'preview_group_invite omits owner_display_name when owner share consent is pending'
);

do $$
begin
  perform tests.as_postgres();
  update public.journey_share_consents
     set status = 'withdrawn', decided_at = now()
   where journey_id = tests.jid(1) and user_id = tests.u(1);
  perform tests.as_anon('203.0.113.10');
end $$;

select is(
  public.preview_group_invite(tests.group_code(1)) ->> 'owner_display_name',
  null,
  'preview_group_invite omits owner_display_name when owner withdrew share consent'
);

do $$
begin
  perform tests.as_postgres();
  update public.journey_share_consents
     set status = 'accepted', decided_at = now()
   where journey_id = tests.jid(1) and user_id = tests.u(1);
  perform tests.as_anon('203.0.113.10');
end $$;

select is(
  public.preview_group_invite(tests.group_code(1)) ->> 'owner_display_name',
  'Minh Anh',
  'preview_group_invite includes owner_display_name when owner accepted share consent'
);

-- Ended journey no longer previews as an active invite
do $$
begin
  perform tests.as_postgres();
  update public.journeys set status = 'ended' where id = tests.jid(1);
  perform tests.as_anon('203.0.113.10');
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

-- ===== 4. Authenticated rate limiting shared with preview_group_by_code / join_by_code =====
do $$ begin perform tests.as_user(tests.u(5)); end $$;

select is(
  public.preview_group_invite(tests.group_code(1)) ->> 'title',
  'Hội IELTS 7.5',
  'authenticated caller can preview a valid group code and records a code_preview rate event'
);

select is(
  (select count(*)::int from generate_series(1, 10) g
    where public.preview_group_invite('ZZZZZZ' || lpad(g::text, 2, '0')) is null),
  10,
  '10 failed authenticated preview_group_invite calls return null and record join_attempts'
);

select throws_ok(
  $$ select public.preview_group_invite(tests.group_code(1)) $$,
  'P0001',
  'rate_limited',
  '11th authenticated preview_group_invite call raises rate_limited even for a valid code once join_attempts limit (10/h) is reached'
);

select throws_ok(
  $$ select public.join_by_code(tests.group_code(1)) $$,
  'P0001',
  'rate_limited',
  'authenticated join_by_code shares the same private.join_attempts budget and raises rate_limited after 10 preview_group_invite misses'
);

select is(
  (select count(*)::int from generate_series(1, 60) g
    where public.preview_friend_invite('zzzzzzzzzz' || lpad(g::text, 2, '0')) is null),
  60,
  '60 failed authenticated preview_friend_invite calls return null and record friend_preview_miss rate events'
);

select throws_ok(
  $$ select public.preview_friend_invite(tests.friend_token(1)) $$,
  'P0001',
  'rate_limited',
  '61st authenticated preview_friend_invite call raises rate_limited even for a valid token once friend_preview_miss limit (60/h) is reached'
);

-- ===== 5. Anonymous salted SHA-256 IP hash rate limiting (failed lookups only) =====
do $$ begin perform tests.as_anon('198.51.100.77'); end $$;

select is(
  (select count(*)::int from generate_series(1, 30) g
    where public.preview_group_invite('YYYYYY' || lpad(g::text, 2, '0')) is null),
  30,
  '30 failed anon preview_group_invite calls from the same IP return null and record hashed IP attempts'
);

select throws_ok(
  $$ select public.preview_group_invite(tests.group_code(1)) $$,
  'P0001',
  'rate_limited',
  '31st anon preview_group_invite call from the throttled IP raises rate_limited even for a valid code'
);

select is(
  (select count(*)::int from generate_series(1, 60) g
    where public.preview_friend_invite('yyyyyyyyyy' || lpad(g::text, 2, '0')) is null),
  60,
  '60 failed anon preview_friend_invite calls from the same IP return null and record hashed IP attempts'
);

select throws_ok(
  $$ select public.preview_friend_invite(tests.friend_token(1)) $$,
  'P0001',
  'rate_limited',
  '61st anon preview_friend_invite call from the throttled IP raises rate_limited even for a valid token'
);

do $$ begin perform tests.as_anon('198.51.100.88'); end $$;

select is(
  public.preview_group_invite(tests.group_code(1)) ->> 'title',
  'Hội IELTS 7.5',
  'another anon IP is not affected by the throttled IP hash for preview_group_invite'
);

select is(
  public.preview_friend_invite(tests.friend_token(1)) ->> 'display_name',
  'Minh Anh',
  'another anon IP is not affected by the throttled IP hash for preview_friend_invite'
);

do $$ begin perform tests.as_postgres(); end $$;

-- Row count breakdown in private.invite_preview_attempts:
--   * kind = 'group_preview' (34 rows total):
--       - 4 rows from '203.0.113.10' in Section 3 valid-format negative tests:
--           1. 'ZZZZZZZZ' (unknown code)
--           2. tests.group_code(3) (soft-deleted owner)
--           3. tests.group_code(4) (banned owner)
--           4. tests.group_code(1) while status = 'ended' (ended journey)
--         (invalid formats in Section 3 exit before DB lookup; valid hits are never logged)
--       - 30 rows from '198.51.100.77' in Section 5 ('YYYYYY01'..'YYYYYY30');
--         the 31st call raises 'rate_limited' before inserting.
--   * kind = 'friend_preview' (64 rows total):
--       - 4 rows from '203.0.113.10' in Section 2 valid-format negative tests:
--           1. 'zzzzzzzzzzzz' (unknown token)
--           2. tests.friend_token(3) (soft-deleted inviter)
--           3. tests.friend_token(4) (banned inviter)
--           4. 'aaaaaaaaaaaa' (rotated old token)
--       - 60 rows from '198.51.100.77' in Section 5 ('yyyyyyyyyy01'..'yyyyyyyyyy60');
--         the 61st call raises 'rate_limited' before inserting.
select ok(
  (select count(*) filter (where kind = 'group_preview') = 34
      and count(*) filter (
            where kind = 'group_preview'
              and ip_hash = pg_catalog.encode(pg_catalog.sha256(pg_catalog.convert_to('ourney-group-preview|203.0.113.10', 'UTF8')), 'hex')
          ) = 4
      and count(*) filter (
            where kind = 'group_preview'
              and ip_hash = pg_catalog.encode(pg_catalog.sha256(pg_catalog.convert_to('ourney-group-preview|198.51.100.77', 'UTF8')), 'hex')
          ) = 30
      and count(*) filter (where kind = 'friend_preview') = 64
      and count(*) filter (
            where kind = 'friend_preview'
              and ip_hash = pg_catalog.encode(pg_catalog.sha256(pg_catalog.convert_to('ourney-friend-preview|203.0.113.10', 'UTF8')), 'hex')
          ) = 4
      and count(*) filter (
            where kind = 'friend_preview'
              and ip_hash = pg_catalog.encode(pg_catalog.sha256(pg_catalog.convert_to('ourney-friend-preview|198.51.100.77', 'UTF8')), 'hex')
          ) = 60
      and count(*) = 98
      and bool_and(length(ip_hash) = 64 and ip_hash ~ '^[0-9a-f]{64}$' and ip_hash !~ '(203\.0\.113|198\.51\.100)')
     from private.invite_preview_attempts),
  'private.invite_preview_attempts stores exact per-IP-bucket counts (34 group_preview = 4 + 30; 64 friend_preview = 4 + 60) as 64-char SHA-256 hashes and never raw IP addresses'
);

select * from finish();
rollback;
