-- 0016_bugscan_backend_fixes: server fixes from the 2026-11-18 bug scan (docs/bug.md).
-- Every function below is a `create or replace` of its newest definition (noted per function)
-- with the same signature, SECURITY DEFINER and search_path, so existing grants are kept.
-- Idempotent (create or replace, guarded updates). Tests: supabase/tests/16_bugscan_backend_fixes.test.sql.
--
--  A-B3  shared_with_me: a saved (public link) journey's shared_by goes through owner_for_viewer,
--        so a group owner who has not consented stays anonymous; send_friend_request from a public
--        page needs that consent too (same rule as journey_view.can_add_owner).
--  A-B4  account_message_paths lists the account's chat images in bucket `messages`
--        (used by the delete-account Edge Function); purge_account_data also clears
--        private.join_attempts, private.rate_events and public.journey_views of the user.
--  A-B6  create_journey forces max_members = 2 for couple journeys (+ backfill).
--  A-B7  _leave_journey (leave, remove_member, account purge) revokes the leaver's pending
--        group invitations; accept_group_invitation needs the inviter to be an active member.
--  A-B8  journey_view / follow_frame hide metric_name, metric_unit from non-members when the
--        owner hides the metric (the public-journey Edge Function does the same).
--  A-B9  share_consents hides members blocked with the caller (either direction);
--  A-B10 consent_json never returns a null requested_by: a deleted (or blocked) requester
--        is the anonymous person (nil id, empty names), as owner_for_viewer does.
--  A-B15 group_today picks the member's latest NOT reported check-in of today;
--        checked_in stays true when every photo of today was reported (L7).
--  A-B16 join_by_code closes the joiner's pending invitations to that group (+ backfill).
--  C1    shared_with_me: the cover thumb of an author who blurs media is not returned
--        (cover_thumb_path null, cover_blurred true).
--  C2    message_json: reply_to_thumb_path only when the caller may see that check-in
--        (member, or viewer of a shareable, unreported, unblocked, unblurred photo).
--  C3    journey_pending_invitations hides invitations whose inviter is blocked with the caller.

