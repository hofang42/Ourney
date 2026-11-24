import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/app_shell.dart';
import 'package:ourney/app/overlays/missed_day_overlay.dart';
import 'package:ourney/app/overlays/reminder_banner.dart';
import 'package:ourney/l10n/generated/app_localizations.dart';
import 'package:ourney/ui/ui.dart';

Widget _host(
  Widget child, {
  bool disableAnimations = false,
  bool withL10n = false,
  Brightness brightness = Brightness.light,
  TextDirection textDirection = TextDirection.ltr,
  Size size = const Size(390, 844),
}) {
  return MaterialApp(
    theme: OurneyTheme.build(brightness),
    themeAnimationDuration: Duration.zero,
    localizationsDelegates: withL10n
        ? AppLocalizations.localizationsDelegates
        : null,
    supportedLocales: withL10n
        ? AppLocalizations.supportedLocales
        : const <Locale>[Locale('en', 'US')],
    locale: withL10n ? const Locale('vi') : null,
    builder: (context, appChild) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        size: size,
        disableAnimations: disableAnimations,
      ),
      child: Directionality(
        textDirection: textDirection,
        child: appChild!,
      ),
    ),
    home: Scaffold(body: Center(child: child)),
  );
}

class _TickerProbe extends StatefulWidget {
  const _TickerProbe({required this.onTickerModeChanged, super.key});

  final ValueChanged<bool> onTickerModeChanged;

  @override
  State<_TickerProbe> createState() => _TickerProbeState();
}

class _TickerProbeState extends State<_TickerProbe> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.onTickerModeChanged(TickerMode.valuesOf(context).enabled);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}

