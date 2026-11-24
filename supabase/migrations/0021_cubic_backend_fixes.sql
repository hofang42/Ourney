-- 0021_cubic_backend_fixes: Batch A backend & security fixes from cubic-scan.md.
--   CB-01  `public.leave_journey` rejects solo journeys (`kind <> 'group'`);
--          `public._leave_journey` revokes the leaver's `journey_shares`, sets their
--          `journey_share_consents` to `'withdrawn'` (reset to `'pending'` on rejoin in
--          `private.memberships_consent_pending`), and when `next_owner is null` clears
--          `public_token`, `saved_journeys`, and `journey_shares`; `private.owner_for_viewer`,
--          `private.can_see_profile`, `public.send_friend_request`, and `private.journey_view`
--          require `private.is_active_member(j.id, j.owner_id)`.
--   CB-02  `public.accept_friend_invite` locks/verifies the caller's active `public.profiles` row,
--          throttles lookups in `private.rate_events` (`<= 30/hour`), and only rejects
--          soft-deleted `friendships` when the invite pre-dates the removal/decline.
--   CB-21  `public.create_journey` rejects `p_visibility = 'link'` on live creation (Rule S9);
--          `public.create_journey` and `public.create_imported_journey` reject soft-deleted
--          tombstone ID collisions; `private.journeys_social_defaults` applies sensitive defaults
--          (`allow_public_reactions = false`, `allow_viewer_requests = false`, Rule S28) when
--          `layout = 'quiet_transformer'`.
--   CB-22  `private.is_member`, `private.is_owner`, and `private.is_active_member` require
--          `j.deleted_at is null`; `private.conversation_read_only`, `public.my_conversations`,
--          and `public.inbox_counts` exclude deleted journeys; `public.delete_journey` tombstones
--          `memberships` & `messages`, clears shares/links/saves/invites, and enqueues all
--          `checkins/{journey}/%` and `messages/{conv}/%` objects into `private.pending_storage_purge`.
--   CB-23  `public.open_conversation`, `public.send_message`, and `public.update_journey_story`
--          verify check-in visibility (`viewer_can_see_checkin` / `can_view_checkin`).
--   CB-24  `public.my_conversations` hides threads whose post-clear messages were all hidden,
--          reported, or deleted while keeping re-opened cleared threads visible to the viewer;
--          `public.mark_conversation_read` advances read timestamps monotonically.
--   CB-25  `public.journey_insights` and `public.my_reach` exclude current and former group
--          members from external `likes`/`likers`, require active valid grants for `from_friend`,
--          deduplicate `started_this_week` by distinct follower first-start date, and exclude
--          active members from view counts.
--   CB-26  `private.reactions_saved_sync` checks `private.checkin_shareable(c.id)` before keeping
--          `saved_journeys`; `reactions_update` and `public.reactions_before_write` allow users to
--          soft-delete their own reactions after settings/status changes; `public.mark_followed`
--          enforces Rule S9 (`s.status in ('ended', 'archived')`) and `followed_from` immutability.
--   CB-27  `public.account_media_paths` and `public.account_message_paths` use indexable
--          `o.name like '<prefix>/%'` queries; `public.claim_storage_purge` atomically claims rows
--          with `FOR UPDATE SKIP LOCKED` and a 2-minute `next_attempt_at` lease.
--   CB-28  `public.check_in_extras_valid` raises its UTF-8 byte cap from 512 to 1024;
--          `public.check_ins_before_write` allows pure author soft-deletes on ended journeys.
--   CB-57  Revokes direct `UPDATE (couple_self_name, couple_partner_name)` on `public.journeys`
--          from `authenticated`, bounds raw `char_length <= 24`, enforces couple/seat invariants
--          in `private.journeys_couple_seats`, raises `42501 forbidden` for non-owners in
--          `public.rename_couple` and `public.update_journey`, and adds `after_id` keyset
--          pagination to `public.checkin_tombstones`.
--   CB-73  `public.shared_with_me` breaks same-day cover ties by `c.captured_at desc, c.id desc`;
--          `public.unshare_journey` checks caller membership/shares before locking `public.journeys`.
-- Idempotent (create or replace, drop if exists, if not exists).

-- ---------------------------------------------------------------------------
-- CB-22: membership helpers require j.deleted_at is null; journeys_select keeps
--        owner tombstone visibility for multi-device purge sync
-- ---------------------------------------------------------------------------
create or replace function private.is_member(journey uuid) returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.memberships m
      join public.journeys j on j.id = m.journey_id and j.deleted_at is null
     where m.journey_id = journey
       and m.user_id = (select auth.uid())
       and m.status = 'active'
       and m.deleted_at is null
  );
$$;

create or replace function private.is_owner(journey uuid) returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.memberships m
      join public.journeys j on j.id = m.journey_id and j.deleted_at is null
     where m.journey_id = journey
       and m.user_id = (select auth.uid())
       and m.role = 'owner'
       and m.status = 'active'
       and m.deleted_at is null
  );
$$;

create or replace function private.is_active_member(p_journey uuid, p_user uuid) returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.memberships m
      join public.journeys j on j.id = m.journey_id and j.deleted_at is null
     where m.journey_id = p_journey and m.user_id = p_user
       and m.status = 'active' and m.deleted_at is null
  );
$$;

revoke all on function
  private.is_member(uuid),
  private.is_owner(uuid),
  private.is_active_member(uuid, uuid)
from public, anon;
grant execute on function
  private.is_member(uuid),
  private.is_owner(uuid),
  private.is_active_member(uuid, uuid)
to authenticated, service_role;

drop policy if exists journeys_select on public.journeys;
create policy journeys_select on public.journeys for select to authenticated
  using (
    private.is_member(id)
    or (owner_id = (select auth.uid()) and deleted_at is not null)
  );

create or replace function private.conversation_read_only(p_conversation uuid) returns boolean
language sql stable security definer set search_path = ''
as $$
  select coalesce((
    select j.deleted_at is not null
           or not private.are_friends(c.member_id, c.viewer_id)
           or private.blocked_between(c.member_id, c.viewer_id)
      from public.conversations c
      join public.journeys j on j.id = c.journey_id
     where c.id = p_conversation), true);
$$;

revoke all on function private.conversation_read_only(uuid) from public, anon;
grant execute on function private.conversation_read_only(uuid) to authenticated, service_role;

