# Storage purge after account deletion

`delete-account` queues every storage path of the user in `private.pending_storage_purge`
(migration 0017; service role only), deletes the auth user, then removes the objects and dequeues
each path it removed. A crash, a timeout or a failed removal leaves the paths queued.

- Inspect (SQL editor): `select * from private.pending_storage_purge order by next_attempt_at;`
- Rows are only claimed once their account is gone (a delete-account that died before `deleteUser`
  never gets a live account's files swept). Failures back off (1 min, 2, 4 ... capped at 1 day) and a
  row is given up on after 20 attempts: it stays in the table with `attempts = 20` and `last_error`,
  and is excluded from claims.
- Retry: `POST /functions/v1/storage-purge-sweep` with header `x-sweep-token: <SWEEP_TOKEN>`
  (`supabase secrets set SWEEP_TOKEN=...`). Each call handles up to 200 due paths. Repeat until
  `claimed` is 0: that terminates because failed rows back off (not due again) and given-up rows are
  never claimed, so a rerun after the backoff picks up what is left.
- Manual handling of given-up rows: `select * from private.pending_storage_purge where attempts >= 20;`
  fix the cause (usually a Storage outage), then `update private.pending_storage_purge set attempts = 0,
  next_attempt_at = now() where attempts >= 20;` and run the sweep again. Delete rows whose objects were
  removed by hand.
- There is no scheduler in this repo (no pg_cron or schedule pattern). Until one is configured
  (Dashboard > Edge Functions > Schedule, or pg_cron + pg_net calling the function), run the sweep by
  hand after any `storage remove failed` log line of `delete-account` and at least weekly.
- If `enqueue_storage_purge failed` (before `deleteUser`) appears the deletion was aborted with
  `storage_cleanup_failed` and can be retried. If `deleteUser failed` appears the queued paths stay
  (they are never claimed while the account exists, and a retry re-stamps them).
- If `second pass paths could not be queued` or `second pass listing failed` appears, or paths exist
  only in the logs, re-run the listing by hand: the folder-based listings still resolve after the
  user is gone. In the SQL editor (service role), for the deleted user id `<uid>`:
  `select public.enqueue_storage_purge('media', '<uid>', array(select public.account_media_paths('<uid>')));`
  and the same with `'messages'` / `public.account_message_paths('<uid>')` (it also needs the
  conversations to still exist, so objects of conversations that cascaded away may only be found by
  listing `storage.objects` under `messages/` manually). Then run the sweep.
- A deleted account that calls `delete-account` again gets `410 already_deleted`. The function only
  answers 410 after `getUser` failed AND `auth.admin.getUserById(sub)` (the `sub` of the JWT, whose
  signature the gateway verified: `verify_jwt = true`) reports the user missing (404 / `user_not_found`).
  A revoked or expired session (`session_not_found`, "Session from session_id claim in JWT does not
  exist") stays 401, and a failing lookup is 503. The client reads only 410 as "already deleted".
- Queue rules (migration 0017): the delete action first clears every row stamped with the user (the
  account is proven alive, so such rows are stale), then queues the listing. A path already queued by a
  user that no longer exists keeps that user (its deletion still owes the purge); a path queued by a
  user that still exists is re-stamped by the new one.
- Owner FK: `storage.objects.owner` may reference `auth.users` depending on the Storage version (the
  repo's migrations and config do not show it). `delete-account` calls
  `detach_account_storage_owner` right before `deleteUser`, so deletion works either way.
