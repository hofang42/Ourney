-- 0024_feature_requests: In-App Feature Requests & Public Roadmap Board (Batch 1).
--
-- Spec: reports/feature-requests-spec.md §4 + binding amendments in fr-opus-review.md (F1-F6):
--   - Tables:
--       1. `public.feature_requests` (contract table #21 in schema `public`)
--       2. `public.feature_request_votes` (contract table #22 in schema `public`)
--       3. `private.feature_request_notifications` (service_role only, RLS enabled)
--   - Moderation & UGC compliance (Apple Guideline 1.2 & Google Play UGC):
--       * `target_feature_request_id` on `public.reports` and `public.moderation_queue`
--       * Bilingual content filter (`private.assert_clean_text` from 0020) on `title`, `body`, `admin_reply`
--       * URL spam guard (`links_not_allowed`, SQLSTATE 23514) on `title` and `body`
--       * F3 role-check immutability guard (`coalesce(nullif(current_setting('role', true), ''), session_user) in ('authenticated', 'anon')`)
--       * Immediate hide for reporter (`private.has_reported_feature_request`), bidirectional block filter (`private.is_blocked_pair`),
--         and auto-quarantine (`hidden = true, moderated_at = now()`) at >= 2 distinct open reporters or 1st `nudity`/`self_harm` report
--       * Unified ban model from 0023 (`private.is_user_banned` / `private.caller_is_banned`; bans never set `profiles.deleted_at`)
--   - App RPCs (`schema public`, §4.4A):
--       `list_feature_requests`, `get_feature_request`, `search_similar_feature_requests`,
--       `create_feature_request`, `update_feature_request`, `delete_feature_request`,
--       `toggle_feature_request_vote`, `report_feature_request`,
--       `my_shipped_request_notifications`, `mark_shipped_requests_seen`,
--       plus `inbox_counts` (`shipped_requests`) and `purge_account_data` updates.
--   - Admin RPCs (`schema admin`, §4.4B & F1-F2, reusing `private.require_admin` + `private.admin_log` from 0023):
--       `admin.feature_request_stats`, `admin.list_feature_requests`,
--       `admin.get_feature_request_detail`, `admin.update_feature_request`,
--       `admin.merge_feature_request`, plus moderation queue extensions for `target_feature_request_id`.
--
-- Idempotent (create or replace, drop if exists, if not exists).

-- ---------------------------------------------------------------------------
-- 1. Extensions & Vietnamese Diacritic Folding Helper
-- ---------------------------------------------------------------------------
create extension if not exists pg_trgm with schema extensions;

create or replace function private.fold_vi(p_text text) returns text
language sql
immutable
security definer
set search_path = ''
as $$
  select case
    when p_text is null then ''
    else translate(
      lower(normalize(
        translate(p_text, U&'\00ad\200b\200c\200d\200e\200f\2060\feff', ''),
        NFC
      )),
      'àáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ',
      'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd'
    )
  end;
$$;

revoke all on function private.fold_vi(text) from public, anon, authenticated;
grant execute on function private.fold_vi(text) to service_role;

-- ---------------------------------------------------------------------------
-- 2. Schema DDL: `public.feature_requests`, `public.feature_request_votes`,
--                `private.feature_request_notifications`, and report columns
-- ---------------------------------------------------------------------------
create table if not exists public.feature_requests (
  id uuid primary key default gen_random_uuid(),
  -- Nullable with ON DELETE SET NULL so popular/planned/shipped community ideas survive
  -- if the original author deletes their account (PII is erased; solo 'new'/'declined'
  -- requests by that user are deleted in purge_account_data).
  author_id uuid references public.profiles (id) on delete set null,
  title text not null
    check (char_length(btrim(title)) between 6 and 80),
  body text not null
    check (char_length(btrim(body)) between 10 and 1000),
  category text not null default 'other'
    check (category in ('camera', 'journeys', 'squad', 'sharing', 'design', 'other')),
  status text not null default 'new'
    check (status in ('new', 'under_review', 'planned', 'in_progress', 'shipped', 'declined')),
  admin_reply text
    check (admin_reply is null or char_length(btrim(admin_reply)) between 1 and 1000),
  admin_replied_at timestamptz,
  shipped_at timestamptz,
  vote_count int not null default 0 check (vote_count >= 0),
  duplicate_of uuid references public.feature_requests (id) on delete set null
    check (duplicate_of is null or duplicate_of <> id),
  hidden boolean not null default false,
  moderated_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists feature_requests_popular_idx
  on public.feature_requests (vote_count desc, created_at desc, id desc)
  where not hidden and duplicate_of is null;

create index if not exists feature_requests_new_idx
  on public.feature_requests (created_at desc, id desc)
  where not hidden and duplicate_of is null;

create index if not exists feature_requests_status_idx
  on public.feature_requests (status, vote_count desc, updated_at desc)
  where not hidden and duplicate_of is null;

create index if not exists feature_requests_author_idx
  on public.feature_requests (author_id, created_at desc)
  where author_id is not null;

create index if not exists feature_requests_duplicate_of_idx
  on public.feature_requests (duplicate_of)
  where duplicate_of is not null;

create index if not exists feature_requests_title_trgm_idx
  on public.feature_requests using gin (lower(title) extensions.gin_trgm_ops)
  where not hidden and duplicate_of is null;

create table if not exists public.feature_request_votes (
  request_id uuid not null references public.feature_requests (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (request_id, user_id)
);

create index if not exists feature_request_votes_user_idx
  on public.feature_request_votes (user_id, created_at desc);

create table if not exists private.feature_request_notifications (
  user_id uuid not null references public.profiles (id) on delete cascade,
  request_id uuid not null references public.feature_requests (id) on delete cascade,
  is_author boolean not null default false,
  created_at timestamptz not null default now(),
  seen_at timestamptz,
  pushed_at timestamptz,
  primary key (user_id, request_id)
);

create index if not exists feature_request_notifications_unseen_idx
  on private.feature_request_notifications (user_id, created_at desc)
  where seen_at is null;

create index if not exists feature_request_notifications_request_idx
  on private.feature_request_notifications (request_id);

alter table private.feature_request_notifications enable row level security;
revoke all on private.feature_request_notifications from public, anon, authenticated;
grant select, insert, update, delete on private.feature_request_notifications to service_role;

alter table public.reports
  add column if not exists target_feature_request_id uuid
    references public.feature_requests (id) on delete set null;

-- Per 0001_core.sql:207 ("Snapshot ids are kept without FKs so evidence survives the target's
-- account deletion"), moderation_queue target columns do NOT use ON DELETE SET NULL FKs.
alter table public.moderation_queue
  add column if not exists target_feature_request_id uuid;

alter table public.moderation_queue
  drop constraint if exists moderation_queue_target_feature_request_id_fkey;

create index if not exists reports_target_feature_request_idx
  on public.reports (target_feature_request_id)
  where target_feature_request_id is not null;

create index if not exists reports_reporter_feature_request_idx
  on public.reports (reporter_id, target_feature_request_id)
  where deleted_at is null and target_feature_request_id is not null;

create index if not exists moderation_queue_target_feature_request_idx
  on public.moderation_queue (target_feature_request_id)
  where target_feature_request_id is not null;

-- ---------------------------------------------------------------------------
-- 3. Triggers: Vote Count Sync, Content Filter, URL Guard & Immutability (F3)
-- ---------------------------------------------------------------------------
create or replace function private.feature_requests_before_write() returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  -- Amendment F3: follow 0018 role-check pattern for direct client write detection.
  -- Privileged internal writes (vote sync, admin triage/merge, moderation quarantine)
  -- set transaction-local GUC `ourney.fr_internal_write = 'on'` for the duration of their statement.
  v_is_client_write boolean :=
    coalesce(nullif(nullif(current_setting('role', true), ''), 'none'), session_user) in ('authenticated', 'anon')
    and coalesce(current_setting('ourney.fr_internal_write', true), '') <> 'on';
  v_url_pattern constant text := '(https?://|www\.[a-z0-9-]+|\m[a-z0-9-]+\.(com|net|org|io|vn|xyz|me|app|gg)(/|\M))';
begin
  if v_is_client_write then
    if not exists (
      select 1 from public.profiles p
       where p.id = coalesce((select auth.uid()), new.author_id)
         and p.deleted_at is null
    ) or private.caller_is_banned() then
      raise exception 'forbidden' using errcode = '42501';
    end if;

    if tg_op = 'INSERT' then
      if new.author_id is distinct from (select auth.uid())
         or new.status <> 'new'
         or new.admin_reply is not null
         or new.admin_replied_at is not null
         or new.shipped_at is not null
         or new.vote_count <> 0
         or new.duplicate_of is not null
         or new.hidden
         or new.moderated_at is not null then
        raise exception 'forbidden' using errcode = '42501';
      end if;
    elsif tg_op = 'UPDATE' then
      if new.id is distinct from old.id
         or new.author_id is distinct from old.author_id
         or new.status is distinct from old.status
         or new.admin_reply is distinct from old.admin_reply
         or new.admin_replied_at is distinct from old.admin_replied_at
         or new.shipped_at is distinct from old.shipped_at
         or new.vote_count is distinct from old.vote_count
         or new.duplicate_of is distinct from old.duplicate_of
         or new.hidden is distinct from old.hidden
         or new.moderated_at is distinct from old.moderated_at
         or new.created_at is distinct from old.created_at then
        raise exception 'immutable_column' using errcode = '23514';
      end if;

      if old.status <> 'new'
         or old.hidden
         or old.duplicate_of is not null
         or old.moderated_at is not null
         or exists (
           select 1 from public.feature_requests child
            where child.duplicate_of = old.id
         )
         or exists (
           select 1 from public.reports r
            where r.target_feature_request_id = old.id
              and r.deleted_at is null
              and r.status = 'open'
         )
         or exists (
           select 1 from public.moderation_queue mq
            where mq.target_feature_request_id = old.id
              and mq.status = 'open'
         ) then
        raise exception 'forbidden' using errcode = '42501';
      end if;

      -- Enforce 20 / 1h edit rate limit even on direct PostgREST table UPDATEs (P2-1).
      if coalesce(current_setting('ourney.fr_edit_rate_checked', true), '') <> 'on' then
        perform 1
          from public.profiles p
         where p.id = old.author_id
           and p.deleted_at is null
           for no key update;
        if not found then
          raise exception 'forbidden' using errcode = '42501';
        end if;

        delete from private.rate_events
         where user_id = old.author_id
           and at < now() - interval '1 day';

        if (
          select count(*)
            from private.rate_events
           where user_id = old.author_id
             and kind = 'feature_request_edit'
             and at > now() - interval '1 hour'
        ) >= 20 then
          raise exception 'rate_limited' using errcode = 'P0001';
        end if;
      end if;
    end if;
  end if;

  if new.title is not null then
    new.title := btrim(new.title);
  end if;
  if new.body is not null then
    new.body := btrim(new.body);
  end if;
  if new.admin_reply is not null then
    new.admin_reply := nullif(btrim(new.admin_reply), '');
  end if;

  if new.title is null or char_length(new.title) not between 6 and 80 then
    raise exception 'invalid' using errcode = '23514';
  end if;
  if new.body is null or char_length(new.body) not between 10 and 1000 then
    raise exception 'invalid' using errcode = '23514';
  end if;
  if new.admin_reply is not null and char_length(new.admin_reply) not between 1 and 1000 then
    raise exception 'invalid' using errcode = '23514';
  end if;

  -- URL spam guard on title and body (insert or change), stripping zero-width chars first.
  if tg_op = 'INSERT' or new.title is distinct from old.title then
    if translate(new.title, U&'\00ad\200b\200c\200d\200e\200f\2060\feff', '') ~* v_url_pattern then
      raise exception 'links_not_allowed' using errcode = '23514';
    end if;
    perform private.assert_clean_text(new.title);
  end if;

  if tg_op = 'INSERT' or new.body is distinct from old.body then
    if translate(new.body, U&'\00ad\200b\200c\200d\200e\200f\2060\feff', '') ~* v_url_pattern then
      raise exception 'links_not_allowed' using errcode = '23514';
    end if;
    perform private.assert_clean_text(new.body);
  end if;

  if new.admin_reply is not null
     and (tg_op = 'INSERT' or new.admin_reply is distinct from old.admin_reply) then
    perform private.assert_clean_text(new.admin_reply);
  end if;

  -- Merge chain guard: canonical target cannot itself be a duplicate, and a parent with children cannot become a duplicate.
  if new.duplicate_of is not null then
    if new.duplicate_of = new.id then
      raise exception 'invalid' using errcode = '23514';
    end if;
    if not exists (
      select 1 from public.feature_requests target
       where target.id = new.duplicate_of
         and target.duplicate_of is null
    ) or exists (
      select 1 from public.feature_requests child
       where child.duplicate_of = new.id
         and child.id <> new.id
    ) then
      raise exception 'invalid' using errcode = '23514';
    end if;
  end if;

  if v_is_client_write
     and tg_op = 'UPDATE'
     and coalesce(current_setting('ourney.fr_edit_rate_checked', true), '') <> 'on' then
    insert into private.rate_events (user_id, kind)
    values (old.author_id, 'feature_request_edit');
  end if;

  if tg_op = 'INSERT' then
    new.created_at := coalesce(new.created_at, now());
    new.updated_at := coalesce(new.updated_at, new.created_at);
  elsif tg_op = 'UPDATE' then
    -- Bump updated_at only when substantive content or state changes (not on vote_count sync).
    if new.title is distinct from old.title
       or new.body is distinct from old.body
       or new.category is distinct from old.category
       or new.status is distinct from old.status
       or new.admin_reply is distinct from old.admin_reply
       or new.admin_replied_at is distinct from old.admin_replied_at
       or new.shipped_at is distinct from old.shipped_at
       or new.duplicate_of is distinct from old.duplicate_of
       or new.hidden is distinct from old.hidden
       or new.moderated_at is distinct from old.moderated_at then
      new.updated_at := now();
    else
      new.updated_at := old.updated_at;
    end if;
  end if;

  return new;
end;
$$;

revoke all on function private.feature_requests_before_write() from public, anon, authenticated;

drop trigger if exists feature_requests_updated on public.feature_requests;
drop trigger if exists feature_requests_before_write on public.feature_requests;
create trigger feature_requests_before_write
  before insert or update on public.feature_requests
  for each row execute function private.feature_requests_before_write();

create or replace function private.sync_feature_request_vote_count() returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_target_id uuid := case when tg_op = 'INSERT' then new.request_id else old.request_id end;
  v_cnt int := 0;
  v_prev_flag text := coalesce(current_setting('ourney.fr_internal_write', true), '');
begin
  -- P1-1: Acquire FOR NO KEY UPDATE on the parent feature_requests row in a separate statement
  -- before counting feature_request_votes. Under READ COMMITTED, the subsequent SELECT count(*)
  -- takes a fresh snapshot after the row lock is held, preventing concurrent lost-update drift.
  -- If the parent row is gone (e.g. ON DELETE CASCADE when deleting a feature request), skip.
  perform 1 from public.feature_requests where id = v_target_id for no key update;
  if not found then
    return null;
  end if;

  select count(*)::int into v_cnt
    from public.feature_request_votes v
   where v.request_id = v_target_id;

  perform set_config('ourney.fr_internal_write', 'on', true);
  update public.feature_requests fr
     set vote_count = v_cnt
   where fr.id = v_target_id
     and fr.vote_count is distinct from v_cnt;
  perform set_config('ourney.fr_internal_write', v_prev_flag, true);
  return null;
end;
$$;

revoke all on function private.sync_feature_request_vote_count() from public, anon, authenticated;

drop trigger if exists feature_request_votes_sync_count on public.feature_request_votes;
create trigger feature_request_votes_sync_count
  after insert or delete on public.feature_request_votes
  for each row execute function private.sync_feature_request_vote_count();

-- ---------------------------------------------------------------------------
-- 4. Row-Level Security (RLS) & Privilege Matrix (§4.3)
-- ---------------------------------------------------------------------------
alter table public.feature_requests enable row level security;
alter table public.feature_request_votes enable row level security;

revoke all on public.feature_requests, public.feature_request_votes from public, anon, authenticated;

grant select on public.feature_requests, public.feature_request_votes to authenticated;
grant update (title, body, category) on public.feature_requests to authenticated;
grant select, insert, update, delete on public.feature_requests, public.feature_request_votes to service_role;

create or replace function private.has_reported_feature_request(p_request uuid) returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.reports r
     where r.target_feature_request_id = p_request
       and r.reporter_id = (select auth.uid())
       and r.deleted_at is null
  );
$$;

revoke all on function private.has_reported_feature_request(uuid) from public, anon;
grant execute on function private.has_reported_feature_request(uuid) to authenticated, service_role;

drop policy if exists feature_requests_select on public.feature_requests;
create policy feature_requests_select on public.feature_requests
  for select to authenticated
  using (
    not private.caller_is_banned()
    and exists (
      select 1 from public.profiles p
       where p.id = (select auth.uid()) and p.deleted_at is null
    )
    and not hidden
    and (
      author_id = (select auth.uid())
      or (
        status <> 'declined'
        and (author_id is null or not private.is_blocked_pair(author_id))
        and not private.has_reported_feature_request(id)
      )
    )
  );

drop policy if exists feature_requests_update_own_new on public.feature_requests;
create policy feature_requests_update_own_new on public.feature_requests
  for update to authenticated
  using (
    author_id = (select auth.uid())
    and not private.caller_is_banned()
    and exists (
      select 1 from public.profiles p
       where p.id = (select auth.uid()) and p.deleted_at is null
    )
  )
  with check (
    author_id = (select auth.uid())
    and status = 'new'
    and not hidden
    and duplicate_of is null
    and not private.caller_is_banned()
  );

drop policy if exists feature_request_votes_select_own on public.feature_request_votes;
create policy feature_request_votes_select_own on public.feature_request_votes
  for select to authenticated
  using (
    user_id = (select auth.uid())
    and not private.caller_is_banned()
  );

-- ---------------------------------------------------------------------------
-- 5. Hydrated JSON Serializer (`private.feature_request_json`)
-- ---------------------------------------------------------------------------
-- Never exposes author email or private avatar_path (spec §1.3 #5).
create or replace function private.feature_request_json(
  fr public.feature_requests,
  p_viewer uuid
) returns json
language sql
stable
security definer
set search_path = ''
as $$
  select json_build_object(
    'id', fr.id,
    'title', fr.title,
    'body', fr.body,
    'category', fr.category,
    'status', fr.status,
    'vote_count', fr.vote_count,
    'voted_by_me', (
      p_viewer is not null
      and exists (
        select 1 from public.feature_request_votes v
         where v.request_id = fr.id and v.user_id = p_viewer
      )
    ),
    'is_mine', (p_viewer is not null and fr.author_id = p_viewer),
    'author', case
      when fr.author_id is not null then (
        select json_build_object(
          'user_id', p.id,
          'username', p.username,
          'display_name', p.display_name
        )
        from public.profiles p
        where p.id = fr.author_id and p.deleted_at is null
      )
      else null
    end,
    'admin_reply', fr.admin_reply,
    'admin_replied_at', fr.admin_replied_at,
    'shipped_at', fr.shipped_at,
    'duplicate_of', fr.duplicate_of,
    'canonical_title', case
      when fr.duplicate_of is not null then (
        select c.title
          from public.feature_requests c
         where c.id = fr.duplicate_of
           and not c.hidden
           and (
             (p_viewer is not null and c.author_id = p_viewer)
             or (
               c.status <> 'declined'
               and (p_viewer is null or c.author_id is null or not private.blocked_between(p_viewer, c.author_id))
               and (
                 p_viewer is null
                 or not exists (
                   select 1 from public.reports r
                    where r.target_feature_request_id = c.id
                      and r.reporter_id = p_viewer
                      and r.deleted_at is null
                 )
               )
             )
           )
      )
      else null
    end,
    'created_at', fr.created_at,
    'updated_at', fr.updated_at
  );
$$;

revoke all on function private.feature_request_json(public.feature_requests, uuid) from public, anon, authenticated;
grant execute on function private.feature_request_json(public.feature_requests, uuid) to service_role;

-- ---------------------------------------------------------------------------
-- 6. App-Side RPCs (`schema public`, §4.4A)
-- ---------------------------------------------------------------------------
create or replace function public.list_feature_requests(
  p_tab text default 'popular',
  p_category text default null,
  p_search text default null,
  p_mine_only boolean default false,
  p_limit int default 30,
  p_offset int default 0
) returns setof json
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  uid uuid := public._uid();
  v_tab text := coalesce(nullif(lower(btrim(p_tab)), ''), 'popular');
  v_cat text := nullif(lower(btrim(coalesce(p_category, ''))), '');
  v_search text := nullif(btrim(coalesce(p_search, '')), '');
  v_folded_search text := case when v_search is not null then private.fold_vi(v_search) else null end;
  v_mine boolean := coalesce(p_mine_only, false);
  v_limit int := greatest(1, least(coalesce(p_limit, 30), 100));
  v_offset int := greatest(0, coalesce(p_offset, 0));
begin
  if not exists (select 1 from public.profiles p where p.id = uid and p.deleted_at is null) then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  if not v_mine and v_tab not in ('popular', 'new', 'planned', 'shipped') then
    raise exception 'invalid' using errcode = 'P0001';
  end if;

  if v_cat is not null and v_cat <> 'all'
     and v_cat not in ('camera', 'journeys', 'squad', 'sharing', 'design', 'other') then
    raise exception 'invalid' using errcode = 'P0001';
  end if;

  return query
  select private.feature_request_json(fr, uid)
    from public.feature_requests fr
   where not fr.hidden
     and (
       case
         when v_mine then fr.author_id = uid
         else
           fr.duplicate_of is null
           and (fr.author_id is null or not private.is_blocked_pair(fr.author_id))
           and not private.has_reported_feature_request(fr.id)
           and (
             (v_tab in ('popular', 'new') and fr.status in ('new', 'under_review', 'planned', 'in_progress'))
             or (v_tab = 'planned' and fr.status in ('planned', 'in_progress'))
             or (v_tab = 'shipped' and fr.status = 'shipped')
           )
       end
     )
     and (v_cat is null or v_cat = 'all' or fr.category = v_cat)
     and (
       v_folded_search is null
       or position(v_folded_search in private.fold_vi(fr.title)) > 0
       or position(v_folded_search in private.fold_vi(fr.body)) > 0
     )
   order by
     case when not v_mine and v_tab = 'planned' and fr.status = 'in_progress' then 0 else 1 end asc,
     case when not v_mine and v_tab in ('popular', 'planned') then fr.vote_count else 0 end desc,
     case when not v_mine and v_tab = 'shipped' then coalesce(fr.shipped_at, fr.updated_at) else fr.created_at end desc,
     fr.created_at desc,
     fr.id desc
   limit v_limit offset v_offset;
end;
$$;

create or replace function public.get_feature_request(p_id uuid) returns json
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  uid uuid := public._uid();
  fr public.feature_requests%rowtype;
begin
  if not exists (select 1 from public.profiles p where p.id = uid and p.deleted_at is null) then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  if p_id is null then
    raise exception 'not_found' using errcode = 'P0001';
  end if;

  select * into fr
    from public.feature_requests r
   where r.id = p_id
     and not r.hidden
     and (
       r.author_id = uid
       or (
         r.status <> 'declined'
         and (r.author_id is null or not private.is_blocked_pair(r.author_id))
         and not private.has_reported_feature_request(r.id)
       )
     );

  if not found then
    raise exception 'not_found' using errcode = 'P0001';
  end if;

  return private.feature_request_json(fr, uid);
end;
$$;

create or replace function public.search_similar_feature_requests(
  p_query text,
  p_limit int default 5
) returns setof json
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  uid uuid := public._uid();
  v_raw text := btrim(coalesce(p_query, ''));
  v_lower text := lower(v_raw);
  v_folded text := private.fold_vi(v_raw);
  v_limit int := greatest(1, least(coalesce(p_limit, 5), 10));
begin
  if not exists (select 1 from public.profiles p where p.id = uid and p.deleted_at is null) then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  if char_length(v_folded) < 3 then
    return;
  end if;

  return query
  select private.feature_request_json(fr, uid)
    from public.feature_requests fr
   where not fr.hidden
     and fr.duplicate_of is null
     and fr.status <> 'declined'
     and (fr.author_id is null or not private.is_blocked_pair(fr.author_id))
     and not private.has_reported_feature_request(fr.id)
     and (
       position(v_folded in private.fold_vi(fr.title)) > 0
       or extensions.word_similarity(v_lower, lower(fr.title)) >= 0.25
       or extensions.word_similarity(v_folded, private.fold_vi(fr.title)) >= 0.25
       or extensions.similarity(v_folded, private.fold_vi(fr.title)) >= 0.2
     )
   order by
     (position(v_folded in private.fold_vi(fr.title)) > 0) desc,
     greatest(
       extensions.word_similarity(v_lower, lower(fr.title)),
       extensions.word_similarity(v_folded, private.fold_vi(fr.title))
     ) desc,
     fr.vote_count desc,
     fr.created_at desc,
     fr.id desc
   limit v_limit;
end;
$$;

create or replace function public.create_feature_request(
  p_id uuid,
  p_title text,
  p_body text,
  p_category text default 'other'
) returns json
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := public._uid();
  v_cat text := coalesce(nullif(lower(btrim(p_category)), ''), 'other');
  fr public.feature_requests%rowtype;
begin
  if p_id is null then
    raise exception 'invalid' using errcode = 'P0001';
  end if;

  perform 1 from public.profiles p where p.id = uid and p.deleted_at is null for no key update;
  if not found then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  -- Idempotent retry with the same p_id by the same author; reject collision from another user.
  select * into fr from public.feature_requests where id = p_id;
  if found then
    if fr.author_id = uid and not fr.hidden then
      return private.feature_request_json(fr, uid);
    end if;
    raise exception 'forbidden' using errcode = '42501';
  end if;

  if v_cat not in ('camera', 'journeys', 'squad', 'sharing', 'design', 'other') then
    raise exception 'invalid' using errcode = 'P0001';
  end if;

  delete from private.rate_events where user_id = uid and at < now() - interval '1 day';
  if (
    select count(*) from private.rate_events
     where user_id = uid
       and kind = 'feature_request_create'
       and at > now() - interval '24 hours'
  ) >= 5 then
    raise exception 'rate_limited' using errcode = 'P0001';
  end if;

  insert into public.feature_requests (id, author_id, title, body, category, status)
  values (p_id, uid, btrim(p_title), btrim(p_body), v_cat, 'new')
  returning * into fr;

  -- Auto-cast the author's initial upvote (trigger updates vote_count = 1).
  insert into public.feature_request_votes (request_id, user_id)
  values (fr.id, uid)
  on conflict (request_id, user_id) do nothing;

  insert into private.rate_events (user_id, kind)
  values (uid, 'feature_request_create');

  select * into fr from public.feature_requests where id = p_id;
  return private.feature_request_json(fr, uid);
end;
$$;

create or replace function public.update_feature_request(
  p_id uuid,
  p_title text,
  p_body text,
  p_category text
) returns json
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := public._uid();
  v_cat text := lower(btrim(coalesce(p_category, '')));
  fr public.feature_requests%rowtype;
begin
  if p_id is null then
    raise exception 'invalid' using errcode = 'P0001';
  end if;

  perform 1 from public.profiles p where p.id = uid and p.deleted_at is null for no key update;
  if not found then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  select * into fr from public.feature_requests where id = p_id for update;
  if not found then
    raise exception 'not_found' using errcode = 'P0001';
  end if;

  if fr.author_id is distinct from uid
     or fr.status <> 'new'
     or fr.hidden
     or fr.duplicate_of is not null
     or fr.moderated_at is not null
     or exists (
       select 1 from public.feature_requests child
        where child.duplicate_of = p_id
     )
     or exists (
       select 1 from public.reports r
        where r.target_feature_request_id = p_id
          and r.deleted_at is null
          and r.status = 'open'
     )
     or exists (
       select 1 from public.moderation_queue mq
        where mq.target_feature_request_id = p_id
          and mq.status = 'open'
     ) then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  if v_cat not in ('camera', 'journeys', 'squad', 'sharing', 'design', 'other') then
    raise exception 'invalid' using errcode = 'P0001';
  end if;

  delete from private.rate_events where user_id = uid and at < now() - interval '1 day';
  if (
    select count(*) from private.rate_events
     where user_id = uid
       and kind = 'feature_request_edit'
       and at > now() - interval '1 hour'
  ) >= 20 then
    raise exception 'rate_limited' using errcode = 'P0001';
  end if;

  perform set_config('ourney.fr_edit_rate_checked', 'on', true);
  update public.feature_requests
     set title = btrim(p_title),
         body = btrim(p_body),
         category = v_cat
   where id = p_id
  returning * into fr;
  perform set_config('ourney.fr_edit_rate_checked', '', true);

  insert into private.rate_events (user_id, kind)
  values (uid, 'feature_request_edit');

  return private.feature_request_json(fr, uid);
end;
$$;

create or replace function public.delete_feature_request(p_id uuid) returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := public._uid();
  fr public.feature_requests%rowtype;
begin
  if p_id is null then
    raise exception 'invalid' using errcode = 'P0001';
  end if;

  perform 1 from public.profiles p where p.id = uid and p.deleted_at is null for no key update;
  if not found then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  select * into fr from public.feature_requests where id = p_id for update;
  if not found then
    raise exception 'not_found' using errcode = 'P0001';
  end if;

  if fr.author_id is distinct from uid
     or fr.status <> 'new'
     or fr.hidden
     or fr.duplicate_of is not null
     or fr.moderated_at is not null
     or exists (
       select 1 from public.feature_requests child
        where child.duplicate_of = p_id
     )
     or exists (
       select 1 from public.reports r
        where r.target_feature_request_id = p_id
          and r.deleted_at is null
          and r.status = 'open'
     )
     or exists (
       select 1 from public.moderation_queue mq
        where mq.target_feature_request_id = p_id
          and mq.status = 'open'
     ) then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  delete from public.feature_requests where id = p_id;
end;
$$;

create or replace function public.toggle_feature_request_vote(
  p_request_id uuid,
  p_voted boolean default null
) returns json
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := public._uid();
  fr public.feature_requests%rowtype;
  v_currently_voted boolean;
  v_next_voted boolean;
  v_count int;
begin
  if p_request_id is null then
    raise exception 'invalid' using errcode = 'P0001';
  end if;

  perform 1 from public.profiles p where p.id = uid and p.deleted_at is null for no key update;
  if not found then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  delete from private.rate_events where user_id = uid and at < now() - interval '1 day';
  if (
    select count(*) from private.rate_events
     where user_id = uid
       and kind = 'feature_request_vote'
       and at > now() - interval '1 minute'
  ) >= 60 then
    raise exception 'rate_limited' using errcode = 'P0001';
  end if;

  -- Lock the target feature_requests row to serialize vote toggles and prevent races
  -- against concurrent merge / ship / decline / hide transitions (P1-1).
  select * into fr from public.feature_requests where id = p_request_id for no key update;
  if not found
     or fr.hidden
     or (fr.author_id is not null and fr.author_id <> uid and private.is_blocked_pair(fr.author_id))
     or (fr.author_id is distinct from uid and private.has_reported_feature_request(fr.id)) then
    raise exception 'not_found' using errcode = 'P0001';
  end if;

  if fr.duplicate_of is not null
     or fr.status not in ('new', 'under_review', 'planned', 'in_progress') then
    raise exception 'ended' using errcode = 'P0001';
  end if;

  select exists (
    select 1 from public.feature_request_votes v
     where v.request_id = p_request_id and v.user_id = uid
  ) into v_currently_voted;

  v_next_voted := coalesce(p_voted, not v_currently_voted);

  if v_next_voted then
    insert into public.feature_request_votes (request_id, user_id)
    values (p_request_id, uid)
    on conflict (request_id, user_id) do nothing;
  else
    delete from public.feature_request_votes
     where request_id = p_request_id and user_id = uid;
  end if;

  insert into private.rate_events (user_id, kind)
  values (uid, 'feature_request_vote');

  select r.vote_count into v_count
    from public.feature_requests r
   where r.id = p_request_id;

  return json_build_object(
    'request_id', p_request_id,
    'vote_count', coalesce(v_count, 0),
    'voted_by_me', v_next_voted
  );
end;
$$;

create or replace function public.report_feature_request(
  p_request_id uuid,
  p_reason public.report_reason,
  p_note text default null
) returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := public._uid();
  fr public.feature_requests%rowtype;
  v_id uuid;
  v_note text := left(nullif(btrim(p_note), ''), 500);
  v_open_reports int := 0;
begin
  if p_request_id is null or p_reason is null then
    raise exception 'invalid' using errcode = 'P0001';
  end if;

  perform 1 from public.profiles p where p.id = uid and p.deleted_at is null for no key update;
  if not found then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  -- Lock the target feature_requests row to serialize vote toggles and prevent races
  -- against concurrent merge / ship / decline / hide transitions (P1-1).
  select * into fr from public.feature_requests where id = p_request_id for no key update;
  if not found
     or fr.hidden
     or fr.status = 'declined'
     or (fr.author_id is not null and private.is_blocked_pair(fr.author_id)) then
    raise exception 'not_found' using errcode = 'P0001';
  end if;

  if fr.author_id = uid then
    raise exception 'invalid' using errcode = 'P0001';
  end if;

  -- Deduplicate open reports on the same feature request by the same reporter.
  select r.id into v_id
    from public.reports r
   where r.reporter_id = uid
     and r.deleted_at is null
     and r.status = 'open'
     and r.target_feature_request_id = p_request_id
   order by r.created_at desc
   limit 1;
  if v_id is not null then
    return v_id;
  end if;

  -- Once a prior report by this user on this request was resolved/dismissed, it stays hidden for them.
  if private.has_reported_feature_request(p_request_id) then
    raise exception 'not_found' using errcode = 'P0001';
  end if;

  -- Shared 20 / 24h cap on public.reports.
  if (
    select count(*) from public.reports
     where reporter_id = uid and created_at > now() - interval '24 hours'
  ) >= 20 then
    raise exception 'rate_limited' using errcode = 'P0001';
  end if;

  insert into public.reports (
    reporter_id, target_user_id, target_feature_request_id, reason, note, due_at
  )
  values (
    uid, fr.author_id, p_request_id, p_reason, v_note, now() + interval '24 hours'
  )
  returning id into v_id;

  insert into public.moderation_queue (
    kind, report_id, actor_id, target_user_id, target_feature_request_id, reason, note, due_at
  )
  values (
    'report', v_id, uid, fr.author_id, p_request_id, p_reason, v_note, now() + interval '24 hours'
  );

  -- Auto-quarantine (hidden = true, moderated_at = now()) if >= 2 distinct open reporters
  -- or immediately on nudity/self_harm with no prior dismissed report (spec §4.4A).
  select count(distinct r.reporter_id)::int into v_open_reports
    from public.reports r
   where r.target_feature_request_id = p_request_id
     and r.deleted_at is null
     and r.status = 'open';

  if v_open_reports >= 2
     or (
       p_reason in ('nudity', 'self_harm')
       and not exists (
         select 1 from public.reports r
          where r.target_feature_request_id = p_request_id
            and r.deleted_at is null
            and r.status = 'dismissed'
       )
     ) then
    perform set_config('ourney.fr_internal_write', 'on', true);
    update public.feature_requests
       set hidden = true,
           moderated_at = coalesce(moderated_at, now())
     where id = p_request_id
       and (not hidden or moderated_at is null);
    perform set_config('ourney.fr_internal_write', '', true);
  end if;

  return v_id;
end;
$$;

create or replace function public.my_shipped_request_notifications(
  p_limit int default 20
) returns setof json
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  uid uuid := public._uid();
  v_limit int := greatest(1, least(coalesce(p_limit, 20), 100));
begin
  if not exists (select 1 from public.profiles p where p.id = uid and p.deleted_at is null) then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  return query
  select json_build_object(
           'request_id', fr.id,
           'title', fr.title,
           'category', fr.category,
           'admin_reply', fr.admin_reply,
           'is_author', n.is_author,
           'shipped_at', fr.shipped_at,
           'created_at', n.created_at,
           'seen', (n.seen_at is not null)
         )
    from private.feature_request_notifications n
    join public.feature_requests fr on fr.id = n.request_id
   where n.user_id = uid
     and not fr.hidden
     and fr.status = 'shipped'
     and (
       fr.author_id = uid
       or (
         (fr.author_id is null or not private.is_blocked_pair(fr.author_id))
         and not private.has_reported_feature_request(fr.id)
       )
     )
   order by coalesce(fr.shipped_at, n.created_at) desc, n.created_at desc, n.request_id desc
   limit v_limit;
end;
$$;

create or replace function public.mark_shipped_requests_seen(
  p_request_ids uuid[] default null
) returns int
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := public._uid();
  v_count int := 0;
begin
  if not exists (select 1 from public.profiles p where p.id = uid and p.deleted_at is null) then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  update private.feature_request_notifications n
     set seen_at = coalesce(n.seen_at, now())
   where n.user_id = uid
     and n.seen_at is null
     and (p_request_ids is null or n.request_id = any(p_request_ids));
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

revoke all on function
  public.list_feature_requests(text, text, text, boolean, int, int),
  public.get_feature_request(uuid),
  public.search_similar_feature_requests(text, int),
  public.create_feature_request(uuid, text, text, text),
  public.update_feature_request(uuid, text, text, text),
  public.delete_feature_request(uuid),
  public.toggle_feature_request_vote(uuid, boolean),
  public.report_feature_request(uuid, public.report_reason, text),
  public.my_shipped_request_notifications(int),
  public.mark_shipped_requests_seen(uuid[])
from public, anon;

grant execute on function
  public.list_feature_requests(text, text, text, boolean, int, int),
  public.get_feature_request(uuid),
  public.search_similar_feature_requests(text, int),
  public.create_feature_request(uuid, text, text, text),
  public.update_feature_request(uuid, text, text, text),
  public.delete_feature_request(uuid),
  public.toggle_feature_request_vote(uuid, boolean),
  public.report_feature_request(uuid, public.report_reason, text),
  public.my_shipped_request_notifications(int),
  public.mark_shipped_requests_seen(uuid[])
to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 7. Extend `public.inbox_counts()` & `public.purge_account_data(p_user)`
-- ---------------------------------------------------------------------------
create or replace function public.inbox_counts() returns json
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  uid uuid := public._uid();
begin
  return json_build_object(
    'friend_requests', (
      select count(*)::int from public.friendships f
       where uid in (f.user_low, f.user_high) and f.deleted_at is null and f.status = 'pending'
         and f.requested_by <> uid and f.source = 'direct'
         and not private.blocked_between(f.user_low, f.user_high)),
    'public_requests', (
      select count(*)::int from public.friendships f
       where uid in (f.user_low, f.user_high) and f.deleted_at is null and f.status = 'pending'
         and f.requested_by <> uid and f.source = 'public_journey'
         and not private.blocked_between(f.user_low, f.user_high)),
    'new_shares', (
      select count(distinct s.journey_id)::int from public.journey_shares s
        join public.journeys j on j.id = s.journey_id and j.deleted_at is null
       where s.viewer_id = uid and s.revoked_at is null and s.seen_at is null
         and private.grant_valid(s.journey_id, s.viewer_id, s.shared_by)
         and not private.is_member(s.journey_id)
         and not private.blocked_between(uid, j.owner_id)),
    'unread_messages', (
      select count(*)::int
        from public.conversations c
        join public.messages m on m.conversation_id = c.id
       where uid in (c.member_id, c.viewer_id)
         and not private.blocked_between(c.member_id, c.viewer_id)
         and m.sender_id <> uid and m.deleted_at is null
         and m.created_at > coalesce(case when c.member_id = uid then c.member_read_at else c.viewer_read_at end,
                                     '-infinity'::timestamptz)
         and m.created_at > coalesce(case when c.member_id = uid then c.member_cleared_at else c.viewer_cleared_at end,
                                     '-infinity'::timestamptz)
         and not exists (select 1 from public.message_hides h where h.message_id = m.id and h.user_id = uid)
         and not exists (select 1 from public.reports r
                          where r.target_message_id = m.id and r.reporter_id = uid and r.deleted_at is null)),
    'consent_requests', (
      select count(*)::int from public.journey_share_consents c
        join public.journeys j on j.id = c.journey_id and j.deleted_at is null
       where c.user_id = uid and c.status = 'pending' and private.is_active_member(c.journey_id, uid)
         and not private.blocked_between(uid, j.owner_id)),
    'group_invitations', (
      select count(*)::int from public.group_invitations i
        join public.journeys j on j.id = i.journey_id and j.deleted_at is null and j.status = 'active'
       where i.invitee_id = uid and i.status = 'pending' and i.expires_at > now()
         and private.is_active_member(j.id, i.inviter_id)
         and (j.duration_days is null
              or public.local_date(now(), j.timezone) <= j.start_date + j.duration_days - 1)
         and not private.blocked_between(uid, i.inviter_id)
         and not exists (select 1 from public.memberships am
                          where am.journey_id = j.id and am.status = 'active' and am.deleted_at is null
                            and private.blocked_between(uid, am.user_id))),
    'shipped_requests', (
      select count(*)::int
        from private.feature_request_notifications n
        join public.feature_requests fr on fr.id = n.request_id
       where n.user_id = uid
         and n.seen_at is null
         and not fr.hidden
         and fr.status = 'shipped'
         and (
           fr.author_id = uid
           or (
             (fr.author_id is null or not private.is_blocked_pair(fr.author_id))
             and not private.has_reported_feature_request(fr.id)
           )
         )));
end;
$$;

revoke all on function public.inbox_counts() from public, anon;
grant execute on function public.inbox_counts() to authenticated, service_role;

create or replace function public.purge_account_data(p_user uuid) returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  r record;
  v_prev_flag text := coalesce(current_setting('ourney.fr_internal_write', true), '');
begin
  -- Consistent lock hierarchy (profiles -> journeys ordered by id) matching join_by_code / send_group_invitation.
  perform 1 from public.profiles where id = p_user for no key update;
  perform 1
    from (
      select j.id
        from public.journeys j
       where j.owner_id = p_user
          or exists (select 1 from public.memberships m where m.journey_id = j.id and m.user_id = p_user)
       order by j.id
       for update
    ) s;

  -- Drop any stale pre-delete snapshot rows for this user and record the exact paths dying in this tx.
  delete from private.pending_storage_purge where user_id = p_user;

  insert into private.pending_storage_purge (bucket, path, user_id)
  select distinct 'media', p, p_user
    from public.account_media_paths(p_user) as p
   where p is not null and length(p) between 1 and 1024
  on conflict (bucket, path) do update
    set user_id = excluded.user_id,
        attempts = 0,
        next_attempt_at = now(),
        last_error = null
    where private.pending_storage_purge.user_id = excluded.user_id
       or exists (select 1 from auth.users u where u.id = private.pending_storage_purge.user_id);

  insert into private.pending_storage_purge (bucket, path, user_id)
  select distinct 'messages', p, p_user
    from public.account_message_paths(p_user) as p
   where p is not null and length(p) between 1 and 1024
  on conflict (bucket, path) do update
    set user_id = excluded.user_id,
        attempts = 0,
        next_attempt_at = now(),
        last_error = null
    where private.pending_storage_purge.user_id = excluded.user_id
       or exists (select 1 from auth.users u where u.id = private.pending_storage_purge.user_id);

  for r in
    select m.journey_id from public.memberships m
     where m.user_id = p_user and m.status = 'active' and m.deleted_at is null
       and m.journey_id not in (select public._journeys_dying_with(p_user))
     order by m.journey_id
  loop
    perform public._leave_journey(r.journey_id, p_user);
  end loop;
  delete from public.journeys where id in (select public._journeys_dying_with(p_user));
  delete from private.join_attempts where user_id = p_user;
  delete from private.rate_events where user_id = p_user;
  delete from public.journey_views where viewer_key = p_user::text;

  -- 0024: Pre-lock all feature_requests rows authored or voted on by p_user in deterministic
  -- UUID order to prevent deadlocks and vote-count drift during concurrent account purges (P1-1).
  perform 1
    from (
      select fr.id
        from public.feature_requests fr
       where fr.author_id = p_user
          or exists (
            select 1 from public.feature_request_votes v
             where v.request_id = fr.id
               and v.user_id = p_user
          )
       order by fr.id
       for no key update
    ) s;

  -- Delete solo-voted unmerged 'new'/'declined' feature requests authored by p_user
  -- that have no open reports or open moderation queue items (P2-3).
  delete from public.feature_requests fr
   where fr.author_id = p_user
     and fr.status in ('new', 'declined')
     and fr.duplicate_of is null
     and not exists (
       select 1 from public.feature_request_votes v
        where v.request_id = fr.id
          and v.user_id <> p_user
     )
     and not exists (
       select 1 from public.feature_requests child
        where child.duplicate_of = fr.id
     )
     and not exists (
       select 1 from public.reports r
        where r.target_feature_request_id = fr.id
          and r.deleted_at is null
          and r.status = 'open'
     )
     and not exists (
       select 1 from public.moderation_queue mq
        where mq.target_feature_request_id = fr.id
          and mq.status = 'open'
     );

  -- Remove p_user's votes (sync trigger decrements vote_count on surviving requests)
  -- and anonymize author_id on surviving community requests.
  delete from public.feature_request_votes where user_id = p_user;
  delete from private.feature_request_notifications where user_id = p_user;

  perform set_config('ourney.fr_internal_write', 'on', true);
  update public.feature_requests
     set author_id = null
   where author_id = p_user;
  perform set_config('ourney.fr_internal_write', v_prev_flag, true);
end;
$$;

revoke all on function public.purge_account_data(uuid) from public, anon, authenticated;
grant execute on function public.purge_account_data(uuid) to service_role;

-- ---------------------------------------------------------------------------
-- 8. Extend Moderation Queue Views & Handlers (`0020` & `0023`) for Feature Requests
-- ---------------------------------------------------------------------------
create or replace view private.moderation_queue_due
with (security_invoker = true) as
select
  q.id,
  q.kind,
  q.report_id,
  q.status,
  q.reason,
  q.note,
  q.created_at,
  q.due_at,
  q.notified_at,
  q.handled_at,
  q.resolution_note,
  (q.status = 'open' and q.due_at <= now()) as overdue,
  round((extract(epoch from (q.due_at - now())) / 3600.0)::numeric, 2) as hours_remaining,
  q.actor_id,
  ap.username as actor_username,
  q.target_user_id,
  tp.username as target_username,
  tp.display_name as target_display_name,
  q.target_checkin_id,
  ci.caption as checkin_caption,
  ci.photo_path as checkin_photo_path,
  ci.moderated_at as checkin_moderated_at,
  q.target_message_id,
  msg.body as message_body,
  msg.media_path as message_media_path,
  msg.moderated_at as message_moderated_at,
  (
    select count(distinct r.reporter_id)::int
      from public.reports r
     where r.deleted_at is null
       and r.status = 'open'
       and (
         (q.target_checkin_id is not null and r.target_checkin_id = q.target_checkin_id)
         or (q.target_message_id is not null and r.target_message_id = q.target_message_id)
         or (q.target_feature_request_id is not null and r.target_feature_request_id = q.target_feature_request_id)
         or (q.target_checkin_id is null and q.target_message_id is null and q.target_feature_request_id is null
             and q.target_user_id is not null and r.target_user_id = q.target_user_id
             and r.target_checkin_id is null and r.target_message_id is null and r.target_feature_request_id is null)
       )
  ) as distinct_open_reporters,
  q.target_feature_request_id,
  fr.title as feature_request_title,
  fr.body as feature_request_body,
  fr.hidden as feature_request_hidden
from public.moderation_queue q
left join public.profiles ap on ap.id = q.actor_id
left join public.profiles tp on tp.id = q.target_user_id
left join public.check_ins ci on ci.id = q.target_checkin_id
left join public.messages msg on msg.id = q.target_message_id
left join public.feature_requests fr on fr.id = q.target_feature_request_id;

revoke all on private.moderation_queue_due from public, anon, authenticated;
grant select on private.moderation_queue_due to service_role;

create or replace function private.ban_user_internal(
  p_user uuid,
  p_admin_id uuid,
  p_reason text,
  p_wipe_ugc boolean default false
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_reason text := left(nullif(btrim(p_reason), ''), 500);
  v_wipe boolean := coalesce(p_wipe_ugc, false);
  v_sessions int := 0;
  v_journey_id uuid;
  v_sentinel uuid := '00000000-0000-0000-0000-000000000000'::uuid;
begin
  if exists (
    select 1 from information_schema.columns
     where table_schema = 'auth' and table_name = 'users' and column_name = 'banned_until'
  ) then
    execute 'update auth.users set banned_until = now() + interval ''100 years'' where id = $1'
      using p_user;
  end if;

  v_sessions := private.revoke_user_sessions_internal(p_user);

  insert into private.user_moderation (
    user_id, banned_at, banned_by, ban_reason, wiped_ugc,
    unbanned_at, unbanned_by, unban_reason, updated_at
  )
  values (
    p_user, now(), p_admin_id, v_reason, v_wipe,
    null, null, null, now()
  )
  on conflict (user_id) do update
    set banned_at = now(),
        banned_by = excluded.banned_by,
        ban_reason = excluded.ban_reason,
        wiped_ugc = private.user_moderation.wiped_ugc or excluded.wiped_ugc,
        unbanned_at = null,
        unbanned_by = null,
        unban_reason = null,
        updated_at = now();

  -- Always revoke public journey links owned by the banned user.
  update public.journeys
     set public_token = null,
         visibility = case when kind = 'solo' and visibility = 'link' then 'private'::public.journey_visibility else visibility end
   where owner_id = p_user
     and public_token is not null;

  delete from public.saved_journeys
   where journey_id in (select j.id from public.journeys j where j.owner_id = p_user);

  if v_wipe then
    insert into private.pending_storage_purge (bucket, path, user_id)
    select distinct 'media', p, v_sentinel
      from (
        select unnest(array[c.photo_path, c.thumb_path, c.partner_photo_path]) as p
          from public.check_ins c
         where c.user_id = p_user
        union all
        select pr.avatar_path as p
          from public.profiles pr
         where pr.id = p_user
      ) x
     where p is not null and length(p) between 1 and 1024
    on conflict (bucket, path) do update
      set user_id = v_sentinel,
          attempts = 0,
          next_attempt_at = now(),
          last_error = null;

    insert into private.pending_storage_purge (bucket, path, user_id)
    select distinct 'messages', m.media_path, v_sentinel
      from public.messages m
     where m.sender_id = p_user
       and m.media_path is not null and length(m.media_path) between 1 and 1024
    on conflict (bucket, path) do update
      set user_id = v_sentinel,
          attempts = 0,
          next_attempt_at = now(),
          last_error = null;

    update public.profiles
       set avatar_path = null
     where id = p_user
       and avatar_path is not null;

    delete from public.friend_invites
     where user_id = p_user;

    update public.check_ins
       set moderated_at = coalesce(moderated_at, now()),
           deleted_at = coalesce(deleted_at, now())
     where user_id = p_user
       and (moderated_at is null or deleted_at is null);

    update public.messages
       set moderated_at = coalesce(moderated_at, now()),
           deleted_at = coalesce(deleted_at, now())
     where sender_id = p_user
       and (moderated_at is null or deleted_at is null);

    perform set_config('ourney.fr_internal_write', 'on', true);
    update public.feature_requests
       set hidden = true,
           moderated_at = coalesce(moderated_at, now())
     where author_id = p_user
       and (not hidden or moderated_at is null);
    perform set_config('ourney.fr_internal_write', '', true);

    for v_journey_id in
      select m.journey_id
        from public.memberships m
        join public.journeys j on j.id = m.journey_id
       where m.user_id = p_user
         and m.status = 'active'
         and m.deleted_at is null
         and j.kind = 'group'
       order by m.journey_id
    loop
      perform public._leave_journey(v_journey_id, p_user);
      update public.memberships
         set removed_at = coalesce(removed_at, now())
       where journey_id = v_journey_id and user_id = p_user;
    end loop;

    update public.journeys
       set public_token = null,
           visibility = case when kind = 'solo' then 'private'::public.journey_visibility else visibility end,
           status = case when kind = 'solo' and status = 'active' then 'archived'::public.journey_status else status end,
           deleted_at = case when kind = 'solo' then coalesce(deleted_at, now()) else deleted_at end
     where owner_id = p_user;

    update public.journey_shares
       set revoked_at = now()
     where (shared_by = p_user or viewer_id = p_user)
       and revoked_at is null;

    update public.friendships
       set deleted_at = now()
     where (user_low = p_user or user_high = p_user)
       and deleted_at is null;

    update public.reports
       set status = 'actioned'
     where target_user_id = p_user and status = 'open';

    update public.moderation_queue
       set status = 'actioned',
           handled_at = coalesce(handled_at, now()),
           resolution_note = coalesce(resolution_note, v_reason)
     where target_user_id = p_user and status = 'open';
  end if;

  return jsonb_build_object(
    'user_id', p_user,
    'banned', true,
    'wipe_ugc', v_wipe,
    'revoked_sessions', v_sessions,
    'banned_at', now()
  );
end;
$$;

revoke all on function private.ban_user_internal(uuid, uuid, text, boolean) from public, anon, authenticated;
grant execute on function private.ban_user_internal(uuid, uuid, text, boolean) to service_role;

create or replace function private.moderate_queue_item(
  p_queue_id uuid,
  p_action text,
  p_note text default null
) returns json
language plpgsql
security definer
set search_path = ''
as $$
declare
  q public.moderation_queue%rowtype;
  v_action text := lower(btrim(coalesce(p_action, '')));
  v_note text := left(nullif(btrim(p_note), ''), 500);
  v_new_status text;
  v_sentinel uuid := '00000000-0000-0000-0000-000000000000'::uuid;
begin
  perform private.assert_service_role();
  if p_queue_id is null or v_action not in ('dismiss', 'remove_content', 'action', 'ban_user') then
    raise exception 'invalid';
  end if;

  select * into q from public.moderation_queue where id = p_queue_id for update;
  if not found then
    raise exception 'not_found';
  end if;

  if v_action = 'dismiss' and q.status = 'actioned' then
    raise exception 'invalid';
  end if;

  v_new_status := case when v_action = 'dismiss' then 'dismissed' else 'actioned' end;

  update public.moderation_queue
     set status = v_new_status,
         handled_at = now(),
         resolution_note = coalesce(v_note, resolution_note)
   where id = q.id
  returning * into q;

  if q.report_id is not null then
    update public.reports set status = v_new_status where id = q.report_id;
  end if;

  if q.target_checkin_id is not null then
    update public.reports
       set status = v_new_status
     where target_checkin_id = q.target_checkin_id and status = 'open';
    update public.moderation_queue
       set status = v_new_status,
           handled_at = coalesce(handled_at, now()),
           resolution_note = coalesce(resolution_note, v_note)
     where target_checkin_id = q.target_checkin_id and status = 'open';
  end if;

  if q.target_message_id is not null then
    update public.reports
       set status = v_new_status
     where target_message_id = q.target_message_id and status = 'open';
    update public.moderation_queue
       set status = v_new_status,
           handled_at = coalesce(handled_at, now()),
           resolution_note = coalesce(resolution_note, v_note)
     where target_message_id = q.target_message_id and status = 'open';
  end if;

  if q.target_feature_request_id is not null then
    update public.reports
       set status = v_new_status
     where target_feature_request_id = q.target_feature_request_id and status = 'open';
    update public.moderation_queue
       set status = v_new_status,
           handled_at = coalesce(handled_at, now()),
           resolution_note = coalesce(resolution_note, v_note)
     where target_feature_request_id = q.target_feature_request_id and status = 'open';
  end if;

  if v_action = 'dismiss' then
    if q.target_checkin_id is not null then
      update public.check_ins c
         set moderated_at = null
       where c.id = q.target_checkin_id
         and c.moderated_at is not null
         and c.deleted_at is null
         and not exists (
           select 1 from public.reports r
            where r.target_checkin_id = q.target_checkin_id
              and r.deleted_at is null
              and r.status = 'actioned'
         )
         and not exists (
           select 1 from public.moderation_queue mq
            where mq.target_checkin_id = q.target_checkin_id
              and mq.status = 'actioned'
         );
    end if;
    if q.target_message_id is not null then
      update public.messages m
         set moderated_at = null
       where m.id = q.target_message_id
         and m.moderated_at is not null
         and m.deleted_at is null
         and not exists (
           select 1 from public.reports r
            where r.target_message_id = q.target_message_id
              and r.deleted_at is null
              and r.status = 'actioned'
         )
         and not exists (
           select 1 from public.moderation_queue mq
            where mq.target_message_id = q.target_message_id
              and mq.status = 'actioned'
         );
    end if;
    if q.target_feature_request_id is not null then
      perform set_config('ourney.fr_internal_write', 'on', true);
      update public.feature_requests fr
         set hidden = false,
             moderated_at = null
       where fr.id = q.target_feature_request_id
         and fr.moderated_at is not null
         and not exists (
           select 1 from public.reports r
            where r.target_feature_request_id = q.target_feature_request_id
              and r.deleted_at is null
              and r.status = 'actioned'
         )
         and not exists (
           select 1 from public.moderation_queue mq
            where mq.target_feature_request_id = q.target_feature_request_id
              and mq.status = 'actioned'
         );
      perform set_config('ourney.fr_internal_write', '', true);
    end if;
  else
    if q.target_checkin_id is not null then
      insert into private.pending_storage_purge (bucket, path, user_id)
      select distinct 'media', p, v_sentinel
        from public.check_ins c
        cross join lateral unnest(array[c.photo_path, c.thumb_path, c.partner_photo_path]) as p
       where c.id = q.target_checkin_id
         and p is not null and length(p) between 1 and 1024
      on conflict (bucket, path) do update
        set user_id = v_sentinel,
            attempts = 0,
            next_attempt_at = now(),
            last_error = null;

      update public.check_ins
         set moderated_at = coalesce(moderated_at, now()),
             deleted_at = coalesce(deleted_at, now())
       where id = q.target_checkin_id;
    end if;

    if q.target_message_id is not null then
      insert into private.pending_storage_purge (bucket, path, user_id)
      select distinct 'messages', m.media_path, v_sentinel
        from public.messages m
       where m.id = q.target_message_id
         and m.media_path is not null and length(m.media_path) between 1 and 1024
      on conflict (bucket, path) do update
        set user_id = v_sentinel,
            attempts = 0,
            next_attempt_at = now(),
            last_error = null;

      update public.messages
         set moderated_at = coalesce(moderated_at, now()),
             deleted_at = coalesce(deleted_at, now())
       where id = q.target_message_id;
    end if;

    if q.target_feature_request_id is not null then
      perform set_config('ourney.fr_internal_write', 'on', true);
      update public.feature_requests
         set hidden = true,
             moderated_at = coalesce(moderated_at, now())
       where id = q.target_feature_request_id;
      perform set_config('ourney.fr_internal_write', '', true);
    end if;

    if v_action = 'ban_user' and q.target_user_id is not null then
      perform private.ban_user_internal(
        q.target_user_id,
        null,
        coalesce(v_note, 'Moderation queue ban_user'),
        true
      );
    end if;
  end if;

  delete from private.admin_media_grants g
   where g.queue_id = q.id
      or exists (
        select 1 from public.moderation_queue mq
         where mq.id = g.queue_id
           and mq.status <> 'open'
      );

  return json_build_object(
    'id', q.id,
    'status', q.status,
    'action', v_action,
    'handled_at', q.handled_at,
    'target_user_id', q.target_user_id,
    'target_checkin_id', q.target_checkin_id,
    'target_message_id', q.target_message_id,
    'target_feature_request_id', q.target_feature_request_id
  );
end;
$$;

revoke all on function private.moderate_queue_item(uuid, text, text) from public, anon, authenticated;
grant execute on function private.moderate_queue_item(uuid, text, text) to service_role;

-- Extend admin moderation RPCs (`0023`) to surface `target_feature_request_id` & `target_type = 'feature_request'`.
create or replace function admin.list_moderation_queue(
  p_status text default 'open',
  p_kind text default 'all',
  p_reason text default 'all',
  p_limit int default 50,
  p_offset int default 0
) returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_status text := coalesce(nullif(lower(btrim(p_status)), ''), 'open');
  v_kind text := coalesce(nullif(lower(btrim(p_kind)), ''), 'all');
  v_reason text := coalesce(nullif(lower(btrim(p_reason)), ''), 'all');
  v_limit int := greatest(1, least(coalesce(p_limit, 50), 200));
  v_offset int := greatest(0, coalesce(p_offset, 0));
  v_summary jsonb;
  v_total int := 0;
  v_items jsonb := '[]'::jsonb;
begin
  v_uid := private.require_admin('moderator');
  select jsonb_build_object(
           'open_reports', count(*) filter (where q.status = 'open' and q.kind = 'report')::int,
           'open_blocks', count(*) filter (where q.status = 'open' and q.kind = 'block')::int,
           'overdue_count', count(*) filter (where q.status = 'open' and q.due_at <= now())::int,
           'due_soon_count', count(*) filter (
             where q.status = 'open' and q.due_at > now() and q.due_at <= now() + interval '4 hours'
           )::int,
           'quarantined_count', count(*) filter (
             where q.status = 'open'
               and (ci.moderated_at is not null or msg.moderated_at is not null or fr.moderated_at is not null or coalesce(fr.hidden, false))
           )::int,
           'median_handle_hours_30d', coalesce((
             select round(
               (percentile_cont(0.5) within group (
                 order by extract(epoch from (q2.handled_at - q2.created_at)) / 3600.0
               ))::numeric,
               2
             )
               from public.moderation_queue q2
              where q2.handled_at is not null
                and q2.created_at >= now() - interval '30 days'
           ), 0.0)
         )
    into v_summary
    from public.moderation_queue q
    left join public.check_ins ci on ci.id = q.target_checkin_id
    left join public.messages msg on msg.id = q.target_message_id
    left join public.feature_requests fr on fr.id = q.target_feature_request_id;

  with enriched as (
    select
      q.id,
      q.kind,
      q.report_id,
      q.status,
      q.reason::text as reason,
      q.note,
      q.created_at,
      q.due_at,
      q.notified_at,
      q.handled_at,
      q.resolution_note,
      (q.status = 'open' and q.due_at <= now()) as overdue,
      round((extract(epoch from (q.due_at - now())) / 3600.0)::numeric, 2) as hours_remaining,
      case
        when q.target_checkin_id is not null then 'checkin'
        when q.target_message_id is not null then 'message'
        when q.target_feature_request_id is not null then 'feature_request'
        else 'user'
      end as target_type,
      q.actor_id,
      ap.username as actor_username,
      ap.display_name as actor_display_name,
      q.target_user_id,
      tp.username as target_username,
      tp.display_name as target_display_name,
      q.target_checkin_id,
      q.target_message_id,
      q.target_feature_request_id,
      coalesce(
        ci.moderated_at is not null,
        msg.moderated_at is not null,
        (fr.moderated_at is not null or fr.hidden),
        false
      ) as auto_quarantined,
      (
        (ci.id is not null and (ci.photo_path is not null or ci.partner_photo_path is not null))
        or (msg.id is not null and msg.media_path is not null)
      ) as has_reported_media,
      (
        select count(distinct r.reporter_id)::int
          from public.reports r
         where r.deleted_at is null
           and r.status = 'open'
           and (
             (q.target_checkin_id is not null and r.target_checkin_id = q.target_checkin_id)
             or (q.target_message_id is not null and r.target_message_id = q.target_message_id)
             or (q.target_feature_request_id is not null and r.target_feature_request_id = q.target_feature_request_id)
             or (q.target_checkin_id is null and q.target_message_id is null and q.target_feature_request_id is null
                 and q.target_user_id is not null and r.target_user_id = q.target_user_id
                 and r.target_checkin_id is null and r.target_message_id is null and r.target_feature_request_id is null)
           )
      ) as distinct_open_reporters,
      (
        select count(*)::int
          from public.moderation_queue mq2
         where mq2.target_user_id = q.target_user_id
           and mq2.status = 'actioned'
      ) as target_prior_actions,
      (
        select count(*)::int
          from public.blocks b
         where b.blocked_id = q.target_user_id
           and b.deleted_at is null
      ) as target_blocked_by_count
    from public.moderation_queue q
    left join public.profiles ap on ap.id = q.actor_id
    left join public.profiles tp on tp.id = q.target_user_id
    left join public.check_ins ci on ci.id = q.target_checkin_id
    left join public.messages msg on msg.id = q.target_message_id
    left join public.feature_requests fr on fr.id = q.target_feature_request_id
    where (
            v_status = 'all'
            or (v_status = 'overdue' and q.status = 'open' and q.due_at <= now())
            or (v_status = 'quarantined' and (ci.moderated_at is not null or msg.moderated_at is not null or fr.moderated_at is not null or coalesce(fr.hidden, false)))
            or (v_status in ('open', 'actioned', 'dismissed') and q.status = v_status)
          )
      and (v_kind = 'all' or q.kind = v_kind)
      and (v_reason = 'all' or q.reason::text = v_reason)
  )
  select count(*)::int,
         coalesce((
           select jsonb_agg(row_to_json(x))
             from (
               select *
                 from enriched e
                order by
                  case when e.status = 'open' then 0 else 1 end,
                  e.due_at asc,
                  case e.reason
                    when 'self_harm' then 0
                    when 'nudity' then 1
                    when 'harassment' then 2
                    when 'spam' then 3
                    else 4
                  end asc,
                  e.created_at asc,
                  e.id asc
                limit v_limit offset v_offset
             ) x
         ), '[]'::jsonb)
    into v_total, v_items
    from enriched;

  return jsonb_build_object(
    'summary', v_summary,
    'total', v_total,
    'items', v_items
  );
end;
$$;

create or replace function admin.get_moderation_item(p_queue_id uuid) returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  q public.moderation_queue%rowtype;
  v_target_user jsonb;
  v_sibling_reports jsonb := '[]'::jsonb;
  v_reported_content jsonb;
begin
  v_uid := private.require_admin('moderator');
  if p_queue_id is null then
    raise exception 'invalid' using errcode = 'P0001';
  end if;

  select * into q from public.moderation_queue where id = p_queue_id;
  if not found then
    raise exception 'not_found' using errcode = 'P0001';
  end if;

  perform private.admin_log(
    v_uid,
    'moderation.view_item',
    'moderation_queue',
    q.id::text,
    null,
    jsonb_build_object(
      'kind', q.kind,
      'target_user_id', q.target_user_id,
      'target_checkin_id', q.target_checkin_id,
      'target_message_id', q.target_message_id,
      'target_feature_request_id', q.target_feature_request_id
    )
  );

  if q.target_user_id is not null then
    select jsonb_build_object(
             'user_id', u.id,
             'username', p.username,
             'display_name', p.display_name,
             'created_at', u.created_at,
             'is_banned', private.is_user_banned(u.id),
             'prior_actioned_reports', (
               select count(*)::int from public.moderation_queue mq
                where mq.target_user_id = u.id and mq.status = 'actioned'
             ),
             'blocked_by_count', (
               select count(*)::int from public.blocks b
                where b.blocked_id = u.id and b.deleted_at is null
             )
           )
      into v_target_user
      from auth.users u
      left join public.profiles p on p.id = u.id
     where u.id = q.target_user_id;
  end if;

  select coalesce(jsonb_agg(
           jsonb_build_object(
             'id', r.id,
             'reporter_id', r.reporter_id,
             'reporter_username', rp.username,
             'reason', r.reason::text,
             'note', r.note,
             'status', r.status,
             'created_at', r.created_at,
             'due_at', r.due_at
           ) order by r.created_at desc
         ), '[]'::jsonb)
    into v_sibling_reports
    from public.reports r
    left join public.profiles rp on rp.id = r.reporter_id
   where r.deleted_at is null
     and (
       (q.target_checkin_id is not null and r.target_checkin_id = q.target_checkin_id)
       or (q.target_message_id is not null and r.target_message_id = q.target_message_id)
       or (q.target_feature_request_id is not null and r.target_feature_request_id = q.target_feature_request_id)
       or (q.target_checkin_id is null and q.target_message_id is null and q.target_feature_request_id is null
           and q.target_user_id is not null and r.target_user_id = q.target_user_id
           and r.target_checkin_id is null and r.target_message_id is null and r.target_feature_request_id is null)
     );

  if q.target_checkin_id is not null then
    select jsonb_build_object(
             'target_type', 'checkin',
             'checkin_id', ci.id,
             'journey_id', ci.journey_id,
             'local_date', ci.local_date,
             'captured_at', ci.captured_at,
             'caption', ci.caption,
             'extras', coalesce(ce.extras, '{}'::jsonb),
             'moderated_at', ci.moderated_at,
             'deleted_at', ci.deleted_at,
             'has_photo', (ci.photo_path is not null),
             'has_thumb', (ci.thumb_path is not null),
             'has_partner_photo', (ci.partner_photo_path is not null)
           )
      into v_reported_content
      from public.check_ins ci
      left join public.check_in_extras ce on ce.checkin_id = ci.id
     where ci.id = q.target_checkin_id;
  elsif q.target_message_id is not null then
    select jsonb_build_object(
             'target_type', 'message',
             'message_id', m.id,
             'conversation_id', m.conversation_id,
             'kind', m.kind,
             'body', m.body,
             'created_at', m.created_at,
             'moderated_at', m.moderated_at,
             'deleted_at', m.deleted_at,
             'has_media', (m.media_path is not null)
           )
      into v_reported_content
      from public.messages m
     where m.id = q.target_message_id;
  elsif q.target_feature_request_id is not null then
    select jsonb_build_object(
             'target_type', 'feature_request',
             'feature_request_id', fr.id,
             'title', fr.title,
             'body', fr.body,
             'caption', fr.title || E'\n\n' || fr.body,
             'category', fr.category,
             'status', fr.status,
             'hidden', fr.hidden,
             'moderated_at', fr.moderated_at,
             'created_at', fr.created_at
           )
      into v_reported_content
      from public.feature_requests fr
     where fr.id = q.target_feature_request_id;
    v_reported_content := coalesce(
      v_reported_content,
      jsonb_build_object(
        'target_type', 'feature_request',
        'feature_request_id', q.target_feature_request_id,
        'deleted', true
      )
    );
  else
    v_reported_content := jsonb_build_object(
      'target_type', 'user',
      'user_id', q.target_user_id
    );
  end if;

  return jsonb_build_object(
    'id', q.id,
    'kind', q.kind,
    'report_id', q.report_id,
    'status', q.status,
    'reason', q.reason::text,
    'note', q.note,
    'created_at', q.created_at,
    'due_at', q.due_at,
    'notified_at', q.notified_at,
    'handled_at', q.handled_at,
    'resolution_note', q.resolution_note,
    'overdue', (q.status = 'open' and q.due_at <= now()),
    'hours_remaining', round((extract(epoch from (q.due_at - now())) / 3600.0)::numeric, 2),
    'actor_id', q.actor_id,
    'target_user_id', q.target_user_id,
    'target_checkin_id', q.target_checkin_id,
    'target_message_id', q.target_message_id,
    'target_feature_request_id', q.target_feature_request_id,
    'target_user', v_target_user,
    'sibling_reports', v_sibling_reports,
    'reported_content', v_reported_content
  );
end;
$$;

create or replace function admin.quarantine_moderation_target(
  p_queue_id uuid,
  p_note text default null
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  q public.moderation_queue%rowtype;
  v_note text := left(nullif(btrim(p_note), ''), 500);
begin
  v_uid := private.require_admin('moderator');
  if p_queue_id is null then
    raise exception 'invalid' using errcode = 'P0001';
  end if;

  select * into q from public.moderation_queue where id = p_queue_id for update;
  if not found then
    raise exception 'not_found' using errcode = 'P0001';
  end if;

  if q.target_checkin_id is null and q.target_message_id is null and q.target_feature_request_id is null then
    raise exception 'invalid' using errcode = 'P0001';
  end if;

  if q.target_checkin_id is not null then
    update public.check_ins
       set moderated_at = coalesce(moderated_at, now())
     where id = q.target_checkin_id;
  end if;

  if q.target_message_id is not null then
    update public.messages
       set moderated_at = coalesce(moderated_at, now())
     where id = q.target_message_id;
  end if;

  if q.target_feature_request_id is not null then
    perform set_config('ourney.fr_internal_write', 'on', true);
    update public.feature_requests
       set hidden = true,
           moderated_at = coalesce(moderated_at, now())
     where id = q.target_feature_request_id;
    perform set_config('ourney.fr_internal_write', '', true);
  end if;

  if v_note is not null then
    update public.moderation_queue
       set resolution_note = v_note
     where id = q.id;
  end if;

  perform private.admin_log(
    v_uid,
    'moderation.quarantine',
    'moderation_queue',
    q.id::text,
    v_note,
    jsonb_build_object(
      'target_checkin_id', q.target_checkin_id,
      'target_message_id', q.target_message_id,
      'target_feature_request_id', q.target_feature_request_id
    )
  );

  return jsonb_build_object(
    'id', q.id,
    'status', q.status,
    'quarantined', true,
    'target_checkin_id', q.target_checkin_id,
    'target_message_id', q.target_message_id,
    'target_feature_request_id', q.target_feature_request_id
  );
end;
$$;

create or replace function admin.resolve_moderation(
  p_queue_id uuid,
  p_action text,
  p_note text default null
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  q public.moderation_queue%rowtype;
  v_action text := lower(btrim(coalesce(p_action, '')));
  v_note text := left(nullif(btrim(p_note), ''), 500);
  v_new_status text;
  v_sentinel uuid := '00000000-0000-0000-0000-000000000000'::uuid;
begin
  v_uid := private.require_admin('moderator');
  if p_queue_id is null or v_action not in ('dismiss', 'remove_content', 'action', 'ban_user') then
    raise exception 'invalid' using errcode = 'P0001';
  end if;

  select * into q from public.moderation_queue where id = p_queue_id for update;
  if not found then
    raise exception 'not_found' using errcode = 'P0001';
  end if;

  if v_action = 'dismiss' and q.status = 'actioned' then
    raise exception 'invalid' using errcode = 'P0001';
  end if;

  v_new_status := case when v_action = 'dismiss' then 'dismissed' else 'actioned' end;

  update public.moderation_queue
     set status = v_new_status,
         handled_at = now(),
         resolution_note = coalesce(v_note, resolution_note)
   where id = q.id
  returning * into q;

  if q.report_id is not null then
    update public.reports set status = v_new_status where id = q.report_id;
  end if;

  if q.target_checkin_id is not null then
    update public.reports
       set status = v_new_status
     where target_checkin_id = q.target_checkin_id and status = 'open';
    update public.moderation_queue
       set status = v_new_status,
           handled_at = coalesce(handled_at, now()),
           resolution_note = coalesce(resolution_note, v_note)
     where target_checkin_id = q.target_checkin_id and status = 'open';
  end if;

  if q.target_message_id is not null then
    update public.reports
       set status = v_new_status
     where target_message_id = q.target_message_id and status = 'open';
    update public.moderation_queue
       set status = v_new_status,
           handled_at = coalesce(handled_at, now()),
           resolution_note = coalesce(resolution_note, v_note)
     where target_message_id = q.target_message_id and status = 'open';
  end if;

  if q.target_feature_request_id is not null then
    update public.reports
       set status = v_new_status
     where target_feature_request_id = q.target_feature_request_id and status = 'open';
    update public.moderation_queue
       set status = v_new_status,
           handled_at = coalesce(handled_at, now()),
           resolution_note = coalesce(resolution_note, v_note)
     where target_feature_request_id = q.target_feature_request_id and status = 'open';
  end if;

  if v_action = 'dismiss' then
    if q.target_checkin_id is not null then
      update public.check_ins c
         set moderated_at = null
       where c.id = q.target_checkin_id
         and c.moderated_at is not null
         and c.deleted_at is null
         and not exists (
           select 1 from public.reports r
            where r.target_checkin_id = q.target_checkin_id
              and r.deleted_at is null
              and r.status = 'actioned'
         )
         and not exists (
           select 1 from public.moderation_queue mq
            where mq.target_checkin_id = q.target_checkin_id
              and mq.status = 'actioned'
         );
    end if;

    if q.target_message_id is not null then
      update public.messages m
         set moderated_at = null
       where m.id = q.target_message_id
         and m.moderated_at is not null
         and m.deleted_at is null
         and not exists (
           select 1 from public.reports r
            where r.target_message_id = q.target_message_id
              and r.deleted_at is null
              and r.status = 'actioned'
         )
         and not exists (
           select 1 from public.moderation_queue mq
            where mq.target_message_id = q.target_message_id
              and mq.status = 'actioned'
         );
    end if;

    if q.target_feature_request_id is not null then
      perform set_config('ourney.fr_internal_write', 'on', true);
      update public.feature_requests fr
         set hidden = false,
             moderated_at = null
       where fr.id = q.target_feature_request_id
         and fr.moderated_at is not null
         and not exists (
           select 1 from public.reports r
            where r.target_feature_request_id = q.target_feature_request_id
              and r.deleted_at is null
              and r.status = 'actioned'
         )
         and not exists (
           select 1 from public.moderation_queue mq
            where mq.target_feature_request_id = q.target_feature_request_id
              and mq.status = 'actioned'
         );
      perform set_config('ourney.fr_internal_write', '', true);
    end if;
  else
    if q.target_checkin_id is not null then
      insert into private.pending_storage_purge (bucket, path, user_id)
      select distinct 'media', p, v_sentinel
        from public.check_ins c
        cross join lateral unnest(array[c.photo_path, c.thumb_path, c.partner_photo_path]) as p
       where c.id = q.target_checkin_id
         and p is not null and length(p) between 1 and 1024
      on conflict (bucket, path) do update
        set user_id = v_sentinel,
            attempts = 0,
            next_attempt_at = now(),
            last_error = null;

      update public.check_ins
         set moderated_at = coalesce(moderated_at, now()),
             deleted_at = coalesce(deleted_at, now())
       where id = q.target_checkin_id;
    end if;

    if q.target_message_id is not null then
      insert into private.pending_storage_purge (bucket, path, user_id)
      select distinct 'messages', m.media_path, v_sentinel
        from public.messages m
       where m.id = q.target_message_id
         and m.media_path is not null and length(m.media_path) between 1 and 1024
      on conflict (bucket, path) do update
        set user_id = v_sentinel,
            attempts = 0,
            next_attempt_at = now(),
            last_error = null;

      update public.messages
         set moderated_at = coalesce(moderated_at, now()),
             deleted_at = coalesce(deleted_at, now())
       where id = q.target_message_id;
    end if;

    if q.target_feature_request_id is not null then
      perform set_config('ourney.fr_internal_write', 'on', true);
      update public.feature_requests
         set hidden = true,
             moderated_at = coalesce(moderated_at, now())
       where id = q.target_feature_request_id;
      perform set_config('ourney.fr_internal_write', '', true);
    end if;

    if v_action = 'ban_user' and q.target_user_id is not null then
      if q.target_user_id = v_uid
         or exists (
           select 1 from private.admins a
            where a.user_id = q.target_user_id
              and (
                a.role = 'owner'
                or not exists (select 1 from private.admins ca where ca.user_id = v_uid and ca.role = 'owner')
              )
         ) then
        raise exception 'forbidden' using errcode = '42501';
      end if;
      perform private.ban_user_internal(
        q.target_user_id,
        v_uid,
        coalesce(v_note, 'Moderation queue ban_user'),
        true
      );
    end if;
  end if;

  delete from private.admin_media_grants g
   where g.queue_id = q.id
      or exists (
        select 1 from public.moderation_queue mq
         where mq.id = g.queue_id
           and mq.status <> 'open'
      );

  perform private.admin_log(
    v_uid,
    'moderation.resolve',
    'moderation_queue',
    q.id::text,
    v_note,
    jsonb_build_object(
      'action', v_action,
      'status', q.status,
      'target_user_id', q.target_user_id,
      'target_checkin_id', q.target_checkin_id,
      'target_message_id', q.target_message_id,
      'target_feature_request_id', q.target_feature_request_id
    )
  );

  return jsonb_build_object(
    'id', q.id,
    'status', q.status,
    'action', v_action,
    'handled_at', q.handled_at,
    'target_user_id', q.target_user_id,
    'target_checkin_id', q.target_checkin_id,
    'target_message_id', q.target_message_id,
    'target_feature_request_id', q.target_feature_request_id
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- 9. Admin-Side Feature Request RPCs (`schema admin`, §4.4B & Amendments F1-F2)
-- ---------------------------------------------------------------------------
create or replace function admin.feature_request_stats() returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_new int := 0;
  v_under_review int := 0;
  v_planned int := 0;
  v_in_progress int := 0;
  v_shipped int := 0;
  v_declined int := 0;
  v_hidden int := 0;
  v_merged int := 0;
  v_new_week int := 0;
  v_top_voted jsonb := '[]'::jsonb;
begin
  v_uid := private.require_admin('moderator');

  select count(*) filter (where fr.status = 'new' and not fr.hidden and fr.duplicate_of is null)::int,
         count(*) filter (where fr.status = 'under_review' and not fr.hidden and fr.duplicate_of is null)::int,
         count(*) filter (where fr.status = 'planned' and not fr.hidden and fr.duplicate_of is null)::int,
         count(*) filter (where fr.status = 'in_progress' and not fr.hidden and fr.duplicate_of is null)::int,
         count(*) filter (where fr.status = 'shipped' and not fr.hidden and fr.duplicate_of is null)::int,
         count(*) filter (where fr.status = 'declined' and not fr.hidden and fr.duplicate_of is null)::int,
         count(*) filter (where fr.hidden)::int,
         count(*) filter (where fr.duplicate_of is not null)::int,
         count(*) filter (where fr.created_at >= now() - interval '7 days' and not fr.hidden and fr.duplicate_of is null)::int
    into v_new, v_under_review, v_planned, v_in_progress, v_shipped, v_declined, v_hidden, v_merged, v_new_week
    from public.feature_requests fr;

  select coalesce(jsonb_agg(row_to_json(t)), '[]'::jsonb)
    into v_top_voted
    from (
      select fr.id, fr.title, fr.category, fr.status, fr.vote_count
        from public.feature_requests fr
       where not fr.hidden
         and fr.duplicate_of is null
         and fr.status in ('new', 'under_review', 'planned', 'in_progress')
       order by fr.vote_count desc, fr.created_at desc, fr.id desc
       limit 5
    ) t;

  return jsonb_build_object(
    'new', v_new,
    'under_review', v_under_review,
    'planned', v_planned,
    'in_progress', v_in_progress,
    'shipped', v_shipped,
    'declined', v_declined,
    'hidden', v_hidden,
    'merged', v_merged,
    'new_this_week', v_new_week,
    'top_voted', v_top_voted
  );
end;
$$;

create or replace function admin.list_feature_requests(
  p_search text default null,
  p_status text default null,
  p_category text default null,
  p_visibility text default 'active',
  p_sort text default 'votes_desc',
  p_limit int default 50,
  p_offset int default 0
) returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_search text := nullif(ltrim(btrim(coalesce(p_search, '')), '@'), '');
  v_folded_search text;
  v_status text := nullif(lower(btrim(coalesce(p_status, ''))), '');
  v_cat text := nullif(lower(btrim(coalesce(p_category, ''))), '');
  v_vis text := coalesce(nullif(lower(btrim(p_visibility)), ''), 'active');
  v_sort text := coalesce(nullif(lower(btrim(p_sort)), ''), 'votes_desc');
  v_limit int := greatest(1, least(coalesce(p_limit, 50), 200));
  v_offset int := greatest(0, coalesce(p_offset, 0));
  v_total int := 0;
  v_items jsonb := '[]'::jsonb;
begin
  v_uid := private.require_admin('moderator');
  v_folded_search := case when v_search is not null then private.fold_vi(v_search) else null end;

  with enriched as (
    select
      fr.id,
      fr.title,
      fr.body,
      fr.category,
      fr.status,
      fr.vote_count,
      (
        select count(distinct r.reporter_id)::int
          from public.reports r
         where r.target_feature_request_id = fr.id
           and r.deleted_at is null
           and r.status = 'open'
      ) as open_reports_count,
      fr.author_id,
      p.username as author_username,
      p.display_name as author_display_name,
      case
        when fr.author_id is not null and p.id is not null and p.deleted_at is null then
          jsonb_build_object(
            'user_id', p.id,
            'username', p.username,
            'display_name', p.display_name
          )
        else null
      end as author,
      fr.admin_reply,
      fr.admin_replied_at,
      fr.shipped_at,
      fr.duplicate_of,
      (
        select count(*)::int
          from public.feature_requests child
         where child.duplicate_of = fr.id
      ) as merged_children_count,
      fr.hidden,
      fr.moderated_at,
      fr.created_at,
      fr.updated_at
    from public.feature_requests fr
    left join public.profiles p on p.id = fr.author_id
    where (
            v_vis = 'all'
            or (v_vis in ('active', 'visible') and not fr.hidden and fr.duplicate_of is null)
            or (v_vis = 'hidden' and fr.hidden)
            or (v_vis = 'merged' and fr.duplicate_of is not null)
          )
      and (
            v_status is null
            or v_status in ('all', 'all_active')
            or fr.status = v_status
          )
      and (
            v_cat is null
            or v_cat = 'all'
            or fr.category = v_cat
          )
      and (
            v_folded_search is null
            or position(v_folded_search in private.fold_vi(fr.title)) > 0
            or position(v_folded_search in private.fold_vi(fr.body)) > 0
            or position(v_folded_search in private.fold_vi(coalesce(p.username, ''))) > 0
            or position(v_folded_search in private.fold_vi(coalesce(p.display_name, ''))) > 0
            or position(lower(v_search) in lower(fr.id::text)) > 0
          )
  )
  select count(*)::int,
         coalesce((
           select jsonb_agg(row_to_json(x))
             from (
               select *
                 from enriched e
                order by
                  case when v_sort = 'reports_desc' then e.open_reports_count else 0 end desc,
                  case when v_sort in ('votes_desc', 'reports_desc') then e.vote_count else 0 end desc,
                  case when v_sort = 'updated_desc' then e.updated_at else null end desc nulls last,
                  case when v_sort = 'oldest' then e.created_at else null end asc nulls last,
                  e.created_at desc,
                  e.id desc
                limit v_limit offset v_offset
             ) x
         ), '[]'::jsonb)
    into v_total, v_items
    from enriched;

  return jsonb_build_object(
    'total', v_total,
    'items', v_items
  );
end;
$$;

create or replace function admin.get_feature_request_detail(p_id uuid) returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  fr public.feature_requests%rowtype;
  p public.profiles%rowtype;
  v_has_author boolean := false;
  v_open_reports int := 0;
  v_merged_children jsonb := '[]'::jsonb;
  v_reports jsonb := '[]'::jsonb;
  v_voters jsonb := '[]'::jsonb;
begin
  v_uid := private.require_admin('moderator');
  if p_id is null then
    raise exception 'invalid' using errcode = 'P0001';
  end if;

  select * into fr from public.feature_requests where id = p_id;
  if not found then
    raise exception 'not_found' using errcode = 'P0001';
  end if;

  if fr.author_id is not null then
    select * into p from public.profiles where id = fr.author_id;
    v_has_author := found;
  end if;

  perform private.admin_log(
    v_uid,
    'feature_requests.view_detail',
    'feature_request',
    fr.id::text,
    null,
    jsonb_build_object('status', fr.status, 'vote_count', fr.vote_count)
  );

  select count(distinct r.reporter_id)::int into v_open_reports
    from public.reports r
   where r.target_feature_request_id = fr.id
     and r.deleted_at is null
     and r.status = 'open';

  select coalesce(jsonb_agg(
           jsonb_build_object(
             'id', c.id,
             'title', c.title,
             'author_id', c.author_id,
             'author_username', cp.username,
             'vote_count', c.vote_count,
             'created_at', c.created_at
           ) order by c.created_at desc, c.id desc
         ), '[]'::jsonb)
    into v_merged_children
    from public.feature_requests c
    left join public.profiles cp on cp.id = c.author_id
   where c.duplicate_of = fr.id;

  select coalesce(jsonb_agg(
           jsonb_build_object(
             'id', r.id,
             'reporter_id', r.reporter_id,
             'reporter_username', rp.username,
             'reason', r.reason::text,
             'note', r.note,
             'status', r.status,
             'created_at', r.created_at
           ) order by r.created_at desc
         ), '[]'::jsonb)
    into v_reports
    from public.reports r
    left join public.profiles rp on rp.id = r.reporter_id
   where r.target_feature_request_id = fr.id
     and r.deleted_at is null;

  select coalesce(jsonb_agg(row_to_json(v)), '[]'::jsonb)
    into v_voters
    from (
      select fv.user_id,
             vp.username,
             vp.display_name,
             (fr.author_id is not null and fv.user_id = fr.author_id) as is_author,
             fv.created_at as voted_at
        from public.feature_request_votes fv
        left join public.profiles vp on vp.id = fv.user_id
       where fv.request_id = fr.id
       order by (fr.author_id is not null and fv.user_id = fr.author_id) desc,
                fv.created_at desc
       limit 200
    ) v;

  return jsonb_build_object(
    'id', fr.id,
    'title', fr.title,
    'body', fr.body,
    'category', fr.category,
    'status', fr.status,
    'vote_count', fr.vote_count,
    'open_reports_count', v_open_reports,
    'author_id', fr.author_id,
    'author_username', case when v_has_author then p.username else null end,
    'author_display_name', case when v_has_author then p.display_name else null end,
    'author', case
      when v_has_author and p.deleted_at is null then
        jsonb_build_object(
          'user_id', p.id,
          'username', p.username,
          'display_name', p.display_name
        )
      else null
    end,
    'admin_reply', fr.admin_reply,
    'admin_replied_at', fr.admin_replied_at,
    'shipped_at', fr.shipped_at,
    'duplicate_of', fr.duplicate_of,
    'merged_children_count', jsonb_array_length(v_merged_children),
    'hidden', fr.hidden,
    'moderated_at', fr.moderated_at,
    'created_at', fr.created_at,
    'updated_at', fr.updated_at,
    'merged_children', v_merged_children,
    'reports', v_reports,
    'voters', v_voters
  );
end;
$$;

create or replace function admin.update_feature_request(
  p_id uuid,
  p_status text default null,
  p_category text default null,
  p_admin_reply text default null,
  p_hidden boolean default null,
  p_reason text default null
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_old public.feature_requests%rowtype;
  v_new public.feature_requests%rowtype;
  v_status text;
  v_cat text;
  v_reply text;
  v_hidden boolean;
  v_replied_at timestamptz;
  v_shipped_at timestamptz;
  v_notified int := 0;
begin
  v_uid := private.require_admin('moderator');
  if p_id is null then
    raise exception 'invalid' using errcode = 'P0001';
  end if;

  select * into v_old from public.feature_requests where id = p_id for update;
  if not found then
    raise exception 'not_found' using errcode = 'P0001';
  end if;

  v_status := coalesce(nullif(lower(btrim(p_status)), ''), v_old.status);
  if v_status not in ('new', 'under_review', 'planned', 'in_progress', 'shipped', 'declined') then
    raise exception 'invalid' using errcode = 'P0001';
  end if;

  v_cat := coalesce(nullif(lower(btrim(p_category)), ''), v_old.category);
  if v_cat not in ('camera', 'journeys', 'squad', 'sharing', 'design', 'other') then
    raise exception 'invalid' using errcode = 'P0001';
  end if;

  v_reply := nullif(btrim(coalesce(p_admin_reply, '')), '');
  if v_reply is not null then
    if char_length(v_reply) > 1000 then
      raise exception 'invalid' using errcode = '23514';
    end if;
    if v_reply is distinct from v_old.admin_reply then
      perform private.assert_clean_text(v_reply);
    end if;
  end if;

  v_hidden := coalesce(p_hidden, v_old.hidden);

  if v_reply is null then
    v_replied_at := null;
  elsif v_reply is distinct from v_old.admin_reply then
    v_replied_at := now();
  else
    v_replied_at := coalesce(v_old.admin_replied_at, now());
  end if;

  if v_status = 'shipped' then
    v_shipped_at := coalesce(v_old.shipped_at, now());
  else
    v_shipped_at := v_old.shipped_at;
  end if;

  perform set_config('ourney.fr_internal_write', 'on', true);
  update public.feature_requests
     set status = v_status,
         category = v_cat,
         admin_reply = v_reply,
         admin_replied_at = v_replied_at,
         shipped_at = v_shipped_at,
         hidden = v_hidden,
         moderated_at = case when v_hidden then v_old.moderated_at else null end
   where id = p_id
  returning * into v_new;
  perform set_config('ourney.fr_internal_write', '', true);

  -- When status is 'shipped' and not hidden, notify every non-deleted, unbanned voter and author
  -- (including voters/authors of duplicates merged into this request), excluding non-author
  -- voters who have a block relationship with the author or reported the request (P2-2).
  if v_status = 'shipped' and not v_hidden then
    insert into private.feature_request_notifications (user_id, request_id, is_author, created_at)
    select
      r.user_id,
      p_id,
      bool_or(r.is_author) as is_author,
      now()
    from (
      select v.user_id, (v.user_id is not distinct from v_new.author_id) as is_author
        from public.feature_request_votes v
       where v.request_id = p_id
      union all
      select v.user_id,
             (v.user_id is not distinct from v_new.author_id
              or v.user_id is not distinct from c.author_id) as is_author
        from public.feature_request_votes v
        join public.feature_requests c on c.id = v.request_id
       where c.duplicate_of = p_id
      union all
      select v_new.author_id as user_id, true as is_author
       where v_new.author_id is not null
      union all
      select c.author_id as user_id, true as is_author
        from public.feature_requests c
       where c.duplicate_of = p_id and c.author_id is not null
    ) r
    join public.profiles p on p.id = r.user_id and p.deleted_at is null
    where not private.is_user_banned(p.id)
      and (
        p.id is not distinct from v_new.author_id
        or (
          (v_new.author_id is null or not private.blocked_between(p.id, v_new.author_id))
          and not exists (
            select 1 from public.reports rep
             where rep.target_feature_request_id = p_id
               and rep.reporter_id = p.id
               and rep.deleted_at is null
          )
        )
      )
    group by r.user_id
    on conflict (user_id, request_id) do update
      set is_author = private.feature_request_notifications.is_author or excluded.is_author;
    get diagnostics v_notified = row_count;
  end if;

  perform private.admin_log(
    v_uid,
    'feature_requests.update',
    'feature_request',
    p_id::text,
    p_reason,
    jsonb_build_object(
      'old_status', v_old.status,
      'new_status', v_new.status,
      'old_category', v_old.category,
      'new_category', v_new.category,
      'old_hidden', v_old.hidden,
      'new_hidden', v_new.hidden,
      'has_admin_reply', (v_new.admin_reply is not null),
      'notified_users', v_notified
    )
  );

  return to_jsonb(v_new);
end;
$$;

create or replace function admin.merge_feature_request(
  p_source_id uuid,
  p_target_id uuid,
  p_reason text default null
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_source public.feature_requests%rowtype;
  v_target public.feature_requests%rowtype;
  v_transferred int := 0;
  v_target_votes int := 0;
begin
  v_uid := private.require_admin('moderator');
  if p_source_id is null or p_target_id is null or p_source_id = p_target_id then
    raise exception 'invalid' using errcode = 'P0001';
  end if;

  -- Lock source, target, and any existing children of source in deterministic UUID order (P1-1).
  perform 1
    from public.feature_requests
   where id in (p_source_id, p_target_id)
      or duplicate_of = p_source_id
   order by id
     for update;

  select * into v_source from public.feature_requests where id = p_source_id;
  if not found then
    raise exception 'not_found' using errcode = 'P0001';
  end if;

  select * into v_target from public.feature_requests where id = p_target_id;
  if not found then
    raise exception 'not_found' using errcode = 'P0001';
  end if;

  if v_target.duplicate_of is not null
     or v_source.duplicate_of is not null
     or v_target.hidden
     or v_target.status = 'declined' then
    raise exception 'invalid' using errcode = 'P0001';
  end if;

  -- Consolidate unique votes from p_source_id and any children previously merged into p_source_id.
  insert into public.feature_request_votes (request_id, user_id, created_at)
  select p_target_id, v.user_id, min(v.created_at)
    from public.feature_request_votes v
   where v.request_id = p_source_id
      or v.request_id in (
        select c.id from public.feature_requests c where c.duplicate_of = p_source_id
      )
   group by v.user_id
  on conflict (request_id, user_id) do nothing;
  get diagnostics v_transferred = row_count;

  perform set_config('ourney.fr_internal_write', 'on', true);

  update public.feature_requests
     set duplicate_of = p_target_id
   where duplicate_of = p_source_id;

  update public.feature_requests
     set duplicate_of = p_target_id
   where id = p_source_id;

  update public.feature_requests
     set vote_count = (
       select count(*)::int
         from public.feature_request_votes v
        where v.request_id = p_target_id
     )
   where id = p_target_id
  returning vote_count into v_target_votes;

  perform set_config('ourney.fr_internal_write', '', true);

  perform private.admin_log(
    v_uid,
    'feature_requests.merge',
    'feature_request',
    p_source_id::text,
    p_reason,
    jsonb_build_object(
      'merged_into', p_target_id,
      'transferred_votes', v_transferred,
      'target_vote_count', v_target_votes
    )
  );

  return jsonb_build_object(
    'source_id', p_source_id,
    'target_id', p_target_id,
    'transferred_votes', v_transferred,
    'target_vote_count', v_target_votes
  );
end;
$$;

revoke all on function
  admin.feature_request_stats(),
  admin.list_feature_requests(text, text, text, text, text, int, int),
  admin.get_feature_request_detail(uuid),
  admin.update_feature_request(uuid, text, text, text, boolean, text),
  admin.merge_feature_request(uuid, uuid, text),
  admin.list_moderation_queue(text, text, text, int, int),
  admin.get_moderation_item(uuid),
  admin.quarantine_moderation_target(uuid, text),
  admin.resolve_moderation(uuid, text, text)
from public, anon;

grant execute on function
  admin.feature_request_stats(),
  admin.list_feature_requests(text, text, text, text, text, int, int),
  admin.get_feature_request_detail(uuid),
  admin.update_feature_request(uuid, text, text, text, boolean, text),
  admin.merge_feature_request(uuid, uuid, text),
  admin.list_moderation_queue(text, text, text, int, int),
  admin.get_moderation_item(uuid),
  admin.quarantine_moderation_target(uuid, text),
  admin.resolve_moderation(uuid, text, text)
to authenticated, service_role;

notify pgrst, 'reload schema';
