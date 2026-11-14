-- 0007_post_extras_couple: V2 backend parity.
--   1. check_ins.extras  validated jsonb: per-skin Post inputs (mood, minutes, place, dish, cook,
--      hearts, pace). Same visibility as the check-in row itself (RLS unchanged).
--   2. check_ins.partner_photo_path  optional photo of the partner for couple journeys, stored in
--      the author's own folder as checkins/{journey}/{author}/{checkin}_p.jpg.
--   3. journeys.couple_self_name / couple_partner_name  persisted couple names.
-- Idempotent: safe to re-run. Tests: supabase/tests/07_post_extras_couple.test.sql.

-- ---------------------------------------------------------------------------
-- 1. extras validation
-- ---------------------------------------------------------------------------
-- Whitelist of keys and value shapes. IMMUTABLE so it can back a CHECK constraint.
create or replace function public.check_in_extras_valid(x jsonb) returns boolean
language sql immutable set search_path = ''
as $$
  select case
    when x is null or jsonb_typeof(x) <> 'object' then false
    when octet_length(x::text) > 512 then false
    when exists (
      select 1 from jsonb_object_keys(x) k
       where k not in ('mood', 'minutes', 'place', 'dish', 'cook', 'hearts', 'pace')
    ) then false
    else
      case when x ? 'mood' then jsonb_typeof(x -> 'mood') = 'string'
             and char_length(x ->> 'mood') between 1 and 24 else true end
      and case when x ? 'place' then jsonb_typeof(x -> 'place') = 'string'
             and char_length(x ->> 'place') between 1 and 60 else true end
      and case when x ? 'dish' then jsonb_typeof(x -> 'dish') = 'string'
             and char_length(x ->> 'dish') between 1 and 60 else true end
      and case when x ? 'cook' then jsonb_typeof(x -> 'cook') = 'string'
             and char_length(x ->> 'cook') between 1 and 24 else true end
      and case when x ? 'minutes' then jsonb_typeof(x -> 'minutes') = 'number'
             and (x ->> 'minutes') ~ '^[0-9]{1,4}$'
             and case when (x ->> 'minutes') ~ '^[0-9]{1,4}$'
                      then (x ->> 'minutes')::int between 1 and 1440 else false end
             else true end
      and case when x ? 'hearts' then jsonb_typeof(x -> 'hearts') = 'number'
             and (x ->> 'hearts') ~ '^[1-5]$' else true end
      and case when x ? 'pace' then jsonb_typeof(x -> 'pace') = 'string'
             and (x ->> 'pace') ~ '^[0-9]{1,2}:[0-5][0-9]$' else true end
  end;
$$;

alter table public.check_ins
  add column if not exists extras jsonb not null default '{}'::jsonb;

alter table public.check_ins drop constraint if exists check_ins_extras_valid;
alter table public.check_ins
  add constraint check_ins_extras_valid check (public.check_in_extras_valid(extras));

-- ---------------------------------------------------------------------------
-- 2. partner photo (couple journeys)
-- ---------------------------------------------------------------------------
alter table public.check_ins add column if not exists partner_photo_path text;

alter table public.check_ins drop constraint if exists check_ins_partner_photo_path;
alter table public.check_ins
  add constraint check_ins_partner_photo_path check (
    partner_photo_path is null
    or partner_photo_path = 'checkins/' || journey_id || '/' || user_id || '/' || id || '_p.jpg'
  );

-- Column-level grants (0005 revoked table-wide insert/update): extend with the new columns.
grant insert (id, journey_id, user_id, local_date, captured_at, photo_path, thumb_path,
              from_library, caption, metric_value, extras, partner_photo_path)
  on public.check_ins to authenticated;
grant update (id, journey_id, user_id, local_date, captured_at, photo_path, thumb_path,
              from_library, caption, metric_value, deleted_at, extras, partner_photo_path)
  on public.check_ins to authenticated;

-- Storage: the partner photo follows the same rules as the photo and thumbnail. It lives in the
-- author's folder, so own-folder write rules and the live-check-in read rule apply unchanged;
-- only the file-name pattern and the row <-> object match learn the `_p` suffix.
create or replace function private.can_read_checkin_object(p_name text) returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.check_ins c
     where c.id = public.try_uuid(substring(p_name from '/([0-9a-f-]{36})(?:_[tp])?\.jpg$'))
       and (c.photo_path = p_name or c.thumb_path = p_name or c.partner_photo_path = p_name)
       and private.can_view_checkin(c.id)
  );
$$;

drop policy if exists media_insert on storage.objects;
create policy media_insert on storage.objects for insert to authenticated
with check (
  bucket_id = 'media'
  and (
    (
      (storage.foldername(name))[1] = 'checkins'
      and array_length(storage.foldername(name), 1) = 3
      and (storage.foldername(name))[3] = (select auth.uid())::text
      and private.is_member(public.try_uuid((storage.foldername(name))[2]))
      and storage.filename(name) ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}(_[tp])?\.jpg$'
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

-- ---------------------------------------------------------------------------
-- 3. couple names
-- ---------------------------------------------------------------------------
alter table public.journeys
  add column if not exists couple_self_name text,
  add column if not exists couple_partner_name text;

alter table public.journeys drop constraint if exists journeys_couple_names;
alter table public.journeys
  add constraint journeys_couple_names check (
    (couple_self_name is null and couple_partner_name is null)
    or (
      couple_self_name is not null and couple_partner_name is not null
      and char_length(btrim(couple_self_name)) between 1 and 24
      and char_length(btrim(couple_partner_name)) between 1 and 24
    )
  );

-- Owners may rename (journeys_update policy already restricts to the owner of an active journey).
grant update (couple_self_name, couple_partner_name) on public.journeys to authenticated;

-- create_journey gains two trailing optional parameters. The old signature is replaced (not
-- overloaded) so PostgREST named-argument calls stay unambiguous.
drop function if exists public.create_journey(uuid, public.journey_kind, public.template_id, text, text, text, text, boolean, date, int, text, int, public.journey_visibility);

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

  if public._active_journey_count(uid) >= 3 then
    raise exception 'limit';
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
