import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/features/journeys/domain/journey_form.dart';
import 'package:ourney/features/journeys/domain/journey_progress.dart';
import 'package:ourney/features/journeys/domain/journey_time.dart';
import 'package:ourney_core/ourney_core.dart';

import 'journeys_fakes.dart';

void main() {
  group('journey time', () {
    test('local date follows the journey time zone', () {
      // 2026-10-16 18:30 UTC is already the 17th in Ho Chi Minh City (+7).
      final t = DateTime.utc(2026, 10, 16, 18, 30);
      expect(journeyLocalDate(testTz, t), const LocalDate(2026, 10, 17));
      expect(journeyLocalDate('UTC', t), const LocalDate(2026, 10, 16));
    });

    test('unknown zone falls back instead of throwing', () {
      expect(isKnownTimezone('Not/AZone'), isFalse);
      expect(() => utcOffsetIn('Not/AZone', testNow), returnsNormally);
    });
  });

  group('JourneyProgress (FR-B4/B5)', () {
    final j = testJourney(); // 2026-10-10, 14 days
    JourneyProgress progress(List<LocalDate> dates, {Membership? m}) =>
        JourneyProgress.compute(
          journey: j,
          membership: m ?? testMembership(j),
          checkIns: [for (final d in dates) testCheckIn(j.id, d)],
          now: testNow,
        );

    test('stats come from computeMemberStreak', () {
      final p = progress(const [
        LocalDate(2026, 10, 10),
        LocalDate(2026, 10, 11),
        LocalDate(2026, 10, 13),
        LocalDate(2026, 10, 14),
        LocalDate(2026, 10, 15),
      ]);
      expect(p.today, testToday);
      expect(p.summary.current, 3);
      expect(p.summary.best, 3);
      expect(p.summary.atRisk, isTrue);
      expect(p.dayNumber, 7);
      expect(p.totalDays, 14);
      expect(p.percentComplete, 36); // 5/14
      expect(p.checkedInToday, isFalse);
    });

    test('timeline marks checked, missed, today and future days', () {
      final days = progress(const [
        LocalDate(2026, 10, 10),
        LocalDate(2026, 10, 12),
      ]).timeline();
      expect(days, hasLength(14));
      final byDate = {for (final d in days) d.date: d.state};
      expect(byDate[const LocalDate(2026, 10, 10)], DayState.checkedIn);
      expect(byDate[const LocalDate(2026, 10, 11)], DayState.missed);
      expect(byDate[const LocalDate(2026, 10, 12)], DayState.checkedIn);
      expect(byDate[const LocalDate(2026, 10, 15)], DayState.missed);
      expect(byDate[testToday], DayState.today);
      expect(byDate[const LocalDate(2026, 10, 17)], DayState.future);
      expect(byDate[const LocalDate(2026, 10, 23)], DayState.future);
      expect(days.where((d) => d.isToday), hasLength(1));
    });

    test('late joiner: days before joining are not counted', () {
      final g = testJourney(kind: JourneyKind.group);
      final m = Membership(
        journeyId: g.id,
        userId: 'u2',
        role: MemberRole.member,
        status: MemberStatus.active,
        joinedAt: DateTime.utc(2026, 10, 13, 3),
      );
      final p = JourneyProgress.compute(
        journey: g,
        membership: m,
        checkIns: [testCheckIn(g.id, const LocalDate(2026, 10, 14))],
        now: testNow,
      );
      final byDate = {for (final d in p.timeline()) d.date: d.state};
      expect(byDate[const LocalDate(2026, 10, 12)], DayState.notCounted);
      expect(byDate[const LocalDate(2026, 10, 13)], DayState.missed);
      expect(p.memberStart, const LocalDate(2026, 10, 13));
      // Window 13..23 = 11 days, 1 completed.
      expect(p.percentComplete, 9);
    });

    test('open-ended journeys run to today and have no percentage', () {
      final open = testJourney(durationDays: null);
      final p = JourneyProgress.compute(
        journey: open,
        membership: null,
        checkIns: const [],
        now: testNow,
      );
      expect(p.timeline().last.date, testToday);
      expect(p.percentComplete, isNull);
      expect(p.dayNumber, 7);
    });
  });

  group('JourneyBuckets (FR-B3/B6)', () {
    test('splits active and finished, enforces the 3-journey rule', () {
      final b = JourneyBuckets([
        testJourney(id: 'a'),
        testJourney(id: 'b', status: JourneyStatus.ended),
        testJourney(id: 'c'),
        testJourney(id: 'd', status: JourneyStatus.archived),
      ]);
      expect(b.active.map((j) => j.id), ['a', 'c']);
      expect(b.finished.map((j) => j.id), ['b', 'd']);
      expect(b.canCreate, isTrue);
      expect(
        JourneyBuckets([for (final id in 'xyz'.split('')) testJourney(id: id)])
            .canCreate,
        isFalse,
      );
    });
  });

  group('JourneyForm (FR-B1/B2/B7)', () {
    JourneyForm form(TemplateId id, [String lang = 'vi']) =>
        JourneyForm.fromTemplate(
          templateFor(id),
          languageCode: lang,
          timezone: testTz,
        );

    test('weight loss hides the metric and blurs shares by default', () {
      final f = form(TemplateId.weightLoss);
      expect(f.title, 'Giảm cân');
      expect(f.trackMetric, isTrue);
      expect(f.metricUnit, 'kg');
      expect(f.hideMetric, isTrue);
      expect(f.blurOnShare, isTrue);
      final draft = f.toDraft(startDate: testToday);
      expect(draft.hideMetricDefault, isTrue);
      expect(draft.templateId, TemplateId.weightLoss);
      expect(draft.visibility, JourneyVisibility.private);
      expect(draft.timezone, testTz);
    });

    test('other templates do not blur and use their own defaults', () {
      final english = form(TemplateId.englishDaily, 'en');
      expect(english.title, 'Daily English');
      expect(english.blurOnShare, isFalse);
      expect(english.hideMetric, isFalse);
      final workout = form(TemplateId.workout30);
      expect(workout.trackMetric, isFalse);
      expect(workout.durationDays, 30);
      expect(workout.allowOpenEnded, isFalse);
      final trip = form(TemplateId.travel);
      expect(trip.durationDays, 7);
      expect(trip.allowOpenEnded, isTrue);
      expect(form(TemplateId.custom).title, isEmpty);
    });

    test('validation uses ourney_core rules', () {
      final f = form(TemplateId.custom);
      expect(f.validate().title, JourneyTitleError.empty);
      f.title = 'x' * (journeyTitleMax + 1);
      expect(f.validate().title, JourneyTitleError.tooLong);
      f
        ..title = 'Đọc sách'
        ..durationDays = 3;
      expect(f.validate().duration, DurationError.outOfRange);
      f.durationDays = null; // open-ended is valid
      expect(f.validate().isValid, isTrue);
      f
        ..trackMetric = true
        ..metricName = '  ';
      expect(f.validate().isValid, isFalse);
    });

    test('group journeys always use group visibility', () {
      final f = form(TemplateId.workout30)
        ..soloVisibility = JourneyVisibility.link
        ..kind = JourneyKind.group;
      expect(f.visibility, JourneyVisibility.group);
      expect(f.validate().visibility, isNull);
    });
  });
}
