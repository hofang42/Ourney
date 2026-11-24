import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';

import '../features/journeys/data/journeys_providers.dart';
import '../l10n/generated/app_localizations.dart';
import '../personas/persona_contract.dart';
import '../ui/ui.dart';
import 'providers.dart';
import 'theme/motion.dart';

/// The 5-tab dock of every primary screen (V2 `Dock`, CLAUDE.md §2):
/// Journeys · Squad ("Nhóm") · the quick-snap pill (filled with the active
/// journey's accent) · Activity · Profile. On the camera it becomes the dark `.camera-dock` with the
/// hero shutter passed as [shutter].
///
/// Long-pressing the center (400ms) opens the journey wheel
/// ([showUiJourneyWheel]) over the screen; picking a journey only switches
/// `activeJourneyIdProvider` (no navigation, the camera keeps running).
class AppDock extends ConsumerStatefulWidget {
  const AppDock({
    required this.currentIndex,
    required this.onSelect,
    this.shutter,
    super.key,
  });

  static const int journeysIndex = 0;
  static const int groupsIndex = 1;
  static const int captureIndex = 2;
  static const int activityIndex = 3;
  static const int profileIndex = 4;

  final int currentIndex;
  final ValueChanged<int> onSelect;

  /// The hero shutter; when set the dock is drawn in camera mode.
  final Widget? shutter;

  @override
  ConsumerState<AppDock> createState() => _AppDockState();
}

class _AppDockState extends ConsumerState<AppDock> {
  final GlobalKey _dockKey = GlobalKey();

  /// [UiTypeBadge] id of a persona skin.
  static String _badgeType(PersonaSkinId skin) => switch (skin) {
    PersonaSkinId.quietTransformer => 'weight',
    PersonaSkinId.accountabilitySquad => 'study',
    PersonaSkinId.memoryCollectors => 'trip',
    PersonaSkinId.coupleRituals => 'couple',
    PersonaSkinId.aestheticFlexer => 'workout',
    PersonaSkinId.minimalistHabit => 'custom',
  };

  void _openWheel() {
    final box = _dockKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached) return;
    final journeys = ref.read(journeysListProvider).value ?? const <Journey>[];
    final active = [
      for (final j in journeys)
        if (j.status == JourneyStatus.active) j,
    ];
    if (active.isEmpty) return;
    final stored = ref.read(activeJourneyIdProvider);
    final activeId = active.any((j) => j.id == stored)
        ? stored
        : active.first.id;
    final l10n = AppLocalizations.of(context);
    OurneyHaptics.selection();
    showUiJourneyWheel(
      context,
      items: [
        for (final j in active)
          UiJourneyWheelItem(
            id: j.id,
            label: j.title,
            type: _badgeType(personaSkinOf(j)),
            accent: uiStyleForSkin(personaSkinOf(j)).accent,
          ),
      ],
      activeId: activeId,
      anchor: box.localToGlobal(box.size.center(Offset.zero)),
      semanticLabel: l10n.nav_chooseJourney,
      closeLabel: l10n.common_close,
      activeHint: l10n.nav_journeySelected,
      onSelect: (id) {
        OurneyHaptics.selection();
        ref.read(activeJourneyIdProvider.notifier).select(id);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final skin = ref.watch(activePersonaSkinProvider);
    final style = skin == null ? null : uiStyleForSkin(skin);
    // Keep the journey list warm so the wheel opens with data.
    ref.watch(journeysListProvider);
    UiDockItem item(String key, String glyph, String label, int index) =>
        UiDockItem(
          itemKey: ValueKey(key),
          glyph: glyph,
          label: label,
          active: widget.currentIndex == index,
          onPressed: () => widget.onSelect(index),
        );
    return KeyedSubtree(
      key: _dockKey,
      child: UiDock(
        camera: widget.shutter != null,
        center: widget.shutter,
        accent: style?.accent,
        onAccent: style?.onAccent,
        snapLabel: l10n.nav_capture,
        snapKey: const ValueKey('dock-snap-pill'),
        onSnap: () => widget.onSelect(AppDock.captureIndex),
        onShutterLongPress: _openWheel,
        left: item(
          'dock-journeys',
          'journeys',
          l10n.nav_journeys,
          AppDock.journeysIndex,
        ),
        extraLeft: [
          item('dock-groups', 'squad', l10n.nav_groups, AppDock.groupsIndex),
        ],
        extraRight: [
          item(
            'dock-activity',
            'activity',
            l10n.nav_activity,
            AppDock.activityIndex,
          ),
        ],
        right: item(
          'dock-profile',
          'profile',
          l10n.nav_profileTab,
          AppDock.profileIndex,
        ),
      ),
    );
  }
}
