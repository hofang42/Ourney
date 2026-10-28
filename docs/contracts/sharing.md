# Contract: social / journey sharing (v1.3)

Implements [docs/09-journey-sharing.md](../09-journey-sharing.md) (S1–S40). Server source of truth:
`supabase/migrations/0006_social.sql`. Dart side: `packages/ourney_core/lib/src/contracts/social.dart`
(models + `FriendRepository`, `SharingRepository`, `ShareConsentRepository`, `ChatRepository`,
`InsightsRepository`). This file fixes the **wire API** both sides code against; table internals may
differ as long as the RPCs below behave as described.

Conventions (same as `schema.md`): every RPC is `security definer`, `set search_path = ''`, raises
`P0001` with the wire codes of `OurneyErrorCode` (`unauthenticated`, `forbidden`, `invalid`,
`not_found`, `rate_limited`, `blocked`, `consent_required`). Authorization helpers live in schema
`private`. Every new table has RLS on and a pgTAP test in `supabase/tests/06_social*.test.sql`.
"Person" JSON = `{"user_id","username","display_name","avatar_path"}`. Dates are `YYYY-MM-DD`,
instants ISO-8601 UTC.

## Schema changes

| Object | Change |
|---|---|
| `journeys` | + `origin text not null default 'live' check (origin in ('live','imported'))`, `story_title text` (≤ 80), `story_intro text` (≤ 600), `story_lessons text` (≤ 600), `cover_checkin_id uuid null references check_ins`, `followed_from uuid null references journeys on delete set null`, `show_counts bool not null default false`, `allow_public_reactions bool not null`, `allow_viewer_requests bool not null` (defaults per S28: `false` for `weight_loss`, else `true`). `public_token` is decoupled from `visibility`: a **group** journey may hold a `public_token` (owner sets it) while `visibility` stays `group`. Solo with a token has `visibility = 'link'` as before. |
| `check_ins` | + `hidden_in_share bool not null default false` (author-updatable only). The 3-journey-local-day `captured_at` rule and the "journey must be active" rule are **skipped for `origin = 'imported'` journeys written by their owner**; `local_date` must still fall within `start_date .. start_date + duration_days - 1`. |
| `friendships` | `(user_low, user_high)` PK (`user_low < user_high`), `requested_by uuid`, `status text` (`pending`/`accepted`), `source text` (`direct`/`public_journey`), `source_journey_id uuid null`, `accepted_at`, `created_at`, `updated_at`, `deleted_at`. Readable by the two users only. No direct writes (RPC only). |
| `friend_invites` | `user_id uuid PK`, `token text unique` (12 chars, `random_token`), `created_at`. One active token per user; rotating replaces it. No client access (RPC only). |
| `journey_shares` | `(journey_id, viewer_id, shared_by)` PK, `granted_at`, `revoked_at null`, `seen_at null`. Viewer reads rows where `viewer_id = auth.uid()`; `shared_by` reads its own rows; owner reads all rows of its journey. Writes via RPC only. |
| `journey_share_consents` | `(journey_id, user_id)` PK, `status` (`pending`/`accepted`/`declined`/`withdrawn`), `requested_by`, `decided_at`, `created_at`, `updated_at`. Readable by active members of the journey. RPC writes only. A member joining a journey that has any consent row gets a `pending` row (trigger on memberships). |
| `saved_journeys` | `(user_id, journey_id)` PK, `created_at`. Created when a **stranger** likes a photo of a public journey; deleted when their last like on it goes or via `unsave_journey`. Own rows only. |
| `journey_views` | `(journey_id, viewer_key, day)` PK. `viewer_key` = user id text, or an opaque hash from the Edge Function. Never counts members. **No client read** — only `journey_insights` / `my_reach`. |
| `conversations` | `id uuid PK`, `journey_id`, `member_id` (recipient side: solo owner, or S33 target), `viewer_id`, `last_message_at`, `member_read_at`, `viewer_read_at`, `member_cleared_at`, `viewer_cleared_at`, `created_at`, `updated_at`; unique `(journey_id, member_id, viewer_id)`. Readable by the two participants. RPC writes only. |
| `messages` | `id uuid PK` (client-generated), `conversation_id`, `sender_id`, `kind` (`text`/`photo`/`clip`), `body text` (≤ 500), `media_path text null`, `reply_to_checkin_id uuid null`, `created_at`, `deleted_at` (server only). Participants read (minus their `message_hides`, minus messages older than their `*_cleared_at`); RPC writes only. **Realtime publication on `messages`** (RLS-filtered). |
| `message_hides` | `(message_id, user_id)` PK. Own rows only. |
| `reactions` | RLS insert/delete also allowed for (a) a viewer with an active `journey_shares` row on the check-in's journey, (b) a signed-in non-member when the journey has a `public_token` **and** `allow_public_reactions` (never for check-ins whose author has not `accepted` consent on a group journey, never for `hidden_in_share`). Viewers cannot read others' reactions. |
| `reports` | + `target_message_id uuid null`. `report_content` gains `p_message uuid default null`. |
| Storage | `checkins` bucket read also allowed for friends with an active share / anyone through `shared_journey` signed URLs is **not** needed: extend `private.can_read_checkin_object` so a viewer with an active share (or a signed-in stranger on a public journey) can read objects of visible check-ins. New bucket `messages` (private): path `messages/{conversation_id}/{sender_id}/{message_id}.jpg`; write by the sender if participant, read by both participants. |
| Profiles | `private.can_see_profile` also true for friends and for both sides of a pending request, and for the owner / consenting members of a journey the caller can view. |
| Unfriend / block | Removing a friendship or blocking revokes every `journey_shares` row between the pair (both directions) and makes their conversations read-only. |

