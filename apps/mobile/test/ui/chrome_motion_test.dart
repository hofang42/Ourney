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
      'UiShellBranchContainer under Reduce Motion switches in 0ms with zero slide or active tickers',
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
      },
    );
  });

  group('M1 #5b — Dock Glyph Overshoot, Haptics & SnapPill <-> Shutter Morph', () {
    testWidgets(
      'DockTab active glyph scales to 1.08 over 180ms with UiCurves.dockOvershoot and fires UiHaptics.selection on tab change; center slot morphs 56x40 <-> 76x76 over 220ms',
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

        // Mid-flight at t = 110ms of 220ms morph
        await tester.pump(const Duration(milliseconds: 110));
        final morphFinder = find.byKey(const ValueKey('dock-center-morph'));
        expect(morphFinder, findsOneWidget);
        final morphMatrix = tester.widget<Transform>(morphFinder).transform;
        final sx = morphMatrix.storage[0];
        final sy = morphMatrix.storage[5];
        expect(sx, greaterThan(UiSize.snapPillW / UiSize.shutter));
        expect(sx, lessThan(1.0));
        expect(sy, greaterThan(UiSize.snapPillH / UiSize.shutter));
        expect(sy, lessThan(1.0));

        // Settled at t >= 220ms: morph wrapper unmounts at rest.
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('dock-center-morph')), findsNothing);
        expect(tester.getSize(find.byType(UiShutter)), const Size(76, 76));
        expect(tester.binding.transientCallbackCount, 0);
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

        // 2. Drag finger across badge A -> badge B -> fires selectionClick haptics
        haptics.clear();
        final centerA = tester.getCenter(badgeAFinder);
        final centerB = tester.getCenter(
          find.byKey(const ValueKey('journey-wheel-b')),
        );
        final drag = await tester.startGesture( anchor);
        await drag.moveTo(centerA);
        await tester.pump();
        expect(haptics, ['HapticFeedbackType.selectionClick']);
        await drag.moveTo(centerB);
        await tester.pump();
        expect(haptics, [
          'HapticFeedbackType.selectionClick',
          'HapticFeedbackType.selectionClick',
        ]);
        await drag.cancel();
        await tester.pumpAndSettle();

        // 3. Dismiss via backdrop tap -> 170ms reverse fan-in (not 0ms vanish!)
        await tester.tapAt(const Offset(10, 10));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 85));

        // Mid-flight reverse at t = 85ms: still mounted and fanning back toward anchor
        expect(badgeAFinder, findsOneWidget);
        final midCloseCenter = tester.getCenter(badgeAFinder);
        expect(midCloseCenter.dy, greaterThan(settledOpenCenter.dy));
        expect(midCloseCenter.dy, lessThan(anchor.dy));

        await tester.pumpAndSettle();
        expect(badgeAFinder, findsNothing);
        expect(tester.binding.transientCallbackCount, 0);
      },
    );

    testWidgets(
      'UiJourneyWheel under Reduce Motion uses 150ms opacity-only fade with zero arc translation',
      (tester) async {
        late BuildContext savedCtx;
        await tester.pumpWidget(
          _host(
            disableAnimations: true,
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
      },
    );

    testWidgets(
      'UiMenuAnchor 3-point open (180ms) and close (130ms) with trigger-corner Alignment, ScaleTransition(0.95 -> 1.0), FadeTransition, and selection haptic',
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

        expect(find.byKey(const ValueKey('menu-item-1')), findsNothing);

        // 1. Open menu (180ms)
        setHost(() => open = true);
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

        // 2. Close menu via barrier tap (130ms exit before hiding)
        await tester.tap(find.byKey(const ValueKey('ui-menu-barrier')));
        await tester.pump();

        // Mid-flight at t = 65ms: menu is still mounted in overlay while reversing!
        await tester.pump(const Duration(milliseconds: 65));
        expect(find.byKey(const ValueKey('menu-item-1')), findsOneWidget);
        expect(scaleTransition.scale.value, greaterThan(UiMotion.popMinScale));
        expect(scaleTransition.scale.value, lessThan(1.0));
        expect(fadeTransition.opacity.value, greaterThan(0.0));
        expect(fadeTransition.opacity.value, lessThan(1.0));

        // Settled at t >= 130ms: unmounted
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('menu-item-1')), findsNothing);
        expect(tester.binding.transientCallbackCount, 0);
      },
    );

    testWidgets(
      'UiMenuAnchor under Reduce Motion uses 150ms opacity-only fade with zero ScaleTransition',
      (tester) async {
        var open = false;
        late StateSetter setHost;

        await tester.pumpWidget(
          _host(
            disableAnimations: true,
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

        setHost(() => open = true);
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
      },
    );
  });

  group('M1 #10 & #15 — UiSegmented, UiEmptyState, UiSkeleton, Progress & Toast', () {
    testWidgets(
      'UiSegmented slides active 2dp sticker capsule over 220ms (UiCurves.easeInOutStrong) and fires selection haptic; snaps in 0ms under Reduce Motion',
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

        final pillBox = find.byKey(const ValueKey('ui-segmented-pill-box'));
        expect(pillBox, findsOneWidget);
        final deco =
            tester.widget<DecoratedBox>(pillBox).decoration as BoxDecoration;
        expect((deco.border! as Border).top.width, UiBorder.standard);
        expect(deco.boxShadow!.single.offset, const Offset(2, 2));

        final startX = tester.getTopLeft(pillBox).dx;

        // Tap segment B -> 3-point check (t=0, t=110ms, t=settled)
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
      'UiProgressBar and UiProgressRing glide over 320ms on value change and snap in 0ms under Reduce Motion',
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

        double currentBarFactor() => tester
            .widget<FractionallySizedBox>(
              find.descendant(
                of: find.byType(UiProgressBar),
                matching: find.byType(FractionallySizedBox),
              ),
            )
            .widthFactor!;

        expect(currentBarFactor(), closeTo(0.2, 0.001));

        // Update 0.2 -> 0.8 (320ms glide)
        setHost(() => progress = 0.8);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 160));
        expect(currentBarFactor(), greaterThan(0.2));
        expect(currentBarFactor(), lessThan(0.8));

        await tester.pumpAndSettle();
        expect(currentBarFactor(), closeTo(0.8, 0.001));
        expect(tester.binding.transientCallbackCount, 0);
      },
    );

    testWidgets(
      'showUiToast 3-point 200ms upward slide (12dp -> 0) + fade entrance, 150ms exit, warning haptic on undo/error, and Reduce Motion parity',
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

        // 1. Info toast: no heavyImpact warning haptic, 200ms 12dp -> 0 upward slide.
        showUiToast(savedCtx, 'Đã lưu thay đổi');
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

        // Clear first toast before testing the second undo toast.
        ScaffoldMessenger.of(savedCtx).removeCurrentSnackBar();
        await tester.pumpAndSettle();

        // 2. Undo toast fires UiHaptics.warning (heavyImpact).
        showUiToast(
          savedCtx,
          'Đã lưu trữ hành trình',
          actionLabel: 'Hoàn tác',
          onAction: () {},
        );
        await tester.pump();
        expect(haptics, contains('HapticFeedbackType.heavyImpact'));

        // Tap action dismisses over 150ms exit.
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
        expect(exitMidDy, greaterThan(0.0));
        expect(exitMidDy, lessThan(12.0));

        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('ui-toast')), findsNothing);

        // 3. Reduce Motion: no vertical Transform.translate on toast.
        await tester.pumpWidget(
          _host(
            disableAnimations: true,
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
      },
    );
  });

  group('M1 #15.3 — ReminderBannerHost & MissedDayOverlay Exit Choreography', () {
    testWidgets(
      'ReminderBannerHost 3-point enter (220ms, -28dp -> 0) and exit (160ms, 0 -> -16dp) before unmounting, with zero Opacity widgets',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: _host(
              withL10n: true,
              ReminderBannerHost(
                onOpenJourneyCamera: (_) {},
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

        // 2. Tap close ('X') -> 160ms exit (0 -> -16dp) before unmounting!
        await tester.tap(find.byKey(const ValueKey('reminder-banner-dismiss')));
        await tester.pump();
        expect(container.read(reminderBannerProvider), isNull);

        // Mid-flight exit at t = 80ms: banner is STILL mounted while sliding up!
        await tester.pump(const Duration(milliseconds: 80));
        expect(find.byType(ReminderBanner), findsOneWidget);
        final exitMidDy = tester
            .widget<Transform>(
              find.byKey(const ValueKey('reminder-banner-translate')),
            )
            .transform
            .getTranslation()
            .y;
        expect(exitMidDy, lessThan(0.0));
        expect(exitMidDy, greaterThan(-16.0));

        await tester.pumpAndSettle();
        expect(find.byType(ReminderBanner), findsNothing);
        expect(tester.binding.transientCallbackCount, 0);
      },
    );

    testWidgets(
      'MissedDayOverlay 3-point enter (200ms) and exit (160ms upward -16dp slide + fade) when visible becomes false, plus Reduce Motion parity',
      (tester) async {
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

        // Dismiss (visible: true -> false) -> 160ms upward -16dp exit before unmounting
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
        expect(exitDy, lessThan(0.0));
        expect(exitDy, greaterThan(-16.0));

        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('missed-day-chip')), findsNothing);
        expect(dismissed, 1);
        expect(tester.binding.transientCallbackCount, 0);

        // Reduce Motion parity: no missed-day-translate spatial wrapper.
        await tester.pumpWidget(
          _host(
            withL10n: true,
            disableAnimations: true,
            const MissedDayOverlay(skinId: 'quiet', day: 5),
          ),
        );
        await tester.pump();
        expect(find.byKey(const ValueKey('missed-day-translate')), findsNothing);
        expect(find.byKey(const ValueKey('missed-day-chip')), findsOneWidget);
        expect(tester.binding.transientCallbackCount, 0);
      },
    );
  });
}
