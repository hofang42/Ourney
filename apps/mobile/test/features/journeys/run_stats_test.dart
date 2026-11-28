import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/features/journeys/domain/journey_progress.dart';
import 'package:ourney/features/journeys/domain/run_stats.dart';
import 'package:ourney/features/journeys/domain/wrapped_story.dart';
import 'package:ourney/features/journeys/l10n/generated/journeys_localizations.dart';
import 'package:ourney/features/journeys/ui/wrapped/journey_wrapped_screen.dart';
import 'package:ourney_core/ourney_core.dart';

import 'journeys_fakes.dart';

void main() {
  final timeout = Timeout(const Duration(seconds: 15));
  JourneyProgress progress(
    List<CheckInExtras> extras, {
    int durationDays = 14,
  }) {
    final j = testJourney(durationDays: durationDays);
    return JourneyProgress.compute(
      journey: j,
      membership: testMembership(j),
      now: testNow,
      checkIns: [
        for (var i = 0; i < extras.length; i++)
          testCheckIn(j.id, j.startDate.addDays(i), extras: extras[i]),
      ],
    );
  }

  test('weights pace by distance and uses the average in wrapped', () {
    final p = progress([
      const CheckInExtras(km: 2, pace: '5:00'),
      const CheckInExtras(km: 6, pace: '6:00'),
      const CheckInExtras(pace: '1:00'),
      const CheckInExtras(km: 4),
    ]);
    final s = RunStats.from(p.timeline());
    expect(s.totalKm, 12);
    expect(s.runs, 4);
    expect(s.avgPaceSec, 345);
    expect(s.maxKm, 6);
    expect(WrappedStats.from(p).pace, '5:45');
  }, timeout: timeout);
  test('zero or one paced day and invalid pace are ignored', () {
    expect(RunStats.from([]).avgPaceSec, isNull);
    expect(
      RunStats.from(
        progress([
          const CheckInExtras(km: 2, pace: '5:00'),
          const CheckInExtras(km: 2, pace: '5:99'),
        ]).timeline(),
      ).avgPaceSec,
      isNull,
    );
    expect(formatPace(342), '5:42');
    for (final value in [
      null,
      '',
      '0:42',
      '00:42',
      '5:60',
      '-1:30',
      '3:2',
      'abc',
    ]) {
      expect(paceSeconds(value), isNull);
    }
    expect(paceSeconds('01:30'), 90);
  }, timeout: timeout);
  test('wrapped and timeline count the same valid distances in range', () {
    final p = progress([
      const CheckInExtras(km: 2),
      const CheckInExtras(km: -7),
      const CheckInExtras(km: double.nan),
      const CheckInExtras(km: double.infinity),
      const CheckInExtras(km: 0),
      const CheckInExtras(km: 100),
    ], durationDays: 5);
    final km = RunStats.from(p.timeline()).totalKm;
    expect(km, 2);
    expect(WrappedStats.from(p).totalKm, km);
  }, timeout: timeout);
  test('journey weeks and multiple check-ins sum by day', () {
    final j = testJourney();
    final p = JourneyProgress.compute(
      journey: j,
      membership: testMembership(j),
      now: testNow.add(const Duration(days: 2)),
      checkIns: [
        testCheckIn(j.id, j.startDate, extras: const CheckInExtras(km: 2)),
        testCheckIn(
          j.id,
          j.startDate,
          hour: 3,
          extras: const CheckInExtras(km: 3),
        ),
        testCheckIn(j.id, j.startDate.addDays(7)),
      ],
    );
    final s = RunStats.from(p.timeline());
    expect(s.runs, 2);
    expect(s.days.first.km, 5);
    expect(s.weeks.map((w) => w.number), [1, 2]);
  }, timeout: timeout);
  test('multiple check-ins weight each pace while counting a day once', () {
    final j = testJourney();
    final p = JourneyProgress.compute(
      journey: j,
      membership: testMembership(j),
      now: testNow,
      checkIns: [
        testCheckIn(
          j.id,
          j.startDate,
          hour: 1,
          extras: const CheckInExtras(km: 2, pace: '5:00'),
        ),
        testCheckIn(
          j.id,
          j.startDate,
          hour: 8,
          extras: const CheckInExtras(km: 3, pace: '6:00'),
        ),
        testCheckIn(
          j.id,
          j.startDate.addDays(1),
          extras: const CheckInExtras(km: 5, pace: '7:00'),
        ),
      ],
    );
    final stats = RunStats.from(p.timeline());
    expect(stats.runs, 2);
    expect(stats.totalKm, 10);
    expect(stats.avgPaceSec, 378);
    expect(WrappedStats.from(p).pace, '6:18');
  }, timeout: timeout);

  test('wrapped distance and weight captions use each locale decimal', () {
    const stats = WrappedStats(
      days: 3,
      moments: 3,
      total: 30,
      streak: 3,
      totalKm: 86.4,
      photos: [],
      lastCaption: null,
      lastPlace: null,
      pace: '5:42',
      weights: [74.2, 72.4],
    );
    for (final locale in ['vi', 'en']) {
      final l = lookupJourneysL10n(Locale(locale));
      final km = locale == 'vi' ? '86,4' : '86.4';
      final kg = locale == 'vi' ? '72,4 kg' : '72.4 kg';
      final run = testJourney();
      expect(
        wrappedBeatsFor(
          l,
          run,
          PersonaSkinId.aestheticFlexer,
          stats,
          localeName: locale,
        ).firstWhere((beat) => beat.id == 'signature').headline,
        contains(km),
      );
      expect(
        wrappedSummaryTitle(l, run, PersonaSkinId.aestheticFlexer, stats),
        contains(km),
      );
      expect(
        wrappedShareText(
          l,
          testJourney(templateId: TemplateId.weightLoss),
          PersonaSkinId.quietTransformer,
          stats,
          hideKg: false,
        ),
        contains(kg),
      );
    }
  }, timeout: timeout);

  test('run DNA and legacy unit share one classification', () {
    expect(isRunJourney(testJourney()), isTrue);
    expect(isRunJourney(testJourney(metricUnit: 'km')), isTrue);
    expect(isRunJourney(testJourney().copyWith(dna: {'sport': 'run'})), isTrue);
    expect(
      isRunJourney(testJourney().copyWith(dna: {'sport': 'gym'})),
      isFalse,
    );
    expect(isRunJourney(testJourney(metricUnit: 'kg')), isFalse);
    expect(
      isRunJourney(testJourney(templateId: TemplateId.weightLoss)),
      isFalse,
    );
  }, timeout: timeout);
}
