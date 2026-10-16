import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/tokens.dart';
import '../../../shared/chunky_button.dart';
import '../../../shared/ourney_card.dart';
import '../data/safety_providers.dart';
import '../l10n/generated/safety_localizations.dart';
import '../safety_paths.dart';
import 'safety_common.dart';

/// `/safety/contact` (FR-F3).
class ContactScreen extends ConsumerWidget {
  const ContactScreen({super.key});

  Future<void> _send(BuildContext context, WidgetRef ref) async {
    final l10n = SafetyL10n.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri(
      scheme: 'mailto',
      path: kSupportEmail,
      query: 'subject=${Uri.encodeComponent(l10n.safety_contactSubject)}',
    );
    bool opened;
    try {
      opened = await ref.read(safetyUrlLauncherProvider)(uri);
    } on Object {
      opened = false;
    }
    if (!opened) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.safety_contactNoMailApp)),
      );
    }
  }

  Future<void> _copy(BuildContext context) async {
    final l10n = SafetyL10n.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(const ClipboardData(text: kSupportEmail));
    messenger.showSnackBar(SnackBar(content: Text(l10n.safety_contactCopied)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = SafetyL10n.of(context);
    final text = Theme.of(context).textTheme;
    final c = OurneyColors.of(context);
    return Scaffold(
      key: const ValueKey('safety-contact'),
      appBar: AppBar(
        leading: BackButton(onPressed: () => closeOr(context, SafetyPaths.hub)),
        title: Text(l10n.safety_hubContact),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(OurneySpacing.screenMargin),
          children: [
            Text(l10n.safety_contactIntro, style: text.bodyLarge),
            const SizedBox(height: OurneySpacing.xl),
            OurneyCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.safety_contactEmailLabel,
                    style: text.bodySmall?.copyWith(color: c.inkMuted),
                  ),
                  const SizedBox(height: OurneySpacing.xs),
                  SelectableText(
                    kSupportEmail,
                    key: const ValueKey('safety-contact-email'),
                    style: text.titleLarge,
                  ),
                  const SizedBox(height: OurneySpacing.lg),
                  ChunkyButton(
                    key: const ValueKey('safety-contact-send'),
                    label: l10n.safety_contactSend,
                    icon: Icons.mail_rounded,
                    onPressed: () => _send(context, ref),
                  ),
                  const SizedBox(height: OurneySpacing.sm),
                  ChunkyButton(
                    key: const ValueKey('safety-contact-copy'),
                    label: l10n.safety_contactCopy,
                    icon: Icons.copy_rounded,
                    variant: ChunkyVariant.neutral,
                    onPressed: () => _copy(context),
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
