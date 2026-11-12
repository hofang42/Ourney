import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/generated/app_localizations.dart';
import '../ui/ui.dart';
import 'providers.dart';

/// The 3-tab dock of every primary screen (App.tsx `Dock`, CLAUDE.md §2):
/// Journeys, the quick-snap pill (filled with the active journey's accent)
/// and Squad. On the camera it becomes the dark `.camera-dock` with the
/// hero shutter passed as [center].
class AppDock extends ConsumerWidget {
  const AppDock({
    required this.currentIndex,
    required this.onSelect,
    this.shutter,
    super.key,
  });

  static const int journeysIndex = 0;
  static const int captureIndex = 1;
  static const int groupsIndex = 2;

  final int currentIndex;
  final ValueChanged<int> onSelect;

  /// The hero shutter; when set the dock is drawn in camera mode.
  final Widget? shutter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final skin = ref.watch(activePersonaSkinProvider);
    final style = skin == null ? null : uiStyleForSkin(skin);
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
        left: UiDockItem(
          itemKey: const ValueKey('dock-journeys'),
          icon: Icons.map_outlined,
          label: l10n.nav_journeys,
          active: currentIndex == journeysIndex,
          onPressed: () => onSelect(journeysIndex),
        ),
        right: UiDockItem(
          itemKey: const ValueKey('dock-groups'),
          icon: Icons.people_outline_rounded,
          label: l10n.nav_groups,
          active: currentIndex == groupsIndex,
          onPressed: () => onSelect(groupsIndex),
        ),
      ),
    );
  }
}
