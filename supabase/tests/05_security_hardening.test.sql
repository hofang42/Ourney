-- Security Auditor findings (0005_security_hardening): every confirmed exploit is a test here.
-- Users: A owner, B member (hide_metric), D member, C outsider.
begin;
create extension if not exists pgtap with schema extensions;
select plan(58);

create schema tests;
grant usage on schema tests to authenticated;
create function tests.as_user(u uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', u, 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);
end $$;
create function tests.as_postgres() returns void language plpgsql as $$
begin
  perform set_config('role', 'postgres', true);
  perform set_config('request.jwt.claims', '', true);
end $$;
create function tests.u(n int) returns uuid language sql immutable as $$
  select format('50000000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function tests.c(n int) returns uuid language sql immutable as $$
  select format('c5000000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function tests.j() returns uuid language sql immutable as $$
  select 'b5000000-0000-4000-8000-000000000001'::uuid $$;
create function tests.code() returns text language sql security definer as $$
  select invite_code from public.journeys where id = tests.j() $$;
-- check-in for the caller with caption + metric (the pre-0005 client upsert body)
create function tests.checkin(cid uuid, at timestamptz, cap text default null, metric numeric default null)
returns void language sql as $$
  insert into public.check_ins (id, journey_id, user_id, local_date, captured_at, photo_path, thumb_path, caption, metric_value)
  values (cid, tests.j(), auth.uid(), current_date, at,
          format('checkins/%s/%s/%s.jpg', tests.j(), auth.uid(), cid),
          format('checkins/%s/%s/%s_t.jpg', tests.j(), auth.uid(), cid), cap, metric) $$;
create function tests.photo(uid uuid, cid uuid) returns text language sql immutable as $$
  select format('checkins/%s/%s/%s.jpg', tests.j(), uid, cid) $$;
grant execute on all functions in schema tests to authenticated;

insert into auth.users (id, email) select tests.u(n), format('s%s@example.test', n) from generate_series(1, 4) n;
insert into public.profiles (id, username, display_name) select tests.u(n), 'suser' || n, 'S' || n from generate_series(1, 4) n;
-- A=1 owner, B=2 member, C=3 outsider, D=4 member

do $$ begin perform tests.as_user(tests.u(1));
  perform public.create_journey(tests.j(), 'group', 'weight_loss', 'G', '⚖️', 'Weight', 'kg', true,
                                current_date - 30, null, 'UTC'); end $$;
do $$ begin perform tests.as_postgres(); end $$;
select tests.code() as old_code \gset
do $$ begin perform tests.as_user(tests.u(2)); perform public.join_by_code(tests.code()); end $$;
do $$ begin perform tests.as_user(tests.u(4)); perform public.join_by_code(tests.code()); end $$;

-- ===== H1: hidden metric is not readable by other members ===================
do $$ begin perform tests.as_user(tests.u(2)); end $$;
select is((select hide_metric from public.memberships where user_id = auth.uid()), true,
  'B hides the metric (copied from hide_metric_default)');
select lives_ok($$ select tests.checkin(tests.c(1), now(), 'secret caption', 92.5) $$,
  'pre-0005 upsert body with metric_value is still accepted');
select lives_ok($$ insert into public.check_in_metrics (checkin_id, journey_id, user_id, metric_value)
                   values (tests.c(1), tests.j(), auth.uid(), 92.5)
                   on conflict (checkin_id) do update set metric_value = excluded.metric_value $$,
  'author writes the metric into check_in_metrics');
select is((select metric_value from public.check_in_metrics where checkin_id = tests.c(1)), 92.5::numeric,
  'author reads own metric');
do $$ begin perform tests.as_user(tests.u(4)); perform tests.checkin(tests.c(4), now(), 'd caption'); end $$;
do $$ begin perform tests.as_postgres(); end $$;
select is((select metric_value from public.check_ins where id = tests.c(1)), null,
  'check_ins.metric_value is never stored (metric lives in check_in_metrics)');

do $$ begin perform tests.as_user(tests.u(1)); end $$;
select is((select count(*)::int from public.check_ins where user_id = tests.u(2) and metric_value is not null), 0,
  'E1: other member cannot select metric_value of a hide_metric member');
select is((select count(*)::int from public.check_in_metrics where user_id = tests.u(2)), 0,
  'other member cannot read a hidden metric from check_in_metrics');
select throws_ok($$ insert into public.check_in_metrics (checkin_id, journey_id, user_id, metric_value)
                    values (tests.c(1), tests.j(), tests.u(2), 1) $$, '42501', null,
  'member cannot write another member''s metric');
do $$ begin update public.check_in_metrics set metric_value = 1 where checkin_id = tests.c(1); end $$;
do $$ begin perform tests.as_postgres(); end $$;
select is((select metric_value from public.check_in_metrics where checkin_id = tests.c(1)), 92.5::numeric,
  'member cannot update another member''s metric');
do $$ begin perform tests.as_user(tests.u(2));
  update public.memberships set hide_metric = false where journey_id = tests.j() and user_id = auth.uid(); end $$;
do $$ begin perform tests.as_user(tests.u(1)); end $$;
select is((select metric_value from public.check_in_metrics where checkin_id = tests.c(1)), 92.5::numeric,
  'metric becomes visible when the author stops hiding it');
do $$ begin perform tests.as_user(tests.u(2));
  update public.memberships set hide_metric = true where journey_id = tests.j() and user_id = auth.uid(); end $$;
do $$ begin perform tests.as_user(tests.u(1)); end $$;
select is((select count(*)::int from public.check_in_metrics where checkin_id = tests.c(1)), 0,
  'metric hidden again when the author re-enables hide_metric');
do $$ begin perform tests.as_user(tests.u(3)); end $$;
select is((select count(*)::int from public.check_in_metrics), 0, 'outsider sees no metric');

-- ===== L1: helpers are not API-callable =====================================
do $$ begin perform tests.as_postgres(); end $$;
select is((select count(*)::int from pg_proc
            where pronamespace = 'public'::regnamespace
              and proname in ('is_member', 'is_owner', 'is_blocked_pair', 'can_see_checkin',
                              'has_reported', 'can_read_checkin_media')), 0,
  'E2: authorization helpers are gone from the API-exposed public schema');
select ok(has_function_privilege('authenticated', 'private.is_member(uuid)', 'execute')
          and has_function_privilege('authenticated', 'private.is_blocked_pair(uuid)', 'execute'),
  'helpers live in private and stay usable by policies');
select ok(not has_function_privilege('anon', 'private.is_blocked_pair(uuid)', 'execute'),
  'anon cannot execute private helpers');
select is((select count(*)::int from pg_policy p
            where pg_get_expr(p.polqual, p.polrelid) ~ 'public\.(is_member|is_owner|is_blocked_pair|can_see_checkin|has_reported|can_read_checkin_media)\('
               or pg_get_expr(p.polwithcheck, p.polrelid) ~ 'public\.(is_member|is_owner|is_blocked_pair|can_see_checkin|has_reported|can_read_checkin_media)\('),
  0, 'no policy references a public helper');

-- ===== M3: media requires a live, visible check-in row ======================
insert into storage.objects (bucket_id, name) values
  ('media', tests.photo(tests.u(2), tests.c(1))),
  ('media', format('checkins/%s/%s/%s_t.jpg', tests.j(), tests.u(2), tests.c(1))),
  ('media', tests.photo(tests.u(2), tests.c(99))),                     -- orphan: no row
  ('media', tests.photo(tests.u(4), tests.c(4))),
  ('media', format('avatars/%s/%s.jpg', tests.u(1), 'aaaaaaaa-0000-4000-8000-000000000001'));
do $$ begin perform tests.as_user(tests.u(1)); end $$;
select is((select count(*)::int from storage.objects where name like 'checkins/%/' || tests.u(2) || '/%'), 2,
  'member reads photo + thumb of a live check-in');
select is((select count(*)::int from storage.objects where name = tests.photo(tests.u(2), tests.c(99))), 0,
  'object without a live check-in row is not readable by others');
do $$ begin perform tests.as_user(tests.u(2)); end $$;
select is((select count(*)::int from storage.objects where name = tests.photo(tests.u(2), tests.c(99))), 1,
  'author still reads own objects (upload/upsert before the row exists)');

-- ===== L7: reports hide media, reactions and the today board entry ===========
do $$ begin perform tests.as_user(tests.u(1));
  insert into public.reactions (checkin_id, user_id, emoji) values (tests.c(1), auth.uid(), '🔥'); end $$;
do $$ begin perform tests.as_user(tests.u(4)); perform public.report_content(tests.c(1), null, 'spam'); end $$;
select is((select count(*)::int from storage.objects where name like 'checkins/%/' || tests.u(2) || '/%'), 0,
  'reporter can no longer read the reported media');
select is((select count(*)::int from public.reactions where checkin_id = tests.c(1)), 0,
  'reporter does not see reactions on the reported check-in');
select is((select checkin_id from public.group_today(tests.j()) where user_id = tests.u(2)), null,
  'group_today hides the reported check-in from the reporter');
select is((select checked_in from public.group_today(tests.j()) where user_id = tests.u(2)), true,
  'group_today still tells the reporter the member checked in');
do $$ begin perform tests.as_user(tests.u(1)); end $$;
select isnt((select checkin_id from public.group_today(tests.j()) where user_id = tests.u(2)), null,
  'group_today unaffected for non-reporters');

-- ===== M2: moderator removal cannot be undone by the author =================
do $$ begin perform tests.as_postgres(); end $$;
select ok(not has_function_privilege('authenticated', 'public.moderate_checkin(uuid)', 'execute'),
  'moderate_checkin is service_role only');
select lives_ok($$ select public.moderate_checkin(tests.c(1)) $$, 'moderator removes the check-in');
do $$ begin perform tests.as_user(tests.u(2)); end $$;
select throws_ok($$ update public.check_ins set deleted_at = null where id = tests.c(1) $$, '42501', 'forbidden',
  'E4: author cannot undelete a moderated check-in');
select throws_ok($$ update public.check_ins set moderated_at = null where id = tests.c(1) $$, '42501', null,
  'author cannot clear moderated_at');
select throws_ok($$ insert into public.check_ins (id, journey_id, user_id, local_date, captured_at, photo_path, thumb_path, moderated_at)
                    values (tests.c(5), tests.j(), auth.uid(), current_date, now() - interval '1 day',
                            tests.photo(auth.uid(), tests.c(5)), format('checkins/%s/%s/%s_t.jpg', tests.j(), auth.uid(), tests.c(5)), now())
                    returning moderated_at $$, '42501', null,
  'clients cannot set moderated_at');
do $$ begin perform tests.as_postgres(); end $$;
select ok((select deleted_at is not null and moderated_at is not null from public.check_ins where id = tests.c(1)),
  'moderated check-in stays removed');

-- ===== M1: tombstones expose no content to others ===========================
do $$ begin perform tests.as_user(tests.u(1)); end $$;
select is((select count(*)::int from public.check_ins where id = tests.c(1)), 0,
  'E3a: other members cannot read a deleted check-in row (caption/metric)');
select is((select count(*)::int from storage.objects where name like 'checkins/%/' || tests.u(2) || '/%'), 0,
  'E5: media of a deleted check-in is not readable');
select results_eq($$ select id, journey_id from public.checkin_tombstones(null) $$,
  $$ values (tests.c(1), tests.j()) $$, 'checkin_tombstones lists the deletion for members');
select is((select array_to_string(proargnames, ',') from pg_proc where proname = 'checkin_tombstones'),
  'since,lim,id,journey_id,updated_at', 'checkin_tombstones returns only id/journey_id/updated_at');
do $$ begin perform tests.as_user(tests.u(2)); end $$;
select is((select count(*)::int from public.check_ins where id = tests.c(1)), 1, 'author still sees own deleted row');
do $$ begin perform tests.as_user(tests.u(3)); end $$;
select is((select count(*)::int from public.checkin_tombstones(null)), 0, 'outsider gets no tombstones');

-- ===== L2: backdated inserts are rejected ===================================
do $$ begin perform tests.as_user(tests.u(2)); end $$;
select throws_ok($$ select tests.checkin(tests.c(6), now() - interval '5 days') $$, '22008', 'invalid_captured_at',
  'BACKDATE: check-in older than the 3-day offline window is rejected');
select lives_ok($$ select tests.checkin(tests.c(7), now() - interval '2 days') $$,
  'offline check-in within the window is accepted');

-- ===== L3: retake of a reported check-in (id change) =========================
do $$ begin perform tests.as_user(tests.u(1)); perform public.report_content(tests.c(4), null, 'other'); end $$;
do $$ begin perform tests.as_user(tests.u(4)); end $$;
select lives_ok($$
  insert into public.check_ins (id, journey_id, user_id, local_date, captured_at, photo_path, thumb_path)
  values (tests.c(8), tests.j(), auth.uid(), current_date, now(), tests.photo(auth.uid(), tests.c(8)),
          format('checkins/%s/%s/%s_t.jpg', tests.j(), auth.uid(), tests.c(8)))
  on conflict (journey_id, user_id, local_date) do update
    set id = excluded.id, photo_path = excluded.photo_path, thumb_path = excluded.thumb_path $$,
  'E6: retake of a reported check-in succeeds');
do $$ begin perform tests.as_postgres(); end $$;
select is((select target_checkin_id from public.reports where reporter_id = tests.u(1)), tests.c(8),
  'report follows the retaken check-in id');
select is((select confdeltype from pg_constraint where conname = 'moderation_queue_report_id_fkey'), 'n'::"char",
  'moderation_queue.report_id is on delete set null');

-- ===== L4: block/unblock does not flood the moderation queue ================
do $$ begin perform tests.as_user(tests.u(3)); end $$;
select lives_ok($$ select public.block_user(tests.u(1)), public.unblock_user(tests.u(1)) from generate_series(1, 5) $$,
  'block/unblock cycles');
do $$ begin perform tests.as_postgres(); end $$;
select is((select count(*)::int from public.moderation_queue where actor_id = tests.u(3)), 1,
  'E8: only the first-ever block of a pair is queued');

-- ===== L5: profiles and avatars only for self + co-members ==================
do $$ begin perform tests.as_user(tests.u(3)); end $$;
select is((select count(*)::int from public.profiles), 1, 'E7: outsider sees only own profile');
select is((select count(*)::int from storage.objects where name like 'avatars/%'), 0, 'outsider cannot read avatars');
do $$ begin perform tests.as_user(tests.u(2)); end $$;
select is((select count(*)::int from public.profiles), 3, 'member sees co-members'' profiles');
select is((select count(*)::int from storage.objects where name like 'avatars/%'), 1, 'member reads co-member avatar');
do $$ begin perform tests.as_user(tests.u(4)); perform public.block_user(tests.u(1)); end $$;
select is((select count(*)::int from public.profiles where id = tests.u(1)), 0, 'blocked pair cannot read each other''s profile');

-- ===== L7: profiles.deleted_at is server-only ===============================
select throws_ok($$ update public.profiles set deleted_at = now() where id = auth.uid() $$, '42501', null,
  'clients cannot set profiles.deleted_at');

-- ===== H2: removed member cannot rejoin; code rotates ========================
do $$ begin perform tests.as_user(tests.u(1)); end $$;
select lives_ok($$ select public.remove_member(tests.j(), tests.u(2)) $$, 'owner removes B');
select isnt(tests.code(), :'old_code', 'remove_member rotates the invite code');
select is((select count(*)::int from public.check_ins where user_id = tests.u(2)), 0,
  'removed member''s hidden check-ins are not readable');
select ok((select count(*) from public.checkin_tombstones(null) where id = tests.c(7)) = 1,
  'hidden_by_leave rows reach other members as tombstones');
do $$ begin perform tests.as_user(tests.u(2)); end $$;
select is((select id from public.join_by_code(:'old_code')), null,
  'E3b: the old code no longer works after remove_member (not_found)');
select throws_ok($$ select public.join_by_code(tests.code()) $$, '42501', 'forbidden',
  'removed member cannot rejoin with the new code either');

-- ===== M4: invite brute force is throttled ==================================
do $$ begin perform tests.as_user(tests.u(3)); end $$;
select is((select count(*)::int from generate_series(1, 10) g, public.join_by_code('ZZZZZZZ' || (g % 10)) j where j.id is null), 10,
  'unknown codes return an empty row (not_found) and are counted');
select throws_ok($$ select public.join_by_code('ZZZZZZZZ') $$, 'P0001', 'rate_limited', '11th attempt -> rate_limited');
select throws_ok($$ select public.join_by_code(tests.code()) $$, 'P0001', 'rate_limited',
  'a correct code is throttled too once the limit is hit');

select * from finish();
rollback;
