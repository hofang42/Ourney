import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/ui.dart';
import '../data/safety_providers.dart';
import '../l10n/generated/safety_localizations.dart';
import '../safety_paths.dart';
import 'safety_common.dart';

/// `/safety/contact` (FR-F3).
class ContactScreen extends ConsumerWidget {
  const ContactScreen({super.key});

  Future<void> _send(BuildContext context, WidgetRef ref) async {
    final l10n = SafetyL10n.of(context);
    final uri = Uri(
      scheme: 'mailto',
      path: ref.read(supportEmailProvider),
      query: 'subject=${Uri.encodeComponent(l10n.safety_contactSubject)}',
    );
    bool opened;
    try {
      opened = await ref.read(safetyUrlLauncherProvider)(uri);
    } on Object {
      opened = false;
    }
    if (!opened && context.mounted) {
      showUiToast(context, l10n.safety_contactNoMailApp);
    }
  }

  Future<void> _copy(BuildContext context, WidgetRef ref) async {
    final l10n = SafetyL10n.of(context);
    await Clipboard.setData(
      ClipboardData(text: ref.read(supportEmailProvider)),
    );
    if (context.mounted) showUiToast(context, l10n.safety_contactCopied);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = SafetyL10n.of(context);
    final ui = context.ui;
    return SafetyPage(
      pageKey: const ValueKey('safety-contact'),
      title: l10n.safety_hubContact,
      onBack: () => closeOr(context, SafetyPaths.hub),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.safety_contactIntro,
            style: UiText.muted(color: ui.inkMuted),
          ),
          const SizedBox(height: UiSpace.xl),
          UiCard(
            radius: UiRadius.card,
            color: ui.fill,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.safety_contactEmailLabel,
                  style: UiText.fieldLabel(color: ui.inkMuted),
                ),
                const SizedBox(height: UiSpace.xs),
                SelectableText(
                  ref.watch(supportEmailProvider),
                  key: const ValueKey('safety-contact-email'),
                  style: UiText.body(
                    color: ui.ink,
                    size: 18,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: UiSpace.lg),
                UiButton(
                  key: const ValueKey('safety-contact-send'),
                  label: l10n.safety_contactSend,
                  icon: Icons.mail_rounded,
                  onPressed: () => _send(context, ref),
                ),
                const SizedBox(height: UiSpace.sm),
                UiButton.secondary(
                  key: const ValueKey('safety-contact-copy'),
                  label: l10n.safety_contactCopy,
                  icon: Icons.copy_rounded,
                  onPressed: () => _copy(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
