import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/providers.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../ui/ui.dart';
import '../../safety/ui/block_dialogs.dart';
import '../../safety/ui/report_form.dart';
import '../data/social_providers.dart';
import '../l10n/generated/social_localizations.dart';
import '../social_paths.dart';
import 'social_common.dart';

/// SCR-80 `/friends`: pending requests (incoming Accept / Decline, outgoing
/// Cancel) and the friends list. The count is shown only here, to the
/// account owner (S4).
class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  /// Above this many friends a filter field is shown (docs/07 §5.8).
  static const searchThreshold = 10;

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  final Set<String> _busy = {};
  String _filter = '';
  final _filterController = TextEditingController();

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  Future<void> _act(String userId, Future<void> Function() action) async {
    setState(() => _busy.add(userId));
    await runSocialAction(context, action);
    if (mounted) setState(() => _busy.remove(userId));
  }

  void _respond(PersonSummary p, {required bool accept}) => _act(
    p.userId,
    () => ref.read(friendRepositoryProvider).respond(p.userId, accept: accept),
  );

  void _cancel(PersonSummary p) =>
      _act(p.userId, () => ref.read(friendRepositoryProvider).remove(p.userId));

  @override
  Widget build(BuildContext context) {
    final l10n = SocialL10n.of(context);
    final localOnly = ref.watch(appConfigProvider).localOnly;
    final async = localOnly ? null : ref.watch(friendshipsProvider);
    final list = async?.value;
    final friends = [
      for (final f in list ?? const <Friendship>[])
        if (f.isFriend) f,
    ];

    Widget body;
    if (async == null) {
      body = const SizedBox.shrink();
    } else if (list != null) {
      body = _body(context, list, friends);
    } else if (async.hasError) {
      body = UiEmptyState(
        key: const ValueKey('friends-error'),
        icon: Icons.error_outline_rounded,
        title: socialErrorMessage(context, async.error!),
        actionLabel: AppLocalizations.of(context).common_retry,
        onAction: () => ref.invalidate(friendshipsProvider),
      );
    } else {
      body = const SocialLoading();
    }

    return SocialScaffold(
      key: const ValueKey('friends-screen'),
      title: l10n.social_friendsTitle,
      subtitle: list == null
          ? null
          : l10n.social_friendsSubtitle(friends.length),
      action: SocialHeaderAction(
        key: const ValueKey('friends-add'),
        icon: Icons.person_add_alt_1_outlined,
        label: l10n.social_add,
        onPressed: () => context.push(SocialPaths.friendsAdd),
      ),
      body: body,
    );
  }

  Widget _body(
    BuildContext context,
    List<Friendship> all,
    List<Friendship> friends,
  ) {
    final l10n = SocialL10n.of(context);
    final ui = context.ui;
    final requests = [
      for (final f in all)
        if (!f.isFriend) f,
    ];
    if (all.isEmpty) {
      return UiEmptyState(
        key: const ValueKey('friends-empty'),
        icon: Icons.people_outline_rounded,
        title: l10n.social_emptyFriendsTitle,
        actionLabel: l10n.social_addFriends,
        onAction: () => context.push(SocialPaths.friendsAdd),
      );
    }
    final query = _filter.trim().toLowerCase();
    final shown = query.isEmpty
        ? friends
        : [
            for (final f in friends)
              if (f.person.displayName.toLowerCase().contains(query) ||
                  f.person.username.toLowerCase().contains(query))
                f,
          ];

    return SocialListBody(
      children: [
        SocialSectionLabel(l10n.social_requests),
        if (requests.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: UiSpace.sm),
            child: Text(
              l10n.social_noRequests,
              style: UiText.muted(size: 13, color: ui.inkMuted),
            ),
          ),
        for (final r in requests) _requestRow(context, r),
        if (friends.isNotEmpty) ...[
          SocialSectionLabel(l10n.social_friendsTitle),
          if (friends.length > FriendsScreen.searchThreshold)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: UiSpace.sm),
              child: UiTextField(
                fieldKey: const ValueKey('friends-filter'),
                label: l10n.social_searchFriends,
                hint: l10n.social_searchFriends,
                controller: _filterController,
                onChanged: (v) => setState(() => _filter = v),
              ),
            ),
          for (final f in shown)
            PersonRow(
              key: ValueKey('friend-${f.person.userId}'),
              person: f.person,
              onTap: () => showFriendSheet(context, f.person),
              trailing: [
                Icon(Icons.chevron_right_rounded, size: 20, color: ui.chevron),
              ],
            ),
        ],
      ],
    );
  }

  Widget _requestRow(BuildContext context, Friendship r) {
    final l10n = SocialL10n.of(context);
    final p = r.person;
    final busy = _busy.contains(p.userId);
    final fromPublic =
        r.source == FriendSource.publicJourney && r.sourceJourneyTitle != null
        ? l10n.social_sawJourney(r.sourceJourneyTitle!)
        : null;
    if (r.direction == FriendDirection.incoming) {
      return PersonRow(
        key: ValueKey('request-${p.userId}'),
        person: p,
        extraLine: fromPublic,
        actions: [
          UiButton(
            key: ValueKey('accept-${p.userId}'),
            label: l10n.social_accept,
            compact: true,
            expand: false,
            onPressed: busy ? null : () => _respond(p, accept: true),
          ),
          UiButton.secondary(
            key: ValueKey('decline-${p.userId}'),
            label: l10n.social_decline,
            compact: true,
            expand: false,
            onPressed: busy ? null : () => _respond(p, accept: false),
          ),
        ],
      );
    }
    return PersonRow(
      key: ValueKey('request-${p.userId}'),
      person: p,
      extraLine: l10n.social_requested,
      trailing: [
        UiButton.secondary(
          key: ValueKey('cancel-${p.userId}'),
          label: l10n.social_cancelRequest,
          compact: true,
          expand: false,
          onPressed: busy ? null : () => _cancel(p),
        ),
      ],
    );
  }
}

