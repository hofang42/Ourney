import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/app_routes.dart';
import 'package:ourney/app/config.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/features/journeys/data/journeys_providers.dart';
import 'package:ourney/features/journeys/domain/journey_progress.dart';
import 'package:ourney/features/journeys/journeys_paths.dart';
import 'package:ourney/features/journeys/ui/timeline_grid.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/test_helpers.dart';
import 'journeys_fakes.dart';

Finder _key(String k) => find.byKey(ValueKey(k));

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

DayState _cellState(WidgetTester tester, LocalDate d) => tester
    .widget<DayCell>(
      find.descendant(
        of: find.byKey(const ValueKey('journey-timeline')),
        matching: find.byWidgetPredicate(
          (w) => w is DayCell && w.day.date == d,
        ),
      ),
    )
    .state;

/// Solo 14-day journey started 2026-10-10; today is 10-16 (day 7).
/// Checked in 10, 11, 13, 14, 15; missed 12; today still open.
Future<JourneysHarness> _pumpDetail(
  WidgetTester tester, {
  Journey? journey,
  Membership? membership,
  FakeJourneyRepository? repo,
  String? userId,
  bool backend = false,
}) {
  final j = journey ?? testJourney();
  final dates = [10, 11, 13, 14, 15].map((d) => LocalDate(2026, 10, d));
  return pumpJourneys(
    tester,
    locale: const Locale('en'),
    location: AppRoutes.journey(j.id),
    config: backend ? testBackendConfig : const AppConfig.localOnly(),
    userId: userId,
    journeys:
        repo ??
        FakeJourneyRepository(
          journeys: [j],
          memberships: {j.id: membership ?? testMembership(j)},
        ),
    checkIns: FakeCheckInRepository([
      for (final d in dates)
        d.day == 15
            ? testCheckIn(j.id, d, caption: 'weighed', metricValue: 71.5)
            : testCheckIn(j.id, d, caption: 'cap $d'),
    ]),
  );
}