create or replace function public.delete_journey(journey uuid) returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := public._uid();
begin
  perform 1 from public.journeys where id = journey and deleted_at is null for update;
  if not found then
    raise exception 'not_found';
  end if;
  if not private.is_owner(journey) then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if exists (select 1 from public.memberships
              where journey_id = journey and user_id <> uid
                and status = 'active' and deleted_at is null) then
    raise exception 'not_alone';
  end if;

  -- CB-22: enqueue any remaining check-in media (including former co-members' files) and chat
  -- media for storage-purge-sweep using the nil sentinel user_id (immediately claimable).
  insert into private.pending_storage_purge (bucket, path, user_id)
  select distinct 'media', p.path, '00000000-0000-0000-0000-000000000000'::uuid
    from (
      select c.photo_path as path from public.check_ins c where c.journey_id = journey
      union all
      select c.thumb_path as path from public.check_ins c where c.journey_id = journey
      union all
      select c.partner_photo_path as path from public.check_ins c
       where c.journey_id = journey and c.partner_photo_path is not null
      union all
      select o.name as path from storage.objects o
       where o.bucket_id = 'media' and o.name like ('checkins/' || journey::text || '/%')
    ) p
   where p.path is not null and length(p.path) between 1 and 1024
  on conflict (bucket, path) do update
    set user_id = '00000000-0000-0000-0000-000000000000'::uuid,
        attempts = 0,
        next_attempt_at = now(),
        last_error = null;

  insert into private.pending_storage_purge (bucket, path, user_id)
  select distinct 'messages', p.path, '00000000-0000-0000-0000-000000000000'::uuid
    from (
      select m.media_path as path
        from public.messages m
        join public.conversations c on c.id = m.conversation_id
       where c.journey_id = journey and m.media_path is not null
      union all
      select o.name as path
        from public.conversations c
        join storage.objects o
          on o.bucket_id = 'messages'
         and o.name like ('messages/' || c.id::text || '/%')
       where c.journey_id = journey
    ) p
   where p.path is not null and length(p.path) between 1 and 1024
  on conflict (bucket, path) do update
    set user_id = '00000000-0000-0000-0000-000000000000'::uuid,
        attempts = 0,
        next_attempt_at = now(),
        last_error = null;

  update public.journeys
     set deleted_at = now(),
         status = 'archived',
         public_token = null,
         visibility = case when kind = 'solo' then 'private'::public.journey_visibility else visibility end
   where id = journey;

  update public.check_ins set deleted_at = now()
   where journey_id = journey and deleted_at is null;

  update public.memberships set status = 'left', deleted_at = now()
   where journey_id = journey and (deleted_at is null or status <> 'left');

  update public.journey_shares set revoked_at = now()
   where journey_id = journey and revoked_at is null;

  delete from public.saved_journeys where journey_id = journey;

  update public.group_invitations set status = 'revoked', responded_at = now()
   where journey_id = journey and status = 'pending';

  update public.messages m set deleted_at = now()
    from public.conversations c
   where c.id = m.conversation_id and c.journey_id = journey and m.deleted_at is null;
end;
$$;

-- Backfill any already soft-deleted journeys so their memberships/shares/links/messages are clean.
update public.journeys
   set status = 'archived',
       public_token = null,
       visibility = case when kind = 'solo' then 'private'::public.journey_visibility else visibility end
 where deleted_at is not null
   and (public_token is not null or status <> 'archived' or (kind = 'solo' and visibility <> 'private'));

update public.memberships m
   set status = 'left', deleted_at = coalesce(m.deleted_at, j.deleted_at)
  from public.journeys j
 where j.id = m.journey_id and j.deleted_at is not null
   and (m.deleted_at is null or m.status <> 'left');

update public.journey_shares s
   set revoked_at = coalesce(s.revoked_at, j.deleted_at)
  from public.journeys j
 where j.id = s.journey_id and j.deleted_at is not null and s.revoked_at is null;

delete from public.saved_journeys s
 using public.journeys j
 where j.id = s.journey_id and j.deleted_at is not null;

update public.group_invitations i
   set status = 'revoked', responded_at = coalesce(i.responded_at, j.deleted_at)
  from public.journeys j
 where j.id = i.journey_id and j.deleted_at is not null and i.status = 'pending';

-- ---------------------------------------------------------------------------
-- CB-01: leave_journey, _leave_journey, memberships_consent_pending,
--        owner_for_viewer, can_see_profile, send_friend_request, journey_view
-- ---------------------------------------------------------------------------
create or replace function public.leave_journey(journey uuid) returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := public._uid();
  v_kind public.journey_kind;
begin
  select j.kind into v_kind
    from public.journeys j
    join public.memberships m on m.journey_id = j.id and m.user_id = uid
   where j.id = journey and j.deleted_at is null
     and m.status = 'active' and m.deleted_at is null
   for update of j, m;
  if not found then
    raise exception 'not_found';
  end if;
  if v_kind <> 'group' then
    raise exception 'invalid';
  end if;
  perform public._leave_journey(journey, uid);
end;
$$;

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
  -- CB-01: leaving a group withdraws share consent and revokes friend shares granted by the leaver.
  update public.journey_shares set revoked_at = now()
   where journey_id = p_journey and shared_by = p_user and revoked_at is null;
  update public.journey_share_consents set status = 'withdrawn', decided_at = now()
   where journey_id = p_journey and user_id = p_user and status <> 'withdrawn';

  if was_owner then
    -- Lock candidate next_owner profile FOR KEY SHARE so concurrent RPCs holding
    -- FOR NO KEY UPDATE on profiles never block ownership transfer.
    select m.user_id into next_owner
      from public.memberships m
      join public.profiles p on p.id = m.user_id and p.deleted_at is null
     where m.journey_id = p_journey and m.status = 'active' and m.deleted_at is null
     order by m.joined_at, m.user_id
     limit 1
     for key share of p;
    if next_owner is null then
      update public.journeys
         set status = 'archived',
             public_token = null,
             visibility = case when kind = 'solo' then 'private'::public.journey_visibility else visibility end
       where id = p_journey;
      delete from public.saved_journeys where journey_id = p_journey;
      update public.journey_shares set revoked_at = now()
       where journey_id = p_journey and revoked_at is null;
    else
      update public.memberships set role = 'owner'
       where journey_id = p_journey and user_id = next_owner;
      update public.journeys set owner_id = next_owner where id = p_journey;
    end if;
  end if;
end;
$$;

revoke all on function public._leave_journey(uuid, uuid) from public, anon, authenticated;

create or replace function private.memberships_consent_pending() returns trigger
language plpgsql security definer set search_path = ''
as $$
declare
  v_by uuid;
begin
  if new.status <> 'active' or new.deleted_at is not null then
    return null;
  end if;
  select requested_by into v_by from public.journey_share_consents
   where journey_id = new.journey_id order by created_at limit 1;
  if not found then
    return null;
  end if;
  insert into public.journey_share_consents (journey_id, user_id, status, requested_by)
  values (new.journey_id, new.user_id, 'pending', v_by)
  on conflict (journey_id, user_id) do update
    set status = 'pending',
        requested_by = excluded.requested_by,
        decided_at = null
    where public.journey_share_consents.status = 'withdrawn'
      and tg_op = 'UPDATE'
      and old.status is distinct from new.status;
  return null;
end;
$$;

revoke all on function private.memberships_consent_pending() from public, anon, authenticated;

-- Clean up any already-abandoned journeys on hosted data where no active member remains.
update public.journeys j
   set status = 'archived',
       public_token = null,
       visibility = case when j.kind = 'solo' then 'private'::public.journey_visibility else j.visibility end
 where not exists (
   select 1 from public.memberships m
    where m.journey_id = j.id and m.status = 'active' and m.deleted_at is null
 )
   and (j.public_token is not null or j.status <> 'archived');

delete from public.saved_journeys s
 where not exists (
   select 1 from public.journeys j
    where j.id = s.journey_id and j.deleted_at is null and j.public_token is not null
 );

create or replace function private.owner_for_viewer(p_journey uuid) returns json
language sql stable security definer set search_path = ''
as $$
  select case when private.is_active_member(j.id, j.owner_id)
                   and (j.kind = 'solo'
                        or private.is_active_member(j.id, (select auth.uid()))
                        or private.consent_accepted(j.id, j.owner_id))
                   and not private.blocked_between((select auth.uid()), j.owner_id)
              then private.person(j.owner_id)
              else json_build_object('user_id', '00000000-0000-0000-0000-000000000000',
                                     'username', '', 'display_name', '', 'avatar_path', null)
         end
    from public.journeys j where j.id = p_journey and j.deleted_at is null;
$$;

create or replace function private.can_see_profile(other uuid) returns boolean
language sql stable security definer set search_path = ''
as $$
  select other = (select auth.uid())
      or (not private.is_blocked_pair(other)
          and (
            exists (
              select 1 from public.memberships a
                join public.memberships b on b.journey_id = a.journey_id
                join public.journeys j on j.id = a.journey_id and j.deleted_at is null
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
                join public.journeys j on j.id = c.journey_id and j.deleted_at is null
               where (c.member_id = other and c.viewer_id = (select auth.uid()))
                  or (c.viewer_id = other and c.member_id = (select auth.uid())))
            or exists (
              select 1 from public.journeys j
               where j.deleted_at is null
                 and private.is_active_member(j.id, other)
                 and ((j.owner_id = other and j.kind = 'solo') or private.consent_accepted(j.id, other))
                 and (private.has_active_share(j.id, (select auth.uid()))
                      or (j.public_token is not null
                          and exists (select 1 from public.saved_journeys s
                                       where s.journey_id = j.id and s.user_id = (select auth.uid())))))
          ));
$$;

revoke all on function private.owner_for_viewer(uuid), private.can_see_profile(uuid) from public, anon;
grant execute on function private.owner_for_viewer(uuid), private.can_see_profile(uuid) to authenticated, service_role;

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
    if j.public_token is null or not j.allow_viewer_requests or j.owner_id <> p_user
       or not private.is_active_member(j.id, j.owner_id)
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
  v_show_couple boolean;
  v_eval_today date;
  v_cover_id uuid;
  v_cover_blurred boolean := false;
begin
  select * into j from public.journeys where id = p_journey;
  v_counts := v_member or j.show_counts;
  v_show_metric := v_member or exists (
    select 1 from public.memberships m
     where m.journey_id = j.id and m.user_id = j.owner_id and not m.hide_metric);
  v_show_couple := v_member or j.kind = 'solo' or (
    private.consent_accepted(j.id, j.owner_id)
    and not exists (
      select 1 from public.memberships cm
       where cm.journey_id = j.id and cm.status = 'active' and cm.deleted_at is null
         and (not private.consent_accepted(j.id, cm.user_id) or private.is_blocked_pair(cm.user_id))
    )
  );

  select coalesce(json_agg(json_build_object(
           'checkin_id', ph.id,
           'author', private.person(ph.user_id),
           'local_date', ph.local_date,
           'photo_path', case when not v_member and ph.blur_media then '' else ph.photo_path end,
           'thumb_path', case when not v_member and ph.blur_media then '' else ph.thumb_path end,
           'partner_photo_path', case when (not v_member and ph.blur_media) or not v_show_couple then null else ph.partner_photo_path end,
           'caption', ph.caption,
           'metric_value', case when ph.user_id = uid or not ph.hide_metric then cm.metric_value end,
           'like_count', case when v_counts then rc.cnt else 0 end,
           'liked_by_me', rc.mine,
           'blurred', (not v_member and ph.blur_media))
           order by ph.local_date, ph.captured_at, ph.id), '[]'::json),
         coalesce(sum(rc.cnt), 0)::int
    into v_photos, v_total
    from (
      select c.id, c.user_id, c.local_date, c.photo_path, c.thumb_path, c.partner_photo_path,
             c.caption, c.captured_at, m.hide_metric, m.blur_media
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
    if j.status in ('ended', 'archived') then
      select least(public.local_date(now(), j.timezone),
                   coalesce(max(c.local_date), j.start_date))
        into v_eval_today
        from public.check_ins c
       where c.journey_id = j.id and c.user_id = j.owner_id and c.deleted_at is null;
    else
      v_eval_today := public.local_date(now(), j.timezone);
    end if;
    select s.current_streak into v_streak from public.journey_streak(j.id, j.owner_id, v_eval_today) s;
    v_streak := coalesce(v_streak, 0);
  else
    v_streak := coalesce(private.group_streak(j.id), 0);
  end if;

  if p_role = 'friend' then
    v_sharer := private.earliest_sharer(p_journey, uid);
  end if;

  if j.cover_checkin_id is not null and (v_member or private.checkin_shareable(j.cover_checkin_id)) then
    v_cover_id := j.cover_checkin_id;
    if not v_member then
      select coalesce(m.blur_media, true) into v_cover_blurred
        from public.check_ins c
        left join public.memberships m on m.journey_id = c.journey_id and m.user_id = c.user_id
       where c.id = j.cover_checkin_id;
      v_cover_blurred := coalesce(v_cover_blurred, false);
    end if;
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
    'layout', j.layout,
    'color', j.color,
    'cover', j.cover,
    'couple_self_name', case when v_show_couple then j.couple_self_name end,
    'couple_partner_name', case when v_show_couple then j.couple_partner_name end,
    'cover_blurred', v_cover_blurred,
    'owner', private.owner_for_viewer(j.id),
    'members', v_members,
    'story', json_build_object(
      'title', j.story_title, 'intro', j.story_intro, 'lessons', j.story_lessons,
      'cover_checkin_id', v_cover_id,
      'cover_blurred', v_cover_blurred),
    'photos', v_photos,
    'current_streak', v_streak,
    'like_count', case when v_counts then v_total end,
    'follow_count', case when v_counts then
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
    'can_follow', j.status in ('ended', 'archived'),
    'can_add_owner', p_role = 'stranger' and j.allow_viewer_requests and j.owner_id <> uid
                     and private.is_active_member(j.id, j.owner_id)
                     and (j.kind = 'solo' or private.consent_accepted(j.id, j.owner_id))
                     and not exists (select 1 from public.friendships f
                                      where f.user_low = least(uid, j.owner_id)
                                        and f.user_high = greatest(uid, j.owner_id)
                                        and f.deleted_at is null)
                     and not private.is_blocked_pair(j.owner_id),
    'saved', exists (select 1 from public.saved_journeys s where s.user_id = uid and s.journey_id = j.id));
end;
$$;

revoke all on function private.journey_view(uuid, text) from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- CB-02: create_friend_invite, accept_friend_invite, respond_friend_request,
--        remove_friend, blocks_sever
-- ---------------------------------------------------------------------------
create or replace function public.create_friend_invite() returns text
language plpgsql security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
  v_token text;
  v_created timestamptz;
begin
  perform 1 from public.profiles where id = uid and deleted_at is null for no key update;
  if not found then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  loop
    v_token := public.random_token(12, 'abcdefghijklmnopqrstuvwxyz0123456789');
    exit when not exists (select 1 from public.friend_invites where token = v_token);
  end loop;
  v_created := greatest(
    clock_timestamp(),
    coalesce((
      select max(greatest(f.updated_at, coalesce(f.deleted_at, '-infinity'::timestamptz))) + interval '1 microsecond'
        from public.friendships f
       where uid in (f.user_low, f.user_high) and f.deleted_at is not null
    ), '-infinity'::timestamptz)
  );
  insert into public.friend_invites (user_id, token, created_at)
  values (uid, v_token, v_created)
  on conflict (user_id) do update
    set token = excluded.token,
        created_at = excluded.created_at;
  return v_token;
end;
$$;

create or replace function public.respond_friend_request(p_user uuid, p_accept boolean) returns void
language plpgsql security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
begin
  if coalesce(p_accept, false) then
    update public.friendships set status = 'accepted', accepted_at = now()
     where user_low = least(uid, p_user) and user_high = greatest(uid, p_user)
       and status = 'pending' and requested_by = p_user and deleted_at is null;
  else
    update public.friendships
       set deleted_at = greatest(
             clock_timestamp(),
             coalesce((
               select max(i.created_at) from public.friend_invites i
                where i.user_id in (least(uid, p_user), greatest(uid, p_user))
             ), '-infinity'::timestamptz))
     where user_low = least(uid, p_user) and user_high = greatest(uid, p_user)
       and status = 'pending' and requested_by = p_user and deleted_at is null;
  end if;
  if not found then
    raise exception 'not_found';
  end if;
end;
$$;

create or replace function public.remove_friend(p_user uuid) returns void
language plpgsql security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
begin
  if p_user is null or p_user = uid then
    raise exception 'invalid';
  end if;
  update public.friendships
     set deleted_at = greatest(
           clock_timestamp(),
           coalesce((
             select max(i.created_at) from public.friend_invites i
              where i.user_id in (least(uid, p_user), greatest(uid, p_user))
           ), '-infinity'::timestamptz))
   where user_low = least(uid, p_user) and user_high = greatest(uid, p_user) and deleted_at is null;
  perform private.sever_pair(uid, p_user);
end;
$$;

create or replace function private.blocks_sever() returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  if new.deleted_at is null then
    perform private.sever_pair(new.blocker_id, new.blocked_id);
    update public.friendships
       set deleted_at = greatest(
             clock_timestamp(),
             coalesce((
               select max(i.created_at) from public.friend_invites i
                where i.user_id in (least(new.blocker_id, new.blocked_id), greatest(new.blocker_id, new.blocked_id))
             ), '-infinity'::timestamptz))
     where user_low = least(new.blocker_id, new.blocked_id)
       and user_high = greatest(new.blocker_id, new.blocked_id)
       and deleted_at is null;
  end if;
  return null;
end;
$$;

revoke all on function private.blocks_sever() from public, anon, authenticated;

create or replace function public.accept_friend_invite(p_token text) returns json
language plpgsql security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
  v_inviter uuid;
  v_invite_created timestamptz;
begin
  perform 1 from public.profiles where id = uid and deleted_at is null for no key update;
  if not found then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  delete from private.rate_events where user_id = uid and at < now() - interval '1 day';
  if (select count(*) from private.rate_events
       where user_id = uid and kind = 'friend_invite' and at > now() - interval '1 hour') >= 30 then
    raise exception 'rate_limited';
  end if;
  insert into private.rate_events (user_id, kind) values (uid, 'friend_invite');

  select i.user_id, i.created_at into v_inviter, v_invite_created
    from public.friend_invites i
    join public.profiles p on p.id = i.user_id and p.deleted_at is null
   where i.token = lower(btrim(coalesce(p_token, '')));
  if v_inviter is null then
    raise exception 'not_found';
  end if;
  if v_inviter = uid then
    raise exception 'invalid';
  end if;
  if private.blocked_between(uid, v_inviter) then
    raise exception 'blocked';
  end if;
  -- CB-02: an old link predating a decline/removal must not undo it, whereas a freshly rotated
  -- invite link (created_at > friendship removal/update) revives the friendship.
  if exists (select 1 from public.friendships f
              where f.user_low = least(uid, v_inviter) and f.user_high = greatest(uid, v_inviter)
                and f.deleted_at is not null
                and v_invite_created <= greatest(f.updated_at, f.deleted_at)) then
    raise exception 'invalid';
  end if;
  insert into public.friendships (user_low, user_high, requested_by, status, source, accepted_at)
  values (least(uid, v_inviter), greatest(uid, v_inviter), v_inviter, 'accepted', 'direct', now())
  on conflict (user_low, user_high) do update
    set requested_by = case when public.friendships.deleted_at is null
                            then public.friendships.requested_by else excluded.requested_by end,
        status = 'accepted',
        accepted_at = case when public.friendships.status = 'accepted' and public.friendships.deleted_at is null
                           then public.friendships.accepted_at else now() end,
        source = case when public.friendships.deleted_at is null then public.friendships.source else 'direct' end,
        source_journey_id = case when public.friendships.deleted_at is null
                                 then public.friendships.source_journey_id else null end,
        deleted_at = null;
  return private.person(v_inviter);
end;
$$;

-- ---------------------------------------------------------------------------
-- CB-21: create_journey (Rule S9 & soft-deleted idempotency),
--        create_imported_journey (soft-deleted idempotency),
--        journeys_social_defaults (layout = 'quiet_transformer', Rule S28)
-- ---------------------------------------------------------------------------
create or replace function private.journeys_social_defaults() returns trigger
language plpgsql set search_path = ''
as $$
begin
  if (tg_op = 'INSERT' and (new.template_id = 'weight_loss' or new.layout = 'quiet_transformer'))
     or (tg_op = 'UPDATE' and new.layout = 'quiet_transformer' and old.layout is distinct from 'quiet_transformer') then
    new.allow_public_reactions := false;
    new.allow_viewer_requests := false;
  end if;
  return new;
end;
$$;

drop trigger if exists journeys_social_defaults on public.journeys;
create trigger journeys_social_defaults
  before insert or update of layout
  on public.journeys
  for each row execute function private.journeys_social_defaults();
revoke all on function private.journeys_social_defaults() from public, anon, authenticated;

update public.journeys
   set allow_public_reactions = false,
       allow_viewer_requests = false
 where (template_id = 'weight_loss' or layout = 'quiet_transformer')
   and (allow_public_reactions or allow_viewer_requests);

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
  v_self text := nullif(btrim(p_couple_self_name), '');
  v_partner text := nullif(btrim(p_couple_partner_name), '');
begin
  if p_id is null or p_kind is null or p_start_date is null or p_timezone is null then
    raise exception 'invalid';
  end if;
  -- CB-21 (Rule S9): live active journeys cannot be created with visibility = 'link'.
  if coalesce(p_visibility, 'private') = 'link'
     or (p_kind = 'solo' and p_visibility = 'group') then
    raise exception 'invalid';
  end if;
  if (v_self is null) <> (v_partner is null)
     or char_length(coalesce(v_self, '')) > 24 or char_length(coalesce(v_partner, '')) > 24 then
    raise exception 'invalid';
  end if;

  perform 1 from public.profiles where id = uid and deleted_at is null for no key update;
  if not found then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  select * into j from public.journeys where id = p_id;
  if found then
    if j.owner_id = uid and j.deleted_at is null then
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
  else
    v_visibility := 'private';
  end if;

  insert into public.journeys (
    id, owner_id, kind, template_id, title, emoji, metric_name, metric_unit,
    hide_metric_default, start_date, duration_days, timezone, visibility, status,
    invite_code, max_members, public_token, couple_self_name, couple_partner_name)
  values (
    p_id, uid, p_kind, coalesce(p_template_id, 'custom'), btrim(p_title), btrim(p_emoji),
    p_metric_name, p_metric_unit, coalesce(p_hide_metric_default, false), p_start_date,
    p_duration_days, p_timezone, v_visibility, 'active', v_code,
    case when p_kind = 'solo' then 1
         when v_self is not null then 2
         else coalesce(p_max_members, 10) end,
    null, v_self, v_partner)
  returning * into j;

  insert into public.memberships (journey_id, user_id, role, hide_metric)
  values (j.id, uid, 'owner', j.hide_metric_default);

  return j;
end;
$$;

create or replace function public.create_imported_journey(
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
  if p_layout is not null and p_layout not in
     ('quiet_transformer', 'memory_collectors', 'aesthetic_flexer', 'minimalist_habit') then
    raise exception 'invalid';
  end if;

  perform 1 from public.profiles where id = uid and deleted_at is null for no key update;
  if not found then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  select * into j from public.journeys where id = p_id;
  if found then
    if j.owner_id = uid and j.deleted_at is null then
      return j; -- idempotent
    end if;
    raise exception 'forbidden' using errcode = '42501';
  end if;

  insert into public.journeys (
    id, owner_id, kind, template_id, title, emoji, metric_name, metric_unit,
    hide_metric_default, start_date, duration_days, timezone, visibility, status,
    max_members, origin, layout, import_end_date)
  values (
    p_id, uid, 'solo', coalesce(p_template, 'custom'), btrim(p_title), btrim(p_emoji),
    p_metric_name, p_metric_unit, coalesce(p_template, 'custom') = 'weight_loss', p_first,
    case when coalesce(p_continues, false) then null else v_days end, p_timezone, 'private',
    case when coalesce(p_continues, false) then 'active' else 'ended' end::public.journey_status,
    1, 'imported', p_layout, p_last)
  returning * into j;
  insert into public.memberships (journey_id, user_id, role, hide_metric, joined_at)
  values (j.id, uid, 'owner', j.hide_metric_default,
          (p_first::text || ' 00:00:00')::timestamp at time zone p_timezone);
  return j;
end;
$$;

-- ---------------------------------------------------------------------------
-- CB-23 + CB-24: open_conversation, send_message, update_journey_story,
--                my_conversations, inbox_counts, mark_conversation_read,
--                clear_conversation
-- ---------------------------------------------------------------------------
alter table public.conversations add column if not exists viewer_reopened_at timestamptz;

create or replace function public.open_conversation(p_journey uuid, p_checkin uuid default null) returns uuid
language plpgsql security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
  j public.journeys%rowtype;
  v_author uuid;
  v_to uuid;
  v_id uuid;
begin
  select * into j from public.journeys where id = p_journey and deleted_at is null;
  if not found then
    raise exception 'not_found';
  end if;
  -- Friend grantees only (strangers and members cannot open a reply thread).
  if private.is_member(p_journey) or not private.has_active_share(p_journey, uid) then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if p_checkin is not null then
    select c.user_id into v_author
      from public.check_ins c
     where c.id = p_checkin and c.journey_id = p_journey
       and private.viewer_can_see_checkin(c.id);
    if v_author is null then
      raise exception 'invalid';
    end if;
  end if;
  if j.kind = 'solo' then
    v_to := j.owner_id;
  elsif v_author is not null and v_author <> uid
        and private.are_friends(uid, v_author)
        and private.is_active_member(p_journey, v_author)
        and private.consent_accepted(p_journey, v_author) then
    v_to := v_author;
  else
    v_to := private.earliest_sharer(p_journey, uid);
  end if;
  if v_to is null or private.blocked_between(uid, v_to) then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  insert into public.conversations (journey_id, member_id, viewer_id)
  values (p_journey, v_to, uid)
  on conflict (journey_id, member_id, viewer_id) do update
    set viewer_reopened_at = case
          when public.conversations.viewer_cleared_at is not null
          then greatest(now(), public.conversations.viewer_cleared_at + interval '1 microsecond')
          else public.conversations.viewer_reopened_at
        end
  returning id into v_id;
  return v_id;
end;
$$;

create or replace function public.send_message(p_id uuid, p_conversation uuid, p_kind text, p_body text, p_media_path text,
                                               p_reply_to uuid default null)
returns json
language plpgsql security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
  c public.conversations%rowtype;
  m public.messages%rowtype;
  v_body text := nullif(btrim(p_body), '');
  v_media text;
begin
  if p_id is null then
    raise exception 'invalid';
  end if;
  select * into c from public.conversations where id = p_conversation for update;
  if not found then
    raise exception 'not_found';
  end if;
  if uid not in (c.member_id, c.viewer_id) then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  select * into m from public.messages where id = p_id;
  if found then
    if m.sender_id = uid and m.conversation_id = p_conversation then
      return private.message_json(m); -- idempotent retry
    end if;
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if private.conversation_read_only(p_conversation) then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if p_kind = 'text' then
    if v_body is null or char_length(v_body) > 500 then
      raise exception 'invalid';
    end if;
  elsif p_kind = 'photo' then
    v_media := p_media_path;
    if v_media is null
       or v_media <> ('messages/' || p_conversation::text || '/' || uid::text || '/' || p_id::text || '.jpg')
       or char_length(v_body) > 500 then
      raise exception 'invalid';
    end if;
  else
    raise exception 'invalid'; -- 'clip' ships with v0.2
  end if;
  if p_reply_to is not null and not exists (
       select 1 from public.check_ins ci
        where ci.id = p_reply_to and ci.journey_id = c.journey_id
          and ci.deleted_at is null and ci.moderated_at is null
          and private.is_active_member(c.journey_id, ci.user_id)
          and (private.can_view_checkin(ci.id) or private.viewer_can_see_checkin(ci.id))) then
    raise exception 'invalid';
  end if;
  if (select count(*) from public.messages
       where sender_id = uid and created_at > now() - interval '1 minute') >= 60 then
    raise exception 'rate_limited';
  end if;

  insert into public.messages (id, conversation_id, sender_id, kind, body, media_path, reply_to_checkin_id)
  values (p_id, p_conversation, uid, p_kind, v_body, v_media, p_reply_to)
  returning * into m;
  update public.conversations
     set last_message_at = m.created_at,
         member_read_at = case when member_id = uid then greatest(coalesce(member_read_at, '-infinity'::timestamptz), m.created_at) else member_read_at end,
         viewer_read_at = case when viewer_id = uid then greatest(coalesce(viewer_read_at, '-infinity'::timestamptz), m.created_at) else viewer_read_at end
   where id = p_conversation;
  return private.message_json(m);
end;
$$;

create or replace function public.update_journey_story(p_journey uuid, p_title text, p_intro text, p_lessons text, p_cover uuid)
returns void
language plpgsql security definer set search_path = ''
as $$
declare
  v_title text := nullif(btrim(p_title), '');
  v_intro text := nullif(btrim(p_intro), '');
  v_lessons text := nullif(btrim(p_lessons), '');
begin
  perform public._uid();
  perform 1 from public.journeys where id = p_journey and deleted_at is null for update;
  if not found then
    raise exception 'not_found';
  end if;
  if not private.is_owner(p_journey) then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if char_length(v_title) > 80 or char_length(v_intro) > 600 or char_length(v_lessons) > 600 then
    raise exception 'invalid';
  end if;
  if p_cover is not null and not exists (
       select 1 from public.check_ins c
        where c.id = p_cover and c.journey_id = p_journey
          and c.deleted_at is null and c.moderated_at is null
          and private.can_view_checkin(c.id)
          and private.is_active_member(p_journey, c.user_id)) then
    raise exception 'invalid';
  end if;
  update public.journeys
     set story_title = v_title, story_intro = v_intro, story_lessons = v_lessons, cover_checkin_id = p_cover
   where id = p_journey;
end;
$$;

create or replace function public.my_conversations() returns setof json
language plpgsql stable security definer set search_path = ''
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
              where m.conversation_id = c.id and m.sender_id <> uid and m.deleted_at is null
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
    join public.journeys j on j.id = c.journey_id and j.deleted_at is null
    cross join lateral (
      select case when c.member_id = uid then c.viewer_id else c.member_id end as other,
             case when c.member_id = uid then c.member_read_at else c.viewer_read_at end as read_at,
             case when c.member_id = uid then c.member_cleared_at else c.viewer_cleared_at end as cleared_at) x
    left join lateral (
      select m.created_at, m.body, m.kind from public.messages m
       where m.conversation_id = c.id and m.deleted_at is null
         and m.created_at > coalesce(x.cleared_at, '-infinity'::timestamptz)
         and not exists (select 1 from public.message_hides h where h.message_id = m.id and h.user_id = uid)
         and not exists (select 1 from public.reports r
                          where r.target_message_id = m.id and r.reporter_id = uid and r.deleted_at is null)
       order by m.created_at desc, m.id desc limit 1) lm on true
   where uid in (c.member_id, c.viewer_id)
     and not private.blocked_between(c.member_id, c.viewer_id)
     and (
       x.cleared_at is null
       or lm.created_at is not null
       or (c.viewer_id = uid and c.viewer_reopened_at is not null and c.viewer_reopened_at > c.viewer_cleared_at)
     )
   order by coalesce(lm.created_at, c.last_message_at, c.created_at) desc, c.id;
end;
$$;

create or replace function public.inbox_counts() returns json
language plpgsql stable security definer set search_path = ''
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
        join public.journeys j on j.id = c.journey_id and j.deleted_at is null
        join public.messages m on m.conversation_id = c.id
       where uid in (c.member_id, c.viewer_id)
         and not private.blocked_between(c.member_id, c.viewer_id)
         and m.sender_id <> uid and m.deleted_at is null
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
                            and private.blocked_between(uid, am.user_id))));