-- ---------------------------------------------------------------------------
-- A-B3 + C1: shared_with_me (from 0006_social)
-- ---------------------------------------------------------------------------
create or replace function public.shared_with_me() returns setof json
language plpgsql stable security definer set search_path = ''
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
     where sv.user_id = uid and sv.journey_id not in (select journey_id from grants)
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
           -- A-B3: a saved journey was "shared" by its owner, who may have to stay anonymous.
           'shared_by', case when i.saved then private.owner_for_viewer(j.id)
                             else private.person(i.shared_by) end,
           'shared_at', i.shared_at,
           'photo_count', st.n,
           'saved', i.saved,
           'unseen', i.unseen,
           'first_date', st.first_date,
           'last_date', st.last_date,
           -- C1: viewers never get the object of a blurred author (FR-B7).
           'cover_thumb_path', case when st.cover_blurred then null else st.cover_thumb end,
           'cover_blurred', coalesce(st.cover_blurred, false))
    from items i
    join public.journeys j on j.id = i.journey_id
    cross join lateral (
      -- Cover = the journey's cover check-in when shareable, else the latest shareable photo.
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

-- ---------------------------------------------------------------------------
-- A-B3: send_friend_request (from 0006_social)
-- ---------------------------------------------------------------------------
create or replace function public.send_friend_request(p_user uuid, p_source_journey uuid default null) returns void
language plpgsql security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
  f public.friendships%rowtype;
  j public.journeys%rowtype;
begin
  if p_user is null or p_user = uid then
    raise exception 'invalid';
  end if;
  perform 1 from public.profiles where id = uid and deleted_at is null for update;
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

  if p_source_journey is not null then
    select * into j from public.journeys where id = p_source_journey and deleted_at is null;
    if not found then
      raise exception 'not_found';
    end if;
    if j.public_token is null or not j.allow_viewer_requests or j.owner_id <> p_user
       -- A-B3: a group owner who has not consented to sharing stays unreachable (S29/S30).
       or not (j.kind = 'solo' or private.consent_accepted(j.id, j.owner_id)) then
      raise exception 'forbidden' using errcode = '42501';
    end if;
    if (select count(*) from private.rate_events
         where user_id = uid and kind = 'public_friend_request' and at > now() - interval '1 day') >= 20 then
      raise exception 'rate_limited';
    end if;
    insert into private.rate_events (user_id, kind) values (uid, 'public_friend_request');
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

-- ---------------------------------------------------------------------------
-- A-B4: account deletion
-- ---------------------------------------------------------------------------
-- Real objects in bucket `messages` (messages/{conversation_id}/{sender_id}/{message_id}.jpg)
-- that go with the account: everything the user sent, everything in a conversation the user
-- is part of (the rows cascade away with the profile), and everything in conversations of
-- journeys that die with the account. Called by the delete-account Edge Function.
create or replace function public.account_message_paths(p_user uuid) returns setof text
language sql
stable
security definer
set search_path = ''
as $$
  select o.name
    from storage.objects o
   where o.bucket_id = 'messages'
     and (storage.foldername(o.name))[1] = 'messages'
     and (
       (storage.foldername(o.name))[3] = p_user::text
       or public.try_uuid((storage.foldername(o.name))[2]) in (
            select c.id from public.conversations c
             where p_user in (c.member_id, c.viewer_id)
                or c.journey_id in (select public._journeys_dying_with(p_user)))
     )
   order by o.name;
$$;

revoke all on function public.account_message_paths(uuid) from public, anon, authenticated;
grant execute on function public.account_message_paths(uuid) to service_role;

-- From 0004_rpc. + rows keyed by the user id without a foreign key (A-B4).
create or replace function public.purge_account_data(p_user uuid) returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  r record;
begin
  for r in
    select m.journey_id from public.memberships m
     where m.user_id = p_user and m.status = 'active' and m.deleted_at is null
       and m.journey_id not in (select public._journeys_dying_with(p_user))
  loop
    perform public._leave_journey(r.journey_id, p_user);
  end loop;
  delete from public.journeys where id in (select public._journeys_dying_with(p_user));
  delete from private.join_attempts where user_id = p_user;
  delete from private.rate_events where user_id = p_user;
  delete from public.journey_views where viewer_key = p_user::text;
end;
$$;

-- ---------------------------------------------------------------------------
-- A-B6: create_journey (from 0013_unlimited_journeys) -- a couple journey has 2 seats.
-- ---------------------------------------------------------------------------
create or replace function public.create_journey(
  p_id uuid,
  p_kind public.journey_kind,
  p_template_id public.template_id,
  p_title text,
  p_emoji text,
  p_metric_name text,
  p_metric_unit text,
  p_hide_metric_default boolean,
  p_start_date date,
  p_duration_days int,
  p_timezone text,
  p_max_members int default 10,
  p_visibility public.journey_visibility default 'private',
  p_couple_self_name text default null,
  p_couple_partner_name text default null
) returns public.journeys
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := public._uid();
  j public.journeys%rowtype;
  v_visibility public.journey_visibility;
  v_code text;
  v_token text;
  v_self text := nullif(btrim(p_couple_self_name), '');
  v_partner text := nullif(btrim(p_couple_partner_name), '');
begin
  if p_id is null or p_kind is null or p_start_date is null or p_timezone is null then
    raise exception 'invalid';
  end if;
  if (p_kind = 'group' and p_visibility = 'link')
     or (p_kind = 'solo' and p_visibility = 'group') then
    raise exception 'invalid';
  end if;
  -- Couple names come as a pair of 1..24 characters, or not at all.
  if (v_self is null) <> (v_partner is null)
     or char_length(coalesce(v_self, '')) > 24 or char_length(coalesce(v_partner, '')) > 24 then
    raise exception 'invalid';
  end if;

  perform 1 from public.profiles where id = uid and deleted_at is null for update;
  if not found then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  select * into j from public.journeys where id = p_id;
  if found then
    if j.owner_id = uid then
      return j;
    end if;
    raise exception 'forbidden' using errcode = '42501';
  end if;

  if p_kind = 'group' then
    v_visibility := 'group';
    loop
      v_code := public.random_token(8, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789');
      exit when not exists (select 1 from public.journeys where invite_code = v_code);
    end loop;
  elsif p_visibility = 'link' then
    v_visibility := 'link';
    v_token := public.random_token(40, 'abcdefghijklmnopqrstuvwxyz0123456789');
  else
    v_visibility := 'private';
  end if;

  insert into public.journeys (
    id, owner_id, kind, template_id, title, emoji, metric_name, metric_unit,
    hide_metric_default, start_date, duration_days, timezone, visibility, status,
    invite_code, max_members, public_token, couple_self_name, couple_partner_name)
  values (
    p_id, uid, p_kind, coalesce(p_template_id, 'custom'), btrim(p_title), p_emoji,
    p_metric_name, p_metric_unit, coalesce(p_hide_metric_default, false), p_start_date,
    p_duration_days, p_timezone, v_visibility, 'active', v_code,
    case when p_kind = 'solo' then 1
         when v_self is not null then 2 -- A-B6: a couple journey is for two people
         else coalesce(p_max_members, 10) end,
    v_token, v_self, v_partner)
  returning * into j;

  insert into public.memberships (journey_id, user_id, role, hide_metric)
  values (j.id, uid, 'owner', j.hide_metric_default);

  return j;
end;
$$;

-- Couple journeys created before this fix: no new seat beyond two (members already in stay).
update public.journeys set max_members = 2
 where kind = 'group' and couple_self_name is not null and max_members <> 2;

-- Owners may add couple names later (0007 grants update on them): keep two seats then too.
create or replace function private.journeys_couple_seats() returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.kind = 'group' and new.couple_self_name is not null then
    new.max_members := 2;
  end if;
  return new;
end;
$$;

drop trigger if exists journeys_couple_seats on public.journeys;
create trigger journeys_couple_seats
  before insert or update of couple_self_name, couple_partner_name, max_members, kind
  on public.journeys
  for each row execute function private.journeys_couple_seats();

-- ---------------------------------------------------------------------------
-- A-B7: _leave_journey (from 0004_rpc) + accept_group_invitation (from 0008_group_invites)
-- ---------------------------------------------------------------------------
create or replace function public._leave_journey(p_journey uuid, p_user uuid) returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  was_owner boolean;
  next_owner uuid;
begin
  perform 1 from public.journeys where id = p_journey for update;
  select (role = 'owner') into was_owner
    from public.memberships
   where journey_id = p_journey and user_id = p_user and status = 'active' and deleted_at is null
   for update;
  if was_owner is null then
    raise exception 'not_found';
  end if;

  update public.memberships set status = 'left', role = 'member'
   where journey_id = p_journey and user_id = p_user;
  update public.check_ins set deleted_at = now(), hidden_by_leave = true
   where journey_id = p_journey and user_id = p_user and deleted_at is null;
  -- A-B7: invitations sent by someone who is no longer in the group stop working.
  update public.group_invitations set status = 'revoked', responded_at = now()
   where journey_id = p_journey and inviter_id = p_user and status = 'pending';

  if was_owner then
    select user_id into next_owner
      from public.memberships
     where journey_id = p_journey and status = 'active' and deleted_at is null
     order by joined_at, user_id
     limit 1;
    if next_owner is null then
      update public.journeys set status = 'archived' where id = p_journey;
    else
      update public.memberships set role = 'owner'
       where journey_id = p_journey and user_id = next_owner;
      update public.journeys set owner_id = next_owner where id = p_journey;
    end if;
  end if;
end;
$$;

create or replace function public.accept_group_invitation(p_invitation uuid) returns public.journeys
language plpgsql security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
  i public.group_invitations%rowtype;
  j public.journeys%rowtype;
  r public.journeys%rowtype;
begin
  select * into i from public.group_invitations
   where id = p_invitation and invitee_id = uid and status = 'pending' and expires_at > now()
   for update;
  if not found then
    raise exception 'not_found';
  end if;
  select * into j from public.journeys where id = i.journey_id and kind = 'group' and deleted_at is null;
  if not found or j.invite_code is null then
    raise exception 'not_found';
  end if;
  -- A-B7: the inviter must still be in the group (left / removed inviters' invitations are dead).
  if not private.is_active_member(i.journey_id, i.inviter_id) then
    raise exception 'not_found';
  end if;
  if private.blocked_between(uid, i.inviter_id) then
    raise exception 'blocked';
  end if;
  r := public.join_by_code(j.invite_code);
  if r.id is null then
    raise exception 'not_found';
  end if;
  update public.group_invitations set status = 'accepted', responded_at = now() where id = i.id;
  return r;
end;
$$;

-- Pending invitations of inviters who already left or were removed.
update public.group_invitations i set status = 'revoked', responded_at = now()
 where i.status = 'pending' and not private.is_active_member(i.journey_id, i.inviter_id);

-- ---------------------------------------------------------------------------
-- A-B8: journey_view + follow_frame (from 0006_social)
-- ---------------------------------------------------------------------------
create or replace function private.journey_view(p_journey uuid, p_role text) returns json
language plpgsql stable security definer set search_path = ''
as $$
declare
  uid uuid := (select auth.uid());
  j public.journeys%rowtype;
  v_member boolean := p_role = 'member';
  v_counts boolean;
  v_photos json;
  v_total int;
  v_members json;
  v_streak int;
  v_sharer uuid;
  v_show_metric boolean;
begin
  select * into j from public.journeys where id = p_journey;
  v_counts := v_member or j.show_counts;
  -- A-B8: the metric's name and unit follow the owner's hide_metric for non-members.
  v_show_metric := v_member or exists (
    select 1 from public.memberships m
     where m.journey_id = j.id and m.user_id = j.owner_id and not m.hide_metric);

  select coalesce(json_agg(json_build_object(
           'checkin_id', ph.id,
           'author', private.person(ph.user_id),
           'local_date', ph.local_date,
           -- Blurred photos carry no object path: the client shows a placeholder.
           'photo_path', case when not v_member and ph.blur_media then '' else ph.photo_path end,
           'thumb_path', case when not v_member and ph.blur_media then '' else ph.thumb_path end,
           'caption', ph.caption,
           'metric_value', case when ph.user_id = uid or not ph.hide_metric then cm.metric_value end,
           'like_count', case when v_counts then rc.cnt else 0 end,
           'liked_by_me', rc.mine,
           'blurred', (not v_member and ph.blur_media))
           order by ph.local_date, ph.created_at, ph.id), '[]'::json),
         coalesce(sum(rc.cnt), 0)::int
    into v_photos, v_total
    from (
      select c.id, c.user_id, c.local_date, c.photo_path, c.thumb_path, c.caption, c.created_at,
             m.hide_metric, m.blur_media
        from public.check_ins c
        join public.memberships m on m.journey_id = c.journey_id and m.user_id = c.user_id
       where c.journey_id = p_journey and c.deleted_at is null
         and not private.is_blocked_pair(c.user_id)
         and not private.has_reported(c.id)
         and (v_member or private.checkin_shareable(c.id))
    ) ph
    left join public.check_in_metrics cm on cm.checkin_id = ph.id
    cross join lateral (
      select count(*)::int as cnt, coalesce(bool_or(r.user_id = uid), false) as mine
        from public.reactions r where r.checkin_id = ph.id and r.deleted_at is null) rc;

  if j.kind = 'solo' then
    v_members := json_build_array(private.person(j.owner_id));
  else
    select coalesce(json_agg(private.person(m.user_id) order by m.joined_at, m.user_id), '[]'::json)
      into v_members
      from public.memberships m
     where m.journey_id = p_journey and m.status = 'active' and m.deleted_at is null
       and not private.is_blocked_pair(m.user_id)
       and (v_member or private.consent_accepted(p_journey, m.user_id));
  end if;

  if j.origin = 'imported' or (p_role = 'stranger' and j.kind = 'group') then
    v_streak := null;
  elsif j.kind = 'solo' then
    select s.current_streak into v_streak from public.journey_streak(j.id, j.owner_id) s;
    v_streak := coalesce(v_streak, 0);
  else
    v_streak := coalesce(private.group_streak(j.id), 0);
  end if;

  if p_role = 'friend' then
    v_sharer := private.earliest_sharer(p_journey, uid);
  end if;

  return json_build_object(
    'journey_id', j.id,
    'role', p_role,
    'title', j.title,
    'emoji', j.emoji,
    'template_id', j.template_id,
    'kind', j.kind,
    'origin', j.origin,
    'status', j.status,
    'duration_days', j.duration_days,
    'start_date', j.start_date,
    'owner', private.owner_for_viewer(j.id),
    'members', v_members,
    'story', json_build_object(
      'title', j.story_title, 'intro', j.story_intro, 'lessons', j.story_lessons,
      'cover_checkin_id', case when v_member or private.checkin_shareable(j.cover_checkin_id)
                               then j.cover_checkin_id end),
    'photos', v_photos,
    'current_streak', v_streak,
    'like_count', case when v_counts then v_total end,
    'follow_count', case when v_counts then
      -- Distinct owners: one account cannot inflate the count with many journeys.
      (select count(distinct f.owner_id)::int from public.journeys f
        where f.followed_from = j.id and f.deleted_at is null) end,
    'metric_name', case when v_show_metric then j.metric_name end,
    'metric_unit', case when v_show_metric then j.metric_unit end,
    'shared_by', case when v_sharer is not null then private.person(v_sharer) end,
    'can_react', case p_role
                   when 'member' then j.status = 'active'
                   when 'friend' then true
                   else j.public_token is not null and j.allow_public_reactions end,
    'can_reply', p_role = 'friend',
    'can_follow', j.status in ('ended', 'archived') or j.origin = 'imported',
    'can_add_owner', p_role = 'stranger' and j.allow_viewer_requests and j.owner_id <> uid
                     and (j.kind = 'solo' or private.consent_accepted(j.id, j.owner_id))
                     and not exists (select 1 from public.friendships f
                                      where f.user_low = least(uid, j.owner_id)
                                        and f.user_high = greatest(uid, j.owner_id)
                                        and f.deleted_at is null)
                     and not private.is_blocked_pair(j.owner_id),
    'saved', exists (select 1 from public.saved_journeys s where s.user_id = uid and s.journey_id = j.id));
end;
$$;

create or replace function public.follow_frame(p_journey uuid) returns json
language plpgsql stable security definer set search_path = ''
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
              and (private.has_active_share(j.id, uid) or j.public_token is not null))) then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if j.status not in ('ended', 'archived') and j.origin <> 'imported' then
    raise exception 'invalid';
  end if;
  -- A-B8: same rule as journey_view.
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
    'metric_unit', case when v_show_metric then j.metric_unit end);
