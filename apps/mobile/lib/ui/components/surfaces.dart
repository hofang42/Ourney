import 'package:flutter/material.dart';

import '../tokens.dart';
import '../typography.dart';
import 'pressable.dart';

/// `.eyebrow`: 12px bold, 0.12em tracking, muted.
class UiEyebrow extends StatelessWidget {
  const UiEyebrow(this.text, {this.color, this.textAlign, super.key});

  final String text;
  final Color? color;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: textAlign,
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    style: UiText.eyebrow(color: color ?? context.ui.inkMuted),
  );
}

/// Hairline between rows (`border-bottom: 1px solid #e6e6e0`).
class UiDivider extends StatelessWidget {
  const UiDivider({super.key});

  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: context.ui.divider);
}

/// Bordered surface (`.shared-compact-list > button`, `.hub-all-done`,
/// `.template-choice`, `.mini-calendar`). Square-cornered by default like the
/// journey/today cards; pass [radius] for the rounded variants (16 / 20).
class UiCard extends StatelessWidget {
  const UiCard({
    required this.child,
    this.padding = const EdgeInsets.all(UiSpace.lg),
    this.radius = 0,
    this.color,
    this.borderColor,
    this.onPressed,
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onPressed;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? ui.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? ui.border),
      ),
      child: child,
    );
    if (onPressed == null) return box;
    return UiPressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      borderRadius: BorderRadius.circular(radius),
      child: box,
    );
  }
}

/// `.journey-row`: leading thumb, two lines of copy, chevron, hairline below.
class UiRow extends StatelessWidget {
  const UiRow({
    required this.title,
    this.leading,
    this.subtitle,
    this.meta,
    this.trailing,
    this.onPressed,
    this.showChevron = true,
    this.minHeight = 64,
    this.divider = true,
    super.key,
  });

  final String title;
  final Widget? leading;
  final Widget? subtitle;
  final Widget? meta;
  final Widget? trailing;
  final VoidCallback? onPressed;
  final bool showChevron;
  final double minHeight;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final row = Container(
      constraints: BoxConstraints(minHeight: minHeight),
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: divider ? Border(bottom: BorderSide(color: ui.divider)) : null,
      ),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 12)],
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.body(
                    size: 15,
                    weight: FontWeight.w700,
                    height: 1.35,
                    color: ui.ink,
                  ),
                ),
                if (subtitle != null) ...[const SizedBox(height: 3), subtitle!],
                if (meta != null) ...[const SizedBox(height: 3), meta!],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          if (onPressed != null && showChevron) ...[
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, size: 20, color: ui.chevron),
          ],
        ],
      ),
    );
    if (onPressed == null) return row;
    return UiPressable(
      onPressed: onPressed,
      semanticLabel: title,
      borderRadius: BorderRadius.zero,
      minSize: const Size(UiSize.tap, 64),
      child: row,
    );
  }
}

/// `.list-heading` / `.section-title`: h2 + trailing quiet action.
class UiListHeading extends StatelessWidget {
  const UiListHeading({
    required this.title,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: UiText.h2(size: 18, color: ui.ink),
            ),
          ),
        ),
        if (actionLabel != null)
          UiPressable(
            onPressed: onAction,
            semanticLabel: actionLabel,
            excludeChildSemantics: true,
            child: Container(
              alignment: Alignment.center,
              constraints: const BoxConstraints(minHeight: UiSize.tap),
              padding: const EdgeInsets.only(left: UiSpace.sm),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionLabel!,
                    style: UiText.body(
                      size: 14,
                      weight: FontWeight.w600,
                      color: ui.inkMuted,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: ui.inkMuted,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// `.hub-add-menu` / `.overflow-menu`: floating action list.
class UiMenuSurface extends StatelessWidget {
  const UiMenuSurface({required this.children, this.width = 238, super.key});

  final List<Widget> children;
  final double width;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return Container(
      width: width,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: ui.surface,
        borderRadius: BorderRadius.circular(UiRadius.menu),
        border: Border.all(color: ui.border),
        boxShadow: [
          BoxShadow(
            color: ui.shadow,
            blurRadius: 34,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

/// One entry of a [UiMenuSurface].
class UiMenuItem extends StatelessWidget {
  const UiMenuItem({
    required this.label,
    required this.onPressed,
    this.icon,
    this.destructive = false,
    super.key,
  });

  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final color = destructive ? ui.danger : ui.ink;
    return UiPressable(
      onPressed: onPressed,
      semanticLabel: label,
      excludeChildSemantics: true,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        constraints: const BoxConstraints(minHeight: UiSize.tap),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 17, color: color),
              const SizedBox(width: 9),
            ],
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: UiText.body(
                  size: 13,
                  weight: FontWeight.w700,
                  height: 1.35,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
