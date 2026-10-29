import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens.dart';
import '../typography.dart';
import 'buttons.dart';

/// Empty / error state: round glyph, h2 title, muted body and an optional
/// action. Always tells the person what to do next.
class UiEmptyState extends StatelessWidget {
  const UiEmptyState({
    required this.icon,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 310),
        child: Padding(
          padding: const EdgeInsets.all(UiSpace.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: ui.fill,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 30, color: ui.ink),
              ),
              const SizedBox(height: UiSpace.lg),
              Semantics(
                header: true,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: UiText.h2(color: ui.ink),
                ),
              ),
              if (body != null) ...[
                const SizedBox(height: 6),
                Text(
                  body!,
                  textAlign: TextAlign.center,
                  style: UiText.muted(color: ui.inkMuted, size: 14),
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: UiSpace.xxl),
                UiButton(
                  label: actionLabel!,
                  onPressed: onAction,
                  expand: false,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// `.progress-track`: 5dp bar. [value] is 0..1.
class UiProgressBar extends StatelessWidget {
  const UiProgressBar({
    required this.value,
    this.color,
    this.semanticLabel,
    super.key,
  });

  final double value;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return Semantics(
      label: semanticLabel,
      value: '${(value.clamp(0, 1) * 100).round()}%',
      child: Container(
        height: 5,
        color: ui.divider,
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: value.clamp(0, 1).toDouble(),
          child: Container(color: color ?? ui.brand),
        ),
      ),
    );
  }
}

/// `.progress-ring`: 64dp ring (5dp stroke) with a count and caption.
class UiProgressRing extends StatelessWidget {
  const UiProgressRing({
    required this.value,
    required this.label,
    this.caption,
    this.color,
    this.size = 64,
    super.key,
  });

  final double value;
  final String label;
  final String? caption;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return Semantics(
      label: caption == null ? label : '$label $caption',
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingPainter(
            value: value.clamp(0, 1).toDouble(),
            track: ui.divider,
            color: color ?? ui.brand,
          ),
          child: Center(
            child: ExcludeSemantics(
              child: Text(
                label,
                style: UiText.display(
                  size: 18,
                  weight: 800,
                  height: 1.3,
                  color: ui.ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.value, required this.track, required this.color});

  final double value;
  final Color track;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 5.0;
    final rect = Offset.zero & size;
    final arc = rect.deflate(stroke / 2);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(arc, 0, math.pi * 2, false, p..color = track);
    canvas.drawArc(
      arc,
      -math.pi / 2,
      math.pi * 2 * value,
      false,
      p..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.track != track || old.color != color;
}

/// `.all-done-illustration` / `.hub-all-done > span`: green check badge.
class UiCheckBadge extends StatelessWidget {
  const UiCheckBadge({this.size = 34, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: ui.successSoft, shape: BoxShape.circle),
      child: Icon(Icons.check_rounded, size: size * 0.52, color: ui.success),
    );
  }
}

/// Inline error / warning line with an icon, announced politely.
class UiInlineError extends StatelessWidget {
  const UiInlineError({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(UiSpace.md),
        decoration: BoxDecoration(
          color: ui.isDark
              ? ui.danger.withValues(alpha: 0.14)
              : const Color(0xFFFEF3F2),
          borderRadius: BorderRadius.circular(UiRadius.input),
          border: Border.all(color: ui.danger.withValues(alpha: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded, size: 18, color: ui.danger),
            const SizedBox(width: UiSpace.sm),
            Expanded(
              child: Text(
                message,
                style: UiText.body(size: 13, height: 1.45, color: ui.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `.toast`: ink pill with paper text. Fixed behavior so it never covers the
/// primary action.
void showUiToast(BuildContext context, String message) {
  final ui = context.ui;
  final messenger = ScaffoldMessenger.maybeOf(context);
  messenger?.hideCurrentSnackBar();
  messenger?.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: ui.ink,
      shape: const StadiumBorder(),
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 36),
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: UiText.body(
          size: 13,
          weight: FontWeight.w700,
          height: 1.4,
          color: ui.bg,
        ),
      ),
    ),
  );
}