end;
$$;

-- ---------------------------------------------------------------------------
-- A-B9 + A-B10: consent_json + share_consents (from 0006_social)
-- ---------------------------------------------------------------------------
create or replace function private.consent_json(c public.journey_share_consents) returns json
language sql stable security definer set search_path = ''
as $$
  select json_build_object(
    'journey_id', c.journey_id,
    'journey_title', (select title from public.journeys where id = c.journey_id),
    'member', private.person(c.user_id),
    'status', c.status,
    -- A-B10: the requester's account may be gone (on delete set null); A-B9: or blocked with
    -- the caller. Both read as the anonymous person, never as null.
    'requested_by', case
      when c.requested_by is null or private.blocked_between((select auth.uid()), c.requested_by)
        or not exists (select 1 from public.profiles p where p.id = c.requested_by)
      then json_build_object('user_id', '00000000-0000-0000-0000-000000000000',
                             'username', '', 'display_name', '', 'avatar_path', null)
      else private.person(c.requested_by) end,
    'decided_at', c.decided_at);
$$;

create or replace function public.share_consents(p_journey uuid) returns setof json
language plpgsql stable security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
begin
  if not private.is_member(p_journey) then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  return query
  select private.consent_json(c)
    from public.journey_share_consents c
    join public.memberships m on m.journey_id = c.journey_id and m.user_id = c.user_id
   where c.journey_id = p_journey and m.status = 'active' and m.deleted_at is null
     and not private.blocked_between(uid, c.user_id) -- A-B9
   order by m.joined_at, c.user_id;
