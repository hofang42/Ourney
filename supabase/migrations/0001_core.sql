-- 0001_core: enums, tables, triggers, pure helpers, streak functions.
-- Contract: docs/contracts/schema.md (v1). Additions are marked "CONTRACT ADDITION".

-- ---------------------------------------------------------------------------
-- Enums
-- ---------------------------------------------------------------------------
create type public.journey_kind as enum ('solo', 'group');
create type public.journey_visibility as enum ('private', 'group', 'link');
create type public.journey_status as enum ('active', 'ended', 'archived');
create type public.member_role as enum ('owner', 'member');
create type public.member_status as enum ('active', 'left');
create type public.template_id as enum ('weight_loss', 'english_daily', 'workout_30', 'travel', 'custom');
create type public.report_reason as enum ('spam', 'nudity', 'harassment', 'self_harm', 'other');

-- ---------------------------------------------------------------------------
-- Generic helpers
-- ---------------------------------------------------------------------------
create function public.set_updated_at() returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

-- Calendar date of ts in IANA timezone tz.
create function public.local_date(ts timestamptz, tz text) returns date
language sql
stable
parallel safe
set search_path = ''
as $$
  select (ts at time zone tz)::date;
$$;

-- Safe text -> uuid cast (NULL on malformed input); used by storage policies.
create function public.try_uuid(t text) returns uuid
language plpgsql
immutable
set search_path = ''
as $$
begin
  return t::uuid;
exception when others then
  return null;
end;
$$;

-- Unguessable random token/code generator. Uses gen_random_uuid() (CSPRNG) bytes.
-- alphabet is the set of allowed characters, len the output length.
create function public.random_token(len int, alphabet text) returns text
language plpgsql
volatile
set search_path = ''
as $$
declare
  out text := '';
  b bytea;
  i int := 0;
  n int := length(alphabet);
begin
  while length(out) < len loop
    b := uuid_send(gen_random_uuid());
    i := 0;
    while i < 16 and length(out) < len loop
      -- rejection sampling: avoid modulo bias
      if get_byte(b, i) < (256 / n) * n then
        out := out || substr(alphabet, (get_byte(b, i) % n) + 1, 1);
      end if;
      i := i + 1;
    end loop;
  end loop;
  return out;
