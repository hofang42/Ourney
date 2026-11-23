-- 0019_fullscan_backend_fixes: Batch A backend & security fixes from fullscan.md.
--   FS-01  Storage bucket `messages` FOR UPDATE RLS policy (`messages_update`) for `x-upsert: true`.
--   FS-07  `private.can_read_message` excludes reported messages and blocked peers;
--          `private.can_read_message_object` enforced in `messages_select`;
--          `public.clear_conversation` enqueues hard-deleted message `media_path`s into
--          `private.pending_storage_purge`.
--   FS-08  `public.purge_account_data` locks user journeys FOR UPDATE and atomically enqueues
--          `account_media_paths` and `account_message_paths` into `private.pending_storage_purge`
--          inside the `BEFORE DELETE ON public.profiles` transaction.
--   FS-09  `public.send_group_invitation` validates journey active/expiry and capacity (`full`)
--          before resolving `@handle` / `p_user` (preventing handle-enumeration oracle via rollback);
--          `public.check_ins_before_write` freezes `id`, `captured_at`, `photo_path`, `thumb_path`,
--          and `partner_photo_path` on UPDATE (preventing moderation evasion & photo swapping).
--   FS-20  `public.send_friend_request` rate-limits direct requests (`<= 30/hour`);
--          `private.can_see_profile` requires `status = 'accepted' or requested_by = other` for
--          friendship rows; `media_select` restricts non-owner avatar reads to the profile's
--          current `avatar_path` and queues replaced avatars into `private.pending_storage_purge`.
--   FS-21  Block & expiry filtering across `my_conversations`, `inbox_counts`, `owner_for_viewer`,
--          `memberships_select`, `send_group_invitation`, `my_group_invitations`,
--          `journey_pending_invitations`, and `preview_group_by_code` (hiding stranger `avatar_path`).
--   FS-22  Continuing imported journeys (`p_continues = true`, `status = 'active'`): enforce Rule S9
--          on `set_public_link`, `follow_frame`, and `journey_view.can_follow`; enforce 3-day
--          anti-backdating on active continuing journeys in `check_ins_before_write`; align
--          `check_in_metrics_before_write`; seed `memberships.joined_at` from `p_first` in
--          `create_imported_journey`.
--   FS-23  `private.journey_view` and `private.group_streak`: anchor ended/archived journey streak
--          evaluation to the journey's last active date; order photos by `(local_date, captured_at, id)`;
--          expose `layout`, `color`, `cover`, `cover_blurred`, `couple_self_name`,
--          `couple_partner_name`, and per-photo `partner_photo_path`.
--   FS-24  Hot-path partial indexes on `public.reports` + B-tree indexes on all unindexed FK columns.
--   FS-25  `public.profile_stats()` excludes `origin = 'imported'` from live streaks (S12), excludes
--          ended/expired journeys from `current_streak`, and counts `archived` / duration-elapsed
--          journeys in `journeys_completed`.
--   FS-38  `public.journey_dna_valid` coalesces SQL NULLs to `false` and validates `dates.end >= start`;
--          `journeys` and `profiles` reject whitespace-only titles/names; `media_update` enforces
--          UUID `.jpg` filename regex; `report_content` locks reporter profile and deduplicates open
--          reports; `withdraw_share_consent` revokes grants shared by the withdrawing member.
-- Idempotent (create or replace, drop if exists, if not exists).

-- ---------------------------------------------------------------------------
-- FS-01 + FS-07: chat messages RLS, storage policies & clear_conversation purge
-- ---------------------------------------------------------------------------
create or replace function private.can_read_message(p_message uuid) returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.messages m
      join public.conversations c on c.id = m.conversation_id
     where m.id = p_message and m.deleted_at is null
       and (select auth.uid()) in (c.member_id, c.viewer_id)
       and not private.blocked_between(c.member_id, c.viewer_id)
       and m.created_at > coalesce(
             case when c.member_id = (select auth.uid()) then c.member_cleared_at else c.viewer_cleared_at end,
             '-infinity'::timestamptz)
       and not exists (select 1 from public.message_hides h
                        where h.message_id = m.id and h.user_id = (select auth.uid()))
       and not exists (select 1 from public.reports r
                        where r.target_message_id = m.id
                          and r.reporter_id = (select auth.uid())
                          and r.deleted_at is null));
$$;

create or replace function private.can_read_message_object(p_name text) returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.messages m
     where m.id = public.try_uuid(substring(p_name from '/([0-9a-f-]{36})\.jpg$'))
       and m.media_path = p_name
       and private.can_read_message(m.id)
  )
  or (
    -- Sender's in-flight upload (x-upsert happens before send_message inserts the public.messages row).
    (storage.foldername(p_name))[1] = 'messages'
    and array_length(storage.foldername(p_name), 1) = 3
    and (storage.foldername(p_name))[3] = (select auth.uid())::text
    and storage.filename(p_name) ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.jpg$'
    and private.is_conversation_participant(public.try_uuid((storage.foldername(p_name))[2]))
    and not private.conversation_read_only(public.try_uuid((storage.foldername(p_name))[2]))
    and not exists (
      select 1 from public.messages m
       where m.id = public.try_uuid(substring(p_name from '/([0-9a-f-]{36})\.jpg$'))
          or m.media_path = p_name
    )
    and not exists (
      select 1 from private.pending_storage_purge s
       where s.bucket = 'messages' and s.path = p_name
    )
  );
$$;

revoke all on function private.can_read_message(uuid), private.can_read_message_object(text) from public, anon;
grant execute on function private.can_read_message(uuid), private.can_read_message_object(text) to authenticated, service_role;

