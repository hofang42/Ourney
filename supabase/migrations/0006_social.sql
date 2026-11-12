-- 0006_social: friends, journey sharing, story, follow-along, retold (imported) journeys,
-- group share consents, 1-1 chat, insights. Contract: docs/contracts/sharing.md (v1.3),
-- decisions S1-S40 in docs/09-journey-sharing.md. Tests: supabase/tests/06_social_*.test.sql.
--
-- Error convention (as 0004/0005): `raise exception '<code>'` (SQLSTATE P0001) except
-- forbidden (42501) and unauthenticated (28000, via public._uid()).
--
-- Replaced v1.2 objects: set_public_link (+ reset), report_content (+ p_message),
-- check_ins write rules (imported journeys), check_in_metrics write rules (imported journeys),
-- private.can_see_profile, private.can_read_checkin_object, reactions RLS.

-- ---------------------------------------------------------------------------
-- journeys / check_ins: new columns and relaxed constraints
-- ---------------------------------------------------------------------------
alter table public.journeys
  add column origin text not null default 'live' check (origin in ('live', 'imported')),
  add column story_title text check (story_title is null or char_length(story_title) <= 80),
  add column story_intro text check (story_intro is null or char_length(story_intro) <= 600),
  add column story_lessons text check (story_lessons is null or char_length(story_lessons) <= 600),
  add column cover_checkin_id uuid references public.check_ins (id) on delete set null on update cascade,
  add column followed_from uuid references public.journeys (id) on delete set null,
  add column show_counts boolean not null default false,
  -- S28: false for weight_loss (set by journeys_social_defaults on insert), else true.
  add column allow_public_reactions boolean not null default true,
  add column allow_viewer_requests boolean not null default true;
create index journeys_followed_from_idx on public.journeys (followed_from) where followed_from is not null;

update public.journeys set allow_public_reactions = false, allow_viewer_requests = false
 where template_id = 'weight_loss';

-- S32: public_token is decoupled from visibility for groups (visibility stays 'group').
alter table public.journeys drop constraint journeys_token_iff_link;
alter table public.journeys add constraint journeys_token_link
  check (kind = 'group' or (public_token is not null) = (visibility = 'link'));

-- Retold journeys span 1..366 days (create_imported_journey); live ones keep 7..365.
alter table public.journeys drop constraint journeys_duration_days_check;
alter table public.journeys add constraint journeys_duration_days_check
  check (duration_days is null
         or duration_days between 7 and 365
         or (origin = 'imported' and duration_days between 1 and 366));

create function private.journeys_social_defaults() returns trigger
language plpgsql set search_path = ''
as $$
begin
  if new.template_id = 'weight_loss' then
    new.allow_public_reactions := false;
    new.allow_viewer_requests := false;
  end if;
  return new;
end;
$$;
create trigger journeys_social_defaults before insert on public.journeys
  for each row execute function private.journeys_social_defaults();

alter table public.check_ins add column hidden_in_share boolean not null default false;

-- ---------------------------------------------------------------------------
-- New tables
-- ---------------------------------------------------------------------------
create table public.friendships (
  user_low uuid not null references public.profiles (id) on delete cascade,
  user_high uuid not null references public.profiles (id) on delete cascade,
  requested_by uuid not null references public.profiles (id) on delete cascade,
  status text not null check (status in ('pending', 'accepted')),
  source text not null default 'direct' check (source in ('direct', 'public_journey')),
  source_journey_id uuid references public.journeys (id) on delete set null,
  accepted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  primary key (user_low, user_high),
  constraint friendships_ordered check (user_low < user_high),
  constraint friendships_requester check (requested_by in (user_low, user_high))
);
create index friendships_high_idx on public.friendships (user_high);

create table public.friend_invites (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  token text not null unique check (token ~ '^[a-z0-9]{12}$'),
  created_at timestamptz not null default now()
);

create table public.journey_shares (
  journey_id uuid not null references public.journeys (id) on delete cascade,
  viewer_id uuid not null references public.profiles (id) on delete cascade,
  shared_by uuid not null references public.profiles (id) on delete cascade,
  granted_at timestamptz not null default now(),
  revoked_at timestamptz,
  seen_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (journey_id, viewer_id, shared_by),
  constraint journey_shares_not_self check (viewer_id <> shared_by)
);
create index journey_shares_viewer_idx on public.journey_shares (viewer_id) where revoked_at is null;
create index journey_shares_by_idx on public.journey_shares (shared_by);

create table public.journey_share_consents (
  journey_id uuid not null references public.journeys (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  status text not null check (status in ('pending', 'accepted', 'declined', 'withdrawn')),
  requested_by uuid references public.profiles (id) on delete set null,
  decided_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (journey_id, user_id)
);

create table public.saved_journeys (
  user_id uuid not null references public.profiles (id) on delete cascade,
  journey_id uuid not null references public.journeys (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, journey_id)
);

create table public.journey_views (
  journey_id uuid not null references public.journeys (id) on delete cascade,
  viewer_key text not null check (char_length(viewer_key) between 1 and 128),
  day date not null,
  created_at timestamptz not null default now(),
  primary key (journey_id, viewer_key, day)
);

create table public.conversations (
  id uuid primary key default gen_random_uuid(),
  journey_id uuid not null references public.journeys (id) on delete cascade,
  member_id uuid not null references public.profiles (id) on delete cascade,
  viewer_id uuid not null references public.profiles (id) on delete cascade,
  last_message_at timestamptz,
  member_read_at timestamptz,
  viewer_read_at timestamptz,
  member_cleared_at timestamptz,
  viewer_cleared_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint conversations_pair unique (journey_id, member_id, viewer_id),
  constraint conversations_not_self check (member_id <> viewer_id)
);
create index conversations_member_idx on public.conversations (member_id);
create index conversations_viewer_idx on public.conversations (viewer_id);

create table public.messages (
  id uuid primary key,
  conversation_id uuid not null references public.conversations (id) on delete cascade,
  sender_id uuid not null references public.profiles (id) on delete cascade,
  kind text not null check (kind in ('text', 'photo', 'clip')),
  body text check (body is null or char_length(body) <= 500),
  media_path text,
  reply_to_checkin_id uuid references public.check_ins (id) on delete set null on update cascade,
  created_at timestamptz not null default now(),
  deleted_at timestamptz
);
create index messages_conversation_idx on public.messages (conversation_id, created_at);
create index messages_sender_idx on public.messages (sender_id, created_at);

create table public.message_hides (
  message_id uuid not null references public.messages (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (message_id, user_id)
);

alter table public.reports add column target_message_id uuid
  references public.messages (id) on delete set null;
alter table public.moderation_queue add column target_message_id uuid;

-- Server-only throttle log (username lookups, public friend requests).
create table private.rate_events (
  user_id uuid not null,
  kind text not null,
  at timestamptz not null default now()
);
create index rate_events_idx on private.rate_events (user_id, kind, at);
alter table private.rate_events enable row level security;
revoke all on private.rate_events from public, anon, authenticated;

create trigger friendships_updated before update on public.friendships for each row execute function public.set_updated_at();
create trigger journey_shares_updated before update on public.journey_shares for each row execute function public.set_updated_at();
create trigger journey_share_consents_updated before update on public.journey_share_consents for each row execute function public.set_updated_at();
create trigger conversations_updated before update on public.conversations for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Helpers (schema private; SECURITY DEFINER to avoid RLS recursion)
-- ---------------------------------------------------------------------------
create function private.person(u uuid) returns json
language sql stable security definer set search_path = ''
as $$
  select json_build_object('user_id', p.id, 'username', p.username,
                           'display_name', p.display_name, 'avatar_path', p.avatar_path)
    from public.profiles p where p.id = u;
$$;

create function private.blocked_between(a uuid, b uuid) returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.blocks x
     where x.deleted_at is null
       and ((x.blocker_id = a and x.blocked_id = b) or (x.blocker_id = b and x.blocked_id = a)));
$$;

create function private.are_friends(a uuid, b uuid) returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.friendships f
     where f.user_low = least(a, b) and f.user_high = greatest(a, b)
       and f.status = 'accepted' and f.deleted_at is null);
$$;

create function private.is_active_member(p_journey uuid, p_user uuid) returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.memberships m
     where m.journey_id = p_journey and m.user_id = p_user
       and m.status = 'active' and m.deleted_at is null);
$$;

-- One grant row still gives access: not revoked, the sharer is still an active member,
-- still friends with the viewer and neither blocked the other.
create function private.grant_valid(p_journey uuid, p_viewer uuid, p_by uuid) returns boolean
language sql stable security definer set search_path = ''
as $$
  select private.is_active_member(p_journey, p_by)
     and private.are_friends(p_by, p_viewer)
     and not private.blocked_between(p_by, p_viewer);
$$;

create function private.has_active_share(p_journey uuid, p_viewer uuid) returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.journey_shares s
      join public.journeys j on j.id = s.journey_id and j.deleted_at is null
     where s.journey_id = p_journey and s.viewer_id = p_viewer and s.revoked_at is null
       and private.grant_valid(s.journey_id, s.viewer_id, s.shared_by)
       and not private.blocked_between(p_viewer, j.owner_id));
$$;

-- Sharer of the earliest still-valid grant (S33).
create function private.earliest_sharer(p_journey uuid, p_viewer uuid) returns uuid
language sql stable security definer set search_path = ''
as $$
  select s.shared_by from public.journey_shares s
   where s.journey_id = p_journey and s.viewer_id = p_viewer and s.revoked_at is null
     and private.grant_valid(s.journey_id, s.viewer_id, s.shared_by)
   order by s.granted_at, s.shared_by
   limit 1;
