-- Public share lookups share fixed UTC minute windows across Edge instances.
create table private.share_lookup_buckets (
  scope text not null,
  bucket_key text not null,
  window_start timestamptz not null,
  hits integer not null,
  primary key (scope, bucket_key)
);
create index share_lookup_bucket_expiry on private.share_lookup_buckets (window_start);
alter table private.share_lookup_buckets enable row level security;
revoke all on table private.share_lookup_buckets from public, anon, authenticated, service_role;

create function private.take_share_lookup(p_scope text, p_key text, p_limit integer) returns integer
language plpgsql set search_path = ''
as $$
declare
  v_window timestamptz := date_trunc('minute', now(), 'UTC');
begin
  -- Once full, skip the write path (and the hot row lock) for the rest of this window.
  if not exists (select from private.share_lookup_buckets b
                  where b.scope = p_scope and b.bucket_key = p_key
                    and b.window_start = v_window and b.hits >= p_limit) then
    insert into private.share_lookup_buckets as b (scope, bucket_key, window_start, hits)
    values (p_scope, p_key, v_window, 1)
    on conflict (scope, bucket_key) do update
      set window_start = excluded.window_start,
          hits = case when b.window_start = excluded.window_start then b.hits + 1 else 1 end
      where b.window_start < excluded.window_start
         or (b.window_start = excluded.window_start and b.hits < p_limit);
    if found then
      return 0;
    end if;
  end if;
  return ceil(extract(epoch from v_window + interval '1 minute' - now()))::integer;
end;
$$;
revoke all on function private.take_share_lookup(text, text, integer)
  from public, anon, authenticated, service_role;

-- Replaces the Edge function's first read, so throttling adds no HTTP round trip.
-- A well-formed miss uses the IP quota without creating a credential-specific bucket.
create function public.lookup_public_journey_for_edge(p_token text, p_ip_hash text) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_is_slug boolean := coalesce(char_length(p_token) <= 40
    and p_token collate "C" ~ '^[a-z0-9]+(-[a-z0-9]+)*-[a-z2-7]{16}$', false);
  v_retry integer;
  v_journey record;
begin
  if not v_is_slug and not coalesce(p_token collate "C" ~ '^[a-z0-9]{32,64}$', false) then
    return jsonb_build_object('retry_after', 0, 'journey', null);
  end if;
  if p_ip_hash is not null and p_ip_hash collate "C" !~ '^[0-9a-f]{64}$' then
    raise exception 'invalid_ip_hash';
  end if;

  v_retry := private.take_share_lookup('ip', coalesce(p_ip_hash, 'unknown'),
    case when p_ip_hash is null then 120 else 60 end);
  if v_retry > 0 then
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

  v_retry := private.take_share_lookup('journey', v_journey.id::text, 120);
  if v_retry > 0 then
    return jsonb_build_object('retry_after', v_retry, 'journey', null);
  end if;
  return jsonb_build_object('retry_after', 0, 'journey', to_jsonb(v_journey));
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
  v_retry integer;
  v_journey uuid;
  v_role text;
  v_view json;
begin
  if not v_is_slug and not coalesce(p_token collate "C" ~ '^[a-z0-9]{32,64}$', false) then
    raise exception 'not_found';
  end if;
  v_retry := private.take_share_lookup('user', uid::text, 60);
  if v_retry > 0 then
    raise sqlstate 'PGRST' using
      message = '{"code":"P0001","message":"rate_limited"}',
      detail = json_build_object('status', 429,
        'headers', json_build_object('Retry-After', v_retry::text, 'Cache-Control', 'no-store'))::text;
  end if;

  -- Use the credential, viewer role, and payload from the same snapshot.
  if v_is_slug then
    select j.id, r.role, private.journey_view(j.id, r.role)
      into v_journey, v_role, v_view
      from public.journeys j
      cross join lateral (select private.viewer_role(j.id, true) as role) r
     where j.public_slug = p_token and j.public_token is not null
       and j.deleted_at is null and r.role is not null;
  else
    select j.id, r.role, private.journey_view(j.id, r.role)
      into v_journey, v_role, v_view
      from public.journeys j
      cross join lateral (select private.viewer_role(j.id, true) as role) r
     where j.public_token = p_token and j.deleted_at is null and r.role is not null;
  end if;
  -- Misses keep raising the legacy error, which rolls back the provisional debit.
  if v_role is null then
    raise exception 'not_found';
  end if;
  if v_role <> 'member' then
    perform private.record_view(v_journey, uid::text);
  end if;
  return v_view;
end;
$$;

create extension if not exists pg_cron with schema pg_catalog;
grant usage on schema cron to postgres;
grant select on cron.job to postgres;
grant select, delete on cron.job_run_details to postgres;
select cron.schedule('purge-share-lookup-buckets', '*/5 * * * *', $job$
  with expired_buckets as (
    delete from private.share_lookup_buckets where window_start < now() - interval '10 minutes'
  )
  delete from cron.job_run_details
   where jobid = (select jobid from cron.job where jobname = 'purge-share-lookup-buckets')
     and end_time < now() - interval '7 days';
$job$);
