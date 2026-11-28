import 'dart:math' as math;
import 'dart:ui' show ClipOp;

import 'package:flutter/material.dart';

import '../../../../ui/ui.dart';

/// Which edge of a ticket piece is a perforation seam (torn edge).
enum TicketSeam { none, top, bottom, left, right }

/// A ticket made of a main piece and an optional stub (or, for couple halves,
/// one piece with a torn edge). The seam carries a dashed line and two notches.
class TicketPaper extends StatelessWidget {
  const TicketPaper({
    required this.radius,
    required this.seam,
    required this.top,
    this.stub,
    this.paper,
    this.borderColor,
    this.shadowColor,
    this.borderWidth,
    this.shadow = 4,
    this.grid = false,
    this.topBar,
    super.key,
  });

  final double radius;
  final TicketSeam seam;
  final Widget top;
  final Widget? stub;
  final Color? paper;
  final Color? borderColor;
  final Color? shadowColor;
  final double? borderWidth;
  final double shadow;
  final bool grid;
  final Color? topBar;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final fill = paper ?? ui.surface;
    final bw =
        borderWidth ??
        UiSkinScope.maybeOf(context)?.skin.borderWidth ??
        UiBorder.standard;
    Widget piece(Widget child, TicketSeam edge, {required bool first}) {
      return CustomPaint(
        painter: _PiecePainter(
          fill: fill,
          border: borderColor ?? ui.outline,
          shadowColor: shadowColor ?? ui.hardShadowColor,
          borderWidth: bw,
          shadow: shadow,
          radius: radius,
          seam: edge,
          dash: ui.ink.withValues(alpha: 0.6),
          grid: grid ? ui.ink.withValues(alpha: 0.10) : null,
          topBar: first ? topBar : null,
        ),
        child: Padding(padding: EdgeInsets.all(bw), child: child),
      );
    }

    final main = piece(top, seam, first: true);
    if (stub == null) return main;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        main,
        piece(
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
            child: stub,
          ),
          TicketSeam.top,
          first: false,
        ),
      ],
    );
  }
}

class _PiecePainter extends CustomPainter {
  _PiecePainter({
    required this.fill,
    required this.border,
    required this.shadowColor,
    required this.borderWidth,
    required this.shadow,
    required this.radius,
    required this.seam,
    required this.dash,
    this.grid,
    this.topBar,
  });

  final Color fill;
  final Color border;
  final Color shadowColor;
  final double borderWidth;
  final double shadow;
  final double radius;
  final TicketSeam seam;
  final Color dash;
  final Color? grid;
  final Color? topBar;

  static const double _notch = 9;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final round = Radius.circular(radius);
    final rrect = RRect.fromRectAndCorners(
      Offset.zero & size,
      topLeft: seam == TicketSeam.top || seam == TicketSeam.left
          ? Radius.zero
          : round,
      topRight: seam == TicketSeam.top || seam == TicketSeam.right
          ? Radius.zero
          : round,
      bottomLeft: seam == TicketSeam.bottom || seam == TicketSeam.left
          ? Radius.zero
          : round,
      bottomRight: seam == TicketSeam.bottom || seam == TicketSeam.right
          ? Radius.zero
          : round,
    );
    // Notch centres sit at the two ends of the seam edge.
    final notches = switch (seam) {
      TicketSeam.none => const <Offset>[],
      TicketSeam.top => [Offset.zero, Offset(w, 0)],
      TicketSeam.bottom => [Offset(0, h), Offset(w, h)],
      TicketSeam.left => [Offset.zero, Offset(0, h)],
      TicketSeam.right => [Offset(w, 0), Offset(w, h)],
    };
    var shape = Path()..addRRect(rrect);
    for (final c in notches) {
      shape = Path.combine(
        PathOperation.difference,
        shape,
        Path()..addOval(Rect.fromCircle(center: c, radius: _notch)),
      );
    }
    canvas.drawPath(
      shape.shift(Offset(shadow, shadow)),
      Paint()..color = shadowColor,
    );
    canvas.drawPath(shape, Paint()..color = fill);

    canvas.save();
    canvas.clipPath(shape);
    if (grid != null) {
      final p = Paint()
        ..color = grid!
        ..strokeWidth = 1;
      for (var x = 20.0; x < w; x += 20) {
        canvas.drawLine(Offset(x, 0), Offset(x, h), p);
      }
      for (var y = 20.0; y < h; y += 20) {
        canvas.drawLine(Offset(0, y), Offset(w, y), p);
      }
    }
    if (topBar != null) {
      canvas.drawRect(Rect.fromLTWH(0, 0, w, 6), Paint()..color = topBar!);
    }
    // Outline (inner half of a doubled stroke), minus the straight seam
    // segment between the notches.
    final bw = borderWidth;
    final gap = switch (seam) {
      TicketSeam.top => Rect.fromLTRB(_notch, -bw, w - _notch, bw),
      TicketSeam.bottom => Rect.fromLTRB(_notch, h - bw, w - _notch, h + bw),
      TicketSeam.left => Rect.fromLTRB(-bw, _notch, bw, h - _notch),
      TicketSeam.right => Rect.fromLTRB(w - bw, _notch, w + bw, h - _notch),
      TicketSeam.none => null,
    };
    if (gap != null) canvas.clipRect(gap, clipOp: ClipOp.difference);
    canvas.drawPath(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = bw * 2
        ..color = border,
    );
    canvas.restore();

    // Dashed perforation along the seam.
    if (seam != TicketSeam.none) {
      final horizontal = seam == TicketSeam.top || seam == TicketSeam.bottom;
      final line = Paint()
        ..color = dash
        ..strokeWidth = 2;
      final len = horizontal ? w : h;
      final end = len - _notch - 6;
      for (var d = _notch + 6; d < end; d += 10) {
        final e = math.min(d + 5, end);
        final a = switch (seam) {
          TicketSeam.top => Offset(d, 1),
          TicketSeam.bottom => Offset(d, h - 1),
          TicketSeam.left => Offset(1, d),
          _ => Offset(w - 1, d),
        };
        canvas.drawLine(
          a,
          horizontal ? Offset(e, a.dy) : Offset(a.dx, e),
          line,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PiecePainter old) =>
      old.fill != fill ||
      old.border != border ||
      old.shadowColor != shadowColor ||
      old.borderWidth != borderWidth ||
      old.shadow != shadow ||
      old.radius != radius ||
      old.seam != seam ||
      old.dash != dash ||
      old.grid != grid ||
      old.topBar != topBar;
}
