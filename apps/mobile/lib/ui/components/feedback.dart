import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens.dart';
import '../typography.dart';
import 'buttons.dart';

/// Empty / error state: sticker icon slot, Space Grotesk h2 title, muted body
/// and an optional pill action. Always tells the person what to do next.
class UiEmptyState extends StatelessWidget {
  const UiEmptyState({
    this.icon,
    this.glyph,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
    super.key,
  }) : assert(icon != null || glyph != null, 'icon or glyph is required');

  final IconData? icon;

  /// A drawn glyph (e.g. `OurneyIcon`) shown instead of [icon]. Lets screens
  /// use the Ourney sticker icon set where a matching icon exists.
  final Widget? glyph;
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
                key: const ValueKey('ui-empty-icon'),
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: ui.fill,
                  shape: BoxShape.circle,
                  border: ui.stickerBorder(),
                  boxShadow: ui.hardShadow(UiShadow.small),
                ),
                child: glyph ?? Icon(icon, size: 30, color: ui.ink),
              ),
              const SizedBox(height: UiSpace.xl),
              Semantics(
                header: true,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: UiText.heading(
                    font: 'Space Grotesk',
                    size: 22,
                    height: 1.3,
                    color: ui.ink,
                  ),
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
                UiButton.secondary(
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

/// `.skeleton-piece` placeholder: 2dp outline at 45% ink, shimmer sweep every
/// 1.35s. Static (no animation) when `MediaQuery.disableAnimations` is on.
class UiSkeleton extends StatefulWidget {
  const UiSkeleton({
    this.width,
    this.height = 16,
    this.radius = UiRadius.input,
    this.circle = false,
    super.key,
  });

  final double? width;
  final double height;
  final double radius;
  final bool circle;

  static const shimmer = Duration(milliseconds: 1350);

  @override
  State<UiSkeleton> createState() => _UiSkeletonState();
}

class _UiSkeletonState extends State<UiSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: UiSkeleton.shimmer,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (still) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final shape = widget.circle ? BoxShape.circle : BoxShape.rectangle;
    final radius = widget.circle ? null : BorderRadius.circular(widget.radius);
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              shape: shape,
              borderRadius: radius,
              border: Border.all(
                color: ui.ink.withValues(alpha: 0.45),
                width: UiBorder.standard,
              ),
              gradient: LinearGradient(
                begin: Alignment(-1.5 + 3 * t, 0),
                end: Alignment(-0.5 + 3 * t, 0),
                colors: [ui.fill, ui.fillSelected, ui.fill],
              ),
            ),
          );
        },
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
          border: Border.all(color: ui.danger, width: UiBorder.standard),
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

/// V2 `.system-toast`: ink pill with paper text, 3dp brand hard shadow,
/// 150ms in/out. [bottomOffset] is the gap above whatever the Scaffold already
/// reserves: a floating SnackBar is lifted above `bottomNavigationBar` by
/// the Scaffold itself, so it must stay small (adding the dock height here
/// double-counted it and covered controls).
void showUiToast(
  BuildContext context,
  String message, {
  double bottomOffset = 36,
}) {
  final ui = context.ui;
  final messenger = ScaffoldMessenger.maybeOf(context);
  final d = UiMotion.of(context, const Duration(milliseconds: 150));
  messenger?.hideCurrentSnackBar();
  messenger?.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      padding: EdgeInsets.zero,
      shape: const StadiumBorder(),
      margin: EdgeInsets.fromLTRB(24, 0, 24, bottomOffset),
      content: Center(
        child: Container(
          key: const ValueKey('ui-toast'),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: ui.ink,
            borderRadius: BorderRadius.circular(UiRadius.capsule),
            boxShadow: UiShadow.hard(ui.brand, UiShadow.small),
          ),
          child: Text(
            message,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: UiText.body(
              size: 13,
              weight: FontWeight.w700,
              height: 1.4,
              color: ui.bg,
            ),
          ),
        ),
      ),
    ),
    snackBarAnimationStyle: AnimationStyle(duration: d, reverseDuration: d),
  );
}
