-- 0025_invite_previews: anon-safe friend invite and squad invite preview RPCs for landing (/f, /j, /join)
-- and Cloudflare Pages Functions link-preview metadata.
--
--   * private.invite_preview_attempts + private.caller_ip_hash(p_salt text)
--       Stores only salted SHA-256 IP hashes (never raw IP, matching 0022_landing_waitlist)
--       for anonymous failed preview lookups so valid edge-cached links are never throttled
--       while brute-force code enumeration is capped.
--
--   * public.preview_friend_invite(p_token text) returns json
--       VOLATILE, SECURITY DEFINER, SET search_path = '', executable by anon + authenticated.
--       Validates ^[a-z0-9]{12}$ format first.
--       Throttles failed lookups (60/hour per user or salted IP hash) and raises
--       'rate_limited' (errcode P0001) when over limit so edge functions fail open
--       (HTTP 400 -> no-store, no edge cache poisoning) and browsers fall back cleanly.
--       Returns ONLY {display_name, handle, avatar_initial} (no user_id, no email, no avatar_path).
--       Returns NULL for malformed/unknown token, soft-deleted profile, banned user, or blocked caller.
--
--   * public.preview_group_invite(p_code text) returns json
--       VOLATILE, SECURITY DEFINER, SET search_path = '', executable by anon + authenticated.
--       Validates ^[A-Z0-9]{8}$ format first.
--       Authenticated callers share the exact preview_group_by_code / join_by_code budgets
--       (private.join_attempts 10 failures/hour + private.rate_events code_preview 60/hour).
--       Anonymous callers count failed lookups by salted SHA-256 IP hash (30 failures/hour).
--       Raises 'rate_limited' (errcode P0001) when over limit.
--       Returns ONLY {title, member_count, max_members, owner_display_name} (no ids, no code, no member list).
--       Respects journey privacy/lifecycle flags and returns NULL for malformed/unknown code,
--       ended/deleted journey, or soft-deleted/banned owner.
--
-- Idempotent (create table if not exists, create or replace, revoke/grant).

create table if not exists private.invite_preview_attempts (
  ip_hash text not null check (length(ip_hash) = 64),
  kind text not null check (kind in ('friend_preview', 'group_preview')),
  created_at timestamptz not null default now()
);
create index if not exists invite_preview_attempts_ip_kind_idx
  on private.invite_preview_attempts (ip_hash, kind, created_at);
create index if not exists invite_preview_attempts_created_at_idx
  on private.invite_preview_attempts (created_at);
alter table private.invite_preview_attempts enable row level security;
revoke all on private.invite_preview_attempts from public, anon, authenticated;
grant select, insert, update, delete on private.invite_preview_attempts to service_role;

create or replace function private.caller_ip_hash(p_salt text default 'ourney-invite-preview')
returns text
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_raw_headers text := current_setting('request.headers', true);
  v_headers jsonb;
  v_ip text;
begin
  if v_raw_headers is not null and btrim(v_raw_headers) <> '' then
    begin
      v_headers := v_raw_headers::jsonb;
      v_ip := nullif(btrim(coalesce(v_headers ->> 'cf-connecting-ip', '')), '');
      if v_ip is null then
        v_ip := nullif(btrim(split_part(coalesce(v_headers ->> 'x-forwarded-for', ''), ',', 1)), '');
      end if;
      if v_ip is null then
        v_ip := nullif(btrim(coalesce(v_headers ->> 'x-real-ip', '')), '');
      end if;
    exception when others then
      v_ip := null;
    end;
  end if;

  v_ip := coalesce(v_ip, 'unknown');
  return pg_catalog.encode(
    pg_catalog.sha256(pg_catalog.convert_to(coalesce(p_salt, 'ourney-invite-preview') || '|' || v_ip, 'UTF8')),
    'hex'
  );
end;
$$;

revoke all on function private.caller_ip_hash(text) from public, anon, authenticated;
grant execute on function private.caller_ip_hash(text) to service_role;

create or replace function public.preview_friend_invite(p_token text) returns json
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_token text := lower(btrim(coalesce(p_token, '')));
  v_uid uuid := (select auth.uid());
  v_ip_hash text;
  v_display_name text;
  v_username text;
  v_initial text;