$$;

create function private.consent_accepted(p_journey uuid, p_user uuid) returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.journey_share_consents s
     where s.journey_id = p_journey and s.user_id = p_user and s.status = 'accepted');
$$;

-- A check-in that may be shown outside the journey (S11, S30): live, not moderated, not hidden
-- in share, author still an active member and (group) has accepted consent.
create function private.checkin_shareable(p_checkin uuid) returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.check_ins c
      join public.journeys j on j.id = c.journey_id
     where c.id = p_checkin
       and c.deleted_at is null and c.moderated_at is null and not c.hidden_in_share
       and j.deleted_at is null
       and private.is_active_member(c.journey_id, c.user_id)
       and (j.kind = 'solo' or private.consent_accepted(c.journey_id, c.user_id)));
$$;

-- Caller sees the check-in as a NON-member: friend grantee, or signed-in stranger on a journey
-- with a public token (S14, S23).
create function private.viewer_can_see_checkin(p_checkin uuid) returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.check_ins c
      join public.journeys j on j.id = c.journey_id
     where c.id = p_checkin
       and private.checkin_shareable(c.id)
       and not private.is_blocked_pair(c.user_id)
       and not private.is_blocked_pair(j.owner_id)
       and not private.has_reported(c.id)
       and (private.has_active_share(j.id, (select auth.uid())) or j.public_token is not null));
$$;

-- Reactions by a non-member (contract: reactions RLS (a) / (b)).
create function private.can_react_as_viewer(p_checkin uuid) returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.check_ins c
      join public.journeys j on j.id = c.journey_id
     where c.id = p_checkin
       and not private.is_member(j.id)
       and private.viewer_can_see_checkin(c.id)
       and (private.has_active_share(j.id, (select auth.uid()))
            or (j.public_token is not null and j.allow_public_reactions)));
$$;

create function private.is_conversation_participant(p_conversation uuid) returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.conversations c
     where c.id = p_conversation and (select auth.uid()) in (c.member_id, c.viewer_id));
$$;

create function private.conversation_read_only(p_conversation uuid) returns boolean
language sql stable security definer set search_path = ''
as $$
  select coalesce((
    select not private.are_friends(c.member_id, c.viewer_id)
           or private.blocked_between(c.member_id, c.viewer_id)
      from public.conversations c where c.id = p_conversation), true);
$$;

create function private.can_read_message(p_message uuid) returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.messages m
      join public.conversations c on c.id = m.conversation_id
     where m.id = p_message and m.deleted_at is null
       and (select auth.uid()) in (c.member_id, c.viewer_id)
       and m.created_at > coalesce(
             case when c.member_id = (select auth.uid()) then c.member_cleared_at else c.viewer_cleared_at end,
             '-infinity'::timestamptz)
       and not exists (select 1 from public.message_hides h
                        where h.message_id = m.id and h.user_id = (select auth.uid())));
$$;

-- Group streak shown to outsiders (S34): days on which any active member checked in.
create function private.group_streak(p_journey uuid) returns int
language sql stable security definer set search_path = ''
as $$
  select s.current_streak
    from public.journeys j
    cross join lateral public.streak_core(
      coalesce((select array_agg(distinct c.local_date)
                  from public.check_ins c
                 where c.journey_id = j.id and c.deleted_at is null
                   and private.is_active_member(j.id, c.user_id)), '{}'),
      j.start_date,
      case when j.duration_days is null then null else j.start_date + j.duration_days - 1 end,
      public.local_date(now(), j.timezone)) s
   where j.id = p_journey;
$$;

-- Records one view (S19). Members never count. Day = journey-local date.
create function private.record_view(p_journey uuid, p_key text) returns void
language plpgsql security definer set search_path = ''
as $$
declare
  v_tz text;
begin
  if p_key is null or p_key = '' then
    return;
  end if;
  if exists (select 1 from public.memberships m
              where m.journey_id = p_journey and m.user_id = public.try_uuid(p_key)
                and m.status = 'active' and m.deleted_at is null) then
    return;
  end if;
  select timezone into v_tz from public.journeys where id = p_journey;
  if v_tz is null then
    return;
  end if;
  insert into public.journey_views (journey_id, viewer_key, day)
  values (p_journey, left(p_key, 128), public.local_date(now(), v_tz))
  on conflict do nothing;
end;
$$;

-- Unfriend / block: every grant between the pair is revoked (both directions).
create function private.sever_pair(a uuid, b uuid) returns void
language sql security definer set search_path = ''
as $$
  update public.journey_shares set revoked_at = now()
   where revoked_at is null
     and ((shared_by = a and viewer_id = b) or (shared_by = b and viewer_id = a));
$$;

-- ---------------------------------------------------------------------------
-- Replaced v1.2 helpers
-- ---------------------------------------------------------------------------
-- Profiles: own; co-members; friends and both sides of a pending request; conversation partners;
-- owner / consenting members of a journey the caller can view as a grantee or saved it. Never
-- across a block.
create or replace function private.can_see_profile(other uuid) returns boolean
language sql stable security definer set search_path = ''
as $$
  select other = (select auth.uid())
      or (not private.is_blocked_pair(other)
          and (
            exists (
              select 1 from public.memberships a
                join public.memberships b on b.journey_id = a.journey_id
               where a.user_id = (select auth.uid()) and b.user_id = other
                 and a.status = 'active' and a.deleted_at is null
                 and b.status = 'active' and b.deleted_at is null)
            or exists (
              select 1 from public.friendships f
               where f.user_low = least(other, (select auth.uid()))
                 and f.user_high = greatest(other, (select auth.uid()))
                 and f.deleted_at is null)
            or exists (
              select 1 from public.conversations c
               where (c.member_id = other and c.viewer_id = (select auth.uid()))
                  or (c.viewer_id = other and c.member_id = (select auth.uid())))
            or exists (
              select 1 from public.journeys j
               where j.deleted_at is null
                 and ((j.owner_id = other and (j.kind = 'solo' or private.consent_accepted(j.id, other)))
                      or (private.is_active_member(j.id, other) and private.consent_accepted(j.id, other)))
                 and (private.has_active_share(j.id, (select auth.uid()))
                      or (j.public_token is not null
                          and exists (select 1 from public.saved_journeys s
                                       where s.journey_id = j.id and s.user_id = (select auth.uid())))))
          ));
$$;

-- Storage: members as before (M3), plus viewers (friend grantee / stranger on a public journey)
-- for check-ins that are shareable.
create or replace function private.can_read_checkin_object(p_name text) returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.check_ins c
     where c.id = public.try_uuid(substring(p_name from '/([0-9a-f-]{36})(?:_t)?\.jpg$'))
       and (c.photo_path = p_name or c.thumb_path = p_name)
       and (private.can_view_checkin(c.id)
            or (private.viewer_can_see_checkin(c.id)
                -- blur_media: viewers never get the original object (FR-B7).
                and not exists (select 1 from public.memberships m
                                 where m.journey_id = c.journey_id and m.user_id = c.user_id
                                   and m.blur_media)))
  );
$$;

-- ---------------------------------------------------------------------------
-- Triggers
-- ---------------------------------------------------------------------------
-- Check-in write rules: retold journeys (origin = 'imported') written by their owner skip the
-- 3-day offline window and the "journey must be active" rule; local_date must stay inside
-- start_date .. start_date + duration_days - 1.
create or replace function public.check_ins_before_write() returns trigger
language plpgsql
set search_path = ''
as $$
declare
  j public.journeys%rowtype;
  v_imported boolean;
begin
  select * into j from public.journeys where id = new.journey_id;
  if not found then
    raise exception 'not_found' using errcode = 'P0001';
  end if;

  if tg_op = 'UPDATE' and (new.journey_id <> old.journey_id or new.user_id <> old.user_id) then
    raise exception 'immutable_column' using errcode = '23514';
  end if;

  new.local_date := public.local_date(new.captured_at, j.timezone);
  new.metric_value := null;
  v_imported := j.origin = 'imported' and new.user_id = j.owner_id;

  if current_user in ('authenticated', 'anon') then
    if tg_op = 'UPDATE' and old.moderated_at is not null then
      raise exception 'forbidden' using errcode = '42501';
    end if;
    if new.captured_at > now() + interval '10 minutes' then
      raise exception 'invalid_captured_at' using errcode = '22008';
    end if;
    if v_imported then
      if j.deleted_at is not null then
        raise exception 'ended' using errcode = 'P0001';
      end if;
      if new.local_date < j.start_date
         or new.local_date > j.start_date + coalesce(j.duration_days, 1) - 1 then
        raise exception 'invalid_captured_at' using errcode = '22008';
      end if;
    else
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
    end if;
    if tg_op = 'INSERT' then
      new.hidden_by_leave := false;
      new.moderated_at := null;
      new.hidden_in_share := false;
    else
      new.hidden_by_leave := old.hidden_by_leave;
      new.moderated_at := old.moderated_at;
      new.hidden_in_share := old.hidden_in_share;
    end if;
  end if;
  return new;
end;
$$;

create or replace function private.check_in_metrics_before_write() returns trigger
language plpgsql set search_path = ''
as $$
declare
  c record;
