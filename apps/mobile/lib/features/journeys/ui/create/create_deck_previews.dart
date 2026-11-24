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
      'flexer' => _FlexerPreview(ui: ui),
      'memory' => _MemoryPreview(ui: ui),
      'couple' => _CouplePreview(ui: ui),
      _ => _MinimalPreview(ui: ui),
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
            Image.asset(
              'assets/samples/weight_loss/cover.webp',
              key: const ValueKey('deck-photo-quiet'),
              fit: BoxFit.cover,
              cacheWidth: 960,
              excludeFromSemantics: true,
              errorBuilder: (context, error, stackTrace) =>
                  ColoredBox(color: ui.ink.withValues(alpha: 0.05)),
            ),
            IgnorePointer(
              child: ColoredBox(
                color: ui.bg.withValues(alpha: ui.isDark ? 0.38 : 0.18),
              ),
            ),
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
                      border: Border.all(color: ui.outline, width: 2),
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
                  border: Border.all(color: ui.outline, width: 1.5),
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

  static const _photos = [
    'assets/samples/ielts_study/08.webp',
    'assets/samples/ielts_study/09.webp',
    'assets/samples/ielts_study/10.webp',
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        final nodeSize = math.min(40.0, h * 0.35);
        final points = [
          Offset(w * 0.20, h * 0.76),
          Offset(w * 0.48, h * 0.56),
          Offset(w * 0.76, h * 0.38),
        ];
        return Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _SquadPathPainter(ink: ui.ink)),
            for (var i = 0; i < points.length; i++)
              Positioned(
                left: points[i].dx - nodeSize / 2,
                top: points[i].dy - nodeSize / 2,
                child: SizedBox(
                  width: nodeSize,
                  height: nodeSize,
                  child: Stack(
                    clipBehavior: Clip.none,
                    fit: StackFit.expand,
                    children: [
                      Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: ui.accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: ui.outline, width: 2),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              _photos[i],
                              key: ValueKey('deck-photo-squad-$i'),
                              fit: BoxFit.cover,
                              cacheWidth: 186,
                              excludeFromSemantics: true,
                              errorBuilder: (context, error, stackTrace) =>
                                  ColoredBox(
                                    color: ui.accent,
                                    child: i == points.length - 1
                                        ? const Center(
                                            child: OurneyIcon(
                                              name: 'trophy',
                                              size: 20,
                                              active: true,
                                              inkColor: UiFlowColors.onPastel,
                                            ),
                                          )
                                        : null,
                                  ),
                            ),
                            if (ui.isDark)
                              const IgnorePointer(
                                child: ColoredBox(color: Color(0x22000000)),
                              ),
                          ],
                        ),
                      ),
                      if (i == points.length - 1)
                        Positioned(
                          right: -4,
                          bottom: -4,
                          child: Container(
                            width: 22,
                            height: 22,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: ui.surface,
                              shape: BoxShape.circle,
                              border: Border.all(color: ui.outline, width: 1.5),
                            ),
                            child: const OurneyIcon(
                              name: 'trophy',
                              size: 13,
                              active: true,
                            ),
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

class _SquadPathPainter extends CustomPainter {
  const _SquadPathPainter({required this.ink});

  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.20, size.height * 0.76)
      ..cubicTo(
        size.width * 0.44,
        size.height * 0.78,
        size.width * 0.28,
        size.height * 0.56,
        size.width * 0.48,
        size.height * 0.56,
      )
      ..cubicTo(
        size.width * 0.68,
        size.height * 0.56,
        size.width * 0.52,
        size.height * 0.36,
        size.width * 0.76,
        size.height * 0.38,
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

class _FlexerPreview extends StatelessWidget {
  const _FlexerPreview({required this.ui});

  final OurneyUi ui;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/samples/morning_run/cover.webp',
          key: const ValueKey('deck-photo-flexer'),
          fit: BoxFit.cover,
          cacheWidth: 540,
          excludeFromSemantics: true,
          errorBuilder: (context, error, stackTrace) =>
              ColoredBox(color: ui.ink.withValues(alpha: 0.05)),
        ),
        IgnorePointer(
          child: ColoredBox(
            color: ui.bg.withValues(alpha: ui.isDark ? 0.32 : 0.14),
          ),
        ),
        CustomPaint(
          painter: _FlexerPreviewPainter(
            accent: ui.accent,
            contrast: ui.brand,
          ),
          child: const SizedBox.expand(),
        ),
      ],
    );
  }
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
      Offset(size.width * 0.12, size.height * 0.62),
      Offset(size.width * 0.88, size.height * 0.75),
      p1,
    );
    canvas.drawLine(
      Offset(size.width * 0.12, size.height * 0.74),
      Offset(size.width * 0.88, size.height * 0.87),
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
                      border: Border.all(color: ui.outline, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: ColoredBox(
                            color: ui.accent,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.asset(
                                  'assets/samples/travel_dalat/02.webp',
                                  key: const ValueKey('deck-photo-memory'),
                                  fit: BoxFit.cover,
                                  cacheWidth: 336,
                                  excludeFromSemantics: true,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Center(
                                        child: OurneyIcon(
                                          name: 'trip',
                                          size: 42,
                                        ),
                                      ),
                                ),
                                if (ui.isDark)
                                  const IgnorePointer(
                                    child: ColoredBox(color: Color(0x22000000)),
                                  ),
                              ],
                            ),
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
    Widget pane(String asset, String key) => DecoratedBox(
      decoration: BoxDecoration(gradient: gradient),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            asset,
            key: ValueKey(key),
            fit: BoxFit.cover,
            cacheWidth: 360,
            excludeFromSemantics: true,
            errorBuilder: (context, error, stackTrace) =>
                DecoratedBox(decoration: BoxDecoration(gradient: gradient)),
          ),
          if (ui.isDark)
            const IgnorePointer(
              child: ColoredBox(color: Color(0x24000000)),
            ),
        ],
      ),
    );
    return Stack(
      alignment: Alignment.center,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: pane(
                'assets/samples/couple_rituals/01.webp',
                'deck-photo-couple-0',
              ),
            ),
            const SizedBox(width: 3),
            Expanded(
              child: pane(
                'assets/samples/couple_rituals/02.webp',
                'deck-photo-couple-1',
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
            border: Border.all(color: ui.outline, width: 2),
          ),
          child: const OurneyIcon(name: 'heart', size: 20, active: true),
        ),
      ],
    );
  }
}

