-- 0013_unlimited_journeys:
--   SRS FR-B3 (owner decision 2026-11-12): no cap on running journeys per user.
--   Redefines create_journey (body from 0007) and join_by_code (body from 0005) without the
--   `_active_journey_count(uid) >= 3 -> 'limit'` check; nothing else in either body changes.
--   Drops the now-unused helper public._active_journey_count. The `limit` error is never raised.
-- Idempotent (create or replace / drop if exists). Tests: supabase/tests/04_lifecycle.test.sql.

create or replace function public.create_journey(
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
  p_visibility public.journey_visibility default 'private',
  p_couple_self_name text default null,
  p_couple_partner_name text default null
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
  v_self text := nullif(btrim(p_couple_self_name), '');
  v_partner text := nullif(btrim(p_couple_partner_name), '');
begin
  if p_id is null or p_kind is null or p_start_date is null or p_timezone is null then
    raise exception 'invalid';
  end if;
  if (p_kind = 'group' and p_visibility = 'link')
     or (p_kind = 'solo' and p_visibility = 'group') then
    raise exception 'invalid';
  end if;
  -- Couple names come as a pair of 1..24 characters, or not at all.
  if (v_self is null) <> (v_partner is null)
     or char_length(coalesce(v_self, '')) > 24 or char_length(coalesce(v_partner, '')) > 24 then
    raise exception 'invalid';
  end if;

  perform 1 from public.profiles where id = uid and deleted_at is null for update;
  if not found then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  select * into j from public.journeys where id = p_id;
  if found then
    if j.owner_id = uid then
      return j;
    end if;
    raise exception 'forbidden' using errcode = '42501';
  end if;

  if p_kind = 'group' then
    v_visibility := 'group';
    loop
      v_code := public.random_token(8, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789');
      exit when not exists (select 1 from public.journeys where invite_code = v_code);
    end loop;
  elsif p_visibility = 'link' then
    v_visibility := 'link';
    v_token := public.random_token(40, 'abcdefghijklmnopqrstuvwxyz0123456789');
  else
    v_visibility := 'private';
  end if;

  insert into public.journeys (
    id, owner_id, kind, template_id, title, emoji, metric_name, metric_unit,
    hide_metric_default, start_date, duration_days, timezone, visibility, status,
    invite_code, max_members, public_token, couple_self_name, couple_partner_name)
  values (
    p_id, uid, p_kind, coalesce(p_template_id, 'custom'), btrim(p_title), p_emoji,
    p_metric_name, p_metric_unit, coalesce(p_hide_metric_default, false), p_start_date,
    p_duration_days, p_timezone, v_visibility, 'active', v_code,
    case when p_kind = 'solo' then 1 else coalesce(p_max_members, 10) end, v_token,
    v_self, v_partner)
  returning * into j;

  insert into public.memberships (journey_id, user_id, role, hide_metric)
  values (j.id, uid, 'owner', j.hide_metric_default);

  return j;
end;
$$;

revoke all on function public.create_journey(uuid, public.journey_kind, public.template_id, text, text, text, text, boolean, date, int, text, int, public.journey_visibility, text, text)
  from public, anon;
grant execute on function public.create_journey(uuid, public.journey_kind, public.template_id, text, text, text, text, boolean, date, int, text, int, public.journey_visibility, text, text)
  to authenticated;

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

-- Grants of join_by_code are kept by create or replace (same signature).

drop function if exists public._active_journey_count(uuid);
