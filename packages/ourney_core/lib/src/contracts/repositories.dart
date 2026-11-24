// Contract (A0). Owned by Architect/Orchestrator — feature agents implement
// or consume these interfaces but must not change them without a contract PR.
//
// Server mapping (supabase/migrations/0004_rpc.sql, supabase/functions):
//   JourneyRepository.create            -> rpc create_journey
//   JourneyRepository.end               -> rpc end_journey
//   JourneyRepository.delete            -> rpc delete_journey
//   JourneyRepository.setPublicLink     -> rpc set_public_link
//   JourneyRepository.updateMyMembership-> update memberships (hide_metric, blur_media)
//   CheckInRepository.submit            -> upsert check_ins on (id) (0014: many per day)
//   GroupRepository.joinByCode          -> rpc join_by_code
//   GroupRepository.rotateInviteCode    -> rpc rotate_invite
//   GroupRepository.leave               -> rpc leave_journey
//   GroupRepository.removeMember        -> rpc remove_member
//   GroupRepository.watchToday          -> rpc group_today
//   GroupRepository.react / unreact     -> upsert reactions (unreact sets deleted_at)
//   SafetyRepository.report             -> rpc report_content
//   SafetyRepository.block / unblock    -> rpc block_user / unblock_user
//   AuthRepository.deleteAccount        -> Edge Function `delete-account` (POST)
//   public read-only link               -> Edge Function `public-journey` (see paths.dart)
//
// Errors: every method that reaches the server throws [OurneyException] (or a
// subclass) whose [OurneyException.error] is mapped with
// [OurneyErrorCode.fromServer]. Writes that are queued offline do not throw.

import '../models.dart';
import 'social.dart' show PersonSummary;

/// Result of an attempt that may need the server.
sealed class SyncResult {
  const SyncResult();
}

class SyncOk extends SyncResult {
  const SyncOk();
}

class SyncOffline extends SyncResult {
  const SyncOffline();
}

class SyncFailed extends SyncResult {
  const SyncFailed(this.message);
  final String message;
}

abstract interface class AuthRepository {
  /// Null when signed out or when running in local-only mode.
  String? get currentUserId;
  bool get isLocalOnly;
  Stream<String?> watchUserId();

  /// How the account signs in: its email, else its phone number. Null when
  /// signed out or local-only.
  String? get signInIdentifier;

  /// Version of the terms the account accepted (`profiles.terms_version`).
  /// Null when absent or local-only.
  int? get acceptedTermsVersion;

  /// Records on the account that it accepted terms [version] (once per
  /// account, RPC `accept_terms`). No-op in local-only mode.
  Future<void> recordTermsAccepted(int version);
  Future<void> sendOtp(String email);
  Future<void> verifyOtp(String email, String code);

  /// Phone OTP (SMS). [e164Phone] is `+84912345678`. Needs an SMS provider
  /// configured in the Supabase dashboard (docs/runbooks/hosted-supabase.md).
  Future<void> sendPhoneOtp(String e164Phone);
  Future<void> verifyPhoneOtp(String e164Phone, String code);

  /// Email + password sign-up. Returns true when the server wants the emailed
  /// code first (then call [confirmSignUp]); false when the user is signed in.
  Future<bool> signUpWithPassword(String email, String password);
  Future<void> confirmSignUp(String email, String code);
  Future<void> signInWithPassword(String email, String password);

  /// Forgot password: emails a 6-digit code; [resetPassword] verifies it and
  /// sets [newPassword] (the user ends up signed in).
  Future<void> sendPasswordReset(String email);
  Future<void> resetPassword(String email, String code, String newPassword);

  Future<void> signOut();

