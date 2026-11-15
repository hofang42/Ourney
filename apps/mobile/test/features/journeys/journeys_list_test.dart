import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/app_routes.dart';
import 'package:ourney/ui/ui.dart';
import 'package:ourney_core/ourney_core.dart';

import 'journeys_fakes.dart';

/// Repository whose streams fail like the A3 placeholders (not wired yet).
class _NotWiredJourneyRepository extends FakeJourneyRepository {
  @override
  Stream<List<Journey>> watchActive() => Stream.error(UnimplementedError());
}

class _FailingJourneyRepository extends FakeJourneyRepository {
  @override
  Stream<List<Journey>> watchActive() =>
      Stream.error(const OurneyException(OurneyErrorCode.offline));
}

/// The hub's + opens the add menu; "New journey" starts the create flow.
Future<void> _addJourney(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('journeys-new')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('journeys-menu-new')));
  await tester.pumpAndSettle();
}

void main() {
  group('Journeys tab (FR-B3/B6)', () {
    testWidgets('day-zero hub offers creating the first journey', (
      tester,
    ) async {
      final h = await pumpJourneys(tester, locale: const Locale('en'));

      expect(find.byKey(const ValueKey('journeys-empty')), findsOneWidget);
      expect(find.text('Start your first journey'), findsOneWidget);
      expect(find.byKey(const ValueKey('journeys-new')), findsNothing);

      await tester.tap(find.text('Start your first journey'));
      await tester.pumpAndSettle();
      expect(h.location, AppRoutes.journeyNew);
      expect(
        find.byKey(const ValueKey('journeys-template-picker')),
        findsOneWidget,
      );
    });

    testWidgets('rows show day N/M and today status; Today card; shelf', (
      tester,
    ) async {
      final active = testJourney();
      final open = testJourney(
        id: 'j2',
        title: 'Đọc sách',
        templateId: TemplateId.travel,
        durationDays: null,
      );
      final ended = testJourney(
        id: 'j3',
        title: 'Old one',
        status: JourneyStatus.ended,
      );
      await pumpJourneys(
        tester,
        locale: const Locale('en'),
        journeys: FakeJourneyRepository(
          journeys: [active, open, ended],
          memberships: {
            for (final j in [active, open, ended]) j.id: testMembership(j),
          },
        ),
        checkIns: FakeCheckInRepository([
          testCheckIn('j1', const LocalDate(2026, 10, 15)),
          testCheckIn('j1', testToday),
        ]),
      );

      expect(find.text('Active · 2/3'), findsOneWidget);
      expect(find.text('Shelf'), findsOneWidget);
      expect(find.byKey(const ValueKey('journey-card-j1')), findsOneWidget);
      // j1 (14 days) is a V2 journey card; the open-ended one a compact row.
      expect(find.byType(UiJourneyCard), findsOneWidget);
      expect(find.text('Ngày 7/14'), findsOneWidget);
      expect(find.textContaining('· Day 7'), findsOneWidget); // open j2
      expect(find.text('Not yet'), findsOneWidget);
      expect(find.byType(UiStreakHero), findsOneWidget);
      // Profile and inbox moved to dock tabs.
      expect(find.byKey(const ValueKey('profile-entry')), findsNothing);
      // j2 has no photo today: it leads the Today card.
      expect(find.byKey(const ValueKey('journeys-today-j2')), findsOneWidget);
      expect(find.text("1 journey still needs today's photo."), findsOneWidget);
      expect(find.byKey(const ValueKey('journeys-new')), findsOneWidget);

      // Ended journeys live on the shelf.
      expect(find.byKey(const ValueKey('journey-card-j3')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('hub-segment-shelf')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('journey-card-j3')), findsOneWidget);
      expect(find.text('Ended'), findsOneWidget);
    });

    testWidgets('tapping a card opens the journey', (tester) async {
      final j = testJourney();
      final h = await pumpJourneys(
        tester,
        journeys: FakeJourneyRepository(
          journeys: [j],
          memberships: {j.id: testMembership(j)},
        ),
      );
      await tester.tap(find.byKey(const ValueKey('journey-card-j1')));
      await tester.pumpAndSettle();
      expect(h.location, AppRoutes.journey('j1'));
      expect(find.byKey(const ValueKey('journey-detail')), findsOneWidget);
    });

    testWidgets('3 active journeys: FAB shows the limit dialog (FR-B3)', (
      tester,
    ) async {
      final journeys = [
        for (var i = 1; i <= 3; i++) testJourney(id: 'j$i', title: 'J$i'),
        testJourney(id: 'old', status: JourneyStatus.archived),
      ];
      final h = await pumpJourneys(
        tester,
        locale: const Locale('en'),
        journeys: FakeJourneyRepository(journeys: journeys),
      );
      expect(find.text('Active · 3/3'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('hub-segment-shelf')));
      await tester.pumpAndSettle();
      expect(find.text('Archived'), findsOneWidget);

      await _addJourney(tester);

      expect(
        find.byKey(const ValueKey('journeys-limit-dialog')),
        findsOneWidget,
      );
      expect(find.text('You have 3 journeys running'), findsOneWidget);
      expect(h.location, AppRoutes.journeys);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('journeys-limit-dialog')), findsNothing);
    });

    testWidgets('ended journeys do not count toward the limit', (tester) async {
      final journeys = [
        for (var i = 1; i <= 2; i++) testJourney(id: 'j$i'),
        testJourney(id: 'e', status: JourneyStatus.ended),
      ];
      final h = await pumpJourneys(
        tester,
        journeys: FakeJourneyRepository(journeys: journeys),
      );
      await _addJourney(tester);
      expect(h.location, AppRoutes.journeyNew);
    });

    testWidgets('data layer not wired: placeholder instead of a crash', (
      tester,
    ) async {
      await pumpJourneys(tester, journeys: _NotWiredJourneyRepository());
      expect(
        find.byKey(const ValueKey('placeholder-journeys')),
        findsOneWidget,
      );
    });

    testWidgets('load error shows a mapped message and retry', (tester) async {
      await pumpJourneys(
        tester,
        locale: const Locale('en'),
        journeys: _FailingJourneyRepository(),
      );
      expect(find.byKey(const ValueKey('journeys-error')), findsOneWidget);
      expect(find.text('could not load. try again?'), findsOneWidget);
      // An offline failure uses the offline state card.
      final card = tester.widget<UiStateCard>(
        find.byKey(const ValueKey('journeys-error')),
      );
      expect(card.kind, UiStateCardKind.offline);
    });

    testWidgets('hero is done once every journey has a photo today', (
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
      final hero = tester.widget<UiStreakHero>(find.byType(UiStreakHero));
      expect(hero.state, UiStreakHeroState.done);
      expect(find.byKey(const ValueKey('journeys-all-done')), findsOneWidget);
      final card = tester.widget<UiJourneyCard>(find.byType(UiJourneyCard));
      expect(card.todayDone, isTrue);
    });
  });
}
