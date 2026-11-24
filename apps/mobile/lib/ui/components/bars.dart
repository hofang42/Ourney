import 'dart:ui' as ui_;

import 'package:flutter/material.dart';

import '../tokens.dart';
import '../typography.dart';
import 'ourney_icons.dart';
import 'pressable.dart';

/// `.screen-header > button`: 44dp circular icon button, 1.5dp ink outline,
/// surface fill, inside a 48dp hit area. Use it in [UiTopBar.actions] /
/// [UiTopBar.leading] so every header control matches.
class UiBarIconButton extends StatelessWidget {
  const UiBarIconButton({
    @Deprecated('Use glyph: OurneyIcon(...)') this.icon,
    this.glyph,
    required this.label,
    required this.onPressed,
    this.iconSize = 21,
    super.key,
  }) : assert(icon != null || glyph != null, 'icon or glyph is required');

  final IconData? icon;

  /// A drawn glyph (e.g. `OurneyIcon`) shown instead of [icon]. Lets screens
  /// use the Ourney sticker icon set where a matching icon exists.
  final Widget? glyph;

  /// Required: icon-only controls must be announced.
  final String label;
  final VoidCallback? onPressed;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return UiPressable(
      onPressed: onPressed,
      semanticLabel: label,
      excludeChildSemantics: true,
      centerChild: true,
      borderRadius: BorderRadius.circular(UiRadius.capsule),
      child: Container(
        key: const ValueKey('ui-bar-icon-button'),
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: ui.surface,
          shape: BoxShape.circle,
          border: ui.stickerBorder(UiBorder.thin),
        ),
        child:
            glyph ??
            Icon(
              icon,
              size: iconSize,
              color: onPressed == null ? ui.inkMuted : ui.ink,
            ),
      ),
    );
  }
}

/// Header chrome: 1dp bottom border at 12% ink, optional frosted fill for a
/// header that content scrolls under (`.screen-header`, bg at 92%).
class _BarFrame extends StatelessWidget {
  const _BarFrame({
    required this.child,
    required this.glass,
    required this.bordered,
    required this.minHeight,
    this.reduceTransparency = false,
  });

  final Widget child;
  final bool glass;
  final bool bordered;
  final double minHeight;

  /// App-level "reduce transparency": solid fill, no blur (like UiGlass).
  final bool reduceTransparency;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final solid =
        reduceTransparency ||
        (MediaQuery.maybeOf(context)?.highContrast ?? false);
    Widget bar = Container(
      constraints: BoxConstraints(minHeight: minHeight),
      decoration: BoxDecoration(
        color: glass ? ui.bg.withValues(alpha: solid ? 1 : 0.92) : null,
        border: bordered
            ? Border(
                bottom: BorderSide(
                  color: ui.ink.withValues(alpha: 0.12),
                  width: UiBorder.hairline,
                ),
              )
            : null,
      ),
      child: child,
    );
    if (glass && !solid) {
      bar = ClipRect(
        child: BackdropFilter(
          filter: ui_.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: bar,
        ),
      );
    }
    return bar;
  }
}

/// `.topbar`: leading title block + trailing actions (`.top-actions`),
/// min 48dp tall, 1dp bottom border. The title is a bold h1 (27) and
/// ellipsizes. [glass] is for a bar that content scrolls under; default is a
/// solid, transparent-fill bar.
class UiTopBar extends StatelessWidget {
  const UiTopBar({
    this.title,
    this.eyebrow,
    this.leading,
    this.actions = const [],
    this.titleSize = 27,
    this.glass = false,
    this.bordered = true,
    this.reduceTransparency = false,
    super.key,
  });

  final String? title;
  final String? eyebrow;
  final Widget? leading;
  final List<Widget> actions;
  final double titleSize;
  final bool glass;
  final bool bordered;

  /// Solid fill instead of the frosted [glass] blur.
  final bool reduceTransparency;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return _BarFrame(
      glass: glass,
      bordered: bordered,
      reduceTransparency: reduceTransparency,
      minHeight: UiSize.tap,
      child: Row(
        children: [
          ?leading,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (eyebrow != null)
                  Text(
                    eyebrow!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: UiText.eyebrow(color: ui.inkMuted),
                  ),
                if (title != null)
                  Semantics(
                    header: true,
                    child: Text(
                      title!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: UiText.h1(size: titleSize, color: ui.ink),
                    ),
                  ),
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

/// `.screen-header`: 44dp outlined back button, centered h1 title (27)
/// with an optional subtitle, and an optional trailing action. 1dp bottom
/// border at 12% ink; [glass] only when content scrolls under it.
class UiBackHeader extends StatelessWidget {
  const UiBackHeader({
    required this.onBack,
    required this.backLabel,
    this.title,
    this.subtitle,
    this.trailing,
    this.bordered = true,
    this.glass = false,
    this.reduceTransparency = false,
    super.key,
  });

  final VoidCallback onBack;
  final String backLabel;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final bool bordered;
  final bool glass;

  /// Solid fill instead of the frosted [glass] blur.
  final bool reduceTransparency;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final titleStyle = UiText.heading(
      font: 'Space Grotesk',
      size: 27,
      weight: 700,
      tracking: -0.02,
      color: ui.ink,
    );
    final scaler = MediaQuery.textScalerOf(context);
    final subtitleStyle = UiText.body(
      size: 11,
      height: 1.35,
      color: ui.inkMuted,
    );
    // At 1x (or whenever there is no subtitle) the bar is the single-row 56dp
    // layout: back button, title (+ 1x subtitle) and trailing centred in one
    // row, with no extra height or per-build TextPainter.
    if (subtitle == null || scaler.scale(1) <= 1.0) {
      return _BarFrame(
        glass: glass,
        bordered: bordered,
        reduceTransparency: reduceTransparency,
        minHeight: 56,
        child: Row(
          children: [
            UiBarIconButton(
              glyph: const OurneyIcon(name: 'back', size: 21),
              label: backLabel,
              onPressed: onBack,
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title != null)
                    Semantics(
                      header: true,
                      child: Text(
                        title!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: titleStyle,
                      ),
                    ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: subtitleStyle,
                    ),
                ],
              ),
            ),
            trailing ?? const SizedBox(width: UiSize.tap),
          ],
        ),
      );
    }
    // Scaled text with a subtitle: the bar grows with its content. The back
    // and trailing controls sit in the title Row so they stay centred on the
    // title (not on title + subtitle), and the subtitle keeps 8dp above the
    // hairline.
    return _BarFrame(
      glass: glass,
      bordered: bordered,
      reduceTransparency: reduceTransparency,
      minHeight: 56,
      child: Padding(
        padding: const EdgeInsets.only(bottom: UiSpace.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                UiBarIconButton(
                  glyph: const OurneyIcon(name: 'back', size: 21),
                  label: backLabel,
                  onPressed: onBack,
                ),
                Expanded(
                  child: title != null
                      ? Semantics(
                          header: true,
                          child: Text(
                            title!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: titleStyle,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                trailing ?? const SizedBox(width: UiSize.tap),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: UiSize.tap),
              child: Text(
                subtitle!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: subtitleStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
