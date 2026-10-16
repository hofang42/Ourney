import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/providers.dart';

/// Support address shown on the contact page. Comes from
/// `--dart-define=SUPPORT_EMAIL` (see `AppConfig`) and defaults to the
/// placeholder `support@ourney.app` until the owner confirms the real mailbox
/// (docs/adr/0002-support-email-and-legal-text.md).
final supportEmailProvider = Provider<String>(
  (ref) => ref.watch(appConfigProvider).supportEmail,
);

/// Date shown as "last updated" on the EULA and privacy pages. Bump when
/// the texts in l10n/safety_*.arb change.
final DateTime kLegalLastUpdated = DateTime(2026, 10, 16);

/// Shared-preferences keys of the safety feature.
abstract final class SafetyPrefs {
  /// `true` once the user accepted the EULA on this device (FR-F3).
  static const eulaAccepted = 'safety.eulaAccepted';

  /// JSON `{userId: displayName}` of people blocked from this device, so
  /// the blocked list can show names (the contract only streams ids).
  static const blockedNames = 'safety.blockedNames';
}

/// Whether the EULA was accepted (FR-F3, Apple Guideline 1.2). Gate any
/// user-generated content on it; see lib/features/safety/README.md.
class EulaAccepted extends Notifier<bool> {
  @override
  bool build() =>
      ref.watch(sharedPreferencesProvider).getBool(SafetyPrefs.eulaAccepted) ??
      false;

  Future<void> accept() async {
    state = true;
    await ref
        .read(sharedPreferencesProvider)
        .setBool(SafetyPrefs.eulaAccepted, true);
  }

  /// Account deletion / QA: ask again.
  Future<void> reset() async {
    state = false;
    await ref.read(sharedPreferencesProvider).remove(SafetyPrefs.eulaAccepted);
  }
}

final eulaAcceptedProvider = NotifierProvider<EulaAccepted, bool>(
  EulaAccepted.new,
);

/// Ids the user has blocked (server truth, `SafetyRepository`).
final blockedUserIdsProvider = StreamProvider.autoDispose<Set<String>>(
  (ref) => ref.watch(safetyRepositoryProvider).watchBlockedIds(),
  retry: (_, _) => null,
);

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
