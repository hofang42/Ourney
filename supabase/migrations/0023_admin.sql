-- 0023_admin: Ourney Admin Dashboard backend schema, private tables, audit trail,
--             5-minute scoped reported-media grants, and 30 SECURITY DEFINER RPCs in schema `admin`.
--
-- Amendments applied (admin-opus-review.md):
--   A1. Feature-request admin RPCs move out of 0023 into 0024_feature_requests.sql.
--       0023 exports `private.require_admin(p_min_role text)` and `private.admin_log(...)` for 0024.
--       Only `admin.overview_stats` includes the feature-request KPI block behind
--       `to_regclass('public.feature_requests') is not null` via EXECUTE (returns null when absent).
--   A2. Ban NEVER sets `public.profiles.deleted_at` (which means account deletion).
--       Ban = `auth.users.banned_until` + delete `auth.sessions`/`auth.refresh_tokens`
--             + `private.user_moderation` row + revoke `journeys.public_token`;
--       `p_wipe_ugc = true` additionally runs the 0020 UGC takedown. Unban reverses only the ban state.
--   A3. Unmerge is P2 (not implemented).
--   A4. 30 RPCs in schema `admin`; zero casual reading of arbitrary check-ins/messages/media;
--       reported-media grants only, 5-min TTL, audited.
--   A5. Every `admin.*` RPC is `SECURITY DEFINER SET search_path = ''`, calls
--       `private.require_admin(...)` as its first statement, and has EXECUTE revoked from
--       `public, anon` and granted to `authenticated, service_role`.
--   A7. Reads `profiles.terms_version` dynamically only if the column exists (via information_schema + EXECUTE).
--
-- Idempotent (create or replace, drop if exists, if not exists).

