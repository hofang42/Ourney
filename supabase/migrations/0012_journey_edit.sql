-- 0012_journey_edit:
--   journeys.layout         nullable skin override (one of the 6 persona skins), used by home, timeline, camera.
--   journeys.cover          nullable sticker index 0..2.
--   journeys.color          nullable colour variant index 0..2 (per-skin palette).
--   journeys.reminder_time  nullable 'HH:MM' (24 h, journey-local) suggested reminder.
--   journeys.dna            nullable validated jsonb with the create-flow answers (goal, ritual, HUD, ...).
--   public.update_journey   owner-only SECURITY DEFINER RPC that validates and writes the fields + title.
-- Additive and idempotent: safe to re-run. Tests: supabase/tests/12_journey_edit.test.sql.

alter table public.journeys
  add column if not exists layout text,
  add column if not exists cover smallint,
  add column if not exists color smallint,
  add column if not exists reminder_time text,
  add column if not exists dna jsonb;

-- ---------------------------------------------------------------------------
-- dna validator: object <= 1024 bytes, whitelisted keys, per-key shape.
-- The weight and the ghost photo request are intentionally NOT storable here (they stay private
-- to the owner's device; journeys rows are readable by every member).
-- ---------------------------------------------------------------------------
create or replace function public.journey_dna_valid(x jsonb) returns boolean
language sql immutable set search_path = ''
as $$
  select case
    when x is null then true
    when jsonb_typeof(x) <> 'object' then false
    when octet_length(x::text) > 1024 then false
    when exists (
      select 1 from jsonb_object_keys(x) k
       where k not in ('goal', 'minutes', 'sport', 'measure', 'hud', 'film', 'ritual', 'side',
                       'trophy', 'place', 'habit', 'reason', 'dates')
    ) then false
    else
      not exists (
        select 1 from jsonb_each(x) e
         where e.key in ('goal', 'minutes', 'sport', 'measure', 'hud', 'film', 'ritual', 'side')
           and not (jsonb_typeof(e.value) = 'string' and (e.value #>> '{}') ~ '^[a-z0-9_]{1,24}$')
      )
      and not exists (
        select 1 from jsonb_each(x) e
         where e.key in ('trophy', 'place', 'habit', 'reason')
           and not (jsonb_typeof(e.value) = 'string'
                    and char_length(e.value #>> '{}') between 1
                        and case e.key when 'trophy' then 24 when 'place' then 60
                                       when 'habit' then 40 else 80 end)
      )
      and case when x ? 'dates' then
            jsonb_typeof(x -> 'dates') = 'object'
            and not exists (select 1 from jsonb_object_keys(x -> 'dates') k where k not in ('start', 'end'))
            and (x -> 'dates') ? 'start'
            and (x #>> '{dates,start}') ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
            and case when (x -> 'dates') ? 'end'
                     then (x #>> '{dates,end}') ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' else true end
          else true end
  end;
$$;
revoke execute on function public.journey_dna_valid(jsonb) from public, anon;
grant execute on function public.journey_dna_valid(jsonb) to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- column constraints (re-creatable)
-- ---------------------------------------------------------------------------
alter table public.journeys drop constraint if exists journeys_layout_valid;
alter table public.journeys add constraint journeys_layout_valid check (
  layout is null or layout in ('quiet_transformer', 'accountability_squad', 'memory_collectors',
                               'couple_rituals', 'aesthetic_flexer', 'minimalist_habit'));
alter table public.journeys drop constraint if exists journeys_cover_valid;
alter table public.journeys add constraint journeys_cover_valid check (cover is null or cover between 0 and 2);
alter table public.journeys drop constraint if exists journeys_color_valid;
alter table public.journeys add constraint journeys_color_valid check (color is null or color between 0 and 2);
alter table public.journeys drop constraint if exists journeys_reminder_time_valid;
alter table public.journeys add constraint journeys_reminder_time_valid check (
  reminder_time is null or reminder_time ~ '^([01][0-9]|2[0-3]):[0-5][0-9]$');
alter table public.journeys drop constraint if exists journeys_dna_valid;
alter table public.journeys add constraint journeys_dna_valid check (public.journey_dna_valid(dna));

-- ---------------------------------------------------------------------------
-- update_journey: owner-only. NULL argument = leave unchanged; list a field in p_clear to reset it
-- to NULL ('layout', 'cover', 'color', 'reminder_time', 'dna').
-- Errors (SQLSTATE P0001, message): not_found (no such journey / not the owner), ended (not active),
-- invalid (bad value, squad layout on a solo journey, couple layout without couple names).
-- ---------------------------------------------------------------------------
create or replace function public.update_journey(
  p_journey uuid,
  p_title text default null,
  p_layout text default null,
  p_cover int default null,
  p_color int default null,
  p_reminder_time text default null,
  p_dna jsonb default null,
  p_clear text[] default '{}'
) returns public.journeys
language plpgsql security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
  j public.journeys%rowtype;
  v_title text := btrim(p_title);
  v_clear text[] := coalesce(p_clear, '{}');
begin
  select * into j from public.journeys
   where id = p_journey and owner_id = uid and deleted_at is null for update;
  if not found then
    raise exception 'not_found';
  end if;
  if j.status <> 'active' then
    raise exception 'ended';
  end if;
  if exists (select 1 from unnest(v_clear) c
              where c not in ('layout', 'cover', 'color', 'reminder_time', 'dna')) then
    raise exception 'invalid';
  end if;
  if p_title is not null and char_length(v_title) not between 1 and 60 then
    raise exception 'invalid';
  end if;
  if p_layout is not null and p_layout not in
     ('quiet_transformer', 'accountability_squad', 'memory_collectors',
      'couple_rituals', 'aesthetic_flexer', 'minimalist_habit') then
    raise exception 'invalid';
  end if;
  if p_layout = 'accountability_squad' and j.kind <> 'group' then
    raise exception 'invalid';
  end if;
  if p_layout = 'couple_rituals' and j.couple_self_name is null then
    raise exception 'invalid';
  end if;
  if p_cover is not null and p_cover not between 0 and 2 then
    raise exception 'invalid';
  end if;
  if p_color is not null and p_color not between 0 and 2 then
    raise exception 'invalid';
  end if;
  if p_reminder_time is not null and p_reminder_time !~ '^([01][0-9]|2[0-3]):[0-5][0-9]$' then
    raise exception 'invalid';
  end if;
  if p_dna is not null and not (jsonb_typeof(p_dna) = 'object' and public.journey_dna_valid(p_dna)) then
    raise exception 'invalid';
  end if;

  update public.journeys set
    title = coalesce(v_title, title),
    layout = case when 'layout' = any (v_clear) then null else coalesce(p_layout, layout) end,
    cover = case when 'cover' = any (v_clear) then null else coalesce(p_cover, cover) end,
    color = case when 'color' = any (v_clear) then null else coalesce(p_color, color) end,
    reminder_time = case when 'reminder_time' = any (v_clear) then null
                         else coalesce(p_reminder_time, reminder_time) end,
    dna = case when 'dna' = any (v_clear) then null else coalesce(p_dna, dna) end
   where id = j.id returning * into j;
  return j;
end;
$$;

revoke execute on function public.update_journey(uuid, text, text, int, int, text, jsonb, text[]) from public, anon;
grant execute on function public.update_journey(uuid, text, text, int, int, text, jsonb, text[]) to authenticated;
