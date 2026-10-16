import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/app/router.dart';
import 'package:ourney/features/reminders/data/notification_gateway.dart';
import 'package:ourney/features/reminders/data/reminder_scheduler.dart';

import '../features/reminders/reminders_fakes.dart';
import 'test_helpers.dart';

void main() {
  testWidgets('app start initialises reminders and opens a tapped journey', (
    tester,
  ) async {
    final gateway = FakeNotificationGateway(granted: true)..launch = 'j1';
    final c = await pumpOurneyApp(
      tester,
      overrides: [
        notificationGatewayProvider.overrideWithValue(gateway),
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
    String path() =>
        c.read(routerProvider).routerDelegate.currentConfiguration.uri.path;

    expect(gateway.initializeCalls, greaterThan(0));
    // Launched from a notification: the journey opens.
    expect(path(), AppRoutes.journey('j1'));

    // A tap while the app runs also navigates.
    gateway.onTap!('j2');
    await tester.pumpAndSettle();
    expect(path(), AppRoutes.journey('j2'));
  });
}
