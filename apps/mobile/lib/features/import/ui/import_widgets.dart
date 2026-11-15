import 'dart:io';

import 'package:flutter/material.dart';

import '../../../ui/ui.dart';

/// Figma `.library-scene` gradients (placeholder art when a photo cannot be
/// decoded). Index wraps over the six scenes.
const List<List<Color>> _scenes = [
  [Color(0xFF9DC6DF), Color(0xFFF3D8AC)],
  [Color(0xFFB8A9D5), Color(0xFFF0D89D)],
  [Color(0xFF9FC9D6), Color(0xFFE9C0A9)],
  [Color(0xFF8FB996), Color(0xFFE7C89B)],
  [Color(0xFFC9C9C9), Color(0xFFF5F5F5)],
  [Color(0xFFCC8B86), Color(0xFFF1D7B4)],
];

/// Fixed light ink for fills that stay light in both themes.
const Color importInkOnLight = Color(0xFF1A1A1A);

/// `.import-type-grid button.selected` fill (sticker yellow).
const Color importSelectedYellow = Color(0xFFFFD84D);

/// `.import-photo-grid i` check badge.
const Color importCheckGreen = Color(0xFF3DE88C);

/// A photo thumbnail: the file when it decodes, else a Figma scene gradient.
class ImportThumb extends StatelessWidget {
  const ImportThumb({
    required this.path,
    required this.index,
    this.height = 112,
    this.radius = 8,
    super.key,
  });

  final String? path;
  final int index;
  final double height;
  final double radius;

  Widget _scene() {
    final c = _scenes[index % _scenes.length];
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: c,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: path == null
              ? _scene()
              : Image.file(
                  File(path!),
                  fit: BoxFit.cover,
                  cacheWidth: 300,
                  errorBuilder: (context, error, stack) => _scene(),
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
    final dark = skin == 'flexer';
    final fg = dark ? Colors.white : importInkOnLight;
    final bg = switch (skin) {
      'quiet' => const Color(0xFFEFF3F0),
      'memory' => const Color(0xFFF4EFE6),
      'flexer' => const Color(0xFF14161F),
      _ => const Color(0xFFFFF8EE),
    };
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
      fontSize: 8,
      height: 1.2,
      fontWeight: FontWeight.w800,
      color: fg,
    );
    return ExcludeSemantics(
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
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
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFFF8A3D), width: 2),
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
                            color: importSelectedYellow,
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
