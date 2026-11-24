import 'package:flutter/material.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../ui/ui.dart';
import '../../journeys/ui/journey_row.dart' show journeyTypeId;
import '../l10n/generated/camera_localizations.dart';

/// At most this many journey discs; with more journeys the last slot becomes
/// the "All (N)" disc (SDS §8.8: 5 discs = 4 journeys + All).
const int kCameraQuickDiscs = 4;

/// Width of one disc slot (also its tap target).
const double kCameraDiscSlot = 48;

/// The journeys shown as discs: every journey when they fit, else pinned
/// first, then not shot today, then shot today (SDS §8.8), and the selected
/// one always stays visible. Order is stable inside each group.
List<Journey> quickCameraJourneys(
  List<Journey> all, {
  required String? selectedId,
  Set<String> pinnedIds = const {},
  Set<String> shotTodayIds = const {},
  int maxDiscs = kCameraQuickDiscs + 1,
}) {
  // [maxDiscs] slots: every journey when they fit, else maxDiscs - 1 plus
  // the "All (N)" disc (narrow phones have fewer slots).
  final quickCount = maxDiscs - 1;
  if (all.length <= maxDiscs) return all;
  int rank(Journey j) => pinnedIds.contains(j.id)
      ? 0
      : shotTodayIds.contains(j.id)
      ? 2
      : 1;
  final indexed = [for (var i = 0; i < all.length; i++) (i, all[i])]
    ..sort((a, b) {
      final r = rank(a.$2).compareTo(rank(b.$2));
      return r != 0 ? r : a.$1.compareTo(b.$1);
    });
  final quick = [for (final e in indexed.take(quickCount)) e.$2];
  final selected = all.where((j) => j.id == selectedId).firstOrNull;
  if (selected != null && !quick.contains(selected)) {
    quick[quick.length - 1] = selected;
  }
  return quick;
}

/// Image-only journey discs (bugs.md A1, SDS §8.8): no text under a disc;
/// state is drawn as small badges (pinned top-left, shot today bottom-right)
/// and the selected disc is bigger with an accent ring. Each disc has a full
/// semantic label. With more than [kCameraQuickDiscs] + 1 journeys the last
/// disc is "All (N)" and opens the searchable sheet.
class JourneyDiscStrip extends StatelessWidget {
  const JourneyDiscStrip({
    required this.journeys,
    required this.total,
    required this.selectedId,
    required this.onSelect,
    required this.onOpenAll,
    this.accent,
    this.pinnedIds = const {},
    this.shotTodayIds = const {},
    super.key,
  });

  /// Discs to draw (see [quickCameraJourneys]).
  final List<Journey> journeys;

  /// Number of active journeys; more than [journeys] adds the "All" disc.
  final int total;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final VoidCallback onOpenAll;
  final Color? accent;
  final Set<String> pinnedIds;
  final Set<String> shotTodayIds;

  @override
  Widget build(BuildContext context) {
    final l10n = CameraL10n.of(context);
    return Semantics(
      container: true,
      label: l10n.camera_journeyPicker,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final j in journeys)
              _Disc(
                key: ValueKey('journey-chip-${j.id}'),
                semanticLabel: [
                  j.title,
                  if (pinnedIds.contains(j.id)) l10n.camera_pickerPinned,
                  shotTodayIds.contains(j.id)
                      ? l10n.camera_pickerShot
                      : l10n.camera_pickerNotShot,
                ].join(', '),
                selected: j.id == selectedId,
                accent: accent,
                pinned: pinnedIds.contains(j.id),
                shot: shotTodayIds.contains(j.id),
                onTap: () => onSelect(j.id),
                child: UiTypeBadge(type: journeyTypeId(j), size: 44),
              ),
            if (total > journeys.length)
              _Disc(
                key: const ValueKey('journey-picker-open'),
                semanticLabel: l10n.camera_allJourneysCount(total),
                selected: false,
                onTap: onOpenAll,
                child: _AllBadge(count: total),
              ),
          ],
        ),
      ),
    );
  }
}

class _Disc extends StatelessWidget {
  const _Disc({
    required this.semanticLabel,
    required this.selected,
    required this.onTap,
    required this.child,
    this.accent,
    this.pinned = false,
    this.shot = false,
    super.key,
  });

  final String semanticLabel;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final Color? accent;
  final bool pinned;
  final bool shot;

  @override
  Widget build(BuildContext context) {
    final ring = accent ?? UiCamera.outline;
    final size = selected ? 48.0 : 42.0;
    return UiPressable(
      onPressed: onTap,
      selected: selected,
      semanticLabel: semanticLabel,
      excludeChildSemantics: true,
      centerChild: true,
      pressOffset: selected ? UiShadow.tiny : 0,
      minSize: const Size(kCameraDiscSlot, 56),
      child: SizedBox(
        width: kCameraDiscSlot,
        height: 56,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (selected)
              Transform.translate(
                offset: const Offset(UiShadow.tiny, UiShadow.tiny),
                child: SizedBox(
                  width: size,
                  height: size,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      color: UiCamera.shadow,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            AnimatedContainer(
              duration: UiMotion.of(context, UiMotion.fast),
              curve: UiCurves.easeOutStrong,
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? ring : UiCamera.dockBorder,
                  width: selected ? 3 : UiBorder.standard,
                ),
              ),
              child: FittedBox(child: child),
            ),
            if (pinned)
              const Positioned(
                left: 0,
                top: 0,
                child: _Badge(glyph: 'star', key: ValueKey('disc-pinned')),
              ),
            if (shot)
              const Positioned(
                right: 0,
                bottom: 0,
                child: _Badge(glyph: 'check', key: ValueKey('disc-shot')),
              ),
          ],
        ),
      ),
    );
  }
}

/// Small paper dot with a flat glyph (state without text).
class _Badge extends StatelessWidget {
  const _Badge({required this.glyph, super.key});

  final String glyph;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: UiCamera.outline,
        shape: BoxShape.circle,
        border: Border.all(color: UiCamera.shadow, width: UiBorder.hairline),
      ),
      child: OurneyIcon(
        name: glyph,
        flat: true,
        size: 12,
        color: UiCamera.shadow,
      ),
    );
  }
}

/// "All (N)": grid glyph and the count inside the disc, no caption.
class _AllBadge extends StatelessWidget {
  const _AllBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 44,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const OurneyIcon(
            name: 'grid',
            flat: true,
            size: 18,
            color: UiCamera.ink,
          ),
          Text(
            '$count',
            style: UiText.body(
              size: 12,
              weight: FontWeight.w700,
              height: 1.3,
              color: UiCamera.ink,
            ),
          ),
        ],
      ),
    );
  }
}
