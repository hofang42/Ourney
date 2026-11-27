import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../ui/ui.dart';
import '../../safety/data/safety_providers.dart'
    show safetyUrlLauncherProvider, supportEmailProvider;
import '../data/update_providers.dart';
import '../l10n/generated/update_localizations.dart';
import 'soft_update_sheet.dart' show shouldShowAndroidSideloadHint;

/// Root host mounted in `OurneyApp.builder` that replaces the app shell and
/// reminder banners with [UpdateGateScreen] whenever
/// [AppUpdateState.urgency] is [UpdateUrgency.forced].
class UpdateGateHost extends ConsumerStatefulWidget {
  const UpdateGateHost({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<UpdateGateHost> createState() => _UpdateGateHostState();
}

class _UpdateGateHostState extends ConsumerState<UpdateGateHost>
    with WidgetsBindingObserver {
  bool _observingBack = false;

  void _syncBackObserver(bool forced) {
    if (forced && !_observingBack) {
      WidgetsBinding.instance.addObserver(this);
      _observingBack = true;
    } else if (!forced && _observingBack) {
      WidgetsBinding.instance.removeObserver(this);
      _observingBack = false;
    }
  }

  @override
  void dispose() {
    if (_observingBack) {
      WidgetsBinding.instance.removeObserver(this);
    }
    super.dispose();
  }

  @override
  Future<bool> didPopRoute() async => true;

  @override
  Widget build(BuildContext context) {
    final forced = ref.watch(
      appUpdateControllerProvider.select(
        (s) => s.urgency == UpdateUrgency.forced,
      ),
    );
    _syncBackObserver(forced);
    if (!forced) return widget.child;

    if (ModalRoute.of(context) != null) {
      return const UpdateGateScreen();
    }
    return HeroControllerScope.none(
      child: Navigator(
        onDidRemovePage: (_) {},
        pages: const [
          MaterialPage<void>(child: UpdateGateScreen()),
        ],
      ),
    );
  }
}

/// Full-screen non-dismissible gate shown when the installed app version is
/// below `min_supported` or requires a major upgrade.
class UpdateGateScreen extends ConsumerStatefulWidget {
  const UpdateGateScreen({super.key});

  @override
  ConsumerState<UpdateGateScreen> createState() => _UpdateGateScreenState();
}

class _UpdateGateScreenState extends ConsumerState<UpdateGateScreen> {
  bool _launching = false;
  bool _showAndroidHint = false;
  bool _launchFailed = false;
  bool _notesExpanded = false;

  UpdatePlatform _resolvePlatform(AppUpdateState state) {
    if (state.platform case final p?) return p;
    return defaultTargetPlatform == TargetPlatform.iOS
        ? UpdatePlatform.ios
        : UpdatePlatform.android;
  }

  Future<void> _handleInstall(AppUpdateState state) async {
    if (_launching) return;
    setState(() {
      _launching = true;
      _launchFailed = false;
    });
    final ok = await ref
        .read(appUpdateControllerProvider.notifier)
        .launchUpdate();
    if (!mounted) return;
    final isAndroid = _resolvePlatform(state) == UpdatePlatform.android;
    setState(() {
      _launching = false;
      _showAndroidHint =
          ok &&
          isAndroid &&
          shouldShowAndroidSideloadHint(state.manifest?.downloadUrl);
      _launchFailed = !ok;
    });
  }

  Future<void> _handleContactSupport() async {
    final email = ref.read(supportEmailProvider);
    final uri = Uri(scheme: 'mailto', path: email);
    try {
      await ref.read(safetyUrlLauncherProvider)(uri);
    } on Object {
      // Quietly ignore if no mail client is configured on the device.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = UpdateL10n.of(context);
    final ui = context.ui;
    final state = ref.watch(appUpdateControllerProvider);
    final installedLabel = state.installedVersion?.precedence ?? '';
    final latestLabel = state.manifest?.latest.precedence ?? '';
    final localeCode = Localizations.localeOf(context).languageCode;
    final notes =
        state.manifest?.notes.forLanguage(localeCode) ?? const <String>[];
    final canInstall = state.manifest?.downloadUrl != null;

    return PopScope(
      canPop: false,
      child: UiScaffold(
        key: const ValueKey('update-gate-screen'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: UiSpace.xl),
            Center(
              child: Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ui.permissionIconBg,
                  shape: BoxShape.circle,
                  border: ui.stickerBorder(),
                  boxShadow: ui.hardShadow(UiShadow.small),
                ),
                child: const OurneyIcon(name: 'sparkle', size: 30),
              ),
            ),
            const SizedBox(height: UiSpace.lg),
            UiEyebrow(
              l10n.update_gateEyebrow(latestLabel),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: UiSpace.xs),
            Semantics(
              header: true,
              child: Text(
                l10n.update_gateTitle,
                textAlign: TextAlign.center,
                style: UiText.h1(color: ui.ink, size: 26),
              ),
            ),
            const SizedBox(height: UiSpace.sm),
            Text(
              l10n.update_gateBody(installedLabel, latestLabel),
              textAlign: TextAlign.center,
              style: UiText.body(
                size: 15,
                height: 1.45,
                color: ui.inkMuted,
              ),
            ),
            if (state.checkFailed) ...[
              const SizedBox(height: UiSpace.lg),
              UiBanner(
                key: const ValueKey('update-gate-offline-banner'),
                message: l10n.update_gateOfflineNotice,
              ),
            ],
            if (notes.isNotEmpty) ...[
              const SizedBox(height: UiSpace.md),
              UiCard(
                key: const ValueKey('update-gate-whats-new-toggle'),
                radius: UiRadius.card,
                shadowOffset: UiShadow.tiny,
                padding: const EdgeInsets.symmetric(
                  horizontal: UiSpace.md,
                  vertical: 12,
                ),
                onPressed: () =>
                    setState(() => _notesExpanded = !_notesExpanded),
                semanticLabel: l10n.update_gateWhatsNewToggle(latestLabel),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const OurneyIcon(
                          name: 'sparkle',
                          size: 18,
                          flat: true,
                        ),
                        const SizedBox(width: UiSpace.sm),
                        Expanded(
                          child: Text(
                            l10n.update_gateWhatsNewToggle(latestLabel),
                            style: UiText.body(
                              size: 14,
                              weight: FontWeight.w700,
                              height: 1.35,
                              color: ui.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: UiSpace.xs),
                        OurneyIcon(
                          name: _notesExpanded ? 'chevron-up' : 'chevron-down',
                          size: 18,
                          flat: true,
                          color: ui.ink,
                        ),
                      ],
                    ),
                    if (_notesExpanded) ...[
                      const SizedBox(height: UiSpace.md),
                      for (final bullet in notes)
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
                  ],
                ),
              ),
            ],
            const SizedBox(height: UiSpace.xl),
            if (canInstall) ...[
              UiButton(
                key: const ValueKey('update-gate-install'),
                label: l10n.update_ctaUpdate,
                loading: _launching,
                glyph: OurneyIcon(
                  name: 'download',
                  size: 20,
                  flat: true,
                  color: ui.onBrand,
                ),
                onPressed: _launching ? null : () => _handleInstall(state),
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
            ] else
              UiCard(
                key: const ValueKey('update-gate-ios-manual-hint'),
                radius: UiRadius.card,
                color: ui.fill,
                shadowOffset: 0,
                padding: const EdgeInsets.all(UiSpace.md),
                child: Text(
                  l10n.update_gateIosManualHint(latestLabel),
                  textAlign: TextAlign.center,
                  style: UiText.body(
                    size: 14,
                    height: 1.4,
                    color: ui.ink,
                  ),
                ),
              ),
            const SizedBox(height: UiSpace.sm),
            UiButton.secondary(
              key: const ValueKey('update-gate-retry'),
              label: l10n.update_ctaRetryCheck,
              loading: state.isChecking,
              glyph: const OurneyIcon(name: 'refresh', size: 18, flat: true),
              onPressed: state.isChecking
                  ? null
                  : () => unawaited(
                      ref
                          .read(appUpdateControllerProvider.notifier)
                          .refresh(manual: true),
                    ),
            ),
            const SizedBox(height: UiSpace.sm),
            UiTextAction(
              key: const ValueKey('update-gate-support'),
              label: l10n.update_ctaContactSupport,
              size: 14,
              color: ui.inkMuted,
              onPressed: _handleContactSupport,
            ),
          ],
        ),
      ),
    );
  }
}
