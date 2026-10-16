import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/generated/app_localizations.dart';
import 'theme/motion.dart';
import 'theme/tokens.dart';

/// Bottom shell: Journeys · [Capture] · Nhom. Branch order = tab order, so
/// branch 1 (Capture) is the center button and the app's start tab.
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const int journeysIndex = 0;
  static const int captureIndex = 1;
  static const int groupsIndex = 2;

  void _go(int index) {
    if (index == navigationShell.currentIndex) {
      navigationShell.goBranch(index, initialLocation: true);
      return;
    }
    OurneyHaptics.selection();
    navigationShell.goBranch(index);
  }

  @override
  Widget build(BuildContext context) {
    final onCapture = navigationShell.currentIndex == captureIndex;
    return Scaffold(
      extendBody: false,
      body: navigationShell,
      bottomNavigationBar: _OurneyBottomBar(
        currentIndex: navigationShell.currentIndex,
        onSelect: _go,
        dark: onCapture, // camera surfaces are always dark
      ),
    );
  }
}

class _OurneyBottomBar extends StatelessWidget {
  const _OurneyBottomBar({
    required this.currentIndex,
    required this.onSelect,
    required this.dark,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = dark ? OurneyColors.dark : OurneyColors.of(context);
    final bg = dark ? OurneyColors.cameraBg : c.surface;
    return Material(
      color: bg,
      child: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: c.border)),
        ),
        child: SafeArea(
          top: false,
          // Compact chrome: labels follow the system text size only up to
          // 1.3x (like native tab bars); content screens scale to 2x.
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.3,
            child: SizedBox(
              height: 72,
              child: Row(
                children: [
                  Expanded(
                    child: _TabItem(
                      icon: Icons.route_rounded,
                      label: l10n.nav_journeys,
                      selected: currentIndex == AppShell.journeysIndex,
                      colors: c,
                      onTap: () => onSelect(AppShell.journeysIndex),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: _CaptureTabButton(
                        label: l10n.nav_capture,
                        selected: currentIndex == AppShell.captureIndex,
                        colors: c,
                        onTap: () => onSelect(AppShell.captureIndex),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _TabItem(
                      icon: Icons.groups_rounded,
                      label: l10n.nav_groups,
                      selected: currentIndex == AppShell.groupsIndex,
                      colors: c,
                      onTap: () => onSelect(AppShell.groupsIndex),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final OurneyColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Selected = deep coral + bold label + indicator bar (not color-only).
    final color = selected ? colors.primaryDeep : colors.inkMuted;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: OurneyMotion.duration(context, OurneyDurations.tap),
              width: selected ? 20 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaptureTabButton extends StatelessWidget {
  const _CaptureTabButton({
    required this.label,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final OurneyColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const size = 64.0;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: colors.primary,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? Colors.white : Colors.transparent,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.photo_camera_rounded,
            color: colors.onPrimary,
            size: 30,
          ),
        ),
      ),
    );
  }
}
