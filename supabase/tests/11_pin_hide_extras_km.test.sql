-- 0011: km in extras, per-user pin, hide_extras + check_in_extras RLS.
begin;
create extension if not exists pgtap with schema extensions;
select plan(17);

create schema tests;
grant usage on schema tests to authenticated;
create function tests.as_user(u uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', u, 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);
end $$;
create function tests.u(n int) returns uuid language sql immutable as $$
  select format('71000000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function tests.jid() returns uuid language sql immutable as $$
  select 'b1100000-0000-4000-8000-0000000000a1'::uuid $$;
create function tests.cid(n int) returns uuid language sql immutable as $$
  select format('c1100000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function tests.code() returns text language sql security definer as $$
  select invite_code from public.journeys where id = tests.jid() $$;
grant execute on all functions in schema tests to authenticated;

insert into auth.users (id, email) select tests.u(n), format('pk%s@example.test', n) from generate_series(1, 3) n;
insert into public.profiles (id, username, display_name) select tests.u(n), 'pkuser' || n, 'P' || n from generate_series(1, 3) n;

do $$ begin perform tests.as_user(tests.u(1));
  perform public.create_journey(tests.jid(), 'group', 'workout30', 'Run', 'x', 'km', 'km', false,
                                current_date, 30, 'UTC', 10, 'private'); end $$;
do $$ begin perform tests.as_user(tests.u(2)); perform public.join_by_code(tests.code()); end $$;

-- validator: km
select ok(public.check_in_extras_valid('{"km":5.3,"pace":"5:04"}'::jsonb), 'km one decimal accepted');
select ok(public.check_in_extras_valid('{"km":500}'::jsonb) and public.check_in_extras_valid('{"km":0.1}'::jsonb),
  'km bounds accepted');
select ok(not public.check_in_extras_valid('{"km":0}'::jsonb)
      and not public.check_in_extras_valid('{"km":500.1}'::jsonb)
      and not public.check_in_extras_valid('{"km":5.25}'::jsonb)
      and not public.check_in_extras_valid('{"km":"5"}'::jsonb), 'km out of range, precision or type rejected');
select ok(not has_function_privilege('anon', 'public.check_in_extras_valid(jsonb)', 'execute')
      and has_function_privilege('authenticated', 'public.check_in_extras_valid(jsonb)', 'execute'),
  'validator stays revoked from anon');

-- check-in by user 1; extras live in check_in_extras
do $$ begin perform tests.as_user(tests.u(1)); end $$;
select lives_ok($$ insert into public.check_ins (id, journey_id, user_id, local_date, captured_at, photo_path, thumb_path, extras)
  values (tests.cid(1), tests.jid(), auth.uid(), current_date, now(),
    format('checkins/%s/%s/%s.jpg', tests.jid(), auth.uid(), tests.cid(1)),
    format('checkins/%s/%s/%s_t.jpg', tests.jid(), auth.uid(), tests.cid(1)),
    '{"mood":"leak"}') $$, 'check-in insert');
select is((select extras::text from public.check_ins where id = tests.cid(1)), '{}', 'check_ins.extras is always blanked');
select lives_ok($$ insert into public.check_in_extras (checkin_id, extras)
  values (tests.cid(1), '{"mood":"light","km":5.3}') $$, 'author writes extras');
select throws_ok($$ update public.check_in_extras set extras = '{"km":9999}' where checkin_id = tests.cid(1) $$,
  '23514', null, 'invalid extras rejected');

-- co-member sees them until the author hides them
do $$ begin perform tests.as_user(tests.u(2)); end $$;
select is((select count(*)::int from public.check_in_extras where checkin_id = tests.cid(1)), 1, 'member reads extras');
do $$ begin perform tests.as_user(tests.u(1)); end $$;
select lives_ok($$ update public.memberships set hide_extras = true where journey_id = tests.jid() and user_id = auth.uid() $$,
  'author hides extras');
select is((select count(*)::int from public.check_in_extras where checkin_id = tests.cid(1)), 1, 'author still reads own extras');
do $$ begin perform tests.as_user(tests.u(2)); end $$;
select is((select count(*)::int from public.check_in_extras where checkin_id = tests.cid(1)), 0, 'member no longer reads hidden extras');
do $$ begin perform tests.as_user(tests.u(3)); end $$;
select is((select count(*)::int from public.check_in_extras where checkin_id = tests.cid(1)), 0, 'outsider never reads extras');

-- pin: own row only
do $$ begin perform tests.as_user(tests.u(2)); end $$;
select lives_ok($$ update public.memberships set pinned = true where journey_id = tests.jid() and user_id = auth.uid() $$,
  'member pins for themselves');
select is((select count(*)::int from public.memberships where journey_id = tests.jid() and pinned), 1, 'exactly one pinned row');
with u as (update public.memberships set pinned = true where journey_id = tests.jid() and user_id = tests.u(1) returning 1)
select is((select count(*)::int from u), 0, 'cannot pin on behalf of another member');
with u as (update public.memberships set hide_extras = false where journey_id = tests.jid() and user_id = tests.u(1) returning 1)
select is((select count(*)::int from u), 0, 'cannot unhide another member extras');

select * from finish();
rollback;
