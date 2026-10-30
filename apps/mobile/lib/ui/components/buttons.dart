import 'package:flutter/material.dart';

import '../tokens.dart';
import '../typography.dart';
import 'pressable.dart';

enum UiButtonVariant {
  /// `.brand-primary` / `.primary-wide`: coral fill, ink label.
  primary,

  /// `.secondary-wide`: surface fill, hairline border.
  secondary,

  /// Text only (`.text-action`, `.auth-link`).
  ghost,
}

/// Wide capsule button: 52dp (44dp when [compact]), 48dp minimum hit target,
/// 0.96 press scale. `.brand-primary`, `.secondary-wide`, `.text-action`.
class UiButton extends StatelessWidget {
  const UiButton({
    required this.label,
    required this.onPressed,
    this.variant = UiButtonVariant.primary,
    this.icon,
    this.compact = false,
    this.expand = true,
    this.loading = false,
    this.accent,
    this.onAccent,
    super.key,
  });

  const UiButton.secondary({
    required this.label,
    required this.onPressed,
    this.icon,
    this.compact = false,
    this.expand = true,
    this.loading = false,
    super.key,
  }) : variant = UiButtonVariant.secondary,
       accent = null,
       onAccent = null;

  const UiButton.ghost({
    required this.label,
    required this.onPressed,
    this.icon,
    this.compact = false,
    this.expand = true,
    this.loading = false,
    super.key,
  }) : variant = UiButtonVariant.ghost,
       accent = null,
       onAccent = null;

  final String label;
  final VoidCallback? onPressed;
  final UiButtonVariant variant;
  final IconData? icon;
  final bool compact;
  final bool expand;
  final bool loading;

  /// Journey-style override for the primary fill (`--setup-accent`).
  final Color? accent;
  final Color? onAccent;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final enabled = onPressed != null && !loading;
    final height = compact ? UiSize.buttonCompact : UiSize.button;

    Color bg;
    Color fg;
    BorderSide? side;
    switch (variant) {
      case UiButtonVariant.primary:
        bg = enabled ? (accent ?? ui.brand) : ui.fill;
        fg = enabled ? (onAccent ?? ui.onBrand) : ui.inkMuted;
      case UiButtonVariant.secondary:
        bg = ui.surface;
        fg = enabled ? ui.ink : ui.inkMuted;
        side = BorderSide(color: ui.border);
      case UiButtonVariant.ghost:
        bg = Colors.transparent;
        fg = enabled ? ui.inkSoft : ui.inkMuted;
    }

    final text = Text(
      label,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: UiText.button(color: fg),
    );
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        else if (icon != null)
          Icon(icon, size: 18, color: fg),
        if (loading || icon != null) const SizedBox(width: UiSpace.sm),
        Flexible(child: text),
      ],
    );

    return UiPressable(
      onPressed: enabled ? onPressed : null,
      semanticLabel: label,
      excludeChildSemantics: true,
      minSize: Size(UiSize.tap, height < UiSize.tap ? UiSize.tap : height),
      centerChild: compact,
      child: Container(
        width: expand ? double.infinity : null,
        constraints: BoxConstraints(minHeight: height),
        padding: const EdgeInsets.symmetric(
          horizontal: UiSpace.xxl,
          vertical: UiSpace.sm,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(UiRadius.capsule),
          border: side == null ? null : Border.fromBorderSide(side),
        ),
        child: content,
      ),
    );
  }
}

/// `.icon-button`: 48x48 circle target, 21dp glyph, stroke 1.8.
class UiIconButton extends StatelessWidget {
  const UiIconButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
    this.background,
    this.size = UiSize.tap,
    this.iconSize = 21,
    super.key,
  });

  final IconData icon;

  /// Required: icon-only controls must be announced.
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? background;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return UiPressable(
      onPressed: onPressed,
      semanticLabel: label,
      excludeChildSemantics: true,
      minSize: Size.square(size < UiSize.tap ? UiSize.tap : size),
      child: Container(
        width: size < UiSize.tap ? UiSize.tap : size,
        height: size < UiSize.tap ? UiSize.tap : size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: Icon(
          icon,
          size: iconSize,
          color: onPressed == null ? ui.inkMuted : (color ?? ui.ink),
        ),
      ),
    );
  }
}

/// `.text-action`: bold text link on the paper, 48dp tall.
class UiTextAction extends StatelessWidget {
  const UiTextAction({
    required this.label,
    required this.onPressed,
    this.underline = false,
    this.color,
    this.size = 15,
    this.alignment = Alignment.center,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool underline;
  final Color? color;
  final double size;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final base = color ?? ui.inkSoft;
    return UiPressable(
      onPressed: onPressed,
      semanticLabel: label,
      excludeChildSemantics: true,
      child: Container(
        alignment: alignment,
        padding: const EdgeInsets.symmetric(horizontal: UiSpace.sm),
        constraints: const BoxConstraints(minHeight: UiSize.tap),
        child: Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: UiText.body(
            size: size,
            weight: FontWeight.w700,
            height: 1.35,
            color: onPressed == null ? ui.inkMuted : base,
          ).copyWith(decoration: underline ? TextDecoration.underline : null),
        ),
      ),
    );
  }
}
