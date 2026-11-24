import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/providers.dart';
import '../../profile/profile_providers.dart' show myProfileProvider;

/// Support address shown on the contact page. Comes from
/// `--dart-define=SUPPORT_EMAIL` (see `AppConfig`) and defaults to the
/// placeholder `support@ourney.tech` until the owner confirms the real mailbox
/// (docs/adr/0002-support-email-and-legal-text.md).
final supportEmailProvider = Provider<String>(
  (ref) => ref.watch(appConfigProvider).supportEmail,
);

/// Date shown as "last updated" on the EULA and privacy pages. Bump when
/// the texts in l10n/safety_*.arb change.
final DateTime kLegalLastUpdated = DateTime(2026, 10, 16);

/// Version of the terms and privacy text the user has to accept. Bump it only
/// when the text changes materially: accounts that accepted an older version
/// are then asked again (`profiles.terms_version`).
const int kTermsVersion = 1;

/// Required terms version ([kTermsVersion]; overridable in tests to exercise
/// version bumps).
final termsVersionProvider = Provider<int>((ref) => kTermsVersion);

/// Shared-preferences keys of the safety feature.
abstract final class SafetyPrefs {
  /// `true` once the user accepted the EULA in local-only / signed-out mode
  /// (FR-F3). Signed-in accounts use [termsVersionFor].
  static const eulaAccepted = 'safety.eulaAccepted';

  /// Prefix of the per-account accepted terms version (`int`).
  static const termsVersionPrefix = 'safety.termsVersion.';

  /// Shared-preferences key storing the accepted [kTermsVersion] (`int`)
  /// for [userId].
  static String termsVersionFor(String userId) => '$termsVersionPrefix$userId';

  /// The user id of a [termsVersionFor] preference [key], else null.
  static String? userIdOfTermsKey(String key) =>
      key.startsWith(termsVersionPrefix)
      ? key.substring(termsVersionPrefix.length)
      : null;

  /// JSON `{userId: displayName}` of people blocked from this device, so
  /// the blocked list can show names (the contract only streams ids).
  static const blockedNames = 'safety.blockedNames';
}

