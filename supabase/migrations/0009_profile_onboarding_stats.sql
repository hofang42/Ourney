-- 0009: onboarding quiz answers + profile stats RPC (v2 backend parity).
-- Idempotent: safe to re-run. No new tables (RLS on profiles already covers the new column).

-- ---------------------------------------------------------------------------
-- profiles.onboarding_quiz: the 3-question onboarding answers
-- {"goal": "...", "who": "solo|group|couple", "reminder": "HH:MM"}. Written by the owner only
-- (existing profiles_update policy: id = auth.uid()); readable like the rest of the profile row.
-- ---------------------------------------------------------------------------
alter table public.profiles add column if not exists onboarding_quiz jsonb;

do $$
begin
  if not exists (
    select 1 from pg_constraint
     where conrelid = 'public.profiles'::regclass and conname = 'profiles_onboarding_quiz_shape'
  ) then
    alter table public.profiles add constraint profiles_onboarding_quiz_shape
      check (onboarding_quiz is null
             or (jsonb_typeof(onboarding_quiz) = 'object' and pg_column_size(onboarding_quiz) <= 512));
  end if;
end $$;

grant update (onboarding_quiz) on public.profiles to authenticated;

-- ---------------------------------------------------------------------------
-- profile_stats(): numbers for the profile screen. SECURITY INVOKER, so RLS decides what the
-- caller may read (own check-ins / own journeys). Badges are derived client-side from these.
-- ---------------------------------------------------------------------------
create or replace function public.profile_stats()
returns table (
  total_snaps int,
  longest_streak int,
  current_streak int,
  journeys_completed int,
  journeys_total int
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  uid uuid := public._uid();
begin
  return query
  select
    (select count(*)::int from public.check_ins c
      where c.user_id = uid and c.deleted_at is null and not c.hidden_by_leave),
    coalesce(max(s.best_streak), 0)::int,
    coalesce(max(s.current_streak), 0)::int,
    (count(*) filter (where j.status = 'ended'))::int,
    count(*)::int
  from public.memberships m
  join public.journeys j on j.id = m.journey_id and j.deleted_at is null
  cross join lateral public.journey_streak(j.id, uid) s
  where m.user_id = uid and m.status = 'active' and m.deleted_at is null;
end;
$$;

revoke all on function public.profile_stats() from public, anon;
grant execute on function public.profile_stats() to authenticated;