begin
  select ci.journey_id, ci.user_id, ci.deleted_at, j.status, j.deleted_at as journey_deleted,
         (j.origin = 'imported' and j.owner_id = ci.user_id) as imported
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
    if c.journey_deleted is not null or (c.status <> 'active' and not c.imported) then
      raise exception 'ended' using errcode = 'P0001';
    end if;
  end if;
  return new;
end;
$$;

-- S26: a stranger's like saves the journey; removing their last like on it unsaves it.
create function private.reactions_saved_sync() returns trigger
language plpgsql security definer set search_path = ''
as $$
declare
  j public.journeys%rowtype;
begin
  select jj.* into j from public.check_ins c join public.journeys jj on jj.id = c.journey_id
   where c.id = new.checkin_id;
  if not found or private.is_active_member(j.id, new.user_id) then
    return null;
  end if;
  if new.deleted_at is null then
    if j.public_token is not null and not private.has_active_share(j.id, new.user_id) then
      insert into public.saved_journeys (user_id, journey_id) values (new.user_id, j.id)
      on conflict do nothing;
    end if;
  elsif not exists (select 1 from public.reactions r join public.check_ins c on c.id = r.checkin_id
                     where c.journey_id = j.id and r.user_id = new.user_id and r.deleted_at is null) then
    delete from public.saved_journeys where user_id = new.user_id and journey_id = j.id;
  end if;
  return null;
end;
$$;
create trigger reactions_saved_sync after insert or update of deleted_at on public.reactions
  for each row execute function private.reactions_saved_sync();

-- A member joining (or rejoining) a journey that already has consent rows gets a pending one (S31).
create function private.memberships_consent_pending() returns trigger
language plpgsql security definer set search_path = ''
as $$
declare
  v_by uuid;
begin
  if new.status <> 'active' or new.deleted_at is not null then
    return null;
  end if;
  select requested_by into v_by from public.journey_share_consents
   where journey_id = new.journey_id order by created_at limit 1;
  if not found then
    return null;
  end if;
  insert into public.journey_share_consents (journey_id, user_id, status, requested_by)
  values (new.journey_id, new.user_id, 'pending', v_by)
  on conflict do nothing;
  return null;
end;
$$;
create trigger memberships_consent_pending after insert or update of status on public.memberships
  for each row execute function private.memberships_consent_pending();

-- Block = unfriend + revoke shares both ways (docs/09 §4).
create function private.blocks_sever() returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  if new.deleted_at is null then
    perform private.sever_pair(new.blocker_id, new.blocked_id);
    update public.friendships set deleted_at = now()
     where user_low = least(new.blocker_id, new.blocked_id)
       and user_high = greatest(new.blocker_id, new.blocked_id)
       and deleted_at is null;
  end if;
  return null;
end;
$$;
create trigger blocks_sever after insert or update of deleted_at on public.blocks
  for each row execute function private.blocks_sever();

-- ---------------------------------------------------------------------------
-- Privileges + RLS on the new tables
-- ---------------------------------------------------------------------------
revoke all on public.friendships, public.friend_invites, public.journey_shares,
  public.journey_share_consents, public.saved_journeys, public.journey_views,
  public.conversations, public.messages, public.message_hides from anon, authenticated;
grant select on public.friendships, public.journey_shares, public.journey_share_consents,
  public.saved_journeys, public.conversations, public.messages, public.message_hides to authenticated;

alter table public.friendships enable row level security;
alter table public.friend_invites enable row level security;
alter table public.journey_shares enable row level security;
alter table public.journey_share_consents enable row level security;
alter table public.saved_journeys enable row level security;
alter table public.journey_views enable row level security;
alter table public.conversations enable row level security;
alter table public.messages enable row level security;
alter table public.message_hides enable row level security;

create policy friendships_select on public.friendships for select to authenticated
  using ((select auth.uid()) in (user_low, user_high));
create policy friend_invites_deny on public.friend_invites for all to authenticated
  using (false) with check (false);
create policy journey_shares_select on public.journey_shares for select to authenticated
  using (viewer_id = (select auth.uid()) or shared_by = (select auth.uid()) or private.is_owner(journey_id));
create policy journey_share_consents_select on public.journey_share_consents for select to authenticated
  using (private.is_member(journey_id));
create policy saved_journeys_select on public.saved_journeys for select to authenticated
  using (user_id = (select auth.uid()));
create policy journey_views_deny on public.journey_views for all to authenticated
  using (false) with check (false);
create policy conversations_select on public.conversations for select to authenticated
  using ((select auth.uid()) in (member_id, viewer_id));
create policy messages_select on public.messages for select to authenticated
  using (deleted_at is null and private.can_read_message(id));
create policy message_hides_select on public.message_hides for select to authenticated
  using (user_id = (select auth.uid()));

-- reactions: members as before, plus viewers (friend grantee / stranger with allow_public_reactions)
-- on shareable check-ins. A viewer only ever reads their own reactions.
drop policy reactions_select on public.reactions;
create policy reactions_select on public.reactions for select to authenticated
  using (user_id = (select auth.uid())
         or (private.can_view_checkin(checkin_id) and not private.is_blocked_pair(user_id)));
drop policy reactions_insert on public.reactions;
create policy reactions_insert on public.reactions for insert to authenticated
  with check (user_id = (select auth.uid())
              and (private.can_view_checkin(checkin_id) or private.can_react_as_viewer(checkin_id)));
drop policy reactions_update on public.reactions;
create policy reactions_update on public.reactions for update to authenticated
  using (user_id = (select auth.uid())
         and (private.can_view_checkin(checkin_id) or private.can_react_as_viewer(checkin_id)))
  with check (user_id = (select auth.uid())
              and (private.can_view_checkin(checkin_id) or private.can_react_as_viewer(checkin_id)));

-- Realtime for chat (RLS-filtered). The publication is absent when realtime is not set up.
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    alter publication supabase_realtime add table public.messages;
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- Storage: bucket `messages` (private)
--   messages/{conversation_id}/{sender_id}/{message_id}.jpg
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('messages', 'messages', false, 10485760, array['image/jpeg'])
on conflict (id) do update
  set public = false,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

create policy messages_select on storage.objects for select to authenticated
using (
  bucket_id = 'messages'
  and (storage.foldername(name))[1] = 'messages'
  and array_length(storage.foldername(name), 1) = 3
  and private.is_conversation_participant(public.try_uuid((storage.foldername(name))[2]))
);
create policy messages_insert on storage.objects for insert to authenticated
with check (
  bucket_id = 'messages'
  and (storage.foldername(name))[1] = 'messages'
  and array_length(storage.foldername(name), 1) = 3
  and (storage.foldername(name))[3] = (select auth.uid())::text
  and private.is_conversation_participant(public.try_uuid((storage.foldername(name))[2]))
  and not private.conversation_read_only(public.try_uuid((storage.foldername(name))[2]))
  and storage.filename(name) ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.jpg$'
);
create policy messages_delete on storage.objects for delete to authenticated
using (
  bucket_id = 'messages'
  and (storage.foldername(name))[1] = 'messages'
  and (storage.foldername(name))[3] = (select auth.uid())::text
);

-- ---------------------------------------------------------------------------
-- RPCs: friends
-- ---------------------------------------------------------------------------
create function public.my_friends() returns setof json
language plpgsql stable security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
begin
  return query
  select json_build_object(
           'person', private.person(o.other),
           'status', f.status,
           'direction', case when f.requested_by = uid then 'outgoing' else 'incoming' end,
           'source', f.source,
           'source_journey_id', f.source_journey_id,
           'source_journey_title', sj.title,
           'created_at', f.created_at,
           'accepted_at', f.accepted_at)
    from public.friendships f
    cross join lateral (select case when f.user_low = uid then f.user_high else f.user_low end as other) o
    join public.profiles p on p.id = o.other and p.deleted_at is null
    left join public.journeys sj on sj.id = f.source_journey_id
   where uid in (f.user_low, f.user_high) and f.deleted_at is null
     and not private.blocked_between(uid, o.other)
   order by coalesce(f.accepted_at, f.created_at) desc, o.other;
end;
$$;

create function public.find_user_by_username(p_username text) returns json
language plpgsql security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
  v_name text := lower(ltrim(btrim(coalesce(p_username, '')), '@'));
  v_out json;
begin
  perform 1 from public.profiles where id = uid and deleted_at is null for update;
  if not found then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  delete from private.rate_events where user_id = uid and at < now() - interval '1 day';
  if (select count(*) from private.rate_events
       where user_id = uid and kind = 'username_lookup' and at > now() - interval '1 hour') >= 30 then
    raise exception 'rate_limited';
  end if;
  insert into private.rate_events (user_id, kind) values (uid, 'username_lookup');
  select private.person(p.id) into v_out
    from public.profiles p
   where p.username = v_name and p.id <> uid and p.deleted_at is null
     and not private.blocked_between(uid, p.id);
  return v_out;
end;
$$;

create function public.send_friend_request(p_user uuid, p_source_journey uuid default null) returns void
language plpgsql security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
  f public.friendships%rowtype;
  j public.journeys%rowtype;
