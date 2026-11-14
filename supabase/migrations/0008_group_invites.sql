-- 0008_group_invites: join-by-code preview + group invitations feed.
-- Idempotent (safe to re-run). Error convention as 0004-0006: `raise exception '<code>'`
-- (P0001), forbidden = 42501, unauthenticated = 28000 via public._uid().
--
--  * public.preview_group_by_code(code)   look up a code WITHOUT joining (throttled, no leaks)
--  * public.group_invitations             invitation rows (RPC-written, RLS read for the two parties)
--  * public.send_group_invitation / my_group_invitations / accept_ / decline_group_invitation
-- Confirming a join reuses public.join_by_code (accept calls it internally).

-- ---------------------------------------------------------------------------
-- group_invitations
-- ---------------------------------------------------------------------------
create table if not exists public.group_invitations (
  id uuid primary key default gen_random_uuid(),
  journey_id uuid not null references public.journeys (id) on delete cascade,
  inviter_id uuid not null references public.profiles (id) on delete cascade,
  invitee_kind text not null check (invitee_kind in ('user', 'handle', 'code')),
  -- Always set for 'user'/'handle' (a handle is resolved to a user when sent); null for 'code'.
  invitee_id uuid references public.profiles (id) on delete cascade,
  invitee_handle text check (invitee_handle is null or invitee_handle ~ '^[a-z0-9_.]{3,20}$'),
  status text not null default 'pending' check (status in ('pending', 'accepted', 'declined')),
  expires_at timestamptz not null default now() + interval '7 days',
  responded_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint group_invitations_target check (
    (invitee_kind in ('user', 'handle') and invitee_id is not null)
    or (invitee_kind = 'code' and invitee_id is null)),
  constraint group_invitations_not_self check (invitee_id is null or invitee_id <> inviter_id)
);
create unique index if not exists group_invitations_pending_uidx
  on public.group_invitations (journey_id, invitee_id)
  where status = 'pending' and invitee_id is not null;
create index if not exists group_invitations_invitee_idx
  on public.group_invitations (invitee_id) where status = 'pending';
create index if not exists group_invitations_inviter_idx on public.group_invitations (inviter_id);
create index if not exists group_invitations_journey_idx on public.group_invitations (journey_id);

drop trigger if exists group_invitations_updated on public.group_invitations;
create trigger group_invitations_updated before update on public.group_invitations
  for each row execute function public.set_updated_at();

revoke all on public.group_invitations from anon, authenticated;
grant select on public.group_invitations to authenticated;
alter table public.group_invitations enable row level security;

drop policy if exists group_invitations_select on public.group_invitations;
create policy group_invitations_select on public.group_invitations for select to authenticated
  using ((select auth.uid()) in (inviter_id, invitee_id));

-- ---------------------------------------------------------------------------
-- preview_group_by_code: what a code holder may see before confirming.
-- Returns NULL for an unknown / malformed / unusable code (blocked, removed): the failed
-- attempt is committed in private.join_attempts and shares join_by_code's budget
-- (rate_limited after 10 failures per hour); successful previews are capped at 60 per hour.
-- Only title, emoji, template, owner display name, headcount, duration, progress and up to
-- 5 member display names/avatars are returned: no ids, no code, no check-ins.
-- ---------------------------------------------------------------------------
create or replace function public.preview_group_by_code(p_code text) returns json
language plpgsql security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
  v_code text := upper(btrim(p_code));
  j public.journeys%rowtype;
  m public.memberships%rowtype;
  v_found boolean := false;
  v_count int;
  v_state text := 'open';
  v_day int;
  v_owner json;
  v_members json;