end;
$$;

create or replace function public.mark_conversation_read(p_conversation uuid) returns void
language plpgsql security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
begin
  update public.conversations
     set member_read_at = case
           when member_id = uid
           then greatest(coalesce(member_read_at, '-infinity'::timestamptz), coalesce(last_message_at, now()), now())
           else member_read_at
         end,
         viewer_read_at = case
           when viewer_id = uid
           then greatest(coalesce(viewer_read_at, '-infinity'::timestamptz), coalesce(last_message_at, now()), now())
           else viewer_read_at
         end
   where id = p_conversation and uid in (member_id, viewer_id);
  if not found then
    raise exception 'not_found';
  end if;
end;
$$;

create or replace function public.clear_conversation(p_conversation uuid) returns void
language plpgsql security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
  c public.conversations%rowtype;
begin
  update public.conversations
     set member_cleared_at = case
           when member_id = uid
           then greatest(coalesce(member_cleared_at, '-infinity'::timestamptz), coalesce(last_message_at, now()), now())
           else member_cleared_at
         end,
         viewer_cleared_at = case
           when viewer_id = uid
           then greatest(coalesce(viewer_cleared_at, '-infinity'::timestamptz), coalesce(last_message_at, now()), now())
           else viewer_cleared_at
         end,
         viewer_reopened_at = case when viewer_id = uid then null else viewer_reopened_at end
   where id = p_conversation and uid in (member_id, viewer_id)
  returning * into c;
  if not found then
    raise exception 'not_found';
  end if;
  -- S37: a message both sides cleared is gone for good; queue its media for storage-purge-sweep.
  if c.member_cleared_at is not null and c.viewer_cleared_at is not null then
    insert into private.pending_storage_purge (bucket, path, user_id)
    select distinct 'messages', m.media_path, '00000000-0000-0000-0000-000000000000'::uuid
      from public.messages m
     where m.conversation_id = p_conversation
       and m.created_at <= least(c.member_cleared_at, c.viewer_cleared_at)
       and m.media_path is not null
       and length(m.media_path) between 1 and 1024
    on conflict (bucket, path) do update
      set user_id = '00000000-0000-0000-0000-000000000000'::uuid,
          attempts = 0,
          next_attempt_at = now(),
          last_error = null;

    delete from public.messages
     where conversation_id = p_conversation
       and created_at <= least(c.member_cleared_at, c.viewer_cleared_at);
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- CB-25: journey_insights & my_reach
-- ---------------------------------------------------------------------------
create or replace function public.journey_insights(p_journey uuid) returns json
language plpgsql stable security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
  j public.journeys%rowtype;
  v_week date;