  /// Deletes the account and all media server-side (Edge Function
  /// `delete-account`, POST with the user's JWT) then wipes local data.
  /// Groups the user is in are handed over to the earliest member.
  /// Throws [OurneyException] with `unauthenticated` or one of the
  /// `storage*` / `deleteFailed` codes (safe to retry).
  ///
  /// Server-side the call is gated by a one-time [code] (3-step delete:
  /// confirm, OTP, final). Get one with [requestDeleteCode]; a wrong or
  /// missing code throws `invalid`, too many requests `rateLimited`.
  Future<void> deleteAccount({String? code});

  /// Sends the delete-confirmation code to the account's own email (or phone
  /// when it has no email). Edge Function `delete-account` `{action: send}`.
  Future<void> requestDeleteCode();
}

abstract interface class ProfileRepository {
  Stream<Profile?> watchMe();
  Future<void> upsertMe(
      {required String username, required String displayName});
  Future<void> setAvatar(List<int> jpegBytes);
}

abstract interface class JourneyRepository {
  Stream<List<Journey>> watchActive();

  /// Every journey the caller has a membership in, archived and ended ones
  /// included (one-shot). Used to push account-wide preferences.
  Future<List<Journey>> allMine();
  Stream<Journey?> watch(String journeyId);

  /// Journeys hidden with [archive] (client-side), newest first. They come
  /// back to [watchActive] with [unarchive].
  Stream<List<Journey>> watchArchived();

  /// `create_journey`. The client generates the id (idempotent retry).
  /// Visibility is sent as `draft.visibility` (group → `group`; solo →
  /// `private` or `link`, which issues `Journey.publicToken`).
  /// No cap on running journeys (SRS FR-B3). Throws [OurneyException]
  /// `invalid` for a bad kind/visibility combo.
  ///
  /// The create-flow extras (cover, colour, reminder, layout...) are sent
  /// right after. When the server permanently rejects them the journey is
  /// kept, the extras are rolled back and [onExtrasRejected] is called (a
  /// non-fatal warning: failing here would strand a journey that exists).
  Future<Journey> create(
    JourneyDraft draft, {
    void Function()? onExtrasRejected,
  });

  /// `update_journey` (owner only): rename, layout, cover, colour, reminder
  /// time, DNA. Throws `notFound`, `ended`, `invalid`.
  Future<Journey> update(String journeyId, JourneyUpdate update);

  /// `end_journey` (owner only): status → ended, check-ins become read-only.
  /// Throws `forbidden`, `ended`, `notFound`.
  ///
  /// [background] is the automatic end of an expired window: it must not force
  /// the outbox to retry (that would burn the retry budget of failing uploads).
  /// Throws [OurneyErrorCode.syncPending] while uploads of the journey are queued.
  Future<void> end(String journeyId, {bool background = false});

  /// Client-side only in v1: hides an ended journey from the active list.
  /// There is no archive RPC; the server sets `archived` itself when the last
  /// member leaves or the journey is deleted.
  Future<void> archive(String journeyId);

  /// Undoes [archive]: the journey is listed again.
  Future<void> unarchive(String journeyId);

  /// `delete_journey` (owner only, solo or alone in the group). Throws
  /// `notAlone` while other active members exist (use [end] instead),
  /// `forbidden`, `notFound`. The RPC only tombstones rows: implementations
  /// must then remove the caller's own media under `checkins/{journeyId}/`
  /// via the Storage API (own-objects delete policy).
  Future<void> delete(String journeyId);

  /// `set_public_link` (solo journeys only). `enabled: true` creates or
  /// rotates the token (old links stop working) and returns it; `false`
  /// revokes it and returns null. Throws `invalid` for group journeys,
  /// `forbidden`, `ended` (archived), `notFound`.
  Future<String?> setPublicLink(String journeyId, {required bool enabled});

  /// The caller's own `memberships` row (role, status, joinedAt, prefs).
  /// Use `joinedAt` with `computeMemberStreak` / `effectiveStreakStart`.
  Stream<Membership?> watchMyMembership(String journeyId);

