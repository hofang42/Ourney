-- Per-platform update policy, readable before sign-in. Release CI publishes it
-- after the corresponding installation artifact is available.

create or replace function private.semver_parse(p_version text) returns numeric[]
language sql immutable strict set search_path = ''
as $$
  select case when p_version ~ '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$'
              then string_to_array(p_version, '.')::numeric[] end
$$;

create or replace function private.semver_lt(p_left text, p_right text) returns boolean
language sql immutable strict set search_path = ''
as $$
  select private.semver_parse(p_left) < private.semver_parse(p_right)
$$;

create or replace function private.semver_max(p_left text, p_right text) returns text
language sql immutable strict set search_path = ''
as $$
  select case when private.semver_lt(p_left, p_right) then p_right else p_left end
$$;

revoke all on function private.semver_parse(text), private.semver_lt(text, text),
  private.semver_max(text, text) from public, anon, authenticated;
grant execute on function private.semver_parse(text) to service_role;

create table if not exists private.app_version_policy (
  platform text primary key check (platform in ('android', 'ios')),
  latest text not null,
  latest_build int not null check (latest_build > 0),
  recommended text not null,
  min_supported text not null,
  force_on_major boolean not null default true,
  kill_switch boolean not null default false,
  download_url text,
  notes_vi jsonb not null default '[]'::jsonb,
  notes_en jsonb not null default '[]'::jsonb,
  updated_at timestamptz not null default now(),
  constraint app_version_policy_version_order check ((
    private.semver_parse(min_supported) <= private.semver_parse(recommended)
    and private.semver_parse(recommended) <= private.semver_parse(latest)
  ) is true)
);

-- Reinstall the named constraints when upgrading a copy of the original table.
alter table private.app_version_policy
  drop constraint if exists app_version_policy_download_url_check,
  drop constraint if exists app_version_policy_notes_arrays,
  add constraint app_version_policy_download_url_check check (
    download_url !~ '[[:space:]]' and (
      download_url ~ '^https://(ourney\.tech|www\.ourney\.tech|objects\.githubusercontent\.com|release-assets\.githubusercontent\.com|play\.google\.com|apps\.apple\.com|testflight\.apple\.com)(:443)?([/?#]|$)'
      or (
        download_url ~ '^https://github\.com(:443)?/hofang42/ourney-releases/releases/'
        and split_part(split_part(download_url, '?', 1), '#', 1)
          !~* '(%2f|%5c|[\\]|/(\.|%2e){1,2}(/|$))'
      )
    )
  ),
  add constraint app_version_policy_notes_arrays check (
    jsonb_typeof(notes_vi) = 'array' and jsonb_typeof(notes_en) = 'array'
    and not jsonb_path_exists(notes_vi, $path$$[*] ? (@.type() != "string" || @ like_regex "^\\s*$")$path$)
    and not jsonb_path_exists(notes_en, $path$$[*] ? (@.type() != "string" || @ like_regex "^\\s*$")$path$)
  );

alter table private.app_version_policy enable row level security;
revoke all on private.app_version_policy from public, anon, authenticated;
grant select, update on private.app_version_policy to service_role;

drop trigger if exists app_version_policy_updated on private.app_version_policy;
create trigger app_version_policy_updated before update on private.app_version_policy
  for each row execute function public.set_updated_at();

insert into private.app_version_policy (
  platform, latest, latest_build, recommended, min_supported, download_url
) values
  ('android', '1.0.0', 1, '1.0.0', '1.0.0', 'https://ourney.tech/Ourney.apk'),
  ('ios', '1.0.0', 1, '1.0.0', '1.0.0', null)
on conflict (platform) do nothing;

create or replace function public.get_app_version_policy(p_platform text) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object(
    'platform', policy.platform,
    'latest', policy.latest,
    'latest_build', policy.latest_build,
    'recommended', policy.recommended,
    'min_supported', policy.min_supported,
    'force_on_major', policy.force_on_major,
    'kill_switch', policy.kill_switch,
    'download_url', policy.download_url,
    'notes', jsonb_build_object('vi', policy.notes_vi, 'en', policy.notes_en),
    'updated_at', policy.updated_at
  )
    from private.app_version_policy policy
   where policy.platform = p_platform
$$;

revoke all on function public.get_app_version_policy(text) from public;
grant execute on function public.get_app_version_policy(text) to anon, authenticated, service_role;

create or replace function public.admin_service_publish_release(
  p_platform text,
  p_latest text,
  p_latest_build int,
  p_recommended text,
  p_min_supported text,
  p_force_on_major boolean,
  p_download_url text,
  p_notes_vi jsonb,
  p_notes_en jsonb,
  p_allow_lower_min boolean default false
) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_current private.app_version_policy%rowtype;
  v_min_supported text;
  v_recommended text;
begin
  perform private.assert_service_role();

  if p_latest_build is null or p_latest_build <= 0 or (
    private.semver_parse(p_min_supported) <= private.semver_parse(p_recommended)
    and private.semver_parse(p_recommended) <= private.semver_parse(p_latest)
  ) is not true then
    raise exception 'invalid_release' using errcode = '22023';
  end if;

  select * into v_current
    from private.app_version_policy
   where platform = p_platform
     for update;
  if not found then
    raise exception 'invalid_platform' using errcode = '22023';
  end if;

  -- Keep the manifest current when release jobs finish out of order.
  if p_latest_build < v_current.latest_build
     or private.semver_lt(p_latest, v_current.latest)
     or (p_latest_build = v_current.latest_build and p_latest <> v_current.latest) then
    raise exception 'release_regression' using errcode = '22023';
  end if;

  v_min_supported := case when p_allow_lower_min then p_min_supported
                          else private.semver_max(v_current.min_supported, p_min_supported) end;
  v_recommended := private.semver_max(p_recommended, v_min_supported);

  -- Identical release payloads are idempotent.
  if (v_current.latest, v_current.latest_build, v_current.recommended, v_current.min_supported,
      v_current.force_on_major, v_current.download_url, v_current.notes_vi, v_current.notes_en)
     is distinct from
     (p_latest, p_latest_build, v_recommended, v_min_supported,
      p_force_on_major, p_download_url, p_notes_vi, p_notes_en) then
    update private.app_version_policy
       set latest = p_latest,
           latest_build = p_latest_build,
           recommended = v_recommended,
           min_supported = v_min_supported,
           force_on_major = p_force_on_major,
           download_url = p_download_url,
           notes_vi = p_notes_vi,
           notes_en = p_notes_en
     where platform = p_platform;

    perform private.admin_log(
      'release.publish', 'system', 'app_version_policy:' || p_platform, null,
      jsonb_build_object(
        'latest', p_latest,
        'latest_build', p_latest_build,
        'recommended', v_recommended,
        'previous_min_supported', v_current.min_supported,
        'min_supported', v_min_supported
      )
    );
  end if;

  return public.get_app_version_policy(p_platform);
end;
$$;

revoke all on function public.admin_service_publish_release(
  text, text, int, text, text, boolean, text, jsonb, jsonb, boolean
) from public, anon, authenticated;
grant execute on function public.admin_service_publish_release(
  text, text, int, text, text, boolean, text, jsonb, jsonb, boolean
) to service_role;
