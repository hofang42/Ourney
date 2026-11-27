import 'dart:io';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/ui/components/dock.dart';
import 'package:ourney/ui/components/glass.dart';
import 'package:ourney/ui/components/ourney_icons.dart';
import 'package:ourney/ui/components/pressable.dart';
import 'package:ourney/ui/components/skin_scope.dart';
import 'package:ourney/ui/skins.dart';
import 'package:ourney/ui/theme.dart';
import 'package:ourney/ui/tokens.dart';
import 'package:ourney/ui/typography.dart';

const _viLabels = ['Hành trình', 'Nhóm', 'Hoạt động', 'Hồ sơ'];
const _tabKeys = [
  'dock-journeys',
  'dock-groups',
  'dock-activity',
  'dock-profile',
];
const _glyphs = ['journeys', 'squad', 'activity', 'profile'];

Future<void> _loadBodyFont() async {
  final loader = FontLoader(UiFonts.body);
  for (final file in [
    'assets/fonts/BeVietnamPro-Regular.ttf',
    'assets/fonts/BeVietnamPro-Medium.ttf',
    'assets/fonts/BeVietnamPro-SemiBold.ttf',
    'assets/fonts/BeVietnamPro-Bold.ttf',
  ]) {
    final bytes = File(file).readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

UiDock _buildDock({
  int active = 0,
  bool compact = false,
  bool camera = false,
  ValueChanged<int>? onSelect,
  VoidCallback? onSnap,
}) {
  UiDockItem item(int i) => UiDockItem(
    itemKey: ValueKey(_tabKeys[i]),
    glyph: _glyphs[i],
    label: _viLabels[i],
    active: active == i,
    onPressed: () => onSelect?.call(i),
  );
  return UiDock(
    camera: camera,
    compact: compact,
    left: item(0),
    extraLeft: [item(1)],
    extraRight: [item(2)],
    right: item(3),
    snapLabel: 'Chụp',
    snapKey: const ValueKey('dock-snap-pill'),
    onSnap: onSnap ?? () {},
    center: camera ? UiShutter(label: 'Chụp', onPressed: () {}) : null,
  );
}

Future<void> _pumpDock(
  WidgetTester tester, {
  required double width,
  int active = 0,
  bool compact = false,
  bool camera = false,
  double textScale = 1.0,
  Brightness brightness = Brightness.light,
  String? skinId,
  bool disableAnimations = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 800);
  addTearDown(tester.view.reset);

  Widget dock = Align(
    alignment: Alignment.bottomCenter,
    child: _buildDock(active: active, compact: compact, camera: camera),
  );
  if (skinId != null) {
    dock = UiSkinScope(skinId: skinId, child: dock);
  }

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: OurneyTheme.build(brightness),
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, 800),
          textScaler: TextScaler.linear(textScale),
          disableAnimations: disableAnimations,
        ),
        child: Scaffold(body: dock),
      ),
    ),
  );
}

Rect _cameraCircleRect(WidgetTester tester) {
  final snap = find.byKey(const ValueKey('dock-snap-pill'));
  final containers = find.descendant(
    of: snap,
    matching: find.byType(Container),
  );
  for (final e in containers.evaluate()) {
    final c = e.widget as Container;
    if (c.decoration is BoxDecoration &&
        (c.decoration! as BoxDecoration).shape == BoxShape.circle) {
      return tester.getRect(find.byWidget(c));
    }
  }
  return tester.getRect(snap);
}