end;
$$;

-- ---------------------------------------------------------------------------
-- A-B15: group_today (from 0014_multi_photo_per_day)
-- ---------------------------------------------------------------------------
create or replace function public.group_today(journey uuid)
returns table (
  user_id uuid,
  username text,
  display_name text,
  avatar_path text,
  role public.member_role,
  checked_in boolean,
  checkin_id uuid,
  thumb_path text,
  captured_at timestamptz,
  current_streak int
)
language plpgsql
stable
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  v_tz text;
  v_today date;
begin
  perform public._uid();
  if not private.is_member(journey) then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  select j.timezone into v_tz from public.journeys j where j.id = journey;
  v_today := public.local_date(now(), v_tz);

  return query
  select m.user_id, p.username, p.display_name, p.avatar_path, m.role,
         d.any_today,
         c.id,
         c.thumb_path,
         c.captured_at,
         coalesce(s.current_streak, 0)
    from public.memberships m
    join public.profiles p on p.id = m.user_id
    -- L7: checked_in counts every photo of today, even ones the caller reported.
    left join lateral (
      select exists (
        select 1 from public.check_ins c3
         where c3.journey_id = m.journey_id and c3.user_id = m.user_id
           and c3.local_date = v_today and c3.deleted_at is null) as any_today
    ) d on true
    -- A-B15: the latest photo of today the caller has not reported.
    left join lateral (
      select c2.id, c2.thumb_path, c2.captured_at
        from public.check_ins c2
       where c2.journey_id = m.journey_id and c2.user_id = m.user_id
         and c2.local_date = v_today and c2.deleted_at is null
         and not private.has_reported(c2.id)
       order by c2.captured_at desc, c2.id desc
       limit 1
    ) c on true
    left join lateral public.journey_streak(m.journey_id, m.user_id, v_today) s on true
   where m.journey_id = journey and m.status = 'active' and m.deleted_at is null
     and not private.is_blocked_pair(m.user_id)
   order by m.joined_at, m.user_id;
