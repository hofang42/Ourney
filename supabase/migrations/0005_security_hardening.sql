-- 0005_security_hardening: fixes for the Security Auditor findings (H1-H2, M1-M4, L1-L7).
-- Tests: supabase/tests/05_security_hardening.test.sql. Contract: docs/contracts/schema.md (v1.2).
--
--   H1  metric values move to public.check_in_metrics (own RLS, honours memberships.hide_metric);
--       check_ins.metric_value is kept for wire compatibility but is always stored as NULL.
--   H2  memberships.removed_at; join_by_code refuses removed members; remove_member rotates the code.
--   M1  other members no longer read soft-deleted check-ins; they get tombstones (id only)
--       from public.checkin_tombstones(since, lim).
--   M2  check_ins.moderated_at (server-only); a moderated row cannot be changed by its author.
--   M3  check-in media is readable by others only through a live, visible check-in row.
--   M4  join_by_code: >= 10 failed codes per user per hour -> rate_limited; unknown/malformed
--       codes return an empty row (all columns NULL) instead of raising, so the attempt commits.
--   L1  authorization helpers move to schema `private` (not exposed through PostgREST).
--   L2  direct client writes reject check-ins older than 3 journey-local days (offline window).
--   L3  reports.target_checkin_id follows a retake (on update cascade).
--   L4  only the first-ever block of a pair lands in moderation_queue.
--   L5  profiles / avatars readable by self and active co-members (not blocked) only.
--   L7  moderation_queue.report_id on delete set null; group_today + reactions honour reports;
--       profiles.deleted_at is no longer client-updatable.

-- ---------------------------------------------------------------------------
-- L1: private schema for helpers (policies need USAGE + EXECUTE; PostgREST does not expose it)
-- ---------------------------------------------------------------------------
create schema if not exists private;
revoke all on schema private from public, anon;
grant usage on schema private to authenticated, service_role;
alter default privileges in schema private revoke all on functions from public, anon;

-- ---------------------------------------------------------------------------
-- New columns
-- ---------------------------------------------------------------------------
-- H2: set by remove_member; a removed member cannot rejoin through an invite code.
alter table public.memberships add column removed_at timestamptz;
-- M2: set by moderators only (public.moderate_checkin / service_role).
alter table public.check_ins add column moderated_at timestamptz;

-- ---------------------------------------------------------------------------
-- Helpers (SECURITY DEFINER: avoid RLS recursion; fixed search_path)
-- ---------------------------------------------------------------------------
create function private.is_member(journey uuid) returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.memberships m
     where m.journey_id = journey
       and m.user_id = (select auth.uid())
       and m.status = 'active'
       and m.deleted_at is null
  );
$$;

create function private.is_owner(journey uuid) returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.memberships m
     where m.journey_id = journey
       and m.user_id = (select auth.uid())
       and m.role = 'owner'
       and m.status = 'active'
       and m.deleted_at is null
  );
$$;

-- True when the caller and `other` blocked each other (either direction).
create function private.is_blocked_pair(other uuid) returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.blocks b
     where b.deleted_at is null
       and ((b.blocker_id = (select auth.uid()) and b.blocked_id = other)
         or (b.blocked_id = (select auth.uid()) and b.blocker_id = other))
  );
$$;

-- FR-F2: content the caller reported is hidden from the caller at once.
create function private.has_reported(checkin uuid) returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.reports r
     where r.target_checkin_id = checkin
       and r.reporter_id = (select auth.uid())
       and r.deleted_at is null
  );
$$;

-- Live check-in in a journey the caller is active in, author not blocked either way.
create function private.can_see_checkin(checkin uuid) returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.check_ins c
     where c.id = checkin
       and c.deleted_at is null
       and private.is_member(c.journey_id)
       and not private.is_blocked_pair(c.user_id)
  );
$$;

-- can_see_checkin and not reported by the caller (content, media, reactions).
create function private.can_view_checkin(checkin uuid) returns boolean
language sql stable security definer set search_path = ''
as $$
  select private.can_see_checkin(checkin) and not private.has_reported(checkin);
$$;

