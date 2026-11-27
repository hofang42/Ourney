import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../ui/ui.dart';
import '../data/update_providers.dart';
import '../l10n/generated/update_localizations.dart';

/// Outcome returned when [SoftUpdateSheet] closes.
enum SoftUpdateSheetResult {
  snoozed,
  skipped,
}

/// Whether [downloadUrl] points to an `ourney.tech` or `.apk` download that
/// should show the Android notification-shade sideload hint after launching.
bool shouldShowAndroidSideloadHint(Uri? downloadUrl) {
  if (downloadUrl == null) return false;
  final host = downloadUrl.host.toLowerCase();
  final path = downloadUrl.path.toLowerCase();
  return host == 'ourney.tech' ||
      host == 'www.ourney.tech' ||
      path.endsWith('.apk');
}

/// Opens the gentle [SoftUpdateSheet] for minor updates or manual checks.
///
/// Dismissing the sheet via swipe-down, scrim tap, or system Back (`null`
/// modal result) records a snooze via [AppUpdateController.snoozeSheet]
/// exactly like tapping "Để sau" / "Not now".
Future<SoftUpdateSheetResult> showSoftUpdateSheet(
  BuildContext context, {
  bool fromSettings = false,
  SemVer? version,
}) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final targetVersion =
      version ?? container.read(appUpdateControllerProvider).manifest?.latest;
  final result = await showUiSheet<SoftUpdateSheetResult>(
    context: context,
    builder: (_) => SoftUpdateSheet(
      fromSettings: fromSettings,
      version: targetVersion,
    ),
  );
  if (result == null) {
    await container
        .read(appUpdateControllerProvider.notifier)
        .snoozeSheet(version: targetVersion);
    return SoftUpdateSheetResult.snoozed;
  }
  return result;
}

/// Gentle bottom sheet presenting release notes, install CTA, snooze, and
/// per-version skip action.
class SoftUpdateSheet extends ConsumerStatefulWidget {
  const SoftUpdateSheet({
    this.fromSettings = false,
    this.version,
    super.key,
  });

  /// Hides the one-tap "Skip version" action when opened manually from Settings.
  final bool fromSettings;

  /// Target version captured when the sheet was opened so actions apply to the
  /// displayed release even if a refresh completes in the background.
  final SemVer? version;

  @override
  ConsumerState<SoftUpdateSheet> createState() => _SoftUpdateSheetState();
}

class _SoftUpdateSheetState extends ConsumerState<SoftUpdateSheet> {
  bool _busy = false;
  bool _showAndroidHint = false;
  bool _launchFailed = false;

  UpdatePlatform _resolvePlatform(AppUpdateState state) {
    if (state.platform case final p?) return p;
    return defaultTargetPlatform == TargetPlatform.iOS
        ? UpdatePlatform.ios
        : UpdatePlatform.android;
  }