class _MinimalPreview extends StatelessWidget {
  const _MinimalPreview({required this.ui});

  final OurneyUi ui;

  static const _photos = [
    'assets/samples/reading_10_pages/01.webp',
    'assets/samples/reading_10_pages/02.webp',
    'assets/samples/reading_10_pages/03.webp',
    'assets/samples/reading_10_pages/04.webp',
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        final hPad = w * 0.07;
        final gridWidth = w - hPad * 2;
        final colWidth = gridWidth / _photos.length;
        final tileSize = math.min(36.0, math.min(colWidth - 6, h * 0.32));
        final midY = h * 0.54;
        return Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _MinimalPreviewPainter(
                ink: ui.ink,
                accent: ui.accent,
                columns: _photos.length,
                hPadFraction: 0.07,
                midYFraction: 0.54,
              ),
              child: const SizedBox.expand(),
            ),
            for (var i = 0; i < _photos.length; i++)
              Positioned(
                left: hPad + colWidth * (i + 0.5) - tileSize / 2,
                top: midY - tileSize / 2,
                width: tileSize,
                height: tileSize,
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: ui.surface,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: ui.outline, width: 1.5),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        _photos[i],
                        key: ValueKey('deck-photo-minimal-$i'),
                        fit: BoxFit.cover,
                        cacheWidth: 186,
                        excludeFromSemantics: true,
                        errorBuilder: (context, error, stackTrace) =>
                            ColoredBox(color: ui.surface),
                      ),
                      if (ui.isDark)
                        const IgnorePointer(
                          child: ColoredBox(color: Color(0x22000000)),
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

class _MinimalPreviewPainter extends CustomPainter {
  const _MinimalPreviewPainter({
    required this.ink,
    required this.accent,
    this.columns = 4,
    this.hPadFraction = 0.07,
    this.midYFraction = 0.54,
  });

  final Color ink;
  final Color accent;
  final int columns;
  final double hPadFraction;
  final double midYFraction;

  @override
  void paint(Canvas canvas, Size size) {
    final hPad = size.width * hPadFraction;
    final top = size.height * 0.25;
    final bottom = size.height * 0.82;
    final left = hPad;
    final right = size.width - hPad;
    final gridWidth = right - left;
    final colWidth = gridWidth / columns;

    final gridPaint = Paint()
      ..color = ink.withValues(alpha: 0.35)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (var i = 1; i < columns; i++) {
      final x = left + colWidth * i;
      canvas.drawLine(Offset(x, top), Offset(x, bottom), gridPaint);
    }

    final midY = size.height * midYFraction;
    final accentPaint = Paint()
      ..color = accent
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(left, midY), Offset(right, midY), accentPaint);
  }

  @override
  bool shouldRepaint(_MinimalPreviewPainter old) =>
      old.ink != ink ||
      old.accent != accent ||
      old.columns != columns ||
      old.hPadFraction != hPadFraction ||
      old.midYFraction != midYFraction;
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
          border: Border.all(color: ui.outline, width: 2),
        ),
      ),
    };
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ui.outline, width: 1.5),
      ),
      child: child,
    );
  }
}
