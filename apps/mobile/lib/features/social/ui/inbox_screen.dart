import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/app_routes.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../shared/avatar.dart';
import '../../../shared/empty_state.dart';
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
              SocialPill(
                key: ValueKey('inbox-accept-${p.userId}'),
                label: l10n.social_accept,
                onPressed: busy ? null : () => _respondFriend(p, accept: true),
              ),
              SocialPill(
                key: ValueKey('inbox-decline-${p.userId}'),
                label: l10n.social_decline,
                quiet: true,
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
            leading: const _IconCircle(Icons.groups_outlined),
            title: l10n.social_consentRequest(
              displayNameOf(s.requestedBy),
              s.journeyTitle,
            ),
            actions: [
              SocialPill(
                key: ValueKey('consent-agree-${s.journeyId}'),
                label: l10n.social_agree,
                onPressed: busy ? null : () => _respondConsent(s, accept: true),
              ),
              SocialPill(
                key: ValueKey('consent-decline-${s.journeyId}'),
                label: l10n.social_decline,
                quiet: true,
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
            child: EmptyState(
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
    final c = OurneyColors.of(context);
    final title =
        requests.first.sourceJourneyTitle ?? l10n.social_publicJourneyFallback;
    final open = _expanded.contains(journeyId);
    return [
      InkWell(
        key: ValueKey('inbox-public-$journeyId'),
        onTap: () => setState(() {
          if (!_expanded.remove(journeyId)) _expanded.add(journeyId);
        }),
        child: Container(
          constraints: const BoxConstraints(minHeight: 68),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.divider)),
          ),
          child: Row(
            children: [
              const _IconCircle(Icons.person_add_alt_outlined),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.social_publicSummary(requests.length, title),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(height: 1.35),
                ),
              ),
              Icon(
                open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                color: c.inkMuted,
              ),
            ],
          ),
        ),
      ),
      if (open)
        Container(
          padding: const EdgeInsets.only(left: 14),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: c.divider, width: 2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final r in requests) _publicRow(context, r),
              TextButton(
                key: ValueKey('inbox-decline-all-$journeyId'),
                style: TextButton.styleFrom(
                  foregroundColor: c.danger,
                  minimumSize: const Size.fromHeight(OurneySizes.minTap),
                ),
                onPressed: _busy.contains('all')
                    ? null
                    : () => _declineAll(requests),
                child: Text(l10n.social_declineAll),
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
        SocialPill(
          key: ValueKey('inbox-accept-${p.userId}'),
          label: l10n.social_accept,
          onPressed: busy ? null : () => _respondFriend(p, accept: true),
        ),
        SocialPill(
          key: ValueKey('inbox-decline-${p.userId}'),
          label: l10n.social_decline,
          quiet: true,
          onPressed: busy ? null : () => _respondFriend(p, accept: false),
        ),
      ],
      trailing: [
        PopupMenuButton<String>(
          tooltip: l10n.social_more,
          icon: const Icon(Icons.more_horiz_rounded),
          onSelected: (v) {
            if (v == 'block') {
              confirmBlock(context, userId: p.userId, name: name);
            } else {
              showReportSheet(context, userId: p.userId, name: name);
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'block', child: Text(l10n.social_block)),
            PopupMenuItem(value: 'report', child: Text(l10n.social_report)),
          ],
        ),
      ],
    );
  }

  Widget _filters(BuildContext context) {
    final l10n = SocialL10n.of(context);
    final c = OurneyColors.of(context);
    final labels = {
      InboxFilter.all: l10n.social_filterAll,
      InboxFilter.replies: l10n.social_filterReplies,
      InboxFilter.invites: l10n.social_filterInvites,
    };
    return SizedBox(
      height: 64,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          for (final f in InboxFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: 7),
              child: Semantics(
                selected: _filter == f,
                child: TextButton(
                  key: ValueKey('inbox-filter-${f.name}'),
                  onPressed: () => setState(() => _filter = f),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(72, OurneySizes.minTap),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    backgroundColor: _filter == f ? c.ink : c.surface,
                    foregroundColor: _filter == f ? c.bg : c.ink,
                    shape: StadiumBorder(
                      side: BorderSide(color: _filter == f ? c.ink : c.border),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: kBodyFont,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  child: Text(labels[f]!),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _IconCircle extends StatelessWidget {
  const _IconCircle(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = OurneyColors.of(context);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: c.surfaceSunken, shape: BoxShape.circle),
      child: Icon(icon, size: 22, color: c.ink),
    );
  }
}

class _NewSharesRow extends StatelessWidget {
  const _NewSharesRow({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = SocialL10n.of(context);
    final c = OurneyColors.of(context);
    void open() => context.go(AppRoutes.journeys);
    return InkWell(
      key: const ValueKey('inbox-new-shares'),
      onTap: open,
      child: Container(
        constraints: const BoxConstraints(minHeight: 68),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.divider)),
        ),
        child: Row(
          children: [
            Container(
              key: const ValueKey('unread-dot'),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: c.danger,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            const _IconCircle(Icons.auto_stories_outlined),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.social_newShares(count),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(height: 1.35, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 6),
            SocialPill(label: l10n.social_view, quiet: true, onPressed: open),
          ],
        ),
      ),
    );
  }
}

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    final l10n = SocialL10n.of(context);
    final c = OurneyColors.of(context);
    final text = Theme.of(context).textTheme;
    final conv = conversation;
    final unread = conv.unreadCount > 0;
    final name = displayNameOf(conv.other);
    final preview = conv.lastMessageKind == MessageKind.photo
        ? l10n.social_photoMessage
        : conv.lastMessagePreview;
    return InkWell(
      key: ValueKey('inbox-conversation-${conv.id}'),
      onTap: () => context.push(SocialPaths.chat(conv.id)),
      child: Container(
        constraints: const BoxConstraints(minHeight: 82),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.divider)),
        ),
        child: Row(
          children: [
            if (unread) ...[
              Container(
                key: const ValueKey('unread-dot'),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: c.danger,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            ExcludeSemantics(child: Avatar(name: name, size: 40)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleSmall?.copyWith(
                      height: 1.35,
                      fontWeight: unread ? FontWeight.w800 : FontWeight.w700,
                    ),
                  ),
                  Text(
                    conv.journeyTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(height: 1.35),
                  ),
                  if (preview != null && preview.isNotEmpty)
                    Text(
                      preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(
                        height: 1.35,
                        color: unread ? c.ink : c.inkMuted,
                        fontWeight: unread ? FontWeight.w700 : null,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (conv.lastMessageAt != null)
                  Text(
                    socialTime(context, conv.lastMessageAt!),
                    style: text.labelSmall,
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
                        color: c.primary,
                        borderRadius: BorderRadius.circular(
                          OurneyRadii.capsule,
                        ),
                      ),
                      child: Text(
                        conv.unreadCount > 99 ? '99+' : '${conv.unreadCount}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: kBodyFont,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                          color: c.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