begin
  select * into j from public.journeys where id = p_journey and deleted_at is null;
  if not found then
    raise exception 'not_found';
  end if;
  if not private.is_member(p_journey) then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  v_week := public.local_date(now(), j.timezone) - 6;
  return (
    with likes as (
      select r.user_id, r.created_at,
             exists (
               select 1 from public.journey_shares s
                where s.journey_id = p_journey
                  and s.viewer_id = r.user_id
                  and s.revoked_at is null
                  and private.grant_valid(s.journey_id, s.viewer_id, s.shared_by)
             ) as from_friend
        from public.reactions r
        join public.check_ins c on c.id = r.checkin_id
       where c.journey_id = p_journey
         and r.deleted_at is null
         and private.checkin_shareable(c.id)
         and not private.is_blocked_pair(r.user_id)
         and not exists (
           select 1 from public.memberships m
            where m.journey_id = p_journey and m.user_id = r.user_id
         )
    ), firsts as (
      select v.viewer_key, min(v.day) as first_day
        from public.journey_views v
       where v.journey_id = p_journey
         and not exists (
           select 1 from public.memberships m
            where m.journey_id = p_journey
              and m.user_id = public.try_uuid(v.viewer_key)
              and m.status = 'active' and m.deleted_at is null
         )
       group by v.viewer_key
    )
    select json_build_object(
      'journey_id', j.id,
      'views', (select count(*)::int from firsts),
      'views_by_day', coalesce((
        select json_agg(json_build_object('day', d.day, 'count', d.n) order by d.day)
          from (
            select v.day, count(distinct v.viewer_key)::int as n
              from public.journey_views v
             where v.journey_id = p_journey
               and not exists (
                 select 1 from public.memberships m
                  where m.journey_id = p_journey
                    and m.user_id = public.try_uuid(v.viewer_key)
                    and m.status = 'active' and m.deleted_at is null
               )
             group by v.day
          ) d), '[]'::json),
      'likes_from_friends', (select count(*)::int from likes where from_friend),
      'likes_from_strangers', (select count(*)::int from likes where not from_friend),
      'started', (select count(distinct f.owner_id)::int from public.journeys f
                   where f.followed_from = p_journey and f.deleted_at is null),
      'views_this_week', (select count(*)::int from firsts where first_day >= v_week),
      'likes_this_week', (select count(*)::int from likes
                           where public.local_date(created_at, j.timezone) >= v_week),
      'started_this_week', (
        select count(*)::int
          from (
            select f.owner_id, min(public.local_date(f.created_at, j.timezone)) as first_day
              from public.journeys f
             where f.followed_from = p_journey and f.deleted_at is null
             group by f.owner_id
          ) sf
         where sf.first_day >= v_week
      ),
      'likers', coalesce((
        select json_agg(private.person(l.user_id) order by l.last_at desc, l.user_id)
          from (
            select r.user_id, max(r.created_at) as last_at
              from public.reactions r
              join public.check_ins c on c.id = r.checkin_id
             where c.journey_id = p_journey and c.user_id = uid
               and r.deleted_at is null and r.user_id <> uid
               and private.checkin_shareable(c.id)
               and not private.is_blocked_pair(r.user_id)
               and not exists (
                 select 1 from public.memberships m
                  where m.journey_id = p_journey and m.user_id = r.user_id
               )
             group by r.user_id
          ) l), '[]'::json)));
