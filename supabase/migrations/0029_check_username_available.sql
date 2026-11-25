-- 0029_check_username_available.sql
-- UX-09: SECURITY DEFINER RPC for authenticated callers (including brand-new
-- accounts on /profile/setup before a public.profiles row exists) to check
-- whether a candidate username is valid, passes content policy, and is not
-- already taken by another account in public.profiles.

create or replace function public.check_username_available(p_username text) returns boolean
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  uid uuid := public._uid();
  v_name text := lower(ltrim(btrim(coalesce(p_username, '')), '@'));
  v_owner uuid;
begin
  if v_name !~ '^[a-z0-9_.]{3,20}$' then
    return false;
  end if;
  select p.id into v_owner from public.profiles p where p.username = v_name;
  if v_owner = uid then
    return true;
  end if;
  if private.contains_objectionable_text(v_name) then
    return false;
  end if;
  return v_owner is null;
end;
$$;

revoke all on function public.check_username_available(text) from public, anon;
grant execute on function public.check_username_available(text) to authenticated, service_role;

-- UX-38: keep only the identity the caller could read before blocking.
-- Legacy blocks have no snapshot. Blocks remain possible by ID alone.
create table private.blocked_profile_names (
  blocker_id uuid not null,
  blocked_id uuid not null,
  username text not null,
  display_name text not null,
  primary key (blocker_id, blocked_id),
  foreign key (blocker_id, blocked_id)
    references public.blocks (blocker_id, blocked_id) on delete cascade
);

alter table private.blocked_profile_names enable row level security;
revoke all on private.blocked_profile_names from public, anon, authenticated;

create or replace function public.block_user(p_user uuid) returns void
language plpgsql security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
  v_username text;
  v_display_name text;
  v_visible boolean;
begin
  if p_user is null or p_user = uid then
    raise exception 'invalid';
  end if;
  select p.username, p.display_name into v_username, v_display_name
    from public.profiles p
   where p.id = p_user and p.deleted_at is null;
  if not found then
    raise exception 'not_found';
  end if;
  v_visible := private.can_see_profile(p_user) and not private.is_user_banned(p_user);

  insert into public.blocks (blocker_id, blocked_id) values (uid, p_user)
  on conflict (blocker_id, blocked_id) do nothing;
  if found then
    insert into public.moderation_queue (kind, actor_id, target_user_id)
    values ('block', uid, p_user);
  else
    update public.blocks
       set deleted_at = null
     where blocker_id = uid and blocked_id = p_user and deleted_at is not null;
    if not found then
      return;
    end if;
  end if;

  if v_visible then
    insert into private.blocked_profile_names (blocker_id, blocked_id, username, display_name)
    values (uid, p_user, v_username, v_display_name)
    on conflict (blocker_id, blocked_id) do update
      set username = excluded.username, display_name = excluded.display_name;
  end if;
end;
$$;

create or replace function public.unblock_user(p_user uuid) returns void
language plpgsql security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
begin
  with unblocked as (
    update public.blocks set deleted_at = now()
     where blocker_id = uid and blocked_id = p_user and deleted_at is null
    returning blocker_id, blocked_id
  )
  delete from private.blocked_profile_names n
   using unblocked u
   where n.blocker_id = u.blocker_id and n.blocked_id = u.blocked_id;
end;
$$;

create or replace function public.my_blocked_people() returns json
language plpgsql stable security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
begin
  return coalesce((
    select json_agg(json_build_object(
      'user_id', b.blocked_id,
      'username', n.username,
      'display_name', n.display_name,
      'avatar_path', null) order by b.created_at desc)
      from public.blocks b
      left join private.blocked_profile_names n
        on n.blocker_id = b.blocker_id and n.blocked_id = b.blocked_id
       and exists (
         select 1 from public.profiles p
          where p.id = b.blocked_id and p.deleted_at is null
            and not private.is_user_banned(p.id)
       )
       and not exists (
         select 1 from public.blocks reverse_block
          where reverse_block.blocker_id = b.blocked_id
            and reverse_block.blocked_id = uid and reverse_block.deleted_at is null
       )
     where b.blocker_id = uid and b.deleted_at is null
  ), '[]'::json);
end;
$$;
