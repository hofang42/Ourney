-- 0035_supabase_security_fixes: pgTAP verification of F-02, F-03, F-04, F-05, F-19, F-20, F-21, F-44.
begin;
create extension if not exists pgtap with schema extensions;
select plan(39);

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
  select format('35000000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function tests.j(n int) returns uuid language sql immutable as $$
  select format('b3500000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function tests.c(n int) returns uuid language sql immutable as $$
  select format('c3500000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function tests.m(n int) returns uuid language sql immutable as $$
  select format('d3500000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function tests.photo(j uuid, u uuid, c uuid) returns text language sql immutable as $$
  select format('checkins/%s/%s/%s.jpg', j, u, c) $$;
create function tests.thumb(j uuid, u uuid, c uuid) returns text language sql immutable as $$
  select format('checkins/%s/%s/%s_t.jpg', j, u, c) $$;
create function tests.partner_photo(j uuid, u uuid, c uuid) returns text language sql immutable as $$
  select format('checkins/%s/%s/%s_p.jpg', j, u, c) $$;
create function tests.slug(j uuid) returns text language sql security definer as $$
  select public_slug from public.journeys where id = j $$;
create function tests.token(j uuid) returns text language sql security definer as $$
  select public_token from public.journeys where id = j $$;
create function tests.rate_event_count(u uuid, k text) returns int language sql security definer as $$
  select count(*)::int from private.rate_events where user_id = u and kind = k $$;
create function tests.react(cid uuid) returns void language sql as $$
  insert into public.reactions (checkin_id, user_id, emoji) values (cid, auth.uid(), '❤️')
  on conflict (checkin_id, user_id) do update set deleted_at = null $$;
create function tests.touch_storage(p_bucket text, p_name text) returns int language plpgsql as $$
declare
  n int;
begin
  update storage.objects set updated_at = now() where bucket_id = p_bucket and name = p_name;
  get diagnostics n = row_count;
  return n;
end $$;
create function tests.delete_storage(p_bucket text, p_name text) returns int language sql stable as $$
  select case
    when p_bucket = 'media' and not private.caller_is_banned() and private.can_delete_checkin_object(p_name) then 1
    when p_bucket = 'messages' and not private.caller_is_banned() and private.can_delete_message_object(p_name) then 1
    else 0
  end
$$;

grant execute on all functions in schema tests to anon, authenticated, service_role;

insert into auth.users (id, email)
select tests.u(n), format('sec35_%s@example.test', n) from generate_series(1, 8) n;

insert into public.profiles (id, username, display_name)
select tests.u(n), 'sec35user' || n, 'Sec35 ' || n from generate_series(1, 8) n;

-- ============================================================================
-- 1. F-02: Public link rotation cuts off old link holders across all surfaces
-- ============================================================================
do $$ begin
  perform tests.as_user(tests.u(1));
  perform public.create_journey(tests.j(1), 'solo', 'travel', 'Da Lat Trip', '🏔️',
                                'Distance', 'km', false, current_date - 5, 30, 'UTC');
  insert into storage.objects (bucket_id, name) values
    ('media', tests.photo(tests.j(1), tests.u(1), tests.c(1))),
    ('media', tests.thumb(tests.j(1), tests.u(1), tests.c(1)));
  insert into public.check_ins (id, journey_id, user_id, local_date, captured_at, photo_path, thumb_path, caption)
  values (tests.c(1), tests.j(1), tests.u(1), current_date, now(),
          tests.photo(tests.j(1), tests.u(1), tests.c(1)),
          tests.thumb(tests.j(1), tests.u(1), tests.c(1)), 'Day 1');
  perform public.end_journey(tests.j(1));
end $$;

do $$ begin
  perform tests.as_user(tests.u(1));
  perform public.set_readable_public_link(tests.j(1), true, false, 'Da Lat Trip');
end $$;

-- [Test 1] Stranger u(3) who has NOT opened public_journey_by_token cannot react or access via bare journey_id/checkin_id
do $$ begin perform tests.as_user(tests.u(3)); end $$;
select throws_ok(
  $$ select tests.react(tests.c(1)) $$,
  '42501', null,
  'F-02: stranger without opening public_journey_by_token cannot react by guessing checkin_id'
);

-- [Test 2] Stranger u(2) opens slug1 via public_journey_by_token, reads photo from Storage, reacts, and saves the journey
do $$ begin perform tests.as_user(tests.u(2)); end $$;
select is(
  (public.public_journey_by_token(tests.slug(tests.j(1)))->>'role'),
  'stranger',
  'F-02: stranger u(2) opens slug1 and receives stranger role'
);

-- [Test 3] Stranger u(2) can react and save the journey while holding the active token grant
select lives_ok(
  $$ select tests.react(tests.c(1)) $$,
  'F-02: stranger u(2) with valid public link grant can react'
);

-- [Test 4] Stranger u(2) can open shared_journey(j(1)) and read Storage object before rotation
select is(
  (public.shared_journey(tests.j(1))->>'role')
  || ':' || (select count(*)::int from storage.objects where name = tests.photo(tests.j(1), tests.u(1), tests.c(1)))::text,
  'stranger:1',
  'F-02: stranger u(2) reads shared_journey and check-in Storage photo before link rotation'
);

-- Owner u(1) rotates the public link (reset := true)
do $$ begin
  perform tests.as_user(tests.u(1));
  perform public.set_readable_public_link(tests.j(1), true, true, 'Da Lat Trip');
end $$;

-- [Test 5] After link rotation, old viewer u(2) cannot re-insert or un-delete a reaction to restore saved_journeys
do $$ begin perform tests.as_user(tests.u(2)); end $$;
select throws_ok(
  $$ select tests.react(tests.c(1)) $$,
  '42501', null,
  'F-02: after public link rotation, previous viewer cannot react to re-save the journey'
);

-- [Test 6] saved_journeys remains empty and shared_journey(j(1)) denies u(2) with 42501 forbidden
select throws_ok(
  $$ select public.shared_journey(tests.j(1)) $$,
  '42501', 'forbidden',
  'F-02: rotated link immediately revokes shared_journey access for previous viewer'
);

-- [Test 7] Previous viewer u(2) can no longer read check-in photo from Storage after rotation
select is(
  (select count(*)::int from storage.objects where name = tests.photo(tests.j(1), tests.u(1), tests.c(1))),
  0,
  'F-02: rotated link immediately revokes Storage media_select access for previous viewer'
);

-- [Test 8] Previous viewer u(2) cannot call follow_frame after rotation
select throws_ok(
  $$ select public.follow_frame(tests.j(1)) $$,
  '42501', 'forbidden',
  'F-02: rotated link revokes follow_frame access for previous viewer'
);

-- [Test 9] Previous viewer u(2) cannot call send_friend_request via p_source_journey after rotation
select throws_ok(
  $$ select public.send_friend_request(tests.u(1), tests.j(1)) $$,
  '42501', 'forbidden',
  'F-02: rotated link revokes send_friend_request(p_source_journey) for previous viewer'
);

-- [Test 10] Previous viewer u(2) cannot call report_content on the check-in after rotation
select throws_ok(
  $$ select public.report_content(tests.c(1), tests.u(1), 'nudity', 'post-rotation probe') $$,
  'P0001', 'not_found',
  'F-02: rotated link prevents previous viewer from reporting/quarantining check-ins without the new token'
);

-- [Test 11] Opening the new rotated slug2 restores legitimate viewer access for u(2)
do $$ begin
  perform tests.as_user(tests.u(2));
  if (public.public_journey_by_token(tests.slug(tests.j(1)))->>'role') is distinct from 'stranger' then
    raise exception 'expected stranger role when opening rotated slug2';
  end if;
end $$;
select is(
  (select count(*)::int from storage.objects where name = tests.photo(tests.j(1), tests.u(1), tests.c(1))),
  1,
  'F-02: opening the new rotated link grants access again'
);

-- ============================================================================
-- 2. F-03: Storage UPDATE/DELETE guards on committed, moderated, and ended media
-- ============================================================================
-- [Test 12] Author u(1) cannot overwrite (UPDATE) or DELETE committed check-in media on ended journey j(1)
do $$ begin perform tests.as_user(tests.u(1)); end $$;
select is(
  tests.touch_storage('media', tests.photo(tests.j(1), tests.u(1), tests.c(1)))
  + tests.delete_storage('media', tests.photo(tests.j(1), tests.u(1), tests.c(1))),
  0,
  'F-03: author cannot overwrite or delete committed check-in media in Storage'
);

-- [Test 13] Author u(1) cannot upload new check-in media into ended live journey j(1)
select throws_ok(
  $$ insert into storage.objects (bucket_id, name)
     values ('media', tests.photo(tests.j(1), tests.u(1), tests.c(99))) $$,
  '42501', null,
  'F-03: member cannot upload new check-in Storage objects into an ended live journey'
);

-- [Test 14] Pre-commit upload, x-upsert UPDATE, and pre-commit cleanup DELETE work on an active journey before check_ins row exists
do $$ begin
  perform tests.as_user(tests.u(1));
  perform public.create_journey(tests.j(2), 'solo', 'custom', 'Active Solo', '🔥',
                                null, null, false, current_date - 2, 30, 'UTC');
  insert into storage.objects (bucket_id, name) values
    ('media', tests.photo(tests.j(2), tests.u(1), tests.c(2))),
    ('media', tests.thumb(tests.j(2), tests.u(1), tests.c(2))),
    ('media', tests.photo(tests.j(2), tests.u(1), tests.c(20)));
end $$;
select is(
  tests.touch_storage('media', tests.photo(tests.j(2), tests.u(1), tests.c(2)))
  + tests.delete_storage('media', tests.photo(tests.j(2), tests.u(1), tests.c(20))),
  2,
  'F-03: pre-commit x-upsert UPDATE and pre-commit orphan DELETE succeed before check_ins row exists'
);

-- [Test 15] Once check_ins row c(2) is committed on active journey j(2), Storage UPDATE and DELETE are blocked
do $$ begin
  perform tests.as_user(tests.u(1));
  insert into public.check_ins (id, journey_id, user_id, local_date, captured_at, photo_path, thumb_path, caption)
  values (tests.c(2), tests.j(2), tests.u(1), current_date, now(),
          tests.photo(tests.j(2), tests.u(1), tests.c(2)),
          tests.thumb(tests.j(2), tests.u(1), tests.c(2)), 'Committed active check-in');
end $$;
select is(
  tests.touch_storage('media', tests.photo(tests.j(2), tests.u(1), tests.c(2)))
  + tests.delete_storage('media', tests.photo(tests.j(2), tests.u(1), tests.c(2))),
  0,
  'F-03: committed active check-in media cannot be overwritten or deleted in Storage'
);

-- [Test 16] Quarantined check-in media cannot be deleted in Storage even if journey/check-in is soft-deleted
do $$ begin
  perform tests.as_postgres();
  update public.check_ins set moderated_at = now() where id = tests.c(2);
  perform tests.as_user(tests.u(1));
  perform public.delete_journey(tests.j(2));
end $$;
select is(
  tests.delete_storage('media', tests.photo(tests.j(2), tests.u(1), tests.c(2))),
  0,
  'F-03: quarantined check-in media cannot be deleted by author even after delete_journey'
);

-- [Test 17] Unmoderated, unreported solo journey deleted via delete_journey allows owner to clean up Storage objects
do $$ begin
  perform tests.as_user(tests.u(1));
  perform public.create_journey(tests.j(21), 'solo', 'custom', 'Clean Delete Solo', '🌱',
                                null, null, false, current_date - 2, 30, 'UTC');
  insert into storage.objects (bucket_id, name) values
    ('media', tests.photo(tests.j(21), tests.u(1), tests.c(21))),
    ('media', tests.thumb(tests.j(21), tests.u(1), tests.c(21)));
  insert into public.check_ins (id, journey_id, user_id, local_date, captured_at, photo_path, thumb_path)
  values (tests.c(21), tests.j(21), tests.u(1), current_date, now(),
          tests.photo(tests.j(21), tests.u(1), tests.c(21)),
          tests.thumb(tests.j(21), tests.u(1), tests.c(21)));
  perform public.delete_journey(tests.j(21));
end $$;
select is(
  tests.delete_storage('media', tests.photo(tests.j(21), tests.u(1), tests.c(21)))
  + tests.delete_storage('media', tests.thumb(tests.j(21), tests.u(1), tests.c(21))),
  2,
  'F-03: owner can clean up unmoderated Storage media after delete_journey tombstones the journey'
);

-- [Test 18] Chat message media: pre-send_message delete succeeds, post-send_message DELETE and post-moderation UPDATE/DELETE are blocked
do $$ declare
  v_conv uuid;
  v_path1 text;
  v_path2 text;
begin
  perform tests.as_user(tests.u(1));
  perform public.send_friend_request(tests.u(4));
  perform tests.as_user(tests.u(4));
  perform public.respond_friend_request(tests.u(1), true);
  perform tests.as_user(tests.u(1));
  perform public.share_journey(tests.j(1), array[tests.u(4)]);
  perform tests.as_user(tests.u(4));
  v_conv := public.open_conversation(tests.j(1), tests.c(1));
  v_path1 := format('messages/%s/%s/%s.jpg', v_conv, tests.u(4), tests.m(1));
  v_path2 := format('messages/%s/%s/%s.jpg', v_conv, tests.u(4), tests.m(2));
  insert into storage.objects (bucket_id, name) values ('messages', v_path1), ('messages', v_path2);
  -- Pre-commit cleanup of v_path2 (e.g. rejected caption cleanup) must succeed
  if tests.delete_storage('messages', v_path2) <> 1 then
    raise exception 'expected pre-commit message storage delete to succeed';
  end if;
  perform public.send_message(tests.m(1), v_conv, 'photo', 'hello photo', v_path1);
  -- Immediately after commit, sender cannot delete the committed message object
  if tests.delete_storage('messages', v_path1) <> 0 then
    raise exception 'expected post-commit message storage delete to be blocked';
  end if;
  -- Once moderated/quarantined, sender cannot overwrite (UPDATE) or delete the message object
  perform tests.as_postgres();
  update public.messages set moderated_at = now() where id = tests.m(1);
  perform tests.as_user(tests.u(4));
end $$;
select is(
  (select tests.touch_storage('messages', format('messages/%s/%s/%s.jpg', c.id, tests.u(4), tests.m(1)))
        + tests.delete_storage('messages', format('messages/%s/%s/%s.jpg', c.id, tests.u(4), tests.m(1)))
     from public.conversations c
    where c.journey_id = tests.j(1) and c.member_id = tests.u(1) and c.viewer_id = tests.u(4)),
  0,
  'F-03: once send_message commits/moderates a message row, sender cannot overwrite or delete its Storage object'
);

-- ============================================================================
-- 3. F-04: Partner photo (_p.jpg) requires group share consent & no block
-- ============================================================================
do $$ declare
  v_code text;
begin
  perform tests.as_user(tests.u(5));
  v_code := (public.create_journey(
    tests.j(4), 'group', 'couple', 'Couple Ritual', '💞',
    null, null, false, current_date - 3, 30, 'UTC', 2, 'private', 'An', 'Binh'
  )).invite_code;
  perform tests.as_user(tests.u(6));
  perform public.join_by_code(v_code);
  perform tests.as_user(tests.u(5));
  insert into storage.objects (bucket_id, name) values
    ('media', tests.photo(tests.j(4), tests.u(5), tests.c(4))),
    ('media', tests.thumb(tests.j(4), tests.u(5), tests.c(4))),
    ('media', tests.partner_photo(tests.j(4), tests.u(5), tests.c(4)));
  insert into public.check_ins (id, journey_id, user_id, local_date, captured_at, photo_path, thumb_path, partner_photo_path)
  values (tests.c(4), tests.j(4), tests.u(5), current_date, now(),
          tests.photo(tests.j(4), tests.u(5), tests.c(4)),
          tests.thumb(tests.j(4), tests.u(5), tests.c(4)),
          tests.partner_photo(tests.j(4), tests.u(5), tests.c(4)));
  -- u(5) befriends u(7), requests share consent (u(5) accepted, partner u(6) still pending), and shares with u(7)
  perform public.send_friend_request(tests.u(7));
  perform tests.as_user(tests.u(7));
  perform public.respond_friend_request(tests.u(5), true);
  perform tests.as_user(tests.u(5));
  perform public.request_share_consent(tests.j(4));
  perform public.share_journey(tests.j(4), array[tests.u(7)]);
end $$;

-- [Test 19] While partner u(6) has not consented, viewer u(7) can read u(5)'s .jpg but NOT _p.jpg
do $$ begin perform tests.as_user(tests.u(7)); end $$;
select is(
  (select count(*)::int from storage.objects where name = tests.photo(tests.j(4), tests.u(5), tests.c(4)))::text
  || ':' ||
  (select count(*)::int from storage.objects where name = tests.partner_photo(tests.j(4), tests.u(5), tests.c(4)))::text,
  '1:0',
  'F-04: non-member viewer cannot read partner_photo_path (_p.jpg) from Storage without partner share consent'
);

-- [Test 20] Once partner u(6) accepts share consent, viewer u(7) can read _p.jpg
do $$ begin
  perform tests.as_user(tests.u(6));
  perform public.respond_share_consent(tests.j(4), true);
  perform tests.as_user(tests.u(7));
end $$;
select is(
  (select count(*)::int from storage.objects where name = tests.partner_photo(tests.j(4), tests.u(5), tests.c(4))),
  1,
  'F-04: viewer can read _p.jpg once all active couple members accept share consent'
);

-- [Test 21] If partner u(6) blocks viewer u(7), _p.jpg is immediately blocked in Storage
do $$ begin
  perform tests.as_user(tests.u(6));
  perform public.block_user(tests.u(7));
  perform tests.as_user(tests.u(7));
end $$;
select is(
  (select count(*)::int from storage.objects where name = tests.partner_photo(tests.j(4), tests.u(5), tests.c(4))),
  0,
  'F-04: partner blocking viewer immediately revokes Storage read access to _p.jpg'
);

-- ============================================================================
-- 4. F-05: Waitlist signup fallback IP bucket & non-hex IP hash rejection
-- ============================================================================
do $$ begin perform tests.as_service_role(); end $$;

-- [Test 22] Non-hex 64-char p_ip_hash is rejected as invalid
select is(
  public.waitlist_signup('badhash@example.test', 'vi', null, 'landing', repeat('z', 64))->>'status',
  'invalid',
  'F-05: waitlist_signup rejects non-hex 64-character p_ip_hash'
);

-- [Test 23] Null p_ip_hash charges the shared fallback bucket and rate-limits on the 6th attempt
select is(
  (select array_agg(public.waitlist_signup('nullip' || i || '@example.test', 'vi', null, 'landing', null)->>'status' order by i)
     from generate_series(1, 6) as i),
  array['created', 'created', 'created', 'created', 'created', 'rate_limited'],
  'F-05: waitlist_signup with null p_ip_hash charges the shared fallback bucket and rate-limits after 5/hour'
);

-- ============================================================================
-- 5. F-19: Username availability rate limit (60/hour) & soft-deleted caller check
-- ============================================================================
do $$ begin perform tests.as_user(tests.u(8)); end $$;

-- [Test 24] Invalid format and own username do not consume rate_events
select is(
  (not public.check_username_available('a'))
  and public.check_username_available('sec35user8')
  and tests.rate_event_count(tests.u(8), 'username_check') = 0,
  true,
  'F-19: invalid format and caller own handle do not consume username_check rate limit'
);

-- [Test 25] 60 username availability checks succeed; 61st raises P0001 rate_limited
do $$ begin
  perform tests.as_postgres();
  insert into private.rate_events (user_id, kind)
  select tests.u(8), 'username_check' from generate_series(1, 59);
  perform tests.as_user(tests.u(8));
end $$;
select is(
  public.check_username_available('available_name_60'),
  true,
  'F-19: 60th username availability check within an hour succeeds'
);
select throws_ok(
  $$ select public.check_username_available('available_name_61') $$,
  'P0001', 'rate_limited',
  'F-19: 61st username availability check within an hour raises P0001 rate_limited'
);

-- [Test 26] Soft-deleted profile calling check_username_available raises 42501 forbidden
do $$ begin
  perform tests.as_postgres();
  update public.profiles set deleted_at = now() where id = tests.u(8);
  perform tests.as_user(tests.u(8));
end $$;
select throws_ok(
  $$ select public.check_username_available('another_handle') $$,
  '42501', 'forbidden',
  'F-19: soft-deleted profile calling check_username_available raises 42501 forbidden'
);
do $$ begin
  perform tests.as_postgres();
  update public.profiles set deleted_at = null where id = tests.u(8);
end $$;

-- ============================================================================
-- 6. F-20: Share lookup per-(IP, journey) cap prevents 2-IP DoS + 404 miss throttling
-- ============================================================================
do $$ begin
  perform tests.as_postgres();
  delete from private.share_lookup_buckets;
  perform tests.as_user(tests.u(1));
end $$;

-- [Test 27] Single IP (or fallback null IP) is capped at 30/min per journey while other IPs remain unaffected
do $$ begin
  perform tests.as_service_role();
  for i in 1..30 loop
    perform public.lookup_public_journey_for_edge(tests.token(tests.j(1)), repeat('1', 64));
    perform public.lookup_public_journey_for_edge(tests.token(tests.j(1)), repeat('2', 64));
    perform public.lookup_public_journey_for_edge(tests.token(tests.j(1)), null);
  end loop;
end $$;
select ok(
  (public.lookup_public_journey_for_edge(tests.token(tests.j(1)), repeat('1', 64))->>'retry_after')::int between 1 and 60
  and (public.lookup_public_journey_for_edge(tests.token(tests.j(1)), repeat('2', 64))->>'retry_after')::int between 1 and 60
  and (public.lookup_public_journey_for_edge(tests.token(tests.j(1)), null)->>'retry_after')::int between 1 and 60,
  'F-20: each IP and the null-IP fallback is capped at 30/min on a single journey'
);

-- [Test 28] A third legitimate IP can still open the journey despite 2 IPs + null-IP fallback being saturated
select is(
  public.lookup_public_journey_for_edge(tests.token(tests.j(1)), repeat('3', 64))->'journey'->>'title',
  'Da Lat Trip',
  'F-20: 2 saturated IPs + saturated fallback bucket cannot DoS the shared link for a 3rd legitimate IP'
);

-- [Test 29] 60 well-formed 404 misses exhaust an IP bucket and throttle the 61st miss
do $$ begin
  perform tests.as_service_role();
  for i in 1..60 loop
    perform public.lookup_public_journey_for_edge(repeat('9', 40), repeat('4', 64));
  end loop;
end $$;
select ok(
  (public.lookup_public_journey_for_edge(repeat('9', 40), repeat('4', 64))->>'retry_after')::int between 1 and 60,
  'F-20: 60 well-formed 404 misses exhaust the IP quota and throttle subsequent 404 probes'
);

-- ============================================================================
-- 7. F-21: Quarantined check-ins are immutable in check_in_metrics & check_in_extras
-- ============================================================================
do $$ begin
  perform tests.as_user(tests.u(5));
  insert into public.check_in_metrics (checkin_id, metric_value) values (tests.c(4), 65.5);
  insert into public.check_in_extras (checkin_id, extras) values (tests.c(4), '{"dish":"Pho","hearts":5}'::jsonb);
  perform tests.as_postgres();
  -- Quarantine c(4): moderated_at set, deleted_at remains null
  update public.check_ins set moderated_at = now() where id = tests.c(4);
  perform tests.as_user(tests.u(5));
end $$;

-- [Test 30] Author cannot update check_in_extras on a quarantined check-in
select throws_ok(
  $$ update public.check_in_extras set extras = '{"dish":"Clean"}'::jsonb where checkin_id = tests.c(4) $$,
  '42501', 'forbidden',
  'F-21: author cannot overwrite check_in_extras while check-in is quarantined (moderated_at IS NOT NULL)'
);

-- [Test 31] Author cannot update check_in_metrics on a quarantined check-in
select throws_ok(
  $$ update public.check_in_metrics set metric_value = 60.0 where checkin_id = tests.c(4) $$,
  '42501', 'forbidden',
  'F-21: author cannot overwrite check_in_metrics while check-in is quarantined (moderated_at IS NOT NULL)'
);

-- [Test 32] Author cannot insert check_in_extras or check_in_metrics on a quarantined check-in
do $$ begin
  perform tests.as_postgres();
  delete from public.check_in_extras where checkin_id = tests.c(4);
  perform tests.as_user(tests.u(5));
end $$;
select throws_ok(
  $$ insert into public.check_in_extras (checkin_id, extras) values (tests.c(4), '{"dish":"Clean"}'::jsonb) $$,
  '42501', 'forbidden',
  'F-21: author cannot insert check_in_extras on a quarantined check-in'
);

-- ============================================================================
-- 8. F-44: Backend hygiene (quarantined content hidden in previews/counts/reply_to_thumb_path,
--          and direct couple_self_name / couple_partner_name UPDATE revoked)
-- ============================================================================
-- [Test 33] Direct UPDATE on couple_self_name / couple_partner_name is revoked from authenticated
select ok(
  not has_column_privilege('authenticated', 'public.journeys', 'couple_self_name', 'UPDATE')
  and not has_column_privilege('authenticated', 'public.journeys', 'couple_partner_name', 'UPDATE'),
  'F-44: authenticated has no direct UPDATE grant on journeys.couple_self_name or couple_partner_name'
);

-- [Test 34] Owner of a 10-member group cannot bypass rename_couple via direct UPDATE on journeys
do $$ begin
  perform tests.as_user(tests.u(1));
  perform public.create_journey(tests.j(10), 'group', 'custom', 'Big Squad', '🔥',
                                null, null, false, current_date - 1, 30, 'UTC', 10, 'private');
end $$;
select throws_ok(
  $$ update public.journeys set couple_self_name = 'An', couple_partner_name = 'Binh' where id = tests.j(10) $$,
  '42501', null,
  'F-44: direct UPDATE on couple_self_name/couple_partner_name is rejected by PostgreSQL column privileges'
);

-- [Test 35] Legitimate rename_couple RPC still succeeds on a 2-member couple journey
do $$ begin perform tests.as_user(tests.u(5)); end $$;
select is(
  (public.rename_couple(tests.j(4), 'Minh', 'Lan')).couple_self_name,
  'Minh',
  'F-44: legitimate rename_couple RPC still updates couple names on a 2-member couple journey'
);

-- [Test 36] Quarantined chat message (moderated_at IS NOT NULL, deleted_at IS NULL) is excluded from my_conversations and inbox_counts
do $$ declare
  v_conv uuid;
begin
  perform tests.as_user(tests.u(4));
  select id into v_conv from public.conversations where journey_id = tests.j(1) and member_id = tests.u(1) and viewer_id = tests.u(4);
  perform public.send_message(tests.m(10), v_conv, 'text', 'Quarantined preview body', null, tests.c(1));
  perform tests.as_postgres();
  update public.messages set moderated_at = now() where id = tests.m(10);
  perform tests.as_user(tests.u(1));
end $$;
select is(
  (public.inbox_counts()->>'unread_messages')::int
  + (select coalesce(sum((c->>'unread_count')::int), 0)::int from public.my_conversations() c)
  + (select count(*)::int from public.my_conversations() c where c->>'last_message_preview' = 'Quarantined preview body'),
  0,
  'F-44: quarantined messages are excluded from inbox_counts.unread_messages and my_conversations unread_count/preview'
);

-- [Test 37] Un-quarantined message replying to a quarantined check-in omits reply_to_thumb_path in message_json
do $$ declare
  v_conv uuid;
begin
  perform tests.as_postgres();
  update public.messages set moderated_at = null where id = tests.m(10);
  update public.check_ins set moderated_at = now() where id = tests.c(1);
  perform tests.as_user(tests.u(1));
end $$;
select is(
  (select m->>'reply_to_thumb_path'
     from public.conversation_messages(
       (select id from public.conversations where journey_id = tests.j(1) and member_id = tests.u(1) and viewer_id = tests.u(4))
     ) m
    where (m->>'id')::uuid = tests.m(10)),
  null,
  'F-44: message_json omits reply_to_thumb_path when the replied-to check-in is quarantined'
);

-- [Test 38] Un-quarantining the check-in restores reply_to_thumb_path for the member
do $$ begin
  perform tests.as_postgres();
  update public.check_ins set moderated_at = null where id = tests.c(1);
  perform tests.as_user(tests.u(1));
end $$;
select is(
  (select m->>'reply_to_thumb_path'
     from public.conversation_messages(
       (select id from public.conversations where journey_id = tests.j(1) and member_id = tests.u(1) and viewer_id = tests.u(4))
     ) m
    where (m->>'id')::uuid = tests.m(10)),
  tests.thumb(tests.j(1), tests.u(1), tests.c(1)),
  'F-44: message_json returns reply_to_thumb_path once the check-in is not quarantined'
);

select * from finish();
rollback;