end;
$$;

create or replace function public.my_reach() returns int
language plpgsql stable security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
begin
  return (
    select count(distinct v.viewer_key)::int
      from public.journey_views v
      join public.journeys j on j.id = v.journey_id and j.deleted_at is null
     where private.is_active_member(v.journey_id, uid)
       and v.viewer_key <> uid::text
       and not exists (
         select 1 from public.memberships m
          where m.journey_id = v.journey_id
            and m.user_id = public.try_uuid(v.viewer_key)
            and m.status = 'active' and m.deleted_at is null
       ));
end;
$$;

-- ---------------------------------------------------------------------------
-- CB-26: reactions_saved_sync, reactions_update, reactions_before_write, mark_followed
-- ---------------------------------------------------------------------------
create or replace function private.reactions_saved_sync() returns trigger
language plpgsql security definer set search_path = ''
as $$
declare
  j public.journeys%rowtype;
begin
  select jj.* into j from public.check_ins c join public.journeys jj on jj.id = c.journey_id
   where c.id = new.checkin_id;
  if not found or private.is_active_member(j.id, new.user_id) then
    return null;
  end if;
  if new.deleted_at is null then
    if j.public_token is not null and not private.has_active_share(j.id, new.user_id) then
      insert into public.saved_journeys (user_id, journey_id) values (new.user_id, j.id)
      on conflict do nothing;
    end if;
  elsif not exists (
    select 1 from public.reactions r
      join public.check_ins c on c.id = r.checkin_id
     where c.journey_id = j.id and r.user_id = new.user_id
       and r.deleted_at is null and private.checkin_shareable(c.id)
  ) then
    delete from public.saved_journeys where user_id = new.user_id and journey_id = j.id;
  end if;
  return null;
