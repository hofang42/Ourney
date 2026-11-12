import 'package:flutter/material.dart';

import '../tokens.dart';
import '../typography.dart';
import 'buttons.dart';

/// `.topbar`: leading title block + trailing actions (`.top-actions`),
/// min 48dp tall. The title is a bold h1/h2 and ellipsizes.
class UiTopBar extends StatelessWidget {
  const UiTopBar({
    this.title,
    this.eyebrow,
    this.leading,
    this.actions = const [],
    this.titleSize = 22,
    super.key,
  });

  final String? title;
  final String? eyebrow;
  final Widget? leading;
  final List<Widget> actions;
  final double titleSize;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: UiSize.tap),
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

/// `.detail-nav`: back button, centered title (+ optional subtitle) and an
/// optional trailing action, with an optional hairline below.
class UiBackHeader extends StatelessWidget {
  const UiBackHeader({
    required this.onBack,
    required this.backLabel,
    this.title,
    this.subtitle,
    this.trailing,
    this.bordered = false,
    super.key,
  });

  final VoidCallback onBack;
  final String backLabel;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      decoration: BoxDecoration(
        border: bordered ? Border(bottom: BorderSide(color: ui.divider)) : null,
      ),
      child: Row(
        children: [
          UiIconButton(
            icon: Icons.arrow_back_rounded,
            label: backLabel,
            onPressed: onBack,
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null)
                  Text(
                    title!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: UiText.body(
                      size: 14,
                      weight: FontWeight.w700,
                      height: 1.4,
                      color: ui.ink,
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
