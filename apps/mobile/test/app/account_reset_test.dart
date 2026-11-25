import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/account_reset.dart';
import 'package:ourney/app/overlays/reminder_banner.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/features/auth/auth_providers.dart';
import 'package:ourney/features/feedback/data/feedback_providers.dart';
import 'package:ourney/features/journeys/data/create_progress.dart';
import 'package:ourney/features/journeys/data/journeys_providers.dart'
    show journeyGhostGuidePrefKey, journeyStartingWeightPrefKey;
import 'package:ourney/features/onboarding/onboarding_providers.dart';
import 'package:ourney/features/profile/settings_providers.dart';
import 'package:ourney/features/reminders/data/notification_gateway.dart';
import 'package:ourney/features/reminders/data/reminder_scheduler.dart';
import 'package:ourney/features/reminders/data/reminder_settings.dart';
import 'package:ourney/features/safety/data/safety_providers.dart';
import 'package:ourney/features/update/data/update_prefs.dart';
import 'package:ourney_core/ourney_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/reminders/reminders_fakes.dart';
import 'test_helpers.dart';

class _SignedInUser extends CurrentUserId {
  @override
  String? build() => 'user-a';

  void signOut() => state = null;

  void switchTo(String id) => state = id;
}

class _SignedOutUser extends CurrentUserId {
  @override
  String? build() => null;
}

