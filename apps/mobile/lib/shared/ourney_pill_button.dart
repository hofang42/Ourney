import 'package:flutter/material.dart';

import '../app/theme/motion.dart';
import '../app/theme/persona_theme.dart';
import 'color_utils.dart';
import 'layout.dart';
import 'ourney_primary_button.dart';

/// Capsule icon button (F5). The dock's quick-snap pill is 56x40; the touch
/// area is always at least 48dp high.
class OurneyPillButton extends StatefulWidget {
  const OurneyPillButton({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.width = 56,
    this.height = 40,
    this.backgroundColor,
    this.foregroundColor,
    this.selected = false,
    super.key,
  });

  final IconData icon;

  /// Spoken label: the pill has no visible text.
  final String semanticLabel;
  final VoidCallback? onPressed;
  final double width;
  final double height;

  /// Defaults to `OurneyPersonaTheme.primaryAccent`.
  final Color? backgroundColor;
  final Color? foregroundColor;

  /// Draws a ring so the selected state is not shown by color alone.
  final bool selected;

  @override
  State<OurneyPillButton> createState() => _OurneyPillButtonState();
}

class _OurneyPillButtonState extends State<OurneyPillButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  void _set(bool value) {
    if (_pressed != value && mounted) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final pTheme = OurneyPersonaTheme.of(context);
    final base = widget.backgroundColor ?? pTheme.primaryAccent;
    final fg = widget.foregroundColor ?? readableOn(base);
    final ring = widget.selected ? pTheme.ink : Colors.transparent;

    return Semantics(
      button: true,
      selected: widget.selected,
      enabled: _enabled,
      label: widget.semanticLabel,
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
        child: SizedBox(
          width: widget.width < OurneyLayout.minTouchTarget
              ? OurneyLayout.minTouchTarget
              : widget.width,
          height: widget.height < OurneyLayout.minTouchTarget
              ? OurneyLayout.minTouchTarget
              : widget.height,
          child: Center(
            child: AnimatedScale(
              scale: _pressed ? ourneyPressScale : 1,
              duration: OurneyMotion.movement(context, ourneyPressDuration),
              curve: Curves.easeOut,
              child: Container(
                key: const ValueKey('ourney-pill-button-face'),
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  color: _enabled ? base : base.withValues(alpha: 0.38),
                  borderRadius: BorderRadius.circular(widget.height / 2),
                  border: Border.all(color: ring, width: 2),
                ),
                child: Icon(widget.icon, color: fg, size: 22),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
