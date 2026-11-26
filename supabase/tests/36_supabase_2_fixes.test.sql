-- 0036_supabase_2_fixes: pgTAP verification of F-27 and F-28.
begin;
create extension if not exists pgtap with schema extensions;
select plan(12);

create schema tests;
grant usage on schema tests to anon, authenticated, service_role;

create function tests.as_user(u uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', u, 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);
end $$;

create function tests.as_service_role() returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);
  perform set_config('role', 'service_role', true);
end $$;

create function tests.as_postgres() returns void language plpgsql as $$
begin
  perform set_config('role', 'postgres', true);
  perform set_config('request.jwt.claims', '', true);
end $$;

create function tests.u(n int) returns uuid language sql immutable as $$
  select format('36000000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function tests.j(n int) returns uuid language sql immutable as $$
  select format('b3600000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function tests.c(n int) returns uuid language sql immutable as $$
  select format('c3600000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function tests.m(n int) returns uuid language sql immutable as $$
  select format('d3600000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function tests.photo(j uuid, u uuid, c uuid) returns text language sql immutable as $$
  select format('checkins/%s/%s/%s.jpg', j, u, c) $$;
create function tests.thumb(j uuid, u uuid, c uuid) returns text language sql immutable as $$
  select format('checkins/%s/%s/%s_t.jpg', j, u, c) $$;
create function tests.token(j uuid) returns text language sql security definer as $$
  select public_token from public.journeys where id = j $$;
create function tests.slug(j uuid) returns text language sql security definer as $$
  select public_slug from public.journeys where id = j $$;

grant execute on all functions in schema tests to anon, authenticated, service_role;

insert into auth.users (id, email)
select tests.u(n), format('sec36_%s@example.test', n) from generate_series(1, 8) n;

insert into public.profiles (id, username, display_name)
select tests.u(n), 'sec36user' || n, 'Sec36 ' || n from generate_series(1, 8) n;

-- ============================================================================
-- 1. F-27: _journeys_dying_with vs _leave_journey soft-deleted co-member alignment
-- ============================================================================
do $$ declare
  v_code1 text;
  v_code2 text;
  v_conv uuid;
begin
  -- Group journey j(1): owned by u(1), joined by u(2) who has a check-in and a chat conversation
  -- on j(1) with viewer u(5), and then u(2)'s profile is soft-deleted (deleted_at IS NOT NULL).
  perform tests.as_user(tests.u(1));
  v_code1 := (public.create_journey(
    tests.j(1), 'group', 'custom', 'Ghost Co-Member Group', '🔥',
    null, null, false, current_date - 3, 30, 'UTC'
  )).invite_code;

  insert into storage.objects (bucket_id, name) values
    ('media', tests.photo(tests.j(1), tests.u(1), tests.c(1))),
    ('media', tests.thumb(tests.j(1), tests.u(1), tests.c(1)));
  insert into public.check_ins (id, journey_id, user_id, local_date, captured_at, photo_path, thumb_path)
  values (tests.c(1), tests.j(1), tests.u(1), current_date, now(),
          tests.photo(tests.j(1), tests.u(1), tests.c(1)),
          tests.thumb(tests.j(1), tests.u(1), tests.c(1)));

  perform tests.as_user(tests.u(2));
  perform public.join_by_code(v_code1);
  insert into storage.objects (bucket_id, name) values
    ('media', tests.photo(tests.j(1), tests.u(2), tests.c(2))),
    ('media', tests.thumb(tests.j(1), tests.u(2), tests.c(2)));
  insert into public.check_ins (id, journey_id, user_id, local_date, captured_at, photo_path, thumb_path)
  values (tests.c(2), tests.j(1), tests.u(2), current_date, now(),
          tests.photo(tests.j(1), tests.u(2), tests.c(2)),
          tests.thumb(tests.j(1), tests.u(2), tests.c(2)));

  -- Create a conversation on j(1) between co-member u(2) and viewer u(5) with a message photo
  perform tests.as_postgres();
  insert into public.conversations (id, journey_id, member_id, viewer_id)
  values ('e3600000-0000-4000-8000-000000000001'::uuid, tests.j(1), tests.u(2), tests.u(5));
  v_conv := 'e3600000-0000-4000-8000-000000000001'::uuid;
  insert into storage.objects (bucket_id, name)
  values ('messages', format('messages/%s/%s/%s.jpg', v_conv, tests.u(2), tests.m(1)));

  -- Soft-delete co-member u(2)'s profile while membership row remains status = 'active'
  update public.profiles set deleted_at = now() where id = tests.u(2);

  -- Group journey j(2): owned by u(3), joined by live co-member u(4) (profiles.deleted_at IS NULL)
  perform tests.as_user(tests.u(3));
  v_code2 := (public.create_journey(
    tests.j(2), 'group', 'custom', 'Live Co-Member Group', '🌱',
    null, null, false, current_date - 3, 30, 'UTC'
  )).invite_code;
  insert into storage.objects (bucket_id, name) values
    ('media', tests.photo(tests.j(2), tests.u(3), tests.c(3))),
    ('media', tests.thumb(tests.j(2), tests.u(3), tests.c(3)));
  insert into public.check_ins (id, journey_id, user_id, local_date, captured_at, photo_path, thumb_path)
  values (tests.c(3), tests.j(2), tests.u(3), current_date, now(),
          tests.photo(tests.j(2), tests.u(3), tests.c(3)),
          tests.thumb(tests.j(2), tests.u(3), tests.c(3)));

  perform tests.as_user(tests.u(4));
  perform public.join_by_code(v_code2);
  insert into storage.objects (bucket_id, name) values
    ('media', tests.photo(tests.j(2), tests.u(4), tests.c(4))),
    ('media', tests.thumb(tests.j(2), tests.u(4), tests.c(4)));
  insert into public.check_ins (id, journey_id, user_id, local_date, captured_at, photo_path, thumb_path)
  values (tests.c(4), tests.j(2), tests.u(4), current_date, now(),
          tests.photo(tests.j(2), tests.u(4), tests.c(4)),
          tests.thumb(tests.j(2), tests.u(4), tests.c(4)));
end $$;

do $$ begin perform tests.as_postgres(); end $$;

-- [Test 1] _journeys_dying_with(u(1)) includes j(1) when the only other active member has a soft-deleted profile
select is(
  array(select public._journeys_dying_with(tests.u(1))),
  array[tests.j(1)],
  'F-27: _journeys_dying_with includes group journey whose only other active member has a soft-deleted profile'
);

-- [Test 2] _journeys_dying_with(u(3)) does NOT include j(2) because co-member u(4) has an active non-deleted profile
select is(
  array(select public._journeys_dying_with(tests.u(3))),
  array[]::uuid[],
  'F-27: _journeys_dying_with excludes group journey with a live active co-member'
);

-- [Test 3] account_media_paths(u(1)) includes co-member u(2)'s check-in objects on dying journey j(1)
select ok(
  tests.photo(tests.j(1), tests.u(2), tests.c(2)) in (select public.account_media_paths(tests.u(1)))
  and tests.thumb(tests.j(1), tests.u(2), tests.c(2)) in (select public.account_media_paths(tests.u(1))),
  'F-27: account_media_paths includes soft-deleted co-member check-in objects on dying journey'
);

-- [Test 4] account_message_paths(u(1)) includes conversation message objects on dying journey j(1) even when u(1) is not a conversation participant
select ok(
  format('messages/%s/%s/%s.jpg', 'e3600000-0000-4000-8000-000000000001'::uuid, tests.u(2), tests.m(1))
    in (select public.account_message_paths(tests.u(1))),
  'F-27: account_message_paths includes conversation message objects belonging to a dying journey'
);

-- [Test 5] Deleting owner u(1)'s account queues all media and message objects of j(1) into pending_storage_purge and deletes j(1)
do $$ begin
  perform tests.as_postgres();
  delete from private.pending_storage_purge;
  delete from auth.users where id = tests.u(1);
end $$;

select is(
  (select count(*)::int from public.journeys where id = tests.j(1)),
  0,
  'F-27: group journey with only soft-deleted co-member is deleted when owner account is purged'
);

-- [Test 6] Co-member check-in media and journey conversation message media are queued in pending_storage_purge
select is(
  (select count(*)::int
     from private.pending_storage_purge
    where (bucket = 'media' and path in (
            tests.photo(tests.j(1), tests.u(1), tests.c(1)),
            tests.thumb(tests.j(1), tests.u(1), tests.c(1)),
            tests.photo(tests.j(1), tests.u(2), tests.c(2)),
            tests.thumb(tests.j(1), tests.u(2), tests.c(2))
          ))
       or (bucket = 'messages' and path = format(
            'messages/%s/%s/%s.jpg',
            'e3600000-0000-4000-8000-000000000001'::uuid, tests.u(2), tests.m(1)
          ))),
  5,
  'F-27: purge_account_data queues both owner and soft-deleted co-member media + message Storage objects'
);

-- [Test 7] Deleting owner u(3)'s account transfers j(2) ownership to live co-member u(4) and does NOT purge u(4)'s media
do $$ begin
  perform tests.as_postgres();
  delete from private.pending_storage_purge;
  delete from auth.users where id = tests.u(3);
end $$;

select is(
  (select owner_id from public.journeys where id = tests.j(2)),
  tests.u(4),
  'F-27: group journey with a live co-member transfers ownership to the live co-member on owner deletion'
);

-- [Test 8] Live co-member u(4)'s check-in photo is not queued for purge
select is(
  (select count(*)::int
     from private.pending_storage_purge
    where path = tests.photo(tests.j(2), tests.u(4), tests.c(4))),
  0,
  'F-27: surviving group live co-member photo is never queued in pending_storage_purge'
);

-- ============================================================================
-- 2. F-28: SQL follow_count in lookup_public_journey_for_edge
-- ============================================================================
do $$ begin
  perform tests.as_user(tests.u(5));
  perform public.create_journey(
    tests.j(5), 'solo', 'travel', 'Popular Shared Journey', '🏔️',
    null, null, false, current_date - 10, 10, 'UTC'
  );
  perform public.end_journey(tests.j(5));
  perform public.set_readable_public_link(tests.j(5), true, false, 'Popular Shared Journey');
  perform public.update_public_settings(tests.j(5), true, true, false);

  -- u(6) opens the link and creates 2 followed journeys from j(5) (should count as 1 distinct owner_id)
  perform tests.as_user(tests.u(6));
  perform public.public_journey_by_token(tests.slug(tests.j(5)));
  perform public.create_journey(tests.j(61), 'solo', 'travel', 'Follow 1', '🏔️', null, null, false, current_date, 10, 'UTC');
  perform public.mark_followed(tests.j(61), tests.j(5));
  perform public.create_journey(tests.j(62), 'solo', 'travel', 'Follow 2', '🏔️', null, null, false, current_date, 10, 'UTC');
  perform public.mark_followed(tests.j(62), tests.j(5));

  -- u(7) opens the link and creates 1 followed journey from j(5)
  perform tests.as_user(tests.u(7));
  perform public.public_journey_by_token(tests.slug(tests.j(5)));
  perform public.create_journey(tests.j(71), 'solo', 'travel', 'Follow 3', '🏔️', null, null, false, current_date, 10, 'UTC');
  perform public.mark_followed(tests.j(71), tests.j(5));

  -- u(8) opens the link, creates 1 followed journey, then soft-deletes that journey (should not be counted)
  perform tests.as_user(tests.u(8));
  perform public.public_journey_by_token(tests.slug(tests.j(5)));
  perform public.create_journey(tests.j(81), 'solo', 'travel', 'Follow Deleted', '🏔️', null, null, false, current_date, 10, 'UTC');
  perform public.mark_followed(tests.j(81), tests.j(5));
  perform public.delete_journey(tests.j(81));
end $$;

-- [Test 9] When show_counts is true (default), lookup_public_journey_for_edge returns exact distinct owner follow_count
do $$ begin perform tests.as_service_role(); end $$;
select is(
  (public.lookup_public_journey_for_edge(tests.slug(tests.j(5)), repeat('a', 64))->'journey'->>'follow_count')::int,
  2,
  'F-28: lookup_public_journey_for_edge computes exact distinct non-deleted follower owner count in SQL'
);

-- [Test 10] When show_counts is false, lookup_public_journey_for_edge returns follow_count = 0
do $$ begin
  perform tests.as_user(tests.u(5));
  perform public.update_public_settings(tests.j(5), false, true, false);
  perform tests.as_service_role();
end $$;
select is(
  (public.lookup_public_journey_for_edge(tests.slug(tests.j(5)), repeat('b', 64))->'journey'->>'follow_count')::int,
  0,
  'F-28: lookup_public_journey_for_edge returns follow_count = 0 when show_counts is false'
);

-- [Test 11] lookup_public_journey_for_edge remains restricted to service_role only
select ok(
  has_function_privilege('service_role', 'public.lookup_public_journey_for_edge(text,text)', 'execute')
  and not has_function_privilege('anon', 'public.lookup_public_journey_for_edge(text,text)', 'execute')
  and not has_function_privilege('authenticated', 'public.lookup_public_journey_for_edge(text,text)', 'execute'),
  'F-28: lookup_public_journey_for_edge remains executable only by service_role'
);

-- [Test 12] _journeys_dying_with remains not callable by anon or authenticated
select ok(
  not has_function_privilege('anon', 'public._journeys_dying_with(uuid)', 'execute')
  and not has_function_privilege('authenticated', 'public._journeys_dying_with(uuid)', 'execute'),
  'F-27: _journeys_dying_with is revoked from anon and authenticated'
);

select * from finish();
rollback;
