-- 0009: onboarding_quiz column + profile_stats().
begin;
create extension if not exists pgtap with schema extensions;
select plan(9);

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
create function tests.uid(n int) returns uuid language sql immutable as $$
  select format('70000000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function tests.jid(n int) returns uuid language sql immutable as $$
  select format('b7000000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;
grant execute on all functions in schema tests to authenticated;

insert into auth.users (id, email) select tests.uid(n), format('s%s@example.test', n) from generate_series(1, 2) n;
insert into public.profiles (id, username, display_name) select tests.uid(n), 'suser' || n, 'S' || n from generate_series(1, 2) n;

-- quiz: owner writes own, cannot write someone else's, shape enforced
select tests.as_user(tests.uid(1));
select lives_ok(
  $$update public.profiles set onboarding_quiz = '{"goal":"workout","who":"solo","reminder":"07:00"}' where id = tests.uid(1)$$,
  'owner can store the onboarding quiz');
select is(
  (select onboarding_quiz->>'goal' from public.profiles where id = tests.uid(1)), 'workout', 'quiz round-trips');
update public.profiles set onboarding_quiz = '{"goal":"x"}' where id = tests.uid(2);
select tests.as_postgres();
select is((select onboarding_quiz from public.profiles where id = tests.uid(2)), null,
  'cannot write another user''s quiz (RLS filters the row)');
select tests.as_user(tests.uid(1));
select throws_ok($$update public.profiles set onboarding_quiz = '[1]' where id = tests.uid(1)$$, '23514',
  null, 'quiz must be a json object');

-- stats
select tests.as_postgres();
select tests.as_user(tests.uid(1));
select is((select total_snaps from public.profile_stats()), 0, 'new user has 0 snaps');

select public.create_journey(tests.jid(1), 'solo', 'custom', 'S1', '🔥', null, null, false,
  current_date - 3, 30, 'UTC', 10, 'private');
insert into public.check_ins (id, journey_id, user_id, local_date, captured_at, photo_path, thumb_path)
values ('c7000000-0000-4000-8000-000000000001', tests.jid(1), auth.uid(), current_date, now(),
  format('checkins/%s/%s/%s.jpg', tests.jid(1), auth.uid(), 'c7000000-0000-4000-8000-000000000001'),
  format('checkins/%s/%s/%s_t.jpg', tests.jid(1), auth.uid(), 'c7000000-0000-4000-8000-000000000001'));
select is((select total_snaps from public.profile_stats()), 1, 'counts own snap');
select is((select journeys_total from public.profile_stats()), 1, 'counts the journey');
select tests.as_postgres();
select tests.as_user(tests.uid(2));
select is((select journeys_total from public.profile_stats()), 0, 'other user does not see it');
select tests.as_postgres();
select throws_ok($$select public.profile_stats()$$, '28000', 'unauthenticated', 'requires a signed-in caller');

select * from finish();
rollback;
