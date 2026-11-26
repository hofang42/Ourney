-- Equivalent to SET LOCAL, including when the CLI starts an implicit batch.
select pg_catalog.set_config('lock_timeout', '2s', true);

-- Public share lookups share fixed UTC minute windows across Edge instances.
create table private.share_lookup_buckets (
  scope text not null,
  bucket_key text not null,
  window_start timestamptz not null,
  hits integer not null,
  primary key (window_start, scope, bucket_key)
);
alter table private.share_lookup_buckets enable row level security;
revoke all on table private.share_lookup_buckets from public, anon, authenticated, service_role;

create function private.share_lookup_is_full(
  p_window timestamptz, p_scope text, p_key text, p_limit integer
) returns boolean
language sql stable strict set search_path = ''
as $$
  select exists (
    select from private.share_lookup_buckets
     where window_start = p_window and scope = p_scope and bucket_key = p_key and hits >= p_limit
  );
$$;

create function private.take_share_lookup(
  p_window timestamptz, p_scope text, p_key text, p_limit integer
) returns boolean
language plpgsql strict set search_path = ''
as $$
begin
  -- Skip the hot row lock once a full count is visible. The upsert enforces the cap during races.
  insert into private.share_lookup_buckets as b (scope, bucket_key, window_start, hits)
  select p_scope, p_key, p_window, 1
   where not private.share_lookup_is_full(p_window, p_scope, p_key, p_limit)
  on conflict (window_start, scope, bucket_key) do update
    set hits = b.hits + 1 where b.hits < p_limit;
  return found;
end;
$$;

create function private.purge_share_lookup_buckets(p_batch_size integer) returns void
language sql strict set search_path = ''
as $$
  with expired as (
    select window_start, scope, bucket_key
      from private.share_lookup_buckets
     where window_start < now() - interval '10 minutes'
     order by window_start, scope, bucket_key
     limit p_batch_size
     for update skip locked
  )
  delete from private.share_lookup_buckets b using expired e
   where (b.window_start, b.scope, b.bucket_key) = (e.window_start, e.scope, e.bucket_key);
$$;

revoke all on function private.share_lookup_is_full(timestamptz, text, text, integer),
  private.take_share_lookup(timestamptz, text, text, integer), private.purge_share_lookup_buckets(integer)
  from public, anon, authenticated, service_role;

-- Resolve the link before charging quota. The counter writes are the last work in this RPC.
create function public.lookup_public_journey_for_edge(p_token text, p_ip_hash text) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_is_slug boolean := coalesce(char_length(p_token) <= 40
    and p_token collate "C" ~ '^[a-z0-9]+(-[a-z0-9]+)*-[a-z2-7]{16}$', false);
  v_window timestamptz := date_trunc('minute', now(), 'UTC');
  v_ip_hash text := case when p_ip_hash collate "C" ~ '^[0-9a-f]{64}$' then p_ip_hash end;
  v_journey record;
  v_response jsonb;
begin
  if not v_is_slug and not coalesce(p_token collate "C" ~ '^[a-z0-9]{32,64}$', false) then
    return jsonb_build_object('retry_after', 0, 'journey', null);
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

  if not private.share_lookup_is_full(v_window, 'journey', v_journey.id::text, 120)
     and not coalesce(private.share_lookup_is_full(v_window, 'ip', v_ip_hash, 60), false) then
    v_response := jsonb_build_object('retry_after', 0, 'journey', to_jsonb(v_journey));
    -- Four expired rows per lookup can outpace up to two new rows even with Cron paused.
    perform private.purge_share_lookup_buckets(4);
    if v_ip_hash is null or private.take_share_lookup(v_window, 'ip', v_ip_hash, 60) then
      if private.take_share_lookup(v_window, 'journey', v_journey.id::text, 120) then
        return v_response;
      end if;
    end if;
  end if;
  return jsonb_build_object('retry_after', ceil(extract(epoch from v_window + interval '1 minute' - now()))::integer,
    'journey', null);
end;
$$;
revoke all on function public.lookup_public_journey_for_edge(text, text) from public, anon, authenticated;
grant execute on function public.lookup_public_journey_for_edge(text, text) to service_role;

-- Keep the old app RPC signature, viewer authorization, payload and view counting.
create or replace function public.public_journey_by_token(p_token text) returns json
language plpgsql security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
  v_is_slug boolean := coalesce(char_length(p_token) <= 40
    and p_token collate "C" ~ '^[a-z0-9]+(-[a-z0-9]+)*-[a-z2-7]{16}$', false);
  v_window timestamptz := date_trunc('minute', now(), 'UTC');
  v_limited boolean;
  v_retry integer;
  v_journey uuid;
  v_role text;
  v_view json;
begin
  if not v_is_slug and not coalesce(p_token collate "C" ~ '^[a-z0-9]{32,64}$', false) then
    raise exception 'not_found';
  end if;
  -- Authorize and build the payload from the same snapshot, with a read-only quota check.
  with candidate as materialized (
    select j.id, private.viewer_role(j.id, true) as role
      from public.journeys j
     where j.deleted_at is null and j.public_token is not null
       and ((v_is_slug and j.public_slug = p_token) or (not v_is_slug and j.public_token = p_token))
  ), authorized as materialized (
    select c.id, c.role, private.share_lookup_is_full(v_window, 'user', uid::text, 60) as limited
      from candidate c where c.role is not null
  )
  select a.id, a.role, a.limited,
         case when not a.limited then private.journey_view(a.id, a.role) end
    into v_journey, v_role, v_limited, v_view
    from authorized a;
  if not found then
    raise exception 'not_found';
  end if;
  if not v_limited then
    if v_role <> 'member' then
      perform private.record_view(v_journey, uid::text);
    end if;
    perform private.purge_share_lookup_buckets(4);
    -- A denied upsert raises below and rolls back any view recorded during a race.
    v_limited := not private.take_share_lookup(v_window, 'user', uid::text, 60);
  end if;
  if v_limited then
    v_retry := ceil(extract(epoch from v_window + interval '1 minute' - now()))::integer;
    raise sqlstate 'PGRST' using
      message = '{"code":"P0001","message":"rate_limited"}',
      detail = json_build_object('status', 429,
        'headers', json_build_object('Retry-After', v_retry::text, 'Cache-Control', 'no-store'))::text;
  end if;
  return v_view;
end;
$$;

create extension if not exists pg_cron with schema pg_catalog;
grant usage on schema cron to postgres;
grant select on cron.job to postgres;
grant select, delete on cron.job_run_details to postgres;
select cron.schedule('purge-share-lookup-buckets', '*/5 * * * *', $job$
  select private.purge_share_lookup_buckets(5000);
$job$);
select cron.schedule('prune-share-lookup-cron-history', '19 3 * * *', $job$
  delete from cron.job_run_details
   where jobid in (select jobid from cron.job
                    where jobname in ('purge-share-lookup-buckets', 'prune-share-lookup-cron-history'))
     and end_time < now() - interval '7 days';
$job$);
