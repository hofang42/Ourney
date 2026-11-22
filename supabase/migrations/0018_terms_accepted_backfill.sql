-- 0018_terms_accepted_backfill: terms consent is recorded once per account (client side `terms_version`
-- and `terms_accepted_at` in the auth user metadata) instead of once per device.
--
-- Before this, the EULA gate only stored a flag on the device (wiped on sign-out), so every sign-in on
-- a new device or after a reinstall asked an existing account to consent again. Every account that has
-- a profile passed that gate at least once, because /profile/setup sits behind it, so those accounts
-- are marked as having accepted version 1. Accounts without a profile (signed up, never finished) are
-- left alone and see the one-tap terms screen after their next sign-in.
--
-- Idempotent: accounts that already carry `terms_version` are not touched, so it is safe to re-run and
-- never lowers a newer version. Service/migration role only (nothing is granted to clients).

create function private.backfill_terms_accepted(p_version int)
returns int
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_count int;
begin
  update auth.users u
     set raw_user_meta_data = coalesce(u.raw_user_meta_data, '{}'::jsonb)
           || jsonb_build_object('terms_version', p_version, 'terms_accepted_at', now())
   where exists (select 1 from public.profiles p where p.id = u.id)
     and not (coalesce(u.raw_user_meta_data, '{}'::jsonb) ? 'terms_version');
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;
revoke all on function private.backfill_terms_accepted(int) from public, anon, authenticated;

select private.backfill_terms_accepted(1);
