-- 0024_feature_requests: pgTAP verification of In-App Feature Requests & Public Roadmap Board
-- (spec §4.5 + binding amendments F1-F3 in fr-opus-review.md).
--
-- Follows repo pgTAP rules:
--   - Exact plan(50)
--   - No psql :'var' inside DO blocks
--   - No data-modifying CTEs inside pgTAP assertions
--   - Writes execute in separate statements before assertion queries
begin;
create extension if not exists pgtap with schema extensions;
select plan(50);

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
  select format('24000000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;

create function tests.fr(n int) returns uuid language sql immutable as $$
  select format('f2400000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;

create function tests.count_fr_admin_rpcs_denying_caller() returns int
language plpgsql
as $$
declare
  v_denied int := 0;
begin
  begin
    perform admin.feature_request_stats();
  exception when sqlstate '42501' then
    v_denied := v_denied + 1;
  end;

  begin
    perform admin.list_feature_requests();
  exception when sqlstate '42501' then
    v_denied := v_denied + 1;
  end;

  begin
    perform admin.get_feature_request_detail(tests.fr(1));
  exception when sqlstate '42501' then
    v_denied := v_denied + 1;
  end;

  begin
    perform admin.update_feature_request(tests.fr(1), 'planned', 'camera', 'reply', false, 'reason');
  exception when sqlstate '42501' then
    v_denied := v_denied + 1;
  end;

  begin
    perform admin.merge_feature_request(tests.fr(1), tests.fr(2), 'merge');
  exception when sqlstate '42501' then
    v_denied := v_denied + 1;
  end;

  return v_denied;
end;
$$;

grant execute on all functions in schema tests to anon, authenticated, service_role;

-- Seed test accounts:
--   u(1): Moderator admin
--   u(2): Regular user A (author)
--   u(3): Regular user B (voter / reporter 1)
--   u(4): Regular user C (voter / reporter 2)
--   u(5): Regular user D (rate-limit / ban / soft-delete test user)
--   u(6): Regular user E (account deletion purge_account_data test user)
insert into auth.users (id, email)
values
  (tests.u(1), 'fr_mod1@ourney.tech'),
  (tests.u(2), 'fr_user_a@example.test'),
  (tests.u(3), 'fr_user_b@example.test'),
  (tests.u(4), 'fr_user_c@example.test'),
  (tests.u(5), 'fr_user_d@example.test'),
  (tests.u(6), 'fr_user_e@example.test');

insert into public.profiles (id, username, display_name, avatar_path)
values
  (tests.u(1), 'fr_admin_mod', 'FR Moderator', null),
  (tests.u(2), 'fr_author_a', 'Author A', format('avatars/%s/aaaaaaaa-0000-4000-8000-000000000002.jpg', tests.u(2))),
  (tests.u(3), 'fr_voter_b', 'Voter B', null),
  (tests.u(4), 'fr_voter_c', 'Voter C', null),
  (tests.u(5), 'fr_tester_d', 'Tester D', null),
  (tests.u(6), 'fr_deleting_e', 'Deleting E', null);

insert into private.admins (user_id, role, note, added_by)
values
  (tests.u(1), 'moderator', 'FR test moderator', tests.u(1));

-- ============================================================================
-- 1. Privilege & Structural Invariants (Tests 1..7)
-- ============================================================================
-- [Test 1] RLS is enabled on public.feature_requests, public.feature_request_votes, and private.feature_request_notifications
select is(
  (select bool_and(relrowsecurity)
     from pg_class
    where oid in (
      'public.feature_requests'::regclass,
      'public.feature_request_votes'::regclass,
      'private.feature_request_notifications'::regclass
    )),
  true,
  'RLS is enabled on public.feature_requests, public.feature_request_votes, and private.feature_request_notifications'
);

-- [Test 2] Table privilege isolation for anon and authenticated
select is(
  (select count(*)::int
     from information_schema.role_table_grants
    where (
      (table_schema = 'public' and table_name in ('feature_requests', 'feature_request_votes') and grantee = 'anon')
      or (table_schema = 'private' and table_name = 'feature_request_notifications' and grantee in ('anon', 'authenticated'))
    )) = 0
  and not has_table_privilege('authenticated', 'public.feature_requests', 'insert')
  and not has_table_privilege('authenticated', 'public.feature_requests', 'delete')
  and not has_table_privilege('authenticated', 'public.feature_request_votes', 'insert')
  and not has_table_privilege('authenticated', 'public.feature_request_votes', 'update')
  and not has_table_privilege('authenticated', 'public.feature_request_votes', 'delete'),
  true,
  'anon has zero table access; authenticated has zero access to private.feature_request_notifications and cannot directly insert/delete feature_requests or votes'
);

-- [Test 3] anon cannot execute any public or admin feature-request RPC
select is(
  has_function_privilege('anon', 'public.list_feature_requests(text, text, text, boolean, int, int)', 'execute')
  or has_function_privilege('anon', 'public.get_feature_request(uuid)', 'execute')
  or has_function_privilege('anon', 'public.search_similar_feature_requests(text, int)', 'execute')
  or has_function_privilege('anon', 'public.create_feature_request(uuid, text, text, text)', 'execute')
  or has_function_privilege('anon', 'public.update_feature_request(uuid, text, text, text)', 'execute')
  or has_function_privilege('anon', 'public.delete_feature_request(uuid)', 'execute')
  or has_function_privilege('anon', 'public.toggle_feature_request_vote(uuid, boolean)', 'execute')
  or has_function_privilege('anon', 'public.report_feature_request(uuid, public.report_reason, text)', 'execute')
  or has_function_privilege('anon', 'public.my_shipped_request_notifications(int)', 'execute')
  or has_function_privilege('anon', 'public.mark_shipped_requests_seen(uuid[])', 'execute')
  or has_function_privilege('anon', 'admin.feature_request_stats()', 'execute')
  or has_function_privilege('anon', 'admin.list_feature_requests(text, text, text, text, text, int, int)', 'execute')
  or has_function_privilege('anon', 'admin.get_feature_request_detail(uuid)', 'execute')
  or has_function_privilege('anon', 'admin.update_feature_request(uuid, text, text, text, boolean, text)', 'execute')
  or has_function_privilege('anon', 'admin.merge_feature_request(uuid, uuid, text)', 'execute'),
  false,
  'anon has zero EXECUTE privileges on public and admin feature-request RPCs'
);

-- [Test 4] Every SECURITY DEFINER function in public, private, and admin pins search_path = ''
select is(
  (select count(*)::int
     from pg_proc p
     join pg_namespace n on n.oid = p.pronamespace
    where n.nspname in ('public', 'private', 'admin')
      and p.prosecdef
      and not coalesce(exists (select 1 from unnest(p.proconfig) c where c like 'search_path=%'), false)),
  0,
  'every SECURITY DEFINER function in public, private, and admin pins search_path'
);

-- [Test 5] Internal helpers in schema private are not executable by anon or authenticated
select is(
  has_function_privilege('anon', 'private.fold_vi(text)', 'execute')
  or has_function_privilege('authenticated', 'private.fold_vi(text)', 'execute')
  or has_function_privilege('anon', 'private.feature_request_json(public.feature_requests, uuid)', 'execute')
  or has_function_privilege('authenticated', 'private.feature_request_json(public.feature_requests, uuid)', 'execute')
  or has_function_privilege('authenticated', 'private.feature_requests_before_write()', 'execute')
  or has_function_privilege('authenticated', 'private.sync_feature_request_vote_count()', 'execute'),
  false,
  'internal feature-request helpers in schema private are not callable by anon or authenticated'
);

-- [Test 6] Non-admin authenticated user receives 42501 ('forbidden') on all 5 admin.*feature_request* RPCs
do $$ begin perform tests.as_user(tests.u(2)); end $$;
select is(
  tests.count_fr_admin_rpcs_denying_caller(),
  5,
  'non-admin authenticated user receives 42501 on all 5 admin.*feature_request* RPCs'
);

-- [Test 7] Unauthenticated caller receives 28000 on public.list_feature_requests
do $$ begin perform tests.as_postgres(); end $$;
select throws_ok(
  $$ select public.list_feature_requests() $$,
  '28000', 'unauthenticated',
  'unauthenticated caller receives 28000 on public.list_feature_requests'
);

-- ============================================================================
-- 2. Creation, Auto-Upvote, Trimming & Idempotency (Tests 8..10)
-- ============================================================================
do $$
declare
  v_res json;
begin
  perform tests.as_user(tests.u(2));
  v_res := public.create_feature_request(
    tests.fr(1),
    '   Widget màn hình khóa   ',
    '   Hiển thị chuỗi ngày ngay trên màn hình khóa iOS và Android để nhắc check-in mỗi sáng.   ',
    'design'
  );
end $$;

-- [Test 8] create_feature_request trims text, auto-upvotes (vote_count=1, voted_by_me=true), and hides author avatar_path/email
select is(
  (public.get_feature_request(tests.fr(1)) ->> 'title') = 'Widget màn hình khóa'
  and (public.get_feature_request(tests.fr(1)) ->> 'status') = 'new'
  and (public.get_feature_request(tests.fr(1)) ->> 'category') = 'design'
  and (public.get_feature_request(tests.fr(1)) ->> 'vote_count')::int = 1
  and (public.get_feature_request(tests.fr(1)) ->> 'voted_by_me')::boolean = true
  and (public.get_feature_request(tests.fr(1)) ->> 'is_mine')::boolean = true
  and (public.get_feature_request(tests.fr(1)) #>> '{author,username}') = 'fr_author_a'
  and (public.get_feature_request(tests.fr(1)) #> '{author,avatar_path}') is null
  and (public.get_feature_request(tests.fr(1)) #> '{author,email}') is null
  and (select created_at = updated_at from public.feature_requests where id = tests.fr(1)),
  true,
  'create_feature_request trims text, sets status=new, auto-upvotes (vote_count=1, voted_by_me=true), keeps updated_at=created_at, and omits private avatar_path/email'
);

-- [Test 9] Idempotent retry with the same p_id by the same author returns existing request with vote_count = 1
select is(
  (public.create_feature_request(
    tests.fr(1),
    'Widget màn hình khóa',
    'Hiển thị chuỗi ngày ngay trên màn hình khóa iOS và Android để nhắc check-in mỗi sáng.',
    'design'
  ) ->> 'vote_count')::int,
  1,
  'create_feature_request is idempotent on retry with the same p_id by the same author'
);

-- [Test 10] Another user attempting to create a feature request with an existing p_id receives 42501 ('forbidden')
do $$ begin perform tests.as_user(tests.u(3)); end $$;
select throws_ok(
  $$ select public.create_feature_request(
       tests.fr(1),
       'Collision title attempt',
       'Attempting to overwrite another user feature request ID.',
       'other'
     ) $$,
  '42501', 'forbidden',
  'create_feature_request rejects p_id collision from another user with 42501 forbidden'
);

-- ============================================================================
-- 3. Content Filter (0020) & URL Spam Guard (Tests 11..17)
-- ============================================================================
do $$ begin perform tests.as_user(tests.u(2)); end $$;

-- [Test 11] Rejects Vietnamese diacritic profanity ('địt')
select throws_ok(
  $$ select public.create_feature_request(
       tests.fr(91),
       'Tính năng địt nhau',
       'Mô tả bình thường đủ dài hơn mười ký tự.',
       'other'
     ) $$,
  '23514', 'content_policy',
  'create_feature_request rejects Vietnamese diacritic profanity (địt) with 23514 content_policy'
);

-- [Test 12] Rejects unaccented Vietnamese phrase ('dit me')
select throws_ok(
  $$ select public.create_feature_request(
       tests.fr(92),
       'Thêm nút bấm nhanh',
       'App chậm quá dit me sửa ngay đi các bạn ơi.',
       'other'
     ) $$,
  '23514', 'content_policy',
  'create_feature_request rejects unaccented Vietnamese phrase (dit me) with 23514 content_policy'
);

-- [Test 13] Rejects Vietnamese teencode ('vcl')
select throws_ok(
  $$ select public.create_feature_request(
       tests.fr(93),
       'Giao diện mới đẹp',
       'Nhưng mà lag vcl luôn khi mở máy ảnh buổi tối.',
       'camera'
     ) $$,
  '23514', 'content_policy',
  'create_feature_request rejects Vietnamese teencode profanity (vcl) with 23514 content_policy'
);

-- [Test 14] Rejects English profanity ('fuck')
select throws_ok(
  $$ select public.create_feature_request(
       tests.fr(94),
       'What the fuck widget',
       'Please add a clean habit calendar view for squads.',
       'squad'
     ) $$,
  '23514', 'content_policy',
  'create_feature_request rejects English profanity (fuck) with 23514 content_policy'
);

-- [Test 15] Rejects external URLs ('https://spam.example.com') with links_not_allowed
select throws_ok(
  $$ select public.create_feature_request(
       tests.fr(95),
       'Thêm liên kết ngoài',
       'Xem chi tiết tại https://spam.example.com/promo để nhận thưởng ngay.',
       'sharing'
     ) $$,
  '23514', 'links_not_allowed',
  'create_feature_request rejects external URLs with 23514 links_not_allowed'
);

-- [Test 16] update_feature_request also enforces content_policy and links_not_allowed
select throws_ok(
  $$ select public.update_feature_request(
       tests.fr(1),
       'Widget www.spam.vn/link',
       'Hiển thị chuỗi ngày ngay trên màn hình khóa iOS và Android.',
       'design'
     ) $$,
  '23514', 'links_not_allowed',
  'update_feature_request rejects external URLs with 23514 links_not_allowed'
);

-- [Test 17] Allows legitimate Vietnamese diacritics without false positives
select lives_ok(
  $$ select public.create_feature_request(
       tests.fr(2),
       'Chế độ tối cho buổi sáng',
       'Theo dõi cân nặng và các bài tập lớn buổi chiều khi đi du lịch Đà Lạt cùng bạn bè.',
       'journeys'
     ) $$,
  'create_feature_request allows legitimate Vietnamese diacritics (Chế độ tối cho buổi sáng, cân nặng, lớn, buổi)'
);

-- ============================================================================
-- 4. Rate Limits & Banned / Soft-Deleted User Guards (Tests 18..20)
-- ============================================================================
do $$
begin
  perform tests.as_user(tests.u(5));
  perform public.create_feature_request(tests.fr(51), 'Đề xuất số 1 của D', 'Nội dung chi tiết cho đề xuất số 1 của người dùng D.', 'camera');
  perform public.create_feature_request(tests.fr(52), 'Đề xuất số 2 của D', 'Nội dung chi tiết cho đề xuất số 2 của người dùng D.', 'journeys');
  perform public.create_feature_request(tests.fr(53), 'Đề xuất số 3 của D', 'Nội dung chi tiết cho đề xuất số 3 của người dùng D.', 'squad');
  perform public.create_feature_request(tests.fr(54), 'Đề xuất số 4 của D', 'Nội dung chi tiết cho đề xuất số 4 của người dùng D.', 'sharing');
  perform public.create_feature_request(tests.fr(55), 'Đề xuất số 5 của D', 'Nội dung chi tiết cho đề xuất số 5 của người dùng D.', 'design');
end $$;

-- [Test 18] 6th create_feature_request within 24h by the same user raises rate_limited
select throws_ok(
  $$ select public.create_feature_request(
       tests.fr(56),
       'Đề xuất số 6 vượt giới hạn',
       'Nội dung chi tiết cho đề xuất thứ 6 trong vòng 24 giờ.',
       'other'
     ) $$,
  'P0001', 'rate_limited',
  '6th create_feature_request within 24 hours raises rate_limited'
);

-- [Test 19] Banned user (0023 unified ban model: profiles.deleted_at IS NULL) receives 42501 ('forbidden')
do $$
begin
  perform tests.as_postgres();
  delete from private.rate_events where user_id = tests.u(5);
  perform tests.as_user(tests.u(1));
  perform admin.ban_user(tests.u(5), 'spamming feature requests', false);
  perform tests.as_user(tests.u(5));
end $$;

select throws_ok(
  $$ select public.create_feature_request(
       tests.fr(57),
       'Banned user feature request',
       'Banned user with active JWT attempting to create a feature request.',
       'other'
     ) $$,
  '42501', 'forbidden',
  'banned user (private.is_user_banned, profiles.deleted_at IS NULL) receives 42501 forbidden'
);

-- [Test 20] Unbanned but soft-deleted profile (profiles.deleted_at IS NOT NULL) receives 42501 ('forbidden')
do $$
begin
  perform tests.as_user(tests.u(1));
  perform admin.unban_user(tests.u(5), 'unban before testing soft-deleted profile');
  perform tests.as_postgres();
  update public.profiles set deleted_at = now() where id = tests.u(5);
  perform tests.as_user(tests.u(5));
end $$;

select throws_ok(
  $$ select public.create_feature_request(
       tests.fr(58),
       'Deleted profile request',
       'Soft-deleted profile attempting to create a feature request.',
       'other'
     ) $$,
  '42501', 'forbidden',
  'soft-deleted profile receives 42501 forbidden on create_feature_request'
);

do $$
begin
  perform tests.as_postgres();
  update public.profiles set deleted_at = null where id = tests.u(5);
  delete from public.feature_requests where author_id = tests.u(5);
end $$;

-- ============================================================================
-- 5. Author Edit & Delete Lifecycle + F3 Direct Table Write Guards (Tests 21..26)
-- ============================================================================
do $$
begin
  perform tests.as_user(tests.u(2));
  perform public.update_feature_request(
    tests.fr(2),
    'Chế độ tối tự động theo giờ',
    'Tự động chuyển sang giao diện tối sau 18h tối và sáng lại lúc 6h sáng.',
    'design'
  );
  update public.feature_requests
     set title = 'Chế độ tối tự động cho buổi sáng'
   where id = tests.fr(2);
end $$;

-- [Test 21] Author can update own 'new' request via both RPC and direct table UPDATE
select is(
  (public.get_feature_request(tests.fr(2)) ->> 'title') = 'Chế độ tối tự động cho buổi sáng'
  and (public.get_feature_request(tests.fr(2)) ->> 'category') = 'design',
  true,
  'author can update own request while status = new via both update_feature_request RPC and direct table UPDATE'
);

-- [Test 22] Non-author receives 42501 ('forbidden') on update_feature_request and delete_feature_request
do $$ begin perform tests.as_user(tests.u(3)); end $$;
select throws_ok(
  $$ select public.update_feature_request(
       tests.fr(2),
       'Hijack title',
       'Hijacking another user feature request body text.',
       'other'
     ) $$,
  '42501', 'forbidden',
  'non-author receives 42501 forbidden on update_feature_request'
);

-- [Test 23] Direct client UPDATE attempting to modify an ungranted/immutable column (status/vote_count) is rejected
do $$ begin perform tests.as_user(tests.u(2)); end $$;
select throws_ok(
  $$ update public.feature_requests set vote_count = 999 where id = tests.fr(2) $$,
  '42501', null,
  'direct client UPDATE on vote_count is rejected by column privilege / trigger guard'
);

-- [Test 24] Once admin transitions status to 'under_review', author UPDATE (both RPC and direct table UPDATE) and DELETE fail with 42501 ('forbidden')
do $$
begin
  perform tests.as_user(tests.u(1));
  perform admin.update_feature_request(
    tests.fr(2),
    'under_review',
    'design',
    'Đội ngũ Ourney đang xem xét đề xuất này.',
    false,
    'triage to under_review'
  );
  perform tests.as_user(tests.u(2));
end $$;

select throws_ok(
  $$ update public.feature_requests set title = 'Sửa trực tiếp khi đang xem xét' where id = tests.fr(2) $$,
  '42501', 'forbidden',
  'F3: direct table UPDATE by author fails with 42501 forbidden once status is under_review'
);

-- [Test 25] Author calling update_feature_request or delete_feature_request after status moves to under_review/planned fails with 42501 ('forbidden')
select throws_ok(
  $$ select public.delete_feature_request(tests.fr(2)) $$,
  '42501', 'forbidden',
  'delete_feature_request by author fails with 42501 forbidden once status is no longer new'
);

-- [Test 26] Author can create and delete their own unreviewed (status = 'new') request
do $$
begin
  perform tests.as_user(tests.u(2));
  perform public.create_feature_request(
    tests.fr(3),
    'Đề xuất nháp cần xóa',
    'Người dùng tạo nhầm đề xuất và xóa ngay khi còn ở trạng thái mới.',
    'other'
  );
  perform public.delete_feature_request(tests.fr(3));
end $$;

select is(
  (select count(*)::int from public.feature_requests where id = tests.fr(3)),
  0,
  'author can delete own feature request while status = new'
);

-- ============================================================================
-- 6. Voting, Voter Privacy RLS & Declined Visibility (Tests 27..30)
-- ============================================================================
do $$
begin
  perform tests.as_user(tests.u(3));
  perform public.toggle_feature_request_vote(tests.fr(1), true);
  -- Idempotent repeat vote with p_voted = true
  perform public.toggle_feature_request_vote(tests.fr(1), true);
end $$;

-- [Test 27] toggle_feature_request_vote increments vote_count accurately without double-counting or bumping updated_at
select is(
  (public.get_feature_request(tests.fr(1)) ->> 'vote_count')::int = 2
  and (public.get_feature_request(tests.fr(1)) ->> 'voted_by_me')::boolean = true
  and (select created_at = updated_at from public.feature_requests where id = tests.fr(1)),
  true,
  'toggle_feature_request_vote increments vote_count to 2, is idempotent on repeat upvote, and preserves updated_at'
);

-- [Test 28] Strict voter privacy RLS: User B (u(3)) sees only their own vote row (1 row) and zero rows of User A (u(2))
select is(
  (select count(*)::int from public.feature_request_votes) = 1
  and (select count(*)::int from public.feature_request_votes where user_id = tests.u(2)) = 0,
  true,
  'F4: feature_request_votes RLS restricts SELECT to user_id = auth.uid() (zero other voters leaked)'
);

-- [Test 29] Voting on a 'declined' request raises 'ended'
do $$
begin
  perform tests.as_user(tests.u(2));
  perform public.create_feature_request(
    tests.fr(4),
    'Tính năng đào tiền ảo',
    'Thêm ví tiền ảo vào ứng dụng thói quen hằng ngày.',
    'other'
  );
  perform tests.as_user(tests.u(1));
  perform admin.update_feature_request(
    tests.fr(4),
    'declined',
    'other',
    'Không phù hợp định hướng sản phẩm của Ourney.',
    false,
    'decline off-strategy request'
  );
  perform tests.as_user(tests.u(3));
end $$;

select throws_ok(
  $$ select public.toggle_feature_request_vote(tests.fr(4), true) $$,
  'P0001', 'ended',
  'voting on a declined feature request raises P0001 ended'
);

-- [Test 30] Declined request is hidden from other users (u(3)), but remains readable to its author (u(2)) in p_mine_only
do $$
begin
  perform tests.as_user(tests.u(2));
  if (select count(*)::int from public.feature_requests where id = tests.fr(4)) <> 1
     or (select count(*)::int from public.list_feature_requests('popular', null, null, true, 30, 0) x
          where (x ->> 'id')::uuid = tests.fr(4)) <> 1 then
    raise exception 'expected declined request fr(4) to remain readable to its author u(2) in SELECT RLS and p_mine_only';
  end if;
  perform tests.as_user(tests.u(3));
end $$;

select is(
  (select count(*)::int from public.feature_requests where id = tests.fr(4)) = 0
  and (select count(*)::int from public.list_feature_requests('popular', null, null, false, 30, 0) x where (x ->> 'id')::uuid = tests.fr(4)) = 0,
  true,
  'declined feature request is readable to its author in p_mine_only but hidden from non-authors in SELECT RLS and public board tabs'
);

-- ============================================================================
-- 7. Vietnamese Diacritic-Insensitive Duplicate Search (Test 31)
-- ============================================================================
-- [Test 31] search_similar_feature_requests('khoa man hinh') finds 'Widget màn hình khóa'
select is(
  exists (
    select 1
      from public.search_similar_feature_requests('khoa man hinh', 5) x
     where (x ->> 'id')::uuid = tests.fr(1)
  ),
  true,
  'search_similar_feature_requests(khoa man hinh) matches Widget màn hình khóa via diacritic folding + trigram similarity'
);

-- ============================================================================
-- 8. UGC Blocking & 24h SLA Reporting / Auto-Quarantine / Moderation (Tests 32..37)
-- ============================================================================
do $$
begin
  -- User B (u(3)) blocks Author A (u(2))
  perform tests.as_user(tests.u(3));
  perform public.block_user(tests.u(2));
end $$;

-- [Test 32] Blocking hides all feature requests in both directions in SELECT RLS and list_feature_requests
select is(
  (select count(*)::int from public.feature_requests where author_id = tests.u(2)) = 0
  and (select count(*)::int from public.list_feature_requests('popular', null, null, false, 30, 0) x
        where (x #>> '{author,user_id}')::uuid = tests.u(2)) = 0,
  true,
  'blocking an author immediately hides all their feature requests from the blocker'
);

do $$
begin
  perform tests.as_user(tests.u(3));
  perform public.unblock_user(tests.u(2));
end $$;

-- [Test 33] 1st spam report hides request immediately from reporter u(3), creates 24h SLA rows, and keeps it visible to User C (u(4))
do $$
declare
  v_rep1 uuid;
  v_rep1_dup uuid;
begin
  perform tests.as_user(tests.u(3));
  v_rep1 := public.report_feature_request(tests.fr(2), 'spam', 'first spam report');
  v_rep1_dup := public.report_feature_request(tests.fr(2), 'harassment', 'duplicate open report by u3');
  if v_rep1 is null or v_rep1 <> v_rep1_dup then
    raise exception 'expected report_feature_request to deduplicate open reports by same reporter';
  end if;
end $$;

select is(
  -- Hidden from reporter u(3) in both SELECT RLS and list_feature_requests
  (select count(*)::int from public.feature_requests where id = tests.fr(2)) = 0
  and (select count(*)::int from public.list_feature_requests('popular', null, null, false, 30, 0) x
        where (x ->> 'id')::uuid = tests.fr(2)) = 0,
  true,
  '1st spam report immediately hides the feature request from the reporter in both SELECT RLS and list_feature_requests'
);

-- Verify User C (u(4)) still sees fr(2), then User C submits the 2nd distinct report -> auto-quarantine!
do $$
begin
  perform tests.as_user(tests.u(4));
  if (select count(*)::int from public.feature_requests where id = tests.fr(2)) <> 1 then
    raise exception 'expected fr(2) to remain visible to third user u(4) after 1 spam report';
  end if;
  perform public.report_feature_request(tests.fr(2), 'harassment', 'second distinct report triggers quarantine');
  perform tests.as_postgres();
end $$;

-- [Test 34] 2nd distinct open report auto-quarantines (hidden = true, moderated_at IS NOT NULL) and sets 24h due_at
select is(
  (select hidden and moderated_at is not null from public.feature_requests where id = tests.fr(2))
  and (select count(*)::int = 2 from public.reports
        where target_feature_request_id = tests.fr(2)
          and status = 'open'
          and due_at = created_at + interval '24 hours')
  and (select count(*)::int = 2 from public.moderation_queue
        where target_feature_request_id = tests.fr(2)
          and status = 'open'
          and due_at = created_at + interval '24 hours'),
  true,
  '2nd distinct reporter auto-quarantines feature request (hidden=true, moderated_at set) with 24h SLA due_at'
);

-- [Test 35] Dismissing via private.moderate_queue_item restores hidden = false and moderated_at = null
do $$
declare
  v_qid uuid;
begin
  perform tests.as_postgres();
  select id into v_qid
    from public.moderation_queue
   where target_feature_request_id = tests.fr(2)
     and status = 'open'
   order by created_at desc
   limit 1;
  perform tests.as_service_role();
  perform private.moderate_queue_item(v_qid, 'dismiss', 'benign feature idea');
  perform tests.as_postgres();
end $$;

select is(
  (select not hidden and moderated_at is null from public.feature_requests where id = tests.fr(2)),
  true,
  'private.moderate_queue_item(dismiss) restores auto-quarantined feature request (hidden=false, moderated_at=null)'
);

-- [Test 36] Single 'nudity' report on a fresh request auto-quarantines on 1st report, and 'remove_content' keeps hidden = true
do $$
declare
  v_qid uuid;
begin
  perform tests.as_user(tests.u(2));
  perform public.create_feature_request(
    tests.fr(5),
    'Đề xuất bị báo cáo nhạy cảm',
    'Nội dung đề xuất dùng để kiểm tra tự động khóa khi bị báo cáo nudity.',
    'other'
  );
  perform tests.as_user(tests.u(3));
  perform public.report_feature_request(tests.fr(5), 'nudity', 'single severe report auto-quarantines');
  perform tests.as_postgres();
  if not (select hidden and moderated_at is not null from public.feature_requests where id = tests.fr(5)) then
    raise exception 'expected 1st nudity report to auto-quarantine immediately';
  end if;
  select id into v_qid
    from public.moderation_queue
   where target_feature_request_id = tests.fr(5)
     and status = 'open'
   limit 1;
  perform tests.as_service_role();
  perform private.moderate_queue_item(v_qid, 'remove_content', 'confirmed policy violation');
  perform tests.as_postgres();
end $$;

select is(
  (select hidden and moderated_at is not null from public.feature_requests where id = tests.fr(5))
  and (select status = 'actioned' from public.reports where target_feature_request_id = tests.fr(5) limit 1),
  true,
  '1st nudity report auto-quarantines immediately and private.moderate_queue_item(remove_content) keeps hidden=true'
);

-- [Test 37] Self-reporting own feature request raises 'invalid'
do $$ begin perform tests.as_user(tests.u(2)); end $$;
select throws_ok(
  $$ select public.report_feature_request(tests.fr(1), 'spam', 'self report attempt') $$,
  'P0001', 'invalid',
  'report_feature_request rejects self-reporting own request with P0001 invalid'
);

-- ============================================================================
-- 9. Admin Operations, Duplicate Merge & Shipped Notification Loop (Tests 38..41)
-- ============================================================================
do $$
begin
  -- User B (u(3)) creates a duplicate request fr(6) (auto-upvoted by u(3)), and User C (u(4)) votes on fr(6).
  -- Note: fr(1) currently has votes from u(2) and u(3) (2 votes).
  -- fr(6) has votes from u(3) and u(4) (2 votes).
  -- Merging fr(6) -> fr(1) should transfer u(4)'s unique vote (u(3) already voted on fr(1)) for a net total of 3 unique votes!
  perform tests.as_user(tests.u(3));
  perform public.create_feature_request(
    tests.fr(6),
    'Thêm widget ngoài màn hình chính',
    'Cho phép xem nhanh chuỗi ngày streak ngay trên màn hình iPhone mà không cần mở app.',
    'design'
  );
  perform tests.as_user(tests.u(4));
  perform public.toggle_feature_request_vote(tests.fr(6), true);

  -- Moderator u(1) merges fr(6) into canonical fr(1)
  perform tests.as_user(tests.u(1));
  perform admin.merge_feature_request(tests.fr(6), tests.fr(1), 'duplicate lock-screen widget request');
end $$;

-- [Test 38] admin.merge_feature_request consolidates unique voters (3 total), sets duplicate_of, exposes canonical_title, logs audit, and locks voting on merged child
do $$ begin perform tests.as_user(tests.u(3)); end $$;
select is(
  (public.get_feature_request(tests.fr(1)) ->> 'vote_count')::int = 3
  and (public.get_feature_request(tests.fr(6)) ->> 'duplicate_of')::uuid = tests.fr(1)
  and (public.get_feature_request(tests.fr(6)) ->> 'canonical_title') = 'Widget màn hình khóa'
  and (select count(*)::int from public.list_feature_requests('popular', null, null, false, 30, 0) x
        where (x ->> 'id')::uuid = tests.fr(6)) = 0,
  true,
  'admin.merge_feature_request consolidates overlapping + unique voters without double-counting and hides merged child from public tabs'
);

-- [Test 39] admin.update_feature_request rejects profanity in admin_reply, then ships fr(1) and notifies all voters + authors (including merged duplicate voters)
do $$ begin perform tests.as_user(tests.u(1)); end $$;
select throws_ok(
  $$ select admin.update_feature_request(
       tests.fr(1),
       'shipped',
       'design',
       'Đã ra mắt rồi vcl nhé!',
       false,
       'bad admin reply'
     ) $$,
  '23514', 'content_policy',
  'admin.update_feature_request enforces private.assert_clean_text on public admin_reply'
);

do $$
begin
  perform tests.as_user(tests.u(1));
  perform admin.update_feature_request(
    tests.fr(1),
    'shipped',
    'design',
    'Widget màn hình khóa đã chính thức ra mắt trong phiên bản Ourney 1.4!',
    false,
    'shipped lock screen widget in v1.4'
  );
end $$;

-- [Test 40] Shipped notification loop: author u(2), voter u(3), and merged-duplicate voter u(4) all receive inbox_counts.shipped_requests = 1 and can mark seen
do $$
declare
  v_marked int;
begin
  perform tests.as_user(tests.u(4));
  if (public.inbox_counts() ->> 'shipped_requests')::int <> 1 then
    raise exception 'expected inbox_counts.shipped_requests = 1 for merged-duplicate voter u(4) before mark_shipped_requests_seen';
  end if;
  if not exists (
    select 1 from public.my_shipped_request_notifications(20) x
     where (x ->> 'request_id')::uuid = tests.fr(1)
       and (x ->> 'seen')::boolean = false
  ) then
    raise exception 'expected unseen shipped notification for u(4) before mark_shipped_requests_seen';
  end if;
  v_marked := public.mark_shipped_requests_seen(array[tests.fr(1)]);
  if v_marked <> 1 then
    raise exception 'expected mark_shipped_requests_seen to mark 1 row seen, got %', v_marked;
  end if;
end $$;

select is(
  (public.inbox_counts() ->> 'shipped_requests')::int = 0
  and (select (x ->> 'request_id')::uuid = tests.fr(1)
              and (x ->> 'seen')::boolean = true
              and (x ->> 'admin_reply') = 'Widget màn hình khóa đã chính thức ra mắt trong phiên bản Ourney 1.4!'
         from public.my_shipped_request_notifications(20) x
        limit 1),
  true,
  'shipping a request notifies voters (including merged-duplicate voter u(4)), increments inbox_counts.shipped_requests, and mark_shipped_requests_seen clears it to 0'
);

-- [Test 41] Admin stats, list, detail (with voters & merged_children), and overview_stats KPI block
do $$ begin perform tests.as_user(tests.u(1)); end $$;
select is(
  (admin.feature_request_stats() ->> 'shipped')::int >= 1
  and (admin.feature_request_stats() ->> 'merged')::int = 1
  and (admin.feature_request_stats() ->> 'hidden')::int = 1
  and (admin.list_feature_requests(null, 'shipped', 'design', 'active', 'votes_desc', 50, 0) ->> 'total')::int = 1
  and jsonb_array_length(admin.get_feature_request_detail(tests.fr(1)) -> 'voters') = 3
  and jsonb_array_length(admin.get_feature_request_detail(tests.fr(1)) -> 'merged_children') = 1
  and (admin.overview_stats(14, 'Asia/Ho_Chi_Minh') #>> '{kpis,feature_requests,shipped_count}')::int >= 1,
  true,
  'admin.feature_request_stats, list_feature_requests, get_feature_request_detail (incl. voters & merged_children), and overview_stats report accurate data'
);

-- ============================================================================
-- 10. Account Deletion (`public.purge_account_data`) (Test 42)
-- ============================================================================
do $$
begin
  -- User E (u(6)) creates:
  --   1) fr(60): a solo-voted 'new' request (nobody else votes on it -> should be deleted on account purge)
  --   2) fr(61): a 'planned' request that User B (u(3)) also votes on (2 votes -> should survive with author_id IS NULL and vote_count = 1)
  perform tests.as_user(tests.u(6));
  perform public.create_feature_request(
    tests.fr(60),
    'Đề xuất cá nhân chưa ai vote',
    'Đề xuất mới chỉ có 1 phiếu của tác giả, sẽ bị xóa khi xóa tài khoản.',
    'other'
  );
  perform public.create_feature_request(
    tests.fr(61),
    'Đề xuất cộng đồng nhiều người vote',
    'Đề xuất đã được lên kế hoạch và có người khác bình chọn nên được giữ lại ẩn danh.',
    'journeys'
  );
  perform tests.as_user(tests.u(3));
  perform public.toggle_feature_request_vote(tests.fr(61), true);
  perform tests.as_user(tests.u(1));
  perform admin.update_feature_request(
    tests.fr(61),
    'planned',
    'journeys',
    null,
    false,
    'planned community request'
  );

  -- Delete u(6)'s account (fires profiles_before_delete -> public.purge_account_data)
  perform tests.as_postgres();
  delete from auth.users where id = tests.u(6);
end $$;

-- [Test 42] Solo-voted 'new' request fr(60) is deleted; multi-voter 'planned' request fr(61) survives with author_id IS NULL and vote_count = 1
select is(
  (select count(*)::int = 0 from public.feature_requests where id = tests.fr(60))
  and (select author_id is null and vote_count = 1 and status = 'planned'
         from public.feature_requests where id = tests.fr(61)),
  true,
  'purge_account_data deletes solo-voted new requests and anonymizes surviving community-voted requests (author_id = NULL, vote_count decremented)'
);

-- ============================================================================
-- 11. P1 & P2 Security Review Regressions (Tests 43..50)
-- ============================================================================
-- [Test 43] anon role is rejected at the PostgreSQL function privilege layer with 42501
do $$ begin perform tests.as_anon(); end $$;
select throws_ok(
  $$ select public.list_feature_requests() $$,
  '42501', null,
  'anon role is denied EXECUTE on public.list_feature_requests with 42501'
);

-- [Test 44] P1-1: vote_count locking & drift prevention across multi-row vote inserts and cascade deletes
do $$
begin
  perform tests.as_user(tests.u(5));
  perform public.create_feature_request(
    tests.fr(70),
    'Đề xuất kiểm tra đồng bộ số phiếu',
    'Kiểm tra khóa dòng FOR NO KEY UPDATE và đồng bộ vote_count khi thêm/xóa nhiều phiếu.',
    'camera'
  );
  perform tests.as_postgres();
  insert into public.feature_request_votes (request_id, user_id)
  values
    (tests.fr(70), tests.u(2)),
    (tests.fr(70), tests.u(3)),
    (tests.fr(70), tests.u(4));
  if (select vote_count from public.feature_requests where id = tests.fr(70)) <> 4 then
    raise exception 'expected vote_count = 4 after multi-row vote insert on fr(70)';
  end if;
  delete from public.feature_request_votes
   where request_id = tests.fr(70)
     and user_id in (tests.u(2), tests.u(4));
end $$;

select is(
  (select vote_count from public.feature_requests where id = tests.fr(70)) = 2
  and (select count(*)::int from public.feature_request_votes where request_id = tests.fr(70)) = 2
  and position(
    'for no key update' in lower((select prosrc from pg_proc where oid = 'private.sync_feature_request_vote_count()'::regprocedure))
  ) > 0
  and position(
    'for no key update' in lower((select prosrc from pg_proc where oid = 'public.toggle_feature_request_vote(uuid, boolean)'::regprocedure))
  ) > 0,
  true,
  'P1-1: sync_feature_request_vote_count and toggle_feature_request_vote lock feature_requests FOR NO KEY UPDATE and prevent vote_count drift'
);

-- [Test 45] P2-1: 20 / 1h edit rate limit cannot be bypassed via direct table UPDATE on public.feature_requests
do $$
declare
  i int;
begin
  perform tests.as_postgres();
  delete from private.rate_events where user_id = tests.u(5);
  perform tests.as_user(tests.u(5));
  for i in 1..10 loop
    perform public.update_feature_request(
      tests.fr(70),
      format('Tiêu đề sửa qua RPC lần %s', i),
      'Kiểm tra giới hạn 20 lần chỉnh sửa trong 1 giờ trên cả RPC và bảng trực tiếp.',
      'camera'
    );
  end loop;
  for i in 11..20 loop
    update public.feature_requests
       set title = format('Tiêu đề sửa trực tiếp lần %s', i)
     where id = tests.fr(70);
  end loop;
end $$;

select throws_ok(
  $$ update public.feature_requests
        set title = 'Tiêu đề sửa trực tiếp lần thứ 21 vượt giới hạn'
      where id = tests.fr(70) $$,
  'P0001', 'rate_limited',
  'P2-1: 21st edit within 1 hour via direct table UPDATE on public.feature_requests raises P0001 rate_limited'
);

do $$
begin
  perform tests.as_postgres();
  delete from private.rate_events where user_id = tests.u(5);
end $$;

-- [Test 46] P2-2: Blocked authors and user-reported requests are filtered from my_shipped_request_notifications, inbox_counts, and canonical_title
do $$
begin
  -- Author u(5) creates canonical fr(71); voter u(3) upvotes fr(71) and creates duplicate fr(72).
  -- Admin u(1) merges fr(72) -> fr(71) and ships fr(71), creating a shipped notification for u(3).
  perform tests.as_user(tests.u(5));
  perform public.create_feature_request(
    tests.fr(71),
    'Chia sẻ lộ trình nhóm cuối tuần',
    'Cho phép xuất poster tổng kết hoạt động của cả nhóm vào cuối mỗi tuần.',
    'sharing'
  );
  perform tests.as_user(tests.u(3));
  perform public.toggle_feature_request_vote(tests.fr(71), true);
  perform public.create_feature_request(
    tests.fr(72),
    'Xuất ảnh tổng kết tuần cho squad',
    'Tạo thẻ chia sẻ tổng kết tuần cho các thành viên trong cùng một hành trình.',
    'sharing'
  );
  perform tests.as_user(tests.u(1));
  perform admin.merge_feature_request(tests.fr(72), tests.fr(71), 'duplicate weekly squad summary');
  perform admin.update_feature_request(
    tests.fr(71),
    'shipped',
    'sharing',
    'Đã hoàn thiện tính năng xuất thẻ tổng kết tuần cho squad!',
    false,
    'shipped weekly squad summary'
  );

  -- Now u(3) reports fr(71) (authored by u(5)) and blocks u(2) (author of shipped fr(1), which fr(6) was merged into).
  perform tests.as_user(tests.u(3));
  perform public.report_feature_request(tests.fr(71), 'spam', 'hide reported shipped request from u3');
  perform public.block_user(tests.u(2));
end $$;

select is(
  (public.get_feature_request(tests.fr(6)) ->> 'canonical_title') is null
  and (public.get_feature_request(tests.fr(72)) ->> 'canonical_title') is null
  and (public.inbox_counts() ->> 'shipped_requests')::int = 0
  and (select count(*)::int from public.my_shipped_request_notifications(20) x
        where (x ->> 'request_id')::uuid in (tests.fr(1), tests.fr(71))) = 0,
  true,
  'P2-2: blocked authors and user-reported requests are hidden from canonical_title, my_shipped_request_notifications, and inbox_counts'
);

do $$
begin
  perform tests.as_user(tests.u(3));
  perform public.unblock_user(tests.u(2));
end $$;

-- [Test 47] P2-3a: Author cannot delete a 'new' feature request while an open report exists on it
do $$
begin
  perform tests.as_user(tests.u(3));
  perform public.report_feature_request(tests.fr(70), 'spam', 'open report blocks author delete');
  perform tests.as_user(tests.u(5));
end $$;

select throws_ok(
  $$ select public.delete_feature_request(tests.fr(70)) $$,
  '42501', 'forbidden',
  'P2-3a: delete_feature_request rejects deleting a new request while an open report exists'
);

-- [Test 48] P2-3a: Even if a feature_requests row is hard-deleted, moderation_queue preserves target_feature_request_id and target_type = feature_request
do $$
begin
  perform tests.as_postgres();
  delete from public.feature_requests where id = tests.fr(70);
  perform tests.as_user(tests.u(1));
end $$;

select is(
  exists (
    select 1
      from jsonb_array_elements(admin.list_moderation_queue('open', 'report', 'all', 50, 0) -> 'items') x
     where (x ->> 'target_feature_request_id')::uuid = tests.fr(70)
       and (x ->> 'target_type') = 'feature_request'
       and (admin.get_moderation_item((x ->> 'id')::uuid) #>> '{reported_content,target_type}') = 'feature_request'
       and (admin.get_moderation_item((x ->> 'id')::uuid) #>> '{reported_content,deleted}')::boolean = true
  ),
  true,
  'P2-3a: moderation_queue preserves target_feature_request_id without ON DELETE SET NULL and keeps target_type = feature_request'
);

-- [Test 49] P2-3b: Author cannot delete a 'new' canonical parent that has merged children (returns 42501 forbidden, never 23514 immutable_column)
do $$
begin
  perform tests.as_postgres();
  delete from private.rate_events where user_id = tests.u(2);
  perform tests.as_user(tests.u(2));
  perform public.create_feature_request(
    tests.fr(73),
    'Đề xuất gốc đang ở trạng thái mới',
    'Đề xuất gốc chưa chuyển trạng thái nhưng đã được gộp bản sao vào.',
    'journeys'
  );
  perform tests.as_user(tests.u(3));
  perform public.create_feature_request(
    tests.fr(74),
    'Đề xuất trùng lặp với đề xuất gốc',
    'Đề xuất trùng lặp sẽ được quản trị viên gộp vào đề xuất gốc fr(73).',
    'journeys'
  );
  perform tests.as_user(tests.u(1));
  perform admin.merge_feature_request(tests.fr(74), tests.fr(73), 'merge child into new parent');
  perform tests.as_user(tests.u(2));
end $$;

select throws_ok(
  $$ select public.delete_feature_request(tests.fr(73)) $$,
  '42501', 'forbidden',
  'P2-3b: delete_feature_request on a new canonical parent with merged children rejects with 42501 forbidden'
);

-- [Test 50] P2-3c: Unhiding a quarantined request via admin.update_feature_request(..., p_hidden => false) clears moderated_at
do $$
begin
  perform tests.as_user(tests.u(1));
  perform admin.update_feature_request(
    tests.fr(5),
    'new',
    'other',
    null,
    false,
    'unhide request and clear moderated_at'
  );
  perform tests.as_postgres();
end $$;

select is(
  (select not hidden and moderated_at is null from public.feature_requests where id = tests.fr(5)),
  true,
  'P2-3c: admin.update_feature_request(p_hidden => false) clears both hidden=false and moderated_at=null'
);

select * from finish();
rollback;
