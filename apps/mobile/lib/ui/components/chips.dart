import 'package:flutter/material.dart';

import '../tokens.dart';
import '../typography.dart';
import 'ourney_icons.dart';
import 'pressable.dart';

/// `.create-extra-chip` / `.language-chip`: sticker capsule. 44dp visual
/// inside a 48dp hit area, 1.5dp outline, surface fill, 3dp hard shadow.
/// Selected chips fill with `accent` and an `onAccent` label.
class UiChip extends StatelessWidget {
  const UiChip({
    required this.label,
    required this.onPressed,
    @Deprecated('Use glyph: OurneyIcon(...)') this.icon,
    this.glyph,
    this.trailing,
    this.selected = false,
    this.fillWhenSelected = true,
    this.compact = false,
    this.semanticHint,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// A drawn glyph (e.g. `OurneyIcon`) shown instead of [icon]. Lets screens
  /// use the Ourney sticker icon set where a matching icon exists.
  final Widget? glyph;

  /// Optional trailing glyph rendered after [label] (e.g. a selection check on
  /// a surface-filled colour-swatch chip).
  final Widget? trailing;
  final bool selected;

  /// Whether [selected] fills the pill with `ui.accent` (default `true`).
  /// Set to `false` for colour-swatch chips so the swatch dot keeps its figure-
  /// ground contrast against `ui.surface`.
  final bool fillWhenSelected;

  /// Smaller visual for photo labels; interactive chips keep a 48dp target.
  final bool compact;
  final String? semanticHint;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final accentFill = selected && fillWhenSelected;
    final fg = accentFill ? ui.onAccent : ui.ink;
    return UiPressable(
      onPressed: onPressed,
      selected: selected,
      semanticLabel: semanticHint == null ? label : '$label, $semanticHint',
      excludeChildSemantics: true,
      centerChild: true,
      shadowOffset: compact ? 0 : UiShadow.small,
      borderRadius: BorderRadius.circular(UiRadius.capsule),
      child: Container(
        constraints: BoxConstraints(minHeight: compact ? 26 : 44),
        padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 14, vertical: compact ? 3 : 6),
        decoration: BoxDecoration(
          color: accentFill ? ui.accent : ui.surface,
          borderRadius: BorderRadius.circular(UiRadius.capsule),
          border: ui.stickerBorder(
            selected && !fillWhenSelected ? UiBorder.standard : UiBorder.thin,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null || glyph != null) ...[
              glyph ?? Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: UiText.body(
                  size: compact ? 11 : 13,
                  weight: FontWeight.w700,
                  height: 1.4,
                  color: fg,
                ),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 6),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Non-interactive small pill (`.imported-badge`, `.add-more-label`) with the
/// 1.5dp sticker outline. No shadow: it is not selectable.
class UiTag extends StatelessWidget {
  const UiTag({
    required this.label,
    @Deprecated('Use glyph: OurneyIcon(...)') this.icon,
    this.glyph,
    this.background,
    this.foreground,
    this.bordered = true,
    this.borderColor,
    super.key,
  });

  final String label;
  final IconData? icon;

  /// A drawn glyph (e.g. `OurneyIcon`) shown instead of [icon]. Lets screens
  /// use the Ourney sticker icon set where a matching icon exists.
  final Widget? glyph;
  final Color? background;
  final Color? foreground;
  final bool bordered;

  /// Outline color; defaults to ink. Pass `UiCamera.outline` for tags drawn
  /// over the dark camera preview.
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final fg = foreground ?? ui.ink;
    return Container(
      constraints: const BoxConstraints(minHeight: 26),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: background ?? ui.surface,
        borderRadius: BorderRadius.circular(UiRadius.capsule),
        border: bordered
            ? Border.all(color: borderColor ?? ui.outline, width: UiBorder.thin)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null || glyph != null) ...[
            glyph ?? Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: UiText.body(
                size: 10,
                weight: FontWeight.w800,
                height: 1.4,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum UiPrivacy { private, link, couple, squad }

/// `Privacy` component: lock / link / heart / users glyph + label, 11px.
class UiPrivacyTag extends StatelessWidget {
  const UiPrivacyTag({
    required this.type,
    required this.label,
    this.color,
    super.key,
  });

  final UiPrivacy type;
  final String label;
  final Color? color;

  /// [OurneyIcon] name of a privacy level.
  static String glyphFor(UiPrivacy type) => switch (type) {
    UiPrivacy.private => 'lock',
    UiPrivacy.link => 'link',
    UiPrivacy.couple => 'heart',
    UiPrivacy.squad => 'squad',
  };

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.ui.inkMuted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OurneyIcon(name: glyphFor(type), size: 13, flat: true, color: c),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: UiText.body(size: 11, weight: FontWeight.w500, color: c),
          ),
        ),
      ],
    );
  }
}

/// `.style-label`: colored dot + journey style name.
class UiStyleLabel extends StatelessWidget {
  const UiStyleLabel({required this.label, required this.dot, super.key});

  final String label;
  final Color dot;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Flexible(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: UiText.body(size: 11, color: context.ui.inkMuted),
        ),
      ),
    ],
  );
}

/// `.new-dot`: 7dp unread marker.
class UiNewDot extends StatelessWidget {
  const UiNewDot({this.size = 7, super.key});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: context.ui.danger, shape: BoxShape.circle),
  );
}
