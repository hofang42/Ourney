-- 0035_supabase_security_fixes:
--   F-02: Token-versioned public link grants (private.public_link_grants) so rotating or revoking
--         a public link immediately cuts off previous viewers across reactions, saved_journeys,
--         Storage media reads, follow_frame, mark_followed, send_friend_request, and report_content.
--   F-03: Storage UPDATE/DELETE guards on buckets `media` and `messages` to prevent overwriting
--         or deleting committed, moderated/quarantined, reported, or ended-journey media.
--   F-04: Partner photo (_p.jpg) read check in private.can_read_checkin_object enforcing S29/S30
--         group share consent and block checks (matching private.journey_view).
--   F-05: Waitlist signup fallback IP bucket, advisory lock serialization, and hourly global cap.
--   F-19: Per-user sliding-window rate limit (60/hour) in public.check_username_available.
--   F-20: Share lookup throttle hardening (charge per-IP quota on 404 misses, shared fallback IP
--         bucket when IP is unavailable, per-(IP, journey) 30/min cap with 600/min global journey
--         ceiling to prevent 2-IP DoS, and pre-lookup user quota check in public_journey_by_token).
--   F-21: Reject writes to public.check_in_metrics and public.check_in_extras when the parent
--         check-in is quarantined (moderated_at IS NOT NULL) or caller is banned.
--   F-44: Exclude quarantined (moderated_at IS NOT NULL) messages/check-ins from my_conversations,
--         inbox_counts, and private.message_json; revoke direct UPDATE (couple_self_name,
--         couple_partner_name) on public.journeys from authenticated so renames go through rename_couple.

select pg_catalog.set_config('lock_timeout', '2s', true);