void main() {
  setUpAll(_loadBodyFont);

  group('T1 — Pure E4 (C1) Geometry (UiDockGeometry.compute)', () {
    const cases =
        <
          ({
            double w,
            String state,
            double cam,
            double islandH,
            double bandH,
            double slot,
            double leftL,
            double leftR,
            double rightL,
            double rightR,
            List<double> centres,
            double? capW,
          })
        >[
          (
            w: 360,
            state: 'shown',
            cam: 60,
            islandH: 64,
            bandH: 64,
            slot: 61,
            leftL: 12,
            leftR: 144,
            rightL: 216,
            rightR: 348,
            centres: [47.5, 108.5, 180, 251.5, 312.5],
            capW: 59,
          ),
          (
            w: 360,
            state: 'compact',
            cam: 52,
            islandH: 52,
            bandH: 64,
            slot: 63,
            leftL: 12,
            leftR: 148,
            rightL: 212,
            rightR: 348,
            centres: [48.5, 111.5, 180, 248.5, 311.5],
            capW: null,
          ),
          (
            w: 360,
            state: 'camera route',
            cam: 76,
            islandH: 64,
            bandH: 76,
            slot: 57,
            leftL: 12,
            leftR: 136,
            rightL: 224,
            rightR: 348,
            centres: [45.5, 102.5, 180, 257.5, 314.5],
            capW: null,
          ),
          (
            w: 390,
            state: 'shown',
            cam: 60,
            islandH: 64,
            bandH: 64,
            slot: 68.5,
            leftL: 12,
            leftR: 159,
            rightL: 231,
            rightR: 378,
            centres: [51.25, 119.75, 195, 270.25, 338.75],
            capW: 66.5,
          ),
          (
            w: 390,
            state: 'compact',
            cam: 52,
            islandH: 52,
            bandH: 64,
            slot: 70.5,
            leftL: 12,
            leftR: 163,
            rightL: 227,
            rightR: 378,
            centres: [52.25, 122.75, 195, 267.25, 337.75],
            capW: null,
          ),
          (
            w: 390,
            state: 'camera route',
            cam: 76,
            islandH: 64,
            bandH: 76,
            slot: 64.5,
            leftL: 12,
            leftR: 151,
            rightL: 239,
            rightR: 378,
            centres: [49.25, 113.75, 195, 276.25, 340.75],
            capW: null,
          ),
          (
            w: 412,
            state: 'shown',
            cam: 60,
            islandH: 64,
            bandH: 64,
            slot: 74,
            leftL: 12,
            leftR: 170,
            rightL: 242,
            rightR: 400,
            centres: [54, 128, 206, 284, 358],
            capW: 72,
          ),
          (
            w: 412,
            state: 'compact',
            cam: 52,
            islandH: 52,
            bandH: 64,
            slot: 75,
            leftL: 14,
            leftR: 174,
            rightL: 238,
            rightR: 398,
            centres: [56.5, 131.5, 206, 280.5, 355.5],
            capW: null,
          ),
          (
            w: 430,
            state: 'shown',
            cam: 60,
            islandH: 64,
            bandH: 64,
            slot: 75,
            leftL: 19,
            leftR: 179,
            rightL: 251,
            rightR: 411,
            centres: [61.5, 136.5, 215, 293.5, 368.5],
            capW: 73,
          ),
        ];

    for (final c in cases) {
      test(
        'matches §1.2 outer island reference table at W=${c.w.toInt()} (${c.state})',
        () {
          final g = UiDockGeometry.compute(
            width: c.w,
            cam: c.cam,
            islandH: c.islandH,
            bandH: c.bandH,
          );
          expect(g.slotWidth, closeTo(c.slot, 0.5));
          expect(g.leftIsland.left, closeTo(c.leftL, 0.5));
          expect(g.leftIsland.right, closeTo(c.leftR, 0.5));
          expect(g.rightIsland.left, closeTo(c.rightL, 0.5));
          expect(g.rightIsland.right, closeTo(c.rightR, 0.5));
          for (var i = 0; i < 5; i++) {
            expect(
              g.allCentersX[i],
              closeTo(c.centres[i], 0.5),
              reason: 'slot $i centre x',
            );
          }

          // Mirror symmetry
          expect(
            g.leftIsland.left,
            closeTo(c.w - g.rightIsland.right, 0.5),
            reason: 'island outer margins mirrored',
          );
          expect(
            g.leftIsland.width,
            closeTo(g.rightIsland.width, 0.5),
            reason: 'island widths equal',
          );
          for (var i = 0; i < 5; i++) {
            expect(
              g.allCentersX[i] + g.allCentersX[4 - i],
              closeTo(c.w, 0.5),
              reason: 'control $i mirrored with ${4 - i} about W/2',
            );
          }

          // Camera centring & island-camera gaps
          expect(g.cameraRect.center.dx, closeTo(c.w / 2, 0.5));
          expect(g.cameraRect.center.dy, closeTo(g.leftIsland.center.dy, 0.5));
          expect(g.cameraRect.center.dy, closeTo(g.rightIsland.center.dy, 0.5));
          expect(g.cameraRect.left - g.leftIsland.right, closeTo(6, 0.5));
          expect(g.rightIsland.left - g.cameraRect.right, closeTo(6, 0.5));

          if (c.capW != null) {
            expect(g.capsuleWidth, closeTo(c.capW!, 0.5));
            for (var t = 0; t < 4; t++) {
              final cap = g.selectionRectForTab(t);
              expect(cap.width, closeTo(c.capW!, 0.5));
              expect(cap.height, closeTo(52, 0.5));
            }
          } else if (c.state == 'compact') {
            for (var t = 0; t < 4; t++) {
              final ring = g.selectionRectForTab(t, compactT: 1);
              expect(ring.width, closeTo(40, 0.5));
              expect(ring.height, closeTo(40, 0.5));
              expect(ring.center, Offset(g.tabCentersX[t], g.centerY));
              expect(ring.top - g.leftIsland.top, closeTo(6, 0.5));
              expect(g.leftIsland.bottom - ring.bottom, closeTo(6, 0.5));
            }
          }
        },
      );
    }

    test(
      'C1 adaptive active-slot flex & concentric radii at t = 0, 0.5, 1',
      () {
        for (final t in [0.0, 0.5, 1.0]) {
          expect(
            UiDockGeometry.islandRadiusAt(t) - UiDockGeometry.pillRadiusAt(t),
            closeTo(6.0, 0.001),
            reason: '6dp concentric moat at t=$t',
          );
        }

        for (final (w, longActiveSlot, longPartnerSlot, equalSlot) in const [
          (360.0, 72.0, 50.0, 61.0),
          (390.0, 75.0, 62.0, 68.5),
          (412.0, 75.0, 73.0, 74.0),
        ]) {
          for (var tabIdx = 0; tabIdx < 4; tabIdx++) {
            final g = UiDockGeometry.compute(
              width: w,
              cam: 60,
              islandH: 64,
              activeTabIndex: tabIdx,
            );
            if (tabIdx == 0) {
              expect(g.tabSlots[0].width, closeTo(longActiveSlot, 0.01));
              expect(g.tabSlots[1].width, closeTo(longPartnerSlot, 0.01));
              expect(g.tabSlots[2].width, closeTo(equalSlot, 0.01));
              expect(g.tabSlots[3].width, closeTo(equalSlot, 0.01));
            } else if (tabIdx == 2) {
              expect(g.tabSlots[0].width, closeTo(equalSlot, 0.01));
              expect(g.tabSlots[1].width, closeTo(equalSlot, 0.01));
              expect(g.tabSlots[2].width, closeTo(longActiveSlot, 0.01));
              expect(g.tabSlots[3].width, closeTo(longPartnerSlot, 0.01));
            } else {
              for (var i = 0; i < 4; i++) {
                expect(g.tabSlots[i].width, closeTo(equalSlot, 0.01));
              }
            }
            for (var i = 0; i < 4; i++) {
              expect(g.tabSlots[i].width, greaterThanOrEqualTo(48.0));
            }
          }
        }
      },
    );

    test('320dp and 430dp graceful bounds: no overflow, slot >= 48dp, constant dockHeight across compact', () {
      for (final w in [320.0, 360.0, 390.0, 412.0, 430.0, 600.0]) {
        final shown = UiDockGeometry.compute(
          width: w,
          cam: 60,
          islandH: 64,
          bandH: 64,
          bottomGap: 16,
        );
        final compact = UiDockGeometry.compute(
          width: w,
          cam: 52,
          islandH: 52,
          bandH: 64,
          bottomGap: 16,
        );
        expect(shown.slotWidth, greaterThanOrEqualTo(48), reason: 'w=$w');
        expect(compact.slotWidth, greaterThanOrEqualTo(48), reason: 'w=$w');
        expect(shown.leftIsland.left, greaterThanOrEqualTo(12));
        expect(shown.rightIsland.right, lessThanOrEqualTo(w - 12));
        // Dock box height and island bottom edge never move on compact
        expect(shown.dockHeight, 84);
        expect(compact.dockHeight, 84);
        expect(shown.leftIsland.bottom, compact.leftIsland.bottom);
        expect(shown.leftIsland.top, shown.leftIsland.bottom - 64);
        expect(compact.leftIsland.top, compact.leftIsland.bottom - 52);
      }

      // B = 34 -> bottomGap = 34 + 8 = 42 -> dockH = 4 + 64 + 42 = 110
      final withSafeBottom = UiDockGeometry.compute(
        width: 390,
        cam: 60,
        islandH: 64,
        bandH: 64,
        bottomGap: 42,
      );
      expect(withSafeBottom.dockHeight, 110);
    });
  });

  group('T1 — Pumped Widget Geometry at W ∈ {360, 390, 412}', () {
    for (final w in [360.0, 390.0, 412.0]) {
      for (final compact in [false, true]) {
        testWidgets(
          'pumped islands, tab centres, symmetry & camera gaps at W=${w.toInt()}, compact=$compact',
          (tester) async {
            await _pumpDock(tester, width: w, active: 0, compact: compact);
            await tester.pumpAndSettle();

            final expected = UiDockGeometry.compute(
              width: w,
              cam: compact ? 52 : 60,
              islandH: compact ? 52 : 64,
              bandH: 64,
              activeTabIndex: 0,
              compactT: compact ? 1 : 0,
            );

            final glasses = find.byType(UiGlass);
            expect(glasses, findsNWidgets(2));
            final leftIsland = tester.getRect(glasses.first);
            final rightIsland = tester.getRect(glasses.last);

            expect(leftIsland.left, closeTo(expected.leftIsland.left, 0.5));
            expect(leftIsland.right, closeTo(expected.leftIsland.right, 0.5));
            expect(leftIsland.height, closeTo(compact ? 52 : 64, 0.5));
            expect(rightIsland.left, closeTo(expected.rightIsland.left, 0.5));
            expect(rightIsland.right, closeTo(expected.rightIsland.right, 0.5));
            expect(rightIsland.height, closeTo(compact ? 52 : 64, 0.5));

            // Mirror symmetry of outer islands
            expect(leftIsland.left, closeTo(w - rightIsland.right, 0.5));
            expect(leftIsland.top, closeTo(rightIsland.top, 0.5));
            expect(leftIsland.bottom, closeTo(rightIsland.bottom, 0.5));

            final camRect = _cameraCircleRect(tester);
            expect(camRect.width, closeTo(compact ? 52 : 60, 0.5));
            expect(camRect.height, closeTo(compact ? 52 : 60, 0.5));
            expect(camRect.center.dx, closeTo(w / 2, 0.5));
            expect(camRect.center.dy, closeTo(leftIsland.center.dy, 0.5));
            expect(camRect.left - leftIsland.right, closeTo(6, 0.5));
            expect(rightIsland.left - camRect.right, closeTo(6, 0.5));

            final tabRects = [
              for (final k in _tabKeys) tester.getRect(find.byKey(ValueKey(k))),
            ];
            for (var i = 0; i < 4; i++) {
              expect(
                tabRects[i].center.dx,
                closeTo(expected.tabCentersX[i], 0.5),
                reason: 'tab $i center dx',
              );
              expect(
                tabRects[i].center.dy,
                closeTo(leftIsland.center.dy, 0.5),
                reason: 'tab $i center dy',
              );
            }
          },
        );
      }
    }
  });

  group('T2 — Capsule (compact=false) across all 4 tabs', () {
    for (final w in [360.0, 390.0, 412.0]) {
      testWidgets(
        'capsule size, concentric r16/R22 radii, and balanced visible top/bottom gaps at W=${w.toInt()}',
        (tester) async {
          for (var tabIdx = 0; tabIdx < 4; tabIdx++) {
            final expected = UiDockGeometry.compute(
              width: w,
              cam: 60,
              islandH: 64,
              bandH: 64,
              activeTabIndex: tabIdx,
            );
            await _pumpDock(tester, width: w, active: tabIdx, compact: false);
            await tester.pumpAndSettle();

            final glasses = tester
                .widgetList<UiGlass>(find.byType(UiGlass))
                .toList();
            for (final g in glasses) {
              expect(g.borderRadius, BorderRadius.circular(22));
            }

            final pillFinder = find.byKey(
              const ValueKey('dock-selection-pill'),
            );
            final capsule = tester.getRect(pillFinder);
            expect(
              capsule.width,
              closeTo(expected.capsuleWidthForTab(tabIdx), 0.5),
            );
            expect(capsule.height, closeTo(52, 0.5));

            final deco =
                tester.widget<DecoratedBox>(pillFinder).decoration
                    as BoxDecoration;
            expect(deco.borderRadius, BorderRadius.circular(16));

            // Concentric 6dp outer moat on the island's outer/inner end-cap
            final hostIsland = tester.getRect(
              tabIdx < 2
                  ? find.byType(UiGlass).first
                  : find.byType(UiGlass).last,
            );
            if (tabIdx == 0 || tabIdx == 2) {
              expect(capsule.left - hostIsland.left, closeTo(6.0, 0.05));
            } else {
              expect(hostIsland.right - capsule.right, closeTo(6.0, 0.05));
            }

            final tabFinder = find.byKey(ValueKey(_tabKeys[tabIdx]));
            final glyphRect = tester.getRect(
              find.descendant(of: tabFinder, matching: find.byType(OurneyIcon)),
            );
            final labelRect = tester.getRect(
              find.descendant(of: tabFinder, matching: find.byType(Text)),
            );

            final visibleGlyphTop = glyphRect.center.dy - 24 * 1.08 / 2;
            final topGap = visibleGlyphTop - capsule.top;
            final bottomGap = capsule.bottom - labelRect.bottom;

            expect(
              (topGap - bottomGap).abs(),
              lessThanOrEqualTo(0.5),
              reason: 'tab $tabIdx at W=$w: top=$topGap bottom=$bottomGap',
            );
            expect(topGap, closeTo(5.2, 0.5));
            expect(bottomGap, closeTo(5.2, 0.5));
          }
        },
      );
    }
  });

  group('T3 — Circle (compact=true) across all 4 tabs', () {
    for (final w in [360.0, 390.0, 412.0]) {
      testWidgets(
        '40x40 r20 circle centred on glyph, R26 islands, 6/6 island gaps, 52 islands and camera at W=${w.toInt()}',
        (tester) async {
          for (var tabIdx = 0; tabIdx < 4; tabIdx++) {
            await _pumpDock(tester, width: w, active: tabIdx, compact: true);
            await tester.pumpAndSettle();

            final glasses = find.byType(UiGlass);
            final leftIsland = tester.getRect(glasses.first);
            final rightIsland = tester.getRect(glasses.last);
            expect(leftIsland.height, closeTo(52, 0.5));
            expect(rightIsland.height, closeTo(52, 0.5));
            for (final g in tester.widgetList<UiGlass>(glasses)) {
              expect(g.borderRadius, BorderRadius.circular(26));
            }

            final camRect = _cameraCircleRect(tester);
            expect(camRect.width, closeTo(52, 0.5));
            expect(camRect.height, closeTo(52, 0.5));

            final pillFinder = find.byKey(
              const ValueKey('dock-selection-pill'),
            );
            final circle = tester.getRect(pillFinder);
            expect(circle.width, closeTo(40, 0.5));
            expect(circle.height, closeTo(40, 0.5));

            final deco =
                tester.widget<DecoratedBox>(pillFinder).decoration
                    as BoxDecoration;
            expect(deco.borderRadius, BorderRadius.circular(20));

            final tabFinder = find.byKey(ValueKey(_tabKeys[tabIdx]));
            final glyphRect = tester.getRect(
              find.descendant(of: tabFinder, matching: find.byType(OurneyIcon)),
            );
            expect(circle.center.dx, closeTo(glyphRect.center.dx, 0.5));
            expect(circle.center.dy, closeTo(glyphRect.center.dy, 0.5));

            final hostIsland = tabIdx < 2 ? leftIsland : rightIsland;
            expect(circle.top - hostIsland.top, closeTo(6, 0.5));
            expect(hostIsland.bottom - circle.bottom, closeTo(6, 0.5));
          }
        },
      );
    }
  });

  group('T4 — Morph Synchronization, Concentricity at t=0/0.5/1 & Reversal', () {
    testWidgets(
      'single 220ms t driver moves islands, camera, selection and labels in lockstep, keeps R_island - r_pill == 6dp at t=0, 0.5, 1, and reverses cleanly',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(360, 800);
        addTearDown(tester.view.reset);

        var compact = false;
        late StateSetter setHost;

        await tester.pumpWidget(
          MaterialApp(
            theme: OurneyTheme.build(Brightness.light),
            home: MediaQuery(
              data: const MediaQueryData(size: Size(360, 800)),
              child: Scaffold(
                body: StatefulBuilder(
                  builder: (context, setState) {
                    setHost = setState;
                    return Align(
                      alignment: Alignment.bottomCenter,
                      child: _buildDock(active: 0, compact: compact),
                    );
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        double currentIslandRadius() => tester
            .widget<UiGlass>(find.byType(UiGlass).first)
            .borderRadius
            .topLeft
            .x;
        double currentPillRadius() =>
            ((tester
                                .widget<DecoratedBox>(
                                  find.byKey(
                                    const ValueKey('dock-selection-pill'),
                                  ),
                                )
                                .decoration
                            as BoxDecoration)
                        .borderRadius!
                    as BorderRadius)
                .topLeft
                .x;

        final pillFinder = find.byKey(const ValueKey('dock-selection-pill'));
        final initialIslandBottom = tester
            .getRect(find.byType(UiGlass).first)
            .bottom;
        expect(tester.getRect(pillFinder).width, closeTo(70, 0.5));
        expect(tester.getRect(pillFinder).height, closeTo(52, 0.5));
        // t = 0 concentricity: R_island = 22, r_pill = 16 -> moat = 6
        expect(currentIslandRadius(), closeTo(22.0, 0.01));
        expect(currentPillRadius(), closeTo(16.0, 0.01));
        expect(currentIslandRadius() - currentPillRadius(), closeTo(6.0, 0.01));

        // Trigger compact = true
        setHost(() => compact = true);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 110));

        final midIsland = tester.getRect(find.byType(UiGlass).first);
        final midCam = _cameraCircleRect(tester);
        final midPill = tester.getRect(pillFinder);

        // Island bottom never moves
        expect(midIsland.bottom, closeTo(initialIslandBottom, 0.01));

        // Selection is strictly between capsule (70x52) and circle (40x40)
        expect(midPill.width, greaterThan(40));
        expect(midPill.width, lessThan(70));
        expect(midPill.height, greaterThan(40));
        expect(midPill.height, lessThan(52));

        // t ≈ 0.5 concentricity: R_island(t) - r_pill(t) == 6.0dp
        expect(currentIslandRadius(), greaterThan(22.0));
        expect(currentIslandRadius(), lessThan(26.0));
        expect(currentPillRadius(), greaterThan(16.0));
        expect(currentPillRadius(), lessThan(20.0));
        expect(currentIslandRadius() - currentPillRadius(), closeTo(6.0, 0.01));
        expect(midPill.left - midIsland.left, greaterThanOrEqualTo(6.0));

        // Label opacity is between 0 and 1
        final opacities = tester
            .widgetList<Opacity>(
              find.descendant(
                of: find.byType(UiDock),
                matching: find.byType(Opacity),
              ),
            )
            .toList();
        expect(opacities, isNotEmpty);
        for (final op in opacities) {
          expect(op.opacity, greaterThan(0));
          expect(op.opacity, lessThan(1));
        }

        // Derive t from island height (64 -> 52) and verify all pieces share t
        final derivedT = (64.0 - midIsland.height) / (64.0 - 52.0);
        expect(derivedT, greaterThan(0.1));
        expect(derivedT, lessThan(0.99));
        expect(midCam.width, closeTo(lerpDouble(60, 52, derivedT)!, 0.5));
        expect(midPill.height, closeTo(lerpDouble(52, 40, derivedT)!, 0.5));
        expect(opacities.first.opacity, closeTo(1 - derivedT, 0.05));

        // Finish 220ms morph -> equals T3 (t = 1 concentricity: R_island = 26, r_pill = 20)
        await tester.pump(const Duration(milliseconds: 110));
        expect(
          tester.getRect(find.byType(UiGlass).first).height,
          closeTo(52, 0.5),
        );
        expect(_cameraCircleRect(tester).width, closeTo(52, 0.5));
        expect(tester.getRect(pillFinder).width, closeTo(40, 0.5));
        expect(tester.getRect(pillFinder).height, closeTo(40, 0.5));
        expect(currentIslandRadius(), closeTo(26.0, 0.01));
        expect(currentPillRadius(), closeTo(20.0, 0.01));
        expect(currentIslandRadius() - currentPillRadius(), closeTo(6.0, 0.01));

        // Reverse to compact = false -> equals T2 after 220ms
        setHost(() => compact = false);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 220));
        expect(
          tester.getRect(find.byType(UiGlass).first).height,
          closeTo(64, 0.5),
        );
        expect(_cameraCircleRect(tester).width, closeTo(60, 0.5));
        expect(tester.getRect(pillFinder).width, closeTo(70, 0.5));
        expect(tester.getRect(pillFinder).height, closeTo(52, 0.5));

        // Mid-way reversal: start compacting again, flip back at +110ms,
        // verify the reversal frame does not jump and the next +16ms frame
        // progresses smoothly back toward T2.
        setHost(() => compact = true);
        await tester.pump();
        await tester.pump(Duration.zero);
        await tester.pump(const Duration(milliseconds: 110));
        final revIsland0 = tester.getRect(find.byType(UiGlass).first);
        final revCam0 = _cameraCircleRect(tester);
        final revPill0 = tester.getRect(pillFinder);

        setHost(() => compact = false);
        await tester.pump();
        final revIslandAt0 = tester.getRect(find.byType(UiGlass).first);
        final revCamAt0 = _cameraCircleRect(tester);
        final revPillAt0 = tester.getRect(pillFinder);
        expect(
          (revIslandAt0.height - revIsland0.height).abs(),
          lessThan(0.01),
          reason: 'reversal frame must start from exact mid-flight islandH',
        );
        expect(
          (revCamAt0.width - revCam0.width).abs(),
          lessThan(0.01),
          reason: 'reversal frame must start from exact mid-flight camD',
        );
        expect(
          (revPillAt0.width - revPill0.width).abs(),
          lessThan(0.01),
          reason: 'reversal frame must start from exact mid-flight pillW',
        );

        await tester.pump(const Duration(milliseconds: 16));
        final revIsland1 = tester.getRect(find.byType(UiGlass).first);
        final revCam1 = _cameraCircleRect(tester);
        final revPill1 = tester.getRect(pillFinder);
        expect(revIsland1.height, greaterThan(revIsland0.height));
        expect(revIsland1.height, lessThan(60.0));
        expect(revCam1.width, greaterThan(revCam0.width));
        expect(revCam1.width, lessThan(58.0));
        expect(revPill1.width, greaterThan(revPill0.width));
        expect(revPill1.width, lessThan(66.0));

        await tester.pump(const Duration(milliseconds: 220));
        expect(
          tester.getRect(find.byType(UiGlass).first).height,
          closeTo(64, 0.5),
        );
        expect(_cameraCircleRect(tester).width, closeTo(60, 0.5));
        expect(tester.getRect(pillFinder).width, closeTo(70, 0.5));
        expect(tester.getRect(pillFinder).height, closeTo(52, 0.5));
      },
    );

    testWidgets(
      'tab tap while compact smoothly expands (220ms) and slides (280ms) with zero snap at completion',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(360, 800);
        addTearDown(tester.view.reset);

        var active = 0;
        var compact = true;
        late StateSetter setHost;

        await tester.pumpWidget(
          MaterialApp(
            theme: OurneyTheme.build(Brightness.light),
            home: MediaQuery(
              data: const MediaQueryData(size: Size(360, 800)),
              child: Scaffold(
                body: StatefulBuilder(
                  builder: (context, setState) {
                    setHost = setState;
                    return Align(
                      alignment: Alignment.bottomCenter,
                      child: _buildDock(
                        active: active,
                        compact: compact,
                        onSelect: (i) => setHost(() {
                          active = i;
                          compact = false;
                        }),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final pillFinder = find.byKey(const ValueKey('dock-selection-pill'));
        expect(tester.getCenter(pillFinder).dx, closeTo(48.5, 0.5));

        // Tap tab 1 (inner left) while compact -> simultaneously expands & slides.
        await tester.tap(find.byKey(ValueKey(_tabKeys[1])));
        await tester.pump();
        await tester.pump(Duration.zero);

        // Advance to 278ms (2ms before the 280ms slide finishes, after the 220ms expand finished).
        await tester.pump(const Duration(milliseconds: 278));
        final x278 = tester.getCenter(pillFinder).dx;
        await tester.pump(const Duration(milliseconds: 2));
        final x280 = tester.getCenter(pillFinder).dx;
        await tester.pump(const Duration(milliseconds: 16));
        final x296 = tester.getCenter(pillFinder).dx;

        expect(
          (x280 - x278).abs(),
          lessThan(0.25),
          reason: 'no snap when 280ms slide completes after compact expand',
        );
        expect((x296 - x280).abs(), lessThan(0.01));
        expect(x296, closeTo(108.5, 0.5));
      },
    );

    testWidgets(
      'asymmetric tab counts (1 left, 2 right) map right-island selection to slots 2 and 3',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 800);
        addTearDown(tester.view.reset);

        for (final active in [0, 1, 2]) {
          UiDockItem item(String glyph, String label, int idx) => UiDockItem(
            itemKey: ValueKey('asym-tab-$idx'),
            glyph: glyph,
            label: label,
            active: active == idx,
            onPressed: () {},
          );
          await tester.pumpWidget(
            MaterialApp(
              theme: OurneyTheme.build(Brightness.light),
              home: MediaQuery(
                data: const MediaQueryData(size: Size(390, 800)),
                child: Scaffold(
                  body: Align(
                    alignment: Alignment.bottomCenter,
                    child: UiDock(
                      left: item('journeys', 'Hành trình', 0),
                      extraRight: [item('activity', 'Hoạt động', 1)],
                      right: item('profile', 'Hồ sơ', 2),
                      snapLabel: 'Chụp',
                      onSnap: () {},
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final pillCenter = tester.getCenter(
            find.byKey(const ValueKey('dock-selection-pill')),
          );
          final tabCenter = tester.getCenter(
            find.byKey(ValueKey('asym-tab-$active')),
          );
          expect(
            pillCenter.dx,
            closeTo(tabCenter.dx, 0.5),
            reason: 'active item $active capsule must align with its tab slot',
          );
        }
      },
    );
  });

  group('T5 — Reduce Motion Snap', () {
    testWidgets(
      'snaps in a single pump() under MediaQuery.disableAnimations and PlatformDispatcher.reduceMotion',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(360, 800);
        addTearDown(tester.view.reset);

        for (final usePlatformFlag in [false, true]) {
          if (usePlatformFlag) {
            tester.platformDispatcher.accessibilityFeaturesTestValue =
                const FakeAccessibilityFeatures(reduceMotion: true);
          }

          var compact = false;
          late StateSetter setHost;

          await tester.pumpWidget(
            MaterialApp(
              theme: OurneyTheme.build(Brightness.light),
              home: MediaQuery(
                data: MediaQueryData(
                  size: const Size(360, 800),
                  disableAnimations: !usePlatformFlag,
                ),
                child: Scaffold(
                  body: StatefulBuilder(
                    builder: (context, setState) {
                      setHost = setState;
                      return Align(
                        alignment: Alignment.bottomCenter,
                        child: _buildDock(active: 0, compact: compact),
                      );
                    },
                  ),
                ),
              ),
            ),
          );

          final pillFinder = find.byKey(const ValueKey('dock-selection-pill'));
          expect(tester.getRect(pillFinder).size, const Size(70, 52));

          // Flip to compact: single pump() reaches final 40x40 / 52 geometry
          setHost(() => compact = true);
          await tester.pump();
          expect(tester.getRect(pillFinder).size, const Size(40, 40));
          expect(tester.getRect(find.byType(UiGlass).first).height, 52);
          expect(_cameraCircleRect(tester).size, const Size(52, 52));

          // Flip back to expanded: single pump() reaches final 70x52 / 64 geometry
          setHost(() => compact = false);
          await tester.pump();
          expect(tester.getRect(pillFinder).size, const Size(70, 52));
          expect(tester.getRect(find.byType(UiGlass).first).height, 64);
          expect(_cameraCircleRect(tester).size, const Size(60, 60));

          if (usePlatformFlag) {
            tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
          }
        }
      },
    );
  });

  group('T6 — Semantics While Hidden in Compact', () {
    testWidgets(
      'all 5 controls keep button semantics and labels in compact; hidden label text is not hit-testable',
      (tester) async {
        final handle = tester.ensureSemantics();
        await _pumpDock(tester, width: 360, active: 0, compact: true);
        await tester.pumpAndSettle();

        for (var i = 0; i < 4; i++) {
          expect(
            tester.getSemantics(find.byKey(ValueKey(_tabKeys[i]))),
            matchesSemantics(
              label: _viLabels[i],
              isButton: true,
              isSelected: i == 0,
              isEnabled: true,
              hasEnabledState: true,
              hasSelectedState: true,
              hasTapAction: true,
            ),
            reason: _tabKeys[i],
          );
          expect(
            find.text(_viLabels[i]).hitTestable(),
            findsNothing,
            reason: '${_viLabels[i]} must not be hit-testable in compact',
          );
        }

        expect(
          tester.getSemantics(find.byKey(const ValueKey('dock-snap-pill'))),
          matchesSemantics(
            label: 'Chụp',
            isButton: true,
            isEnabled: true,
            hasEnabledState: true,
            hasTapAction: true,
          ),
        );
        handle.dispose();
      },
    );

    testWidgets(
      'camera dock suppresses tab active state (UiCamera.ink foreground and isSelected: false) even when item.active is true',
      (tester) async {
        final handle = tester.ensureSemantics();
        await _pumpDock(tester, width: 390, active: 0, camera: true);
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('dock-selection-pill')), findsNothing);
        for (var i = 0; i < 4; i++) {
          final text = tester.widget<Text>(find.text(_viLabels[i]));
          expect(
            text.style!.color,
            UiCamera.ink,
            reason: 'camera tab $i must use UiCamera.ink, never dark onBrand',
          );
          expect(
            tester.getSemantics(find.byKey(ValueKey(_tabKeys[i]))),
            matchesSemantics(
              label: _viLabels[i],
              isButton: true,
              isSelected: false,
              isEnabled: true,
              hasEnabledState: true,
              hasSelectedState: true,
              hasTapAction: true,
            ),
            reason: 'camera tab $i must not announce isSelected: true',
          );
        }
        handle.dispose();
      },
    );
  });

  group('T7 — Tap Targets >= 48x48 at 320, 360, 390 in both states', () {
    for (final w in [320.0, 360.0, 390.0]) {
      for (final compact in [false, true]) {
        testWidgets(
          'every tab and camera >= 48x48 at W=${w.toInt()}, compact=$compact',
          (tester) async {
            await _pumpDock(tester, width: w, compact: compact);
            await tester.pumpAndSettle();

            for (final key in [..._tabKeys, 'dock-snap-pill']) {
              final size = tester.getSize(find.byKey(ValueKey(key)));
              expect(
                size.width,
                greaterThanOrEqualTo(48),
                reason: '$key width at W=$w compact=$compact',
              );
              expect(
                size.height,
                greaterThanOrEqualTo(48),
                reason: '$key height at W=$w compact=$compact',
              );
            }
          },
        );
      }
    }
  });

  group('T10 — Skins (shell + 6 skins × light/dark)', () {
    final skinIds = <String?>[null, ...uiSkins.map((s) => s.id)];
    for (final skinId in skinIds) {
      for (final brightness in Brightness.values) {
        testWidgets(
          'skin=${skinId ?? "shell"} (${brightness.name}) borders and hard shadows match E4 spec',
          (tester) async {
            await _pumpDock(
              tester,
              width: 390,
              brightness: brightness,
              skinId: skinId,
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);

            final isQuiet = skinId == 'quiet';
            final expectedBorder = isQuiet ? UiBorder.thin : UiBorder.standard;
            final expectedShadow = isQuiet ? UiShadow.tiny : UiShadow.large;

            // Islands
            final glasses = tester
                .widgetList<UiGlass>(find.byType(UiGlass))
                .toList();
            expect(glasses, hasLength(2));
            for (final g in glasses) {
              expect(g.borderWidth, expectedBorder);
              expect(g.hardShadow, expectedShadow);
            }

            // Camera circle
            final snapFinder = find.byKey(const ValueKey('dock-snap-pill'));
            final snapPressable = tester.widget<UiPressable>(snapFinder);
            expect(snapPressable.shadowOffset, expectedShadow);
            final camRect = _cameraCircleRect(tester);
            expect(camRect.size, const Size(60, 60));
            final camContainers = tester.widgetList<Container>(
              find.descendant(of: snapFinder, matching: find.byType(Container)),
            );
            final camDeco =
                camContainers
                        .firstWhere(
                          (c) =>
                              c.decoration is BoxDecoration &&
                              (c.decoration! as BoxDecoration).shape ==
                                  BoxShape.circle,
                        )
                        .decoration!
                    as BoxDecoration;
            expect((camDeco.border! as Border).top.width, expectedBorder);

            // Selection capsule always uses 1.5 border and 2dp shadow
            final pillDeco =
                tester
                        .widget<DecoratedBox>(
                          find.byKey(const ValueKey('dock-selection-pill')),
                        )
                        .decoration
                    as BoxDecoration;
            expect((pillDeco.border! as Border).top.width, UiBorder.thin);
            expect(pillDeco.boxShadow!.single.offset, const Offset(2, 2));
          },
        );
      }
    }
  });
}
