import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/app_routes.dart';
import '../../../app/providers.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../ui/ui.dart';
import '../../safety/ui/block_dialogs.dart';
import '../../safety/ui/report_form.dart';
import '../data/social_providers.dart';
import '../l10n/generated/social_localizations.dart';
import '../social_paths.dart';
import 'social_common.dart';

enum InboxFilter { all, replies, invites }

/// V2 ActivityScreen (SCR-85 `/inbox`, the "Hoạt động" dock tab): a feed
/// grouped "Hôm nay" / "Trước đó" of friend requests (Accept / Decline
/// inline), group share consent requests (Agree / Decline), new shares
/// (→ Hub), conversations and, without a red dot, "From your public
/// journeys" (S27). Shows a back button only when pushed standalone.
class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  InboxFilter _filter = InboxFilter.all;
  final Set<String> _busy = {};
  final Set<String> _expanded = {};

  /// Ids of unread items marked as read with "mark all read" (this session).
  final Set<String> _seen = {};

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

  void _retry() {
    ref
      ..invalidate(friendshipsProvider)
      ..invalidate(pendingConsentsProvider)
      ..invalidate(conversationsProvider)
      ..invalidate(inboxCountsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = SocialL10n.of(context);
    final app = AppLocalizations.of(context);
    final localOnly = ref.watch(appConfigProvider).localOnly;
    return UiScaffold(
      key: const ValueKey('inbox-screen'),
      scroll: false,
      padTop: 0,
      padBottom: 0,
      child: Column(
        children: [
          UiTopBar(
            title: l10n.social_activityTitle,
            leading: context.canPop()
                ? UiIconButton(
                    key: const ValueKey('social-back'),
                    icon: Icons.arrow_back_rounded,
                    label: MaterialLocalizations.of(context).backButtonTooltip,
                    onPressed: () => socialBack(context),
                  )
                : null,
          ),
          Expanded(
            child: localOnly
                ? UiEmptyState(
                    key: const ValueKey('needs-server'),
                    glyph: const OurneyIcon(name: 'cloud-off', size: 40),
                    title: app.needsServer_title,
                    body: app.needsServer_message,
                  )
                : _body(context),
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    final l10n = SocialL10n.of(context);
    final app = AppLocalizations.of(context);
    final friendsAsync = ref.watch(friendshipsProvider);
    final consentsAsync = ref.watch(pendingConsentsProvider);
    final convAsync = ref.watch(conversationsProvider);
    final countsAsync = ref.watch(inboxCountsProvider);

    final loading =
        !friendsAsync.hasValue &&
        !friendsAsync.hasError &&
        !convAsync.hasValue &&
        !convAsync.hasError;
    if (loading) return _Skeleton(label: app.common_loading);
    if (!friendsAsync.hasValue &&
        !convAsync.hasValue &&
        (friendsAsync.hasError || convAsync.hasError)) {
      final error = friendsAsync.error ?? convAsync.error!;
      final offline = socialErrorCode(error) == OurneyErrorCode.offline;
      return ListView(
        padding: const EdgeInsets.only(top: UiSpace.lg),
        children: [
          UiStateCard(
            key: const ValueKey('inbox-error'),
            kind: offline ? UiStateCardKind.offline : UiStateCardKind.error,
            title: socialErrorMessage(context, error),
            actionLabel: app.common_retry,
            onAction: _retry,
          ),
        ],
      );
    }

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

    final items = <_FeedItem>[];
    if (showInvites && newShares > 0) {
      items.add(
        _FeedItem(
          id: 'shares',
          unread: true,
          build: (unread) => _newSharesCard(newShares, unread),
        ),
      );
    }
    if (showInvites) {
      for (final r in requests) {
        items.add(
          _FeedItem(
            id: 'f:${r.person.userId}',
            at: r.createdAt,
            unread: true,
            build: (unread) => _requestCard(r, unread),
          ),
        );
      }
      for (final s in consents) {
        items.add(
          _FeedItem(
            id: 'c:${s.journeyId}',
            unread: true,
            build: (unread) => _consentCard(s, unread),
          ),
        );
      }
    }
    if (showReplies) {
      for (final conv in conversations) {
        items.add(
          _FeedItem(
            id: 'm:${conv.id}',
            at: conv.lastMessageAt,
            unread: conv.unreadCount > 0,
            build: (unread) =>
                _ConversationRow(conversation: conv, showUnread: unread),
          ),
        );
      }
    }
    if (showInvites) {
      final groups = <String, List<Friendship>>{};
      for (final r in publicRequests) {
        groups.putIfAbsent(r.sourceJourneyId ?? '', () => []).add(r);
      }
      for (final entry in groups.entries) {
        items.add(
          _FeedItem(
            id: 'p:${entry.key}',
            at: entry.value
                .map((r) => r.createdAt)
                .reduce((a, b) => a.isAfter(b) ? a : b),
            unread: false,
            build: (_) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _publicGroup(context, entry.key, entry.value),
            ),
          ),
        );
      }
    }

    final now = DateTime.now();
    bool isToday(DateTime? at) {
      if (at == null) return true;
      final l = at.toLocal();
      return l.year == now.year && l.month == now.month && l.day == now.day;
    }

    final today = [
      for (final i in items)
        if (isToday(i.at)) i,
    ];
    final earlier = [
      for (final i in items)
        if (!isToday(i.at)) i,
    ]..sort((a, b) => b.at!.compareTo(a.at!));
    final hasUnread = items.any((i) => i.unread && !_seen.contains(i.id));

    final children = <Widget>[];
    void group(String title, List<_FeedItem> list, {required bool first}) {
      if (list.isEmpty) return;
      final showMark = first && hasUnread;
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: UiSpace.lg, bottom: UiSpace.sm),
          child: UiListHeading(
            title: title,
            actionLabel: showMark ? l10n.social_markAllRead : null,
            onAction: showMark
                ? () => setState(() {
                    _seen.addAll([
                      for (final i in items)
                        if (i.unread) i.id,
                    ]);
                  })
                : null,
          ),
        ),
      );
      for (final i in list) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: UiSpace.md),
            child: i.build(i.unread && !_seen.contains(i.id)),
          ),
        );
      }
    }

    group(l10n.social_groupToday, today, first: true);
    group(l10n.social_groupEarlier, earlier, first: today.isEmpty);

    if (children.isEmpty) {
      return Column(
        children: [
          _filters(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: UiSpace.lg),
              children: [
                UiStateCard(
                  key: const ValueKey('inbox-empty'),
                  kind: UiStateCardKind.empty,
                  title: l10n.social_inboxEmpty,
                ),
                const SizedBox(height: UiSpace.lg),
                const _InviteCard(),
              ],
            ),
          ),
        ],
      );
    }
    children.add(const _InviteCard());
    return Column(
      children: [
        _filters(context),
        Expanded(child: SocialListBody(children: children)),
      ],
    );
  }

  Widget _newSharesCard(int count, bool unread) {
    final l10n = SocialL10n.of(context);
    void open() => context.go(AppRoutes.journeys);
    return _ActivityCard(
      key: const ValueKey('inbox-new-shares'),
      badge: const _Badge('journeys', UiTypePastel.weightLoss),
      title: l10n.social_newShares(count),
      unread: unread,
      onTap: open,
      actions: [
        UiButton.secondary(
          label: l10n.social_view,
          compact: true,
          expand: false,
          onPressed: open,
        ),
      ],
    );
  }

  Widget _requestCard(Friendship r, bool unread) {
    final l10n = SocialL10n.of(context);
    final p = r.person;
    final busy = _busy.contains('f:${p.userId}');
    return _ActivityCard(
      key: ValueKey('inbox-request-${p.userId}'),
      badge: _PersonBadge(p),
      title: l10n.social_friendRequestFrom(displayNameOf(p)),
      subtitle: '@${p.username} · ${socialTime(context, r.createdAt)}',
      unread: unread,
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
    );
  }

  Widget _consentCard(ShareConsent s, bool unread) {
    final l10n = SocialL10n.of(context);
    final busy = _busy.contains('c:${s.journeyId}');
    return _ActivityCard(
      key: ValueKey('inbox-consent-${s.journeyId}'),
      badge: const _Badge('share', UiTypePastel.workout),
      title: l10n.social_consentRequest(
        displayNameOf(s.requestedBy),
        s.journeyTitle,
      ),
      unread: unread,
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
          onPressed: busy ? null : () => _respondConsent(s, accept: false),
        ),
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
      _ActivityCard(
        key: ValueKey('inbox-public-$journeyId'),
        badge: const _Badge('squad', UiTypePastel.custom),
        title: l10n.social_publicSummary(requests.length, title),
        onTap: () => setState(() {
          if (!_expanded.remove(journeyId)) _expanded.add(journeyId);
        }),
        trailing: Icon(
          open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
          color: ui.inkMuted,
        ),
      ),
      if (open)
        Container(
          margin: const EdgeInsets.only(top: UiSpace.sm),
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
      padding: const EdgeInsets.only(top: UiSpace.sm),
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

class _FeedItem {
  const _FeedItem({
    required this.id,
    required this.unread,
    required this.build,
    this.at,
  });

  final String id;
  final DateTime? at;
  final bool unread;
  final Widget Function(bool unread) build;
}

/// Pastel sticker tile with an Ourney icon (type badge of a feed row).
class _Badge extends StatelessWidget {
  const _Badge(this.icon, this.pastel);

  final String icon;
  final Color pastel;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: pastel,
        borderRadius: BorderRadius.circular(UiRadius.input),
        border: context.ui.stickerBorder(),
      ),
      child: OurneyIcon(name: icon, size: 26, active: true),
    ),
  );
}

