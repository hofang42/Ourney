-- 0026_auth_has_password.sql
-- Parameterless SECURITY DEFINER RPC for authenticated callers to check whether
-- their own auth.users row has a non-empty encrypted_password set.
-- Cross-user enumeration is impossible by signature (caller resolved via public._uid(),
-- which rejects unauthenticated/anon with 28000 and banned users with 42501).

create or replace function public.auth_has_password() returns boolean
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  uid uuid := public._uid();
begin
  return coalesce((
    select u.encrypted_password is not null and btrim(u.encrypted_password) <> ''
      from auth.users u
     where u.id = uid
  ), false);
end;
$$;

revoke all on function public.auth_has_password() from public, anon;
grant execute on function public.auth_has_password() to authenticated, service_role;
