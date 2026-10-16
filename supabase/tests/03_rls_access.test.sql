-- RLS behaviour: member vs non-member vs blocked, storage path policies, reports, anon.
-- Users: u1 owner, u2 member, u4 member (later blocked by u2), u3 outsider.
begin;
create extension if not exists pgtap with schema extensions;
select plan(42);

-- ---- helpers (rolled back with the transaction) ---------------------------
create schema tests;
grant usage on schema tests to anon, authenticated;
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
create function tests.as_postgres() returns void language plpgsql as $$
begin
  perform set_config('role', 'postgres', true);
  perform set_config('request.jwt.claims', '', true);
end $$;
-- insert a check-in for the current caller with contract-shaped paths
create function tests.checkin(cid uuid, j uuid, at timestamptz) returns void language sql as $$
  insert into public.check_ins (id, journey_id, user_id, local_date, captured_at, photo_path, thumb_path)
  values (cid, j, auth.uid(), '2000-01-01', at,
          format('checkins/%s/%s/%s.jpg', j, auth.uid(), cid),
          format('checkins/%s/%s/%s_t.jpg', j, auth.uid(), cid));
$$;
grant execute on all functions in schema tests to anon, authenticated;

insert into auth.users (id, email) values
  ('10000000-0000-4000-8000-000000000001', 'u1@example.test'),
  ('10000000-0000-4000-8000-000000000002', 'u2@example.test'),
  ('10000000-0000-4000-8000-000000000003', 'u3@example.test'),
  ('10000000-0000-4000-8000-000000000004', 'u4@example.test');
insert into public.profiles (id, username, display_name) values
  ('10000000-0000-4000-8000-000000000001', 'user1', 'User 1'),
  ('10000000-0000-4000-8000-000000000002', 'user2', 'User 2'),
  ('10000000-0000-4000-8000-000000000003', 'user3', 'User 3'),
  ('10000000-0000-4000-8000-000000000004', 'user4', 'User 4');

-- u1 creates the group through the RPC
do $$ begin perform tests.as_user('10000000-0000-4000-8000-000000000001'); end $$;
select isnt(
  (select invite_code from public.create_journey(
     'a0000000-0000-4000-8000-000000000001', 'group', 'english_daily', 'English', '📚',
     null, null, false, current_date - 2, 30, 'Asia/Ho_Chi_Minh')),
  null, 'create_journey(group) issues an invite code');
do $$ begin perform tests.as_postgres(); end $$;
select invite_code as code from public.journeys where id = 'a0000000-0000-4000-8000-000000000001' \gset

do $$ begin perform tests.as_user('10000000-0000-4000-8000-000000000002'); end $$;
select is((select id from public.join_by_code(lower(:'code'))), 'a0000000-0000-4000-8000-000000000001'::uuid,
  'join_by_code is case-insensitive');
do $$ begin perform tests.as_user('10000000-0000-4000-8000-000000000004'); end $$;
select lives_ok(format('select public.join_by_code(%L)', :'code'), 'u4 joins');

-- each member posts a check-in now
do $$ begin perform tests.as_user('10000000-0000-4000-8000-000000000001'); end $$;
select lives_ok($$ select tests.checkin('c1000000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000001', now()) $$,
  'owner can insert own check-in');
do $$ begin perform tests.as_user('10000000-0000-4000-8000-000000000002'); end $$;
select lives_ok($$ select tests.checkin('c2000000-0000-4000-8000-000000000002', 'a0000000-0000-4000-8000-000000000001', now()) $$,
  'member can insert own check-in');
do $$ begin perform tests.as_user('10000000-0000-4000-8000-000000000004'); end $$;
select lives_ok($$ select tests.checkin('c4000000-0000-4000-8000-000000000004', 'a0000000-0000-4000-8000-000000000001', now()) $$,
  'u4 can insert own check-in');

-- storage objects (as postgres; policies tested by selecting as each user)
do $$ begin perform tests.as_postgres(); end $$;
insert into storage.objects (bucket_id, name)
select 'media', format('checkins/%s/%s/%s.jpg', 'a0000000-0000-4000-8000-000000000001', u, c)
  from (values ('10000000-0000-4000-8000-000000000001', 'c1000000-0000-4000-8000-000000000001'),
               ('10000000-0000-4000-8000-000000000002', 'c2000000-0000-4000-8000-000000000002'),
               ('10000000-0000-4000-8000-000000000004', 'c4000000-0000-4000-8000-000000000004')) v(u, c);