-- ===========================================================================
-- 1. F-02: Token-versioned public link grants
-- ===========================================================================
create table if not exists private.public_link_grants (
  journey_id uuid not null references public.journeys (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  public_token text not null,
  granted_at timestamptz not null default now(),
  primary key (journey_id, user_id)
);

create index if not exists public_link_grants_user_idx
  on private.public_link_grants (user_id);

alter table private.public_link_grants enable row level security;
revoke all on table private.public_link_grants from public, anon, authenticated, service_role;

-- Backfill grants for existing saved_journeys rows on currently active public links.
insert into private.public_link_grants (journey_id, user_id, public_token)
select j.id, s.user_id, j.public_token
  from public.saved_journeys s
  join public.journeys j on j.id = s.journey_id
 where j.public_token is not null
   and j.deleted_at is null
on conflict (journey_id, user_id) do update
  set public_token = excluded.public_token;

create or replace function private.has_public_link_access(p_journey uuid, p_viewer uuid) returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select p_viewer is not null
     and exists (
       select 1
         from public.journeys j
         join private.public_link_grants g
           on g.journey_id = j.id
          and g.user_id = p_viewer
          and g.public_token = j.public_token
        where j.id = p_journey
          and j.deleted_at is null
          and j.public_token is not null
     );
$$;

revoke all on function private.has_public_link_access(uuid, uuid) from public, anon;
grant execute on function private.has_public_link_access(uuid, uuid) to authenticated, service_role;

create or replace function private.journeys_clear_public_link_grants() returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if old.public_token is distinct from new.public_token then
    delete from private.public_link_grants where journey_id = new.id;
    delete from public.saved_journeys where journey_id = new.id;
  end if;
  return null;
end;
$$;

revoke all on function private.journeys_clear_public_link_grants() from public, anon, authenticated, service_role;

drop trigger if exists journeys_clear_public_link_grants on public.journeys;
create trigger journeys_clear_public_link_grants
  after update of public_token on public.journeys
  for each row
  when (old.public_token is distinct from new.public_token)
  execute function private.journeys_clear_public_link_grants();

create or replace function private.viewer_can_see_checkin(p_checkin uuid) returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select not private.caller_is_banned()
     and exists (
       select 1 from public.check_ins c
         join public.journeys j on j.id = c.journey_id
        where c.id = p_checkin
          and private.checkin_shareable(c.id)
          and not private.is_blocked_pair(c.user_id)
          and not private.is_blocked_pair(j.owner_id)
          and not private.has_reported(c.id)
          and (
            private.has_active_share(j.id, (select auth.uid()))
            or private.has_public_link_access(j.id, (select auth.uid()))
          )
     );
$$;

create or replace function private.can_react_as_viewer(p_checkin uuid) returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select not private.caller_is_banned()
     and exists (
       select 1 from public.check_ins c
         join public.journeys j on j.id = c.journey_id
        where c.id = p_checkin
          and not private.is_member(j.id)
          and private.viewer_can_see_checkin(c.id)
          and (
            private.has_active_share(j.id, (select auth.uid()))
            or (
              private.has_public_link_access(j.id, (select auth.uid()))
              and j.allow_public_reactions
            )
          )
     );
$$;

create or replace function private.reactions_saved_sync() returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  j public.journeys%rowtype;
begin
  select jj.* into j
    from public.check_ins c
    join public.journeys jj on jj.id = c.journey_id
   where c.id = new.checkin_id;
  if not found or private.is_active_member(j.id, new.user_id) then
    return null;
  end if;
  if new.deleted_at is null then
    if private.has_public_link_access(j.id, new.user_id)
       and not private.has_active_share(j.id, new.user_id) then
      insert into public.saved_journeys (user_id, journey_id)
      values (new.user_id, j.id)
      on conflict do nothing;
    end if;
  elsif not exists (
    select 1 from public.reactions r
      join public.check_ins c on c.id = r.checkin_id
     where c.journey_id = j.id
       and r.user_id = new.user_id
       and r.deleted_at is null
  ) then
    delete from public.saved_journeys
     where user_id = new.user_id and journey_id = j.id;
  end if;
  return null;
end;
$$;

create or replace function private.viewer_role(p_journey uuid, p_has_token boolean) returns text
language sql
stable
security definer
set search_path = ''
as $$
  select case
    when private.is_member(j.id) then 'member'
    when private.is_blocked_pair(j.owner_id) then null
    when private.has_active_share(j.id, (select auth.uid())) then 'friend'
    when j.public_token is not null
         and (
           p_has_token
           or (
             private.has_public_link_access(j.id, (select auth.uid()))
             and exists (
               select 1 from public.saved_journeys s
                where s.journey_id = j.id and s.user_id = (select auth.uid())
             )
           )
         )
      then 'stranger'
  end
  from public.journeys j
  where j.id = p_journey and j.deleted_at is null;
$$;

create or replace function private.can_see_profile(other uuid) returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select not private.caller_is_banned()
     and (
       other = (select auth.uid())
       or (not private.is_blocked_pair(other)
           and (
             exists (
               select 1 from public.memberships a
                 join public.memberships b on b.journey_id = a.journey_id
                where a.user_id = (select auth.uid()) and b.user_id = other
                  and a.status = 'active' and a.deleted_at is null
                  and b.status = 'active' and b.deleted_at is null)
             or exists (
               select 1 from public.friendships f
                where f.user_low = least(other, (select auth.uid()))
                  and f.user_high = greatest(other, (select auth.uid()))
                  and f.deleted_at is null
                  and (f.status = 'accepted' or f.requested_by = other))
             or exists (
               select 1 from public.conversations c
                where (c.member_id = other and c.viewer_id = (select auth.uid()))
                   or (c.viewer_id = other and c.member_id = (select auth.uid())))
             or exists (
               select 1 from public.journeys j
                where j.deleted_at is null
                  and ((j.owner_id = other and (j.kind = 'solo' or private.consent_accepted(j.id, other)))
                       or (private.is_active_member(j.id, other) and private.consent_accepted(j.id, other)))
                  and (private.has_active_share(j.id, (select auth.uid()))
                       or (private.has_public_link_access(j.id, (select auth.uid()))
                           and exists (select 1 from public.saved_journeys s
                                        where s.journey_id = j.id and s.user_id = (select auth.uid())))))
           ))
     );
$$;

revoke all on function
  private.viewer_can_see_checkin(uuid),
  private.can_react_as_viewer(uuid),
  private.viewer_role(uuid, boolean),
  private.can_see_profile(uuid)
from public, anon;
grant execute on function
  private.viewer_can_see_checkin(uuid),
  private.can_react_as_viewer(uuid),
  private.viewer_role(uuid, boolean),
  private.can_see_profile(uuid)
to authenticated, service_role;
revoke all on function private.reactions_saved_sync() from public, anon, authenticated, service_role;

create or replace function public.shared_with_me() returns setof json
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  uid uuid := public._uid();
begin
  return query
  with grants as (
    select s.journey_id,
           (array_agg(s.shared_by order by s.granted_at, s.shared_by))[1] as shared_by,
           min(s.granted_at) as shared_at,
           bool_or(s.seen_at is null) as unseen
      from public.journey_shares s
     where s.viewer_id = uid and s.revoked_at is null
       and private.grant_valid(s.journey_id, s.viewer_id, s.shared_by)
     group by s.journey_id
  ), items as (
    select g.journey_id, g.shared_by, g.shared_at, g.unseen, false as saved from grants g
    union all
    select sv.journey_id, j.owner_id, sv.created_at, false, true
      from public.saved_journeys sv
      join public.journeys j on j.id = sv.journey_id and j.public_token is not null
     where sv.user_id = uid
       and private.has_public_link_access(j.id, uid)
       and sv.journey_id not in (select journey_id from grants)
  )
  select json_build_object(
           'journey_id', j.id,
           'title', j.title,
           'emoji', j.emoji,
           'template_id', j.template_id,
           'kind', j.kind,
           'origin', j.origin,
           'status', j.status,
           'owner', private.owner_for_viewer(j.id),
           'shared_by', case when i.saved then private.owner_for_viewer(j.id)
                             else private.person(i.shared_by) end,
           'shared_at', i.shared_at,
           'photo_count', st.n,
           'saved', i.saved,
           'unseen', i.unseen,
           'first_date', st.first_date,
           'last_date', st.last_date,
           'cover_thumb_path', case when st.cover_blurred then null else st.cover_thumb end,
           'cover_blurred', coalesce(st.cover_blurred, false))
    from items i
    join public.journeys j on j.id = i.journey_id
    cross join lateral (
      select count(*)::int as n, min(c.local_date) as first_date, max(c.local_date) as last_date,
             (array_agg(c.thumb_path order by (c.id = j.cover_checkin_id) desc, c.local_date desc, c.id))[1]
               as cover_thumb,
             (array_agg(coalesce(m.blur_media, true)
                        order by (c.id = j.cover_checkin_id) desc, c.local_date desc, c.id))[1]
               as cover_blurred
        from public.check_ins c
        left join public.memberships m on m.journey_id = c.journey_id and m.user_id = c.user_id
       where c.journey_id = j.id
         and private.checkin_shareable(c.id)
         and not private.is_blocked_pair(c.user_id)
         and not private.has_reported(c.id)) st
   where j.deleted_at is null
     and not private.is_blocked_pair(j.owner_id)
     and not private.is_member(j.id)
   order by i.shared_at desc, j.id;
end;
$$;

revoke all on function public.shared_with_me() from public, anon;
grant execute on function public.shared_with_me() to authenticated;

create or replace function public.follow_frame(p_journey uuid) returns json
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  uid uuid := public._uid();
  j public.journeys%rowtype;
  v_show_metric boolean;
begin
  select * into j from public.journeys where id = p_journey and deleted_at is null;
  if not found then
    raise exception 'not_found';
  end if;
  if not (private.is_member(j.id)
          or (not private.is_blocked_pair(j.owner_id)
              and (private.has_active_share(j.id, uid) or private.has_public_link_access(j.id, uid)))) then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if j.status not in ('ended', 'archived') then
    raise exception 'invalid';
  end if;
  v_show_metric := private.is_member(j.id) or exists (
    select 1 from public.memberships m
     where m.journey_id = j.id and m.user_id = j.owner_id and not m.hide_metric);
  return json_build_object(
    'source_journey_id', j.id,
    'template_id', j.template_id,
    'kind', j.kind,
    'title', j.title,
    'emoji', j.emoji,
    'owner_name', private.owner_for_viewer(j.id)->>'display_name',
    'duration_days', j.duration_days,
    'metric_name', case when v_show_metric then j.metric_name end,
    'metric_unit', case when v_show_metric then j.metric_unit end,
    'layout', j.layout);
end;
$$;

revoke all on function public.follow_frame(uuid) from public, anon;
grant execute on function public.follow_frame(uuid) to authenticated;

create or replace function public.mark_followed(p_journey uuid, p_source uuid) returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := public._uid();
  j public.journeys%rowtype;
  s public.journeys%rowtype;
begin
  select * into j from public.journeys where id = p_journey and deleted_at is null for update;
  if not found then
    raise exception 'not_found';
  end if;
  if j.owner_id <> uid or not private.is_owner(p_journey) then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if j.created_at < now() - interval '1 day' or p_source is null or p_source = p_journey then
    raise exception 'invalid';
  end if;
  select * into s from public.journeys where id = p_source and deleted_at is null;
  if not found then
    raise exception 'not_found';
  end if;
  if not (private.is_member(s.id)
          or (not private.is_blocked_pair(s.owner_id)
              and (private.has_active_share(s.id, uid) or private.has_public_link_access(s.id, uid)))) then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  update public.journeys set followed_from = p_source where id = p_journey;
end;
$$;

revoke all on function public.mark_followed(uuid, uuid) from public, anon;
grant execute on function public.mark_followed(uuid, uuid) to authenticated;

create or replace function public.send_friend_request(p_user uuid, p_source_journey uuid default null) returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := public._uid();
  f public.friendships%rowtype;
  j public.journeys%rowtype;
begin
  if p_user is null or p_user = uid then
    raise exception 'invalid';
  end if;
  perform 1 from public.profiles where id = uid and deleted_at is null for no key update;
  if not found then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if not exists (select 1 from public.profiles where id = p_user and deleted_at is null) then
    raise exception 'not_found';
  end if;
  if private.blocked_between(uid, p_user) then
    raise exception 'blocked';
  end if;

  select * into f from public.friendships
   where user_low = least(uid, p_user) and user_high = greatest(uid, p_user) for update;
  if found and f.deleted_at is null then
    if f.status = 'accepted' or f.requested_by = uid then
      return; -- idempotent
    end if;
    update public.friendships set status = 'accepted', accepted_at = now()
     where user_low = f.user_low and user_high = f.user_high;
    return;
  end if;

  delete from private.rate_events where user_id = uid and at < now() - interval '1 day';
  if p_source_journey is not null then
    select * into j from public.journeys where id = p_source_journey and deleted_at is null;
    if not found then
      raise exception 'not_found';
    end if;
    if not private.has_public_link_access(j.id, uid)
       or not j.allow_viewer_requests
       or j.owner_id <> p_user
       or not (j.kind = 'solo' or private.consent_accepted(j.id, j.owner_id)) then
      raise exception 'forbidden' using errcode = '42501';
    end if;
    if (select count(*) from private.rate_events
         where user_id = uid and kind = 'public_friend_request' and at > now() - interval '1 day') >= 20 then
      raise exception 'rate_limited';
    end if;
    insert into private.rate_events (user_id, kind) values (uid, 'public_friend_request');
  else
    if (select count(*) from private.rate_events
         where user_id = uid and kind = 'friend_request' and at > now() - interval '1 hour') >= 30 then
      raise exception 'rate_limited';
    end if;
    insert into private.rate_events (user_id, kind) values (uid, 'friend_request');
  end if;

  insert into public.friendships (user_low, user_high, requested_by, status, source, source_journey_id)
  values (least(uid, p_user), greatest(uid, p_user), uid, 'pending',
          case when p_source_journey is null then 'direct' else 'public_journey' end, p_source_journey)
  on conflict (user_low, user_high) do update
    set requested_by = excluded.requested_by, status = 'pending', source = excluded.source,
        source_journey_id = excluded.source_journey_id, accepted_at = null,
        created_at = now(), deleted_at = null;
end;
$$;

revoke all on function public.send_friend_request(uuid, uuid) from public, anon;
grant execute on function public.send_friend_request(uuid, uuid) to authenticated;

create or replace function public.report_content(
  p_checkin uuid,
  p_user uuid,
  p_reason public.report_reason,
  p_note text default null,
  p_message uuid default null
) returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := public._uid();
  v_target_user uuid := p_user;
  v_id uuid;
  v_note text := left(nullif(btrim(p_note), ''), 500);
  v_open_reports int := 0;
  v_has_public_link boolean := false;
begin
  if (p_checkin is null and p_user is null and p_message is null) or p_reason is null then
    raise exception 'invalid';
  end if;
  if p_checkin is not null and p_message is not null then
    raise exception 'invalid';
  end if;
  perform 1 from public.profiles where id = uid and deleted_at is null for no key update;
  if not found then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  if p_message is not null then
    select m.sender_id into v_target_user
      from public.messages m
      join public.conversations c on c.id = m.conversation_id
     where m.id = p_message
       and m.deleted_at is null
       and m.moderated_at is null
       and uid in (c.member_id, c.viewer_id)
       and not private.blocked_between(c.member_id, c.viewer_id)
       and m.created_at > coalesce(
             case when c.member_id = uid then c.member_cleared_at else c.viewer_cleared_at end,
             '-infinity'::timestamptz)
       and not exists (select 1 from public.message_hides h
                        where h.message_id = m.id and h.user_id = uid);
    if v_target_user is null then
      raise exception 'not_found';
    end if;
    if p_user is not null and p_user <> v_target_user then
      raise exception 'invalid';
    end if;
  elsif p_checkin is not null then
    if not (
      private.can_see_checkin(p_checkin)
      or exists (
        select 1 from public.check_ins c
          join public.journeys j on j.id = c.journey_id
         where c.id = p_checkin
           and private.checkin_shareable(c.id)
           and not private.is_blocked_pair(c.user_id)
           and not private.is_blocked_pair(j.owner_id)
           and (private.has_active_share(j.id, uid) or private.has_public_link_access(j.id, uid))
      )
    ) then
      raise exception 'not_found';
    end if;
    select c.user_id, (j.public_token is not null)
      into v_target_user, v_has_public_link
      from public.check_ins c
      join public.journeys j on j.id = c.journey_id
     where c.id = p_checkin;
    if p_user is not null and p_user <> v_target_user then
      raise exception 'invalid';
    end if;
  elsif p_user = uid
     or not (exists (
       select 1 from public.memberships a
         join public.memberships b on b.journey_id = a.journey_id
        where a.user_id = uid and b.user_id = p_user
          and a.status = 'active' and b.status = 'active')
       or private.can_see_profile(p_user)) then
    raise exception 'not_found';
  end if;

  if v_target_user = uid then
    raise exception 'invalid';
  end if;

  select r.id into v_id
    from public.reports r
   where r.reporter_id = uid
     and r.deleted_at is null
     and r.status = 'open'
     and r.target_checkin_id is not distinct from p_checkin
     and r.target_message_id is not distinct from p_message
     and r.target_user_id is not distinct from v_target_user
   order by r.created_at desc
   limit 1;
  if v_id is not null then
    return v_id;
  end if;

  if (p_message is not null and not private.can_read_message(p_message))
     or (p_checkin is not null and private.has_reported(p_checkin)) then
    raise exception 'not_found';
  end if;

  if (select count(*) from public.reports
       where reporter_id = uid and created_at > now() - interval '24 hours') >= 20 then
    raise exception 'rate_limited';
  end if;

  insert into public.reports (
    reporter_id, target_checkin_id, target_user_id, target_message_id, reason, note, due_at
  )
  values (
    uid, p_checkin, v_target_user, p_message, p_reason, v_note, now() + interval '24 hours'
  )
  returning id into v_id;

  insert into public.moderation_queue (
    kind, report_id, actor_id, target_user_id, target_checkin_id, target_message_id, reason, note, due_at
  )
  values (
    'report', v_id, uid, v_target_user, p_checkin, p_message, p_reason, v_note, now() + interval '24 hours'
  );

  if p_checkin is not null then
    select count(distinct r.reporter_id)::int into v_open_reports
      from public.reports r
     where r.target_checkin_id = p_checkin
       and r.deleted_at is null
       and r.status = 'open';
    if v_open_reports >= 2
       or (
         v_has_public_link
         and p_reason in ('nudity', 'self_harm')
         and not exists (
           select 1 from public.reports r
            where r.target_checkin_id = p_checkin
              and r.deleted_at is null
              and r.status = 'dismissed'
         )
       ) then
      update public.check_ins
         set moderated_at = coalesce(moderated_at, now())
       where id = p_checkin
         and moderated_at is null;
    end if;
  end if;

  return v_id;
end;
$$;

revoke all on function public.report_content(uuid, uuid, public.report_reason, text, uuid) from public, anon;
grant execute on function public.report_content(uuid, uuid, public.report_reason, text, uuid) to authenticated;

-- ===========================================================================
-- 2. F-03 & F-04: Storage Policies & Helpers (`media` and `messages`)
-- ===========================================================================
create or replace function private.can_read_checkin_object(p_name text) returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select not private.caller_is_banned()
     and exists (
       select 1
         from public.check_ins c
         join public.journeys j on j.id = c.journey_id
        where c.id = public.try_uuid(substring(p_name from '/([0-9a-f-]{36})(?:_[tp])?\.jpg$'))
          and (c.photo_path = p_name or c.thumb_path = p_name or c.partner_photo_path = p_name)
          and (
            private.can_view_checkin(c.id)
            or (
              private.viewer_can_see_checkin(c.id)
              -- blur_media: viewers never get the original object (FR-B7).
              and not exists (
                select 1 from public.memberships m
                 where m.journey_id = c.journey_id
                   and m.user_id = c.user_id
                   and m.blur_media
              )
              -- S29/S30 (F-04): partner_photo_path (_p.jpg) on a group journey requires
              -- the owner and every active member to have accepted share consent and not
              -- be in a blocked pair with the viewer (matching private.journey_view).
              and (
                c.partner_photo_path is distinct from p_name
                or j.kind = 'solo'
                or (
                  private.consent_accepted(j.id, j.owner_id)
                  and not exists (
                    select 1 from public.memberships cm
                     where cm.journey_id = j.id
                       and cm.status = 'active'
                       and cm.deleted_at is null
                       and (
                         not private.consent_accepted(j.id, cm.user_id)
                         or private.is_blocked_pair(cm.user_id)
                       )
                  )
                )
              )
            )
          )
     );
$$;

create or replace function private.can_insert_checkin_object(p_name text) returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select not private.caller_is_banned()
     and (storage.foldername(p_name))[1] = 'checkins'
     and array_length(storage.foldername(p_name), 1) = 3
     and (storage.foldername(p_name))[3] = (select auth.uid())::text
     and storage.filename(p_name) ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}(_[tp])?\.jpg$'
     and private.is_member(public.try_uuid((storage.foldername(p_name))[2]))
     and exists (
       select 1 from public.journeys j
        where j.id = public.try_uuid((storage.foldername(p_name))[2])
          and j.deleted_at is null
          and (
            j.status = 'active'
            or (
              j.origin = 'imported'
              and j.owner_id = (select auth.uid())
              and j.status in ('ended', 'archived')
              and j.duration_days is not null
            )
          )
     )
     and not exists (
       select 1 from public.check_ins c
        where (
          c.id = public.try_uuid(substring(p_name from '/([0-9a-f-]{36})(?:_[tp])?\.jpg$'))
          or c.photo_path = p_name
          or c.thumb_path = p_name
          or c.partner_photo_path = p_name
        )
          and (
            c.user_id <> (select auth.uid())
            or c.journey_id <> public.try_uuid((storage.foldername(p_name))[2])
            or c.deleted_at is not null
            or c.moderated_at is not null
            or exists (
              select 1 from public.reports r
               where r.target_checkin_id = c.id and r.deleted_at is null
            )
            or exists (
              select 1 from public.moderation_queue mq
               where mq.target_checkin_id = c.id
            )
          )
     )
     and not exists (
       select 1 from private.pending_storage_purge s
        where s.bucket = 'media' and s.path = p_name
     );
