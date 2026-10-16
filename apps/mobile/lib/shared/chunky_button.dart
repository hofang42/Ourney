import 'package:flutter/material.dart';

import '../app/theme/motion.dart';
import '../app/theme/tokens.dart';

enum ChunkyVariant { primary, accent, neutral }

/// Duolingo-style pill button: a darker 4pt bottom edge, sinks 3pt on press,
/// light haptic on tap. Primary label is bold 18pt (white on coral is only
/// allowed for bold >= 18pt).
class ChunkyButton extends StatefulWidget {
  const ChunkyButton({
    required this.label,
    required this.onPressed,
    this.variant = ChunkyVariant.primary,
    this.icon,
    this.expand = true,
    this.semanticLabel,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final ChunkyVariant variant;
  final IconData? icon;
  final bool expand;
  final String? semanticLabel;

  @override
  State<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<ChunkyButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  void _set(bool v) {
    if (_pressed != v && mounted) setState(() => _pressed = v);
  }

  Color _darken(Color c, [double amount = 0.14]) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  @override
  Widget build(BuildContext context) {
    final c = OurneyColors.of(context);
    final (face, fg) = switch (widget.variant) {
      ChunkyVariant.primary => (c.primary, c.onPrimary),
      ChunkyVariant.accent => (
        c.accent,
        Theme.of(context).colorScheme.onSecondary,
      ),
      ChunkyVariant.neutral => (c.surface, c.ink),
    };
    final edge = widget.variant == ChunkyVariant.neutral
        ? c.border.withValues(alpha: 0.4)
        : _darken(face);
    final faceColor = _enabled ? face : c.inkMuted.withValues(alpha: 0.25);
    final edgeColor = _enabled ? edge : c.inkMuted.withValues(alpha: 0.35);
    final fgColor = _enabled ? fg : c.inkMuted;
    final sink = _pressed ? OurneySizes.chunkySink : 0.0;
    final dur = OurneyMotion.movement(context, OurneyDurations.tap);

    final label = Text(
      widget.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: kButtonFont,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: fgColor,
      ),
    );

    final content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, color: fgColor, size: 22),
          const SizedBox(width: OurneySpacing.sm),
        ],
        Flexible(child: label),
      ],
    );

    final shape = BorderRadius.circular(OurneyRadii.capsule);
    final border = widget.variant == ChunkyVariant.neutral
        ? Border.all(color: c.border)
        : null;

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.semanticLabel ?? widget.label,
      excludeSemantics: true,
      onTap: widget.onPressed,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _enabled ? (_) => _set(true) : null,
        onTapUp: _enabled ? (_) => _set(false) : null,
        onTapCancel: _enabled ? () => _set(false) : null,
        onTap: _enabled
            ? () {
                OurneyHaptics.light();
                widget.onPressed!();
              }
            : null,
        child: Stack(
          children: [
            Positioned.fill(
              top: OurneySizes.chunkyEdge,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: edgeColor,
                  borderRadius: shape,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: OurneySizes.chunkyEdge),
              child: AnimatedContainer(
                duration: dur,
                curve: OurneyCurves.tap,
                transform: Matrix4.translationValues(0, sink, 0),
                constraints: const BoxConstraints(minHeight: 52),
                padding: const EdgeInsets.symmetric(
                  horizontal: OurneySpacing.xl,
                  vertical: OurneySpacing.md,
                ),
                decoration: BoxDecoration(
                  color: faceColor,
                  borderRadius: shape,
                  border: border,
                ),
                child: content,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const String kButtonFont = 'BeVietnamPro';
