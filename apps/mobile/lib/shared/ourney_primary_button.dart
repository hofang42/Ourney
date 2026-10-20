import 'package:flutter/material.dart';

import '../app/theme/app_theme.dart' show kBodyFont;
import '../app/theme/motion.dart';
import '../app/theme/persona_theme.dart';
import 'color_utils.dart';
import 'layout.dart';

/// Duration of the press-scale animation (`CLAUDE.md` §2.2).
const Duration ourneyPressDuration = Duration(milliseconds: 110);

/// Scale of a pressed button (`CLAUDE.md` §2.2).
const double ourneyPressScale = 0.96;

/// The primary call-to-action of every persona screen (F5).
///
/// * 52dp high (44dp when [compact]) with a hit area of at least 48dp.
/// * Corners follow `OurneyPersonaTheme.cardRadius`, capped to a capsule.
/// * Presses to 0.96 in 110ms (skipped under reduced motion).
/// * Draws a physical bottom lip (and a tactile border) when the persona
///   sets `bottomLipHeight > 0`.
class OurneyPrimaryButton extends StatefulWidget {
  const OurneyPrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.compact = false,
    this.expand = true,
    this.backgroundColor,
    this.foregroundColor,
    this.semanticLabel,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// 44dp instead of 52dp.
  final bool compact;

  /// Fill the available width instead of hugging the label.
  final bool expand;

  /// Defaults to `OurneyPersonaTheme.primaryAccent`.
  final Color? backgroundColor;

  /// Defaults to white or dark ink, whichever reads better on the fill.
  final Color? foregroundColor;
  final String? semanticLabel;

  @override
  State<OurneyPrimaryButton> createState() => _OurneyPrimaryButtonState();
}

class _OurneyPrimaryButtonState extends State<OurneyPrimaryButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  void _set(bool value) {
    if (_pressed != value && mounted) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final pTheme = OurneyPersonaTheme.of(context);
    final height = widget.compact
        ? OurneyLayout.compactButtonHeight
        : OurneyLayout.primaryButtonHeight;
    final lip = pTheme.bottomLipHeight;
    final base = widget.backgroundColor ?? pTheme.primaryAccent;
    final face = _enabled ? base : base.withValues(alpha: 0.38);
    final fg = _enabled
        ? widget.foregroundColor ?? readableOn(base)
        : pTheme.inkMuted;
    final radius = BorderRadius.circular(
      pTheme.cardRadius < height / 2 ? pTheme.cardRadius : height / 2,
    );

    final label = Text(
      widget.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: kBodyFont,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: fg,
      ),
    );

    final face0 = Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: face,
        borderRadius: radius,
        border: lip > 0
            ? Border.all(color: pTheme.border, width: pTheme.borderWidth)
            : null,
      ),
      child: Row(
        mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, color: fg, size: 22),
            const SizedBox(width: 8),
          ],
          Flexible(child: label),
        ],
      ),
    );

    final visual = lip > 0
        ? DecoratedBox(
            decoration: BoxDecoration(
              color: shiftLightness(base, -0.18),
              borderRadius: radius,
            ),
            child: Padding(
              padding: EdgeInsets.only(bottom: lip),
              child: face0,
            ),
          )
        : face0;

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
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: OurneyLayout.minTouchTarget,
          ),
          child: Center(
            widthFactor: widget.expand ? null : 1,
            child: AnimatedScale(
              scale: _pressed ? ourneyPressScale : 1,
              duration: OurneyMotion.movement(context, ourneyPressDuration),
              curve: Curves.easeOut,
              child: visual,
            ),
          ),
        ),
      ),
    );
  }
}