begin
  perform 1 from public.profiles where id = uid and deleted_at is null for update;
  if not found then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  delete from private.join_attempts where user_id = uid and attempted_at < now() - interval '1 hour';
  delete from private.rate_events where user_id = uid and at < now() - interval '1 day';
  if (select count(*) from private.join_attempts where user_id = uid and not success) >= 10
     or (select count(*) from private.rate_events
          where user_id = uid and kind = 'code_preview' and at > now() - interval '1 hour') >= 60 then
    raise exception 'rate_limited';
  end if;

  if v_code is not null and v_code ~ '^[A-Z0-9]{8}$' then
    select * into j from public.journeys
     where invite_code = v_code and kind = 'group' and deleted_at is null;
    v_found := found;
  end if;
  if v_found then
    select * into m from public.memberships where journey_id = j.id and user_id = uid;
    if found and m.removed_at is not null then
      v_found := false; -- removed members learn nothing (same answer as an unknown code)
    elsif exists (
      select 1 from public.memberships am
       where am.journey_id = j.id and am.status = 'active' and am.deleted_at is null
         and private.blocked_between(uid, am.user_id)
    ) then
      v_found := false;
    end if;
  end if;
  if not v_found then
    insert into private.join_attempts (user_id, success) values (uid, false);
    return null;
  end if;
  insert into private.rate_events (user_id, kind) values (uid, 'code_preview');

  select count(*) into v_count from public.memberships
   where journey_id = j.id and status = 'active' and deleted_at is null;
  if j.status <> 'active'
     or (j.duration_days is not null
         and public.local_date(now(), j.timezone) > j.start_date + j.duration_days - 1) then
    v_state := 'ended';
  elsif m.user_id is not null and m.status = 'active' and m.deleted_at is null then
    v_state := 'member';
  elsif v_count >= j.max_members then
    v_state := 'full';
  end if;

  v_day := greatest(1, least(coalesce(j.duration_days, 2147483647),
             (public.local_date(now(), j.timezone) - j.start_date) + 1));
  select json_build_object('display_name', p.display_name, 'avatar_path', p.avatar_path)
    into v_owner from public.profiles p where p.id = j.owner_id;
  select coalesce(json_agg(x.o order by x.joined_at), '[]'::json) into v_members
    from (
      select json_build_object('display_name', p.display_name, 'avatar_path', p.avatar_path) as o,
             am.joined_at
        from public.memberships am
        join public.profiles p on p.id = am.user_id and p.deleted_at is null
       where am.journey_id = j.id and am.status = 'active' and am.deleted_at is null
       order by am.joined_at
       limit 5
    ) x;

  return json_build_object(
    'state', v_state,
    'title', j.title,
    'emoji', j.emoji,
    'template_id', j.template_id,
    'owner', v_owner,
    'member_count', v_count,
    'max_members', j.max_members,
    'duration_days', j.duration_days,
    'day_number', v_day,
    'members', v_members);
end;
$$;

-- ---------------------------------------------------------------------------
-- send_group_invitation: an active member invites a user (id) or a @handle.
-- Errors: forbidden (not an active member), not_found (no such group/user, or blocked),
-- ended, full, invalid (already a member / already pending), rate_limited (20 per day).
-- ---------------------------------------------------------------------------
create or replace function public.send_group_invitation(
  p_journey uuid, p_user uuid default null, p_handle text default null
) returns json
language plpgsql security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
  j public.journeys%rowtype;
  v_handle text := lower(ltrim(btrim(coalesce(p_handle, '')), '@'));
  v_target uuid;
  v_kind text;
  v_id uuid;
begin
  perform 1 from public.profiles where id = uid and deleted_at is null for update;
  if not found then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if not exists (select 1 from public.memberships
                  where journey_id = p_journey and user_id = uid
                    and status = 'active' and deleted_at is null) then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  select * into j from public.journeys where id = p_journey and kind = 'group' and deleted_at is null;
  if not found then
    raise exception 'not_found';
  end if;
  if j.status <> 'active' then
    raise exception 'ended';
  end if;

  delete from private.rate_events where user_id = uid and at < now() - interval '1 day';
  if (select count(*) from private.rate_events
       where user_id = uid and kind = 'group_invite' and at > now() - interval '1 day') >= 20 then
    raise exception 'rate_limited';
  end if;
  insert into private.rate_events (user_id, kind) values (uid, 'group_invite');

  if p_user is not null then
    v_target := p_user;
    v_kind := 'user';
  elsif v_handle ~ '^[a-z0-9_.]{3,20}$' then
    select id into v_target from public.profiles where username = v_handle and deleted_at is null;
    v_kind := 'handle';
  end if;
  if v_target is null or v_target = uid
     or not exists (select 1 from public.profiles where id = v_target and deleted_at is null)
     or private.blocked_between(uid, v_target) then
    raise exception 'not_found'; -- same answer for unknown and blocked users
  end if;
  if exists (select 1 from public.memberships
              where journey_id = j.id and user_id = v_target and status = 'active' and deleted_at is null)
     or exists (select 1 from public.memberships
                 where journey_id = j.id and user_id = v_target and removed_at is not null) then
    raise exception 'invalid';
  end if;
  if (select count(*) from public.memberships
       where journey_id = j.id and status = 'active' and deleted_at is null) >= j.max_members then
    raise exception 'full';
  end if;

  -- An expired pending row must not block a fresh invitation.
  update public.group_invitations set status = 'declined', responded_at = now()
   where journey_id = j.id and invitee_id = v_target and status = 'pending' and expires_at <= now();
  if exists (select 1 from public.group_invitations
              where journey_id = j.id and invitee_id = v_target and status = 'pending') then
    raise exception 'invalid';
  end if;

  insert into public.group_invitations (journey_id, inviter_id, invitee_kind, invitee_id, invitee_handle)
  values (j.id, uid, v_kind, v_target,
          case when v_kind = 'handle' then v_handle else null end)
  returning id into v_id;
  return json_build_object('id', v_id);
