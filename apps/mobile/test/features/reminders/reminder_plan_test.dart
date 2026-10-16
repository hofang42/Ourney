import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/features/reminders/domain/reminder_plan.dart';
import 'package:ourney_core/ourney_core.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

const hcm = 'Asia/Ho_Chi_Minh'; // UTC+7, no DST
const ny = 'America/New_York';

LocalDate d(String iso) => LocalDate.parse(iso);

JourneyReminderInput journey({
  String id = 'j1',
  String timezone = hcm,
  JourneyStatus status = JourneyStatus.active,
  String start = '2026-10-01',
  String? end,
  Set<LocalDate> checked = const {},
  ReminderTime? time = const ReminderTime(20, 0),
}) => JourneyReminderInput(
  journeyId: id,
  title: 'Journey $id',
  timezone: timezone,
  status: status,
  streakStart: d(start),
  endDate: end == null ? null : d(end),
  checkedInDates: checked,
  reminderTime: time,
);

/// Local wall-clock string of [utc] in [zone], `YYYY-MM-DD HH:mm`.
String wall(DateTime utc, String zone) {
  final t = tz.TZDateTime.from(utc, tz.getLocation(zone));
  String two(int v) => v.toString().padLeft(2, '0');
  return '${t.year}-${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}';
}

void main() {
  setUpAll(tzdata.initializeTimeZones);

  // 2026-10-16 10:00 in Ho Chi Minh.
  final now = DateTime.utc(2026, 10, 16, 3);

  group('ReminderTime', () {
    test('parses and prints HH:mm', () {
      expect(ReminderTime.tryParse('07:05'), const ReminderTime(7, 5));
      expect(const ReminderTime(7, 5).toString(), '07:05');
      expect(ReminderTime.tryParse('24:00'), isNull);
      expect(ReminderTime.tryParse('7'), isNull);
      expect(ReminderTime.tryParse(null), isNull);
      expect(ReminderTime.tryParse('ab:cd'), isNull);
    });
  });

  group('daily reminders', () {
    test('one per day for 14 days at the chosen device-local time', () {
      final plan = planReminders(
        now: now,
        deviceTimezone: hcm,
        journeys: [journey()],
        streakAlerts: false,
      );
      expect(plan, hasLength(14));
      expect(plan.every((p) => p.kind == PlannedKind.reminder), isTrue);
      expect(wall(plan.first.fireAt, hcm), '2026-10-16 20:00');
      expect(wall(plan.last.fireAt, hcm), '2026-10-29 20:00');
      expect(plan.first.journeyDate, d('2026-10-16'));
      expect(plan.every((p) => p.fireAt.isUtc), isTrue);
    });

    test('today is skipped once the time has passed', () {
      final plan = planReminders(
        now: DateTime.utc(2026, 10, 16, 13, 30), // 20:30 local
        deviceTimezone: hcm,
        journeys: [journey()],
        streakAlerts: false,
      );
      expect(plan, hasLength(13));
      expect(wall(plan.first.fireAt, hcm), '2026-10-17 20:00');
    });

    test('a reminder exactly at now is not planned (strictly future)', () {
      final plan = planReminders(
        now: DateTime.utc(2026, 10, 16, 13), // 20:00 local
        deviceTimezone: hcm,
        journeys: [journey()],
        streakAlerts: false,
      );
      expect(plan.first.journeyDate, d('2026-10-17'));
    });

    test('days already checked in are skipped', () {
      final plan = planReminders(
        now: now,
        deviceTimezone: hcm,
        journeys: [
          journey(checked: {d('2026-10-16'), d('2026-10-18')}),
        ],
        streakAlerts: false,
      );
      expect(plan, hasLength(12));
      final days = plan.map((p) => p.journeyDate).toSet();
      expect(days.contains(d('2026-10-16')), isFalse);
      expect(days.contains(d('2026-10-18')), isFalse);
      expect(days.contains(d('2026-10-17')), isTrue);
    });

    test('reminder off -> nothing', () {
      final plan = planReminders(
        now: now,
        deviceTimezone: hcm,
        journeys: [journey(time: null)],
        streakAlerts: false,
      );
      expect(plan, isEmpty);
    });

    test('ended and archived journeys are excluded', () {
      final plan = planReminders(
        now: now,
        deviceTimezone: hcm,
        journeys: [
          journey(id: 'e', status: JourneyStatus.ended),
          journey(id: 'a', status: JourneyStatus.archived),
        ],
      );
      expect(plan, isEmpty);
    });

    test('nothing after the last journey day', () {
      final plan = planReminders(
        now: now,
        deviceTimezone: hcm,
        journeys: [journey(end: '2026-10-19')],
        streakAlerts: false,
      );
      expect(plan.map((p) => p.journeyDate), [
        d('2026-10-16'),
        d('2026-10-17'),
        d('2026-10-18'),
        d('2026-10-19'),
      ]);
    });

    test('a journey whose end is in the past yields nothing', () {
      final plan = planReminders(
        now: now,
        deviceTimezone: hcm,
        journeys: [journey(start: '2026-09-01', end: '2026-10-15')],
      );
      expect(plan, isEmpty);
    });

    test('nothing before the journey (or the member) starts', () {
      final plan = planReminders(
        now: now,
        deviceTimezone: hcm,
        journeys: [journey(start: '2026-10-25')],
        streakAlerts: false,
      );
      expect(plan.first.journeyDate, d('2026-10-25'));
      expect(plan, hasLength(5)); // 25..29
    });

    test('device timezone decides the wall-clock time', () {
      // Device in New York, journey in Ho Chi Minh: 08:00 New York.
      final plan = planReminders(
        now: now,
        deviceTimezone: ny,
        journeys: [journey(time: const ReminderTime(8, 0))],
        streakAlerts: false,
      );
      expect(wall(plan.first.fireAt, ny).endsWith('08:00'), isTrue);
      // 08:00 EDT = 19:00 in Ho Chi Minh: same journey day.
      final first = plan.first;
      expect(wall(first.fireAt, hcm).substring(0, 10), '${first.journeyDate}');
    });

    test('journey day is computed in the journey timezone', () {
      // Device in New York at 23:00 = next day 10:00 in Ho Chi Minh. A
      // check-in on that HCM day suppresses the reminder.
      final plan = planReminders(
        now: DateTime.utc(2026, 10, 16, 12), // 08:00 NY, 19:00 HCM
        deviceTimezone: ny,
        journeys: [
          journey(
            time: const ReminderTime(23, 0),
            checked: {d('2026-10-17')},
          ),
        ],
        streakAlerts: false,
      );
      // 2026-10-16 23:00 NY = 2026-10-17 10:00 HCM -> skipped.
      expect(plan.first.journeyDate, d('2026-10-18'));
      expect(wall(plan.first.fireAt, ny), '2026-10-17 23:00');
    });

    test('unknown time zone names fall back to UTC instead of throwing', () {
      final plan = planReminders(
        now: now,
        deviceTimezone: 'Mars/Olympus',
        journeys: [journey(timezone: 'Nowhere/Zone')],
        streakAlerts: false,
      );
      expect(wall(plan.first.fireAt, 'Etc/UTC'), '2026-10-16 20:00');
    });
  });

  group('DST', () {
    test('spring forward: a time inside the gap moves forward by the gap', () {
      // 2027-03-14: New York clocks jump 02:00 -> 03:00.
      final plan = planReminders(
        now: DateTime.utc(2027, 3, 13, 12),
        deviceTimezone: ny,
        journeys: [
          journey(
            timezone: ny,
            start: '2027-03-01',
            time: const ReminderTime(2, 30),
          ),
        ],
        streakAlerts: false,
      );
      final walls = plan.map((p) => wall(p.fireAt, ny)).toList();
      expect(walls.first, '2027-03-14 03:30');
      expect(walls[1], '2027-03-15 02:30');
      // Exactly one per day, all distinct instants.
      expect(plan.map((p) => p.journeyDate).toSet(), hasLength(plan.length));
    });

    test('spring forward: regular times keep their wall clock', () {
      final plan = planReminders(
        now: DateTime.utc(2027, 3, 13, 12),
        deviceTimezone: ny,
        journeys: [journey(timezone: ny, start: '2027-03-01')],
        streakAlerts: false,
      );
      expect(plan.map((p) => wall(p.fireAt, ny).substring(11)).toSet(), {
        '20:00',
      });
      // UTC hour changes across the transition (01:00Z -> 00:00Z).
      expect(plan[0].fireAt.hour, 1); // 2027-03-13 20:00 EST
      expect(plan[1].fireAt.hour, 0); // 2027-03-14 20:00 EDT
    });

    test('fall back: an ambiguous time fires once, at the first occurrence',
        () {
      // 2026-11-01: New York clocks go 02:00 -> 01:00.
      final plan = planReminders(
        now: DateTime.utc(2026, 10, 31, 12),
        deviceTimezone: ny,
        journeys: [
          journey(timezone: ny, time: const ReminderTime(1, 30)),
        ],
        streakAlerts: false,
      );
      final nov1 = plan.where((p) => p.journeyDate == d('2026-11-01'));
      expect(nov1, hasLength(1));
      // First 01:30 is EDT (UTC-4) = 05:30Z.
      expect(nov1.single.fireAt, DateTime.utc(2026, 11, 1, 5, 30));
    });

    test('wallClockToUtc handles both transitions', () {
      final loc = tz.getLocation(ny);
      expect(
        wallClockToUtc(loc, d('2027-03-14'), const ReminderTime(2, 0)),
        DateTime.utc(2027, 3, 14, 7),
      );
      expect(
        wallClockToUtc(loc, d('2027-03-14'), const ReminderTime(3, 0)),
        DateTime.utc(2027, 3, 14, 7),
      );
      expect(
        wallClockToUtc(loc, d('2026-11-01'), const ReminderTime(1, 0)),
        DateTime.utc(2026, 11, 1, 5),
      );
      expect(
        wallClockToUtc(loc, d('2026-11-01'), const ReminderTime(2, 0)),
        DateTime.utc(2026, 11, 1, 7),
      );
      expect(
        wallClockToUtc(
          tz.getLocation(hcm),
          d('2026-10-16'),
          const ReminderTime(0, 0),
        ),
        DateTime.utc(2026, 10, 15, 17),
      );
    });
  });

  group('streak alert (21:00)', () {
    test('today, not checked in, streak alive -> alert at 21:00 local', () {
      final plan = planReminders(
        now: now,
        deviceTimezone: hcm,
        journeys: [
          journey(time: null, checked: {d('2026-10-14'), d('2026-10-15')}),
        ],
      );
      expect(plan, hasLength(1));
      final alert = plan.single;
      expect(alert.kind, PlannedKind.streakAlert);
      expect(alert.streak, 2);
      expect(wall(alert.fireAt, hcm), '2026-10-16 21:00');
    });

    test('no alert when the streak is already 0', () {
      final plan = planReminders(
        now: now,
        deviceTimezone: hcm,
        journeys: [
          journey(time: null, checked: {d('2026-10-10')}),
        ],
      );
      expect(plan, isEmpty);
    });

    test('checked in today -> alert moves to tomorrow', () {
      final plan = planReminders(
        now: now,
        deviceTimezone: hcm,
        journeys: [
          journey(time: null, checked: {d('2026-10-15'), d('2026-10-16')}),
        ],
      );
      expect(plan, hasLength(1));
      expect(plan.single.journeyDate, d('2026-10-17'));
      expect(plan.single.streak, 2);
    });

    test('first check-in today -> alert tomorrow with streak 1', () {
      final plan = planReminders(
        now: now,
        deviceTimezone: hcm,
        journeys: [
          journey(time: null, checked: {d('2026-10-16')}),
        ],
      );
      expect(plan.single.journeyDate, d('2026-10-17'));
      expect(plan.single.streak, 1);
    });

    test('after 21:00 the alert for today is gone', () {
      final plan = planReminders(
        now: DateTime.utc(2026, 10, 16, 14, 5), // 21:05 local
        deviceTimezone: hcm,
        journeys: [
          journey(time: null, checked: {d('2026-10-15')}),
        ],
      );
      expect(plan, isEmpty);
    });

    test('alert uses the journey timezone, not the device one', () {
      final plan = planReminders(
        now: now,
        deviceTimezone: ny,
        journeys: [
          journey(time: null, checked: {d('2026-10-15')}),
        ],
      );
      expect(wall(plan.single.fireAt, hcm), '2026-10-16 21:00');
    });

    test('alerts can be switched off', () {
      final plan = planReminders(
        now: now,
        deviceTimezone: hcm,
        streakAlerts: false,
        journeys: [
          journey(time: null, checked: {d('2026-10-15')}),
        ],
      );
      expect(plan, isEmpty);
    });

    test('no alert on a day after the journey ends', () {
      final plan = planReminders(
        now: now,
        deviceTimezone: hcm,
        journeys: [
          journey(
            time: null,
            end: '2026-10-16',
            checked: {d('2026-10-15'), d('2026-10-16')},
          ),
        ],
      );
      expect(plan, isEmpty);
    });

    test('reminders and alert on the same day are both kept, in order', () {
      final plan = planReminders(
        now: now,
        deviceTimezone: hcm,
        journeys: [
          journey(checked: {d('2026-10-15')}),
        ],
      );
      expect(plan.take(2).map((p) => p.kind), [
        PlannedKind.reminder,
        PlannedKind.streakAlert,
      ]);
    });

    test('at the same instant the alert sorts first', () {
      final plan = planReminders(
        now: now,
        deviceTimezone: hcm,
        journeys: [
          journey(
            time: const ReminderTime(21, 0),
            checked: {d('2026-10-15')},
          ),
        ],
      );
      expect(plan[0].kind, PlannedKind.streakAlert);
      expect(plan[1].kind, PlannedKind.reminder);
      expect(plan[0].fireAt, plan[1].fireAt);
    });
  });

  group('64 pending limit', () {
    test('5 journeys x 14 days + alerts are capped at 64', () {
      final plan = planReminders(
        now: now,
        deviceTimezone: hcm,
        journeys: [
          for (final id in ['a', 'b', 'c', 'd', 'e'])
            journey(id: id, checked: {d('2026-10-15')}),
        ],
      );
      expect(plan.length, kMaxPendingNotifications);
    });

    test('keeps the nearest notifications when trimming', () {
      final all = planReminders(
        now: now,
        deviceTimezone: hcm,
        maxPending: 1000,
        journeys: [
          for (var i = 0; i < 6; i++)
            journey(id: 'j$i', time: ReminderTime(11 + i, 0)),
        ],
      );
      expect(all, hasLength(84));
      final capped = planReminders(
        now: now,
        deviceTimezone: hcm,
        journeys: [
          for (var i = 0; i < 6; i++)
            journey(id: 'j$i', time: ReminderTime(11 + i, 0)),
        ],
      );
      expect(capped, hasLength(64));
      expect(capped.map((p) => p.fireAt), all.take(64).map((p) => p.fireAt));
      // Sorted ascending.
      for (var i = 1; i < capped.length; i++) {
        expect(capped[i].fireAt.isBefore(capped[i - 1].fireAt), isFalse);
      }
      final lastKept = capped.last.fireAt;
      expect(
        all.skip(64).every((p) => !p.fireAt.isBefore(lastKept)),
        isTrue,
      );
    });

    test('custom window and limit are honoured', () {
      final plan = planReminders(
        now: now,
        deviceTimezone: hcm,
        windowDays: 3,
        maxPending: 2,
        journeys: [journey()],
        streakAlerts: false,
      );
      expect(plan, hasLength(2));
    });
  });

  test('fromJourney uses the later of start and join date', () {
    final j = Journey(
      id: 'x',
      ownerId: 'o',
      kind: JourneyKind.group,
      templateId: TemplateId.custom,
      title: 'Run',
      emoji: '🏃',
      startDate: d('2026-10-01'),
      durationDays: 30,
      timezone: hcm,
      visibility: JourneyVisibility.group,
      status: JourneyStatus.active,
    );
    final input = JourneyReminderInput.fromJourney(
      j,
      checkedInDates: [d('2026-10-05')],
      joinedLocalDate: d('2026-10-10'),
    );
    expect(input.streakStart, d('2026-10-10'));
    expect(input.endDate, d('2026-10-30'));
    expect(
      JourneyReminderInput.fromJourney(
        j,
        checkedInDates: const [],
        joinedLocalDate: d('2026-09-01'),
      ).streakStart,
      d('2026-10-01'),
    );
  });
}
