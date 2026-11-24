-- 0017_pending_storage_purge: service-only table and RPCs. Written without a local run.
begin;
create extension if not exists pgtap with schema extensions;
select plan(26);

-- A live user (rows of live accounts must never be claimed) and a user that does not exist.
insert into auth.users (id, email) values ('17000000-0000-4000-8000-000000000001', 'purge-live@example.test');

select has_table('private', 'pending_storage_purge', 'queue table exists in the private schema');
select is(
  (select relrowsecurity from pg_class where oid = 'private.pending_storage_purge'::regclass),
  true,
  'RLS is enabled on the queue'
);
select is(
  (select count(*)::int from pg_policy where polrelid = 'private.pending_storage_purge'::regclass),
  0,
  'the queue has no policies (service role only)'
);
select is(
  has_table_privilege('authenticated', 'private.pending_storage_purge', 'select')
    or has_table_privilege('anon', 'private.pending_storage_purge', 'select'),
  false,
  'anon and authenticated have no grants on the queue'
);

-- Grants of every RPC: no anon, no authenticated, service_role yes.
select is(
  (select bool_or(
     has_function_privilege('anon', f, 'execute') or has_function_privilege('authenticated', f, 'execute'))
     from unnest(array[
       'public.enqueue_storage_purge(text,uuid,text[])',
       'public.fail_storage_purge(text,text[],text)',
       'public.claim_storage_purge(int)',
       'public.finish_storage_purge(text,text[])',
       'public.abort_storage_purge(text,uuid,text[])',
       'public.clear_storage_purge_for_user(uuid)',
       'public.detach_account_storage_owner(uuid)'
     ]) as f),
  false,
  'clients (anon and authenticated) cannot execute any purge RPC'
);
select is(
  has_function_privilege('anon', 'public.enqueue_storage_purge(text,uuid,text[])', 'execute'),
  false,
  'anon cannot enqueue'
);
select is(
  has_function_privilege('anon', 'public.finish_storage_purge(text,text[])', 'execute'),
  false,
  'anon cannot finish'
);
select is(
  has_function_privilege('anon', 'public.detach_account_storage_owner(uuid)', 'execute')
    or has_function_privilege('authenticated', 'public.detach_account_storage_owner(uuid)', 'execute'),
  false,
  'clients cannot detach storage owners'
);
select is(
  (select bool_and(has_function_privilege('service_role', f, 'execute'))
     from unnest(array[
       'public.enqueue_storage_purge(text,uuid,text[])',
       'public.fail_storage_purge(text,text[],text)',
       'public.claim_storage_purge(int)',
       'public.finish_storage_purge(text,text[])',
       'public.abort_storage_purge(text,uuid,text[])',
       'public.clear_storage_purge_for_user(uuid)',
       'public.detach_account_storage_owner(uuid)'
     ]) as f),
  true,
  'service_role can execute every purge RPC'
);

-- enqueue: distinct, idempotent.
select is(
  public.enqueue_storage_purge('media', '17000000-0000-4000-8000-000000000009',
    array['avatars/u/a.jpg', 'avatars/u/a.jpg', 'checkins/j/u/c.jpg']),
  2,
  'enqueue records each distinct path once'
);
select is(
  public.enqueue_storage_purge('media', '17000000-0000-4000-8000-000000000009', array['avatars/u/a.jpg']),
  1,
  'enqueueing a queued path again re-stamps it (still one row)'
);
select is((select count(*)::int from private.pending_storage_purge), 2, 'no duplicate rows');

-- claim: only paths of accounts that are gone; limit honoured.
select is((select count(*)::int from public.claim_storage_purge(1)), 1, 'claim honours the limit');
do $$ begin
  perform public.enqueue_storage_purge('media', '17000000-0000-4000-8000-000000000001', array['avatars/live/x.jpg']);
end $$;
select is(
  (select count(*)::int from public.claim_storage_purge(10) where path = 'avatars/live/x.jpg'),
  0,
  'a path of a still-existing account is never claimed'
);

-- fail: back off and give up after 20 attempts.
do $$ begin
  perform public.fail_storage_purge('media', array['avatars/u/a.jpg'], 'boom');
end $$;
select is(
  (select count(*)::int from public.claim_storage_purge(10) where path = 'avatars/u/a.jpg'),
  0,
  'a failed path waits for its next attempt'
);
update private.pending_storage_purge set next_attempt_at = now() - interval '1 minute' where path = 'avatars/u/a.jpg';
select is(
  (select count(*)::int from public.claim_storage_purge(10) where path = 'avatars/u/a.jpg'),
  1,
  'it is claimable again once due'
);
update private.pending_storage_purge set attempts = 20, next_attempt_at = now() - interval '1 minute'
 where path = 'avatars/u/a.jpg';
select is(
  (select count(*)::int from public.claim_storage_purge(10) where path = 'avatars/u/a.jpg'),
  0,
  'after 20 attempts the row is left for manual handling'
);
select is(
  (select attempts from private.pending_storage_purge where path = 'checkins/j/u/c.jpg'),
  0,
  'untouched rows keep attempts = 0 and are claimed first'
);

-- enqueue conflicts: a row of a GONE user is kept (that deletion still owes the purge), a row of a
-- user that still exists is re-stamped, the same user's own row is reset.
do $$ begin
  perform public.enqueue_storage_purge('media', '17000000-0000-4000-8000-000000000009', array['avatars/shared/s.jpg']);
  perform public.enqueue_storage_purge('media', '17000000-0000-4000-8000-000000000001', array['avatars/shared/s.jpg']);
  perform public.enqueue_storage_purge('media', '17000000-0000-4000-8000-000000000001', array['avatars/own/o.jpg']);
  perform public.enqueue_storage_purge('media', '17000000-0000-4000-8000-000000000009', array['avatars/own/o.jpg']);
end $$;
select is(
  (select user_id from private.pending_storage_purge where path = 'avatars/shared/s.jpg'),
  '17000000-0000-4000-8000-000000000009'::uuid,
  'a row of a gone user keeps its user when a live user enqueues the path'
);
select is(
  (select count(*)::int from public.claim_storage_purge(10) where path = 'avatars/shared/s.jpg'),
  1,
  'the kept row is still claimable (its deletion owes the purge)'
);
select is(
  (select user_id from private.pending_storage_purge where path = 'avatars/own/o.jpg'),
  '17000000-0000-4000-8000-000000000009'::uuid,
  'a row of a user that still exists is re-stamped by the new user'
);

-- clear: drops only this user's rows (delete action, after getUser proved the account is alive).
select is(
  public.clear_storage_purge_for_user('17000000-0000-4000-8000-000000000001'),
  1,
  'clear removes the rows stamped with the user (the live/x.jpg row)'
);
select is(
  (select count(*)::int from private.pending_storage_purge where user_id = '17000000-0000-4000-8000-000000000001'),
  0,
  'no row of that user is left'
);

-- abort only drops the given user's rows.
select is(
  public.abort_storage_purge('media', '17000000-0000-4000-8000-000000000009', array['avatars/shared/s.jpg', 'checkins/j/u/c.jpg']),
  2,
  'abort removes the rows stamped with that user'
);
select is(
  public.abort_storage_purge('media', '17000000-0000-4000-8000-000000000001', array['avatars/u/a.jpg']),
  0,
  'abort never touches another user''s rows'
);

-- finish removes.
select is(
  public.finish_storage_purge('media', array['avatars/u/a.jpg', 'checkins/j/u/c.jpg', 'avatars/live/x.jpg']),
  1,
  'finish removes the purged paths'
);

select * from finish();
rollback;
