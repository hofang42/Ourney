import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/providers.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/needs_server_view.dart';
import '../../../ui/ui.dart';
import '../../profile/profile_providers.dart' show avatarFileProvider;
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

  static String? _resolvedName(PersonSummary? person, String? cachedName) {
    final display = person?.displayName.trim() ?? '';
    if (display.isNotEmpty) return display;
    final cached = cachedName?.trim() ?? '';
    if (cached.isNotEmpty) return cached;
    final username = person?.username.trim() ?? '';
    if (username.isNotEmpty) return '@$username';
    return null;
  }

  static String? _resolvedHandle(PersonSummary? person) {
    final username = person?.username.trim() ?? '';
    return username.isEmpty ? null : '@$username';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = SafetyL10n.of(context);
    final blocked = ref.watch(blockedUserIdsProvider);
    final cached = ref.watch(blockedNamesProvider);
    final people =
        ref.watch(blockedPeopleProvider).value ??
        const <String, PersonSummary>{};
    // Server names first (fresh device), then the names cached here.
    final names = <String, String>{
      for (final id in {...cached.keys, ...people.keys})
        if (_resolvedName(people[id], cached[id]) case final String resolved)
          id: resolved,
    };
    return blocked.when(
      loading: () => Padding(
        padding: const EdgeInsets.all(UiSpace.xxl),
        child: Center(
          child: UiSpinner(
            semanticsLabel: AppLocalizations.of(context).common_loading,
          ),
        ),
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
            for (final id in sorted)
              _row(
                context,
                ref,
                l10n,
                id,
                person: people[id],
                name: names[id],
              ),
          ],
        );
      },
    );
  }

  Widget _row(
    BuildContext context,
    WidgetRef ref,
    SafetyL10n l10n,
    String id, {
    required PersonSummary? person,
    required String? name,
  }) {
    final shown = name ?? l10n.safety_unknownUser;
    final handle = _resolvedHandle(person);
    final subtitleText = (handle != null && handle != shown)
        ? handle
        : (name == null ? l10n.safety_blockedAccount : null);
    final avatarPath = person?.avatarPath?.trim();
    final storedAvatar = (avatarPath != null && avatarPath.isNotEmpty)
        ? ref.watch(avatarFileProvider(avatarPath)).value
        : null;
    final ImageProvider? avatarImage =
        (storedAvatar != null && storedAvatar.isNotEmpty)
        ? FileImage(File(storedAvatar))
        : null;
    return UiRow(
      key: ValueKey('safety-blocked-$id'),
      leading: UiAvatar(
        name: shown,
        image: avatarImage,
        colorIndex: UiAvatar.indexFor(id),
        size: 40,
      ),
      title: shown,
      subtitle: subtitleText == null
          ? null
          : Text(
              subtitleText,
              key: ValueKey(
                name == null
                    ? 'safety-blocked-fallback-$id'
                    : 'safety-blocked-handle-$id',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: UiText.body(
                size: 12,
                height: 1.4,
                color: context.ui.inkMuted,
              ),
            ),
      showChevron: false,
      trailing: UiTextAction(
        key: ValueKey('safety-unblock-$id'),
        label: l10n.safety_unblockConfirm,
        onPressed: () => confirmUnblock(context, userId: id, name: name),
      ),
    );
  }
}