-- L5: own profile, or an active co-member of an active membership of the caller, not blocked.
create function private.can_see_profile(other uuid) returns boolean
language sql stable security definer set search_path = ''
as $$
  select other = (select auth.uid())
      or (not private.is_blocked_pair(other)
          and exists (
            select 1 from public.memberships a
              join public.memberships b on b.journey_id = a.journey_id
             where a.user_id = (select auth.uid()) and b.user_id = other
               and a.status = 'active' and a.deleted_at is null
               and b.status = 'active' and b.deleted_at is null));
$$;

-- M3: storage object `checkins/{journey}/{author}/{id}[_t].jpg` is readable by others only if
-- the check-in row {id} is live, visible to the caller and its photo/thumb path is exactly it.
create function private.can_read_checkin_object(p_name text) returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.check_ins c
     where c.id = public.try_uuid(substring(p_name from '/([0-9a-f-]{36})(?:_t)?\.jpg$'))
       and (c.photo_path = p_name or c.thumb_path = p_name)
       and private.can_view_checkin(c.id)
  );
$$;

-- H1: another member's metric is readable only for a visible check-in whose author does not
-- hide metrics (memberships.hide_metric) and is still active.
create function private.can_see_metric(checkin uuid) returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.check_ins c
      join public.memberships m on m.journey_id = c.journey_id and m.user_id = c.user_id
     where c.id = checkin
       and m.status = 'active' and m.deleted_at is null and not m.hide_metric
       and private.can_view_checkin(c.id)
  );
$$;

revoke all on function private.is_member(uuid), private.is_owner(uuid),
  private.is_blocked_pair(uuid), private.has_reported(uuid), private.can_see_checkin(uuid),
  private.can_view_checkin(uuid), private.can_see_profile(uuid),
  private.can_read_checkin_object(text), private.can_see_metric(uuid) from public, anon;
grant execute on function private.is_member(uuid), private.is_owner(uuid),
  private.is_blocked_pair(uuid), private.has_reported(uuid), private.can_see_checkin(uuid),
  private.can_view_checkin(uuid), private.can_see_profile(uuid),
  private.can_read_checkin_object(text), private.can_see_metric(uuid) to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- H1: check_in_metrics