end;
$$;

revoke all on function private.reactions_saved_sync() from public, anon, authenticated;

drop policy if exists reactions_update on public.reactions;
create policy reactions_update on public.reactions for update to authenticated
  using (user_id = (select auth.uid()))
  with check (
    user_id = (select auth.uid())
    and (
      deleted_at is not null
      or private.can_view_checkin(checkin_id)
      or private.can_react_as_viewer(checkin_id)
    )
  );

create or replace function public.reactions_before_write() returns trigger
language plpgsql
set search_path = ''
as $$
declare
  s public.journey_status;
begin
  if tg_op = 'UPDATE' and (new.checkin_id <> old.checkin_id or new.user_id <> old.user_id) then
    raise exception 'immutable_column' using errcode = '23514';
  end if;
  if current_user in ('authenticated', 'anon') then
    -- CB-26: soft-deleting one's own reaction (with unchanged emoji) is always allowed, even after
    -- the journey ends, allow_public_reactions is turned off, or the check-in is hidden.
    if tg_op = 'UPDATE' and new.deleted_at is not null then
      if new.emoji is distinct from old.emoji
         and not (private.can_view_checkin(new.checkin_id) or private.can_react_as_viewer(new.checkin_id)) then
        raise exception 'forbidden' using errcode = '42501';
      end if;
      return new;
    end if;
    select j.status into s
      from public.check_ins c join public.journeys j on j.id = c.journey_id
     where c.id = new.checkin_id;
    -- s is null when the caller cannot see the check-in as a member: let RLS reject/allow it.
    if s is not null and s <> 'active' then
      raise exception 'ended' using errcode = 'P0001';
    end if;
  end if;
  return new;
end;
$$;

revoke all on function public.reactions_before_write() from public, anon, authenticated;

create or replace function public.mark_followed(p_journey uuid, p_source uuid) returns void
language plpgsql security definer set search_path = ''
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
  if j.created_at < now() - interval '1 day'
     or j.origin <> 'live'
     or p_source is null
     or p_source = p_journey
     or (j.followed_from is not null and j.followed_from <> p_source) then
    raise exception 'invalid';
  end if;
  select * into s from public.journeys where id = p_source and deleted_at is null;
  if not found then
    raise exception 'not_found';
  end if;
  if not (private.is_member(s.id)
          or (not private.is_blocked_pair(s.owner_id)
              and (private.has_active_share(s.id, uid) or s.public_token is not null))) then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  -- CB-26 (Rule S9): only finished journeys (ended/archived) can be followed along.
  if s.status not in ('ended', 'archived') then
    raise exception 'invalid';
  end if;
  update public.journeys set followed_from = p_source where id = p_journey;
end;
$$;

