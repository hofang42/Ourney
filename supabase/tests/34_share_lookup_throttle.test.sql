begin;
create extension if not exists pgtap with schema extensions;
select plan(36);

select ok(
  has_function_privilege('service_role', 'public.lookup_public_journey_for_edge(text,text)', 'execute')
  and not has_function_privilege('anon', 'public.lookup_public_journey_for_edge(text,text)', 'execute')
  and not has_function_privilege('authenticated', 'public.lookup_public_journey_for_edge(text,text)', 'execute'),
  'only the Edge service role can call the anonymous lookup RPC'
);
select ok(
  not has_table_privilege('anon', 'private.share_lookup_buckets', 'select')
  and not has_table_privilege('authenticated', 'private.share_lookup_buckets', 'update')
  and not has_table_privilege('service_role', 'private.share_lookup_buckets', 'update')
  and not has_function_privilege('service_role', 'private.take_share_lookup(timestamptz,text,text,integer)', 'execute')
  and not has_function_privilege('authenticated', 'private.share_lookup_is_full(timestamptz,text,text,integer)', 'execute')
  and not has_function_privilege('service_role', 'private.purge_share_lookup_buckets(integer)', 'execute'),
  'callers cannot inspect or modify the rate limiter directly'
);
select ok(exists (select from cron.job where jobname = 'purge-share-lookup-buckets' and active),
  'expired buckets have a scheduled cleanup');
select ok(exists (select from cron.job where jobname = 'prune-share-lookup-cron-history' and active),
  'Cron history is pruned separately');

insert into auth.users (id, email) values
  ('34000000-0000-4000-8000-000000000001', 'throttle1@example.test'),
  ('34000000-0000-4000-8000-000000000002', 'throttle2@example.test');
insert into public.profiles (id, username, display_name) values
  ('34000000-0000-4000-8000-000000000001', 'throttleuser1', 'Throttle owner'),
  ('34000000-0000-4000-8000-000000000002', 'throttleuser2', 'Throttle viewer');

set local role authenticated;
set local request.jwt.claims = '{"sub":"34000000-0000-4000-8000-000000000001","role":"authenticated"}';
select public_token as legacy, public_slug as slug from public.create_journey(
  'b3400000-0000-4000-8000-000000000001', 'solo', 'travel', 'Throttle journey',
  'x', null, null, false, current_date, 7, 'UTC', p_visibility => 'link'
) \gset
select public_slug as other_slug from public.create_journey(
  'b3400000-0000-4000-8000-000000000002', 'solo', 'travel', 'Other throttle journey',
  'x', null, null, false, current_date, 7, 'UTC', p_visibility => 'link'
) \gset
reset role;

set local role service_role;
select is(public.lookup_public_journey_for_edge(:'legacy', repeat('a', 64))->'journey'->>'title',
  'Throttle journey', 'the Edge RPC still resolves an opaque token');
select is(public.lookup_public_journey_for_edge(:'slug', repeat('b', 64))->'journey'->>'public_token',
  :'legacy', 'the readable alias resolves the same journey and retains its internal view key');
select is(public.lookup_public_journey_for_edge(repeat('z', 40), repeat('a', 64)),
  '{"journey": null, "retry_after": 0}'::jsonb, 'an unknown link returns a miss');
select is(public.lookup_public_journey_for_edge('invalid', repeat('e', 64)),
  '{"journey": null, "retry_after": 0}'::jsonb, 'malformed credentials return a miss');
reset role;

select is((select hits from private.share_lookup_buckets where scope = 'ip' and bucket_key = repeat('a', 64)),
  1, 'a well-formed miss does not use the IP budget');
select is((select hits from private.share_lookup_buckets where scope = 'journey'),
  2, 'both aliases share the same journey budget and misses do not create journey buckets');
select ok(not exists (select from private.share_lookup_buckets where bucket_key = repeat('e', 64)),
  'malformed credentials never allocate buckets');

update private.share_lookup_buckets set hits = 60 where scope = 'ip' and bucket_key = repeat('a', 64);
set local role service_role;
select ok((public.lookup_public_journey_for_edge(:'slug', repeat('a', 64))->>'retry_after')::int between 1 and 60,
  'the IP limit applies across credentials and returns a bounded retry time');
select is(public.lookup_public_journey_for_edge(repeat('z', 40), repeat('a', 64)),
  '{"journey": null, "retry_after": 0}'::jsonb, 'an unknown link remains a miss after IP budget exhaustion');
select is(public.lookup_public_journey_for_edge(:'slug', repeat('b', 64))->'journey'->>'title',
  'Throttle journey', 'a different IP can still open the same link');
reset role;
select is((select hits from private.share_lookup_buckets where scope = 'journey'),
  3, 'requests blocked by their IP quota do not use the journey budget');

