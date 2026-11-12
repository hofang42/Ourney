import 'package:flutter/material.dart';

import '../tokens.dart';
import '../typography.dart';
import 'pressable.dart';

/// `.language-chip` / `.inbox-filters button`: bordered capsule, 48dp tall,
/// optional leading glyph. Selected chips invert (ink fill, paper label).
class UiChip extends StatelessWidget {
  const UiChip({
    required this.label,
    required this.onPressed,
    this.icon,
    this.selected = false,
    this.semanticHint,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool selected;
  final String? semanticHint;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final fg = selected ? ui.bg : ui.ink;
    return UiPressable(
      onPressed: onPressed,
      selected: selected,
      semanticLabel: semanticHint == null ? label : '$label, $semanticHint',
      excludeChildSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: UiSize.tap),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? ui.ink : ui.surfaceInput,
          borderRadius: BorderRadius.circular(UiRadius.capsule),
          border: Border.all(color: selected ? ui.ink : ui.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: UiText.body(
                  size: 12,
                  weight: FontWeight.w700,
                  height: 1.4,
                  color: fg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Non-interactive small pill (`.imported-badge`, `.add-more-label`).
class UiTag extends StatelessWidget {
  const UiTag({
    required this.label,
    this.icon,
    this.background,
    this.foreground,
    this.bordered = false,
    super.key,
  });

  final String label;
  final IconData? icon;
  final Color? background;
  final Color? foreground;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final fg = foreground ?? ui.ink;
    return Container(
      constraints: const BoxConstraints(minHeight: 26),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background ?? ui.surface,
        borderRadius: BorderRadius.circular(UiRadius.capsule),
        border: bordered ? Border.all(color: ui.border) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
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

  static IconData iconFor(UiPrivacy type) => switch (type) {
    UiPrivacy.private => Icons.lock_outline_rounded,
    UiPrivacy.link => Icons.link_rounded,
    UiPrivacy.couple => Icons.favorite_border_rounded,
    UiPrivacy.squad => Icons.group_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.ui.inkMuted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(iconFor(type), size: 13, color: c),
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
