import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/features/journeys/domain/journey_progress.dart';
import 'package:ourney/features/journeys/domain/run_stats.dart';
import 'package:ourney/features/journeys/l10n/generated/journeys_localizations.dart';
import 'package:ourney/features/journeys/ui/widgets/photo_log_timelines.dart';
import 'package:ourney/ui/ui.dart';
import 'package:ourney_core/ourney_core.dart';

import 'journeys_fakes.dart';

const _width = 320.0;
const _locale = Locale('en');
const _timeout = Timeout(Duration(seconds: 15));

Future<void> _pumpBars(
  WidgetTester tester, {
  required int dayCount,
  required List<int> daysWithRuns,
  required ValueChanged<TimelineDay> onTap,
}) async {
  final journey = testJourney(
    startDate: testToday.addDays(1 - dayCount),
    durationDays: dayCount,
  );
  final progress = JourneyProgress.compute(
    journey: journey,
    membership: testMembership(journey),
    now: testNow,
    checkIns: [
      for (final day in daysWithRuns)
        testCheckIn(
          journey.id,
          journey.startDate.addDays(day - 1),
          extras: const CheckInExtras(km: 4),
        ),
    ],
  );
  await tester.pumpWidget(
    MaterialApp(
      locale: _locale,
      localizationsDelegates: JourneysL10n.localizationsDelegates,
      supportedLocales: JourneysL10n.supportedLocales,
      theme: OurneyTheme.build(Brightness.light),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: _width,
            child: RunKmBars(
              stats: RunStats.from(progress.timeline()),
              totalDays: dayCount,
              onTapDay: onTap,
            ),
          ),
        ),
      ),
    ),
  );
}

Finder get _plot => find.descendant(
  of: find.byType(RunKmBars),
  matching: find.byType(CustomPaint),
);

Finder _weekLabel(int week) =>
    find.text(lookupJourneysL10n(_locale).journeys_weekLabel(week));

void main() {
  testWidgets('daily week labels align with the partial week boundary', (
    tester,
  ) async {
    await _pumpBars(tester, dayCount: 10, daysWithRuns: [2, 8], onTap: (_) {});
    final plot = tester.getRect(_plot);
    expect(tester.getTopLeft(_weekLabel(1)).dx, plot.left);
    expect(tester.getTopLeft(_weekLabel(2)).dx, closeTo(plot.left + 224, .01));
  }, timeout: _timeout);

  testWidgets('tapping gaps in the daily plot opens the nearest run', (
    tester,
  ) async {
    final tapped = <int>[];
    await _pumpBars(
      tester,
      dayCount: 10,
      daysWithRuns: [2, 8],
      onTap: (day) => tapped.add(day.dayNumber),
    );
    final plot = tester.getRect(_plot);
    await tester.tapAt(Offset(plot.left + plot.width * .35, plot.top + 1));
    await tester.tapAt(Offset(plot.left + plot.width * .60, plot.bottom - 1));
    expect(tapped, [2, 8]);
  }, timeout: _timeout);

  testWidgets('weekly labels have room and gap taps open the nearest week', (
    tester,
  ) async {
    final tapped = <int>[];
    await _pumpBars(
      tester,
      dayCount: 120,
      daysWithRuns: [2, 6, 117],
      onTap: (day) => tapped.add(day.dayNumber),
    );
    final plot = tester.getRect(_plot);
    expect(tester.getSize(_weekLabel(1)).width, greaterThan(64));
    expect(_weekLabel(2), findsNothing);
    expect(
      tester.getTopLeft(_weekLabel(5)).dx,
      closeTo(plot.left + 4 / 18 * _width, .01),
    );
    await tester.tapAt(Offset(plot.left + plot.width * .25, plot.center.dy));
    await tester.tapAt(Offset(plot.left + plot.width * .65, plot.center.dy));
    expect(tapped, [6, 117]);
  }, timeout: _timeout);
}
