import 'package:flutter/widgets.dart';

/// Dashed rounded-rectangle outline, the one painter behind every dashed
/// border in the app (placeholders, missed days, today cell, Custom card).
///
/// The stroke is inset by half its width so it stays inside the paint area.
class DashedBorderPainter extends CustomPainter {
  const DashedBorderPainter({
    required this.color,
    this.radius = BorderRadius.zero,
    this.strokeWidth = 1,
    this.dash = 4,
    this.gap = 3,
    this.roundCaps = false,
  });

  final Color color;
  final BorderRadius radius;
  final double strokeWidth;
  final double dash;
  final double gap;
  final bool roundCaps;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = roundCaps ? StrokeCap.round : StrokeCap.butt;
    final path = Path()
      ..addRRect(radius.toRRect(Offset.zero & size).deflate(strokeWidth / 2));
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = distance + dash;
        canvas.drawPath(
          metric.extractPath(
            distance,
            end > metric.length ? metric.length : end,
          ),
          paint,
        );
        distance = end + gap;
      }
    }
  }

  @override
  bool shouldRepaint(DashedBorderPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.strokeWidth != strokeWidth ||
      old.dash != dash ||
      old.gap != gap ||
      old.roundCaps != roundCaps;
}
