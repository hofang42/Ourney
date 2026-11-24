import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/import/data/import_providers.dart';
import '../features/journeys/data/create_progress.dart';
import '../features/onboarding/onboarding_providers.dart';
import '../features/profile/settings_providers.dart';
import '../features/reminders/data/reminder_scheduler.dart';
import '../features/reminders/data/reminder_settings.dart';
import '../features/safety/data/safety_providers.dart';
import 'providers.dart';

/// Shared-preferences keys that belong to the signed-in account rather than
/// to the device. Theme, locale, haptics, the onboarding intro and
/// the OS permission flags stay; everything here is dropped on sign-out and
/// account deletion so the next account starts clean (C-B4).
const List<String> accountPrefsKeys = [
  OnboardingQuizNotifier.prefsKey,
  SafetyPrefs.eulaAccepted,
  SafetyPrefs.blockedNames,
  ActiveJourneyId.prefsKey,
  CreateProgressPrefs.key,
  CreateProgressPrefs.draftKey,
  SharePrivacyPrefs.hideWeight,
  SharePrivacyPrefs.blurPhotos,
  SharePrivacyPrefs.pendingHeal,
];

/// The user id the per-account prefs above were written for.
const String accountOwnerPrefsKey = 'account.ownerUserId';

/// Forgets every per-account value kept outside the database (which
/// `AuthRepository.signOut` / `deleteAccount` wipe) and cancels the
/// reminders of the previous account. Never throws.
Future<void> resetAccountLocalState(Ref ref) async {
  final prefs = ref.read(sharedPreferencesProvider);
  final nextUserId = ref.read(currentUserIdProvider);
  final keys = {
    ...accountPrefsKeys,
    // Per-journey reminder times of the previous account's journeys, and
    // per-account EULA version records of previous accounts.
    for (final key in prefs.keys)
      if (ReminderPrefs.journeyIdOf(key) != null ||
          (SafetyPrefs.userIdOfTermsKey(key) != null &&
              SafetyPrefs.userIdOfTermsKey(key) != nextUserId))
        key,
  };
  try {
    for (final key in keys) {
      if (prefs.containsKey(key)) await prefs.remove(key);
    }
  } on Object {
    // Storage failure: the in-memory reset below still applies.
  }
  // Their values are read from the preferences in build().
  ref
    ..invalidate(onboardingQuizProvider)
    ..invalidate(eulaAcceptedProvider)
    ..invalidate(blockedNamesProvider)
    ..invalidate(hiddenCheckInIdsProvider)
    ..invalidate(activeJourneyIdProvider)
    ..invalidate(createProgressProvider)
    ..invalidate(hideWeightOnShareProvider)
    ..invalidate(blurPhotosOnShareProvider)
    ..invalidate(reminderSettingsProvider);
  // Import job folders nobody owns any more (the rows go with the database
  // wipe on sign-out). A job whose rows survive, such as an expired session's,
  // keeps its files; a running job stops on its own when the account changes.
  try {
    await ref.read(importJobRunnerProvider).sweepOrphans();
  } on Object {
    // Not wired (no data layer): nothing to clean.
  }
  // Signed out: the plan is empty, so every pending reminder is cancelled.
  await ref.read(reminderSchedulerProvider).reschedule();
}

/// Watch once at the app root: resets the per-account local state whenever
/// the account changes: sign-out from any screen, account deletion, a
/// session revoked elsewhere or expired while the app was closed, and a
/// different user signing in (the owner id is kept in the preferences).
final accountSessionResetProvider = Provider<void>((ref) {
  void apply(String? next) {
    final prefs = ref.read(sharedPreferencesProvider);
    final owner = prefs.getString(accountOwnerPrefsKey);
    final changed = next == null
        ? owner != null
        : owner != null && owner != next;
    if (next == null) {
      unawaited(prefs.remove(accountOwnerPrefsKey));
    } else if (owner != next) {
      unawaited(prefs.setString(accountOwnerPrefsKey, next));
    }
    // Never reset synchronously: this may run while the provider builds.
    if (changed) unawaited(Future(() => resetAccountLocalState(ref)));
  }

  apply(ref.read(currentUserIdProvider));
  ref.listen<String?>(currentUserIdProvider, (previous, next) {
    if (next != previous) apply(next);
  });
});