class _PersonBadge extends StatelessWidget {
  const _PersonBadge(this.person);

  final PersonSummary person;

  @override
  Widget build(BuildContext context) {
    final name = displayNameOf(person);
    return ExcludeSemantics(
      child: UiAvatar(
        name: name,
        colorIndex: UiAvatar.indexFor(name),
        size: 44,
        ring: false,
      ),
    );
  }
}

/// V2 activity row: sticker card with a badge, text lines, optional unread
/// dot and inline actions.
class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.badge,
    required this.title,
    this.subtitle,
    this.extra,
    this.unread = false,
    this.onTap,
    this.actions = const [],
    this.trailing,
    super.key,
  });

  final Widget badge;
  final String title;
  final String? subtitle;
  final String? extra;
  final bool unread;
  final VoidCallback? onTap;
  final List<Widget> actions;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    Widget line(String text) => Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: UiText.body(size: 12, height: 1.4, color: ui.inkMuted),
    );
    return UiCard(
      padding: const EdgeInsets.all(UiSpace.md),
      shadowOffset: UiShadow.small,
      onPressed: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              badge,
              const SizedBox(width: UiSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: UiText.body(
                        size: 15,
                        height: 1.35,
                        weight: unread ? FontWeight.w800 : FontWeight.w700,
                        color: ui.ink,
                      ),
                    ),
                    if (subtitle != null) line(subtitle!),
                    if (extra != null) line(extra!),
                  ],
                ),
              ),
              if (unread) ...[
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    key: const ValueKey('unread-dot'),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: ui.danger,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: UiSpace.sm),
            Wrap(spacing: 8, runSpacing: 8, children: actions),
          ],
        ],
      ),
    );
  }
}

