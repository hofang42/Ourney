import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney/app/theme/motion.dart';
import 'package:ourney/app/theme/tokens.dart';
import 'package:ourney/ui/ui.dart';

Widget _host(
  Widget child, {
  bool disableAnimations = false,
  Brightness brightness = Brightness.light,
}) {
  return MaterialApp(
    theme: OurneyTheme.build(brightness),
    themeAnimationDuration: disableAnimations
        ? Duration.zero
        : kThemeAnimationDuration,
    builder: (context, appChild) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        size: const Size(390, 844),
        disableAnimations: disableAnimations,
      ),
      child: appChild!,
    ),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('UiMotion, UiCurves, UiSprings, UiHeroTags & legacy aliases', () {
    test('duration scale, curves, springs and hero tags follow spec', () {
      expect(UiMotion.instant, Duration.zero);
      expect(UiMotion.micro, const Duration(milliseconds: 90));
      expect(UiMotion.press, const Duration(milliseconds: 110));
      expect(UiMotion.reducedFade, const Duration(milliseconds: 150));
      expect(UiMotion.fast, const Duration(milliseconds: 160));
      expect(UiMotion.normal, const Duration(milliseconds: 200));
      expect(UiMotion.medium, const Duration(milliseconds: 220));
      expect(UiMotion.sheetEnter, const Duration(milliseconds: 260));
      expect(UiMotion.sheetExit, const Duration(milliseconds: 190));
      expect(UiMotion.sheet, UiMotion.sheetEnter);
      expect(UiMotion.dockPill, const Duration(milliseconds: 280));
      expect(UiMotion.theme, const Duration(milliseconds: 320));
      expect(UiMotion.page, const Duration(milliseconds: 320));
      expect(UiMotion.countRoll, const Duration(milliseconds: 520));
      expect(UiMotion.stamp, const Duration(milliseconds: 540));
      expect(UiMotion.celebration, const Duration(milliseconds: 700));
      expect(UiMotion.develop, const Duration(milliseconds: 1100));
      expect(UiMotion.confetti, const Duration(milliseconds: 1600));
      expect(UiMotion.pressScale, 0.96);
      expect(UiMotion.popMinScale, 0.95);

      // Curves evaluate smoothly in (0, 1).
      expect(UiCurves.easeOutStrong.transform(0.5), greaterThan(0.5));
      expect(
        UiCurves.easeInOutStrong.transform(0.5),
        inInclusiveRange(0.45, 0.65),
      );
      expect(UiCurves.drawer.transform(0.5), greaterThan(0.5));
      expect(UiCurves.dockOvershoot.transform(0.8), greaterThan(1.0));
      expect(UiCurves.stampDecel.transform(0.5), greaterThan(0.5));
      expect(UiCurves.m3Decelerate.transform(0.5), greaterThan(0.5));
      expect(UiCurves.m3Accelerate.transform(0.5), lessThan(0.5));

      // Springs per skin: quiet & minimal use gentle (critically damped), others bouncy.
      expect(UiSprings.forSkin(UiSkinId.quiet), same(UiSprings.gentle));
      expect(UiSprings.forSkin(UiSkinId.minimal), same(UiSprings.gentle));
      expect(UiSprings.forSkin('quiet'), same(UiSprings.gentle));
      expect(UiSprings.forSkin(uiSkinById('quiet')), same(UiSprings.gentle));
      expect(UiSprings.forSkin(UiSkinId.squad), same(UiSprings.bouncy));
      expect(UiSprings.forSkin(UiSkinId.couple), same(UiSprings.bouncy));
      expect(UiSprings.forSkin(UiSkinId.flexer), same(UiSprings.bouncy));
      expect(UiSprings.forSkin(UiSkinId.memory), same(UiSprings.bouncy));
      expect(UiSprings.snappy.stiffness, 420.0);

      // Hero tags.
      expect(UiHeroTags.journeyBadge('j1'), 'journey-badge-j1');
      expect(UiHeroTags.journeyCover('j1'), 'journey-cover-j1');
      expect(UiHeroTags.capturePhoto('k1'), 'capture-photo-k1');
      expect(UiHeroTags.dayPhoto('e1'), 'day-photo-e1');
      expect(UiHeroTags.sharePreview('j1'), 'share-preview-j1');

      // Legacy forwarding aliases.
      expect(OurneyDurations.tap, UiMotion.press);
      expect(OurneyDurations.personaTheme, UiMotion.theme);
      expect(OurneyCurves.tap, UiCurves.easeOutStrong);
    });

    testWidgets('UiMotion.of and fadeOf honour MediaQuery.disableAnimations', (
      tester,
    ) async {
      late bool normalReduced;
      late Duration normalPress;
      late Duration normalFade;
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) {
              normalReduced = UiMotion.reduced(context);
              normalPress = UiMotion.of(context, UiMotion.press);
              normalFade = UiMotion.fadeOf(context, UiMotion.normal);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(normalReduced, isFalse);
      expect(normalPress, UiMotion.press);
      expect(normalFade, UiMotion.normal);

      late bool rmReduced;
      late Duration rmPress;
      late Duration rmFade;
      await tester.pumpWidget(
        _host(
          disableAnimations: true,
          Builder(
            builder: (context) {
              rmReduced = UiMotion.reduced(context);
              rmPress = UiMotion.of(context, UiMotion.press);
              rmFade = UiMotion.fadeOf(context, UiMotion.normal);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(rmReduced, isTrue);
      expect(rmPress, Duration.zero);
      expect(rmFade, UiMotion.reducedFade);

      // Dual-platform iOS Reduce Motion: accessibilityFeatures.reduceMotion
      // is honoured even when MediaQueryData.disableAnimations is false.
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(reduceMotion: true);
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      late bool iosReduced;
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) {
              iosReduced = UiMotion.reduced(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(iosReduced, isTrue);
      tester.platformDispatcher.clearAllTestValues();
    });

    testWidgets('UiHaptics and OurneyHaptics share enabled flag and invoke channel', (
      tester,
    ) async {
      final calls = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'HapticFeedback.vibrate') {
              calls.add(call.arguments as String? ?? '');
            }
            return null;
          });
      addTearDown(() {
        UiHaptics.enabled = true;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      await UiHaptics.selection();
      await UiHaptics.pressLight();
      await UiHaptics.shutterMedium();
      await UiHaptics.stampImpact();
      await UiHaptics.warning();
      expect(calls, [
        'HapticFeedbackType.selectionClick',
        'HapticFeedbackType.lightImpact',
        'HapticFeedbackType.mediumImpact',
        'HapticFeedbackType.mediumImpact',
        'HapticFeedbackType.heavyImpact',
      ]);

      calls.clear();
      OurneyHaptics.enabled = false;
      expect(UiHaptics.enabled, isFalse);
      await UiHaptics.pressLight();
      await UiHaptics.milestoneSuccess();
      expect(calls, isEmpty);

      OurneyHaptics.enabled = true;
      expect(UiHaptics.enabled, isTrue);
    });
  });

  group('UiPressable, UiButton & UiBarIconButton Soft Neo-Brutalism physics', () {
    testWidgets(
      '3-point pump choreography on primary UiButton: t=0, t=55ms mid-flight, t=settled (no scale-down, static shadow, haptics)',
      (tester) async {
        final haptics = <String>[];
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, (call) async {
              if (call.method == 'HapticFeedback.vibrate') {
                haptics.add(call.arguments as String? ?? '');
              }
              return null;
            });
        addTearDown(() {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(SystemChannels.platform, null);
        });

        var tapped = 0;
        await tester.pumpWidget(
          _host(
            UiButton(
              key: const ValueKey('primary-btn'),
              label: 'Chụp ngay',
              onPressed: () => tapped++,
            ),
          ),
        );

        // Static shadow box is mounted once.
        expect(
          find.byKey(const ValueKey('ui-pressable-static-shadow')),
          findsOneWidget,
        );

        final textFinder = find.text('Chụp ngay');
        final origin = tester.getTopLeft(textFinder);

        // 1. Start (t = 0ms)
        final gesture = await tester.startGesture(tester.getCenter(textFinder));
        await tester.pump();
        expect(tester.getTopLeft(textFinder) - origin, Offset.zero);
        expect(
          tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
          1.0,
        );

        // 2. Mid-flight (t = 55ms)
        await tester.pump(const Duration(milliseconds: 55));
        final midDelta = tester.getTopLeft(textFinder) - origin;
        expect(midDelta.dx, greaterThan(0.0));
        expect(midDelta.dx, lessThan(UiShadow.large));
        expect(midDelta.dy, closeTo(midDelta.dx, 0.001));
        expect(
          tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
          1.0,
        );

        // 3. Settled hold (t >= 110ms)
        await tester.pumpAndSettle();
        final fullDelta = tester.getTopLeft(textFinder) - origin;
        expect(fullDelta.dx, closeTo(UiShadow.large, 0.01));
        expect(fullDelta.dy, closeTo(UiShadow.large, 0.01));

        // Release and verify rebound mid-flight + final settle + haptic.
        await gesture.up();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 55));
        final releaseMidDelta = tester.getTopLeft(textFinder) - origin;
        expect(releaseMidDelta.dx, greaterThan(0.0));
        expect(releaseMidDelta.dx, lessThan(UiShadow.large));

        await tester.pumpAndSettle();
        expect(tester.getTopLeft(textFinder) - origin, Offset.zero);
        expect(tapped, 1);
        expect(haptics, contains('HapticFeedbackType.lightImpact'));
        expect(tester.binding.transientCallbackCount, 0);
      },
    );

    testWidgets(
      'UiBarIconButton uses 2dp (UiShadow.tiny) sticker press instead of 0.96 scale-down',
      (tester) async {
        var tapped = 0;
        await tester.pumpWidget(
          _host(
            UiBarIconButton(
              glyph: const OurneyIcon(name: 'back', size: 21),
              label: 'Quay lại',
              onPressed: () => tapped++,
            ),
          ),
        );

        final btn = find.byKey(const ValueKey('ui-bar-icon-button'));
        final origin = tester.getTopLeft(btn);

        final gesture = await tester.startGesture(tester.getCenter(btn));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 55));
        final mid = tester.getTopLeft(btn) - origin;
        expect(mid.dx, greaterThan(0.0));
        expect(mid.dx, lessThan(UiShadow.tiny));
        expect(
          tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
          1.0,
        );

        await tester.pumpAndSettle();
        expect(
          tester.getTopLeft(btn) - origin,
          const Offset(UiShadow.tiny, UiShadow.tiny),
        );

        await gesture.up();
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(btn), origin);
        expect(tapped, 1);
        expect(tester.binding.transientCallbackCount, 0);
      },
    );

    testWidgets(
      'UiPressable under Reduce Motion snaps to pressed offset in 0ms with zero active tickers',
      (tester) async {
        await tester.pumpWidget(
          _host(
            disableAnimations: true,
            UiButton(label: 'Lưu', onPressed: () {}),
          ),
        );

        final textFinder = find.text('Lưu');
        final origin = tester.getTopLeft(textFinder);
        final gesture = await tester.startGesture(tester.getCenter(textFinder));
        await tester.pump();

        expect(
          tester.getTopLeft(textFinder) - origin,
          const Offset(UiShadow.large, UiShadow.large),
        );
        expect(tester.binding.transientCallbackCount, 0);

        await gesture.up();
        await tester.pump();
        expect(tester.getTopLeft(textFinder), origin);
        expect(tester.binding.transientCallbackCount, 0);
      },
    );
  });

  group('UiDirectionalSwitcher choreography & Reduce Motion parity', () {
    testWidgets(
      'Next (direction: +1) slides incoming from +dx; Back (direction: -1) slides incoming from -dx',
      (tester) async {
        var step = 1;
        var dir = 1;
        late StateSetter setHost;

        await tester.pumpWidget(
          _host(
            StatefulBuilder(
              builder: (context, setState) {
                setHost = setState;
                return UiDirectionalSwitcher(
                  step: step,
                  direction: dir,
                  animateSize: true,
                  child: SizedBox(
                    width: 200,
                    height: 60,
                    child: Text('Step $step'),
                  ),
                );
              },
            ),
          ),
        );

        final originX = tester.getTopLeft(find.text('Step 1')).dx;

        // 1. Advance Step 1 -> Step 2 (direction: +1)
        setHost(() {
          step = 2;
          dir = 1;
        });
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));

        // Incoming Step 2 is at dx > 0 relative to resting originX.
        final step2MidX = tester.getTopLeft(find.text('Step 2')).dx;
        expect(step2MidX - originX, greaterThan(0.0));
        expect(step2MidX - originX, lessThan(18.0));

        await tester.pumpAndSettle();
        expect(tester.getTopLeft(find.text('Step 2')).dx, closeTo(originX, 0.01));

        // 2. Go Back Step 2 -> Step 1 (direction: -1)
        setHost(() {
          step = 1;
          dir = -1;
        });
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));

        // Incoming Step 1 is at dx < 0 relative to resting originX.
        final step1MidX = tester.getTopLeft(find.text('Step 1')).dx;
        expect(step1MidX - originX, lessThan(0.0));
        expect(step1MidX - originX, greaterThan(-18.0));

        await tester.pumpAndSettle();
        expect(tester.getTopLeft(find.text('Step 1')).dx, closeTo(originX, 0.01));
        expect(tester.binding.transientCallbackCount, 0);
      },
    );

    testWidgets(
      'UiDirectionalSwitcher under Reduce Motion has zero horizontal offset',
      (tester) async {
        var step = 1;
        late StateSetter setHost;

        await tester.pumpWidget(
          _host(
            disableAnimations: true,
            StatefulBuilder(
              builder: (context, setState) {
                setHost = setState;
                return UiDirectionalSwitcher(
                  step: step,
                  direction: 1,
                  child: SizedBox(
                    width: 200,
                    height: 60,
                    child: Text('Step $step'),
                  ),
                );
              },
            ),
          ),
        );

        final originX = tester.getTopLeft(find.text('Step 1')).dx;
        setHost(() => step = 2);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));

        expect(tester.getTopLeft(find.text('Step 2')).dx, closeTo(originX, 0.01));
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('Step 2'), findsOneWidget);
        expect(tester.binding.transientCallbackCount, 0);
      },
    );
  });

  group('UiStaggerItem wave delays & Reduce Motion parity', () {
    test('non-uniform shrinking wave delays cap at index 4', () {
      expect(UiStaggerItem.delayFor(0), Duration.zero);
      expect(UiStaggerItem.delayFor(1), const Duration(milliseconds: 45));
      expect(UiStaggerItem.delayFor(2), const Duration(milliseconds: 80));
      expect(UiStaggerItem.delayFor(3), const Duration(milliseconds: 105));
      expect(UiStaggerItem.delayFor(4), const Duration(milliseconds: 120));
      expect(UiStaggerItem.delayFor(9), const Duration(milliseconds: 120));
    });

    testWidgets(
      '3-point pump choreography on UiStaggerItem and Reduce Motion parity',
      (tester) async {
        await tester.pumpWidget(
          _host(
            Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                UiStaggerItem(index: 0, child: Text('Card 0')),
                UiStaggerItem(index: 2, child: Text('Card 2')),
              ],
            ),
          ),
        );

        // At t = 50ms: Card 0 (0ms delay) is mid-flight; Card 2 (80ms delay) has not started yet.
        await tester.pump(const Duration(milliseconds: 50));
        final fades = tester
            .widgetList<FadeTransition>(
              find.descendant(
                of: find.byType(UiStaggerItem),
                matching: find.byType(FadeTransition),
              ),
            )
            .toList();
        expect(fades[0].opacity.value, greaterThan(0.0));
        expect(fades[0].opacity.value, lessThan(1.0));
        expect(fades[1].opacity.value, 0.0);

        // Advance past the 80ms delay timer and one animation frame so Card 2 is mid-flight.
        await tester.pump(const Duration(milliseconds: 40));
        await tester.pump(const Duration(milliseconds: 50));
        expect(fades[1].opacity.value, greaterThan(0.0));
        expect(fades[1].opacity.value, lessThan(1.0));

        await tester.pumpAndSettle();
        expect(fades[0].opacity.value, 1.0);
        expect(fades[1].opacity.value, 1.0);
        expect(tester.binding.transientCallbackCount, 0);

        // Reduce Motion: renders at Offset.zero immediately with 0 pending timers.
        await tester.pumpWidget(
          _host(
            disableAnimations: true,
            const UiStaggerItem(index: 3, child: Text('Reduced Card')),
          ),
        );
        await tester.pump();
        final t = tester.widget<Transform>(
          find.descendant(
            of: find.byType(UiStaggerItem),
            matching: find.byType(Transform),
          ),
        );
        expect(t.transform.getTranslation().y, 0.0);
        expect(tester.binding.transientCallbackCount, 0);
      },
    );
  });

  group('UiCountRoll odometer choreography & Reduce Motion parity', () {
    testWidgets(
      'rolls from initialValue and on value updates with 3-point mid-flight verification',
      (tester) async {
        var count = 21;
        late StateSetter setHost;

        await tester.pumpWidget(
          _host(
            StatefulBuilder(
              builder: (context, setState) {
                setHost = setState;
                return UiCountRoll(
                  value: count,
                  initialValue: 20,
                  duration: UiMotion.normal,
                );
              },
            ),
          ),
        );

        // Mid-flight on initial roll (20 -> 21): both '20' and '21' are present.
        await tester.pump(const Duration(milliseconds: 80));
        expect(find.text('20'), findsOneWidget);
        expect(find.text('21'), findsOneWidget);

        // Settled: only '21' remains.
        await tester.pumpAndSettle();
        expect(find.text('20'), findsNothing);
        expect(find.text('21'), findsOneWidget);

        // Increment 21 -> 22.
        setHost(() => count = 22);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));
        expect(find.text('21'), findsOneWidget);
        expect(find.text('22'), findsOneWidget);

        await tester.pumpAndSettle();
        expect(find.text('21'), findsNothing);
        expect(find.text('22'), findsOneWidget);
        expect(tester.binding.transientCallbackCount, 0);
      },
    );

    testWidgets(
      'UiCountRoll under Reduce Motion renders final value immediately',
      (tester) async {
        await tester.pumpWidget(
          _host(
            disableAnimations: true,
            const UiCountRoll(value: 14, initialValue: 13),
          ),
        );
        await tester.pump();
        expect(find.text('14'), findsOneWidget);
        expect(find.text('13'), findsNothing);
        expect(tester.binding.transientCallbackCount, 0);
      },
    );
  });

  group('UiRefreshScaffold pull-to-refresh choreography & Reduce Motion', () {
    testWidgets(
      'overscroll pulls sticker badge, crosses threshold, spins during refresh, and collapses',
      (tester) async {
        final completer = Completer<void>();
        var refreshCalls = 0;

        await tester.pumpWidget(
          _host(
            UiRefreshScaffold(
              onRefresh: () {
                refreshCalls++;
                return completer.future;
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120, child: Center(child: Text('Row 1'))),
                  SizedBox(height: 120, child: Center(child: Text('Row 2'))),
                ],
              ),
            ),
          ),
        );

        expect(find.byKey(const ValueKey('ui-refresh-badge')), findsNothing);

        // Drag down past triggerOffset (72dp).
        final gesture = await tester.startGesture(const Offset(195, 200));
        await gesture.moveBy(const Offset(0, 40));
        await tester.pump();
        // Mid-pull: badge is visible.
        expect(find.byKey(const ValueKey('ui-refresh-badge')), findsOneWidget);

        await gesture.moveBy(const Offset(0, 60));
        await tester.pump();
        await gesture.up();
        await tester.pump();

        expect(refreshCalls, 1);
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('ui-refresh-badge')),
            matching: find.byType(RotationTransition),
          ),
          findsOneWidget,
        );

        // Complete refresh and verify 180ms collapse.
        completer.complete();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 90));
        expect(find.byKey(const ValueKey('ui-refresh-badge')), findsOneWidget);

        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('ui-refresh-badge')), findsNothing);
        expect(tester.binding.transientCallbackCount, 0);
      },
    );

    testWidgets(
      'UiRefreshScaffold under Reduce Motion pulses opacity without RotationTransition',
      (tester) async {
        final completer = Completer<void>();

        await tester.pumpWidget(
          _host(
            disableAnimations: true,
            UiRefreshScaffold(
              onRefresh: () => completer.future,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120, child: Center(child: Text('Row 1'))),
                ],
              ),
            ),
          ),
        );

        await tester.drag(find.byType(ListView), const Offset(0, 100));
        await tester.pump();

        expect(find.byKey(const ValueKey('ui-refresh-badge')), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('ui-refresh-badge')),
            matching: find.byType(RotationTransition),
          ),
          findsNothing,
        );

        completer.complete();
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('ui-refresh-badge')), findsNothing);
        expect(tester.binding.transientCallbackCount, 0);
      },
    );
  });

  group('buildUiPage (CustomTransitionPage) & UiHero Reduce Motion parity', () {
    for (final kind in UiPageTransition.values) {
      testWidgets('buildUiPage animates ${kind.name} and respects Reduce Motion', (
        tester,
      ) async {
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => Scaffold(
                body: Center(
                  child: UiHero(
                    tag: UiHeroTags.journeyBadge('j1'),
                    child: TextButton(
                      onPressed: () => context.push('/detail'),
                      child: const Text('Open'),
                    ),
                  ),
                ),
              ),
            ),
            GoRoute(
              path: '/detail',
              pageBuilder: (context, state) => buildUiPage<void>(
                state: state,
                kind: kind,
                child: const Scaffold(
                  body: Center(
                    child: UiHero(
                      tag: 'journey-badge-j1',
                      child: Text('Detail Page'),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(
          MaterialApp.router(
            theme: OurneyTheme.build(Brightness.light),
            routerConfig: router,
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));
        expect(find.text('Detail Page'), findsOneWidget);

        await tester.pumpAndSettle();
        expect(find.text('Detail Page'), findsOneWidget);
        expect(tester.binding.transientCallbackCount, 0);
      });
    }

    testWidgets('UiHero disables HeroMode when Reduce Motion is enabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          disableAnimations: true,
          const UiHero(tag: 'hero-1', child: Text('Hero Child')),
        ),
      );
      final heroMode = tester.widget<HeroMode>(find.byType(HeroMode));
      expect(heroMode.enabled, isFalse);
    });
  });
}
