import 'package:flutter/material.dart';

import '../tokens.dart';
import '../typography.dart';
import 'chips.dart';
import 'ourney_icons.dart';

/// Sticky month header of a long timeline (`SliverPersistentHeader`,
/// pinned): accent bar, `THÁNG 10 2026` title, a one-line summary and a
/// chevron that shows the expanded state.
///
/// One semantics node: a heading and a button with the `expanded` flag, so a
/// screen reader jumps month to month with heading navigation and hears
/// whether a month is open. Its height is [extentOf] (grows with the text
/// scale, never clips at 1.35x).
class UiMonthHeader extends StatelessWidget {
  const UiMonthHeader({
    required this.title,
    required this.summary,
    required this.expanded,
    required this.onPressed,
    required this.semanticLabel,
    this.semanticHint,
    this.accent,
    this.background,
    super.key,
  });

  final String title;
  final String summary;
  final bool expanded;
  final VoidCallback onPressed;

  /// Spoken label ("Tháng 10 2026, 27 trên 31 ngày đã chụp, 30 ảnh").
  final String semanticLabel;

  /// Spoken action ("Mở rộng" / "Thu gọn").
  final String? semanticHint;

  /// Bar color (the journey accent); defaults to the brand color.
  final Color? accent;

  /// Opaque paper behind the header (content scrolls under it).
  final Color? background;

  static const double _vPad = 6;

  /// Header height for the ambient text scale: at least 56dp, taller when
  /// the two text lines need it.
  static double extentOf(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return (scaler.scale(13 * 1.35) + scaler.scale(12 * 1.4) + _vPad * 2 + 4)
        .clamp(56.0, double.infinity);
  }

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return Semantics(
      header: true,
      button: true,
      expanded: expanded,
      label: semanticLabel,
      hint: semanticHint,
      onTap: onPressed,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background ?? ui.bg,
            border: Border(bottom: BorderSide(color: ui.divider)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: _vPad),
            child: Row(
              children: [
                Container(
                  width: 4,
                  margin: const EdgeInsetsDirectional.only(end: UiSpace.md),
                  decoration: BoxDecoration(
                    color: accent ?? ui.brand,
                    borderRadius: BorderRadius.circular(UiRadius.capsule),
                  ),
                ),
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
                          size: 13,
                          weight: FontWeight.w800,
                          height: 1.35,
                          tracking: 0.6,
                          color: ui.ink,
                        ),
                      ),
                      Text(
                        summary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: UiText.body(
                          size: 12,
                          height: 1.4,
                          color: ui.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: UiSpace.sm),
                SizedBox.square(
                  dimension: UiSize.tap,
                  child: Center(
                    child: OurneyIcon(
                      name: expanded ? 'chevron-down' : 'chevron-right',
                      size: 20,
                      flat: true,
                      color: ui.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One chip of [UiJumpChips].
class UiJumpChip {
  const UiJumpChip({
    required this.label,
    required this.onPressed,
    this.semanticHint,
    this.selected = false,
    this.key,
  });

  final String label;
  final VoidCallback onPressed;

  /// Spoken action ("Đi tới tháng 10 2026").
  final String? semanticHint;
  final bool selected;
  final Key? key;
}

/// Horizontal row of month (or year) jump chips, 48dp touch targets. Lazy:
/// only the chips in view are built.
class UiJumpChips extends StatelessWidget {
  const UiJumpChips({required this.chips, super.key});

  final List<UiJumpChip> chips;

  /// Row height: the 48dp chip hit area plus room for its hard shadow.
  static const double height = 52;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsetsDirectional.only(end: UiSpace.sm),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: UiSpace.sm),
        itemBuilder: (context, i) {
          final c = chips[i];
          return Align(
            child: UiChip(
              key: c.key,
              label: c.label,
              selected: c.selected,
              semanticHint: c.semanticHint,
              onPressed: c.onPressed,
            ),
          );
        },
      ),
    );
  }
}