-- ---------------------------------------------------------------------------
-- CB-27: account_media_paths, account_message_paths, claim_storage_purge
-- ---------------------------------------------------------------------------
create or replace function public.account_media_paths(p_user uuid) returns setof text
language sql
stable
security definer
set search_path = ''
as $$
  select distinct p.name
    from (
      select o.name
        from storage.objects o
       where o.bucket_id = 'media'
         and o.name like ('avatars/' || p_user::text || '/%')
      union all
      select o.name
        from public.memberships m
        join storage.objects o
          on o.bucket_id = 'media'
         and o.name like ('checkins/' || m.journey_id::text || '/' || p_user::text || '/%')
       where m.user_id = p_user
      union all
      select o.name
        from public._journeys_dying_with(p_user) dj
        join storage.objects o
          on o.bucket_id = 'media'
         and o.name like ('checkins/' || dj::text || '/%')
    ) p
   order by p.name;
$$;

create or replace function public.account_message_paths(p_user uuid) returns setof text
language sql
stable
security definer
set search_path = ''
as $$
  select distinct o.name
    from (
      select c.id
        from public.conversations c
       where p_user in (c.member_id, c.viewer_id)
          or c.journey_id in (select public._journeys_dying_with(p_user))
    ) conv
    join storage.objects o
      on o.bucket_id = 'messages'
     and o.name like ('messages/' || conv.id::text || '/%')
   order by o.name;
$$;

create or replace function public.claim_storage_purge(p_limit int default 200)
returns table (bucket text, path text)
language plpgsql
volatile
security definer
set search_path = ''
as $$
begin
  return query
  with due as (
    select s.bucket, s.path
      from private.pending_storage_purge s
     where s.attempts < 20
       and s.next_attempt_at <= now()
       and not exists (select 1 from auth.users u where u.id = s.user_id)
     order by s.next_attempt_at, s.attempts, s.created_at, s.bucket, s.path
     limit greatest(1, least(coalesce(p_limit, 200), 1000))
     for update skip locked
  )
  update private.pending_storage_purge t
     set next_attempt_at = now() + interval '2 minutes'
    from due
   where t.bucket = due.bucket and t.path = due.path
  returning t.bucket, t.path;
end;
$$;

revoke all on function
  public.account_media_paths(uuid),
  public.account_message_paths(uuid),
  public.claim_storage_purge(int)
from public, anon, authenticated;
grant execute on function
  public.account_media_paths(uuid),
  public.account_message_paths(uuid),
  public.claim_storage_purge(int)
to service_role;

-- ---------------------------------------------------------------------------
-- CB-28: check_in_extras_valid (1024-byte cap) & check_ins_before_write
--        (allow pure author soft-delete on ended journeys)
-- ---------------------------------------------------------------------------
create or replace function public.check_in_extras_valid(x jsonb) returns boolean
language sql immutable set search_path = ''
as $$
  select case
    when x is null or jsonb_typeof(x) <> 'object' then false
    when octet_length(x::text) > 1024 then false
    when exists (
      select 1 from jsonb_object_keys(x) k
       where k not in ('mood', 'minutes', 'place', 'dish', 'cook', 'hearts', 'pace', 'km')
    ) then false
    else
      case when x ? 'mood' then jsonb_typeof(x -> 'mood') = 'string'
             and char_length(x ->> 'mood') between 1 and 24 else true end
      and case when x ? 'place' then jsonb_typeof(x -> 'place') = 'string'
             and char_length(x ->> 'place') between 1 and 60 else true end
      and case when x ? 'dish' then jsonb_typeof(x -> 'dish') = 'string'
             and char_length(x ->> 'dish') between 1 and 60 else true end
      and case when x ? 'cook' then jsonb_typeof(x -> 'cook') = 'string'
             and char_length(x ->> 'cook') between 1 and 24 else true end
      and case when x ? 'minutes' then jsonb_typeof(x -> 'minutes') = 'number'
             and (x ->> 'minutes') ~ '^[0-9]{1,4}$'
             and case when (x ->> 'minutes') ~ '^[0-9]{1,4}$'
                      then (x ->> 'minutes')::int between 1 and 1440 else false end
             else true end
      and case when x ? 'hearts' then jsonb_typeof(x -> 'hearts') = 'number'
             and (x ->> 'hearts') ~ '^[1-5]$' else true end
      and case when x ? 'pace' then jsonb_typeof(x -> 'pace') = 'string'
             and (x ->> 'pace') ~ '^[0-9]{1,2}:[0-5][0-9]$' else true end
      and case when x ? 'km' then jsonb_typeof(x -> 'km') = 'number'
             and (x ->> 'km') ~ '^[0-9]{1,3}(\.[0-9]0*)?$'
             and case when (x ->> 'km') ~ '^[0-9]{1,3}(\.[0-9]0*)?$'
                      then (x ->> 'km')::numeric between 0.1 and 500 else false end
             else true end
  end;
$$;

revoke all on function public.check_in_extras_valid(jsonb) from public, anon;
grant execute on function public.check_in_extras_valid(jsonb) to authenticated, service_role;

create or replace function public.check_ins_before_write() returns trigger
language plpgsql
set search_path = ''
as $$
declare
  j public.journeys%rowtype;
  v_imported boolean;
  v_soft_delete boolean;
begin
  select * into j from public.journeys where id = new.journey_id;
  if not found then
    raise exception 'not_found' using errcode = 'P0001';
  end if;

  if tg_op = 'UPDATE' and (
       new.id <> old.id
    or new.journey_id <> old.journey_id
    or new.user_id <> old.user_id
    or new.captured_at <> old.captured_at
    or new.photo_path <> old.photo_path
    or new.thumb_path <> old.thumb_path
    or new.partner_photo_path is distinct from old.partner_photo_path
    or new.from_library is distinct from old.from_library
  ) then
    raise exception 'immutable_column' using errcode = '23514';
  end if;

  new.local_date := public.local_date(new.captured_at, j.timezone);
  new.metric_value := null;
  v_soft_delete := tg_op = 'UPDATE'
    and new.deleted_at is not null
    and new.caption is not distinct from old.caption;
  v_imported := j.origin = 'imported' and new.user_id = j.owner_id and (
    (j.status in ('ended', 'archived') and j.duration_days is not null)
    or (
      j.status = 'active'
      and new.from_library
      and new.local_date between j.start_date
                             and coalesce(j.import_end_date, public.local_date(j.created_at, j.timezone))
    )
  );

  if current_user in ('authenticated', 'anon') then
    if tg_op = 'UPDATE' and old.moderated_at is not null then
      raise exception 'forbidden' using errcode = '42501';
    end if;
    if v_soft_delete then
      if j.deleted_at is not null then
        raise exception 'ended' using errcode = 'P0001';
      end if;
    else
      if new.captured_at > now() + interval '10 minutes' then
        raise exception 'invalid_captured_at' using errcode = '22008';
      end if;
      if v_imported then
        if j.deleted_at is not null then
          raise exception 'ended' using errcode = 'P0001';
        end if;
        if new.local_date < j.start_date
           or (j.duration_days is not null and new.local_date > j.start_date + j.duration_days - 1) then
          raise exception 'invalid_captured_at' using errcode = '22008';
        end if;
      else
        if j.status <> 'active' or j.deleted_at is not null then
          raise exception 'ended' using errcode = 'P0001';
        end if;
        if (tg_op = 'INSERT' or new.captured_at is distinct from old.captured_at)
           and (new.local_date < public.local_date(now(), j.timezone) - 3
                or (j.origin = 'imported' and new.local_date < j.start_date)) then
          raise exception 'invalid_captured_at' using errcode = '22008';
        end if;
        if j.duration_days is not null and new.local_date > j.start_date + j.duration_days - 1 then
          raise exception 'ended' using errcode = 'P0001';
        end if;
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

revoke all on function public.check_ins_before_write() from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- CB-57: couple names column privilege, raw length constraint, couple seats
--        trigger, rename_couple & update_journey 42501 forbidden, and
--        checkin_tombstones after_id keyset pagination
-- ---------------------------------------------------------------------------
revoke update (couple_self_name, couple_partner_name) on public.journeys from authenticated;

