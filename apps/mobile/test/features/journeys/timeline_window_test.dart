import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/features/journeys/data/long_timeline_state.dart';
import 'package:ourney/features/journeys/domain/journey_progress.dart';
import 'package:ourney/features/journeys/domain/timeline_window.dart';
import 'package:ourney/features/journeys/ui/widgets/timeline_archive.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/test_helpers.dart';
import 'journeys_fakes.dart';

TimelineIndex _index({
  required int elapsed,
  int? duration,
  int perDay = 1,
  bool Function(int dayIndex)? skip,
}) {
  final j = testJourney(
    startDate: testToday.addDays(1 - elapsed),
    durationDays: duration,
    templateId: TemplateId.custom,
  );
  final cis = [
    for (var d = 0; d < elapsed; d++)
      if (!(skip?.call(d) ?? false))
        for (var k = 0; k < perDay; k++)
          testCheckIn(j.id, j.startDate.addDays(d), hour: 2 + k),
  ];
  return TimelineIndex.build(
    JourneyProgress.compute(
      journey: j,
      membership: testMembership(j),
      checkIns: cis,
      now: testNow,
    ),
  );
}

void main() {
  test('downsample keeps first, last, min and max within the limit', () {
    final v = [for (var i = 0; i < 1000; i++) (i * 37 % 101).toDouble()];
    v[400] = -50;
    v[777] = 500;
    final d = downsample(v);
    expect(d.length, lessThanOrEqualTo(maxCurvePoints));
    expect(d.first, v.first);
    expect(d.last, v.last);
    expect(d.reduce((a, b) => a < b ? a : b), -50);
    expect(d.reduce((a, b) => a > b ? a : b), 500);
    final short = [1.0, 2.0, 3.0];
    expect(downsample(short), same(short));
  });

  test('365-day journey: months, totals and window', () {
    final i = _index(elapsed: 365, duration: 365, perDay: 3);
    expect(i.isLong, isTrue);
    expect(i.months.length, 13);
    expect(i.months.first.firstDayNumber, 1);
    expect(i.months.last.isCurrent, isTrue);
    expect(i.months.map((m) => m.days).reduce((a, b) => a + b), 365);
    expect(i.summary.done, 365);
    expect(i.summary.frames, 365 * 3);
    expect(i.summary.pace.length, lessThanOrEqualTo(maxCurvePoints));
    expect(i.months.every((m) => m.covers.length == 3), isTrue);
    final w = i.recent;
    expect(w.days.first.dayNumber, 365 - 13);
    expect(w.days.length, 14); // today is the last day: no upcoming days
    expect(w.earlierDays, 351);
    expect(w.earlierChecked, 351);
    expect(w.hasEndCap, isFalse);
    expect(w.earlierMonthId, monthIdOf(w.days.first.date.addDays(-1)));
  });

  test('fixed journey in progress has upcoming days and an end cap', () {
    final j = testJourney(
      startDate: testToday.addDays(-99),
      durationDays: 365,
      templateId: TemplateId.custom,
    );
    final i = TimelineIndex.build(
      JourneyProgress.compute(
        journey: j,
        membership: testMembership(j),
        checkIns: const [],
        now: testNow,
      ),
    );
    expect(i.recent.days.length, 16);
    expect(i.recent.daysToGo, 265);
    expect(i.recent.finishDay, 365);
    expect(i.recent.hasEndCap, isTrue);
    expect(i.lastMissedDay, 99);
  });

  test('800-day open-ended journey', () {
    final i = _index(elapsed: 800, skip: (d) => d % 5 == 0);
    expect(i.months.length, greaterThanOrEqualTo(26));
    expect(i.recent.daysToGo, isNull);
    expect(i.recent.days.length, 16);
    expect(i.summary.done, 640);
    expect(i.summary.totalDays, 800);
    expect(i.summary.curve30, isNotNull);
  });

  test('journey that starts mid-month and week starts', () {
    final i = _index(elapsed: 40); // 2026-09-07 .. 2026-10-16
    expect(i.months.first.first, const LocalDate(2026, 9, 7));
    expect(i.months.first.days, 24);
    // Sep 7 2026 is a Monday: no blank cell before it on a Monday-first
    // grid, one (the Sunday) on a Sunday-first grid.
    expect(ArchiveGeometry.leading(i.months.first.first, 1), 0);
    expect(ArchiveGeometry.leading(i.months.first.first, 0), 1);
    expect(ArchiveGeometry.rowsOf(i.months.first, 1), 4);
    // Minimal window: the month of today (day 16 > 7).
    expect(i.recentMinimal.days.first.date, const LocalDate(2026, 10, 1));
  });

  test('minimal window includes the previous month in the first week', () {
    final j = testJourney(
      startDate: const LocalDate(2026, 8, 1),
      durationDays: null,
      templateId: TemplateId.custom,
    );
    final i = TimelineIndex.build(
      JourneyProgress.compute(
        journey: j,
        membership: testMembership(j),
        checkIns: const [],
        now: DateTime.utc(2026, 10, 3, 5),
      ),
    );
    expect(i.recentMinimal.days.first.date, const LocalDate(2026, 9, 1));
  });

  test('a 30-day journey that ended 10 days ago keeps the short layout', () {
    final j = testJourney(
      startDate: testToday.addDays(-39),
      durationDays: 30,
      templateId: TemplateId.custom,
    );
    final p = JourneyProgress.compute(
      journey: j,
      membership: testMembership(j),
      checkIns: const [],
      now: testNow,
    );
    expect(p.elapsedDays, 30);
    final i = TimelineIndex.build(p);
    expect(i.isLong, isFalse);
    expect(i.lastMissedDay, 30);
    expect(i.months.last.last, j.endDate);
  });

  test('a 365-day journey that ended stops at its last day', () {
    final j = testJourney(
      startDate: testToday.addDays(-399),
      durationDays: 365,
      templateId: TemplateId.custom,
    );
    final p = JourneyProgress.compute(
      journey: j,
      membership: testMembership(j),
      checkIns: const [],
      now: testNow,
    );
    final i = TimelineIndex.build(p);
    expect(p.elapsedDays, 365);
    expect(i.isLong, isTrue);
    // 35 days past the end: no month after the end, none is "today".
    expect(i.months.last.last, j.endDate);
    expect(i.months.last.isCurrent, isTrue);
    expect(i.months.map((m) => m.days).reduce((a, b) => a + b), 365);
    expect(i.lastMissedDay, 365);
    expect(i.recent.days.last.date, j.endDate);
    expect(i.recent.hasEndCap, isFalse);
  });

  test('fixed journey, day 5 of 365: elapsed days + 2 + end cap', () {
    final i = _index(elapsed: 5, duration: 365);
    expect(i.isLong, isFalse);
    expect(i.shortWindow.days.length, 7);
    expect(i.shortWindow.earlierDays, 0);
    expect(i.shortWindow.daysToGo, 360);
    expect(i.shortWindow.hasEndCap, isTrue);
    expect(i.summary.curve30, isNull);
  });

  test('journey tz: today follows the journey zone, not the device', () {
    final j = Journey(
      id: 'j',
      ownerId: 'u1',
      kind: JourneyKind.solo,
      templateId: TemplateId.custom,
      title: 't',
      emoji: 'x',
      startDate: const LocalDate(2026, 8, 1),
      timezone: 'America/Los_Angeles',
      visibility: defaultVisibilityFor(JourneyKind.solo),
      status: JourneyStatus.active,
    );
    final p = JourneyProgress.compute(
      journey: j,
      membership: null,
      checkIns: const [],
      now: testNow, // 05:00 UTC: still Oct 15 in Los Angeles
    );
    expect(p.today, const LocalDate(2026, 10, 15));
    expect(TimelineIndex.build(p).recent.days.firstWhere((d) => d.isToday).date,
        const LocalDate(2026, 10, 15));
  });

  test('long-timeline choices: default month follows the calendar', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final n = c.read(longTimelineProvider('a').notifier);
    expect(c.read(longTimelineProvider('a')).open, isNull);
    n.toggleMonth(5, current: 9);
    expect(c.read(longTimelineProvider('a')).open, {9, 5});
    n.toggleMonth(9, current: 9);
    expect(c.read(longTimelineProvider('a')).open, {5});
    expect(c.read(longTimelineProvider('b')).open, isNull);
    n.setChipYear(2025);
    n.setChipYear(null);
    expect(c.read(longTimelineProvider('a')).chipYear, isNull);
  });

  test('fixed journey that has not started: days 1-3 and the end cap', () {
    final j = testJourney(
      startDate: testToday.addDays(5),
      durationDays: 365,
      templateId: TemplateId.custom,
    );
    final i = TimelineIndex.build(
      JourneyProgress.compute(
        journey: j,
        membership: testMembership(j),
        checkIns: const [],
        now: testNow,
      ),
    );
    expect(i.isLong, isFalse);
    expect(i.months, isEmpty);
    expect(i.shortWindow.days.map((d) => d.dayNumber), [1, 2, 3]);
    expect(i.shortWindow.hasEndCap, isTrue);
    expect(i.shortWindow.daysToGo, 369);
    expect(i.shortWindow.startsIn, 5);
    expect(i.shortWindow.finishDay, 365);
  });

  test('journey ended early stops at its last check-in, no upcoming days', () {
    final j = testJourney(
      startDate: testToday.addDays(-99),
      durationDays: 365,
      templateId: TemplateId.custom,
      status: JourneyStatus.ended,
    );
    final last = j.startDate.addDays(59);
    final p = JourneyProgress.compute(
      journey: j,
      membership: testMembership(j),
      checkIns: [
        for (var d = 0; d < 60; d++)
          testCheckIn(j.id, j.startDate.addDays(d)),
      ],
      now: testNow,
    );
    expect(p.lastDay, last);
    expect(p.elapsedDays, 60);
    final i = TimelineIndex.build(p);
    expect(i.months.last.last, last);
    expect(i.lastMissedDay, isNull);
    expect(i.recent.days.last.date, last);
    expect(i.recent.hasEndCap, isFalse);
    expect(i.recent.daysToGo, isNull);
  });

  test('ended journey with no check-in stops at its start day', () {
    for (final duration in [365, null]) {
      final j = testJourney(
        startDate: testToday.addDays(-99),
        durationDays: duration,
        templateId: TemplateId.custom,
        status: JourneyStatus.ended,
      );
      final p = JourneyProgress.compute(
        journey: j,
        membership: testMembership(j),
        checkIns: const [],
        now: testNow,
      );
      expect(p.lastDay, j.startDate, reason: '$duration');
      expect(p.elapsedDays, 1);
      final i = TimelineIndex.build(p);
      expect(i.isLong, isFalse);
      expect(i.months.length, 1);
      expect(i.months.single.days, 1);
      // Day 1 itself was never checked in, and nothing after it counts.
      expect(i.lastMissedDay, 1);
      expect(i.shortWindow.hasEndCap, isFalse);
    }
  });

  test('timeline choices reset when the account changes', () async {
    final auth = FakeAuthRepository(userId: 'u1');
    final c = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(testBackendConfig),
        authRepositoryProvider.overrideWithValue(auth),
      ],
    );
    addTearDown(c.dispose);
    c.listen(longTimelineProvider('a'), (_, _) {});
    c.read(longTimelineProvider('a').notifier)
      ..setMode(LongTimelineMode.month)
      ..setChipYear(2025);
    expect(c.read(longTimelineProvider('a')).mode, LongTimelineMode.month);
    auth.emit('u2');
    await Future<void>.delayed(Duration.zero);
    final s = c.read(longTimelineProvider('a'));
    expect(s.mode, LongTimelineMode.recent);
    expect(s.chipYear, isNull);
  });

  test('ended journey: timeline length stops at its last day', () {
    for (final duration in [200, null]) {
      final j = testJourney(
        startDate: testToday.addDays(-99),
        durationDays: duration,
        templateId: TemplateId.custom,
        status: JourneyStatus.ended,
      );
      final p = JourneyProgress.compute(
        journey: j,
        membership: testMembership(j),
        checkIns: [
          for (var d = 0; d < 60; d++)
            testCheckIn(j.id, j.startDate.addDays(d)),
        ],
        now: testNow,
      );
      final i = TimelineIndex.build(p);
      expect(i.timelineLength, 60, reason: '$duration');
      expect(i.summary.totalDays, 60);
      expect(p.timeline().length, 60);
    }
  });

  test('short journeys are not long', () {
    expect(_index(elapsed: 31).isLong, isFalse);
    expect(_index(elapsed: 32).isLong, isTrue);
  });
}