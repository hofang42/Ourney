-- 0025_invite_previews: anon-safe friend invite and squad invite preview RPCs for landing (/f, /j, /join)
-- and Cloudflare Pages Functions link-preview metadata.
--
--   * public.preview_friend_invite(p_token text) returns json
--       SECURITY DEFINER, SET search_path = '', executable by anon + authenticated.
--       Validates ^[a-z0-9]{12}$ format first.
--       Returns ONLY {display_name, handle, avatar_initial} (no user_id, no email, no avatar_path).
--       Returns NULL for malformed/unknown token, soft-deleted profile, banned user, or blocked caller.
--
--   * public.preview_group_invite(p_code text) returns json
--       SECURITY DEFINER, SET search_path = '', executable by anon + authenticated.
--       Validates ^[A-Z0-9]{8}$ format first.
--       Returns ONLY {title, member_count, max_members, inviter_display_name} (no ids, no code, no member list).
--       Respects journey privacy/lifecycle flags and returns NULL for malformed/unknown code,
--       ended/deleted journey, or soft-deleted/banned owner.
--
-- Idempotent (create or replace, revoke/grant).

create or replace function public.preview_friend_invite(p_token text) returns json
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_token text := lower(btrim(coalesce(p_token, '')));
  v_uid uuid := (select auth.uid());
  v_display_name text;
  v_username text;
  v_initial text;
begin
  if v_token !~ '^[a-z0-9]{12}$' then
    return null;
  end if;

  if v_uid is not null and private.caller_is_banned() then
    return null;
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
    return null;
  end if;

  v_initial := upper(left(coalesce(nullif(v_display_name, ''), v_username, '?'), 1));

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
stable
security definer
set search_path = ''
as $$
declare
  v_code text := upper(btrim(coalesce(p_code, '')));
  v_uid uuid := (select auth.uid());
  v_journey_id uuid;
  v_title text;
  v_max_members int;
  v_owner_name text;
  v_member_count int;
begin
  if v_code !~ '^[A-Z0-9]{8}$' then
    return null;
  end if;

  if v_uid is not null and private.caller_is_banned() then
    return null;
  end if;

  select j.id,
         btrim(j.title),
         j.max_members,
         case
           when exists (
             select 1 from public.journey_share_consents sc
              where sc.journey_id = j.id
                and sc.user_id = j.owner_id
                and sc.status in ('declined', 'withdrawn')
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

  if not found then
    return null;
  end if;

  if v_uid is not null then
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
      return null;
    end if;
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
    'inviter_display_name', v_owner_name
  );
end;
$$;

revoke all on function public.preview_group_invite(text) from public;
grant execute on function public.preview_group_invite(text) to anon, authenticated, service_role;
