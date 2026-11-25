import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/safety/data/safety_providers.dart';
import '../features/safety/ui/legal_screens.dart';
import '../features/update/ui/update_shell_coordinator.dart';
import '../ui/ui.dart';
import 'app_dock.dart';
import 'providers.dart';

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
    final termsBlocking =
        (userId != null && needsTermsUpdate) || _promptedTermsKey != null;
    return Scaffold(
      backgroundColor: context.ui.bg,
      extendBody: true,
      body: UpdateShellCoordinator(
        currentIndex: navigationShell.currentIndex,
        termsSheetBlocking: termsBlocking,
        child: navigationShell,
      ),
      bottomNavigationBar: onCamera
          ? null
          : AppDock(currentIndex: navigationShell.currentIndex, onSelect: _go),
    );
  }
}

/// Animated branch container for [StatefulShellRoute] that immediately places
/// inactive branches inside `Offstage(offstage: true)` and
/// `TickerMode(enabled: false)` (so Tab 2 `CaptureScreen` stops/releases the
/// camera sensor on the very frame the user leaves Tab 2) while animating only
/// the newly active branch over [UiMotion.fast] (`160ms`,
/// [UiCurves.easeOutStrong]): [FadeTransition] (`0.0 -> 1.0`) + subtle
/// directional horizontal translate (`±6dp`, `0dp` when entering or leaving
/// Tab 2 Camera, `0dp` under Reduce Motion).
class UiShellBranchContainer extends StatefulWidget {
  const UiShellBranchContainer({
    required this.currentIndex,
    required this.children,
    super.key,
  });

  final int currentIndex;
  final List<Widget> children;

  static const double slideDistance = 6.0;

  @override
  State<UiShellBranchContainer> createState() => _UiShellBranchContainerState();
}

class _UiShellBranchContainerState extends State<UiShellBranchContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: UiMotion.fast,
    value: 1.0,
  );
  late final CurvedAnimation _curved = CurvedAnimation(
    parent: _ctrl,
    curve: UiCurves.easeOutStrong,
  );

  double _slideDx = 0.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (UiMotion.reduced(context) && _ctrl.isAnimating) {
      _ctrl.stop();
      _ctrl.value = 1.0;
      _slideDx = 0.0;
    }
  }

  @override
  void didUpdateWidget(covariant UiShellBranchContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex == oldWidget.currentIndex) return;
    if (UiMotion.reduced(context)) {
      _ctrl.stop();
      _ctrl.value = 1.0;
      _slideDx = 0.0;
      return;
    }
    final enteringOrLeavingCamera =
        oldWidget.currentIndex == AppShell.captureIndex ||
        widget.currentIndex == AppShell.captureIndex;
    if (enteringOrLeavingCamera) {
      _slideDx = 0.0;
    } else {
      final isRtl = Directionality.maybeOf(context) == TextDirection.rtl;
      final dir = widget.currentIndex.compareTo(oldWidget.currentIndex);
      final sign = isRtl ? -dir.toDouble() : dir.toDouble();
      _slideDx = sign * UiShellBranchContainer.slideDistance;
    }
    _ctrl
      ..duration = UiMotion.fast
      ..forward(from: 0.0);
  }

  @override
  void dispose() {
    _curved.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = UiMotion.reduced(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          Offstage(
            offstage: i != widget.currentIndex,
            child: TickerMode(
              enabled: i == widget.currentIndex,
              child: IgnorePointer(
                ignoring: i != widget.currentIndex,
                child: FadeTransition(
                  opacity: (!reduced && i == widget.currentIndex)
                      ? _curved
                      : kAlwaysCompleteAnimation,
                  child: AnimatedBuilder(
                    animation: (!reduced && i == widget.currentIndex)
                        ? _curved
                        : kAlwaysCompleteAnimation,
                    child: widget.children[i],
                    builder: (context, child) {
                      final active = !reduced && i == widget.currentIndex;
                      final dx = active
                          ? (1.0 - _curved.value) * _slideDx
                          : 0.0;
                      return Transform.translate(
                        key: ValueKey('shell-branch-translate-$i'),
                        offset: Offset(dx, 0.0),
                        child: child,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