end;
$$;

-- ---------------------------------------------------------------------------
-- my_group_invitations: the caller's pending, unexpired invitations (Activity feed).
-- Never returns the invite code; invitations from blocked users and for groups that
-- ended or were deleted are hidden.
-- ---------------------------------------------------------------------------
create or replace function public.my_group_invitations() returns json
language plpgsql stable security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
begin
  return coalesce((
    select json_agg(json_build_object(
      'id', i.id,
      'journey_id', j.id,
      'title', j.title,
      'emoji', j.emoji,
      'template_id', j.template_id,
      'inviter', private.person(i.inviter_id),
      'member_count', (select count(*) from public.memberships am
                        where am.journey_id = j.id and am.status = 'active' and am.deleted_at is null),
      'max_members', j.max_members,
      'created_at', i.created_at,
      'expires_at', i.expires_at) order by i.created_at desc)
      from public.group_invitations i
      join public.journeys j on j.id = i.journey_id and j.deleted_at is null and j.status = 'active'
     where i.invitee_id = uid and i.status = 'pending' and i.expires_at > now()
       and not private.blocked_between(uid, i.inviter_id)
  ), '[]'::json);
end;
$$;

-- ---------------------------------------------------------------------------
-- accept_group_invitation: joins through public.join_by_code (same rules: ended, blocked,
-- full, limit, rate_limited) and returns the journey row. Errors: not_found (unknown, not
-- yours, not pending or expired), plus join_by_code's. All-or-nothing: if the join raises,
-- the invitation stays pending.
-- ---------------------------------------------------------------------------
create or replace function public.accept_group_invitation(p_invitation uuid) returns public.journeys
language plpgsql security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
  i public.group_invitations%rowtype;
  j public.journeys%rowtype;
  r public.journeys%rowtype;
begin
  select * into i from public.group_invitations
   where id = p_invitation and invitee_id = uid and status = 'pending' and expires_at > now()
   for update;
  if not found then
    raise exception 'not_found';
  end if;
  select * into j from public.journeys where id = i.journey_id and kind = 'group' and deleted_at is null;
  if not found or j.invite_code is null then
    raise exception 'not_found';
  end if;
  if private.blocked_between(uid, i.inviter_id) then
    raise exception 'blocked';
  end if;
  r := public.join_by_code(j.invite_code);
  if r.id is null then
    raise exception 'not_found';
  end if;
  update public.group_invitations set status = 'accepted', responded_at = now() where id = i.id;
  return r;
end;
$$;

create or replace function public.decline_group_invitation(p_invitation uuid) returns void
language plpgsql security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
begin
  update public.group_invitations set status = 'declined', responded_at = now()
   where id = p_invitation and invitee_id = uid and status = 'pending';
  if not found then
    raise exception 'not_found';
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- Privileges
-- ---------------------------------------------------------------------------
revoke all on function
  public.preview_group_by_code(text), public.send_group_invitation(uuid, uuid, text),
  public.my_group_invitations(), public.accept_group_invitation(uuid),
  public.decline_group_invitation(uuid)
  from public, anon;
grant execute on function
  public.preview_group_by_code(text), public.send_group_invitation(uuid, uuid, text),
  public.my_group_invitations(), public.accept_group_invitation(uuid),
  public.decline_group_invitation(uuid)
  to authenticated;