begin
  if p_user is null or p_user = uid then
    raise exception 'invalid';
  end if;
  perform 1 from public.profiles where id = uid and deleted_at is null for update;
  if not found then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if not exists (select 1 from public.profiles where id = p_user and deleted_at is null) then
    raise exception 'not_found';
  end if;
  if private.blocked_between(uid, p_user) then
    raise exception 'blocked';
  end if;

  select * into f from public.friendships
   where user_low = least(uid, p_user) and user_high = greatest(uid, p_user) for update;
  if found and f.deleted_at is null then
    if f.status = 'accepted' or f.requested_by = uid then
      return; -- idempotent
    end if;
    update public.friendships set status = 'accepted', accepted_at = now()
     where user_low = f.user_low and user_high = f.user_high;
    return;
  end if;

  if p_source_journey is not null then
    select * into j from public.journeys where id = p_source_journey and deleted_at is null;
    if not found then
      raise exception 'not_found';
    end if;
    if j.public_token is null or not j.allow_viewer_requests or j.owner_id <> p_user then
      raise exception 'forbidden' using errcode = '42501';
    end if;
    if (select count(*) from private.rate_events
         where user_id = uid and kind = 'public_friend_request' and at > now() - interval '1 day') >= 20 then
      raise exception 'rate_limited';
    end if;
    insert into private.rate_events (user_id, kind) values (uid, 'public_friend_request');
  end if;

  insert into public.friendships (user_low, user_high, requested_by, status, source, source_journey_id)
  values (least(uid, p_user), greatest(uid, p_user), uid, 'pending',
          case when p_source_journey is null then 'direct' else 'public_journey' end, p_source_journey)
  on conflict (user_low, user_high) do update
    set requested_by = excluded.requested_by, status = 'pending', source = excluded.source,
        source_journey_id = excluded.source_journey_id, accepted_at = null,
        created_at = now(), deleted_at = null;
end;
$$;

create function public.respond_friend_request(p_user uuid, p_accept boolean) returns void
language plpgsql security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
begin
  if coalesce(p_accept, false) then
    update public.friendships set status = 'accepted', accepted_at = now()
     where user_low = least(uid, p_user) and user_high = greatest(uid, p_user)
       and status = 'pending' and requested_by = p_user and deleted_at is null;
  else
    update public.friendships set deleted_at = now()
     where user_low = least(uid, p_user) and user_high = greatest(uid, p_user)
       and status = 'pending' and requested_by = p_user and deleted_at is null;
  end if;
  if not found then
    raise exception 'not_found';
  end if;
end;
$$;

create function public.remove_friend(p_user uuid) returns void
language plpgsql security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
begin
  if p_user is null or p_user = uid then
    raise exception 'invalid';
  end if;
  update public.friendships set deleted_at = now()
   where user_low = least(uid, p_user) and user_high = greatest(uid, p_user) and deleted_at is null;
  perform private.sever_pair(uid, p_user);
end;
$$;

create function public.create_friend_invite() returns text
language plpgsql security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
  v_token text;
begin
  perform 1 from public.profiles where id = uid and deleted_at is null for update;
  if not found then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  loop
    v_token := public.random_token(12, 'abcdefghijklmnopqrstuvwxyz0123456789');
    exit when not exists (select 1 from public.friend_invites where token = v_token);
  end loop;
  insert into public.friend_invites (user_id, token) values (uid, v_token)
  on conflict (user_id) do update set token = excluded.token, created_at = now();
  return v_token;
end;
$$;

create function public.accept_friend_invite(p_token text) returns json
language plpgsql security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
  v_inviter uuid;
begin
  select i.user_id into v_inviter
    from public.friend_invites i join public.profiles p on p.id = i.user_id and p.deleted_at is null
   where i.token = lower(btrim(coalesce(p_token, '')));
  if v_inviter is null then
    raise exception 'not_found';
  end if;
  if v_inviter = uid then
    raise exception 'invalid';
  end if;
  if private.blocked_between(uid, v_inviter) then
    raise exception 'blocked';
  end if;
  -- An old link must not undo a removal: a removed friend asks again instead.
  if exists (select 1 from public.friendships f
              where f.user_low = least(uid, v_inviter) and f.user_high = greatest(uid, v_inviter)
                and f.deleted_at is not null) then
    raise exception 'invalid';
  end if;
  insert into public.friendships (user_low, user_high, requested_by, status, source, accepted_at)
  values (least(uid, v_inviter), greatest(uid, v_inviter), v_inviter, 'accepted', 'direct', now())
  on conflict (user_low, user_high) do update
    set status = 'accepted',
        accepted_at = case when public.friendships.status = 'accepted' and public.friendships.deleted_at is null
                           then public.friendships.accepted_at else now() end,
        source = case when public.friendships.deleted_at is null then public.friendships.source else 'direct' end,
        deleted_at = null;
  return private.person(v_inviter);
end;
$$;

-- ---------------------------------------------------------------------------
-- RPCs: sharing
-- ---------------------------------------------------------------------------
create function public.journey_share_state(p_journey uuid) returns json
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
  if not private.is_member(p_journey) then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  return json_build_object(
    'journey_id', j.id,
    'viewers', coalesce((
      select json_agg(private.person(s.viewer_id) order by s.granted_at, s.viewer_id)
        from public.journey_shares s
       where s.journey_id = j.id and s.shared_by = uid and s.revoked_at is null
         and private.grant_valid(s.journey_id, s.viewer_id, s.shared_by)), '[]'::json),
    'story', json_build_object('title', j.story_title, 'intro', j.story_intro,
                               'lessons', j.story_lessons, 'cover_checkin_id', j.cover_checkin_id),
    'public', json_build_object('show_counts', j.show_counts,
                                'allow_public_reactions', j.allow_public_reactions,
                                'allow_viewer_requests', j.allow_viewer_requests),
    'hidden_checkin_ids', coalesce((
      select json_agg(c.id order by c.local_date, c.id)
        from public.check_ins c
       where c.journey_id = j.id and c.hidden_in_share and c.deleted_at is null
         and not private.is_blocked_pair(c.user_id)), '[]'::json),
    'public_token', j.public_token);
end;
$$;

create function public.share_journey(p_journey uuid, p_viewers uuid[]) returns void
language plpgsql security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
  j public.journeys%rowtype;
  v uuid;
begin
  select * into j from public.journeys where id = p_journey and deleted_at is null;
  if not found then
    raise exception 'not_found';
  end if;
  if not private.is_member(p_journey) then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  for v in select distinct x from unnest(coalesce(p_viewers, '{}'::uuid[])) x where x is not null loop
    if v = uid or not private.are_friends(uid, v) or private.blocked_between(uid, v) then
      raise exception 'forbidden' using errcode = '42501';
    end if;
  end loop;
  if j.kind = 'group' and not private.consent_accepted(p_journey, uid) then
    raise exception 'consent_required';
  end if;
  insert into public.journey_shares (journey_id, viewer_id, shared_by)
  select p_journey, x, uid
    from (select distinct x from unnest(coalesce(p_viewers, '{}'::uuid[])) x where x is not null) v
   where not private.is_active_member(p_journey, x)
  on conflict (journey_id, viewer_id, shared_by) do update
    set granted_at = case when public.journey_shares.revoked_at is null
                          then public.journey_shares.granted_at else now() end,
        seen_at = case when public.journey_shares.revoked_at is null
                       then public.journey_shares.seen_at else null end,
        revoked_at = null;
end;
$$;

create function public.unshare_journey(p_journey uuid, p_viewer uuid default null, p_all boolean default false)
returns void
language plpgsql security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
  j public.journeys%rowtype;
begin
  select * into j from public.journeys where id = p_journey for update;
  if not found then
    raise exception 'not_found';
  end if;
  if coalesce(p_all, false) then
    if not private.is_owner(p_journey) then
      raise exception 'forbidden' using errcode = '42501';
    end if;
    update public.journey_shares set revoked_at = now()
     where journey_id = p_journey and revoked_at is null;
    update public.journeys
       set public_token = null,
           visibility = case when kind = 'solo' then 'private'::public.journey_visibility else visibility end
     where id = p_journey;
    delete from public.saved_journeys where journey_id = p_journey;
  else
    update public.journey_shares set revoked_at = now()
     where journey_id = p_journey and shared_by = uid and revoked_at is null
       and (p_viewer is null or viewer_id = p_viewer);
  end if;
end;
$$;

create function public.update_journey_story(p_journey uuid, p_title text, p_intro text, p_lessons text, p_cover uuid)
returns void
language plpgsql security definer set search_path = ''
as $$
declare
  v_title text := nullif(btrim(p_title), '');
  v_intro text := nullif(btrim(p_intro), '');
  v_lessons text := nullif(btrim(p_lessons), '');
begin
  perform public._uid();
  perform 1 from public.journeys where id = p_journey and deleted_at is null for update;
  if not found then
    raise exception 'not_found';
  end if;
  if not private.is_owner(p_journey) then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if char_length(v_title) > 80 or char_length(v_intro) > 600 or char_length(v_lessons) > 600 then
    raise exception 'invalid';
  end if;
  if p_cover is not null and not exists (
       select 1 from public.check_ins where id = p_cover and journey_id = p_journey and deleted_at is null) then
    raise exception 'invalid';
  end if;
  update public.journeys
     set story_title = v_title, story_intro = v_intro, story_lessons = v_lessons, cover_checkin_id = p_cover
   where id = p_journey;
end;
$$;

create function public.update_public_settings(p_journey uuid, p_show_counts boolean, p_allow_reactions boolean,
                                              p_allow_requests boolean)
returns void
language plpgsql security definer set search_path = ''
as $$
begin
  perform public._uid();
  perform 1 from public.journeys where id = p_journey and deleted_at is null for update;
  if not found then
    raise exception 'not_found';
  end if;
  if not private.is_owner(p_journey) then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  update public.journeys
     set show_counts = coalesce(p_show_counts, show_counts),
         allow_public_reactions = coalesce(p_allow_reactions, allow_public_reactions),
         allow_viewer_requests = coalesce(p_allow_requests, allow_viewer_requests)
   where id = p_journey;