end;
$$;

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  username text not null unique check (username ~ '^[a-z0-9_.]{3,20}$'),
  display_name text not null check (char_length(display_name) between 1 and 40),
  avatar_path text check (avatar_path is null or avatar_path ~ ('^avatars/' || id::text || '/[0-9a-f-]{36}\.jpg$')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table public.journeys (
  id uuid primary key,
  owner_id uuid not null references public.profiles (id) on delete cascade,
  kind public.journey_kind not null,
  template_id public.template_id not null default 'custom',
  title text not null check (char_length(title) between 1 and 60),
  emoji text not null check (char_length(emoji) between 1 and 16),
  metric_name text check (metric_name is null or char_length(metric_name) <= 40),
  metric_unit text check (metric_unit is null or char_length(metric_unit) <= 16),
  hide_metric_default boolean not null default false,
  start_date date not null,
  duration_days int check (duration_days is null or duration_days between 7 and 365),
  timezone text not null,
  visibility public.journey_visibility not null default 'private',
  status public.journey_status not null default 'active',
  invite_code text unique check (invite_code is null or invite_code ~ '^[A-Z0-9]{8}$'),
  max_members int not null default 10 check (max_members between 1 and 10),
  -- CONTRACT ADDITION: revocable token for the public-journey Edge Function (link solo only).
  public_token text unique check (public_token is null or char_length(public_token) >= 32),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint journeys_link_only_solo check (visibility <> 'link' or kind = 'solo'),
  constraint journeys_group_visibility check (kind <> 'group' or visibility = 'group'),
  constraint journeys_solo_visibility check (kind <> 'solo' or visibility in ('private', 'link')),
  constraint journeys_invite_group_only check (invite_code is null or kind = 'group'),
  constraint journeys_token_iff_link check ((public_token is not null) = (visibility = 'link'))
);
create index journeys_owner_idx on public.journeys (owner_id);
create index journeys_updated_idx on public.journeys (updated_at);

create table public.memberships (
  journey_id uuid not null references public.journeys (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  role public.member_role not null default 'member',
  status public.member_status not null default 'active',
  joined_at timestamptz not null default now(),
  hide_metric boolean not null default false,
  blur_media boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  primary key (journey_id, user_id)
);
create index memberships_user_idx on public.memberships (user_id) where status = 'active';
create index memberships_updated_idx on public.memberships (updated_at);
-- Exactly one active owner per journey.
create unique index memberships_one_owner_idx on public.memberships (journey_id)
  where role = 'owner' and status = 'active';

create table public.check_ins (
  id uuid primary key,
  journey_id uuid not null references public.journeys (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  local_date date not null,
  captured_at timestamptz not null,
  photo_path text not null,
  thumb_path text not null,
  from_library boolean not null default false,
  caption text check (caption is null or char_length(caption) <= 140),
  metric_value numeric,
  -- CONTRACT ADDITION: marks rows hidden because the author left the group (restored on rejoin).
  hidden_by_leave boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint check_ins_unique_day unique (journey_id, user_id, local_date),
  constraint check_ins_photo_path check (photo_path = 'checkins/' || journey_id || '/' || user_id || '/' || id || '.jpg'),
  constraint check_ins_thumb_path check (thumb_path = 'checkins/' || journey_id || '/' || user_id || '/' || id || '_t.jpg')
);
create index check_ins_journey_date_idx on public.check_ins (journey_id, local_date);
create index check_ins_updated_idx on public.check_ins (updated_at);
create index check_ins_user_idx on public.check_ins (user_id);

create table public.reactions (
  checkin_id uuid not null references public.check_ins (id) on delete cascade on update cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  emoji text not null check (emoji in ('🔥', '💪', '👏', '❤️', '😂')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  primary key (checkin_id, user_id)
);
create index reactions_updated_idx on public.reactions (updated_at);

create table public.blocks (
  blocker_id uuid not null references public.profiles (id) on delete cascade,
  blocked_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  primary key (blocker_id, blocked_id),
  constraint blocks_not_self check (blocker_id <> blocked_id)
);
create index blocks_blocked_idx on public.blocks (blocked_id);

-- reports: user-facing record (status = 'open' | 'actioned' | 'dismissed').
-- At least one target is required; enforced by report_content() rather than a CHECK, because
-- both FKs are ON DELETE SET NULL and an account deletion must not fail on old reports.
create table public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles (id) on delete cascade,
  target_checkin_id uuid references public.check_ins (id) on delete set null,
  target_user_id uuid references public.profiles (id) on delete set null,
  reason public.report_reason not null,
  note text check (note is null or char_length(note) <= 500),
  status text not null default 'open' check (status in ('open', 'actioned', 'dismissed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);
create index reports_open_idx on public.reports (created_at) where status = 'open';

-- moderation_queue: server-only work queue for moderators (service_role / dashboard).
-- Filled by report_content() and block_user(); never readable through the API.
-- Snapshot ids are kept without FKs so evidence survives the target's account deletion.
create table public.moderation_queue (
  id uuid primary key default gen_random_uuid(),
  kind text not null check (kind in ('report', 'block')),
  report_id uuid references public.reports (id) on delete cascade,
  actor_id uuid,
  target_user_id uuid,
  target_checkin_id uuid,
  reason public.report_reason,
  note text,
  status text not null default 'open' check (status in ('open', 'actioned', 'dismissed')),
  handled_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index moderation_queue_open_idx on public.moderation_queue (created_at) where status = 'open';

-- updated_at triggers (sync cursor is server authoritative)
create trigger profiles_updated before update on public.profiles for each row execute function public.set_updated_at();
create trigger journeys_updated before update on public.journeys for each row execute function public.set_updated_at();
create trigger memberships_updated before update on public.memberships for each row execute function public.set_updated_at();
create trigger check_ins_updated before update on public.check_ins for each row execute function public.set_updated_at();
create trigger reactions_updated before update on public.reactions for each row execute function public.set_updated_at();
create trigger blocks_updated before update on public.blocks for each row execute function public.set_updated_at();
create trigger reports_updated before update on public.reports for each row execute function public.set_updated_at();
create trigger moderation_queue_updated before update on public.moderation_queue for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Journey validation
-- ---------------------------------------------------------------------------
create function public.journeys_validate() returns trigger
language plpgsql
set search_path = ''
as $$
begin
  -- Raises 22023 for an unknown IANA timezone.
  perform now() at time zone new.timezone;
  if tg_op = 'UPDATE' and (
       new.kind is distinct from old.kind
    or new.timezone is distinct from old.timezone
    or new.start_date is distinct from old.start_date
    or new.id is distinct from old.id) then
    raise exception 'immutable_column' using errcode = '23514';
  end if;
  return new;
end;
$$;
create trigger journeys_validate before insert or update on public.journeys
  for each row execute function public.journeys_validate();

-- ---------------------------------------------------------------------------
-- check_ins: server-authoritative local_date + invariants
-- ---------------------------------------------------------------------------
create function public.check_ins_before_write() returns trigger
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

  -- Trigger runs SECURITY INVOKER so current_user is the real caller. Rules below apply to direct client writes only; SECURITY DEFINER RPCs
  -- (leave/remove/rejoin) run as the function owner and bypass them.
  if current_user in ('authenticated', 'anon') then
    if new.captured_at > now() + interval '10 minutes' then
      raise exception 'invalid_captured_at' using errcode = '22008';
    end if;
    if j.status <> 'active' or j.deleted_at is not null then
      raise exception 'ended' using errcode = 'P0001';
    end if;
    if j.duration_days is not null and new.local_date > j.start_date + j.duration_days - 1 then
      raise exception 'ended' using errcode = 'P0001';
    end if;
    -- hidden_by_leave is server-managed.
    if tg_op = 'INSERT' then
      new.hidden_by_leave := false;
    else
      new.hidden_by_leave := old.hidden_by_leave;
    end if;
  end if;
  return new;
end;
$$;
create trigger check_ins_before_write before insert or update on public.check_ins
  for each row execute function public.check_ins_before_write();

-- reactions: read-only once the journey is not active (direct client writes only)
create function public.reactions_before_write() returns trigger
language plpgsql
set search_path = ''
as $$
declare
  s public.journey_status;
begin
  if current_user in ('authenticated', 'anon') then
    select j.status into s
      from public.check_ins c join public.journeys j on j.id = c.journey_id
     where c.id = new.checkin_id;
    -- s is null when the caller cannot see the check-in: let RLS reject it (42501).
    if s is not null and s <> 'active' then
      raise exception 'ended' using errcode = 'P0001';
    end if;
  end if;
  return new;
end;
$$;
create trigger reactions_before_write before insert or update on public.reactions
  for each row execute function public.reactions_before_write();

-- ---------------------------------------------------------------------------
-- Streak (SQL is the server source of truth; shares streak_vectors.json with Dart)
-- ---------------------------------------------------------------------------
-- Core: p_dates are check-in local dates; the journey window is [p_win_start, p_win_end]
-- (p_win_end NULL = open, evaluated up to p_today).
--   best      = longest consecutive run over ALL dates <= today (window-agnostic)
--   current   = run of in-window dates ending today, or yesterday (not lost until the day is over)
--   completed = distinct in-window dates
create function public.streak_core(p_dates date[], p_win_start date, p_win_end date, p_today date)
returns table (current_streak int, best_streak int, completed_days int)
language sql
immutable
parallel safe
set search_path = ''
as $$
  with d as (
    select distinct x as dt from unnest(p_dates) as x where x is not null and x <= p_today
  ),
  all_runs as (
    select count(*)::int as c
      from (select dt, dt - (row_number() over (order by dt))::int as g from d) r
     group by g
  ),
  w as (
    select dt from d
     where dt >= p_win_start and dt <= coalesce(p_win_end, p_today)
  ),
  w_runs as (
    select count(*)::int as c, max(dt) as mx
      from (select dt, dt - (row_number() over (order by dt))::int as g from w) r
     group by g
  )
  select
    coalesce((select c from w_runs where mx >= p_today - 1 order by mx desc limit 1), 0),
    coalesce((select max(c) from all_runs), 0),
    (select count(*)::int from w);
$$;

-- Vector-shaped entry point: (dates, start, duration|null, today).
create function public.streak_from_dates(p_dates date[], p_start date, p_duration int, p_today date)
returns table (current_streak int, best_streak int, completed_days int)
language sql
immutable
parallel safe
set search_path = ''
as $$
  select * from public.streak_core(
    p_dates, p_start,
    case when p_duration is null then null else p_start + p_duration - 1 end,
    p_today);
$$;

-- Per-member streak for a journey. SECURITY INVOKER: RLS decides what the caller may see
-- (service_role bypasses RLS, used by the public-journey Edge Function).
-- Personal progress counts from the local date of memberships.joined_at (02 §9.1).
create function public.journey_streak(journey uuid, member uuid, today date default null)
returns table (current_streak int, best_streak int, completed_days int)
language plpgsql
stable
set search_path = ''
as $$
declare
  j public.journeys%rowtype;
  joined date;
  t date;
  dates date[];
begin
  select * into j from public.journeys where id = journey;
  if not found then
    return;
  end if;
  select public.local_date(m.joined_at, j.timezone) into joined
    from public.memberships m where m.journey_id = journey and m.user_id = member;
  if joined is null then
    return;
  end if;
  t := coalesce(today, public.local_date(now(), j.timezone));
  select coalesce(array_agg(c.local_date), '{}') into dates
    from public.check_ins c
   where c.journey_id = journey and c.user_id = member
     and c.deleted_at is null and c.local_date >= joined;
  return query select * from public.streak_core(
    dates,
    greatest(j.start_date, joined),
    case when j.duration_days is null then null else j.start_date + j.duration_days - 1 end,
    t);
end;
$$;