class _InviteCard extends StatelessWidget {
  const _InviteCard();

  @override
  Widget build(BuildContext context) {
    final l10n = SocialL10n.of(context);
    final ui = context.ui;
    return UiCard(
      key: const ValueKey('inbox-invite-card'),
      padding: const EdgeInsets.all(UiSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.social_inviteCardTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: UiText.h2(size: 18, color: ui.ink),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.social_inviteCardBody,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: UiText.body(size: 13, height: 1.4, color: ui.inkMuted),
          ),
          const SizedBox(height: UiSpace.md),
          UiButton.secondary(
            key: const ValueKey('inbox-invite-action'),
            label: l10n.social_inviteCardAction,
            compact: true,
            expand: false,
            onPressed: () => context.push(SocialPaths.friendsAdd),
          ),
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: label,
    child: ExcludeSemantics(
      child: ListView(
        key: const ValueKey('inbox-loading'),
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: UiSpace.lg),
        children: [
          for (var i = 0; i < 4; i++)
            const Padding(
              padding: EdgeInsets.only(bottom: UiSpace.md),
              child: UiCard(
                padding: EdgeInsets.all(UiSpace.md),
                child: Row(
                  children: [
                    UiSkeleton(width: 44, height: 44, radius: UiRadius.input),
                    SizedBox(width: UiSpace.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          UiSkeleton(height: 14),
                          SizedBox(height: 8),
                          UiSkeleton(width: 120, height: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({required this.conversation, this.showUnread = true});

  final Conversation conversation;
  final bool showUnread;

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
    return _ActivityCard(
      key: ValueKey('inbox-conversation-${conv.id}'),
      badge: _PersonBadge(conv.other),
      title: name,
      subtitle: conv.journeyTitle,
      extra: preview == null || preview.isEmpty ? null : preview,
      unread: unread && showUnread,
      onTap: () => context.push(SocialPaths.chat(conv.id)),
      trailing: Column(
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
    );
  }
}