update private.share_lookup_buckets set hits = 120 where scope = 'journey';
set local role service_role;
select ok((public.lookup_public_journey_for_edge(:'legacy', repeat('c', 64))->>'retry_after')::int between 1 and 60,
  'the journey cap holds for a new IP and the legacy alias');
select ok((public.lookup_public_journey_for_edge(:'slug', null)->>'retry_after')::int between 1 and 60,
  'the journey cap also holds when the gateway supplies no usable IP');
select is(public.lookup_public_journey_for_edge(repeat('z', 40), null),
  '{"journey": null, "retry_after": 0}'::jsonb, 'a miss without an IP stays a miss');
select is(public.lookup_public_journey_for_edge(:'other_slug', null)->'journey'->>'title',
  'Other throttle journey', 'the exhausted journey does not block another link without an IP');
select is(public.lookup_public_journey_for_edge(:'other_slug', 'invalid')->'journey'->>'title',
  'Other throttle journey', 'an invalid IP digest also skips the IP quota');
reset role;
select is((select count(*) from private.share_lookup_buckets where scope = 'ip'), 2::bigint,
  'only successful lookups with a usable IP have created IP buckets');

update private.share_lookup_buckets set window_start = window_start - interval '1 minute';
set local role service_role;
select is(public.lookup_public_journey_for_edge(:'slug', repeat('a', 64))->>'retry_after', '0',
  'an exhausted IP and journey get a fresh budget in the next fixed window');
reset role;
select is((select hits from private.share_lookup_buckets
  where scope = 'journey' and window_start = date_trunc('minute', now(), 'UTC')), 1,
  'the current minute has its own count');
select is((select hits from private.share_lookup_buckets where scope = 'journey'
  and bucket_key = 'b3400000-0000-4000-8000-000000000001' and window_start < date_trunc('minute', now(), 'UTC')), 120,
  'the previous minute remains available for cleanup');

insert into private.share_lookup_buckets (scope, bucket_key, window_start, hits)
select 'ip', repeat('d', 60) || lpad(i::text, 4, '0'), now() - interval '11 minutes', 1
from generate_series(1, 5) as i;
select private.purge_share_lookup_buckets(1);
select is((select count(*) from private.share_lookup_buckets where bucket_key like repeat('d', 60) || '%'),
  4::bigint, 'cleanup respects the batch size');
set local role service_role;
select is(public.lookup_public_journey_for_edge(:'slug', null)->>'retry_after', '0',
  'the loader can still open a link without Cron');
reset role;
select ok(not exists (select from private.share_lookup_buckets where bucket_key like repeat('d', 60) || '%'),
  'a successful lookup purges a bounded batch independently of Cron');

insert into private.share_lookup_buckets (scope, bucket_key, window_start, hits)
values ('ip', repeat('d', 64), now() - interval '11 minutes', 1);
do $$ begin
  execute (select command from cron.job where jobname = 'purge-share-lookup-buckets');
end $$;
select ok(not exists (select from private.share_lookup_buckets where bucket_key = repeat('d', 64)),
  'cleanup deletes expired keys');
select ok(exists (select from private.share_lookup_buckets where scope = 'journey'),
  'cleanup preserves current keys');

set local role authenticated;
select is(public.public_journey_by_token(:'legacy')->>'role', 'member',
  'the existing signed-in RPC still opens an opaque token');
select throws_ok($$ select public.public_journey_by_token(repeat('z', 40)) $$,
  'P0001', 'not_found', 'an unknown token still raises the legacy error');
reset role;
select is((select hits from private.share_lookup_buckets where scope = 'user'), 1,
  'an authenticated miss does not consume the successful lookup budget');
update private.share_lookup_buckets set hits = 60 where scope = 'user';
set local role authenticated;
select throws_ok(format('select public.public_journey_by_token(%L)', :'slug'), 'PGRST',
  '{"code":"P0001","message":"rate_limited"}',
  'the same signed-in account is throttled across both token formats');
select throws_ok($$ select public.public_journey_by_token(repeat('z', 40)) $$,
  'P0001', 'not_found', 'an authenticated miss stays on the cheap path after budget exhaustion');
set local request.jwt.claims = '{"sub":"34000000-0000-4000-8000-000000000002","role":"authenticated"}';
select is(public.public_journey_by_token(:'slug')->>'role', 'stranger',
  'another signed-in account retains its own quota and can open the readable link');

reset role;
update public.journeys set public_token = null, visibility = 'private'
  where id = 'b3400000-0000-4000-8000-000000000001';
set local role service_role;
select is(public.lookup_public_journey_for_edge(:'slug', repeat('b', 64)),
  '{"journey": null, "retry_after": 0}'::jsonb, 'the Edge RPC returns a miss after revocation');
reset role;
select * from finish();
rollback;
