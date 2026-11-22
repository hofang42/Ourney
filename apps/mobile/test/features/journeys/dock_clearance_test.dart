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
}
