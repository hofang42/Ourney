-- 0036_supabase_2_fixes:
--   F-27: Align `public._journeys_dying_with(p_user)` with `public._leave_journey(p_journey, p_user)`
--         by requiring surviving active co-members to have a non-deleted profile (`p.deleted_at is null`).
--         Previously, if a group owner deleted their account when the only other active member had a
--         soft-deleted profile (`profiles.deleted_at is not null`), `_journeys_dying_with` treated the
--         journey as surviving (skipping Storage purge queueing for co-member check-ins and conversation
--         media), while `_leave_journey` found no live `next_owner` and left `owner_id = p_user`, causing
--         `profiles ON DELETE CASCADE` to hard-delete the journey and orphan its Storage objects.
--   F-28: Include SQL-computed `follow_count` (`count(distinct f.owner_id)::int`) in the `journey`
--         payload returned by `public.lookup_public_journey_for_edge(p_token, p_ip_hash)` when
--         `show_counts` is enabled, avoiding PostgREST `max_rows = 1000` truncation on popular
--         shared journeys (paired with 1,000-row `.range()` check-in pagination in `public-journey`).

select pg_catalog.set_config('lock_timeout', '2s', true);

-- ===========================================================================
-- 1. F-27: Align `_journeys_dying_with` co-member liveness with `_leave_journey`
-- ===========================================================================
create or replace function public._journeys_dying_with(p_user uuid) returns setof uuid
language sql
stable
security definer
set search_path = ''
as $$
  select j.id
    from public.journeys j
   where j.owner_id = p_user
     and not exists (
       select 1
         from public.memberships m
         join public.profiles p on p.id = m.user_id and p.deleted_at is null
        where m.journey_id = j.id
          and m.user_id <> p_user
          and m.status = 'active'
          and m.deleted_at is null
     );
$$;

revoke all on function public._journeys_dying_with(uuid) from public, anon, authenticated;

-- ===========================================================================
-- 2. F-28: Compute `follow_count` in SQL inside `lookup_public_journey_for_edge`
-- ===========================================================================
create or replace function public.lookup_public_journey_for_edge(p_token text, p_ip_hash text) returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_is_slug boolean := coalesce(char_length(p_token) <= 40
    and p_token collate "C" ~ '^[a-z0-9]+(-[a-z0-9]+)*-[a-z2-7]{16}$', false);
  v_window timestamptz := date_trunc('minute', now(), 'UTC');
  v_ip_key text := coalesce(case when p_ip_hash collate "C" ~ '^[0-9a-f]{64}$' then p_ip_hash end, 'fallback');
  v_journey record;
  v_retry integer := greatest(1, ceil(extract(epoch from v_window + interval '1 minute' - now()))::integer);
begin
  if not v_is_slug and not coalesce(p_token collate "C" ~ '^[a-z0-9]{32,64}$', false) then
    return jsonb_build_object('retry_after', 0, 'journey', null);
  end if;

  -- F-20: charge the per-IP (or shared fallback) bucket on every well-formed lookup, including 404 misses,
  -- and check before resolving so exhausted IPs cannot probe 404s or use 429-vs-404 as an existence oracle.
  if private.share_lookup_is_full(v_window, 'ip', v_ip_key, 60) then
    return jsonb_build_object('retry_after', v_retry, 'journey', null);
  end if;
  perform private.purge_share_lookup_buckets(6);
  if not private.take_share_lookup(v_window, 'ip', v_ip_key, 60) then
    return jsonb_build_object('retry_after', v_retry, 'journey', null);
  end if;

  select j.id, j.owner_id, j.public_token, j.kind, j.template_id, j.title, j.emoji, j.metric_name,
         j.metric_unit, j.start_date, j.duration_days, j.timezone, j.status, j.origin, j.layout,
         j.color, j.cover, j.story_title, j.story_intro, j.story_lessons, j.cover_checkin_id, j.show_counts
    into v_journey
    from public.journeys j
   where j.deleted_at is null and j.public_token is not null
     and ((v_is_slug and j.public_slug = p_token) or (not v_is_slug and j.public_token = p_token));
  if not found then
    return jsonb_build_object('retry_after', 0, 'journey', null);
  end if;

  -- F-20: cap each (IP/fallback, journey) pair at 30/min while raising the per-journey global ceiling
  -- to 600/min so 1-2 IPs (or missing-IP subrequests) cannot exhaust a shared journey's global quota.
  if not private.share_lookup_is_full(v_window, 'ip_journey', v_ip_key || ':' || v_journey.id::text, 30)
     and not private.share_lookup_is_full(v_window, 'journey', v_journey.id::text, 600) then
    if private.take_share_lookup(v_window, 'ip_journey', v_ip_key || ':' || v_journey.id::text, 30) then
      if private.take_share_lookup(v_window, 'journey', v_journey.id::text, 600) then
        return jsonb_build_object(
          'retry_after', 0,
          'journey', to_jsonb(v_journey) || jsonb_build_object(
            'follow_count',
            case when v_journey.show_counts then (
              select count(distinct f.owner_id)::int
                from public.journeys f
               where f.followed_from = v_journey.id
                 and f.deleted_at is null
            ) else 0 end
          )
        );
      end if;
    end if;
  end if;

  return jsonb_build_object('retry_after', v_retry, 'journey', null);
end;
$$;

revoke all on function public.lookup_public_journey_for_edge(text, text) from public, anon, authenticated;
grant execute on function public.lookup_public_journey_for_edge(text, text) to service_role;