drop policy if exists messages_select on storage.objects;
create policy messages_select on storage.objects for select to authenticated
using (
  bucket_id = 'messages'
  and (storage.foldername(name))[1] = 'messages'
  and array_length(storage.foldername(name), 1) = 3
  and private.can_read_message_object(name)
);

drop policy if exists messages_update on storage.objects;
create policy messages_update on storage.objects for update to authenticated
using (
  bucket_id = 'messages'
  and (storage.foldername(name))[1] = 'messages'
  and array_length(storage.foldername(name), 1) = 3
  and (storage.foldername(name))[3] = (select auth.uid())::text
  and private.is_conversation_participant(public.try_uuid((storage.foldername(name))[2]))
  and not private.conversation_read_only(public.try_uuid((storage.foldername(name))[2]))
  and storage.filename(name) ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.jpg$'
)
with check (
  bucket_id = 'messages'
  and (storage.foldername(name))[1] = 'messages'
  and array_length(storage.foldername(name), 1) = 3
  and (storage.foldername(name))[3] = (select auth.uid())::text
  and private.is_conversation_participant(public.try_uuid((storage.foldername(name))[2]))
  and not private.conversation_read_only(public.try_uuid((storage.foldername(name))[2]))
  and storage.filename(name) ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.jpg$'
);

create or replace function public.clear_conversation(p_conversation uuid) returns void
language plpgsql security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
  c public.conversations%rowtype;
begin
  update public.conversations
     set member_cleared_at = case when member_id = uid then now() else member_cleared_at end,
         viewer_cleared_at = case when viewer_id = uid then now() else viewer_cleared_at end
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
       select 1 from public.check_ins where id = p_reply_to and journey_id = c.journey_id) then
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
         member_read_at = case when member_id = uid then m.created_at else member_read_at end,
         viewer_read_at = case when viewer_id = uid then m.created_at else viewer_read_at end
   where id = p_conversation;
  return private.message_json(m);
end;
$$;

-- ---------------------------------------------------------------------------
-- FS-08: atomic storage purge queueing inside purge_account_data & lock order
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
    -- Lock candidate next_owner profile FOR KEY SHARE SKIP LOCKED so concurrent RPCs holding
    -- FOR NO KEY UPDATE on profiles never block ownership transfer, and a co-member whose account
    -- is simultaneously mid-DELETE is skipped rather than deadlocking.
    select m.user_id into next_owner
      from public.memberships m
      join public.profiles p on p.id = m.user_id and p.deleted_at is null
     where m.journey_id = p_journey and m.status = 'active' and m.deleted_at is null
     order by m.joined_at, m.user_id
     limit 1
     for key share of p skip locked;
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

revoke all on function public._leave_journey(uuid, uuid) from public, anon, authenticated;

create or replace function public.purge_account_data(p_user uuid) returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  r record;
begin
  -- Consistent lock hierarchy (profiles -> journeys ordered by id) matching join_by_code / send_group_invitation.
  perform 1 from public.profiles where id = p_user for no key update;
  perform 1
    from (
      select j.id
        from public.journeys j
       where j.owner_id = p_user
          or exists (select 1 from public.memberships m where m.journey_id = j.id and m.user_id = p_user)
       order by j.id
       for update
    ) s;

  -- Drop any stale pre-delete snapshot rows for this user and record the exact paths dying in this tx.
  delete from private.pending_storage_purge where user_id = p_user;

  insert into private.pending_storage_purge (bucket, path, user_id)
  select distinct 'media', p, p_user
    from public.account_media_paths(p_user) as p
   where p is not null and length(p) between 1 and 1024
  on conflict (bucket, path) do update
    set user_id = excluded.user_id,
        attempts = 0,
        next_attempt_at = now(),
        last_error = null
    where private.pending_storage_purge.user_id = excluded.user_id
       or exists (select 1 from auth.users u where u.id = private.pending_storage_purge.user_id);

  insert into private.pending_storage_purge (bucket, path, user_id)
  select distinct 'messages', p, p_user
    from public.account_message_paths(p_user) as p
   where p is not null and length(p) between 1 and 1024
  on conflict (bucket, path) do update
    set user_id = excluded.user_id,
        attempts = 0,
        next_attempt_at = now(),
        last_error = null
    where private.pending_storage_purge.user_id = excluded.user_id
       or exists (select 1 from auth.users u where u.id = private.pending_storage_purge.user_id);

  for r in
    select m.journey_id from public.memberships m
     where m.user_id = p_user and m.status = 'active' and m.deleted_at is null
       and m.journey_id not in (select public._journeys_dying_with(p_user))
     order by m.journey_id
  loop
    perform public._leave_journey(r.journey_id, p_user);
  end loop;
  delete from public.journeys where id in (select public._journeys_dying_with(p_user));
  delete from private.join_attempts where user_id = p_user;
  delete from private.rate_events where user_id = p_user;
  delete from public.journey_views where viewer_key = p_user::text;
end;
$$;

revoke all on function public.purge_account_data(uuid) from public, anon, authenticated;
grant execute on function public.purge_account_data(uuid) to service_role;

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
    p_id, uid, p_kind, coalesce(p_template_id, 'custom'), btrim(p_title), btrim(p_emoji),
    p_metric_name, p_metric_unit, coalesce(p_hide_metric_default, false), p_start_date,
    p_duration_days, p_timezone, v_visibility, 'active', v_code,
    case when p_kind = 'solo' then 1
         when v_self is not null then 2
         else coalesce(p_max_members, 10) end,
    v_token, v_self, v_partner)
  returning * into j;

  insert into public.memberships (journey_id, user_id, role, hide_metric)
  values (j.id, uid, 'owner', j.hide_metric_default);

  return j;
