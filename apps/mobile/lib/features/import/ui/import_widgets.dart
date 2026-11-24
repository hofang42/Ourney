import 'dart:io';

import 'package:flutter/material.dart';

import '../../../ui/ui.dart';
import '../data/import_types.dart';

/// A photo thumbnail: the file when it decodes, else a broken-image state
/// (never fake art that looks like a real photo).
class ImportThumb extends StatelessWidget {
  const ImportThumb({
    required this.path,
    this.height = 112,
    this.radius = 8,
    super.key,
  });

  final String? path;
  final double height;
  final double radius;

  Widget _broken(BuildContext context) {
    final ui = context.ui;
    return ColoredBox(
      key: const ValueKey('import-thumb-broken'),
      color: ui.fill,
      child: Center(
        child: OurneyIcon(
          name: 'image-off',
          size: (height * 0.4).clamp(16, 28),
          flat: true,
          color: ui.inkMuted,
        ),
      ),
    );
  }

  /// No file to show (a saved photo's copies are deleted): a plain tile.
  Widget _empty(BuildContext context) {
    final ui = context.ui;
    return ColoredBox(
      key: const ValueKey('import-thumb-empty'),
      color: ui.fill,
      child: Center(
        child: OurneyIcon(
          name: 'image',
          size: (height * 0.4).clamp(16, 28),
          flat: true,
          color: ui.inkMuted,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = path;
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: p == null
              ? _empty(context)
              : Image.file(
                  File(p),
                  fit: BoxFit.cover,
                  cacheWidth: 300,
                  errorBuilder: (context, error, stack) => _broken(context),
                ),
        ),
      ),
    );
  }
}

/// Dashed rounded outline (`border-style: dashed`).
class DashedBox extends StatelessWidget {
  const DashedBox({
    required this.child,
    this.radius = 14,
    this.width = 2,
    this.padding = EdgeInsets.zero,
    this.opacity = 1,
    super.key,
  });

  final Widget child;
  final double radius;
  final double width;
  final EdgeInsetsGeometry padding;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return Opacity(
      opacity: opacity,
      child: CustomPaint(
        painter: _DashPainter(ui.ink, radius, width),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  _DashPainter(this.color, this.radius, this.width);

  final Color color;
  final double radius;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    final inset = width / 2;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(inset, inset, size.width - width, size.height - width),
          Radius.circular(radius),
        ),
      );
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 6), paint);
        d += 10;
      }
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) =>
      old.color != color || old.radius != radius || old.width != width;
}

/// Figma `.layout-preview`: a 92dp mini of a skin (top bar, three timeline
/// nodes, HUD pill). Decorative, so it ignores text scale and semantics.
class ImportLayoutPreview extends StatelessWidget {
  const ImportLayoutPreview({
    required this.skin,
    required this.previewLabel,
    required this.hudLabel,
    super.key,
  });

  /// `quiet`, `memory`, `flexer` or `minimal`.
  final String skin;
  final String previewLabel;
  final String hudLabel;

  @override
  Widget build(BuildContext context) {
    final style = uiStyleForSkin(importSkinId(skin));
    final fg = style.ink;
    final bg = style.paper;
    final radius = switch (skin) {
      'memory' => 2.0,
      'minimal' => 0.0,
      _ => 8.0,
    };
    Widget dot() => Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: fg),
      ),
    );
    final label = TextStyle(
      fontSize: 10,
      height: 1.3,
      fontWeight: FontWeight.w800,
      color: fg,
    );
    return ExcludeSemantics(
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: MediaQuery.textScalerOf(context)
              .clamp(maxScaleFactor: 1.35),
        ),
        child: Container(
          height: 92,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: fg),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            children: [
              Row(
                children: [
                  dot(),
                  Expanded(
                    child: Text(
                      previewLabel,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: label,
                    ),
                  ),
                  dot(),
                ],
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: style.accent, width: 2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      for (var i = 0; i < 3; i++)
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: style.accent,
                            border: Border.all(color: fg, width: 2),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 24,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OurneyIcon(name: 'camera', size: 14, flat: true, color: fg),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        hudLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: label,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
