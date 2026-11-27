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
Future<Rect> paintedBounds(
  String name, {
  required bool active,
  bool ring = true,
}) async {
  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec);
  canvas.translate(_margin.toDouble(), _margin.toDouble());
  OurneyIconPainter(
    name: name,
    color: ourneyIconColor(name),
    ink: const Color(0xFF000000),
    active: active,
    shadow: ring ? const Color(0xFF000000) : null,
    dieCut: ring ? const Color(0xFFFFFFFF) : const Color(0x00000000),
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

/// The sticker may spill this far past the 24dp glyph box (the dock keeps
/// the artwork at full size and gives the die-cut ring this much room).
const _spill = 4.0;

void main() {
  for (final active in [false, true]) {
    final spill = active ? _spill : 0.0;
    testWidgets(
      'dock tab icons stay within the glyph slot + $spill (active=$active)',
      (tester) async {
        final bounds = <String, Rect>{};
        await tester.runAsync(() async {
          for (final name in _tabs) {
            bounds[name] = await paintedBounds(name, active: active);
          }
        });
        for (final e in bounds.entries) {
          final r = e.value;
          String reason() => '${e.key} $r';
          expect(r.left, greaterThanOrEqualTo(-spill), reason: reason());
          expect(r.top, greaterThanOrEqualTo(-spill), reason: reason());
          expect(r.right, lessThanOrEqualTo(_box + spill), reason: reason());
          expect(r.bottom, lessThanOrEqualTo(_box + spill), reason: reason());
        }
      },
    );
  }

  testWidgets('active artwork is never smaller than inactive', (tester) async {
    await tester.runAsync(() async {
      for (final name in [..._tabs, 'camera', 'react-heart', 'flame']) {
        final off = await paintedBounds(name, active: false, ring: false);
        final on = await paintedBounds(name, active: true, ring: false);
        expect(on.width, greaterThanOrEqualTo(off.width - 0.5), reason: name);
        expect(on.height, greaterThanOrEqualTo(off.height - 0.5), reason: name);
        // With the ring off, the active glyph is exactly the inactive one.
        expect(on, off, reason: name);
      }
    });
  });

  testWidgets(
    'camera dock tabs sit at the E4 camera-route centres and glide there '
    'monotonically during the 220ms morph while keeping y invariant',
    (tester) async {
      for (final (w, expectedShellX, expectedCamX) in const [
        (360.0, [47.5, 108.5, 251.5, 312.5], [45.5, 102.5, 257.5, 314.5]),
        (
          390.0,
          [51.25, 119.75, 270.25, 338.75],
          [49.25, 113.75, 276.25, 340.75],
        ),
      ]) {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(w, 780);
        addTearDown(tester.view.reset);

        var camera = false;
        late StateSetter setHost;

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
              data: MediaQueryData(
                size: Size(w, 780),
                viewPadding: const EdgeInsets.only(bottom: 20),
              ),
              child: Scaffold(
                body: StatefulBuilder(
                  builder: (context, setState) {
                    setHost = setState;
                    return Align(
                      alignment: Alignment.bottomCenter,
                      child: UiDock(
                        key: ValueKey('dock-$w'),
                        left: item('journeys', 0),
                        extraLeft: [item('squad', 1)],
                        extraRight: [item('activity', 3)],
                        right: item('profile', 4),
                        snapLabel: 'Snap',
                        onSnap: () {},
                        camera: camera,
                        center: camera
                            ? const SizedBox.square(dimension: 76)
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        List<Offset> centers() => [
          for (final k in ['t0', 't1', 't3', 't4'])
            tester.getRect(find.byKey(ValueKey(k))).center,
        ];

        final shell = centers();
        for (var i = 0; i < 4; i++) {
          expect(
            shell[i].dx,
            closeTo(expectedShellX[i], 0.5),
            reason: 'shell tab $i x at W=$w',
          );
        }

        // Flip to camera route and sample mid-morph at 55ms, 110ms, 165ms, 220ms
        setHost(() => camera = true);
        await tester.pump();

        var prev = shell;
        for (var step = 1; step <= 4; step++) {
          await tester.pump(const Duration(milliseconds: 55));
          final cur = centers();
          for (var i = 0; i < 4; i++) {
            // Y is invariant throughout
            expect(
              cur[i].dy,
              closeTo(shell[i].dy, 0.01),
              reason: 'tab $i y invariant at step $step (W=$w)',
            );
            // Left tabs (0, 1) glide monotonically left; right tabs (2, 3) glide right
            if (i < 2) {
              expect(
                cur[i].dx,
                lessThanOrEqualTo(prev[i].dx + 0.001),
                reason: 'left tab $i monotonic at step $step (W=$w)',
              );
            } else {
              expect(
                cur[i].dx,
                greaterThanOrEqualTo(prev[i].dx - 0.001),
                reason: 'right tab $i monotonic at step $step (W=$w)',
              );
            }
          }
          prev = cur;
        }

        await tester.pumpAndSettle();
        final cam = centers();
        for (var i = 0; i < 4; i++) {
          expect(
            cam[i].dx,
            closeTo(expectedCamX[i], 0.5),
            reason: 'camera tab $i x at W=$w',
          );
          expect(
            cam[i].dy,
            closeTo(shell[i].dy, 0.01),
            reason: 'camera tab $i y at W=$w',
          );
        }
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      }
    },
  );
}
