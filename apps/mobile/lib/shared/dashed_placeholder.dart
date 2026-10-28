import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../app/theme/persona_theme.dart';

/// Empty slot with a dashed outline (F5): "waiting for a photo", a missed
/// day, a squad member who has not checked in. The dashes plus [label] mean
/// the state is never conveyed by color alone.
class DashedPlaceholder extends StatelessWidget {
  const DashedPlaceholder({
    this.icon,
    this.label,
    this.aspectRatio = 1,
    this.radius,
    this.strokeWidth = 1.5,
    this.color,
    super.key,
  });

  final IconData? icon;
  final String? label;
  final double aspectRatio;

  /// Defaults to `OurneyPersonaTheme.cardRadius`, capped at 16.
  final double? radius;
  final double strokeWidth;

  /// Optional override for the dash border, icon, and label color (e.g. over
  /// dark camera viewfinders in light mode).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final pTheme = OurneyPersonaTheme.of(context);
    final fg = color ?? pTheme.inkMuted;
    final r = radius ?? (pTheme.cardRadius < 16 ? pTheme.cardRadius : 16.0);
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: fg,
            radius: r,
            strokeWidth: strokeWidth,
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) Icon(icon, color: fg, size: 24),
                  if (icon != null && label != null) const SizedBox(height: 4),
                  if (label != null)
                    Flexible(
                      child: Text(
                        label!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: fg,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
  });

  final Color color;
  final double radius;
  final double strokeWidth;

  static const double _dash = 6;
  static const double _gap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final inset = rect.deflate(strokeWidth / 2);
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(inset, Radius.circular(radius)));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    for (final PathMetric metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = distance + _dash;
        canvas.drawPath(
          metric.extractPath(
            distance,
            end > metric.length ? metric.length : end,
          ),
          paint,
        );
        distance = end + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.strokeWidth != strokeWidth;
}
