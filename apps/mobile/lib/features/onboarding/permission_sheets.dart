import 'package:flutter/material.dart';

import '../../ui/ui.dart';
import 'l10n/generated/onboarding_localizations.dart';

/// App.tsx `CameraPermission`: rationale shown before the OS camera prompt.
/// Resolves to `true` when the person taps "Allow camera", so the caller can
/// go on to request the OS permission.
Future<bool> showCameraPermissionSheet(BuildContext context) {
  final l10n = OnboardingL10n.of(context);
  return showUiPermissionSheet(
    context: context,
    sheetKey: const ValueKey('camera-permission-sheet'),
    primaryKey: const ValueKey('camera-permission-allow'),
    secondaryKey: const ValueKey('camera-permission-later'),
    icon: Icons.photo_camera_outlined,
    title: l10n.onboarding_cameraTitle,
    body: l10n.onboarding_cameraBody,
    primaryLabel: l10n.onboarding_cameraAllow,
    secondaryLabel: l10n.onboarding_notNow,
  );
}

/// App.tsx `NotificationSheet`: offers the daily reminder at [timeLabel]
/// (e.g. "21:00"). Resolves to `true` for "Turn on".
Future<bool> showNotificationSheet(
  BuildContext context, {
  required String timeLabel,
}) {
  final l10n = OnboardingL10n.of(context);
  return showUiPermissionSheet(
    context: context,
    sheetKey: const ValueKey('notification-sheet'),
    primaryKey: const ValueKey('notification-turn-on'),
    secondaryKey: const ValueKey('notification-later'),
    icon: Icons.schedule_rounded,
    title: l10n.onboarding_nudgeTitle(timeLabel),
    primaryLabel: l10n.onboarding_nudgeAllow,
    secondaryLabel: l10n.onboarding_notNow,
  );
}
