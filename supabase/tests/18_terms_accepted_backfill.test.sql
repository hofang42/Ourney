-- 0018_terms_accepted_backfill: marks accounts with a profile as having accepted the terms (version 1).
begin;
create extension if not exists pgtap with schema extensions;
select plan(9);

-- u1: profile, no metadata. u2: profile with other metadata. u3: profile that already accepted v2.
-- u4: signed up but never made a profile.
insert into auth.users (id, email, raw_user_meta_data) values
  ('18000000-0000-4000-8000-000000000001', 'terms1@example.test', null),
  ('18000000-0000-4000-8000-000000000002', 'terms2@example.test', '{"locale":"vi"}'::jsonb),
  ('18000000-0000-4000-8000-000000000003', 'terms3@example.test', '{"terms_version":2}'::jsonb),
  ('18000000-0000-4000-8000-000000000004', 'terms4@example.test', null);
insert into public.profiles (id, username, display_name) values
  ('18000000-0000-4000-8000-000000000001', 'terms_one', 'T1'),
  ('18000000-0000-4000-8000-000000000002', 'terms_two', 'T2'),
  ('18000000-0000-4000-8000-000000000003', 'terms_three', 'T3');

select is(
  has_function_privilege('anon', 'private.backfill_terms_accepted(int)', 'execute')
    or has_function_privilege('authenticated', 'private.backfill_terms_accepted(int)', 'execute'),
  false,
  'clients cannot run the backfill'
);

select is(private.backfill_terms_accepted(1), 2, 'two accounts needed the backfill');

select is(
  (select (raw_user_meta_data ->> 'terms_version')::int from auth.users where id = '18000000-0000-4000-8000-000000000001'),
  1,
  'an account with a profile gets terms_version 1'
);
select ok(
  (select raw_user_meta_data ? 'terms_accepted_at' from auth.users where id = '18000000-0000-4000-8000-000000000001'),
  'and a terms_accepted_at stamp'
);
select is(
  (select raw_user_meta_data ->> 'locale' from auth.users where id = '18000000-0000-4000-8000-000000000002'),
  'vi',
  'existing metadata keys are kept'
);
select is(
  (select (raw_user_meta_data ->> 'terms_version')::int from auth.users where id = '18000000-0000-4000-8000-000000000002'),
  1,
  'the merge also sets the version on an account with other metadata'
);
select is(
  (select (raw_user_meta_data ->> 'terms_version')::int from auth.users where id = '18000000-0000-4000-8000-000000000003'),
  2,
  'a newer recorded version is never lowered'
);
select ok(
  (select not (coalesce(raw_user_meta_data, '{}'::jsonb) ? 'terms_version') from auth.users where id = '18000000-0000-4000-8000-000000000004'),
  'an account without a profile is not marked'
);
select is(private.backfill_terms_accepted(1), 0, 'idempotent: a second run changes nothing');

select * from finish();
rollback;