end;
$$;

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
  perform 1 from public.profiles where id = uid and deleted_at is null for no key update;
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
    update public.memberships set status = 'active', role = 'member', deleted_at = null
     where journey_id = j.id and user_id = uid;
    update public.check_ins set deleted_at = null, hidden_by_leave = false
     where journey_id = j.id and user_id = uid and hidden_by_leave and moderated_at is null;
  else
    insert into public.memberships (journey_id, user_id, role, hide_metric)
    values (j.id, uid, 'member', j.hide_metric_default);
  end if;
  update public.group_invitations set status = 'accepted', responded_at = now()
   where journey_id = j.id and invitee_id = uid and status = 'pending';
  return j;
end;
$$;

create or replace function public.find_user_by_username(p_username text) returns json
language plpgsql security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
  v_name text := lower(ltrim(btrim(coalesce(p_username, '')), '@'));
  v_out json;
begin
  perform 1 from public.profiles where id = uid and deleted_at is null for no key update;
  if not found then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  delete from private.rate_events where user_id = uid and at < now() - interval '1 day';
  if (select count(*) from private.rate_events
       where user_id = uid and kind = 'username_lookup' and at > now() - interval '1 hour') >= 30 then
    raise exception 'rate_limited';
  end if;
  insert into private.rate_events (user_id, kind) values (uid, 'username_lookup');
  select private.person(p.id) into v_out
    from public.profiles p
   where p.username = v_name and p.id <> uid and p.deleted_at is null
     and not private.blocked_between(uid, p.id);
  return v_out;
end;
$$;

create or replace function public.create_friend_invite() returns text
language plpgsql security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
  v_token text;
begin
  perform 1 from public.profiles where id = uid and deleted_at is null for no key update;
  if not found then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  loop
    v_token := public.random_token(12, 'abcdefghijklmnopqrstuvwxyz0123456789');
    exit when not exists (select 1 from public.friend_invites where token = v_token);
  end loop;
  insert into public.friend_invites (user_id, token) values (uid, v_token)
  on conflict (user_id) do update set token = excluded.token, created_at = now();
  return v_token;
end;
$$;

-- ---------------------------------------------------------------------------
-- FS-09 + FS-21: send_group_invitation, my_group_invitations, preview_group_by_code
-- ---------------------------------------------------------------------------
create or replace function public.send_group_invitation(
  p_journey uuid, p_user uuid default null, p_handle text default null
) returns json
language plpgsql security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
  j public.journeys%rowtype;
  v_handle text := lower(ltrim(btrim(coalesce(p_handle, '')), '@'));
  v_target uuid;
  v_kind text;
  v_id uuid;
begin
  perform 1 from public.profiles where id = uid and deleted_at is null for no key update;
  if not found then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if not exists (select 1 from public.memberships
                  where journey_id = p_journey and user_id = uid
                    and status = 'active' and deleted_at is null) then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  select * into j from public.journeys
   where id = p_journey and kind = 'group' and deleted_at is null
   for update;
  if not found then
    raise exception 'not_found';
  end if;
  if j.status <> 'active'
     or (j.duration_days is not null
         and public.local_date(now(), j.timezone) > j.start_date + j.duration_days - 1) then
    raise exception 'ended';
  end if;
  -- FS-09: check capacity BEFORE resolving p_handle/p_user so a full group cannot be used
  -- as a rollback-based username enumeration oracle.
  if (select count(*) from public.memberships
       where journey_id = j.id and status = 'active' and deleted_at is null) >= j.max_members then
    raise exception 'full';
  end if;

  delete from private.rate_events where user_id = uid and at < now() - interval '1 day';
  if (select count(*) from private.rate_events
       where user_id = uid and kind = 'group_invite' and at > now() - interval '1 day') >= 20 then
    raise exception 'rate_limited';
  end if;
  insert into private.rate_events (user_id, kind) values (uid, 'group_invite');

  if p_user is not null then
    v_target := p_user;
    v_kind := 'user';
  elsif v_handle ~ '^[a-z0-9_.]{3,20}$' then
    select id into v_target from public.profiles where username = v_handle and deleted_at is null;
    v_kind := 'handle';
  end if;
  -- FS-21: check blocks against any active member of the group (matching join_by_code).
  if v_target is null or v_target = uid
     or not exists (select 1 from public.profiles where id = v_target and deleted_at is null)
     or private.blocked_between(uid, v_target)
     or exists (select 1 from public.memberships am
                 where am.journey_id = j.id and am.status = 'active' and am.deleted_at is null
                   and private.blocked_between(v_target, am.user_id)) then
    raise exception 'not_found'; -- same answer for unknown and blocked users
  end if;
  if exists (select 1 from public.memberships
              where journey_id = j.id and user_id = v_target and status = 'active' and deleted_at is null)
     or exists (select 1 from public.memberships
                 where journey_id = j.id and user_id = v_target and removed_at is not null) then
    raise exception 'invalid';
  end if;

  -- An expired pending row must not block a fresh invitation.
  update public.group_invitations set status = 'declined', responded_at = now()
   where journey_id = j.id and invitee_id = v_target and status = 'pending' and expires_at <= now();
  if exists (select 1 from public.group_invitations
              where journey_id = j.id and invitee_id = v_target and status = 'pending') then
    raise exception 'invalid';
  end if;

  insert into public.group_invitations (journey_id, inviter_id, invitee_kind, invitee_id, invitee_handle)
  values (j.id, uid, v_kind, v_target,
          case when v_kind = 'handle' then v_handle else null end)
  returning id into v_id;
  return json_build_object('id', v_id);
