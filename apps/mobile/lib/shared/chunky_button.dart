import 'package:flutter/material.dart';

import '../app/theme/motion.dart';
import '../app/theme/tokens.dart';
import 'color_utils.dart';
import 'ourney_primary_button.dart' show ourneyPressDuration, ourneyPressScale;

enum ChunkyVariant { primary, accent, neutral }

/// Wide capsule action button (V1.0 `.brand-primary` / `.secondary-wide`).
///
/// * [ChunkyVariant.primary]: brand coral fill with ink label (5.41:1).
/// * [ChunkyVariant.accent]: secondary accent fill, readable label.
/// * [ChunkyVariant.neutral]: surface fill with a hairline border.
///
/// 52dp high, 15pt bold label, presses to 0.96 in 110ms (skipped under
/// reduced motion), light haptic on tap. Disabled: sunken fill, muted ink.
/// The name is historical (the pre-V1.0 button had a chunky bottom edge).
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

  @override
  Widget build(BuildContext context) {
    final c = OurneyColors.of(context);
    final (face, fg) = switch (widget.variant) {
      ChunkyVariant.primary => (c.primary, c.onPrimary),
      ChunkyVariant.accent => (c.accent, readableOn(c.accent)),
      ChunkyVariant.neutral => (c.surface, c.ink),
    };
    final faceColor = _enabled ? face : c.surfaceSunken;
    final fgColor = _enabled ? fg : c.inkMuted;

    final content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, color: fgColor, size: 18),
          const SizedBox(width: OurneySpacing.sm),
        ],
        Flexible(
          child: Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: kButtonFont,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.3,
              color: fgColor,
            ),
          ),
        ),
      ],
    );

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
        child: AnimatedScale(
          scale: _pressed ? ourneyPressScale : 1,
          duration: OurneyMotion.movement(context, ourneyPressDuration),
          curve: OurneyCurves.tap,
          child: Container(
            constraints: const BoxConstraints(minHeight: OurneySizes.button),
            padding: const EdgeInsets.symmetric(
              horizontal: OurneySpacing.xl,
              vertical: OurneySpacing.md,
            ),
            decoration: BoxDecoration(
              color: faceColor,
              borderRadius: BorderRadius.circular(OurneyRadii.capsule),
              border: widget.variant == ChunkyVariant.neutral && _enabled
                  ? Border.all(color: c.border)
                  : null,
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}

const String kButtonFont = 'BeVietnamPro';
