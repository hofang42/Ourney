import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';

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
      title: l10n.safety_blockedPageTitle,
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
    final cached = ref.watch(blockedNamesProvider);
    final people =
        ref.watch(blockedPeopleProvider).value ??
        const <String, PersonSummary>{};
    // Server names first (fresh device), then the names cached here.
    final names = {
      ...cached,
      for (final p in people.values)
        if (p.displayName.isNotEmpty) p.userId: p.displayName,
    };
    return blocked.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(UiSpace.xxl),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => UiEmptyState(
        key: const ValueKey('safety-blocked-error'),
        glyph: const OurneyIcon(name: 'cloud-off', flat: true),
        title: l10n.safety_loadError,
        actionLabel: l10n.safety_retry,
        onAction: () => ref.invalidate(blockedUserIdsProvider),
      ),
      data: (ids) {
        if (ids.isEmpty) {
          return UiEmptyState(
            key: const ValueKey('safety-blocked-empty'),
            glyph: const OurneyIcon(name: 'shield', flat: true),
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
      leading: UiAvatar(
        name: shown,
        colorIndex: UiAvatar.indexFor(id),
        size: 40,
      ),
      title: shown,
      // Without a cached name every row would read "User": add a short id.
      subtitle: name == null
          ? Text(
              l10n.safety_unknownUserId(
                id.length > 8 ? id.substring(0, 8) : id,
              ),
              key: ValueKey('safety-blocked-id-$id'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: UiText.body(
                size: 12,
                height: 1.4,
                color: context.ui.inkMuted,
              ),
            )
          : null,
      showChevron: false,
      trailing: UiTextAction(
        key: ValueKey('safety-unblock-$id'),
        label: l10n.safety_unblockConfirm,
        onPressed: () => confirmUnblock(context, userId: id, name: name),
      ),
    );
  }
}
