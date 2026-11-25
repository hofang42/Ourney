-- 0029_check_username_available: pgTAP tests for public.check_username_available(text).
-- Covers: anon denied, authenticated/service_role allowed, SECURITY DEFINER + STABLE + search_path='',
-- brand-new authenticated caller without a public.profiles row, available handle -> true,
-- taken handle (active or soft-deleted) -> false, caller's own handle -> true,
-- invalid format / length -> false, objectionable word -> false,
-- unauthenticated JWT claim -> 28000 unauthenticated, banned caller -> 42501 forbidden.
begin;
create extension if not exists pgtap with schema extensions;
select plan(13);

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

create function tests.u(n int) returns uuid language sql immutable as $$
  select format('29000000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;

grant execute on all functions in schema tests to anon, authenticated, service_role;

-- Seed users:
--   1: Existing active profile ('minh_active')
--   2: Existing soft-deleted profile still holding unique username ('minh_deleted')
--   3: Brand-new authenticated user on /profile/setup (NO row in public.profiles yet)
--   4: Banned user
insert into auth.users (id, email)
values
  (tests.u(1), 'u1@example.test'),
  (tests.u(2), 'u2@example.test'),
  (tests.u(3), 'u3@example.test'),
  (tests.u(4), 'u4@example.test');

insert into public.profiles (id, username, display_name, deleted_at)
values
  (tests.u(1), 'minh_active', 'Minh Active', null),
  (tests.u(2), 'minh_deleted', 'Minh Deleted', now()),
  (tests.u(4), 'minh_banned', 'Minh Banned', null);

insert into private.user_moderation (user_id, banned_at, ban_reason)
values (tests.u(4), now(), 'Banned test user');

-- The current handle was valid when set, before a moderation policy update.
insert into private.objectionable_words (term, lang, match_mode)
values ('minhactive', 'any', 'substring');

select ok(
  private.contains_objectionable_text('minh_active'),
  'the current handle now matches an objectionable term'
);

-- 1. Grants: anon denied, authenticated and service_role granted
select ok(
  not has_function_privilege('anon', 'public.check_username_available(text)', 'execute')
  and has_function_privilege('authenticated', 'public.check_username_available(text)', 'execute')
  and has_function_privilege('service_role', 'public.check_username_available(text)', 'execute'),
  'check_username_available(text) is executable by authenticated and service_role, never by anon'
);

-- 2. Function metadata
select ok(
  (select p.prosecdef and p.provolatile = 's' and p.pronargs = 1 and 'search_path=""' = any(p.proconfig)
     from pg_proc p
    where p.oid = 'public.check_username_available(text)'::regprocedure),
  'check_username_available(text) is STABLE, SECURITY DEFINER, search_path='''''
);

-- 3. Calling as anon fails with permission denied (42501)
do $$ begin perform tests.as_anon(); end $$;

select throws_ok(
  $$ select public.check_username_available('fresh_handle') $$,
  '42501',
  null,
  'anon calling check_username_available is rejected with 42501 permission denied'
);

-- 4. Calling with missing JWT sub throws 28000 unauthenticated
do $$
begin
  perform set_config('request.jwt.claims', '{"role":"authenticated"}', true);
  perform set_config('role', 'authenticated', true);
end $$;

select throws_ok(
  $$ select public.check_username_available('fresh_handle') $$,
  '28000',
  'unauthenticated',
  'authenticated role without a sub claim raises 28000 unauthenticated'
);

-- 5. Brand-new authenticated user without a public.profiles row can check availability
do $$ begin perform tests.as_user(tests.u(3)); end $$;

select is(
  public.check_username_available('  @Fresh.Handle_29  '),
  true,
  'brand-new user without a profile row sees an unused valid username as available'
);

-- 6. Username taken by another active user returns false
select is(
  public.check_username_available('MINH_ACTIVE'),
  false,
  'username taken by another active profile returns false'
);

-- 7. Username held by a soft-deleted profile row returns false (matches UNIQUE constraint)
select is(
  public.check_username_available('minh_deleted'),
  false,
  'username still held by a soft-deleted profile row returns false'
);

-- 8. Invalid format (too short, too long > 20 chars, invalid characters) returns false
select ok(
  not public.check_username_available('ab')
  and not public.check_username_available('abcdefghijklmnopqrstu')
  and not public.check_username_available('bad!name')
  and not public.check_username_available(null),
  'invalid format or >20-char username returns false'
);

-- 9. Objectionable text in username returns false (matches profiles_enforce_content_policy)
select is(
  public.check_username_available('fuck_user'),
  false,
  'username containing objectionable text returns false'
);

-- 10. Existing user checking their own current username sees true
do $$ begin perform tests.as_user(tests.u(1)); end $$;

select is(
  public.check_username_available('minh_active'),
  true,
  'caller own current username returns true even when policy has changed'
);

-- 11. Existing user checking another user taken username sees false
select is(
  public.check_username_available('minh_deleted'),
  false,
  'existing user checking another user taken username sees false'
);

-- 12. Banned user raises 42501 forbidden via public._uid()
do $$ begin perform tests.as_user(tests.u(4)); end $$;

select throws_ok(
  $$ select public.check_username_available('fresh_handle') $$,
  '42501',
  'forbidden',
  'banned user calling check_username_available raises 42501 forbidden'
);

select * from finish();
rollback;