-- ---------------------------------------------------------------------------
-- 1. Schema `admin` (RPC-only; zero tables or views)
-- ---------------------------------------------------------------------------
create schema if not exists admin;
revoke all on schema admin from public, anon;
grant usage on schema admin to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 2. Admin tables in schema `private` (RLS enabled, no policies, service_role only)
-- ---------------------------------------------------------------------------
create table if not exists private.admins (
  user_id uuid primary key references auth.users (id) on delete cascade,
  role text not null check (role in ('owner', 'moderator')),
  note text check (note is null or char_length(note) <= 500),
  added_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table private.admins enable row level security;
revoke all on private.admins from public, anon, authenticated;
grant select, insert, update, delete on private.admins to service_role;

create table if not exists private.admin_audit (
  id bigint generated always as identity primary key,
  admin_id uuid references auth.users (id) on delete set null,
  admin_email text,
  action text not null check (char_length(btrim(action)) between 2 and 120),
  target_type text not null
    check (target_type in (
      'system', 'admin', 'user', 'journey', 'moderation_queue',
      'checkin', 'message', 'feature_request', 'waitlist', 'word'
    )),
  target_id text,
  reason text check (reason is null or char_length(reason) <= 500),
  meta jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists admin_audit_created_idx on private.admin_audit (created_at desc, id desc);
create index if not exists admin_audit_admin_idx on private.admin_audit (admin_id, id desc);
create index if not exists admin_audit_action_idx on private.admin_audit (action, id desc);
create index if not exists admin_audit_target_idx on private.admin_audit (target_type, target_id, id desc);

alter table private.admin_audit enable row level security;
revoke all on private.admin_audit from public, anon, authenticated;
grant select, insert on private.admin_audit to service_role;

create or replace function private.admin_audit_immutable() returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  raise exception 'immutable_audit_log' using errcode = '42501';
end;
$$;

drop trigger if exists admin_audit_immutable on private.admin_audit;
create trigger admin_audit_immutable
  before update or delete on private.admin_audit
  for each row execute function private.admin_audit_immutable();

revoke all on function private.admin_audit_immutable() from public, anon, authenticated;

create table if not exists private.admin_media_grants (
  admin_id uuid not null references auth.users (id) on delete cascade,
  bucket_id text not null check (bucket_id in ('media', 'messages')),
  object_path text not null check (char_length(object_path) between 1 and 1024),
  queue_id uuid not null references public.moderation_queue (id) on delete cascade,
  expires_at timestamptz not null,
  created_at timestamptz not null default now(),
  primary key (admin_id, bucket_id, object_path)
);

create index if not exists admin_media_grants_expires_idx on private.admin_media_grants (expires_at);

alter table private.admin_media_grants enable row level security;
revoke all on private.admin_media_grants from public, anon, authenticated;
grant select, insert, update, delete on private.admin_media_grants to service_role;

create table if not exists private.user_moderation (
  user_id uuid primary key references auth.users (id) on delete cascade,
  banned_at timestamptz,
  banned_by uuid references auth.users (id) on delete set null,
  ban_reason text check (ban_reason is null or char_length(ban_reason) <= 500),
  wiped_ugc boolean not null default false,
  unbanned_at timestamptz,
  unbanned_by uuid references auth.users (id) on delete set null,
  unban_reason text check (unban_reason is null or char_length(unban_reason) <= 500),
  updated_at timestamptz not null default now()
);

alter table private.user_moderation enable row level security;
revoke all on private.user_moderation from public, anon, authenticated;
grant select, insert, update, delete on private.user_moderation to service_role;

-- ---------------------------------------------------------------------------
-- 3. Shared Admin Authorization & Audit Helpers (exported for 0024_feature_requests.sql)
-- ---------------------------------------------------------------------------
create or replace function private.is_user_banned(p_user uuid) returns boolean
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_auth_banned boolean := false;
  v_mod_banned boolean := false;
begin
  if p_user is null then
    return false;
  end if;

  if exists (
    select 1 from information_schema.columns
     where table_schema = 'auth' and table_name = 'users' and column_name = 'banned_until'
  ) then
    execute 'select coalesce(banned_until > now(), false) from auth.users where id = $1'
      into v_auth_banned
      using p_user;
  end if;

  select exists (
    select 1 from private.user_moderation um
     where um.user_id = p_user
       and um.banned_at is not null
       and um.unbanned_at is null
  ) into v_mod_banned;

  return coalesce(v_auth_banned, false) or coalesce(v_mod_banned, false);
end;
$$;

revoke all on function private.is_user_banned(uuid) from public, anon, authenticated;
grant execute on function private.is_user_banned(uuid) to service_role;

-- Verifies caller is an active, unbanned admin with at least `p_min_role` ('moderator' or 'owner').
-- Raises SQLSTATE 42501 ('forbidden') if unauthenticated, not in private.admins, banned, soft-deleted,
-- or insufficient role. Returns caller's user_id.
create or replace function private.require_admin(p_min_role text default 'moderator') returns uuid
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
  v_role text;
  v_min text := coalesce(nullif(lower(btrim(p_min_role)), ''), 'moderator');
begin
  if v_min not in ('moderator', 'owner') then
    raise exception 'invalid' using errcode = 'P0001';
  end if;

  if v_uid is null then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  select a.role into v_role
    from private.admins a
    join auth.users u on u.id = a.user_id
   where a.user_id = v_uid;

  if v_role is null then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  if private.is_user_banned(v_uid) then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  if exists (
    select 1 from public.profiles p
     where p.id = v_uid and p.deleted_at is not null
  ) then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  if v_min = 'owner' and v_role <> 'owner' then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  return v_uid;
end;
$$;

revoke all on function private.require_admin(text) from public, anon, authenticated;
grant execute on function private.require_admin(text) to service_role;

-- Appends an immutable audit entry to private.admin_audit.
-- Exported in two overloads (5-arg using auth.uid(), and 6-arg with explicit p_admin_id)
-- so 0023, 0024, and service_role helpers can all call private.admin_log cleanly.
create or replace function private.admin_log(
  p_admin_id uuid,
  p_action text,
  p_target_type text,
  p_target_id text default null,
  p_reason text default null,
  p_meta jsonb default '{}'::jsonb
) returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := coalesce(p_admin_id, (select auth.uid()));
  v_email text;
  v_id bigint;
begin
  if v_uid is not null then
    select lower(u.email) into v_email from auth.users u where u.id = v_uid;
  end if;

  insert into private.admin_audit (
    admin_id, admin_email, action, target_type, target_id, reason, meta
  )
  values (
    v_uid,
    v_email,
    btrim(p_action),
    btrim(p_target_type),
    nullif(btrim(p_target_id), ''),
    left(nullif(btrim(p_reason), ''), 500),
    coalesce(p_meta, '{}'::jsonb)
  )
  returning id into v_id;

  return v_id;
end;
$$;

create or replace function private.admin_log(
  p_action text,
  p_target_type text,
  p_target_id text default null,
  p_reason text default null,
  p_meta jsonb default '{}'::jsonb
) returns bigint
language plpgsql
security definer
set search_path = ''
as $$
begin
  return private.admin_log(
    (select auth.uid()),
    p_action,
    p_target_type,
    p_target_id,
    p_reason,
    p_meta
  );
end;
$$;

revoke all on function
  private.admin_log(uuid, text, text, text, text, jsonb),
  private.admin_log(text, text, text, text, jsonb)
from public, anon, authenticated;
grant execute on function
  private.admin_log(uuid, text, text, text, text, jsonb),
  private.admin_log(text, text, text, text, jsonb)
to service_role;

-- ---------------------------------------------------------------------------
-- 4. Storage Policy for 5-Minute Scoped Reported-Media Grants
-- ---------------------------------------------------------------------------
create or replace function private.can_admin_read_reported_object(p_bucket text, p_name text)
returns boolean
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
begin
  if v_uid is null or p_bucket is null or p_name is null then
    return false;
  end if;

  if not exists (select 1 from private.admins a where a.user_id = v_uid) then
    return false;
  end if;

  if private.is_user_banned(v_uid) then
    return false;
  end if;

  if exists (select 1 from public.profiles p where p.id = v_uid and p.deleted_at is not null) then
    return false;
  end if;

  return exists (
    select 1
      from private.admin_media_grants g
     where g.admin_id = v_uid
       and g.bucket_id = p_bucket
       and g.object_path = p_name
       and g.expires_at > now()
  );
end;
$$;

revoke all on function private.can_admin_read_reported_object(text, text) from public, anon;
grant execute on function private.can_admin_read_reported_object(text, text) to authenticated, service_role;

drop policy if exists admin_reported_media_select on storage.objects;
create policy admin_reported_media_select on storage.objects for select to authenticated
using (
  bucket_id in ('media', 'messages')
  and private.can_admin_read_reported_object(bucket_id, name)
);

-- ---------------------------------------------------------------------------
-- 5. Internal Ban / Takedown & Session Revocation Helpers (Amendment A2)
-- ---------------------------------------------------------------------------
create or replace function private.revoke_user_sessions_internal(p_user uuid) returns int
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_deleted int := 0;
begin
  if p_user is null then
    return 0;
  end if;

  if exists (
    select 1 from information_schema.tables
     where table_schema = 'auth' and table_name = 'refresh_tokens'
  ) then
    execute 'delete from auth.refresh_tokens where user_id::text = $1::text'
      using p_user;
  end if;

  if exists (
    select 1 from information_schema.tables
     where table_schema = 'auth' and table_name = 'sessions'
  ) then
    execute 'delete from auth.sessions where user_id = $1'
      using p_user;
    get diagnostics v_deleted = row_count;
  end if;

  return v_deleted;
end;
$$;

-- A2: Ban MUST NOT set public.profiles.deleted_at.
-- Ban = auth.users.banned_until + delete auth.sessions/refresh_tokens + private.user_moderation row
--       + revoke journeys.public_token; wipe_ugc variant reuses 0020 takedown.
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
    -- Reuse 0020 takedown (without touching public.profiles.deleted_at):
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

revoke all on function
  private.revoke_user_sessions_internal(uuid),
  private.ban_user_internal(uuid, uuid, text, boolean)
from public, anon, authenticated;
grant execute on function
  private.revoke_user_sessions_internal(uuid),
  private.ban_user_internal(uuid, uuid, text, boolean)
to service_role;

-- ---------------------------------------------------------------------------
-- 6. RPC 1: Auth / Self (`admin.me`)
-- ---------------------------------------------------------------------------
create or replace function admin.me() returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_out jsonb;
begin
  v_uid := private.require_admin('moderator');

  select jsonb_build_object(
           'user_id', a.user_id,
           'email', u.email,
           'role', a.role,
           'username', p.username,
           'display_name', p.display_name,
           'avatar_path', p.avatar_path,
           'note', a.note,
           'created_at', a.created_at,
           'updated_at', a.updated_at
         )
    into v_out
    from private.admins a
    join auth.users u on u.id = a.user_id
    left join public.profiles p on p.id = a.user_id
   where a.user_id = v_uid;

  return v_out;
end;
$$;

-- ---------------------------------------------------------------------------
-- 7. RPC 2: Overview (`admin.overview_stats`)
-- ---------------------------------------------------------------------------
create or replace function admin.overview_stats(
  p_days int default 30,
  p_tz text default 'Asia/Ho_Chi_Minh'
) returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_days int;
  v_tz text;
  v_today date;
  v_open_reports int := 0;
  v_open_blocks int := 0;
  v_overdue_count int := 0;
  v_earliest_due timestamptz;
  v_earliest_hours numeric;
  v_sla_30d numeric := 100.0;
  v_failed_waitlist int := 0;
  v_pending_purge int := 0;
  v_stuck_purge int := 0;
  v_total_auth int := 0;
  v_live_profiles int := 0;
  v_deleted_profiles int := 0;
  v_banned_users int := 0;
  v_new_users_today int := 0;
  v_new_users_7d int := 0;
  v_waitlist_total int := 0;
  v_waitlist_7d int := 0;
  v_waitlist_converted int := 0;
  v_dau int := 0;
  v_wau int := 0;
  v_mau int := 0;
  v_avg_dau_7d numeric := 0;
  v_stickiness numeric := 0;
  v_auth_signins_1d int := 0;
  v_auth_signins_7d int := 0;
  v_checkins_today int := 0;
  v_checkins_7d int := 0;
  v_camera_7d int := 0;
  v_library_7d int := 0;
  v_streak_3d int := 0;
  v_streak_7d int := 0;
  v_streak_14d int := 0;
  v_streak_30d int := 0;
  v_signup_7d int := 0;
  v_terms_7d int := 0;
  v_profile_7d int := 0;
  v_journey_7d int := 0;
  v_checkin_first_7d int := 0;
  v_social_7d int := 0;
  v_feature_requests jsonb := null;
  v_untriaged_fr int := 0;
  v_daily_growth jsonb := '[]'::jsonb;
  v_daily_pulse jsonb := '[]'::jsonb;
  v_funnel jsonb := '[]'::jsonb;
  v_cohorts jsonb := '[]'::jsonb;
  v_template_mix jsonb := '[]'::jsonb;
begin
  v_uid := private.require_admin('moderator');
  v_days := greatest(1, least(coalesce(p_days, 30), 90));
  v_tz := coalesce(nullif(btrim(p_tz), ''), 'Asia/Ho_Chi_Minh');

  -- Validate IANA timezone (raises 22023 on invalid timezone).
  perform now() at time zone v_tz;
  v_today := public.local_date(now(), v_tz);

  -- Moderation SLA metrics
  select count(*) filter (where q.status = 'open' and q.kind = 'report')::int,
         count(*) filter (where q.status = 'open' and q.kind = 'block')::int,
         count(*) filter (where q.status = 'open' and q.due_at <= now())::int,
         min(q.due_at) filter (where q.status = 'open'),
         coalesce(
           round(
             100.0 * count(*) filter (
               where q.created_at >= now() - interval '30 days'
                 and (
                   (q.status in ('actioned', 'dismissed') and coalesce(q.handled_at, q.updated_at) <= q.due_at)
                   or (q.status = 'open' and q.due_at > now())
                 )
             )::numeric / nullif(count(*) filter (where q.created_at >= now() - interval '30 days'), 0),
             1
           ),
           100.0
         )
    into v_open_reports, v_open_blocks, v_overdue_count, v_earliest_due, v_sla_30d
    from public.moderation_queue q;

  if v_earliest_due is not null then
    v_earliest_hours := round((extract(epoch from (v_earliest_due - now())) / 3600.0)::numeric, 2);
  end if;

  -- Storage purge & waitlist alerts
  select count(*) filter (where s.attempts < 20)::int,
         count(*) filter (where s.attempts >= 20)::int
    into v_pending_purge, v_stuck_purge
    from private.pending_storage_purge s;

  select count(*)::int,
         count(*) filter (where w.created_at >= now() - interval '7 days')::int,
         count(*) filter (where w.confirmation_error is not null)::int,
         count(*) filter (
           where exists (select 1 from auth.users u where lower(u.email) = w.email)
         )::int
    into v_waitlist_total, v_waitlist_7d, v_failed_waitlist, v_waitlist_converted
    from private.waitlist w;

  -- Users KPI
  select count(*)::int,
         count(*) filter (where u.last_sign_in_at >= now() - interval '1 day')::int,
         count(*) filter (where u.last_sign_in_at >= now() - interval '7 days')::int
    into v_total_auth, v_auth_signins_1d, v_auth_signins_7d
    from auth.users u;

  select count(*) filter (where p.deleted_at is null)::int,
         count(*) filter (where p.deleted_at is not null)::int,
         count(*) filter (where p.deleted_at is null and public.local_date(p.created_at, v_tz) = v_today)::int,
         count(*) filter (where p.deleted_at is null and p.created_at >= now() - interval '7 days')::int
    into v_live_profiles, v_deleted_profiles, v_new_users_today, v_new_users_7d
    from public.profiles p;

  select count(*)::int
    into v_banned_users
    from auth.users u
   where private.is_user_banned(u.id);

  -- Meaningful DAU / WAU / MAU (distinct non-deleted users performing >= 1 habit/social write)
  with events as (
    select c.user_id, c.created_at as at
      from public.check_ins c
      join public.journeys j on j.id = c.journey_id and j.deleted_at is null
     where c.deleted_at is null and j.origin = 'live'
    union all
    select r.user_id, r.created_at as at
      from public.reactions r
     where r.deleted_at is null
    union all
    select m.sender_id as user_id, m.created_at as at
      from public.messages m
     where m.deleted_at is null
    union all
    select j.owner_id as user_id, j.created_at as at
      from public.journeys j
     where j.deleted_at is null
    union all
    select mb.user_id, mb.joined_at as at
      from public.memberships mb
     where mb.deleted_at is null
  )
  select count(distinct e.user_id) filter (where e.at >= now() - interval '1 day')::int,
         count(distinct e.user_id) filter (where e.at >= now() - interval '7 days')::int,
         count(distinct e.user_id) filter (where e.at >= now() - interval '30 days')::int,
         coalesce((
           select round(avg(d.cnt)::numeric, 2)
             from (
               select (v_today - g.offs) as d_day,
                      count(distinct e2.user_id) filter (
                        where public.local_date(e2.at, v_tz) = (v_today - g.offs)
                      )::int as cnt
                 from generate_series(0, 6) as g(offs)
                 left join events e2 on public.local_date(e2.at, v_tz) = (v_today - g.offs)
                 left join public.profiles p2 on p2.id = e2.user_id and p2.deleted_at is null
                group by g.offs
             ) d
         ), 0)
    into v_dau, v_wau, v_mau, v_avg_dau_7d
    from events e
    join public.profiles p on p.id = e.user_id and p.deleted_at is null;

  if v_mau > 0 then
    v_stickiness := round((100.0 * v_avg_dau_7d / v_mau)::numeric, 1);
  end if;

  -- Check-ins today & 7d (live journeys, non-deleted)
  select count(*) filter (where public.local_date(c.captured_at, v_tz) = v_today and j.origin = 'live')::int,
         count(*) filter (where c.captured_at >= now() - interval '7 days' and j.origin = 'live')::int,
         count(*) filter (where c.captured_at >= now() - interval '7 days' and j.origin = 'live' and not c.from_library)::int,
         count(*) filter (where c.captured_at >= now() - interval '7 days' and (j.origin = 'imported' or c.from_library))::int
    into v_checkins_today, v_checkins_7d, v_camera_7d, v_library_7d
    from public.check_ins c
    join public.journeys j on j.id = c.journey_id and j.deleted_at is null
   where c.deleted_at is null and c.moderated_at is null;

  -- Active streaks across live active journeys
  with user_streaks as (
    select m.user_id,
           max(s.current_streak)::int as max_streak
      from public.memberships m
      join public.profiles p on p.id = m.user_id and p.deleted_at is null
      join public.journeys j on j.id = m.journey_id and j.deleted_at is null
      cross join lateral public.journey_streak(j.id, m.user_id, public.local_date(now(), j.timezone)) s
     where m.status = 'active'
       and m.deleted_at is null
       and j.origin = 'live'
       and j.status = 'active'
       and (j.duration_days is null or public.local_date(now(), j.timezone) <= j.start_date + j.duration_days - 1)
     group by m.user_id
  )
  select count(*) filter (where max_streak >= 3)::int,
         count(*) filter (where max_streak >= 7)::int,
         count(*) filter (where max_streak >= 14)::int,
         count(*) filter (where max_streak >= 30)::int
    into v_streak_3d, v_streak_7d, v_streak_14d, v_streak_30d
    from user_streaks;

  -- A1: Feature-request KPI block behind to_regclass('public.feature_requests') is not null via EXECUTE
  if to_regclass('public.feature_requests') is not null then
    execute $fr$
      select jsonb_build_object(
        'new_7d', count(*) filter (where created_at >= now() - interval '7 days' and not hidden and duplicate_of is null)::int,
        'untriaged_count', count(*) filter (where status = 'new' and not hidden and duplicate_of is null)::int,
        'open_count', count(*) filter (where status in ('new', 'under_review', 'planned', 'in_progress') and not hidden and duplicate_of is null)::int,
        'shipped_count', count(*) filter (where status = 'shipped' and not hidden and duplicate_of is null)::int,
        'top_voted', coalesce((
          select jsonb_agg(row_to_json(t))
            from (
              select id, title, category, status, vote_count, created_at
                from public.feature_requests
               where not hidden
                 and duplicate_of is null
                 and status in ('new', 'under_review', 'planned', 'in_progress')
               order by vote_count desc, created_at desc
               limit 5
            ) t
        ), '[]'::jsonb)
      )
      from public.feature_requests
    $fr$ into v_feature_requests;
    v_untriaged_fr := coalesce((v_feature_requests ->> 'untriaged_count')::int, 0);
  end if;

  -- Daily growth series (v_days)
  select coalesce(jsonb_agg(
           jsonb_build_object(
             'day', d.day::text,
             'new_profiles', coalesce(p.cnt, 0),
             'new_waitlist', coalesce(w.cnt, 0)
           ) order by d.day
         ), '[]'::jsonb)
    into v_daily_growth
    from (
      select (v_today - (v_days - 1) + g.offs) as day
        from generate_series(0, v_days - 1) as g(offs)
    ) d
    left join (
      select public.local_date(created_at, v_tz) as day, count(*)::int as cnt
        from public.profiles
       where deleted_at is null
         and created_at >= now() - make_interval(days => v_days + 2)
       group by 1
    ) p on p.day = d.day
    left join (
      select public.local_date(created_at, v_tz) as day, count(*)::int as cnt
        from private.waitlist
       where created_at >= now() - make_interval(days => v_days + 2)
       group by 1
    ) w on w.day = d.day;

  -- Daily habit pulse series (v_days)
  with events as (
    select c.user_id, public.local_date(c.captured_at, v_tz) as day
      from public.check_ins c
      join public.journeys j on j.id = c.journey_id and j.deleted_at is null
     where c.deleted_at is null and j.origin = 'live'
       and c.captured_at >= now() - make_interval(days => v_days + 2)
    union all
    select r.user_id, public.local_date(r.created_at, v_tz) as day
      from public.reactions r
     where r.deleted_at is null
       and r.created_at >= now() - make_interval(days => v_days + 2)
    union all
    select m.sender_id as user_id, public.local_date(m.created_at, v_tz) as day
      from public.messages m
     where m.deleted_at is null
       and m.created_at >= now() - make_interval(days => v_days + 2)
  )
  select coalesce(jsonb_agg(
           jsonb_build_object(
             'day', d.day::text,
             'dau', coalesce(ev.dau, 0),
             'live_checkins', coalesce(ci.cnt, 0)
           ) order by d.day
         ), '[]'::jsonb)
    into v_daily_pulse
    from (
      select (v_today - (v_days - 1) + g.offs) as day
        from generate_series(0, v_days - 1) as g(offs)
    ) d
    left join (
      select e.day, count(distinct e.user_id)::int as dau
        from events e
        join public.profiles p on p.id = e.user_id and p.deleted_at is null
       group by e.day
    ) ev on ev.day = d.day
    left join (
      select public.local_date(c.captured_at, v_tz) as day, count(*)::int as cnt
        from public.check_ins c
        join public.journeys j on j.id = c.journey_id and j.deleted_at is null
       where c.deleted_at is null and c.moderated_at is null and j.origin = 'live'
         and c.captured_at >= now() - make_interval(days => v_days + 2)
       group by 1
    ) ci on ci.day = d.day;

  -- 7-Day Activation Funnel (A7: dynamic check for profiles.terms_version)
  select count(*)::int
    into v_signup_7d
    from auth.users u
   where u.created_at >= now() - interval '7 days';

  select count(*)::int,
         count(*) filter (
           where exists (select 1 from public.memberships m where m.user_id = u.id and m.deleted_at is null)
         )::int,
         count(*) filter (
           where exists (
             select 1 from public.check_ins c
               join public.journeys j on j.id = c.journey_id and j.deleted_at is null
              where c.user_id = u.id and c.deleted_at is null and j.origin = 'live'
           )
         )::int,
         count(*) filter (
           where exists (
             select 1 from public.memberships m
               join public.journeys j on j.id = m.journey_id and j.deleted_at is null
              where m.user_id = u.id and m.status = 'active' and m.deleted_at is null and j.kind = 'group'
           )
           or exists (
             select 1 from public.friendships f
              where (f.user_low = u.id or f.user_high = u.id)
                and f.status = 'accepted' and f.deleted_at is null
           )
           or exists (
             select 1 from public.journey_shares js
              where (js.shared_by = u.id or js.viewer_id = u.id) and js.revoked_at is null
           )
         )::int
    into v_profile_7d, v_journey_7d, v_checkin_first_7d, v_social_7d
    from auth.users u
    join public.profiles p on p.id = u.id and p.deleted_at is null
   where u.created_at >= now() - interval '7 days';

  if exists (
    select 1 from information_schema.columns
     where table_schema = 'public' and table_name = 'profiles' and column_name = 'terms_version'
  ) then
    execute $tv$
      select count(*)::int
        from auth.users u
        join public.profiles p on p.id = u.id and p.deleted_at is null
       where u.created_at >= now() - interval '7 days'
         and coalesce(p.terms_version, 0) >= 1
    $tv$ into v_terms_7d;
  else
    v_terms_7d := v_profile_7d;
  end if;

  v_funnel := jsonb_build_array(
    jsonb_build_object(
      'step', 'auth_signup',
      'label', 'Auth Signup',
      'count', v_signup_7d,
      'conversion_pct', case when v_signup_7d > 0 then 100.0 else 0.0 end
    ),
    jsonb_build_object(
      'step', 'terms_accepted',
      'label', 'Accepted Terms',
      'count', v_terms_7d,
      'conversion_pct', case when v_signup_7d > 0 then round(100.0 * v_terms_7d / v_signup_7d, 1) else 0.0 end
    ),
    jsonb_build_object(
      'step', 'profile_created',
      'label', 'Created Profile',
      'count', v_profile_7d,
      'conversion_pct', case when v_signup_7d > 0 then round(100.0 * v_profile_7d / v_signup_7d, 1) else 0.0 end
    ),
    jsonb_build_object(
      'step', 'first_journey',
      'label', 'Joined / Created Journey',
      'count', v_journey_7d,
      'conversion_pct', case when v_signup_7d > 0 then round(100.0 * v_journey_7d / v_signup_7d, 1) else 0.0 end
    ),
    jsonb_build_object(
      'step', 'first_live_checkin',
      'label', 'Posted 1st Check-in',
      'count', v_checkin_first_7d,
      'conversion_pct', case when v_signup_7d > 0 then round(100.0 * v_checkin_first_7d / v_signup_7d, 1) else 0.0 end
    ),
    jsonb_build_object(
      'step', 'social_connected',
      'label', 'Joined Squad / Added Friend',
      'count', v_social_7d,
      'conversion_pct', case when v_signup_7d > 0 then round(100.0 * v_social_7d / v_signup_7d, 1) else 0.0 end
    )
  );

  -- Weekly Cohort Retention (last 8 weeks)
  with cohorts as (
    select date_trunc('week', p.created_at at time zone v_tz)::date as cohort_week,
           p.id as user_id,
           public.local_date(p.created_at, v_tz) as signup_date
      from public.profiles p
     where p.deleted_at is null
       and p.created_at >= now() - interval '8 weeks'
  ),
  activity_days as (
    select c.user_id, c.local_date as act_date
      from public.check_ins c
     where c.deleted_at is null
    union
    select r.user_id, public.local_date(r.created_at, v_tz) as act_date
      from public.reactions r
     where r.deleted_at is null
    union
    select m.sender_id as user_id, public.local_date(m.created_at, v_tz) as act_date
      from public.messages m
     where m.deleted_at is null
  ),
  cohort_agg as (
    select c.cohort_week,
           count(distinct c.user_id)::int as cohort_size,
           count(distinct c.user_id) filter (
             where exists (
               select 1 from activity_days a
                where a.user_id = c.user_id and a.act_date between c.signup_date + 1 and c.signup_date + 2
             )
           )::int as d1_users,
           count(distinct c.user_id) filter (
             where exists (
               select 1 from activity_days a
                where a.user_id = c.user_id and a.act_date between c.signup_date + 6 and c.signup_date + 8
             )
           )::int as d7_users,
           count(distinct c.user_id) filter (
             where exists (
               select 1 from activity_days a
                where a.user_id = c.user_id and a.act_date between c.signup_date + 13 and c.signup_date + 15
             )
           )::int as d14_users,
           count(distinct c.user_id) filter (
             where exists (
               select 1 from activity_days a
                where a.user_id = c.user_id and a.act_date between c.signup_date + 28 and c.signup_date + 31
             )
           )::int as d30_users
      from cohorts c
     group by c.cohort_week
  )
  select coalesce(jsonb_agg(
           jsonb_build_object(
             'cohort_week', ca.cohort_week::text,
             'cohort_size', ca.cohort_size,
             'd1_pct', case when ca.cohort_size > 0 then round(100.0 * ca.d1_users / ca.cohort_size, 1) else 0.0 end,
             'd7_pct', case when ca.cohort_size > 0 then round(100.0 * ca.d7_users / ca.cohort_size, 1) else 0.0 end,
             'd14_pct', case when ca.cohort_size > 0 then round(100.0 * ca.d14_users / ca.cohort_size, 1) else 0.0 end,
             'd30_pct', case when ca.cohort_size > 0 then round(100.0 * ca.d30_users / ca.cohort_size, 1) else 0.0 end
           ) order by ca.cohort_week desc
         ), '[]'::jsonb)
    into v_cohorts
    from cohort_agg ca;

  -- Persona / Template Mix (6 canonical personas)
  with classified as (
    select case
             when j.layout = 'couple_rituals' or j.couple_self_name is not null then 'couple'
             when j.template_id = 'weight_loss' or j.layout = 'quiet_transformer' then 'weight_loss'
             when j.template_id = 'english_daily' or j.layout = 'accountability_squad' then 'english_daily'
             when j.template_id = 'travel' or j.layout = 'memory_collectors' then 'travel'
             when j.template_id = 'workout_30' or j.layout = 'aesthetic_flexer' then 'workout_30'
             else 'custom'
           end as persona_key
      from public.journeys j
     where j.deleted_at is null and j.status = 'active'
  ),
  palette(persona_key, ord) as (
    values
      ('weight_loss', 1),
      ('english_daily', 2),
      ('travel', 3),
      ('couple', 4),
      ('workout_30', 5),
      ('custom', 6)
  )
  select coalesce(jsonb_agg(
           jsonb_build_object(
             'template', pl.persona_key,
             'active_journeys', coalesce(c.cnt, 0)
           ) order by pl.ord
         ), '[]'::jsonb)
    into v_template_mix
    from palette pl
    left join (
      select persona_key, count(*)::int as cnt
        from classified
       group by persona_key
    ) c on c.persona_key = pl.persona_key;

  return jsonb_build_object(
    'timezone', v_tz,
    'days', v_days,
    'generated_at', now(),
    'alerts', jsonb_build_object(
      'open_reports', v_open_reports,
      'open_blocks', v_open_blocks,
      'overdue_reports', v_overdue_count,
      'earliest_due_at', v_earliest_due,
      'earliest_hours_remaining', v_earliest_hours,
      'untriaged_feature_requests', v_untriaged_fr,
      'failed_waitlist_emails', v_failed_waitlist,
      'pending_storage_purge', v_pending_purge,
      'stuck_storage_purge', v_stuck_purge
    ),
    'kpis', jsonb_build_object(
      'users', jsonb_build_object(
        'total_auth', v_total_auth,
        'live_profiles', v_live_profiles,
        'deleted_profiles', v_deleted_profiles,
        'banned_users', v_banned_users,
        'new_today', v_new_users_today,
        'new_7d', v_new_users_7d
      ),
      'waitlist', jsonb_build_object(
        'total', v_waitlist_total,
        'new_7d', v_waitlist_7d,
        'converted_count', v_waitlist_converted,
        'converted_pct', case when v_waitlist_total > 0
                              then round(100.0 * v_waitlist_converted / v_waitlist_total, 1)
                              else 0.0 end,
        'failed_emails', v_failed_waitlist
      ),
      'engagement', jsonb_build_object(
        'dau', v_dau,
        'wau', v_wau,
        'mau', v_mau,
        'avg_dau_7d', v_avg_dau_7d,
        'stickiness_pct', v_stickiness,
        'auth_signins_1d', v_auth_signins_1d,
        'auth_signins_7d', v_auth_signins_7d
      ),
      'checkins', jsonb_build_object(
        'today', v_checkins_today,
        'last_7d', v_checkins_7d,
        'camera_7d', v_camera_7d,
        'library_7d', v_library_7d,
        'camera_pct_7d', case when (v_camera_7d + v_library_7d) > 0
                              then round(100.0 * v_camera_7d / (v_camera_7d + v_library_7d), 1)
                              else 100.0 end
      ),
      'streaks', jsonb_build_object(
        'streak_3d_plus', v_streak_3d,
        'streak_7d_plus', v_streak_7d,
        'streak_14d_plus', v_streak_14d,
        'streak_30d_plus', v_streak_30d
      ),
      'moderation', jsonb_build_object(
        'open_reports', v_open_reports,
        'open_blocks', v_open_blocks,
        'overdue_count', v_overdue_count,
        'sla_compliance_pct_30d', v_sla_30d
      ),
      'feature_requests', v_feature_requests
    ),
    'daily_growth', v_daily_growth,
    'daily_habit_pulse', v_daily_pulse,
    'activation_funnel_7d', v_funnel,
    'cohort_retention', v_cohorts,
    'template_mix', v_template_mix
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- 8. RPCs 3..7: Moderation Queue (24-Hour SLA & Scoped Audited Media Reveal)
-- ---------------------------------------------------------------------------
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
             where q.status = 'open' and (ci.moderated_at is not null or msg.moderated_at is not null)
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
    left join public.messages msg on msg.id = q.target_message_id;

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
      coalesce(ci.moderated_at is not null, msg.moderated_at is not null, false) as auto_quarantined,
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
             or (q.target_checkin_id is null and q.target_message_id is null
                 and q.target_user_id is not null and r.target_user_id = q.target_user_id
                 and r.target_checkin_id is null and r.target_message_id is null)
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
    where (
            v_status = 'all'
            or (v_status = 'overdue' and q.status = 'open' and q.due_at <= now())
            or (v_status = 'quarantined' and (ci.moderated_at is not null or msg.moderated_at is not null))
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

-- Scoped moderation detail inspector: returns ONLY the single reported check-in or single reported message
-- (never surrounding chat messages or unreported check-ins) and writes `moderation.view_item` to audit log.
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
      'target_message_id', q.target_message_id
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
       or (q.target_checkin_id is null and q.target_message_id is null
           and q.target_user_id is not null and r.target_user_id = q.target_user_id
           and r.target_checkin_id is null and r.target_message_id is null)
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
    -- Strictly ONLY the reported message row; never surrounding messages in the conversation.
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
    'target_user', v_target_user,
    'sibling_reports', v_sibling_reports,
    'reported_content', v_reported_content
  );
end;
$$;

-- Two-step audited media reveal: inserts 5-minute grant(s) into private.admin_media_grants
-- for ONLY the reported check-in or reported message on p_queue_id, and logs moderation.reveal_media.
create or replace function admin.reveal_reported_media(
  p_queue_id uuid,
  p_purpose text default null
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  q public.moderation_queue%rowtype;
  ci public.check_ins%rowtype;
  msg public.messages%rowtype;
  v_expires_at timestamptz := now() + interval '5 minutes';
  v_objects jsonb := '[]'::jsonb;
begin
  v_uid := private.require_admin('moderator');
  if p_queue_id is null then
    raise exception 'invalid' using errcode = 'P0001';
  end if;

  select * into q from public.moderation_queue where id = p_queue_id;
  if not found then
    raise exception 'not_found' using errcode = 'P0001';
  end if;

  -- Prune expired grants
  delete from private.admin_media_grants where expires_at <= now();

  if q.target_checkin_id is not null then
    select * into ci from public.check_ins where id = q.target_checkin_id;
    if found then
      if ci.photo_path is not null then
        insert into private.admin_media_grants (admin_id, bucket_id, object_path, queue_id, expires_at)
        values (v_uid, 'media', ci.photo_path, q.id, v_expires_at)
        on conflict (admin_id, bucket_id, object_path) do update
          set queue_id = excluded.queue_id, expires_at = excluded.expires_at, created_at = now();
        v_objects := v_objects || jsonb_build_array(
          jsonb_build_object('bucket', 'media', 'path', ci.photo_path, 'kind', 'photo')
        );
      end if;
      if ci.thumb_path is not null then
        insert into private.admin_media_grants (admin_id, bucket_id, object_path, queue_id, expires_at)
        values (v_uid, 'media', ci.thumb_path, q.id, v_expires_at)
        on conflict (admin_id, bucket_id, object_path) do update
          set queue_id = excluded.queue_id, expires_at = excluded.expires_at, created_at = now();
        v_objects := v_objects || jsonb_build_array(
          jsonb_build_object('bucket', 'media', 'path', ci.thumb_path, 'kind', 'thumb')
        );
      end if;
      if ci.partner_photo_path is not null then
        insert into private.admin_media_grants (admin_id, bucket_id, object_path, queue_id, expires_at)
        values (v_uid, 'media', ci.partner_photo_path, q.id, v_expires_at)
        on conflict (admin_id, bucket_id, object_path) do update
          set queue_id = excluded.queue_id, expires_at = excluded.expires_at, created_at = now();
        v_objects := v_objects || jsonb_build_array(
          jsonb_build_object('bucket', 'media', 'path', ci.partner_photo_path, 'kind', 'partner_photo')
        );
      end if;
    end if;
  elsif q.target_message_id is not null then
    select * into msg from public.messages where id = q.target_message_id;
    if found and msg.media_path is not null then
      insert into private.admin_media_grants (admin_id, bucket_id, object_path, queue_id, expires_at)
      values (v_uid, 'messages', msg.media_path, q.id, v_expires_at)
      on conflict (admin_id, bucket_id, object_path) do update
        set queue_id = excluded.queue_id, expires_at = excluded.expires_at, created_at = now();
      v_objects := v_objects || jsonb_build_array(
        jsonb_build_object('bucket', 'messages', 'path', msg.media_path, 'kind', 'message_photo')
      );
    end if;
  end if;

  if jsonb_array_length(v_objects) = 0 then
    raise exception 'no_reported_media' using errcode = 'P0001';
  end if;

  perform private.admin_log(
    v_uid,
    'moderation.reveal_media',
    'moderation_queue',
    q.id::text,
    coalesce(nullif(btrim(p_purpose), ''), 'Moderation reported media inspection'),
    jsonb_build_object('objects', v_objects, 'expires_at', v_expires_at)
  );

  return jsonb_build_object(
    'queue_id', q.id,
    'expires_at', v_expires_at,
    'ttl_seconds', 300,
    'objects', v_objects
  );
end;
$$;

-- Quarantines (hides) a reported check-in or message pending further investigation while keeping queue item open.
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

  if q.target_checkin_id is null and q.target_message_id is null then
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
      'target_message_id', q.target_message_id
    )
  );

  return jsonb_build_object(
    'id', q.id,
    'status', q.status,
    'quarantined', true,
    'target_checkin_id', q.target_checkin_id,
    'target_message_id', q.target_message_id
  );
end;
$$;

-- Resolves a moderation queue item: 'dismiss', 'remove_content', 'action', or 'ban_user'.
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

    -- A2: ban_user in admin console uses private.ban_user_internal (wiping UGC without setting profiles.deleted_at)
    if v_action = 'ban_user' and q.target_user_id is not null then
      if q.target_user_id = v_uid or exists (
        select 1 from private.admins a where a.user_id = q.target_user_id and a.role = 'owner'
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
      'target_message_id', q.target_message_id
    )
  );

  return jsonb_build_object(
    'id', q.id,
    'status', q.status,
    'action', v_action,
    'handled_at', q.handled_at,
    'target_user_id', q.target_user_id,
    'target_checkin_id', q.target_checkin_id,
    'target_message_id', q.target_message_id
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- 9. RPCs 8..12: Content Filter Words (`private.objectionable_words`)
-- ---------------------------------------------------------------------------
create or replace function admin.list_objectionable_words(
  p_search text default null,
  p_lang text default null,
  p_mode text default null,
  p_category text default null,
  p_enabled boolean default null
) returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_search text := nullif(lower(normalize(btrim(coalesce(p_search, '')), NFC)), '');
  v_lang text := nullif(lower(btrim(coalesce(p_lang, ''))), '');
  v_mode text := nullif(lower(btrim(coalesce(p_mode, ''))), '');
  v_cat text := nullif(lower(btrim(coalesce(p_category, ''))), '');
  v_items jsonb;
begin
  v_uid := private.require_admin('moderator');
  select coalesce(jsonb_agg(row_to_json(w) order by w.term asc), '[]'::jsonb)
    into v_items
    from private.objectionable_words w
   where (v_search is null or position(v_search in w.term) > 0)
     and (v_lang is null or v_lang = 'all' or w.lang = v_lang)
     and (v_mode is null or v_mode = 'all' or w.match_mode = v_mode)
     and (v_cat is null or v_cat = 'all' or w.category = v_cat)
     and (p_enabled is null or w.enabled = p_enabled);

  return v_items;
end;
$$;

create or replace function admin.test_content_filter(p_text text) returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_lower text;
  v_diacritic_words text;
  v_diacritic_collapsed_words text;
  v_diacritic_tokens text;
  v_folded text;
  v_leet_folded text;
  v_alpha_words text;
  v_collapsed_words text;
  v_leet_words text;
  v_token_raw text;
  v_token_leet text;
  v_matches jsonb := '[]'::jsonb;
  v_first jsonb := null;
begin
  v_uid := private.require_admin('moderator');
  if p_text is null or btrim(p_text) = '' then
    return jsonb_build_object(
      'blocked', false,
      'term', null,
      'lang', null,
      'match_mode', null,
      'category', null,
      'matches', '[]'::jsonb
    );
  end if;

  v_lower := lower(normalize(
    translate(p_text, U&'\00ad\200b\200c\200d\200e\200f\2060\feff', ''),
    NFC
  ));

  v_diacritic_words := ' ' || btrim(regexp_replace(
    v_lower,
    '[^a-zàáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ]+',
    ' ',
    'g'
  )) || ' ';

  v_diacritic_collapsed_words := ' ' || btrim(regexp_replace(
    regexp_replace(
      v_lower,
      '([a-zàáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ])[\._/\-]+(?=[a-zàáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ])',
      '\1',
      'g'
    ),
    '[^a-zàáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ]+',
    ' ',
    'g'
  )) || ' ';

  v_diacritic_tokens := ' ' || btrim(regexp_replace(
    regexp_replace(v_lower, '[\._/\-]+', '', 'g'),
    '[^a-z0-9àáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ]+',
    ' ',
    'g'
  )) || ' ';

  v_folded := translate(
    v_lower,
    'àáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ',
    'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd'
  );

  v_leet_folded := translate(
    regexp_replace(v_folded, '!(?=[a-z0-9])', 'i', 'g'),
    '013457@$',
    'oieastas'
  );

  v_alpha_words := ' ' || btrim(regexp_replace(v_folded, '[^a-z]+', ' ', 'g')) || ' ';
  v_collapsed_words := ' ' || btrim(regexp_replace(
    regexp_replace(v_folded, '([a-z])[\._/\-]+(?=[a-z])', '\1', 'g'),
    '[^a-z]+',
    ' ',
    'g'
  )) || ' ';
  v_leet_words := ' ' || btrim(regexp_replace(
    regexp_replace(v_leet_folded, '([a-z])[\._/\-]+(?=[a-z])', '\1', 'g'),
    '[^a-z]+',
    ' ',
    'g'
  )) || ' ';

  v_token_raw := ' ' || btrim(regexp_replace(
    regexp_replace(v_folded, '[\._/\-]+', '', 'g'),
    '[^a-z0-9]+',
    ' ',
    'g'
  )) || ' ';
  v_token_leet := ' ' || btrim(regexp_replace(
    regexp_replace(v_leet_folded, '[\._/\-]+', '', 'g'),
    '[^a-z0-9]+',
    ' ',
    'g'
  )) || ' ';

  select coalesce(jsonb_agg(
           jsonb_build_object(
             'term', w.term,
             'lang', w.lang,
             'match_mode', w.match_mode,
             'category', w.category
           ) order by char_length(w.term) desc, w.term asc
         ), '[]'::jsonb)
    into v_matches
    from private.objectionable_words w
   where w.enabled
     and (
       (w.match_mode = 'diacritic_word' and (
            position(' ' || w.term || ' ' in v_diacritic_words) > 0
            or position(' ' || w.term || ' ' in v_diacritic_collapsed_words) > 0
       ))
       or (w.match_mode = 'word' and (
            position(' ' || w.term || ' ' in v_alpha_words) > 0
            or position(' ' || w.term || ' ' in v_collapsed_words) > 0
            or position(' ' || w.term || ' ' in v_leet_words) > 0
       ))
       or (w.match_mode = 'substring' and (
            position(w.term in v_diacritic_tokens) > 0
            or (
              w.term !~ '[àáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ]'
              and (
                position(w.term in v_token_raw) > 0
                or position(w.term in v_token_leet) > 0
              )
            )
       ))
     );

  if jsonb_array_length(v_matches) > 0 then
    v_first := v_matches -> 0;
  end if;

  return jsonb_build_object(
    'blocked', jsonb_array_length(v_matches) > 0,
    'term', case when v_first is not null then v_first ->> 'term' else null end,
    'lang', case when v_first is not null then v_first ->> 'lang' else null end,
    'match_mode', case when v_first is not null then v_first ->> 'match_mode' else null end,
    'category', case when v_first is not null then v_first ->> 'category' else null end,
    'matches', v_matches
  );
end;
$$;

create or replace function admin.upsert_objectionable_word(
  p_term text,
  p_lang text default 'vi',
  p_match_mode text default 'word',
  p_category text default 'profanity',
  p_enabled boolean default true
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_term text := lower(normalize(btrim(coalesce(p_term, '')), NFC));
  v_row private.objectionable_words%rowtype;
begin
  v_uid := private.require_admin('moderator');
  if char_length(v_term) not between 2 and 64
     or coalesce(p_lang, '') not in ('vi', 'en', 'any')
     or coalesce(p_match_mode, '') not in ('word', 'substring', 'diacritic_word')
     or coalesce(p_category, '') not in ('profanity', 'slur', 'sexual', 'csae', 'self_harm', 'violence') then
    raise exception 'invalid' using errcode = 'P0001';
  end if;

  insert into private.objectionable_words (term, lang, match_mode, category, enabled)
  values (v_term, p_lang, p_match_mode, p_category, coalesce(p_enabled, true))
  on conflict (term) do update
    set lang = excluded.lang,
        match_mode = excluded.match_mode,
        category = excluded.category,
        enabled = excluded.enabled
  returning * into v_row;

  perform private.admin_log(
    v_uid,
    'words.upsert',
    'word',
    v_term,
    null,
    jsonb_build_object(
      'lang', v_row.lang,
      'match_mode', v_row.match_mode,
      'category', v_row.category,
      'enabled', v_row.enabled
    )
  );

  return to_jsonb(v_row);
end;
$$;

create or replace function admin.set_objectionable_word_enabled(
  p_term text,
  p_enabled boolean
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_term text := lower(normalize(btrim(coalesce(p_term, '')), NFC));
  v_row private.objectionable_words%rowtype;
begin
  v_uid := private.require_admin('moderator');
  if char_length(v_term) not between 2 and 64 then
    raise exception 'invalid' using errcode = 'P0001';
  end if;

  update private.objectionable_words
     set enabled = coalesce(p_enabled, false)
   where term = v_term
  returning * into v_row;

  if not found then
    raise exception 'not_found' using errcode = 'P0001';
  end if;

  perform private.admin_log(
    v_uid,
    'words.toggle',
    'word',
    v_term,
    null,
    jsonb_build_object('enabled', v_row.enabled)
  );

  return to_jsonb(v_row);
end;
$$;

create or replace function admin.delete_objectionable_word(
  p_term text,
  p_reason text default null
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_term text := lower(normalize(btrim(coalesce(p_term, '')), NFC));
  v_row private.objectionable_words%rowtype;
begin
  v_uid := private.require_admin('moderator');
  if char_length(v_term) not between 2 and 64 then
    raise exception 'invalid' using errcode = 'P0001';
  end if;

  delete from private.objectionable_words
   where term = v_term
  returning * into v_row;

  if not found then
    raise exception 'not_found' using errcode = 'P0001';
  end if;

  perform private.admin_log(
    v_uid,
    'words.delete',
    'word',
    v_term,
    p_reason,
    jsonb_build_object(
      'lang', v_row.lang,
      'match_mode', v_row.match_mode,
      'category', v_row.category
    )
  );

  return jsonb_build_object('term', v_term, 'deleted', true);
end;
$$;

-- ---------------------------------------------------------------------------
-- 10. RPCs 13..16: Waitlist (`private.waitlist`)
-- ---------------------------------------------------------------------------
create or replace function admin.waitlist_summary(p_days int default 30) returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_days int := greatest(1, least(coalesce(p_days, 30), 90));
  v_total int := 0;
  v_new_7d int := 0;
  v_ios_only int := 0;
  v_android_only int := 0;
  v_both int := 0;
  v_vi int := 0;
  v_en int := 0;
  v_sent int := 0;
  v_failed int := 0;
  v_unsent int := 0;
  v_converted int := 0;
  v_sources jsonb := '[]'::jsonb;
  v_daily jsonb := '[]'::jsonb;
begin
  v_uid := private.require_admin('moderator');
  select count(*)::int,
         count(*) filter (where w.created_at >= now() - interval '7 days')::int,
         count(*) filter (where w.platforms = array['ios']::text[])::int,
         count(*) filter (where w.platforms = array['android']::text[])::int,
         count(*) filter (where 'ios' = any(w.platforms) and 'android' = any(w.platforms))::int,
         count(*) filter (where w.lang = 'vi')::int,
         count(*) filter (where w.lang = 'en')::int,
         count(*) filter (where w.confirmation_sent_at is not null and w.confirmation_error is null)::int,
         count(*) filter (where w.confirmation_error is not null)::int,
         count(*) filter (where w.confirmation_sent_at is null and w.confirmation_error is null)::int,
         count(*) filter (where exists (select 1 from auth.users u where lower(u.email) = w.email))::int
    into v_total, v_new_7d, v_ios_only, v_android_only, v_both,
         v_vi, v_en, v_sent, v_failed, v_unsent, v_converted
    from private.waitlist w;

  select coalesce(jsonb_agg(row_to_json(s)), '[]'::jsonb)
    into v_sources
    from (
      select coalesce(w.source, 'landing') as source, count(*)::int as count
        from private.waitlist w
       group by coalesce(w.source, 'landing')
       order by count(*) desc, coalesce(w.source, 'landing') asc
       limit 10
    ) s;

  select coalesce(jsonb_agg(
           jsonb_build_object(
             'day', d.day::text,
             'total', coalesce(c.total, 0),
             'vi', coalesce(c.vi, 0),
             'en', coalesce(c.en, 0)
           ) order by d.day
         ), '[]'::jsonb)
    into v_daily
    from (
      select (current_date - (v_days - 1) + g.offs) as day
        from generate_series(0, v_days - 1) as g(offs)
    ) d
    left join (
      select (w.created_at at time zone 'UTC')::date as day,
             count(*)::int as total,
             count(*) filter (where w.lang = 'vi')::int as vi,
             count(*) filter (where w.lang = 'en')::int as en
        from private.waitlist w
       where w.created_at >= now() - make_interval(days => v_days + 2)
       group by 1
    ) c on c.day = d.day;

  return jsonb_build_object(
    'total', v_total,
    'new_7d', v_new_7d,
    'ios_only', v_ios_only,
    'android_only', v_android_only,
    'both_platforms', v_both,
    'lang_vi', v_vi,
    'lang_en', v_en,
    'mail_sent', v_sent,
    'mail_failed', v_failed,
    'mail_unsent', v_unsent,
    'converted_count', v_converted,
    'waiting_count', greatest(0, v_total - v_converted),
    'by_source', v_sources,
    'daily', v_daily
  );
end;
$$;

create or replace function admin.list_waitlist(
  p_search text default null,
  p_lang text default 'all',
  p_platform text default 'all',
  p_mail_status text default 'all',
  p_converted text default 'all',
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
  v_search text := nullif(lower(btrim(coalesce(p_search, ''))), '');
  v_lang text := coalesce(nullif(lower(btrim(p_lang)), ''), 'all');
  v_plat text := coalesce(nullif(lower(btrim(p_platform)), ''), 'all');
  v_mail text := coalesce(nullif(lower(btrim(p_mail_status)), ''), 'all');
  v_conv text := coalesce(nullif(lower(btrim(p_converted)), ''), 'all');
  v_limit int := greatest(1, least(coalesce(p_limit, 50), 200));
  v_offset int := greatest(0, coalesce(p_offset, 0));
  v_total int := 0;
  v_items jsonb := '[]'::jsonb;
begin
  v_uid := private.require_admin('moderator');
  with filtered as (
    select
      w.id,
      w.email,
      w.lang,
      w.platforms,
      w.source,
      w.created_at,
      w.confirmation_sent_at,
      w.confirmation_error,
      case
        when w.confirmation_error is not null then 'failed'
        when w.confirmation_sent_at is not null then 'sent'
        else 'unsent'
      end as mail_status,
      exists (select 1 from auth.users u where lower(u.email) = w.email) as registered_in_app
    from private.waitlist w
    where (v_search is null
           or position(v_search in w.email) > 0
           or position(v_search in lower(coalesce(w.source, ''))) > 0)
      and (v_lang = 'all' or w.lang = v_lang)
      and (v_plat = 'all' or v_plat = any(w.platforms))
      and (
        v_mail = 'all'
        or (v_mail = 'sent' and w.confirmation_sent_at is not null and w.confirmation_error is null)
        or (v_mail = 'failed' and w.confirmation_error is not null)
        or (v_mail = 'unsent' and w.confirmation_sent_at is null and w.confirmation_error is null)
      )
      and (
        v_conv = 'all'
        or (v_conv = 'registered' and exists (select 1 from auth.users u where lower(u.email) = w.email))
        or (v_conv = 'waiting' and not exists (select 1 from auth.users u where lower(u.email) = w.email))
      )
  )
  select count(*)::int,
         coalesce((
           select jsonb_agg(row_to_json(x))
             from (
               select * from filtered
                order by created_at desc, id desc
                limit v_limit offset v_offset
             ) x
         ), '[]'::jsonb)
    into v_total, v_items
    from filtered;

  return jsonb_build_object(
    'total', v_total,
    'items', v_items
  );
end;
$$;

-- Owner-only CSV export with audit logging (`waitlist.export_csv`).
create or replace function admin.export_waitlist(
  p_search text default null,
  p_lang text default 'all',
  p_platform text default 'all',
  p_mail_status text default 'all',
  p_converted text default 'all'
) returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_search text := nullif(lower(btrim(coalesce(p_search, ''))), '');
  v_lang text := coalesce(nullif(lower(btrim(p_lang)), ''), 'all');
  v_plat text := coalesce(nullif(lower(btrim(p_platform)), ''), 'all');
  v_mail text := coalesce(nullif(lower(btrim(p_mail_status)), ''), 'all');
  v_conv text := coalesce(nullif(lower(btrim(p_converted)), ''), 'all');
  v_csv text;
  v_count int := 0;
begin
  v_uid := private.require_admin('owner');
  with rows as (
    select
      w.email,
      w.lang,
      array_to_string(w.platforms, ';') as platforms,
      regexp_replace(coalesce(w.source, ''), '^[=+@-]+', '', '') as source,
      to_char(w.created_at at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"') as created_at,
      coalesce(to_char(w.confirmation_sent_at at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'), '') as confirmation_sent_at,
      case when exists (select 1 from auth.users u where lower(u.email) = w.email)
           then 'true' else 'false' end as registered_in_app
    from private.waitlist w
    where (v_search is null
           or position(v_search in w.email) > 0
           or position(v_search in lower(coalesce(w.source, ''))) > 0)
      and (v_lang = 'all' or w.lang = v_lang)
      and (v_plat = 'all' or v_plat = any(w.platforms))
      and (
        v_mail = 'all'
        or (v_mail = 'sent' and w.confirmation_sent_at is not null and w.confirmation_error is null)
        or (v_mail = 'failed' and w.confirmation_error is not null)
        or (v_mail = 'unsent' and w.confirmation_sent_at is null and w.confirmation_error is null)
      )
      and (
        v_conv = 'all'
        or (v_conv = 'registered' and exists (select 1 from auth.users u where lower(u.email) = w.email))
        or (v_conv = 'waiting' and not exists (select 1 from auth.users u where lower(u.email) = w.email))
      )
    order by w.created_at desc, w.id desc
  )
  select count(*)::int,
         'email,lang,platforms,source,created_at,confirmation_sent_at,registered_in_app'
         || coalesce(
              E'\n' || string_agg(
                format(
                  '"%s","%s","%s","%s","%s","%s","%s"',
                  replace(r.email, '"', '""'),
                  replace(r.lang, '"', '""'),
                  replace(r.platforms, '"', '""'),
                  replace(r.source, '"', '""'),
                  r.created_at,
                  r.confirmation_sent_at,
                  r.registered_in_app
                ),
                E'\n'
              ),
              ''
            )
    into v_count, v_csv
    from rows r;

  perform private.admin_log(
    v_uid,
    'waitlist.export_csv',
    'waitlist',
    null,
    null,
    jsonb_build_object(
      'row_count', v_count,
      'lang', v_lang,
      'platform', v_plat,
      'mail_status', v_mail,
      'converted', v_conv
    )
  );

  return v_csv;
end;
$$;

-- Owner-only waitlist row deletion; logs sha256(email) instead of plaintext email.
create or replace function admin.delete_waitlist_entry(
  p_id uuid,
  p_reason text default null
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_email text;
  v_hash text;
begin
  v_uid := private.require_admin('owner');
  if p_id is null then
    raise exception 'invalid' using errcode = 'P0001';
  end if;

  delete from private.waitlist
   where id = p_id
  returning email into v_email;

  if not found then
    raise exception 'not_found' using errcode = 'P0001';
  end if;

  v_hash := encode(extensions.digest(v_email, 'sha256'), 'hex');

  perform private.admin_log(
    v_uid,
    'waitlist.delete',
    'waitlist',
    p_id::text,
    p_reason,
    jsonb_build_object('email_sha256', v_hash)
  );

  return jsonb_build_object(
    'id', p_id,
    'deleted', true,
    'email_sha256', v_hash
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- 11. RPCs 17..21: Users Lookup, Detail, Reversible Ban/Unban & Session Revoke
-- ---------------------------------------------------------------------------
create or replace function admin.list_users(
  p_search text default null,
  p_status text default 'all',
  p_sort text default 'created_at',
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
  v_search text := nullif(lower(ltrim(btrim(coalesce(p_search, '')), '@')), '');
  v_status text := coalesce(nullif(lower(btrim(p_status)), ''), 'all');
  v_sort text := coalesce(nullif(lower(btrim(p_sort)), ''), 'created_at');
  v_limit int := greatest(1, least(coalesce(p_limit, 50), 200));
  v_offset int := greatest(0, coalesce(p_offset, 0));
  v_has_terms_col boolean := false;
  v_terms_map jsonb := '{}'::jsonb;
  v_total int := 0;
  v_items jsonb := '[]'::jsonb;
begin
  v_uid := private.require_admin('moderator');
  select exists (
    select 1 from information_schema.columns
     where table_schema = 'public' and table_name = 'profiles' and column_name = 'terms_version'
  ) into v_has_terms_col;

  if v_has_terms_col then
    execute 'select coalesce(jsonb_object_agg(id::text, terms_version), ''{}''::jsonb) from public.profiles'
      into v_terms_map;
  end if;

  with user_rows as (
    select
      u.id,
      p.username,
      p.display_name,
      u.email,
      (u.phone is not null and btrim(u.phone) <> '') as has_phone,
      (u.encrypted_password is not null and btrim(u.encrypted_password) <> '') as has_password,
      coalesce((v_terms_map ->> u.id::text)::int, 0) as terms_version,
      private.is_user_banned(u.id) as is_banned,
      case
        when private.is_user_banned(u.id) then 'banned'
        when p.id is null then 'incomplete_onboarding'
        when p.deleted_at is not null then 'soft_deleted'
        else 'active'
      end as status,
      um.banned_at,
      um.ban_reason,
      um.wiped_ugc,
      (
        select count(*)::int
          from public.memberships m
          join public.journeys j on j.id = m.journey_id and j.deleted_at is null
         where m.user_id = u.id and m.status = 'active' and m.deleted_at is null and j.status = 'active'
      ) as active_journeys_count,
      (
        select count(*)::int
          from public.memberships m
          join public.journeys j on j.id = m.journey_id and j.deleted_at is null
         where m.user_id = u.id and m.deleted_at is null
      ) as total_journeys_count,
      (
        select count(*)::int
          from public.memberships m
          join public.journeys j on j.id = m.journey_id and j.deleted_at is null
         where m.user_id = u.id and m.status = 'active' and m.deleted_at is null and j.kind = 'group'
      ) as group_journeys_count,
      (
        select count(*)::int
          from public.check_ins c
         where c.user_id = u.id and c.deleted_at is null
      ) as total_checkins,
      coalesce((
        select max(s.best_streak)::int
          from public.memberships m
          join public.journeys j on j.id = m.journey_id and j.deleted_at is null
          cross join lateral public.journey_streak(j.id, u.id) s
         where m.user_id = u.id and m.status = 'active' and m.deleted_at is null and j.origin = 'live'
      ), 0) as best_streak,
      (
        select count(*)::int
          from public.moderation_queue mq
         where mq.target_user_id = u.id and mq.status = 'open'
      ) as open_reports_against,
      (
        select count(*)::int
          from public.moderation_queue mq
         where mq.target_user_id = u.id and mq.status = 'actioned'
      ) as total_actioned_reports,
      (
        select count(*)::int
          from public.blocks b
         where b.blocked_id = u.id and b.deleted_at is null
      ) as blocked_by_count,
      greatest(
        u.last_sign_in_at,
        p.updated_at,
        (select max(c.created_at) from public.check_ins c where c.user_id = u.id),
        (select max(m.created_at) from public.messages m where m.sender_id = u.id)
      ) as last_active_at,
      u.created_at
    from auth.users u
    left join public.profiles p on p.id = u.id
    left join private.user_moderation um on um.user_id = u.id
  ),
  filtered as (
    select *
      from user_rows ur
     where (
             v_search is null
             or position(v_search in lower(coalesce(ur.username, ''))) > 0
             or position(v_search in lower(coalesce(ur.email, ''))) > 0
             or position(v_search in lower(coalesce(ur.display_name, ''))) > 0
             or position(v_search in lower(ur.id::text)) > 0
           )
       and (
             v_status = 'all'
             or (v_status = 'active' and ur.status = 'active')
             or (v_status = 'banned' and ur.is_banned)
             or (v_status = 'incomplete_onboarding' and ur.status = 'incomplete_onboarding')
             or (v_status = 'soft_deleted' and ur.status = 'soft_deleted')
             or (v_status = 'reported' and (ur.open_reports_against > 0 or ur.total_actioned_reports > 0))
           )
  )
  select count(*)::int,
         coalesce((
           select jsonb_agg(row_to_json(x))
             from (
               select *
                 from filtered f
                order by
                  case when v_sort = 'reports_against' then f.open_reports_against + f.total_actioned_reports else 0 end desc,
                  case when v_sort = 'last_active_at' then coalesce(f.last_active_at, '-infinity'::timestamptz) else f.created_at end desc,
                  f.created_at desc,
                  f.id asc
                limit v_limit offset v_offset
             ) x
         ), '[]'::jsonb)
    into v_total, v_items
    from filtered;

  return jsonb_build_object(
    'total', v_total,
    'items', v_items
  );
end;
$$;

-- User detail drawer: returns auth & activity counts and moderation history (zero private photos/metrics/chats)
-- and logs `users.view_detail`.
create or replace function admin.get_user_detail(p_user uuid) returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  u auth.users%rowtype;
  p public.profiles%rowtype;
  v_has_profile boolean := false;
  um private.user_moderation%rowtype;
  v_has_um boolean := false;
  v_terms_version int := 0;
  v_banned_until timestamptz := null;
  v_recent_reports jsonb := '[]'::jsonb;
  v_audit_history jsonb := '[]'::jsonb;
begin
  v_uid := private.require_admin('moderator');
  if p_user is null then
    raise exception 'invalid' using errcode = 'P0001';
  end if;

  select * into u from auth.users where id = p_user;
  if not found then
    raise exception 'not_found' using errcode = 'P0001';
  end if;

  select * into p from public.profiles where id = p_user;
  v_has_profile := found;

  select * into um from private.user_moderation where user_id = p_user;
  v_has_um := found;

  if v_has_profile and exists (
    select 1 from information_schema.columns
     where table_schema = 'public' and table_name = 'profiles' and column_name = 'terms_version'
  ) then
    execute 'select coalesce(terms_version, 0) from public.profiles where id = $1'
      into v_terms_version
      using p_user;
  end if;

  if exists (
    select 1 from information_schema.columns
     where table_schema = 'auth' and table_name = 'users' and column_name = 'banned_until'
  ) then
    execute 'select banned_until from auth.users where id = $1'
      into v_banned_until
      using p_user;
  end if;

  perform private.admin_log(
    v_uid,
    'users.view_detail',
    'user',
    p_user::text,
    null,
    jsonb_build_object('username', p.username)
  );

  select coalesce(jsonb_agg(row_to_json(r)), '[]'::jsonb)
    into v_recent_reports
    from (
      select mq.id as queue_id,
             mq.kind,
             mq.reason::text as reason,
             mq.status,
             mq.created_at,
             mq.due_at,
             mq.handled_at,
             mq.resolution_note
        from public.moderation_queue mq
       where mq.target_user_id = p_user
       order by mq.created_at desc
       limit 20
    ) r;

  select coalesce(jsonb_agg(row_to_json(a)), '[]'::jsonb)
    into v_audit_history
    from (
      select aa.id,
             aa.admin_id,
             aa.admin_email,
             aa.action,
             aa.reason,
             aa.meta,
             aa.created_at
        from private.admin_audit aa
       where aa.target_type = 'user' and aa.target_id = p_user::text
       order by aa.id desc
       limit 25
    ) a;

  return jsonb_build_object(
    'id', u.id,
    'email', u.email,
    'has_phone', (u.phone is not null and btrim(u.phone) <> ''),
    'has_password', (u.encrypted_password is not null and btrim(u.encrypted_password) <> ''),
    'username', p.username,
    'display_name', p.display_name,
    'terms_version', v_terms_version,
    'is_banned', private.is_user_banned(u.id),
    'banned_until', v_banned_until,
    'status', case
      when private.is_user_banned(u.id) then 'banned'
      when not v_has_profile then 'incomplete_onboarding'
      when p.deleted_at is not null then 'soft_deleted'
      else 'active'
    end,
    'created_at', u.created_at,
    'last_sign_in_at', u.last_sign_in_at,
    'deleted_at', p.deleted_at,
    'last_active_at', greatest(
      u.last_sign_in_at,
      p.updated_at,
      (select max(c.created_at) from public.check_ins c where c.user_id = u.id),
      (select max(m.created_at) from public.messages m where m.sender_id = u.id)
    ),
    'activity', jsonb_build_object(
      'active_journeys_count', (
        select count(*)::int
          from public.memberships m
          join public.journeys j on j.id = m.journey_id and j.deleted_at is null
         where m.user_id = u.id and m.status = 'active' and m.deleted_at is null and j.status = 'active'
      ),
      'total_journeys_count', (
        select count(*)::int
          from public.memberships m
          join public.journeys j on j.id = m.journey_id and j.deleted_at is null
         where m.user_id = u.id and m.deleted_at is null
      ),
      'group_journeys_count', (
        select count(*)::int
          from public.memberships m
          join public.journeys j on j.id = m.journey_id and j.deleted_at is null
         where m.user_id = u.id and m.status = 'active' and m.deleted_at is null and j.kind = 'group'
      ),
      'total_checkins', (
        select count(*)::int
          from public.check_ins c
         where c.user_id = u.id and c.deleted_at is null
      ),
      'best_streak', coalesce((
        select max(s.best_streak)::int
          from public.memberships m
          join public.journeys j on j.id = m.journey_id and j.deleted_at is null
          cross join lateral public.journey_streak(j.id, u.id) s
         where m.user_id = u.id and m.status = 'active' and m.deleted_at is null and j.origin = 'live'
      ), 0),
      'friends_count', (
        select count(*)::int
          from public.friendships f
         where (f.user_low = u.id or f.user_high = u.id)
           and f.status = 'accepted' and f.deleted_at is null
      )
    ),
    'trust', jsonb_build_object(
      'open_reports_against', (
        select count(*)::int from public.moderation_queue mq
         where mq.target_user_id = u.id and mq.status = 'open'
      ),
      'total_actioned_reports', (
        select count(*)::int from public.moderation_queue mq
         where mq.target_user_id = u.id and mq.status = 'actioned'
      ),
      'blocked_by_count', (
        select count(*)::int from public.blocks b
         where b.blocked_id = u.id and b.deleted_at is null
      ),
      'moderation_record', case when v_has_um then to_jsonb(um) else null end,
      'recent_reports_against', v_recent_reports,
      'audit_history', v_audit_history
    )
  );
end;
$$;

-- A2: Ban user without setting public.profiles.deleted_at.
create or replace function admin.ban_user(
  p_user uuid,
  p_reason text,
  p_wipe_ugc boolean default false
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_reason text := left(nullif(btrim(p_reason), ''), 500);
  v_res jsonb;
begin
  v_uid := private.require_admin('moderator');
  if p_user is null or v_reason is null or char_length(v_reason) < 3 then
    raise exception 'invalid' using errcode = 'P0001';
  end if;

  if p_user = v_uid or exists (
    select 1 from private.admins a where a.user_id = p_user and a.role = 'owner'
  ) then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  if not exists (select 1 from auth.users u where u.id = p_user) then
    raise exception 'not_found' using errcode = 'P0001';
  end if;

  v_res := private.ban_user_internal(p_user, v_uid, v_reason, coalesce(p_wipe_ugc, false));

  perform private.admin_log(
    v_uid,
    'users.ban',
    'user',
    p_user::text,
    v_reason,
    jsonb_build_object('wipe_ugc', coalesce(p_wipe_ugc, false))
  );

  return v_res;
end;
$$;

-- A2: Unban reverses only the ban state (banned_until + private.user_moderation), never profiles.deleted_at.
create or replace function admin.unban_user(
  p_user uuid,
  p_reason text default null
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_reason text := left(nullif(btrim(p_reason), ''), 500);
begin
  v_uid := private.require_admin('moderator');
  if p_user is null then
    raise exception 'invalid' using errcode = 'P0001';
  end if;

  if not exists (select 1 from auth.users u where u.id = p_user) then
    raise exception 'not_found' using errcode = 'P0001';
  end if;

  if exists (
    select 1 from information_schema.columns
     where table_schema = 'auth' and table_name = 'users' and column_name = 'banned_until'
  ) then
    execute 'update auth.users set banned_until = null where id = $1'
      using p_user;
  end if;

  insert into private.user_moderation (
    user_id, unbanned_at, unbanned_by, unban_reason, updated_at
  )
  values (
    p_user, now(), v_uid, v_reason, now()
  )
  on conflict (user_id) do update
    set unbanned_at = now(),
        unbanned_by = excluded.unbanned_by,
        unban_reason = excluded.unban_reason,
        updated_at = now();

  perform private.admin_log(
    v_uid,
    'users.unban',
    'user',
    p_user::text,
    v_reason,
    '{}'::jsonb
  );

  return jsonb_build_object(
    'user_id', p_user,
    'banned', false,
    'unbanned_at', now()
  );
end;
$$;

create or replace function admin.revoke_user_sessions(
  p_user uuid,
  p_reason text default null
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_deleted int := 0;
begin
  v_uid := private.require_admin('moderator');
  if p_user is null then
    raise exception 'invalid' using errcode = 'P0001';
  end if;

  if not exists (select 1 from auth.users u where u.id = p_user) then
    raise exception 'not_found' using errcode = 'P0001';
  end if;

  v_deleted := private.revoke_user_sessions_internal(p_user);

  perform private.admin_log(
    v_uid,
    'users.revoke_sessions',
    'user',
    p_user::text,
    p_reason,
    jsonb_build_object('revoked_sessions', v_deleted)
  );

  return jsonb_build_object(
    'user_id', p_user,
    'revoked_sessions', v_deleted
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- 12. RPCs 22..24: Journeys (Aggregate Stats, Privacy-Redacted List & Link Kill-Switch)
-- ---------------------------------------------------------------------------
create or replace function admin.journey_stats() returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_total int := 0;
  v_active int := 0;
  v_ended int := 0;
  v_archived int := 0;
  v_solo int := 0;
  v_group int := 0;
  v_couple int := 0;
  v_live int := 0;
  v_imported int := 0;
  v_public_links int := 0;
  v_public_views int := 0;
  v_by_template jsonb := '[]'::jsonb;
  v_by_skin jsonb := '[]'::jsonb;
begin
  v_uid := private.require_admin('moderator');
  select count(*)::int,
         count(*) filter (where j.status = 'active')::int,
         count(*) filter (where j.status = 'ended')::int,
         count(*) filter (where j.status = 'archived')::int,
         count(*) filter (where j.kind = 'solo' and j.couple_self_name is null and coalesce(j.layout, '') <> 'couple_rituals')::int,
         count(*) filter (where j.kind = 'group' and j.couple_self_name is null and coalesce(j.layout, '') <> 'couple_rituals')::int,
         count(*) filter (where j.couple_self_name is not null or j.layout = 'couple_rituals')::int,
         count(*) filter (where j.origin = 'live')::int,
         count(*) filter (where j.origin = 'imported')::int,
         count(*) filter (where j.public_token is not null)::int
    into v_total, v_active, v_ended, v_archived, v_solo, v_group, v_couple, v_live, v_imported, v_public_links
    from public.journeys j
   where j.deleted_at is null;

  select count(*)::int into v_public_views from public.journey_views;

  select coalesce(jsonb_agg(row_to_json(t)), '[]'::jsonb)
    into v_by_template
    from (
      select j.template_id::text as template_id, count(*)::int as count
        from public.journeys j
       where j.deleted_at is null
       group by j.template_id
       order by count(*) desc, j.template_id::text asc
    ) t;

  select coalesce(jsonb_agg(row_to_json(s)), '[]'::jsonb)
    into v_by_skin
    from (
      select coalesce(j.layout, case
               when j.couple_self_name is not null then 'couple_rituals'
               when j.template_id = 'weight_loss' then 'quiet_transformer'
               when j.template_id = 'english_daily' then 'accountability_squad'
               when j.template_id = 'travel' then 'memory_collectors'
               when j.template_id = 'workout_30' then 'aesthetic_flexer'
               else 'minimalist_habit'
             end) as skin,
             count(*)::int as count
        from public.journeys j
       where j.deleted_at is null
       group by 1
       order by count(*) desc, 1 asc
    ) s;

  return jsonb_build_object(
    'total', v_total,
    'active', v_active,
    'ended', v_ended,
    'archived', v_archived,
    'solo_count', v_solo,
    'group_count', v_group,
    'couple_count', v_couple,
    'live_count', v_live,
    'imported_count', v_imported,
    'public_links_count', v_public_links,
    'total_public_views', v_public_views,
    'by_template', v_by_template,
    'by_skin', v_by_skin
  );
end;
$$;

-- Privacy-by-construction: `title` and `emoji` are NULL in SQL unless `j.public_token is not null`.
-- Never selects `story_*`, `couple_*`, `dna`, `invite_code`, `metric_name`, or `check_ins` content.
create or replace function admin.list_journeys(
  p_search text default null,
  p_kind text default 'all',
  p_template text default 'all',
  p_status text default 'all',
  p_public_only boolean default false,
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
  v_search text := nullif(lower(ltrim(btrim(coalesce(p_search, '')), '@')), '');
  v_kind text := coalesce(nullif(lower(btrim(p_kind)), ''), 'all');
  v_tpl text := coalesce(nullif(lower(btrim(p_template)), ''), 'all');
  v_status text := coalesce(nullif(lower(btrim(p_status)), ''), 'all');
  v_limit int := greatest(1, least(coalesce(p_limit, 50), 200));
  v_offset int := greatest(0, coalesce(p_offset, 0));
  v_total int := 0;
  v_items jsonb := '[]'::jsonb;
begin
  v_uid := private.require_admin('moderator');
  with filtered as (
    select
      j.id,
      j.owner_id,
      p.username as owner_username,
      p.display_name as owner_display_name,
      j.kind::text as kind,
      (j.couple_self_name is not null or j.layout = 'couple_rituals') as is_couple,
      j.origin,
      j.template_id::text as template_id,
      j.layout,
      j.status::text as status,
      j.visibility::text as visibility,
      -- Strictly redact title & emoji unless public_token IS NOT NULL
      case when j.public_token is not null then j.title else null end as title,
      case when j.public_token is not null then j.emoji else null end as emoji,
      (j.public_token is not null) as has_public_link,
      j.public_token,
      (
        select count(*)::int
          from public.memberships m
         where m.journey_id = j.id and m.status = 'active' and m.deleted_at is null
      ) as active_members,
      j.max_members,
      (
        select count(*)::int
          from public.check_ins c
         where c.journey_id = j.id and c.deleted_at is null and c.moderated_at is null
      ) as checkin_count,
      (
        select count(*)::int
          from public.journey_views jv
         where jv.journey_id = j.id
      ) as public_views,
      j.start_date,
      j.duration_days,
      j.created_at
    from public.journeys j
    left join public.profiles p on p.id = j.owner_id
    where j.deleted_at is null
      and (not coalesce(p_public_only, false) or j.public_token is not null)
      and (
        v_kind = 'all'
        or (v_kind = 'couple' and (j.couple_self_name is not null or j.layout = 'couple_rituals'))
        or (v_kind in ('solo', 'group') and j.kind::text = v_kind)
      )
      and (
        v_tpl = 'all'
        or (v_tpl = 'couple' and (j.couple_self_name is not null or j.layout = 'couple_rituals'))
        or j.template_id::text = v_tpl
        or coalesce(j.layout, '') = v_tpl
      )
      and (v_status = 'all' or j.status::text = v_status)
      and (
        v_search is null
        or position(v_search in lower(coalesce(p.username, ''))) > 0
        or position(v_search in lower(j.id::text)) > 0
        or position(v_search in lower(j.owner_id::text)) > 0
        or (j.public_token is not null and position(v_search in lower(j.title)) > 0)
      )
  )
  select count(*)::int,
         coalesce((
           select jsonb_agg(row_to_json(x))
             from (
               select *
                 from filtered
                order by created_at desc, id desc
                limit v_limit offset v_offset
             ) x
         ), '[]'::jsonb)
    into v_total, v_items
    from filtered;

  return jsonb_build_object(
    'total', v_total,
    'items', v_items
  );
end;
$$;

create or replace function admin.revoke_journey_public_link(
  p_journey uuid,
  p_reason text
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_reason text := left(nullif(btrim(p_reason), ''), 500);
  j public.journeys%rowtype;
begin
  v_uid := private.require_admin('moderator');
  if p_journey is null or v_reason is null or char_length(v_reason) < 3 then
    raise exception 'invalid' using errcode = 'P0001';
  end if;

  select * into j from public.journeys where id = p_journey and deleted_at is null for update;
  if not found then
    raise exception 'not_found' using errcode = 'P0001';
  end if;

  update public.journeys
     set public_token = null,
         visibility = case when kind = 'solo' then 'private'::public.journey_visibility else visibility end
   where id = p_journey;

  delete from public.saved_journeys where journey_id = p_journey;

  perform private.admin_log(
    v_uid,
    'journeys.revoke_public_link',
    'journey',
    p_journey::text,
    v_reason,
    jsonb_build_object('owner_id', j.owner_id, 'had_token', j.public_token is not null)
  );

  return jsonb_build_object(
    'journey_id', p_journey,
    'revoked', true
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- 13. RPC 25: Audit Log (`admin.list_audit_log`)
-- ---------------------------------------------------------------------------
create or replace function admin.list_audit_log(
  p_admin uuid default null,
  p_action_prefix text default null,
  p_target_type text default null,
  p_target_id text default null,
  p_before_id bigint default null,
  p_limit int default 50
) returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_prefix text := nullif(btrim(p_action_prefix), '');
  v_type text := nullif(lower(btrim(p_target_type)), '');
  v_target_id text := nullif(btrim(p_target_id), '');
  v_limit int := greatest(1, least(coalesce(p_limit, 50), 200));
  v_items jsonb := '[]'::jsonb;
  v_next_before bigint := null;
begin
  v_uid := private.require_admin('moderator');
  with rows as (
    select
      a.id,
      a.admin_id,
      a.admin_email,
      p.username as admin_username,
      a.action,
      a.target_type,
      a.target_id,
      a.reason,
      a.meta,
      a.created_at
    from private.admin_audit a
    left join public.profiles p on p.id = a.admin_id
    where (p_admin is null or a.admin_id = p_admin)
      and (v_prefix is null or a.action like v_prefix || '%')
      and (v_type is null or v_type = 'all' or a.target_type = v_type)
      and (v_target_id is null or a.target_id = v_target_id)
      and (p_before_id is null or a.id < p_before_id)
    order by a.id desc
    limit v_limit
  )
  select coalesce(jsonb_agg(row_to_json(r) order by r.id desc), '[]'::jsonb),
         case when count(*) = v_limit then min(r.id) else null end
    into v_items, v_next_before
    from rows r;

  return jsonb_build_object(
    'items', v_items,
    'next_before_id', v_next_before
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- 14. RPCs 26..30: Settings & System Ops (`private.admins`, `private.pending_storage_purge`)
-- ---------------------------------------------------------------------------
create or replace function admin.list_admins() returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_items jsonb;
begin
  v_uid := private.require_admin('moderator');
  select coalesce(jsonb_agg(
           jsonb_build_object(
             'user_id', a.user_id,
             'email', u.email,
             'username', p.username,
             'display_name', p.display_name,
             'role', a.role,
             'note', a.note,
             'added_by', a.added_by,
             'created_at', a.created_at,
             'updated_at', a.updated_at,
             'last_sign_in_at', u.last_sign_in_at
           ) order by case when a.role = 'owner' then 0 else 1 end, a.created_at asc
         ), '[]'::jsonb)
    into v_items
    from private.admins a
    join auth.users u on u.id = a.user_id
    left join public.profiles p on p.id = a.user_id;

  return v_items;
end;
$$;

create or replace function admin.upsert_admin_user(
  p_email_or_uid text,
  p_role text,
  p_note text default null
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_input text := btrim(coalesce(p_email_or_uid, ''));
  v_role text := lower(btrim(coalesce(p_role, '')));
  v_note text := left(nullif(btrim(p_note), ''), 500);
  v_target_uid uuid;
  v_target_email text;
  v_existing_role text;
  v_other_owners int := 0;
  v_row private.admins%rowtype;
begin
  v_uid := private.require_admin('owner');
  if v_input = '' or v_role not in ('owner', 'moderator') then
    raise exception 'invalid' using errcode = 'P0001';
  end if;

  v_target_uid := public.try_uuid(v_input);
  if v_target_uid is not null then
    select u.id, lower(u.email) into v_target_uid, v_target_email
      from auth.users u
     where u.id = v_target_uid;
  else
    select u.id, lower(u.email) into v_target_uid, v_target_email
      from auth.users u
     where lower(u.email) = lower(v_input)
     limit 1;
  end if;

  if v_target_uid is null then
    raise exception 'not_found' using errcode = 'P0001';
  end if;

  select a.role into v_existing_role
    from private.admins a
   where a.user_id = v_target_uid
   for update;

  if v_existing_role = 'owner' and v_role <> 'owner' then
    select count(*)::int into v_other_owners
      from private.admins a
     where a.role = 'owner' and a.user_id <> v_target_uid;
    if v_other_owners = 0 then
      raise exception 'cannot_remove_last_owner' using errcode = 'P0001';
    end if;
  end if;

  insert into private.admins (user_id, role, note, added_by, created_at, updated_at)
  values (v_target_uid, v_role, v_note, v_uid, now(), now())
  on conflict (user_id) do update
    set role = excluded.role,
        note = coalesce(excluded.note, private.admins.note),
        updated_at = now()
  returning * into v_row;

  perform private.admin_log(
    v_uid,
    'admins.upsert',
    'admin',
    v_target_uid::text,
    v_note,
    jsonb_build_object('role', v_row.role, 'email', v_target_email)
  );

  return to_jsonb(v_row);
end;
$$;

create or replace function admin.remove_admin_user(
  p_user uuid,
  p_reason text default null
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_existing_role text;
  v_other_owners int := 0;
begin
  v_uid := private.require_admin('owner');
  if p_user is null then
    raise exception 'invalid' using errcode = 'P0001';
  end if;

  select a.role into v_existing_role
    from private.admins a
   where a.user_id = p_user
   for update;

  if not found then
    raise exception 'not_found' using errcode = 'P0001';
  end if;

  if v_existing_role = 'owner' then
    select count(*)::int into v_other_owners
      from private.admins a
     where a.role = 'owner' and a.user_id <> p_user;
    if v_other_owners = 0 then
      raise exception 'cannot_remove_last_owner' using errcode = 'P0001';
    end if;
  end if;

  delete from private.admin_media_grants where admin_id = p_user;
  delete from private.admins where user_id = p_user;

  perform private.admin_log(
    v_uid,
    'admins.remove',
    'admin',
    p_user::text,
    p_reason,
    jsonb_build_object('removed_role', v_existing_role)
  );

  return jsonb_build_object(
    'user_id', p_user,
    'removed', true
  );
end;
$$;

create or replace function admin.system_health() returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_due_now int := 0;
  v_backing_off int := 0;
  v_stuck int := 0;
  v_total_purge int := 0;
  v_sample_errors jsonb := '[]'::jsonb;
  v_unnotified_mod int := 0;
  v_leased_mod int := 0;
  v_overdue_mod int := 0;
  v_owners int := 0;
  v_moderators int := 0;
begin
  v_uid := private.require_admin('moderator');
  select count(*) filter (
           where s.attempts < 20
             and s.next_attempt_at <= now()
             and not exists (select 1 from auth.users u where u.id = s.user_id)
         )::int,
         count(*) filter (where s.attempts < 20 and s.next_attempt_at > now())::int,
         count(*) filter (where s.attempts >= 20)::int,
         count(*)::int
    into v_due_now, v_backing_off, v_stuck, v_total_purge
    from private.pending_storage_purge s;

  -- Privacy rule: only redacted path prefix, never full object paths or signed URLs.
  select coalesce(jsonb_agg(row_to_json(e)), '[]'::jsonb)
    into v_sample_errors
    from (
      select s.bucket,
             split_part(s.path, '/', 1) || '/...' as path_prefix,
             s.attempts,
             s.next_attempt_at,
             s.last_error,
             s.created_at
        from private.pending_storage_purge s
       where s.last_error is not null
       order by s.attempts desc, s.next_attempt_at asc
       limit 10
    ) e;

  select count(*) filter (where q.status = 'open' and q.notified_at is null)::int,
         count(*) filter (
           where q.status = 'open' and q.notified_at is null and q.notify_claimed_until > now()
         )::int,
         count(*) filter (where q.status = 'open' and q.due_at <= now())::int
    into v_unnotified_mod, v_leased_mod, v_overdue_mod
    from public.moderation_queue q;

  select count(*) filter (where a.role = 'owner')::int,
         count(*) filter (where a.role = 'moderator')::int
    into v_owners, v_moderators
    from private.admins a;

  return jsonb_build_object(
    'storage_purge', jsonb_build_object(
      'due_now_count', v_due_now,
      'backing_off_count', v_backing_off,
      'stuck_count', v_stuck,
      'total_queued', v_total_purge,
      'sample_errors', v_sample_errors
    ),
    'moderation_notifications', jsonb_build_object(
      'unnotified_open_count', v_unnotified_mod,
      'leased_count', v_leased_mod,
      'overdue_open_count', v_overdue_mod
    ),
    'admins_count', jsonb_build_object(
      'owners', v_owners,
      'moderators', v_moderators
    )
  );
end;
$$;

create or replace function admin.reset_stuck_storage_purge(
  p_reason text default null
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_count int := 0;
begin
  v_uid := private.require_admin('moderator');
  update private.pending_storage_purge
     set attempts = 0,
         next_attempt_at = now(),
         last_error = null
   where attempts >= 20
      or (attempts > 0 and next_attempt_at > now());
  get diagnostics v_count = row_count;

  perform private.admin_log(
    v_uid,
    'system.reset_storage_purge',
    'system',
    'pending_storage_purge',
    p_reason,
    jsonb_build_object('reset_count', v_count)
  );

  return jsonb_build_object('reset_count', v_count);
end;
$$;

-- ---------------------------------------------------------------------------
-- 15. Service-Role Support RPCs for `admin-action` Edge Function
-- ---------------------------------------------------------------------------
create or replace function public.admin_service_get_waitlist_targets(
  p_waitlist_id uuid default null,
  p_limit int default 25
) returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_items jsonb;
begin
  perform private.assert_service_role();

  if p_waitlist_id is not null then
    select coalesce(jsonb_agg(row_to_json(w)), '[]'::jsonb)
      into v_items
      from (
        select id, email, lang, platforms, source, confirmation_sent_at, confirmation_error
          from private.waitlist
         where id = p_waitlist_id
      ) w;
  else
    select coalesce(jsonb_agg(row_to_json(w)), '[]'::jsonb)
      into v_items
      from (
        select id, email, lang, platforms, source, confirmation_sent_at, confirmation_error
          from private.waitlist
         where confirmation_error is not null
         order by created_at desc
         limit greatest(1, least(coalesce(p_limit, 25), 50))
      ) w;
  end if;

  return coalesce(v_items, '[]'::jsonb);
end;
$$;

create or replace function public.admin_service_record_audit(
  p_admin_id uuid,
  p_action text,
  p_target_type text,
  p_target_id text default null,
  p_reason text default null,
  p_meta jsonb default '{}'::jsonb
) returns bigint
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.assert_service_role();
  return private.admin_log(p_admin_id, p_action, p_target_type, p_target_id, p_reason, p_meta);
end;
$$;

revoke all on function
  public.admin_service_get_waitlist_targets(uuid, int),
  public.admin_service_record_audit(uuid, text, text, text, text, jsonb)
from public, anon, authenticated;
grant execute on function
  public.admin_service_get_waitlist_targets(uuid, int),
  public.admin_service_record_audit(uuid, text, text, text, text, jsonb)
to service_role;

-- ---------------------------------------------------------------------------
-- 16. Grants on all 30 `admin.*` RPCs (authenticated + service_role ONLY)
-- ---------------------------------------------------------------------------
revoke all on all functions in schema admin from public, anon;
grant execute on all functions in schema admin to authenticated, service_role;

notify pgrst, 'reload schema';
