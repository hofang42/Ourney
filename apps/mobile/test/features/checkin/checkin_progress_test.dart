import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/features/checkin/captured_photo.dart';
import 'package:ourney/features/checkin/checkin_controller.dart';
import 'package:ourney/features/checkin/checkin_progress.dart';
import 'package:ourney_core/ourney_core.dart';

import 'fakes.dart';

void main() {
  final clock = FakeCheckinClock();

  StreakSummary streak(Journey j, Iterable<LocalDate> dates, {Membership? m}) =>
      memberStreak(
        journey: j,
        membership: m,
        today: testToday,
        dates: dates,
        clock: clock,
      );

  /// Milestone for checking in today on top of [daysBefore] consecutive days.
  Milestone? afterRun(Journey j, int daysBefore, {bool replaced = false}) {
    final before = [
      for (var i = 1; i <= daysBefore; i++) testToday.addDays(-i),
    ];
    return detectMilestone(
      journey: j,
      before: streak(j, before),
      after: streak(j, [...before, testToday]),
      replaced: replaced,
    );
  }

  group('detectMilestone (FR-C8)', () {
    final open = testJourney(start: testToday.addDays(-60), durationDays: null);

    test('7 and 30 day streaks', () {
      expect(afterRun(open, 5), isNull);
      expect(afterRun(open, 6), Milestone.sevenDays);
      expect(afterRun(open, 7), isNull);
      expect(afterRun(open, 29), Milestone.thirtyDays);
      expect(afterRun(open, 30), isNull);
    });

    test('first check-in is not a milestone', () {
      expect(afterRun(open, 0), isNull);
    });

    test('replacing today never celebrates again', () {
      expect(afterRun(open, 6, replaced: true), isNull);
    });

    test('completing every day of a fixed journey', () {
      final j = testJourney(start: testToday.addDays(-9), durationDays: 10);
      expect(afterRun(j, 9), Milestone.completed);
      // Gaps: the last day alone is not the finish line.
      final before = [testToday.addDays(-9), testToday.addDays(-5)];
      expect(
        detectMilestone(
          journey: j,
          before: streak(j, before),
          after: streak(j, [...before, testToday]),
          replaced: false,
        ),
        isNull,
      );
    });

    test('a journey completed earlier does not celebrate again', () {
      // 7-day journey finished yesterday; checking in past the end date.
      final j = testJourney(start: testToday.addDays(-7), durationDays: 7);
      expect(afterRun(j, 7), isNull);
    });

    test('finish wins over a 7-day streak', () {
      final j = testJourney(start: testToday.addDays(-6), durationDays: 7);
      expect(afterRun(j, 6), Milestone.completed);
    });

    test('late joiner counts from the join date', () {
      final j = testJourney(start: testToday.addDays(-20), durationDays: null);
      final joined = Membership(
        journeyId: 'j1',
        userId: 'me',
        role: MemberRole.member,
        status: MemberStatus.active,
        // 2026-10-13 10:00 at +07:00.
        joinedAt: DateTime.utc(2026, 10, 13, 3),
      );
      final dates = [for (var i = 0; i <= 10; i++) testToday.addDays(-i)];
      expect(streak(j, dates, m: joined).current, 4);
      expect(streak(j, dates).current, 11);
    });
  });

  group('CheckInPoster', () {
    late FakeCheckInRepository repo;
    late FakePhotoCompressor compressor;
    late CheckInPoster poster;
    final journey = testJourney();

    setUp(() {
      repo = FakeCheckInRepository();
      compressor = FakePhotoCompressor();
      poster = CheckInPoster(
        repository: repo,
        compressor: compressor,
        clock: clock,
      );
    });

    test('day uses the journey timezone, not UTC', () {
      // 2026-10-15 18:30 UTC is already 2026-10-16 01:30 at +07:00.
      final late = CapturedPhoto(
        journeyId: 'j1',
        path: '/x.jpg',
        capturedAt: DateTime.utc(2026, 10, 15, 18, 30),
      );
      expect(poster.dayOf(journey, late), testToday);
      expect(
        poster.replacesExisting(journey, late, [testCheckIn(testToday)]),
        isTrue,
      );
      expect(
        poster.replacesExisting(journey, late, [
          testCheckIn(testToday.addDays(-1)),
        ]),
        isFalse,
      );
    });

    test('post compresses, submits and reports streak +1', () async {
      final outcome = await poster.post(
        journey: journey,
        membership: null,
        photo: CapturedPhoto(
          journeyId: 'j1',
          path: '/x.jpg',
          capturedAt: testNowUtc,
        ),
        mine: [testCheckIn(testToday.addDays(-1))],
        caption: 'hi',
        metricValue: 3,
      );
      expect(compressor.sources, ['/x.jpg']);
      final draft = repo.submitted.single;
      expect(draft.photoFile, '/x.jpg.1080.jpg');
      expect(draft.thumbFile, '/x.jpg.thumb.jpg');
      expect(draft.caption, 'hi');
      expect(draft.metricValue, 3);
      expect(outcome.streakBefore, 1);
      expect(outcome.streakAfter, 2);
      expect(outcome.replaced, isFalse);
      expect(outcome.milestone, isNull);
    });

    test('maps repository errors', () async {
      repo.submitError = const OurneyException(OurneyErrorCode.ended);
      final photo = CapturedPhoto(
        journeyId: 'j1',
        path: '/x.jpg',
        capturedAt: testNowUtc,
      );
      await expectLater(
        poster.post(journey: journey, membership: null, photo: photo, mine: []),
        throwsA(
          isA<CheckInPostException>().having(
            (e) => e.failure,
            'failure',
            CheckInFailure.ended,
          ),
        ),
      );
      repo.submitError = StateError('disk');
      await expectLater(
        poster.post(journey: journey, membership: null, photo: photo, mine: []),
        throwsA(
          isA<CheckInPostException>().having(
            (e) => e.failure,
            'failure',
            CheckInFailure.generic,
          ),
        ),
      );
    });
  });
}
