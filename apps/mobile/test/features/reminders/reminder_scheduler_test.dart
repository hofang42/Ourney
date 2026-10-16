import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/features/reminders/data/notification_gateway.dart';
import 'package:ourney/features/reminders/data/reminder_scheduler.dart';
import 'package:ourney/features/reminders/data/reminder_settings.dart';
import 'package:ourney/features/reminders/domain/reminder_plan.dart';
import 'package:ourney_core/ourney_core.dart';

import 'reminders_fakes.dart';

const today = LocalDate(2026, 10, 16);

Map<String, Object> reminderOn(String id, [String time = '20:00']) => {
  ReminderPrefs.journey(id): ReminderSetting(
    enabled: true,
    time: ReminderTime.tryParse(time)!,
  ).encode(),
};

void main() {
  group('ReminderSetting / prefs', () {
    test('round-trips through JSON and tolerates garbage', () {
      const s = ReminderSetting(enabled: true, time: ReminderTime(7, 30));
      expect(ReminderSetting.decode(s.encode()), s);
      expect(ReminderSetting.decode(null), ReminderSetting.off);
      expect(ReminderSetting.decode('nope'), ReminderSetting.off);
      expect(ReminderSetting.decode('[1]'), ReminderSetting.off);
      expect(
        ReminderSetting.decode('{"on": true, "time": "99:00"}'),
        const ReminderSetting(enabled: true, time: kDefaultReminderTime),
      );
      expect(s.activeTime, const ReminderTime(7, 30));
      expect(s.copyWith(enabled: false).activeTime, isNull);
    });

    test('journey keys exclude the reserved ones', () {
      expect(ReminderPrefs.journeyIdOf('reminders.abc'), 'abc');
      expect(ReminderPrefs.journeyIdOf(ReminderPrefs.streakAlerts), isNull);
      expect(ReminderPrefs.journeyIdOf(ReminderPrefs.permissionAsked), isNull);
      expect(ReminderPrefs.journeyIdOf('camera.lastJourneyId'), isNull);
      expect(ReminderPrefs.journeyIdOf('reminders.'), isNull);
    });

    test('settings controller loads and saves under reminders.<id>', () async {
      final h = await reminderHarness(
        prefs: {...reminderOn('a', '07:15'), 'camera.lastJourneyId': 'x'},
      );
      addTearDown(h.container.dispose);
      final settings = h.container.read(reminderSettingsProvider);
      expect(settings.keys, ['a']);
      expect(settings['a']!.time, const ReminderTime(7, 15));

      await h.container
          .read(reminderSettingsProvider.notifier)
          .save(
            'b',
            const ReminderSetting(enabled: true, time: ReminderTime(6, 0)),
          );
      expect(h.prefs.getString('reminders.b'), contains('06:00'));
      await h.container.read(reminderSettingsProvider.notifier).forget('a');
      expect(h.prefs.getString('reminders.a'), isNull);
      expect(h.container.read(reminderSettingsProvider).keys, ['b']);
    });

    test('streak alerts default on and persist', () async {
      final h = await reminderHarness();
      addTearDown(h.container.dispose);
      expect(h.container.read(streakAlertsEnabledProvider), isTrue);
      await h.container
          .read(streakAlertsEnabledProvider.notifier)
          .set(enabled: false);
      expect(h.prefs.getBool(ReminderPrefs.streakAlerts), isFalse);
    });
  });

  group('ReminderScheduler', () {
    test(
      'without permission nothing is scheduled and old reminders go',
      () async {
        final gateway = FakeNotificationGateway()..foreign.add(1);
        final h = await reminderHarness(
          gateway: gateway,
          prefs: reminderOn('j1'),
        );
        addTearDown(h.container.dispose);
        gateway.scheduled[kReminderIdBase + 3] = _dummy(kReminderIdBase + 3);

        await h.container.read(reminderSchedulerProvider).reschedule();

        expect(gateway.scheduled, isEmpty);
        expect(gateway.foreign, {1}, reason: 'other ids are not ours');
      },
    );

    test(
      'schedules 14 localized reminders with the journey as payload',
      () async {
        final gateway = FakeNotificationGateway(granted: true)..foreign.add(7);
        final h = await reminderHarness(
          gateway: gateway,
          prefs: {...reminderOn('j1'), ReminderPrefs.streakAlerts: false},
        );
        addTearDown(h.container.dispose);

        await h.container.read(reminderSchedulerProvider).reschedule();

        expect(gateway.scheduled, hasLength(14));
        expect(gateway.foreign, {7});
        final first = gateway.scheduled[kReminderIdBase]!;
        expect(first.payload, 'j1');
        expect(first.title, 'Đến giờ check-in rồi');
        expect(first.body, contains('Tập mỗi ngày'));
        // 20:00 in Ho Chi Minh = 13:00Z.
        expect(first.fireAt, DateTime.utc(2026, 10, 16, 13));
        expect(
          gateway.scheduled.keys.every(
            (id) => id >= kReminderIdBase && id < kReminderIdBase + 64,
          ),
          isTrue,
        );
      },
    );

    test('a check-in today removes today and adds tomorrow\'s alert', () async {
      final gateway = FakeNotificationGateway(granted: true);
      final h = await reminderHarness(
        gateway: gateway,
        prefs: reminderOn('j1'),
      );
      addTearDown(h.container.dispose);
      h.checkIns.byJourney['j1'] = [reminderCheckIn('j1', today.addDays(-1))];

      await h.container.read(reminderSchedulerProvider).reschedule();
      final before = gateway.scheduled.values.toList()
        ..sort((a, b) => a.fireAt.compareTo(b.fireAt));
      expect(before.first.fireAt, DateTime.utc(2026, 10, 16, 13));
      final alert = before[1];
      expect(alert.title, 'Streak sắp mất');
      expect(alert.body, contains('1 ngày'));
      expect(alert.fireAt, DateTime.utc(2026, 10, 16, 14)); // 21:00 local

      h.checkIns.byJourney['j1'] = [
        reminderCheckIn('j1', today.addDays(-1)),
        reminderCheckIn('j1', today),
      ];
      await h.container.read(reminderSchedulerProvider).reschedule();
      final after = gateway.scheduled.values.toList()
        ..sort((a, b) => a.fireAt.compareTo(b.fireAt));
      expect(after, hasLength(14)); // 13 reminders + tomorrow's alert
      expect(after.first.fireAt, DateTime.utc(2026, 10, 17, 13));
      expect(after[1].body, contains('2 ngày'));
    });

    test('only the user\'s own check-ins count when signed in', () async {
      final gateway = FakeNotificationGateway(granted: true);
      final h = await reminderHarness(
        gateway: gateway,
        prefs: {...reminderOn('j1'), ReminderPrefs.streakAlerts: false},
        overrides: [currentUserIdProvider.overrideWithBuild((ref, _) => 'u1')],
      );
      addTearDown(h.container.dispose);
      h.checkIns.byJourney['j1'] = [reminderCheckIn('j1', today, user: 'u2')];
      await h.container.read(reminderSchedulerProvider).reschedule();
      expect(gateway.scheduled, hasLength(14));
    });

    test('late joiners get nothing before their join date', () async {
      final gateway = FakeNotificationGateway(granted: true);
      final j = reminderJourney(start: const LocalDate(2026, 10, 1));
      final h = await reminderHarness(
        journeys: [j],
        gateway: gateway,
        prefs: {...reminderOn('j1'), ReminderPrefs.streakAlerts: false},
      );
      addTearDown(h.container.dispose);
      h.journeys.memberships['j1'] = Membership(
        journeyId: 'j1',
        userId: 'u1',
        role: MemberRole.member,
        status: MemberStatus.active,
        joinedAt: DateTime.utc(2026, 10, 20, 2), // 09:00 local on the 20th
      );
      await h.container.read(reminderSchedulerProvider).reschedule();
      expect(gateway.scheduled, hasLength(10)); // 20..29
    });

    test('ended journeys and journeys without reminders are skipped', () async {
      final gateway = FakeNotificationGateway(granted: true);
      final h = await reminderHarness(
        journeys: [
          reminderJourney(id: 'ended', status: JourneyStatus.ended),
          reminderJourney(id: 'off'),
        ],
        gateway: gateway,
        prefs: {...reminderOn('ended'), ReminderPrefs.streakAlerts: false},
      );
      addTearDown(h.container.dispose);
      await h.container.read(reminderSchedulerProvider).reschedule();
      expect(gateway.scheduled, isEmpty);
    });

    test('never more than 64 pending', () async {
      final gateway = FakeNotificationGateway(granted: true);
      final ids = ['a', 'b', 'c', 'd', 'e'];
      final h = await reminderHarness(
        journeys: [for (final id in ids) reminderJourney(id: id)],
        gateway: gateway,
        prefs: {for (final id in ids) ...reminderOn(id)},
      );
      addTearDown(h.container.dispose);
      for (final id in ids) {
        h.checkIns.byJourney[id] = [reminderCheckIn(id, today.addDays(-1))];
      }
      await h.container.read(reminderSchedulerProvider).reschedule();
      expect(gateway.scheduled, hasLength(64));
    });

    test('a data layer failure keeps the previous schedule', () async {
      final gateway = FakeNotificationGateway(granted: true);
      final h = await reminderHarness(
        gateway: gateway,
        prefs: reminderOn('j1'),
        failJourneys: true,
      );
      addTearDown(h.container.dispose);
      gateway.scheduled[kReminderIdBase] = _dummy(kReminderIdBase);
      await h.container.read(reminderSchedulerProvider).reschedule();
      expect(gateway.scheduled.keys, [kReminderIdBase]);
    });

    test('an unwired repository is not an error', () async {
      final gateway = FakeNotificationGateway(granted: true);
      final h = await reminderHarness(
        gateway: gateway,
        prefs: reminderOn('j1'),
        unwiredJourneys: true,
      );
      addTearDown(h.container.dispose);
      await expectLater(
        h.container.read(reminderSchedulerProvider).reschedule(),
        completes,
      );
      expect(gateway.scheduled, isEmpty);
    });

    test('concurrent reschedules are serialised', () async {
      final gateway = FakeNotificationGateway(granted: true);
      final h = await reminderHarness(
        gateway: gateway,
        prefs: reminderOn('j1'),
      );
      addTearDown(h.container.dispose);
      final scheduler = h.container.read(reminderSchedulerProvider);
      await Future.wait([
        scheduler.reschedule(),
        scheduler.reschedule(),
        scheduler.reschedule(),
      ]);
      expect(gateway.scheduled, hasLength(14));
    });

    test('English device gets English texts', () async {
      final gateway = FakeNotificationGateway(granted: true);
      final h = await reminderHarness(
        gateway: gateway,
        prefs: reminderOn('j1'),
        locale: const Locale('en'),
      );
      addTearDown(h.container.dispose);
      await h.container.read(reminderSchedulerProvider).reschedule();
      expect(gateway.scheduled[kReminderIdBase]!.title, 'Time to check in');
    });
  });

  group('ReminderLifecycleHook', () {
    testWidgets('reschedules on start and on resume, routes taps', (
      tester,
    ) async {
      final gateway = FakeNotificationGateway(granted: true)..launch = 'j1';
      final h = await reminderHarness(
        gateway: gateway,
        prefs: reminderOn('j1'),
      );
      addTearDown(h.container.dispose);
      final opened = <String>[];
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: h.container,
          child: ReminderLifecycleHook(
            onOpenJourney: opened.add,
            child: const SizedBox(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(opened, ['j1']);
      expect(gateway.scheduled, isNotEmpty);

      gateway.scheduled.clear();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(gateway.scheduled, isNotEmpty);

      gateway.onTap!('j2');
      expect(opened, ['j1', 'j2']);
    });
  });
}

NotificationRequest _dummy(int id) => NotificationRequest(
  id: id,
  fireAt: DateTime.utc(2026, 10, 20),
  title: 'old',
  body: 'old',
  payload: 'old',
);
