-- 0014_multi_photo_per_day:
--   SRS FR-C7/FR-C8, SDS §7.1 (owner decision 2026-11-11): several check-ins per member per day.
--   Posting again the same day adds a photo; it no longer replaces the day's row.
--   * Drops `check_ins_unique_day unique (journey_id, user_id, local_date)` (0001). Clients now
--     upsert `check_ins` on the primary key `id` (each photo is its own row).
--   * Streak still counts a day once: `streak_core` (0001) and `group_streak` (0006) already work
--     on distinct dates, so `journey_streak` needs no change.
--   * Redefines `group_today` (body from 0005) so it returns one row per member: the member's
--     latest check-in of today (FR-D3 "ảnh mới nhất của từng người") instead of one row per
--     check-in. Signature, grants and the L7 report rule are unchanged.
--   Not in this migration (still pending in docs/contracts/schema.md): per-day cover photo and a
--   delete-proof `checkin_days` streak input (SDS Q11).
-- Idempotent (drop if exists / create or replace). Tests: supabase/tests/14_multi_photo_per_day.test.sql.

alter table public.check_ins drop constraint if exists check_ins_unique_day;

-- Timeline reads (journey, member, day) without the old unique index behind them.
create index if not exists check_ins_journey_user_date_idx
  on public.check_ins (journey_id, user_id, local_date);

create or replace function public.group_today(journey uuid)
returns table (
  user_id uuid,
  username text,
  display_name text,
  avatar_path text,
  role public.member_role,
  checked_in boolean,
  checkin_id uuid,
  thumb_path text,
  captured_at timestamptz,
  current_streak int
)
language plpgsql
stable
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  v_tz text;
  v_today date;
begin
  perform public._uid();
  if not private.is_member(journey) then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  select j.timezone into v_tz from public.journeys j where j.id = journey;
  v_today := public.local_date(now(), v_tz);

  return query
  select m.user_id, p.username, p.display_name, p.avatar_path, m.role,
         (c.id is not null),
         case when r.hidden then null else c.id end,
         case when r.hidden then null else c.thumb_path end,
         case when r.hidden then null else c.captured_at end,
         coalesce(s.current_streak, 0)
    from public.memberships m
    join public.profiles p on p.id = m.user_id
    left join lateral (
      select c2.id, c2.thumb_path, c2.captured_at
        from public.check_ins c2
       where c2.journey_id = m.journey_id and c2.user_id = m.user_id
         and c2.local_date = v_today and c2.deleted_at is null
       order by c2.captured_at desc, c2.id desc
       limit 1
    ) c on true
    left join lateral (select c.id is not null and private.has_reported(c.id) as hidden) r on true
    left join lateral public.journey_streak(m.journey_id, m.user_id, v_today) s on true
   where m.journey_id = journey and m.status = 'active' and m.deleted_at is null
     and not private.is_blocked_pair(m.user_id)
   order by m.joined_at, m.user_id;
end;
$$;
