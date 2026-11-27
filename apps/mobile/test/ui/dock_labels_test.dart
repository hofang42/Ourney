import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/ui/components/dock.dart';
import 'package:ourney/ui/components/dock_tab.dart'
    show DockTab, dockE4CapsuleLabelSidePad, dockLabelMaxScale;
import 'package:ourney/ui/theme.dart';
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
      theme: OurneyTheme.build(Brightness.light),
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, 700),
          textScaler: TextScaler.linear(scale),
        ),
        child: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: UiDock(
              camera: camera,
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

  for (final w in [360.0, 390.0, 412.0]) {
    testWidgets('Vietnamese dock labels stay >= 10dp at 360dp and 10.5dp from '
        '390dp up, with bounded capsule overhang (1x, ${w}dp)', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(w, 700);
      addTearDown(tester.view.reset);
      await _pump(tester, w, 1);
      final geo = UiDockGeometry.compute(width: w, cam: 60, islandH: 64);
      final maxLabelW = geo.capsuleWidth - dockE4CapsuleLabelSidePad;
      for (final l in _labels) {
        final text = tester.widget<Text>(find.text(l));
        expect(
          text.style!.fontSize!,
          w >= 390 ? 10.5 : greaterThanOrEqualTo(10),
          reason: '$l at ${w}dp',
        );
        expect(
          tester.getSize(find.text(l)).width,
          lessThanOrEqualTo(maxLabelW + 0.5),
          reason: '$l width <= capW - 6 at ${w}dp',
        );
      }
      final dockTabs = tester
          .widgetList<DockTab>(find.byType(DockTab))
          .toList();
      expect(dockTabs, hasLength(4));
      for (var i = 0; i < 4; i++) {
        expect(
          dockTabs[i].labelMaxWidth,
          closeTo(maxLabelW, 0.05),
          reason: 'tab $i labelMaxWidth',
        );
        expect(
          tester.getSize(find.byKey(ValueKey('t$i'))).width,
          closeTo(geo.slotWidth, 0.5),
          reason: 'tab $i slot width',
        );
      }

      // Bounded overhang past the outer capsule outline on the two widest
      // active labels ('Hành trình' = 0, 'Hoạt động' = 2):
      // <= 4dp at 360, <= 1dp at 390, 0 at 412.
      final maxOverhang = switch (w) {
        360.0 => 4.0,
        390.0 => 1.0,
        _ => 0.0,
      };
      for (final activeIdx in [0, 2]) {
        await _pump(tester, w, 1.0, active: activeIdx);
        await tester.pumpAndSettle();
        final pill = tester.getRect(
          find.byKey(const ValueKey('dock-selection-pill')),
        );
        expect(pill.width, closeTo(geo.capsuleWidth, 0.5));
        final labelText = _labels[activeIdx];
        final labelRect = tester.getRect(find.text(labelText));
        final activeText = tester.widget<Text>(find.text(labelText));
        final tp = TextPainter(
          text: TextSpan(text: labelText, style: activeText.style),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout();
        final baselineFromTop = tp.computeDistanceToActualBaseline(
          TextBaseline.alphabetic,
        );
        tp.dispose();
        final baselineY = labelRect.top + baselineFromTop;
        final r = pill.height / 2;
        double overhangPastOutline(Offset p) {
          final cx = p.dx.clamp(pill.left + r, pill.right - r);
          final dist = (p - Offset(cx, pill.center.dy)).distance;
          return dist > r ? dist - r : 0.0;
        }

        for (final p in [
          Offset(labelRect.left, baselineY),
          Offset(labelRect.right, baselineY),
          labelRect.topLeft,
          labelRect.topRight,
        ]) {
          expect(
            overhangPastOutline(p),
            lessThanOrEqualTo(maxOverhang),
            reason: '$labelText point $p overhang vs $pill at ${w}dp',
          );
        }
      }
    });
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
