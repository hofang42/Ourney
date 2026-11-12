import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../shared/needs_server_view.dart';
import '../../../ui/ui.dart';
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
    return SafetyPage(
      pageKey: const ValueKey('safety-blocked'),
      title: l10n.safety_hubBlocked,
      onBack: () => closeOr(context, SafetyPaths.hub),
      child: localOnly ? const NeedsServerView() : const _BlockedList(),
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
      loading: () => const Padding(
        padding: EdgeInsets.all(UiSpace.xxl),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => UiEmptyState(
        key: const ValueKey('safety-blocked-error'),
        icon: Icons.cloud_off_rounded,
        title: l10n.safety_loadError,
        actionLabel: l10n.safety_retry,
        onAction: () => ref.invalidate(blockedUserIdsProvider),
      ),
      data: (ids) {
        if (ids.isEmpty) {
          return UiEmptyState(
            key: const ValueKey('safety-blocked-empty'),
            icon: Icons.shield_outlined,
            title: l10n.safety_blockedEmptyTitle,
            body: l10n.safety_blockedEmptyMessage,
          );
        }
        final sorted = ids.toList()
          ..sort((a, b) => (names[a] ?? '~$a').compareTo(names[b] ?? '~$b'));
        return Column(
          children: [
            for (final id in sorted) _row(context, l10n, id, names[id]),
          ],
        );
      },
    );
  }

  Widget _row(BuildContext context, SafetyL10n l10n, String id, String? name) {
    final shown = name ?? l10n.safety_unknownUser;
    return UiRow(
      key: ValueKey('safety-blocked-$id'),
      leading: UiAvatar(name: shown, size: 40),
      title: shown,
      showChevron: false,
      trailing: UiTextAction(
        key: ValueKey('safety-unblock-$id'),
        label: l10n.safety_unblockConfirm,
        onPressed: () => confirmUnblock(context, userId: id, name: name),
      ),
    );
  }
}
