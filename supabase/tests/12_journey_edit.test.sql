-- 0012: journey edit fields, dna validator, update_journey RPC.
begin;
create extension if not exists pgtap with schema extensions;
select plan(16);

create schema tests;
grant usage on schema tests to authenticated;
create function tests.as_user(u uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', u, 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);
end $$;
create function tests.u(n int) returns uuid language sql immutable as $$
  select format('72000000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function tests.jid(n int) returns uuid language sql immutable as $$
  select format('b1200000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function tests.code() returns text language sql security definer as $$
  select invite_code from public.journeys where id = tests.jid(2) $$;
grant execute on all functions in schema tests to authenticated;

insert into auth.users (id, email) select tests.u(n), format('je%s@example.test', n) from generate_series(1, 3) n;
insert into public.profiles (id, username, display_name) select tests.u(n), 'jeuser' || n, 'J' || n from generate_series(1, 3) n;

do $$ begin perform tests.as_user(tests.u(1));
  perform public.create_journey(tests.jid(1), 'solo', 'workout_30', 'Run', 'x', null, null, false,
                                current_date, 30, 'UTC', 1, 'private');
  perform public.create_journey(tests.jid(2), 'group', 'custom', 'Squad', 'x', null, null, false,
                                current_date, 30, 'UTC', 10, 'private'); end $$;
do $$ begin perform tests.as_user(tests.u(2)); perform public.join_by_code(tests.code()); end $$;

-- validator
select ok(public.journey_dna_valid('{"goal":"ielts","minutes":"30","trophy":"Cup","dates":{"start":"2026-01-01"}}'::jsonb),
  'valid dna accepted');
select ok(not public.journey_dna_valid('{"weight":70}'::jsonb)
      and not public.journey_dna_valid('{"goal":"Not Valid"}'::jsonb)
      and not public.journey_dna_valid('[1]'::jsonb)
      and not public.journey_dna_valid('{"trophy":""}'::jsonb), 'unknown key, bad choice, non-object, empty text rejected');
select ok(not has_function_privilege('anon', 'public.update_journey(uuid,text,text,int,int,text,jsonb,text[])', 'execute')
      and has_function_privilege('authenticated', 'public.update_journey(uuid,text,text,int,int,text,jsonb,text[])', 'execute'),
  'update_journey revoked from anon, granted to authenticated');

-- owner happy path
do $$ begin perform tests.as_user(tests.u(1)); end $$;
select lives_ok($$ select public.update_journey(tests.jid(1), 'Run 2', 'minimalist_habit', 1, 2, '07:30',
  '{"sport":"run","measure":"km"}'::jsonb) $$, 'owner updates all fields');
select is((select layout from public.journeys where id = tests.jid(1)), 'minimalist_habit', 'layout stored');
select is((select reminder_time from public.journeys where id = tests.jid(1)), '07:30', 'reminder stored');
select is((select (dna ->> 'sport') from public.journeys where id = tests.jid(1)), 'run', 'dna stored');
select is((select title from public.journeys where id = tests.jid(1)), 'Run 2', 'title renamed');

-- partial update keeps the rest, p_clear resets
select lives_ok($$ select public.update_journey(tests.jid(1), null, null, 0) $$, 'partial update');
select is((select color from public.journeys where id = tests.jid(1)), 2::smallint, 'unchanged field kept');
select lives_ok($$ select public.update_journey(tests.jid(1), null, null, null, null, null, null, array['layout']) $$,
  'clear layout');
select ok((select layout is null from public.journeys where id = tests.jid(1)), 'layout cleared to null');

-- validation
select throws_ok($$ select public.update_journey(tests.jid(1), null, 'accountability_squad') $$, 'P0001', 'invalid',
  'squad layout needs a group journey');
select throws_ok($$ select public.update_journey(tests.jid(1), null, null, 3) $$, 'P0001', 'invalid', 'cover out of range');
select throws_ok($$ select public.update_journey(tests.jid(1), null, null, null, null, '25:00') $$, 'P0001', 'invalid',
  'bad reminder time');

-- not owner
do $$ begin perform tests.as_user(tests.u(2)); end $$;
select throws_ok($$ select public.update_journey(tests.jid(2), 'Hijack') $$, '42501', 'forbidden',
  'member (not owner) cannot update');

select * from finish();
rollback;
