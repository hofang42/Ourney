begin;
create extension if not exists pgtap with schema extensions;
select plan(30);

select ok(
  (select relrowsecurity from pg_class where oid = 'private.app_version_policy'::regclass),
  'the version policy table has RLS enabled'
);

set local role anon;
select is(
  public.get_app_version_policy('android') - 'updated_at',
  '{"platform":"android","latest":"1.0.0","latest_build":1,"recommended":"1.0.0",
    "min_supported":"1.0.0","force_on_major":true,"kill_switch":false,
    "download_url":"https://ourney.tech/Ourney.apk","notes":{"vi":[],"en":[]}}'::jsonb,
  'anon can read the seeded Android manifest and its public fields'
);
select ok(
  (public.get_app_version_policy('android') ->> 'updated_at')::timestamptz is not null,
  'the manifest includes a timestamp'
);
select is(public.get_app_version_policy('web'), null::jsonb, 'unknown platforms have no manifest');
select throws_ok(
  $$ select * from private.app_version_policy $$, '42501', null,
  'anon cannot read the version policy table'
);
select throws_ok(
  $$ update private.app_version_policy set kill_switch = true $$, '42501', null,
  'anon cannot write to the version policy table'
);
select throws_ok(
  $$ select public.admin_service_publish_release('android', '1.1.0', 2, '1.1.0', '1.0.0', true, null, '[]', '[]') $$,
  '42501', null, 'anon cannot publish a release'
);

set local role authenticated;
select is(
  public.get_app_version_policy('ios') - 'updated_at',
  '{"platform":"ios","latest":"1.0.0","latest_build":1,"recommended":"1.0.0",
    "min_supported":"1.0.0","force_on_major":true,"kill_switch":false,
    "download_url":null,"notes":{"vi":[],"en":[]}}'::jsonb,
  'authenticated callers can read the seeded iOS manifest with a null download URL'
);
select throws_ok(
  $$ select * from private.app_version_policy $$, '42501', null,
  'authenticated callers cannot read the version policy table'
);
select throws_ok(
  $$ update private.app_version_policy set kill_switch = true $$, '42501', null,
  'authenticated callers cannot write to the version policy table'
);
select throws_ok(
  $$ select public.admin_service_publish_release('android', '1.1.0', 2, '1.1.0', '1.0.0', true, null, '[]', '[]') $$,
  '42501', null, 'authenticated callers cannot publish a release'
);

set local role service_role;
set local "request.jwt.claims" = '{"role":"authenticated"}';
select throws_ok(
  $$ select public.admin_service_publish_release('android', '1.9.0', 2, '1.9.0', '1.9.0', true, null, '[]', '[]') $$,
  '42501', 'forbidden', 'the publish RPC also verifies the caller JWT role'
);

set local "request.jwt.claims" = '{"role":"service_role"}';
update private.app_version_policy set kill_switch = true where platform = 'android';

select is(
  public.admin_service_publish_release(
    p_platform => 'android',
    p_latest => '1.9.0',
    p_latest_build => 2,
    p_recommended => '1.9.0',
    p_min_supported => '1.9.0',
    p_force_on_major => false,
    p_download_url => 'https://ourney.tech/Ourney.apk',
    p_notes_vi => '["Tính năng mới"]',
    p_notes_en => '["New features"]'
  ) - 'updated_at',
  '{"platform":"android","latest":"1.9.0","latest_build":2,"recommended":"1.9.0",
    "min_supported":"1.9.0","force_on_major":false,"kill_switch":true,
    "download_url":"https://ourney.tech/Ourney.apk",
    "notes":{"vi":["Tính năng mới"],"en":["New features"]}}'::jsonb,
  'service role publishes the complete manifest and preserves the kill switch'
);

select is(
  public.admin_service_publish_release(
    'android', '1.9.0', 2, '1.9.0', '1.9.0', false,
    'https://ourney.tech/Ourney.apk', '["Tính năng mới"]', '["New features"]'
  ) ->> 'latest',
  '1.9.0', 'retrying the same release succeeds'
);

reset role;
select is(
  (select count(*) from private.admin_audit
    where action = 'release.publish' and target_type = 'system' and target_id = 'app_version_policy:android'),
  1::bigint, 'the successful release has one audit entry after a retry'
);

