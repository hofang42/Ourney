import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../ui/ui.dart';
import 'app_dock.dart';
import 'theme/motion.dart';

/// Bottom shell: Journeys · [Capture] · Squad, drawn by [AppDock]. Branch
/// order = tab order, so branch 1 (Capture) is the center button and the
/// app's start tab. On the Capture tab the camera screen draws its own
/// dark dock around the hero shutter, so the shell shows none.
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const int journeysIndex = AppDock.journeysIndex;
  static const int captureIndex = AppDock.captureIndex;
  static const int groupsIndex = AppDock.groupsIndex;

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
    final onCamera = navigationShell.currentIndex == captureIndex;
    return Scaffold(
      backgroundColor: context.ui.bg,
      extendBody: false,
      body: navigationShell,
      bottomNavigationBar: onCamera
          ? null
          : AppDock(currentIndex: navigationShell.currentIndex, onSelect: _go),
    );
  }
}
