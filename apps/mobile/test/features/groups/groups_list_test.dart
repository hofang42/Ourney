import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/app_routes.dart';
import 'package:ourney/app/config.dart';
import 'package:ourney_core/ourney_core.dart';

import 'groups_fakes.dart';

class _NotWiredJourneys extends FakeJourneyRepository {
  @override
  Stream<List<Journey>> watchActive() => Stream.error(UnimplementedError());
}

void main() {
  group('Groups tab', () {
    testWidgets('local-only mode shows the needs-server state', (tester) async {
      await pumpGroups(tester, config: const AppConfig.localOnly());
      expect(find.byKey(const ValueKey('groups-list')), findsOneWidget);
      expect(find.byKey(const ValueKey('needs-server')), findsOneWidget);
    });

    testWidgets('local-only join and today screens need the server too', (
      tester,
    ) async {
      final h = await pumpGroups(tester, config: const AppConfig.localOnly());
      await h.go(tester, AppRoutes.join('ABCD1234'));
      expect(find.byKey(const ValueKey('needs-server')), findsOneWidget);
      await h.go(tester, '/groups/g1');
      expect(find.byKey(const ValueKey('needs-server')), findsOneWidget);
    });

    testWidgets('empty state offers joining with a code', (tester) async {
      final h = await pumpGroups(tester);
      expect(find.byKey(const ValueKey('groups-empty')), findsOneWidget);
      expect(find.text('No groups yet'), findsOneWidget);
      await tester.tap(find.text('Join with code'));
      await tester.pumpAndSettle();
      expect(h.location, '/join');
      expect(find.byKey(const ValueKey('groups-join-screen')), findsOneWidget);
    });

    testWidgets('lists only group journeys, running then finished', (
      tester,
    ) async {
      final h = await pumpGroups(
        tester,
        journeys: FakeJourneyRepository(
          journeys: [
            groupJourney(),
            groupJourney(id: 'solo', title: 'Solo one', kind: JourneyKind.solo),
            groupJourney(
              id: 'g2',
              title: 'Old group',
              status: JourneyStatus.ended,
            ),
          ],
        ),
      );
      expect(find.byKey(const ValueKey('group-card-g1')), findsOneWidget);
      expect(find.byKey(const ValueKey('group-card-g2')), findsOneWidget);
      expect(find.text('Solo one'), findsNothing);
      expect(find.text('Running'), findsOneWidget);
      expect(find.text('Finished'), findsOneWidget);
      expect(find.text('Day 7 of 30'), findsOneWidget);
      expect(find.text('Ended'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('group-card-g1')));
      await tester.pumpAndSettle();
      expect(h.location, '/groups/g1');
      expect(find.byKey(const ValueKey('group-today')), findsOneWidget);
    });

    testWidgets('data layer not wired: placeholder', (tester) async {
      await pumpGroups(tester, journeys: _NotWiredJourneys());
      expect(find.byKey(const ValueKey('placeholder-groups')), findsOneWidget);
    });
  });
}