void main() {
  group('Journey detail (FR-B4/B5)', () {
    testWidgets('stats: current/longest streak, % complete, day N/M', (
      tester,
    ) async {
      await _pumpDetail(tester);
      expect(_key('journey-detail'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Current streak: Streak of 3 days'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Longest: 3 days'), findsOneWidget);
      // 5 of 14 days.
      expect(find.bySemanticsLabel('Complete: 36%'), findsOneWidget);
      expect(find.bySemanticsLabel('Progress: Day 7 of 14'), findsOneWidget);
    });

    testWidgets('timeline grid: checked, missed, today, future', (
      tester,
    ) async {
      await _pumpDetail(tester);
      expect(find.byType(DayCell), findsNWidgets(14));
      expect(
        _cellState(tester, const LocalDate(2026, 10, 10)),
        DayState.checkedIn,
      );
      expect(
        _cellState(tester, const LocalDate(2026, 10, 12)),
        DayState.missed,
      );
      expect(_cellState(tester, testToday), DayState.today);
      expect(
        _cellState(tester, const LocalDate(2026, 10, 17)),
        DayState.future,
      );
      expect(
        _cellState(tester, const LocalDate(2026, 10, 23)),
        DayState.future,
      );
      expect(_key('journey-today-ring'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp(r'^Day 3, .*: missed$')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          RegExp(r'^Day 7, .*: today, not checked in yet$'),
        ),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(RegExp(r': checked in$')), findsNWidgets(5));
    });

    testWidgets('open-ended journeys show day N without a percentage', (
      tester,
    ) async {
      await _pumpDetail(
        tester,
        // `custom` keeps the day grid (the Minimalist persona still shows
        // the shared grid); `travel` would draw the scrapbook thread.
        journey: testJourney(templateId: TemplateId.custom, durationDays: null),
      );
      expect(_key('stat-percent'), findsNothing);
      expect(find.bySemanticsLabel('Progress: Day 7'), findsOneWidget);
      // Start to today.
      expect(find.byType(DayCell), findsNWidgets(7));
    });

    testWidgets('tapping a day opens the photo viewer; hidden metric', (
      tester,
    ) async {
      final j = testJourney(
        templateId: TemplateId.weightLoss,
        metricName: 'Weight',
        metricUnit: 'kg',
        hideMetricDefault: true,
      );
      final h = await _pumpDetail(
        tester,
        journey: j,
        membership: testMembership(j, hideMetric: true),
      );
      final cell = find.byWidgetPredicate(
        (w) => w is DayCell && w.day.date == const LocalDate(2026, 10, 15),
      );
      await _tap(tester, cell);
      expect(
        h.location,
        JourneysPaths.day('j1', const LocalDate(2026, 10, 15)),
      );
      expect(_key('journey-day-viewer'), findsOneWidget);
      expect(find.text('weighed'), findsOneWidget);
      expect(find.text('Hidden'), findsOneWidget);
      expect(find.textContaining('71.5'), findsNothing);

      await _tap(tester, _key('journey-day-reveal'));
      expect(find.text('71.5 kg'), findsOneWidget);
    });

    testWidgets('missed and future days are not tappable', (tester) async {
      final h = await _pumpDetail(tester);
      await _tap(
        tester,
        find.byWidgetPredicate(
          (w) => w is DayCell && w.day.date == const LocalDate(2026, 10, 12),
        ),
      );
      expect(h.location, AppRoutes.journey('j1'));
    });
  });

  group('Journey actions (FR-B6)', () {
    testWidgets('check in now opens the camera for this journey', (
      tester,
    ) async {
      final h = await _pumpDetail(tester);
      await _tap(tester, _key('journey-checkin'));
      expect(h.location, '/capture?journeyId=j1');
      expect(
        h.container
            .read(sharedPreferencesProvider)
            .getString(lastJourneyPrefsKey),
        'j1',
      );
    });

    testWidgets('share opens the share card route', (tester) async {
      final h = await _pumpDetail(tester);
      await _tap(tester, _key('journey-share'));
      expect(h.location, AppRoutes.share('j1'));
    });

    testWidgets('end makes the journey read-only, then archive', (
      tester,
    ) async {
      final h = await _pumpDetail(tester);
      expect(_key('journey-read-only'), findsNothing);

      await _tap(tester, _key('journey-more'));
      expect(_key('journey-action-archive'), findsNothing);
      await _tap(tester, _key('journey-action-end'));
      expect(find.text('End this journey?'), findsOneWidget);
      await _tap(tester, _key('journeys-confirm'));

      expect(h.journeys.calls, contains('end:j1'));
      expect(_key('journey-read-only'), findsOneWidget);
      expect(_key('journey-checkin'), findsNothing);
      expect(_key('journey-pref-blur'), findsNothing);

      await _tap(tester, _key('journey-more'));
      expect(_key('journey-action-end'), findsNothing);
      await _tap(tester, _key('journey-action-archive'));
      expect(h.journeys.calls, contains('archive:j1'));
      expect(h.location, AppRoutes.journeys);
      expect(find.text('Archived'), findsOneWidget);
    });

    testWidgets('cancelling end does nothing', (tester) async {
      final h = await _pumpDetail(tester);
      await _tap(tester, _key('journey-more'));
      await _tap(tester, _key('journey-action-end'));
      await _tap(tester, find.text('Cancel'));
      expect(h.journeys.calls, isEmpty);
    });

    testWidgets('delete removes the journey and returns to the list', (
      tester,
    ) async {
      final h = await _pumpDetail(tester);
      await _tap(tester, _key('journey-more'));
      await _tap(tester, _key('journey-action-delete'));
      expect(find.text('Delete this journey?'), findsOneWidget);
      await _tap(tester, _key('journeys-confirm'));
      expect(h.journeys.calls, ['delete:j1']);
      expect(h.journeys.journeys, isEmpty);
      expect(h.location, AppRoutes.journeys);
      expect(_key('journeys-empty'), findsOneWidget);
    });

    testWidgets('delete with other members maps not_alone', (tester) async {
      final j = testJourney(kind: JourneyKind.group);
      final repo = FakeJourneyRepository(
        journeys: [j],
        memberships: {j.id: testMembership(j)},
      )..deleteError = const OurneyException(OurneyErrorCode.notAlone);
      final h = await _pumpDetail(
        tester,
        journey: j,
        repo: repo,
        backend: true,
        userId: 'u1',
      );
      await _tap(tester, _key('journey-more'));
      await _tap(tester, _key('journey-action-delete'));
      await _tap(tester, _key('journeys-confirm'));
      expect(
        find.text(
          'Other members are still in the group, so it can\'t be deleted. '
          'You can end the journey instead.',
        ),
        findsOneWidget,
      );
      expect(h.location, AppRoutes.journey('j1'));
    });

    testWidgets('group member: no owner actions; open group button', (
      tester,
    ) async {
      final j = testJourney(kind: JourneyKind.group, ownerId: 'owner');
      final h = await _pumpDetail(
        tester,
        journey: j,
        membership: testMembership(j, userId: 'u1'),
        backend: true,
        userId: 'u1',
      );
      expect(_key('journey-more'), findsNothing);
      expect(_key('journey-checkin'), findsOneWidget);
      expect(_key('journey-timeline'), findsOneWidget);
      await _tap(tester, _key('journey-open-group'));
      expect(h.location, AppRoutes.groups);
    });

    testWidgets('privacy switches update my membership (FR-B7)', (
      tester,
    ) async {
      final j = testJourney(metricName: 'Weight', metricUnit: 'kg');
      final h = await _pumpDetail(tester, journey: j);
      await _tap(tester, _key('journey-pref-hide-metric'));
      await _tap(tester, _key('journey-pref-blur'));
      expect(h.journeys.prefUpdates, [
        (id: 'j1', hideMetric: true, blurMedia: null),
        (id: 'j1', hideMetric: null, blurMedia: true),
      ]);
    });

    testWidgets('unknown journey shows not found', (tester) async {
      await pumpJourneys(
        tester,
        locale: const Locale('en'),
        location: AppRoutes.journey('missing'),
      );
      expect(_key('journey-detail-empty'), findsOneWidget);
      expect(find.text('Journey not found.'), findsOneWidget);
    });
  });
}
