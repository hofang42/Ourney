import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../shared/ourney_dock.dart';
import 'theme/motion.dart';

/// Bottom shell: Journeys · [Capture] · Squad, drawn by [OurneyDock]. Branch
/// order = tab order, so branch 1 (Capture) is the center button and the
/// app's start tab.
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const int journeysIndex = OurneyDock.journeysIndex;
  static const int captureIndex = OurneyDock.captureIndex;
  static const int groupsIndex = OurneyDock.groupsIndex;

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
    return Scaffold(
      extendBody: false,
      body: navigationShell,
      bottomNavigationBar: OurneyDock(
        currentIndex: navigationShell.currentIndex,
        onSelect: _go,
      ),
    );
  }
}