end;
$$;

-- ---------------------------------------------------------------------------
-- A-B16: join_by_code (from 0013_unlimited_journeys)
-- ---------------------------------------------------------------------------
create or replace function public.join_by_code(code text) returns public.journeys
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := public._uid();
  v_code text := upper(btrim(code));
  j public.journeys%rowtype;
  m public.memberships%rowtype;
  v_rejoin boolean;
begin
  -- Serialises attempts per user (also makes the throttle count exact).
  perform 1 from public.profiles where id = uid and deleted_at is null for update;
  if not found then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  delete from private.join_attempts
   where user_id = uid and attempted_at < now() - interval '1 hour';
  if (select count(*) from private.join_attempts where user_id = uid and not success) >= 10 then
    raise exception 'rate_limited';
  end if;

  if v_code is not null and v_code ~ '^[A-Z0-9]{8}$' then
    select * into j from public.journeys
     where invite_code = v_code and kind = 'group' and deleted_at is null
     for update;
  end if;
  if j.id is null then
    insert into private.join_attempts (user_id, success) values (uid, false);
    return null; -- not_found
  end if;

  if j.status <> 'active' then
    raise exception 'ended';
  end if;
  if j.duration_days is not null
     and public.local_date(now(), j.timezone) > j.start_date + j.duration_days - 1 then
    raise exception 'ended';
  end if;

  select * into m from public.memberships where journey_id = j.id and user_id = uid;
  v_rejoin := found;
  if v_rejoin and m.status = 'active' then
    return j; -- idempotent
  end if;
  if v_rejoin and m.removed_at is not null then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  -- A block in either direction between the joiner and any active member prevents joining.
  if exists (
    select 1
      from public.memberships am
      join public.blocks b
        on b.deleted_at is null
       and ((b.blocker_id = uid and b.blocked_id = am.user_id)
         or (b.blocked_id = uid and b.blocker_id = am.user_id))
     where am.journey_id = j.id and am.status = 'active' and am.deleted_at is null
  ) then
    raise exception 'blocked';
  end if;

  if (select count(*) from public.memberships
       where journey_id = j.id and status = 'active' and deleted_at is null) >= j.max_members then
    raise exception 'full';
  end if;

  if v_rejoin then
    -- Rejoin: keep original joined_at (personal progress), restore hidden check-ins.
    update public.memberships set status = 'active', role = 'member', deleted_at = null
     where journey_id = j.id and user_id = uid;
    update public.check_ins set deleted_at = null, hidden_by_leave = false
     where journey_id = j.id and user_id = uid and hidden_by_leave and moderated_at is null;
  else
    insert into public.memberships (journey_id, user_id, role, hide_metric)
    values (j.id, uid, 'member', j.hide_metric_default);
  end if;
  -- A-B16: joining by code answers any pending invitation to this group.
  update public.group_invitations set status = 'accepted', responded_at = now()
   where journey_id = j.id and invitee_id = uid and status = 'pending';
  return j;