update public.journeys
   set couple_self_name = left(nullif(btrim(couple_self_name), ''), 24),
       couple_partner_name = left(nullif(btrim(couple_partner_name), ''), 24)
 where couple_self_name is distinct from left(nullif(btrim(couple_self_name), ''), 24)
    or couple_partner_name is distinct from left(nullif(btrim(couple_partner_name), ''), 24);

alter table public.journeys drop constraint if exists journeys_couple_names;
alter table public.journeys
  add constraint journeys_couple_names check (
    (couple_self_name is null and couple_partner_name is null)
    or (
      couple_self_name is not null and couple_partner_name is not null
      and char_length(couple_self_name) <= 24
      and char_length(couple_partner_name) <= 24
      and char_length(btrim(couple_self_name)) between 1 and 24
      and char_length(btrim(couple_partner_name)) between 1 and 24
    )
  );

create or replace function private.journeys_couple_seats() returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.couple_self_name is not null and char_length(new.couple_self_name) <= 24 then
    new.couple_self_name := nullif(btrim(new.couple_self_name), '');
  end if;
  if new.couple_partner_name is not null and char_length(new.couple_partner_name) <= 24 then
    new.couple_partner_name := nullif(btrim(new.couple_partner_name), '');
  end if;
  if new.layout = 'couple_rituals' and (new.couple_self_name is null or new.couple_partner_name is null) then
    raise exception 'invalid';
  end if;
  if new.kind = 'group' and new.couple_self_name is not null then
    if tg_op = 'UPDATE' and old.couple_self_name is null and (
         select count(*) from public.memberships m
          where m.journey_id = new.id and m.status = 'active' and m.deleted_at is null
       ) > 2 then
      raise exception 'full';
    end if;
    new.max_members := 2;
  end if;
  return new;
end;
$$;

drop trigger if exists journeys_couple_seats on public.journeys;
create trigger journeys_couple_seats
  before insert or update of couple_self_name, couple_partner_name, max_members, kind, layout
  on public.journeys
  for each row execute function private.journeys_couple_seats();
revoke all on function private.journeys_couple_seats() from public, anon, authenticated;

create or replace function public.rename_couple(p_journey uuid, p_self text, p_partner text)
returns public.journeys
language plpgsql security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
  j public.journeys%rowtype;
  v_self text := btrim(coalesce(p_self, ''));
  v_partner text := btrim(coalesce(p_partner, ''));
begin
  select * into j from public.journeys
   where id = p_journey and deleted_at is null for update;
  if not found then
    raise exception 'not_found';
  end if;
  if j.owner_id <> uid or not private.is_owner(p_journey) then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if j.couple_self_name is null then
    raise exception 'invalid';
  end if;
  if j.status <> 'active' then
    raise exception 'ended';
  end if;
  if char_length(v_self) not between 1 and 24 or char_length(v_partner) not between 1 and 24 then
    raise exception 'invalid';
  end if;
  update public.journeys set couple_self_name = v_self, couple_partner_name = v_partner
   where id = j.id returning * into j;
  return j;
end;
$$;

create or replace function public.update_journey(
  p_journey uuid,
  p_title text default null,
  p_layout text default null,
  p_cover int default null,
  p_color int default null,
  p_reminder_time text default null,
  p_dna jsonb default null,
  p_clear text[] default '{}'
) returns public.journeys
language plpgsql security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
  j public.journeys%rowtype;
  v_title text := btrim(p_title);
  v_clear text[] := coalesce(p_clear, '{}');
begin
  select * into j from public.journeys
   where id = p_journey and deleted_at is null for update;
  if not found then
    raise exception 'not_found';
  end if;
  if j.owner_id <> uid or not private.is_owner(p_journey) then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if j.status <> 'active' then
    raise exception 'ended';
  end if;
  if exists (select 1 from unnest(v_clear) c
              where c not in ('layout', 'cover', 'color', 'reminder_time', 'dna')) then
    raise exception 'invalid';
  end if;
  if p_title is not null and char_length(v_title) not between 1 and 60 then
    raise exception 'invalid';
  end if;
  if p_layout is not null and p_layout not in
     ('quiet_transformer', 'accountability_squad', 'memory_collectors',
      'couple_rituals', 'aesthetic_flexer', 'minimalist_habit') then
    raise exception 'invalid';
  end if;
  if p_layout = 'accountability_squad' and j.kind <> 'group' then
    raise exception 'invalid';
  end if;
  if p_layout = 'couple_rituals' and j.couple_self_name is null then
    raise exception 'invalid';
  end if;
  if p_cover is not null and p_cover not between 0 and 2 then
    raise exception 'invalid';
  end if;
  if p_color is not null and p_color not between 0 and 2 then
    raise exception 'invalid';
  end if;
  if p_reminder_time is not null and p_reminder_time !~ '^([01][0-9]|2[0-3]):[0-5][0-9]$' then
    raise exception 'invalid';
  end if;
  if p_dna is not null and not (jsonb_typeof(p_dna) = 'object' and public.journey_dna_valid(p_dna)) then
    raise exception 'invalid';
  end if;

  update public.journeys set
    title = coalesce(v_title, title),
    layout = case when 'layout' = any (v_clear) then null else coalesce(p_layout, layout) end,
    cover = case when 'cover' = any (v_clear) then null else coalesce(p_cover, cover) end,
    color = case when 'color' = any (v_clear) then null else coalesce(p_color, color) end,
    reminder_time = case when 'reminder_time' = any (v_clear) then null
                         else coalesce(p_reminder_time, reminder_time) end,
    dna = case when 'dna' = any (v_clear) then null else coalesce(p_dna, dna) end
   where id = j.id returning * into j;
  return j;
end;
$$;

drop function if exists public.checkin_tombstones(timestamptz, int);

create or replace function public.checkin_tombstones(
  since timestamptz default null,
  lim int default 1000,
  after_id uuid default null
)
returns table (id uuid, journey_id uuid, updated_at timestamptz)
language sql
stable
security definer
set search_path = ''
as $$
  select c.id, c.journey_id, c.updated_at
    from public.check_ins c
   where c.deleted_at is not null
     and c.user_id <> (select auth.uid())
     and (
       since is null
       or c.updated_at > since
       or (c.updated_at = since and (after_id is null or c.id > after_id))
     )
     and private.is_member(c.journey_id)
   order by c.updated_at, c.id
   limit least(greatest(coalesce(lim, 1000), 1), 1000);
$$;

revoke all on function public.checkin_tombstones(timestamptz, int, uuid) from public, anon;
grant execute on function public.checkin_tombstones(timestamptz, int, uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- CB-73: shared_with_me cover tie-break & unshare_journey membership guard
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
             (array_agg(c.thumb_path
                        order by coalesce(c.id = j.cover_checkin_id, false) desc,
                                 c.local_date desc, c.captured_at desc, c.id desc))[1]
               as cover_thumb,
             (array_agg(coalesce(m.blur_media, true)
                        order by coalesce(c.id = j.cover_checkin_id, false) desc,
                                 c.local_date desc, c.captured_at desc, c.id desc))[1]
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

create or replace function public.unshare_journey(p_journey uuid, p_viewer uuid default null, p_all boolean default false)
returns void
language plpgsql security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
begin
  if not exists (select 1 from public.journeys where id = p_journey and deleted_at is null) then
    raise exception 'not_found';
  end if;
  if coalesce(p_all, false) then
    if not private.is_owner(p_journey) then
      raise exception 'forbidden' using errcode = '42501';
    end if;
    perform 1 from public.journeys where id = p_journey and deleted_at is null for update;
    update public.journey_shares set revoked_at = now()
     where journey_id = p_journey and revoked_at is null;
    update public.journeys
       set public_token = null,
           visibility = case when kind = 'solo' then 'private'::public.journey_visibility else visibility end
     where id = p_journey;
    delete from public.saved_journeys where journey_id = p_journey;
  else
    if not private.is_member(p_journey)
       and not exists (select 1 from public.journey_shares
                        where journey_id = p_journey and shared_by = uid) then
      raise exception 'forbidden' using errcode = '42501';
    end if;
    update public.journey_shares set revoked_at = now()
     where journey_id = p_journey and shared_by = uid and revoked_at is null
       and (p_viewer is null or viewer_id = p_viewer);
  end if;
end;
$$;
