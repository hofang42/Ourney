-- 0018_terms_accepted_backfill: server-authoritative terms consent (`public.profiles.terms_version`
-- and `private.terms_acceptance`), recorded via `public.accept_terms(p_version int)`.
--
-- Terms consent must never live in client-writable `auth.users.raw_user_meta_data`. Instead:
--   1. `public.profiles.terms_version` (`int not null default 0`) exposes the accepted version on
--      the existing profile SELECT while revoking direct client INSERT/UPDATE on that column.
--   2. `private.terms_acceptance` records `(user_id, terms_version, accepted_at)` even when a newly
--      signed-in account accepts the EULA on `/safety/eula/accept` before creating its profile row
--      on `/profile/setup`; a BEFORE INSERT trigger on `public.profiles` copies that version onto
--      the profile row when it is created.
--   3. `public.accept_terms(p_version int)` (SECURITY DEFINER, `search_path = ''`) validates the
--      signed-in caller (`public._uid()`) and version (`1..v_max`), stamps server `now()`, and only
--      raises `terms_version` (never lowers a newer version).
--   4. Every existing profile row passed the EULA gate at least once (because `/profile/setup` sits
--      behind it) and is backfilled to version 1.

alter table public.profiles
  add column if not exists terms_version int not null default 0;

do $$
begin
  if not exists (
    select 1 from pg_constraint
     where conrelid = 'public.profiles'::regclass
       and conname = 'profiles_terms_version_non_negative'
  ) then
    alter table public.profiles
      add constraint profiles_terms_version_non_negative check (terms_version >= 0);
  end if;
end $$;

-- Clients read `terms_version` through the table-level SELECT grant on `public.profiles`, but may
-- never write it directly (column-level INSERT/UPDATE grants on `public.profiles` exclude it).
revoke insert (terms_version), update (terms_version) on public.profiles
  from public, anon, authenticated;

create table if not exists private.terms_acceptance (
  user_id uuid primary key references auth.users (id) on delete cascade,
  terms_version int not null check (terms_version >= 1),
  accepted_at timestamptz not null default now()
);
alter table private.terms_acceptance enable row level security;
revoke all on private.terms_acceptance from public, anon, authenticated;
grant select, insert, update, delete on private.terms_acceptance to service_role;

-- Copies any pre-profile consent from `private.terms_acceptance` onto `public.profiles` on insert,
-- and prevents direct client inserts from forging `terms_version`.
create or replace function private.profiles_apply_terms()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_accepted int;
begin
  select t.terms_version into v_accepted
    from private.terms_acceptance t
   where t.user_id = new.id;
  if current_user in ('authenticated', 'anon') then
    new.terms_version := coalesce(v_accepted, 0);
  else
    new.terms_version := greatest(coalesce(new.terms_version, 0), coalesce(v_accepted, 0));
  end if;
  return new;
end;
$$;
revoke all on function private.profiles_apply_terms() from public, anon, authenticated;

drop trigger if exists profiles_apply_terms on public.profiles;
create trigger profiles_apply_terms
  before insert on public.profiles
  for each row execute function private.profiles_apply_terms();

-- Backfills existing profiles to [p_version] without ever lowering a higher version.
-- Service/migration role only (never touches `auth.users.raw_user_meta_data`).
create or replace function private.backfill_terms_accepted(p_version int)
returns int
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_count int;
begin
  if p_version is null or p_version < 1 then
    raise exception 'invalid';
  end if;

  update public.profiles
     set terms_version = p_version
   where terms_version < p_version;
  get diagnostics v_count = row_count;

  insert into private.terms_acceptance (user_id, terms_version, accepted_at)
  select p.id, p.terms_version, now()
    from public.profiles p
   where p.terms_version >= 1
  on conflict (user_id) do update
    set terms_version = greatest(private.terms_acceptance.terms_version, excluded.terms_version);

  return v_count;
end;
$$;
revoke all on function private.backfill_terms_accepted(int) from public, anon, authenticated;

-- Records that the signed-in caller accepted terms [p_version]. Only raises the version, never
-- lowers it, and rejects versions outside `1..v_max`.
create or replace function public.accept_terms(p_version int)
returns int
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := public._uid();
  v_max constant int := 1;
  v_ver int;
begin
  if p_version is null or p_version < 1 or p_version > v_max then
    raise exception 'invalid';
  end if;

  insert into private.terms_acceptance (user_id, terms_version, accepted_at)
  values (uid, p_version, now())
  on conflict (user_id) do update
    set terms_version = greatest(private.terms_acceptance.terms_version, excluded.terms_version),
        accepted_at = case
          when excluded.terms_version > private.terms_acceptance.terms_version then now()
          else private.terms_acceptance.accepted_at
        end
  returning terms_version into v_ver;

  update public.profiles
     set terms_version = greatest(terms_version, v_ver)
   where id = uid
     and terms_version < v_ver;

  select greatest(v_ver, coalesce((select p.terms_version from public.profiles p where p.id = uid), 0))
    into v_ver;
  return v_ver;
end;
$$;

revoke all on function public.accept_terms(int) from public, anon;
grant execute on function public.accept_terms(int) to authenticated;

select private.backfill_terms_accepted(1);
