-- 0002_rls: authorization helpers, privileges, RLS on EVERY table.
-- Writes to journeys/memberships structure go through SECURITY DEFINER RPCs (0004).

-- ---------------------------------------------------------------------------
-- SECURITY DEFINER helpers (avoid RLS recursion on memberships; fixed search_path)
-- ---------------------------------------------------------------------------
create function public.is_member(journey uuid) returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.memberships m
     where m.journey_id = journey
       and m.user_id = (select auth.uid())
       and m.status = 'active'
       and m.deleted_at is null
  );
$$;

create function public.is_owner(journey uuid) returns boolean
language sql
stable
security definer
set search_path = ''
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

-- True when either user has blocked the other (and the caller is one of them or the check is about the caller).
create function public.is_blocked_pair(other uuid) returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.blocks b
     where b.deleted_at is null
       and ((b.blocker_id = (select auth.uid()) and b.blocked_id = other)
         or (b.blocked_id = (select auth.uid()) and b.blocker_id = other))
  );
$$;

create function public.can_see_checkin(checkin uuid) returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.check_ins c
     where c.id = checkin
       and c.deleted_at is null
       and public.is_member(c.journey_id)
       and not public.is_blocked_pair(c.user_id)
  );
$$;

-- FR-F2: content the caller reported is hidden from the caller at once.
create function public.has_reported(checkin uuid) returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.reports r
     where r.target_checkin_id = checkin
       and r.reporter_id = (select auth.uid())
       and r.deleted_at is null
  );
$$;

-- Storage read check for checkins/{journey}/{author}/...: own media always; otherwise the
-- caller must be an active member, the author must still be an active member (media of
-- members who left is hidden, 02 §9.1) and neither may have blocked the other.
create function public.can_read_checkin_media(journey uuid, author uuid) returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select author = (select auth.uid())
      or (public.is_member(journey)
          and exists (select 1 from public.memberships m
                       where m.journey_id = journey and m.user_id = author
                         and m.status = 'active' and m.deleted_at is null)
          and not public.is_blocked_pair(author));
$$;

revoke all on function public.is_member(uuid), public.is_owner(uuid),
  public.is_blocked_pair(uuid), public.can_see_checkin(uuid), public.has_reported(uuid),
  public.can_read_checkin_media(uuid, uuid) from public, anon;
grant execute on function public.is_member(uuid), public.is_owner(uuid),
  public.is_blocked_pair(uuid), public.can_see_checkin(uuid), public.has_reported(uuid),
  public.can_read_checkin_media(uuid, uuid) to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- Privileges: least privilege. anon gets nothing.
-- ---------------------------------------------------------------------------
revoke all on all tables in schema public from anon, authenticated;
revoke all on all functions in schema public from public, anon;
alter default privileges in schema public revoke all on tables from anon;
alter default privileges in schema public revoke all on functions from public, anon;

grant select on public.profiles, public.journeys, public.memberships, public.check_ins,
  public.reactions, public.blocks, public.reports to authenticated;
grant insert (id, username, display_name, avatar_path) on public.profiles to authenticated;
grant update (username, display_name, avatar_path, deleted_at) on public.profiles to authenticated;
-- journeys: no direct insert/delete; owners may edit presentation fields only.
grant update (title, emoji, metric_name, metric_unit, hide_metric_default, duration_days) on public.journeys to authenticated;
-- memberships: users only toggle their own display preferences.
grant update (hide_metric, blur_media) on public.memberships to authenticated;
grant insert, update on public.check_ins to authenticated;
grant insert, update on public.reactions to authenticated;
-- blocks: written only via block_user()/unblock_user() (they also feed moderation_queue).
-- reports: created only via report_content().

-- service_role (Edge Functions) keeps full access through Supabase default grants.

-- ---------------------------------------------------------------------------
-- RLS on every table
-- ---------------------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.journeys enable row level security;
alter table public.memberships enable row level security;
alter table public.check_ins enable row level security;
alter table public.reactions enable row level security;
alter table public.blocks enable row level security;
alter table public.reports enable row level security;
alter table public.moderation_queue enable row level security;

