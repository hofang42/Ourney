begin;
create extension if not exists pgtap with schema extensions;
select plan(8);

create schema tests;
grant usage on schema tests to anon, authenticated;
create function tests.as_user(u uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', u, 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);
end $$;
create function tests.u(n int) returns uuid language sql immutable as $$
  select format('37000000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function tests.j(n int) returns uuid language sql immutable as $$
  select format('b3700000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function tests.c(n int) returns uuid language sql immutable as $$
  select format('c3700000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;
grant execute on all functions in schema tests to anon, authenticated;

insert into auth.users (id, email)
select tests.u(n), format('wrapped%s@example.test', n) from generate_series(1, 4) n;
insert into public.profiles (id, username, display_name)
select tests.u(n), 'wrapped' || n, 'Member ' || n from generate_series(1, 4) n;

do $$ begin
  perform tests.as_user(tests.u(1));
  perform public.create_journey(tests.j(1), 'group', 'english_daily', 'Study', 'x',
    null, null, false, current_date - 1, 7, 'UTC');
  perform public.create_journey(tests.j(2), 'group', 'custom', 'Couple', 'x',
    null, null, false, current_date - 1, 7, 'UTC', 2, 'group', 'An', 'Mai');
  perform public.create_journey(tests.j(3), 'group', 'english_daily', 'Empty group', 'x',
    null, null, false, current_date - 1, 7, 'UTC');
end $$;
reset role;

insert into public.memberships (journey_id, user_id)
values (tests.j(1), tests.u(2)), (tests.j(1), tests.u(3)), (tests.j(2), tests.u(2));

-- Give one member two check-ins on the same day. The caller owns the deleted
-- and quarantined check-ins, which the check-in SELECT policy lets them read.
insert into public.check_ins (
  id, journey_id, user_id, local_date, captured_at, photo_path, thumb_path, deleted_at, moderated_at
)
select tests.c(c), tests.j(j), tests.u(u), current_date, now(),
       format('checkins/%s/%s/%s.jpg', tests.j(j), tests.u(u), tests.c(c)),
       format('checkins/%s/%s/%s_t.jpg', tests.j(j), tests.u(u), tests.c(c)),
       case when c = 5 then now() end, case when c = 6 then now() end
  from (values (1,1,1), (2,1,2), (3,1,2), (4,1,3), (5,1,1), (6,1,1), (7,2,1)) fixture(c,j,u);

insert into public.reactions (checkin_id, user_id, emoji, deleted_at)
select tests.c(c), tests.u(u), U&'\+01F525', case when deleted then now() end
  from (values
    (1,2,false), (1,3,false), (1,1,true), (2,1,false), (2,2,false),
    (3,1,false), (4,1,false), (5,1,false), (6,1,false), (7,2,false)
  ) fixture(c,u,deleted);

do $$ begin perform tests.as_user(tests.u(1)); end $$;
select is(public.journey_reaction_count(tests.j(1)), 6::bigint,
  'counts live reactions across members and same-day check-ins, excluding deleted or quarantined rows');
select is(public.journey_reaction_count(tests.j(2)), 1::bigint,
  'counts the couple journey separately');
select is(public.journey_reaction_count(tests.j(3)), 0::bigint,
  'a journey with no reactions returns zero');

do $$ begin
  perform tests.as_user(tests.u(2));
  perform public.report_content(tests.c(1), null, 'spam');
end $$;
select is(public.journey_reaction_count(tests.j(1)), 4::bigint,
  'the reporter sees no reactions on the reported check-in, including their own');

do $$ begin
  perform tests.as_user(tests.u(1));
  perform public.block_user(tests.u(3));
  perform public.end_journey(tests.j(1));
end $$;
select is(public.journey_reaction_count(tests.j(1)), 4::bigint,
  'an ended journey omits reactions from blocked users and on their check-ins');

reset role;
update public.memberships set status = 'left' where journey_id = tests.j(1) and user_id = tests.u(2);
do $$ begin perform tests.as_user(tests.u(2)); end $$;
select is(public.journey_reaction_count(tests.j(1)), 0::bigint,
  'a former member gets zero even if they can still read their own check-in and reaction');

do $$ begin perform tests.as_user(tests.u(4)); end $$;
select is(public.journey_reaction_count(tests.j(1)), 0::bigint,
  'an authenticated outsider gets zero');

set local role anon;
select throws_ok($$ select public.journey_reaction_count(tests.j(1)) $$,
  '42501', null, 'anonymous callers cannot invoke the count');

select * from finish();
rollback;
