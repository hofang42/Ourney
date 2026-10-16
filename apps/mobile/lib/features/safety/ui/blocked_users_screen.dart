import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/theme/tokens.dart';
import '../../../shared/avatar.dart';
import '../../../shared/empty_state.dart';
import '../../../shared/needs_server_view.dart';
import '../../../shared/ourney_card.dart';
import '../data/safety_providers.dart';
import '../l10n/generated/safety_localizations.dart';
import '../safety_paths.dart';
import 'block_dialogs.dart';
import 'safety_common.dart';

/// `/safety/blocked`: people I blocked, with unblock (FR-F2).
class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = SafetyL10n.of(context);
    final localOnly = ref.watch(appConfigProvider).localOnly;
    return Scaffold(
      key: const ValueKey('safety-blocked'),
      appBar: AppBar(
        leading: BackButton(onPressed: () => closeOr(context, SafetyPaths.hub)),
        title: Text(l10n.safety_hubBlocked),
      ),
      body: SafeArea(
        child: localOnly ? const NeedsServerView() : const _BlockedList(),
      ),
    );
  }
}

class _BlockedList extends ConsumerWidget {
  const _BlockedList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = SafetyL10n.of(context);
    final blocked = ref.watch(blockedUserIdsProvider);
    final names = ref.watch(blockedNamesProvider);
    return blocked.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => EmptyState(
        key: const ValueKey('safety-blocked-error'),
        icon: Icons.cloud_off_rounded,
        title: l10n.safety_loadError,
        actionLabel: l10n.safety_retry,
        onAction: () => ref.invalidate(blockedUserIdsProvider),
      ),
      data: (ids) {
        if (ids.isEmpty) {
          return EmptyState(
            key: const ValueKey('safety-blocked-empty'),
            icon: Icons.shield_outlined,
            title: l10n.safety_blockedEmptyTitle,
            message: l10n.safety_blockedEmptyMessage,
          );
        }
        final sorted = ids.toList()
          ..sort((a, b) => (names[a] ?? '~$a').compareTo(names[b] ?? '~$b'));
        return ListView.separated(
          padding: const EdgeInsets.all(OurneySpacing.screenMargin),
          itemCount: sorted.length,
          separatorBuilder: (_, _) => const SizedBox(height: OurneySpacing.md),
          itemBuilder: (context, i) {
            final id = sorted[i];
            final name = names[id];
            final shown = name ?? l10n.safety_unknownUser;
            return OurneyCard(
              key: ValueKey('safety-blocked-$id'),
              padding: const EdgeInsets.symmetric(
                horizontal: OurneySpacing.lg,
                vertical: OurneySpacing.sm,
              ),
              child: Row(
                children: [
                  Avatar(name: shown, size: 40),
                  const SizedBox(width: OurneySpacing.md),
                  Expanded(
                    child: Text(
                      shown,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  TextButton(
                    key: ValueKey('safety-unblock-$id'),
                    onPressed: () =>
                        confirmUnblock(context, userId: id, name: name),
                    child: Text(l10n.safety_unblockConfirm),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
