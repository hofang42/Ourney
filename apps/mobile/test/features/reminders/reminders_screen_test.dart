import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/features/reminders/data/reminder_scheduler.dart';
import 'package:ourney/features/reminders/data/reminder_settings.dart';

import 'reminders_fakes.dart';

Finder byKey(String key) => find.byKey(ValueKey(key));

void main() {
  testWidgets('first reminder: rationale, OS prompt, saved and scheduled', (
    tester,
  ) async {
    final h = await reminderHarness();
    addTearDown(h.container.dispose);
    await tester.pumpWidget(remindersApp(h));
    await tester.pumpAndSettle();

    expect(find.text('Tập mỗi ngày'), findsOneWidget);
    expect(find.text('Đang tắt'), findsOneWidget);
    expect(h.gateway.requests, 0, reason: 'never asked on open (FR-A3)');

    await tester.tap(byKey('reminders-toggle-j1'));
    await tester.pumpAndSettle();
    expect(byKey('reminders-permission-dialog'), findsOneWidget);
    await tester.tap(byKey('reminders-permission-continue'));
    await tester.pumpAndSettle();

    expect(h.gateway.requests, 1);
    expect(h.prefs.getBool(ReminderPrefs.permissionAsked), isTrue);
    expect(
      ReminderSetting.decode(h.prefs.getString('reminders.j1')).enabled,
      isTrue,
    );
    expect(byKey('reminders-time-j1'), findsOneWidget);
    expect(h.gateway.scheduled.length, greaterThan(0));
    expect(byKey('reminders-denied'), findsNothing);
  });

  testWidgets('"not now" keeps the reminder off and asks nothing', (
    tester,
  ) async {
    final h = await reminderHarness();
    addTearDown(h.container.dispose);
    await tester.pumpWidget(remindersApp(h));
    await tester.pumpAndSettle();

    await tester.tap(byKey('reminders-toggle-j1'));
    await tester.pumpAndSettle();
    await tester.tap(byKey('reminders-permission-later'));
    await tester.pumpAndSettle();

    expect(h.gateway.requests, 0);
    expect(h.prefs.getString('reminders.j1'), isNull);
    expect(find.text('Đang tắt'), findsOneWidget);
  });

  testWidgets('denied permission: saved anyway, banner opens settings', (
    tester,
  ) async {
    final h = await reminderHarness(
      gateway: FakeNotificationGateway(grantOnRequest: false),
    );
    addTearDown(h.container.dispose);
    await tester.pumpWidget(remindersApp(h));
    await tester.pumpAndSettle();

    await tester.tap(byKey('reminders-toggle-j1'));
    await tester.pumpAndSettle();
    await tester.tap(byKey('reminders-permission-continue'));
    await tester.pumpAndSettle();

    expect(byKey('reminders-denied'), findsOneWidget);
    expect(find.text('Thông báo đang tắt'), findsOneWidget);
    expect(h.gateway.scheduled, isEmpty);
    expect(
      ReminderSetting.decode(h.prefs.getString('reminders.j1')).enabled,
      isTrue,
    );

    await tester.ensureVisible(byKey('reminders-open-settings'));
    await tester.tap(byKey('reminders-open-settings'));
    await tester.pumpAndSettle();
    expect(h.gateway.settingsOpened, 1);
  });

  testWidgets('already asked and denied: no second prompt, banner shown', (
    tester,
  ) async {
    final h = await reminderHarness(
      prefs: {ReminderPrefs.permissionAsked: true},
    );
    addTearDown(h.container.dispose);
    await tester.pumpWidget(remindersApp(h));
    await tester.pumpAndSettle();
    // Streak alerts are on by default, so the banner already shows.
    expect(byKey('reminders-denied'), findsOneWidget);

    await tester.tap(byKey('reminders-toggle-j1'));
    await tester.pumpAndSettle();
    expect(byKey('reminders-permission-dialog'), findsNothing);
    expect(h.gateway.requests, 0);
  });

  testWidgets('granted: toggling off cancels the reminders', (tester) async {
    final h = await reminderHarness(
      gateway: FakeNotificationGateway(granted: true),
      prefs: {
        'reminders.j1': const ReminderSetting(
          enabled: true,
          time: kDefaultReminderTime,
        ).encode(),
        ReminderPrefs.streakAlerts: false,
      },
    );
    addTearDown(h.container.dispose);
    await h.container.read(reminderSchedulerProvider).reschedule();
    expect(h.gateway.scheduled, hasLength(14));

    await tester.pumpWidget(remindersApp(h));
    await tester.pumpAndSettle();
    expect(find.textContaining('20:00'), findsWidgets);

    await tester.tap(byKey('reminders-toggle-j1'));
    await tester.pumpAndSettle();
    expect(h.gateway.scheduled, isEmpty);
    expect(byKey('reminders-time-j1'), findsNothing);
  });

  testWidgets('time picker opens from the time button', (tester) async {
    final h = await reminderHarness(
      gateway: FakeNotificationGateway(granted: true),
      prefs: {
        'reminders.j1': const ReminderSetting(
          enabled: true,
          time: kDefaultReminderTime,
        ).encode(),
      },
    );
    addTearDown(h.container.dispose);
    await tester.pumpWidget(remindersApp(h, locale: const Locale('en')));
    await tester.pumpAndSettle();
    await tester.tap(byKey('reminders-time-j1'));
    await tester.pumpAndSettle();
    expect(find.text('Check-in reminder time'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(
      ReminderSetting.decode(h.prefs.getString('reminders.j1')).time,
      kDefaultReminderTime,
    );
  });

  testWidgets('streak alert switch persists', (tester) async {
    final h = await reminderHarness(
      gateway: FakeNotificationGateway(granted: true),
    );
    addTearDown(h.container.dispose);
    await tester.pumpWidget(remindersApp(h));
    await tester.pumpAndSettle();
    await tester.ensureVisible(byKey('reminders-streak-alert'));
    await tester.tap(byKey('reminders-streak-alert'));
    await tester.pumpAndSettle();
    expect(h.prefs.getBool(ReminderPrefs.streakAlerts), isFalse);
  });

  testWidgets('no journeys -> empty state', (tester) async {
    final empty = await reminderHarness(journeys: []);
    addTearDown(empty.container.dispose);
    await tester.pumpWidget(remindersApp(empty));
    await tester.pumpAndSettle();
    expect(byKey('reminders-empty'), findsOneWidget);
  });

  testWidgets('load failure -> error state', (tester) async {
    final failing = await reminderHarness(failJourneys: true);
    addTearDown(failing.container.dispose);
    await tester.pumpWidget(remindersApp(failing, locale: const Locale('en')));
    await tester.pumpAndSettle();
    expect(byKey('reminders-error'), findsOneWidget);
  });

  testWidgets('no overflow at 2x text scale', (tester) async {
    final h = await reminderHarness(
      prefs: {
        'reminders.j1': const ReminderSetting(
          enabled: true,
          time: kDefaultReminderTime,
        ).encode(),
        ReminderPrefs.permissionAsked: true,
      },
    );
    addTearDown(h.container.dispose);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(remindersApp(h));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
