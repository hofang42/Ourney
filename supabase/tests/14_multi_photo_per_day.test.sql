-- 0014: several check-ins per member per day (SRS FR-C7/FR-C8). The day counts once for the
-- streak; group_today returns one row per member with the latest photo of today.
begin;
create extension if not exists pgtap with schema extensions;
select plan(8);

create schema tests;
grant usage on schema tests to authenticated;
create function tests.as_user(u uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', u, 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);
end $$;
create function tests.u(n int) returns uuid language sql immutable as $$
  select format('74000000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function tests.jid() returns uuid language sql immutable as $$
  select 'b1400000-0000-4000-8000-000000000001'::uuid $$;
create function tests.cid(n int) returns uuid language sql immutable as $$
  select format('c1400000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;
-- a check-in for the current caller with contract-shaped paths
create function tests.checkin(cid uuid, at timestamptz) returns void language sql as $$
  insert into public.check_ins (id, journey_id, user_id, local_date, captured_at, photo_path, thumb_path)
  values (cid, tests.jid(), auth.uid(), '2000-01-01', at,
          format('checkins/%s/%s/%s.jpg', tests.jid(), auth.uid(), cid),
          format('checkins/%s/%s/%s_t.jpg', tests.jid(), auth.uid(), cid));
$$;
grant execute on all functions in schema tests to authenticated;

insert into auth.users (id, email) select tests.u(n), format('mp%s@example.test', n) from generate_series(1, 2) n;
insert into public.profiles (id, username, display_name) select tests.u(n), 'mpuser' || n, 'M' || n from generate_series(1, 2) n;

do $$ begin perform tests.as_user(tests.u(1));
  perform public.create_journey(tests.jid(), 'group', 'english_daily', 'Lessons', 'x', null, null, false,
                                current_date, 30, 'UTC', 10, 'private'); end $$;

select ok(not exists (select 1 from pg_constraint
                        where conrelid = 'public.check_ins'::regclass and contype = 'u'),
  'check_ins has no unique (journey_id, user_id, local_date) any more');

do $$ begin perform tests.as_user(tests.u(1)); end $$;
select lives_ok($$ select tests.checkin(tests.cid(1), now() - interval '2 minutes') $$, 'first photo of today');
select lives_ok($$ select tests.checkin(tests.cid(2), now() - interval '1 minute') $$,
  'second photo of the same day is a new row, not a conflict');
select lives_ok($$ select tests.checkin(tests.cid(3), now()) $$, 'third photo of the same day');

select is((select count(*)::int from public.check_ins
            where journey_id = tests.jid() and user_id = tests.u(1) and deleted_at is null),
  3, 'all three photos of the day are kept');

select results_eq(
  $$ select completed_days, current_streak from public.journey_streak(tests.jid(), tests.u(1)) $$,
  $$ values (1, 1) $$, 'three photos on one day count the day once');

select is((select count(*)::int from public.group_today(tests.jid()) where user_id = tests.u(1)),
  1, 'group_today returns one row per member');
select is((select checkin_id from public.group_today(tests.jid()) where user_id = tests.u(1)),
  tests.cid(3), 'group_today shows the latest photo of today');

select * from finish();
rollback;
