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

    testWidgets('empty card focuses the code field', (tester) async {
      await pumpGroups(tester);
      expect(find.byKey(const ValueKey('groups-empty')), findsOneWidget);
      expect(find.text('no squads yet.'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('groups-empty-enter-code')));
      await tester.pump();
      final field = tester.widget<TextField>(
        find.byKey(const ValueKey('squad-join-field')),
      );
      expect(field.focusNode!.hasFocus, isTrue);
    });

    testWidgets('each group shows once, solo journeys never', (tester) async {
      final h = await pumpGroups(
        tester,
        journeys: FakeJourneyRepository(
          journeys: [
            groupJourney(),
            groupJourney(id: 'solo', title: 'Solo one', kind: JourneyKind.solo),
          ],
        ),
      );
      expect(find.byKey(const ValueKey('squad-today-g1')), findsOneWidget);
      expect(find.text('Chạy bộ cùng nhau'), findsOneWidget);
      expect(find.text('Solo one'), findsNothing);
      expect(find.byKey(const ValueKey('groups-create')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('squad-today-open-g1')));
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