end;
$$;

create function public.set_hidden_in_share(p_checkin uuid, p_hidden boolean) returns void
language plpgsql security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
  v_author uuid;
begin
  select user_id into v_author from public.check_ins where id = p_checkin;
  if v_author is null then
    raise exception 'not_found';
  end if;
  if v_author <> uid then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  update public.check_ins set hidden_in_share = coalesce(p_hidden, false) where id = p_checkin;
end;
$$;

-- Replaces the v1.2 set_public_link(journey, enabled).
drop function public.set_public_link(uuid, boolean);
create function public.set_public_link(journey uuid, enabled boolean, reset boolean default false) returns text
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
  if coalesce(enabled, false) then
    -- S9: only finished journeys or retold ones.
    if j.status not in ('ended', 'archived') and j.origin <> 'imported' then
      raise exception 'invalid';
    end if;
    if j.public_token is not null and not coalesce(reset, false) then
      return j.public_token;
    end if;
    v_token := public.random_token(40, 'abcdefghijklmnopqrstuvwxyz0123456789');
    update public.journeys
       set public_token = v_token,
           visibility = case when kind = 'solo' then 'link'::public.journey_visibility else visibility end
     where id = journey;
  else
    update public.journeys
       set public_token = null,
           visibility = case when kind = 'solo' then 'private'::public.journey_visibility else visibility end
     where id = journey;
  end if;
  -- A dead or rotated link takes "Saved" with it.
  if j.public_token is not null then
    delete from public.saved_journeys where journey_id = journey;
  end if;
  return v_token;
end;
$$;

-- Owner of a journey as seen by a non-member: a group owner who has not consented to
-- sharing (S29/S30) stays anonymous (nil id, empty names), so viewers cannot reach them.
create function private.owner_for_viewer(p_journey uuid) returns json
language sql stable security definer set search_path = ''
as $$
  select case when j.kind = 'solo' or private.is_active_member(j.id, (select auth.uid()))
                   or private.consent_accepted(j.id, j.owner_id)
              then private.person(j.owner_id)
              else json_build_object('user_id', '00000000-0000-0000-0000-000000000000',
                                     'username', '', 'display_name', '', 'avatar_path', null)
         end
    from public.journeys j where j.id = p_journey;
$$;

create function public.shared_with_me() returns setof json
language plpgsql stable security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
begin
  return query
  with grants as (
    select s.journey_id,
           (array_agg(s.shared_by order by s.granted_at, s.shared_by))[1] as shared_by,
           min(s.granted_at) as shared_at,
           bool_or(s.seen_at is null) as unseen
      from public.journey_shares s
     where s.viewer_id = uid and s.revoked_at is null
       and private.grant_valid(s.journey_id, s.viewer_id, s.shared_by)
     group by s.journey_id
  ), items as (
    select g.journey_id, g.shared_by, g.shared_at, g.unseen, false as saved from grants g
    union all
    select sv.journey_id, j.owner_id, sv.created_at, false, true
      from public.saved_journeys sv
      join public.journeys j on j.id = sv.journey_id and j.public_token is not null
     where sv.user_id = uid and sv.journey_id not in (select journey_id from grants)
  )
  select json_build_object(
           'journey_id', j.id,
           'title', j.title,
           'emoji', j.emoji,
           'template_id', j.template_id,
           'kind', j.kind,
           'origin', j.origin,
           'status', j.status,
           'owner', private.owner_for_viewer(j.id),
           'shared_by', private.person(i.shared_by),
           'shared_at', i.shared_at,
           'photo_count', st.n,
           'saved', i.saved,
           'unseen', i.unseen,
           'first_date', st.first_date,
           'last_date', st.last_date,
           'cover_thumb_path', coalesce(st.cover_thumb, st.last_thumb))
    from items i
    join public.journeys j on j.id = i.journey_id
    cross join lateral (
      select count(*)::int as n, min(c.local_date) as first_date, max(c.local_date) as last_date,
             max(c.thumb_path) filter (where c.id = j.cover_checkin_id) as cover_thumb,
             (array_agg(c.thumb_path order by c.local_date desc, c.id))[1] as last_thumb
        from public.check_ins c
       where c.journey_id = j.id
         and private.checkin_shareable(c.id)
         and not private.is_blocked_pair(c.user_id)
         and not private.has_reported(c.id)) st
   where j.deleted_at is null
     and not private.is_blocked_pair(j.owner_id)
     and not private.is_member(j.id)
   order by i.shared_at desc, j.id;
end;
$$;

-- View JSON shared by shared_journey / public_journey_by_token (caller = auth.uid()).
create function private.journey_view(p_journey uuid, p_role text) returns json
language plpgsql stable security definer set search_path = ''
as $$
declare
  uid uuid := (select auth.uid());
  j public.journeys%rowtype;
  v_member boolean := p_role = 'member';
  v_counts boolean;
  v_photos json;
  v_total int;
  v_members json;
  v_streak int;
  v_sharer uuid;
begin
  select * into j from public.journeys where id = p_journey;
  v_counts := v_member or j.show_counts;

  select coalesce(json_agg(json_build_object(
           'checkin_id', ph.id,
           'author', private.person(ph.user_id),
           'local_date', ph.local_date,
           -- Blurred photos carry no object path: the client shows a placeholder.
           'photo_path', case when not v_member and ph.blur_media then '' else ph.photo_path end,
           'thumb_path', case when not v_member and ph.blur_media then '' else ph.thumb_path end,
           'caption', ph.caption,
           'metric_value', case when ph.user_id = uid or not ph.hide_metric then cm.metric_value end,
           'like_count', case when v_counts then rc.cnt else 0 end,
           'liked_by_me', rc.mine,
           'blurred', (not v_member and ph.blur_media))
           order by ph.local_date, ph.created_at, ph.id), '[]'::json),
         coalesce(sum(rc.cnt), 0)::int
    into v_photos, v_total
    from (
      select c.id, c.user_id, c.local_date, c.photo_path, c.thumb_path, c.caption, c.created_at,
             m.hide_metric, m.blur_media
        from public.check_ins c
        join public.memberships m on m.journey_id = c.journey_id and m.user_id = c.user_id
       where c.journey_id = p_journey and c.deleted_at is null
         and not private.is_blocked_pair(c.user_id)
         and not private.has_reported(c.id)
         and (v_member or private.checkin_shareable(c.id))
    ) ph
    left join public.check_in_metrics cm on cm.checkin_id = ph.id
    cross join lateral (
      select count(*)::int as cnt, coalesce(bool_or(r.user_id = uid), false) as mine
        from public.reactions r where r.checkin_id = ph.id and r.deleted_at is null) rc;

  if j.kind = 'solo' then
    v_members := json_build_array(private.person(j.owner_id));
  else
    select coalesce(json_agg(private.person(m.user_id) order by m.joined_at, m.user_id), '[]'::json)
      into v_members
      from public.memberships m
     where m.journey_id = p_journey and m.status = 'active' and m.deleted_at is null
       and not private.is_blocked_pair(m.user_id)
       and (v_member or private.consent_accepted(p_journey, m.user_id));
  end if;

  if j.origin = 'imported' or (p_role = 'stranger' and j.kind = 'group') then
    v_streak := null;
  elsif j.kind = 'solo' then
    select s.current_streak into v_streak from public.journey_streak(j.id, j.owner_id) s;
    v_streak := coalesce(v_streak, 0);
  else
    v_streak := coalesce(private.group_streak(j.id), 0);
  end if;

  if p_role = 'friend' then
    v_sharer := private.earliest_sharer(p_journey, uid);
  end if;

  return json_build_object(
    'journey_id', j.id,
    'role', p_role,
    'title', j.title,
    'emoji', j.emoji,
    'template_id', j.template_id,
    'kind', j.kind,
    'origin', j.origin,
    'status', j.status,
    'duration_days', j.duration_days,
    'start_date', j.start_date,
    'owner', private.owner_for_viewer(j.id),
    'members', v_members,
    'story', json_build_object(
      'title', j.story_title, 'intro', j.story_intro, 'lessons', j.story_lessons,
      'cover_checkin_id', case when v_member or private.checkin_shareable(j.cover_checkin_id)
                               then j.cover_checkin_id end),
    'photos', v_photos,
    'current_streak', v_streak,
    'like_count', case when v_counts then v_total end,
    'follow_count', case when v_counts then
      -- Distinct owners: one account cannot inflate the count with many journeys.
      (select count(distinct f.owner_id)::int from public.journeys f
        where f.followed_from = j.id and f.deleted_at is null) end,
    'metric_name', j.metric_name,
    'metric_unit', j.metric_unit,
    'shared_by', case when v_sharer is not null then private.person(v_sharer) end,
    'can_react', case p_role
                   when 'member' then j.status = 'active'
                   when 'friend' then true
                   else j.public_token is not null and j.allow_public_reactions end,
    'can_reply', p_role = 'friend',
    'can_follow', j.status in ('ended', 'archived') or j.origin = 'imported',
    'can_add_owner', p_role = 'stranger' and j.allow_viewer_requests and j.owner_id <> uid
                     and (j.kind = 'solo' or private.consent_accepted(j.id, j.owner_id))
                     and not exists (select 1 from public.friendships f
                                      where f.user_low = least(uid, j.owner_id)
                                        and f.user_high = greatest(uid, j.owner_id)
                                        and f.deleted_at is null)
                     and not private.is_blocked_pair(j.owner_id),
    'saved', exists (select 1 from public.saved_journeys s where s.user_id = uid and s.journey_id = j.id));