end;
$$;

create or replace function public.my_group_invitations() returns json
language plpgsql stable security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
begin
  return coalesce((
    select json_agg(json_build_object(
      'id', i.id,
      'journey_id', j.id,
      'title', j.title,
      'emoji', j.emoji,
      'template_id', j.template_id,
      'inviter', private.person(i.inviter_id),
      'member_count', (select count(*) from public.memberships am
                        where am.journey_id = j.id and am.status = 'active' and am.deleted_at is null),
      'max_members', j.max_members,
      'created_at', i.created_at,
      'expires_at', i.expires_at) order by i.created_at desc)
      from public.group_invitations i
      join public.journeys j on j.id = i.journey_id and j.deleted_at is null and j.status = 'active'
     where i.invitee_id = uid and i.status = 'pending' and i.expires_at > now()
       and private.is_active_member(j.id, i.inviter_id)
       and (j.duration_days is null
            or public.local_date(now(), j.timezone) <= j.start_date + j.duration_days - 1)
       and not private.blocked_between(uid, i.inviter_id)
       and not exists (select 1 from public.memberships am
                        where am.journey_id = j.id and am.status = 'active' and am.deleted_at is null
                          and private.blocked_between(uid, am.user_id))
  ), '[]'::json);
end;
$$;

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
      join public.journeys j on j.id = i.journey_id and j.deleted_at is null and j.status = 'active'
     where i.journey_id = p_journey and i.status = 'pending' and i.expires_at > now()
       and private.is_active_member(j.id, i.inviter_id)
       and (j.duration_days is null
            or public.local_date(now(), j.timezone) <= j.start_date + j.duration_days - 1)
       and not private.blocked_between(uid, i.invitee_id)
       and not private.blocked_between(uid, i.inviter_id)
       and not exists (select 1 from public.memberships am
                        where am.journey_id = j.id and am.status = 'active' and am.deleted_at is null
                          and private.blocked_between(i.invitee_id, am.user_id))
  ), '[]'::json);
end;
$$;

create or replace function public.preview_group_by_code(p_code text) returns json
language plpgsql security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
  v_code text := upper(btrim(p_code));
  j public.journeys%rowtype;
  m public.memberships%rowtype;
  v_found boolean := false;
  v_count int;
  v_state text := 'open';
  v_day int;
  v_owner json;
  v_members json;