$$;

create or replace function private.can_update_checkin_object(p_name text) returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select private.can_insert_checkin_object(p_name)
     and not exists (
       select 1 from public.check_ins c
        where c.id = public.try_uuid(substring(p_name from '/([0-9a-f-]{36})(?:_[tp])?\.jpg$'))
           or c.photo_path = p_name
           or c.thumb_path = p_name
           or c.partner_photo_path = p_name
     );
$$;

create or replace function private.can_delete_checkin_object(p_name text) returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select not private.caller_is_banned()
     and (storage.foldername(p_name))[1] = 'checkins'
     and array_length(storage.foldername(p_name), 1) = 3
     and (storage.foldername(p_name))[3] = (select auth.uid())::text
     and not exists (
       select 1 from public.check_ins c
        where (
          c.photo_path = p_name
          or c.thumb_path = p_name
          or c.partner_photo_path = p_name
          or c.id = public.try_uuid(substring(p_name from '/([0-9a-f-]{36})(?:_[tp])?\.jpg$'))
        )
          and (
            (
              c.deleted_at is null
              and (
                c.photo_path = p_name
                or c.thumb_path = p_name
                or c.partner_photo_path = p_name
              )
            )
            or c.moderated_at is not null
            or exists (
              select 1 from public.reports r
               where r.target_checkin_id = c.id
                 and r.deleted_at is null
                 and r.status in ('open', 'actioned')
            )
            or exists (
              select 1 from public.moderation_queue mq
               where mq.target_checkin_id = c.id
                 and mq.status in ('open', 'actioned')
            )
          )
     )
     and not exists (
       select 1 from private.pending_storage_purge s
        where s.bucket = 'media' and s.path = p_name
     );
