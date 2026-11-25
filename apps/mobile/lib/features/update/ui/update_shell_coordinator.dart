import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/app_dock.dart';
import '../../../app/overlays/reminder_banner.dart';
import '../data/update_providers.dart';
import 'soft_update_sheet.dart';
import 'whats_new_sheet.dart';

/// Coordinates automatic presentation of [WhatsNewSheet] and [SoftUpdateSheet]
/// inside `AppShell`.
///
/// Rules enforced:
/// - Never opens automatic update sheets on the Camera tab
///   (`currentIndex == AppDock.captureIndex`).
/// - Defers presentation while a [ReminderBanner] or `TermsUpdateSheet` is
///   visible, and retries automatically once it clears.
/// - Respects single-sheet priority:
///   `TermsUpdateSheet` > `WhatsNewSheet` > `SoftUpdateSheet`.
/// - Re-evaluates after a snooze window expires or a newer release arrives in
///   a long-lived session.
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

  void _syncPromptGuards(AppUpdateState state) {
    if (!state.canShowWhatsNew) {
      _promptedWhatsNewVersion = null;
    }
    if (state.urgency != UpdateUrgency.softSheet) {
      _promptedSoftVersion = null;
    }
  }

  void _maybeSchedule(
    AppUpdateState state, {
    required bool reminderBlocking,
  }) {
    if (_scheduled ||
        _sheetOpen ||
        !_onBrowseTab ||
        widget.termsSheetBlocking ||
        reminderBlocking ||
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
          ref.read(reminderBannerProvider) != null ||
          (ModalRoute.of(context)?.isCurrent == false)) {
        return;
      }
      final live = ref.read(appUpdateControllerProvider);
      _syncPromptGuards(live);
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
      if (!live.canShowWhatsNew &&
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
    final reminderBlocking = ref.watch(reminderBannerProvider) != null;
    _syncPromptGuards(state);
    if (ModalRoute.of(context)?.isCurrent != false) {
      _maybeSchedule(state, reminderBlocking: reminderBlocking);
    }
    return widget.child;
  }
}
