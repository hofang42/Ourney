// Contract (A0). Owned by Architect/Orchestrator — feature agents implement
// or consume these interfaces but must not change them without a contract PR.

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
  /// `delete-account`) then wipes local data.
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

  /// Throws [JourneyLimitException] when the user already has 3 active journeys.
  Future<Journey> create(JourneyDraft draft);
  Future<void> end(String journeyId);
  Future<void> archive(String journeyId);
}

abstract interface class CheckInRepository {
  Stream<List<CheckIn>> watchForJourney(String journeyId, {String? userId});

  /// Saves locally at once (visible immediately) and enqueues the upload.
  /// Upserts on (journeyId, userId, localDate): a retake replaces today's.
  Future<CheckIn> submit(CheckInDraft draft);

  /// Number of queued uploads not yet confirmed by the server.
  Stream<int> watchPendingUploads();
}

abstract interface class GroupRepository {
  /// Returns the journey id joined. Throws [GroupException] on full group,
  /// blocked user, unknown code or journey limit.
  Future<String> joinByCode(String code);
  Future<String> rotateInviteCode(String journeyId);
  Stream<List<MemberToday>> watchToday(String journeyId);
  Future<void> react(String checkInId, String emoji);
  Future<void> leave(String journeyId);
  Future<void> removeMember(String journeyId, String userId);
}

abstract interface class SafetyRepository {
  Future<void> report({String? checkInId, String? userId, required ReportReason reason, String? note});
  Future<void> block(String userId);
  Future<void> unblock(String userId);
  Stream<Set<String>> watchBlockedIds();
}

/// Resolves storage paths to displayable bytes/URLs with a disk cache keyed
/// by path (signed URLs change on every call so they are never cache keys).
abstract interface class MediaStore {
  Future<String> localFileFor(String storagePath);
}

class JourneyLimitException implements Exception {
  const JourneyLimitException();
}

class GroupException implements Exception {
  const GroupException(this.code);

  /// One of: `not_found`, `full`, `blocked`, `limit`, `ended`, `offline`.
  final String code;
}