begin
  perform 1 from public.profiles where id = uid and deleted_at is null for no key update;
  if not found then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  delete from private.join_attempts where user_id = uid and attempted_at < now() - interval '1 hour';
  delete from private.rate_events where user_id = uid and at < now() - interval '1 day';
  if (select count(*) from private.join_attempts where user_id = uid and not success) >= 10
     or (select count(*) from private.rate_events
          where user_id = uid and kind = 'code_preview' and at > now() - interval '1 hour') >= 60 then
    raise exception 'rate_limited';
  end if;

  if v_code is not null and v_code ~ '^[A-Z0-9]{8}$' then
    select * into j from public.journeys
     where invite_code = v_code and kind = 'group' and deleted_at is null;
    v_found := found;
  end if;
  if v_found then
    select * into m from public.memberships where journey_id = j.id and user_id = uid;
    if found and m.removed_at is not null then
      v_found := false;
    elsif exists (
      select 1 from public.memberships am
       where am.journey_id = j.id and am.status = 'active' and am.deleted_at is null
         and private.blocked_between(uid, am.user_id)
    ) then
      v_found := false;
    end if;
  end if;
  if not v_found then
    insert into private.join_attempts (user_id, success) values (uid, false);
    return null;
  end if;
  insert into private.rate_events (user_id, kind) values (uid, 'code_preview');

  select count(*) into v_count from public.memberships
   where journey_id = j.id and status = 'active' and deleted_at is null;
  if j.status <> 'active'
     or (j.duration_days is not null
         and public.local_date(now(), j.timezone) > j.start_date + j.duration_days - 1) then
    v_state := 'ended';
  elsif m.user_id is not null and m.status = 'active' and m.deleted_at is null then
    v_state := 'member';
  elsif v_count >= j.max_members then
    v_state := 'full';
  end if;

  v_day := greatest(1, least(coalesce(j.duration_days, 2147483647),
             (public.local_date(now(), j.timezone) - j.start_date) + 1));
  -- FS-21: only return avatar_path when the caller can already see the member's profile
  -- (otherwise avatar_path leaks the member's user_id UUID and fails Storage signing anyway).
  select json_build_object(
           'display_name', p.display_name,
           'avatar_path', case when private.can_see_profile(p.id) then p.avatar_path else null end)
    into v_owner from public.profiles p where p.id = j.owner_id;
  select coalesce(json_agg(x.o order by x.joined_at), '[]'::json) into v_members
    from (
      select json_build_object(
               'display_name', p.display_name,
               'avatar_path', case when private.can_see_profile(p.id) then p.avatar_path else null end) as o,
             am.joined_at
        from public.memberships am
        join public.profiles p on p.id = am.user_id and p.deleted_at is null
       where am.journey_id = j.id and am.status = 'active' and am.deleted_at is null
       order by am.joined_at
       limit 5
    ) x;

  return json_build_object(
    'state', v_state,
    'title', j.title,
    'emoji', j.emoji,
    'template_id', j.template_id,
    'owner', v_owner,
    'member_count', v_count,
    'max_members', j.max_members,
    'duration_days', j.duration_days,
    'day_number', v_day,
    'members', v_members);
end;
$$;

-- ---------------------------------------------------------------------------
-- FS-09 + FS-22: check_ins_before_write, check_in_metrics_before_write,
--                create_imported_journey, set_public_link, follow_frame
-- ---------------------------------------------------------------------------
alter table public.journeys add column if not exists import_end_date date;

update public.journeys
   set import_end_date = coalesce(start_date + duration_days - 1, public.local_date(created_at, timezone))
 where origin = 'imported' and import_end_date is null;

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

  -- FS-09: primary key, ownership, timestamp, and media paths of a check-in are immutable on UPDATE.
  if tg_op = 'UPDATE' and (
       new.id <> old.id
    or new.journey_id <> old.journey_id
    or new.user_id <> old.user_id
    or new.captured_at <> old.captured_at
    or new.photo_path <> old.photo_path
    or new.thumb_path <> old.thumb_path
    or new.partner_photo_path is distinct from old.partner_photo_path
  ) then
    raise exception 'immutable_column' using errcode = '23514';
  end if;

  new.local_date := public.local_date(new.captured_at, j.timezone);
  new.metric_value := null;
  -- FS-22: finished retold journeys (duration_days is not null) allow historical dates in
  -- [start_date, start_date + duration_days - 1]; active continuing imported journeys
  -- (p_continues = true, status = 'active', duration_days is null) allow initial library
  -- photos (from_library = true) within the declared pre-creation range [start_date, import_end_date],
  -- while ongoing days (local_date > import_end_date or not from_library) enforce the 3-day window.
  v_imported := j.origin = 'imported' and new.user_id = j.owner_id and (
    j.duration_days is not null
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
              or new.local_date < j.start_date) then
        raise exception 'invalid_captured_at' using errcode = '22008';
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

create or replace function private.check_in_metrics_before_write() returns trigger
language plpgsql set search_path = ''
as $$
declare
  c record;
begin
  select ci.journey_id, ci.user_id, ci.deleted_at, j.status, j.deleted_at as journey_deleted,
         (j.origin = 'imported' and j.owner_id = ci.user_id and j.duration_days is not null) as imported
    into c
    from public.check_ins ci join public.journeys j on j.id = ci.journey_id
   where ci.id = new.checkin_id;
  if not found then
    raise exception 'not_found' using errcode = 'P0001';
  end if;
  new.journey_id := c.journey_id;
  new.user_id := c.user_id;
  if current_user in ('authenticated', 'anon') then
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
    if j.owner_id = uid then
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
  -- FS-22: anchor joined_at to p_first in the journey's timezone so journey_streak counts imported days.
  insert into public.memberships (journey_id, user_id, role, hide_metric, joined_at)
  values (j.id, uid, 'owner', j.hide_metric_default,
          (p_first::text || ' 00:00:00')::timestamp at time zone p_timezone);
  return j;
end;
$$;

-- Backfill existing imported journeys whose owner joined_at was set to now() after start_date.
update public.memberships m
   set joined_at = (j.start_date::text || ' 00:00:00')::timestamp at time zone j.timezone
  from public.journeys j
 where m.journey_id = j.id
   and m.user_id = j.owner_id
   and j.origin = 'imported'
   and public.local_date(m.joined_at, j.timezone) > j.start_date;

create or replace function public.set_public_link(journey uuid, enabled boolean, reset boolean default false) returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := public._uid();
  j public.journeys%rowtype;
  v_token text;
begin
  select * into j from public.journeys where id = journey and deleted_at is null for update;
  if not found then
    raise exception 'not_found';
  end if;
  if not exists (select 1 from public.memberships
                  where journey_id = journey and user_id = uid
                    and role = 'owner' and status = 'active') then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if coalesce(enabled, false) then
    -- S9 + FS-22: only finished journeys (ended/archived); active continuing imports must end first.
    if j.status not in ('ended', 'archived') then
      raise exception 'invalid';
    end if;
    if j.public_token is not null and not coalesce(reset, false) then
      return j.public_token;
    end if;
    v_token := public.random_token(40, 'abcdefghijklmnopqrstuvwxyz0123456789');
    update public.journeys
       set public_token = v_token,
           visibility = case when kind = 'solo' then 'link'::public.journey_visibility else visibility end
     where id = journey;
  else
    update public.journeys
       set public_token = null,
           visibility = case when kind = 'solo' then 'private'::public.journey_visibility else visibility end
     where id = journey;
  end if;
  if j.public_token is not null then
    delete from public.saved_journeys where journey_id = journey;
  end if;
  return v_token;
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
  -- S9 + FS-22: only finished journeys can be followed along.
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
    'metric_unit', case when v_show_metric then j.metric_unit end);
end;
$$;

-- ---------------------------------------------------------------------------
-- FS-20 + FS-38: send_friend_request, can_see_profile, media_select, media_update,
--                and old avatar purge trigger
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
       or not (j.kind = 'solo' or private.consent_accepted(j.id, j.owner_id)) then
      raise exception 'forbidden' using errcode = '42501';
    end if;
    if (select count(*) from private.rate_events
         where user_id = uid and kind = 'public_friend_request' and at > now() - interval '1 day') >= 20 then
      raise exception 'rate_limited';
    end if;
    insert into private.rate_events (user_id, kind) values (uid, 'public_friend_request');
  else
    -- FS-20: rate-limit direct friend requests (<= 30 per hour).
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

