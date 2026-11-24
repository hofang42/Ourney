-- 0023_admin: pgTAP verification of Admin Dashboard schema, privilege invariants,
--             dynamic non-admin/banned-admin 42501 denial across all 30 admin.* RPCs,
--             role matrix (moderator vs owner), A2 reversible ban vs wipe-UGC ban without
--             touching profiles.deleted_at, 5-minute reported-media grants, journey title
--             redaction, and append-only audit log immutability.
--
-- Follows repo pgTAP rules (A6): no psql :'var' inside DO blocks, no data-modifying CTEs
-- inside pgTAP assertions, writes run in separate statements before assertion queries.
begin;
create extension if not exists pgtap with schema extensions;
select plan(56);

create schema tests;
grant usage on schema tests to anon, authenticated, service_role;

create function tests.as_user(u uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', u, 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);
end $$;

create function tests.as_anon() returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', '{"role":"anon"}', true);
  perform set_config('role', 'anon', true);
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
  select format('23000000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function tests.j(n int) returns uuid language sql immutable as $$
  select format('b2300000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function tests.c(n int) returns uuid language sql immutable as $$
  select format('c2300000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function tests.m(n int) returns uuid language sql immutable as $$
  select format('d2300000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;

-- Dynamically enumerates every function in schema `admin` from pg_proc and verifies
-- that calling it as the current user raises SQLSTATE 42501 ('forbidden').
create function tests.count_admin_rpcs_denying_caller() returns int
language plpgsql
as $$
declare
  r record;
  v_denied int := 0;
begin
  for r in
    select p.oid,
           p.proname,
           coalesce((
             select string_agg(format('null::%s', t.typid::regtype), ', ' order by t.ord)
               from unnest(p.proargtypes::oid[]) with ordinality as t(typid, ord)
           ), '') as args
      from pg_proc p
     where p.pronamespace = 'admin'::regnamespace
     order by p.proname, p.oid
  loop
    begin
      execute format('select admin.%I(%s)', r.proname, r.args);
      raise exception 'SECURITY BREACH: admin.%(%) did not raise 42501 for unauthorized caller', r.proname, r.args;
    exception
      when sqlstate '42501' then
        v_denied := v_denied + 1;
    end;
  end loop;
  return v_denied;
end;
$$;

grant execute on all functions in schema tests to anon, authenticated, service_role;

-- Seed test accounts:
--   u(1): Owner admin
--   u(2): Moderator admin
--   u(3): Regular non-admin user (reporter / journey owner)
--   u(4): Regular non-admin user (reported user / offender)
--   u(5): Second owner admin (for testing owner removal & demotion)
insert into auth.users (id, email)
values
  (tests.u(1), 'owner1@ourney.tech'),
  (tests.u(2), 'mod1@ourney.tech'),
  (tests.u(3), 'member3@example.test'),
  (tests.u(4), 'offender4@example.test'),
  (tests.u(5), 'owner2@ourney.tech');

insert into public.profiles (id, username, display_name)
values
  (tests.u(1), 'admin_owner1', 'Owner One'),
  (tests.u(2), 'admin_mod1', 'Mod One'),
  (tests.u(3), 'user_three', 'User Three'),
  (tests.u(4), 'user_four', 'User Four'),
  (tests.u(5), 'admin_owner2', 'Owner Two');

insert into private.admins (user_id, role, note, added_by)
values
  (tests.u(1), 'owner', 'Bootstrap owner', tests.u(1)),
  (tests.u(2), 'moderator', 'Support moderator', tests.u(1));

-- ============================================================================
-- 1. Structural & Privilege Invariants
-- ============================================================================
-- [Test 1] All 4 private admin tables exist and have RLS enabled
select is(
  (select bool_and(relrowsecurity)
     from pg_class
    where oid in (
      'private.admins'::regclass,
      'private.admin_audit'::regclass,
      'private.admin_media_grants'::regclass,
      'private.user_moderation'::regclass
    )),
  true,
  'RLS is enabled on private.admins, private.admin_audit, private.admin_media_grants, and private.user_moderation'
);

-- [Test 2] anon and authenticated have zero table privileges on the 4 private admin tables
select is(
  (select count(*)::int
     from information_schema.role_table_grants
    where table_schema = 'private'
      and table_name in ('admins', 'admin_audit', 'admin_media_grants', 'user_moderation')
      and grantee in ('anon', 'authenticated')),
  0,
  'anon and authenticated have zero direct table grants on private admin tables'
);

-- [Test 3] Schema `admin` contains zero tables, views, or materialized views
select is(
  (select count(*)::int
     from pg_class c
     join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'admin'
      and c.relkind in ('r', 'p', 'v', 'm', 'f')),
  0,
  'schema admin contains zero tables, views, or materialized views (RPC-only)'
);

-- [Test 4] Schema `admin` has all expected RPC functions (30 base in 0023 + 5 feature_requests in 0024)
select is(
  (select count(*)::int from pg_proc where pronamespace = 'admin'::regnamespace),
  35,
  'schema admin exposes the 35 admin.* RPC functions (30 base + 5 feature_requests)'
);

-- [Test 5] Every function in schema `admin` and `private` is SECURITY DEFINER and pins search_path = ''
select is(
  (select count(*)::int
     from pg_proc p
     join pg_namespace n on n.oid = p.pronamespace
    where (n.nspname = 'admin' or (n.nspname = 'private' and p.prosecdef))
      and (
        not p.prosecdef
        or not coalesce(exists (select 1 from unnest(p.proconfig) c where c like 'search_path=%'), false)
      )),
  0,
  'every function in admin and every SECURITY DEFINER function in private pins empty search_path'
);

-- [Test 6] anon has no USAGE on schema admin and no EXECUTE on any admin.* function
select is(
  has_schema_privilege('anon', 'admin', 'usage')
  or exists (
    select 1 from pg_proc p
     where p.pronamespace = 'admin'::regnamespace
       and has_function_privilege('anon', p.oid, 'execute')
  ),
  false,
  'anon has zero USAGE on schema admin and zero EXECUTE on any admin.* function'
);

-- [Test 7] Exported helpers private.require_admin and private.admin_log are not callable by anon or authenticated
select is(
  has_function_privilege('anon', 'private.require_admin(text)', 'execute')
  or has_function_privilege('authenticated', 'private.require_admin(text)', 'execute')
  or has_function_privilege('anon', 'private.admin_log(text, text, text, text, jsonb)', 'execute')
  or has_function_privilege('authenticated', 'private.admin_log(text, text, text, text, jsonb)', 'execute')
  or has_function_privilege('authenticated', 'private.is_user_banned(uuid)', 'execute')
  or has_function_privilege('authenticated', 'public.admin_service_get_waitlist_targets(uuid, int)', 'execute')
  or has_function_privilege('authenticated', 'public.admin_service_record_audit(uuid, text, text, text, text, jsonb)', 'execute'),
  false,
  'private.require_admin, private.admin_log, private.is_user_banned, and admin_service_* helpers are not directly callable by clients'
);

-- ============================================================================
-- 2. Dynamic Authorization Matrix: Non-Admin, Banned Admin, Moderator vs Owner
-- ============================================================================
-- [Test 8] Non-admin authenticated user receives 42501 on every single admin.* RPC in pg_proc
do $$ begin perform tests.as_user(tests.u(3)); end $$;
select is(
  tests.count_admin_rpcs_denying_caller(),
  35,
  'A5: non-admin authenticated user receives 42501 on every admin.* RPC in pg_proc'
);

-- [Test 9] Banned admin (auth.users.banned_until > now()) receives 42501 on every single admin.* RPC
do $$ begin
  perform tests.as_postgres();
  update auth.users set banned_until = now() + interval '1 day' where id = tests.u(2);
  perform tests.as_user(tests.u(2));
end $$;
select is(
  tests.count_admin_rpcs_denying_caller(),
  35,
  'banned admin (auth.users.banned_until > now()) receives 42501 on every admin.* RPC'
);

do $$ begin
  perform tests.as_postgres();
  update auth.users set banned_until = null where id = tests.u(2);
end $$;

-- [Test 10] Moderator succeeds on admin.me() and sees role = 'moderator'
do $$ begin perform tests.as_user(tests.u(2)); end $$;
select is(
  admin.me() ->> 'role',
  'moderator',
  'moderator calls admin.me() and receives role = moderator'
);

-- [Test 11] Moderator is denied (42501) on owner-only admin.export_waitlist
select throws_ok(
  $$ select admin.export_waitlist() $$,
  '42501', 'forbidden',
  'moderator receives 42501 on owner-only admin.export_waitlist'
);

-- [Test 12] Moderator is denied (42501) on owner-only admin.delete_waitlist_entry
select throws_ok(
  $$ select admin.delete_waitlist_entry(gen_random_uuid(), 'test') $$,
  '42501', 'forbidden',
  'moderator receives 42501 on owner-only admin.delete_waitlist_entry'
);

-- [Test 13] Moderator is denied (42501) on owner-only admin.upsert_admin_user
select throws_ok(
  $$ select admin.upsert_admin_user('owner2@ourney.tech', 'moderator', 'try add') $$,
  '42501', 'forbidden',
  'moderator receives 42501 on owner-only admin.upsert_admin_user'
);

-- [Test 14] Moderator is denied (42501) on owner-only admin.remove_admin_user
select throws_ok(
  $$ select admin.remove_admin_user(tests.u(1), 'try remove owner') $$,
  '42501', 'forbidden',
  'moderator receives 42501 on owner-only admin.remove_admin_user'
);

-- ============================================================================
-- 3. Settings & Admin Team Management (Last-Owner Protection)
-- ============================================================================
do $$ begin perform tests.as_user(tests.u(1)); end $$;

-- [Test 15] Last remaining owner cannot remove themselves
select throws_ok(
  $$ select admin.remove_admin_user(tests.u(1), 'self remove') $$,
  'P0001', 'cannot_remove_last_owner',
  'last remaining owner cannot remove themselves'
);

-- [Test 16] Last remaining owner cannot demote themselves to moderator
select throws_ok(
  $$ select admin.upsert_admin_user('owner1@ourney.tech', 'moderator', 'self demote') $$,
  'P0001', 'cannot_remove_last_owner',
  'last remaining owner cannot demote themselves to moderator'
);

-- [Test 17] Owner can promote u(5) by email to owner, then demote u(5) to moderator, then remove u(5)
do $$ begin
  perform tests.as_user(tests.u(1));
  perform admin.upsert_admin_user('owner2@ourney.tech', 'owner', 'co-owner');
end $$;
select is(
  (select count(*)::int from jsonb_array_elements(admin.list_admins()) x where x ->> 'role' = 'owner'),
  2,
  'upsert_admin_user adds a second owner by email'
);

do $$ begin
  perform tests.as_user(tests.u(1));
  perform admin.upsert_admin_user(tests.u(5)::text, 'moderator', 'step down to mod');
  perform admin.remove_admin_user(tests.u(5), 'offboarded');
end $$;
select is(
  (select count(*)::int from jsonb_array_elements(admin.list_admins()) x where (x ->> 'user_id')::uuid = tests.u(5)),
  0,
  'owner can demote and remove another admin when at least one owner remains'
);

-- ============================================================================
-- 4. Content Filter Words CRUD & Dry-Run Tester
-- ============================================================================
do $$ begin perform tests.as_user(tests.u(2)); end $$;

-- [Test 18] test_content_filter detects seeded Vietnamese profanity and passes benign diacritics
select is(
  ((admin.test_content_filter('Hôm nay vãi lồn thật') ->> 'blocked')::boolean)
  and not ((admin.test_content_filter('Các bạn lớn đi du lịch Đà Lạt') ->> 'blocked')::boolean),
  true,
  'test_content_filter flags seeded profanity and passes benign Vietnamese diacritics'
);

-- [Test 19] Moderator can upsert, toggle, list, and delete a filter word with audit logging
do $$ begin
  perform tests.as_user(tests.u(2));
  perform admin.upsert_objectionable_word('AdminTestSlur', 'en', 'word', 'slur', true);
end $$;
select is(
  (admin.test_content_filter('hello admintestslur world') ->> 'term'),
  'admintestslur',
  'upsert_objectionable_word normalizes term and activates it in test_content_filter'
);

do $$ begin
  perform tests.as_user(tests.u(2));
  perform admin.set_objectionable_word_enabled('admintestslur', false);
end $$;
select is(
  (admin.test_content_filter('hello admintestslur world') ->> 'blocked')::boolean,
  false,
  'set_objectionable_word_enabled disables term immediately'
);

do $$ begin
  perform tests.as_user(tests.u(2));
  perform admin.delete_objectionable_word('admintestslur', 'cleanup test word');
end $$;
select is(
  jsonb_array_length(admin.list_objectionable_words('admintestslur', null, null, null, null)),
  0,
  'delete_objectionable_word removes the word from private.objectionable_words'
);

-- ============================================================================
-- 5. Waitlist Summary, List, Owner-Only CSV Export & SHA-256 Delete
-- ============================================================================
do $$ begin
  perform tests.as_service_role();
  perform public.waitlist_signup('owner1@ourney.tech', 'vi', array['ios', 'android'], 'hero', null);
  perform public.waitlist_signup('beta_waiter@example.test', 'en', array['ios'], 'footer', null);
end $$;

do $$ begin perform tests.as_user(tests.u(2)); end $$;

-- [Test 20] waitlist_summary and list_waitlist compute totals and registered_in_app conversion
select is(
  (admin.waitlist_summary(30) ->> 'total')::int = 2
  and (admin.waitlist_summary(30) ->> 'converted_count')::int = 1
  and (admin.list_waitlist('beta_waiter', 'en', 'ios', 'all', 'waiting', 50, 0) ->> 'total')::int = 1,
  true,
  'waitlist_summary and list_waitlist report signups, filters, and registered conversion count'
);

-- [Test 21] Owner exports CSV (P2-4: formula-leading characters stripped on email and source) and deletes waitlist entry
do $$ begin
  perform tests.as_service_role();
  perform public.waitlist_signup('=cmd@example.test', 'en', array['ios'], '=evil_source', null);
  perform tests.as_user(tests.u(1));
end $$;
select ok(
  position('beta_waiter@example.test' in admin.export_waitlist()) > 0
  and position('"cmd@example.test"' in admin.export_waitlist()) > 0
  and position('"evil_source"' in admin.export_waitlist()) > 0
  and position('"=cmd@example.test"' in admin.export_waitlist()) = 0
  and position('"=evil_source"' in admin.export_waitlist()) = 0,
  'P2-4: admin.export_waitlist exports CSV and strips leading formula characters from email and source'
);

do $$
declare
  v_wid uuid;
  v_evil_wid uuid;
begin
  perform tests.as_postgres();
  select id into v_wid from private.waitlist where email = 'beta_waiter@example.test';
  select id into v_evil_wid from private.waitlist where email = '=cmd@example.test';
  perform tests.as_user(tests.u(1));
  perform admin.delete_waitlist_entry(v_wid, 'GDPR erasure test');
  perform admin.delete_waitlist_entry(v_evil_wid, 'cleanup formula test');
  perform tests.as_postgres();
end $$;

-- [Test 22] Deleted waitlist audit entry stores email_sha256 and never plaintext email
select is(
  exists (
    select 1 from private.admin_audit
     where action = 'waitlist.delete'
       and (meta ->> 'email_sha256') = encode(extensions.digest('beta_waiter@example.test', 'sha256'), 'hex')
       and position('beta_waiter@example.test' in meta::text) = 0
  ),
  true,
  'delete_waitlist_entry logs sha256(email) in private.admin_audit without plaintext email'
);

-- ============================================================================
-- 6. Privacy-Redacted Journeys & Public Link Kill-Switch
-- ============================================================================
do $$ begin
  -- u(3) creates a private solo journey and a public-link ended solo journey
  perform tests.as_user(tests.u(3));
  perform public.create_journey(tests.j(1), 'solo', 'weight_loss', 'Secret Weight Diary', '⚖️',
                                'Weight', 'kg', true, current_date - 5, 30, 'UTC');
  perform public.create_journey(tests.j(2), 'solo', 'travel', 'Public Da Lat Trip', '🏔️',
                                null, null, false, current_date - 5, 30, 'UTC');
  perform public.end_journey(tests.j(2));
  perform public.set_public_link(tests.j(2), true);
end $$;

do $$ begin perform tests.as_user(tests.u(2)); end $$;

-- [Test 23] admin.list_journeys redacts private journey title to NULL and exposes public-link title
select is(
  (select (item ->> 'title') is null and (item ->> 'emoji') is null
     from jsonb_array_elements(admin.list_journeys(null, 'all', 'all', 'all', false, 50, 0) -> 'items') item
    where (item ->> 'id')::uuid = tests.j(1))
  and
  (select (item ->> 'title') = 'Public Da Lat Trip' and (item ->> 'has_public_link')::boolean = true
     from jsonb_array_elements(admin.list_journeys(null, 'all', 'all', 'all', false, 50, 0) -> 'items') item
    where (item ->> 'id')::uuid = tests.j(2)),
  true,
  'admin.list_journeys returns NULL title/emoji for private journeys and non-null only when public_token IS NOT NULL'
);

-- [Test 24] admin.revoke_journey_public_link revokes public_token and immediately redacts title in admin.list_journeys
do $$ begin
  perform tests.as_user(tests.u(2));
  perform admin.revoke_journey_public_link(tests.j(2), 'abused public share link');
end $$;
select is(
  (select (item ->> 'has_public_link')::boolean = false and (item ->> 'title') is null
     from jsonb_array_elements(admin.list_journeys(null, 'all', 'all', 'all', false, 50, 0) -> 'items') item
    where (item ->> 'id')::uuid = tests.j(2)),
  true,
  'revoke_journey_public_link clears public_token and redacts the journey title'
);

-- ============================================================================
-- 7. Moderation Queue, Scoped Content Excerpt & 5-Minute Audited Media Grants
-- ============================================================================
do $$
declare
  v_code text;
begin
  -- u(3) creates group journey j(3) and captures its invite_code BEFORE switching to u(4)
  -- (journeys_select RLS only lets members read public.journeys).
  perform tests.as_user(tests.u(3));
  v_code := (public.create_journey(tests.j(3), 'group', 'custom', 'Squad Habit', '🔥',
                                   null, null, false, current_date - 3, 30, 'UTC')).invite_code;
  perform tests.as_user(tests.u(4));
  perform public.join_by_code(v_code);

  -- u(3) posts an unreported check-in c(1) with private media
  perform tests.as_user(tests.u(3));
  insert into public.check_ins (id, journey_id, user_id, local_date, captured_at, photo_path, thumb_path, caption)
  values (
    tests.c(1), tests.j(3), tests.u(3), current_date, now(),
    format('checkins/%s/%s/%s.jpg', tests.j(3), tests.u(3), tests.c(1)),
    format('checkins/%s/%s/%s_t.jpg', tests.j(3), tests.u(3), tests.c(1)),
    'Private unreported photo'
  );
  insert into storage.objects (bucket_id, name)
  values ('media', format('checkins/%s/%s/%s.jpg', tests.j(3), tests.u(3), tests.c(1)));

  -- u(4) posts a check-in c(2) with media that u(3) then reports
  perform tests.as_user(tests.u(4));
  insert into public.check_ins (id, journey_id, user_id, local_date, captured_at, photo_path, thumb_path, caption)
  values (
    tests.c(2), tests.j(3), tests.u(4), current_date, now(),
    format('checkins/%s/%s/%s.jpg', tests.j(3), tests.u(4), tests.c(2)),
    format('checkins/%s/%s/%s_t.jpg', tests.j(3), tests.u(4), tests.c(2)),
    'Reported offensive check-in caption'
  );
  insert into storage.objects (bucket_id, name)
  values
    ('media', format('checkins/%s/%s/%s.jpg', tests.j(3), tests.u(4), tests.c(2))),
    ('media', format('checkins/%s/%s/%s_t.jpg', tests.j(3), tests.u(4), tests.c(2)));

  perform tests.as_user(tests.u(3));
  perform public.report_content(tests.c(2), tests.u(4), 'nudity', 'explicit image in group');
end $$;

-- [Test 25] Admin CANNOT read unreported check-in media OR reported check-in media before reveal_reported_media
do $$ begin perform tests.as_user(tests.u(2)); end $$;
select is(
  (select count(*)::int from storage.objects where bucket_id = 'media' and name like 'checkins/%'),
  0,
  'A4: admin cannot read any check-in storage.objects before reveal_reported_media'
);

-- [Test 26] admin.get_moderation_item returns scoped reported caption and logs moderation.view_item
do $$
declare
  v_qid uuid;
  v_item jsonb;
begin
  perform tests.as_user(tests.u(2));
  select (item ->> 'id')::uuid into v_qid
    from jsonb_array_elements(admin.list_moderation_queue('open', 'report', 'nudity', 50, 0) -> 'items') item
   where (item ->> 'target_checkin_id')::uuid = tests.c(2);
  v_item := admin.get_moderation_item(v_qid);
  if (v_item #>> '{reported_content,caption}') <> 'Reported offensive check-in caption' then
    raise exception 'unexpected caption in get_moderation_item';
  end if;
end $$;

select is(
  (select count(*)::int
     from jsonb_array_elements(admin.list_audit_log(tests.u(2), 'moderation.view_item', 'moderation_queue', null, null, 10) -> 'items')),
  1,
  'get_moderation_item logs moderation.view_item in private.admin_audit'
);

-- [Test 27] admin.reveal_reported_media grants 5-minute access ONLY to the reported check-in's media, not u(3)'s unreported media
do $$
declare
  v_qid uuid;
begin
  perform tests.as_user(tests.u(2));
  select (item ->> 'id')::uuid into v_qid
    from jsonb_array_elements(admin.list_moderation_queue('open', 'report', 'nudity', 50, 0) -> 'items') item
   where (item ->> 'target_checkin_id')::uuid = tests.c(2);
  perform admin.reveal_reported_media(v_qid, 'Verify nudity report');
end $$;

select is(
  (select count(*)::int from storage.objects
    where bucket_id = 'media'
      and name in (
        format('checkins/%s/%s/%s.jpg', tests.j(3), tests.u(4), tests.c(2)),
        format('checkins/%s/%s/%s_t.jpg', tests.j(3), tests.u(4), tests.c(2))
      )) = 2
  and
  (select count(*)::int from storage.objects
    where bucket_id = 'media'
      and name = format('checkins/%s/%s/%s.jpg', tests.j(3), tests.u(3), tests.c(1))) = 0,
  true,
  'reveal_reported_media grants storage read ONLY to the reported check-in photos, never unreported photos'
);

-- [Test 28] Once the 5-minute media grant expires, storage.objects denies read again
do $$ begin
  perform tests.as_postgres();
  update private.admin_media_grants set expires_at = now() - interval '1 second';
  perform tests.as_user(tests.u(2));
end $$;
select is(
  (select count(*)::int from storage.objects where bucket_id = 'media' and name like 'checkins/%'),
  0,
  'expired admin_media_grants row immediately revokes storage.objects read access'
);

-- [Test 29] admin.quarantine_moderation_target sets moderated_at while keeping queue status open, and resolve_moderation('dismiss') restores it
do $$
declare
  v_qid uuid;
begin
  perform tests.as_user(tests.u(2));
  select (item ->> 'id')::uuid into v_qid
    from jsonb_array_elements(admin.list_moderation_queue('open', 'report', 'nudity', 50, 0) -> 'items') item
   where (item ->> 'target_checkin_id')::uuid = tests.c(2);
  perform admin.quarantine_moderation_target(v_qid, 'hold for review');
  perform tests.as_postgres();
end $$;

select is(
  (select moderated_at is not null and deleted_at is null from public.check_ins where id = tests.c(2)),
  true,
  'quarantine_moderation_target sets check_ins.moderated_at without soft-deleting'
);

do $$
declare
  v_qid uuid;
begin
  perform tests.as_user(tests.u(2));
  select (item ->> 'id')::uuid into v_qid
    from jsonb_array_elements(admin.list_moderation_queue('open', 'report', 'nudity', 50, 0) -> 'items') item
   where (item ->> 'target_checkin_id')::uuid = tests.c(2);
  -- Mint a fresh 5-minute grant right before resolving to verify resolve_moderation purges active grants (P2-2)
  perform admin.reveal_reported_media(v_qid, 're-verify before resolve');
  perform admin.resolve_moderation(v_qid, 'dismiss', 'false alarm');
  perform tests.as_postgres();
end $$;

-- [Test 30] Dismissing restores moderated_at = null and immediately purges active admin_media_grants (P2-2)
select is(
  (select moderated_at is null and deleted_at is null from public.check_ins where id = tests.c(2))
  and (select count(*)::int = 0 from private.admin_media_grants),
  true,
  'P2-2: resolve_moderation(dismiss) clears moderated_at, closes the report, and purges active media grants'
);

-- [Test 30b] P2-2: reveal_reported_media rejects closed / dismissed moderation queue items
do $$ begin perform tests.as_user(tests.u(2)); end $$;
select throws_ok(
  $$ select admin.reveal_reported_media(
       (select (item ->> 'id')::uuid
          from jsonb_array_elements(admin.list_moderation_queue('dismissed', 'report', 'nudity', 50, 0) -> 'items') item
         where (item ->> 'target_checkin_id')::uuid = tests.c(2)
         limit 1),
       'attempt reveal on dismissed item'
     ) $$,
  'P0001', 'invalid',
  'P2-2: reveal_reported_media rejects closed/dismissed moderation queue items'
);

-- ============================================================================
-- 8. Amendment A2: Reversible Ban vs Wipe-UGC Ban (NEVER sets profiles.deleted_at!)
-- ============================================================================
do $$ begin
  -- Re-enable public link on u(3)'s journey j(2) to verify ban revokes public_token
  perform tests.as_user(tests.u(3));
  perform public.set_public_link(tests.j(2), true);
  -- Moderator u(2) reversibly bans u(3) (p_wipe_ugc = false)
  perform tests.as_user(tests.u(2));
  perform admin.ban_user(tests.u(3), 'temporary suspension for cooling off', false);
  perform tests.as_postgres();
end $$;

-- [Test 31] A2: Reversible ban sets auth.users.banned_until, creates private.user_moderation row,
--           revokes public_token, leaves check-ins intact, and NEVER sets public.profiles.deleted_at!
select is(
  (select deleted_at is null from public.profiles where id = tests.u(3))
  and (select banned_until > now() from auth.users where id = tests.u(3))
  and (select banned_at is not null and unbanned_at is null and not wiped_ugc
         from private.user_moderation where user_id = tests.u(3))
  and (select public_token is null from public.journeys where id = tests.j(2))
  and (select deleted_at is null and moderated_at is null from public.check_ins where id = tests.c(1)),
  true,
  'A2: reversible ban_user(p_wipe_ugc=false) leaves profiles.deleted_at NULL and check-ins intact while setting banned_until + user_moderation + revoking public_token'
);

-- [Tests 31b..31e] P1-1: Banned user u(3) with an existing unexpired JWT (profiles.deleted_at IS NULL)
--                        immediately loses write and read access across RPCs, triggers, and RLS.
do $$ begin perform tests.as_user(tests.u(3)); end $$;

select throws_ok(
  $$ select public.create_journey(tests.j(99), 'solo', 'custom', 'Banned Try', '🔥',
                                  null, null, false, current_date, 30, 'UTC') $$,
  '42501', 'forbidden',
  'P1-1: banned user with active JWT is immediately denied (42501) on public.create_journey'
);

select throws_ok(
  $$ insert into public.check_ins (id, journey_id, user_id, local_date, captured_at, photo_path, thumb_path, caption)
     values (
       tests.c(99), tests.j(1), tests.u(3), current_date, now(),
       format('checkins/%s/%s/%s.jpg', tests.j(1), tests.u(3), tests.c(99)),
       format('checkins/%s/%s/%s_t.jpg', tests.j(1), tests.u(3), tests.c(99)),
       'Banned direct insert'
     ) $$,
  '42501', 'forbidden',
  'P1-1: banned user with active JWT is immediately denied (42501) on direct check_ins INSERT'
);

select throws_ok(
  $$ select public.set_public_link(tests.j(2), true) $$,
  '42501', 'forbidden',
  'P1-1: banned user with active JWT cannot re-enable public_token via set_public_link'
);

select is(
  (select count(*)::int from public.journeys) + (select count(*)::int from public.check_ins),
  0,
  'P1-1: banned user with active JWT sees zero journeys and zero check_ins via RLS'
);

-- [Test 32] A2: Unban clears auth.users.banned_until and marks unbanned_at in private.user_moderation
do $$ begin
  perform tests.as_user(tests.u(2));
  perform admin.unban_user(tests.u(3), 'appeal accepted');
  perform tests.as_postgres();
end $$;
select is(
  (select banned_until is null from auth.users where id = tests.u(3))
  and (select unbanned_at is not null and unban_reason = 'appeal accepted'
         from private.user_moderation where user_id = tests.u(3))
  and (select deleted_at is null from public.profiles where id = tests.u(3)),
  true,
  'A2: unban_user clears banned_until and updates private.user_moderation without touching profiles.deleted_at'
);

-- [Test 33] A2 & P1-1: Severe ban (p_wipe_ugc = true) wipes UGC, clears avatar_path, revokes friend_invites,
--           queues storage purge, leaves groups, and STILL leaves profiles.deleted_at NULL
do $$ begin
  -- Give u(4) an avatar_path and an active friend_invite before wipe-banning
  perform tests.as_user(tests.u(4));
  update public.profiles
     set avatar_path = format('avatars/%s/%s.jpg', tests.u(4), tests.c(2))
   where id = tests.u(4);
  perform public.create_friend_invite();
  perform tests.as_user(tests.u(2));
  perform admin.ban_user(tests.u(4), 'severe repeat abuse takedown', true);
  perform tests.as_postgres();
end $$;
select is(
  (select deleted_at is null and avatar_path is null from public.profiles where id = tests.u(4))
  and (select count(*)::int = 0 from public.friend_invites where user_id = tests.u(4))
  and (select banned_until > now() from auth.users where id = tests.u(4))
  and (select wiped_ugc from private.user_moderation where user_id = tests.u(4))
  and (select moderated_at is not null and deleted_at is not null from public.check_ins where id = tests.c(2))
  and (select status = 'left' and removed_at is not null from public.memberships where journey_id = tests.j(3) and user_id = tests.u(4))
  and (select count(*)::int >= 2 from private.pending_storage_purge where path like format('checkins/%s/%s/%%', tests.j(3), tests.u(4)))
  and (select count(*)::int = 1 from private.pending_storage_purge where path = format('avatars/%s/%s.jpg', tests.u(4), tests.c(2))),
  true,
  'A2 & P1-1: ban_user(p_wipe_ugc=true) wipes UGC, clears avatar_path, revokes friend_invites, and queues storage purge while keeping profiles.deleted_at NULL'
);

-- [Tests 34..34e] P2-1: Admin-target guards (moderators cannot ban/wipe/unban/revoke other admins;
--                       only owners can act on moderators; nobody can ban the last owner)
do $$ begin
  perform tests.as_user(tests.u(1));
  perform admin.upsert_admin_user('owner2@ourney.tech', 'moderator', 'second moderator for P2-1 test');
  perform tests.as_user(tests.u(2));
end $$;

select throws_ok(
  $$ select admin.ban_user(tests.u(1), 'try ban owner', false) $$,
  '42501', 'forbidden',
  'P2-1: moderator cannot ban an owner admin'
);

select throws_ok(
  $$ select admin.ban_user(tests.u(5), 'try ban peer moderator', true) $$,
  '42501', 'forbidden',
  'P2-1: moderator cannot ban or wipe another moderator'
);

select throws_ok(
  $$ select admin.revoke_user_sessions(tests.u(1), 'try revoke owner sessions') $$,
  '42501', 'forbidden',
  'P2-1: moderator cannot revoke an owner or peer admin sessions'
);

do $$ begin
  -- Owner u(1) suspends moderator u(5), then moderator u(2) tries to unban u(5)
  perform tests.as_user(tests.u(1));
  perform admin.ban_user(tests.u(5), 'owner suspends moderator u5', false);
  perform tests.as_user(tests.u(2));
end $$;

select throws_ok(
  $$ select admin.unban_user(tests.u(5), 'colluding mod unban attempt') $$,
  '42501', 'forbidden',
  'P2-1: moderator cannot unban another admin'
);

do $$ begin perform tests.as_user(tests.u(1)); end $$;
select throws_ok(
  $$ select admin.ban_user(tests.u(1), 'owner self ban', false) $$,
  '42501', 'forbidden',
  'P2-1: nobody can ban the last owner'
);

do $$ begin
  perform tests.as_user(tests.u(1));
  perform admin.unban_user(tests.u(5), 'owner restores u5');
  perform admin.remove_admin_user(tests.u(5), 'cleanup u5 mod role');
  perform tests.as_user(tests.u(2));
end $$;

-- [Test 35] admin.list_users and admin.get_user_detail reflect banned status and log users.view_detail
select is(
  (admin.list_users('user_four', 'banned', 'created_at', 50, 0) ->> 'total')::int = 1
  and (admin.get_user_detail(tests.u(4)) ->> 'status') = 'banned',
  true,
  'list_users and get_user_detail report banned status accurately'
);

-- [Test 36] admin.revoke_user_sessions executes and logs users.revoke_sessions
do $$ begin
  perform tests.as_user(tests.u(2));
  perform admin.revoke_user_sessions(tests.u(3), 'compromised device');
end $$;
select is(
  (select count(*)::int
     from jsonb_array_elements(admin.list_audit_log(tests.u(2), 'users.revoke_sessions', 'user', tests.u(3)::text, null, 10) -> 'items')),
  1,
  'revoke_user_sessions logs users.revoke_sessions in private.admin_audit'
);

-- ============================================================================
-- 9. Overview Stats, Journey Stats, System Health & Storage Purge Reset
-- ============================================================================
-- [Test 37] admin.overview_stats returns KPIs and feature_requests block
select is(
  (admin.overview_stats(14, 'Asia/Ho_Chi_Minh') #>> '{kpis,users,total_auth}')::int >= 5
  and (
    case
      when to_regclass('public.feature_requests') is null
        then (admin.overview_stats(14, 'Asia/Ho_Chi_Minh') #> '{kpis,feature_requests}') = 'null'::jsonb
      else (admin.overview_stats(14, 'Asia/Ho_Chi_Minh') #>> '{kpis,feature_requests,new_7d}')::int >= 0
    end
  )
  and jsonb_array_length(admin.overview_stats(14, 'Asia/Ho_Chi_Minh') -> 'activation_funnel_7d') = 6
  and jsonb_array_length(admin.overview_stats(14, 'Asia/Ho_Chi_Minh') -> 'template_mix') = 6,
  true,
  'A1 & A7: overview_stats returns KPIs, 6-step funnel, 6-persona mix, and feature_requests KPI block'
);

-- [Test 38] admin.journey_stats returns aggregate counts
select is(
  (admin.journey_stats() ->> 'total')::int >= 3,
  true,
  'journey_stats returns aggregate journey metrics'
);

-- [Test 39] admin.system_health and admin.reset_stuck_storage_purge handle stuck rows with redacted path prefixes
do $$ begin
  perform tests.as_postgres();
  update private.pending_storage_purge
     set attempts = 25,
         last_error = 'storage timeout'
   where path like format('checkins/%s/%s/%%', tests.j(3), tests.u(4));
  perform tests.as_user(tests.u(2));
end $$;

select is(
  (admin.system_health() #>> '{storage_purge,stuck_count}')::int >= 2
  and (admin.system_health() #>> '{storage_purge,sample_errors,0,path_prefix}') = 'checkins/...',
  true,
  'system_health reports stuck storage purge count with redacted path_prefix'
);

do $$ begin
  perform tests.as_user(tests.u(2));
  perform admin.reset_stuck_storage_purge('retry after storage recovery');
end $$;

-- [Test 40] reset_stuck_storage_purge resets attempts to 0
select is(
  (admin.system_health() #>> '{storage_purge,stuck_count}')::int,
  0,
  'reset_stuck_storage_purge resets stuck storage purge attempts to 0'
);

-- ============================================================================
-- 10. Append-Only Audit Log Immutability (`immutable_audit_log`)
-- ============================================================================
do $$ begin perform tests.as_postgres(); end $$;

-- [Test 41] UPDATE on private.admin_audit raises 42501 immutable_audit_log even for postgres
select throws_ok(
  $$ update private.admin_audit set reason = 'tampered' $$,
  '42501', 'immutable_audit_log',
  'UPDATE on private.admin_audit is blocked by immutable_audit_log trigger'
);

-- [Test 42] DELETE on private.admin_audit raises 42501 immutable_audit_log even for postgres
select throws_ok(
  $$ delete from private.admin_audit $$,
  '42501', 'immutable_audit_log',
  'DELETE on private.admin_audit is blocked by immutable_audit_log trigger'
);

-- [Test 42b] TRUNCATE on private.admin_audit raises 42501 immutable_audit_log even for postgres
select throws_ok(
  $$ truncate private.admin_audit $$,
  '42501', 'immutable_audit_log',
  'TRUNCATE on private.admin_audit is blocked by immutable_audit_log trigger'
);

-- [Test 43] P1-2: Deleting an auth.users account that previously wrote admin_audit entries succeeds
--           without triggering immutable_audit_log, and preserves historical admin_id attribution
do $$ begin
  perform tests.as_postgres();
  perform private.admin_log(
    tests.u(5),
    'moderation.view_item',
    'moderation_queue',
    'u5-audit-entry',
    'offboarded admin prior action',
    '{}'::jsonb
  );
  delete from auth.users where id = tests.u(5);
end $$;
select is(
  (select count(*)::int = 0 from auth.users where id = tests.u(5))
  and (select count(*)::int >= 1 from private.admin_audit where admin_id = tests.u(5) and target_id = 'u5-audit-entry'),
  true,
  'P1-2: deleting an offboarded admin from auth.users succeeds and preserves immutable admin_audit attribution'
);

select * from finish();
rollback;
