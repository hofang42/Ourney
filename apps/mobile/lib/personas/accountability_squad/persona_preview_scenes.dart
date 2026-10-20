import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Which illustrated placeholder photo [SampleScene] paints.
enum SampleSceneKind {
  desk,
  laptop,
  window,
  forest,
  clouds,
  campfire,
  cafe,
  group,
}

/// Procedurally painted "photo" used only by the persona preview harness, so
/// the six screens can be judged against the reference boards without bundling
/// binary sample images.
class SampleScene extends StatelessWidget {
  const SampleScene(this.kind, {this.seed = 0, super.key});

  final SampleSceneKind kind;
  final int seed;

  static SampleSceneKind studyKind(int i) => const [
    SampleSceneKind.desk,
    SampleSceneKind.laptop,
    SampleSceneKind.window,
  ][i % 3];

  static SampleSceneKind travelKind(int i) => const [
    SampleSceneKind.forest,
    SampleSceneKind.clouds,
    SampleSceneKind.campfire,
    SampleSceneKind.cafe,
    SampleSceneKind.group,
  ][i % 5];

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: CustomPaint(
        painter: _ScenePainter(kind, seed),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _ScenePainter extends CustomPainter {
  const _ScenePainter(this.kind, this.seed);

  final SampleSceneKind kind;
  final int seed;

  static LinearGradient _vertical(List<Color> colors) => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: colors,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final w = size.width;
    final h = size.height;
    final rnd = math.Random(seed * 31 + kind.index);
    final p = Paint();

    void fillSky(List<Color> colors) =>
        canvas.drawRect(rect, p..shader = _vertical(colors).createShader(rect));

    void block(Rect r, Color c, {double radius = 0}) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, Radius.circular(radius)),
        Paint()..color = c,
      );
    }

    switch (kind) {
      case SampleSceneKind.desk:
        fillSky(const [
          Color(0xFFF2C79B),
          Color(0xFFB98963),
          Color(0xFF6B4A35),
        ]);
        block(Rect.fromLTWH(0, h * 0.58, w, h * 0.42), const Color(0xFF8A6244));
        // Open book.
        final book = Path()
          ..moveTo(w * 0.12, h * 0.86)
          ..lineTo(w * 0.5, h * 0.7)
          ..lineTo(w * 0.88, h * 0.86)
          ..lineTo(w * 0.5, h * 0.98)
          ..close();
        canvas.drawPath(book, Paint()..color = const Color(0xFFF6EEDD));
        canvas.drawLine(
          Offset(w * 0.5, h * 0.7),
          Offset(w * 0.5, h * 0.98),
          Paint()
            ..color = const Color(0x55000000)
            ..strokeWidth = 1.2,
        );
        // Cup.
        block(
          Rect.fromLTWH(w * 0.66, h * 0.55, w * 0.18, h * 0.11),
          const Color(0xFFE9A15A),
          radius: 4,
        );
        // Window glow.
        block(
          Rect.fromLTWH(w * 0.08, h * 0.08, w * 0.5, h * 0.3),
          const Color(0xAAFFE0B0),
          radius: 3,
        );
      case SampleSceneKind.laptop:
        fillSky(const [
          Color(0xFFE8D2B0),
          Color(0xFFA98466),
          Color(0xFF5E4331),
        ]);
        block(
          Rect.fromLTWH(w * 0.18, h * 0.22, w * 0.64, h * 0.4),
          const Color(0xFF2C3440),
          radius: 4,
        );
        block(
          Rect.fromLTWH(w * 0.22, h * 0.27, w * 0.56, h * 0.3),
          const Color(0xFFC9DDF2),
          radius: 2,
        );
        for (var i = 0; i < 4; i++) {
          block(
            Rect.fromLTWH(
              w * 0.27,
              h * (0.31 + i * 0.06),
              w * (0.4 - i * 0.04),
              3,
            ),
            const Color(0xFF7E93AB),
          );
        }
        block(
          Rect.fromLTWH(w * 0.1, h * 0.62, w * 0.8, h * 0.06),
          const Color(0xFFBFC3C9),
          radius: 3,
        );
        block(Rect.fromLTWH(0, h * 0.7, w, h * 0.3), const Color(0xFFF1E7D3));
      case SampleSceneKind.window:
        fillSky(const [
          Color(0xFFF3A66B),
          Color(0xFFF6C99B),
          Color(0xFFD9B58C),
        ]);
        block(
          Rect.fromLTWH(w * 0.05, h * 0.06, w * 0.9, h * 0.46),
          const Color(0xFF7FA6D3),
          radius: 4,
        );
        canvas.drawRect(
          Rect.fromLTWH(w * 0.05, h * 0.36, w * 0.9, h * 0.16),
          Paint()..color = const Color(0xFFE8895A),
        );
        for (var i = 0; i < 6; i++) {
          block(
            Rect.fromLTWH(
              w * (0.08 + i * 0.15),
              h * (0.36 - rnd.nextDouble() * 0.08),
              w * 0.09,
              h * 0.16,
            ),
            const Color(0xFF4A4458),
          );
        }
        block(Rect.fromLTWH(0, h * 0.62, w, h * 0.38), const Color(0xFFC79A6E));
        block(
          Rect.fromLTWH(w * 0.14, h * 0.7, w * 0.3, h * 0.12),
          const Color(0xFFE6A25D),
          radius: 5,
        );
      case SampleSceneKind.forest:
        fillSky(const [
          Color(0xFFDDE6D5),
          Color(0xFF7E9A74),
          Color(0xFF2F4B33),
        ]);
        for (var i = 0; i < 9; i++) {
          final x = w * (0.04 + i * 0.12);
          block(
            Rect.fromLTWH(x, h * 0.1, w * 0.035, h * 0.78),
            Color.lerp(
              const Color(0xFF3B2F26),
              const Color(0xFF5A4636),
              i / 9,
            )!,
          );
        }
        block(Rect.fromLTWH(0, h * 0.78, w, h * 0.22), const Color(0xFFC8A576));
      case SampleSceneKind.clouds:
        fillSky(const [
          Color(0xFF8DB7E3),
          Color(0xFFD7E6F4),
          Color(0xFFF4EFE4),
        ]);
        for (var i = 0; i < 4; i++) {
          canvas.drawOval(
            Rect.fromLTWH(
              w * (-0.1 + i * 0.3),
              h * (0.52 + rnd.nextDouble() * 0.18),
              w * 0.7,
              h * 0.3,
            ),
            Paint()..color = Colors.white.withValues(alpha: 0.78),
          );
        }
        block(Rect.fromLTWH(0, h * 0.86, w, h * 0.14), const Color(0xFF6A7F66));
      case SampleSceneKind.campfire:
        fillSky(const [
          Color(0xFF14110F),
          Color(0xFF2B1D16),
          Color(0xFF4A2A18),
        ]);
        canvas.drawCircle(
          Offset(w * 0.5, h * 0.66),
          w * 0.3,
          Paint()
            ..shader =
                const RadialGradient(
                  colors: [Color(0xFFFFB347), Color(0x00FF6A00)],
                ).createShader(
                  Rect.fromCircle(
                    center: Offset(w * 0.5, h * 0.66),
                    radius: w * 0.3,
                  ),
                ),
        );
        final flame = Path()
          ..moveTo(w * 0.44, h * 0.78)
          ..quadraticBezierTo(w * 0.42, h * 0.6, w * 0.5, h * 0.5)
          ..quadraticBezierTo(w * 0.58, h * 0.6, w * 0.56, h * 0.78)
          ..close();
        canvas.drawPath(flame, Paint()..color = const Color(0xFFFFC857));
      case SampleSceneKind.cafe:
        fillSky(const [
          Color(0xFFEBD9BC),
          Color(0xFFC69C6D),
          Color(0xFF7A5A3F),
        ]);
        block(
          Rect.fromLTWH(w * 0.1, h * 0.1, w * 0.8, h * 0.4),
          const Color(0xFFBFD6D2),
          radius: 4,
        );
        block(Rect.fromLTWH(0, h * 0.62, w, h * 0.38), const Color(0xFF8B6444));
        block(
          Rect.fromLTWH(w * 0.2, h * 0.5, w * 0.24, h * 0.3),
          const Color(0xFF3F3A3A),
          radius: w * 0.12,
        );
        block(
          Rect.fromLTWH(w * 0.56, h * 0.5, w * 0.24, h * 0.3),
          const Color(0xFFB55D4C),
          radius: w * 0.12,
        );
      case SampleSceneKind.group:
        fillSky(const [
          Color(0xFFC9D4C5),
          Color(0xFF8CA08A),
          Color(0xFF4F6551),
        ]);
        const tones = [
          Color(0xFFB85C4A),
          Color(0xFFD9B38A),
          Color(0xFF5B6F8A),
          Color(0xFFC98B5E),
        ];
        // Sized from the width so the group stays proportioned in tall
        // (viewfinder) and square (Polaroid) frames alike.
        final base = h * 0.98;
        for (var i = 0; i < 4; i++) {
          final cx = w * (0.2 + i * 0.2);
          final bodyH = w * 0.55;
          canvas.drawCircle(
            Offset(cx, base - bodyH - w * 0.02),
            w * 0.09,
            Paint()..color = const Color(0xFFF0C9A4),
          );
          block(
            Rect.fromLTWH(
              cx - w * 0.1,
              base - bodyH + w * 0.08,
              w * 0.2,
              bodyH,
            ),
            tones[i],
            radius: w * 0.07,
          );
        }
    }

    // Soft vignette for a photographic feel.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          radius: 0.95,
          colors: [Color(0x00000000), Color(0x40000000)],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_ScenePainter old) => old.kind != kind || old.seed != seed;
}
