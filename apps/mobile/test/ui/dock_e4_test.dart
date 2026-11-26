import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/ui/components/dock.dart';

void main() {
  group('T1 — Pure E4 Geometry (UiDockGeometry.compute)', () {
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
            slot: 62,
            leftL: 12,
            leftR: 144,
            rightL: 216,
            rightR: 348,
            centres: [47, 109, 180, 251, 313],
            capW: 60,
          ),
          (
            w: 360,
            state: 'compact',
            cam: 52,
            islandH: 52,
            bandH: 64,
            slot: 64,
            leftL: 12,
            leftR: 148,
            rightL: 212,
            rightR: 348,
            centres: [48, 112, 180, 248, 312],
            capW: null,
          ),
          (
            w: 360,
            state: 'camera route',
            cam: 76,
            islandH: 64,
            bandH: 76,
            slot: 58,
            leftL: 12,
            leftR: 136,
            rightL: 224,
            rightR: 348,
            centres: [45, 103, 180, 257, 315],
            capW: null,
          ),
          (
            w: 390,
            state: 'shown',
            cam: 60,
            islandH: 64,
            bandH: 64,
            slot: 69.5,
            leftL: 12,
            leftR: 159,
            rightL: 231,
            rightR: 378,
            centres: [50.75, 120.25, 195, 269.75, 339.25],
            capW: 67.5,
          ),
          (
            w: 390,
            state: 'compact',
            cam: 52,
            islandH: 52,
            bandH: 64,
            slot: 71.5,
            leftL: 12,
            leftR: 163,
            rightL: 227,
            rightR: 378,
            centres: [51.75, 123.25, 195, 266.75, 338.25],
            capW: null,
          ),
          (
            w: 390,
            state: 'camera route',
            cam: 76,
            islandH: 64,
            bandH: 76,
            slot: 65.5,
            leftL: 12,
            leftR: 151,
            rightL: 239,
            rightR: 378,
            centres: [48.75, 114.25, 195, 275.75, 341.25],
            capW: null,
          ),
          (
            w: 412,
            state: 'shown',
            cam: 60,
            islandH: 64,
            bandH: 64,
            slot: 75,
            leftL: 12,
            leftR: 170,
            rightL: 242,
            rightR: 400,
            centres: [53.5, 128.5, 206, 283.5, 358.5],
            capW: 73,
          ),
          (
            w: 412,
            state: 'compact',
            cam: 52,
            islandH: 52,
            bandH: 64,
            slot: 76,
            leftL: 14,
            leftR: 174,
            rightL: 238,
            rightR: 398,
            centres: [56, 132, 206, 280, 356],
            capW: null,
          ),
          (
            w: 430,
            state: 'shown',
            cam: 60,
            islandH: 64,
            bandH: 64,
            slot: 76,
            leftL: 19,
            leftR: 179,
            rightL: 251,
            rightR: 411,
            centres: [61, 137, 215, 293, 369],
            capW: 74,
          ),
        ];

    for (final c in cases) {
      test(
        'matches §1.2 reference table at W=${c.w.toInt()} (${c.state})',
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
      '320dp and 430dp graceful bounds: no overflow, slot >= 48dp, constant dockHeight across compact',
      () {
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
      },
    );
  });
}