end;
$$;

-- Pending invitations whose invitee is already an active member.
update public.group_invitations i set status = 'accepted', responded_at = now()
 where i.status = 'pending' and private.is_active_member(i.journey_id, i.invitee_id);

-- ---------------------------------------------------------------------------
-- C2: message_json (from 0006_social)
-- ---------------------------------------------------------------------------
create or replace function private.message_json(m public.messages) returns json
language sql stable security definer set search_path = ''
as $$
  select json_build_object(
    'id', m.id,
    'conversation_id', m.conversation_id,
    'sender_id', m.sender_id,
    'kind', m.kind,
    'body', m.body,
    'media_path', m.media_path,
    'reply_to_checkin_id', m.reply_to_checkin_id,
    -- C2: the thumb only when the caller may see that photo (same rules as journey_view).
    'reply_to_thumb_path', (select c.thumb_path from public.check_ins c
                              left join public.memberships a
                                on a.journey_id = c.journey_id and a.user_id = c.user_id
                             where c.id = m.reply_to_checkin_id and c.deleted_at is null
                               and not private.has_reported(c.id)
                               and not private.is_blocked_pair(c.user_id)
                               and (private.is_member(c.journey_id)
                                    or (private.viewer_can_see_checkin(c.id)
                                        and not coalesce(a.blur_media, true)))),
    'created_at', m.created_at);