-- profiles: readable by any authenticated user, writable by self
create policy profiles_select on public.profiles for select to authenticated using (true);
create policy profiles_insert on public.profiles for insert to authenticated
  with check (id = (select auth.uid()));
create policy profiles_update on public.profiles for update to authenticated
  using (id = (select auth.uid())) with check (id = (select auth.uid()));

-- journeys: members only (link-visibility solo journeys are served by the public-journey
-- Edge Function using the service role, never by anon RLS)
create policy journeys_select on public.journeys for select to authenticated
  using (public.is_member(id));
create policy journeys_update on public.journeys for update to authenticated
  using (public.is_owner(id) and status = 'active' and deleted_at is null)
  with check (public.is_owner(id));

-- memberships
create policy memberships_select on public.memberships for select to authenticated
  using (user_id = (select auth.uid()) or public.is_member(journey_id));
create policy memberships_update on public.memberships for update to authenticated
  using (user_id = (select auth.uid()) and status = 'active')
  with check (user_id = (select auth.uid()));

-- check_ins: own rows always (also after leaving); otherwise active members, minus blocked
-- users (either direction) and minus check-ins the caller reported.
-- Soft-deleted rows (deleted_at, incl. hidden_by_leave) stay visible as sync tombstones;
-- their media is no longer readable (can_read_checkin_media).
create policy check_ins_select on public.check_ins for select to authenticated
  using (
    user_id = (select auth.uid())
    or (public.is_member(journey_id)
        and not public.is_blocked_pair(user_id)
        and not public.has_reported(id))
  );
create policy check_ins_insert on public.check_ins for insert to authenticated
  with check (user_id = (select auth.uid()) and public.is_member(journey_id));
create policy check_ins_update on public.check_ins for update to authenticated
  using (user_id = (select auth.uid()) and public.is_member(journey_id))
  with check (user_id = (select auth.uid()) and public.is_member(journey_id));

-- reactions: members who can see the check-in
create policy reactions_select on public.reactions for select to authenticated
  using (public.can_see_checkin(checkin_id) and not public.is_blocked_pair(user_id));
create policy reactions_insert on public.reactions for insert to authenticated
  with check (user_id = (select auth.uid()) and public.can_see_checkin(checkin_id));
create policy reactions_update on public.reactions for update to authenticated
  using (user_id = (select auth.uid()) and public.can_see_checkin(checkin_id))
  with check (user_id = (select auth.uid()) and public.can_see_checkin(checkin_id));

-- blocks: own, read-only (writes via RPC)
create policy blocks_select on public.blocks for select to authenticated
  using (blocker_id = (select auth.uid()));

-- reports: own, read-only (insert via RPC); moderators use service_role
create policy reports_select on public.reports for select to authenticated
  using (reporter_id = (select auth.uid()));

-- moderation_queue: no API access at all (no grants either). Explicit deny policy so the
-- "every table has a policy" check stays meaningful; service_role bypasses RLS.
create policy moderation_queue_deny on public.moderation_queue for all to authenticated
  using (false) with check (false);

-- ---------------------------------------------------------------------------
-- Function privileges: internal/trigger helpers are not callable by API roles.
-- Pure helpers used inside triggers/policies stay executable for authenticated.
-- ---------------------------------------------------------------------------
revoke all on function public.set_updated_at(), public.random_token(int, text),
  public.journeys_validate(), public.check_ins_before_write(), public.reactions_before_write()
  from public, anon, authenticated;
revoke all on function public.local_date(timestamptz, text), public.try_uuid(text),
  public.streak_core(date[], date, date, date), public.streak_from_dates(date[], date, int, date),
  public.journey_streak(uuid, uuid, date) from public, anon;
grant execute on function public.local_date(timestamptz, text), public.try_uuid(text),
  public.streak_core(date[], date, date, date), public.streak_from_dates(date[], date, int, date),
  public.journey_streak(uuid, uuid, date) to authenticated, service_role;