/// Whether the EULA was accepted (FR-F3, Apple Guideline 1.2). Gate any
/// user-generated content on it; see lib/features/safety/README.md.
///
/// Accepted when this device remembers the current account's consent for
/// [kTermsVersion] OR the signed-in account carries
/// `terms_version >= kTermsVersion` on the server (`profiles.terms_version`),
/// so an existing account is never asked again after signing in on a new
/// device, while account switches and [kTermsVersion] bumps re-ask.
class EulaAccepted extends Notifier<bool> {
  final Set<String> _inFlightRecords = {};
  String? _deferredClickwrapUserId;

  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final requiredVersion = ref.watch(termsVersionProvider);
    // Recomputes when the session arrives or the account changes.
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) {
      _deferredClickwrapUserId = null;
      return prefs.getBool(SafetyPrefs.eulaAccepted) ?? false;
    }
    final key = SafetyPrefs.termsVersionFor(userId);
    final localVer = prefs.getInt(key) ?? 0;
    final localOk = localVer >= requiredVersion;
    final AuthRepository auth;
    try {
      auth = ref.watch(authRepositoryProvider);
    } on Object {
      return localOk; // Not wired.
    }
    Profile? profile;
    var profileLoaded = false;
    try {
      // Triggers the existing `profiles` select and rebuilds when it arrives.
      ref.watch(profileRepositoryProvider);
      final profileAsync = ref.watch(myProfileProvider);
      if (profileAsync.hasValue) {
        profileLoaded = true;
        profile = profileAsync.value;
      }
    } on Object {
      // ProfileRepository not wired in this test.
    }
    final authVer = auth.acceptedTermsVersion ?? 0;
    final profileVer = profile?.termsVersion ?? 0;
    final serverVer = authVer > profileVer ? authVer : profileVer;
    final serverOk = serverVer >= requiredVersion;
    if (_deferredClickwrapUserId == userId && profileLoaded) {
      _deferredClickwrapUserId = null;
      if (serverVer <= 0 && !localOk) {
        // Initial profile fetch succeeded and confirmed no prior terms version
        // (brand-new user or unaccepted profile): record clickwrap consent now.
        unawaited(Future.microtask(accept));
      }
    }
    if (localOk && !serverOk) {
      // Accepted by this user for this version on this device, but the
      // account record failed earlier: retry quietly (deduplicated while
      // already in flight, M2).
      unawaited(_record(auth, userId, localVer));
    } else if (serverOk && localVer < serverVer) {
      // Cheap local cache of the server record for this user.
      unawaited(prefs.setInt(key, serverVer));
    }
    return localOk || serverOk;
  }

  /// Defers initial clickwrap consent recording when the post-sign-in profile
  /// check failed or timed out while `acceptedTermsVersion` was still `null`
  /// (unknown), so a returning account on an older terms version never has
  /// bumped consent forged before `TermsUpdateSheet` can appear (H2).
  void deferInitialClickwrap(String? userId) {
    final uid = userId ?? ref.read(currentUserIdProvider);
    if (uid == null) return;
    _deferredClickwrapUserId = uid;
  }

  Future<void> _record(
    AuthRepository auth,
    String expectedUserId,
    int version,
  ) async {
    final flightKey = '$expectedUserId:$version';
    if (_inFlightRecords.contains(flightKey)) return;
    _inFlightRecords.add(flightKey);
    try {
      if (auth.currentUserId != expectedUserId) return;
      await auth.recordTermsAccepted(version);
    } on Object {
      // Offline: the next launch tries again; the gate stays satisfied.
    } finally {
      _inFlightRecords.remove(flightKey);
    }
  }

  /// Accepts on this device and records it on the account (best effort: a
  /// failure keeps the local flag and the next launch asks the server again).
  Future<void> accept() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final requiredVersion = ref.read(termsVersionProvider);
    final userId = ref.read(currentUserIdProvider);
    AuthRepository? auth;
    try {
      auth = ref.read(authRepositoryProvider);
    } on Object {
      auth = null; // Not wired.
    }
    final uid = userId ?? auth?.currentUserId;
    state = true;
    await prefs.setBool(SafetyPrefs.eulaAccepted, true);
    if (uid != null) {
      await prefs.setInt(SafetyPrefs.termsVersionFor(uid), requiredVersion);
    }
    if (auth != null && uid != null && auth.currentUserId == uid) {
      unawaited(_record(auth, uid, requiredVersion));
    }
  }

  /// Account deletion / QA: ask again.
  Future<void> reset() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final userId = ref.read(currentUserIdProvider);
    state = false;
    await prefs.remove(SafetyPrefs.eulaAccepted);
    if (userId != null) {
      await prefs.remove(SafetyPrefs.termsVersionFor(userId));
    }
    for (final key in prefs.keys.toList()) {
      if (SafetyPrefs.userIdOfTermsKey(key) != null) {
        await prefs.remove(key);
      }
    }
  }
}

final eulaAcceptedProvider = NotifierProvider<EulaAccepted, bool>(
  EulaAccepted.new,
);

/// True when the signed-in account accepted an older terms version on the
/// server (`0 < acceptedTermsVersion < termsVersionProvider`) and has not yet
/// accepted the current version on this device (§4.5).
///
/// Accounts with `acceptedTermsVersion == 0` (brand-new accounts) record
/// initial consent via the `AuthScreen` inline clickwrap and never trigger
/// `TermsUpdateSheet`.
final needsTermsUpdateProvider = Provider<bool>((ref) {
  if (ref.watch(appConfigProvider).localOnly) return false;
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return false;
  if (ref.watch(eulaAcceptedProvider)) return false;
  final requiredVersion = ref.watch(termsVersionProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  final localVer = prefs.getInt(SafetyPrefs.termsVersionFor(userId)) ?? 0;
  final AuthRepository auth;
  try {
    auth = ref.watch(authRepositoryProvider);
  } on Object {
    return false;
  }
  Profile? profile;
  try {
    ref.watch(profileRepositoryProvider);
    profile = ref.watch(myProfileProvider).asData?.value;
  } on Object {
    // ProfileRepository not wired in this test.
  }
  final authVer = auth.acceptedTermsVersion ?? 0;
  final profileVer = profile?.termsVersion ?? 0;
  var knownVer = authVer > profileVer ? authVer : profileVer;
  if (localVer > knownVer) knownVer = localVer;
  return knownVer > 0 && knownVer < requiredVersion;
});

/// Ids the user has blocked (server truth, `SafetyRepository`).
final blockedUserIdsProvider = StreamProvider.autoDispose<Set<String>>(
  (ref) => ref.watch(safetyRepositoryProvider).watchBlockedIds(),
  retry: (_, _) => null,
);

/// Blocked people with their real names from `my_blocked_people` (U16),
/// keyed by user id. Empty when offline / not wired: callers fall back to the
/// names cached on this device and then to a short id.
final blockedPeopleProvider =
    FutureProvider.autoDispose<Map<String, PersonSummary>>((ref) async {
      // A new block / unblock changes the list.
      ref.watch(blockedUserIdsProvider);
      try {
        final people = await ref
            .watch(safetyRepositoryProvider)
            .myBlockedPeople();
        return {for (final p in people) p.userId: p};
      } on Object {
        return const {};
      }
    }, retry: (_, _) => null);

/// Check-ins reported from this device during this session. The server
/// already hides them from the reporter (FR-F2); lists that may still hold
/// a cached copy should filter with this set so the content disappears
/// immediately, even before the next sync.
class HiddenCheckIns extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void hide(String checkInId) => state = {...state, checkInId};
}

