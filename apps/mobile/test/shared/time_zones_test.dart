import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/data/journey_clock.dart' as data;
import 'package:ourney/features/checkin/journey_clock.dart';
import 'package:ourney/features/groups/domain/group_today.dart';
import 'package:ourney/features/journeys/domain/journey_time.dart';
import 'package:ourney/features/reminders/domain/reminder_plan.dart';
import 'package:ourney/shared/time_zones.dart';
import 'package:ourney_core/ourney_core.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUp(resetTimeZoneGuesses);

  // 2026-10-16 18:30 UTC is already the 17th in Viet Nam (+7) and in India
  // (+5:30, 00:00 on the 17th), still the 16th in California (-7, PDT).
  final t = DateTime.utc(2026, 10, 16, 18, 30);

  group('legacy aliases', () {
    test('map to canonical names', () {
      expect(canonicalTimeZoneName('Asia/Saigon'), 'Asia/Ho_Chi_Minh');
      expect(canonicalTimeZoneName(' Asia/Calcutta '), 'Asia/Kolkata');
      expect(canonicalTimeZoneName('US/Pacific'), 'America/Los_Angeles');
      expect(canonicalTimeZoneName('Etc/UTC'), 'UTC');
      expect(canonicalTimeZoneName('Europe/Paris'), 'Europe/Paris');
    });

    test('every alias target exists in the bundled database', () {
      ensureTimeZonesLoaded();
      for (final target in legacyTimeZoneAliases.values.toSet()) {
        expect(
          tz.timeZoneDatabase.locations.containsKey(target),
          isTrue,
          reason: target,
        );
      }
    });

    test('resolve to the right offset, never UTC', () {
      expect(resolveTimeZone('Asia/Saigon').name, 'Asia/Ho_Chi_Minh');
      expect(timeZoneOffsetAt('Asia/Saigon', t), const Duration(hours: 7));
      expect(
        timeZoneOffsetAt('Asia/Calcutta', t),
        const Duration(hours: 5, minutes: 30),
      );
      expect(timeZoneOffsetAt('US/Pacific', t), const Duration(hours: -7));
      expect(isKnownTimeZone('Asia/Saigon'), isTrue);
    });
  });

  group('unknown names fall back to a canonical guess', () {
    test('case-insensitive match', () {
      expect(resolveTimeZone('asia/ho_chi_minh').name, 'Asia/Ho_Chi_Minh');
    });

    test('same city in another region', () {
      expect(resolveTimeZone('Mars/Saigon').name, 'Asia/Ho_Chi_Minh');
    });

    test('device offset when nothing matches', () {
      expect(
        resolveTimeZone(
          'Not/AZone',
          deviceOffset: const Duration(hours: 7),
        ).name,
        'Etc/GMT-7',
      );
      expect(
        guessTimeZoneForOffset(
          const Duration(hours: 5, minutes: 30),
          at: t,
        ).timeZone(t.millisecondsSinceEpoch).offset,
        const Duration(hours: 5, minutes: 30),
      );
      expect(guessTimeZoneForOffset(Duration.zero).name, 'UTC');
      expect(isKnownTimeZone('Not/AZone'), isFalse);
    });
  });

  group('every feature uses the shared loader (Asia/Saigon)', () {
    const next = LocalDate(2026, 10, 17);

    test('journeys', () {
      expect(journeyLocalDate('Asia/Saigon', t), next);
      expect(isKnownTimezone('Asia/Saigon'), isTrue);
    });

    test('check-in clock', () {
      expect(TzJourneyClock().localDate(t, 'Asia/Saigon'), next);
    });

    test('groups', () {
      expect(groupLocalDate('Asia/Saigon', t), next);
    });

    test('reminders', () {
      expect(localDateIn('Asia/Saigon', t), next);
      expect(localDateIn('US/Pacific', t), const LocalDate(2026, 10, 16));
    });

    test('data layer clock', () {
      expect(data.JourneyClock(now: () => t).today('Asia/Saigon'), next);
      expect(data.ianaOffset('Asia/Calcutta', t).inMinutes, 330);
    });

    test('reminder plan: device in Asia/Saigon schedules in +7', () {
      final plan = planReminders(
        now: DateTime.utc(2026, 10, 16, 3), // 10:00 in Viet Nam
        deviceTimezone: 'Asia/Saigon',
        journeys: [
          JourneyReminderInput(
            journeyId: 'j1',
            title: 'J',
            timezone: 'Asia/Saigon',
            status: JourneyStatus.active,
            streakStart: const LocalDate(2026, 10, 1),
            checkedInDates: const {},
            reminderTime: const ReminderTime(20, 0),
          ),
        ],
        streakAlerts: false,
      );
      // 20:00 +7 = 13:00 UTC (it would be 20:00 UTC with the old fallback).
      expect(plan.first.fireAt, DateTime.utc(2026, 10, 16, 13));
    });
  });
}