## RPCs

### Friends
| RPC | Returns | Rules |
|---|---|---|
| `my_friends()` | `setof json` `{person, status, direction ('incoming'/'outgoing'), source, source_journey_id, source_journey_title, created_at, accepted_at}` | Non-deleted rows of the caller, blocked pairs excluded, newest first. |
| `find_user_by_username(p_username text)` | `json` person or `null` | Exact match, case-insensitive, never the caller, not blocked, not deleted. 30 lookups / user / hour → `rate_limited`. |
| `send_friend_request(p_user uuid, p_source_journey uuid default null)` | `void` | `invalid` for self, `blocked` if blocked pair, idempotent when already pending/accepted; if the other user had a pending request to the caller → accept. With `p_source_journey`: the journey must be public, `allow_viewer_requests`, not a `custom` baby template (n/a in v1 enums), caller not already friend; ≤ 20 such requests / sender / day (S39) → `rate_limited`; source = `public_journey`. |
| `respond_friend_request(p_user uuid, p_accept boolean)` | `void` | Incoming pending only → else `not_found`. Decline = soft delete. |
| `remove_friend(p_user uuid)` | `void` | Soft delete; revokes shares both ways. |
| `create_friend_invite()` | `text` token | Rotates. |
| `accept_friend_invite(p_token text)` | `json` person | `not_found` for unknown token, `invalid` for own token, `blocked`; creates/turns the pair **accepted** (source `direct`). |