$$;

-- ---------------------------------------------------------------------------
-- C3: journey_pending_invitations (from 0010_invite_management)
-- ---------------------------------------------------------------------------
create or replace function public.journey_pending_invitations(p_journey uuid) returns json
language plpgsql stable security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
begin
  if not exists (select 1 from public.memberships
                  where journey_id = p_journey and user_id = uid
                    and status = 'active' and deleted_at is null) then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  return coalesce((
    select json_agg(json_build_object(
      'id', i.id,
      'invitee', private.person(i.invitee_id),
      'inviter', private.person(i.inviter_id),
      'can_revoke', (i.inviter_id = uid or j.owner_id = uid),
      'created_at', i.created_at,
      'expires_at', i.expires_at) order by i.created_at desc)
      from public.group_invitations i
      join public.journeys j on j.id = i.journey_id and j.deleted_at is null
     where i.journey_id = p_journey and i.status = 'pending' and i.expires_at > now()
       and not private.blocked_between(uid, i.invitee_id)
       and not private.blocked_between(uid, i.inviter_id) -- C3
  ), '[]'::json);
end;
$$;

-- ---------------------------------------------------------------------------
-- C-B11: create_imported_journey takes the skin (layout) and "still going"
-- (p_continues): the journey stays active and open-ended (duration_days null) so the owner can
-- keep adding photos. Replaces the 9-argument function from 0006_social.
-- ---------------------------------------------------------------------------
drop function if exists public.create_imported_journey(
  uuid, text, text, public.template_id, date, date, text, text, text);

create function public.create_imported_journey(
  p_id uuid,
  p_title text,
  p_emoji text,
  p_template public.template_id,
  p_first date,
  p_last date,
  p_timezone text,
  p_metric_name text default null,
  p_metric_unit text default null,
  p_layout text default null,
  p_continues boolean default false
) returns public.journeys
language plpgsql security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
  j public.journeys%rowtype;
  v_days int;
begin
  if p_id is null or p_first is null or p_last is null or p_timezone is null then
    raise exception 'invalid';
  end if;
  perform now() at time zone p_timezone; -- 22023 for an unknown timezone
  v_days := p_last - p_first + 1;
  if v_days < 1 or v_days > 366 or p_last > public.local_date(now(), p_timezone) then
    raise exception 'invalid';
  end if;
  -- A solo journey: no squad skin, and the couple skin needs couple names.
  if p_layout is not null and p_layout not in
     ('quiet_transformer', 'memory_collectors', 'aesthetic_flexer', 'minimalist_habit') then
    raise exception 'invalid';
  end if;

  perform 1 from public.profiles where id = uid and deleted_at is null for update;
  if not found then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  select * into j from public.journeys where id = p_id;
  if found then
    if j.owner_id = uid then
      return j; -- idempotent
    end if;
    raise exception 'forbidden' using errcode = '42501';
  end if;

  insert into public.journeys (
    id, owner_id, kind, template_id, title, emoji, metric_name, metric_unit,
    hide_metric_default, start_date, duration_days, timezone, visibility, status,
    max_members, origin, layout)
  values (
    p_id, uid, 'solo', coalesce(p_template, 'custom'), btrim(p_title), p_emoji,
    p_metric_name, p_metric_unit, coalesce(p_template, 'custom') = 'weight_loss', p_first,
    case when coalesce(p_continues, false) then null else v_days end, p_timezone, 'private',
    case when coalesce(p_continues, false) then 'active' else 'ended' end::public.journey_status,
    1, 'imported', p_layout)
  returning * into j;
  insert into public.memberships (journey_id, user_id, role, hide_metric)
  values (j.id, uid, 'owner', j.hide_metric_default);
  return j;
