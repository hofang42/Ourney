-- 0004_rpc: validated SECURITY DEFINER RPCs (group lifecycle, limits, moderation).
-- Error convention: `raise exception '<code>'` (SQLSTATE P0001) so clients match on message:
--   not_found | full | blocked | limit | ended | forbidden(42501) | unauthenticated(28000) | invalid
-- Every function: fixed search_path = '', fully qualified names, auth.uid() checked.

-- ---------------------------------------------------------------------------
-- Internal helpers (not exposed to API roles)
-- ---------------------------------------------------------------------------
create function public._uid() returns uuid
language plpgsql
stable
set search_path = ''
as $$
declare
  u uuid := (select auth.uid());
begin
  if u is null then
    raise exception 'unauthenticated' using errcode = '28000';
  end if;
  return u;
end;
$$;

create function public._active_journey_count(p_user uuid) returns int
language sql
stable
security definer
set search_path = ''
as $$
  select count(*)::int
    from public.memberships m
    join public.journeys j on j.id = m.journey_id
   where m.user_id = p_user and m.status = 'active' and m.deleted_at is null
     and j.status = 'active' and j.deleted_at is null;
$$;

-- Leave semantics (02 §9.1): hide the member's check-ins (restored on rejoin),
-- hand ownership to the earliest active member, archive the journey if nobody is left.
create function public._leave_journey(p_journey uuid, p_user uuid) returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  was_owner boolean;
  next_owner uuid;
begin
  perform 1 from public.journeys where id = p_journey for update;
  select (role = 'owner') into was_owner
    from public.memberships
   where journey_id = p_journey and user_id = p_user and status = 'active' and deleted_at is null
   for update;
  if was_owner is null then
    raise exception 'not_found';
  end if;

  update public.memberships set status = 'left', role = 'member'
   where journey_id = p_journey and user_id = p_user;
  update public.check_ins set deleted_at = now(), hidden_by_leave = true
   where journey_id = p_journey and user_id = p_user and deleted_at is null;

  if was_owner then
    select user_id into next_owner
      from public.memberships
     where journey_id = p_journey and status = 'active' and deleted_at is null
     order by joined_at, user_id
     limit 1;
    if next_owner is null then
      update public.journeys set status = 'archived' where id = p_journey;
    else
      update public.memberships set role = 'owner'
       where journey_id = p_journey and user_id = next_owner;
      update public.journeys set owner_id = next_owner where id = p_journey;
    end if;
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- create_journey
-- ---------------------------------------------------------------------------
create function public.create_journey(
  p_id uuid,
  p_kind public.journey_kind,
  p_template_id public.template_id,
  p_title text,
  p_emoji text,
  p_metric_name text,
  p_metric_unit text,
  p_hide_metric_default boolean,
  p_start_date date,
  p_duration_days int,
  p_timezone text,
  p_max_members int default 10,
  p_public_link boolean default false
) returns public.journeys
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := public._uid();
  j public.journeys%rowtype;
  v_visibility public.journey_visibility;
  v_code text;
  v_token text;
