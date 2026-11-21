import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/account_reset.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/features/journeys/data/create_progress.dart';
import 'package:ourney/features/onboarding/onboarding_providers.dart';
import 'package:ourney/features/profile/settings_providers.dart';
import 'package:ourney/features/reminders/data/notification_gateway.dart';
import 'package:ourney/features/reminders/data/reminder_scheduler.dart';
import 'package:ourney/features/reminders/data/reminder_settings.dart';
import 'package:ourney/features/safety/data/safety_providers.dart';
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
      SafetyPrefs.blockedNames: jsonEncode({'u9': 'Blocked'}),
      ActiveJourneyId.prefsKey: journeyId,
      CreateProgressPrefs.key: 3,
      ReminderPrefs.journey(journeyId): '{"on":true,"time":"20:00"}',
      // Device settings survive.
      ThemeModeController.prefsKey: 'dark',
      OnboardingComplete.prefsKey: true,
      ReminderPrefs.permissionAsked: true,
    });
    final gateway = FakeNotificationGateway(granted: true);
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
    container.read(hiddenCheckInIdsProvider.notifier).hide('c1');

    (container.read(currentUserIdProvider.notifier) as _SignedInUser).signOut();
    await pumpEventQueue();

    expect(container.read(onboardingQuizProvider), isNull);
    expect(container.read(eulaAcceptedProvider), isFalse);
    expect(container.read(blockedNamesProvider), isEmpty);
    expect(container.read(hiddenCheckInIdsProvider), isEmpty);
    expect(container.read(activeJourneyIdProvider), isNull);
    expect(container.read(createProgressProvider), isNull);
    expect(container.read(reminderSettingsProvider), isEmpty);
    expect(gateway.scheduled, isEmpty, reason: 'old reminders cancelled');

    expect(prefs.getString(ThemeModeController.prefsKey), 'dark');
    expect(prefs.getBool(OnboardingComplete.prefsKey), isTrue);
    expect(prefs.getBool(ReminderPrefs.permissionAsked), isTrue);
  });

  ProviderContainer containerFor(
    SharedPreferencesWithCache prefs,
    CurrentUserId Function() user,
  ) {
    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(testBackendConfig),
        sharedPreferencesProvider.overrideWithValue(prefs),
        supabaseClientProvider.overrideWithValue(null),
        currentUserIdProvider.overrideWith(user),
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
        SharePrivacyPrefs.hideWeight: true,
      });
      final container = containerFor(prefs, _SignedOutUser.new);
      await pumpEventQueue();
      expect(container.read(eulaAcceptedProvider), isFalse);
      expect(container.read(hideWeightOnShareProvider), isFalse);
      expect(prefs.containsKey(accountOwnerPrefsKey), isFalse);
    },
  );

  test('a different user signing in directly resets (C-B4)', () async {
    final prefs = await testPrefs({
      SafetyPrefs.eulaAccepted: true,
      SharePrivacyPrefs.blurPhotos: true,
    });
    final container = containerFor(prefs, _SignedInUser.new);
    await pumpEventQueue();
    expect(prefs.getString(accountOwnerPrefsKey), 'user-a');
    // Same user: nothing is dropped.
    expect(container.read(eulaAcceptedProvider), isTrue);

    (container.read(currentUserIdProvider.notifier) as _SignedInUser).switchTo(
      'user-b',
    );
    await pumpEventQueue();
    expect(container.read(eulaAcceptedProvider), isFalse);
    expect(container.read(blurPhotosOnShareProvider), isFalse);
    expect(prefs.getString(accountOwnerPrefsKey), 'user-b');
  });
}
