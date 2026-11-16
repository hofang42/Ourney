import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/localization.dart';
import 'package:ourney/app/theme/app_theme.dart';
import 'package:ourney/features/reminders/data/reminder_settings.dart';
import 'package:ourney/features/reminders/domain/reminder_plan.dart';
import 'package:ourney/features/reminders/ui/reminder_permission_prompt.dart';

import 'reminders_fakes.dart';

Finder byKey(String key) => find.byKey(ValueKey(key));

Map<String, Object> reminderOn(String id, String time) => {
  ReminderPrefs.journey(id): ReminderSetting(
    enabled: true,
    time: ReminderTime.tryParse(time)!,
  ).encode(),
};

/// Bug #7: reminders switched on outside `/reminders` (quiz time saved on
/// create, default-on 21:00 alert) never got the OS permission, so the
/// scheduler planned nothing. [offerReminderPermission] asks once, in
/// context.
class _ThrowingGateway extends FakeNotificationGateway {
  @override
  Future<bool> isPermissionGranted() async =>
      throw StateError('LateInitializationError: plugin not registered');
}

Widget _app(ReminderHarness h, void Function(bool) onResult) =>
    UncontrolledProviderScope(
      container: h.container,
      child: MaterialApp(
        theme: buildAppTheme(Brightness.light),
        locale: const Locale('vi'),
        localizationsDelegates: ourneyLocalizationsDelegates,
        supportedLocales: ourneySupportedLocales,
        home: Consumer(
          builder: (context, ref, _) => Center(
            child: TextButton(
              key: const ValueKey('offer'),
              onPressed: () async => onResult(
                await offerReminderPermission(
                  context,
                  ref,
                  time: const ReminderTime(7, 30),
                ),
              ),
              child: const Text('offer'),
            ),
          ),
        ),
      ),
    );

Future<bool?> _offer(WidgetTester tester, ReminderHarness h) async {
  bool? result;
  await tester.pumpWidget(_app(h, (r) => result = r));
  await tester.tap(byKey('offer'));
  await tester.pumpAndSettle();
  return result;
}

void main() {
  testWidgets('not asked yet: sheet, OS prompt, then reminders scheduled', (
    tester,
  ) async {
    final h = await reminderHarness(prefs: reminderOn('j1', '07:30'));
    addTearDown(h.container.dispose);
    bool? result;
    await tester.pumpWidget(_app(h, (r) => result = r));
    await tester.tap(byKey('offer'));
    await tester.pumpAndSettle();

    expect(byKey('notification-sheet'), findsOneWidget);
    expect(find.textContaining('07:30'), findsWidgets);
    expect(h.gateway.requests, 0, reason: 'the sheet comes first (FR-A3)');
    await tester.tap(byKey('notification-turn-on'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
    expect(h.gateway.requests, 1);
    expect(h.prefs.getBool(ReminderPrefs.permissionAsked), isTrue);
    expect(h.prefs.getBool(ReminderPrefs.promptOffered), isTrue);
    // The schedule is rebuilt right away with the new permission.
    expect(h.gateway.scheduled, isNotEmpty);
    expect(h.gateway.scheduled.values.map((r) => r.payload).toSet(), {'j1'});
  });

  testWidgets('"not now" asks nothing and leaves the screen prompt intact', (
    tester,
  ) async {
    final h = await reminderHarness();
    addTearDown(h.container.dispose);
    bool? result;
    await tester.pumpWidget(_app(h, (r) => result = r));
    await tester.tap(byKey('offer'));
    await tester.pumpAndSettle();
    await tester.tap(byKey('notification-later'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
    expect(h.gateway.requests, 0);
    expect(h.prefs.getBool(ReminderPrefs.promptOffered), isTrue);
    // Not the OS prompt: `/reminders` can still show its own rationale.
    expect(h.prefs.getBool(ReminderPrefs.permissionAsked), isNull);
    expect(ReminderPrefs.journeyIdOf(ReminderPrefs.promptOffered), isNull);

    // Offered once only.
    await tester.tap(byKey('offer'));
    await tester.pumpAndSettle();
    expect(byKey('notification-sheet'), findsNothing);
  });

  testWidgets('already allowed: no sheet, reports true', (tester) async {
    final h = await reminderHarness(
      gateway: FakeNotificationGateway(granted: true),
    );
    addTearDown(h.container.dispose);
    expect(await _offer(tester, h), isTrue);
    expect(byKey('notification-sheet'), findsNothing);
    expect(h.gateway.requests, 0);
  });

  testWidgets('OS prompt shown before: no sheet', (tester) async {
    final h = await reminderHarness(
      prefs: {ReminderPrefs.permissionAsked: true},
    );
    addTearDown(h.container.dispose);
    expect(await _offer(tester, h), isFalse);
    expect(byKey('notification-sheet'), findsNothing);
  });

  testWidgets('plugin unavailable: no sheet, never throws', (tester) async {
    final h = await reminderHarness(gateway: _ThrowingGateway());
    addTearDown(h.container.dispose);
    expect(await _offer(tester, h), isFalse);
    expect(byKey('notification-sheet'), findsNothing);
  });
}