begin
  if p_id is null or p_kind is null or p_start_date is null or p_timezone is null then
    raise exception 'invalid';
  end if;
  if p_kind = 'group' and p_public_link then
    raise exception 'invalid';
  end if;

  -- Serialise per user so concurrent creates cannot exceed the limit.
  perform 1 from public.profiles where id = uid and deleted_at is null for update;
  if not found then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  -- Idempotent retry from the offline queue.
  select * into j from public.journeys where id = p_id;
  if found then
    if j.owner_id = uid then
      return j;
    end if;
    raise exception 'forbidden' using errcode = '42501';
  end if;

  if public._active_journey_count(uid) >= 3 then
    raise exception 'limit';
  end if;

  if p_kind = 'group' then
    v_visibility := 'group';
    loop
      v_code := public.random_token(8, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789');
      exit when not exists (select 1 from public.journeys where invite_code = v_code);
    end loop;
  elsif p_public_link then
    v_visibility := 'link';
    v_token := public.random_token(40, 'abcdefghijklmnopqrstuvwxyz0123456789');
  else
    v_visibility := 'private';
  end if;

  insert into public.journeys (
    id, owner_id, kind, template_id, title, emoji, metric_name, metric_unit,
    hide_metric_default, start_date, duration_days, timezone, visibility, status,
    invite_code, max_members, public_token)
  values (
    p_id, uid, p_kind, coalesce(p_template_id, 'custom'), btrim(p_title), p_emoji,
    p_metric_name, p_metric_unit, coalesce(p_hide_metric_default, false), p_start_date,
    p_duration_days, p_timezone, v_visibility, 'active', v_code,
    case when p_kind = 'solo' then 1 else coalesce(p_max_members, 10) end, v_token)
  returning * into j;

  insert into public.memberships (journey_id, user_id, role, hide_metric)
  values (j.id, uid, 'owner', j.hide_metric_default);

  return j;
end;
$$;

-- ---------------------------------------------------------------------------
-- join_by_code
-- ---------------------------------------------------------------------------
create function public.join_by_code(code text) returns public.journeys
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
  if v_code is null or v_code !~ '^[A-Z0-9]{8}$' then
    raise exception 'not_found';
  end if;

  perform 1 from public.profiles where id = uid and deleted_at is null for update;
  if not found then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  select * into j from public.journeys
   where invite_code = v_code and kind = 'group' and deleted_at is null
   for update;
  if not found then
    raise exception 'not_found';
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
     where journey_id = j.id and user_id = uid and hidden_by_leave;
  else
    insert into public.memberships (journey_id, user_id, role, hide_metric)
    values (j.id, uid, 'member', j.hide_metric_default);
  end if;
  return j;
end;
$$;

-- ---------------------------------------------------------------------------
-- rotate_invite / leave / remove / end / delete / public link
-- ---------------------------------------------------------------------------
create function public.rotate_invite(journey uuid) returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := public._uid();
  j public.journeys%rowtype;
  v_code text;
begin
  select * into j from public.journeys where id = journey and deleted_at is null for update;
  if not found then
    raise exception 'not_found';
  end if;
  if not exists (select 1 from public.memberships
                  where journey_id = journey and user_id = uid
                    and role = 'owner' and status = 'active') then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if j.kind <> 'group' then
    raise exception 'invalid';
  end if;
  if j.status <> 'active' then
    raise exception 'ended';
  end if;
  loop
    v_code := public.random_token(8, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789');
    exit when not exists (select 1 from public.journeys where invite_code = v_code);
  end loop;
  update public.journeys set invite_code = v_code where id = journey;
  return v_code;
end;
$$;

create function public.leave_journey(journey uuid) returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public._leave_journey(journey, public._uid());
end;
$$;

create function public.remove_member(journey uuid, member uuid) returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := public._uid();
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
end;
$$;

create function public.end_journey(journey uuid) returns public.journeys
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := public._uid();
  j public.journeys%rowtype;
begin
  select * into j from public.journeys where id = journey and deleted_at is null for update;
  if not found then
    raise exception 'not_found';
  end if;
  if not exists (select 1 from public.memberships
                  where journey_id = journey and user_id = uid
                    and role = 'owner' and status = 'active') then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if j.status <> 'active' then
    raise exception 'ended';
  end if;
  update public.journeys set status = 'ended' where id = journey returning * into j;
  return j;
end;
$$;

-- Owner may delete only while alone; otherwise the journey can only be ended (02 §9.1).
create function public.delete_journey(journey uuid) returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := public._uid();
begin
  perform 1 from public.journeys where id = journey and deleted_at is null for update;
  if not found then
    raise exception 'not_found';
  end if;
  if not exists (select 1 from public.memberships
                  where journey_id = journey and user_id = uid
                    and role = 'owner' and status = 'active') then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if exists (select 1 from public.memberships
              where journey_id = journey and user_id <> uid
                and status = 'active' and deleted_at is null) then
    raise exception 'not_alone';
  end if;
  update public.journeys set deleted_at = now(), status = 'archived' where id = journey;
end;
$$;

-- Solo journeys only. enabled=true creates OR rotates the public token (old one stops working);
-- enabled=false revokes it. Returns the new token (null when revoked).
create function public.set_public_link(journey uuid, enabled boolean) returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := public._uid();
  j public.journeys%rowtype;
  v_token text;
begin
  select * into j from public.journeys where id = journey and deleted_at is null for update;
  if not found then
    raise exception 'not_found';
  end if;
  if not exists (select 1 from public.memberships
                  where journey_id = journey and user_id = uid
                    and role = 'owner' and status = 'active') then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if j.kind <> 'solo' then
    raise exception 'invalid';
  end if;
  if j.status = 'archived' then
    raise exception 'ended';
  end if;
  if coalesce(enabled, false) then
    v_token := public.random_token(40, 'abcdefghijklmnopqrstuvwxyz0123456789');
    update public.journeys set visibility = 'link', public_token = v_token where id = journey;
  else
    update public.journeys set visibility = 'private', public_token = null where id = journey;
  end if;
  return v_token;
end;
$$;

-- ---------------------------------------------------------------------------
-- group_today: today's board for a journey
-- ---------------------------------------------------------------------------
create function public.group_today(journey uuid)
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
  if not public.is_member(journey) then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  select j.timezone into v_tz from public.journeys j where j.id = journey;
  v_today := public.local_date(now(), v_tz);

  return query
  select m.user_id, p.username, p.display_name, p.avatar_path, m.role,
         (c.id is not null), c.id, c.thumb_path, c.captured_at,
         coalesce(s.current_streak, 0)
    from public.memberships m
    join public.profiles p on p.id = m.user_id
    left join public.check_ins c
      on c.journey_id = m.journey_id and c.user_id = m.user_id
     and c.local_date = v_today and c.deleted_at is null
    left join lateral public.journey_streak(m.journey_id, m.user_id, v_today) s on true
   where m.journey_id = journey and m.status = 'active' and m.deleted_at is null
     and not public.is_blocked_pair(m.user_id)
   order by m.joined_at, m.user_id;
end;
$$;

-- ---------------------------------------------------------------------------
-- Moderation
-- ---------------------------------------------------------------------------
create function public.report_content(
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
    if not public.can_see_checkin(p_checkin) then
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
  values (uid, p_checkin, v_target_user, p_reason, nullif(btrim(p_note), ''))
  returning id into v_id;
  return v_id;
end;
$$;

create function public.block_user(p_user uuid) returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := public._uid();
begin
  if p_user is null or p_user = uid then
    raise exception 'invalid';
  end if;
  if not exists (select 1 from public.profiles where id = p_user and deleted_at is null) then
    raise exception 'not_found';
  end if;
  insert into public.blocks (blocker_id, blocked_id) values (uid, p_user)
  on conflict (blocker_id, blocked_id) do update set deleted_at = null;
end;
$$;

create function public.unblock_user(p_user uuid) returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := public._uid();
begin
  update public.blocks set deleted_at = now()
   where blocker_id = uid and blocked_id = p_user and deleted_at is null;
end;
$$;

-- ---------------------------------------------------------------------------
-- Account deletion support (service_role only; called by the delete-account Edge Function)
-- Two steps so the function is retry-safe: list media, remove storage, purge, delete auth user.
-- ---------------------------------------------------------------------------
create function public.account_media_paths(p_user uuid) returns setof text
language sql
stable
security definer
set search_path = ''
as $$
  select c.photo_path from public.check_ins c where c.user_id = p_user
  union
  select c.thumb_path from public.check_ins c where c.user_id = p_user
  union
  -- media of journeys that will be deleted with the account (owner alone, nobody else active)
  select x.p
    from public.journeys j
    join public.check_ins c on c.journey_id = j.id
    cross join lateral (values (c.photo_path), (c.thumb_path)) as x(p)
   where j.owner_id = p_user
     and not exists (select 1 from public.memberships m
                      where m.journey_id = j.id and m.user_id <> p_user and m.status = 'active')
  union
  select pr.avatar_path from public.profiles pr where pr.id = p_user and pr.avatar_path is not null;
$$;

-- Hands over owned groups to the earliest active member, hard-deletes journeys where the
-- user is the only active member. Everything else cascades when the auth user is deleted.
create function public.purge_account_data(p_user uuid) returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  r record;
begin
  for r in
    select j.id from public.journeys j where j.owner_id = p_user
  loop
    if exists (select 1 from public.memberships m
                where m.journey_id = r.id and m.user_id <> p_user
                  and m.status = 'active' and m.deleted_at is null) then
      -- other members remain: transfer ownership and hide the leaver's content
      if exists (select 1 from public.memberships m
                  where m.journey_id = r.id and m.user_id = p_user and m.status = 'active') then
        perform public._leave_journey(r.id, p_user);
      end if;
    else
      delete from public.journeys where id = r.id;
    end if;
  end loop;
end;
$$;

-- ---------------------------------------------------------------------------
-- Privileges
-- ---------------------------------------------------------------------------
revoke all on function public._uid(), public._active_journey_count(uuid),
  public._leave_journey(uuid, uuid) from public, anon, authenticated;

revoke all on function
  public.create_journey(uuid, public.journey_kind, public.template_id, text, text, text, text, boolean, date, int, text, int, boolean),
  public.join_by_code(text), public.rotate_invite(uuid), public.leave_journey(uuid),
  public.remove_member(uuid, uuid), public.end_journey(uuid), public.delete_journey(uuid),
  public.set_public_link(uuid, boolean), public.group_today(uuid),
  public.report_content(uuid, uuid, public.report_reason, text),
  public.block_user(uuid), public.unblock_user(uuid)
  from public, anon;
grant execute on function
  public.create_journey(uuid, public.journey_kind, public.template_id, text, text, text, text, boolean, date, int, text, int, boolean),
  public.join_by_code(text), public.rotate_invite(uuid), public.leave_journey(uuid),
  public.remove_member(uuid, uuid), public.end_journey(uuid), public.delete_journey(uuid),
  public.set_public_link(uuid, boolean), public.group_today(uuid),
  public.report_content(uuid, uuid, public.report_reason, text),
  public.block_user(uuid), public.unblock_user(uuid)
  to authenticated;

revoke all on function public.account_media_paths(uuid), public.purge_account_data(uuid)
  from public, anon, authenticated;
grant execute on function public.account_media_paths(uuid), public.purge_account_data(uuid)
  to service_role;
