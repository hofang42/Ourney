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
begin
  if v_name !~ '^[a-z0-9_.]{3,20}$' then
    return false;
  end if;
  if private.contains_objectionable_text(v_name) then
    return false;
  end if;
  return not exists (
    select 1
      from public.profiles p
     where p.username = v_name
       and p.id <> uid
  );
end;
$$;

revoke all on function public.check_username_available(text) from public, anon;
grant execute on function public.check_username_available(text) to authenticated, service_role;
