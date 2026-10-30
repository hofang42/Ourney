import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/app_routes.dart';
import '../../../app/providers.dart';
import '../../../ui/ui.dart';
import '../../safety/ui/block_dialogs.dart';
import '../../safety/ui/report_form.dart';
import '../data/social_providers.dart';
import '../l10n/generated/social_localizations.dart';
import '../social_paths.dart';
import 'social_common.dart';

enum InboxFilter { all, replies, invites }

/// SCR-85 `/inbox`: friend requests (Accept / Decline inline), group share
/// consent requests (Agree / Decline), new shares (→ Hub), conversations
/// and, last and without a red dot, "From your public journeys" (S27).
class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  InboxFilter _filter = InboxFilter.all;
  final Set<String> _busy = {};
  final Set<String> _expanded = {};

  Future<void> _act(String key, Future<void> Function() action) async {
    setState(() => _busy.add(key));
    await runSocialAction(context, action);
    if (mounted) setState(() => _busy.remove(key));
  }

  void _respondFriend(PersonSummary p, {required bool accept}) => _act(
    'f:${p.userId}',
    () => ref.read(friendRepositoryProvider).respond(p.userId, accept: accept),
  );

  void _respondConsent(ShareConsent s, {required bool accept}) => _act(
    'c:${s.journeyId}',
    () => ref
        .read(shareConsentRepositoryProvider)
        .respond(s.journeyId, accept: accept),
  );

  void _declineAll(List<Friendship> requests) => _act('all', () async {
    final repo = ref.read(friendRepositoryProvider);
    for (final r in requests) {
      await repo.respond(r.person.userId, accept: false);
    }
  });

  @override
  Widget build(BuildContext context) {
    final l10n = SocialL10n.of(context);
    final localOnly = ref.watch(appConfigProvider).localOnly;
    return SocialScaffold(
      key: const ValueKey('inbox-screen'),
      title: l10n.social_inboxTitle,
      body: localOnly ? const SizedBox.shrink() : _body(context),
    );
  }

  Widget _body(BuildContext context) {
    final l10n = SocialL10n.of(context);
    final friendsAsync = ref.watch(friendshipsProvider);
    final consentsAsync = ref.watch(pendingConsentsProvider);
    final convAsync = ref.watch(conversationsProvider);
    final countsAsync = ref.watch(inboxCountsProvider);

    final loading =
        !friendsAsync.hasValue &&
        !friendsAsync.hasError &&
        !convAsync.hasValue &&
        !convAsync.hasError;
    if (loading) return const SocialLoading();

    final friendships = friendsAsync.value ?? const <Friendship>[];
    final requests = [
      for (final f in friendships)
        if (f.isIncomingRequest && f.source == FriendSource.direct) f,
    ];
    final publicRequests = [
      for (final f in friendships)
        if (f.isIncomingRequest && f.source == FriendSource.publicJourney) f,
    ];
    final consents = [
      for (final s in consentsAsync.value ?? const <ShareConsent>[])
        if (s.status == ShareConsentStatus.pending) s,
    ];
    final conversations = convAsync.value ?? const <Conversation>[];
    final newShares = countsAsync.value?.newShares ?? 0;

    final showInvites = _filter != InboxFilter.replies;
    final showReplies = _filter != InboxFilter.invites;

    final children = <Widget>[];
    if (showInvites && newShares > 0) {
      children
        ..add(SocialSectionLabel(l10n.social_sectionNewShares))
        ..add(_NewSharesRow(count: newShares));
    }
    if (showInvites && requests.isNotEmpty) {
      children.add(SocialSectionLabel(l10n.social_sectionFriendRequests));
      for (final r in requests) {
        final p = r.person;
        final busy = _busy.contains('f:${p.userId}');
        children.add(
          PersonRow(
            key: ValueKey('inbox-request-${p.userId}'),
            person: p,
            unread: true,
            title: l10n.social_friendRequestFrom(displayNameOf(p)),
            subtitle: '@${p.username} · ${socialTime(context, r.createdAt)}',
            actions: [
              UiButton(
                key: ValueKey('inbox-accept-${p.userId}'),
                label: l10n.social_accept,
                compact: true,
                expand: false,
                onPressed: busy ? null : () => _respondFriend(p, accept: true),
              ),
              UiButton.secondary(
                key: ValueKey('inbox-decline-${p.userId}'),
                label: l10n.social_decline,
                compact: true,
                expand: false,
                onPressed: busy ? null : () => _respondFriend(p, accept: false),
              ),
            ],
          ),
        );
      }
    }
    if (showInvites && consents.isNotEmpty) {
      children.add(SocialSectionLabel(l10n.social_sectionConsents));
      for (final s in consents) {
        final busy = _busy.contains('c:${s.journeyId}');
        children.add(
          PersonRow(
            key: ValueKey('inbox-consent-${s.journeyId}'),
            person: s.requestedBy,
            unread: true,
            leading: const UiIconCircle(Icons.groups_outlined),
            title: l10n.social_consentRequest(
              displayNameOf(s.requestedBy),
              s.journeyTitle,
            ),
            actions: [
              UiButton(
                key: ValueKey('consent-agree-${s.journeyId}'),
                label: l10n.social_agree,
                compact: true,
                expand: false,
                onPressed: busy ? null : () => _respondConsent(s, accept: true),
              ),
              UiButton.secondary(
                key: ValueKey('consent-decline-${s.journeyId}'),
                label: l10n.social_decline,
                compact: true,
                expand: false,
                onPressed: busy
                    ? null
                    : () => _respondConsent(s, accept: false),
              ),
            ],
          ),
        );
      }
    }
    if (showReplies && conversations.isNotEmpty) {
      children.add(SocialSectionLabel(l10n.social_sectionConversations));
      for (final conv in conversations) {
        children.add(_ConversationRow(conversation: conv));
      }
    }
    if (showInvites && publicRequests.isNotEmpty) {
      children.add(SocialSectionLabel(l10n.social_sectionPublic));
      final groups = <String, List<Friendship>>{};
      for (final r in publicRequests) {
        groups.putIfAbsent(r.sourceJourneyId ?? '', () => []).add(r);
      }
      for (final entry in groups.entries) {
        children.addAll(_publicGroup(context, entry.key, entry.value));
      }
    }

    if (children.isEmpty) {
      return Column(
        children: [
          _filters(context),
          Expanded(
            child: UiEmptyState(
              key: const ValueKey('inbox-empty'),
              icon: Icons.inbox_outlined,
              title: l10n.social_inboxEmpty,
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        _filters(context),
        Expanded(child: SocialListBody(children: children)),
      ],
    );
  }

  List<Widget> _publicGroup(
    BuildContext context,
    String journeyId,
    List<Friendship> requests,
  ) {
    final l10n = SocialL10n.of(context);
    final ui = context.ui;
    final title =
        requests.first.sourceJourneyTitle ?? l10n.social_publicJourneyFallback;
    final open = _expanded.contains(journeyId);
    return [
      UiPressable(
        key: ValueKey('inbox-public-$journeyId'),
        onPressed: () => setState(() {
          if (!_expanded.remove(journeyId)) _expanded.add(journeyId);
        }),
        borderRadius: BorderRadius.circular(UiRadius.input),
        minSize: const Size(UiSize.tap, 68),
        child: Container(
          constraints: const BoxConstraints(minHeight: 68),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: ui.divider)),
          ),
          child: Row(
            children: [
              const UiIconCircle(Icons.person_add_alt_outlined),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.social_publicSummary(requests.length, title),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.body(
                    size: 15,
                    weight: FontWeight.w700,
                    height: 1.35,
                    color: ui.ink,
                  ),
                ),
              ),
              Icon(
                open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                color: ui.inkMuted,
              ),
            ],
          ),
        ),
      ),
      if (open)
        Container(
          padding: const EdgeInsets.only(left: 14),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: ui.divider, width: 2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final r in requests) _publicRow(context, r),
              UiButton.ghost(
                key: ValueKey('inbox-decline-all-$journeyId'),
                label: l10n.social_declineAll,
                onPressed: _busy.contains('all')
                    ? null
                    : () => _declineAll(requests),
              ),
            ],
          ),
        ),
    ];
  }

  Widget _publicRow(BuildContext context, Friendship r) {
    final l10n = SocialL10n.of(context);
    final p = r.person;
    final busy = _busy.contains('f:${p.userId}') || _busy.contains('all');
    final name = displayNameOf(p);
    return PersonRow(
      key: ValueKey('inbox-public-request-${p.userId}'),
      person: p,
      extraLine: r.sourceJourneyTitle == null
          ? null
          : '${l10n.social_sawJourney(r.sourceJourneyTitle!)}'
                ' · ${socialTime(context, r.createdAt)}',
      actions: [
        UiButton(
          key: ValueKey('inbox-accept-${p.userId}'),
          label: l10n.social_accept,
          compact: true,
          expand: false,
          onPressed: busy ? null : () => _respondFriend(p, accept: true),
        ),
        UiButton.secondary(
          key: ValueKey('inbox-decline-${p.userId}'),
          label: l10n.social_decline,
          compact: true,
          expand: false,
          onPressed: busy ? null : () => _respondFriend(p, accept: false),
        ),
      ],
      trailing: [
        UiIconButton(
          icon: Icons.more_horiz_rounded,
          label: l10n.social_more,
          onPressed: () => showUiSheet<void>(
            context: context,
            builder: (sheet) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                UiMenuItem(
                  label: l10n.social_block,
                  icon: Icons.block_rounded,
                  onPressed: () {
                    Navigator.of(sheet).pop();
                    confirmBlock(context, userId: p.userId, name: name);
                  },
                ),
                UiMenuItem(
                  label: l10n.social_report,
                  icon: Icons.flag_outlined,
                  onPressed: () {
                    Navigator.of(sheet).pop();
                    showReportSheet(context, userId: p.userId, name: name);
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _filters(BuildContext context) {
    final l10n = SocialL10n.of(context);
    final labels = {
      InboxFilter.all: l10n.social_filterAll,
      InboxFilter.replies: l10n.social_filterReplies,
      InboxFilter.invites: l10n.social_filterInvites,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: UiSpace.sm),
      child: SizedBox(
        height: UiSize.tap,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            for (final f in InboxFilter.values)
              Padding(
                padding: const EdgeInsets.only(right: 7),
                child: UiChip(
                  key: ValueKey('inbox-filter-${f.name}'),
                  label: labels[f]!,
                  selected: _filter == f,
                  onPressed: () => setState(() => _filter = f),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NewSharesRow extends StatelessWidget {
  const _NewSharesRow({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = SocialL10n.of(context);
    void open() => context.go(AppRoutes.journeys);
    return UiPersonRow(
      key: const ValueKey('inbox-new-shares'),
      name: '',
      title: l10n.social_newShares(count),
      unread: true,
      leading: const UiIconCircle(Icons.auto_stories_outlined),
      onPressed: open,
      trailing: [
        UiButton.secondary(
          label: l10n.social_view,
          compact: true,
          expand: false,
          onPressed: open,
        ),
      ],
    );
  }
}

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    final l10n = SocialL10n.of(context);
    final ui = context.ui;
    final conv = conversation;
    final unread = conv.unreadCount > 0;
    final name = displayNameOf(conv.other);
    final preview = conv.lastMessageKind == MessageKind.photo
        ? l10n.social_photoMessage
        : conv.lastMessagePreview;
    return UiPersonRow(
      key: ValueKey('inbox-conversation-${conv.id}'),
      name: name,
      title: name,
      subtitle: conv.journeyTitle,
      extraLine: preview == null || preview.isEmpty ? null : preview,
      unread: unread,
      minHeight: 82,
      onPressed: () => context.push(SocialPaths.chat(conv.id)),
      trailing: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (conv.lastMessageAt != null)
              Text(
                socialTime(context, conv.lastMessageAt!),
                style: UiText.body(size: 11, height: 1.3, color: ui.inkMuted),
              ),
            if (unread) ...[
              const SizedBox(height: 4),
              Semantics(
                label: l10n.social_unread(conv.unreadCount),
                excludeSemantics: true,
                child: Container(
                  key: const ValueKey('unread-badge'),
                  constraints: const BoxConstraints(minWidth: 22),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: ui.brand,
                    borderRadius: BorderRadius.circular(UiRadius.capsule),
                  ),
                  child: Text(
                    conv.unreadCount > 99 ? '99+' : '${conv.unreadCount}',
                    textAlign: TextAlign.center,
                    style: UiText.body(
                      size: 11,
                      weight: FontWeight.w800,
                      height: 1.3,
                      color: ui.onBrand,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
