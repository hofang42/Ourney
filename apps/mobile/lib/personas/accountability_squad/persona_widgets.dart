import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/motion.dart';
import '../../app/theme/persona_theme.dart';
import 'persona_palette.dart';

/// Top capsule pill reading from [OurneyPersonaTheme] (used in S1, S2, M1, M2).
///
/// Renders a physical bottom lip when `pTheme.bottomLipHeight > 0` (such as
/// `PersonaSkinId.accountabilitySquad`).
class SquadPersonaPill extends StatelessWidget {
  const SquadPersonaPill({
    required this.label,
    this.leading,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.expand = false,
    super.key,
  });

  /// Stretches the pill across the available width (S1 title bar).
  final bool expand;
  final String label;
  final Widget? leading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final pTheme = OurneyPersonaTheme.of(context);
    final bg = backgroundColor ?? pTheme.surface;
    final fg = foregroundColor ?? pTheme.ink;
    final border = borderColor ?? pTheme.border;
    final lip = pTheme.bottomLipHeight;

    return Container(
      constraints: const BoxConstraints(minHeight: 40),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border, width: pTheme.borderWidth),
        boxShadow: lip > 0
            ? [BoxShadow(color: border, offset: Offset(0, lip))]
            : null,
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 8)],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fg,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                height: 1.35,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tilted Polaroid photo frame with optional masking tape strip at the top
/// (used in S1, S3, and M1).
class SquadPolaroidFrame extends StatelessWidget {
  const SquadPolaroidFrame({
    required this.photo,
    required this.caption,
    this.tiltRadians = 0.0,
    this.showMaskingTape = false,
    this.highlighted = false,
    this.photoAspectRatio = 1.0,
    this.chipCaption = false,
    this.tapeShift = 0.0,
    this.footer,
    this.onTap,
    this.semanticLabel,
    super.key,
  });

  final Widget photo;
  final String caption;

  /// Width / height of the photo window (`1` = square).
  final double photoAspectRatio;

  /// Draws [caption] as an outlined chip tucked under the photo (S1 road
  /// stops) instead of printing it on the Polaroid's paper margin.
  final bool chipCaption;

  /// Horizontal placement of the masking tape, `-1` (left edge) to `1`
  /// (right edge); the tape is also rotated against the card's tilt.
  final double tapeShift;

  /// Slight tilt in radians (e.g., `-0.04` or `0.04`).
  final double tiltRadians;

  /// Draws a warm masking-tape strip centered on top of the frame (M1).
  final bool showMaskingTape;

  /// Highlights the caption bar or border with `pTheme.primaryAccent` (e.g.,
  /// today's node in S1).
  final bool highlighted;

  /// Optional extra widget below the caption (e.g., reaction bar in S3).
  final Widget? footer;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final pTheme = OurneyPersonaTheme.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final effectiveTilt = reduceMotion ? 0.0 : tiltRadians;

    final cardBorderColor = highlighted ? pTheme.primaryAccent : pTheme.border;
    // Squad uses a hard ink outline; Memory uses a hairline plus soft paper
    // shadow. Both read from the active skin.
    final heavyOutline = pTheme.borderWidth > 1;

