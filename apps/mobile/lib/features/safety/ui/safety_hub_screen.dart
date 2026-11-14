import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../app/providers.dart';
import '../../../app/redirect.dart' show AuthStatus;
import '../../../ui/ui.dart';
import '../l10n/generated/safety_localizations.dart';
import '../safety_paths.dart';
import 'safety_common.dart';

/// `/safety`: entry point to terms, privacy, contact and blocked people.
/// Reachable before sign-in (EULA/privacy/contact must be readable).
class SafetyHubScreen extends ConsumerWidget {
  const SafetyHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = SafetyL10n.of(context);
    final ui = context.ui;
    final signedIn = ref.watch(authStatusProvider) == AuthStatus.signedIn;

    Widget tile(
      String key,
      String icon,
      String title,
      String path, {
      bool divider = true,
    }) => UiRow(
      key: ValueKey(key),
      divider: divider,
      leading: OurneyIcon(name: icon, color: ui.ink, flat: true),
      title: title,
      onPressed: () => context.push(path),
    );

    return SafetyPage(
      pageKey: const ValueKey('safety-hub'),
      title: l10n.safety_title,
      onBack: () => closeOr(context, AppRoutes.capture),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.safety_hubIntro, style: UiText.muted(color: ui.inkMuted)),
          const SizedBox(height: UiSpace.xl),
          UiCard(
            radius: UiRadius.card,
            shadowOffset: UiShadow.small,
            padding: const EdgeInsets.symmetric(horizontal: UiSpace.md),
            child: Column(
              children: [
                tile(
                  'safety-hub-eula',
                  'gavel',
                  l10n.safety_hubEula,
                  SafetyPaths.eula,
                ),
                tile(
                  'safety-hub-privacy',
                  'shield',
                  l10n.safety_hubPrivacy,
                  SafetyPaths.privacy,
                ),
                tile(
                  'safety-hub-contact',
                  'mail',
                  l10n.safety_hubContact,
                  SafetyPaths.contact,
                  divider: signedIn,
                ),
                // Blocking needs an account (no other users otherwise).
                if (signedIn)
                  tile(
                    'safety-hub-blocked',
                    'block',
                    l10n.safety_hubBlocked,
                    SafetyPaths.blocked,
                    divider: false,
                  ),
              ],
            ),
          ),
          const SizedBox(height: UiSpace.xl),
          UiCard(
            radius: UiRadius.card,
            color: ui.fill,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OurneyIcon(name: 'flag', color: ui.ink, flat: true),
                const SizedBox(width: UiSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.safety_hubHowToReport,
                        style: UiText.body(
                          color: ui.ink,
                          weight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: UiSpace.xs),
                      Text(
                        l10n.safety_hubHowToReportBody,
                        style: UiText.muted(color: ui.inkMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
