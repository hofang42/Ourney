import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../ui/ui.dart';
import '../camera_session.dart';
import '../l10n/generated/camera_localizations.dart';

// Viewfinder state panels of the camera (moved out of capture_screen.dart):
// the in-context pre-prompt before the OS camera prompt, and one panel per
// CameraFailure (denied, restricted, no hardware, failed to start).

/// Shared layout for the pre-prompt and failure panels: scrolls so it never
/// overflows at large text.
class _Panel extends StatelessWidget {
  const _Panel({
    required this.icon,
    required this.title,
    required this.message,
    required this.actions,
    this.panelKey,
  });

  final Widget icon;
  final String title;
  final String message;
  final List<Widget> actions;
  final Key? panelKey;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return Center(
      key: panelKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(UiSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Container(
                width: UiSize.permissionIcon,
                height: UiSize.permissionIcon,
                decoration: BoxDecoration(
                  color: ui.permissionIconBg,
                  shape: BoxShape.circle,
                ),
                child: Center(child: icon),
              ),
            ),
            const SizedBox(height: UiSpace.lg),
            Semantics(
              header: true,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: UiText.h2(color: ui.ink, size: 20),
              ),
            ),
            const SizedBox(height: UiSpace.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: UiText.muted(color: ui.inkMuted, size: 14),
            ),
            for (final a in actions) ...[const SizedBox(height: UiSpace.md), a],
          ],
        ),
      ),
    );
  }
}

class CameraPrePrompt extends StatelessWidget {
  const CameraPrePrompt({required this.onAccept, super.key});

  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final l10n = CameraL10n.of(context);
    return _Panel(
      panelKey: const ValueKey('capture-pre-prompt'),
      icon: const OurneyIcon(name: 'camera', size: 28),
      title: l10n.camera_prePromptTitle,
      message: l10n.camera_prePromptMessage,
      actions: [
        UiButton(
          label: l10n.camera_prePromptAction,
          onPressed: onAccept,
          expand: false,
        ),
      ],
    );
  }
}

class CameraFailurePanel extends StatelessWidget {
  const CameraFailurePanel({
    required this.failure,
    required this.settingsSupported,
    required this.onOpenSettings,
    required this.onRetry,
    super.key,
  });

  final CameraFailure failure;
  final bool settingsSupported;
  final VoidCallback onOpenSettings;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = CameraL10n.of(context);
    final common = AppLocalizations.of(context);
    final retry = UiButton.secondary(
      key: const ValueKey('capture-retry'),
      label: common.common_retry,
      onPressed: onRetry,
      expand: false,
    );
    final settings = UiButton(
      key: const ValueKey('capture-open-settings'),
      label: l10n.camera_openSettings,
      onPressed: onOpenSettings,
      expand: false,
    );
    final settingsHint = Text(
      l10n.camera_deniedSettingsPath,
      textAlign: TextAlign.center,
      style: UiText.muted(color: context.ui.inkMuted, size: 13),
    );
    switch (failure) {
      case CameraFailure.permissionDenied:
      case CameraFailure.permissionDeniedPermanently:
        return _Panel(
          panelKey: const ValueKey('capture-denied'),
          icon: OurneyIcon(
            name: 'camera',
            flat: true,
            size: 28,
            color: context.ui.ink,
          ),
          title: l10n.camera_deniedTitle,
          message: l10n.camera_deniedMessage,
          actions: [
            if (settingsSupported) settings else settingsHint,
            if (failure == CameraFailure.permissionDenied || !settingsSupported)
              retry,
          ],
        );
      case CameraFailure.restricted:
        return _Panel(
          panelKey: const ValueKey('capture-restricted'),
          icon: OurneyIcon(
            name: 'camera',
            flat: true,
            size: 28,
            color: context.ui.ink,
          ),
          title: l10n.camera_deniedTitle,
          message: l10n.camera_restrictedMessage,
          actions: const [],
        );
      case CameraFailure.unavailable:
        return _Panel(
          panelKey: const ValueKey('capture-unavailable'),
          icon: OurneyIcon(
            name: 'warning',
            flat: true,
            size: 28,
            color: context.ui.ink,
          ),
          title: l10n.camera_unavailableTitle,
          message: l10n.camera_unavailableMessage,
          actions: const [],
        );
      case CameraFailure.failed:
        return _Panel(
          panelKey: const ValueKey('capture-failed'),
          icon: OurneyIcon(
            name: 'warning',
            flat: true,
            size: 28,
            color: context.ui.ink,
          ),
          title: l10n.camera_failedTitle,
          message: common.common_errorGeneric,
          actions: [retry],
        );
    }
  }
}