$$;

create or replace function private.can_write_message_object(p_name text) returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select not private.caller_is_banned()
     and (storage.foldername(p_name))[1] = 'messages'
     and array_length(storage.foldername(p_name), 1) = 3
     and (storage.foldername(p_name))[3] = (select auth.uid())::text
     and storage.filename(p_name) ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.jpg$'
     and private.is_conversation_participant(public.try_uuid((storage.foldername(p_name))[2]))
     and not private.conversation_read_only(public.try_uuid((storage.foldername(p_name))[2]))
     and not exists (
       select 1 from public.messages m
        where m.media_path = p_name
           or m.id = public.try_uuid(substring(p_name from '/([0-9a-f-]{36})\.jpg$'))
     )
     and not exists (
       select 1 from private.pending_storage_purge s
        where s.bucket = 'messages' and s.path = p_name
     );
$$;

create or replace function private.can_delete_message_object(p_name text) returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select not private.caller_is_banned()
     and (storage.foldername(p_name))[1] = 'messages'
     and array_length(storage.foldername(p_name), 1) = 3
     and (storage.foldername(p_name))[3] = (select auth.uid())::text
     and storage.filename(p_name) ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.jpg$'
     and not exists (
       select 1 from public.messages m
        where m.media_path = p_name
           or m.id = public.try_uuid(substring(p_name from '/([0-9a-f-]{36})\.jpg$'))
     )
     and not exists (
       select 1 from private.pending_storage_purge s
        where s.bucket = 'messages' and s.path = p_name
     );