end;
$$;

-- Roles for a journey: member / friend (valid grant) / stranger (public token + saved it). Null = none.
create function private.viewer_role(p_journey uuid, p_has_token boolean) returns text
language sql stable security definer set search_path = ''
as $$
  select case
    when private.is_member(j.id) then 'member'
    when private.is_blocked_pair(j.owner_id) then null
    when private.has_active_share(j.id, (select auth.uid())) then 'friend'
    when j.public_token is not null
         and (p_has_token or exists (select 1 from public.saved_journeys s
                                      where s.journey_id = j.id and s.user_id = (select auth.uid())))
      then 'stranger'
  end
  from public.journeys j where j.id = p_journey and j.deleted_at is null;
$$;

create function public.shared_journey(p_journey uuid) returns json
language plpgsql security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
  v_role text;
begin
  if not exists (select 1 from public.journeys where id = p_journey and deleted_at is null) then
    raise exception 'not_found';
  end if;
  v_role := private.viewer_role(p_journey, false);
  if v_role is null then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if v_role <> 'member' then
    perform private.record_view(p_journey, uid::text);
    update public.journey_shares set seen_at = now()
     where journey_id = p_journey and viewer_id = uid and seen_at is null and revoked_at is null;
  end if;
  return private.journey_view(p_journey, v_role);
end;
$$;

create function public.public_journey_by_token(p_token text) returns json
language plpgsql security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
  v_journey uuid;
  v_role text;
begin
  if p_token is null or p_token !~ '^[a-z0-9]{32,64}$' then
    raise exception 'not_found';
  end if;
  select id into v_journey from public.journeys where public_token = p_token and deleted_at is null;
  if v_journey is null then
    raise exception 'not_found';
  end if;
  v_role := private.viewer_role(v_journey, true);
  if v_role is null then
    raise exception 'not_found'; -- blocked owner: behave as an unknown link
  end if;
  if v_role <> 'member' then
    perform private.record_view(v_journey, uid::text);
  end if;
  return private.journey_view(v_journey, v_role);
end;
$$;

create function public.follow_frame(p_journey uuid) returns json
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
    'metric_unit', j.metric_unit);
end;
$$;

create function public.mark_followed(p_journey uuid, p_source uuid) returns void
language plpgsql security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
  j public.journeys%rowtype;
  s public.journeys%rowtype;
begin
  select * into j from public.journeys where id = p_journey and deleted_at is null for update;
  if not found then
    raise exception 'not_found';
  end if;
  if j.owner_id <> uid or not private.is_owner(p_journey) then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if j.created_at < now() - interval '1 day' or p_source is null or p_source = p_journey then
    raise exception 'invalid';
  end if;
  select * into s from public.journeys where id = p_source and deleted_at is null;
  if not found then
    raise exception 'not_found';
  end if;
  if not (private.is_member(s.id)
          or (not private.is_blocked_pair(s.owner_id)
              and (private.has_active_share(s.id, uid) or s.public_token is not null))) then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  update public.journeys set followed_from = p_source where id = p_journey;
end;
$$;

create function public.create_imported_journey(
  p_id uuid,
  p_title text,
  p_emoji text,
  p_template public.template_id,
  p_first date,
  p_last date,
  p_timezone text,
  p_metric_name text default null,
  p_metric_unit text default null
) returns public.journeys
language plpgsql security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
  j public.journeys%rowtype;
  v_days int;
begin
  if p_id is null or p_first is null or p_last is null or p_timezone is null then
    raise exception 'invalid';
  end if;
  perform now() at time zone p_timezone; -- 22023 for an unknown timezone
  v_days := p_last - p_first + 1;
  if v_days < 1 or v_days > 366 or p_last > public.local_date(now(), p_timezone) then
    raise exception 'invalid';
  end if;

  perform 1 from public.profiles where id = uid and deleted_at is null for update;
  if not found then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  select * into j from public.journeys where id = p_id;
  if found then
    if j.owner_id = uid then
      return j; -- idempotent
    end if;
    raise exception 'forbidden' using errcode = '42501';
  end if;

  insert into public.journeys (
    id, owner_id, kind, template_id, title, emoji, metric_name, metric_unit,
    hide_metric_default, start_date, duration_days, timezone, visibility, status,
    max_members, origin)
  values (
    p_id, uid, 'solo', coalesce(p_template, 'custom'), btrim(p_title), p_emoji,
    p_metric_name, p_metric_unit, coalesce(p_template, 'custom') = 'weight_loss', p_first,
    v_days, p_timezone, 'private', 'ended', 1, 'imported')
  returning * into j;
  insert into public.memberships (journey_id, user_id, role, hide_metric)
  values (j.id, uid, 'owner', j.hide_metric_default);
  return j;
end;
$$;

create function public.unsave_journey(p_journey uuid) returns void
language plpgsql security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
begin
  delete from public.saved_journeys where user_id = uid and journey_id = p_journey;
  if not private.is_member(p_journey) then
    update public.reactions r set deleted_at = now()
      from public.check_ins c
     where c.id = r.checkin_id and c.journey_id = p_journey
       and r.user_id = uid and r.deleted_at is null;
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- RPCs: group consents (S29-S31)
-- ---------------------------------------------------------------------------
create function private.consent_json(c public.journey_share_consents) returns json
language sql stable security definer set search_path = ''
as $$
  select json_build_object(
    'journey_id', c.journey_id,
    'journey_title', (select title from public.journeys where id = c.journey_id),
    'member', private.person(c.user_id),
    'status', c.status,
    'requested_by', private.person(c.requested_by),
    'decided_at', c.decided_at);
$$;

create function public.share_consents(p_journey uuid) returns setof json
language plpgsql stable security definer set search_path = ''
as $$
begin
  perform public._uid();
  if not private.is_member(p_journey) then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  return query
  select private.consent_json(c)
    from public.journey_share_consents c
    join public.memberships m on m.journey_id = c.journey_id and m.user_id = c.user_id
   where c.journey_id = p_journey and m.status = 'active' and m.deleted_at is null
   order by m.joined_at, c.user_id;
end;
$$;

create function public.my_pending_consents() returns setof json
language plpgsql stable security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
begin
  return query
  select private.consent_json(c)
    from public.journey_share_consents c
    join public.journeys j on j.id = c.journey_id and j.deleted_at is null
   where c.user_id = uid and c.status = 'pending' and private.is_active_member(c.journey_id, uid)
   order by c.created_at desc, c.journey_id;
end;
$$;

create function public.request_share_consent(p_journey uuid) returns void
language plpgsql security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
  j public.journeys%rowtype;
begin
  select * into j from public.journeys where id = p_journey and deleted_at is null for update;
  if not found then
    raise exception 'not_found';
  end if;
  if not private.is_member(p_journey) then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if j.kind <> 'group' then
    raise exception 'invalid';
  end if;
  insert into public.journey_share_consents (journey_id, user_id, status, requested_by, decided_at)
  values (p_journey, uid, 'accepted', uid, now())
  on conflict (journey_id, user_id) do update
    set status = 'accepted', decided_at = now();
  insert into public.journey_share_consents (journey_id, user_id, status, requested_by)
  select m.journey_id, m.user_id, 'pending', uid
    from public.memberships m
   where m.journey_id = p_journey and m.user_id <> uid and m.status = 'active' and m.deleted_at is null
  on conflict (journey_id, user_id) do nothing;
end;
$$;

create function public.respond_share_consent(p_journey uuid, p_accept boolean) returns void
language plpgsql security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
begin
  if not private.is_member(p_journey) then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  update public.journey_share_consents
     set status = case when coalesce(p_accept, false) then 'accepted' else 'declined' end,
         decided_at = now()
   where journey_id = p_journey and user_id = uid;
  if not found then
    raise exception 'not_found';
  end if;
end;
$$;

create function public.withdraw_share_consent(p_journey uuid) returns void
language plpgsql security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
begin
  update public.journey_share_consents set status = 'withdrawn', decided_at = now()
   where journey_id = p_journey and user_id = uid;
  if not found then
    raise exception 'not_found';
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- RPCs: chat (S13, S16-S17, S24, S33, S37)
-- ---------------------------------------------------------------------------
create function private.message_json(m public.messages) returns json
language sql stable security definer set search_path = ''
as $$
  select json_build_object(
    'id', m.id,
    'conversation_id', m.conversation_id,
    'sender_id', m.sender_id,
    'kind', m.kind,
    'body', m.body,
    'media_path', m.media_path,
    'reply_to_checkin_id', m.reply_to_checkin_id,
    'reply_to_thumb_path', (select c.thumb_path from public.check_ins c
                             where c.id = m.reply_to_checkin_id and c.deleted_at is null),
    'created_at', m.created_at);
$$;

create function public.open_conversation(p_journey uuid, p_checkin uuid default null) returns uuid
language plpgsql security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
  j public.journeys%rowtype;
  v_author uuid;
  v_to uuid;
  v_id uuid;
