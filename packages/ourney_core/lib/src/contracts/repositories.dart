// Contract (A0). Owned by Architect/Orchestrator — feature agents implement
// or consume these interfaces but must not change them without a contract PR.
//
// Server mapping (supabase/migrations/0004_rpc.sql, supabase/functions):
//   JourneyRepository.create            -> rpc create_journey
//   JourneyRepository.end               -> rpc end_journey
//   JourneyRepository.delete            -> rpc delete_journey
//   JourneyRepository.setPublicLink     -> rpc set_public_link
//   JourneyRepository.updateMyMembership-> update memberships (hide_metric, blur_media)
//   CheckInRepository.submit            -> upsert check_ins on (journey_id, user_id, local_date)
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
  Future<void> sendOtp(String email);
  Future<void> verifyOtp(String email, String code);
  Future<void> signOut();

  /// Deletes the account and all media server-side (Edge Function
  /// `delete-account`, POST with the user's JWT) then wipes local data.
  /// Groups the user is in are handed over to the earliest member.
  /// Throws [OurneyException] with `unauthenticated` or one of the
  /// `storage*` / `deleteFailed` codes (safe to retry).
  Future<void> deleteAccount();
}

abstract interface class ProfileRepository {
  Stream<Profile?> watchMe();
  Future<void> upsertMe({required String username, required String displayName});
  Future<void> setAvatar(List<int> jpegBytes);
}

abstract interface class JourneyRepository {
  Stream<List<Journey>> watchActive();
  Stream<Journey?> watch(String journeyId);

  /// `create_journey`. The client generates the id (idempotent retry).
  /// Visibility is sent as `draft.visibility` (group → `group`; solo →
  /// `private` or `link`, which issues `Journey.publicToken`).
  /// Throws [JourneyLimitException] when the user already has 3 active
  /// journeys, [OurneyException] `invalid` for a bad kind/visibility combo.
  Future<Journey> create(JourneyDraft draft);

  /// `end_journey` (owner only): status → ended, check-ins become read-only.
  /// Throws `forbidden`, `ended`, `notFound`.
  Future<void> end(String journeyId);

  /// Client-side only in v1: hides an ended journey from the active list.
  /// There is no archive RPC; the server sets `archived` itself when the last
  /// member leaves or the journey is deleted.
  Future<void> archive(String journeyId);

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

  /// Updates the caller's `hide_metric` / `blur_media` (null = unchanged).
  Future<void> updateMyMembership(String journeyId, {bool? hideMetric, bool? blurMedia});
}

abstract interface class CheckInRepository {
  Stream<List<CheckIn>> watchForJourney(String journeyId, {String? userId});

  /// Saves locally at once (visible immediately) and enqueues the upload.
  /// Upserts on (journeyId, userId, localDate): a retake replaces today's.
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
  /// [GroupException] with `notFound`, `full`, `blocked`, `limit`, `ended`,
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
  Future<void> report({String? checkInId, String? userId, required ReportReason reason, String? note});

  /// `block_user` (idempotent). Throws `invalid` (self), `notFound`.
  Future<void> block(String userId);
  Future<void> unblock(String userId);
  Stream<Set<String>> watchBlockedIds();
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
  invalidCapturedAt('invalid_captured_at'), // 22008
  consentRequired('consent_required'), // v1.3: group share needs consent first
  // Edge Function codes.
  methodNotAllowed('method_not_allowed'),
  storageListingFailed('storage_listing_failed'),
  storageCleanupIncomplete('storage_cleanup_incomplete'),
  storageCleanupFailed('storage_cleanup_failed'),
  deleteFailed('delete_failed'),
  internal('internal'),
  // Client-side.
  offline('offline'),
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
  /// SQLSTATE decides (42501 forbidden, 28000 unauthenticated, 22008
  /// invalidCapturedAt, other 22xxx/23xxx invalid, e.g. a bad timezone or a
  /// CHECK violation).
  static OurneyErrorCode fromServer({String? message, String? sqlstate}) {
    if (message != null) {
      final byMessage = fromWire(message);
      if (byMessage != unknown) return byMessage;
    }
    switch (sqlstate) {
      case '42501':
        return forbidden;
      case '28000':
        return unauthenticated;
      case '22008':
        return invalidCapturedAt;
    }
    if (sqlstate != null && (sqlstate.startsWith('22') || sqlstate.startsWith('23'))) {
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
  String toString() => 'OurneyException($code${detail == null ? '' : ': $detail'})';
}

class JourneyLimitException extends OurneyException {
  const JourneyLimitException([String? detail]) : super(OurneyErrorCode.limit, detail);
}

class GroupException extends OurneyException {
  /// From a wire code string (backward compatible): one of `not_found`,
  /// `full`, `blocked`, `limit`, `ended`, `forbidden`, `offline`, ...
  GroupException(String code) : super(OurneyErrorCode.fromWire(code));

  const GroupException.of(super.error, [super.detail]);
}
