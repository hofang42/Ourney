import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/app.dart';
import 'package:ourney/app/config.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/app/router.dart';
import 'package:ourney/data/group_daily_checkins_provider.dart';
import 'package:ourney/features/journeys/data/journeys_providers.dart';
import 'package:ourney/features/journeys/ui/home/journey_home_header.dart';
import 'package:ourney/features/journeys/ui/home/journey_home_intro.dart';
import 'package:ourney/features/journeys/ui/widgets/photo_log_timelines.dart';
import 'package:ourney/features/safety/data/safety_providers.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/test_helpers.dart';
import 'journeys_fakes.dart';

const _timeout = Timeout(Duration(seconds: 15));

Future<void> _pumpDetail(WidgetTester tester, Journey journey) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(420, 1000);
  tester.platformDispatcher.localesTestValue = [const Locale('en')];
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);

  final checkIn = testCheckIn(
    journey.id,
    testToday,
    extras: const CheckInExtras(km: 4.2),
  );
  final prefs = await testPrefs({
    OnboardingComplete.prefsKey: true,
    SafetyPrefs.eulaAccepted: true,
  });
  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(const AppConfig.localOnly()),
      sharedPreferencesProvider.overrideWithValue(prefs),
      supabaseClientProvider.overrideWithValue(null),
      journeyRepositoryProvider.overrideWithValue(
        FakeJourneyRepository(
          journeys: [journey],
          memberships: {journey.id: testMembership(journey)},
        ),
      ),
      checkInRepositoryProvider.overrideWithValue(
        FakeCheckInRepository([checkIn]),
      ),
      mediaStoreProvider.overrideWithValue(FakeMediaStore()),
      journeysClockProvider.overrideWithValue(Clock.fixed(testNow)),
      deviceTimezoneProvider.overrideWith((ref) => testTz),
      journeyHomeOfflineProvider.overrideWith((ref) => Stream.value(false)),
      groupMembersTodaySafeProvider(journey.id).overrideWith(
        (ref) => Stream.value([
          MemberToday(
            userId: 'u1',
            displayName: 'Member 1',
            role: MemberRole.owner,
            todayCheckIn: checkIn,
          ),
          for (var i = 2; i <= 5; i++)
            MemberToday(
              userId: 'u$i',
              displayName: 'Member $i',
              role: MemberRole.member,
              checkedInHidden: i <= 3,
            ),
        ]),
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const OurneyApp()),
  );
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  container.read(routerProvider).go(AppRoutes.journey(journey.id));
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  for (final (sport, verb) in [('run', 'RAN'), ('gym', 'TRAINED')]) {
    testWidgets('group $sport shows one attendance pill above its stats', (
      tester,
    ) async {
      await _pumpDetail(
        tester,
        testJourney(
          kind: JourneyKind.group,
          maxMembers: 5,
        ).copyWith(dna: {'sport': sport}),
      );
      final pill = find.byKey(const ValueKey('journey-workout-members'));
      final stats = find.byType(RunStatStrip);
      expect(find.byType(JourneyWorkoutMembers), findsOneWidget);
      expect(pill, findsOneWidget);
      expect(find.text('3/5 $verb'), findsOneWidget);
      expect(stats, findsOneWidget);
      expect(
        tester.getRect(pill).bottom,
        lessThanOrEqualTo(tester.getRect(stats).top),
      );
    }, timeout: _timeout);

    testWidgets('solo $sport has no group attendance pill', (tester) async {
      await _pumpDetail(tester, testJourney().copyWith(dna: {'sport': sport}));
      expect(find.byType(RunStatStrip), findsOneWidget);
      expect(find.byType(JourneyWorkoutMembers), findsNothing);
      expect(find.text('3/5 $verb'), findsNothing);
    }, timeout: _timeout);
  }
}
