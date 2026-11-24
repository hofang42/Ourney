import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/safety/data/safety_providers.dart';
import '../features/safety/ui/legal_screens.dart';
import '../ui/ui.dart';
import 'app_dock.dart';
import 'providers.dart';
import 'theme/motion.dart';

/// Bottom shell: Journeys · Squad · [Capture] · Activity · Profile, drawn by [AppDock]. Branch
/// order = tab order, so branch 2 (Capture) is the center button and the
/// app's start tab. On the Capture tab the camera screen draws its own
/// dark dock around the hero shutter, so the shell shows none.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const int journeysIndex = AppDock.journeysIndex;
  static const int captureIndex = AppDock.captureIndex;
  static const int groupsIndex = AppDock.groupsIndex;
  static const int activityIndex = AppDock.activityIndex;
  static const int profileIndex = AppDock.profileIndex;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  String? _promptedTermsKey;

  void _go(int index) {
    final navigationShell = widget.navigationShell;
    if (index == navigationShell.currentIndex) {
      navigationShell.goBranch(index, initialLocation: true);
      return;
    }
    OurneyHaptics.selection();
    navigationShell.goBranch(index);
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    final requiredVersion = ref.watch(termsVersionProvider);
    final needsTermsUpdate = ref.watch(needsTermsUpdateProvider);
    if (userId == null) {
      _promptedTermsKey = null;
    } else if (needsTermsUpdate) {
      final key = '$userId:$requiredVersion';
      if (_promptedTermsKey != key) {
        _promptedTermsKey = key;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          unawaited(showTermsUpdateSheet(context));
        });
      }
    }

    final navigationShell = widget.navigationShell;
    final onCamera = navigationShell.currentIndex == AppShell.captureIndex;
    return Scaffold(
      backgroundColor: context.ui.bg,
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: onCamera
          ? null
          : AppDock(currentIndex: navigationShell.currentIndex, onSelect: _go),
    );
  }
}
