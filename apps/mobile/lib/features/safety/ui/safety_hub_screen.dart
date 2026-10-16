import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../app/providers.dart';
import '../../../app/redirect.dart' show AuthStatus;
import '../../../app/theme/tokens.dart';
import '../../../shared/ourney_card.dart';
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
    final text = Theme.of(context).textTheme;
    final c = OurneyColors.of(context);
    final signedIn = ref.watch(authStatusProvider) == AuthStatus.signedIn;

    Widget tile(String key, IconData icon, String title, String path) =>
        ListTile(
          key: ValueKey(key),
          leading: Icon(icon),
          title: Text(title),
          trailing: const Icon(Icons.chevron_right_rounded),
          minTileHeight: OurneySizes.minTap + OurneySpacing.md,
          onTap: () => context.push(path),
        );

    return Scaffold(
      key: const ValueKey('safety-hub'),
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => closeOr(context, AppRoutes.capture),
        ),
        title: Text(l10n.safety_title),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(OurneySpacing.screenMargin),
          children: [
            Text(
              l10n.safety_hubIntro,
              style: text.bodyMedium?.copyWith(color: c.inkMuted),
            ),
            const SizedBox(height: OurneySpacing.xl),
            OurneyCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  tile(
                    'safety-hub-eula',
                    Icons.gavel_rounded,
                    l10n.safety_hubEula,
                    SafetyPaths.eula,
                  ),
                  const Divider(height: 1),
                  tile(
                    'safety-hub-privacy',
                    Icons.privacy_tip_outlined,
                    l10n.safety_hubPrivacy,
                    SafetyPaths.privacy,
                  ),
                  const Divider(height: 1),
                  tile(
                    'safety-hub-contact',
                    Icons.mail_outline_rounded,
                    l10n.safety_hubContact,
                    SafetyPaths.contact,
                  ),
                  // Blocking needs an account (no other users otherwise).
                  if (signedIn) ...[
                    const Divider(height: 1),
                    tile(
                      'safety-hub-blocked',
                      Icons.block_rounded,
                      l10n.safety_hubBlocked,
                      SafetyPaths.blocked,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: OurneySpacing.xl),
            OurneyCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.flag_outlined, color: c.primaryDeep),
                  const SizedBox(width: OurneySpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.safety_hubHowToReport,
                          style: text.titleMedium,
                        ),
                        const SizedBox(height: OurneySpacing.xs),
                        Text(
                          l10n.safety_hubHowToReportBody,
                          style: text.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