set local role service_role;
select is(
  public.admin_service_publish_release(
    'android', '1.10.0', 3, '1.8.0', '1.0.0', true,
    'https://ourney.tech/Ourney.apk', '["Bản cập nhật"]', '["Update"]'
  ) - 'updated_at',
  '{"platform":"android","latest":"1.10.0","latest_build":3,"recommended":"1.9.0",
    "min_supported":"1.9.0","force_on_major":true,"kill_switch":true,
    "download_url":"https://ourney.tech/Ourney.apk",
    "notes":{"vi":["Bản cập nhật"],"en":["Update"]}}'::jsonb,
  'numeric version order applies and the recommended version stays at least the retained minimum'
);
select is(
  public.admin_service_publish_release(
    'android', '1.10.0', 3, '1.8.0', '1.0.0', true,
    'https://ourney.tech/Ourney.apk', '["Bản cập nhật"]', '["Update"]', p_allow_lower_min => true
  ) ->> 'min_supported',
  '1.0.0', 'service role can explicitly lower the minimum supported version'
);
select throws_ok(
  $$ select public.admin_service_publish_release('android', '1.9.0', 2, '1.9.0', '1.9.0', true, null, '[]', '[]') $$,
  '22023', 'release_regression', 'a delayed publish cannot overwrite a newer release'
);
select throws_ok(
  $$ select public.admin_service_publish_release('android', '1.11.0', 3, '1.9.0', '1.9.0', true, null, '[]', '[]') $$,
  '22023', 'release_regression', 'an advancing release cannot reuse a build number'
);
select throws_ok(
  $$ select public.admin_service_publish_release('android', '1.11.00', 4, '1.9.0', '1.9.0', true, null, '[]', '[]') $$,
  '22023', 'invalid_release', 'noncanonical version strings are rejected'
);
select throws_ok(
  $$ select public.admin_service_publish_release('android', '1.11.0', 4, '1.9.0', '1.10.0', true, null, '[]', '[]') $$,
  '22023', 'invalid_release', 'the requested minimum cannot exceed the requested recommended version'
);
select throws_ok(
  $$ select public.admin_service_publish_release('android', '1.11.0', 4, '1.9.0', '1.9.0', true, null, '[1]', '["Update"]') $$,
  '23514', null, 'release notes must contain strings'
);
select throws_ok(
  $$ update private.app_version_policy set notes_vi = '[""]' where platform = 'android' $$,
  '23514', null, 'empty Vietnamese bullets are rejected'
);
select throws_ok(
  $$ update private.app_version_policy set notes_en = '[" \t\n"]' where platform = 'android' $$,
  '23514', null, 'whitespace-only English bullets are rejected'
);
select throws_ok(
  $$ update private.app_version_policy set download_url = 'http://ourney.tech/Ourney.apk' where platform = 'android' $$,
  '23514', null, 'download URLs require HTTPS'
);
select throws_ok(
  $$ update private.app_version_policy set download_url = 'https://ourney.tech.example.com/Ourney.apk' where platform = 'android' $$,
  '23514', null, 'lookalike download hosts are rejected'
);
select throws_ok(
  $$ update private.app_version_policy set download_url = 'https://github.com:444/hofang42/ourney-releases/releases/download/v1.10.0/Ourney.apk' where platform = 'android' $$,
  '23514', null, 'download URLs reject non-default HTTPS ports'
);
select throws_ok(
  $$ update private.app_version_policy set download_url = 'https://github.com/hofang42/ourney-releases/releases/%2e%2e/issues' where platform = 'android' $$,
  '23514', null, 'GitHub download URLs cannot leave the release path'
);
select lives_ok(
  $$ update private.app_version_policy set download_url = 'https://github.com/hofang42/ourney-releases/releases/download/v1.10.0/Ourney.apk' where platform = 'android' $$,
  'the canonical GitHub release artifact URL is allowed'
);
select ok(
  public.get_app_version_policy('android') @> '{"latest":"1.10.0","latest_build":3,"min_supported":"1.0.0"}'::jsonb
  and public.get_app_version_policy('ios') @> '{"latest":"1.0.0","latest_build":1,"download_url":null}'::jsonb,
  'failed publishes leave the prior Android release in place and publishing Android leaves iOS unchanged'
);

select * from finish();
rollback;
