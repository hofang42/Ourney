import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/ui/components/dock.dart';
import 'package:ourney/ui/components/ourney_icons.dart';
import 'package:ourney/ui/theme.dart';

const _tabs = ['journeys', 'squad', 'activity', 'profile'];
const _box = 24;
const _margin = 24;

/// Pixel bounds of everything the painter draws for [name] in a 24dp box
/// (offset by [_margin] inside a larger canvas so overflow is measurable).
Future<Rect> paintedBounds(String name, {required bool active}) async {
  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec);
  canvas.translate(_margin.toDouble(), _margin.toDouble());
  OurneyIconPainter(
    name: name,
    color: ourneyIconColor(name),
    ink: const Color(0xFF000000),
    active: active,
    shadow: const Color(0xFF000000),
    dieCut: const Color(0xFFFFFFFF),
  ).paint(canvas, const Size(24, 24));
  const side = _box + 2 * _margin;
  final image = await rec.endRecording().toImage(side, side);
  final data = (await image.toByteData())!;
  var l = side, t = side, r = -1, b = -1;
  for (var y = 0; y < side; y++) {
    for (var x = 0; x < side; x++) {
      if (data.getUint8((y * side + x) * 4 + 3) > 8) {
        if (x < l) l = x;
        if (x > r) r = x;
        if (y < t) t = y;
        if (y > b) b = y;
      }
    }
  }
  return Rect.fromLTRB(
    (l - _margin).toDouble(),
    (t - _margin).toDouble(),
    (r + 1 - _margin).toDouble(),
    (b + 1 - _margin).toDouble(),
  );
}

void main() {
  for (final active in [false, true]) {
    testWidgets('dock tab icons stay inside their 24dp box (active=$active)', (
      tester,
    ) async {
      final bounds = <String, Rect>{};
      await tester.runAsync(() async {
        for (final name in _tabs) {
          bounds[name] = await paintedBounds(name, active: active);
        }
      });
      for (final e in bounds.entries) {
        final r = e.value;
        expect(r.left, greaterThanOrEqualTo(0), reason: '${e.key} $r');
        expect(r.top, greaterThanOrEqualTo(0), reason: '${e.key} $r');
        expect(r.right, lessThanOrEqualTo(_box), reason: '${e.key} $r');
        expect(r.bottom, lessThanOrEqualTo(_box), reason: '${e.key} $r');
      }
      // The map no longer dwarfs the other tabs: its painted extent is
      // within 6dp of every other tab icon.
      final map = bounds['journeys']!;
      for (final e in bounds.entries) {
        expect(
          (map.width - e.value.width).abs(),
          lessThanOrEqualTo(6),
          reason: 'width of journeys vs ${e.key}',
        );
        expect(
          (map.height - e.value.height).abs(),
          lessThanOrEqualTo(6),
          reason: 'height of journeys vs ${e.key}',
        );
      }
    });
  }

  testWidgets('camera and shell docks keep the tabs where they are', (
    tester,
  ) async {
    Future<List<Offset>> centers({required bool camera}) async {
      UiDockItem item(String g, int i) => UiDockItem(
        glyph: g,
        label: g,
        itemKey: ValueKey('t$i'),
        onPressed: () {},
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: OurneyTheme.build(Brightness.light),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 780),
              viewPadding: EdgeInsets.only(bottom: 20),
            ),
            child: Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: UiDock(
                  left: item('journeys', 0),
                  extraLeft: [item('squad', 1)],
                  extraRight: [item('activity', 3)],
                  right: item('profile', 4),
                  snapLabel: 'Snap',
                  onSnap: () {},
                  camera: camera,
                  center: camera ? const SizedBox.square(dimension: 76) : null,
                ),
              ),
            ),
          ),
        ),
      );
      return [
        for (final k in ['t0', 't1', 't3', 't4'])
          tester.getRect(find.byKey(ValueKey(k))).center,
      ];
    }

    final shell = await centers(camera: false);
    final cam = await centers(camera: true);
    for (var i = 0; i < shell.length; i++) {
      expect(cam[i].dx, closeTo(shell[i].dx, 0.01), reason: 'tab $i x');
      expect(cam[i].dy, closeTo(shell[i].dy, 0.01), reason: 'tab $i y');
    }
  });
}
