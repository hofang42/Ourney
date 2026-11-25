-- 0027_ux_journeys_fixes: rename_couple / update_journey on unnamed couple journeys (never emoji) + follow_frame layout & A-B8 / FS-22 guards.
begin;
create extension if not exists pgtap with schema extensions;
select plan(12);

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
create function tests.heart_squad_id() returns uuid language sql immutable as $$
  select 'b2700000-0000-4000-8000-000000000004'::uuid $$;
create function tests.active_import_id() returns uuid language sql immutable as $$
  select 'b2700000-0000-4000-8000-000000000005'::uuid $$;
grant execute on all functions in schema tests to authenticated;

insert into auth.users (id, email) select tests.u(n), format('ux27_%s@example.test', n) from generate_series(1, 2) n;
insert into public.profiles (id, username, display_name) select tests.u(n), 'ux27_' || n, 'UX' || n from generate_series(1, 2) n;

do $$ begin
  perform tests.as_user(tests.u(1));
  -- Couple journey created via quick setup without initial couple_self_name / couple_partner_name (2 seats).
  perform public.create_journey(
    tests.couple_unnamed(), 'group', 'custom', 'Two of us', '✨', null, null, false,
    current_date, 30, 'UTC', 2, 'private', null, null
  );
  -- Regular 10-member squad journey (not a couple journey).
  perform public.create_journey(
    tests.squad_id(), 'group', 'custom', 'Squad', '🔥', null, null, false,
    current_date, 30, 'UTC', 10, 'private', null, null
  );
  -- 10-member squad journey with a heart emoji ('💞'): must NOT be treated as a couple journey.
  perform public.create_journey(
    tests.heart_squad_id(), 'group', 'custom', 'Heart Squad', '💞', null, null, false,
    current_date, 30, 'UTC', 10, 'private', null, null
  );
  -- Custom solo journey with a hidden metric and a layout override that has ended and has a public link.
  perform public.create_journey(
    tests.custom_layout_id(), 'solo', 'custom', 'My trip', '✨', 'Weight', 'kg', true,
    current_date - 10, 10, 'UTC', 1, 'private'
  );
  perform public.update_journey(tests.custom_layout_id(), null, 'memory_collectors');
  perform public.end_journey(tests.custom_layout_id());
  perform public.set_public_link(tests.custom_layout_id(), true);
  -- Active continuing imported journey (FS-22).
  perform public.create_imported_journey(
    tests.active_import_id(), 'Continuing Trip', '✈️', 'travel',
    current_date - 20, current_date - 5, 'UTC', 'Weight', 'kg', 'memory_collectors', true
  );
end $$;

do $$ begin perform tests.as_user(tests.u(1)); end $$;

-- 1. Unnamed 2-seat couple journey can set layout := 'couple_rituals' and be renamed via rename_couple (UX-04).
select is(
  (public.update_journey(tests.couple_unnamed(), null, 'couple_rituals')).layout,
  'couple_rituals',
  'owner can set couple_rituals layout on an unnamed 2-member couple journey'
);
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

-- 3. 10-member squad with heart emoji ('💞') rejects couple_rituals layout and rename_couple, keeping max_members = 10.
select throws_ok(
  $$ select public.update_journey(tests.heart_squad_id(), null, 'couple_rituals') $$,
  'P0001',
  'invalid',
  '10-member squad with heart emoji rejects couple_rituals layout'
);
select throws_ok(
  $$ select public.rename_couple(tests.heart_squad_id(), 'An', 'Binh') $$,
  'P0001',
  'invalid',
  '10-member squad with heart emoji rejects rename_couple'
);
select is(
  (select max_members from public.journeys where id = tests.heart_squad_id()),
  10,
  '10-member squad with heart emoji keeps max_members = 10'
);

-- 4. follow_frame includes the customized layout override (UX-19) and preserves A-B8 metric privacy.
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
select is(
  public.follow_frame(tests.custom_layout_id())->>'metric_name',
  'Weight',
  'A-B8: owner/member sees hidden metric_name in follow_frame'
);

do $$ begin perform tests.as_user(tests.u(2)); end $$;
select ok(
  (public.follow_frame(tests.custom_layout_id()))->>'metric_name' is null
  and (public.follow_frame(tests.custom_layout_id()))->>'metric_unit' is null,
  'A-B8: follow_frame hides metric_name/metric_unit from non-members when owner hides metric'
);

-- 5. FS-22: active continuing imported journey cannot be followed before ending.
do $$ begin perform tests.as_user(tests.u(1)); end $$;
select throws_ok(
  $$ select public.follow_frame(tests.active_import_id()) $$,
  'P0001',
  'invalid',
  'FS-22: active continuing imported journey cannot be followed before ending'
);

select * from finish();
rollback;