$$;

revoke all on function
  private.can_read_checkin_object(text),
  private.can_insert_checkin_object(text),
  private.can_update_checkin_object(text),
  private.can_delete_checkin_object(text),
  private.can_write_message_object(text),
  private.can_delete_message_object(text)
from public, anon;
grant execute on function
  private.can_read_checkin_object(text),
  private.can_insert_checkin_object(text),
  private.can_update_checkin_object(text),
  private.can_delete_checkin_object(text),
  private.can_write_message_object(text),
  private.can_delete_message_object(text)
to authenticated, service_role;

drop policy if exists media_insert on storage.objects;
create policy media_insert on storage.objects for insert to authenticated
with check (
  bucket_id = 'media'
  and not private.caller_is_banned()
  and (
    private.can_insert_checkin_object(name)
    or (
      (storage.foldername(name))[1] = 'avatars'
      and array_length(storage.foldername(name), 1) = 2
      and (storage.foldername(name))[2] = (select auth.uid())::text
      and exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.deleted_at is null)
      and storage.filename(name) ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.jpg$'
    )
  )
);

drop policy if exists media_update on storage.objects;
create policy media_update on storage.objects for update to authenticated
using (
  bucket_id = 'media'
  and not private.caller_is_banned()
  and (
    private.can_update_checkin_object(name)
    or (
      (storage.foldername(name))[1] = 'avatars'
      and array_length(storage.foldername(name), 1) = 2
      and (storage.foldername(name))[2] = (select auth.uid())::text
      and exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.deleted_at is null)
      and storage.filename(name) ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.jpg$'
    )
  )
)
with check (
  bucket_id = 'media'
  and not private.caller_is_banned()
  and (
    private.can_update_checkin_object(name)
    or (
      (storage.foldername(name))[1] = 'avatars'
      and array_length(storage.foldername(name), 1) = 2
      and (storage.foldername(name))[2] = (select auth.uid())::text
      and exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.deleted_at is null)
      and storage.filename(name) ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.jpg$'
    )
  )
);

drop policy if exists media_delete on storage.objects;
create policy media_delete on storage.objects for delete to authenticated
using (
  bucket_id = 'media'
  and not private.caller_is_banned()
  and (
    private.can_delete_checkin_object(name)
    or (
      (storage.foldername(name))[1] = 'avatars'
      and array_length(storage.foldername(name), 1) = 2
      and (storage.foldername(name))[2] = (select auth.uid())::text
    )
  )
);

drop policy if exists messages_insert on storage.objects;
create policy messages_insert on storage.objects for insert to authenticated
with check (
  bucket_id = 'messages'
  and private.can_write_message_object(name)
);

