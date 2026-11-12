import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/app_routes.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/features/journeys/ui/journey_chain.dart';
import 'package:ourney/features/journeys/ui/today_sheet.dart';
import 'package:ourney/ui/ui.dart';
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

/// Hub widgets of the V1.0 rebuild that the other journey tests only touch
/// in passing: Today sheet, shelf albums, style-painted detail.
void main() {
  group('Today sheet', () {
    testWidgets('lists journeys by urgency and opens the camera', (
      tester,
    ) async {
      final j = testJourney();
      final h = await pumpJourneys(
        tester,
        locale: const Locale('en'),
        journeys: FakeJourneyRepository(
          journeys: [j],
          memberships: {j.id: testMembership(j)},
        ),
        checkIns: FakeCheckInRepository([
          for (final d in [13, 14, 15])
            testCheckIn(j.id, LocalDate(2026, 10, d)),
        ]),
      );
      unawaited(showTodaySheet(tester.element(_key('journeys-list'))));
      await tester.pumpAndSettle();

      expect(_key('today-sheet'), findsOneWidget);
      expect(find.text('1 left'), findsOneWidget);
      expect(find.text('At risk'), findsOneWidget);
      await _tap(tester, _key('today-row-j1'));
      expect(h.location, '/capture?journeyId=j1');
    });

    testWidgets('all done: offers adding more', (tester) async {
      final j = testJourney();
      await pumpJourneys(
        tester,
        locale: const Locale('en'),
        journeys: FakeJourneyRepository(
          journeys: [j],
          memberships: {j.id: testMembership(j)},
        ),
        checkIns: FakeCheckInRepository([testCheckIn(j.id, testToday)]),
      );
      unawaited(showTodaySheet(tester.element(_key('journeys-list'))));
      await tester.pumpAndSettle();
      expect(find.text('All done for today'), findsWidgets);
      expect(find.text('Add more'), findsOneWidget);
    });
  });

  group('Hub', () {
    testWidgets('all journeys posted today: all-done row, no Today card', (
      tester,
    ) async {
      final j = testJourney();
      await pumpJourneys(
        tester,
        locale: const Locale('en'),
        journeys: FakeJourneyRepository(
          journeys: [j],
          memberships: {j.id: testMembership(j)},
        ),
        checkIns: FakeCheckInRepository([testCheckIn(j.id, testToday)]),
      );
      expect(_key('journeys-all-done'), findsOneWidget);
      expect(_key('journeys-today-j1'), findsNothing);
      expect(
        find.text('Nothing left for today. See you tomorrow.'),
        findsOneWidget,
      );
    });

    testWidgets('Snap today on the Today card opens the camera', (
      tester,
    ) async {
      final j = testJourney();
      final h = await pumpJourneys(
        tester,
        locale: const Locale('en'),
        journeys: FakeJourneyRepository(
          journeys: [j],
          memberships: {j.id: testMembership(j)},
        ),
      );
      await _tap(tester, _key('journeys-snap-today'));
      expect(h.location, '/capture?journeyId=j1');
      expect(h.container.read(activeJourneyIdProvider), 'j1');
    });

    testWidgets('shelf with a server shows the retell tile and albums', (
      tester,
    ) async {
      final ended = testJourney(id: 'e1', status: JourneyStatus.ended);
      await pumpJourneys(
        tester,
        config: testBackendConfig,
        userId: 'u1',
        locale: const Locale('en'),
        journeys: FakeJourneyRepository(
          journeys: [ended],
          memberships: {ended.id: testMembership(ended)},
        ),
      );
      await _tap(tester, _key('hub-segment-shelf'));
      expect(_key('journeys-retell'), findsOneWidget);
      expect(_key('journey-card-e1'), findsOneWidget);
      expect(
        find.text('Completed journeys, kept like albums.'),
        findsOneWidget,
      );
    });

    testWidgets('local-only shelf hides retell', (tester) async {
      final ended = testJourney(id: 'e1', status: JourneyStatus.ended);
      await pumpJourneys(
        tester,
        locale: const Locale('en'),
        journeys: FakeJourneyRepository(journeys: [ended]),
      );
      await _tap(tester, _key('hub-segment-shelf'));
      expect(_key('journeys-retell'), findsNothing);
    });
  });

  group('Detail style', () {
    testWidgets('opening a journey makes it the active one', (tester) async {
      final other = testJourney(id: 'other', templateId: TemplateId.weightLoss);
      final trip = testJourney(id: 'trip', templateId: TemplateId.travel);
      final h = await pumpJourneys(
        tester,
        locale: const Locale('en'),
        location: AppRoutes.journey(trip.id),
        journeys: FakeJourneyRepository(
          journeys: [other, trip],
          memberships: {trip.id: testMembership(trip)},
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(h.container.read(activeJourneyIdProvider), 'trip');
    });

    for (final t in [TemplateId.travel, TemplateId.weightLoss]) {
      testWidgets('${t.wireName} draws the chain calendar', (tester) async {
        final j = testJourney(templateId: t);
        await pumpJourneys(
          tester,
          locale: const Locale('en'),
          location: AppRoutes.journey(j.id),
          journeys: FakeJourneyRepository(
            journeys: [j],
            memberships: {j.id: testMembership(j)},
          ),
        );
        expect(find.byType(JourneyChain), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('large text does not overflow the detail screen', (
      tester,
    ) async {
      final j = testJourney(title: 'Một hành trình có cái tên rất dài để thử');
      await pumpJourneys(
        tester,
        location: AppRoutes.journey(j.id),
        journeys: FakeJourneyRepository(
          journeys: [j],
          memberships: {j.id: testMembership(j)},
        ),
      );
      tester.platformDispatcher.textScaleFactorTestValue = 1.35;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(UiScaffold), findsWidgets);
    });
  });
}