begin
  select * into j from public.journeys where id = p_journey and deleted_at is null;
  if not found then
    raise exception 'not_found';
  end if;
  -- Friend grantees only (strangers and members cannot open a reply thread).
  if private.is_member(p_journey) or not private.has_active_share(p_journey, uid) then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if p_checkin is not null then
    select user_id into v_author from public.check_ins
     where id = p_checkin and journey_id = p_journey and deleted_at is null;
    if v_author is null then
      raise exception 'invalid';
    end if;
  end if;
  if j.kind = 'solo' then
    v_to := j.owner_id;
  elsif v_author is not null and v_author <> uid
        and private.are_friends(uid, v_author)
        and private.is_active_member(p_journey, v_author)
        and private.consent_accepted(p_journey, v_author) then
    v_to := v_author;
  else
    v_to := private.earliest_sharer(p_journey, uid);
  end if;
  if v_to is null or private.blocked_between(uid, v_to) then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  insert into public.conversations (journey_id, member_id, viewer_id)
  values (p_journey, v_to, uid)
  on conflict (journey_id, member_id, viewer_id) do nothing;
  select id into v_id from public.conversations
   where journey_id = p_journey and member_id = v_to and viewer_id = uid;
  return v_id;
end;
$$;

create function public.my_conversations() returns setof json
language plpgsql stable security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
begin
  return query
  select json_build_object(
           'id', c.id,
           'journey_id', c.journey_id,
           'journey_title', j.title,
           'other', private.person(x.other),
           'unread_count', (
             select count(*)::int from public.messages m
              where m.conversation_id = c.id and m.sender_id <> uid and m.deleted_at is null
                and m.created_at > coalesce(x.read_at, '-infinity'::timestamptz)
                and m.created_at > coalesce(x.cleared_at, '-infinity'::timestamptz)
                and not exists (select 1 from public.message_hides h
                                 where h.message_id = m.id and h.user_id = uid)),
           'read_only', private.conversation_read_only(c.id),
           'last_message_at', lm.created_at,
           'last_message_preview', left(lm.body, 120),
           'last_message_kind', lm.kind)
    from public.conversations c
    join public.journeys j on j.id = c.journey_id
    cross join lateral (
      select case when c.member_id = uid then c.viewer_id else c.member_id end as other,
             case when c.member_id = uid then c.member_read_at else c.viewer_read_at end as read_at,
             case when c.member_id = uid then c.member_cleared_at else c.viewer_cleared_at end as cleared_at) x
    left join lateral (
      select m.created_at, m.body, m.kind from public.messages m
       where m.conversation_id = c.id and m.deleted_at is null
         and m.created_at > coalesce(x.cleared_at, '-infinity'::timestamptz)
         and not exists (select 1 from public.message_hides h where h.message_id = m.id and h.user_id = uid)
       order by m.created_at desc, m.id desc limit 1) lm on true
   where uid in (c.member_id, c.viewer_id)
     and (x.cleared_at is null or c.last_message_at > x.cleared_at)
   order by coalesce(c.last_message_at, c.created_at) desc, c.id;
end;
$$;

create function public.conversation_messages(p_conversation uuid, p_before timestamptz default null,
                                             p_limit int default 100)
returns setof json
language plpgsql stable security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
begin
  if not exists (select 1 from public.conversations where id = p_conversation) then
    raise exception 'not_found';
  end if;
  if not private.is_conversation_participant(p_conversation) then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  return query
  select private.message_json(t)
    from (
      select m.* from public.messages m
       where m.conversation_id = p_conversation
         and (p_before is null or m.created_at < p_before)
         and private.can_read_message(m.id)
       order by m.created_at desc, m.id desc
       limit least(greatest(coalesce(p_limit, 100), 1), 500)
    ) t
   order by t.created_at, t.id;
end;
$$;

create function public.send_message(p_id uuid, p_conversation uuid, p_kind text, p_body text, p_media_path text,
                                    p_reply_to uuid default null)
returns json
language plpgsql security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
  c public.conversations%rowtype;
  m public.messages%rowtype;
  v_body text := nullif(btrim(p_body), '');
  v_media text;
begin
  if p_id is null then
    raise exception 'invalid';
  end if;
  select * into c from public.conversations where id = p_conversation for update;
  if not found then
    raise exception 'not_found';
  end if;
  if uid not in (c.member_id, c.viewer_id) then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  select * into m from public.messages where id = p_id;
  if found then
    if m.sender_id = uid and m.conversation_id = p_conversation then
      return private.message_json(m); -- idempotent retry
    end if;
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if private.conversation_read_only(p_conversation) then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if p_kind = 'text' then
    if v_body is null or char_length(v_body) > 500 then
      raise exception 'invalid';
    end if;
  elsif p_kind = 'photo' then
    v_media := p_media_path;
    if v_media is null
       or v_media !~ ('^messages/' || p_conversation::text || '/' || uid::text
                      || '/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.jpg$')
       or char_length(v_body) > 500 then
      raise exception 'invalid';
    end if;
  else
    raise exception 'invalid'; -- 'clip' ships with v0.2
  end if;
  if p_reply_to is not null and not exists (
       select 1 from public.check_ins where id = p_reply_to and journey_id = c.journey_id) then
    raise exception 'invalid';
  end if;
  if (select count(*) from public.messages
       where sender_id = uid and created_at > now() - interval '1 minute') >= 60 then
    raise exception 'rate_limited';
  end if;

  insert into public.messages (id, conversation_id, sender_id, kind, body, media_path, reply_to_checkin_id)
  values (p_id, p_conversation, uid, p_kind, v_body, v_media, p_reply_to)
  returning * into m;
  update public.conversations
     set last_message_at = m.created_at,
         member_read_at = case when member_id = uid then m.created_at else member_read_at end,
         viewer_read_at = case when viewer_id = uid then m.created_at else viewer_read_at end
   where id = p_conversation;
  return private.message_json(m);
end;
$$;

create function public.mark_conversation_read(p_conversation uuid) returns void
language plpgsql security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
begin
  update public.conversations
     set member_read_at = case when member_id = uid then now() else member_read_at end,
         viewer_read_at = case when viewer_id = uid then now() else viewer_read_at end
   where id = p_conversation and uid in (member_id, viewer_id);
  if not found then
    raise exception 'not_found';
  end if;
end;
$$;

create function public.clear_conversation(p_conversation uuid) returns void
language plpgsql security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
  c public.conversations%rowtype;
begin
  update public.conversations
     set member_cleared_at = case when member_id = uid then now() else member_cleared_at end,
         viewer_cleared_at = case when viewer_id = uid then now() else viewer_cleared_at end
   where id = p_conversation and uid in (member_id, viewer_id)
  returning * into c;
  if not found then
    raise exception 'not_found';
  end if;
  -- S37: a message both sides cleared is gone for good. (Photo objects of such messages are
  -- left to a storage cleanup job; they are no longer referenced.)
  if c.member_cleared_at is not null and c.viewer_cleared_at is not null then
    delete from public.messages
     where conversation_id = p_conversation
       and created_at <= least(c.member_cleared_at, c.viewer_cleared_at);
  end if;
end;
$$;

create function public.hide_message(p_message uuid) returns void
language plpgsql security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
begin
  if not exists (select 1 from public.messages m
                   join public.conversations c on c.id = m.conversation_id
                  where m.id = p_message and uid in (c.member_id, c.viewer_id)) then
    raise exception 'not_found';
  end if;
  insert into public.message_hides (message_id, user_id) values (p_message, uid)
  on conflict do nothing;
end;
$$;

-- ---------------------------------------------------------------------------
-- RPCs: inbox & insights (S16, S19-S21, S32)
-- ---------------------------------------------------------------------------
create function public.inbox_counts() returns json
language plpgsql stable security definer set search_path = ''
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
         and m.sender_id <> uid and m.deleted_at is null
         and m.created_at > coalesce(case when c.member_id = uid then c.member_read_at else c.viewer_read_at end,
                                     '-infinity'::timestamptz)
         and m.created_at > coalesce(case when c.member_id = uid then c.member_cleared_at else c.viewer_cleared_at end,
                                     '-infinity'::timestamptz)
         and not exists (select 1 from public.message_hides h where h.message_id = m.id and h.user_id = uid)),
    'consent_requests', (
      select count(*)::int from public.journey_share_consents c
        join public.journeys j on j.id = c.journey_id and j.deleted_at is null
       where c.user_id = uid and c.status = 'pending' and private.is_active_member(c.journey_id, uid)));
end;
$$;

create function public.journey_insights(p_journey uuid) returns json
language plpgsql stable security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
  j public.journeys%rowtype;
  v_week date;
