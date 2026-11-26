import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/app_dock.dart';
import 'package:ourney/app/router.dart';
import 'package:ourney/ui/components/dock.dart';
import 'package:ourney/ui/components/glass.dart';

import '../features/journeys/journeys_fakes.dart';

class _NestedScrollUpdateNotification extends ScrollUpdateNotification {
  _NestedScrollUpdateNotification({
    required super.metrics,
    required super.context,
    super.scrollDelta,
    super.dragDetails,
  });

  @override
  int get depth => 1;
}

void main() {
  group('T8 — Shell Scroll Compact Trigger', () {
    for (final w in [360.0, 390.0]) {
      testWidgets(
        'scroll down >40 compacts, scroll up / top expands, tab switch resets, '
        'and UiDock top dy remains constant at W=${w.toInt()}',
        (tester) async {
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
          // Re-enable normal animations and set phone viewport size.
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(w, 800);
          await tester.pumpAndSettle();

          final list = find
              .descendant(
                of: find.byKey(const ValueKey('journeys-list')),
                matching: find.byType(Scrollable),
              )
              .first;

          final initialDockTop = tester.getTopLeft(find.byType(UiDock)).dy;
          final initialIslandBottom = tester
              .getRect(find.byType(UiGlass).first)
              .bottom;
          expect(tester.widget<AppDock>(find.byType(AppDock)).compact, isFalse);

          // 1. Drag down (-200) -> compact == true, labels opacity 0 after 300ms
          await tester.drag(list, const Offset(0, -200));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          expect(tester.widget<AppDock>(find.byType(AppDock)).compact, isTrue);
          expect(
            tester.getTopLeft(find.byType(UiDock)).dy,
            closeTo(initialDockTop, 0.01),
            reason: 'UiDock box top dy never changes on compact',
          );
          expect(
            tester.getRect(find.byType(UiGlass).first).bottom,
            closeTo(initialIslandBottom, 0.01),
            reason: 'Island bottom edge never moves on compact',
          );
          expect(
            tester.getRect(find.byType(UiGlass).first).height,
            closeTo(52, 0.5),
          );

          final opacities = tester
              .widgetList<Opacity>(
                find.descendant(
                  of: find.byType(UiDock),
                  matching: find.byType(Opacity),
                ),
              )
              .toList();
          expect(opacities, hasLength(4));
          for (final op in opacities) {
            expect(op.opacity, 0.0);
          }

          // 2. Drag up (+30) -> compact == false
          await tester.drag(list, const Offset(0, 30));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.widget<AppDock>(find.byType(AppDock)).compact, isFalse);
          expect(
            tester.getRect(find.byType(UiGlass).first).height,
            closeTo(64, 0.5),
          );
          expect(
            tester.getTopLeft(find.byType(UiDock)).dy,
            closeTo(initialDockTop, 0.01),
          );

          // 3. Drag down again (-200) -> compact == true
          await tester.drag(list, const Offset(0, -200));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.widget<AppDock>(find.byType(AppDock)).compact, isTrue);

          // 4. Drag to top (+5000) -> compact == false
          await tester.drag(list, const Offset(0, 5000));
          await tester.pumpAndSettle();
          expect(tester.widget<AppDock>(find.byType(AppDock)).compact, isFalse);
          expect(
            tester.getTopLeft(find.byType(UiDock)).dy,
            closeTo(initialDockTop, 0.01),
          );
        },
      );
    }

    testWidgets(
      'programmatic animateTo, horizontal scrollables, and nested (depth > 0) '
      'scrollables do not compact the dock; tab switching resets to expanded',
      (tester) async {
        final js = [
          for (var i = 1; i <= 8; i++)
            testJourney(id: 'j$i', title: 'Hành trình số $i'),
        ];
        final h = await pumpJourneys(
          tester,
          journeys: FakeJourneyRepository(
            journeys: js,
            memberships: {for (final j in js) j.id: testMembership(j)},
          ),
        );
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 800);
        await tester.pumpAndSettle();

        final list = find
            .descendant(
              of: find.byKey(const ValueKey('journeys-list')),
              matching: find.byType(Scrollable),
            )
            .first;
        final scrollableState = tester.state<ScrollableState>(list);

        // 1. Programmatic animateTo(300) does NOT compact the dock.
        final future = scrollableState.position.animateTo(
          300,
          duration: const Duration(milliseconds: 200),
          curve: Curves.linear,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.widget<AppDock>(find.byType(AppDock)).compact, isFalse);
        await tester.pump(const Duration(milliseconds: 150));
        await future;
        expect(scrollableState.position.pixels, closeTo(300, 0.5));
        expect(
          tester.widget<AppDock>(find.byType(AppDock)).compact,
          isFalse,
          reason: 'programmatic animateTo must not compact',
        );

        // Return to top
        scrollableState.position.jumpTo(0);
        await tester.pumpAndSettle();

        // 2. Horizontal scroll notifications (Axis.horizontal, depth 0) and
        // nested vertical scroll notifications (Axis.vertical, depth 1) are ignored.
        final listContext = tester.element(list);
        final horizMetrics = FixedScrollMetrics(
          minScrollExtent: 0,
          maxScrollExtent: 500,
          pixels: 120,
          viewportDimension: 390,
          axisDirection: AxisDirection.right,
          devicePixelRatio: 1,
        );
        UserScrollNotification(
          metrics: horizMetrics,
          context: listContext,
          direction: ScrollDirection.reverse,
        ).dispatch(listContext);
        ScrollUpdateNotification(
          metrics: horizMetrics,
          context: listContext,
          scrollDelta: 40,
          dragDetails: DragUpdateDetails(
            globalPosition: const Offset(100, 400),
            delta: const Offset(-40, 0),
            primaryDelta: -40,
          ),
        ).dispatch(listContext);
        await tester.pump();
        expect(
          tester.widget<AppDock>(find.byType(AppDock)).compact,
          isFalse,
          reason: 'horizontal scroll must be ignored',
        );

        final vertMetrics = FixedScrollMetrics(
          minScrollExtent: 0,
          maxScrollExtent: 500,
          pixels: 120,
          viewportDimension: 400,
          axisDirection: AxisDirection.down,
          devicePixelRatio: 1,
        );
        final nestedUpdate = _NestedScrollUpdateNotification(
          metrics: vertMetrics,
          context: listContext,
          scrollDelta: 40,
          dragDetails: DragUpdateDetails(
            globalPosition: const Offset(100, 400),
            delta: const Offset(0, -40),
            primaryDelta: -40,
          ),
        );
        nestedUpdate.dispatch(listContext);
        await tester.pump();
        expect(
          tester.widget<AppDock>(find.byType(AppDock)).compact,
          isFalse,
          reason: 'nested depth > 0 scroll must be ignored',
        );

        // 3. Overscroll / iOS bounce (pixels > maxScrollExtent or < minScrollExtent) is ignored.
        final overscrollMetrics = FixedScrollMetrics(
          minScrollExtent: 0,
          maxScrollExtent: 500,
          pixels: 520,
          viewportDimension: 400,
          axisDirection: AxisDirection.down,
          devicePixelRatio: 1,
        );
        ScrollUpdateNotification(
          metrics: overscrollMetrics,
          context: listContext,
          scrollDelta: 20,
          dragDetails: DragUpdateDetails(
            globalPosition: const Offset(100, 400),
            delta: const Offset(0, -20),
            primaryDelta: -20,
          ),
        ).dispatch(listContext);
        await tester.pump();
        expect(
          tester.widget<AppDock>(find.byType(AppDock)).compact,
          isFalse,
          reason: 'overscroll must be ignored',
        );

        // 4. Compact via user drag down, then switch tab -> resets to expanded.
        await tester.drag(list, const Offset(0, -200));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.widget<AppDock>(find.byType(AppDock)).compact, isTrue);

        await tester.tap(find.byKey(const ValueKey('dock-groups')));
        await tester.pumpAndSettle();
        expect(h.location, AppRoutes.groups);
        expect(
          tester.widget<AppDock>(find.byType(AppDock)).compact,
          isFalse,
          reason: 'switching tab must reset dock to expanded',
        );

        // Switch back to Journeys, compact again, and navigate to camera -> resets when returning.
        await tester.tap(find.byKey(const ValueKey('dock-journeys')));
        await tester.pumpAndSettle();
        await tester.drag(list, const Offset(0, -200));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.widget<AppDock>(find.byType(AppDock)).compact, isTrue);

        await tester.tap(find.byKey(const ValueKey('dock-snap-pill')));
        await tester.pumpAndSettle();
        expect(h.location, AppRoutes.capture);

        await h.go(tester, AppRoutes.journeys);
        expect(
          tester.widget<AppDock>(find.byType(AppDock)).compact,
          isFalse,
          reason: 'returning from camera route must be expanded',
        );
      },
    );
  });
}
