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

    Widget tile(String key, IconData icon, String title, String path) => UiRow(
      key: ValueKey(key),
      leading: Icon(icon, color: ui.ink),
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
          tile(
            'safety-hub-eula',
            Icons.gavel_rounded,
            l10n.safety_hubEula,
            SafetyPaths.eula,
          ),
          tile(
            'safety-hub-privacy',
            Icons.privacy_tip_outlined,
            l10n.safety_hubPrivacy,
            SafetyPaths.privacy,
          ),
          tile(
            'safety-hub-contact',
            Icons.mail_outline_rounded,
            l10n.safety_hubContact,
            SafetyPaths.contact,
          ),
          // Blocking needs an account (no other users otherwise).
          if (signedIn)
            tile(
              'safety-hub-blocked',
              Icons.block_rounded,
              l10n.safety_hubBlocked,
              SafetyPaths.blocked,
            ),
          const SizedBox(height: UiSpace.xl),
          UiCard(
            radius: UiRadius.card,
            color: ui.fill,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.flag_outlined, color: ui.ink),
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
