-- 0007: check_ins.extras validation, partner photo path, couple names on journeys.
begin;
create extension if not exists pgtap with schema extensions;
select plan(15);

create schema tests;
grant usage on schema tests to authenticated;
create function tests.as_user(u uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', u, 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);
end $$;
create function tests.u(n int) returns uuid language sql immutable as $$
  select format('70000000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function tests.j(n int) returns uuid language sql immutable as $$
  select format('b7000000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function tests.c(n int) returns uuid language sql immutable as $$
  select format('c7000000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;
grant execute on all functions in schema tests to authenticated;

insert into auth.users (id, email) select tests.u(n), format('x%s@example.test', n) from generate_series(1, 2) n;
insert into public.profiles (id, username, display_name) select tests.u(n), 'xuser' || n, 'X' || n from generate_series(1, 2) n;
-- user 1 owns a couple journey, user 2 is an outsider

-- extras validator (pure)
select ok(public.check_in_extras_valid('{}'::jsonb), 'empty extras are valid');
select ok(public.check_in_extras_valid('{"mood":"Nhẹ nhõm","minutes":45,"place":"Đà Lạt","dish":"Phở","cook":"An","hearts":4,"pace":"5:04"}'::jsonb),
  'every whitelisted key with a valid value');
select ok(not public.check_in_extras_valid('{"evil":1}'::jsonb), 'unknown key rejected');
select ok(not public.check_in_extras_valid('[]'::jsonb), 'non-object rejected');
select ok(not public.check_in_extras_valid('{"minutes":0}'::jsonb), 'minutes below range rejected');
select ok(not public.check_in_extras_valid('{"minutes":"45"}'::jsonb), 'minutes must be a number');
select ok(not public.check_in_extras_valid('{"hearts":6}'::jsonb), 'hearts above 5 rejected');
select ok(not public.check_in_extras_valid('{"pace":"5:75"}'::jsonb), 'pace seconds above 59 rejected');
select ok(not public.check_in_extras_valid(jsonb_build_object('place', repeat('x', 61))), 'place over 60 chars rejected');

-- journeys: couple names through create_journey
select tests.as_user(tests.u(1));
select lives_ok($$ select public.create_journey(tests.j(1), 'solo', 'custom', 'Us', 'x', null, null, false,
  current_date, 30, 'UTC', 1, 'private', ' An ', 'Bình') $$, 'create_journey stores couple names');
select is((select couple_self_name || '/' || couple_partner_name from public.journeys where id = tests.j(1)),
  'An/Bình', 'names are trimmed and persisted');
select throws_ok($$ select public.create_journey(tests.j(2), 'solo', 'custom', 'Us', 'x', null, null, false,
  current_date, 30, 'UTC', 1, 'private', 'Only one', null) $$, 'P0001', 'invalid', 'names must come as a pair');

-- check-in: extras + partner photo path
select lives_ok($$ insert into public.check_ins (id, journey_id, user_id, local_date, captured_at, photo_path, thumb_path, partner_photo_path, extras)
  values (tests.c(1), tests.j(1), auth.uid(), current_date, now(),
    format('checkins/%s/%s/%s.jpg', tests.j(1), auth.uid(), tests.c(1)),
    format('checkins/%s/%s/%s_t.jpg', tests.j(1), auth.uid(), tests.c(1)),
    format('checkins/%s/%s/%s_p.jpg', tests.j(1), auth.uid(), tests.c(1)),
    '{"dish":"Phở","hearts":5}') $$, 'check-in with extras and partner photo');
-- since 0011 extras are stored in check_in_extras (check_ins.extras is blanked by a trigger)
select throws_ok($$ insert into public.check_in_extras (checkin_id, journey_id, user_id, extras)
  values (tests.c(1), tests.j(1), auth.uid(), '{"evil":true}') $$,
  '23514', null, 'invalid extras rejected');

-- RLS: an outsider sees neither the row nor its extras
select tests.as_user(tests.u(2));
select is((select count(*)::int from public.check_ins where id = tests.c(1)), 0, 'outsider cannot read the check-in extras');

select * from finish();
rollback;