  /// Ids of the journeys the caller pinned (`memberships.pinned`); also
  /// works local-only. [watchActive] lists pinned journeys first.
  Stream<Set<String>> watchPinnedJourneyIds();

  /// Updates the caller's `hide_metric` / `blur_media` / `hide_extras` /
  /// `pinned` (null = unchanged).
  Future<void> updateMyMembership(String journeyId,
      {bool? hideMetric, bool? blurMedia, bool? hideExtras, bool? pinned});
}

abstract interface class CheckInRepository {
  Stream<List<CheckIn>> watchForJourney(String journeyId, {String? userId});

  /// Saves locally at once (visible immediately) and enqueues the upload.
  /// Each call adds a new check-in (several per day are allowed, FR-C7,
  /// migration 0014); the streak still counts a day once.
  /// The server recomputes `local_date`; rejects with `ended` after the
  /// journey ends and `invalidCapturedAt` for timestamps > now + 10 min.
  /// Streaks shown for the user must use `computeMemberStreak` (counts from
  /// the member's join date, like the server's `journey_streak`).
  Future<CheckIn> submit(CheckInDraft draft);

  /// Number of queued uploads not yet confirmed by the server.
  Stream<int> watchPendingUploads();
}

abstract interface class GroupRepository {
  /// `join_by_code`. Returns the journey id joined (idempotent; a rejoin
  /// restores the member's earlier check-ins and joinedAt). Throws
  /// [GroupException] with `notFound`, `full`, `blocked`, `ended`,
  /// `forbidden` or `offline`.
  Future<String> joinByCode(String code);

  /// `rotate_invite` (owner only). Throws `forbidden`, `invalid` (solo),
  /// `ended`, `notFound`.
  Future<String> rotateInviteCode(String journeyId);

  /// `group_today`: active, non-blocked members with today's check-in and
  /// server-computed current streak. Throws `forbidden` if not a member.
  Stream<List<MemberToday>> watchToday(String journeyId);

  /// One reaction per (checkIn, user); a new emoji replaces the old one.
  /// [emoji] must be one of [reactionEmojis]. Throws `ended` once the
  /// journey is no longer active.
  Future<void> react(String checkInId, String emoji);

  /// Removes the caller's reaction (soft delete: `deleted_at`).
  Future<void> unreact(String checkInId);

  /// Live (not deleted) reactions on a check-in, minus blocked users.
  Stream<List<Reaction>> watchReactions(String checkInId);

  /// `leave_journey`. Hides the caller's check-ins from the group (restored
  /// on rejoin); ownership passes to the earliest-joined active member.
  Future<void> leave(String journeyId);

  /// `remove_member` (owner only; same effects as that member leaving).
  /// Throws `forbidden`, `invalid` (removing yourself), `notFound`.
  Future<void> removeMember(String journeyId, String userId);
}

abstract interface class SafetyRepository {
  /// `report_content`: at least one of [checkInId] / [userId]. The reported
  /// check-in is hidden from the reporter at once. Throws `invalid`,
  /// `notFound`, `rateLimited` (20 reports / 24 h).
  Future<void> report(
      {String? checkInId,
      String? userId,
      required ReportReason reason,
      String? note});

  /// `block_user` (idempotent). Throws `invalid` (self), `notFound`.
  Future<void> block(String userId);
  Future<void> unblock(String userId);
  Stream<Set<String>> watchBlockedIds();

  /// `my_blocked_people` (U16): the people the caller blocked with their real
  /// names, even on a fresh device. Server only: throws `offline` without one.
  Future<List<PersonSummary>> myBlockedPeople();
}

/// Resolves storage paths to displayable bytes/URLs with a disk cache keyed
/// by path (signed URLs change on every call so they are never cache keys).
abstract interface class MediaStore {
  Future<String> localFileFor(String storagePath);
}

