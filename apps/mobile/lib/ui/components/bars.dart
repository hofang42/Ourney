import 'dart:ui' as ui_;

import 'package:flutter/material.dart';

import '../tokens.dart';
import '../typography.dart';
import 'pressable.dart';

/// `.screen-header > button`: 44dp circular icon button, 1.5dp ink outline,
/// surface fill, inside a 48dp hit area. Use it in [UiTopBar.actions] /
/// [UiTopBar.leading] so every header control matches.
class UiBarIconButton extends StatelessWidget {
  const UiBarIconButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.iconSize = 21,
    super.key,
  });

  final IconData icon;

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
        child: Icon(
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
  });

  final Widget child;
  final bool glass;
  final bool bordered;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final solid = MediaQuery.maybeOf(context)?.highContrast ?? false;
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
    super.key,
  });

  final String? title;
  final String? eyebrow;
  final Widget? leading;
  final List<Widget> actions;
  final double titleSize;
  final bool glass;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return _BarFrame(
      glass: glass,
      bordered: bordered,
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
    super.key,
  });

  final VoidCallback onBack;
  final String backLabel;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final bool bordered;
  final bool glass;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return _BarFrame(
      glass: glass,
      bordered: bordered,
      minHeight: 56,
      child: Row(
        children: [
          UiBarIconButton(
            icon: Icons.arrow_back_rounded,
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
                      style: UiText.h1(size: 27, color: ui.ink),
                    ),
                  ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: UiText.body(size: 11, color: ui.inkMuted),
                  ),
              ],
            ),
          ),
          trailing ?? const SizedBox(width: UiSize.tap),
        ],
      ),
    );
  }
}
