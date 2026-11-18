import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../../ui/ui.dart';
import '../../l10n/generated/journeys_localizations.dart';

/// Visual preview illustration inside a create-flow type deck card.
class CreateDeckPreview extends StatelessWidget {
  const CreateDeckPreview({required this.skinId, super.key});

  final String skinId;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final l10n = JourneysL10n.of(context);
    return switch (skinId) {
      'quiet' => _QuietPreview(ui: ui, privateLabel: l10n.journeys_deckPrivate),
      'squad' => _SquadPreview(ui: ui),
      'flexer' => CustomPaint(
        painter: _FlexerPreviewPainter(accent: ui.accent, contrast: ui.brand),
        child: const SizedBox.expand(),
      ),
      'memory' => _MemoryPreview(ui: ui),
      'couple' => _CouplePreview(ui: ui),
      _ => CustomPaint(
        painter: _MinimalPreviewPainter(ink: ui.ink, accent: ui.accent),
        child: const SizedBox.expand(),
      ),
    };
  }
}

class _QuietPreview extends StatelessWidget {
  const _QuietPreview({required this.ui, required this.privateLabel});

  final OurneyUi ui;
  final String privateLabel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        final nodeSize = math.min(34.0, h * 0.34);
        final points = [
          Offset(w * 0.18, h * 0.58),
          Offset(w * 0.50, h * 0.44),
          Offset(w * 0.82, h * 0.32),
        ];
        return Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _QuietCurvePainter(accent: ui.accent)),
            for (final pt in points)
              Positioned(
                left: pt.dx - nodeSize / 2,
                top: pt.dy - nodeSize / 2,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
                  child: Container(
                    width: nodeSize,
                    height: nodeSize,
                    decoration: BoxDecoration(
                      color: ui.accent.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                      border: Border.all(color: ui.ink, width: 2),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 10,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ui.bg,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: ui.ink, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const OurneyIcon(name: 'lock', size: 15),
                    const SizedBox(width: 5),
                    Text(
                      privateLabel,
                      style: UiText.body(
                        size: 12,
                        weight: FontWeight.w700,
                        height: 1.2,
                        color: ui.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _QuietCurvePainter extends CustomPainter {
  const _QuietCurvePainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.1, size.height * 0.64)
      ..quadraticBezierTo(
        size.width * 0.48,
        size.height * 0.36,
        size.width * 0.9,
        size.height * 0.28,
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_QuietCurvePainter old) => old.accent != accent;
}

class _SquadPreview extends StatelessWidget {
  const _SquadPreview({required this.ui});

  final OurneyUi ui;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        final nodeSize = math.min(36.0, h * 0.36);
        final points = [
          Offset(w * 0.20, h * 0.72),
          Offset(w * 0.50, h * 0.48),
          Offset(w * 0.80, h * 0.26),
        ];
        return Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _SquadPathPainter(ink: ui.ink)),
            for (var i = 0; i < points.length; i++)
              Positioned(
                left: points[i].dx - nodeSize / 2,
                top: points[i].dy - nodeSize / 2,
                child: Container(
                  width: nodeSize,
                  height: nodeSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: ui.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: ui.ink, width: 2),
                  ),
                  child: i == points.length - 1
                      ? const OurneyIcon(name: 'trophy', size: 22, active: true)
                      : null,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SquadPathPainter extends CustomPainter {
  const _SquadPathPainter({required this.ink});

  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.20, size.height * 0.72)
      ..cubicTo(
        size.width * 0.46,
        size.height * 0.74,
        size.width * 0.30,
        size.height * 0.48,
        size.width * 0.50,
        size.height * 0.48,
      )
      ..cubicTo(
        size.width * 0.70,
        size.height * 0.48,
        size.width * 0.54,
        size.height * 0.24,
        size.width * 0.80,
        size.height * 0.26,
      );
    final paint = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        final next = math.min(d + 6, metric.length);
        canvas.drawPath(metric.extractPath(d, next), paint);
        d += 11;
      }
    }
  }

  @override
  bool shouldRepaint(_SquadPathPainter old) => old.ink != ink;
}

class _FlexerPreviewPainter extends CustomPainter {
  const _FlexerPreviewPainter({required this.accent, required this.contrast});

  final Color accent;
  final Color contrast;

