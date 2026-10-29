import 'package:flutter/material.dart';

import '../tokens.dart';
import '../typography.dart';
import 'avatar.dart';
import 'buttons.dart';
import 'pressable.dart';
import 'sheets.dart';

/// `.person-row` / `.inbox-row`: avatar, title + muted sub-lines, inline
/// [trailing] widgets and hairline underneath. [actions] (Accept / Decline)
/// sit inline on wide rows and wrap under the text on narrow ones (320dp,
/// large text). [unread] adds a red dot and bold title.
class UiPersonRow extends StatelessWidget {
  const UiPersonRow({
    required this.name,
    required this.title,
    this.subtitle,
    this.extraLine,
    this.trailing = const [],
    this.actions = const [],
    this.onPressed,
    this.unread = false,
    this.leading,
    this.dotKey,
    this.minHeight = 68,
    super.key,
  });

  /// Seeds the initial avatar.
  final String name;
  final String title;
  final String? subtitle;
  final String? extraLine;
  final List<Widget> trailing;
  final List<Widget> actions;
  final VoidCallback? onPressed;
  final bool unread;

  /// Replaces the avatar.
  final Widget? leading;
  final Key? dotKey;
  final double minHeight;

  /// Narrowest row (at 1x text) that keeps [actions] inline.
  static const double inlineActionsMinWidth = 400;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (context, constraints) {
        final inline =
            actions.isEmpty ||
            constraints.maxWidth >= inlineActionsMinWidth * scale;
        Widget line(String text, {Color? color, FontWeight? weight}) => Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: UiText.body(
            size: 12,
            height: 1.4,
            weight: weight ?? FontWeight.w400,
            color: color ?? ui.inkMuted,
          ),
        );
        final texts = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: UiText.body(
                size: 15,
                height: 1.35,
                weight: unread ? FontWeight.w800 : FontWeight.w700,
                color: ui.ink,
              ),
            ),
            if (subtitle != null) line(subtitle!),
            if (extraLine != null) line(extraLine!),
            if (!inline) ...[
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 6, children: actions),
            ],
          ],
        );
        final row = Container(
          constraints: BoxConstraints(minHeight: minHeight),
          padding: const EdgeInsets.symmetric(vertical: UiSpace.sm),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: ui.divider)),
          ),
          child: Row(
            children: [
              if (unread) ...[
                Container(
                  key: dotKey ?? const ValueKey('unread-dot'),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: ui.danger,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              leading ??
                  ExcludeSemantics(
                    child: UiAvatar(
                      name: name,
                      colorIndex: UiAvatar.indexFor(name),
                      size: UiSize.avatarLarge,
                      ring: false,
                    ),
                  ),
              const SizedBox(width: 10),
              Expanded(child: texts),
              if (inline)
                for (final a in actions) ...[const SizedBox(width: 6), a],
              for (final t in trailing) ...[const SizedBox(width: 6), t],
            ],
          ),
        );
        if (onPressed == null) return row;
        return UiPressable(
          onPressed: onPressed,
          borderRadius: BorderRadius.circular(UiRadius.input),
          minSize: Size(UiSize.tap, minHeight),
          child: row,
        );
      },
    );
  }
}

/// Round 40dp glyph tile used as a row leading (consents, shares).
class UiIconCircle extends StatelessWidget {
  const UiIconCircle(this.icon, {this.size = 40, super.key});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: ui.fill, shape: BoxShape.circle),
      child: Icon(icon, size: size * 0.5, color: ui.ink),
    );
  }
}

/// Muted state label in place of a button ("Requested", "Friends").
class UiStateLabel extends StatelessWidget {
  const UiStateLabel(this.text, {this.icon, super.key});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: UiSize.tap),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: ui.inkMuted),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: UiText.body(
              size: 13,
              weight: FontWeight.w700,
              height: 1.3,
              color: ui.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom-sheet confirmation. Resolves to true on confirm. The confirm button
/// has [confirmKey]; [destructive] draws it in the danger color.
Future<bool> showUiConfirmSheet({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
  bool destructive = false,
  Key? sheetKey,
  Key? confirmKey,
}) async {
  final result = await showUiSheet<bool>(
    context: context,
    builder: (context) {
      final ui = context.ui;
      return Column(
        key: sheetKey,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: UiText.h2(size: 22, color: ui.ink)),
          ),
          const SizedBox(height: UiSpace.sm),
          Text(message, style: UiText.muted(size: 15, color: ui.inkMuted)),
          const SizedBox(height: UiSpace.xl),
          UiButton(
            key: confirmKey,
            label: confirmLabel,
            accent: destructive ? ui.danger : null,
            onAccent: destructive ? Colors.white : null,
            onPressed: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: UiSpace.sm),
          UiButton.secondary(
            label: cancelLabel,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
