import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/app_routes.dart';
import '../../../app/redirect.dart' show safeFrom;
import '../../../app/theme/tokens.dart';
import '../../../shared/chunky_button.dart';
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
    final text = Theme.of(context).textTheme;
    final (title, sections) = switch (document) {
      LegalDocument.eula => (l10n.safety_hubEula, eulaSections(l10n)),
      LegalDocument.privacy => (l10n.safety_hubPrivacy, privacySections(l10n)),
    };
    return Scaffold(
      key: ValueKey('safety-${document.name}'),
      appBar: AppBar(
        leading: BackButton(onPressed: () => closeOr(context, SafetyPaths.hub)),
        title: Text(title),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(OurneySpacing.screenMargin),
          children: [
            Text(
              _lastUpdated(context, l10n),
              style: text.bodySmall?.copyWith(
                color: OurneyColors.of(context).inkMuted,
              ),
            ),
            const SizedBox(height: OurneySpacing.lg),
            for (final (t, b) in sections) LegalSection(title: t, body: b),
          ],
        ),
      ),
    );
  }
}

/// `/safety/eula/accept?from=<path>`: the EULA acceptance gate (FR-F3).
/// Accepting stores `safety.eulaAccepted` and continues to the `from`
/// target (or the camera).
class EulaAcceptScreen extends ConsumerStatefulWidget {
  const EulaAcceptScreen({this.from, super.key});

  /// Raw `?from=` value; only safe in-app paths are followed.
  final Uri? from;

  @override
  ConsumerState<EulaAcceptScreen> createState() => _EulaAcceptScreenState();
}

class _EulaAcceptScreenState extends ConsumerState<EulaAcceptScreen> {
  bool _checked = false;

  Future<void> _accept() async {
    await ref.read(eulaAcceptedProvider.notifier).accept();
    if (!mounted) return;
    final from = widget.from;
    final target = from == null ? null : safeFrom(from);
    context.go(target ?? AppRoutes.capture);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = SafetyL10n.of(context);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      key: const ValueKey('safety-eula-accept'),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(l10n.safety_eulaAcceptTitle),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(OurneySpacing.screenMargin),
                children: [
                  Text(l10n.safety_eulaAcceptIntro, style: text.bodyLarge),
                  const SizedBox(height: OurneySpacing.xl),
                  for (final (t, b) in eulaSections(l10n))
                    LegalSection(title: t, body: b),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      key: const ValueKey('safety-eula-accept-privacy'),
                      onPressed: () => context.push(SafetyPaths.privacy),
                      icon: const Icon(Icons.privacy_tip_outlined),
                      label: Text(l10n.safety_hubPrivacy),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(OurneySpacing.lg),
              child: Column(
                children: [
                  CheckboxListTile(
                    key: const ValueKey('safety-eula-checkbox'),
                    value: _checked,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(l10n.safety_eulaAcceptCheckbox),
                    onChanged: (v) => setState(() => _checked = v ?? false),
                  ),
                  const SizedBox(height: OurneySpacing.sm),
                  ChunkyButton(
                    key: const ValueKey('safety-eula-accept-button'),
                    label: l10n.safety_eulaAcceptButton,
                    onPressed: _checked ? _accept : null,
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
