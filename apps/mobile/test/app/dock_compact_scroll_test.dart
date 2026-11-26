import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney/app/app_dock.dart';
import 'package:ourney/app/app_shell.dart';
import 'package:ourney/app/router.dart';
import 'package:ourney/ui/components/dock.dart';
import 'package:ourney/ui/components/glass.dart';

import '../features/journeys/journeys_fakes.dart';

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
      'threshold edges (p <= 40, |dy| <= 1, post-fling animateTo), tab switch, '
      'camera morph from compact (52 -> 76), and intra-branch push/pop reset',
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

        // 1. Threshold edge: user drag down that stays at pixels <= 40 does NOT compact.
        await tester.drag(list, const Offset(0, -30));
        await tester.pumpAndSettle();
        expect(scrollableState.position.pixels, lessThanOrEqualTo(40));
        expect(
          tester.widget<AppDock>(find.byType(AppDock)).compact,
          isFalse,
          reason: 'pixels <= 40 must not compact',
        );

        // Return to top.
        scrollableState.position.jumpTo(0);
        await tester.pumpAndSettle();

        // 2. Programmatic animateTo(300) does NOT compact the dock.
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

        // Return to top.
        scrollableState.position.jumpTo(0);
        await tester.pumpAndSettle();

        // 3. Post-fling animateTo: after a user drag ends (ScrollEndNotification),
        // a programmatic animateTo must not compact (proving _userScrolling cleared).
        await tester.drag(list, const Offset(0, -200));
        await tester.pumpAndSettle();
        expect(tester.widget<AppDock>(find.byType(AppDock)).compact, isTrue);

        // Expand via upward drag, ending at a mid-scroll offset (> 40).
        await tester.drag(list, const Offset(0, 60));
        await tester.pumpAndSettle();
        expect(tester.widget<AppDock>(find.byType(AppDock)).compact, isFalse);
        expect(scrollableState.position.pixels, greaterThan(40));

        // Now run a programmatic downward animateTo(350): must stay expanded!
        final future2 = scrollableState.position.animateTo(
          350,
          duration: const Duration(milliseconds: 150),
          curve: Curves.linear,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 160));
        await future2;
        await tester.pumpAndSettle();
        expect(
          tester.widget<AppDock>(find.byType(AppDock)).compact,
          isFalse,
          reason: 'post-gesture programmatic animateTo must not compact',
        );

        // 4. Compact via user drag down, then push intra-branch sub-route (/journey/j1) -> resets to expanded.
        await tester.drag(list, const Offset(0, -150));
        await tester.pumpAndSettle();
        expect(tester.widget<AppDock>(find.byType(AppDock)).compact, isTrue);

        unawaited(
          h.container.read(routerProvider).push(AppRoutes.journey('j1')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        expect(h.location, AppRoutes.journey('j1'));
        expect(
          tester.widget<AppDock>(find.byType(AppDock)).compact,
          isFalse,
          reason: 'pushing a sub-route inside a branch must expand the dock',
        );

        // Pop back to /journeys -> stays expanded.
        h.container.read(routerProvider).pop();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        expect(h.location, AppRoutes.journeys);
        expect(tester.widget<AppDock>(find.byType(AppDock)).compact, isFalse);

        // 5. Compact on Journeys, switch tab -> resets to expanded.
        await tester.drag(list, const Offset(0, -200));
        await tester.pumpAndSettle();
        expect(tester.widget<AppDock>(find.byType(AppDock)).compact, isTrue);

        await tester.tap(find.byKey(const ValueKey('dock-groups')));
        await tester.pumpAndSettle();
        expect(h.location, AppRoutes.groups);
        expect(
          tester.widget<AppDock>(find.byType(AppDock)).compact,
          isFalse,
          reason: 'switching tab must reset dock to expanded',
        );

        // 6. Switch back to Journeys, compact again (camera circle = 52dp), and
        // tap camera -> morphs from 52dp (not 60dp!) to 76dp shutter, then returns expanded.
        await tester.tap(find.byKey(const ValueKey('dock-journeys')));
        await tester.pumpAndSettle();
        await tester.drag(list, const Offset(0, -200));
        await tester.pumpAndSettle();
        expect(tester.widget<AppDock>(find.byType(AppDock)).compact, isTrue);

        await tester.tap(find.byKey(const ValueKey('dock-snap-pill')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));
        final morphFinder = find.byKey(const ValueKey('dock-center-morph'));
        expect(morphFinder, findsOneWidget);
        final earlyMorphWidth = tester.getSize(morphFinder).width;
        expect(
          earlyMorphWidth,
          greaterThan(52.0),
          reason: 'compact -> camera morph starts at 52dp',
        );
        expect(
          earlyMorphWidth,
          lessThan(60.0),
          reason: 'compact -> camera morph must not jump to 60dp at t=16ms',
        );
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

    testWidgets(
      'real horizontal Scrollable, real nested vertical Scrollable (depth > 0), '
      'and short vertical Scrollable (maxScrollExtent < 56) never compact AppDock',
      (tester) async {
        final router = GoRouter(
          initialLocation: '/journeys',
          routes: [
            StatefulShellRoute(
              builder: (context, state, shell) =>
                  AppShell(navigationShell: shell),
              navigatorContainerBuilder: (context, shell, children) =>
                  UiShellBranchContainer(
                    currentIndex: shell.currentIndex,
                    children: children,
                  ),
              branches: [
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/journeys',
                      builder: (context, state) => SingleChildScrollView(
                        key: const ValueKey('outer-short-vertical'),
                        child: Column(
                          children: [
                            // 40dp overflow (< 56dp threshold) on outer depth-0 vertical scroll
                            SizedBox(
                              height: 120,
                              child: ListView.builder(
                                key: const ValueKey('real-horizontal-list'),
                                scrollDirection: Axis.horizontal,
                                itemCount: 30,
                                itemBuilder: (_, i) =>
                                    SizedBox(width: 80, child: Text('H$i')),
                              ),
                            ),
                            SizedBox(
                              height: 300,
                              child: ListView.builder(
                                key: const ValueKey('real-nested-vertical'),
                                itemCount: 40,
                                itemBuilder: (_, i) =>
                                    SizedBox(height: 50, child: Text('V$i')),
                              ),
                            ),
                            const SizedBox(height: 410),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                for (var b = 1; b < 5; b++)
                  StatefulShellBranch(
                    routes: [
                      GoRoute(
                        path: '/b$b',
                        builder: (_, _) => const SizedBox.expand(),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        );
        addTearDown(router.dispose);

        await pumpJourneys(
          tester,
          extraOverrides: [routerProvider.overrideWithValue(router)],
        );
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 800);
        await tester.pumpAndSettle();

        // 1. Drag real horizontal ListView -> must not compact.
        await tester.drag(
          find.byKey(const ValueKey('real-horizontal-list')),
          const Offset(-250, 0),
        );
        await tester.pumpAndSettle();
        expect(
          tester.widget<AppDock>(find.byType(AppDock)).compact,
          isFalse,
          reason: 'real horizontal Scrollable drag must not compact AppDock',
        );

        // 2. Drag real nested vertical ListView (depth == 1 under outer SingleChildScrollView) -> must not compact.
        await tester.drag(
          find.byKey(const ValueKey('real-nested-vertical')),
          const Offset(0, -250),
        );
        await tester.pumpAndSettle();
        expect(
          tester.widget<AppDock>(find.byType(AppDock)).compact,
          isFalse,
          reason: 'real nested vertical Scrollable (depth 1) must not compact',
        );

        // 3. Drag outer depth-0 SingleChildScrollView whose maxScrollExtent is 30 (< 56) -> must not compact.
        await tester.drag(
          find.byKey(const ValueKey('outer-short-vertical')),
          const Offset(0, -100),
        );
        await tester.pumpAndSettle();
        expect(
          tester.widget<AppDock>(find.byType(AppDock)).compact,
          isFalse,
          reason: 'short vertical Scrollable (extent < 56) must not compact',
        );
      },
    );
  });
}
