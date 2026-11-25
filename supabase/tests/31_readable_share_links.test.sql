begin;
create extension if not exists pgtap with schema extensions;
select plan(31);

create schema tests;
grant usage on schema tests to authenticated;
create function tests.u(n int) returns uuid language sql immutable as $$
  select format('31000000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid
$$;
create function tests.j(n int) returns uuid language sql immutable as $$
  select format('b3100000-0000-4000-8000-%s', lpad(n::text, 12, '0'))::uuid
$$;
create function tests.as_user(u uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', u, 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);
end;
$$;
grant execute on all functions in schema tests to authenticated;

insert into auth.users (id, email)
select tests.u(n), format('sharelink%s@example.test', n) from generate_series(1, 2) n;
insert into public.profiles (id, username, display_name)
select tests.u(n), 'sharelinkuser' || n, 'Share link user ' || n from generate_series(1, 2) n;

select ok(
  has_function_privilege('authenticated', 'public.set_readable_public_link(uuid,boolean,boolean,text)', 'execute')
  and not has_function_privilege('anon', 'public.set_readable_public_link(uuid,boolean,boolean,text)', 'execute'),
  'only authenticated users can call the new management RPC'
);
select ok(not has_column_privilege('authenticated', 'public.journeys', 'public_slug', 'UPDATE'),
  'authenticated users cannot change a slug directly');

do $$ begin perform tests.as_user(tests.u(1)); end $$;
select public_token as create_token, public_slug as create_slug
  from public.create_journey(tests.j(1), 'solo', 'travel', '7 Ngày Đà Lạt', 'x', null, null,
    false, current_date, 7, 'UTC', p_visibility => 'link')
\gset
select matches(:'create_token', '^[a-z0-9]{40}$', 'create_journey still returns a legacy token');
select matches(:'create_slug', '^journey-[a-z2-7]{16}$', 'link visibility at creation issues a neutral slug');
select throws_ok($$ select public.set_readable_public_link(tests.j(1), true, true, '7 Ngày Đà Lạt') $$,
  'P0001', 'invalid', 'active journeys still cannot rotate a link');

do $$
begin
  perform public.create_journey(tests.j(2), 'solo', 'travel', normalize('7 Ngày, Đà Lạt!', NFD),
    'x', null, null, false, current_date - 1, 7, 'UTC');
  perform public.create_journey(tests.j(3), 'solo', 'travel', '7 Ngày, Đà Lạt!',
    'x', null, null, false, current_date - 1, 7, 'UTC');
  perform public.create_journey(tests.j(4), 'solo', 'weight_loss', 'Cân nặng 78 kg',
    'x', 'Weight', 'kg', false, current_date - 1, 7, 'UTC');
  perform public.create_journey(tests.j(5), 'solo', 'custom', 'Số đo 126 cm',
    'x', 'Waist', 'cm', false, current_date - 1, 7, 'UTC');
  perform public.create_journey(tests.j(6), 'solo', 'custom', 'A long title without Vietnamese accents',
    'x', null, null, false, current_date - 1, 7, 'UTC');
  perform public.create_journey(tests.j(7), 'solo', 'custom', '日本語',
    'x', null, null, false, current_date - 1, 7, 'UTC');
  perform public.create_journey(tests.j(8), 'group', 'travel', '7 Ngày Đà Lạt',
    'x', null, null, false, current_date - 1, 7, 'UTC');
  update public.memberships set hide_metric = true
    where user_id = tests.u(1) and journey_id = tests.j(5);
  for n in 2..8 loop
    perform public.end_journey(tests.j(n));
  end loop;
end;
$$;

select public.set_readable_public_link(tests.j(2), true, false,
  normalize('7 Ngày, Đà Lạt!', NFD)) as slug \gset
select public_token as legacy from public.journeys where id = tests.j(2) \gset
select matches(:'slug', '^7-ngay-da-lat-[a-z2-7]{16}$',
  'an approved Vietnamese title folds lowercase letters, accents and punctuation');
select is(public.set_readable_public_link(tests.j(2), true), :'slug',
  'enabling an active link again preserves its slug');
select is(public.set_public_link(tests.j(2), true), :'legacy',
  'the previous setter still returns the legacy token');
select is(public.journey_share_state(tests.j(2))->>'public_slug', :'slug',
  'share settings provide the readable slug');
select is(public.journey_share_state(tests.j(2))->>'public_token', :'legacy',
  'share settings preserve the legacy API result');
select isnt(public.set_readable_public_link(tests.j(3), true, false, '7 Ngày, Đà Lạt!'), :'slug',
  'the same title on another journey gets a different slug');
select matches(public.set_readable_public_link(tests.j(4), true, false, 'Cân nặng 78 kg'),
  '^journey-[a-z2-7]{16}$', 'a weight journey keeps numbers in its title out of the URL');
select matches(public.set_readable_public_link(tests.j(5), true, false, 'Số đo 126 cm'),
  '^journey-[a-z2-7]{16}$', 'a hidden owner metric forces a neutral URL');
select matches(public.set_readable_public_link(tests.j(6), true, false, 'A long title without Vietnamese accents'),
  '^a-long-title-without-vi-[a-z2-7]{16}$', 'the complete readable slug is capped at 40 characters');
select matches(public.set_readable_public_link(tests.j(6), true, true, 'the title before refresh'),
  '^journey-[a-z2-7]{16}$', 'a stale title approval cannot expose the current title');
select matches(public.set_readable_public_link(tests.j(7), true, false, '日本語'),
  '^journey-[a-z2-7]{16}$', 'a title without ASCII after folding falls back to a neutral URL');
select matches(public.set_readable_public_link(tests.j(8), true), '^journey-[a-z2-7]{16}$',
  'turning on a group link without approval uses a neutral URL');
select is((select visibility::text from public.journeys where id = tests.j(8)), 'group',
  'the group keeps its membership visibility');

do $$ begin perform tests.as_user(tests.u(2)); end $$;
select is(public.public_journey_by_token(:'legacy')->>'role', 'stranger',
  'an authenticated stranger can still open the original URL');
select is(public.public_journey_by_token(:'slug')->>'role', 'stranger',
  'the readable URL resolves through the same viewer permission');
select throws_ok($$ select public.set_readable_public_link(tests.j(2), true, true) $$,
  '42501', 'forbidden', 'a non-owner cannot rotate a readable URL');

do $$ begin perform tests.as_user(tests.u(1)); end $$;
select public.set_readable_public_link(tests.j(2), true, true) as rotated \gset
select isnt(:'rotated', :'slug', 'rotation issues a different readable URL');
select throws_ok(format('select public.public_journey_by_token(%L)', :'slug'), 'P0001', 'not_found',
  'rotation invalidates the previous readable URL');
select throws_ok(format('select public.public_journey_by_token(%L)', :'legacy'), 'P0001', 'not_found',
  'rotation invalidates the previous legacy URL as well');
select is(public.public_journey_by_token(:'rotated')->>'role', 'member', 'the replacement URL resolves');

-- This matches the direct public_token clear used by moderation and unshare.
reset role;
update public.journeys set public_token = null, visibility = 'private' where id = tests.j(2);
select is((select public_slug from public.journeys where id = tests.j(2)), null::text,
  'the database clears the readable URL when an existing revocation clears the token');
do $$ begin perform tests.as_user(tests.u(2)); end $$;
select throws_ok(format('select public.public_journey_by_token(%L)', :'rotated'), 'P0001', 'not_found',
  'revocation stops the previously valid readable URL resolving');

do $$ begin perform tests.as_user(tests.u(1)); end $$;
select public_token as group_token, public_slug as group_slug
  from public.journeys where id = tests.j(8) \gset
select is(public.set_readable_public_link(tests.j(8), false), null::text,
  'disabling a public link returns no URL');
select throws_ok(format('select public.public_journey_by_token(%L)', :'group_slug'), 'P0001', 'not_found',
  'disabling the link revokes the readable URL');
select throws_ok(format('select public.public_journey_by_token(%L)', :'group_token'), 'P0001', 'not_found',
  'disabling the link also revokes the legacy URL');
select is((select visibility::text from public.journeys where id = tests.j(8)), 'group',
  'revoking a group link preserves its group visibility');

select * from finish();
rollback;
