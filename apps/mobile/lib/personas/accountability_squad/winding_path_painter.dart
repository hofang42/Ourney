import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

/// Style of the winding trail connecting Polaroid checkpoints in S1 and M1.
enum WindingPathStyle {
  /// S1 (`steppingStoneQuest`): broad S-curve stepping-stone road with a filled
  /// active progress ribbon and dark outline edges.
  steppingStoneRibbon,

  /// M1 (`scrapbookThread`): continuous terracotta stitched thread with
  /// cross-stitch tick marks at each Polaroid anchor.
  stitchedThread,
}

/// Reusable `CustomPainter` shared by **S1** (`SteppingStoneQuestTimeline`) and
/// **M1** (`ScrapbookThreadTimeline`) as specified in `docs/TASKS.md` §2 & §3.
///
/// Connects an ordered list of [waypoints] (in canvas coordinates) using smooth
/// cubic Beziers.
class WindingPathPainter extends CustomPainter {
  const WindingPathPainter({
    required this.waypoints,
    required this.activeIndex,
    required this.style,
    this.activeFromIndex = 0,
    required this.activeColor,
    required this.inactiveColor,
    required this.outlineColor,
    this.ribbonWidth = 22.0,
    this.outlineWidth = 2.0,
    this.knotTieDx = 0.0,
    this.roundStart = false,
    this.roundEnd = false,
    this.clipToBand = false,
  });

  /// Ordered anchor points along the vertical trail.
  final List<Offset> waypoints;

  /// Index in [waypoints] up to which the trail is highlighted as completed
  /// (`-1` when no step is completed yet).
  final int activeIndex;

  /// First waypoint of the highlighted run (`0` = from the start). S1 walks the
  /// trail bottom-up, so today's segment highlights only its lower half.
  final int activeFromIndex;

  final WindingPathStyle style;
  final Color activeColor;
  final Color inactiveColor;
  final Color outlineColor;
  final double ribbonWidth;
  final double outlineWidth;

  /// Horizontal length of the short tie that links each knot to its Polaroid
  /// (negative = card on the left, `0` = no tie). Used by the stitched thread.
  final double knotTieDx;

  /// Round off the first / last waypoint of the ribbon. Interior joins stay
  /// square so neighbouring segments overlap seamlessly; only the true ends of
  /// the road (under the trophy, off the bottom) get a cap.
  final bool roundStart;
  final bool roundEnd;

  /// Paints only inside the canvas (with a 1dp overlap). Lazy lists draw one
  /// band per item; clipping keeps one band's outline from landing on the
  /// previous band's fill, which would leave a dark ring at the joins.
  final bool clipToBand;

  /// Builds a smooth S-curve [Path] passing through [points].
  static Path buildSmoothPath(List<Offset> points) {
    final path = Path();
    if (points.isEmpty) return path;
    path.moveTo(points.first.dx, points.first.dy);
    if (points.length == 1) return path;

    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final midY = (p0.dy + p1.dy) / 2;
      path.cubicTo(p0.dx, midY, p1.dx, midY, p1.dx, p1.dy);
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (waypoints.length < 2) return;
    if (clipToBand) {
      canvas.clipRect(
        Rect.fromLTWH(-4, -1, size.width + 8, size.height + 2),
        doAntiAlias: false,
      );
    }
    switch (style) {
      case WindingPathStyle.steppingStoneRibbon:
        _paintSteppingStoneRibbon(canvas);
      case WindingPathStyle.stitchedThread:
        _paintStitchedThread(canvas);
    }
  }

  void _paintSteppingStoneRibbon(Canvas canvas) {
    final fullPath = buildSmoothPath(waypoints);

    Paint stroke(Color c, double width) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Ink edge with a heavier lower lip, like the reference road: the outline
    // is drawn twice, the second copy nudged down, before the fill goes on.
    final edge = ribbonWidth + outlineWidth * 2;
    canvas
      ..save()
      ..translate(0, outlineWidth * 1.6)
      ..drawPath(fullPath, stroke(outlineColor, edge))
      ..restore()
      ..drawPath(fullPath, stroke(outlineColor, edge))
      ..drawPath(fullPath, stroke(inactiveColor, ribbonWidth));

    void cap(Offset at, Color color, double width) =>
        canvas.drawCircle(at, width / 2, Paint()..color = color);
    for (final at in [
      if (roundStart) waypoints.first,
      if (roundEnd) waypoints.last,
    ]) {
      cap(at + Offset(0, outlineWidth * 1.6), outlineColor, edge);
      cap(at, outlineColor, edge);
      cap(at, inactiveColor, ribbonWidth);
    }

    // Highlighted run (the stretch still ahead of the traveller in S1).
    final clampedEnd = activeIndex.clamp(0, waypoints.length - 1);
    final clampedStart = activeFromIndex.clamp(0, clampedEnd);
    if (activeIndex >= 0 && clampedEnd > clampedStart) {
      final activePath = buildSmoothPath(
        waypoints.sublist(clampedStart, clampedEnd + 1),
      );
      canvas.drawPath(activePath, stroke(activeColor, ribbonWidth));
    }
  }

  void _paintStitchedThread(Canvas canvas) {
    final fullPath = buildSmoothPath(waypoints);

    // Continuous hand-sewn thread: a thin solid line with a faint second
    // strand so it reads as twisted cord rather than a UI divider.
    canvas
      ..drawPath(
        fullPath,
        Paint()
          ..color = activeColor.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.6
          ..strokeCap = StrokeCap.round,
      )
      ..drawPath(
        fullPath,
        Paint()
          ..color = activeColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.7
          ..strokeCap = StrokeCap.round,
      );

    // A small tied knot at each Polaroid anchor.
    final knotPaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final startIdx = waypoints.length > 2 ? 1 : 0;
    final endIdx = waypoints.length > 2
        ? waypoints.length - 1
        : waypoints.length;
    for (var i = startIdx; i < endIdx; i++) {
      final p = waypoints[i];
      canvas
        ..drawLine(p + const Offset(-6, -5), p + const Offset(6, 5), knotPaint)
        ..drawLine(p + const Offset(-6, 5), p + const Offset(6, -5), knotPaint)
        ..drawCircle(p, 2.6, Paint()..color = activeColor);
      if (knotTieDx != 0) {
        canvas
          ..drawLine(p, p + Offset(knotTieDx, -3), knotPaint)
          ..drawCircle(
            p + Offset(knotTieDx, -3),
            2.2,
            Paint()..color = activeColor,
          );
      }
    }
  }

  @override
  bool shouldRepaint(WindingPathPainter oldDelegate) {
    return !listEquals(oldDelegate.waypoints, waypoints) ||
        oldDelegate.activeIndex != activeIndex ||
        oldDelegate.activeFromIndex != activeFromIndex ||
        oldDelegate.style != style ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor ||
        oldDelegate.outlineColor != outlineColor ||
        oldDelegate.ribbonWidth != ribbonWidth ||
        oldDelegate.outlineWidth != outlineWidth ||
        oldDelegate.knotTieDx != knotTieDx ||
        oldDelegate.roundStart != roundStart ||
        oldDelegate.roundEnd != roundEnd ||
        oldDelegate.clipToBand != clipToBand;
  }
}
