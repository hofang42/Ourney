-- A readable URL is a second credential for the same active public link.
alter table public.journeys
  add column public_slug text unique,
  add constraint journeys_public_slug_check check (
    public_slug is null or (
      public_token is not null and char_length(public_slug) <= 40
      and public_slug collate "C" ~ '^[a-z0-9]+(-[a-z0-9]+)*-[a-z2-7]{16}$'
    )
  );

create function private.new_public_slug(p_title text) returns text
language sql volatile set search_path = ''
as $$
  select coalesce(
    nullif(trim(both '-' from left(regexp_replace(
      lower(translate(normalize(p_title, NFD),
        U&'\0110\0111\0300\0301\0302\0303\0306\0309\031B\0323', 'dd') collate "C"),
      '[^a-z0-9]+', '-', 'g'
    ), 23)), ''),
    'journey'
  ) || '-' || public.random_token(16, 'abcdefghijklmnopqrstuvwxyz234567');
$$;

create function private.sync_public_slug() returns trigger
language plpgsql set search_path = ''
as $$
begin
  if new.public_token is null then
    new.public_slug := null;
  elsif tg_op = 'INSERT' then
    -- create_journey may start with link visibility without title approval.
    new.public_slug := coalesce(new.public_slug, private.new_public_slug(null));
  elsif new.public_token is distinct from old.public_token
        and new.public_slug is not distinct from old.public_slug then
    new.public_slug := private.new_public_slug(null);
  end if;
  return new;
end;
$$;

create trigger journeys_sync_public_slug
  before insert or update of public_token on public.journeys
  for each row execute function private.sync_public_slug();

-- Give active links a neutral alias without changing their issued token.
update public.journeys
   set public_slug = private.new_public_slug(null)
 where public_token is not null and deleted_at is null;

create function private.manage_public_link(
  p_journey uuid, p_enabled boolean, p_reset boolean, p_approved_title text
) returns public.journeys
language plpgsql set search_path = ''
as $$
declare
  uid uuid := public._uid();
  j public.journeys%rowtype;
  v_token text;
  v_slug text;
  v_title text;
begin
  select * into j from public.journeys
   where id = p_journey and deleted_at is null for update;
  if not found then
    raise exception 'not_found';
  end if;
  if not exists (select 1 from public.memberships
                  where journey_id = p_journey and user_id = uid
                    and role = 'owner' and status = 'active') then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  if coalesce(p_enabled, false) then
    if j.status not in ('ended', 'archived') then
      raise exception 'invalid';
    end if;
    if j.public_token is not null and not coalesce(p_reset, false) then
      return j;
    end if;
    -- Only the exact title the owner approved can become part of the URL.
    -- Metric data and privacy-sensitive titles never supply a prefix.
    if p_approved_title collate "C" = j.title collate "C"
       and j.template_id <> 'weight_loss' and not j.hide_metric_default
       and not exists (select 1 from public.memberships
                        where journey_id = p_journey and user_id = uid and hide_metric) then
      v_title := j.title;
    end if;
    loop
      v_token := public.random_token(40, 'abcdefghijklmnopqrstuvwxyz0123456789');
      v_slug := private.new_public_slug(v_title);
      exit when v_token is distinct from j.public_token
            and v_slug is distinct from j.public_slug;
    end loop;
  end if;

  if j.public_token is not null then
    delete from public.saved_journeys where journey_id = p_journey;
  end if;
  update public.journeys
     set public_token = v_token,
         public_slug = v_slug,
         visibility = case when kind <> 'solo' then visibility
                           when v_token is null then 'private'::public.journey_visibility
                           else 'link'::public.journey_visibility end
   where id = p_journey
   returning * into j;
  return j;
end;
$$;

-- Preserve the RPC contract used by released mobile builds.
create or replace function public.set_public_link(journey uuid, enabled boolean, reset boolean default false)
returns text language sql security definer set search_path = ''
as $$
  select (private.manage_public_link(journey, enabled, reset, null)).public_token;
$$;

create function public.set_readable_public_link(
  journey uuid, enabled boolean, reset boolean default false, approved_title text default null
) returns text language sql security definer set search_path = ''
as $$
  select (private.manage_public_link(journey, enabled, reset, approved_title)).public_slug;
$$;

revoke all on function private.new_public_slug(text), private.sync_public_slug(),
  private.manage_public_link(uuid, boolean, boolean, text),
  public.set_readable_public_link(uuid, boolean, boolean, text) from public, anon, authenticated;
grant execute on function public.set_readable_public_link(uuid, boolean, boolean, text) to authenticated;

create or replace function public.public_journey_by_token(p_token text) returns json
language plpgsql security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
  v_journey uuid;
  v_role text;
begin
  if p_token collate "C" ~ '^[a-z0-9]{32,64}$' then
    select id into v_journey from public.journeys
     where public_token = p_token and deleted_at is null;
  elsif char_length(p_token) <= 40
        and p_token collate "C" ~ '^[a-z0-9]+(-[a-z0-9]+)*-[a-z2-7]{16}$' then
    select id into v_journey from public.journeys
     where public_slug = p_token and public_token is not null and deleted_at is null;
  end if;
  if v_journey is null then
    raise exception 'not_found';
  end if;
  v_role := private.viewer_role(v_journey, true);
  if v_role is null then
    raise exception 'not_found';
  end if;
  if v_role <> 'member' then
    perform private.record_view(v_journey, uid::text);
  end if;
  return private.journey_view(v_journey, v_role);
end;
$$;

create or replace function public.journey_share_state(p_journey uuid) returns json
language plpgsql stable security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
  j public.journeys%rowtype;
begin
  select * into j from public.journeys where id = p_journey and deleted_at is null;
  if not found then
    raise exception 'not_found';
  end if;
  if not private.is_member(p_journey) then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  return json_build_object(
    'journey_id', j.id,
    'viewers', coalesce((
      select json_agg(private.person(s.viewer_id) order by s.granted_at, s.viewer_id)
        from public.journey_shares s
       where s.journey_id = j.id and s.shared_by = uid and s.revoked_at is null
         and private.grant_valid(s.journey_id, s.viewer_id, s.shared_by)), '[]'::json),
    'story', json_build_object('title', j.story_title, 'intro', j.story_intro,
                               'lessons', j.story_lessons, 'cover_checkin_id', j.cover_checkin_id),
    'public', json_build_object('show_counts', j.show_counts,
                                'allow_public_reactions', j.allow_public_reactions,
                                'allow_viewer_requests', j.allow_viewer_requests),
    'hidden_checkin_ids', coalesce((
      select json_agg(c.id order by c.local_date, c.id)
        from public.check_ins c
       where c.journey_id = j.id and c.hidden_in_share and c.deleted_at is null
         and not private.is_blocked_pair(c.user_id)), '[]'::json),
    'public_token', j.public_token,
    'public_slug', j.public_slug);
end;
$$;