begin
  if v_token !~ '^[a-z0-9]{12}$' then
    return null;
  end if;

  if v_uid is not null then
    if private.caller_is_banned()
       or not exists (select 1 from public.profiles where id = v_uid and deleted_at is null) then
      return null;
    end if;

    delete from private.rate_events
     where user_id = v_uid and at < now() - interval '1 day';
    if (select count(*) from private.rate_events
         where user_id = v_uid
           and kind = 'friend_preview_miss'
           and at > now() - interval '1 hour') >= 60 then
      raise exception 'rate_limited' using errcode = 'P0001';
    end if;
  else
    v_ip_hash := private.caller_ip_hash('ourney-friend-preview');
    delete from private.invite_preview_attempts
     where created_at < now() - interval '1 day';
    if (select count(*) from private.invite_preview_attempts
         where ip_hash = v_ip_hash
           and kind = 'friend_preview'
           and created_at > now() - interval '1 hour') >= 60 then
      raise exception 'rate_limited' using errcode = 'P0001';
    end if;
  end if;

  select btrim(p.display_name), p.username
    into v_display_name, v_username
    from public.friend_invites i
    join public.profiles p on p.id = i.user_id
   where i.token = v_token
     and p.deleted_at is null
     and not private.is_user_banned(i.user_id)
     and (v_uid is null or not private.blocked_between(v_uid, i.user_id));

  if not found then
    if v_uid is not null then
      insert into private.rate_events (user_id, kind) values (v_uid, 'friend_preview_miss');
    else
      insert into private.invite_preview_attempts (ip_hash, kind) values (v_ip_hash, 'friend_preview');
    end if;
    return null;
  end if;

  v_initial := upper(coalesce(
    nullif(substring(v_display_name from '[[:alpha:][:digit:]]'), ''),
    nullif(left(v_display_name, 1), ''),
    nullif(left(v_username, 1), ''),
    '?'
  ));

  return json_build_object(
    'display_name', v_display_name,
    'handle', v_username,
    'avatar_initial', v_initial
  );
end;
$$;

revoke all on function public.preview_friend_invite(text) from public;
grant execute on function public.preview_friend_invite(text) to anon, authenticated, service_role;

create or replace function public.preview_group_invite(p_code text) returns json
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_code text := upper(btrim(coalesce(p_code, '')));
  v_uid uuid := (select auth.uid());
  v_ip_hash text;
  v_journey_id uuid;
  v_title text;
  v_max_members int;
  v_owner_name text;
  v_member_count int;
  v_found boolean := false;
begin
  if v_code !~ '^[A-Z0-9]{8}$' then
    return null;
  end if;

  if v_uid is not null then
    if private.caller_is_banned()
       or not exists (select 1 from public.profiles where id = v_uid and deleted_at is null) then
      return null;
    end if;

    delete from private.join_attempts
     where user_id = v_uid and attempted_at < now() - interval '1 hour';
    delete from private.rate_events
     where user_id = v_uid and at < now() - interval '1 day';

    if (select count(*) from private.join_attempts
         where user_id = v_uid and not success) >= 10
       or (select count(*) from private.rate_events
            where user_id = v_uid and kind = 'code_preview' and at > now() - interval '1 hour') >= 60 then
      raise exception 'rate_limited' using errcode = 'P0001';
    end if;
  else
    v_ip_hash := private.caller_ip_hash('ourney-group-preview');
    delete from private.invite_preview_attempts
     where created_at < now() - interval '1 day';
    if (select count(*) from private.invite_preview_attempts
         where ip_hash = v_ip_hash
           and kind = 'group_preview'
           and created_at > now() - interval '1 hour') >= 30 then
      raise exception 'rate_limited' using errcode = 'P0001';
    end if;
  end if;

  select j.id,
         btrim(j.title),
         j.max_members,
         case
           when exists (
             select 1 from public.journey_share_consents sc
              where sc.journey_id = j.id
                and sc.user_id = j.owner_id
                and sc.status in ('pending', 'declined', 'withdrawn')
           ) then null
           else nullif(btrim(p.display_name), '')
         end
    into v_journey_id, v_title, v_max_members, v_owner_name
    from public.journeys j
    join public.profiles p on p.id = j.owner_id
   where j.invite_code = v_code
     and j.kind = 'group'
     and j.deleted_at is null
     and j.status = 'active'
     and (j.duration_days is null
          or public.local_date(now(), j.timezone) <= j.start_date + j.duration_days - 1)
     and p.deleted_at is null
     and not private.is_user_banned(j.owner_id);

  v_found := found;

  if v_found and v_uid is not null then
    if exists (
      select 1 from public.memberships m
       where m.journey_id = v_journey_id
         and m.user_id = v_uid
         and m.removed_at is not null
    ) or exists (
      select 1 from public.memberships am
       where am.journey_id = v_journey_id
         and am.status = 'active'
         and am.deleted_at is null
         and private.blocked_between(v_uid, am.user_id)
    ) then
      v_found := false;
    end if;
  end if;

  if not v_found then
    if v_uid is not null then
      insert into private.join_attempts (user_id, success) values (v_uid, false);
    else
      insert into private.invite_preview_attempts (ip_hash, kind) values (v_ip_hash, 'group_preview');
    end if;
    return null;
  end if;

  if v_uid is not null then
    insert into private.rate_events (user_id, kind) values (v_uid, 'code_preview');
  end if;

  select count(*)::int
    into v_member_count
    from public.memberships am
    join public.profiles mp on mp.id = am.user_id and mp.deleted_at is null
   where am.journey_id = v_journey_id
     and am.status = 'active'
     and am.deleted_at is null
     and not private.is_user_banned(am.user_id);

  return json_build_object(
    'title', v_title,
    'member_count', v_member_count,
    'max_members', v_max_members,
    'owner_display_name', v_owner_name
  );
end;
$$;

revoke all on function public.preview_group_invite(text) from public;
grant execute on function public.preview_group_invite(text) to anon, authenticated, service_role;
