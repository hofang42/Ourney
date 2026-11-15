-- 0011_pin_hide_extras_km:
--   1. check_in_extras_valid learns `km` (number 0.1..500, one decimal).
--   2. memberships.pinned          per-user journey pin (own preference).
--   3. memberships.hide_extras     author hides mood/minutes/place/dish/cook/hearts/pace/km
--                                  from other members.
--   4. public.check_in_extras      extras moved out of check_ins into their own table (like
--      check_in_metrics, 0005) so RLS can honour hide_extras. check_ins.extras is kept for wire
--      compatibility but is always stored as an empty object.
-- Idempotent: safe to re-run. Tests: supabase/tests/11_pin_hide_extras_km.test.sql.

-- ---------------------------------------------------------------------------
-- 1. extras validation: + km
-- ---------------------------------------------------------------------------
create or replace function public.check_in_extras_valid(x jsonb) returns boolean
language sql immutable set search_path = ''
as $$
  select case
    when x is null or jsonb_typeof(x) <> 'object' then false
    when octet_length(x::text) > 512 then false
    when exists (
      select 1 from jsonb_object_keys(x) k
       where k not in ('mood', 'minutes', 'place', 'dish', 'cook', 'hearts', 'pace', 'km')
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
      and case when x ? 'km' then jsonb_typeof(x -> 'km') = 'number'
             and (x ->> 'km') ~ '^[0-9]{1,3}(\.[0-9]0*)?$'
             and case when (x ->> 'km') ~ '^[0-9]{1,3}(\.[0-9]0*)?$'
                      then (x ->> 'km')::numeric between 0.1 and 500 else false end
             else true end
  end;
$$;

revoke execute on function public.check_in_extras_valid(jsonb) from public, anon;
grant execute on function public.check_in_extras_valid(jsonb) to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 2 + 3. membership preferences
-- ---------------------------------------------------------------------------
alter table public.memberships
  add column if not exists hide_extras boolean not null default false,
  add column if not exists pinned boolean not null default false;

-- Members update only their own row (memberships_update policy); column-level grant.
grant update (hide_metric, blur_media, hide_extras, pinned) on public.memberships to authenticated;

-- ---------------------------------------------------------------------------
-- 4. check_in_extras
-- ---------------------------------------------------------------------------
create table if not exists public.check_in_extras (
  checkin_id uuid primary key references public.check_ins (id) on delete cascade on update cascade,
  journey_id uuid not null references public.journeys (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  extras jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint check_in_extras_valid check (public.check_in_extras_valid(extras))
);
create index if not exists check_in_extras_updated_idx on public.check_in_extras (updated_at);
create index if not exists check_in_extras_member_idx on public.check_in_extras (journey_id, user_id);

drop trigger if exists check_in_extras_updated on public.check_in_extras;
create trigger check_in_extras_updated before update on public.check_in_extras
  for each row execute function public.set_updated_at();

-- journey_id / user_id always come from the check-in (same rules as check_in_metrics).
drop trigger if exists check_in_extras_before_write on public.check_in_extras;
create trigger check_in_extras_before_write before insert or update on public.check_in_extras
  for each row execute function private.check_in_metrics_before_write();

-- Another member's extras are readable only for a visible check-in whose author does not hide
-- them (memberships.hide_extras) and is still active.
create or replace function private.can_see_extras(checkin uuid) returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.check_ins c
      join public.memberships m on m.journey_id = c.journey_id and m.user_id = c.user_id
     where c.id = checkin
       and m.status = 'active' and m.deleted_at is null and not m.hide_extras
       and private.can_view_checkin(c.id)
  );
$$;
revoke all on function private.can_see_extras(uuid) from public, anon;
grant execute on function private.can_see_extras(uuid) to authenticated, service_role;

alter table public.check_in_extras enable row level security;
revoke all on public.check_in_extras from anon, authenticated;
grant select, insert, update on public.check_in_extras to authenticated;

drop policy if exists check_in_extras_select on public.check_in_extras;
create policy check_in_extras_select on public.check_in_extras for select to authenticated
  using (user_id = (select auth.uid()) or private.can_see_extras(checkin_id));
drop policy if exists check_in_extras_insert on public.check_in_extras;
create policy check_in_extras_insert on public.check_in_extras for insert to authenticated
  with check (user_id = (select auth.uid()) and private.is_member(journey_id));
drop policy if exists check_in_extras_update on public.check_in_extras;
create policy check_in_extras_update on public.check_in_extras for update to authenticated
  using (user_id = (select auth.uid()) and private.is_member(journey_id))
  with check (user_id = (select auth.uid()) and private.is_member(journey_id));

-- Re-bump rows when their visibility can change so other members' pull cursors pick them up.
create or replace function private.touch_member_extras() returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  update public.check_in_extras set updated_at = now()
   where journey_id = new.journey_id and user_id = new.user_id;
  return null;
end;
$$;
drop trigger if exists memberships_touch_extras on public.memberships;
create trigger memberships_touch_extras after update of hide_extras, status on public.memberships
  for each row
  when (old.hide_extras is distinct from new.hide_extras or old.status is distinct from new.status)
  execute function private.touch_member_extras();

create or replace function private.touch_checkin_extras() returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  update public.check_in_extras set updated_at = now() where checkin_id = new.id;
  return null;
end;
$$;
drop trigger if exists check_ins_touch_extras on public.check_ins;
create trigger check_ins_touch_extras after update of deleted_at on public.check_ins
  for each row when (old.deleted_at is distinct from new.deleted_at)
  execute function private.touch_checkin_extras();

-- check_ins.extras never carries data any more (it would bypass hide_extras).
create or replace function private.check_ins_blank_extras() returns trigger
language plpgsql set search_path = ''
as $$
begin
  new.extras := '{}'::jsonb;
  return new;
end;
$$;
drop trigger if exists check_ins_blank_extras on public.check_ins;
create trigger check_ins_blank_extras before insert or update on public.check_ins
  for each row execute function private.check_ins_blank_extras();

revoke all on function private.touch_member_extras(), private.touch_checkin_extras(),
  private.check_ins_blank_extras() from public, anon, authenticated;

-- Move existing values, then blank the exposed column.
insert into public.check_in_extras (checkin_id, journey_id, user_id, extras)
select id, journey_id, user_id, extras from public.check_ins where extras <> '{}'::jsonb
on conflict (checkin_id) do nothing;
update public.check_ins set extras = '{}'::jsonb where extras <> '{}'::jsonb;
