-- 0017_pending_storage_purge: storage objects of deleted accounts that still have to be removed.
--
-- delete-account lists the user's storage objects, queues EVERY path here, deletes the auth user,
-- removes the objects and dequeues each path it removed. A crash, a timeout or a failed removal
-- therefore leaves the paths queued; the storage-purge-sweep Edge Function (or the runbook in
-- docs/runbooks/storage-purge.md) retries them later. Service role only: RLS is on with no
-- policies, nothing is granted to anon or authenticated, and the RPC wrappers below are
-- executable by service_role only.
--
-- Safety: rows carry the owning user_id and are only claimed once that auth user is gone, so a
-- delete-account that died before deleteUser can never get a live account's files swept.
-- Retries back off exponentially and a row is given up on after 20 attempts (it stays for manual
-- handling, see the runbook, and is excluded from claims).
-- No extra index: the table only holds the leftovers of failed deletions (a handful of rows).

create table private.pending_storage_purge (
  bucket text not null check (bucket in ('media', 'messages')),
  path text not null check (length(path) between 1 and 1024),
  user_id uuid not null,
  created_at timestamptz not null default now(),
  attempts int not null default 0,
  next_attempt_at timestamptz not null default now(),
  last_error text,
  primary key (bucket, path)
);
alter table private.pending_storage_purge enable row level security;
revoke all on private.pending_storage_purge from public, anon, authenticated;
grant select, insert, update, delete on private.pending_storage_purge to service_role;

-- Queues paths for [p_user]. A path that is already queued is re-stamped with this user (retry
-- state reset) when the existing row is this user's own or belongs to a user that still exists: a
-- stale row of a live account must not stay claimable. A row of a user that is already gone is
-- kept as it is: that earlier deletion still owes the purge, and re-stamping it onto a live user
-- would hide it (and an abort of this run would drop it).
create function public.enqueue_storage_purge(p_bucket text, p_user uuid, p_paths text[])
returns int
language plpgsql
security definer
set search_path = ''
as $$
declare
  n int;
begin
  insert into private.pending_storage_purge (bucket, path, user_id)
  select distinct p_bucket, p, p_user
    from unnest(p_paths) as p
   where p is not null and length(p) between 1 and 1024
  on conflict (bucket, path) do update
    set user_id = excluded.user_id,
        attempts = 0,
        next_attempt_at = now(),
        last_error = null
    where private.pending_storage_purge.user_id = excluded.user_id
       or exists (select 1 from auth.users u where u.id = private.pending_storage_purge.user_id);
  get diagnostics n = row_count;
  return n;
end;
$$;

-- delete-account (delete action) first drops every row stamped with the user: getUser has just
-- proved the account is alive, so any such row is stale and must not become claimable later.
create function public.clear_storage_purge_for_user(p_user uuid)
returns int
language plpgsql
security definer
set search_path = ''
as $$
declare
  n int;
begin
  -- Only while the account still exists, checked in the same statement: a
  -- concurrent delete may already have removed it and left rows to sweep.
  delete from private.pending_storage_purge
   where user_id = p_user
     and exists (select 1 from auth.users u where u.id = p_user);
  get diagnostics n = row_count;
  return n;
end;
$$;

-- delete-account gave up before deleting the user: drop only THIS user's queued paths.
create function public.abort_storage_purge(p_bucket text, p_user uuid, p_paths text[])
returns int
language plpgsql
security definer
set search_path = ''
as $$
declare
  n int;
begin
  delete from private.pending_storage_purge
   where bucket = p_bucket and user_id = p_user and path = any (p_paths);
  get diagnostics n = row_count;
  return n;
end;
$$;

-- A removal failed: count the attempt and back off (1 min, 2, 4 ... capped at 1 day).
create function public.fail_storage_purge(p_bucket text, p_paths text[], p_error text default null)
returns int
language plpgsql
security definer
set search_path = ''
as $$
declare
  n int;
begin
  update private.pending_storage_purge
     set attempts = attempts + 1,
         next_attempt_at = now() + least(interval '1 day', interval '1 minute' * power(2, least(attempts, 20))),
         last_error = left(p_error, 500)
   where bucket = p_bucket and path = any (p_paths);
  get diagnostics n = row_count;
  return n;
end;
$$;

-- Due paths of accounts that are really gone, least-tried first, for one sweep run. Rows that
-- reached 20 attempts are excluded (manual handling).
create function public.claim_storage_purge(p_limit int default 200)
returns table (bucket text, path text)
language sql
stable
security definer
set search_path = ''
as $$
  select s.bucket, s.path
    from private.pending_storage_purge s
   where s.attempts < 20
     and s.next_attempt_at <= now()
     and not exists (select 1 from auth.users u where u.id = s.user_id)
   order by s.next_attempt_at, s.attempts, s.created_at
   limit greatest(1, least(coalesce(p_limit, 200), 1000));
$$;

-- Forgets paths that were removed (or never existed).
create function public.finish_storage_purge(p_bucket text, p_paths text[])
returns int
language plpgsql
security definer
set search_path = ''
as $$
declare
  n int;
begin
  delete from private.pending_storage_purge
   where bucket = p_bucket and path = any (p_paths);
  get diagnostics n = row_count;
  return n;
end;
$$;

-- Objects uploaded through the Storage API carry owner = auth.uid(). Depending on the Storage
-- version storage.objects.owner may reference auth.users (then auth.admin.deleteUser fails while
-- objects exist) or not. delete-account calls this right before deleteUser so it works either
-- way; the objects themselves are removed afterwards via the Storage API.
create function public.detach_account_storage_owner(p_user uuid)
returns int
language plpgsql
security definer
set search_path = ''
as $$
declare
  n int := 0;
  has_owner_id boolean;
begin
  update storage.objects set owner = null where owner = p_user;
  get diagnostics n = row_count;
  select exists (
    select 1 from information_schema.columns
     where table_schema = 'storage' and table_name = 'objects' and column_name = 'owner_id'
  ) into has_owner_id;
  if has_owner_id then
    execute 'update storage.objects set owner_id = null where owner_id = $1' using p_user::text;
  end if;
  return n;
end;
$$;

revoke all on function
  public.enqueue_storage_purge(text, uuid, text[]),
  public.fail_storage_purge(text, text[], text),
  public.claim_storage_purge(int),
  public.finish_storage_purge(text, text[]),
  public.abort_storage_purge(text, uuid, text[]),
  public.clear_storage_purge_for_user(uuid),
  public.detach_account_storage_owner(uuid)
from public, anon, authenticated;
grant execute on function
  public.enqueue_storage_purge(text, uuid, text[]),
  public.fail_storage_purge(text, text[], text),
  public.claim_storage_purge(int),
  public.finish_storage_purge(text, text[]),
  public.abort_storage_purge(text, uuid, text[]),
  public.clear_storage_purge_for_user(uuid),
  public.detach_account_storage_owner(uuid)
to service_role;