begin
  select * into j from public.journeys where id = p_journey and deleted_at is null;
  if not found then
    raise exception 'not_found';
  end if;
  if not private.is_member(p_journey) then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  v_week := public.local_date(now(), j.timezone) - 6;
  return (
    with likes as (
      select r.user_id, r.created_at,
             exists (select 1 from public.journey_shares s
                      where s.journey_id = p_journey and s.viewer_id = r.user_id) as from_friend
        from public.reactions r join public.check_ins c on c.id = r.checkin_id
       where c.journey_id = p_journey and r.deleted_at is null and c.deleted_at is null
         and not private.is_active_member(p_journey, r.user_id)
    ), firsts as (
      select viewer_key, min(day) as first_day from public.journey_views
       where journey_id = p_journey group by viewer_key
    )
    select json_build_object(
      'journey_id', j.id,
      'views', (select count(*)::int from firsts),
      'views_by_day', coalesce((
        select json_agg(json_build_object('day', d.day, 'count', d.n) order by d.day)
          from (select v.day, count(distinct v.viewer_key)::int as n from public.journey_views v
                 where v.journey_id = p_journey group by v.day) d), '[]'::json),
      'likes_from_friends', (select count(*)::int from likes where from_friend),
      'likes_from_strangers', (select count(*)::int from likes where not from_friend),
      'started', (select count(distinct f.owner_id)::int from public.journeys f
                   where f.followed_from = p_journey and f.deleted_at is null),
      'views_this_week', (select count(*)::int from firsts where first_day >= v_week),
      'likes_this_week', (select count(*)::int from likes
                           where public.local_date(created_at, j.timezone) >= v_week),
      'started_this_week', (select count(*)::int from public.journeys f
                             where f.followed_from = p_journey and f.deleted_at is null
                               and public.local_date(f.created_at, j.timezone) >= v_week),
      'likers', coalesce((
        select json_agg(private.person(l.user_id) order by l.last_at desc, l.user_id)
          from (select r.user_id, max(r.created_at) as last_at
                  from public.reactions r join public.check_ins c on c.id = r.checkin_id
                 where c.journey_id = p_journey and c.user_id = uid and c.deleted_at is null
                   and r.deleted_at is null and r.user_id <> uid
                   and not private.is_blocked_pair(r.user_id)
                 group by r.user_id) l), '[]'::json)));
end;
$$;

create function public.my_reach() returns int
language plpgsql stable security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
begin
  return (
    select count(distinct v.viewer_key)::int
      from public.journey_views v
      join public.journeys j on j.id = v.journey_id and j.deleted_at is null
     where private.is_active_member(v.journey_id, uid));
end;
$$;

-- Edge Function public-journey (service_role): records an anonymous web view.
create function public.record_journey_view(p_journey uuid, p_viewer_key text) returns void
language plpgsql security definer set search_path = ''
as $$
begin
  perform private.record_view(p_journey, p_viewer_key);
end;
$$;

-- ---------------------------------------------------------------------------
-- report_content gains p_message (replaces the v1.2 4-argument function)
-- ---------------------------------------------------------------------------
drop function public.report_content(uuid, uuid, public.report_reason, text);
create function public.report_content(
  p_checkin uuid,
  p_user uuid,
  p_reason public.report_reason,
  p_note text default null,
  p_message uuid default null
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
  if (p_checkin is null and p_user is null and p_message is null) or p_reason is null then
    raise exception 'invalid';
  end if;
  if p_message is not null then
    if not private.can_read_message(p_message) then
      raise exception 'not_found';
    end if;
    select m.sender_id into v_target_user from public.messages m where m.id = p_message;
  elsif p_checkin is not null then
    if not (private.can_see_checkin(p_checkin) or private.viewer_can_see_checkin(p_checkin)) then
      raise exception 'not_found';
    end if;
    select c.user_id into v_target_user from public.check_ins c where c.id = p_checkin;
  elsif p_user = uid
     or not (exists (
       select 1 from public.memberships a
         join public.memberships b on b.journey_id = a.journey_id
        where a.user_id = uid and b.user_id = p_user
          and a.status = 'active' and b.status = 'active')
       or private.can_see_profile(p_user)) then
    raise exception 'not_found';
  end if;
  if v_target_user = uid then
    raise exception 'invalid';
  end if;
  if (select count(*) from public.reports
       where reporter_id = uid and created_at > now() - interval '24 hours') >= 20 then
    raise exception 'rate_limited';
  end if;

  insert into public.reports (reporter_id, target_checkin_id, target_user_id, target_message_id, reason, note)
  values (uid, p_checkin, v_target_user, p_message, p_reason, left(nullif(btrim(p_note), ''), 500))
  returning id into v_id;
  insert into public.moderation_queue (kind, report_id, actor_id, target_user_id, target_checkin_id,
                                       target_message_id, reason, note)
  values ('report', v_id, uid, v_target_user, p_checkin, p_message, p_reason,
          left(nullif(btrim(p_note), ''), 500));
  return v_id;
end;
$$;

-- ---------------------------------------------------------------------------
-- Function privileges
-- ---------------------------------------------------------------------------
-- Helpers used by RLS / storage policies: callable by authenticated (schema private is not
-- exposed by PostgREST).
revoke all on function
  private.person(uuid), private.blocked_between(uuid, uuid), private.are_friends(uuid, uuid),
  private.is_active_member(uuid, uuid), private.grant_valid(uuid, uuid, uuid),
  private.has_active_share(uuid, uuid), private.earliest_sharer(uuid, uuid),
  private.consent_accepted(uuid, uuid), private.checkin_shareable(uuid),
  private.viewer_can_see_checkin(uuid), private.can_react_as_viewer(uuid),
  private.is_conversation_participant(uuid), private.conversation_read_only(uuid),
  private.can_read_message(uuid), private.group_streak(uuid), private.journey_view(uuid, text),
  private.viewer_role(uuid, boolean), private.consent_json(public.journey_share_consents),
  private.message_json(public.messages)
  from public, anon;
grant execute on function
  private.person(uuid), private.blocked_between(uuid, uuid), private.are_friends(uuid, uuid),
  private.is_active_member(uuid, uuid), private.grant_valid(uuid, uuid, uuid),
  private.has_active_share(uuid, uuid), private.earliest_sharer(uuid, uuid),
  private.consent_accepted(uuid, uuid), private.checkin_shareable(uuid),
  private.viewer_can_see_checkin(uuid), private.can_react_as_viewer(uuid),
  private.is_conversation_participant(uuid), private.conversation_read_only(uuid),
  private.can_read_message(uuid)
  to authenticated, service_role;
grant execute on function private.owner_for_viewer(uuid) to authenticated, service_role;
revoke all on function private.group_streak(uuid), private.journey_view(uuid, text),
  private.viewer_role(uuid, boolean), private.consent_json(public.journey_share_consents),
  private.message_json(public.messages)
  from authenticated;

-- Writers and triggers: never callable from the API.
revoke all on function private.record_view(uuid, text), private.sever_pair(uuid, uuid),
  private.journeys_social_defaults(), private.reactions_saved_sync(),
  private.memberships_consent_pending(), private.blocks_sever()
  from public, anon, authenticated;

revoke all on function
  public.my_friends(), public.find_user_by_username(text), public.send_friend_request(uuid, uuid),
  public.respond_friend_request(uuid, boolean), public.remove_friend(uuid),
  public.create_friend_invite(), public.accept_friend_invite(text),
  public.journey_share_state(uuid), public.share_journey(uuid, uuid[]),
  public.unshare_journey(uuid, uuid, boolean),
  public.update_journey_story(uuid, text, text, text, uuid),
  public.update_public_settings(uuid, boolean, boolean, boolean),
  public.set_hidden_in_share(uuid, boolean), public.set_public_link(uuid, boolean, boolean),
  public.shared_with_me(), public.shared_journey(uuid), public.public_journey_by_token(text),
  public.follow_frame(uuid), public.mark_followed(uuid, uuid),
  public.create_imported_journey(uuid, text, text, public.template_id, date, date, text, text, text),
  public.unsave_journey(uuid),
  public.share_consents(uuid), public.my_pending_consents(), public.request_share_consent(uuid),
  public.respond_share_consent(uuid, boolean), public.withdraw_share_consent(uuid),
  public.open_conversation(uuid, uuid), public.my_conversations(),
  public.conversation_messages(uuid, timestamptz, int),
  public.send_message(uuid, uuid, text, text, text, uuid), public.mark_conversation_read(uuid),
  public.clear_conversation(uuid), public.hide_message(uuid),
  public.inbox_counts(), public.journey_insights(uuid), public.my_reach(),
  public.report_content(uuid, uuid, public.report_reason, text, uuid),
  public.record_journey_view(uuid, text)
  from public, anon;
grant execute on function
  public.my_friends(), public.find_user_by_username(text), public.send_friend_request(uuid, uuid),
  public.respond_friend_request(uuid, boolean), public.remove_friend(uuid),
  public.create_friend_invite(), public.accept_friend_invite(text),
  public.journey_share_state(uuid), public.share_journey(uuid, uuid[]),
  public.unshare_journey(uuid, uuid, boolean),
  public.update_journey_story(uuid, text, text, text, uuid),
  public.update_public_settings(uuid, boolean, boolean, boolean),
  public.set_hidden_in_share(uuid, boolean), public.set_public_link(uuid, boolean, boolean),
  public.shared_with_me(), public.shared_journey(uuid), public.public_journey_by_token(text),
  public.follow_frame(uuid), public.mark_followed(uuid, uuid),
  public.create_imported_journey(uuid, text, text, public.template_id, date, date, text, text, text),
  public.unsave_journey(uuid),
  public.share_consents(uuid), public.my_pending_consents(), public.request_share_consent(uuid),
  public.respond_share_consent(uuid, boolean), public.withdraw_share_consent(uuid),
  public.open_conversation(uuid, uuid), public.my_conversations(),
  public.conversation_messages(uuid, timestamptz, int),
  public.send_message(uuid, uuid, text, text, text, uuid), public.mark_conversation_read(uuid),
  public.clear_conversation(uuid), public.hide_message(uuid),
  public.inbox_counts(), public.journey_insights(uuid), public.my_reach(),
  public.report_content(uuid, uuid, public.report_reason, text, uuid)
  to authenticated;
revoke all on function public.record_journey_view(uuid, text) from authenticated;
grant execute on function public.record_journey_view(uuid, text) to service_role;