create or replace function private.can_see_profile(other uuid) returns boolean
language sql stable security definer set search_path = ''
as $$
  select other = (select auth.uid())
      or (not private.is_blocked_pair(other)
          and (
            exists (
              select 1 from public.memberships a
                join public.memberships b on b.journey_id = a.journey_id
               where a.user_id = (select auth.uid()) and b.user_id = other
                 and a.status = 'active' and a.deleted_at is null
                 and b.status = 'active' and b.deleted_at is null)
            -- FS-20: an unaccepted pending request only grants profile visibility to the recipient.
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
                      or (j.public_token is not null
                          and exists (select 1 from public.saved_journeys s
                                       where s.journey_id = j.id and s.user_id = (select auth.uid())))))
          ));
$$;

drop policy if exists media_select on storage.objects;
create policy media_select on storage.objects for select to authenticated
using (
  bucket_id = 'media'
  and (
    (
      (storage.foldername(name))[1] = 'checkins'
      and array_length(storage.foldername(name), 1) = 3
      and (
        (storage.foldername(name))[3] = (select auth.uid())::text
        or private.can_read_checkin_object(name)
      )
    )
    or (
      (storage.foldername(name))[1] = 'avatars'
      and array_length(storage.foldername(name), 1) = 2
      and (
        -- Own folder always (upload upserts happen before profiles.avatar_path is updated).
        (storage.foldername(name))[2] = (select auth.uid())::text
        or (
          private.can_see_profile(public.try_uuid((storage.foldername(name))[2]))
          and exists (
            select 1 from public.profiles p
             where p.id = public.try_uuid((storage.foldername(name))[2])
               and p.deleted_at is null
               and p.avatar_path = name
          )
        )
      )
    )
  )
);

drop policy if exists media_update on storage.objects;
create policy media_update on storage.objects for update to authenticated
using (
  bucket_id = 'media'
  and (
    (
      (storage.foldername(name))[1] = 'checkins'
      and array_length(storage.foldername(name), 1) = 3
      and (storage.foldername(name))[3] = (select auth.uid())::text
      and private.is_member(public.try_uuid((storage.foldername(name))[2]))
      and storage.filename(name) ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}(_[tp])?\.jpg$'
    )
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
  and (
    (
      (storage.foldername(name))[1] = 'checkins'
      and array_length(storage.foldername(name), 1) = 3
      and (storage.foldername(name))[3] = (select auth.uid())::text
      and private.is_member(public.try_uuid((storage.foldername(name))[2]))
      and storage.filename(name) ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}(_[tp])?\.jpg$'
    )
    or (
      (storage.foldername(name))[1] = 'avatars'
      and array_length(storage.foldername(name), 1) = 2
      and (storage.foldername(name))[2] = (select auth.uid())::text
      and exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.deleted_at is null)
      and storage.filename(name) ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.jpg$'
    )
  )
);

create or replace function private.profiles_queue_old_avatar() returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  if old.avatar_path is not null and old.avatar_path is distinct from new.avatar_path
     and length(old.avatar_path) between 1 and 1024 then
    insert into private.pending_storage_purge (bucket, path, user_id)
    values ('media', old.avatar_path, '00000000-0000-0000-0000-000000000000'::uuid)
    on conflict (bucket, path) do update
      set user_id = '00000000-0000-0000-0000-000000000000'::uuid,
          attempts = 0,
          next_attempt_at = now(),
          last_error = null;
  end if;
  return null;
end;
$$;

drop trigger if exists profiles_queue_old_avatar on public.profiles;
create trigger profiles_queue_old_avatar after update of avatar_path on public.profiles
  for each row
  when (old.avatar_path is not null and old.avatar_path is distinct from new.avatar_path)
  execute function private.profiles_queue_old_avatar();

revoke all on function private.profiles_queue_old_avatar() from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- FS-21: my_conversations, inbox_counts, owner_for_viewer, memberships_select
-- ---------------------------------------------------------------------------
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
    join public.journeys j on j.id = c.journey_id
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
     and (x.cleared_at is null or c.last_message_at > x.cleared_at)
   order by coalesce(c.last_message_at, c.created_at) desc, c.id;
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

create or replace function private.owner_for_viewer(p_journey uuid) returns json
language sql stable security definer set search_path = ''
as $$
  select case when (j.kind = 'solo' or private.is_active_member(j.id, (select auth.uid()))
                    or private.consent_accepted(j.id, j.owner_id))
                   and not private.blocked_between((select auth.uid()), j.owner_id)
              then private.person(j.owner_id)
              else json_build_object('user_id', '00000000-0000-0000-0000-000000000000',
                                     'username', '', 'display_name', '', 'avatar_path', null)
         end
    from public.journeys j where j.id = p_journey;
$$;

drop policy if exists memberships_select on public.memberships;
create policy memberships_select on public.memberships for select to authenticated
  using (
    user_id = (select auth.uid())
    or (private.is_member(journey_id) and not private.is_blocked_pair(user_id))
  );

create or replace function public.my_pending_consents() returns setof json
language plpgsql stable security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
begin
  return query
  select private.consent_json(c)
    from public.journey_share_consents c
    join public.journeys j on j.id = c.journey_id and j.deleted_at is null
   where c.user_id = uid and c.status = 'pending' and private.is_active_member(c.journey_id, uid)
     and not private.blocked_between(uid, j.owner_id)
   order by c.created_at desc, c.journey_id;
end;
$$;

create or replace function public.request_share_consent(p_journey uuid) returns void
language plpgsql security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
  j public.journeys%rowtype;
