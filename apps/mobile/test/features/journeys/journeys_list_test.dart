import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/app_routes.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/ui/ui.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/test_helpers.dart';
import '../sharing/sharing_fakes.dart' show FakeSharingRepository;
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

      expect(find.text('Active · 2'), findsOneWidget);
      expect(find.text('Shelf'), findsOneWidget);
      expect(find.byKey(const ValueKey('journey-card-j1')), findsOneWidget);
      // j1 (14 days) is a V2 journey card; the open-ended one a compact row.
      expect(find.byType(UiJourneyCard), findsOneWidget);
      expect(find.text('Day 7 of 14'), findsOneWidget);
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

    testWidgets(
      '/journeys?segment=shared opens the Hub on the Shared segment and re-selects after switching to Active (DE-18)',
      (tester) async {
        final j = testJourney();
        final h = await pumpJourneys(
          tester,
          config: testBackendConfig,
          userId: 'u1',
          locale: const Locale('en'),
          location: '${AppRoutes.journeys}?segment=shared',
          journeys: FakeJourneyRepository(
            journeys: [j],
            memberships: {j.id: testMembership(j)},
          ),
          extraOverrides: [
            sharingRepositoryProvider.overrideWithValue(
              FakeSharingRepository(),
            ),
          ],
        );
        expect(
          find.byKey(const ValueKey('shared-with-me-empty')),
          findsOneWidget,
        );

        // Switching manually to Active clears `?segment=shared` so a second
        // navigation to `/journeys?segment=shared` from Inbox re-selects Shared.
        await tester.tap(find.byKey(const ValueKey('hub-segment-active')));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('journey-card-j1')), findsOneWidget);
        expect(h.location, AppRoutes.journeys);

        await h.go(tester, '${AppRoutes.journeys}?segment=shared');
        expect(
          find.byKey(const ValueKey('shared-with-me-empty')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'zero-own-journeys user with shared journeys keeps Shared segment and segmented bar (DE-18)',
      (tester) async {
        const friend = PersonSummary(
          userId: 'u2',
          username: 'nam',
          displayName: 'Nam Tran',
        );
        final shared = SharedJourneySummary(
          journeyId: 'sh1',
          title: 'Da Lat Trip',
          emoji: '✈️',
          templateId: TemplateId.travel,
          kind: JourneyKind.solo,
          origin: JourneyOrigin.live,
          status: JourneyStatus.active,
          owner: friend,
          sharedBy: friend,
          sharedAt: DateTime.utc(2026, 10, 15),
          photoCount: 1,
          unseen: false,
          saved: false,
        );
        await pumpJourneys(
          tester,
          config: testBackendConfig,
          userId: 'u1',
          locale: const Locale('en'),
          journeys: FakeJourneyRepository(),
          extraOverrides: [
            sharingRepositoryProvider.overrideWithValue(
              FakeSharingRepository(sharedWithMe: [shared]),
            ),
          ],
        );
        expect(find.byKey(const ValueKey('journeys-empty')), findsNothing);
        expect(find.byKey(const ValueKey('shared-row-sh1')), findsOneWidget);

        // Switching to Active · 0 keeps the segmented bar so Shared remains reachable.
        await tester.ensureVisible(
          find.byKey(const ValueKey('hub-segment-active')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('hub-segment-active')));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('journeys-empty')), findsNothing);
        expect(find.byKey(const ValueKey('hub-segment-shared')), findsOneWidget);

        await tester.ensureVisible(
          find.byKey(const ValueKey('hub-segment-shared')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('hub-segment-shared')));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('shared-row-sh1')), findsOneWidget);
      },
    );

    testWidgets('no cap: 3 running journeys still open create (FR-B3)', (
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
      // Count only, no "x/3" cap (bug 3).
      expect(find.text('Active · 3'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('hub-segment-shelf')));
      await tester.pumpAndSettle();
      expect(find.text('Archived'), findsOneWidget);

      await _addJourney(tester);
      expect(h.location, AppRoutes.journeyNew);
    });

    testWidgets('add menu floats over the hub without reflowing it (bug 1)', (
      tester,
    ) async {
      await pumpJourneys(
        tester,
        journeys: FakeJourneyRepository(journeys: [testJourney()]),
      );
      final greeting = find.byKey(const ValueKey('hub-greeting'));
      final before = tester.getTopLeft(greeting);
      await tester.tap(find.byKey(const ValueKey('journeys-new')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('journeys-menu-new')), findsOneWidget);
      expect(tester.getTopLeft(greeting), before);

      await tester.tap(find.byKey(const ValueKey('ui-menu-barrier')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('journeys-menu-new')), findsNothing);
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

    testWidgets('expired fixed-term journey is ended: no Today card (B-B7)', (
      tester,
    ) async {
      // 7 days from 10-01 ended 10-07; the fake clock is 10-16.
      final j = testJourney(
        startDate: const LocalDate(2026, 10, 1),
        durationDays: 7,
      );
      final repo = FakeJourneyRepository(
        journeys: [j],
        memberships: {j.id: testMembership(j)},
      );
      await pumpJourneys(tester, locale: const Locale('en'), journeys: repo);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('journeys-today-j1')), findsNothing);
      // Nothing runs, so the hub opens on the shelf, where it now sits.
      expect(find.byKey(const ValueKey('journey-card-j1')), findsOneWidget);
      // The owner's app closes it in the repository.
      expect(repo.calls, contains('end:j1'));
    });

    testWidgets('archived journeys can be restored from the shelf (U12)', (
      tester,
    ) async {
      final j = testJourney(status: JourneyStatus.ended);
      final other = testJourney(id: 'j2', durationDays: null);
      final repo = FakeJourneyRepository(
        journeys: [j, other],
        memberships: {j.id: testMembership(j), other.id: testMembership(other)},
      );
      await repo.archive(j.id);
      await pumpJourneys(tester, locale: const Locale('en'), journeys: repo);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('hub-segment-shelf')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('shelf-archived-title')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('unarchive-j1')));
      await tester.pumpAndSettle();
      expect(repo.calls, contains('unarchive:j1'));
      expect(find.byKey(const ValueKey('shelf-archived-title')), findsNothing);
      expect(find.byKey(const ValueKey('journey-card-j1')), findsOneWidget);
    });

    testWidgets('only archived journeys: the shelf opens, not Day Zero (U12)', (
      tester,
    ) async {
      final j = testJourney(status: JourneyStatus.ended);
      final repo = FakeJourneyRepository(
        journeys: [j],
        memberships: {j.id: testMembership(j)},
      );
      await repo.archive(j.id);
      await pumpJourneys(tester, locale: const Locale('en'), journeys: repo);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('journeys-empty')), findsNothing);
      expect(
        find.byKey(const ValueKey('shelf-archived-title')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('unarchive-j1')));
      await tester.pumpAndSettle();
      expect(repo.calls, contains('unarchive:j1'));
    });

    testWidgets('inside the 3 day upload grace the RPC is not called (B-B7)', (
      tester,
    ) async {
      // 14 days from 10-01 ended 10-14; the fake clock is 10-16: shown ended,
      // but the server still takes late uploads until 10-17.
      final j = testJourney(
        startDate: const LocalDate(2026, 10, 1),
        durationDays: 14,
      );
      final repo = FakeJourneyRepository(
        journeys: [j],
        memberships: {j.id: testMembership(j)},
      );
      await pumpJourneys(tester, locale: const Locale('en'), journeys: repo);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('journeys-today-j1')), findsNothing);
      expect(repo.calls, isNot(contains('end:j1')));
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