  Future<void> _handleInstall(AppUpdateState state) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _launchFailed = false;
    });
    final ok = await ref
        .read(appUpdateControllerProvider.notifier)
        .launchUpdate();
    if (!mounted) return;
    final isAndroid = _resolvePlatform(state) == UpdatePlatform.android;
    setState(() {
      _busy = false;
      _showAndroidHint =
          ok &&
          isAndroid &&
          shouldShowAndroidSideloadHint(state.manifest?.downloadUrl);
      _launchFailed = !ok;
    });
  }

  Future<void> _handleLater(SemVer? targetVersion) async {
    if (_busy) return;
    await ref
        .read(appUpdateControllerProvider.notifier)
        .snoozeSheet(version: targetVersion);
    if (!mounted) return;
    Navigator.of(context).pop(SoftUpdateSheetResult.snoozed);
  }

  Future<void> _handleSkip(SemVer? targetVersion) async {
    if (_busy) return;
    await ref
        .read(appUpdateControllerProvider.notifier)
        .skipVersion(version: targetVersion);
    if (!mounted) return;
    Navigator.of(context).pop(SoftUpdateSheetResult.skipped);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = UpdateL10n.of(context);
    final ui = context.ui;
    final state = ref.watch(appUpdateControllerProvider);
    final targetVersion = widget.version ?? state.manifest?.latest;
    final versionLabel = targetVersion?.precedence ?? '';
    final localeCode = Localizations.localeOf(context).languageCode;
    final bullets =
        state.manifest?.notes.forLanguage(localeCode) ?? const <String>[];
    final canInstall = state.manifest?.downloadUrl != null;

    return Column(
      key: const ValueKey('update-soft-sheet'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 56,
            height: 56,
            margin: const EdgeInsets.only(top: 4, bottom: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ui.permissionIconBg,
              shape: BoxShape.circle,
              border: ui.stickerBorder(),
            ),
            child: const OurneyIcon(name: 'sparkle', size: 27),
          ),
        ),
        UiEyebrow(
          l10n.update_softEyebrow(versionLabel),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: UiSpace.xs),
        Semantics(
          header: true,
          child: Text(
            l10n.update_softTitle(versionLabel),
            textAlign: TextAlign.center,
            style: UiText.h2(color: ui.ink),
          ),
        ),
        const SizedBox(height: UiSpace.sm),
        Text(
          l10n.update_softSubtitle,
          textAlign: TextAlign.center,
          style: UiText.muted(
            color: ui.inkMuted,
            size: 14,
          ).copyWith(height: 1.4),
        ),
        if (bullets.isNotEmpty) ...[
          const SizedBox(height: UiSpace.md),
          for (final bullet in bullets)
            Padding(
              padding: const EdgeInsets.only(bottom: UiSpace.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: OurneyIcon(
                      name: 'check',
                      size: 18,
                      flat: true,
                      color: ui.accentText,
                    ),
                  ),
                  const SizedBox(width: UiSpace.sm),
                  Expanded(
                    child: Text(
                      bullet,
                      style: UiText.body(
                        size: 14,
                        height: 1.4,
                        color: ui.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
        const SizedBox(height: UiSpace.lg),
        if (canInstall) ...[
          UiButton(
            key: const ValueKey('update-soft-install'),
            label: l10n.update_ctaUpdate,
            loading: _busy,
            glyph: OurneyIcon(
              name: 'download',
              size: 20,
              flat: true,
              color: ui.onBrand,
            ),
            onPressed: _busy ? null : () => _handleInstall(state),
          ),
          if (_showAndroidHint) ...[
            const SizedBox(height: UiSpace.sm),
            Semantics(
              liveRegion: true,
              child: Text(
                l10n.update_androidInstallHint,
                key: const ValueKey('update-android-install-hint'),
                textAlign: TextAlign.center,
                style: UiText.body(
                  size: 13,
                  height: 1.4,
                  color: ui.inkMuted,
                ),
              ),
            ),
          ],
          if (_launchFailed) ...[
            const SizedBox(height: UiSpace.sm),
            Semantics(
              liveRegion: true,
              child: Text(
                l10n.update_launchFailed,
                key: const ValueKey('update-launch-failed'),
                textAlign: TextAlign.center,
                style: UiText.body(
                  size: 13,
                  height: 1.4,
                  color: ui.warn,
                ),
              ),
            ),
          ],
          const SizedBox(height: UiSpace.sm),
        ],
        UiButton.secondary(
          key: const ValueKey('update-soft-later'),
          label: l10n.update_ctaLater,
          onPressed: _busy ? null : () => _handleLater(targetVersion),
        ),
        if (!widget.fromSettings) ...[
          const SizedBox(height: UiSpace.xs),
          UiTextAction(
            key: const ValueKey('update-soft-skip'),
            label: l10n.update_ctaSkipVersion(versionLabel),
            color: ui.inkMuted,
            size: 14,
            onPressed: _busy ? null : () => _handleSkip(targetVersion),
          ),
        ],
      ],
    );
  }
}
