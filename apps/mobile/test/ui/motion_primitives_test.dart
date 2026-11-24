import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
  TextDirection textDirection = TextDirection.ltr,
  EdgeInsets padding = EdgeInsets.zero,
}) {
  return MaterialApp(
    theme: OurneyTheme.build(brightness),
    themeAnimationDuration: Duration.zero,
    builder: (context, appChild) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        size: const Size(390, 844),
        disableAnimations: disableAnimations,
        padding: padding,
      ),
      child: Directionality(
        textDirection: textDirection,
        child: appChild!,
      ),
    ),
    home: Scaffold(body: Center(child: child)),
  );
}

Future<Uint8List> _captureBoundaryRgba(
  WidgetTester tester,
  GlobalKey boundaryKey,
) async {
  final boundary =
      boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  Uint8List? bytes;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    bytes = byteData!.buffer.asUint8List();
  });
  return bytes!;
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

    testWidgets(
      'UiHaptics and OurneyHaptics share enabled flag, invoke channel, and OurneyHaptics.success() spawns no delayed timer',
      (tester) async {
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
        await UiHaptics.reject();
        await UiHaptics.shutterMedium();
        await UiHaptics.stampImpact();
        await UiHaptics.success();
        await UiHaptics.warning();
        expect(calls, [
          'HapticFeedbackType.selectionClick',
          'HapticFeedbackType.lightImpact',
          'HapticFeedbackType.lightImpact',
          'HapticFeedbackType.mediumImpact',
          'HapticFeedbackType.mediumImpact',
          'HapticFeedbackType.mediumImpact',
          'HapticFeedbackType.heavyImpact',
        ]);

        // OurneyHaptics.success() routes to single-beat UiHaptics.success()
        // without spawning a 110ms Timer that would fail widget tests.
        calls.clear();
        OurneyHaptics.success();
        await tester.pump();
        expect(calls, ['HapticFeedbackType.mediumImpact']);

        calls.clear();
        OurneyHaptics.enabled = false;
        expect(UiHaptics.enabled, isFalse);
        await UiHaptics.pressLight();
        await UiHaptics.milestoneSuccess();
        expect(calls, isEmpty);

        OurneyHaptics.enabled = true;
        expect(UiHaptics.enabled, isTrue);
      },
    );
  });

  group('UiPressable, UiButton & UiBarIconButton Soft Neo-Brutalism physics', () {
    testWidgets(
      '3-point pump choreography on primary UiButton: t=0, t=55ms mid-flight, t=settled (no scale-down, static shadow, haptics, zero test shims)',
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

        // Static shadow box is mounted once; no AnimatedContainer or AnimatedScale shim exists.
        expect(
          find.byKey(const ValueKey('ui-pressable-static-shadow')),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(UiPressable),
            matching: find.byType(AnimatedContainer),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: find.byType(UiPressable),
            matching: find.byType(AnimatedScale),
          ),
          findsNothing,
        );

        final textFinder = find.text('Chụp ngay');
        final origin = tester.getTopLeft(textFinder);

        // 1. Start (t = 0ms)
        final gesture = await tester.startGesture(tester.getCenter(textFinder));
        await tester.pump();
        expect(tester.getTopLeft(textFinder) - origin, Offset.zero);

        // 2. Mid-flight (t = 55ms)
        await tester.pump(const Duration(milliseconds: 55));
        final midDelta = tester.getTopLeft(textFinder) - origin;
        expect(midDelta.dx, greaterThan(0.0));
        expect(midDelta.dx, lessThan(UiShadow.large));
        expect(midDelta.dy, closeTo(midDelta.dx, 0.001));

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
      'UiBarIconButton has NO shadow at idle (pixel-identical to main) and uses 2dp flat translate press without 0.96 scale-down',
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

        // No static shadow block at idle.
        expect(
          find.byKey(const ValueKey('ui-pressable-static-shadow')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('ui-pressable-surface-scale')),
          findsNothing,
        );

        final btn = find.byKey(const ValueKey('ui-bar-icon-button'));
        final origin = tester.getTopLeft(btn);

        final gesture = await tester.startGesture(tester.getCenter(btn));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 55));
        final mid = tester.getTopLeft(btn) - origin;
        expect(mid.dx, greaterThan(0.0));
        expect(mid.dx, lessThan(UiShadow.tiny));

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
      'golden-free idle-pixel test: UiButton and UiBarIconButton RGBA renders are byte-identical before press and after press settle (and UiBarIconButton idle matches shadowless reference)',
      (tester) async {
        final btnBoundary = GlobalKey();
        final barBtnBoundary = GlobalKey();
        final refBarBtnBoundary = GlobalKey();

        await tester.pumpWidget(
          _host(
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RepaintBoundary(
                  key: btnBoundary,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: UiButton(
                      label: 'Tiếp tục',
                      expand: false,
                      onPressed: () {},
                    ),
                  ),
                ),
                RepaintBoundary(
                  key: barBtnBoundary,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: UiBarIconButton(
                      glyph: const OurneyIcon(name: 'back', size: 21),
                      label: 'Back',
                      onPressed: () {},
                    ),
                  ),
                ),
                RepaintBoundary(
                  key: refBarBtnBoundary,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: SizedBox(
                      width: UiSize.tap,
                      height: UiSize.tap,
                      child: Center(
                        child: Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: OurneyUi.light.surface,
                            shape: BoxShape.circle,
                            border: OurneyUi.light.stickerBorder(UiBorder.thin),
                          ),
                          child: const OurneyIcon(name: 'back', size: 21),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        final btnIdleBefore = await _captureBoundaryRgba(tester, btnBoundary);
        final barIdleBefore = await _captureBoundaryRgba(tester, barBtnBoundary);
        final refBarIdle = await _captureBoundaryRgba(tester, refBarBtnBoundary);

        // 1. UiBarIconButton at idle is byte-for-byte identical to the
        // pre-M0 flat 44dp shadowless reference circle.
        expect(barIdleBefore, equals(refBarIdle));

        // 2. Press UiButton, verify mid-flight pixels change, release and
        // verify settled pixels match idle before press byte-for-byte.
        final btnGesture = await tester.startGesture(
          tester.getCenter(find.text('Tiếp tục')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 55));
        final btnMidPress = await _captureBoundaryRgba(tester, btnBoundary);
        expect(btnMidPress, isNot(equals(btnIdleBefore)));

        await btnGesture.up();
        await tester.pumpAndSettle();
        final btnIdleAfter = await _captureBoundaryRgba(tester, btnBoundary);
        expect(btnIdleAfter, equals(btnIdleBefore));

        // 3. Press UiBarIconButton, verify mid-flight pixels change, release
        // and verify settled pixels match idle before press byte-for-byte.
        final barGesture = await tester.startGesture(
          tester.getCenter(find.byKey(const ValueKey('ui-bar-icon-button'))),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 55));
        final barMidPress = await _captureBoundaryRgba(tester, barBtnBoundary);
        expect(barMidPress, isNot(equals(barIdleBefore)));

        await barGesture.up();
        await tester.pumpAndSettle();
        final barIdleAfter = await _captureBoundaryRgba(tester, barBtnBoundary);
        expect(barIdleAfter, equals(barIdleBefore));
      },
    );

    testWidgets(
      'shadowOffset == 0 ghost control animates 0.96 scale mid-flight at 55ms; stationary >= 48x48 hit box and tap-to-loading reset work cleanly',
      (tester) async {
        // 1. Mid-flight scale on shadowOffset == 0 ghost button
        await tester.pumpWidget(
          _host(UiButton.ghost(label: 'Bỏ qua', onPressed: () {})),
        );
        final scaleFinder = find.byKey(
          const ValueKey('ui-pressable-surface-scale'),
        );
        double currentScale() =>
            tester.widget<Transform>(scaleFinder).transform.storage[0];

        expect(currentScale(), 1.0);
        final ghostGesture = await tester.startGesture(
          tester.getCenter(find.text('Bỏ qua')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 55));
        expect(currentScale(), greaterThan(UiMotion.pressScale));
        expect(currentScale(), lessThan(1.0));

        await tester.pumpAndSettle();
        expect(currentScale(), closeTo(UiMotion.pressScale, 0.001));

        await ghostGesture.up();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 55));
        expect(currentScale(), greaterThan(UiMotion.pressScale));
        expect(currentScale(), lessThan(1.0));

        await tester.pumpAndSettle();
        expect(currentScale(), closeTo(1.0, 0.001));

        // 2. Stationary >= 48x48 hit-test box while visual surface shifts (+4, +4)
        // and immediate controller reset when tapping transitions into disabled state.
        var isDisabled = false;
        var taps = 0;
        late StateSetter setHost;
        await tester.pumpWidget(
          _host(
            StatefulBuilder(
              builder: (context, setState) {
                setHost = setState;
                return UiButton(
                  compact: true,
                  expand: false,
                  label: 'Gửi',
                  onPressed: isDisabled
                      ? null
                      : () {
                          taps++;
                          setHost(() => isDisabled = true);
                        },
                );
              },
            ),
          ),
        );

        final pressableFinder = find.byType(UiPressable);
        final hitRectBefore = tester.getRect(pressableFinder);
        expect(hitRectBefore.width, greaterThanOrEqualTo(48));
        expect(hitRectBefore.height, greaterThanOrEqualTo(48));

        // Start press near top-left edge (origin + (2, 2)): even after the
        // visual surface shifts (+4, +4), the outer GestureDetector hit box
        // remains stationary at hitRectBefore and commits the tap on release.
        final edgePoint = hitRectBefore.topLeft + const Offset(2, 2);
        final edgeGesture = await tester.startGesture(edgePoint);
        await tester.pump();
        await tester.pumpAndSettle();
        expect(tester.getRect(pressableFinder), hitRectBefore);

        await edgeGesture.up();
        await tester.pump();

        // Tapping immediately transitioned UiButton into disabled state.
        // _ctrl must be stopped and reset to 0.0 immediately with zero
        // lingering transient callbacks and static shadow unmounted.
        expect(taps, 1);
        expect(isDisabled, isTrue);
        expect(tester.binding.transientCallbackCount, 0);
        expect(
          find.byKey(const ValueKey('ui-pressable-static-shadow')),
          findsNothing,
        );

        // 3. No-motion configuration (shadowOffset: 0, pressOffset: 0, pressScale: 1.0)
        // allocates zero controllers/tickers on press.
        await tester.pumpWidget(
          _host(
            UiPressable(
              pressScale: 1.0,
              onPressed: () {},
              child: const Text('Static Tap'),
            ),
          ),
        );
        final staticGesture = await tester.startGesture(
          tester.getCenter(find.text('Static Tap')),
        );
        await tester.pump();
        expect(tester.binding.transientCallbackCount, 0);
        await staticGesture.up();
        await tester.pump();
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

  group('UiDirectionalSwitcher choreography, RTL & Reduce Motion parity', () {
    testWidgets(
      'Next (direction: +1) slides incoming from +18dp; Back (direction: -1) slides incoming from -18dp; RTL flips horizontal direction',
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

        // 1. Advance Step 1 -> Step 2 (direction: +1, LTR)
        setHost(() {
          step = 2;
          dir = 1;
        });
        await tester.pump();
        // At t = 1ms, incoming offset is <= 18.0dp (never 22.5dp double-translated).
        await tester.pump(const Duration(milliseconds: 1));
        final step2StartDelta =
            tester.getTopLeft(find.text('Step 2')).dx - originX;
        expect(step2StartDelta, greaterThan(15.0));
        expect(step2StartDelta, lessThanOrEqualTo(18.0));

        await tester.pump(const Duration(milliseconds: 79));
        final step2MidX = tester.getTopLeft(find.text('Step 2')).dx;
        expect(step2MidX - originX, greaterThan(0.0));
        expect(step2MidX - originX, lessThan(18.0));

        await tester.pumpAndSettle();
        expect(tester.getTopLeft(find.text('Step 2')).dx, closeTo(originX, 0.01));

        // 2. Go Back Step 2 -> Step 1 (direction: -1, LTR)
        setHost(() {
          step = 1;
          dir = -1;
        });
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));

        final step1MidX = tester.getTopLeft(find.text('Step 1')).dx;
        expect(step1MidX - originX, lessThan(0.0));
        expect(step1MidX - originX, greaterThan(-18.0));

        await tester.pumpAndSettle();
        expect(tester.getTopLeft(find.text('Step 1')).dx, closeTo(originX, 0.01));

        // 3. RTL flips direction (+1 Next enters from -dx in RTL)
        await tester.pumpWidget(
          _host(
            textDirection: TextDirection.rtl,
            StatefulBuilder(
              builder: (context, setState) {
                setHost = setState;
                return UiDirectionalSwitcher(
                  step: step,
                  direction: dir,
                  child: SizedBox(
                    width: 200,
                    height: 60,
                    child: Text('RTL $step'),
                  ),
                );
              },
            ),
          ),
        );
        final rtlOriginX = tester.getTopLeft(find.text('RTL 1')).dx;
        setHost(() {
          step = 2;
          dir = 1;
        });
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));
        final rtlStep2MidX = tester.getTopLeft(find.text('RTL 2')).dx;
        expect(rtlStep2MidX - rtlOriginX, lessThan(0.0));
        expect(rtlStep2MidX - rtlOriginX, greaterThan(-18.0));

        await tester.pumpAndSettle();
        expect(tester.binding.transientCallbackCount, 0);
      },
    );

    testWidgets(
      'UiDirectionalSwitcher under Reduce Motion has zero horizontal offset and mounts no SlideTransition',
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
        expect(
          find.descendant(
            of: find.byType(UiDirectionalSwitcher),
            matching: find.byType(SlideTransition),
          ),
          findsNothing,
        );
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
      '3-point pump choreography on UiStaggerItem, disabled fast path, and Reduce Motion parity',
      (tester) async {
        await tester.pumpWidget(
          _host(
            Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                UiStaggerItem(index: 0, child: Text('Card 0')),
                UiStaggerItem(index: 2, child: Text('Card 2')),
                UiStaggerItem(
                  index: 1,
                  enabled: false,
                  child: Text('Disabled Card'),
                ),
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
        expect(fades, hasLength(2));
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

        // Reduce Motion: returns child directly with zero Transform wrapper or pending timers.
        await tester.pumpWidget(
          _host(
            disableAnimations: true,
            const UiStaggerItem(index: 3, child: Text('Reduced Card')),
          ),
        );
        await tester.pump();
        expect(find.text('Reduced Card'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(UiStaggerItem),
            matching: find.byType(Transform),
          ),
          findsNothing,
        );
        expect(tester.binding.transientCallbackCount, 0);
      },
    );
  });

  group('UiCountRoll odometer choreography & Reduce Motion parity', () {
    testWidgets(
      'rolls from initialValue and on value updates with 3-point mid-flight dy/opacity verification and single-line ellipsis',
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
                  format: (v) => '$v ngày liên tiếp',
                );
              },
            ),
          ),
        );

        // Mid-flight on initial roll (20 -> 21): both texts are present with
        // strictly interpolated FadeTransition opacities and vertical dy offsets.
        await tester.pump(const Duration(milliseconds: 80));
        expect(find.text('20 ngày liên tiếp'), findsOneWidget);
        expect(find.text('21 ngày liên tiếp'), findsOneWidget);

        final fades = tester
            .widgetList<FadeTransition>(
              find.descendant(
                of: find.byType(UiCountRoll),
                matching: find.byType(FadeTransition),
              ),
            )
            .toList();
        expect(fades, hasLength(2));
        expect(fades[0].opacity.value, greaterThan(0.0));
        expect(fades[0].opacity.value, lessThan(1.0));
        expect(fades[1].opacity.value, greaterThan(0.0));
        expect(fades[1].opacity.value, lessThan(1.0));

        final transforms = tester
            .widgetList<Transform>(
              find.descendant(
                of: find.byType(UiCountRoll),
                matching: find.byType(Transform),
              ),
            )
            .toList();
        expect(transforms, hasLength(2));
        final outDy = transforms[0].transform.getTranslation().y;
        final inDy = transforms[1].transform.getTranslation().y;
        expect(outDy, lessThan(0.0));
        expect(outDy, greaterThan(-14.0));
        expect(inDy, greaterThan(0.0));
        expect(inDy, lessThan(14.0));

        // Settled: only '21 ngày liên tiếp' remains with single-line overflow safety.
        await tester.pumpAndSettle();
        expect(find.text('20 ngày liên tiếp'), findsNothing);
        final settledText = tester.widget<Text>(find.text('21 ngày liên tiếp'));
        expect(settledText.maxLines, 1);
        expect(settledText.softWrap, isFalse);
        expect(settledText.overflow, TextOverflow.ellipsis);

        // Decrement 21 -> 20 reverses vertical roll sign.
        setHost(() => count = 20);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));
        final decTransforms = tester
            .widgetList<Transform>(
              find.descendant(
                of: find.byType(UiCountRoll),
                matching: find.byType(Transform),
              ),
            )
            .toList();
        expect(decTransforms[0].transform.getTranslation().y, greaterThan(0.0));
        expect(decTransforms[1].transform.getTranslation().y, lessThan(0.0));

        await tester.pumpAndSettle();
        expect(find.text('21 ngày liên tiếp'), findsNothing);
        expect(find.text('20 ngày liên tiếp'), findsOneWidget);
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
      'overscroll pulls sticker badge below top safe area, fires single-shot haptic, obeys TickerMode, and collapses',
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

        final completer = Completer<void>();
        var refreshCalls = 0;
        var tickerEnabled = true;
        late StateSetter setHost;

        await tester.pumpWidget(
          _host(
            padding: const EdgeInsets.only(top: 44),
            StatefulBuilder(
              builder: (context, setState) {
                setHost = setState;
                return TickerMode(
                  enabled: tickerEnabled,
                  child: UiRefreshScaffold(
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
                );
              },
            ),
          ),
        );

        expect(find.byKey(const ValueKey('ui-refresh-badge')), findsNothing);

        // Drag down past triggerOffset (72dp).
        final gesture = await tester.startGesture(const Offset(195, 200));
        await gesture.moveBy(const Offset(0, 40));
        await tester.pump();
        final badgeFinder = find.byKey(const ValueKey('ui-refresh-badge'));
        expect(badgeFinder, findsOneWidget);
        // Respects top safe area (44dp + >= 8dp = >= 52dp).
        expect(tester.getTopLeft(badgeFinder).dy, greaterThanOrEqualTo(52.0));
        expect(haptics, isEmpty);

        // Cross threshold once -> fires selectionClick exactly once even as drag continues.
        await gesture.moveBy(const Offset(0, 45));
        await tester.pump();
        await gesture.moveBy(const Offset(0, 20));
        await tester.pump();
        expect(haptics, ['HapticFeedbackType.selectionClick']);

        await gesture.up();
        await tester.pump();

        expect(refreshCalls, 1);
        expect(
          find.descendant(
            of: badgeFinder,
            matching: find.byType(RotationTransition),
          ),
        findsOneWidget,
        );

        // Toggling TickerMode(enabled: false) while refreshing stops _spinCtrl.
        setHost(() => tickerEnabled = false);
        await tester.pump();
        expect(tester.binding.transientCallbackCount, 0);

        setHost(() => tickerEnabled = true);
        await tester.pump();
        expect(tester.binding.transientCallbackCount, greaterThan(0));

        // Complete refresh and verify 180ms collapse.
        completer.complete();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 90));
        expect(badgeFinder, findsOneWidget);

        await tester.pumpAndSettle();
        expect(badgeFinder, findsNothing);
        expect(tester.binding.transientCallbackCount, 0);
      },
    );

    testWidgets(
      'passive ballistic scroll-to-top fling never triggers refresh or haptics',
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

        var refreshCalls = 0;
        final controller = ScrollController(initialScrollOffset: 400);
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          _host(
            UiRefreshScaffold(
              onRefresh: () async {
                refreshCalls++;
              },
              child: ListView.builder(
                controller: controller,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                itemCount: 30,
                itemBuilder: (_, i) => SizedBox(
                  height: 60,
                  child: Center(child: Text('Item $i')),
                ),
              ),
            ),
          ),
        );

        expect(controller.offset, 400);
        // Fling rapidly upward from mid-list so ballistic momentum overshoots the top edge.
        await tester.fling(
          find.byType(ListView),
          const Offset(0, 500),
          3000,
        );
        await tester.pumpAndSettle();

        expect(refreshCalls, 0);
        expect(haptics, isEmpty);
        expect(find.byKey(const ValueKey('ui-refresh-badge')), findsNothing);
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

  group('buildUiPage (CustomTransitionPage) & UiHero flight shuttle + Reduce Motion parity', () {
    for (final kind in UiPageTransition.values) {
      testWidgets(
        'buildUiPage animates ${kind.name} mid-flight and settles in <= 160ms under Reduce Motion',
        (tester) async {
          var disableAnimations = false;
          late StateSetter setAppState;

          final router = GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => Scaffold(
                  body: Center(
                    child: GestureDetector(
                      onTap: () => context.push('/detail'),
                      child: const Text('Open'),
                    ),
                  ),
                ),
              ),
              GoRoute(
                path: '/detail',
                pageBuilder: (context, state) => buildUiPage<void>(
                  context: context,
                  state: state,
                  kind: kind,
                  opaque: false,
                  fullscreenDialog: true,
                  child: Scaffold(
                    body: Center(
                      child: GestureDetector(
                        onTap: () => context.pop(),
                        child: const Text('Detail Page'),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
          addTearDown(router.dispose);

          final appTheme = OurneyTheme.build(Brightness.light);
          await tester.pumpWidget(
            StatefulBuilder(
              builder: (context, setState) {
                setAppState = setState;
                return MaterialApp.router(
                  theme: appTheme,
                  themeAnimationDuration: Duration.zero,
                  routerConfig: router,
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      disableAnimations: disableAnimations,
                    ),
                    child: child!,
                  ),
                );
              },
            ),
          );

          // 1. Normal motion (320ms): mid-flight at 120ms still has active transition ticker.
          await tester.tap(find.text('Open'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 120));
          expect(find.text('Detail Page'), findsOneWidget);
          expect(tester.binding.transientCallbackCount, greaterThan(0));

          await tester.pumpAndSettle();
          expect(find.text('Detail Page'), findsOneWidget);
          expect(tester.binding.transientCallbackCount, 0);

          // Pop back to root.
          await tester.tap(find.text('Detail Page'));
          await tester.pumpAndSettle();
          expect(find.text('Open'), findsOneWidget);

          // 2. Reduce Motion (150ms fade): mid-flight at 75ms, completely settled by 160ms!
          setAppState(() => disableAnimations = true);
          await tester.pump();

          await tester.tap(find.text('Open'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 75));
          final fade = tester.widget<FadeTransition>(
            find
                .ancestor(
                  of: find.text('Detail Page'),
                  matching: find.byType(FadeTransition),
                )
                .first,
          );
          expect(fade.opacity.value, greaterThan(0.0));
          expect(fade.opacity.value, lessThan(1.0));

          // Advance to 160ms total (>= 150ms UiMotion.reducedFade): transition is 100% settled.
          await tester.pump(const Duration(milliseconds: 85));
          expect(fade.opacity.value, 1.0);
          await tester.pump();
          expect(tester.binding.transientCallbackCount, 0);
        },
      );
    }

    testWidgets(
      'UiHero flight shuttle tweens borderRadiusBegin -> borderRadiusEnd without mounting a nested Hero or clipping the 2dp border',
      (tester) async {
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => Scaffold(
                body: Center(
                  child: GestureDetector(
                    onTap: () => context.push('/photo'),
                    child: UiHero(
                      tag: UiHeroTags.dayPhoto('e1'),
                      borderRadiusBegin: BorderRadius.circular(12),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: OurneyUi.light.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: OurneyUi.light.stickerBorder(UiBorder.standard),
                        ),
                        child: const Center(child: Text('Thumb')),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            GoRoute(
              path: '/photo',
              pageBuilder: (context, state) => buildUiPage<void>(
                context: context,
                state: state,
                child: Scaffold(
                  body: Center(
                    child: UiHero(
                      tag: UiHeroTags.dayPhoto('e1'),
                      borderRadiusEnd: BorderRadius.circular(24),
                      child: Container(
                        width: 240,
                        height: 240,
                        decoration: BoxDecoration(
                          color: OurneyUi.light.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: OurneyUi.light.stickerBorder(UiBorder.standard),
                        ),
                        child: const Center(child: Text('Full')),
                      ),
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

        await tester.tap(find.text('Thumb'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));

        final shuttleFinder = find.byKey(const ValueKey('ui-hero-shuttle'));
        expect(shuttleFinder, findsOneWidget);

        // 1. Flight shuttle must NOT contain a nested Hero widget.
        expect(
          find.descendant(of: shuttleFinder, matching: find.byType(Hero)),
          findsNothing,
        );

        // 2. BorderRadius is interpolated mid-flight between 12 and 24, and the
        // 2dp border is painted in the foreground DecoratedBox outside ClipRRect.
        final clip = tester.widget<ClipRRect>(
          find.descendant(of: shuttleFinder, matching: find.byType(ClipRRect)),
        );
        final midRadius = (clip.borderRadius as BorderRadius).topLeft.x;
        expect(midRadius, greaterThan(12.0));
        expect(midRadius, lessThan(24.0));

        final fgBox = tester.widget<DecoratedBox>(
          find
              .descendant(
                of: shuttleFinder,
                matching: find.byWidgetPredicate(
                  (w) =>
                      w is DecoratedBox &&
                      w.position == DecorationPosition.foreground,
                ),
              )
              .first,
        );
        final fgDeco = fgBox.decoration as BoxDecoration;
        expect(fgDeco.borderRadius, clip.borderRadius);
        expect((fgDeco.border! as Border).top.width, UiBorder.standard);

        await tester.pumpAndSettle();
        expect(find.text('Full'), findsOneWidget);
        expect(tester.binding.transientCallbackCount, 0);
      },
    );

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
