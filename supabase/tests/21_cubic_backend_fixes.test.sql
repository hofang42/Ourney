-- 0021_cubic_backend_fixes: pgTAP verification of Batch A findings
-- (CB-01, CB-02, CB-21, CB-22, CB-23, CB-24, CB-25, CB-26, CB-27, CB-28, CB-57, CB-73).
begin;
create extension if not exists pgtap with schema extensions;
select plan(40);

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
  select format('21000000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function tests.j(n int) returns uuid language sql immutable as $$
  select format('b2100000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function tests.c(n int) returns uuid language sql immutable as $$
  select format('c2100000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function tests.m(n int) returns uuid language sql immutable as $$
  select format('d2100000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function tests.checkin(cid uuid, j uuid, at timestamptz default now(), lib boolean default false)
returns void language sql as $$
  insert into public.check_ins (id, journey_id, user_id, local_date, captured_at, photo_path, thumb_path, from_library)
  values (cid, j, auth.uid(), public.local_date(at, 'UTC'), at,
          format('checkins/%s/%s/%s.jpg', j, auth.uid(), cid),
          format('checkins/%s/%s/%s_t.jpg', j, auth.uid(), cid), lib) $$;
create function tests.code(n int) returns text language sql security definer as $$
  select invite_code from public.journeys where id = tests.j(n) $$;
create function tests.pub(n int) returns text language sql security definer as $$
  select public_token::text from public.journeys where id = tests.j(n) $$;
create function tests.friend_token(u uuid) returns text language sql security definer as $$
  select token from public.friend_invites where user_id = u $$;
create function tests.conv(j uuid, member uuid, viewer uuid) returns uuid language sql security definer as $$
  select id from public.conversations where journey_id = j and member_id = member and viewer_id = viewer $$;
create function tests.befriend(a uuid, b uuid) returns void language plpgsql as $$
begin
  perform tests.as_user(a); perform public.send_friend_request(b);
  perform tests.as_user(b); perform public.respond_friend_request(a, true);
end $$;
grant execute on all functions in schema tests to authenticated;

insert into auth.users (id, email)
select tests.u(n), format('cb21_%s@example.test', n) from generate_series(1, 10) n;
insert into public.profiles (id, username, display_name)
select tests.u(n), 'cb21user' || n, 'CB21_' || n from generate_series(1, 10) n;

-- ============================================================================
-- 1. CB-01: leave_journey solo guard, _leave_journey share/consent cleanup,
--           rejoin consent reset, and abandoned group owner hygiene
-- ============================================================================
do $$ begin
  perform tests.befriend(tests.u(1), tests.u(2));
  perform tests.befriend(tests.u(1), tests.u(3));
  perform tests.befriend(tests.u(2), tests.u(3));
  perform tests.as_user(tests.u(1));
  perform public.create_journey(tests.j(1), 'solo', 'custom', 'Solo Leave Guard', '🏃', null, null, false, current_date - 5, 30, 'UTC');
end $$;

-- [1]
select throws_ok(
  $$ select public.leave_journey(tests.j(1)) $$,
  'P0001', 'invalid',
  'CB-01: leave_journey rejects solo journeys (must use end_journey/delete_journey)'
);

do $$ begin
  perform tests.as_user(tests.u(1));
  perform public.create_journey(tests.j(2), 'group', 'custom', 'Group Leave Hygiene', '🔥', null, null, false, current_date - 5, 30, 'UTC');
  perform tests.checkin(tests.c(21), tests.j(2), now() - interval '1 day');
  perform tests.as_user(tests.u(2));
  perform public.join_by_code(tests.code(2));
  perform tests.checkin(tests.c(22), tests.j(2), now() - interval '1 day');
  perform tests.as_user(tests.u(1));
  perform public.end_journey(tests.j(2));
  perform public.set_journey_public_link(tests.j(2), true);
  perform tests.as_user(tests.u(2));
  perform public.respond_share_consent(tests.j(2), true);
  perform public.share_journey(tests.j(2), array[tests.u(3)]);
  perform tests.as_user(tests.u(4));
  perform public.save_shared_journey(tests.j(2), tests.pub(2));
  perform tests.as_user(tests.u(2));
  perform public.leave_journey(tests.j(2));
  perform tests.as_postgres();
end $$;

-- [2]
select is(
  (select status from public.journey_share_consents where journey_id = tests.j(2) and user_id = tests.u(2))
  || ':' ||
  (select count(*)::text from public.journey_shares where journey_id = tests.j(2) and shared_by = tests.u(2) and revoked_at is null),
  'withdrawn:0',
  'CB-01: leaving a group sets journey_share_consents to withdrawn and revokes leaver journey_shares'
);

do $$ begin
  perform tests.as_postgres();
  update public.journeys set status = 'active' where id = tests.j(2);
  perform tests.as_user(tests.u(2));
  perform public.join_by_code(tests.code(2));
  perform tests.as_postgres();
end $$;

-- [3]
select is(
  (select status || ':' || coalesce(decided_at::text, 'null')
     from public.journey_share_consents
    where journey_id = tests.j(2) and user_id = tests.u(2)),
  'pending:null',
  'CB-01: rejoining a group resets withdrawn share consent back to pending'
);

do $$ begin
  perform tests.as_user(tests.u(2));
  perform public.leave_journey(tests.j(2));
  perform tests.as_user(tests.u(1));
  perform public.leave_journey(tests.j(2));
  perform tests.as_user(tests.u(4));
end $$;

-- [4]
select is(
  (select j.status::text || ':' || coalesce(j.public_token::text, 'null')
     from public.journeys j where j.id = tests.j(2))
  || ':' ||
  (select count(*)::text from public.saved_journeys where journey_id = tests.j(2))
  || ':' ||
  (private.owner_for_viewer(tests.j(2))->>'user_id')
  || ':' ||
  private.can_see_profile(tests.u(1))::text,
  'archived:null:0:00000000-0000-0000-0000-000000000000:false',
  'CB-01: last owner leaving archives group, clears public_token & saved_journeys, and hides ex-owner profile'
);

-- ============================================================================
-- 2. CB-02: accept_friend_invite profile lock, rate limit, & timestamp check
-- ============================================================================
do $$ declare
  v_tok text;
begin
  perform tests.as_user(tests.u(5));
  v_tok := public.create_friend_invite();
  perform tests.as_user(tests.u(6));
  perform public.accept_friend_invite(v_tok);
  perform tests.as_user(tests.u(5));
  perform public.remove_friend(tests.u(6));
  perform tests.as_user(tests.u(6));
end $$;

-- [5]
select throws_ok(
  $$ select public.accept_friend_invite(tests.friend_token(tests.u(5))) $$,
  'P0001', 'invalid',
  'CB-02: accept_friend_invite rejects old invite token predating friendship removal'
);

do $$ declare
  v_tok text;
begin
  perform tests.as_user(tests.u(5));
  v_tok := public.create_friend_invite();
  perform tests.as_user(tests.u(6));
  perform public.accept_friend_invite(v_tok);
end $$;

-- [6]
select is(
  (select count(*)::int from public.friendships
    where user_low = least(tests.u(5), tests.u(6))
      and user_high = greatest(tests.u(5), tests.u(6))
      and status = 'accepted' and deleted_at is null),
  1,
  'CB-02: rotating friend invite via create_friend_invite allows reviving a previously removed friendship'
);

do $$ begin
  perform tests.as_postgres();
  update public.profiles set deleted_at = now() where id = tests.u(9);
  perform tests.as_user(tests.u(9));
end $$;

-- [7]
select throws_ok(
  $$ select public.accept_friend_invite(tests.friend_token(tests.u(5))) $$,
  '42501', 'forbidden',
  'CB-02: accept_friend_invite rejects callers whose profile is missing or soft-deleted'
);

do $$ begin
  perform tests.as_postgres();
  update public.profiles set deleted_at = null where id = tests.u(9);
  insert into private.rate_events (user_id, kind, at)
  select tests.u(9), 'friend_invite', now() - (n || ' seconds')::interval
    from generate_series(1, 30) n;
  perform tests.as_user(tests.u(9));
end $$;

-- [8]
select throws_ok(
  $$ select public.accept_friend_invite(tests.friend_token(tests.u(5))) $$,
  'P0001', 'rate_limited',
  'CB-02: accept_friend_invite enforces <= 30/hour rate limit in private.rate_events'
);

do $$ begin
  perform tests.as_postgres();
  delete from private.rate_events where user_id = tests.u(9);
end $$;

-- ============================================================================
-- 3. CB-21: create_journey Rule S9 link rejection, soft-deleted ID collision,
--           and journeys_social_defaults for quiet_transformer
-- ============================================================================
do $$ begin perform tests.as_user(tests.u(1)); end $$;

-- [9]
select throws_ok(
  $$ select public.create_journey(tests.j(21), 'solo', 'custom', 'Live Link', '🔗', null, null, false, current_date, 10, 'UTC', 1, 'link') $$,
  'P0001', 'invalid',
  'CB-21: create_journey rejects p_visibility = link on live journey creation (Rule S9)'
);

do $$ begin
  perform tests.as_user(tests.u(1));
  perform public.create_journey(tests.j(21), 'solo', 'custom', 'To Delete', '🗑️', null, null, false, current_date, 10, 'UTC');
  perform public.delete_journey(tests.j(21));
end $$;

-- [10]
select throws_ok(
  $$ select public.create_journey(tests.j(21), 'solo', 'custom', 'Retry Deleted', '🗑️', null, null, false, current_date, 10, 'UTC') $$,
  '42501', 'forbidden',
  'CB-21: create_journey rejects retrying a soft-deleted journey ID'
);

-- [11]
select throws_ok(
  $$ select public.create_imported_journey(tests.j(21), 'Retry Imp', '📷', 'custom', current_date - 5, current_date - 1, 'UTC') $$,
  '42501', 'forbidden',
  'CB-21: create_imported_journey rejects retrying a soft-deleted journey ID'
);

do $$ begin
  perform tests.as_user(tests.u(1));
  perform public.create_imported_journey(tests.j(22), 'Quiet Imported', '🤫', 'custom', current_date - 5, current_date - 1, 'UTC', null, null, 'quiet_transformer', false);
  perform public.update_journey(tests.j(1), p_layout := 'quiet_transformer');
end $$;

-- [12]
select is(
  (select count(*)::int from public.journeys
    where id in (tests.j(1), tests.j(22))
      and not allow_public_reactions
      and not allow_viewer_requests),
  2,
  'CB-21: journeys_social_defaults forces allow_public_reactions=false and allow_viewer_requests=false on quiet_transformer'
);

-- ============================================================================
-- 4. CB-22: delete_journey membership revocation, conversation hiding, and
--           storage purge queueing for live users
-- ============================================================================
do $$ declare
  v_conv uuid;
begin
  perform tests.as_user(tests.u(1));
  perform public.create_journey(tests.j(23), 'solo', 'custom', 'Delete Storage & Chat', '🧹', null, null, false, current_date - 5, 30, 'UTC');
  perform tests.checkin(tests.c(230), tests.j(23), now() - interval '1 day');
  perform public.end_journey(tests.j(23));
  perform public.share_journey(tests.j(23), array[tests.u(2)]);
  perform tests.as_user(tests.u(2));
  v_conv := public.open_conversation(tests.j(23), tests.c(230));
  insert into storage.objects (bucket_id, name) values
    ('messages', format('messages/%s/%s/%s.jpg', v_conv, tests.u(2), tests.m(230)));
  perform public.send_message(
    tests.m(230), v_conv, 'photo', 'before delete',
    format('messages/%s/%s/%s.jpg', v_conv, tests.u(2), tests.m(230))
  );
  perform tests.as_postgres();
  insert into storage.objects (bucket_id, name) values
    ('media', format('checkins/%s/%s/%s.jpg', tests.j(23), tests.u(1), tests.c(230)));
  delete from private.pending_storage_purge;
  perform tests.as_user(tests.u(1));
  perform public.delete_journey(tests.j(23));
end $$;

-- [13]
select is(
  private.is_member(tests.j(23))::text
  || ':' || private.is_owner(tests.j(23))::text
  || ':' || private.is_active_member(tests.j(23), tests.u(1))::text
  || ':' || (select status || ':' || (deleted_at is not null)::text
               from public.memberships where journey_id = tests.j(23) and user_id = tests.u(1)),
  'false:false:false:left:true',
  'CB-22: delete_journey marks memberships left/deleted and is_member/is_owner/is_active_member return false'
);

-- [14]
select is(
  (select count(*)::int from public.my_conversations() c where (c->>'journey_id')::uuid = tests.j(23))
  + (public.inbox_counts()->>'unread_messages')::int
  + (case when private.conversation_read_only(tests.conv(tests.j(23), tests.u(1), tests.u(2))) then 0 else 1 end),
  0,
  'CB-22: deleted-journey threads are read-only and excluded from my_conversations and inbox_counts'
);

do $$ begin perform tests.as_postgres(); end $$;
-- [15]
select is(
  (select count(*)::int from public.claim_storage_purge(20)
    where path in (
      format('checkins/%s/%s/%s.jpg', tests.j(23), tests.u(1), tests.c(230)),
      format('messages/%s/%s/%s.jpg', tests.conv(tests.j(23), tests.u(1), tests.u(2)), tests.u(2), tests.m(230))
    )),
  2,
  'CB-22: delete_journey enqueues check-in and chat media for immediate claim_storage_purge even for live users'
);
do $$ begin perform tests.as_postgres(); delete from private.pending_storage_purge; end $$;

-- ============================================================================
-- 5. CB-23: check-in visibility in open_conversation, send_message,
--           and update_journey_story
-- ============================================================================
do $$ begin
  perform tests.as_user(tests.u(1));
  perform public.create_journey(tests.j(24), 'solo', 'custom', 'Checkin Visibility', '👁️', null, null, false, current_date - 5, 30, 'UTC');
  perform tests.checkin(tests.c(240), tests.j(24), now() - interval '2 days');
  perform tests.checkin(tests.c(241), tests.j(24), now() - interval '1 day');
  perform public.set_hidden_in_share(tests.c(240), true);
  perform public.end_journey(tests.j(24));
  perform public.share_journey(tests.j(24), array[tests.u(2)]);
  perform tests.as_user(tests.u(2));
end $$;

-- [16]
select throws_ok(
  $$ select public.open_conversation(tests.j(24), tests.c(240)) $$,
  'P0001', 'invalid',
  'CB-23: open_conversation rejects p_checkin when hidden_in_share is true'
);

do $$ begin
  perform tests.as_user(tests.u(2));
  perform public.open_conversation(tests.j(24), tests.c(241));
end $$;

-- [17]
select throws_ok(
  $$ select public.send_message(tests.m(240), tests.conv(tests.j(24), tests.u(1), tests.u(2)), 'text', 'sneak reply', null, tests.c(240)) $$,
  'P0001', 'invalid',
  'CB-23: send_message rejects p_reply_to pointing at a hidden_in_share check-in for a viewer'
);

do $$ begin
  perform tests.as_postgres();
  update public.check_ins set moderated_at = now() where id = tests.c(241);
  perform tests.as_user(tests.u(1));
end $$;

-- [18]
select throws_ok(
  $$ select public.update_journey_story(tests.j(24), 'Story', 'Intro', 'Lessons', tests.c(241)) $$,
  'P0001', 'invalid',
  'CB-23: update_journey_story rejects moderated check-ins as story cover'
);

-- ============================================================================
-- 6. CB-24: my_conversations post-clear hidden messages, re-opened cleared
--           conversation visibility, and monotonic mark_conversation_read
-- ============================================================================
do $$ declare
  v_conv uuid;
begin
  perform tests.as_user(tests.u(1));
  perform public.create_journey(tests.j(25), 'solo', 'custom', 'Chat Clear & Reopen', '💬', null, null, false, current_date - 5, 30, 'UTC');
  perform tests.checkin(tests.c(250), tests.j(25), now() - interval '1 day');
  perform public.end_journey(tests.j(25));
  perform public.share_journey(tests.j(25), array[tests.u(2)]);
  perform tests.as_user(tests.u(2));
  v_conv := public.open_conversation(tests.j(25), tests.c(250));
  perform public.send_message(tests.m(250), v_conv, 'text', 'first msg', null);
  perform tests.as_postgres();
  update public.messages set created_at = now() - interval '2 minutes' where id = tests.m(250);
  update public.conversations set last_message_at = now() - interval '2 minutes' where id = v_conv;
  perform tests.as_user(tests.u(1));
  perform public.clear_conversation(v_conv);
  perform tests.as_user(tests.u(2));
  perform public.send_message(tests.m(251), v_conv, 'text', 'second msg hidden', null);
  perform tests.as_user(tests.u(1));
  perform public.hide_message(tests.m(251));
end $$;

-- [19]
select is(
  (select count(*)::int from public.my_conversations() c where (c->>'journey_id')::uuid = tests.j(25)),
  0,
  'CB-24: my_conversations hides a cleared thread when all post-clear messages are hidden'
);

do $$ declare
  v_conv uuid := tests.conv(tests.j(25), tests.u(1), tests.u(2));
begin
  perform tests.as_user(tests.u(2));
  perform public.clear_conversation(v_conv);
  perform public.open_conversation(tests.j(25), tests.c(250));
end $$;

-- [20]
select is(
  (select count(*)::int from public.my_conversations() c where (c->>'journey_id')::uuid = tests.j(25))
  || ':' ||
  (select count(*)::int from public.conversation_messages(tests.conv(tests.j(25), tests.u(1), tests.u(2)))),
  '1:0',
  'CB-24: re-opening a cleared conversation via open_conversation shows the empty thread to the viewer without restoring cleared messages'
);

do $$ declare
  v_conv uuid := tests.conv(tests.j(25), tests.u(1), tests.u(2));
begin
  perform tests.as_postgres();
  update public.conversations set last_message_at = now() + interval '5 minutes' where id = v_conv;
  perform tests.as_user(tests.u(1));
  perform public.mark_conversation_read(v_conv);
  perform tests.as_postgres();
end $$;

-- [21]
select ok(
  (select member_read_at >= last_message_at
     from public.conversations
    where id = tests.conv(tests.j(25), tests.u(1), tests.u(2))),
  'CB-24: mark_conversation_read advances read_at monotonically to at least last_message_at'
);

-- ============================================================================
-- 7. CB-25: journey_insights & my_reach member exclusion, grant_valid
--           from_friend classification, and started_this_week deduplication
-- ============================================================================
do $$ begin
  perform tests.as_user(tests.u(1));
  perform public.create_journey(tests.j(26), 'group', 'custom', 'Insights Accuracy', '📊', null, null, false, current_date - 5, 30, 'UTC');
  perform tests.checkin(tests.c(260), tests.j(26), now() - interval '1 day');
  perform tests.as_user(tests.u(3));
  perform public.join_by_code(tests.code(26));
  insert into public.reactions (checkin_id, user_id, emoji) values (tests.c(260), tests.u(3), '🔥');
  perform public.leave_journey(tests.j(26));
  perform tests.as_user(tests.u(1));
  insert into public.reactions (checkin_id, user_id, emoji) values (tests.c(260), tests.u(1), '💪');
  perform public.end_journey(tests.j(26));
  perform public.set_journey_public_link(tests.j(26), true);
  perform public.share_journey(tests.j(26), array[tests.u(2)]);
  perform tests.as_user(tests.u(2));
  insert into public.reactions (checkin_id, user_id, emoji) values (tests.c(260), tests.u(2), '❤️');
  perform public.create_journey(tests.j(261), 'solo', 'custom', 'Follow 1', '🌱', null, null, false, current_date, 10, 'UTC');
  perform public.mark_followed(tests.j(261), tests.j(26));
  perform public.create_journey(tests.j(262), 'solo', 'custom', 'Follow 2', '🌱', null, null, false, current_date, 10, 'UTC');
  perform public.mark_followed(tests.j(262), tests.j(26));
  perform tests.as_user(tests.u(1));
  perform public.unshare_journey(tests.j(26), tests.u(2), false);
  perform tests.as_postgres();
  insert into public.journey_views (journey_id, viewer_key, day) values
    (tests.j(26), tests.u(1)::text, current_date),
    (tests.j(26), tests.u(2)::text, current_date);
  perform tests.as_user(tests.u(1));
end $$;

-- [22]
select is(
  (select (ji->>'views') || ':' ||
          (ji->>'likes_from_friends') || ':' ||
          (ji->>'likes_from_strangers') || ':' ||
          (ji->>'started') || ':' ||
          (ji->>'started_this_week') || ':' ||
          json_array_length(ji->'likers')::text
     from public.journey_insights(tests.j(26)) ji),
  '1:0:1:1:1:1',
  'CB-25: journey_insights excludes active/former members, treats revoked shares as stranger likes, and deduplicates started_this_week'
);

-- [23]
select is(
  public.my_reach(),
  1,
  'CB-25: my_reach excludes active members viewing their own journey'
);

-- ============================================================================
-- 8. CB-26: reactions_saved_sync shareable check, reaction soft-delete on ended
--           journey, and mark_followed Rule S9 + immutability
-- ============================================================================
do $$ begin
  perform tests.as_user(tests.u(1));
  perform public.create_journey(tests.j(27), 'solo', 'custom', 'Reactions & Follow', '❤️', null, null, false, current_date - 5, 30, 'UTC');
  perform tests.checkin(tests.c(270), tests.j(27), now() - interval '2 days');
  perform tests.checkin(tests.c(271), tests.j(27), now() - interval '1 day');
  perform public.end_journey(tests.j(27));
  perform public.set_journey_public_link(tests.j(27), true, true, true);
  perform tests.as_user(tests.u(4));
  insert into public.reactions (checkin_id, user_id, emoji) values
    (tests.c(270), tests.u(4), '🔥'),
    (tests.c(271), tests.u(4), '👏');
  perform tests.as_user(tests.u(1));
  perform public.set_hidden_in_share(tests.c(270), true);
  perform public.set_journey_public_link(tests.j(27), true, false, false);
  perform tests.as_user(tests.u(4));
end $$;

-- [24]
select lives_ok(
  $$ update public.reactions set deleted_at = now() where checkin_id = tests.c(271) and user_id = tests.u(4) $$,
  'CB-26: user can soft-delete their own reaction even after journey ended and allow_public_reactions was disabled'
);

-- [25]
select is(
  (select count(*)::int from public.saved_journeys where user_id = tests.u(4) and journey_id = tests.j(27)),
  0,
  'CB-26: reactions_saved_sync deletes saved_journeys when the only remaining liked check-in is hidden_in_share'
);

do $$ begin
  perform tests.as_user(tests.u(1));
  perform public.create_journey(tests.j(272), 'solo', 'custom', 'Active Unfinished', '⏳', null, null, false, current_date, 30, 'UTC');
  perform tests.as_user(tests.u(2));
  perform public.create_journey(tests.j(273), 'solo', 'custom', 'Follower Journey', '👣', null, null, false, current_date, 30, 'UTC');
  perform tests.as_user(tests.u(1));
  perform public.share_journey(tests.j(272), array[tests.u(2)]);
  perform tests.as_user(tests.u(2));
end $$;

-- [26]
select throws_ok(
  $$ select public.mark_followed(tests.j(273), tests.j(272)) $$,
  'P0001', 'invalid',
  'CB-26: mark_followed rejects active unfinished source journeys (Rule S9)'
);

do $$ begin
  perform tests.as_user(tests.u(2));
  perform public.mark_followed(tests.j(273), tests.j(27));
end $$;

-- [27]
select throws_ok(
  $$ select public.mark_followed(tests.j(273), tests.j(26)) $$,
  'P0001', 'invalid',
  'CB-26: mark_followed rejects overwriting followed_from with a different source journey'
);

-- ============================================================================
-- 9. CB-27: account_media_paths, account_message_paths, & claim_storage_purge lease
-- ============================================================================
do $$ declare
  v_conv uuid := tests.conv(tests.j(25), tests.u(1), tests.u(2));
begin
  perform tests.as_postgres();
  insert into storage.objects (bucket_id, name) values
    ('media', format('avatars/%s/avatar.jpg', tests.u(2))),
    ('messages', format('messages/%s/%s/chat.jpg', v_conv, tests.u(2)));
  delete from private.pending_storage_purge;
  insert into private.pending_storage_purge (bucket, path, user_id)
  values ('media', 'avatars/00000000-0000-0000-0000-000000000000/test.jpg', '00000000-0000-0000-0000-000000000000'::uuid);
end $$;

-- [28]
select is(
  (select count(*)::int from public.account_media_paths(tests.u(2))
    where account_media_paths = format('avatars/%s/avatar.jpg', tests.u(2)))
  +
  (select count(*)::int from public.account_message_paths(tests.u(2))
    where account_message_paths = format('messages/%s/%s/chat.jpg', tests.conv(tests.j(25), tests.u(1), tests.u(2)), tests.u(2))),
  2,
  'CB-27: account_media_paths and account_message_paths match prefix paths accurately'
);

-- [29]
select is(
  (select count(*)::int from public.claim_storage_purge(10))
  || ':' ||
  (select count(*)::int from public.claim_storage_purge(10)),
  '1:0',
  'CB-27: claim_storage_purge atomically leases claimed rows for 2 minutes so back-to-back calls do not double-claim'
);
do $$ begin perform tests.as_postgres(); delete from private.pending_storage_purge; end $$;

-- ============================================================================
-- 10. CB-28: check_in_extras_valid 1024-byte cap & author soft-delete on ended journey
-- ============================================================================
-- [30]
select is(
  public.check_in_extras_valid(
    jsonb_build_object(
      'place', repeat('Đà Nẵng ', 7),
      'dish', repeat('Bánh xèo miền Trung ', 3),
      'mood', 'Tuyệt vời lắm luôn',
      'cook', 'Mẹ nấu ngon nhất',
      'minutes', 120,
      'hearts', 5,
      'pace', '05:30',
      'km', 12.5
    )
  ),
  true,
  'CB-28: check_in_extras_valid accepts multibyte Vietnamese extras between 513 and 1024 UTF-8 bytes'
);

do $$ begin perform tests.as_user(tests.u(1)); end $$;

-- [31]
select throws_ok(
  $$ update public.check_ins set caption = 'late edit' where id = tests.c(270) $$,
  'P0001', 'ended',
  'CB-28: check_ins_before_write still rejects caption edits on ended journeys'
);

-- [32]
select lives_ok(
  $$ update public.check_ins set deleted_at = now() where id = tests.c(270) $$,
  'CB-28: check_ins_before_write allows authors to soft-delete their own check-in on an ended journey'
);

-- ============================================================================
-- 11. CB-57: couple names column privilege, trigger seat/layout invariants,
--            42501 on rename_couple & update_journey, and checkin_tombstones after_id
-- ============================================================================
do $$ begin
  perform tests.as_user(tests.u(1));
  perform public.create_journey(tests.j(28), 'group', 'custom', 'Couple Perms', '💑', null, null, false,
                                current_date - 3, 30, 'UTC', 2, 'group', 'An', 'Binh');
  perform public.update_journey(tests.j(28), p_layout := 'couple_rituals');
  perform tests.as_user(tests.u(2));
  perform public.join_by_code(tests.code(28));
  perform tests.as_user(tests.u(1));
end $$;

-- [33]
select throws_ok(
  $$ update public.journeys set couple_self_name = 'DirectEdit' where id = tests.j(28) $$,
  '42501', null,
  'CB-57: authenticated role cannot directly UPDATE couple_self_name / couple_partner_name on public.journeys'
);

do $$ begin perform tests.as_user(tests.u(2)); end $$;

-- [34]
select throws_ok(
  $$ select public.rename_couple(tests.j(28), 'Hack1', 'Hack2') $$,
  '42501', 'forbidden',
  'CB-57: rename_couple raises 42501 forbidden for non-owner group members'
);

-- [35]
select throws_ok(
  $$ select public.update_journey(tests.j(28), p_title := 'Hijack') $$,
  '42501', 'forbidden',
  'CB-57: update_journey raises 42501 forbidden for non-owner group members'
);

do $$ begin
  perform tests.as_user(tests.u(1));
  perform public.create_journey(tests.j(29), 'group', 'custom', 'Squad of 3', '🤝', null, null, false, current_date - 3, 30, 'UTC');
  perform tests.as_user(tests.u(2));
  perform public.join_by_code(tests.code(29));
  perform tests.checkin(tests.c(291), tests.j(29), now() - interval '2 days');
  perform tests.checkin(tests.c(292), tests.j(29), now() - interval '1 day');
  update public.check_ins set deleted_at = now() where id in (tests.c(291), tests.c(292));
  perform tests.as_user(tests.u(3));
  perform public.join_by_code(tests.code(29));
  perform tests.as_postgres();
end $$;

-- [36]
select throws_ok(
  $$ update public.journeys set couple_self_name = 'A', couple_partner_name = 'B' where id = tests.j(29) $$,
  'P0001', 'full',
  'CB-57: journeys_couple_seats rejects converting a >2-member group into a couple journey'
);

-- [37]
select throws_ok(
  $$ update public.journeys set couple_self_name = null, couple_partner_name = null where id = tests.j(28) $$,
  'P0001', 'invalid',
  'CB-57: journeys_couple_seats rejects clearing couple names while layout is couple_rituals'
);

do $$ begin perform tests.as_user(tests.u(1)); end $$;

-- [38]
select is(
  (select id from public.checkin_tombstones(
     (select updated_at from public.check_ins where id = tests.c(291)),
     1,
     tests.c(291)
   )),
  tests.c(292),
  'CB-57: checkin_tombstones keyset pagination via after_id advances past same-timestamp tombstones'
);

-- ============================================================================
-- 12. CB-73: shared_with_me same-day cover tie-break & unshare_journey guard
-- ============================================================================
do $$ declare
  v_yesterday date := public.local_date(now(), 'UTC') - 1;
begin
  perform tests.as_user(tests.u(1));
  perform public.create_journey(tests.j(30), 'group', 'custom', 'Cover Tie Break', '🖼️', null, null, false, current_date - 5, 30, 'UTC');
  -- c(301) has lower UUID but LATER captured_at on the same local_date
  perform tests.checkin(tests.c(301), tests.j(30), (v_yesterday::text || ' 15:00:00+00')::timestamptz);
  perform tests.as_user(tests.u(3));
  perform public.join_by_code(tests.code(30));
  -- c(302) has higher UUID but EARLIER captured_at on the same local_date
  perform tests.checkin(tests.c(302), tests.j(30), (v_yesterday::text || ' 09:00:00+00')::timestamptz);
  perform tests.as_user(tests.u(1));
  perform public.end_journey(tests.j(30));
  perform public.share_journey(tests.j(30), array[tests.u(2)]);
  perform tests.as_user(tests.u(3));
  perform public.respond_share_consent(tests.j(30), true);
  perform tests.as_user(tests.u(2));
end $$;

-- [39]
select is(
  (select s->>'cover_thumb_path' from public.shared_with_me() s where (s->>'journey_id')::uuid = tests.j(30)),
  format('checkins/%s/%s/%s_t.jpg', tests.j(30), tests.u(1), tests.c(301)),
  'CB-73: shared_with_me picks the latest captured_at photo on same-day check-ins'
);

do $$ begin perform tests.as_user(tests.u(4)); end $$;

-- [40]
select throws_ok(
  $$ select public.unshare_journey(tests.j(30), null, false) $$,
  '42501', 'forbidden',
  'CB-73: unshare_journey raises 42501 forbidden when called by a non-member with no shares'
);

select * from finish();
rollback;