/// C-B4 and the section 1.4 item "sign-out / delete account keep reminders
/// and the EULA": ending the session drops every per-account local value.
void main() {
  const journeyId = 'aaaaaaaa-0000-4000-8000-000000000001';

  test('ending the session resets per-account state and reminders', () async {
    final prefs = await testPrefs({
      OnboardingQuizNotifier.prefsKey: jsonEncode(
        const OnboardingQuiz(goal: QuizGoal.weightLoss).toJson(),
      ),
      SafetyPrefs.eulaAccepted: true,
      SafetyPrefs.termsVersionFor('user-a'): kTermsVersion,
      SafetyPrefs.blockedNames: jsonEncode({'u9': 'Blocked'}),
      FeedbackPrefs.draftFor('user-a'): jsonEncode(
        const FeedbackComposeDraft(
          title: 'Secret draft idea',
          body: 'Private unsent notes for user-a',
        ).toJson(),
      ),
      FeedbackPrefs.cacheFor('user-a', mineOnly: false): '[{"id":"req-1"}]',
      FeedbackPrefs.cacheFor('user-a', mineOnly: true): '[{"id":"req-2"}]',
      AuthMethodPrefs.hasPasswordKeyFor('user-a'): true,
      ActiveJourneyId.prefsKey: journeyId,
      CreateProgressPrefs.key: 3,
      ReminderPrefs.journey(journeyId): '{"on":true,"time":"20:00"}',
      journeyStartingWeightPrefKey(journeyId): 68.4,
      journeyGhostGuidePrefKey(journeyId): true,
      ReminderPrefs.streakAlerts: false,
      ReminderPrefs.promptOffered: true,
      // Device settings survive.
      AuthMethodPrefs.lastMethodKey: 'password',
      ThemeModeController.prefsKey: 'dark',
      OnboardingComplete.prefsKey: true,
      ReminderPrefs.permissionAsked: true,
    });
    final gateway = FakeNotificationGateway(granted: true);
    final updates = UpdatePrefs(prefs);
    final version = SemVer.tryParse('1.1.0')!;
    final installed = SemVer.tryParse('1.0.0')!;
    await updates.saveSnooze(
      UpdateSnooze(version: version, count: 1, until: reminderNow),
    );
    await updates.skipVersion(version);
    await updates.recordInstalledVersion(installed);
    gateway.scheduled[kReminderIdBase] = NotificationRequest(
      id: kReminderIdBase,
      fireAt: reminderNow.add(const Duration(hours: 10)),
      title: 'A',
      body: 'A',
      payload: journeyId,
    );
    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(testBackendConfig),
        sharedPreferencesProvider.overrideWithValue(prefs),
        supabaseClientProvider.overrideWithValue(null),
        currentUserIdProvider.overrideWith(_SignedInUser.new),
        notificationGatewayProvider.overrideWithValue(gateway),
        journeyRepositoryProvider.overrideWithValue(
          FakeReminderJourneyRepository([reminderJourney(id: journeyId)]),
        ),
        checkInRepositoryProvider.overrideWithValue(
          FakeReminderCheckInRepository(),
        ),
        reminderDeviceTimezoneProvider.overrideWith((ref) async => hcm),
        remindersClockProvider.overrideWithValue(Clock.fixed(reminderNow)),
      ],
    );
    addTearDown(container.dispose);
    container.listen(accountSessionResetProvider, (_, _) {});

    expect(container.read(onboardingQuizProvider), isNotNull);
    expect(container.read(eulaAcceptedProvider), isTrue);
    expect(container.read(blockedNamesProvider), isNotEmpty);
    expect(container.read(feedbackDraftProvider)?.title, 'Secret draft idea');
    expect(container.read(streakAlertsEnabledProvider), isFalse);
    container.read(hiddenCheckInIdsProvider.notifier).hide('c1');
    container.read(hiddenFeatureRequestIdsProvider.notifier).hide('req-1');
    container
        .read(feedbackVoteOverlayProvider.notifier)
        .seed('req-1', votedByMe: true, voteCount: 43);
    container
        .read(reminderBannerProvider.notifier)
        .show(
          const ReminderBannerData(
            journeyId: journeyId,
            journeyName: 'A',
            skinId: 'quiet',
            kind: ReminderBannerKind.daily,
          ),
        );

    (container.read(currentUserIdProvider.notifier) as _SignedInUser).signOut();
    await pumpEventQueue();

    expect(container.read(onboardingQuizProvider), isNull);
    expect(container.read(eulaAcceptedProvider), isFalse);
    expect(container.read(blockedNamesProvider), isEmpty);
    expect(container.read(hiddenCheckInIdsProvider), isEmpty);
    expect(container.read(hiddenFeatureRequestIdsProvider), isEmpty);
    expect(container.read(feedbackDraftProvider), isNull);
    expect(container.read(feedbackVoteOverlayProvider), isEmpty);
    expect(
      prefs.containsKey(FeedbackPrefs.draftFor('user-a')),
      isFalse,
    );
    expect(
      prefs.containsKey(FeedbackPrefs.cacheFor('user-a', mineOnly: false)),
      isFalse,
    );
    expect(
      prefs.containsKey(FeedbackPrefs.cacheFor('user-a', mineOnly: true)),
      isFalse,
    );
    expect(
      prefs.containsKey(AuthMethodPrefs.hasPasswordKeyFor('user-a')),
      isFalse,
    );
    expect(container.read(hasPasswordProvider), isFalse);
    expect(
      prefs.getString(AuthMethodPrefs.lastMethodKey),
      'password',
      reason: 'device-scoped remembered sign-in method survives sign-out',
    );
    expect(container.read(activeJourneyIdProvider), isNull);
    expect(container.read(createProgressProvider), isNull);
    expect(container.read(reminderSettingsProvider), isEmpty);
    expect(container.read(streakAlertsEnabledProvider), isTrue);
    expect(container.read(reminderBannerProvider), isNull);
    expect(prefs.containsKey(ReminderPrefs.promptOffered), isFalse);
    expect(
      prefs.containsKey(journeyStartingWeightPrefKey(journeyId)),
      isFalse,
    );
    expect(
      prefs.containsKey(journeyGhostGuidePrefKey(journeyId)),
      isFalse,
    );
    expect(gateway.scheduled, isEmpty, reason: 'old reminders cancelled');

    expect(prefs.getString(ThemeModeController.prefsKey), 'dark');
    expect(prefs.getBool(OnboardingComplete.prefsKey), isTrue);
    expect(prefs.getBool(ReminderPrefs.permissionAsked), isTrue);
    expect(updates.snooze?.version, version);
    expect(updates.snooze?.count, 1);
    expect(updates.skippedVersion, version);
    expect(updates.lastSeenInstalledVersion, installed);
  });

  ProviderContainer containerFor(
    SharedPreferencesWithCache prefs,
    CurrentUserId Function() user, {
    FakeAuthRepository? auth,
  }) {
    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(testBackendConfig),
        sharedPreferencesProvider.overrideWithValue(prefs),
        supabaseClientProvider.overrideWithValue(null),
        currentUserIdProvider.overrideWith(user),
        if (auth != null) authRepositoryProvider.overrideWithValue(auth),
        notificationGatewayProvider.overrideWithValue(
          FakeNotificationGateway(granted: true),
        ),
        journeyRepositoryProvider.overrideWithValue(
          FakeReminderJourneyRepository([reminderJourney(id: journeyId)]),
        ),
        checkInRepositoryProvider.overrideWithValue(
          FakeReminderCheckInRepository(),
        ),
        reminderDeviceTimezoneProvider.overrideWith((ref) async => hcm),
        remindersClockProvider.overrideWithValue(Clock.fixed(reminderNow)),
      ],
    );
    addTearDown(container.dispose);
    container.listen(accountSessionResetProvider, (_, _) {});
    return container;
  }

  test(
    'a session that expired while the app was closed resets (C-B4)',
    () async {
      final prefs = await testPrefs({
        accountOwnerPrefsKey: 'user-a',
        SafetyPrefs.eulaAccepted: true,
        SafetyPrefs.termsVersionFor('user-a'): kTermsVersion,
        FeedbackPrefs.draftFor('user-a'): '{"title":"Expired draft","body":"x"}',
        FeedbackPrefs.cacheFor('user-a', mineOnly: false): '[{"id":"req-1"}]',
        FeedbackPrefs.cacheFor('user-a', mineOnly: true): '[{"id":"req-2"}]',
        SharePrivacyPrefs.hideWeight: true,
      });
      final container = containerFor(prefs, _SignedOutUser.new);
      await pumpEventQueue();
      expect(container.read(eulaAcceptedProvider), isFalse);
      expect(container.read(hideWeightOnShareProvider), isFalse);
      expect(prefs.containsKey(accountOwnerPrefsKey), isFalse);
      expect(
        prefs.containsKey(SafetyPrefs.termsVersionFor('user-a')),
        isFalse,
      );
      expect(
        prefs.containsKey(FeedbackPrefs.draftFor('user-a')),
        isFalse,
      );
      expect(
        prefs.containsKey(FeedbackPrefs.cacheFor('user-a', mineOnly: false)),
        isFalse,
      );
      expect(
        prefs.containsKey(FeedbackPrefs.cacheFor('user-a', mineOnly: true)),
        isFalse,
      );
    },
  );

  test(
    'a different user signing in directly resets without leaking EULA consent '
    '(C-B4 / H1)',
    () async {
      final prefs = await testPrefs({
        SafetyPrefs.eulaAccepted: true,
        SafetyPrefs.termsVersionFor('user-a'): kTermsVersion,
        FeedbackPrefs.draftFor('user-a'): '{"title":"User A draft","body":"y"}',
        FeedbackPrefs.cacheFor('user-a', mineOnly: false): '[{"id":"req-1"}]',
        FeedbackPrefs.cacheFor('user-a', mineOnly: true): '[{"id":"req-2"}]',
        SharePrivacyPrefs.blurPhotos: true,
      });
      final auth = FakeAuthRepository(
        userId: 'user-a',
        termsVersion: kTermsVersion,
      );
      final container = containerFor(prefs, _SignedInUser.new, auth: auth);
      await pumpEventQueue();
      expect(prefs.getString(accountOwnerPrefsKey), 'user-a');
      // Same user: nothing is dropped.
      expect(container.read(eulaAcceptedProvider), isTrue);
      expect(auth.recordedTerms, isEmpty);

      // Direct switch to user-b (new account, termsVersion == null).
      auth
        ..userId = 'user-b'
        ..termsVersion = null;
      (container.read(currentUserIdProvider.notifier) as _SignedInUser)
          .switchTo('user-b');
      // Providers are invalidated synchronously on user switch (no Timer.run gap, FS-26),
      // while accountOwnerPrefsKey is only updated after per-account key removals flush,
      // and user-b must not inherit user-a's consent or trigger recordTermsAccepted.
      expect(container.read(eulaAcceptedProvider), isFalse);
      expect(container.read(blurPhotosOnShareProvider), isFalse);
      expect(prefs.containsKey(SafetyPrefs.eulaAccepted), isFalse);
      expect(prefs.containsKey(SharePrivacyPrefs.blurPhotos), isFalse);
      expect(auth.recordedTerms, isEmpty);

      await pumpEventQueue();
      expect(container.read(eulaAcceptedProvider), isFalse);
      expect(auth.recordedTerms, isEmpty);
      expect(
        prefs.containsKey(SafetyPrefs.termsVersionFor('user-a')),
        isFalse,
      );
      expect(
        prefs.containsKey(FeedbackPrefs.draftFor('user-a')),
        isFalse,
      );
      expect(
        prefs.containsKey(FeedbackPrefs.cacheFor('user-a', mineOnly: false)),
        isFalse,
      );
      expect(
        prefs.containsKey(FeedbackPrefs.cacheFor('user-a', mineOnly: true)),
        isFalse,
      );
      expect(container.read(blurPhotosOnShareProvider), isFalse);
      expect(prefs.getString(accountOwnerPrefsKey), 'user-b');
    },
  );
}
