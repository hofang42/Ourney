import 'package:flutter/material.dart';

import '../../ui/ui.dart';
import 'l10n/generated/onboarding_localizations.dart';

/// V2 `PermissionSheet` (camera): rationale shown before the OS camera
/// prompt. Resolves to `true` when the person taps "Allow", so the caller can
/// go on to request the OS permission.
Future<bool> showCameraPermissionSheet(BuildContext context) {
  final l10n = OnboardingL10n.of(context);
  return _show(
    context,
    UiStickerPermissionContent(
      key: const ValueKey('camera-permission-sheet'),
      primaryKey: const ValueKey('camera-permission-allow'),
      secondaryKey: const ValueKey('camera-permission-later'),
      glyph: const OurneyIcon(
        name: 'camera',
        size: 38,
        inkColor: UiFlowColors.onPastel,
      ),
      title: l10n.onboarding_cameraTitle,
      body: l10n.onboarding_cameraBody,
      primaryLabel: l10n.onboarding_cameraAllow,
      secondaryLabel: l10n.onboarding_notNow,
      closeLabel: l10n.onboarding_permissionClose,
    ),
  );
}

/// V2 `PermissionSheet` (notification): offers the daily reminder at
/// [timeLabel] (e.g. "21:00"). Resolves to `true` for "Allow".
Future<bool> showNotificationSheet(
  BuildContext context, {
  required String timeLabel,
}) {
  final l10n = OnboardingL10n.of(context);
  return _show(
    context,
    UiStickerPermissionContent(
      key: const ValueKey('notification-sheet'),
      primaryKey: const ValueKey('notification-turn-on'),
      secondaryKey: const ValueKey('notification-later'),
      glyph: const OurneyIcon(
        name: 'heart',
        size: 38,
        inkColor: UiFlowColors.onPastel,
      ),
      title: l10n.onboarding_nudgeTitle,
      body: l10n.onboarding_nudgeBody(timeLabel),
      primaryLabel: l10n.onboarding_nudgeAllow,
      secondaryLabel: l10n.onboarding_notNow,
      closeLabel: l10n.onboarding_permissionClose,
    ),
  );
}

Future<bool> _show(BuildContext context, Widget content) async {
  // The V2 sheet keeps the brand-orange top shadow in every journey skin.
  final result = await showUiSheet<bool>(
    context: context,
    accent: context.ui.brand,
    builder: (_) => content,
  );
  return result ?? false;
}
