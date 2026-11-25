-- 0027_ux_journeys_fixes: rename_couple on unnamed couple journeys + follow_frame layout.
begin;
create extension if not exists pgtap with schema extensions;
select plan(5);

create schema tests;
grant usage on schema tests to authenticated;
create function tests.as_user(u uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', u, 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);
end $$;
create function tests.u(n int) returns uuid language sql immutable as $$
  select format('a2700000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function tests.couple_unnamed() returns uuid language sql immutable as $$
  select 'b2700000-0000-4000-8000-000000000001'::uuid $$;
create function tests.squad_id() returns uuid language sql immutable as $$
  select 'b2700000-0000-4000-8000-000000000002'::uuid $$;
create function tests.custom_layout_id() returns uuid language sql immutable as $$
  select 'b2700000-0000-4000-8000-000000000003'::uuid $$;
grant execute on all functions in schema tests to authenticated;

insert into auth.users (id, email) select tests.u(n), format('ux27_%s@example.test', n) from generate_series(1, 2) n;
insert into public.profiles (id, username, display_name) select tests.u(n), 'ux27_' || n, 'UX' || n from generate_series(1, 2) n;

do $$ begin
  perform tests.as_user(tests.u(1));
  -- Couple journey created via quick setup without initial couple_self_name / couple_partner_name.
  perform public.create_journey(
    tests.couple_unnamed(), 'group', 'custom', 'Two of us', '💞', null, null, false,
    current_date, 30, 'UTC', 2, 'private', null, null
  );
  -- Regular 10-member squad journey (not a couple journey).
  perform public.create_journey(
    tests.squad_id(), 'group', 'custom', 'Squad', '🔥', null, null, false,
    current_date, 30, 'UTC', 10, 'private', null, null
  );
  -- Custom solo journey with a layout override that has ended.
  perform public.create_journey(
    tests.custom_layout_id(), 'solo', 'custom', 'My trip', '✨', null, null, false,
    current_date - 5, 5, 'UTC', 1, 'private', null, null, null, null, 0, 'memory_collectors'
  );
  perform public.end_journey(tests.custom_layout_id());
end $$;

do $$ begin perform tests.as_user(tests.u(1)); end $$;

-- 1. Unnamed couple journey can be renamed via rename_couple (UX-04).
select is(
  (public.rename_couple(tests.couple_unnamed(), 'An', 'Binh')).couple_self_name,
  'An',
  'owner can set couple names on a 2-member couple journey even when initially null'
);
select is(
  (select couple_partner_name from public.journeys where id = tests.couple_unnamed()),
  'Binh',
  'couple_partner_name is persisted'
);

-- 2. Non-couple 10-member squad journey still rejects rename_couple.
select throws_ok(
  $$ select public.rename_couple(tests.squad_id(), 'An', 'Binh') $$,
  'P0001',
  'invalid',
  '10-member non-couple squad still rejects rename_couple'
);

-- 3. follow_frame includes the customized layout override (UX-19).
select is(
  public.follow_frame(tests.custom_layout_id())->>'layout',
  'memory_collectors',
  'follow_frame returns the journey layout override'
);
select is(
  public.follow_frame(tests.custom_layout_id())->>'template_id',
  'custom',
  'follow_frame preserves template_id alongside layout'
);

select * from finish();
rollback;