/// Friend sheet: Message (when a conversation exists), Remove friend
/// (confirmed), Block, Report.
Future<void> showFriendSheet(BuildContext context, PersonSummary person) {
  return showUiSheet<void>(
    context: context,
    builder: (_) => _FriendSheet(person: person, hostContext: context),
  );
}

class _FriendSheet extends ConsumerWidget {
  const _FriendSheet({required this.person, required this.hostContext});

  final PersonSummary person;

  /// The screen under the sheet (dialogs and toasts outlive the sheet).
  final BuildContext hostContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = SocialL10n.of(context);
    final ui = context.ui;
    final name = displayNameOf(person);
    final conversations = ref.watch(conversationsProvider).value;
    Conversation? conversation;
    for (final conv in conversations ?? const <Conversation>[]) {
      if (conv.other.userId == person.userId) {
        conversation = conv;
        break;
      }
    }

    return Column(
      key: const ValueKey('friend-sheet'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            ExcludeSemantics(
              child: UiAvatar(
                name: name,
                colorIndex: UiAvatar.indexFor(name),
                size: 48,
                ring: false,
              ),
            ),
            const SizedBox(width: UiSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: UiText.h2(size: 20, color: ui.ink),
                  ),
                  Text(
                    '@${person.username}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: UiText.muted(size: 13, color: ui.inkMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: UiSpace.lg),
        if (conversation != null)
          UiMenuItem(
            key: const ValueKey('friend-message'),
            icon: Icons.chat_bubble_outline_rounded,
            label: l10n.social_message,
            onPressed: () {
              Navigator.of(context).pop();
              hostContext.push(SocialPaths.chat(conversation!.id));
            },
          ),
        UiMenuItem(
          key: const ValueKey('friend-remove'),
          icon: Icons.person_remove_outlined,
          label: l10n.social_removeFriend,
          destructive: true,
          onPressed: () async {
            // The sheet (and its ref) is gone after pop.
            final repo = ref.read(friendRepositoryProvider);
            Navigator.of(context).pop();
            final ok = await confirmSocialAction(
              hostContext,
              title: l10n.social_removeFriendTitle(name),
              message: l10n.social_removeFriendBody,
              confirmLabel: l10n.social_removeFriend,
              destructive: true,
            );
            if (!ok || !hostContext.mounted) return;
            final done = await runSocialAction(
              hostContext,
              () => repo.remove(person.userId),
            );
            if (done && hostContext.mounted) {
              showSocialSnack(hostContext, l10n.social_removed(name));
            }
          },
        ),
        UiMenuItem(
          key: const ValueKey('friend-block'),
          icon: Icons.block_rounded,
          label: l10n.social_block,
          onPressed: () {
            Navigator.of(context).pop();
            confirmBlock(hostContext, userId: person.userId, name: name);
          },
        ),
        UiMenuItem(
          key: const ValueKey('friend-report'),
          icon: Icons.flag_outlined,
          label: l10n.social_report,
          onPressed: () {
            Navigator.of(context).pop();
            showReportSheet(hostContext, userId: person.userId, name: name);
          },
        ),
      ],
    );
  }
}
