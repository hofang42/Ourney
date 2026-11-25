begin;
create extension if not exists pgtap with schema extensions;
select plan(59);

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
  has_function_privilege('authenticated', 'public.set_readable_public_link(uuid,boolean,boolean,text,boolean,boolean,text)', 'execute')
  and not has_function_privilege('anon', 'public.set_readable_public_link(uuid,boolean,boolean,text,boolean,boolean,text)', 'execute'),
  'only authenticated users can call the new management RPC'
);
select ok(not has_column_privilege('authenticated', 'public.journeys', 'public_slug', 'UPDATE'),
  'authenticated users cannot change a slug directly');
select ok((select indisvalid and indisunique from pg_index
  where indexrelid = 'public.journeys_public_slug_key'::regclass),
  'the alias index is valid and unique before aliases can be issued');
select matches(pg_get_functiondef('private.retire_private_public_slug()'::regprocedure),
  'for no key update nowait', 'privacy never waits for the journey row while holding the membership row');

do $$ begin perform tests.as_user(tests.u(1)); end $$;
select public_token as create_token, public_slug as create_slug
  from public.create_journey(tests.j(1), 'solo', 'travel', '7 Ngày Đà Lạt', 'x', null, null,
    false, current_date, 7, 'UTC', p_visibility => 'link')
\gset
select matches(:'create_token'::text, '^[a-z0-9]{40}$', 'create_journey still returns a legacy token');
select matches(:'create_slug'::text, '^journey-[a-z2-7]{16}$', 'link visibility at creation issues a neutral slug');
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
  perform public.create_journey(tests.j(9), 'solo', 'custom', 'At 78 kg',
    'x', 'Custom number', U&'\FEFF KG\00A0', false, current_date - 1, 7, 'UTC');
  perform public.create_journey(tests.j(10), 'solo', 'custom', 'Old title', 'x',
    null, null, false, current_date - 1, 7, 'UTC');
  perform public.create_journey(tests.j(11), 'solo', 'custom', 'Legacy address', 'x',
    null, null, false, current_date - 1, 7, 'UTC', p_visibility => 'link');
  update public.memberships set hide_metric = true
    where user_id = tests.u(1) and journey_id = tests.j(5);
  for n in 2..11 loop
    perform public.end_journey(tests.j(n));
  end loop;
end;
$$;

select link->>'public_slug' as slug, link->>'issued' as issued, link->>'style' as style
  from public.set_readable_public_link(tests.j(2), true, false,
  normalize('7 Ngày, Đà Lạt!', NFD)) as link \gset
select public_token as legacy from public.journeys where id = tests.j(2) \gset
select matches(:'slug'::text, '^7-ngay-da-lat-[a-z2-7]{16}$',
  'an approved Vietnamese title folds lowercase letters, accents and punctuation');
select is(:'issued'::text, 'true', 'a newly created link is marked issued');
select is(:'style'::text, 'titled', 'a titled link reports its style');
select is((public.set_readable_public_link(tests.j(2), true))->>'public_slug', :'slug',
  'enabling an active link again preserves its slug');
select is(public.set_readable_public_link(tests.j(2), true)->>'issued', 'false',
  'an already active link does not claim to be newly issued');
select is(public.set_public_link(tests.j(2), true), :'legacy',
  'the previous setter still returns the legacy token');
select is(public.journey_share_state(tests.j(2))->>'public_slug', :'slug',
  'share settings provide the readable slug');
select is(public.journey_share_state(tests.j(2))->>'public_token', :'legacy',
  'share settings preserve the legacy API result');
select isnt((public.set_readable_public_link(tests.j(3), true, false, '7 Ngày, Đà Lạt!'))->>'public_slug', :'slug',
  'the same title on another journey gets a different slug');
select matches(public.set_readable_public_link(tests.j(4), true, false, 'Cân nặng 78 kg')->>'public_slug',
  '^journey-[a-z2-7]{16}$', 'a weight journey keeps numbers in its title out of the URL');
select matches(public.set_readable_public_link(tests.j(5), true, false, 'Số đo 126 cm')->>'public_slug',
  '^journey-[a-z2-7]{16}$', 'a hidden owner metric forces a neutral URL');
select matches(public.set_readable_public_link(tests.j(6), true, false, 'A long title without Vietnamese accents')->>'public_slug',
  '^a-long-title-without-vi-[a-z2-7]{16}$', 'the complete readable slug is capped at 40 characters');
select matches(public.set_readable_public_link(tests.j(6), true, true, 'the title before refresh')->>'public_slug',
  '^journey-[a-z2-7]{16}$', 'a stale title approval cannot expose the current title');
select matches(public.set_readable_public_link(tests.j(7), true, false, '日本語')->>'public_slug',
  '^journey-[a-z2-7]{16}$', 'a title without ASCII after folding falls back to a neutral URL');