-- ---------------------------------------------------------------------------
create table public.check_in_metrics (
  checkin_id uuid primary key references public.check_ins (id) on delete cascade on update cascade,
  journey_id uuid not null references public.journeys (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  metric_value numeric,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index check_in_metrics_updated_idx on public.check_in_metrics (updated_at);
create index check_in_metrics_member_idx on public.check_in_metrics (journey_id, user_id);
create trigger check_in_metrics_updated before update on public.check_in_metrics
  for each row execute function public.set_updated_at();

-- journey_id / user_id always come from the check-in. Direct client writes need a live
-- check-in in an active journey (RLS then requires it to be the caller's own).
create function private.check_in_metrics_before_write() returns trigger
language plpgsql set search_path = ''
as $$
declare
  c record;
begin
  select ci.journey_id, ci.user_id, ci.deleted_at, j.status, j.deleted_at as journey_deleted
    into c
    from public.check_ins ci join public.journeys j on j.id = ci.journey_id
   where ci.id = new.checkin_id;
  if not found then
    raise exception 'not_found' using errcode = 'P0001';
  end if;
  new.journey_id := c.journey_id;
  new.user_id := c.user_id;
  if current_user in ('authenticated', 'anon') then
    if c.deleted_at is not null then
      raise exception 'not_found' using errcode = 'P0001';
    end if;
    if c.status <> 'active' or c.journey_deleted is not null then
      raise exception 'ended' using errcode = 'P0001';
    end if;
  end if;
  return new;
end;
$$;
create trigger check_in_metrics_before_write before insert or update on public.check_in_metrics
  for each row execute function private.check_in_metrics_before_write();

-- Move existing values, then blank the exposed column.
insert into public.check_in_metrics (checkin_id, journey_id, user_id, metric_value)
select id, journey_id, user_id, metric_value from public.check_ins where metric_value is not null;
update public.check_ins set metric_value = null where metric_value is not null;

alter table public.check_in_metrics enable row level security;
revoke all on public.check_in_metrics from anon, authenticated;
grant select, insert, update on public.check_in_metrics to authenticated;
create policy check_in_metrics_select on public.check_in_metrics for select to authenticated
  using (user_id = (select auth.uid()) or private.can_see_metric(checkin_id));
create policy check_in_metrics_insert on public.check_in_metrics for insert to authenticated
  with check (user_id = (select auth.uid()) and private.is_member(journey_id));
create policy check_in_metrics_update on public.check_in_metrics for update to authenticated
  using (user_id = (select auth.uid()) and private.is_member(journey_id))
  with check (user_id = (select auth.uid()) and private.is_member(journey_id));

-- Bump metric rows whenever their visibility can change, so other members' pull cursors pick
-- them up again: hide_metric toggled, check-in hidden/restored (leave, rejoin, moderation).
create function private.touch_member_metrics() returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  update public.check_in_metrics set updated_at = now()
   where journey_id = new.journey_id and user_id = new.user_id;
  return null;
end;
$$;
create trigger memberships_touch_metrics after update of hide_metric, status on public.memberships
  for each row
  when (old.hide_metric is distinct from new.hide_metric or old.status is distinct from new.status)
  execute function private.touch_member_metrics();

create function private.touch_checkin_metric() returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  update public.check_in_metrics set updated_at = now() where checkin_id = new.id;
  return null;
end;
$$;
create trigger check_ins_touch_metric after update of deleted_at on public.check_ins
  for each row when (old.deleted_at is distinct from new.deleted_at)
  execute function private.touch_checkin_metric();

revoke all on function private.check_in_metrics_before_write(), private.touch_member_metrics(),
  private.touch_checkin_metric() from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- check_ins write rules (H1 metric, M2 moderation, L2 backdating)
-- ---------------------------------------------------------------------------
-- Offline window: a check-in may be uploaded up to this many journey-local days late.
create or replace function public.check_ins_before_write() returns trigger
language plpgsql
set search_path = ''
as $$
declare
  j public.journeys%rowtype;
begin
  select * into j from public.journeys where id = new.journey_id;
  if not found then
    raise exception 'not_found' using errcode = 'P0001';
  end if;

  if tg_op = 'UPDATE' and (new.journey_id <> old.journey_id or new.user_id <> old.user_id) then
    raise exception 'immutable_column' using errcode = '23514';
  end if;

  -- Server decides the day, never the client.
  new.local_date := public.local_date(new.captured_at, j.timezone);
  -- H1: metric values live in public.check_in_metrics only.
  new.metric_value := null;

  -- Trigger runs SECURITY INVOKER so current_user is the real caller. Rules below apply to
  -- direct client writes only; SECURITY DEFINER RPCs run as the function owner.
  if current_user in ('authenticated', 'anon') then
    -- M2: a moderated check-in is frozen for its author (also blocks a retake upsert onto it).
    if tg_op = 'UPDATE' and old.moderated_at is not null then
      raise exception 'forbidden' using errcode = '42501';
    end if;
    if new.captured_at > now() + interval '10 minutes' then
      raise exception 'invalid_captured_at' using errcode = '22008';
    end if;
    -- L2: no backdating beyond the offline window (3 journey-local days).
    if (tg_op = 'INSERT' or new.captured_at is distinct from old.captured_at)
       and new.local_date < public.local_date(now(), j.timezone) - 3 then
      raise exception 'invalid_captured_at' using errcode = '22008';
    end if;
    if j.status <> 'active' or j.deleted_at is not null then
      raise exception 'ended' using errcode = 'P0001';
    end if;
    if j.duration_days is not null and new.local_date > j.start_date + j.duration_days - 1 then
      raise exception 'ended' using errcode = 'P0001';
    end if;
    -- hidden_by_leave / moderated_at are server-managed.
    if tg_op = 'INSERT' then
      new.hidden_by_leave := false;
      new.moderated_at := null;
    else
      new.hidden_by_leave := old.hidden_by_leave;
      new.moderated_at := old.moderated_at;
    end if;
  end if;
  return new;
end;
$$;

-- Column-level grants: hidden_by_leave, moderated_at, created_at, updated_at are server-only.
revoke insert, update on public.check_ins from authenticated;
grant insert (id, journey_id, user_id, local_date, captured_at, photo_path, thumb_path,
              from_library, caption, metric_value)
  on public.check_ins to authenticated;
grant update (id, journey_id, user_id, local_date, captured_at, photo_path, thumb_path,
              from_library, caption, metric_value, deleted_at)
  on public.check_ins to authenticated;

-- M2: moderator action (service_role / dashboard). Hides the row and its media for everyone
-- but the author, who can no longer modify it.
create function public.moderate_checkin(p_checkin uuid) returns void
language plpgsql security definer set search_path = ''
as $$
begin
  update public.check_ins
     set moderated_at = now(), deleted_at = coalesce(deleted_at, now())
   where id = p_checkin;
  if not found then
    raise exception 'not_found';
  end if;
end;
$$;
revoke all on function public.moderate_checkin(uuid) from public, anon, authenticated;
grant execute on function public.moderate_checkin(uuid) to service_role;

-- ---------------------------------------------------------------------------
-- Policies (L1: private helpers; M1, L5, L7)
-- ---------------------------------------------------------------------------
drop policy profiles_select on public.profiles;
create policy profiles_select on public.profiles for select to authenticated
  using (private.can_see_profile(id));

drop policy journeys_select on public.journeys;
create policy journeys_select on public.journeys for select to authenticated
  using (private.is_member(id));
drop policy journeys_update on public.journeys;
create policy journeys_update on public.journeys for update to authenticated
  using (private.is_owner(id) and status = 'active' and deleted_at is null)
  with check (private.is_owner(id));

drop policy memberships_select on public.memberships;
create policy memberships_select on public.memberships for select to authenticated
  using (user_id = (select auth.uid()) or private.is_member(journey_id));

-- M1: soft-deleted rows (incl. hidden_by_leave, moderated) are visible to their author only;
-- other members learn about deletions from checkin_tombstones().
drop policy check_ins_select on public.check_ins;
create policy check_ins_select on public.check_ins for select to authenticated
  using (
    user_id = (select auth.uid())
    or (deleted_at is null
        and private.is_member(journey_id)
        and not private.is_blocked_pair(user_id)
        and not private.has_reported(id))
  );
drop policy check_ins_insert on public.check_ins;
create policy check_ins_insert on public.check_ins for insert to authenticated
  with check (user_id = (select auth.uid()) and private.is_member(journey_id));
drop policy check_ins_update on public.check_ins;
create policy check_ins_update on public.check_ins for update to authenticated
  using (user_id = (select auth.uid()) and private.is_member(journey_id))
  with check (user_id = (select auth.uid()) and private.is_member(journey_id));

drop policy reactions_select on public.reactions;
create policy reactions_select on public.reactions for select to authenticated
  using (private.can_view_checkin(checkin_id) and not private.is_blocked_pair(user_id));
drop policy reactions_insert on public.reactions;
create policy reactions_insert on public.reactions for insert to authenticated
  with check (user_id = (select auth.uid()) and private.can_view_checkin(checkin_id));
drop policy reactions_update on public.reactions;
create policy reactions_update on public.reactions for update to authenticated
  using (user_id = (select auth.uid()) and private.can_view_checkin(checkin_id))
  with check (user_id = (select auth.uid()) and private.can_view_checkin(checkin_id));

-- L7: deletion is server-side only (delete-account).
revoke update (deleted_at) on public.profiles from authenticated;

-- ---------------------------------------------------------------------------
-- Storage (M3, L5)
-- ---------------------------------------------------------------------------
drop policy media_select on storage.objects;
create policy media_select on storage.objects for select to authenticated
using (
  bucket_id = 'media'
  and (
    (
      (storage.foldername(name))[1] = 'checkins'
      and array_length(storage.foldername(name), 1) = 3
      and (
        -- own objects always (upload upserts happen before the row exists)
        (storage.foldername(name))[3] = (select auth.uid())::text
        or private.can_read_checkin_object(name)
      )
    )
    or (
      (storage.foldername(name))[1] = 'avatars'
      and array_length(storage.foldername(name), 1) = 2
      and private.can_see_profile(public.try_uuid((storage.foldername(name))[2]))
    )
  )
);

drop policy media_insert on storage.objects;
create policy media_insert on storage.objects for insert to authenticated
with check (
  bucket_id = 'media'
  and (
    (
      (storage.foldername(name))[1] = 'checkins'
      and array_length(storage.foldername(name), 1) = 3
      and (storage.foldername(name))[3] = (select auth.uid())::text
      and private.is_member(public.try_uuid((storage.foldername(name))[2]))
      and storage.filename(name) ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}(_t)?\.jpg$'
    )
    or (
      (storage.foldername(name))[1] = 'avatars'
      and array_length(storage.foldername(name), 1) = 2
      and (storage.foldername(name))[2] = (select auth.uid())::text
      and exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.deleted_at is null)
      and storage.filename(name) ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.jpg$'
    )
  )
);

drop policy media_update on storage.objects;
create policy media_update on storage.objects for update to authenticated
using (
  bucket_id = 'media'
  and (
    ((storage.foldername(name))[1] = 'checkins'
      and (storage.foldername(name))[3] = (select auth.uid())::text
      and private.is_member(public.try_uuid((storage.foldername(name))[2])))
    or ((storage.foldername(name))[1] = 'avatars'
      and (storage.foldername(name))[2] = (select auth.uid())::text)
  )
)
with check (
  bucket_id = 'media'
  and (
    ((storage.foldername(name))[1] = 'checkins'
      and array_length(storage.foldername(name), 1) = 3
      and (storage.foldername(name))[3] = (select auth.uid())::text
      and private.is_member(public.try_uuid((storage.foldername(name))[2])))
    or ((storage.foldername(name))[1] = 'avatars'
      and array_length(storage.foldername(name), 1) = 2
      and (storage.foldername(name))[2] = (select auth.uid())::text)
  )
);

-- ---------------------------------------------------------------------------
-- FKs (L3, L7)
-- ---------------------------------------------------------------------------
alter table public.reports drop constraint reports_target_checkin_id_fkey,
  add constraint reports_target_checkin_id_fkey foreign key (target_checkin_id)
    references public.check_ins (id) on delete set null on update cascade;
alter table public.moderation_queue drop constraint moderation_queue_report_id_fkey,
  add constraint moderation_queue_report_id_fkey foreign key (report_id)
    references public.reports (id) on delete set null;

-- ---------------------------------------------------------------------------
-- M4: join throttle (server-only table, never exposed)
-- ---------------------------------------------------------------------------
create table private.join_attempts (
  user_id uuid not null,
  attempted_at timestamptz not null default now(),
  success boolean not null
);
create index join_attempts_user_idx on private.join_attempts (user_id, attempted_at);
alter table private.join_attempts enable row level security;
revoke all on private.join_attempts from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- RPCs
-- ---------------------------------------------------------------------------
-- join_by_code. Unknown or malformed codes return an EMPTY row (every column NULL; PostgREST
-- sends {"id": null, ...}) so the failed attempt is committed: clients map id == null to
-- not_found. Errors: rate_limited (>= 10 failed codes in the last hour), forbidden (deleted
-- profile, or removed from this group by the owner), ended, blocked, full, limit.
create or replace function public.join_by_code(code text) returns public.journeys
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := public._uid();
  v_code text := upper(btrim(code));
  j public.journeys%rowtype;
  m public.memberships%rowtype;
  v_rejoin boolean;
begin
  -- Serialises attempts per user (also makes the throttle count exact).
  perform 1 from public.profiles where id = uid and deleted_at is null for update;
  if not found then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  delete from private.join_attempts
   where user_id = uid and attempted_at < now() - interval '1 hour';
  if (select count(*) from private.join_attempts where user_id = uid and not success) >= 10 then
    raise exception 'rate_limited';
  end if;

  if v_code is not null and v_code ~ '^[A-Z0-9]{8}$' then
    select * into j from public.journeys
     where invite_code = v_code and kind = 'group' and deleted_at is null
     for update;
  end if;
  if j.id is null then
    insert into private.join_attempts (user_id, success) values (uid, false);
    return null; -- not_found
  end if;

  if j.status <> 'active' then
    raise exception 'ended';
  end if;
  if j.duration_days is not null
     and public.local_date(now(), j.timezone) > j.start_date + j.duration_days - 1 then
    raise exception 'ended';
  end if;

  select * into m from public.memberships where journey_id = j.id and user_id = uid;
  v_rejoin := found;
  if v_rejoin and m.status = 'active' then
    return j; -- idempotent
  end if;
  if v_rejoin and m.removed_at is not null then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  -- A block in either direction between the joiner and any active member prevents joining.
  if exists (
    select 1
      from public.memberships am
      join public.blocks b
        on b.deleted_at is null
       and ((b.blocker_id = uid and b.blocked_id = am.user_id)
         or (b.blocked_id = uid and b.blocker_id = am.user_id))
     where am.journey_id = j.id and am.status = 'active' and am.deleted_at is null
  ) then
    raise exception 'blocked';
  end if;

  if (select count(*) from public.memberships
       where journey_id = j.id and status = 'active' and deleted_at is null) >= j.max_members then
    raise exception 'full';
  end if;

  if public._active_journey_count(uid) >= 3 then
    raise exception 'limit';
  end if;

  if v_rejoin then
    -- Rejoin: keep original joined_at (personal progress), restore hidden check-ins.
    update public.memberships set status = 'active', role = 'member', deleted_at = null
     where journey_id = j.id and user_id = uid;
    update public.check_ins set deleted_at = null, hidden_by_leave = false
     where journey_id = j.id and user_id = uid and hidden_by_leave and moderated_at is null;
  else
    insert into public.memberships (journey_id, user_id, role, hide_metric)
    values (j.id, uid, 'member', j.hide_metric_default);
  end if;
  return j;
end;
$$;

-- H2: removal is permanent for invite codes, and the code the member knew stops working.
create or replace function public.remove_member(journey uuid, member uuid) returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := public._uid();
  v_code text;
begin
  if member is null or member = uid then
    raise exception 'invalid';
  end if;
  if not exists (select 1 from public.memberships
                  where journey_id = journey and user_id = uid
                    and role = 'owner' and status = 'active') then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  perform public._leave_journey(journey, member);
  update public.memberships set removed_at = now()
   where journey_id = journey and user_id = member;
  if exists (select 1 from public.journeys where id = journey and kind = 'group') then
    loop
      v_code := public.random_token(8, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789');
      exit when not exists (select 1 from public.journeys where invite_code = v_code);
    end loop;
    update public.journeys set invite_code = v_code where id = journey;
  end if;
end;
$$;

-- L7: a check-in the caller reported is not shown (checked_in stays true).
create or replace function public.group_today(journey uuid)
returns table (
  user_id uuid,
  username text,
  display_name text,
  avatar_path text,
  role public.member_role,
  checked_in boolean,
  checkin_id uuid,
  thumb_path text,
  captured_at timestamptz,
  current_streak int
)
language plpgsql
stable
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  v_tz text;
  v_today date;
begin
  perform public._uid();
  if not private.is_member(journey) then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  select j.timezone into v_tz from public.journeys j where j.id = journey;
  v_today := public.local_date(now(), v_tz);

  return query
  select m.user_id, p.username, p.display_name, p.avatar_path, m.role,
         (c.id is not null),
         case when r.hidden then null else c.id end,
         case when r.hidden then null else c.thumb_path end,
         case when r.hidden then null else c.captured_at end,
         coalesce(s.current_streak, 0)
    from public.memberships m
    join public.profiles p on p.id = m.user_id
    left join public.check_ins c
      on c.journey_id = m.journey_id and c.user_id = m.user_id
     and c.local_date = v_today and c.deleted_at is null
    left join lateral (select c.id is not null and private.has_reported(c.id) as hidden) r on true
    left join lateral public.journey_streak(m.journey_id, m.user_id, v_today) s on true
   where m.journey_id = journey and m.status = 'active' and m.deleted_at is null
     and not private.is_blocked_pair(m.user_id)
   order by m.joined_at, m.user_id;
end;
$$;

-- M1: deletions of other members' check-ins, without content. Pull with an updated_at cursor
-- (same overlap rule as tables), at most `lim` (<= 1000) rows ordered by updated_at.
create function public.checkin_tombstones(since timestamptz default null, lim int default 1000)
returns table (id uuid, journey_id uuid, updated_at timestamptz)
language sql
stable
security definer
set search_path = ''
as $$
  select c.id, c.journey_id, c.updated_at
    from public.check_ins c
   where c.deleted_at is not null
     and c.user_id <> (select auth.uid())
     and (since is null or c.updated_at >= since)
     and private.is_member(c.journey_id)
   order by c.updated_at, c.id
   limit least(greatest(coalesce(lim, 1000), 1), 1000);
$$;

create or replace function public.report_content(
  p_checkin uuid,
  p_user uuid,
  p_reason public.report_reason,
  p_note text default null
) returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := public._uid();
  v_target_user uuid := p_user;
  v_id uuid;
begin
  if (p_checkin is null and p_user is null) or p_reason is null then
    raise exception 'invalid';
  end if;
  if p_checkin is not null then
    if not private.can_see_checkin(p_checkin) then
      raise exception 'not_found';
    end if;
    select c.user_id into v_target_user from public.check_ins c where c.id = p_checkin;
  elsif p_user = uid
     or not exists (
       select 1 from public.memberships a
         join public.memberships b on b.journey_id = a.journey_id
        where a.user_id = uid and b.user_id = p_user
          and a.status = 'active' and b.status = 'active') then
    raise exception 'not_found';
  end if;
  if v_target_user = uid then
    raise exception 'invalid';
  end if;
  if (select count(*) from public.reports
       where reporter_id = uid and created_at > now() - interval '24 hours') >= 20 then
    raise exception 'rate_limited';
  end if;

  insert into public.reports (reporter_id, target_checkin_id, target_user_id, reason, note)
  values (uid, p_checkin, v_target_user, p_reason, left(nullif(btrim(p_note), ''), 500))
  returning id into v_id;
  insert into public.moderation_queue (kind, report_id, actor_id, target_user_id, target_checkin_id, reason, note)
  values ('report', v_id, uid, v_target_user, p_checkin, p_reason, left(nullif(btrim(p_note), ''), 500));
  return v_id;
end;
$$;

-- L4: re-blocking after an unblock does not queue again.
create or replace function public.block_user(p_user uuid) returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := public._uid();
  b public.blocks%rowtype;
begin
  if p_user is null or p_user = uid then
    raise exception 'invalid';
  end if;
  if not exists (select 1 from public.profiles where id = p_user and deleted_at is null) then
    raise exception 'not_found';
  end if;
  select * into b from public.blocks where blocker_id = uid and blocked_id = p_user for update;
  if found then
    if b.deleted_at is not null then
      update public.blocks set deleted_at = null where blocker_id = uid and blocked_id = p_user;
    end if;
    return; -- idempotent; only the first-ever block is a moderation signal
  end if;
  insert into public.blocks (blocker_id, blocked_id) values (uid, p_user)
  on conflict (blocker_id, blocked_id) do update set deleted_at = null;
  insert into public.moderation_queue (kind, actor_id, target_user_id)
  values ('block', uid, p_user);
end;
$$;

revoke all on function public.checkin_tombstones(timestamptz, int) from public, anon;
grant execute on function public.checkin_tombstones(timestamptz, int) to authenticated;

-- ---------------------------------------------------------------------------
-- L1: drop the API-exposed helpers (every dependent policy/function was recreated above)
-- ---------------------------------------------------------------------------
drop function public.can_read_checkin_media(uuid, uuid);
drop function public.can_see_checkin(uuid);
drop function public.has_reported(uuid);
drop function public.is_blocked_pair(uuid);
drop function public.is_owner(uuid);
drop function public.is_member(uuid);