void main() {
  group('M1 #5a — 5-Tab Shell Branch Switch & Camera TickerMode Invariant', () {
    testWidgets(
      'inactive branches immediately get Offstage(true) & TickerMode(false) while active branch plays 160ms directional fade+slide (0dp to/from Camera)',
      (tester) async {
        final cameraTickerLog = <bool>[];
        var index = AppShell.captureIndex; // Start on Tab 2 (Camera)
        late StateSetter setHost;

        await tester.pumpWidget(
          _host(
            StatefulBuilder(
              builder: (context, setState) {
                setHost = setState;
                return UiShellBranchContainer(
                  currentIndex: index,
                  children: [
                    const Center(child: Text('Tab 0 Journeys')),
                    const Center(child: Text('Tab 1 Squad')),
                    _TickerProbe(
                      key: const ValueKey('camera-probe'),
                      onTickerModeChanged: cameraTickerLog.add,
                    ),
                    const Center(child: Text('Tab 3 Activity')),
                    const Center(child: Text('Tab 4 Profile')),
                  ],
                );
              },
            ),
          ),
        );

        expect(cameraTickerLog, [true]);
        expect(tester.binding.transientCallbackCount, 0);

        // 1. Switch Tab 2 (Camera) -> Tab 0 (Journeys):
        // Camera must immediately receive TickerMode(false) on the first pump,
        // and slide offset dx must be 0.0 when leaving Camera.
        setHost(() => index = AppShell.journeysIndex);
        await tester.pump();
        expect(cameraTickerLog.last, isFalse);

        final offstages = tester
            .widgetList<Offstage>(
              find.descendant(
                of: find.byType(UiShellBranchContainer),
                matching: find.byType(Offstage),
              ),
            )
            .toList();
        expect(offstages[AppShell.journeysIndex].offstage, isFalse);
        expect(offstages[AppShell.captureIndex].offstage, isTrue);

        await tester.pump(const Duration(milliseconds: 80));
        final camLeaveShift = tester
            .widget<Transform>(
              find.byKey(const ValueKey('shell-branch-translate-0')),
            )
            .transform
            .getTranslation();
        expect(camLeaveShift.x, 0.0);

        final branchFades = tester
            .widgetList<FadeTransition>(
              find.descendant(
                of: find.byType(UiShellBranchContainer),
                matching: find.byType(FadeTransition),
              ),
            )
            .toList();
        expect(branchFades[0].opacity.value, greaterThan(0.0));
        expect(branchFades[0].opacity.value, lessThan(1.0));

        await tester.pumpAndSettle();
        expect(branchFades[0].opacity.value, 1.0);

        // 2. Switch Tab 0 -> Tab 1 (forward non-camera tab switch: +6dp -> 0):
        // 3-point check: t=0, t=80ms mid-flight, t=settled.
        setHost(() => index = AppShell.groupsIndex);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));
        final forwardDx = tester
            .widget<Transform>(
              find.byKey(const ValueKey('shell-branch-translate-1')),
            )
            .transform
            .getTranslation()
            .x;
        expect(forwardDx, greaterThan(0.0));
        expect(forwardDx, lessThan(UiShellBranchContainer.slideDistance));

        await tester.pumpAndSettle();
        expect(
          tester
              .widget<Transform>(
                find.byKey(const ValueKey('shell-branch-translate-1')),
              )
              .transform
              .getTranslation()
              .x,
          0.0,
        );

        // 3. Switch Tab 1 -> Tab 0 (backward non-camera tab switch: -6dp -> 0):
        setHost(() => index = AppShell.journeysIndex);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));
        final backwardDx = tester
            .widget<Transform>(
              find.byKey(const ValueKey('shell-branch-translate-0')),
            )
            .transform
            .getTranslation()
            .x;
        expect(backwardDx, lessThan(0.0));
        expect(backwardDx, greaterThan(-UiShellBranchContainer.slideDistance));

        await tester.pumpAndSettle();
        expect(tester.binding.transientCallbackCount, 0);
      },
    );

    testWidgets(
      'UiShellBranchContainer under Reduce Motion (Android & iOS) switches in 0ms with zero slide or active tickers',
      (tester) async {
        var index = 0;
        late StateSetter setHost;

        await tester.pumpWidget(
          _host(
            disableAnimations: true,
            StatefulBuilder(
              builder: (context, setState) {
                setHost = setState;
                return UiShellBranchContainer(
                  currentIndex: index,
                  children: const [
                    Text('Tab 0'),
                    Text('Tab 1'),
                    Text('Tab 2'),
                  ],
                );
              },
            ),
          ),
        );

        setHost(() => index = 1);
        await tester.pump();
        final dx = tester
            .widget<Transform>(
              find.byKey(const ValueKey('shell-branch-translate-1')),
            )
            .transform
            .getTranslation()
            .x;
        expect(dx, 0.0);
        expect(tester.binding.transientCallbackCount, 0);

        // iOS PlatformDispatcher accessibilityFeatures.reduceMotion parity
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(reduceMotion: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        await tester.pumpWidget(
          _host(
            StatefulBuilder(
              builder: (context, setState) {
                setHost = setState;
                return UiShellBranchContainer(
                  currentIndex: index,
                  children: const [
                    Text('Tab 0'),
                    Text('Tab 1'),
                    Text('Tab 2'),
                  ],
                );
              },
            ),
          ),
        );
        setHost(() => index = 2);
        await tester.pump();
        expect(tester.binding.transientCallbackCount, 0);
      },
    );
  });

  group('M1 #5b — Dock Glyph Overshoot, Haptics & SnapPill <-> Shutter Morph', () {
    testWidgets(
      'DockTab active glyph scales to 1.08 over 180ms with UiCurves.dockOvershoot and fires UiHaptics.selection once (gated on !camera); center slot morphs 56x40 <-> 76x76 bounds with uniform 2dp border & 1:1 icon over 220ms and on TickerMode handoff',
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

        var active = 0;
        var camera = false;
        late StateSetter setHost;

        UiDockItem tab(String glyph, String label, int i) => UiDockItem(
          itemKey: ValueKey('dock-tab-$i'),
          glyph: glyph,
          label: label,
          active: active == i,
          onPressed: () => setHost(() => active = i),
        );

        await tester.pumpWidget(
          _host(
            StatefulBuilder(
              builder: (context, setState) {
                setHost = setState;
                return Align(
                  alignment: Alignment.bottomCenter,
                  child: UiDock(
                    camera: camera,
                    left: tab('journeys', 'Hành trình', 0),
                    extraLeft: [tab('squad', 'Nhóm', 1)],
                    extraRight: [tab('activity', 'Hoạt động', 3)],
                    right: tab('profile', 'Hồ sơ', 4),
                    snapLabel: 'Chụp',
                    snapKey: const ValueKey('dock-snap-pill'),
                    onSnap: () => setHost(() => camera = true),
                    center: camera
                        ? UiShutter(
                            label: 'Chụp',
                            onPressed: () {},
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
        );

        final scaleWidget = tester.widget<AnimatedScale>(
          find.descendant(
            of: find.byKey(const ValueKey('dock-tab-0')),
            matching: find.byType(AnimatedScale),
          ),
        );
        expect(scaleWidget.duration, const Duration(milliseconds: 180));
        expect(scaleWidget.curve, UiCurves.dockOvershoot);
        expect(scaleWidget.scale, 1.08);

        final pillFinder = find.byKey(const ValueKey('dock-selection-pill'));
        final pillStartX = tester.getCenter(pillFinder).dx;

        // 1. Tap inactive tab 1 -> fires selectionClick haptic, slides pill (280ms) and scales glyph (180ms).
        await tester.tap(find.byKey(const ValueKey('dock-tab-1')));
        await tester.pump();
        expect(haptics, contains('HapticFeedbackType.selectionClick'));

        // Mid-flight at t = 35ms (before dockOvershoot peak)
        await tester.pump(const Duration(milliseconds: 35));
        final pillMidX = tester.getCenter(pillFinder).dx;
        expect(pillMidX, greaterThan(pillStartX));

        // Overshoot peak at t = 140ms (UiCurves.dockOvershoot > 1.0)
        await tester.pump(const Duration(milliseconds: 105));
        final pillOvershootX = tester.getCenter(pillFinder).dx;

        await tester.pumpAndSettle();
        final pillEndX = tester.getCenter(pillFinder).dx;
        expect(pillEndX, greaterThan(pillMidX));
        expect(pillOvershootX, greaterThan(pillEndX));

        // Tapping already-active tab 1 does not emit duplicate selectionClick.
        haptics.clear();
        await tester.tap(find.byKey(const ValueKey('dock-tab-1')));
        await tester.pump();
        expect(haptics, isEmpty);

        // 2. Tap UiSnapPill -> fires lightImpact and morphs center slot into 76x76 UiShutter over 220ms.
        expect(find.byKey(const ValueKey('dock-center-morph')), findsNothing);
        await tester.tap(find.byKey(const ValueKey('dock-snap-pill')));
        await tester.pump();
        expect(haptics, contains('HapticFeedbackType.lightImpact'));

        // Mid-flight at t = 110ms of 220ms morph: bounds interpolate 56x40 -> 76x76
        // with constant uniform 2dp border and square 1:1 camera icon.
        await tester.pump(const Duration(milliseconds: 110));
        final morphFinder = find.byKey(const ValueKey('dock-center-morph'));
        expect(morphFinder, findsOneWidget);
        final morphSize = tester.getSize(morphFinder);
        expect(morphSize.width, greaterThan(UiSize.snapPillW));
        expect(morphSize.width, lessThan(UiSize.shutter));
        expect(morphSize.height, greaterThan(UiSize.snapPillH));
        expect(morphSize.height, lessThan(UiSize.shutter));

        final morphDeco =
            tester
                    .widget<DecoratedBox>(
                      find.byKey(const ValueKey('dock-center-morph-box')),
                    )
                    .decoration
                as BoxDecoration;
        final morphBorder = morphDeco.border! as Border;
        expect(morphBorder.top.width, UiBorder.standard);
        expect(morphBorder.left.width, UiBorder.standard);
        final morphIconSize = tester.getSize(
          find.descendant(of: morphFinder, matching: find.byType(OurneyIcon)),
        );
        expect(morphIconSize.width, closeTo(morphIconSize.height, 0.01));

        // Settled at t >= 220ms: morph wrapper unmounts at rest.
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('dock-center-morph')), findsNothing);
        expect(tester.getSize(find.byType(UiShutter)), const Size(76, 76));
        expect(tester.binding.transientCallbackCount, 0);

        // 3. On camera dock (camera: true), tapping a tab does NOT emit DockTab's
        // selectionClick haptic (CaptureScreen._goTab owns that haptic).
        haptics.clear();
        await tester.tap(find.byKey(const ValueKey('dock-tab-0')));
        await tester.pump();
        expect(haptics, isEmpty);
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'UiDock triggers 220ms center morph on TickerMode false->true transition and snaps in 0ms under Android & iOS Reduce Motion',
      (tester) async {
        var tickerOn = false;
        var camera = false;
        late StateSetter setHost;

        UiDockItem tab(String glyph, String label, int i) => UiDockItem(
          itemKey: ValueKey('rm-dock-tab-$i'),
          glyph: glyph,
          label: label,
          active: i == 0,
          onPressed: () {},
        );

        await tester.pumpWidget(
          _host(
            StatefulBuilder(
              builder: (context, setState) {
                setHost = setState;
                return TickerMode(
                  enabled: tickerOn,
                  child: UiDock(
                    camera: true,
                    left: tab('journeys', 'Hành trình', 0),
                    right: tab('profile', 'Hồ sơ', 1),
                    snapLabel: 'Chụp',
                    onSnap: () {},
                    center: UiShutter(label: 'Chụp', onPressed: () {}),
                  ),
                );
              },
            ),
          ),
        );

        expect(find.byKey(const ValueKey('dock-center-morph')), findsNothing);

        // Simulate entering Tab 2 Camera in UiShellBranchContainer (TickerMode false -> true):
        setHost(() => tickerOn = true);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));
        expect(find.byKey(const ValueKey('dock-center-morph')), findsOneWidget);
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('dock-center-morph')), findsNothing);

        // Reduce Motion (Android disableAnimations + iOS reduceMotion): 0ms snap, no morph wrapper.
        for (final useIosFlag in [false, true]) {
          if (useIosFlag) {
            tester.platformDispatcher.accessibilityFeaturesTestValue =
                const FakeAccessibilityFeatures(reduceMotion: true);
          }
          camera = false;
          await tester.pumpWidget(
            _host(
              disableAnimations: !useIosFlag,
              StatefulBuilder(
                builder: (context, setState) {
                  setHost = setState;
                  return UiDock(
                    camera: camera,
                    left: tab('journeys', 'Hành trình', 0),
                    right: tab('profile', 'Hồ sơ', 1),
                    snapLabel: 'Chụp',
                    onSnap: () {},
                    center: camera
                        ? UiShutter(label: 'Chụp', onPressed: () {})
                        : null,
                  );
                },
              ),
            ),
          );
          setHost(() => camera = true);
          await tester.pump();
          expect(
            find.byKey(const ValueKey('dock-center-morph')),
            findsNothing,
          );
          expect(tester.binding.transientCallbackCount, 0);
          if (useIosFlag) {
            tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
          }
        }
      },
    );
  });

  group('M1 #5c — Bidirectional UiJourneyWheel, FadeTransition & Drag Haptics', () {
    const items = [
      UiJourneyWheelItem(id: 'a', label: 'Giảm cân', type: 'weight'),
      UiJourneyWheelItem(id: 'b', label: 'Tiếng Anh', type: 'study'),
      UiJourneyWheelItem(id: 'c', label: 'Đà Lạt', type: 'trip'),
    ];
    const anchor = Offset(195, 520);

    testWidgets(
      '3-point fan-out (240ms) and reverse fan-in (170ms), zero Opacity widgets, and drag-across selection haptics',
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

        late BuildContext savedCtx;
        final picked = <String>[];
        await tester.pumpWidget(
          _host(
            Builder(
              builder: (context) {
                savedCtx = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        // 1. Open wheel (240ms fan-out)
        unawaited(
          showUiJourneyWheel(
            savedCtx,
            items: items,
            activeId: 'b',
            anchor: anchor,
            onSelect: picked.add,
          ),
        );
        await tester.pump();
        final badgeAFinder = find.byKey(const ValueKey('journey-wheel-a'));
        expect(badgeAFinder, findsOneWidget);

        // Gate 9: Zero Opacity widgets inside UiJourneyWheel (uses FadeTransition).
        expect(
          find.descendant(
            of: find.byType(UiJourneyWheel),
            matching: find.byType(Opacity),
          ),
          findsNothing,
        );

        // Mid-flight open at t = 30ms (before dockOvershoot peak)
        await tester.pump(const Duration(milliseconds: 30));
        final midOpenCenter = tester.getCenter(badgeAFinder);
        expect(midOpenCenter.dy, lessThan(anchor.dy));

        // Settled open
        await tester.pumpAndSettle();
        final settledOpenCenter = tester.getCenter(badgeAFinder);
        expect(settledOpenCenter.dy, lessThan(midOpenCenter.dy));

        // 2. Normal tap with sub-pixel pointer jitter on badge A does NOT fire
        // a drag haptic inside UiJourneyWheel (seeded in onPointerDown);
        // dragging across badge A -> badge B fires selectionClick once on crossing.
        haptics.clear();
        final centerA = tester.getCenter(badgeAFinder);
        final centerB = tester.getCenter(
          find.byKey(const ValueKey('journey-wheel-b')),
        );
        final jitterGesture = await tester.startGesture(centerA);
        await jitterGesture.moveBy(const Offset(1.5, -1.0));
        await tester.pump();
        expect(haptics, isEmpty);
        await jitterGesture.moveTo(centerB);
        await tester.pump();
        expect(haptics, ['HapticFeedbackType.selectionClick']);
        await jitterGesture.cancel();
        await tester.pumpAndSettle();

        // 3. Dismiss via backdrop tap -> 170ms reverse fan-in with easeOutStrong.flipped
        // (at 85ms midpoint, >80% of the return travel toward anchor is already completed!)
        final settledOpenTop = tester.getTopLeft(badgeAFinder).dy;
        const anchorTop = 520.0 - 26.0; // anchor.dy - _badge / 2
        await tester.tapAt(const Offset(10, 10));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 85));

        expect(badgeAFinder, findsOneWidget);
        final midCloseTop = tester.getTopLeft(badgeAFinder).dy;
        final totalTravelDy = anchorTop - settledOpenTop;
        final elapsedTravelDy = midCloseTop - settledOpenTop;
        expect(elapsedTravelDy / totalTravelDy, greaterThan(0.80));
        expect(midCloseTop, lessThan(anchorTop));

        await tester.pumpAndSettle();
        expect(badgeAFinder, findsNothing);
        expect(tester.binding.transientCallbackCount, 0);
      },
    );

    testWidgets(
      'UiJourneyWheel under Reduce Motion (Android & iOS) uses 150ms opacity-only fade with zero arc translation',
      (tester) async {
        for (final useIosFlag in [false, true]) {
          if (useIosFlag) {
            tester.platformDispatcher.accessibilityFeaturesTestValue =
                const FakeAccessibilityFeatures(reduceMotion: true);
          }
          late BuildContext savedCtx;
          await tester.pumpWidget(
            _host(
              disableAnimations: !useIosFlag,
              Builder(
                builder: (context) {
                  savedCtx = context;
                  return const SizedBox.shrink();
                },
              ),
            ),
          );

          unawaited(
            showUiJourneyWheel(
              savedCtx,
              items: items,
              activeId: 'b',
              anchor: anchor,
              onSelect: (_) {},
            ),
          );
          await tester.pump();
          final badgeAFinder = find.byKey(const ValueKey('journey-wheel-a'));
          final startPos = tester.getTopLeft(badgeAFinder);

          await tester.pump(const Duration(milliseconds: 75));
          final midPos = tester.getTopLeft(badgeAFinder);
          // Zero spatial arc translation during Reduce Motion fade.
          expect(midPos, startPos);

          await tester.pump(const Duration(milliseconds: 100));
          expect(tester.getTopLeft(badgeAFinder), startPos);

          await tester.tap(find.byKey(const ValueKey('journey-wheel-close')));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 160));
          expect(badgeAFinder, findsNothing);
          expect(tester.binding.transientCallbackCount, 0);
          if (useIosFlag) {
            tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
          }
        }
      },
    );
  });

  group('M1 #12 — Bottom Sheets (showUiSheet) & Trigger-Anchored UiMenuAnchor', () {
    testWidgets(
      'showUiSheet animates 260ms enter (UiCurves.drawer) and 190ms exit (UiCurves.easeOutStrong)',
      (tester) async {
        await tester.pumpWidget(
          _host(
            Builder(
              builder: (context) => UiButton(
                label: 'Mở sheet',
                onPressed: () => showUiSheet<void>(
                  context: context,
                  builder: (_) => const Text('Sheet Body'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Mở sheet'));
        await tester.pump();
        final sheetOutline = find.byKey(const ValueKey('ui-sheet-outline'));
        expect(sheetOutline, findsOneWidget);
        final startTop = tester.getTopLeft(sheetOutline).dy;

        // Mid-flight at t = 130ms of 260ms entrance
        await tester.pump(const Duration(milliseconds: 130));
        final midTop = tester.getTopLeft(sheetOutline).dy;
        expect(midTop, lessThan(startTop));

        await tester.pumpAndSettle();
        final settledTop = tester.getTopLeft(sheetOutline).dy;
        expect(settledTop, lessThan(midTop));

        // Dismiss via scrim tap -> 190ms reverse exit
        await tester.tapAt(const Offset(20, 20));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 95));
        expect(sheetOutline, findsOneWidget);
        expect(tester.getTopLeft(sheetOutline).dy, greaterThan(settledTop));

        await tester.pumpAndSettle();
        expect(sheetOutline, findsNothing);
        expect(tester.binding.transientCallbackCount, 0);

        // Reduce Motion (Android & iOS): showUiSheet settles immediately in 0ms.
        for (final useIosFlag in [false, true]) {
          if (useIosFlag) {
            tester.platformDispatcher.accessibilityFeaturesTestValue =
                const FakeAccessibilityFeatures(reduceMotion: true);
          }
          await tester.pumpWidget(
            _host(
              disableAnimations: !useIosFlag,
              Builder(
                builder: (context) => UiButton(
                  label: 'Mở sheet RM',
                  onPressed: () => showUiSheet<void>(
                    context: context,
                    builder: (_) => const Text('Sheet Body RM'),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Mở sheet RM'));
          await tester.pump();
          expect(find.text('Sheet Body RM'), findsOneWidget);
          expect(tester.binding.transientCallbackCount, 0);
          await tester.tapAt(const Offset(20, 20));
          await tester.pump();
          expect(find.text('Sheet Body RM'), findsNothing);
          if (useIosFlag) {
            tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
          }
        }
      },
    );

    testWidgets(
      'UiMenuAnchor keeps OverlayPortal hidden when closed, plays 3-point open (180ms) and ease-out close (130ms) with trigger-corner Alignment, ScaleTransition(0.95 -> 1.0), FadeTransition, and selection haptic',
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

        var open = false;
        late StateSetter setHost;

        await tester.pumpWidget(
          _host(
            StatefulBuilder(
              builder: (context, setState) {
                setHost = setState;
                return UiMenuAnchor(
                  open: open,
                  onClose: () => setHost(() => open = false),
                  anchor: UiButton(
                    label: 'Menu',
                    expand: false,
                    onPressed: () => setHost(() => open = !open),
                  ),
                  menu: UiMenuSurface(
                    children: [
                      UiMenuItem(
                        key: const ValueKey('menu-item-1'),
                        label: 'Chỉnh sửa',
                        onPressed: () => setHost(() => open = false),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
        await tester.pump();

        // When closed initially, OverlayPortal does NOT mount the menu in Overlay.
        expect(find.byKey(const ValueKey('menu-item-1')), findsNothing);
        expect(find.byKey(const ValueKey('ui-menu-fade')), findsNothing);

        // 1. Open menu (180ms)
        setHost(() => open = true);
        await tester.pump();
        await tester.pump();
        expect(haptics, contains('HapticFeedbackType.selectionClick'));
        expect(find.byKey(const ValueKey('menu-item-1')), findsOneWidget);

        // Mid-flight at t = 90ms
        await tester.pump(const Duration(milliseconds: 90));
        final scaleTransition = tester.widget<ScaleTransition>(
          find.byKey(const ValueKey('ui-menu-scale')),
        );
        final fadeTransition = tester.widget<FadeTransition>(
          find.byKey(const ValueKey('ui-menu-fade')),
        );
        expect(scaleTransition.alignment, Alignment.topRight);
        expect(scaleTransition.scale.value, greaterThan(UiMotion.popMinScale));
        expect(scaleTransition.scale.value, lessThan(1.0));
        expect(fadeTransition.opacity.value, greaterThan(0.0));
        expect(fadeTransition.opacity.value, lessThan(1.0));

        // Settled at t >= 180ms
        await tester.pumpAndSettle();
        expect(scaleTransition.scale.value, 1.0);
        expect(fadeTransition.opacity.value, 1.0);

        // 2. Close menu via barrier tap (130ms ease-out exit before _portal.hide())
        await tester.tap(find.byKey(const ValueKey('ui-menu-barrier')));
        await tester.pump();

        // Mid-flight at t = 65ms: menu is still mounted in overlay while reversing
        // with easeOutStrong.flipped (opacity already < 0.25 at midpoint)!
        await tester.pump(const Duration(milliseconds: 65));
        expect(find.byKey(const ValueKey('menu-item-1')), findsOneWidget);
        expect(scaleTransition.scale.value, greaterThan(UiMotion.popMinScale));
        expect(scaleTransition.scale.value, lessThan(1.0));
        expect(fadeTransition.opacity.value, greaterThan(0.0));
        expect(fadeTransition.opacity.value, lessThan(0.25));

        // Settled at t >= 130ms: _portal.hide() called, overlay entry unmounted!
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('menu-item-1')), findsNothing);
        expect(find.byKey(const ValueKey('ui-menu-fade')), findsNothing);
        expect(tester.binding.transientCallbackCount, 0);
      },
    );

    testWidgets(
      'UiMenuAnchor under Reduce Motion (Android & iOS) uses 150ms opacity-only fade with zero ScaleTransition and hides portal on close',
      (tester) async {
        for (final useIosFlag in [false, true]) {
          if (useIosFlag) {
            tester.platformDispatcher.accessibilityFeaturesTestValue =
                const FakeAccessibilityFeatures(reduceMotion: true);
          }
          var open = false;
          late StateSetter setHost;

          await tester.pumpWidget(
            _host(
              disableAnimations: !useIosFlag,
              StatefulBuilder(
                builder: (context, setState) {
                  setHost = setState;
                  return UiMenuAnchor(
                    open: open,
                    onClose: () => setHost(() => open = false),
                    anchor: const Text('Trigger'),
                    menu: UiMenuSurface(
                      children: [
                        UiMenuItem(
                          key: const ValueKey('rm-menu-item'),
                          label: 'Mục 1',
                          onPressed: () {},
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
          await tester.pump();
          expect(find.byKey(const ValueKey('rm-menu-item')), findsNothing);

          setHost(() => open = true);
          await tester.pump();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 75));
          expect(
            find.ancestor(
              of: find.byType(UiMenuSurface),
              matching: find.byType(ScaleTransition),
            ),
            findsNothing,
          );

          await tester.pump(const Duration(milliseconds: 100));
          expect(find.byKey(const ValueKey('rm-menu-item')), findsOneWidget);

          setHost(() => open = false);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 160));
          expect(find.byKey(const ValueKey('rm-menu-item')), findsNothing);
          expect(tester.binding.transientCallbackCount, 0);
          if (useIosFlag) {
            tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
          }
        }
      },
    );
  });

  group('M1 #10 & #15 — UiSegmented, UiEmptyState, UiSkeleton, Progress & Toast', () {
    testWidgets(
      'UiSegmented (fixed & scrollable) slides active 2dp sticker capsule over 220ms (UiCurves.easeInOutStrong), keeps active pressScale at 1.0, and snaps in 0ms under Android & iOS Reduce Motion',
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

        for (final isScrollable in [false, true]) {
          var selected = 'a';
          late StateSetter setHost;

          await tester.pumpWidget(
            _host(
              StatefulBuilder(
                builder: (context, setState) {
                  setHost = setState;
                  return SizedBox(
                    width: 320,
                    child: UiSegmented<String>(
                      scrollable: isScrollable,
                      segments: const [
                        UiSegment(
                          key: ValueKey('seg-a'),
                          value: 'a',
                          label: 'Đang chạy',
                        ),
                        UiSegment(
                          key: ValueKey('seg-b'),
                          value: 'b',
                          label: 'Đã xong',
                          showDot: true,
                        ),
                      ],
                      value: selected,
                      onChanged: (v) => setHost(() => selected = v),
                    ),
                  );
                },
              ),
            ),
          );

          final pillBox = find.byKey(const ValueKey('ui-segmented-pill-box'));
          expect(pillBox, findsOneWidget);
          final deco =
              tester.widget<DecoratedBox>(pillBox).decoration as BoxDecoration;
          expect((deco.border! as Border).top.width, UiBorder.standard);
          expect(deco.boxShadow!.single.offset, const Offset(2, 2));

          // Active tab does not shrink to 0.96 on press (pressScale == 1.0).
          final activePressable = tester.widget<UiPressable>(
            find.byKey(const ValueKey('seg-a')),
          );
          expect(activePressable.pressScale, 1.0);

          final startX = tester.getTopLeft(pillBox).dx;

          // Tap segment B -> 3-point check (t=0, t=110ms, t=settled)
          haptics.clear();
          await tester.tap(find.byKey(const ValueKey('seg-b')));
          await tester.pump();
          expect(haptics, contains('HapticFeedbackType.selectionClick'));

          await tester.pump(const Duration(milliseconds: 110));
          final midX = tester.getTopLeft(pillBox).dx;
          expect(midX, greaterThan(startX));

          await tester.pumpAndSettle();
          final endX = tester.getTopLeft(pillBox).dx;
          expect(endX, greaterThan(midX));
          expect(tester.binding.transientCallbackCount, 0);

          // Reduce Motion (Android & iOS): snaps in 0ms on the very first pump.
          for (final useIosFlag in [false, true]) {
            if (useIosFlag) {
              tester.platformDispatcher.accessibilityFeaturesTestValue =
                  const FakeAccessibilityFeatures(reduceMotion: true);
            }
            selected = 'a';
            await tester.pumpWidget(
              _host(
                disableAnimations: !useIosFlag,
                StatefulBuilder(
                  builder: (context, setState) {
                    setHost = setState;
                    return SizedBox(
                      width: 320,
                      child: UiSegmented<String>(
                        scrollable: isScrollable,
                        segments: const [
                          UiSegment(
                            key: ValueKey('seg-a'),
                            value: 'a',
                            label: 'Đang chạy',
                          ),
                          UiSegment(
                            key: ValueKey('seg-b'),
                            value: 'b',
                            label: 'Đã xong',
                          ),
                        ],
                        value: selected,
                        onChanged: (v) => setHost(() => selected = v),
                      ),
                    );
                  },
                ),
              ),
            );
            await tester.tap(find.byKey(const ValueKey('seg-b')));
            await tester.pump();
            expect(tester.getTopLeft(pillBox).dx, greaterThan(startX));
            expect(tester.binding.transientCallbackCount, 0);
            if (useIosFlag) {
              tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
            }
          }
        }
      },
    );

    testWidgets(
      'UiEmptyState 3-point mount settle (220ms scale 0.96 -> 1.0 + fade) and Reduce Motion parity; UiSkeleton isolates RepaintBoundary',
      (tester) async {
        await tester.pumpWidget(
          _host(
            const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                UiEmptyState(
                  glyph: OurneyIcon(name: 'inbox', size: 28),
                  title: 'Chưa có thông báo',
                ),
                UiSkeleton(width: 120, height: 18),
              ],
            ),
          ),
        );

        // UiSkeleton is wrapped in RepaintBoundary.
        expect(
          find.descendant(
            of: find.byType(UiSkeleton),
            matching: find.byType(RepaintBoundary),
          ),
          findsOneWidget,
        );

        final emptyScale = tester.widget<ScaleTransition>(
          find.descendant(
            of: find.byType(UiEmptyState),
            matching: find.byType(ScaleTransition),
          ),
        );
        final emptyFade = tester.widget<FadeTransition>(
          find.descendant(
            of: find.byType(UiEmptyState),
            matching: find.byType(FadeTransition),
          ),
        );
        expect(emptyScale.scale.value, closeTo(0.96, 0.001));
        expect(emptyFade.opacity.value, 0.0);

        // Mid-flight at t = 110ms
        await tester.pump(const Duration(milliseconds: 110));
        expect(emptyScale.scale.value, greaterThan(0.96));
        expect(emptyScale.scale.value, lessThan(1.0));
        expect(emptyFade.opacity.value, greaterThan(0.0));
        expect(emptyFade.opacity.value, lessThan(1.0));

        // Settled at t = 220ms
        await tester.pump(const Duration(milliseconds: 120));
        expect(emptyScale.scale.value, 1.0);
        expect(emptyFade.opacity.value, 1.0);

        // Reduce Motion: zero ScaleTransition on UiEmptyState and stopped UiSkeleton ticker.
        await tester.pumpWidget(
          _host(
            disableAnimations: true,
            const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                UiEmptyState(
                  glyph: OurneyIcon(name: 'inbox', size: 28),
                  title: 'Trống',
                ),
                UiSkeleton(width: 120, height: 18),
              ],
            ),
          ),
        );
        await tester.pump();
        expect(
          find.descendant(
            of: find.byType(UiEmptyState),
            matching: find.byType(ScaleTransition),
          ),
          findsNothing,
        );
        expect(tester.binding.transientCallbackCount, 0);
      },
    );

    testWidgets(
      'UiProgressBar and UiProgressRing (with RepaintBoundary) glide over 320ms on value change and snap in 0ms under Android & iOS Reduce Motion',
      (tester) async {
        var progress = 0.2;
        late StateSetter setHost;

        await tester.pumpWidget(
          _host(
            StatefulBuilder(
              builder: (context, setState) {
                setHost = setState;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 200,
                      child: UiProgressBar(value: progress),
                    ),
                    UiProgressRing(value: progress, label: '6/30'),
                  ],
                );
              },
            ),
          ),
        );

        // UiProgressRing isolates its CustomPaint inside a RepaintBoundary.
        expect(
          find.descendant(
            of: find.byType(UiProgressRing),
            matching: find.byType(RepaintBoundary),
          ),
          findsOneWidget,
        );

        double currentBarFactor() => tester
            .widget<FractionallySizedBox>(
              find.descendant(
                of: find.byType(UiProgressBar),
                matching: find.byType(FractionallySizedBox),
              ),
            )
            .widthFactor!;

        double currentRingValue() =>
            (tester
                        .widget<CustomPaint>(
                          find.descendant(
                            of: find.byType(UiProgressRing),
                            matching: find.byType(CustomPaint),
                          ),
                        )
                        .painter!
                    as dynamic)
                .value
                as double;

        expect(currentBarFactor(), closeTo(0.2, 0.001));
        expect(currentRingValue(), closeTo(0.2, 0.001));

        // Update 0.2 -> 0.8 (320ms glide)
        setHost(() => progress = 0.8);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 160));
        expect(currentBarFactor(), greaterThan(0.2));
        expect(currentBarFactor(), lessThan(0.8));
        expect(currentRingValue(), greaterThan(0.2));
        expect(currentRingValue(), lessThan(0.8));

        await tester.pumpAndSettle();
        expect(currentBarFactor(), closeTo(0.8, 0.001));
        expect(currentRingValue(), closeTo(0.8, 0.001));
        expect(tester.binding.transientCallbackCount, 0);

        // Reduce Motion (Android & iOS): snaps to new value in 0ms.
        for (final useIosFlag in [false, true]) {
          if (useIosFlag) {
            tester.platformDispatcher.accessibilityFeaturesTestValue =
                const FakeAccessibilityFeatures(reduceMotion: true);
          }
          progress = 0.2;
          await tester.pumpWidget(
            _host(
              disableAnimations: !useIosFlag,
              StatefulBuilder(
                builder: (context, setState) {
                  setHost = setState;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 200,
                        child: UiProgressBar(value: progress),
                      ),
                      UiProgressRing(value: progress, label: '6/30'),
                    ],
                  );
                },
              ),
            ),
          );
          setHost(() => progress = 0.9);
          await tester.pump();
          expect(currentBarFactor(), closeTo(0.9, 0.001));
          expect(currentRingValue(), closeTo(0.9, 0.001));
          expect(tester.binding.transientCallbackCount, 0);
          if (useIosFlag) {
            tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
          }
        }
      },
    );

    testWidgets(
      'showUiToast 3-point 200ms upward slide (12dp -> 0) + fade entrance, 150ms ease-out exit, semantic haptics (no substring false-positives), and Android & iOS Reduce Motion parity',
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

        late BuildContext savedCtx;
        await tester.pumpWidget(
          _host(
            Builder(
              builder: (context) {
                savedCtx = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        // 1. Info toast (even with "Error" / "lỗi" in journey title): zero haptic, 200ms 12dp -> 0 upward slide.
        showUiToast(savedCtx, 'Đã lưu hành trình Trial & Error - Sửa lỗi phát âm');
        await tester.pump();
        expect(haptics, isEmpty);

        await tester.pump(const Duration(milliseconds: 80));
        final midDy = tester
            .widget<Transform>(
              find.byKey(const ValueKey('ui-toast-translate')),
            )
            .transform
            .getTranslation()
            .y;
        expect(midDy, greaterThan(0.0));
        expect(midDy, lessThan(12.0));

        await tester.pump(const Duration(milliseconds: 150));
        final settledDy = tester
            .widget<Transform>(
              find.byKey(const ValueKey('ui-toast-translate')),
            )
            .transform
            .getTranslation()
            .y;
        expect(settledDy, closeTo(0.0, 0.01));

        // Clear first toast before testing the routine error toast.
        ScaffoldMessenger.of(savedCtx).removeCurrentSnackBar();
        await tester.pumpAndSettle();

        // 2. Routine error toast (isError: true, hasAction: false) fires UiHaptics.reject (lightImpact).
        showUiToast(savedCtx, 'Chưa có mã trong bộ nhớ tạm', isError: true);
        await tester.pump();
        expect(haptics, ['HapticFeedbackType.lightImpact']);
        ScaffoldMessenger.of(savedCtx).removeCurrentSnackBar();
        await tester.pumpAndSettle();

        // 3. Undo toast (hasAction: true) fires UiHaptics.warning (heavyImpact).
        haptics.clear();
        showUiToast(
          savedCtx,
          'Đã lưu trữ hành trình',
          actionLabel: 'Hoàn tác',
          onAction: () {},
        );
        await tester.pump();
        expect(haptics, contains('HapticFeedbackType.heavyImpact'));

        // Tap action dismisses over 150ms ease-out exit (>75% travel completed at 75ms midpoint).
        await tester.pump(const Duration(milliseconds: 220));
        await tester.tap(find.byKey(const ValueKey('ui-toast-action')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 75));
        final exitMidDy = tester
            .widget<Transform>(
              find.byKey(const ValueKey('ui-toast-translate')),
            )
            .transform
            .getTranslation()
            .y;
        expect(exitMidDy, greaterThan(9.0));
        expect(exitMidDy, lessThan(12.0));

        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('ui-toast')), findsNothing);

        // 4. Reduce Motion (Android & iOS): no vertical Transform.translate on toast.
        for (final useIosFlag in [false, true]) {
          if (useIosFlag) {
            tester.platformDispatcher.accessibilityFeaturesTestValue =
                const FakeAccessibilityFeatures(reduceMotion: true);
          }
          await tester.pumpWidget(
            _host(
              disableAnimations: !useIosFlag,
              Builder(
                builder: (context) {
                  savedCtx = context;
                  return const SizedBox.shrink();
                },
              ),
            ),
          );
          showUiToast(savedCtx, 'Đã sao chép');
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 75));
          expect(find.byKey(const ValueKey('ui-toast-translate')), findsNothing);
          await tester.pump(const Duration(seconds: 5));
          await tester.pumpAndSettle();
          if (useIosFlag) {
            tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
          }
        }
      },
    );
  });

  group('M1 #15.3 — ReminderBannerHost & MissedDayOverlay Exit Choreography', () {
    testWidgets(
      'ReminderBannerHost 3-point enter (220ms, -28dp -> 0), ease-out exit (160ms, 0 -> -16dp), mid-entrance dismiss without jump, double-tap protection, and Reduce Motion parity',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final openedJourneys = <String>[];

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: _host(
              withL10n: true,
              ReminderBannerHost(
                onOpenJourneyCamera: openedJourneys.add,
                child: const SizedBox.expand(),
              ),
            ),
          ),
        );

        // 1. Show banner -> 220ms enter (-28dp -> 0)
        container.read(reminderBannerProvider.notifier).show(
          const ReminderBannerData(
            journeyId: 'j1',
            journeyName: 'Chạy sáng',
            skinId: 'flexer',
            kind: ReminderBannerKind.streak,
            streak: 14,
          ),
        );
        await tester.pump();
        expect(find.byType(ReminderBanner), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(ReminderBanner),
            matching: find.byType(Opacity),
          ),
          findsNothing,
        );

        // Mid-flight enter at t = 110ms
        await tester.pump(const Duration(milliseconds: 110));
        final enterMidDy = tester
            .widget<Transform>(
              find.byKey(const ValueKey('reminder-banner-translate')),
            )
            .transform
            .getTranslation()
            .y;
        expect(enterMidDy, lessThan(0.0));
        expect(enterMidDy, greaterThan(-28.0));

        await tester.pumpAndSettle();
        expect(
          tester
              .widget<Transform>(
                find.byKey(const ValueKey('reminder-banner-translate')),
              )
              .transform
              .getTranslation()
              .y,
          0.0,
        );

        // 2. Tap banner open twice rapidly during 160ms exit -> IgnorePointer prevents double navigation,
        // and easeOutStrong.flipped completes >75% of -16dp exit travel at 80ms midpoint!
        await tester.tap(find.byKey(const ValueKey('reminder-banner-open')));
        await tester.pump();
        expect(container.read(reminderBannerProvider), isNull);
        expect(openedJourneys, ['j1']);

        // Second tap while exiting at t = 80ms must be ignored.
        await tester.pump(const Duration(milliseconds: 80));
        expect(find.byType(ReminderBanner), findsOneWidget);
        await tester.tap(
          find.byKey(const ValueKey('reminder-banner-open')),
          warnIfMissed: false,
        );
        await tester.pump();
        expect(openedJourneys, ['j1']);

        final exitMidDy = tester
            .widget<Transform>(
              find.byKey(const ValueKey('reminder-banner-translate')),
            )
            .transform
            .getTranslation()
            .y;
        expect(exitMidDy, lessThan(-12.0));
        expect(exitMidDy, greaterThan(-16.0));

        await tester.pumpAndSettle();
        expect(find.byType(ReminderBanner), findsNothing);

        // 3. Mid-entrance dismiss at t = 60ms: zero single-frame vertical jump!
        container.read(reminderBannerProvider.notifier).show(
          const ReminderBannerData(
            journeyId: 'j2',
            journeyName: 'Đọc sách',
            skinId: 'minimal',
            kind: ReminderBannerKind.daily,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 60));
        final dyBeforeReverse = tester
            .widget<Transform>(
              find.byKey(const ValueKey('reminder-banner-translate')),
            )
            .transform
            .getTranslation()
            .y;
        await tester.tap(find.byKey(const ValueKey('reminder-banner-dismiss')));
        await tester.pump();
        final dyOnReverseFrame = tester
            .widget<Transform>(
              find.byKey(const ValueKey('reminder-banner-translate')),
            )
            .transform
            .getTranslation()
            .y;
        expect(dyOnReverseFrame, closeTo(dyBeforeReverse, 0.5));
        await tester.pumpAndSettle();
        expect(find.byType(ReminderBanner), findsNothing);
        expect(tester.binding.transientCallbackCount, 0);

        // 4. Reduce Motion (Android & iOS): 150ms opacity-only fade with zero reminder-banner-translate.
        for (final useIosFlag in [false, true]) {
          if (useIosFlag) {
            tester.platformDispatcher.accessibilityFeaturesTestValue =
                const FakeAccessibilityFeatures(reduceMotion: true);
          }
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: _host(
                withL10n: true,
                disableAnimations: !useIosFlag,
                ReminderBannerHost(
                  onOpenJourneyCamera: (_) {},
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          );
          container.read(reminderBannerProvider.notifier).show(
            const ReminderBannerData(
              journeyId: 'j-rm',
              journeyName: 'RM',
              skinId: 'quiet',
              kind: ReminderBannerKind.daily,
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 75));
          expect(
            find.byKey(const ValueKey('reminder-banner-translate')),
            findsNothing,
          );
          await tester.pumpAndSettle();
          container.read(reminderBannerProvider.notifier).dismiss();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 160));
          expect(find.byType(ReminderBanner), findsNothing);
          if (useIosFlag) {
            tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
          }
        }
      },
    );

    testWidgets(
      'MissedDayOverlay 3-point enter (200ms) and ease-out exit (160ms upward -16dp), mid-entrance dismiss without jump, lazy controller init, and Android & iOS Reduce Motion dismiss parity',
      (tester) async {
        // Unsupported skin allocates zero tickers and renders nothing.
        await tester.pumpWidget(
          _host(
            withL10n: true,
            const MissedDayOverlay(skinId: 'memory', day: 4),
          ),
        );
        expect(find.byKey(const ValueKey('missed-day-chip')), findsNothing);
        expect(tester.binding.transientCallbackCount, 0);

        var visible = true;
        var dismissed = 0;
        late StateSetter setHost;

        await tester.pumpWidget(
          _host(
            withL10n: true,
            StatefulBuilder(
              builder: (context, setState) {
                setHost = setState;
                return MissedDayOverlay(
                  skinId: 'squad',
                  day: 9,
                  visible: visible,
                  onDismiss: () => dismissed++,
                );
              },
            ),
          ),
        );

        // Mid-flight enter at t = 100ms
        await tester.pump(const Duration(milliseconds: 100));
        final enterDy = tester
            .widget<Transform>(
              find.byKey(const ValueKey('missed-day-translate')),
            )
            .transform
            .getTranslation()
            .y;
        expect(enterDy, greaterThan(0.0));
        expect(enterDy, lessThan(6.0));

        await tester.pumpAndSettle();
        expect(
          tester
              .widget<Transform>(
                find.byKey(const ValueKey('missed-day-translate')),
              )
              .transform
              .getTranslation()
              .y,
          0.0,
        );

        // Dismiss (visible: true -> false) -> 160ms upward -16dp ease-out exit (>75% travel at 80ms midpoint)
        setHost(() => visible = false);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));
        expect(find.byKey(const ValueKey('missed-day-chip')), findsOneWidget);
        final exitDy = tester
            .widget<Transform>(
              find.byKey(const ValueKey('missed-day-translate')),
            )
            .transform
            .getTranslation()
            .y;
        expect(exitDy, lessThan(-12.0));
        expect(exitDy, greaterThan(-16.0));

        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('missed-day-chip')), findsNothing);
        expect(dismissed, 1);
        expect(tester.binding.transientCallbackCount, 0);

        // Mid-entrance dismiss at t = 60ms: zero single-frame vertical jump!
        setHost(() => visible = true);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 60));
        final dyBeforeReverse = tester
            .widget<Transform>(
              find.byKey(const ValueKey('missed-day-translate')),
            )
            .transform
            .getTranslation()
            .y;
        setHost(() => visible = false);
        await tester.pump();
        final dyOnReverseFrame = tester
            .widget<Transform>(
              find.byKey(const ValueKey('missed-day-translate')),
            )
            .transform
            .getTranslation()
            .y;
        expect(dyOnReverseFrame, closeTo(dyBeforeReverse, 0.5));
        await tester.pumpAndSettle();

        // Reduce Motion parity (Android & iOS): no missed-day-translate wrapper on enter or dismiss.
        for (final useIosFlag in [false, true]) {
          if (useIosFlag) {
            tester.platformDispatcher.accessibilityFeaturesTestValue =
                const FakeAccessibilityFeatures(reduceMotion: true);
          }
          visible = true;
          dismissed = 0;
          await tester.pumpWidget(
            _host(
              withL10n: true,
              disableAnimations: !useIosFlag,
              StatefulBuilder(
                builder: (context, setState) {
                  setHost = setState;
                  return MissedDayOverlay(
                    skinId: 'quiet',
                    day: 5,
                    visible: visible,
                    onDismiss: () => dismissed++,
                  );
                },
              ),
            ),
          );
          await tester.pump();
          expect(
            find.byKey(const ValueKey('missed-day-translate')),
            findsNothing,
          );
          expect(find.byKey(const ValueKey('missed-day-chip')), findsOneWidget);
          expect(tester.binding.transientCallbackCount, 0);

          setHost(() => visible = false);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 160));
          expect(find.byKey(const ValueKey('missed-day-chip')), findsNothing);
          expect(dismissed, 1);
          expect(tester.binding.transientCallbackCount, 0);
          if (useIosFlag) {
            tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
          }
        }
      },
    );
  });
}