select matches((public.set_readable_public_link(tests.j(8), true))->>'public_slug', '^journey-[a-z2-7]{16}$',
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
select (public.set_readable_public_link(tests.j(2), true, true))->>'public_slug' as rotated \gset
select isnt(:'rotated'::text, :'slug'::text, 'rotation issues a different readable URL');
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
select is(public.set_readable_public_link(tests.j(8), false)->>'public_slug', null::text,
  'disabling a public link returns no URL');
select throws_ok(format('select public.public_journey_by_token(%L)', :'group_slug'), 'P0001', 'not_found',
  'disabling the link revokes the readable URL');
select throws_ok(format('select public.public_journey_by_token(%L)', :'group_token'), 'P0001', 'not_found',
  'disabling the link also revokes the legacy URL');
select is((select visibility::text from public.journeys where id = tests.j(8)), 'group',
  'revoking a group link preserves its group visibility');

select public.set_readable_public_link(tests.j(9), true, false, 'At 78 kg', hide_weight => true)->>'style'
  as custom_style \gset
select is(:'custom_style'::text, 'neutral',
  'local Hide Weight also protects custom weight metrics before membership sync');
select link->>'public_slug' as kg_titled, link->>'public_token' as kg_token
  from public.set_readable_public_link(tests.j(9), true, true, 'At 78 kg') as link \gset
select matches(:'kg_titled'::text, '^at-78-kg-[a-z2-7]{16}$', 'a custom metric may be shared while visible');
select public.set_readable_public_link(tests.j(9), true, hide_weight => true, existing_only => true)->>'public_slug'
  as kg_neutral \gset
select matches(:'kg_neutral'::text, '^journey-[a-z2-7]{16}$',
  'a copy with local Hide Weight retires a titled link before membership sync');
select throws_ok(format('select public.public_journey_by_token(%L)', :'kg_titled'), 'P0001', 'not_found',
  'local Hide Weight removes the old titled credential');
select is(public.public_journey_by_token(:'kg_token')->>'role', 'member',
  'local Hide Weight preserves the opaque credential');

select link->>'public_slug' as replacement_titled, link->>'public_token' as replacement_token
  from public.set_readable_public_link(tests.j(9), true, true, 'At 78 kg') as link \gset
select is(public.set_readable_public_link(tests.j(9), true, true, hide_weight => true,
  expected_address => :'kg_titled')->>'public_token', :'replacement_token',
  'a stale confirmed reset preserves the replacement link token');
select throws_ok(format('select public.public_journey_by_token(%L)', :'replacement_titled'), 'P0001', 'not_found',
  'local Hide Weight retires the active title even on a stale reset');

select link->>'public_slug' as old_title_slug, link->>'public_token' as old_title_token
  from public.set_readable_public_link(tests.j(10), true, false, 'Old title') as link \gset
update public.memberships set hide_metric = true
 where journey_id = tests.j(10) and user_id = tests.u(1);
select public.journey_share_state(tests.j(10))->>'public_slug' as private_slug \gset
select matches(:'private_slug'::text, '^journey-[a-z2-7]{16}$',
  'changing owner membership privacy replaces an issued title at once');
select throws_ok(format('select public.public_journey_by_token(%L)', :'old_title_slug'), 'P0001', 'not_found',
  'the retired title no longer resolves');
select is(public.public_journey_by_token(:'old_title_token')->>'role', 'member',
  'the opaque credential still resolves after membership privacy changes');
update public.memberships set hide_metric = false
 where journey_id = tests.j(10) and user_id = tests.u(1);
select is(public.journey_share_state(tests.j(10))->>'public_slug', :'private_slug',
  'making the metric visible again does not restore the retired title');
select is(public.set_readable_public_link(tests.j(10), true, true, expected_address => :'old_title_slug')->>'issued',
  'false', 'a reset confirmed for a retired address leaves the current link alone');

select link->>'public_slug' as before_rename, link->>'public_token' as rename_token
  from public.set_readable_public_link(tests.j(10), true, true, 'Old title') as link \gset
reset role;
update public.journeys set title = 'New title' where id = tests.j(10);
-- Simulate the nullable alias column on a link created before migration 0031.
update public.journeys set public_slug = null where id = tests.j(11);
do $$ begin perform tests.as_user(tests.u(1)); end $$;
select public.journey_share_state(tests.j(10))->>'public_slug' as after_rename \gset
select matches(:'after_rename'::text, '^journey-[a-z2-7]{16}$',
  'renaming retires the old title without publishing the new one');
select throws_ok(format('select public.public_journey_by_token(%L)', :'before_rename'), 'P0001', 'not_found',
  'the previous title is no longer a credential after renaming');
select is(public.public_journey_by_token(:'rename_token')->>'role', 'member',
  'renaming keeps the opaque token working');
select is(public.set_readable_public_link(tests.j(10), true, true, 'New title')->>'style', 'titled',
  'the new title can be used only with fresh approval and explicit reset');

select public_token as old_token from public.journeys where id = tests.j(11) \gset
select is(public.journey_share_state(tests.j(11))->>'public_slug', null::text,
  'a legacy row can have no readable alias');
select is(public.public_journey_by_token(:'old_token')->>'role', 'member',
  'legacy tokens resolve while the alias is missing');
select link->>'public_slug' as lazy_slug, link->>'issued' as lazy_issued
  from public.set_readable_public_link(tests.j(11), true, existing_only => true) as link \gset
select matches(:'lazy_slug'::text, '^journey-[a-z2-7]{16}$', 'the first copy assigns a neutral alias');
select is(:'lazy_issued'::text, 'false', 'lazy alias creation leaves the same link active');
select is(public.journey_share_state(tests.j(11))->>'public_token', :'old_token',
  'lazy alias creation preserves the opaque token');
select is(public.set_readable_public_link(tests.j(11), true, true, expected_address => :'old_token')->>'issued', 'false',
  'a reset confirmed for an alias-less row cannot reset its new address');
select is(public.set_readable_public_link(tests.j(8), true, existing_only => true)->>'public_token', null::text,
  'a stale copy request does not re-enable a revoked link');

select * from finish();
rollback;
