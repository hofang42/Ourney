import 'package:flutter/material.dart';

import '../tokens.dart';
import '../typography.dart';
import 'ourney_icons.dart';
import 'pressable.dart';

/// The six reaction ids, in display order.
const List<String> uiReactionIds = [
  'clap',
  'flex',
  'heart',
  'laugh',
  'fire',
  'wave',
];

/// A pill of the six V2 reactions drawn with Ourney sticker icons (never
/// emoji). Each reaction is a 38dp sticker disc inside a 48dp hit target.
/// [selected] is the reaction the viewer already gave; [counts] adds a small
/// count badge. [labels] maps each id in [uiReactionIds] to its localized
/// semantics label (supplied by the caller from l10n).
class UiReactionBar extends StatelessWidget {
  const UiReactionBar({
    required this.onReact,
    required this.labels,
    this.selected,
    this.counts,
    super.key,
  });

  final ValueChanged<String> onReact;
  final Map<String, String> labels;
  final String? selected;
  final Map<String, int>? counts;

  static const double visual = 38;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    // Scrolls horizontally instead of shrinking: hit targets stay 48dp.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      // Room for the 2dp hard shadow, which the scroll view would clip.
      clipBehavior: Clip.none,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ui.surface,
          borderRadius: BorderRadius.circular(UiRadius.capsule),
          border: ui.stickerBorder(UiBorder.thin),
          boxShadow: ui.hardShadow(UiShadow.tiny),
        ),
        child: Padding(
          padding: const EdgeInsets.all(UiSpace.xs),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final id in uiReactionIds)
                _ReactionButton(
                  id: id,
                  selected: selected == id,
                  count: counts?[id] ?? 0,
                  label: labels[id] ?? id,
                  onReact: onReact,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReactionButton extends StatelessWidget {
  const _ReactionButton({
    required this.id,
    required this.selected,
    required this.count,
    required this.label,
    required this.onReact,
  });

  final String id;
  final bool selected;
  final int count;
  final String label;
  final ValueChanged<String> onReact;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final semantic = count > 0 ? '$label, $count' : label;
    return UiPressable(
      onPressed: () => onReact(id),
      selected: selected,
      semanticLabel: semantic,
      excludeChildSemantics: true,
      centerChild: true,
      borderRadius: BorderRadius.circular(UiRadius.capsule),
      child: SizedBox.square(
        dimension: UiSize.tap,
        child: Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                key: ValueKey('reaction-disc-$id'),
                width: UiReactionBar.visual,
                height: UiReactionBar.visual,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? ui.brand : ui.fill,
                  border: selected
                      ? Border.all(color: ui.outline, width: UiBorder.thin)
                      : null,
                ),
                child: OurneyIcon(name: 'react-$id', size: 24, active: true),
              ),
              if (count > 0)
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 18),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: ui.surface,
                      borderRadius: BorderRadius.circular(UiRadius.capsule),
                      border: Border.all(
                        color: ui.outline,
                        width: UiBorder.hairline,
                      ),
                    ),
                    child: MediaQuery.withClampedTextScaling(
                      maxScaleFactor: 1.35,
                      child: Text(
                        '$count',
                        textAlign: TextAlign.center,
                        style: UiText.body(
                          size: 10,
                          weight: FontWeight.w700,
                          height: 1.3,
                          color: ui.ink,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
