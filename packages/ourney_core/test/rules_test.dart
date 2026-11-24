import 'package:ourney_core/ourney_core.dart';
import 'package:test/test.dart';

void main() {
  test('limits', () {
    expect(maxGroupMembers, 10);
  });

  test('maxMembersForDraft: solo 1, couple 2, group 10 (A-B6)', () {
    JourneyDraft draft(JourneyKind kind, {String? self, String? partner}) =>
        JourneyDraft(
          kind: kind,
          templateId: TemplateId.custom,
          title: 'T',
          emoji: 'x',
          startDate: const LocalDate(2026, 10, 16),
          timezone: 'Asia/Ho_Chi_Minh',
          coupleSelfName: self,
          couplePartnerName: partner,
        );
    expect(maxMembersForDraft(draft(JourneyKind.solo)), 1);
    expect(maxMembersForDraft(draft(JourneyKind.group)), maxGroupMembers);
    expect(
      maxMembersForDraft(draft(JourneyKind.group, self: 'An', partner: 'Bo')),
      2,
    );
    expect(
      maxMembersForDraft(draft(JourneyKind.group, self: '  ', partner: ' ')),
      maxGroupMembers,
      reason: 'blank names are not a couple (create_journey nullif)',
    );
  });

  group('sanitizeJourneyDna (A-B11, FS-37)', () {
    test('clips by code points, never inside a surrogate pair', () {
      final trophy = '${'a' * 23}\u{1F3C6}';
      expect(sanitizeJourneyDna({'trophy': trophy})!['trophy'], trophy);
      final long = '${'a' * 23}\u{1F3C6}\u{1F3C6}';
      expect(sanitizeJourneyDna({'trophy': long})!['trophy'], trophy);
    });

    test('validates nested dates and choice format', () {
      expect(
        sanitizeJourneyDna({
          'dates': {'start': '2026-05-01', 'end': '2026-05-10'},
          'goal': 'lose',
        }),
        {
          'dates': {'start': '2026-05-01', 'end': '2026-05-10'},
          'goal': 'lose',
        },
      );
      // Null end is omitted so SQL journey_dna_valid never sees JSON null.
      expect(
        sanitizeJourneyDna({
          'dates': {'start': '2026-05-01', 'end': null},
        }),
        {
          'dates': {'start': '2026-05-01'},
        },
      );
      // Invalid dates or end < start are dropped.
      expect(
        sanitizeJourneyDna({
          'dates': {'start': '2026-05-10', 'end': '2026-05-01'},
        }),
        isNull,
      );
      expect(
        sanitizeJourneyDna({
          'dates': {'start': 'not-a-date'},
        }),
        isNull,
      );
      expect(
        sanitizeJourneyDna({
          'dates': {'start': '2026-05-01', 'extra': '1'},
        }),
        isNull,
      );
      expect(
        sanitizeJourneyDna({'goal': 'INVALID CHOICE!'}),
        isNull,
      );
    });

    test('rejects payloads whose Postgres jsonb::text exceeds 960 bytes (FS-37)', () {
      // Multi-byte UTF-8 emojis (4 bytes per rune) + all choice fields can push
      // formatted jsonb::text past the server 1024-byte limit even when compact
      // jsonEncode is just under 1024 bytes.
      final oversized = <String, Object?>{
        'trophy': '\u{1F3C6}' * 24,
        'place': '\u{1F30D}' * 60,
        'habit': '\u{1F525}' * 40,
        'reason': '\u{1F4AA}' * 80,
        'goal': 'a' * 24,
        'minutes': 'b' * 24,
        'sport': 'c' * 24,
        'measure': 'd' * 24,
        'dates': {'start': '2026-05-01', 'end': '2026-05-10'},
      };
      expect(sanitizeJourneyDna(oversized), isNull);
    });
  });

  group('rollingReminderTimes', () {
    test('before reminder time starts today, 14 entries', () {
      final t = rollingReminderTimes(
          nowLocal: DateTime(2026, 10, 5, 8, 0), hour: 20, minute: 30);
      expect(t.length, 14);
      expect(t.first, DateTime(2026, 10, 5, 20, 30));
      expect(t.last, DateTime(2026, 10, 18, 20, 30));
    });
    test('after reminder time starts tomorrow', () {
      final t = rollingReminderTimes(
          nowLocal: DateTime(2026, 10, 5, 21, 0), hour: 20, minute: 30);
      expect(t.length, 14);
      expect(t.first, DateTime(2026, 10, 6, 20, 30));
    });
    test('exactly at reminder time is not scheduled for today', () {
      final t = rollingReminderTimes(
          nowLocal: DateTime(2026, 10, 5, 20, 30), hour: 20, minute: 30);
      expect(t.first, DateTime(2026, 10, 6, 20, 30));
    });
    test('skipDates removes days (e.g. already checked in today)', () {
      final t = rollingReminderTimes(
        nowLocal: DateTime(2026, 10, 5, 8, 0),
        hour: 20,
        minute: 0,
        skipDates: {LocalDate(2026, 10, 5), LocalDate(2026, 10, 7)},
      );
      expect(t.length, 12);
      expect(t.first, DateTime(2026, 10, 6, 20, 0));
      expect(t.contains(DateTime(2026, 10, 7, 20, 0)), isFalse);
    });
    test('month and year rollover', () {
      final t = rollingReminderTimes(
          nowLocal: DateTime(2026, 12, 28, 8, 0), hour: 9, minute: 0, days: 6);
      expect(t.last, DateTime(2027, 1, 2, 9, 0));
    });
    test('leap day included', () {
      final t = rollingReminderTimes(
          nowLocal: DateTime(2028, 2, 27, 8, 0), hour: 9, minute: 0, days: 3);
      expect(t.map((e) => e.day), [27, 28, 29]);
    });
    test('custom days count', () {
      final t = rollingReminderTimes(
          nowLocal: DateTime(2026, 10, 5, 8), hour: 9, minute: 0, days: 5);
      expect(t.length, 5);
    });
    test('results are strictly increasing', () {
      final t = rollingReminderTimes(
          nowLocal: DateTime(2026, 10, 5, 8), hour: 9, minute: 0);
      for (var i = 1; i < t.length; i++) {
        expect(t[i].isAfter(t[i - 1]), isTrue);
      }
    });
  });

  group('maxReminderSlotsPerJourney', () {
    test('zero journeys -> 0', () => expect(maxReminderSlotsPerJourney(0), 0));
    test('one journey is capped at 14',
        () => expect(maxReminderSlotsPerJourney(1), 14));
    test('two journeys capped at 14',
        () => expect(maxReminderSlotsPerJourney(2), 14));
    test('three journeys share budget',
        () => expect(maxReminderSlotsPerJourney(3), 10));
    test('total reminders + at-risk never exceeds iOS cap of 64', () {
      // No cap on running journeys (FR-B3): the budget must hold for many.
      for (var n = 0; n <= 30; n++) {
        final total =
            n * (maxReminderSlotsPerJourney(n) + maxAtRiskSlotsPerJourney(n));
        expect(total, lessThanOrEqualTo(iosPendingNotificationLimit),
            reason: 'n=$n');
      }
    });
    test('reserves at least as many at-risk slots as reminder slots', () {
      for (var n = 1; n <= 3; n++) {
        expect(maxAtRiskSlotsPerJourney(n), maxReminderSlotsPerJourney(n));
      }
    });
  });
}
