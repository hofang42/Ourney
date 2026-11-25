import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/app_dock.dart';
import '../data/update_providers.dart';
import 'soft_update_sheet.dart';
import 'whats_new_sheet.dart';

/// Coordinates automatic presentation of [WhatsNewSheet] and [SoftUpdateSheet]
/// inside `AppShell`.
///
/// Rules enforced:
/// - Never opens automatic update sheets on the Camera tab
///   (`currentIndex == AppDock.captureIndex`).
/// - Respects single-sheet priority:
///   `TermsUpdateSheet` > `WhatsNewSheet` > `SoftUpdateSheet`.
/// - Never stacks two sheets at once or re-prompts the same version in the
///   same session after a dismissal.
class UpdateShellCoordinator extends ConsumerStatefulWidget {
  const UpdateShellCoordinator({
    required this.currentIndex,
    required this.termsSheetBlocking,
    required this.child,
    super.key,
  });

  final int currentIndex;
  final bool termsSheetBlocking;
  final Widget child;

  @override
  ConsumerState<UpdateShellCoordinator> createState() =>
      _UpdateShellCoordinatorState();
}

class _UpdateShellCoordinatorState
    extends ConsumerState<UpdateShellCoordinator> {
  bool _sheetOpen = false;
  bool _scheduled = false;
  SemVer? _promptedWhatsNewVersion;
  SemVer? _promptedSoftVersion;

  bool get _onBrowseTab => widget.currentIndex != AppDock.captureIndex;

  void _maybeSchedule(AppUpdateState state) {
    if (_scheduled ||
        _sheetOpen ||
        !_onBrowseTab ||
        widget.termsSheetBlocking ||
        state.urgency == UpdateUrgency.forced) {
      return;
    }

    final wantsWhatsNew =
        state.canShowWhatsNew &&
        state.installedVersion != null &&
        _promptedWhatsNewVersion != state.installedVersion;
    final latest = state.manifest?.latest;
    final wantsSoftSheet =
        !wantsWhatsNew &&
        _promptedWhatsNewVersion == null &&
        state.urgency == UpdateUrgency.softSheet &&
        state.manifest?.downloadUrl != null &&
        latest != null &&
        _promptedSoftVersion != latest;

    if (!wantsWhatsNew && !wantsSoftSheet) return;

    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!mounted ||
          _sheetOpen ||
          !_onBrowseTab ||
          widget.termsSheetBlocking ||
          (ModalRoute.of(context)?.isCurrent == false)) {
        return;
      }
      final live = ref.read(appUpdateControllerProvider);
      if (live.urgency == UpdateUrgency.forced) return;

      if (live.canShowWhatsNew &&
          live.installedVersion != null &&
          _promptedWhatsNewVersion != live.installedVersion) {
        _promptedWhatsNewVersion = live.installedVersion;
        _sheetOpen = true;
        unawaited(
          showWhatsNewSheet(
            context,
            version: live.installedVersion,
          ).whenComplete(() {
            if (mounted) {
              setState(() => _sheetOpen = false);
            } else {
              _sheetOpen = false;
            }
          }),
        );
        return;
      }

      final liveLatest = live.manifest?.latest;
      if (_promptedWhatsNewVersion == null &&
          live.urgency == UpdateUrgency.softSheet &&
          live.manifest?.downloadUrl != null &&
          liveLatest != null &&
          _promptedSoftVersion != liveLatest) {
        _promptedSoftVersion = liveLatest;
        _sheetOpen = true;
        unawaited(
          showSoftUpdateSheet(
            context,
            version: liveLatest,
          ).whenComplete(() {
            if (mounted) {
              setState(() => _sheetOpen = false);
            } else {
              _sheetOpen = false;
            }
          }),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appUpdateControllerProvider);
    if (ModalRoute.of(context)?.isCurrent != false) {
      _maybeSchedule(state);
    }
    return widget.child;
  }
}
