import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../ui/ui.dart';
import '../data/social_providers.dart';
import '../l10n/generated/social_localizations.dart';
import '../social_paths.dart';

/// Hub header entry to the inbox (SCR-85, S16): inbox glyph with a red dot
/// when [InboxCounts.hasDot] (public-journey requests never light it, S27).
/// 48dp target. Renders nothing in local-only mode.
class InboxButton extends ConsumerWidget {
  const InboxButton({super.key});

  static const buttonKey = ValueKey('inbox-entry');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(appConfigProvider).localOnly) return const SizedBox.shrink();
    final l10n = SocialL10n.of(context);
    final ui = context.ui;
    final dot = ref.watch(inboxCountsProvider).value?.hasDot ?? false;
    return UiPressable(
      key: buttonKey,
      semanticLabel: dot ? l10n.social_inboxNew : l10n.social_inboxTitle,
      excludeChildSemantics: true,
      centerChild: true,
      onPressed: () => context.push(SocialPaths.inbox),
      child: SizedBox(
        width: 28,
        height: 28,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 24, color: ui.ink),
            if (dot)
              Positioned(
                right: -1,
                top: 0,
                child: Container(
                  key: const ValueKey('inbox-dot'),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: ui.danger,
                    shape: BoxShape.circle,
                    border: Border.all(color: ui.bg, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