begin
  select * into j from public.journeys where id = p_journey and deleted_at is null for update;
  if not found then
    raise exception 'not_found';
  end if;
  if not private.is_member(p_journey) then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if j.kind <> 'group' then
    raise exception 'invalid';
  end if;
  insert into public.journey_share_consents (journey_id, user_id, status, requested_by, decided_at)
  values (p_journey, uid, 'accepted', uid, now())
  on conflict (journey_id, user_id) do update
    set status = 'accepted', decided_at = now();
  insert into public.journey_share_consents (journey_id, user_id, status, requested_by)
  select m.journey_id, m.user_id, 'pending', uid
    from public.memberships m
   where m.journey_id = p_journey and m.user_id <> uid and m.status = 'active' and m.deleted_at is null
     and not private.blocked_between(uid, m.user_id)
     and not private.blocked_between(m.user_id, j.owner_id)
  on conflict (journey_id, user_id) do nothing;
end;
$$;

-- ---------------------------------------------------------------------------
-- FS-22 + FS-23: group_streak & journey_view parity
-- ---------------------------------------------------------------------------
create or replace function private.group_streak(p_journey uuid) returns int
language sql stable security definer set search_path = ''
as $$
  select s.current_streak
    from public.journeys j
    cross join lateral (
      select coalesce(array_agg(distinct c.local_date), '{}') as dates,
             max(c.local_date) as last_date
        from public.check_ins c
       where c.journey_id = j.id and c.deleted_at is null
         and private.is_active_member(j.id, c.user_id)
    ) cd
    cross join lateral public.streak_core(
      cd.dates,
      j.start_date,
      case when j.duration_days is null then null else j.start_date + j.duration_days - 1 end,
      case when j.status in ('ended', 'archived')
           then least(public.local_date(now(), j.timezone), coalesce(cd.last_date, j.start_date))
           else public.local_date(now(), j.timezone) end) s
   where j.id = p_journey;
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
  -- S29/S30: couple names and partner photo on a group journey require every active member
  -- to have accepted share consent and not be in a blocked pair with the viewer.
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
                     and (j.kind = 'solo' or private.consent_accepted(j.id, j.owner_id))
                     and not exists (select 1 from public.friendships f
                                      where f.user_low = least(uid, j.owner_id)
                                        and f.user_high = greatest(uid, j.owner_id)
                                        and f.deleted_at is null)
                     and not private.is_blocked_pair(j.owner_id),
    'saved', exists (select 1 from public.saved_journeys s where s.user_id = uid and s.journey_id = j.id));
end;
$$;

-- ---------------------------------------------------------------------------
-- FS-24: reports RLS hot-path indexes & 13+ unindexed FK columns
-- ---------------------------------------------------------------------------
create index if not exists reports_reporter_checkin_idx
  on public.reports (reporter_id, target_checkin_id)
  where deleted_at is null and target_checkin_id is not null;

create index if not exists reports_reporter_message_idx
  on public.reports (reporter_id, target_message_id)
  where deleted_at is null and target_message_id is not null;

create index if not exists reports_reporter_created_idx
  on public.reports (reporter_id, created_at);

create index if not exists reports_target_checkin_idx
  on public.reports (target_checkin_id) where target_checkin_id is not null;

create index if not exists reports_target_user_idx
  on public.reports (target_user_id) where target_user_id is not null;

create index if not exists reports_target_message_idx
  on public.reports (target_message_id) where target_message_id is not null;

create index if not exists reactions_user_idx on public.reactions (user_id);
create index if not exists memberships_user_all_idx on public.memberships (user_id);
create index if not exists journeys_cover_checkin_idx
  on public.journeys (cover_checkin_id) where cover_checkin_id is not null;
create index if not exists messages_reply_to_checkin_idx
  on public.messages (reply_to_checkin_id) where reply_to_checkin_id is not null;
create index if not exists saved_journeys_journey_idx on public.saved_journeys (journey_id);
create index if not exists journey_share_consents_user_idx on public.journey_share_consents (user_id);
create index if not exists journey_share_consents_requested_by_idx
  on public.journey_share_consents (requested_by) where requested_by is not null;
create index if not exists check_in_metrics_user_idx on public.check_in_metrics (user_id);
create index if not exists check_in_extras_user_idx on public.check_in_extras (user_id);
create index if not exists message_hides_user_idx on public.message_hides (user_id);
create index if not exists moderation_queue_report_idx
  on public.moderation_queue (report_id) where report_id is not null;
create index if not exists friendships_requested_by_idx on public.friendships (requested_by);
create index if not exists friendships_source_journey_idx
  on public.friendships (source_journey_id) where source_journey_id is not null;
create index if not exists journey_shares_viewer_all_idx on public.journey_shares (viewer_id);
create index if not exists group_invitations_invitee_all_idx on public.group_invitations (invitee_id);
create index if not exists messages_media_path_idx
  on public.messages (media_path) where media_path is not null;