drop policy if exists messages_update on storage.objects;
create policy messages_update on storage.objects for update to authenticated
using (
  bucket_id = 'messages'
  and private.can_write_message_object(name)
)
with check (
  bucket_id = 'messages'
  and private.can_write_message_object(name)
);

drop policy if exists messages_delete on storage.objects;
create policy messages_delete on storage.objects for delete to authenticated
using (
  bucket_id = 'messages'
  and private.can_delete_message_object(name)
);

-- ===========================================================================
-- 3. F-05: Waitlist signup rate limiting (fallback IP bucket + advisory lock + hourly cap)
-- ===========================================================================
create or replace function public.waitlist_signup(
  p_email text,
  p_lang text default 'vi',
  p_platforms text[] default array['ios', 'android']::text[],
  p_source text default null,
  p_ip_hash text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_email text := lower(btrim(coalesce(p_email, '')));
  v_lang text := case when p_lang = 'en' then 'en' else 'vi' end;
  v_platforms text[];
  v_ip_hash text := coalesce(p_ip_hash, repeat('0', 64));
  v_id uuid;
begin
  if length(v_email) not between 3 and 254 or v_email !~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$' then
    return jsonb_build_object('status', 'invalid');
  end if;

  if length(v_ip_hash) <> 64 or v_ip_hash collate "C" !~ '^[0-9a-f]{64}$' then
    return jsonb_build_object('status', 'invalid');
  end if;

  select coalesce(array_agg(distinct p order by p), array['ios', 'android']::text[])
    into v_platforms
    from unnest(coalesce(p_platforms, array[]::text[])) as p
   where p in ('ios', 'android');

  perform pg_advisory_xact_lock(hashtext('waitlist_signup'), hashtext(v_ip_hash));
  delete from private.waitlist_attempts where created_at < now() - interval '1 day';

  if (select count(*) from private.waitlist_attempts
       where ip_hash = v_ip_hash and created_at > now() - interval '1 hour') >= 5
     or (select count(*) from private.waitlist
          where created_at > now() - interval '1 hour') >= 300 then
    return jsonb_build_object('status', 'rate_limited');
  end if;

  insert into private.waitlist_attempts (ip_hash) values (v_ip_hash);

  insert into private.waitlist (email, lang, platforms, source)
  values (v_email, v_lang, v_platforms, nullif(left(btrim(coalesce(p_source, '')), 64), ''))
  on conflict (email) do nothing
  returning id into v_id;

  if v_id is null then
    return jsonb_build_object('status', 'exists');
  end if;
  return jsonb_build_object('status', 'created', 'id', v_id);
end;
$$;

revoke all on function public.waitlist_signup(text, text, text[], text, text) from public, anon, authenticated;
grant execute on function public.waitlist_signup(text, text, text[], text, text) to service_role;

-- ===========================================================================
-- 4. F-19: Username availability throttle & block-safe existence check
-- ===========================================================================
create or replace function public.check_username_available(p_username text) returns boolean
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  uid uuid := public._uid();
  v_name text := lower(ltrim(btrim(coalesce(p_username, '')), '@'));
  v_owner uuid;
begin
  if exists (select 1 from public.profiles p where p.id = uid and p.deleted_at is not null) then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  if v_name !~ '^[a-z0-9_.]{3,20}$' then
    return false;
  end if;

  select p.id into v_owner from public.profiles p where p.username = v_name;
  if v_owner = uid then
    return true;
  end if;

  perform pg_advisory_xact_lock(hashtext('check_username_available'), hashtext(uid::text));
  delete from private.rate_events where user_id = uid and at < now() - interval '1 day';
  if (
    select count(*) from private.rate_events
     where user_id = uid
       and kind = 'username_check'
       and at > now() - interval '1 hour'
  ) >= 60 then
    raise exception 'rate_limited' using errcode = 'P0001';
  end if;
  insert into private.rate_events (user_id, kind) values (uid, 'username_check');

  if private.contains_objectionable_text(v_name) then
    return false;
  end if;

  return v_owner is null;
end;
$$;

revoke all on function public.check_username_available(text) from public, anon;
grant execute on function public.check_username_available(text) to authenticated, service_role;

-- ===========================================================================
-- 5. F-20 & F-02: Share lookup throttle hardening & token-versioned grant recording
-- ===========================================================================
create or replace function public.lookup_public_journey_for_edge(p_token text, p_ip_hash text) returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_is_slug boolean := coalesce(char_length(p_token) <= 40
    and p_token collate "C" ~ '^[a-z0-9]+(-[a-z0-9]+)*-[a-z2-7]{16}$', false);
  v_window timestamptz := date_trunc('minute', now(), 'UTC');
  v_ip_key text := coalesce(case when p_ip_hash collate "C" ~ '^[0-9a-f]{64}$' then p_ip_hash end, 'fallback');
  v_journey record;
  v_retry integer := greatest(1, ceil(extract(epoch from v_window + interval '1 minute' - now()))::integer);
begin
  if not v_is_slug and not coalesce(p_token collate "C" ~ '^[a-z0-9]{32,64}$', false) then
    return jsonb_build_object('retry_after', 0, 'journey', null);
  end if;

  -- F-20: charge the per-IP (or shared fallback) bucket on every well-formed lookup, including 404 misses,
  -- and check before resolving so exhausted IPs cannot probe 404s or use 429-vs-404 as an existence oracle.
  if private.share_lookup_is_full(v_window, 'ip', v_ip_key, 60) then
    return jsonb_build_object('retry_after', v_retry, 'journey', null);
  end if;
  perform private.purge_share_lookup_buckets(6);
  if not private.take_share_lookup(v_window, 'ip', v_ip_key, 60) then
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

  -- F-20: cap each (IP/fallback, journey) pair at 30/min while raising the per-journey global ceiling
  -- to 600/min so 1-2 IPs (or missing-IP subrequests) cannot exhaust a shared journey's global quota.
  if not private.share_lookup_is_full(v_window, 'ip_journey', v_ip_key || ':' || v_journey.id::text, 30)
     and not private.share_lookup_is_full(v_window, 'journey', v_journey.id::text, 600) then
    if private.take_share_lookup(v_window, 'ip_journey', v_ip_key || ':' || v_journey.id::text, 30) then
      if private.take_share_lookup(v_window, 'journey', v_journey.id::text, 600) then
        return jsonb_build_object('retry_after', 0, 'journey', to_jsonb(v_journey));
      end if;
    end if;
  end if;

  return jsonb_build_object('retry_after', v_retry, 'journey', null);
end;
$$;

revoke all on function public.lookup_public_journey_for_edge(text, text) from public, anon, authenticated;
grant execute on function public.lookup_public_journey_for_edge(text, text) to service_role;

create or replace function public.public_journey_by_token(p_token text) returns json
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := public._uid();
  v_is_slug boolean := coalesce(char_length(p_token) <= 40
    and p_token collate "C" ~ '^[a-z0-9]+(-[a-z0-9]+)*-[a-z2-7]{16}$', false);
  v_window timestamptz := date_trunc('minute', now(), 'UTC');
  v_limited boolean;
  v_retry integer;
  v_journey uuid;
  v_public_token text;
  v_role text;
  v_view json;
begin
  if not v_is_slug and not coalesce(p_token collate "C" ~ '^[a-z0-9]{32,64}$', false) then
    raise exception 'not_found';
  end if;

  -- F-20: check per-user quota before resolving the token so an exhausted caller cannot probe 404s.
  if private.share_lookup_is_full(v_window, 'user', uid::text, 60) then
    v_retry := greatest(1, ceil(extract(epoch from v_window + interval '1 minute' - now()))::integer);
    raise sqlstate 'PGRST' using
      message = '{"code":"P0001","message":"rate_limited"}',
      detail = json_build_object('status', 429,
        'headers', json_build_object('Retry-After', v_retry::text, 'Cache-Control', 'no-store'))::text;
  end if;

  with candidate as materialized (
    select j.id, j.public_token, private.viewer_role(j.id, true) as role
      from public.journeys j
     where j.deleted_at is null and j.public_token is not null
       and ((v_is_slug and j.public_slug = p_token) or (not v_is_slug and j.public_token = p_token))
  )
  select c.id, c.public_token, c.role
    into v_journey, v_public_token, v_role
    from candidate c
   where c.role is not null;
  if not found then
    raise exception 'not_found';
  end if;

  -- F-02: record the token-versioned grant for this viewer before building the view.
  insert into private.public_link_grants (journey_id, user_id, public_token, granted_at)
  values (v_journey, uid, v_public_token, now())
  on conflict (journey_id, user_id) do update
    set public_token = excluded.public_token,
        granted_at = excluded.granted_at
  where private.public_link_grants.public_token is distinct from excluded.public_token;

  v_view := private.journey_view(v_journey, v_role);

  if v_role <> 'member' then
    perform private.record_view(v_journey, uid::text);
  end if;
  perform private.purge_share_lookup_buckets(6);
  v_limited := not private.take_share_lookup(v_window, 'user', uid::text, 60);
  if v_limited then
    v_retry := greatest(1, ceil(extract(epoch from v_window + interval '1 minute' - now()))::integer);
    raise sqlstate 'PGRST' using
      message = '{"code":"P0001","message":"rate_limited"}',
      detail = json_build_object('status', 429,
        'headers', json_build_object('Retry-After', v_retry::text, 'Cache-Control', 'no-store'))::text;
  end if;
  return v_view;
end;
$$;

revoke all on function public.public_journey_by_token(text) from public, anon;
grant execute on function public.public_journey_by_token(text) to authenticated;

-- ===========================================================================
-- 6. F-21: Reject writes to check_in_metrics and check_in_extras when quarantined or banned
-- ===========================================================================
create or replace function private.check_in_metrics_before_write() returns trigger
language plpgsql
set search_path = ''
as $$
declare
  c record;
begin
  if current_user in ('authenticated', 'anon') and private.caller_is_banned() then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  select ci.journey_id, ci.user_id, ci.deleted_at, ci.moderated_at,
         j.status, j.deleted_at as journey_deleted,
         (j.origin = 'imported' and j.owner_id = ci.user_id
          and j.status in ('ended', 'archived') and j.duration_days is not null) as imported
    into c
    from public.check_ins ci
    join public.journeys j on j.id = ci.journey_id
   where ci.id = new.checkin_id;
  if not found then
    raise exception 'not_found' using errcode = 'P0001';
  end if;
  new.journey_id := c.journey_id;
  new.user_id := c.user_id;
  if current_user in ('authenticated', 'anon') then
    if c.moderated_at is not null then
      raise exception 'forbidden' using errcode = '42501';
    end if;
    if c.deleted_at is not null then
      raise exception 'not_found' using errcode = 'P0001';
    end if;
    if c.journey_deleted is not null or (c.status <> 'active' and not c.imported) then
      raise exception 'ended' using errcode = 'P0001';
    end if;
  end if;
  return new;
end;
$$;

revoke all on function private.check_in_metrics_before_write() from public, anon, authenticated;

-- ===========================================================================
-- 7. F-44: Backend hygiene (quarantined content in conversation previews/counts/reply thumbs,
--          and revoking direct UPDATE on couple_self_name / couple_partner_name)
-- ===========================================================================
revoke update (couple_self_name, couple_partner_name) on public.journeys from authenticated;

create or replace function private.message_json(m public.messages) returns json
language sql
stable
security definer
set search_path = ''
as $$
  select json_build_object(
    'id', m.id,
    'conversation_id', m.conversation_id,
    'sender_id', m.sender_id,
    'kind', m.kind,
    'body', m.body,
    'media_path', m.media_path,
    'reply_to_checkin_id', m.reply_to_checkin_id,
    'reply_to_thumb_path', (
      select c.thumb_path
        from public.check_ins c
        left join public.memberships a
          on a.journey_id = c.journey_id and a.user_id = c.user_id
       where c.id = m.reply_to_checkin_id
         and c.deleted_at is null
         and c.moderated_at is null
         and not private.has_reported(c.id)
         and not private.is_blocked_pair(c.user_id)
         and (
           private.is_member(c.journey_id)
           or (
             private.viewer_can_see_checkin(c.id)
             and not coalesce(a.blur_media, true)
           )
         )
    ),
    'created_at', m.created_at
  );
$$;

revoke all on function private.message_json(public.messages) from public, anon, authenticated;

create or replace function public.my_conversations() returns setof json
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  uid uuid := public._uid();
begin
  return query
  select json_build_object(
           'id', c.id,
           'journey_id', c.journey_id,
           'journey_title', j.title,
           'other', private.person(x.other),
           'unread_count', (
             select count(*)::int from public.messages m
              where m.conversation_id = c.id
                and m.sender_id <> uid
                and m.deleted_at is null
                and m.moderated_at is null
                and m.created_at > coalesce(x.read_at, '-infinity'::timestamptz)
                and m.created_at > coalesce(x.cleared_at, '-infinity'::timestamptz)
                and not exists (select 1 from public.message_hides h
                                 where h.message_id = m.id and h.user_id = uid)
                and not exists (select 1 from public.reports r
                                 where r.target_message_id = m.id and r.reporter_id = uid
                                   and r.deleted_at is null)),
           'read_only', private.conversation_read_only(c.id),
           'last_message_at', lm.created_at,
           'last_message_preview', left(lm.body, 120),
           'last_message_kind', lm.kind)
    from public.conversations c
    join public.journeys j on j.id = c.journey_id
    cross join lateral (
      select case when c.member_id = uid then c.viewer_id else c.member_id end as other,
             case when c.member_id = uid then c.member_read_at else c.viewer_read_at end as read_at,
             case when c.member_id = uid then c.member_cleared_at else c.viewer_cleared_at end as cleared_at) x
    left join lateral (
      select m.created_at, m.body, m.kind from public.messages m
       where m.conversation_id = c.id
         and m.deleted_at is null
         and m.moderated_at is null
         and m.created_at > coalesce(x.cleared_at, '-infinity'::timestamptz)
         and not exists (select 1 from public.message_hides h where h.message_id = m.id and h.user_id = uid)
         and not exists (select 1 from public.reports r
                          where r.target_message_id = m.id and r.reporter_id = uid and r.deleted_at is null)
       order by m.created_at desc, m.id desc limit 1) lm on true
   where uid in (c.member_id, c.viewer_id)
     and not private.blocked_between(c.member_id, c.viewer_id)
     and (x.cleared_at is null or c.last_message_at > x.cleared_at)
   order by coalesce(c.last_message_at, c.created_at) desc, c.id;
end;
$$;

revoke all on function public.my_conversations() from public, anon;
grant execute on function public.my_conversations() to authenticated;

create or replace function public.inbox_counts() returns json
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  uid uuid := public._uid();
begin
  return json_build_object(
    'friend_requests', (
      select count(*)::int from public.friendships f
       where uid in (f.user_low, f.user_high) and f.deleted_at is null and f.status = 'pending'
         and f.requested_by <> uid and f.source = 'direct'
         and not private.blocked_between(f.user_low, f.user_high)),
    'public_requests', (
      select count(*)::int from public.friendships f
       where uid in (f.user_low, f.user_high) and f.deleted_at is null and f.status = 'pending'
         and f.requested_by <> uid and f.source = 'public_journey'
         and not private.blocked_between(f.user_low, f.user_high)),
    'new_shares', (
      select count(distinct s.journey_id)::int from public.journey_shares s
        join public.journeys j on j.id = s.journey_id and j.deleted_at is null
       where s.viewer_id = uid and s.revoked_at is null and s.seen_at is null
         and private.grant_valid(s.journey_id, s.viewer_id, s.shared_by)
         and not private.is_member(s.journey_id)
         and not private.blocked_between(uid, j.owner_id)),
    'unread_messages', (
      select count(*)::int
        from public.conversations c
        join public.messages m on m.conversation_id = c.id
       where uid in (c.member_id, c.viewer_id)
         and not private.blocked_between(c.member_id, c.viewer_id)
         and m.sender_id <> uid
         and m.deleted_at is null
         and m.moderated_at is null
         and m.created_at > coalesce(case when c.member_id = uid then c.member_read_at else c.viewer_read_at end,
                                     '-infinity'::timestamptz)
         and m.created_at > coalesce(case when c.member_id = uid then c.member_cleared_at else c.viewer_cleared_at end,
                                     '-infinity'::timestamptz)
         and not exists (select 1 from public.message_hides h where h.message_id = m.id and h.user_id = uid)
         and not exists (select 1 from public.reports r
                          where r.target_message_id = m.id and r.reporter_id = uid and r.deleted_at is null)),
    'consent_requests', (
      select count(*)::int from public.journey_share_consents c
        join public.journeys j on j.id = c.journey_id and j.deleted_at is null
       where c.user_id = uid and c.status = 'pending' and private.is_active_member(c.journey_id, uid)
         and not private.blocked_between(uid, j.owner_id)),
    'group_invitations', (
      select count(*)::int from public.group_invitations i
        join public.journeys j on j.id = i.journey_id and j.deleted_at is null and j.status = 'active'
       where i.invitee_id = uid and i.status = 'pending' and i.expires_at > now()
         and private.is_active_member(j.id, i.inviter_id)
         and (j.duration_days is null
              or public.local_date(now(), j.timezone) <= j.start_date + j.duration_days - 1)
         and not private.blocked_between(uid, i.inviter_id)
         and not exists (select 1 from public.memberships am
                          where am.journey_id = j.id and am.status = 'active' and am.deleted_at is null
                            and private.blocked_between(uid, am.user_id))),
    'shipped_requests', (
      select count(*)::int
        from private.feature_request_notifications n
        join public.feature_requests fr on fr.id = n.request_id
       where n.user_id = uid
         and n.seen_at is null
         and not fr.hidden
         and fr.status = 'shipped'
         and (
           fr.author_id = uid
           or (
             (fr.author_id is null or not private.is_blocked_pair(fr.author_id))
             and not private.has_reported_feature_request(fr.id)
           )
         )));
end;
$$;

revoke all on function public.inbox_counts() from public, anon;
grant execute on function public.inbox_counts() to authenticated, service_role;
