import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/journeys/data/create_progress.dart';
import '../features/onboarding/onboarding_providers.dart';
import '../features/reminders/data/reminder_scheduler.dart';
import '../features/reminders/data/reminder_settings.dart';
import '../features/safety/data/safety_providers.dart';
import 'providers.dart';

/// Shared-preferences keys that belong to the signed-in account rather than
/// to the device. Theme, locale, haptics, app icon, the onboarding intro and
/// the OS permission flags stay; everything here is dropped on sign-out and
/// account deletion so the next account starts clean (C-B4).
const List<String> accountPrefsKeys = [
  OnboardingQuizNotifier.prefsKey,
  SafetyPrefs.eulaAccepted,
  SafetyPrefs.blockedNames,
  ActiveJourneyId.prefsKey,
  CreateProgressPrefs.key,
];

/// Forgets every per-account value kept outside the database (which
/// `AuthRepository.signOut` / `deleteAccount` wipe) and cancels the
/// reminders of the previous account. Never throws.
Future<void> resetAccountLocalState(Ref ref) async {
  final prefs = ref.read(sharedPreferencesProvider);
  final keys = {
    ...accountPrefsKeys,
    // Per-journey reminder times of the previous account's journeys.
    for (final key in prefs.keys)
      if (ReminderPrefs.journeyIdOf(key) != null) key,
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
    ..invalidate(reminderSettingsProvider);
  // Signed out: the plan is empty, so every pending reminder is cancelled.
  await ref.read(reminderSchedulerProvider).reschedule();
}

/// Watch once at the app root: resets the per-account local state whenever
/// the session ends (sign-out from any screen, account deletion, a session
/// revoked elsewhere).
final accountSessionResetProvider = Provider<void>((ref) {
  ref.listen<String?>(currentUserIdProvider, (previous, next) {
    if (previous != null && next == null) {
      unawaited(resetAccountLocalState(ref));
    }
  });
});