-- ---- member ---------------------------------------------------------------
do $$ begin perform tests.as_user('10000000-0000-4000-8000-000000000002'); end $$;
select is((select count(*)::int from public.journeys), 1, 'member sees the journey');
select is((select count(*)::int from public.memberships), 3, 'member sees all memberships of the group');
select is((select count(*)::int from public.check_ins), 3, 'member sees every member''s check-in');
select is((select count(*)::int from storage.objects where bucket_id = 'media'), 3, 'member can read all check-in media');
select throws_ok(
  $$ select tests.checkin('c2000000-0000-4000-8000-0000000000ff', 'a0000000-0000-4000-8000-000000000001', now()) $$,
  '23505', null, 'one check-in per local day (unique journey,user,local_date)');
-- retake = upsert on (journey,user,local_date) with a new client id
select lives_ok($$
  insert into public.check_ins (id, journey_id, user_id, local_date, captured_at, photo_path, thumb_path, caption)
  values ('c2000000-0000-4000-8000-0000000000aa', 'a0000000-0000-4000-8000-000000000001', auth.uid(), '2000-01-01', now(),
          format('checkins/%s/%s/%s.jpg', 'a0000000-0000-4000-8000-000000000001', auth.uid(), 'c2000000-0000-4000-8000-0000000000aa'),
          format('checkins/%s/%s/%s_t.jpg', 'a0000000-0000-4000-8000-000000000001', auth.uid(), 'c2000000-0000-4000-8000-0000000000aa'),
          'retake')
  on conflict (journey_id, user_id, local_date) do update
    set id = excluded.id, captured_at = excluded.captured_at, photo_path = excluded.photo_path,
        thumb_path = excluded.thumb_path, caption = excluded.caption
$$, 'retake upserts today''s check-in');
select is((select caption from public.check_ins where user_id = auth.uid()), 'retake', 'retake replaced the row');
-- put the original id back so later assertions stay simple
update public.check_ins set id = 'c2000000-0000-4000-8000-000000000002',
  photo_path = format('checkins/%s/%s/%s.jpg', journey_id, user_id, 'c2000000-0000-4000-8000-000000000002'),
  thumb_path = format('checkins/%s/%s/%s_t.jpg', journey_id, user_id, 'c2000000-0000-4000-8000-000000000002')
 where user_id = auth.uid();

update public.check_ins set caption = 'hacked' where id = 'c1000000-0000-4000-8000-000000000001';
update public.journeys set title = 'hacked' where id = 'a0000000-0000-4000-8000-000000000001';
update public.profiles set display_name = 'hacked' where id = '10000000-0000-4000-8000-000000000001';
select throws_ok($$ update public.memberships set role = 'owner' where user_id = auth.uid() $$,
  '42501', null, 'member cannot change own role (column privilege)');
select throws_ok(
  $$ insert into storage.objects (bucket_id, name) values ('media',
       'checkins/a0000000-0000-4000-8000-000000000001/10000000-0000-4000-8000-000000000001/c9000000-0000-4000-8000-000000000009.jpg') $$,
  '42501', null, 'member cannot upload into another user''s folder');
select lives_ok(
  $$ insert into storage.objects (bucket_id, name) values ('media',
       'checkins/a0000000-0000-4000-8000-000000000001/10000000-0000-4000-8000-000000000002/c9000000-0000-4000-8000-000000000009.jpg') $$,
  'member can upload into own folder of a journey they belong to');
select throws_ok(
  $$ insert into storage.objects (bucket_id, name) values ('media',
       'checkins/a0000000-0000-4000-8000-000000000001/10000000-0000-4000-8000-000000000002/not-a-uuid.png') $$,
  '42501', null, 'upload file names are strict');
select lives_ok(
  $$ insert into public.reactions (checkin_id, user_id, emoji) values ('c1000000-0000-4000-8000-000000000001', auth.uid(), '🔥') $$,
  'member can react');
select throws_ok(
  $$ insert into public.reactions (checkin_id, user_id, emoji) values ('c4000000-0000-4000-8000-000000000004', auth.uid(), '🤡') $$,
  '23514', null, 'only the 5 contract emojis are allowed');