### Sharing
| RPC | Returns | Rules |
|---|---|---|
| `journey_share_state(p_journey uuid)` | `json` `{journey_id, viewers:[person], story:{title,intro,lessons,cover_checkin_id}, public:{show_counts,allow_public_reactions,allow_viewer_requests}, hidden_checkin_ids:[uuid], public_token}` | Owner / active member. `viewers` = the **caller's** active grants. |
| `share_journey(p_journey uuid, p_viewers uuid[])` | `void` | Caller must be an active member; every viewer must be an accepted friend of the caller (else `forbidden`). Group journey: the caller must have an `accepted` consent row (else `consent_required`). Re-granting a revoked row clears `revoked_at`, resets `seen_at`. |
| `unshare_journey(p_journey uuid, p_viewer uuid default null, p_all boolean default false)` | `void` | Revokes caller's grant(s). `p_all` (owner only): revoke everyone's grants and clear `public_token` (visibility back to `private` for solo). |
| `update_journey_story(p_journey uuid, p_title text, p_intro text, p_lessons text, p_cover uuid)` | `void` | Owner only. Empty strings → null. Cover must be a check-in of the journey. |
| `update_public_settings(p_journey uuid, p_show_counts boolean, p_allow_reactions boolean, p_allow_requests boolean)` | `void` | Owner only. |
| `set_hidden_in_share(p_checkin uuid, p_hidden boolean)` | `void` | Author only. |
| `set_public_link(journey uuid, enabled boolean, reset boolean default false)` | `text` token or null | **Replaces** the v1.2 function (same name, new optional arg). Owner only (solo or group owner). Enabling requires `status in ('ended','archived')` or `origin = 'imported'` (S9) → else `invalid`; under-18 owner → `forbidden` (existing rule if present). `reset` issues a new token. Solo: visibility follows (`link` / `private`). Group: visibility stays `group`. |
| `shared_with_me()` | `setof json` `{journey_id,title,emoji,template_id,kind,origin,status,owner:person,shared_by:person,shared_at,photo_count,saved,unseen,first_date,last_date,cover_thumb_path}` | Active grants to the caller (earliest active grant per journey = `shared_by`) **plus** `saved_journeys` whose journey still has a `public_token` (`saved = true`, `shared_by` = owner). Excludes deleted journeys and blocked owners. Newest first. |
| `shared_journey(p_journey uuid)` | `json` view (below) | Members: everything. Friends with an active grant: `role = 'friend'`. Else `forbidden`. Records a view (non-members) and sets `seen_at`. |
| `public_journey_by_token(p_token text)` | `json` view | Signed-in caller; `not_found` when the token is unknown. Member → `role 'member'`; active grantee → `'friend'`; else `'stranger'`. Records a view. |
| `follow_frame(p_journey uuid)` | `json` `{source_journey_id,template_id,kind,title,emoji,owner_name,duration_days,metric_name,metric_unit}` | Caller can view it (member/grantee/public token) and `status in ('ended','archived')` or `origin='imported'` → else `invalid`. |
| `mark_followed(p_journey uuid, p_source uuid)` | `void` | `p_journey` owned by caller, created ≤ 1 day ago; sets `followed_from`. |
| `create_imported_journey(p_id uuid, p_title text, p_emoji text, p_template template_id, p_first date, p_last date, p_timezone text, p_metric_name text default null, p_metric_unit text default null)` | `journeys` row | Solo, `origin='imported'`, `status='ended'`, `visibility='private'`, `start_date = p_first`, `duration_days = p_last - p_first + 1` (1..366 → else `invalid`), `p_last <= today`. Not counted toward the 3-active limit. Idempotent on `p_id`. |
| `unsave_journey(p_journey uuid)` | `void` | Deletes the caller's saved row and their likes on it. |

**View JSON** (`shared_journey`, `public_journey_by_token`):
`{journey_id, role, title, emoji, template_id, kind, origin, status, duration_days, start_date, owner:person, members:[person], story:{title,intro,lessons,cover_checkin_id}, photos:[{checkin_id, author:person, local_date, photo_path, thumb_path, caption, metric_value, like_count, liked_by_me, blurred}], current_streak, like_count, follow_count, metric_name, metric_unit, shared_by:person|null, can_react, can_reply, can_follow, can_add_owner, saved}`.
Non-members never get photos with `hidden_in_share`, deleted, or (group) from authors without `accepted` consent; `metric_value` is null when the author hides metrics; `current_streak` null for imported journeys and for strangers on groups; `like_count`/`follow_count` null for non-members unless `show_counts`; per-photo `like_count` for non-members is the total only when `show_counts`, else 0 (they still get `liked_by_me`). `can_reply` only for `friend`; `can_follow` per S9; `can_add_owner` = stranger + `allow_viewer_requests` + not friends + not pending.

