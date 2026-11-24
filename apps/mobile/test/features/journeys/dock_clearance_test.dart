import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/ui/components/dock.dart';

import 'journeys_fakes.dart';

void main() {
  for (final (w, h, s) in [
    (320.0, 568.0, 1.35),
    (320.0, 640.0, 1.35),
    (360.0, 640.0, 1.35),
    (320.0, 640.0, 2.0),
  ]) {
    testWidgets('empty hub scrolls clear of the dock at ${w}dp x$s', (
      tester,
    ) async {
      await pumpJourneys(tester);
      tester.view.physicalSize = Size(w, h);
      tester.platformDispatcher.textScaleFactorTestValue = s;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();

      final scrollable = find.descendant(
        of: find.byKey(const ValueKey('journeys-list')),
        matching: find.byType(Scrollable),
      );
      await tester.drag(scrollable.first, const Offset(0, -2000));
      await tester.pumpAndSettle();

      final dockTop = tester.getTopLeft(find.byType(UiDock)).dy;
      final content = tester.getRect(
        find.byKey(const ValueKey('journeys-empty')),
      );
      expect(
        content.bottom,
        lessThanOrEqualTo(dockTop + 0.5),
        reason: 'last content line must end above the dock',
      );
    });
  }

  for (final (w, h, s) in [(320.0, 640.0, 1.35), (360.0, 640.0, 1.0)]) {
    testWidgets('populated hub scrolls its last card clear of the dock '
        '(${w}dp x$s)', (tester) async {
      final js = [
        for (var i = 1; i <= 8; i++)
          testJourney(id: 'j$i', title: 'Hành trình số $i'),
      ];
      await pumpJourneys(
        tester,
        journeys: FakeJourneyRepository(
          journeys: js,
          memberships: {for (final j in js) j.id: testMembership(j)},
        ),
      );
      tester.view.physicalSize = Size(w, h);
      tester.platformDispatcher.textScaleFactorTestValue = s;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();

      final scrollable = find
          .descendant(
            of: find.byKey(const ValueKey('journeys-list')),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.drag(scrollable, const Offset(0, -20000));
      await tester.pumpAndSettle();

      final dockTop = tester.getTopLeft(find.byType(UiDock)).dy;
      final last = tester.getRect(
        find.byKey(const ValueKey('journey-card-j8')),
      );
      expect(last.bottom, lessThanOrEqualTo(dockTop + 0.5));
      expect(
        tester.getRect(scrollable).bottom,
        greaterThan(last.bottom),
        reason: 'the last card is fully scrolled into view',
      );
    });
  }
}
