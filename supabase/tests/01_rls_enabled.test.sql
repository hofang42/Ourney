-- Security baseline: RLS everywhere, fixed search_path, no anon access, private bucket.
begin;
create extension if not exists pgtap with schema extensions;
select plan(15);

select tables_are(
  'public',
  array['profiles', 'journeys', 'memberships', 'check_ins', 'reactions', 'blocks', 'reports', 'moderation_queue'],
  'public schema contains exactly the contract tables'
);

select is(
  (select count(*)::int
     from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relkind in ('r', 'p') and not c.relrowsecurity),
  0,
  'RLS is enabled on every public table'
);

select is(
  (select count(*)::int
     from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relkind in ('r', 'p')
      and not exists (select 1 from pg_policy p where p.polrelid = c.oid)),
  0,
  'every public table has at least one policy'
);

select is(
  (select relrowsecurity from pg_class where oid = 'storage.objects'::regclass),
  true,
  'RLS is enabled on storage.objects'
);

select is(
  (select count(*)::int
     from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.prosecdef
      and not coalesce(exists (select 1 from unnest(p.proconfig) c where c like 'search_path=%'), false)),
  0,
  'every SECURITY DEFINER function pins search_path'
);

select is(
  (select count(*)::int
     from information_schema.role_table_grants
    where table_schema = 'public' and grantee = 'anon'),
  0,
  'anon has no table privileges in public'
);

select is(
  (select count(*)::int
     from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and has_function_privilege('anon', p.oid, 'execute')),
  0,
  'anon cannot execute any public function'
);

select ok(
  not has_function_privilege('authenticated', 'public.purge_account_data(uuid)', 'execute')
  and not has_function_privilege('authenticated', 'public.account_media_paths(uuid)', 'execute'),
  'account purge helpers are service_role only'
);

select is(
  (select count(*)::int
     from information_schema.role_table_grants
    where table_schema = 'public' and table_name = 'moderation_queue'
      and grantee in ('anon', 'authenticated')),
  0,
  'moderation_queue is not exposed to API roles'
);

select ok(
  not has_table_privilege('authenticated', 'public.blocks', 'insert')
  and not has_table_privilege('authenticated', 'public.reports', 'insert')
  and not has_table_privilege('authenticated', 'public.journeys', 'insert')
  and not has_table_privilege('authenticated', 'public.memberships', 'insert'),
  'blocks/reports/journeys/memberships are written only through RPCs'
);

select ok(
  not has_table_privilege('authenticated', 'public.check_ins', 'delete')
  and not has_table_privilege('authenticated', 'public.journeys', 'delete'),
  'no hard deletes from the API (soft delete via deleted_at)'
);

select is(
  (select count(*)::int
     from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname like '\_%'
      and has_function_privilege('authenticated', p.oid, 'execute')),
  0,
  'internal _helpers are not callable by authenticated'
);

select ok(
  has_function_privilege('authenticated', 'public.join_by_code(text)', 'execute'),
  'authenticated can call join_by_code'
);

select is(
  (select public from storage.buckets where id = 'media'),
  false,
  'storage bucket media is private'
);

select is(
  (select count(*)::int from storage.buckets where id = 'media'),
  1,
  'storage bucket media exists'
);

select * from finish();
rollback;
