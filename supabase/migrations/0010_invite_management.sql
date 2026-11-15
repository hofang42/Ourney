-- 0010_invite_management: inviter-side invitation management, couple rename, inbox dot.
-- Idempotent. Error convention as 0004-0009 (`raise exception '<code>'`, forbidden = 42501).
--
--  * invitee_kind 'code' is REMOVED. Nothing ever wrote it, and a per-journey invite_code
--    already gives join-by-code (join_by_code / rotate_invite_code, revocable by rotation).
--    A second code mechanism would add a parallel path for no benefit.
--  * status 'revoked' + public.revoke_group_invitation   (inviter or journey owner)
--  * public.journey_pending_invitations                   (active members list pending ones)
--  * public.rename_couple                                 (owner-only, validated)
--  * public.inbox_counts gains group_invitations (old keys unchanged)

-- ---------------------------------------------------------------------------
-- constraints: drop the unused 'code' kind, allow 'revoked'
-- ---------------------------------------------------------------------------
delete from public.group_invitations where invitee_kind = 'code';

alter table public.group_invitations drop constraint if exists group_invitations_target;
alter table public.group_invitations drop constraint if exists group_invitations_invitee_kind_check;
alter table public.group_invitations drop constraint if exists group_invitations_status_check;
alter table public.group_invitations
  add constraint group_invitations_invitee_kind_check check (invitee_kind in ('user', 'handle'));
alter table public.group_invitations
  add constraint group_invitations_status_check
  check (status in ('pending', 'accepted', 'declined', 'revoked'));
alter table public.group_invitations
  add constraint group_invitations_target check (invitee_id is not null);

-- ---------------------------------------------------------------------------
-- revoke_group_invitation: the inviter or the journey owner (both still active members)
-- withdraws a pending invitation. Everything else is the same `not_found`.
-- ---------------------------------------------------------------------------
create or replace function public.revoke_group_invitation(p_invitation uuid) returns void
language plpgsql security definer set search_path = ''
as $$
declare
  uid uuid := public._uid();
begin
  update public.group_invitations i set status = 'revoked', responded_at = now()
   where i.id = p_invitation and i.status = 'pending'
     and (i.inviter_id = uid
          or exists (select 1 from public.journeys j where j.id = i.journey_id and j.owner_id = uid))
     and exists (select 1 from public.memberships m
                  where m.journey_id = i.journey_id and m.user_id = uid
                    and m.status = 'active' and m.deleted_at is null);
  if not found then
    raise exception 'not_found';
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- journey_pending_invitations: pending, unexpired invitations of one group, for its active
-- members (table RLS only shows the two parties, hence the definer function).
-- Invitees blocked by/blocking the caller are hidden.
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
  ), '[]'::json);
end;
$$;

-- ---------------------------------------------------------------------------
-- rename_couple: owner renames the two couple names (both required, 1..24 chars).
-- Errors: not_found (no such journey / not the owner), invalid (not a couple journey or bad
-- names), ended.
-- ---------------------------------------------------------------------------
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
   where id = p_journey and owner_id = uid and deleted_at is null for update;
  if not found then
    raise exception 'not_found';
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

-- ---------------------------------------------------------------------------
-- inbox_counts: + group_invitations (same visibility rules as my_group_invitations).
-- ---------------------------------------------------------------------------
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
         and m.sender_id <> uid and m.deleted_at is null
         and m.created_at > coalesce(case when c.member_id = uid then c.member_read_at else c.viewer_read_at end,
                                     '-infinity'::timestamptz)
         and m.created_at > coalesce(case when c.member_id = uid then c.member_cleared_at else c.viewer_cleared_at end,
                                     '-infinity'::timestamptz)
         and not exists (select 1 from public.message_hides h where h.message_id = m.id and h.user_id = uid)),
    'consent_requests', (
      select count(*)::int from public.journey_share_consents c
        join public.journeys j on j.id = c.journey_id and j.deleted_at is null
       where c.user_id = uid and c.status = 'pending' and private.is_active_member(c.journey_id, uid)),
    'group_invitations', (
      select count(*)::int from public.group_invitations i
        join public.journeys j on j.id = i.journey_id and j.deleted_at is null and j.status = 'active'
       where i.invitee_id = uid and i.status = 'pending' and i.expires_at > now()
         and not private.blocked_between(uid, i.inviter_id)));
end;
$$;

-- ---------------------------------------------------------------------------
-- Privileges
-- ---------------------------------------------------------------------------
revoke all on function
  public.revoke_group_invitation(uuid), public.journey_pending_invitations(uuid),
  public.rename_couple(uuid, text, text), public.inbox_counts()
  from public, anon;
grant execute on function
  public.revoke_group_invitation(uuid), public.journey_pending_invitations(uuid),
  public.rename_couple(uuid, text, text), public.inbox_counts()
  to authenticated;
