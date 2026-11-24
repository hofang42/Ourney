-- 0018_terms_accepted_backfill: server-side terms_version on public.profiles + public.accept_terms(int).
begin;
create extension if not exists pgtap with schema extensions;
select plan(25);

create schema tests;
grant usage on schema tests to anon, authenticated;
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
create function tests.uid(n int) returns uuid language sql immutable as $$
  select format('18000000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;
grant execute on all functions in schema tests to anon, authenticated;

-- u1: profile, SQL NULL metadata.
-- u2: profile, JSON 'null'::jsonb metadata (must never be touched or turned into a JSON array).
-- u3: profile already at terms_version = 2.
-- u4: signed-up user without a profile yet (accepts terms before /profile/setup).
-- u5: profile with terms_version = 0 (created after backfill).
insert into auth.users (id, email, raw_user_meta_data) values
  (tests.uid(1), 'terms1@example.test', null),
  (tests.uid(2), 'terms2@example.test', 'null'::jsonb),
  (tests.uid(3), 'terms3@example.test', '{"locale":"vi"}'::jsonb),
  (tests.uid(4), 'terms4@example.test', null),
  (tests.uid(5), 'terms5@example.test', null);

insert into public.profiles (id, username, display_name, terms_version) values
  (tests.uid(1), 'terms_one', 'T1', 0),
  (tests.uid(2), 'terms_two', 'T2', 0),
  (tests.uid(3), 'terms_three', 'T3', 2);

-- 1-4: privileges and RLS on private.terms_acceptance and functions.
select is(
  has_function_privilege('anon', 'private.backfill_terms_accepted(int)', 'execute')
    or has_function_privilege('authenticated', 'private.backfill_terms_accepted(int)', 'execute'),
  false,
  'clients cannot run private.backfill_terms_accepted'
);
select is(
  has_function_privilege('anon', 'public.accept_terms(int)', 'execute'),
  false,
  'anon cannot execute public.accept_terms'
);
select is(
  has_function_privilege('authenticated', 'public.accept_terms(int)', 'execute'),
  true,
  'authenticated can execute public.accept_terms'
);
select ok(
  (select relrowsecurity from pg_class where oid = 'private.terms_acceptance'::regclass)
  and not has_table_privilege('anon', 'private.terms_acceptance', 'select')
  and not has_table_privilege('authenticated', 'private.terms_acceptance', 'select'),
  'private.terms_acceptance has RLS enabled and no client grants'
);

-- 5-11: backfill marks existing profiles as version 1, never lowers v2, and never touches auth.users.
select is(private.backfill_terms_accepted(1), 2, 'two profiles needed the backfill');
select is(
  (select terms_version from public.profiles where id = tests.uid(1)),
  1,
  'u1 profile gets terms_version 1'
);
select is(
  (select terms_version from public.profiles where id = tests.uid(2)),
  1,
  'u2 profile gets terms_version 1'
);
select is(
  (select terms_version from public.profiles where id = tests.uid(3)),
  2,
  'a newer terms_version (2) is never lowered by the backfill'
);
select is(
  (select raw_user_meta_data from auth.users where id = tests.uid(1)),
  null::jsonb,
  'auth.users.raw_user_meta_data (SQL NULL) is never touched'
);
select is(
  (select raw_user_meta_data from auth.users where id = tests.uid(2)),
  'null'::jsonb,
  'auth.users.raw_user_meta_data (JSON null) is never corrupted into an array'
);
select is(private.backfill_terms_accepted(1), 0, 'idempotent: second backfill changes nothing');

-- 12: unauthenticated caller is rejected with 28000.
select throws_ok(
  $$select public.accept_terms(1)$$,
  '28000',
  'unauthenticated',
  'accept_terms requires a signed-in user'
);

-- 13-14: clients cannot write terms_version directly on public.profiles (INSERT or UPDATE).
select tests.as_user(tests.uid(1));
select throws_ok(
  $$update public.profiles set terms_version = 99 where id = auth.uid()$$,
  '42501',
  null,
  'authenticated user cannot directly UPDATE public.profiles.terms_version'
);

select tests.as_user(tests.uid(4));
select throws_ok(
  $$insert into public.profiles (id, username, display_name, terms_version)
    values (auth.uid(), 'terms_four', 'T4', 99)$$,
  '42501',
  null,
  'authenticated user cannot directly INSERT public.profiles.terms_version'
);

-- 15-18: accept_terms rejects null, <= 0, and versions > current server max (1).
select throws_ok(
  $$select public.accept_terms(null)$$,
  'P0001',
  'invalid',
  'accept_terms rejects NULL version'
);
select throws_ok(
  $$select public.accept_terms(0)$$,
  'P0001',
  'invalid',
  'accept_terms rejects version 0'
);
select throws_ok(
  $$select public.accept_terms(-1)$$,
  'P0001',
  'invalid',
  'accept_terms rejects negative version'
);
select throws_ok(
  $$select public.accept_terms(2)$$,
  'P0001',
  'invalid',
  'accept_terms rejects version > server max'
);

-- 19-21: u4 accepts terms BEFORE creating a profile (inline /auth clickwrap -> /profile/setup),
-- then creates the profile and reads own terms_version via the existing profile SELECT.
select is(
  public.accept_terms(1),
  1,
  'u4 records terms_version 1 before profile setup'
);
select lives_ok(
  $$insert into public.profiles (id, username, display_name)
    values (auth.uid(), 'terms_four', 'T4')$$,
  'u4 creates own profile on /profile/setup'
);
select is(
  (select terms_version from public.profiles where id = auth.uid()),
  1,
  'u4 reads own terms_version = 1 via the existing profile select'
);

-- 22-24: u5 creates a profile with default terms_version = 0, then accepts terms via accept_terms(1).
select tests.as_user(tests.uid(5));
insert into public.profiles (id, username, display_name)
values (auth.uid(), 'terms_five', 'T5');
select is(
  (select terms_version from public.profiles where id = auth.uid()),
  0,
  'new profile defaults to terms_version 0 before accept_terms'
);
select is(
  public.accept_terms(1),
  1,
  'u5 raises own terms_version to 1 via accept_terms'
);
select is(
  (select terms_version from public.profiles where id = auth.uid()),
  1,
  'u5 profile now carries terms_version = 1'
);

-- 25: calling accept_terms(1) on an account already at v2 never lowers the version.
select tests.as_user(tests.uid(3));
select is(
  public.accept_terms(1),
  2,
  'accept_terms never lowers an existing higher version'
);

select tests.as_postgres();
select * from finish();
rollback;
