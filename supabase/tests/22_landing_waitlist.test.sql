-- 0022_landing_waitlist: landing beta waitlist (private tables, service-role RPCs).
begin;
create extension if not exists pgtap with schema extensions;
select plan(16);

select has_table('private', 'waitlist', 'waitlist table exists in the private schema');
select has_table('private', 'waitlist_attempts', 'waitlist_attempts table exists in the private schema');

select is(
  (select bool_and(relrowsecurity) from pg_class
    where oid in ('private.waitlist'::regclass, 'private.waitlist_attempts'::regclass)),
  true,
  'RLS is enabled on both waitlist tables'
);
select is(
  (select count(*)::int from pg_policy
    where polrelid in ('private.waitlist'::regclass, 'private.waitlist_attempts'::regclass)),
  0,
  'waitlist tables have no policies (service role only)'
);
select is(
  has_table_privilege('anon', 'private.waitlist', 'select')
    or has_table_privilege('authenticated', 'private.waitlist', 'select')
    or has_table_privilege('anon', 'private.waitlist', 'insert')
    or has_table_privilege('authenticated', 'private.waitlist', 'insert'),
  false,
  'anon and authenticated have no grants on the waitlist'
);
select is(
  (select bool_or(
     has_function_privilege('anon', f, 'execute') or has_function_privilege('authenticated', f, 'execute'))
     from unnest(array[
       'public.waitlist_signup(text,text,text[],text,text)',
       'public.waitlist_mark_confirmation(uuid,text)'
     ]) as f),
  false,
  'waitlist RPCs are not executable by anon or authenticated'
);
select ok(
  has_function_privilege('service_role', 'public.waitlist_signup(text,text,text[],text,text)', 'execute')
  and has_function_privilege('service_role', 'public.waitlist_mark_confirmation(uuid,text)', 'execute'),
  'service_role can execute the waitlist RPCs'
);

select is(
  public.waitlist_signup('  Test.User@Example.com ', 'en', array['ios'], 'landing', null) ->> 'status',
  'created',
  'a new email is created'
);
select is(
  (select email || '|' || lang || '|' || array_to_string(platforms, ',') || '|' || source
     from private.waitlist where email = 'test.user@example.com'),
  'test.user@example.com|en|ios|landing',
  'email is trimmed and lower-cased; lang, platforms and source are stored'
);
select is(
  public.waitlist_signup('TEST.USER@example.com', 'vi', null, null, null) ->> 'status',
  'exists',
  'the same email in another case is reported as existing'
);
select is(
  public.waitlist_signup('not-an-email', 'vi', null, null, null) ->> 'status',
  'invalid',
  'a malformed email is rejected'
);
select is(
  (public.waitlist_signup('plat@example.com', 'xx', array['ios', 'bogus', 'ios'], null, null) ->> 'status')
    || '|' || (select lang || '|' || array_to_string(platforms, ',') from private.waitlist where email = 'plat@example.com'),
  'created|vi|ios',
  'unknown platforms and languages are dropped, duplicates collapsed'
);

-- Rate limit: 5 attempts per IP hash per hour, the 6th is refused.
select is(
  (select array_agg(public.waitlist_signup('rl' || i || '@example.com', 'vi', null, null, repeat('a', 64)) ->> 'status' order by i)
     from generate_series(1, 6) as i),
  array['created', 'created', 'created', 'created', 'created', 'rate_limited'],
  'the sixth attempt within an hour from the same IP hash is rate limited'
);
select is(
  public.waitlist_signup('other-ip@example.com', 'vi', null, null, repeat('b', 64)) ->> 'status',
  'created',
  'another IP hash is not affected'
);

do $$ begin
  perform public.waitlist_mark_confirmation(
    (select id from private.waitlist where email = 'test.user@example.com'), null);
end $$;
select ok(
  (select confirmation_sent_at is not null and confirmation_error is null
     from private.waitlist where email = 'test.user@example.com'),
  'a successful send stamps confirmation_sent_at'
);

do $$ begin
  perform public.waitlist_mark_confirmation(
    (select id from private.waitlist where email = 'plat@example.com'), repeat('x', 900));
end $$;
select is(
  (select length(confirmation_error) from private.waitlist where email = 'plat@example.com'),
  500,
  'a send error is stored truncated to 500 characters'
);

select * from finish();
rollback;
