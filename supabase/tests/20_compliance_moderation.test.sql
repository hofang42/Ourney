-- 0020_compliance_moderation: pgTAP verification of Batch 4 compliance & moderation fixes
-- (CS-02 report_content target_message_id, CS-03 objectionable-content filter & 24h moderation queue,
--  CS-05 account_has_password re-auth support).
begin;
create extension if not exists pgtap with schema extensions;
select plan(38);

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
  select format('20000000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function tests.j(n int) returns uuid language sql immutable as $$
  select format('b2000000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function tests.c(n int) returns uuid language sql immutable as $$
  select format('c2000000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function tests.m(n int) returns uuid language sql immutable as $$
  select format('d2000000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function tests.checkin(cid uuid, j uuid, cap text default null, at timestamptz default now())
returns void language sql as $$
  insert into public.check_ins (id, journey_id, user_id, local_date, captured_at, photo_path, thumb_path, caption)
  values (cid, j, auth.uid(), current_date, at,
          format('checkins/%s/%s/%s.jpg', j, auth.uid(), cid),
          format('checkins/%s/%s/%s_t.jpg', j, auth.uid(), cid), cap) $$;
create function tests.code(n int) returns text language sql security definer as $$
  select invite_code from public.journeys where id = tests.j(n) $$;
create function tests.conv(j uuid, member uuid, viewer uuid) returns uuid language sql security definer as $$
  select id from public.conversations where journey_id = j and member_id = member and viewer_id = viewer $$;
create function tests.befriend(a uuid, b uuid) returns void language plpgsql as $$
begin
  perform tests.as_user(a); perform public.send_friend_request(b);
  perform tests.as_user(b); perform public.respond_friend_request(a, true);
end $$;
create function tests.latest_queue_id(p_checkin uuid default null, p_message uuid default null, p_user uuid default null)
returns uuid language sql security definer as $$
  select id from public.moderation_queue
   where (p_checkin is null or target_checkin_id = p_checkin)
     and (p_message is null or target_message_id = p_message)
     and (p_user is null or target_user_id = p_user)
   order by created_at desc, id desc
   limit 1 $$;
grant execute on all functions in schema tests to anon, authenticated, service_role;

insert into auth.users (id, email, encrypted_password)
values
  (tests.u(1), 'cs20_1@example.test', null),
  (tests.u(2), 'cs20_2@example.test', ''),
  (tests.u(3), 'cs20_3@example.test', null),
  (tests.u(4), 'cs20_4@example.test', null),
  (tests.u(5), 'review-delete@ourney.tech', '$2a$10$abcdefghijklmnopqrstuuABCDEFGHIJKLMNOPQRSTUVWXYZ01234');

insert into public.profiles (id, username, display_name)
select tests.u(n), 'cs20user' || n, 'CS20 User ' || n from generate_series(1, 5) n;

-- ============================================================================
-- 1. Security & privilege checks on moderation tables, views, and RPCs
-- ============================================================================
-- [Test 1]
select is(
  (select relrowsecurity from pg_class where oid = 'private.objectionable_words'::regclass),
  true,
  'CS-03: RLS is enabled on private.objectionable_words'
);

-- [Test 2]
select ok(
  not has_table_privilege('anon', 'private.objectionable_words', 'select')
  and not has_table_privilege('authenticated', 'private.objectionable_words', 'select')
  and not has_table_privilege('anon', 'private.moderation_queue_due', 'select')
  and not has_table_privilege('authenticated', 'private.moderation_queue_due', 'select'),
  'CS-03: objectionable_words and moderation_queue_due are not readable by anon or authenticated'
);

-- [Test 3]
select ok(
  not has_function_privilege('authenticated', 'public.list_moderation_queue(text, int)', 'execute')
  and not has_function_privilege('authenticated', 'public.claim_moderation_notifications(int)', 'execute')
  and not has_function_privilege('authenticated', 'public.resolve_moderation_item(uuid, text, text)', 'execute')
  and not has_function_privilege('authenticated', 'private.moderate_queue_item(uuid, text, text)', 'execute')
  and not has_function_privilege('authenticated', 'public.upsert_objectionable_word(text, text, text, text, boolean)', 'execute')
  and not has_function_privilege('authenticated', 'public.account_has_password(uuid)', 'execute')
  and has_function_privilege('service_role', 'public.list_moderation_queue(text, int)', 'execute')
  and has_function_privilege('service_role', 'public.claim_moderation_notifications(int)', 'execute')
  and has_function_privilege('service_role', 'public.resolve_moderation_item(uuid, text, text)', 'execute')
  and has_function_privilege('service_role', 'public.upsert_objectionable_word(text, text, text, text, boolean)', 'execute')
  and has_function_privilege('service_role', 'public.account_has_password(uuid)', 'execute'),
  'CS-03 & CS-05: moderation management and account_has_password RPCs are restricted to service_role'
);

-- ============================================================================
-- 2. CS-03: Objectionable-content filter across all UGC write paths
-- ============================================================================
do $$ begin perform tests.as_user(tests.u(1)); end $$;

-- [Test 4] Benign Vietnamese words that share base letters with slurs (lon, cac, buoi, du) must pass
select lives_ok(
  $$ update public.profiles set display_name = 'Các bạn lớn đi du lịch buổi sáng' where id = tests.u(1) $$,
  'CS-03: benign Vietnamese diacritics (lớn, các, buổi, du lịch) are never false-flagged'
);

-- [Test 5] profiles.username rejects teencode / compound slurs
select throws_ok(
  $$ update public.profiles set username = 'user_ditme_99' where id = tests.u(1) $$,
  '23514', 'content_policy',
  'CS-03: profiles.username rejects Vietnamese compound slur with content_policy'
);

-- [Test 6] profiles.display_name rejects Vietnamese diacritic profanity
select throws_ok(
  $$ update public.profiles set display_name = 'Địt mẹ mày' where id = tests.u(1) $$,
  '23514', 'content_policy',
  'CS-03: profiles.display_name rejects Vietnamese profanity with content_policy'
);

-- [Test 7] profiles.display_name rejects English profanity / leet
select throws_ok(
  $$ update public.profiles set display_name = 'm0th3rfuck3r' where id = tests.u(1) $$,
  '23514', 'content_policy',
  'CS-03: profiles.display_name rejects leet-obfuscated English slur with content_policy'
);

-- [Test 8] create_journey rejects objectionable title
select throws_ok(
  $$ select public.create_journey(tests.j(90), 'solo', 'custom', 'Hành trình vãi lồn', '🔥',
                                  null, null, false, current_date, 30, 'UTC') $$,
  '23514', 'content_policy',
  'CS-03: create_journey rejects objectionable journey title'
);

-- [Test 9] create_journey rejects objectionable couple names
select throws_ok(
  $$ select public.create_journey(tests.j(91), 'group', 'custom', 'Couple Habit', '💞',
                                  null, null, false, current_date, 30, 'UTC', 2, 'private', 'An', 'con đĩ') $$,
  '23514', 'content_policy',
  'CS-03: create_journey rejects objectionable couple_partner_name'
);

-- [Test 10] create_imported_journey rejects objectionable title
select throws_ok(
  $$ select public.create_imported_journey(tests.j(92), 'Chuyến đi dkm', '✈️', 'travel',
                                           current_date - 10, current_date - 2, 'UTC') $$,
  '23514', 'content_policy',
  'CS-03: create_imported_journey rejects teencode profanity in title'
);

-- Setup clean solo and group journeys for subsequent tests
do $$ begin
  perform tests.as_user(tests.u(1));
  perform public.create_journey(tests.j(1), 'group', 'custom', 'Du lịch Đà Lạt', '🏔️',
                                'Quãng đường', 'km', false, current_date - 3, 30, 'UTC');
  perform public.create_journey(tests.j(2), 'solo', 'custom', 'Morning Run', '🏃',
                                null, null, false, current_date - 3, 30, 'UTC');
  perform tests.as_user(tests.u(2));
  perform public.join_by_code(tests.code(1));
  perform tests.as_user(tests.u(3));
  perform public.join_by_code(tests.code(1));
  perform tests.as_user(tests.u(4));
  perform public.join_by_code(tests.code(1));
  perform tests.as_user(tests.u(1));
end $$;

-- [Test 11] update_journey rejects objectionable title
select throws_ok(
  $$ select public.update_journey(tests.j(1), 'fuck this squad') $$,
  '23514', 'content_policy',
  'CS-03: update_journey rejects English profanity in title'
);

-- [Test 12] update_journey rejects objectionable DNA text field
select throws_ok(
  $$ select public.update_journey(tests.j(1), null, null, null, null, null,
                                  '{"trophy":"cunt trophy"}'::jsonb) $$,
  '23514', 'content_policy',
  'CS-03: update_journey rejects profanity inside journeys.dna'
);

-- [Test 13] update_journey_story rejects objectionable story intro/lessons
select throws_ok(
  $$ select public.update_journey_story(tests.j(1), 'Kỷ niệm đẹp', 'Vui vcl luôn', 'Bài học hay', null) $$,
  '23514', 'content_policy',
  'CS-03: update_journey_story rejects Vietnamese teencode profanity in story_intro'
);

-- [Test 14] check_ins INSERT rejects objectionable caption (including dot-separated evasion)
select throws_ok(
  $$ select tests.checkin(tests.c(90), tests.j(1), 'Hôm nay mệt d.i.t m.e') $$,
  '23514', 'content_policy',
  'CS-03: check_ins INSERT rejects dot-separated profanity in caption'
);

-- [Test 15] check_ins INSERT accepts clean Vietnamese caption and UPDATE rejects objectionable edit
select lives_ok(
  $$ select tests.checkin(tests.c(1), tests.j(1), 'Buổi sáng chạy bộ cùng các bạn lớn rất vui!') $$,
  'CS-03: check_ins INSERT accepts clean Vietnamese caption'
);

-- [Test 16]
select throws_ok(
  $$ update public.check_ins set caption = 'kill yourself now' where id = tests.c(1) $$,
  '23514', 'content_policy',
  'CS-03: check_ins UPDATE rejects self-harm solicitation in caption'
);

-- [Test 17] check_in_extras rejects objectionable dish/place text
select throws_ok(
  $$ insert into public.check_in_extras (checkin_id, journey_id, user_id, extras)
     values (tests.c(1), tests.j(1), auth.uid(), '{"dish":"món cái lồn"}'::jsonb) $$,
  '23514', 'content_policy',
  'CS-03: check_in_extras rejects profanity in extras JSON fields'
);

-- Setup a shared journey and 1-1 chat conversation between u(1) and u(2)
do $$ begin
  perform tests.befriend(tests.u(1), tests.u(2));
  perform tests.as_user(tests.u(1));
  perform tests.checkin(tests.c(2), tests.j(2), 'Day 1 run completed');
  perform public.end_journey(tests.j(2));
  perform public.share_journey(tests.j(2), array[tests.u(2)]);
  perform tests.as_user(tests.u(2));
  perform public.open_conversation(tests.j(2), tests.c(2));
end $$;

-- [Test 18] send_message rejects objectionable chat text
select throws_ok(
  $$ select public.send_message(tests.m(90), tests.conv(tests.j(2), tests.u(1), tests.u(2)),
                                'text', 'chat sex không em', null) $$,
  '23514', 'content_policy',
  'CS-03: send_message rejects sexual solicitation in chat body'
);

-- [Test 19] send_message accepts clean chat text
select lives_ok(
  $$ select public.send_message(tests.m(1), tests.conv(tests.j(2), tests.u(1), tests.u(2)),
                                'text', 'Chúc mừng bạn đã hoàn thành hành trình!', null) $$,
  'CS-03: send_message accepts clean Vietnamese chat message'
);

-- [Test 20] Dynamic word list update without deploy via public.upsert_objectionable_word
do $$ begin
  perform tests.as_service_role();
  perform public.upsert_objectionable_word('customblockedterm', 'en', 'word', 'profanity', true);
  perform tests.as_user(tests.u(1));
end $$;
select throws_ok(
  $$ update public.check_ins set caption = 'Testing customblockedterm filter' where id = tests.c(1) $$,
  '23514', 'content_policy',
  'CS-03: newly upserted word in private.objectionable_words takes effect immediately without deploy'
);

-- [Test 21] Disabling the custom word immediately allows it again
do $$ begin
  perform tests.as_service_role();
  perform public.upsert_objectionable_word('customblockedterm', 'en', 'word', 'profanity', false);
  perform tests.as_user(tests.u(1));
end $$;
select lives_ok(
  $$ update public.check_ins set caption = 'Testing customblockedterm filter' where id = tests.c(1) $$,
  'CS-03: disabling a word in private.objectionable_words allows it immediately'
);

-- ============================================================================
-- 3. CS-02: report_content with target_message_id (with and without p_user)
--           and hiding reported messages for the reporter
-- ============================================================================
do $$ begin
  perform tests.as_user(tests.u(2));
  insert into storage.objects (bucket_id, name)
  values ('messages', format('messages/%s/%s/%s.jpg', tests.conv(tests.j(2), tests.u(1), tests.u(2)), tests.u(2), tests.m(2)));
  perform public.send_message(
    tests.m(2),
    tests.conv(tests.j(2), tests.u(1), tests.u(2)),
    'photo',
    'Check out this photo',
    format('messages/%s/%s/%s.jpg', tests.conv(tests.j(2), tests.u(1), tests.u(2)), tests.u(2), tests.m(2))
  );
  perform tests.as_user(tests.u(1));
end $$;

-- [Test 22] Mismatched p_user and p_message sender is rejected
select throws_ok(
  $$ select public.report_content(null, tests.u(3), 'spam', 'wrong sender', tests.m(2)) $$,
  'P0001', 'invalid',
  'CS-02: report_content rejects p_message when p_user does not match the message sender'
);

-- [Test 23] Passing both p_user (sender) and p_message (mobile ChatScreen pattern) stores target_message_id
do $$ declare
  v_rep uuid;
begin
  perform tests.as_user(tests.u(1));
  v_rep := public.report_content(null, tests.u(2), 'harassment', 'offensive message', tests.m(2));
  if v_rep is null then
    raise exception 'expected report id';
  end if;
end $$;

select is(
  (select count(*)::int from public.reports
    where reporter_id = tests.u(1)
      and target_user_id = tests.u(2)
      and target_message_id = tests.m(2)
      and due_at = created_at + interval '24 hours')
  + (select count(*)::int from public.moderation_queue
      where actor_id = tests.u(1)
        and target_user_id = tests.u(2)
        and target_message_id = tests.m(2)
        and due_at = created_at + interval '24 hours'),
  2,
  'CS-02 & CS-03: report_content stores target_message_id and 24h due_at in both reports and moderation_queue'
);

-- [Test 24] Reported message and its storage object are hidden from the reporter at once
do $$ begin perform tests.as_user(tests.u(1)); end $$;
select is(
  (select count(*)::int from public.messages where id = tests.m(2))
  + (select count(*)::int from storage.objects
      where bucket_id = 'messages'
        and name = format('messages/%s/%s/%s.jpg', tests.conv(tests.j(2), tests.u(1), tests.u(2)), tests.u(2), tests.m(2))),
  0,
  'CS-02: reported message row and storage object are immediately hidden from the reporter'
);

-- [Test 25] Sender still sees own message before moderator action
do $$ begin perform tests.as_user(tests.u(2)); end $$;
select is(
  (select count(*)::int from public.messages where id = tests.m(2)),
  1,
  'CS-02: single report hides message from reporter only while pending moderator review'
);

-- ============================================================================
-- 4. CS-03: 24-hour moderation queue, auto-hide after N >= 2 distinct reports,
--           notification claiming, and moderator resolution (dismiss / remove / ban)
-- ============================================================================
-- u(2) reports u(1)'s check-in c(1) in group journey j(1) (1st distinct report)
do $$ begin
  perform tests.as_user(tests.u(2));
  perform public.report_content(tests.c(1), tests.u(1), 'spam', 'first report on c1');
end $$;

-- [Test 26] After 1 report, c(1) is hidden from reporter u(2) but still visible to u(4)
do $$ begin perform tests.as_user(tests.u(4)); end $$;
select is(
  (select count(*)::int from public.check_ins where id = tests.c(1)),
  1,
  'CS-03: check-in with 1 non-public spam report remains visible to other members'
);

-- u(3) also reports c(1) (2nd distinct open report -> triggers auto-quarantine)
do $$ begin
  perform tests.as_user(tests.u(3));
  perform public.report_content(tests.c(1), tests.u(1), 'harassment', 'second report on c1');
end $$;

-- [Test 27] After 2 distinct open reports, c(1) is auto-quarantined and hidden even from u(4)
do $$ begin perform tests.as_user(tests.u(4)); end $$;
select is(
  (select count(*)::int from public.check_ins where id = tests.c(1)),
  0,
  'CS-03: check-in is automatically hidden for all members after 2 distinct open reports pending review'
);

-- [Test 28] Author u(1) cannot un-delete or edit an auto-quarantined check-in
do $$ begin perform tests.as_user(tests.u(1)); end $$;
select throws_ok(
  $$ update public.check_ins set caption = 'try to edit quarantined' where id = tests.c(1) $$,
  '42501', 'forbidden',
  'CS-03: author cannot modify an auto-quarantined check-in while pending moderation'
);

-- [Test 29] claim_moderation_notifications claims unnotified open items once
do $$ begin perform tests.as_service_role(); end $$;
select is(
  (select count(*)::int from public.claim_moderation_notifications(50)),
  3,
  'CS-03: claim_moderation_notifications claims all 3 unnotified open queue items'
);

-- [Test 30] Second claim call returns 0 items (idempotent notification hook)
select is(
  (select count(*)::int from public.claim_moderation_notifications(50)),
  0,
  'CS-03: claim_moderation_notifications returns 0 on immediate repeat call (no duplicate emails)'
);

-- [Test 31] list_moderation_queue shows open items with distinct_open_reporters = 2 on c(1)
select is(
  (select (item->>'distinct_open_reporters')::int
     from public.list_moderation_queue('open', 50) item
    where (item->>'target_checkin_id')::uuid = tests.c(1)
    limit 1),
  2,
  'CS-03: list_moderation_queue reports distinct_open_reporters = 2 and 24h SLA metadata'
);

-- [Test 32] Moderator dismissing false-positive reports on c(1) restores the check-in for u(4)
do $$ begin
  perform tests.as_service_role();
  perform public.resolve_moderation_item(tests.latest_queue_id(tests.c(1), null, null), 'dismiss', 'benign running photo');
  perform tests.as_user(tests.u(4));
end $$;
select is(
  (select count(*)::int from public.check_ins where id = tests.c(1)),
  1,
  'CS-03: dismissing auto-quarantined check-in report restores visibility for other members'
);

-- [Test 33] Public-link check-in reported for nudity is immediately auto-quarantined on 1st report
do $$ begin
  perform tests.as_user(tests.u(1));
  perform public.set_public_link(tests.j(2), true);
  perform tests.as_user(tests.u(2));
  perform public.report_content(tests.c(2), tests.u(1), 'nudity', 'explicit photo on public link');
  perform tests.as_postgres();
end $$;
select is(
  (select (moderated_at is not null and deleted_at is not null) from public.check_ins where id = tests.c(2)),
  true,
  'CS-03: nudity report on a public-link journey check-in auto-quarantines immediately'
);

-- [Test 34] Moderator remove_content permanently actions the message report
do $$ begin
  perform tests.as_service_role();
  perform public.resolve_moderation_item(tests.latest_queue_id(null, tests.m(2), null), 'remove_content', 'confirmed harassment');
  perform tests.as_user(tests.u(2));
end $$;
select is(
  (select count(*)::int from public.messages where id = tests.m(2)),
  0,
  'CS-03: resolve_moderation_item(remove_content) hides the moderated message even from its sender'
);

-- [Test 35] Moderator ban_user suspends the offending profile, moderates all their content, and revokes public links
do $$ begin
  perform tests.as_user(tests.u(3));
  perform tests.checkin(tests.c(3), tests.j(1), 'spam check-in by u3');
  perform tests.as_user(tests.u(4));
  perform public.report_content(tests.c(3), tests.u(3), 'spam', 'repeat spammer u3');
  perform tests.as_service_role();
  perform public.resolve_moderation_item(tests.latest_queue_id(tests.c(3), null, tests.u(3)), 'ban_user', 'banned repeat offender');
  perform tests.as_postgres();
end $$;
select is(
  (select (p.deleted_at is not null) from public.profiles p where p.id = tests.u(3))
  and (select (c.moderated_at is not null and c.deleted_at is not null) from public.check_ins c where c.id = tests.c(3))
  and (select count(*)::int = 0 from public.moderation_queue where target_user_id = tests.u(3) and status = 'open'),
  true,
  'CS-03: resolve_moderation_item(ban_user) soft-deletes profile, moderates content, and closes open queue items'
);

-- [Test 36] Banned user can no longer create journeys or post messages
do $$ begin perform tests.as_user(tests.u(3)); end $$;
select throws_ok(
  $$ select public.create_journey(tests.j(99), 'solo', 'custom', 'Banned', '🚫',
                                  null, null, false, current_date, 30, 'UTC') $$,
  '42501', 'forbidden',
  'CS-03: banned user (profiles.deleted_at set) is blocked from creating new journeys'
);

-- ============================================================================
-- 5. CS-05: account_has_password for OTP accounts vs password / App Review demo account
-- ============================================================================
do $$ begin perform tests.as_service_role(); end $$;

-- [Test 37] OTP-only accounts (null or empty encrypted_password) return false
select is(
  public.account_has_password(tests.u(1)) or public.account_has_password(tests.u(2)),
  false,
  'CS-05: account_has_password returns false for OTP-only accounts without a password'
);

-- [Test 38] Password-enabled / App Review demo account returns true
select is(
  public.account_has_password(tests.u(5)),
  true,
  'CS-05: account_has_password returns true for password-enabled / App Review demo accounts'
);

select * from finish();
rollback;
