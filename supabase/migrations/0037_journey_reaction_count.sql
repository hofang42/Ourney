-- Journey Wrapped reads one scalar across all check-ins visible to the caller.
-- Use invoker security so the journeys, check_ins and reactions RLS policies
-- continue to enforce membership, reports and blocks.

create function public.journey_reaction_count(p_journey uuid) returns bigint
language sql
stable
security invoker
set search_path = ''
as $$
  select count(*)
    from public.journeys j
    join public.check_ins c on c.journey_id = j.id
    join public.reactions r on r.checkin_id = c.id
   where j.id = p_journey
     and j.deleted_at is null
     and c.deleted_at is null
     and c.moderated_at is null
     and r.deleted_at is null;
$$;

revoke all on function public.journey_reaction_count(uuid) from public, anon;
grant execute on function public.journey_reaction_count(uuid) to authenticated;
