-- 0027_ux_journeys_fixes:
-- 1. UX-04: allow `rename_couple` and `update_journey(..., p_layout := 'couple_rituals')`
--    on couple journeys (`couple_self_name is not null`, `max_members = 2`,
--    `layout = 'couple_rituals'`, or `emoji in ('💞', '❤️')`) even when
--    `couple_self_name` was initially NULL.
-- 2. UX-19: return `layout` from `follow_frame` so `FollowJourneyScreen` and
--    cloned journeys respect a customized layout override.

create or replace function public.rename_couple(p_journey uuid, p_self text, p_partner text)
returns public.journeys
language plpgsql security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
  j public.journeys%rowtype;
  v_self text := btrim(p_self);
  v_partner text := btrim(p_partner);
begin
  select * into j from public.journeys
   where id = p_journey and owner_id = uid and deleted_at is null for update;
  if not found then
    raise exception 'not_found';
  end if;
  if j.status <> 'active' then
    raise exception 'ended';
  end if;
  if j.couple_self_name is null
     and j.max_members <> 2
     and coalesce(j.layout, '') <> 'couple_rituals'
     and j.emoji not in ('💞', '❤️') then
    raise exception 'invalid';
  end if;
  if v_self is null or v_partner is null
     or char_length(v_self) not between 1 and 24
     or char_length(v_partner) not between 1 and 24 then
    raise exception 'invalid';
  end if;
  update public.journeys
     set couple_self_name = v_self, couple_partner_name = v_partner
   where id = p_journey
   returning * into j;
  return j;
end;
$$;

revoke all on function public.rename_couple(uuid, text, text) from public, anon;
grant execute on function public.rename_couple(uuid, text, text) to authenticated;

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
  if p_layout = 'couple_rituals'
     and j.couple_self_name is null
     and j.max_members <> 2
     and coalesce(j.layout, '') <> 'couple_rituals'
     and j.emoji not in ('💞', '❤️') then
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

create or replace function public.follow_frame(p_journey uuid) returns json
language plpgsql stable security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
  j public.journeys%rowtype;
begin
  select * into j from public.journeys where id = p_journey and deleted_at is null;
  if not found then
    raise exception 'not_found';
  end if;
  if not (private.is_member(j.id)
          or (not private.is_blocked_pair(j.owner_id)
              and (private.has_active_share(j.id, uid) or j.public_token is not null))) then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if j.status not in ('ended', 'archived') and j.origin <> 'imported' then
    raise exception 'invalid';
  end if;
  return json_build_object(
    'source_journey_id', j.id,
    'template_id', j.template_id,
    'kind', j.kind,
    'title', j.title,
    'emoji', j.emoji,
    'owner_name', private.owner_for_viewer(j.id)->>'display_name',
    'duration_days', j.duration_days,
    'metric_name', j.metric_name,
    'metric_unit', j.metric_unit,
    'layout', j.layout);
end;
$$;

revoke all on function public.follow_frame(uuid) from public, anon;
grant execute on function public.follow_frame(uuid) to authenticated;
