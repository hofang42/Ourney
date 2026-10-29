import 'package:flutter/material.dart';

import '../tokens.dart';
import '../typography.dart';
import 'chips.dart';
import 'pressable.dart';

class UiSegment<T> {
  const UiSegment({
    required this.value,
    required this.label,
    this.showDot = false,
    this.key,
  });

  /// Key of the tappable segment (tests, other features).
  final Key? key;

  final T value;
  final String label;

  /// `.segment-new-dot`.
  final bool showDot;
}

/// `.segments`: 48dp capsule track, 4dp inset, selected tab raised on
/// [OurneyUi.fillSelected]. With [scrollable] (`.hub-segments`) segments take
/// their natural width (min 92) and the track scrolls horizontally.
class UiSegmented<T> extends StatelessWidget {
  const UiSegmented({
    required this.segments,
    required this.value,
    required this.onChanged,
    this.scrollable = false,
    super.key,
  });

  final List<UiSegment<T>> segments;
  final T value;
  final ValueChanged<T> onChanged;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    Widget tab(UiSegment<T> s) {
      final selected = s.value == value;
      final label = Flexible(
        child: Text(
          s.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: UiText.body(
            size: 15,
            weight: FontWeight.w600,
            height: 1.3,
            color: ui.ink,
          ),
        ),
      );
      final child = Container(
        alignment: Alignment.center,
        constraints: BoxConstraints(minWidth: scrollable ? 92 : 0),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? ui.fillSelected : Colors.transparent,
          borderRadius: BorderRadius.circular(UiRadius.capsule),
          boxShadow: selected && !ui.isDark
              ? const [
                  BoxShadow(
                    color: Color(0x0D111114),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            label,
            if (s.showDot) ...[const SizedBox(width: 6), const UiNewDot()],
          ],
        ),
      );
      final pressable = UiPressable(
        key: s.key,
        onPressed: () => onChanged(s.value),
        selected: selected,
        semanticLabel: s.label,
        excludeChildSemantics: true,
        minSize: const Size(UiSize.tap, 40),
        child: child,
      );
      return scrollable ? pressable : Expanded(child: pressable);
    }

    final row = Row(
      mainAxisSize: scrollable ? MainAxisSize.min : MainAxisSize.max,
      children: [for (final s in segments) tab(s)],
    );
    return Container(
      height: UiSize.tap,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ui.fill,
        borderRadius: BorderRadius.circular(UiRadius.capsule),
      ),
      child: scrollable
          ? SingleChildScrollView(scrollDirection: Axis.horizontal, child: row)
          : row,
    );
  }
}
