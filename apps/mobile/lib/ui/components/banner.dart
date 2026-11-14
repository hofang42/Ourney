import 'package:flutter/material.dart';

import '../tokens.dart';
import '../typography.dart';
import 'buttons.dart';

enum UiBannerKind { offline, readOnly, archived }

/// V2 status banner (`.flow-offline`, read-only and archived notices):
/// 2dp outline, surface fill, drawn leading glyph, status semantics and an
/// optional "Thử lại" action with a 48dp target.
class UiBanner extends StatelessWidget {
  const UiBanner({
    required this.message,
    this.kind = UiBannerKind.offline,
    this.onRetry,
    this.retryLabel = 'Thử lại',
    super.key,
  });

  final String message;
  final UiBannerKind kind;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return Semantics(
      container: true,
      liveRegion: true,
      label: message,
      child: Container(
        constraints: const BoxConstraints(minHeight: UiSize.tap),
        padding: const EdgeInsets.fromLTRB(UiSpace.md, 6, UiSpace.sm, 6),
        decoration: BoxDecoration(
          color: ui.surface,
          borderRadius: BorderRadius.circular(UiRadius.input),
          border: ui.stickerBorder(),
        ),
        child: Row(
          children: [
            ExcludeSemantics(
              child: SizedBox.square(
                dimension: 22,
                child: CustomPaint(
                  painter: _GlyphPainter(kind: kind, color: ui.ink),
                ),
              ),
            ),
            const SizedBox(width: UiSpace.md),
            Expanded(
              child: ExcludeSemantics(
                child: Text(
                  message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.body(
                    size: 13,
                    weight: FontWeight.w600,
                    height: 1.4,
                    color: ui.ink,
                  ),
                ),
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(width: UiSpace.xs),
              UiButton.ghost(
                label: retryLabel,
                onPressed: onRetry,
                compact: true,
                expand: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter({required this.kind, required this.color});

  final UiBannerKind kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 22);
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    switch (kind) {
      case UiBannerKind.offline:
        final cloud = Path()
          ..moveTo(6.5, 16.5)
          ..cubicTo(3.5, 16.5, 3, 12, 6.2, 11.4)
          ..cubicTo(6.6, 8, 11.8, 6.6, 13.6, 9.8)
          ..cubicTo(17.6, 9.4, 19.4, 14.6, 15.6, 16.5)
          ..close();
        canvas.drawPath(cloud, p);
        canvas.drawLine(const Offset(3.5, 3.5), const Offset(18.5, 18.5), p);
      case UiBannerKind.readOnly:
        canvas.drawRRect(
          RRect.fromLTRBR(4.5, 10, 17.5, 19, const Radius.circular(2.5)),
          p,
        );
        final shackle = Path()
          ..moveTo(7.5, 10)
          ..lineTo(7.5, 7.5)
          ..arcToPoint(
            const Offset(14.5, 7.5),
            radius: const Radius.circular(3.5),
          )
          ..lineTo(14.5, 10);
        canvas.drawPath(shackle, p);
      case UiBannerKind.archived:
        canvas.drawRRect(
          RRect.fromLTRBR(3, 4, 19, 8.5, const Radius.circular(1.5)),
          p,
        );
        final box = Path()
          ..moveTo(4.5, 8.5)
          ..lineTo(4.5, 17)
          ..quadraticBezierTo(4.5, 18.5, 6, 18.5)
          ..lineTo(16, 18.5)
          ..quadraticBezierTo(17.5, 18.5, 17.5, 17)
          ..lineTo(17.5, 8.5);
        canvas.drawPath(box, p);
        canvas.drawLine(const Offset(9, 12.5), const Offset(13, 12.5), p);
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.kind != kind || old.color != color;
}
