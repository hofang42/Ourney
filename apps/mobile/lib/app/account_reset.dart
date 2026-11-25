import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/auth_providers.dart';
import '../features/feedback/data/feedback_providers.dart';
import '../features/groups/data/groups_providers.dart'
    show groupJourneysProvider;
import '../features/import/data/import_providers.dart';
import '../features/journeys/data/create_progress.dart';
import '../features/journeys/data/journeys_providers.dart'
    show
        archivedJourneysProvider,
        isPerJourneyAccountPrefKey,
        journeysListProvider,
        pinnedJourneyIdsProvider;
import '../features/onboarding/onboarding_providers.dart';
import '../features/profile/settings_providers.dart';
import '../features/reminders/data/reminder_scheduler.dart';
import '../features/reminders/data/reminder_settings.dart';
import '../features/safety/data/safety_providers.dart';
import '../features/widgets/data/widget_sync_controller.dart';
import 'overlays/reminder_banner.dart';
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
  ReminderPrefs.streakAlerts,
  ReminderPrefs.promptOffered,
  ...WidgetPrefs.accountKeys,
];

/// The user id the per-account prefs above were written for.
const String accountOwnerPrefsKey = 'account.ownerUserId';

/// Forgets every per-account value kept outside the database (which
/// `AuthRepository.signOut` / `deleteAccount` wipe) and cancels the
/// reminders of the previous account. Never throws.
Future<void> resetAccountLocalState(
  Ref ref, {
  String? nextOwner,
  bool updateOwner = false,
}) async {
  final prefs = ref.read(sharedPreferencesProvider);
  final nextUserId = ref.read(currentUserIdProvider);
  final keys = {
    ...accountPrefsKeys,
    // Per-journey reminder times of the previous account's journeys,
    // per-account EULA version records, and per-account feedback drafts
    // and cached boards of previous accounts.
    for (final key in prefs.keys)
      if (ReminderPrefs.journeyIdOf(key) != null ||
          isPerJourneyAccountPrefKey(key) ||
          (SafetyPrefs.userIdOfTermsKey(key) != null &&
              SafetyPrefs.userIdOfTermsKey(key) != nextUserId) ||
          (FeedbackPrefs.userIdOfKey(key) != null &&
              FeedbackPrefs.userIdOfKey(key) != nextUserId) ||
          (AuthMethodPrefs.userIdOfHasPasswordKey(key) != null &&
              AuthMethodPrefs.userIdOfHasPasswordKey(key) != nextUserId))
        key,
  };
  final removals = <Future<void>>[];
  try {
    for (final key in keys) {
      // SharedPreferencesWithCache.remove updates the in-memory cache
      // synchronously before returning its platform write Future.
      if (prefs.containsKey(key)) removals.add(prefs.remove(key));
    }
  } on Object {
    // Storage failure: the in-memory reset below still applies.
  }
  // Invalidate synchronously before awaiting platform disk flushes so no
  // microtask after sign-in reads the previous account's cached provider state.
  ref
    ..invalidate(onboardingQuizProvider)
    ..invalidate(eulaAcceptedProvider)
    ..invalidate(blockedNamesProvider)
    ..invalidate(hiddenCheckInIdsProvider)
    ..invalidate(hiddenFeatureRequestIdsProvider)
    ..invalidate(feedbackDraftProvider)
    ..invalidate(feedbackVoteOverlayProvider)
    ..invalidate(activeJourneyIdProvider)
    ..invalidate(activeJourneyProvider)
    ..invalidate(journeysListProvider)
    ..invalidate(archivedJourneysProvider)
    ..invalidate(pinnedJourneyIdsProvider)
    ..invalidate(groupJourneysProvider)
    ..invalidate(createProgressProvider)
    ..invalidate(hideWeightOnShareProvider)
    ..invalidate(blurPhotosOnShareProvider)
    ..invalidate(hasPasswordProvider)
    ..invalidate(reminderSettingsProvider)
    ..invalidate(streakAlertsEnabledProvider)
    ..invalidate(reminderBannerProvider)
    ..invalidate(widgetPhotoModeProvider)
    ..invalidate(redactLockScreenTitlesPrefProvider)
    ..invalidate(redactLockScreenTitlesProvider)
    ..invalidate(liveActivityEnabledProvider)
    ..invalidate(defaultWidgetJourneyIdProvider)
    ..invalidate(dismissedLiveWindowKeyProvider);
  try {
    await Future.wait(removals);
    if (updateOwner) {
      if (nextOwner == null) {
        await prefs.remove(accountOwnerPrefsKey);
      } else {
        await prefs.setString(accountOwnerPrefsKey, nextOwner);
      }
    }
  } on Object {
    // Storage failure: in-memory cache and providers are already reset.
  }
  // Import job folders nobody owns any more (the rows go with the database
  // wipe on sign-out). A job whose rows survive, such as an expired session's,
  // keeps its files; a running job stops on its own when the account changes.
  try {
    await ref.read(importJobRunnerProvider).sweepOrphans();
  } on Object {
    // Not wired (no data layer): nothing to clean.
  }
  // Signed out: the plan is empty, so every pending reminder is cancelled,
  // and all home-screen / lock-screen widget snapshots and Live Activities
  // are wiped from disk.
  await ref.read(reminderSchedulerProvider).reschedule();
  await ref.read(widgetSyncControllerProvider).clearAll();
}

/// Watch once at the app root: resets the per-account local state whenever
/// the account changes: sign-out from any screen, account deletion, a
/// session revoked elsewhere or expired while the app was closed, and a
/// different user signing in (the owner id is kept in the preferences).
final accountSessionResetProvider = Provider<void>((ref) {
  void apply(String? next, {required bool inBuild}) {
    final prefs = ref.read(sharedPreferencesProvider);
    final owner = prefs.getString(accountOwnerPrefsKey);
    final changed = next == null
        ? owner != null
        : owner != null && owner != next;
    if (!changed) {
      if (next != null && owner != next) {
        unawaited(prefs.setString(accountOwnerPrefsKey, next));
      }
      return;
    }
    if (inBuild) {
      // During initial provider build, defer to the next microtask.
      unawaited(
        Future.microtask(
          () => resetAccountLocalState(
            ref,
            nextOwner: next,
            updateOwner: true,
          ),
        ),
      );
    } else {
      // On live user change, invalidate per-account providers synchronously.
      unawaited(
        resetAccountLocalState(
          ref,
          nextOwner: next,
          updateOwner: true,
        ),
      );
    }
  }

  apply(ref.read(currentUserIdProvider), inBuild: true);
  ref.listen<String?>(currentUserIdProvider, (previous, next) {
    if (next != previous) apply(next, inBuild: false);
  });
});
