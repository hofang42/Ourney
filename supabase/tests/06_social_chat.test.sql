-- Social v1.3 (0006_social): conversations (S13, S24, S33, S37), messages RLS, read-only after
-- unfriend, hide / clear, rate limit, message reports, messages bucket.
-- Users: 1 A solo owner, 2 B friend grantee, 3 C stranger (public link), 4 D group owner,
--        5 E group member, 6 F friend of D and E (grants from both).
begin;
create extension if not exists pgtap with schema extensions;
select plan(45);

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
  select format('62000000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function tests.j(n int) returns uuid language sql immutable as $$
  select format('b6200000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function tests.c(n int) returns uuid language sql immutable as $$
  select format('c6200000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function tests.m(n int) returns uuid language sql immutable as $$
  select format('d6200000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid $$;
create function tests.checkin(cid uuid, j uuid) returns void language sql as $$
  insert into public.check_ins (id, journey_id, user_id, local_date, captured_at, photo_path, thumb_path)
  values (cid, j, auth.uid(), current_date, now(), format('checkins/%s/%s/%s.jpg', j, auth.uid(), cid),
          format('checkins/%s/%s/%s_t.jpg', j, auth.uid(), cid)) $$;
create function tests.code(n int) returns text language sql security definer as $$
  select invite_code from public.journeys where id = tests.j(n) $$;
create function tests.conv(j uuid, member uuid, viewer uuid) returns uuid language sql security definer as $$
  select id from public.conversations where journey_id = j and member_id = member and viewer_id = viewer $$;
create function tests.befriend(a uuid, b uuid) returns void language plpgsql as $$
begin
  perform tests.as_user(a); perform public.send_friend_request(b);
  perform tests.as_user(b); perform public.respond_friend_request(a, true);
end $$;
grant execute on all functions in schema tests to authenticated;

insert into auth.users (id, email) select tests.u(n), format('ch%s@example.test', n) from generate_series(1, 6) n;
insert into public.profiles (id, username, display_name) select tests.u(n), 'chuser' || n, 'CH' || n from generate_series(1, 6) n;

-- ---- setup -------------------------------------------------------------------
do $$ begin
  perform tests.befriend(tests.u(1), tests.u(2));
  perform tests.befriend(tests.u(4), tests.u(6));
  perform tests.befriend(tests.u(5), tests.u(6));
  perform tests.as_user(tests.u(1));
  perform public.create_journey(tests.j(1), 'solo', 'custom', 'Run', '🏃', null, null, false, current_date - 3, 30, 'UTC');
  perform tests.checkin(tests.c(1), tests.j(1));
  perform public.end_journey(tests.j(1));
  perform public.share_journey(tests.j(1), array[tests.u(2)]);
  perform public.set_public_link(tests.j(1), true);
  perform tests.as_user(tests.u(4));
  perform public.create_journey(tests.j(2), 'group', 'custom', 'Team', '🔥', null, null, false, current_date - 3, 30, 'UTC');
  perform tests.checkin(tests.c(4), tests.j(2));
  perform tests.as_user(tests.u(5));
  perform public.join_by_code(tests.code(2));
  perform tests.checkin(tests.c(5), tests.j(2));
  perform tests.as_user(tests.u(4));
  perform public.request_share_consent(tests.j(2));
  perform public.share_journey(tests.j(2), array[tests.u(6)]);
end $$;
do $$ begin perform tests.as_postgres();
  -- D's grant is the earliest one (S33)
  update public.journey_shares set granted_at = now() - interval '1 hour' where journey_id = tests.j(2); end $$;

-- ===== who may open a conversation ============================================
do $$ begin perform tests.as_user(tests.u(3)); end $$;
select throws_ok($$ select public.open_conversation(tests.j(1), tests.c(1)) $$, '42501', 'forbidden',
  'S24: a stranger cannot open a conversation');
do $$ begin perform tests.as_user(tests.u(1)); end $$;
select throws_ok($$ select public.open_conversation(tests.j(1)) $$, '42501', 'forbidden', 'members do not open reply threads');
do $$ begin perform tests.as_user(tests.u(2)); end $$;
select is(public.open_conversation(tests.j(1), tests.c(1)), tests.conv(tests.j(1), tests.u(1), tests.u(2)),
  'friend grantee opens a conversation with the solo owner');
select is(public.open_conversation(tests.j(1)), tests.conv(tests.j(1), tests.u(1), tests.u(2)),
  'opening again reuses the conversation');

-- ===== S33 recipient resolution ================================================
do $$ begin perform tests.as_user(tests.u(6)); end $$;
select is(public.open_conversation(tests.j(2), tests.c(5)), tests.conv(tests.j(2), tests.u(4), tests.u(6)),
  'S33: author not consenting -> reply goes to the earliest sharer');
do $$ begin perform tests.as_user(tests.u(5));
  perform public.respond_share_consent(tests.j(2), true);
  perform public.share_journey(tests.j(2), array[tests.u(6)]); end $$;
do $$ begin perform tests.as_user(tests.u(6)); end $$;
select is(public.open_conversation(tests.j(2), tests.c(5)), tests.conv(tests.j(2), tests.u(5), tests.u(6)),
  'S33: author is a consenting friend -> reply goes to the author');
select is(public.open_conversation(tests.j(2)), tests.conv(tests.j(2), tests.u(4), tests.u(6)),
  'S33: no photo -> earliest active grant');

-- ===== send / read ============================================================
do $$ begin perform tests.as_user(tests.u(2)); end $$;
select tests.conv(tests.j(1), tests.u(1), tests.u(2)) as cv \gset
select is((public.send_message(tests.m(1), :'cv'::uuid, 'text', ' hi ', null, tests.c(1)))->>'body', 'hi',
  'send_message stores a trimmed text');
select is((public.send_message(tests.m(1), :'cv'::uuid, 'text', 'other', null))->>'body', 'hi',
  'send_message is idempotent on p_id');
select throws_ok(format($f$ select public.send_message(gen_random_uuid(), %L, 'text', '  ', null) $f$, :'cv'),
  'P0001', 'invalid', 'empty text -> invalid');
select throws_ok(format($f$ select public.send_message(gen_random_uuid(), %L, 'text', repeat('x', 501), null) $f$, :'cv'),
  'P0001', 'invalid', 'text over 500 chars -> invalid');
select throws_ok(format($f$ select public.send_message(gen_random_uuid(), %L, 'photo', null, 'messages/x/y/z.jpg') $f$, :'cv'),
  'P0001', 'invalid', 'photo path outside messages/{conversation}/{sender}/ -> invalid');
select is((public.send_message(tests.m(2), :'cv'::uuid, 'photo', null,
            format('messages/%s/%s/%s.jpg', :'cv', tests.u(2), tests.m(2))))->>'kind', 'photo',
  'photo message with a correct path');
select is((select count(*)::int from public.messages), 2, 'sender reads the messages');
do $$ begin perform tests.as_user(tests.u(1)); end $$;
select results_eq($$ select (c->>'unread_count')::int, c->'other'->>'username', (c->>'read_only')::boolean,
                            c->>'last_message_kind' from public.my_conversations() c $$,
  $$ values (2, 'chuser2', false, 'photo') $$, 'my_conversations for the recipient');
select is((public.inbox_counts()->>'unread_messages')::int, 2, 'inbox_counts.unread_messages');
select lives_ok(format('select public.mark_conversation_read(%L)', :'cv'), 'mark read');
select is((public.inbox_counts()->>'unread_messages')::int, 0, 'read mark clears the unread count');
select lives_ok(format($f$ select public.send_message(%L, %L, 'text', 'thanks', null) $f$, tests.m(3), :'cv'), 'owner replies');
select is((select array_agg(m->>'id' order by ord)::text from public.conversation_messages(:'cv'::uuid) with ordinality t(m, ord)),
  array[tests.m(1), tests.m(2), tests.m(3)]::text, 'conversation_messages: ascending');

do $$ begin perform tests.as_user(tests.u(3)); end $$;
select is((select count(*)::int from public.messages), 0, 'outsiders read no messages');
select is((select count(*)::int from public.conversations), 0, 'outsiders read no conversations');
select throws_ok(format($f$ select public.send_message(gen_random_uuid(), %L, 'text', 'x', null) $f$, :'cv'),
  '42501', 'forbidden', 'outsider cannot post');
select throws_ok(format('select * from public.conversation_messages(%L)', :'cv'), '42501', 'forbidden',
  'outsider cannot list messages');

-- ===== storage bucket messages =================================================
do $$ begin perform tests.as_postgres();
  insert into storage.objects (bucket_id, name)
  values ('messages', format('messages/%s/%s/%s.jpg', tests.conv(tests.j(1), tests.u(1), tests.u(2)), tests.u(2), tests.m(2))); end $$;
select is((select public from storage.buckets where id = 'messages'), false, 'bucket messages is private');
do $$ begin perform tests.as_user(tests.u(1)); end $$;
select is((select count(*)::int from storage.objects where bucket_id = 'messages'), 1, 'participant reads the photo');
do $$ begin perform tests.as_user(tests.u(3)); end $$;
select is((select count(*)::int from storage.objects where bucket_id = 'messages'), 0, 'outsider cannot read it');

-- ===== reports on messages =====================================================
do $$ begin perform tests.as_user(tests.u(1)); end $$;
select isnt(public.report_content(null, null, 'harassment', 'rude', tests.m(1)), null, 'report_content(p_message)');
select is((select target_message_id from public.reports), tests.m(1), 'report keeps the message target');
select throws_ok(format($f$ select public.report_content(null, null, 'spam', null, %L) $f$, tests.m(3)), 'P0001', 'invalid',
  'cannot report your own message');

-- ===== hide / clear (S37) =====================================================
do $$ begin perform tests.as_user(tests.u(2)); end $$;
select lives_ok(format('select public.hide_message(%L)', tests.m(1)), 'B hides a message for himself');
select is((select count(*)::int from public.messages), 2, 'hidden message gone for B');
do $$ begin perform tests.as_user(tests.u(1)); end $$;
select is((select count(*)::int from public.messages), 3, 'other side still sees it');
do $$ begin perform tests.as_postgres();
  update public.messages set created_at = now() - interval '10 minutes';
  update public.conversations set last_message_at = now() - interval '10 minutes'; end $$;
do $$ begin perform tests.as_user(tests.u(2)); end $$;
select lives_ok(format('select public.clear_conversation(%L)', :'cv'), 'B clears the conversation');
select is((select count(*)::int from public.conversation_messages(:'cv'::uuid)), 0, 'cleared side sees no history');
select is((select count(*)::int from public.my_conversations()), 0, 'cleared conversation leaves the list');
do $$ begin perform tests.as_user(tests.u(1)); end $$;
select is((select count(*)::int from public.conversation_messages(:'cv'::uuid)), 3, 'other side keeps the history');
do $$ begin perform tests.as_postgres();
  update public.conversations set viewer_cleared_at = now() - interval '5 minutes'; end $$;
do $$ begin perform tests.as_user(tests.u(1));
  perform public.send_message(tests.m(4), tests.conv(tests.j(1), tests.u(1), tests.u(2)), 'text', 'still there?', null); end $$;
do $$ begin perform tests.as_user(tests.u(2)); end $$;
select is((select count(*)::int from public.my_conversations()), 1, 'a new message brings the conversation back');
select is((select count(*)::int from public.conversation_messages(:'cv'::uuid)), 1, 'only messages after the clear mark');
do $$ begin perform tests.as_user(tests.u(1)); perform public.clear_conversation(tests.conv(tests.j(1), tests.u(1), tests.u(2))); end $$;
do $$ begin perform tests.as_postgres(); end $$;
select is((select count(*)::int from public.messages where conversation_id = :'cv'::uuid), 1,
  'messages both sides cleared are hard-deleted');

-- ===== rate limit ============================================================
do $$ begin perform tests.as_user(tests.u(2)); end $$;
select throws_ok(format($f$ select public.send_message(gen_random_uuid(), %L, 'text', 'spam', null) from generate_series(1, 61) $f$, :'cv'),
  'P0001', 'rate_limited', '60 messages per sender per minute');

-- ===== read-only after unfriend ==============================================
do $$ begin perform tests.as_user(tests.u(1)); perform public.remove_friend(tests.u(2)); end $$;
do $$ begin perform tests.as_user(tests.u(2)); end $$;
select is((select (c->>'read_only')::boolean from public.my_conversations() c), true, 'unfriended conversation is read-only');
select throws_ok(format($f$ select public.send_message(gen_random_uuid(), %L, 'text', 'hey', null) $f$, :'cv'),
  '42501', 'forbidden', 'read-only conversation rejects new messages');
select is((select count(*)::int from public.conversation_messages(:'cv'::uuid)), 1, 'history stays readable');
select throws_ok($$ select public.open_conversation(tests.j(1)) $$, '42501', 'forbidden', 'ex-friend cannot open a new thread');

select * from finish();
rollback;