do $$ begin perform tests.as_postgres(); end $$;
select is((select caption from public.check_ins where id = 'c1000000-0000-4000-8000-000000000001'), null,
  'member cannot edit someone else''s check-in');
select is((select title from public.journeys where id = 'a0000000-0000-4000-8000-000000000001'), 'English',
  'non-owner cannot edit the journey');
select is((select display_name from public.profiles where id = '10000000-0000-4000-8000-000000000001'), 'User 1',
  'cannot edit another profile');

-- ---- outsider -------------------------------------------------------------
do $$ begin perform tests.as_user('10000000-0000-4000-8000-000000000003'); end $$;
select is((select count(*)::int from public.journeys), 0, 'outsider sees no journey');
select is((select count(*)::int from public.memberships), 0, 'outsider sees no membership');
select is((select count(*)::int from public.check_ins), 0, 'outsider sees no check-in');
select is((select count(*)::int from public.reactions), 0, 'outsider sees no reaction');
select is((select count(*)::int from storage.objects where bucket_id = 'media'), 0, 'outsider cannot read media');
select throws_ok(
  $$ select tests.checkin('c3000000-0000-4000-8000-000000000003', 'a0000000-0000-4000-8000-000000000001', now()) $$,
  'P0001', 'not_found', 'outsider cannot post into the journey');
select throws_ok($$ select public.group_today('a0000000-0000-4000-8000-000000000001') $$,
  '42501', 'forbidden', 'outsider cannot read the today board');
select throws_ok($$ select public.rotate_invite('a0000000-0000-4000-8000-000000000001') $$,
  '42501', 'forbidden', 'outsider cannot rotate the invite');

-- ---- block (u2 blocks u4): content hidden both ways, third parties unaffected --
do $$ begin perform tests.as_user('10000000-0000-4000-8000-000000000002'); end $$;
select lives_ok($$ select public.block_user('10000000-0000-4000-8000-000000000004') $$, 'u2 blocks u4');
select is((select count(*)::int from public.check_ins where user_id = '10000000-0000-4000-8000-000000000004'), 0,
  'blocker no longer sees blocked user''s check-ins');
select is((select count(*)::int from storage.objects
            where name like 'checkins/%/10000000-0000-4000-8000-000000000004/%'), 0,
  'blocker no longer reads blocked user''s media');
do $$ begin perform tests.as_user('10000000-0000-4000-8000-000000000004'); end $$;
select is((select count(*)::int from public.check_ins where user_id = '10000000-0000-4000-8000-000000000002'), 0,
  'blocked user no longer sees blocker''s check-ins');
select is((select array_agg(user_id order by user_id)::text from public.group_today('a0000000-0000-4000-8000-000000000001')),
  '{10000000-0000-4000-8000-000000000001,10000000-0000-4000-8000-000000000004}',
  'today board hides the blocker from the blocked user');
select throws_ok(
  $$ insert into public.reactions (checkin_id, user_id, emoji) values ('c2000000-0000-4000-8000-000000000002', auth.uid(), '🔥') $$,
  '42501', null, 'blocked user cannot react to blocker''s check-in');
do $$ begin perform tests.as_user('10000000-0000-4000-8000-000000000001'); end $$;
select is((select count(*)::int from public.check_ins), 3, 'third party still sees both users');

-- ---- report: hidden from reporter at once, queued for moderation -----------
select lives_ok($$ select public.report_content('c4000000-0000-4000-8000-000000000004', null, 'spam', 'ad') $$,
  'member reports a check-in');
select is((select count(*)::int from public.check_ins where id = 'c4000000-0000-4000-8000-000000000004'), 0,
  'reported check-in is hidden from the reporter');
select throws_ok($$ select count(*) from public.moderation_queue $$, '42501', null,
  'moderation_queue is not readable by users');
do $$ begin perform tests.as_postgres(); end $$;
select results_eq(
  $$ select kind, target_user_id from public.moderation_queue order by kind $$,
  $$ values ('block'::text, '10000000-0000-4000-8000-000000000004'::uuid),
            ('report'::text, '10000000-0000-4000-8000-000000000004'::uuid) $$,
  'block and report both land in moderation_queue');

-- ---- anon -----------------------------------------------------------------
do $$ begin perform tests.as_anon(); end $$;
select throws_ok($$ select count(*) from public.check_ins $$, '42501', null, 'anon has no table access');

select * from finish();
rollback;