-- ---------------------------------------------------------------------------
-- FS-25: profile_stats() Rule S12 & ended/completed parity
-- ---------------------------------------------------------------------------
create or replace function public.profile_stats()
returns table (
  total_snaps int,
  longest_streak int,
  current_streak int,
  journeys_completed int,
  journeys_total int
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  uid uuid := public._uid();
begin
  return query
  select
    (select count(*)::int
       from public.check_ins c
       join public.journeys cj on cj.id = c.journey_id and cj.deleted_at is null
      where c.user_id = uid and c.deleted_at is null and not c.hidden_by_leave),
    -- S12: imported journeys do not count toward live streaks.
    coalesce(max(s.best_streak) filter (where j.origin <> 'imported'), 0)::int,
    coalesce(max(s.current_streak) filter (
      where j.origin <> 'imported'
        and j.status = 'active'
        and not (j.duration_days is not null
                 and public.local_date(now(), j.timezone) > j.start_date + j.duration_days - 1)
    ), 0)::int,
    (count(*) filter (
      where j.status in ('ended', 'archived')
         or (j.duration_days is not null
             and public.local_date(now(), j.timezone) > j.start_date + j.duration_days - 1)
    ))::int,
    count(*)::int
  from public.memberships m
  join public.journeys j on j.id = m.journey_id and j.deleted_at is null
  cross join lateral public.journey_streak(j.id, uid) s
  where m.user_id = uid and m.status = 'active' and m.deleted_at is null;
end;
$$;

-- ---------------------------------------------------------------------------
-- FS-38: journey_dna_valid NULL trap, btrim checks, report_content dedup,
--        withdraw_share_consent grant revocation
-- ---------------------------------------------------------------------------
create or replace function public.journey_dna_valid(x jsonb) returns boolean
language sql immutable set search_path = ''
as $$
  select coalesce(case
    when x is null then true
    when jsonb_typeof(x) <> 'object' then false
    when octet_length(x::text) > 1024 then false
    when exists (
      select 1 from jsonb_object_keys(x) k
       where k not in ('goal', 'minutes', 'sport', 'measure', 'hud', 'film', 'ritual', 'side',
                       'trophy', 'place', 'habit', 'reason', 'dates')
    ) then false
    else
      not exists (
        select 1 from jsonb_each(x) e
         where e.key in ('goal', 'minutes', 'sport', 'measure', 'hud', 'film', 'ritual', 'side')
           and not (jsonb_typeof(e.value) = 'string' and (e.value #>> '{}') ~ '^[a-z0-9_]{1,24}$')
      )
      and not exists (
        select 1 from jsonb_each(x) e
         where e.key in ('trophy', 'place', 'habit', 'reason')
           and not (jsonb_typeof(e.value) = 'string'
                    and char_length(btrim(e.value #>> '{}')) >= 1
                    and char_length(e.value #>> '{}') between 1
                        and case e.key when 'trophy' then 24 when 'place' then 60
                                       when 'habit' then 40 else 80 end)
      )
      and case when x ? 'dates' then
            jsonb_typeof(x -> 'dates') = 'object'
            and not exists (select 1 from jsonb_object_keys(x -> 'dates') k where k not in ('start', 'end'))
            and (x -> 'dates') ? 'start'
            and jsonb_typeof(x -> 'dates' -> 'start') = 'string'
            and coalesce((x #>> '{dates,start}') ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$', false)
            and case when (x -> 'dates') ? 'end' then
                  jsonb_typeof(x -> 'dates' -> 'end') = 'string'
                  and coalesce((x #>> '{dates,end}') ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$', false)
                  and coalesce((x #>> '{dates,end}') >= (x #>> '{dates,start}'), false)
                else true end
          else true end
  end, false);
$$;

update public.journeys
   set title = case when btrim(title) = '' then 'Journey' else title end,
       emoji = case when btrim(emoji) = '' then '✨' else emoji end
 where btrim(title) = '' or btrim(emoji) = '';

update public.journeys
   set dna = null
 where dna is not null and not public.journey_dna_valid(dna);

update public.profiles
   set display_name = username
 where btrim(display_name) = '';

alter table public.journeys drop constraint if exists journeys_title_not_blank;
alter table public.journeys add constraint journeys_title_not_blank
  check (char_length(btrim(title)) between 1 and 60 and char_length(btrim(emoji)) between 1 and 16) not valid;
alter table public.journeys validate constraint journeys_title_not_blank;

alter table public.profiles drop constraint if exists profiles_display_name_not_blank;
alter table public.profiles add constraint profiles_display_name_not_blank
  check (char_length(btrim(display_name)) between 1 and 40) not valid;
alter table public.profiles validate constraint profiles_display_name_not_blank;

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
begin
  if (p_checkin is null and p_user is null and p_message is null) or p_reason is null then
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
     where m.id = p_message and m.deleted_at is null
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
           and (private.has_active_share(j.id, uid) or j.public_token is not null)
      )
    ) then
      raise exception 'not_found';
    end if;
    select c.user_id into v_target_user from public.check_ins c where c.id = p_checkin;
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

  -- FS-38: deduplicate repeated open reports on the same target by the same reporter.
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

  -- If a prior report on this specific message or check-in was already resolved/dismissed,
  -- the content remains hidden from the caller (FR-F2) and cannot be reported again.
  if (p_message is not null and not private.can_read_message(p_message))
     or (p_checkin is not null and private.has_reported(p_checkin)) then
    raise exception 'not_found';
  end if;

  if (select count(*) from public.reports
       where reporter_id = uid and created_at > now() - interval '24 hours') >= 20 then
    raise exception 'rate_limited';
  end if;

  insert into public.reports (reporter_id, target_checkin_id, target_user_id, target_message_id, reason, note)
  values (uid, p_checkin, v_target_user, p_message, p_reason, left(nullif(btrim(p_note), ''), 500))
  returning id into v_id;
  insert into public.moderation_queue (kind, report_id, actor_id, target_user_id, target_checkin_id,
                                       target_message_id, reason, note)
  values ('report', v_id, uid, v_target_user, p_checkin, p_message, p_reason,
          left(nullif(btrim(p_note), ''), 500));
  return v_id;
end;
$$;

create or replace function public.withdraw_share_consent(p_journey uuid) returns void
language plpgsql security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
begin
  update public.journey_share_consents set status = 'withdrawn', decided_at = now()
   where journey_id = p_journey and user_id = uid;
  if not found then
    raise exception 'not_found';
  end if;
  -- FS-38: withdrawing consent also revokes any shares granted by the withdrawing member.
  update public.journey_shares set revoked_at = now()
   where journey_id = p_journey and shared_by = uid and revoked_at is null;
end;
$$;