/// Every error code the backend can produce (SQL `raise exception '<code>'`
/// in 0001/0004, Edge Function `{"error": "<code>"}` bodies) plus client-side
/// codes. [wireName] is the exact server string.
enum OurneyErrorCode {
  // RPC / trigger codes (SQLSTATE P0001 unless noted).
  unauthenticated('unauthenticated'), // 28000; also delete-account 401
  forbidden('forbidden'), // 42501 (also plain RLS denials)
  invalid('invalid'),
  notFound('not_found'), // also public-journey 404
  full('full'),
  blocked('blocked'),
  limit('limit'),
  ended('ended'),
  notAlone('not_alone'),
  rateLimited('rate_limited'),
  immutableColumn('immutable_column'), // 23514
  contentPolicy('content_policy'), // 23514 (0020 objectionable_words filter)
  linksNotAllowed('links_not_allowed'), // 23514 (0024 URL guard)
  invalidCapturedAt('invalid_captured_at'), // 22008
  consentRequired('consent_required'), // v1.3: group share needs consent first
  // Edge Function codes.
  methodNotAllowed('method_not_allowed'),
  storageListingFailed('storage_listing_failed'),
  storageCleanupIncomplete('storage_cleanup_incomplete'),
  storageCleanupFailed('storage_cleanup_failed'),
  deleteFailed('delete_failed'),
  // delete-account 410: the caller's account no longer exists (a retry after a lost response).
  alreadyDeleted('already_deleted'),
  internal('internal'),
  // Client-side.
  // The auth provider (e.g. phone/SMS) is turned off on the server.
  unavailable('unavailable'),
  // PostgREST PGRST202/PGRST203: the RPC is missing or ambiguous, so the
  // server lacks a migration (the app is newer than the backend).
  serverOutdated('server_outdated'),
  offline('offline'),
  syncPending('sync_pending'), // queued uploads of the journey are not sent yet
  unknown('unknown');

  const OurneyErrorCode(this.wireName);
  final String wireName;

  /// Unknown strings map to [unknown] (forward compatible, never throws).
  static OurneyErrorCode fromWire(String wire) {
    final w = wire.trim();
    for (final c in values) {
      if (c.wireName == w) return c;
    }
    return unknown;
  }

  /// Maps a PostgREST/Postgres error: the raised message wins; otherwise the
  /// SQLSTATE decides (PGRST202/203 serverOutdated, 42501 forbidden, 28000 unauthenticated, 22008
  /// invalidCapturedAt, other 22xxx/23xxx invalid, e.g. a bad timezone or a
  /// CHECK violation).
  static OurneyErrorCode fromServer({String? message, String? sqlstate}) {
    if (message != null) {
      final byMessage = fromWire(message);
      if (byMessage != unknown) return byMessage;
      if (message.toLowerCase().contains('could not find the function')) {
        return serverOutdated;
      }
    }
    switch (sqlstate) {
      case 'PGRST202' || 'PGRST203' || '42883':
        return serverOutdated;
      case '42501':
        return forbidden;
      case '28000':
        return unauthenticated;
      case '22008':
        return invalidCapturedAt;
    }
    if (sqlstate != null &&
        (sqlstate.startsWith('22') || sqlstate.startsWith('23'))) {
      return invalid;
    }
    return unknown;
  }
}

/// Base type for every error a repository surfaces.
class OurneyException implements Exception {
  const OurneyException(this.error, [this.detail]);

  final OurneyErrorCode error;

  /// Raw server message for logs; never shown to users.
  final String? detail;

  /// Wire name of [error] (e.g. `not_found`).
  String get code => error.wireName;

  @override
  String toString() =>
      'OurneyException($code${detail == null ? '' : ': $detail'})';
}

class GroupException extends OurneyException {
  /// From a wire code string (backward compatible): one of `not_found`,
  /// `full`, `blocked`, `ended`, `forbidden`, `offline`, ...
  GroupException(String code) : super(OurneyErrorCode.fromWire(code));

  const GroupException.of(super.error, [super.detail]);
}
