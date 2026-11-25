-- 0028_auth_has_password: pgTAP tests for public.auth_has_password().
-- Covers: anon denied, authenticated/service_role allowed, SECURITY DEFINER + STABLE + search_path='',
-- parameterless signature (cross-user query impossible; account_has_password(uuid) remains service_role-only),
-- NULL / empty / whitespace encrypted_password -> false, bcrypt hash -> true,
-- caller isolation (never reads another user's password state), live password transition false -> true,
-- unauthenticated JWT claim -> 28000 unauthenticated, banned caller -> 42501 forbidden.
begin;
create extension if not exists pgtap with schema extensions;
select plan(12);

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
  select format('28000000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;

grant execute on all functions in schema tests to anon, authenticated, service_role;

-- Seed users:
--   1: OTP-only account (encrypted_password is NULL)
--   2: OTP-only account (encrypted_password is empty/whitespace '')
--   3: Password-enabled account (encrypted_password is a bcrypt hash)
--   4: Banned account with a password
insert into auth.users (id, email, encrypted_password)
values
  (tests.u(1), 'pw1@example.test', null),
  (tests.u(2), 'pw2@example.test', '   '),
  (tests.u(3), 'pw3@example.test', '$2a$10$abcdefghijklmnopqrstuuABCDEFGHIJKLMNOPQRSTUVWXYZ012'),
  (tests.u(4), 'pw4@example.test', '$2a$10$abcdefghijklmnopqrstuuABCDEFGHIJKLMNOPQRSTUVWXYZ012');

insert into public.profiles (id, username, display_name)
values
  (tests.u(1), 'otp_null_user', 'OTP Null'),
  (tests.u(2), 'otp_blank_user', 'OTP Blank'),
  (tests.u(3), 'pw_set_user', 'Password Set'),
  (tests.u(4), 'pw_banned_user', 'Banned User');

insert into private.user_moderation (user_id, banned_at, ban_reason)
values (tests.u(4), now(), 'Banned test user');

-- 1. Grants: anon denied, authenticated and service_role granted
select ok(
  not has_function_privilege('anon', 'public.auth_has_password()', 'execute')
  and has_function_privilege('authenticated', 'public.auth_has_password()', 'execute')
  and has_function_privilege('service_role', 'public.auth_has_password()', 'execute'),
  'auth_has_password() is executable by authenticated and service_role, never by anon'
);

-- 2. Function metadata & parameterless signature (cross-user query impossible)
select ok(
  (select p.prosecdef and p.provolatile = 's' and p.pronargs = 0 and 'search_path=""' = any(p.proconfig)
     from pg_proc p
    where p.oid = 'public.auth_has_password()'::regprocedure)
  and (select count(*)::int
         from pg_proc p join pg_namespace n on n.oid = p.pronamespace
        where n.nspname = 'public' and p.proname = 'auth_has_password') = 1
  and not has_function_privilege('authenticated', 'public.account_has_password(uuid)', 'execute'),
  'auth_has_password() is STABLE, SECURITY DEFINER, search_path='''', strictly parameterless with no uuid overload, and account_has_password(uuid) stays service_role-only'
);

-- 3. Calling as anon fails with permission denied (42501)
do $$ begin perform tests.as_anon(); end $$;

select throws_ok(
  $$ select public.auth_has_password() $$,
  '42501',
  null,
  'anon calling auth_has_password() is rejected with 42501 permission denied'
);

-- 4. Calling with missing JWT sub throws 28000 unauthenticated
do $$
begin
  perform set_config('request.jwt.claims', '{"role":"authenticated"}', true);
  perform set_config('role', 'authenticated', true);
end $$;

select throws_ok(
  $$ select public.auth_has_password() $$,
  '28000',
  'unauthenticated',
  'authenticated role without a sub claim raises 28000 unauthenticated'
);

-- 5. Any call with a user argument fails to resolve (other-user query impossible)
do $$ begin perform tests.as_user(tests.u(1)); end $$;

select throws_ok(
  format('select public.auth_has_password(%L::uuid)', tests.u(3)),
  '42883',
  null,
  'passing another user uuid to auth_has_password is impossible (42883 undefined_function)'
);

-- 6. NULL encrypted_password returns false
select is(
  public.auth_has_password(),
  false,
  'auth_has_password() returns false when caller encrypted_password is NULL'
);

-- 7. Empty / whitespace encrypted_password returns false
do $$ begin perform tests.as_user(tests.u(2)); end $$;

select is(
  public.auth_has_password(),
  false,
  'auth_has_password() returns false when caller encrypted_password is blank/whitespace'
);

-- 8. Non-empty encrypted_password returns true
do $$ begin perform tests.as_user(tests.u(3)); end $$;

select is(
  public.auth_has_password(),
  true,
  'auth_has_password() returns true when caller encrypted_password is set'
);

-- 9. Cross-user isolation: u(1) still sees false even while u(3) has a password
do $$ begin perform tests.as_user(tests.u(1)); end $$;

select is(
  public.auth_has_password(),
  false,
  'auth_has_password() only inspects caller auth.uid() and never leaks another user state'
);

-- 10. Setting encrypted_password on u(1) flips auth_has_password() from false to true
do $$
begin
  perform tests.as_postgres();
  update auth.users
     set encrypted_password = '$2a$10$newpasswordhashabcdefghijklmnopqrstuvwx0123456789'
   where id = tests.u(1);
  perform tests.as_user(tests.u(1));
end $$;

select is(
  public.auth_has_password(),
  true,
  'auth_has_password() returns true immediately after caller sets a password'
);

-- 11. Clearing encrypted_password flips auth_has_password() back to false
do $$
begin
  perform tests.as_postgres();
  update auth.users set encrypted_password = '' where id = tests.u(1);
  perform tests.as_user(tests.u(1));
end $$;

select is(
  public.auth_has_password(),
  false,
  'auth_has_password() returns false if encrypted_password is cleared'
);

-- 12. Banned user raises 42501 forbidden via public._uid()
do $$ begin perform tests.as_user(tests.u(4)); end $$;

select throws_ok(
  $$ select public.auth_has_password() $$,
  '42501',
  'forbidden',
  'banned user calling auth_has_password() raises 42501 forbidden'
);

select * from finish();
rollback;
