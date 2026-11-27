import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/ui/components/dock.dart';
import 'package:ourney/ui/components/dock_tab.dart'
    show
        DockTab,
        dockE4CapsuleLabelSidePad,
        dockLabelLetterSpacingEm,
        dockLabelMaxScale;
import 'package:ourney/ui/components/glass.dart';
import 'package:ourney/ui/theme.dart';
import 'package:ourney/ui/tokens.dart';
import 'package:ourney/ui/typography.dart';

const _labels = ['Hành trình', 'Nhóm', 'Hoạt động', 'Hồ sơ'];
const _enLabels = ['Journeys', 'Squad', 'Activity', 'Profile'];

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

Future<void> _pump(
  WidgetTester tester,
  double width,
  double scale, {
  List<String> labels = _labels,
  bool camera = false,
  bool compact = false,
  int active = 0,
  ValueChanged<String>? onTap,
}) async {
  UiDockItem item(String l, int i) => UiDockItem(
    glyph: ['journeys', 'squad', 'activity', 'profile'][i],
    label: l,
    active: active == i,
    itemKey: ValueKey('t$i'),
    onPressed: () => onTap?.call('t$i'),
  );
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: OurneyTheme.build(Brightness.light),
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, 700),
          textScaler: TextScaler.linear(scale),
        ),
        child: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: RepaintBoundary(
              key: const ValueKey('dock-boundary'),
              child: UiDock(
                camera: camera,
                compact: compact,
                left: item(labels[0], 0),
                extraLeft: [item(labels[1], 1)],
                extraRight: [item(labels[2], 2)],
                right: item(labels[3], 3),
                snapLabel: 'Chụp',
                onSnap: () => onTap?.call('snap'),
                center: camera
                    ? UiShutter(
                        label: 'Chụp',
                        onPressed: () => onTap?.call('shutter'),
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Scans the rendered 3x bitmap of the active selection pill and returns
/// `(leftHorizDp, rightHorizDp, minHorizDp, minRadialDp)` from the outermost
/// label glyph ink pixel to the inner edge of the 1.5dp pill border.
Future<({double leftDp, double rightDp, double minHorizDp, double minRadialDp})>
_scanActivePillClearance(
  WidgetTester tester, {
  required Rect pillGlobal,
  required Rect labelGlobal,
  required double pillRadius,
}) async {
  const ratio = 3.0;
  final boundaryFinder = find.byKey(const ValueKey('dock-boundary'));
  final boundaryOrigin = tester.getTopLeft(boundaryFinder);
  final pill = pillGlobal.shift(-boundaryOrigin);
  final label = labelGlobal.shift(-boundaryOrigin);

  late ByteData bytes;
  late int imgW;
  late int imgH;
  await tester.runAsync(() async {
    final boundary =
        tester.renderObject(boundaryFinder) as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: ratio);
    imgW = image.width;
    imgH = image.height;
    bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    image.dispose();
  });

  // Sample reference pill fill colour in the peach region between icon and label
  final sampleX = (pill.left + 8.0) * ratio;
  final sampleY = (label.top - 1.0) * ratio;
  final sIdx =
      (sampleY.floor().clamp(0, imgH - 1) * imgW +
          sampleX.floor().clamp(0, imgW - 1)) *
      4;
  final fillR = bytes.getUint8(sIdx);
  final fillG = bytes.getUint8(sIdx + 1);
  final fillB = bytes.getUint8(sIdx + 2);

  bool isInk(int px, int py) {
    final idx = (py * imgW + px) * 4;
    final r = bytes.getUint8(idx);
    final g = bytes.getUint8(idx + 1);
    final b = bytes.getUint8(idx + 2);
    final diff = (r - fillR).abs() + (g - fillG).abs() + (b - fillB).abs();
    return diff > 60;
  }

  final rInner = pillRadius - UiBorder.thin;
  final yMin = (label.top * ratio).floor().clamp(0, imgH - 1);
  final yMax = (label.bottom * ratio).ceil().clamp(0, imgH - 1);

  var minLeftDp = double.infinity;
  var minRightDp = double.infinity;
  var minRadialDp = double.infinity;

  for (var py = yMin; py <= yMax; py++) {
    final yDp = (py + 0.5) / ratio;
    final dyBottom = math.max(0.0, yDp - (pill.bottom - pillRadius));
    final dyTop = math.max(0.0, (pill.top + pillRadius) - yDp);
    final dy = math.max(dyBottom, dyTop);
    if (dy >= rInner) continue;

    final dxArc = math.sqrt(rInner * rInner - dy * dy);
    final innerLeftDp = (pill.left + pillRadius) - dxArc;
    final innerRightDp = (pill.right - pillRadius) + dxArc;

    // Scan strictly inside the inner pill fill at this scanline (excluding the
    // pill's own 1.5dp curved border and 2dp outer shadow).
    final rowXMin = ((innerLeftDp + 0.75) * ratio).ceil().clamp(0, imgW - 1);
    final rowXMax = ((innerRightDp - 0.75) * ratio).floor().clamp(0, imgW - 1);

    var firstInk = -1;
    var lastInk = -1;
    for (var px = rowXMin; px <= rowXMax; px++) {
      if (isInk(px, py)) {
        if (firstInk < 0) firstInk = px;
        lastInk = px;
      }
    }
    if (firstInk < 0) continue;

    final leftInkDp = firstInk / ratio;
    final rightInkDp = (lastInk + 1) / ratio;

    final leftClear = leftInkDp - innerLeftDp;
    final rightClear = innerRightDp - rightInkDp;
    if (leftClear < minLeftDp) minLeftDp = leftClear;
    if (rightClear < minRightDp) minRightDp = rightClear;

    // 2D radial clearance to the bottom/top corner arcs when inside corner x-range:
    for (final xDp in [leftInkDp, rightInkDp]) {
      final cx = xDp.clamp(pill.left + pillRadius, pill.right - pillRadius);
      final cy = yDp.clamp(pill.top + pillRadius, pill.bottom - pillRadius);
      final radial = rInner - (Offset(xDp, yDp) - Offset(cx, cy)).distance;
      if (radial < minRadialDp) minRadialDp = radial;
    }
  }

  return (
    leftDp: minLeftDp,
    rightDp: minRightDp,
    minHorizDp: math.min(minLeftDp, minRightDp),
    minRadialDp: minRadialDp,
  );
}

void main() {
  setUpAll(_loadBodyFont);

  for (final (w, s) in [(320.0, 2.0), (360.0, 1.35), (390.0, 1.0)]) {
    testWidgets('all dock labels share one font size at ${w}dp x$s', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(w, 700);
      addTearDown(tester.view.reset);
      await _pump(tester, w, s);
      final sizes = <double>[];
      for (final l in _labels) {
        final text = tester.widget<Text>(find.text(l));
        final fit = tester.widget<FittedBox>(
          find
              .ancestor(of: find.text(l), matching: find.byType(FittedBox))
              .first,
        );
        expect(fit.fit, BoxFit.scaleDown);
        // Rendered size = font size x the FittedBox scale (must be 1).
        final box = tester.getSize(find.text(l));
        final fitted = tester.getSize(
          find
              .ancestor(of: find.text(l), matching: find.byType(FittedBox))
              .first,
        );
        expect(box.width, lessThanOrEqualTo(fitted.width + 0.01), reason: l);
        sizes.add(text.style!.fontSize!);
      }
      expect(sizes.toSet().length, 1, reason: 'sizes: $sizes');
      if (w == 320.0) {
        for (var i = 0; i < 4; i++) {
          final tab = tester.getSize(find.byKey(ValueKey('t$i')));
          expect(tab.width, greaterThanOrEqualTo(48), reason: 'tab $i width');
          expect(tab.height, greaterThanOrEqualTo(48), reason: 'tab $i height');
        }
      }
    });
  }

  for (final scale in [1.0, dockLabelMaxScale]) {
    for (final w in [360.0, 390.0, 412.0]) {
      testWidgets(
        'C1 Vietnamese dock labels at ${w.toInt()}dp x$scale across all 4 active tabs: '
        'font >=10dp (10.0 <390 / 10.5 >=390 at 1x), -0.01em tracking, adaptive slot flex, '
        'partner >=48dp, and 3x pixel ink-to-inner-edge clearance >=4.5dp',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(w, 700);
          addTearDown(tester.view.reset);

          final equalGeo = UiDockGeometry.compute(
            width: w,
            cam: 60,
            islandH: 64,
          );
          final maxLabelW = equalGeo.labelMaxWidth;
          expect(
            maxLabelW,
            closeTo(w < 390 ? 53.0 : 56.0, 0.01),
            reason: 'labelMaxW at W=$w',
          );
          final base1xFont = w < 390 ? 10.0 : 10.5;

          for (var activeIdx = 0; activeIdx < 4; activeIdx++) {
            await _pump(tester, w, scale, active: activeIdx);
            await tester.pumpAndSettle();

            final activeGeo = UiDockGeometry.compute(
              width: w,
              cam: 60,
              islandH: 64,
              activeTabIndex: activeIdx,
            );

            // 1. All 4 labels share one font size (>= 1x font size and >= 10.0dp) and -0.01em tracking
            final seenFonts = <double>{};
            for (final l in _labels) {
              final text = tester.widget<Text>(find.text(l));
              final fontSize = text.style!.fontSize!;
              seenFonts.add(fontSize);
              final effectiveFont = fontSize * scale;
              if (scale == 1.0) {
                expect(
                  effectiveFont,
                  closeTo(base1xFont, 0.01),
                  reason: '$l 1x fontSize at W=$w active=$activeIdx',
                );
              } else {
                expect(
                  effectiveFont,
                  greaterThanOrEqualTo(base1xFont),
                  reason:
                      '$l effective fontSize ($effectiveFont) >= 1x ($base1xFont) at W=$w x$scale',
                );
                expect(
                  effectiveFont,
                  greaterThanOrEqualTo(10.0),
                  reason: '$l effective fontSize >= 10dp at W=$w x$scale',
                );
              }
              expect(
                text.style!.letterSpacing!,
                closeTo(effectiveFont * dockLabelLetterSpacingEm, 0.001),
                reason:
                    '$l letterSpacing (-0.01em) at W=$w x$scale active=$activeIdx',
              );
              expect(
                tester.getSize(find.text(l)).width,
                lessThanOrEqualTo(maxLabelW + 0.5),
                reason: '$l width <= labelMaxW ($maxLabelW) at W=$w x$scale',
              );
            }
            expect(seenFonts, hasLength(1));

            // 2. Slot widths match C1 adaptive flex (equal when short tab active, widened when long tab active; partner >= 48dp)
            final dockTabs = tester
                .widgetList<DockTab>(find.byType(DockTab))
                .toList();
            expect(dockTabs, hasLength(4));
            for (var i = 0; i < 4; i++) {
              expect(
                dockTabs[i].labelMaxWidth,
                closeTo(maxLabelW, 0.05),
                reason: 'tab $i labelMaxWidth at W=$w x$scale',
              );
              final slotSize = tester.getSize(find.byKey(ValueKey('t$i')));
              expect(
                slotSize.width,
                closeTo(activeGeo.tabSlots[i].width, 0.5),
                reason: 'tab $i slot width at W=$w x$scale active=$activeIdx',
              );
              expect(
                slotSize.width,
                greaterThanOrEqualTo(48.0),
                reason:
                    'tab $i partner tap target >= 48dp at W=$w x$scale active=$activeIdx',
              );
            }
            if (activeIdx == 1 || activeIdx == 3) {
              // Short labels (Nhóm / Hồ sơ) -> strictly equal slots
              for (var i = 0; i < 4; i++) {
                expect(
                  tester.getSize(find.byKey(ValueKey('t$i'))).width,
                  closeTo(equalGeo.slotWidth, 0.01),
                  reason:
                      'short tab $activeIdx must keep equal slots at W=$w x$scale',
                );
              }
            }

            // 3. Concentric radii at expanded state (R_island = 22, r_pill = 16 -> 6dp moat)
            final glasses = tester
                .widgetList<UiGlass>(find.byType(UiGlass))
                .toList();
            for (final g in glasses) {
              expect(g.borderRadius, BorderRadius.circular(22));
            }
            final pillFinder = find.byKey(
              const ValueKey('dock-selection-pill'),
            );
            final pill = tester.getRect(pillFinder);
            expect(
              pill.width,
              closeTo(activeGeo.capsuleWidthForTab(activeIdx), 0.5),
              reason: 'active=$activeIdx capsule width at W=$w x$scale',
            );
            final pillDeco =
                tester.widget<DecoratedBox>(pillFinder).decoration
                    as BoxDecoration;
            expect(pillDeco.borderRadius, BorderRadius.circular(16));

            // 4. Vertical inner containment (N3) + real 3x bitmap ink-scan clearance inside r=16 (r_inner=14.5) pill
            final labelText = _labels[activeIdx];
            final labelRect = tester.getRect(find.text(labelText));
            expect(
              labelRect.top,
              greaterThanOrEqualTo(pill.top + UiBorder.thin),
              reason: '$labelText top inside inner pill border at W=$w x$scale',
            );
            expect(
              labelRect.bottom,
              lessThanOrEqualTo(pill.bottom - UiBorder.thin),
              reason:
                  '$labelText bottom inside inner pill border at W=$w x$scale',
            );
            final scan = await _scanActivePillClearance(
              tester,
              pillGlobal: pill,
              labelGlobal: labelRect,
              pillRadius: 16.0,
            );
            expect(
              scan.minHorizDp,
              greaterThanOrEqualTo(4.5),
              reason:
                  '$labelText at W=$w x$scale horiz clearance=${scan.minHorizDp.toStringAsFixed(2)}dp '
                  '(L=${scan.leftDp.toStringAsFixed(2)}, R=${scan.rightDp.toStringAsFixed(2)})',
            );
            expect(
              scan.minRadialDp,
              greaterThanOrEqualTo(scale == 1.0 ? 3.5 : 3.2),
              reason:
                  '$labelText at W=$w x$scale 2D radial clearance=${scan.minRadialDp.toStringAsFixed(2)}dp',
            );
          }
        },
      );
    }
  }

  for (final (locale, labels) in [('vi', _labels), ('en', _enLabels)]) {
    for (final w in [320.0, 360.0, 390.0]) {
      testWidgets(
        'camera dock 76dp shutter never overlaps any 48dp tab at ${w}dp ($locale)',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(w, 700);
          addTearDown(tester.view.reset);
          final taps = <String>[];
          await _pump(
            tester,
            w,
            1.0,
            labels: labels,
            camera: true,
            onTap: taps.add,
          );
          final shutterRect = tester.getRect(find.byType(UiShutter));
          expect(shutterRect.width, 76);
          expect(shutterRect.height, 76);
          for (var i = 0; i < 4; i++) {
            final tabRect = tester.getRect(find.byKey(ValueKey('t$i')));
            expect(
              tabRect.width,
              greaterThanOrEqualTo(48),
              reason: 'tab $i width at ${w}dp',
            );
            expect(
              tabRect.height,
              greaterThanOrEqualTo(48),
              reason: 'tab $i height at ${w}dp',
            );
            expect(
              shutterRect.overlaps(tabRect),
              isFalse,
              reason: 'shutter $shutterRect must not overlap tab $i $tabRect',
            );
          }
          // Tapping the inner edge of Squad (t1) and Activity (t2) must fire
          // the tab, never the camera shutter.
          final squadRect = tester.getRect(find.byKey(const ValueKey('t1')));
          final activityRect = tester.getRect(find.byKey(const ValueKey('t2')));
          await tester.tapAt(Offset(squadRect.right - 2, squadRect.center.dy));
          await tester.tapAt(
            Offset(activityRect.left + 2, activityRect.center.dy),
          );
          expect(taps, ['t1', 't2']);
        },
      );

      testWidgets(
        'large text never shrinks rendered label size below 1x at ${w}dp ($locale)',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(w, 700);
          addTearDown(tester.view.reset);

          double renderedSize(double scale) {
            final text = tester.widget<Text>(find.text(labels.first));
            final clamped = scale.clamp(1.0, dockLabelMaxScale);
            return text.style!.fontSize! * clamped;
          }

          await _pump(tester, w, 1.0, labels: labels);
          final size10 = renderedSize(1.0);

          for (final s in [1.35, 2.0]) {
            await _pump(tester, w, s, labels: labels);
            final sizeScaled = renderedSize(s);
            expect(
              sizeScaled,
              greaterThanOrEqualTo(size10 - 0.01),
              reason: '$locale at ${w}dp x$s ($sizeScaled vs 1x $size10)',
            );
            final pill = tester.getRect(
              find.byKey(const ValueKey('dock-selection-pill')),
            );
            final labelRect = tester.getRect(find.text(labels.first));
            expect(
              labelRect.width,
              lessThanOrEqualTo(pill.width - dockE4CapsuleLabelSidePad + 0.5),
              reason: '${w}dp active label width <= capW - 6',
            );
            expect(
              labelRect.left,
              greaterThanOrEqualTo(pill.left - 0.5),
              reason: '${w}dp active label left inside capsule',
            );
            expect(
              labelRect.right,
              lessThanOrEqualTo(pill.right + 0.5),
              reason: '${w}dp active label right inside capsule',
            );
            expect(
              labelRect.top,
              greaterThanOrEqualTo(pill.top - 0.5),
              reason: '${w}dp active label top inside capsule',
            );
            expect(
              labelRect.bottom,
              lessThanOrEqualTo(pill.bottom + 0.5),
              reason: '${w}dp active label bottom inside capsule',
            );
          }
        },
      );
    }
  }
}