final hiddenCheckInIdsProvider = NotifierProvider<HiddenCheckIns, Set<String>>(
  HiddenCheckIns.new,
);

/// Names of blocked users remembered locally (see [SafetyPrefs.blockedNames]).
class BlockedNames extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() {
    final raw = ref
        .watch(sharedPreferencesProvider)
        .getString(SafetyPrefs.blockedNames);
    if (raw == null) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, Object?>) return const {};
      return {
        for (final e in decoded.entries)
          if (e.value case final String name) e.key: name,
      };
    } on Object {
      return const {};
    }
  }

  Future<void> remember(String userId, String name) async {
    if (name.isEmpty || state[userId] == name) return;
    state = {...state, userId: name};
    await _save();
  }

  Future<void> forget(String userId) async {
    if (!state.containsKey(userId)) return;
    state = {...state}..remove(userId);
    await _save();
  }

  Future<void> _save() => ref
      .read(sharedPreferencesProvider)
      .setString(SafetyPrefs.blockedNames, jsonEncode(state));
}

final blockedNamesProvider =
    NotifierProvider<BlockedNames, Map<String, String>>(BlockedNames.new);

/// Opens external URLs (mailto). Override in tests.
final safetyUrlLauncherProvider = Provider<Future<bool> Function(Uri)>(
  (ref) =>
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);

/// Which message to show for a failed report/block.
enum SafetyFailure { rateLimited, notFound, invalid, offline, generic }

SafetyFailure safetyFailureOf(Object error) {
  if (error is OurneyException) {
    return switch (error.error) {
      OurneyErrorCode.rateLimited => SafetyFailure.rateLimited,
      OurneyErrorCode.notFound => SafetyFailure.notFound,
      OurneyErrorCode.invalid => SafetyFailure.invalid,
      OurneyErrorCode.offline => SafetyFailure.offline,
      _ => SafetyFailure.generic,
    };
  }
  return SafetyFailure.generic;
}

/// Report + block operations used by every safety entry point.
class SafetyActions {
  SafetyActions(this._ref);

  final Ref _ref;

  SafetyRepository get _repo => _ref.read(safetyRepositoryProvider);

  /// FR-F1. Hides a reported check-in locally at once (FR-F2).
  Future<void> report({
    String? checkInId,
    String? userId,
    required ReportReason reason,
    String? note,
  }) async {
    assert(checkInId != null || userId != null, 'report needs a target');
    final trimmed = note?.trim();
    await _repo.report(
      checkInId: checkInId,
      userId: checkInId == null ? userId : null,
      reason: reason,
      note: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
    );
    if (checkInId != null) {
      _ref.read(hiddenCheckInIdsProvider.notifier).hide(checkInId);
    }
  }

  Future<void> block(String userId, {String? name}) async {
    await _repo.block(userId);
    if (name != null) {
      await _ref.read(blockedNamesProvider.notifier).remember(userId, name);
    }
  }

  Future<void> unblock(String userId) async {
    await _repo.unblock(userId);
    await _ref.read(blockedNamesProvider.notifier).forget(userId);
  }
}

final safetyActionsProvider = Provider<SafetyActions>(SafetyActions.new);
