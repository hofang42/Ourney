import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../features/journeys/domain/journey_progress.dart';

/// Data point extracted from a [TimelineDay] that has a non-null `metricValue`.
@immutable
class MetricCurvePoint {
  const MetricCurvePoint({required this.dayNumber, required this.value});

  final int dayNumber;
  final double value;
}

/// Extracts chronological [MetricCurvePoint]s from [days], and computes summary
/// statistics (`startValue`, `latestValue`, `delta`, `total`).
@immutable
class MetricSeries {
  const MetricSeries(this.points);

  factory MetricSeries.fromDays(Iterable<TimelineDay> days) {
    final pts = <MetricCurvePoint>[];
    for (final d in days) {
      final v = d.checkIn?.metricValue;
      if (v != null && v.isFinite) {
        pts.add(MetricCurvePoint(dayNumber: d.dayNumber, value: v));
      }
    }
    pts.sort((a, b) => a.dayNumber.compareTo(b.dayNumber));
    return MetricSeries(pts);
  }

  final List<MetricCurvePoint> points;

  bool get isEmpty => points.isEmpty;
  bool get isSingle => points.length == 1;
  bool get hasCurve => points.length >= 2;

  double? get startValue => points.isEmpty ? null : points.first.value;
  double? get latestValue => points.isEmpty ? null : points.last.value;

  /// Difference between the latest and the first logged value (`latest - start`).
  double? get delta =>
      hasCurve ? (points.last.value - points.first.value) : null;

  /// Sum of all logged values (used by R1 telemetry totals).
  double get total => points.fold<double>(0, (sum, pt) => sum + pt.value);

  /// Formats [v] with at most 1 decimal place (`65` -> `65.0`, `62.45` -> `62.5`),
  /// appending [unit] when non-empty.
  static String formatValue(double v, [String? unit]) {
    final numStr = v.toStringAsFixed(1);
    final u = unit?.trim() ?? '';
    return u.isEmpty ? numStr : '$numStr $u';
  }

  /// Formats signed delta (`-3.2 kg` or `+1.5 kg`).
  static String formatDelta(double delta, [String? unit]) {
    final sign = delta > 0 ? '+' : '';
    final numStr = '$sign${delta.toStringAsFixed(1)}';
    final u = unit?.trim() ?? '';
    return u.isEmpty ? numStr : '$numStr $u';
  }
}

/// Smooth cubic-Bezier trend curve painter shared by **Q1**
/// (`ConnectedWeightCurveTimeline`) and **R1** (`AthleticTelemetryTimeline`).
///
/// Properly handles 0, 1, and 2+ data points (`docs/TASKS.md` Q1 & R1).
class MetricCurvePainter extends CustomPainter {
  MetricCurvePainter({
    required this.points,
    required this.lineColor,
    required this.gridColor,
    required this.dotStrokeColor,
    this.glow = false,
  });

  final List<MetricCurvePoint> points;
  final Color lineColor;
  final Color gridColor;
  final Color dotStrokeColor;
  final bool glow;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    const hPad = 14.0;
    const vPad = 14.0;
    final chartW = math.max(1.0, size.width - hPad * 2);
    final chartH = math.max(1.0, size.height - vPad * 2);

    // Subtle horizontal guide lines.
    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final frac in const [0.2, 0.5, 0.8]) {
      final y = vPad + chartH * frac;
      canvas.drawLine(Offset(hPad, y), Offset(size.width - hPad, y), gridPaint);
    }

    if (points.isEmpty) return;

    if (points.length == 1) {
      final center = Offset(size.width / 2, size.height / 2);
      final dashPaint = Paint()
        ..color = lineColor.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawLine(
        Offset(hPad, center.dy),
        Offset(size.width - hPad, center.dy),
        dashPaint,
      );
      _drawNode(canvas, center, radius: 5.5);
      return;
    }

    var minV = points.first.value;
    var maxV = points.first.value;
    for (final p in points) {
      if (p.value < minV) minV = p.value;
      if (p.value > maxV) maxV = p.value;
    }
    final isFlat = (maxV - minV).abs() < 1e-6;
    final range = isFlat ? 1.0 : (maxV - minV);

    final offsets = <Offset>[];
    for (var i = 0; i < points.length; i++) {
      final t = i / (points.length - 1);
      final x = hPad + chartW * t;
      final normY = isFlat ? 0.5 : (points[i].value - minV) / range;
      final y = vPad + chartH * (1.0 - normY);
      offsets.add(Offset(x, y));
    }

    final curvePath = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (var i = 0; i < offsets.length - 1; i++) {
      final p0 = offsets[i];
      final p1 = offsets[i + 1];
      final midX = (p0.dx + p1.dx) / 2;
      curvePath.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }

    // Soft area fill under the curve.
    final fillPath = Path.from(curvePath)
      ..lineTo(offsets.last.dx, size.height - 4)
      ..lineTo(offsets.first.dx, size.height - 4)
      ..close();
    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = ui.Gradient.linear(Offset(0, vPad), Offset(0, size.height), [
        lineColor.withValues(alpha: glow ? 0.34 : 0.24),
        lineColor.withValues(alpha: 0.0),
      ]);
    canvas.drawPath(fillPath, fillPaint);

    if (glow) {
      final glowPaint = Paint()
        ..color = lineColor.withValues(alpha: 0.40)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawPath(curvePath, glowPaint);
    }

    final strokePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.75
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(curvePath, strokePaint);

    // Draw milestone dots on start, intermediate, and latest points.
    for (var i = 0; i < offsets.length; i++) {
      final isEndpoint = i == 0 || i == offsets.length - 1;
      _drawNode(canvas, offsets[i], radius: isEndpoint ? 5.0 : 3.5);
    }
  }

  void _drawNode(Canvas canvas, Offset center, {required double radius}) {
    final fill = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    final ring = Paint()
      ..color = dotStrokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, fill);
    canvas.drawCircle(center, radius, ring);
  }

  @override
  bool shouldRepaint(MetricCurvePainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.gridColor != gridColor ||
      oldDelegate.dotStrokeColor != dotStrokeColor ||
      oldDelegate.glow != glow;
}
