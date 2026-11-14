import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/generated/app_localizations.dart';
import '../ui/ui.dart';
import 'providers.dart';

/// The 5-tab dock of every primary screen (V2 `Dock`, CLAUDE.md §2):
/// Journeys · Squad ("Hội") · the quick-snap pill (filled with the active
/// journey's accent) · Activity · Profile. On the camera it becomes the dark `.camera-dock` with the
/// hero shutter passed as [center].
class AppDock extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final skin = ref.watch(activePersonaSkinProvider);
    final style = skin == null ? null : uiStyleForSkin(skin);
    UiDockItem item(String key, String glyph, String label, int index) =>
        UiDockItem(
          itemKey: ValueKey(key),
          glyph: glyph,
          label: label,
          active: currentIndex == index,
          onPressed: () => onSelect(index),
        );
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: UiDock(
        camera: shutter != null,
        center: shutter,
        accent: style?.accent,
        onAccent: style?.onAccent,
        snapLabel: l10n.nav_capture,
        snapKey: const ValueKey('dock-snap-pill'),
        onSnap: () => onSelect(captureIndex),
        left: item(
          'dock-journeys',
          'journeys',
          l10n.nav_journeys,
          journeysIndex,
        ),
        extraLeft: [item('dock-groups', 'squad', l10n.nav_groups, groupsIndex)],
        extraRight: [
          item('dock-activity', 'activity', l10n.nav_activity, activityIndex),
        ],
        right: item(
          'dock-profile',
          'profile',
          l10n.nav_profileTab,
          profileIndex,
        ),
      ),
    );
  }
}