end;
$$;

revoke execute on function
  public.create_imported_journey(uuid, text, text, public.template_id, date, date, text, text, text, text, boolean)
  from public, anon;
grant execute on function
  public.create_imported_journey(uuid, text, text, public.template_id, date, date, text, text, text, text, boolean)
  to authenticated, service_role;

-- Imported check-ins: the owner's photos stay inside start_date .. start + duration - 1 only
-- while the journey has a duration; an open-ended (continuing) one has no upper cap.
create or replace function public.check_ins_before_write() returns trigger
language plpgsql
set search_path = ''
as $$
declare
  j public.journeys%rowtype;
  v_imported boolean;
begin
  select * into j from public.journeys where id = new.journey_id;
  if not found then
    raise exception 'not_found' using errcode = 'P0001';
  end if;

  if tg_op = 'UPDATE' and (new.journey_id <> old.journey_id or new.user_id <> old.user_id) then
    raise exception 'immutable_column' using errcode = '23514';
  end if;

  new.local_date := public.local_date(new.captured_at, j.timezone);
  new.metric_value := null;
  -- A live (camera) photo on a journey that is still going follows the normal rules.
  v_imported := j.origin = 'imported' and new.user_id = j.owner_id
    and not (j.status = 'active' and j.duration_days is null and not new.from_library);

  if current_user in ('authenticated', 'anon') then
    if tg_op = 'UPDATE' and old.moderated_at is not null then
      raise exception 'forbidden' using errcode = '42501';
    end if;
    if new.captured_at > now() + interval '10 minutes' then
      raise exception 'invalid_captured_at' using errcode = '22008';
    end if;
    if v_imported then
      if j.deleted_at is not null or (j.duration_days is null and j.status <> 'active') then
        raise exception 'ended' using errcode = 'P0001';
      end if;
      if new.local_date < j.start_date
         or (j.duration_days is not null
             and new.local_date > j.start_date + j.duration_days - 1) then
        raise exception 'invalid_captured_at' using errcode = '22008';
      end if;
    else
      if (tg_op = 'INSERT' or new.captured_at is distinct from old.captured_at)
         and new.local_date < public.local_date(now(), j.timezone) - 3 then
        raise exception 'invalid_captured_at' using errcode = '22008';
      end if;
      if j.status <> 'active' or j.deleted_at is not null then
        raise exception 'ended' using errcode = 'P0001';
      end if;
      if j.duration_days is not null and new.local_date > j.start_date + j.duration_days - 1 then
        raise exception 'ended' using errcode = 'P0001';
      end if;
    end if;
    if tg_op = 'INSERT' then
      new.hidden_by_leave := false;
      new.moderated_at := null;
      new.hidden_in_share := false;
    else
      new.hidden_by_leave := old.hidden_by_leave;
      new.moderated_at := old.moderated_at;
      new.hidden_in_share := old.hidden_in_share;
    end if;
  end if;
  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- U16: the caller's own blocked people with real names (a fresh device has no
-- cached names). Only rows where the caller is the blocker; never who blocked them.
-- ---------------------------------------------------------------------------
create or replace function public.my_blocked_people() returns json
language plpgsql stable security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
begin
  return coalesce((
    select json_agg(json_build_object(
      'user_id', b.blocked_id,
      'username', p.username,
      'display_name', p.display_name,
      'avatar_path', p.avatar_path) order by b.created_at desc)
      from public.blocks b
      left join public.profiles p on p.id = b.blocked_id
     where b.blocker_id = uid and b.deleted_at is null
  ), '[]'::json);
end;
$$;

revoke all on function public.my_blocked_people() from public, anon;
grant execute on function public.my_blocked_people() to authenticated;
