-- Streak: hand-translated from docs/contracts/streak_vectors.json (keep in sync!),
-- plus local_date / trigger / journey_streak integration.
-- Result columns: (current_streak, best_streak, completed_days)
begin;
create extension if not exists pgtap with schema extensions;
select plan(18);

-- ---- golden vectors -------------------------------------------------------
select results_eq(
  $$ select * from public.streak_from_dates('{}'::date[], '2026-10-01', 30, '2026-10-05') $$,
  $$ values (0, 0, 0) $$, 'vector: empty');

select results_eq(
  $$ select * from public.streak_from_dates(array['2026-10-05']::date[], '2026-10-01', 30, '2026-10-05') $$,
  $$ values (1, 1, 1) $$, 'vector: only today');

select results_eq(
  $$ select * from public.streak_from_dates(array['2026-10-03','2026-10-04']::date[], '2026-10-01', 30, '2026-10-05') $$,
  $$ values (2, 2, 2) $$, 'vector: yesterday kept alive');

select results_eq(
  $$ select * from public.streak_from_dates(array['2026-10-01','2026-10-02','2026-10-03']::date[], '2026-10-01', 30, '2026-10-05') $$,
  $$ values (0, 3, 3) $$, 'vector: gap breaks');

select results_eq(
  $$ select * from public.streak_from_dates(array['2026-10-01','2026-10-02','2026-10-04','2026-10-05']::date[], '2026-10-01', 30, '2026-10-05') $$,
  $$ values (2, 2, 4) $$, 'vector: run through today');

select results_eq(
  $$ select * from public.streak_from_dates(array['2026-10-03','2026-10-01','2026-10-02','2026-10-02']::date[], '2026-10-01', 30, '2026-10-03') $$,
  $$ values (3, 3, 3) $$, 'vector: duplicates ignored and unsorted');

select results_eq(
  $$ select * from public.streak_from_dates(array['2026-09-30','2026-10-01','2026-10-02','2026-10-03','2026-10-04']::date[], '2026-10-01', 3, '2026-10-05') $$,
  $$ values (0, 5, 3) $$, 'vector: dates outside journey ignored for completed');

select results_eq(
  $$ select * from public.streak_from_dates(array['2026-09-29','2026-09-30','2026-10-01','2026-10-02']::date[], '2026-09-28', null, '2026-10-02') $$,
  $$ values (4, 4, 4) $$, 'vector: month boundary');

select results_eq(
  $$ select * from public.streak_from_dates(array['2028-02-28','2028-02-29','2028-03-01']::date[], '2028-02-27', null, '2028-03-01') $$,
  $$ values (3, 3, 3) $$, 'vector: leap day');

-- ---- local_date -----------------------------------------------------------
select is(
  public.local_date('2026-10-04 18:30:00+00', 'Asia/Ho_Chi_Minh'),
  '2026-10-05'::date,
  'local_date rolls over to next day east of UTC');

select is(
  public.local_date('2026-10-05 03:30:00+00', 'America/Los_Angeles'),
  '2026-10-04'::date,
  'local_date stays on previous day west of UTC');

select is(
  public.local_date('2026-03-08 04:30:00+00', 'America/New_York'),
  '2026-03-07'::date,
  'local_date before DST switch (23:30 EST)');

select is(
  public.local_date('2026-03-09 03:30:00+00', 'America/New_York'),
  '2026-03-08'::date,
  'local_date after DST switch uses the new offset (23:30 EDT)');

-- ---- trigger + journey_streak integration ---------------------------------
insert into auth.users (id, email) values ('11111111-1111-4111-8111-111111111111', 'streak-a@example.test');
insert into public.profiles (id, username, display_name)
  values ('11111111-1111-4111-8111-111111111111', 'streaker', 'Streaker');
insert into public.journeys (id, owner_id, kind, title, emoji, start_date, timezone, visibility)
  values ('aaaaaaaa-0000-4000-8000-000000000001', '11111111-1111-4111-8111-111111111111',
          'solo', 'Tz test', '🔥', '2026-10-01', 'Asia/Ho_Chi_Minh', 'private');
insert into public.memberships (journey_id, user_id, role, joined_at)
  values ('aaaaaaaa-0000-4000-8000-000000000001', '11111111-1111-4111-8111-111111111111',
          'owner', '2026-09-30 00:00:00+00');

-- client claims a bogus local_date; the server must overwrite it from captured_at + timezone
insert into public.check_ins (id, journey_id, user_id, local_date, captured_at, photo_path, thumb_path)
select id, 'aaaaaaaa-0000-4000-8000-000000000001', '11111111-1111-4111-8111-111111111111',
       '1999-01-01', captured_at,
       format('checkins/%s/%s/%s.jpg', 'aaaaaaaa-0000-4000-8000-000000000001', '11111111-1111-4111-8111-111111111111', id),
       format('checkins/%s/%s/%s_t.jpg', 'aaaaaaaa-0000-4000-8000-000000000001', '11111111-1111-4111-8111-111111111111', id)
  from (values
    ('c0000000-0000-4000-8000-000000000001'::uuid, '2026-10-01 05:00:00+00'::timestamptz),
    ('c0000000-0000-4000-8000-000000000002'::uuid, '2026-10-02 05:00:00+00'::timestamptz),
    -- 18:30 UTC on 10-03 is already 10-04 in Ho Chi Minh (UTC+7)
    ('c0000000-0000-4000-8000-000000000003'::uuid, '2026-10-03 18:30:00+00'::timestamptz)
  ) as t(id, captured_at);

select is(
  (select local_date from public.check_ins where id = 'c0000000-0000-4000-8000-000000000003'),
  '2026-10-04'::date,
  'trigger derives local_date from captured_at + journey timezone (client value ignored)');

select results_eq(
  $$ select * from public.journey_streak('aaaaaaaa-0000-4000-8000-000000000001', '11111111-1111-4111-8111-111111111111', '2026-10-04') $$,
  $$ values (1, 2, 3) $$,
  'journey_streak: 10-01,10-02 then 10-04 -> current 1, best 2, completed 3');

select results_eq(
  $$ select * from public.journey_streak('aaaaaaaa-0000-4000-8000-000000000001', '11111111-1111-4111-8111-111111111111', '2026-10-05') $$,
  $$ values (1, 2, 3) $$,
  'journey_streak: yesterday keeps the streak alive');

select results_eq(
  $$ select * from public.journey_streak('aaaaaaaa-0000-4000-8000-000000000001', '11111111-1111-4111-8111-111111111111', '2026-10-07') $$,
  $$ values (0, 2, 3) $$,
  'journey_streak: gap of two days resets current');

-- personal progress counts from joined_at
update public.memberships set joined_at = '2026-10-02 00:00:00+00'
 where journey_id = 'aaaaaaaa-0000-4000-8000-000000000001';
select results_eq(
  $$ select * from public.journey_streak('aaaaaaaa-0000-4000-8000-000000000001', '11111111-1111-4111-8111-111111111111', '2026-10-04') $$,
  $$ values (1, 1, 2) $$,
  'journey_streak ignores check-ins before the member joined (local date of joined_at)');

select * from finish();
rollback;
