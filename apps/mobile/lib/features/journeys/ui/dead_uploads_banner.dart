import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/data_providers.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../ui/ui.dart';
import '../l10n/generated/journeys_localizations.dart';

/// "N photos couldn't be sent" with Retry and Discard, shown on the journey
/// detail while the outbox has given up on some check-ins.
class DeadUploadsBanner extends ConsumerWidget {
  const DeadUploadsBanner({required this.journeyId, super.key});

  final String journeyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items =
        ref.watch(deadJourneyUploadsProvider(journeyId)).value ?? const [];
    if (items.isEmpty) return const SizedBox.shrink();
    final l10n = JourneysL10n.of(context);
    final dead = ref.read(deadUploadsProvider);
    return Padding(
      key: const ValueKey('dead-uploads-banner'),
      padding: const EdgeInsets.only(bottom: UiSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UiBanner(
            message: l10n.journeys_deadUploads(items.length),
            kind: UiBannerKind.readOnly,
            retryLabel: l10n.journeys_deadRetry,
            onRetry: () => unawaited(dead?.retry(items) ?? Future.value()),
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: UiButton.ghost(
              key: const ValueKey('dead-uploads-discard'),
              label: l10n.journeys_deadDiscard,
              compact: true,
              expand: false,
              onPressed: () async {
                final ok = await showUiConfirmSheet(
                  context: context,
                  title: l10n.journeys_deadDiscardTitle,
                  message: l10n.journeys_deadDiscardBody(items.length),
                  confirmLabel: l10n.journeys_deadDiscard,
                  cancelLabel: AppLocalizations.of(context).common_cancel,
                  destructive: true,
                  sheetKey: const ValueKey('dead-uploads-confirm-sheet'),
                  confirmKey: const ValueKey('dead-uploads-confirm'),
                );
                if (ok) await dead?.discard(items);
              },
            ),
          ),
        ],
      ),
    );
  }
}
