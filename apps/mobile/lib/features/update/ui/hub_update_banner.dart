import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/ui.dart';
import '../data/update_providers.dart';
import '../l10n/generated/update_localizations.dart';
import 'soft_update_sheet.dart';

/// Quiet inline update notice card rendered inside the Journeys hub notices.
class HubUpdateBanner extends ConsumerWidget {
  const HubUpdateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appUpdateControllerProvider);
    final manifest = state.manifest;
    if (!state.showHubBanner || manifest == null) {
      return const SizedBox.shrink();
    }

    final l10n = UpdateL10n.of(context);
    final ui = context.ui;
    final latest = manifest.latest;
    final versionLabel = latest.precedence;
    final localeCode = Localizations.localeOf(context).languageCode;
    final notes = manifest.notes.forLanguage(localeCode);
    final summary =
        notes.isNotEmpty ? notes.first : l10n.update_hubFallbackSub;

    return UiCard(
      key: const ValueKey('hub-update-banner'),
      radius: UiRadius.card,
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      child: Row(
        children: [
          const OurneyIcon(name: 'sparkle', size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.update_hubTitle(versionLabel),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.body(
                    size: 14,
                    weight: FontWeight.w800,
                    height: 1.35,
                    color: ui.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.body(
                    size: 13,
                    height: 1.4,
                    color: ui.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          UiTextAction(
            key: const ValueKey('hub-update-banner-view'),
            label: l10n.update_hubAction,
            size: 14,
            color: ui.ink,
            expand: false,
            onPressed: () => unawaited(
              showSoftUpdateSheet(context, version: latest),
            ),
          ),
          UiIconButton(
            key: const ValueKey('hub-update-banner-dismiss'),
            label: l10n.update_hubDismissLabel,
            glyph: OurneyIcon(
              name: 'close',
              size: 18,
              flat: true,
              color: ui.inkMuted,
            ),
            onPressed: () => unawaited(
              ref
                  .read(appUpdateControllerProvider.notifier)
                  .dismissHubBanner(version: latest),
            ),
          ),
        ],
      ),
    );
  }
}