    if (chipCaption) {
      final accentOnInk = PersonaPalette.onAccent(pTheme.primaryAccent);
      Widget stop = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: pTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: pTheme.border,
                width: pTheme.borderWidth,
              ),
              boxShadow: [
                BoxShadow(
                  color: PersonaPalette.cardShadow(
                    Theme.of(context).brightness,
                  ),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(5),
            child: AspectRatio(
              aspectRatio: photoAspectRatio,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: ColoredBox(color: pTheme.surfaceElevated, child: photo),
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: highlighted ? pTheme.primaryAccent : pTheme.surface,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: pTheme.border, width: 1.6),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  caption,
                  maxLines: 1,
                  style: TextStyle(
                    color: highlighted ? accentOnInk : pTheme.ink,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
      if (effectiveTilt != 0.0) {
        stop = Transform.rotate(angle: effectiveTilt, child: stop);
      }
      if (onTap == null) {
        return Semantics(label: semanticLabel ?? caption, child: stop);
      }
      return Semantics(
        button: true,
        label: semanticLabel ?? caption,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            OurneyHaptics.light();
            onTap!();
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: PersonaLayout.minTouchTarget,
              minHeight: PersonaLayout.minTouchTarget,
            ),
            child: stop,
          ),
        ),
      );
    }

    Widget card = Container(
      decoration: BoxDecoration(
        color: pTheme.surface,
        borderRadius: BorderRadius.circular(heavyOutline ? 12 : 4),
        border: Border.all(
          color: cardBorderColor,
          width: highlighted ? 2.5 : pTheme.borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: PersonaPalette.cardShadow(Theme.of(context).brightness),
            blurRadius: heavyOutline ? 8 : 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(6, 6, 6, heavyOutline ? 8 : 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: photoAspectRatio,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(heavyOutline ? 6 : 2),
              child: ColoredBox(color: pTheme.surfaceElevated, child: photo),
            ),
          ),
          SizedBox(height: heavyOutline ? 6 : 8),
          Container(
            padding: highlighted
                ? const EdgeInsets.symmetric(horizontal: 6, vertical: 3)
                : EdgeInsets.zero,
            decoration: highlighted
                ? BoxDecoration(
                    color: pTheme.primaryAccent,
                    borderRadius: BorderRadius.circular(6),
                  )
                : null,
            child: Text(
              caption,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                // Pick the chip's text colour from the accent itself so both the
                // amber (Squad) and terracotta (Memory) chips keep contrast.
                color: highlighted
                    ? PersonaPalette.onAccent(pTheme.primaryAccent)
                    : pTheme.ink,
                fontSize: heavyOutline ? 10.5 : 9.5,
                fontWeight: FontWeight.w800,
                height: 1.35,
                letterSpacing: heavyOutline ? 0.3 : 0.5,
              ),
            ),
          ),
          if (footer != null) ...[const SizedBox(height: 6), footer!],
        ],
      ),
    );

    if (showMaskingTape) {
      final tapeColor = PersonaPalette.maskingTape(
        Theme.of(context).brightness,
      );
      card = Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(padding: const EdgeInsets.only(top: 9), child: card),
          Positioned.fill(
            child: Align(
              alignment: Alignment(tapeShift, -1),
              child: Transform.rotate(
                angle: -effectiveTilt * 1.6 + tapeShift * 0.12,
                child: Container(
                  key: const ValueKey('polaroid-masking-tape'),
                  width: 68,
                  height: 22,
                  decoration: BoxDecoration(
                    color: tapeColor,
                    borderRadius: BorderRadius.circular(1.5),
                    boxShadow: [
                      BoxShadow(
                        color: PersonaPalette.cardShadow(
                          Brightness.light,
                          lightAlpha: 0.10,
                        ),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (effectiveTilt != 0.0) {
      card = Transform.rotate(angle: effectiveTilt, child: card);
    }

    if (onTap == null) {
      return Semantics(label: semanticLabel ?? caption, child: card);
    }

    return Semantics(
      button: true,
      label: semanticLabel ?? caption,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          OurneyHaptics.light();
          onTap!();
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: PersonaLayout.minTouchTarget,
            minHeight: PersonaLayout.minTouchTarget,
          ),
          child: card,
        ),
      ),
    );
  }
}

/// Dashed waiting slot card for members who haven't checked in yet (S3).
class DashedWaitingBox extends StatelessWidget {
  const DashedWaitingBox({
    required this.child,
    this.borderRadius = 16.0,
    super.key,
  });

  final Widget child;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final pTheme = OurneyPersonaTheme.of(context);
    return CustomPaint(
      painter: _DashedRectPainter(
        color: pTheme.inkMuted.withValues(alpha: 0.55),
        radius: BorderRadius.circular(borderRadius),
        strokeWidth: 1.8,
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: pTheme.surface.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: child,
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  const _DashedRectPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
  });

  final Color color;
  final BorderRadius radius;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final rrect = radius.toRRect(Offset.zero & size).deflate(strokeWidth / 2);
    final path = Path()..addRRect(rrect);
    const dash = 6.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRectPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.radius != radius ||
      oldDelegate.strokeWidth != strokeWidth;
}

/// Primary tactile CTA button reading [OurneyPersonaTheme] (`CLAUDE.md` §2.2).
class PersonaPrimaryButton extends StatefulWidget {
  const PersonaPrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  State<PersonaPrimaryButton> createState() => _PersonaPrimaryButtonState();
}

class _PersonaPrimaryButtonState extends State<PersonaPrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final pTheme = OurneyPersonaTheme.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final bg = widget.backgroundColor ?? pTheme.primaryAccent;
    final fg = widget.foregroundColor ?? PersonaPalette.onAccent(bg);
    final lip = pTheme.bottomLipHeight;
    final enabled = widget.onPressed != null;

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTapUp: enabled
            ? (_) {
                setState(() => _pressed = false);
                HapticFeedback.lightImpact();
                widget.onPressed?.call();
              }
            : null,
        child: AnimatedScale(
          scale: (!reduceMotion && _pressed) ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 110),
            transform: Matrix4.translationValues(
              0,
              (_pressed && lip > 0) ? 2.0 : 0.0,
              0,
            ),
            constraints: const BoxConstraints(
              minHeight: PersonaLayout.primaryButtonHeight,
              minWidth: PersonaLayout.minTouchTarget,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: enabled ? bg : bg.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(pTheme.cardRadius),
              border: pTheme.borderWidth > 1
                  ? Border.all(color: pTheme.border, width: pTheme.borderWidth)
                  : null,
              boxShadow: lip > 0 && !_pressed
                  ? [BoxShadow(color: pTheme.border, offset: Offset(0, lip))]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: fg, size: 20),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: fg,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