  @override
  void paint(Canvas canvas, Size size) {
    final p1 = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final p2 = Paint()
      ..color = contrast
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.12, size.height * 0.36),
      Offset(size.width * 0.88, size.height * 0.54),
      p1,
    );
    canvas.drawLine(
      Offset(size.width * 0.12, size.height * 0.54),
      Offset(size.width * 0.88, size.height * 0.72),
      p2,
    );
  }

  @override
  bool shouldRepaint(_FlexerPreviewPainter old) =>
      old.accent != accent || old.contrast != contrast;
}

class _MemoryPreview extends StatelessWidget {
  const _MemoryPreview({required this.ui});

  final OurneyUi ui;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Transform.rotate(
                  angle: 2 * math.pi / 180,
                  child: Container(
                    width: 132,
                    height: 150,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: ui.surface,
                      border: Border.all(color: ui.ink, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Container(
                            color: ui.accent,
                            alignment: Alignment.center,
                            child: const OurneyIcon(name: 'trip', size: 42),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 2,
                          child: CustomPaint(
                            painter: _DashedLinePainter(color: ui.ink),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Transform.rotate(
                angle: -3 * math.pi / 180,
                child: Container(
                  width: 68,
                  height: 16,
                  color: ui.inkMuted.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset(math.min(x + 6, size.width), size.height / 2),
        paint,
      );
      x += 10;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) => old.color != color;
}

class _CouplePreview extends StatelessWidget {
  const _CouplePreview({required this.ui});

  final OurneyUi ui;

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [ui.accent, ui.surface],
    );
    return Stack(
      alignment: Alignment.center,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: gradient),
              ),
            ),
            const SizedBox(width: 3),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: gradient),
              ),
            ),
          ],
        ),
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ui.surface,
            shape: BoxShape.circle,
            border: Border.all(color: ui.ink, width: 2),
          ),
          child: const OurneyIcon(name: 'heart', size: 20, active: true),
        ),
      ],
    );
  }
}

class _MinimalPreviewPainter extends CustomPainter {
  const _MinimalPreviewPainter({required this.ink, required this.accent});

  final Color ink;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final hPad = size.width * 0.08;
    final vPad = size.height * 0.22;
    final left = hPad;
    final right = size.width - hPad;
    final top = vPad;
    final bottom = size.height - vPad;
    final gridWidth = right - left;
    final colWidth = gridWidth / 7;

    final gridPaint = Paint()
      ..color = ink
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (var i = 1; i <= 6; i++) {
      final x = left + colWidth * i;
      canvas.drawLine(Offset(x, top), Offset(x, bottom), gridPaint);
    }

    final midY = size.height / 2;
    final accentPaint = Paint()
      ..color = accent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(left, midY), Offset(right, midY), accentPaint);
  }

  @override
  bool shouldRepaint(_MinimalPreviewPainter old) =>
      old.ink != ink || old.accent != accent;
}

/// Mini HUD strip shown below the preview in a create-flow type deck card.
class CreateDeckHud extends StatelessWidget {
  const CreateDeckHud({required this.skinId, super.key});

  final String skinId;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final l10n = JourneysL10n.of(context);
    final textStyle = UiText.body(
      size: 12,
      weight: FontWeight.w700,
      height: 1.3,
      color: ui.ink,
    );
    final Widget child = switch (skinId) {
      'quiet' => const OurneyIcon(name: 'profile', size: 28),
      'squad' => FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const OurneyIcon(name: 'book', size: 14),
            const SizedBox(width: 4),
            Text(l10n.journeys_deckHudStudy, style: textStyle),
            const SizedBox(width: 8),
            const OurneyIcon(name: 'flame', size: 14, active: true),
            const SizedBox(width: 4),
            Text('21', style: textStyle),
          ],
        ),
      ),
      'flexer' => Text(
        l10n.journeys_deckHudFlexer,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textStyle,
      ),
      'memory' => Text(
        l10n.journeys_deckHudMemory,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textStyle.copyWith(fontFamily: UiFonts.mono),
      ),
      'couple' => Text(
        l10n.journeys_deckHudCouple,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textStyle,
      ),
      _ => Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: ui.accent,
          shape: BoxShape.circle,
          border: Border.all(color: ui.ink, width: 2),
        ),
      ),
    };
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ui.ink, width: 1.5),
      ),
      child: child,
    );
  }
}
