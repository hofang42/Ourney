import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../ui/ui.dart';
import '../data/safety_providers.dart';
import '../l10n/generated/safety_localizations.dart';
import '../safety_paths.dart';
import 'safety_common.dart';

/// EULA sections in order (FR-F3: zero tolerance, Apple Guideline 1.2).
List<(String, String)> eulaSections(SafetyL10n l10n) => [
  (l10n.safety_eula1Title, l10n.safety_eula1Body),
  (l10n.safety_eula2Title, l10n.safety_eula2Body),
  (l10n.safety_eula3Title, l10n.safety_eula3Body),
  (l10n.safety_eula4Title, l10n.safety_eula4Body),
  (l10n.safety_eula5Title, l10n.safety_eula5Body),
  (l10n.safety_eula6Title, l10n.safety_eula6Body),
];

List<(String, String)> privacySections(SafetyL10n l10n) => [
  (l10n.safety_privacy1Title, l10n.safety_privacy1Body),
  (l10n.safety_privacy2Title, l10n.safety_privacy2Body),
  (l10n.safety_privacy3Title, l10n.safety_privacy3Body),
  (l10n.safety_privacy4Title, l10n.safety_privacy4Body),
  (l10n.safety_privacy5Title, l10n.safety_privacy5Body),
  (l10n.safety_privacy6Title, l10n.safety_privacy6Body),
];

String _lastUpdated(BuildContext context, SafetyL10n l10n) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  return l10n.safety_lastUpdated(
    DateFormat.yMd(locale).format(kLegalLastUpdated),
  );
}

enum LegalDocument { eula, privacy }

/// `/safety/eula` and `/safety/privacy`.
class LegalScreen extends StatelessWidget {
  const LegalScreen({required this.document, super.key});

  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    final l10n = SafetyL10n.of(context);
    final ui = context.ui;
    final (title, sections) = switch (document) {
      LegalDocument.eula => (l10n.safety_eulaPageTitle, eulaSections(l10n)),
      LegalDocument.privacy => (
        l10n.safety_privacyPageTitle,
        privacySections(l10n),
      ),
    };
    return SafetyPage(
      pageKey: ValueKey('safety-${document.name}'),
      title: title,
      onBack: () => closeOr(context, SafetyPaths.hub),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _lastUpdated(context, l10n),
            style: UiText.muted(color: ui.inkMuted, size: 13),
          ),
          const SizedBox(height: UiSpace.lg),
          for (final (t, b) in sections) LegalSection(title: t, body: b),
        ],
      ),
    );
  }
}

/// Shows the compact dismissible bottom sheet when an existing account signed
/// in with an older server `terms_version` (`0 < terms_version < kTermsVersion`).
Future<bool?> showTermsUpdateSheet(BuildContext context) => showUiSheet<bool>(
  context: context,
  dismissible: true,
  builder: (_) => const TermsUpdateSheet(),
);

/// Compact bottom sheet shown from `AppShell` when `kTermsVersion` bumps for
/// an existing account (`0 < server terms_version < kTermsVersion`).
class TermsUpdateSheet extends ConsumerStatefulWidget {
  const TermsUpdateSheet({super.key});

  @override
  ConsumerState<TermsUpdateSheet> createState() => _TermsUpdateSheetState();
}

class _TermsUpdateSheetState extends ConsumerState<TermsUpdateSheet> {
  bool _busy = false;

  Future<void> _accept() async {
    if (_busy) return;
    setState(() => _busy = true);
    await ref.read(eulaAcceptedProvider.notifier).accept();
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = SafetyL10n.of(context);
    final ui = context.ui;
    final bullets = [
      l10n.safety_termsUpdateBullet1,
      l10n.safety_termsUpdateBullet2,
    ];
    return Column(
      key: const ValueKey('safety-terms-update-sheet'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.safety_termsUpdateTitle,
            style: UiText.h2(color: ui.ink),
          ),
        ),
        const SizedBox(height: UiSpace.xs),
        Text(
          l10n.safety_termsUpdateIntro,
          style: UiText.muted(color: ui.inkMuted, size: 14),
        ),
        const SizedBox(height: UiSpace.sm),
        for (final b in bullets) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: UiSpace.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: OurneyIcon(
                    name: 'check',
                    size: 18,
                    flat: true,
                    color: ui.ink,
                  ),
                ),
                const SizedBox(width: UiSpace.sm),
                Expanded(
                  child: Text(
                    b,
                    style: UiText.body(
                      size: 14,
                      height: 1.35,
                      color: ui.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        Wrap(
          spacing: UiSpace.md,
          children: [
            UiTextAction(
              key: const ValueKey('safety-terms-update-eula'),
              label: l10n.safety_hubEula,
              size: 13,
              underline: true,
              color: ui.ink,
              expand: false,
              onPressed: () => context.push(SafetyPaths.eula),
            ),
            UiTextAction(
              key: const ValueKey('safety-terms-update-privacy'),
              label: l10n.safety_hubPrivacy,
              size: 13,
              underline: true,
              color: ui.ink,
              expand: false,
              onPressed: () => context.push(SafetyPaths.privacy),
            ),
          ],
        ),
        const SizedBox(height: UiSpace.sm),
        UiButton(
          key: const ValueKey('safety-terms-update-accept'),
          label: l10n.safety_termsUpdateAccept,
          loading: _busy,
          onPressed: _busy ? null : _accept,
        ),
        const SizedBox(height: UiSpace.xs),
        UiButton.ghost(
          key: const ValueKey('safety-terms-update-later'),
          label: l10n.safety_termsUpdateLater,
          compact: true,
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}