### Group consents
| RPC | Returns | Rules |
|---|---|---|
| `share_consents(p_journey uuid)` | `setof json` `{journey_id, journey_title, member:person, status, requested_by:person, decided_at}` | Active members. |
| `my_pending_consents()` | `setof json` (same shape) | Caller's `pending` rows on active memberships. |
| `request_share_consent(p_journey uuid)` | `void` | Group journey, active member. Upserts the caller `accepted` and every other active member without a row `pending`. |
| `respond_share_consent(p_journey uuid, p_accept boolean)` | `void` | Caller's row → `accepted` / `declined`. |
| `withdraw_share_consent(p_journey uuid)` | `void` | Caller's row → `withdrawn` (S31). |

### Chat
| RPC | Returns | Rules |
|---|---|---|
| `open_conversation(p_journey uuid, p_checkin uuid default null)` | `uuid` | Caller must be a **friend grantee** of the journey (S13/S24: strangers → `forbidden`). Recipient (`member_id`): solo → owner; group → author of `p_checkin` if that author is the caller's friend and consented, else the `shared_by` of the earliest active grant (S33). Reuses the existing row. |
| `my_conversations()` | `setof json` `{id, journey_id, journey_title, other:person, unread_count, read_only, last_message_at, last_message_preview, last_message_kind}` | Participant side only, excluding conversations whose last message is older than the caller's cleared mark; newest first. `read_only` when no longer friends or blocked. |
| `conversation_messages(p_conversation uuid, p_before timestamptz default null, p_limit int default 100)` | `setof json` `{id, conversation_id, sender_id, kind, body, media_path, reply_to_checkin_id, reply_to_thumb_path, created_at}` | Participant; excludes hidden / cleared / deleted; ascending by `created_at`. |
| `send_message(p_id uuid, p_conversation uuid, p_kind text, p_body text, p_media_path text, p_reply_to uuid default null)` | `json` message | Participant, not `read_only` → `forbidden`; `text` needs 1..500 chars; `photo` needs `media_path` under `messages/{conversation}/{caller}/`. Idempotent on `p_id`. 60 messages / sender / minute → `rate_limited`. Bumps `last_message_at`. |
| `mark_conversation_read(p_conversation uuid)` | `void` | Sets the caller's `*_read_at = now()`. |
| `clear_conversation(p_conversation uuid)` | `void` | Sets the caller's `*_cleared_at = now()`; when both marks pass a message it is hard-deleted (S37). |
| `hide_message(p_message uuid)` | `void` | Participant. |

### Inbox & insights
| RPC | Returns | Rules |
|---|---|---|
| `inbox_counts()` | `json` `{friend_requests, public_requests, new_shares, unread_messages, consent_requests}` | Caller only. `friend_requests` = incoming pending `direct`; `public_requests` = incoming pending `public_journey`; `new_shares` = active grants with `seen_at is null`; `unread_messages` = messages from the other side newer than the caller's read mark. |
| `journey_insights(p_journey uuid)` | `json` `{journey_id, views, views_by_day:[{day,count}], likes_from_friends, likes_from_strangers, started, views_this_week, likes_this_week, started_this_week, likers:[person]}` | Solo owner or active member (S32); `likers` = people who liked the **caller's own** photos (S20). Week = last 7 journey-local days. |
| `my_reach()` | `int` | Distinct `viewer_key` over journeys the caller owns (solo) or is an active member of. |

### Edge Function `public-journey`
Keeps its route. Response adds `story`, `origin`, `can_follow`, `frame` (as `follow_frame`), `like_count`/`follow_count` only when `show_counts`; drops `hidden_in_share` photos and non-consenting authors; records a view with `viewer_key = sha256(token || ua || day-salt)` (no raw IP). Group journeys with a token are served.
