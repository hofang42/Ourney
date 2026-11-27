import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../ui/ui.dart';
import '../data/update_providers.dart';
import '../l10n/generated/update_localizations.dart';

/// Opens the post-upgrade [WhatsNewSheet].
///
/// When [markSeen] is `true`, closing the sheet records the installed version
/// via [AppUpdateController.markWhatsNewSeen] so automatic presentation only
/// happens once per release.
Future<void> showWhatsNewSheet(
  BuildContext context, {
  SemVer? version,
  List<String>? notes,
  bool markSeen = true,
}) async {
  final container = ProviderScope.containerOf(context, listen: false);
  try {
    await showUiSheet<void>(
      context: context,
      builder: (_) => WhatsNewSheet(
        version: version,
        notes: notes,
        markSeen: markSeen,
      ),
    );
  } finally {
    if (markSeen) {
      unawaited(
        container.read(appUpdateControllerProvider.notifier).markWhatsNewSeen(),
      );
    }
  }
}

/// Post-upgrade bottom sheet celebrating a newly installed Ourney release.
class WhatsNewSheet extends ConsumerWidget {
  const WhatsNewSheet({
    this.version,
    this.notes,
    this.markSeen = true,
    super.key,
  });

  final SemVer? version;
  final List<String>? notes;
  final bool markSeen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = UpdateL10n.of(context);
    final ui = context.ui;
    final state = ref.watch(appUpdateControllerProvider);
    final resolvedVersion =
        version ?? state.installedVersion ?? state.manifest?.latest;
    final versionLabel = resolvedVersion?.precedence ?? '';
    final localeCode = Localizations.localeOf(context).languageCode;
    final bullets =
        notes ??
        (state.installedReleaseNotes ?? state.manifest?.notes)?.forLanguage(
          localeCode,
        ) ??
        const <String>[];

    return Column(
      key: const ValueKey('update-whats-new-sheet'),
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
          l10n.update_whatsNewEyebrow(versionLabel),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: UiSpace.xs),
        Semantics(
          header: true,
          child: Text(
            l10n.update_whatsNewTitle(versionLabel),
            textAlign: TextAlign.center,
            style: UiText.h2(color: ui.ink),
          ),
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
        UiButton(
          key: const ValueKey('update-whats-new-done'),
          label: l10n.update_whatsNewDone,
          onPressed: () async {
            if (markSeen) {
              await ref
                  .read(appUpdateControllerProvider.notifier)
                  .markWhatsNewSeen();
            }
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
      ],
    );
  }
}
