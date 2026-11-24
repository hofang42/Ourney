import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/journey_clock.dart';
import 'package:ourney/app/overlays/reminder_banner.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/app/router.dart';
import 'package:ourney/features/reminders/data/notification_gateway.dart';
import 'package:ourney/features/reminders/data/reminder_scheduler.dart';
import 'package:ourney_core/ourney_core.dart';

import '../features/reminders/reminders_fakes.dart';
import 'test_helpers.dart';

void main() {
  testWidgets(
    'app start initialises reminders, opens camera for tapped journey, and falls back if deleted (DE-16)',
    (tester) async {
      final gateway = FakeNotificationGateway(granted: true)..launch = 'j1';
      final c = await pumpOurneyApp(
        tester,
        overrides: [
          notificationGatewayProvider.overrideWithValue(gateway),
          journeysClockProvider.overrideWithValue(
            Clock.fixed(DateTime.utc(2026, 10, 16, 5)),
          ),
          journeyRepositoryProvider.overrideWithValue(
            FakeReminderJourneyRepository([reminderJourney()]),
          ),
          checkInRepositoryProvider.overrideWithValue(
            FakeReminderCheckInRepository(),
          ),
          reminderDeviceTimezoneProvider.overrideWith((ref) async => hcm),
          remindersClockProvider.overrideWithValue(Clock.fixed(reminderNow)),
        ],
      );
      await tester.pumpAndSettle();
      Uri currentUri() =>
          c.read(routerProvider).routerDelegate.currentConfiguration.uri;

      expect(gateway.initializeCalls, greaterThan(0));
      // Launched from a notification for active journey j1: camera opens for j1.
      expect(currentUri().path, AppRoutes.capture);
      expect(currentUri().queryParameters['journeyId'], 'j1');

      // Tapping a notification for a deleted journey ('j2') falls back to /capture.
      c.read(routerProvider).go(AppRoutes.journeys);
      await tester.pumpAndSettle();
      gateway.onTap!('j2');
      await tester.pumpAndSettle();
      expect(currentUri().path, AppRoutes.capture);
      expect(currentUri().queryParameters['journeyId'], isNull);
    },
  );

  testWidgets('foreground reminder timer triggers ReminderBannerHost (DE-16)', (
    tester,
  ) async {
    final gateway = FakeNotificationGateway(granted: true);
    final checkIns = FakeReminderCheckInRepository()
      ..byJourney['j1'] = [reminderCheckIn('j1', const LocalDate(2026, 10, 15))];
    await pumpOurneyApp(
      tester,
      overrides: [
        notificationGatewayProvider.overrideWithValue(gateway),
        journeysClockProvider.overrideWithValue(
          Clock.fixed(DateTime.utc(2026, 10, 16, 5)),
        ),
        journeyRepositoryProvider.overrideWithValue(
          FakeReminderJourneyRepository([reminderJourney()]),
        ),
        checkInRepositoryProvider.overrideWithValue(checkIns),
        reminderDeviceTimezoneProvider.overrideWith((ref) async => hcm),
        remindersClockProvider.overrideWithValue(Clock.fixed(reminderNow)),
      ],
    );
    await tester.pumpAndSettle();
    expect(find.byType(ReminderBanner), findsNothing);

    // Streak alert is planned at 21:00 local (11h after reminderNow 10:00 local).
    await tester.pump(const Duration(hours: 11));
    await tester.pumpAndSettle();
    expect(find.byType(ReminderBanner), findsOneWidget);
    expect(find.byKey(const ValueKey('reminder-banner-j1')), findsOneWidget);
  });

  testWidgets('the in-app reminder banner opens the camera of its journey '
      '(bug.md 1.4, app.dart:58)', (tester) async {
    final gateway = FakeNotificationGateway(granted: true);
    final c = await pumpOurneyApp(
      tester,
      overrides: [
        notificationGatewayProvider.overrideWithValue(gateway),
        journeysClockProvider.overrideWithValue(
          Clock.fixed(DateTime.utc(2026, 10, 16, 5)),
        ),
        journeyRepositoryProvider.overrideWithValue(
          FakeReminderJourneyRepository([reminderJourney()]),
        ),
        checkInRepositoryProvider.overrideWithValue(
          FakeReminderCheckInRepository(),
        ),
        reminderDeviceTimezoneProvider.overrideWith((ref) async => hcm),
        remindersClockProvider.overrideWithValue(Clock.fixed(reminderNow)),
      ],
    );
    await tester.pumpAndSettle();
    c.read(routerProvider).go(AppRoutes.journeys);
    await tester.pumpAndSettle();
    c
        .read(reminderBannerProvider.notifier)
        .show(
          const ReminderBannerData(
            journeyId: 'j1',
            journeyName: 'A',
            skinId: 'quiet',
            kind: ReminderBannerKind.daily,
          ),
        );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reminder-banner-open')));
    await tester.pumpAndSettle();
    final uri = c.read(routerProvider).routerDelegate.currentConfiguration.uri;
    expect(uri.path, AppRoutes.capture);
    expect(uri.queryParameters['journeyId'], 'j1');
  });
}
