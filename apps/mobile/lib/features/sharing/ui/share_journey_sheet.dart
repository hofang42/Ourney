import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/providers.dart';
import '../../../personas/persona_contract.dart';
import '../../../ui/ui.dart';
import '../data/sharing_providers.dart';
import '../l10n/generated/sharing_localizations.dart';
import '../sharing_paths.dart';
import 'sharing_widgets.dart';

/// Templates whose shares start private (S7, S28). Glow-up / baby templates
/// of the spec do not exist in the v1 enum.
bool isSensitiveTemplate(TemplateId id) => id == TemplateId.weightLoss;

/// Opens "Share this journey" (SCR-82) as a kit bottom sheet over the root
/// navigator. Exported for the journey screen / shelf (integrator).
Future<void> showShareJourneySheet(BuildContext context, Journey journey) =>
    showUiSheet<void>(
      context: context,
      builder: (context) => ShareJourneyPanel(
        key: const ValueKey('share-journey-sheet'),
        journey: journey,
        inSheet: true,
      ),
    );

/// `/sharing/:journeyId`: full-screen version of the sheet.
class ShareJourneyScreen extends ConsumerWidget {
  const ShareJourneyScreen({required this.journeyId, super.key});

  final String journeyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = SharingL10n.of(context);
    final localOnly = ref.watch(appConfigProvider).localOnly;
    final journey = localOnly
        ? null
        : ref.watch(sharingJourneyProvider(journeyId));
    return SharingPage(
      scaffoldKey: const ValueKey('share-journey-screen'),
      title: l10n.sharing_shareThisJourney,
      children: [
        switch (journey) {
          null => const SharingNeedsServer(),
          AsyncValue(value: final Journey j) => ShareJourneyPanel(journey: j),
          AsyncValue(:final error?) => SharingErrorView(
            error: error,
            onRetry: () => ref.invalidate(sharingJourneyProvider(journeyId)),
          ),
          AsyncValue(isLoading: true) => const SharingLoading(),
          _ => SharingErrorView(
            error: const OurneyException(OurneyErrorCode.notFound),
          ),
        },
      ],
    );
  }
}

/// Body of SCR-82: story preview, group consent, friends, public link.
/// Not scrollable by itself: the sheet / page around it scrolls.
class ShareJourneyPanel extends ConsumerStatefulWidget {
  const ShareJourneyPanel({
    required this.journey,
    this.inSheet = false,
    super.key,
  });

  final Journey journey;
  final bool inSheet;

  @override
  ConsumerState<ShareJourneyPanel> createState() => _ShareJourneyPanelState();
}

class _ShareJourneyPanelState extends ConsumerState<ShareJourneyPanel> {
  /// Friends ticked to receive a new grant (never already-shared ones).
  Set<String>? _ticked;
  String _query = '';
  bool _sharing = false;
  bool _linkBusy = false;
  bool _under18 = false;
  bool _consentNeeded = false;
  final Set<String> _removing = {};

  Journey get _journey => widget.journey;
  bool get _sensitive => isSensitiveTemplate(_journey.templateId);
  bool get _isGroup => _journey.kind == JourneyKind.group;

  bool _isOwner() {
    final me = ref.read(currentUserIdProvider);
    return me == null || me == _journey.ownerId;
  }

  /// Leaves the sheet (if any) before navigating.
  void _open(String location) {
    final router = GoRouter.of(context);
    if (widget.inSheet) Navigator.of(context).pop();
    unawaited(router.push(location));
  }

  void _snack(String message) => showSharingSnack(context, message);

  Future<void> _share(List<String> ids) async {
    final l10n = SharingL10n.of(context);
    setState(() => _sharing = true);
    try {
      await ref
          .read(sharingRepositoryProvider)
          .shareWithFriends(_journey.id, ids);
      if (!mounted) return;
      setState(() => _ticked = {..._ticked!}..removeAll(ids));
      _snack(l10n.sharing_sharedSnack(ids.length));
    } on Object catch (e) {
      if (!mounted) return;
      if (sharingErrorCode(e) == OurneyErrorCode.consentRequired) {
        setState(() => _consentNeeded = true);
      }
      _snack(sharingErrorMessage(context, e));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _unshareFriend(PersonSummary friend) async {
    setState(() => _removing.add(friend.userId));
    try {
      await ref
          .read(sharingRepositoryProvider)
          .unshare(_journey.id, friendId: friend.userId);
    } on Object catch (e) {
      if (mounted) _snack(sharingErrorMessage(context, e));
    } finally {
      if (mounted) setState(() => _removing.remove(friend.userId));
    }
  }

  Future<void> _askGroup() async {
    final l10n = SharingL10n.of(context);
    try {
      await ref.read(shareConsentRepositoryProvider).request(_journey.id);
      if (!mounted) return;
      setState(() => _consentNeeded = false);
      _snack(l10n.sharing_askedSnack);
    } on Object catch (e) {
      if (mounted) _snack(sharingErrorMessage(context, e));
    }
  }

  Future<void> _setLink(bool enabled, {bool reset = false}) async {
    final l10n = SharingL10n.of(context);
    if (enabled && !reset && _sensitive) {
      if (!await showSensitiveLinkWarning(context) || !mounted) return;
    }
    if (reset) {
      final ok = await confirmSharingAction(
        context,
        title: l10n.sharing_resetConfirmTitle,
        message: l10n.sharing_resetConfirmBody,
        confirmLabel: l10n.sharing_resetLink,
      );
      if (!ok || !mounted) return;
    }
    setState(() => _linkBusy = true);
    try {
      await ref
          .read(sharingRepositoryProvider)
          .setPublicLink(_journey.id, enabled: enabled, reset: reset);
    } on Object catch (e) {
      if (!mounted) return;
      if (sharingErrorCode(e) == OurneyErrorCode.forbidden) {
        setState(() => _under18 = true);
        _snack(l10n.sharing_under18);
      } else {
        _snack(sharingErrorMessage(context, e));
      }
    } finally {
      if (mounted) setState(() => _linkBusy = false);
    }
  }

  Future<void> _setPublic(
    PublicSettings next, {
    required bool turningOn,
  }) async {
    if (turningOn && _sensitive) {
      if (!await showSensitiveSwitchWarning(context) || !mounted) return;
    }
    try {
      await ref
          .read(sharingRepositoryProvider)
          .updatePublicSettings(_journey.id, next);
    } on Object catch (e) {
      if (mounted) _snack(sharingErrorMessage(context, e));
    }
  }

  Future<void> _stopSharing({required bool owner}) async {
    final l10n = SharingL10n.of(context);
    final ok = await confirmSharingAction(
      context,
      message: owner ? l10n.sharing_stopConfirm : l10n.sharing_stopMineConfirm,
      confirmLabel: l10n.sharing_stopSharing,
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await ref
          .read(sharingRepositoryProvider)
          .unshare(_journey.id, all: owner);
    } on Object catch (e) {
      if (mounted) _snack(sharingErrorMessage(context, e));
    }
  }

  Future<void> _withdraw() async {
    final l10n = SharingL10n.of(context);
    final ok = await confirmSharingAction(
      context,
      message: l10n.sharing_removeMyPhotosConfirm,
      confirmLabel: l10n.sharing_removeMyPhotos,
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(shareConsentRepositoryProvider).withdraw(_journey.id);
    } on Object catch (e) {
      if (mounted) _snack(sharingErrorMessage(context, e));
    }
  }

  Uri? _linkUri(String token) {
    final base = Uri.tryParse(ref.read(appConfigProvider).supabaseUrl);
    if (base == null || !base.hasScheme) return null;
    return publicJourneyUri(base, token);
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(appConfigProvider).localOnly) {
      return const SharingNeedsServer();
    }
    final stateAsync = ref.watch(shareStateProvider(_journey.id));
    final friendsAsync = ref.watch(acceptedFriendsProvider);
    final state = stateAsync.value;
    final friends = friendsAsync.value;
    if (state == null || friends == null) {
      final error = stateAsync.error ?? friendsAsync.error;
      if (error != null) {
        return SharingErrorView(
          error: error,
          onRetry: () {
            ref.invalidate(shareStateProvider(_journey.id));
            ref.invalidate(acceptedFriendsProvider);
          },
        );
      }
      return const SharingLoading();
    }

    final viewerIds = {for (final v in state.viewers) v.userId};
    // S7: everyone new ticked, nobody for a sensitive template. Seeded once.
    _ticked ??= _sensitive
        ? <String>{}
        : {
            for (final f in friends)
              if (!viewerIds.contains(f.userId)) f.userId,
          };
    final ticked = {
      for (final id in _ticked!)
        if (!viewerIds.contains(id) && friends.any((f) => f.userId == id)) id,
    };

    final consents = _isGroup
        ? ref.watch(shareConsentsProvider(_journey.id)).value
        : null;
    final me = ref.watch(currentUserIdProvider);
    final myConsent = consents?.where((s) => s.member.userId == me).firstOrNull;
    final needsConsent =
        _isGroup &&
        (_consentNeeded ||
            (consents != null &&
                myConsent?.status != ShareConsentStatus.accepted));
    final owner = _isOwner();
    final l10n = SharingL10n.of(context);
    final danger = context.ui.danger;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PreviewRow(
          journey: _journey,
          story: state.story,
          onEdit: () => _open(SharingPaths.story(_journey.id)),
        ),
        if (_isGroup) ...[
          const _Rule(),
          _ConsentBlock(
            consents: consents ?? const [],
            needsConsent: needsConsent,
            onAsk: _askGroup,
          ),
        ],
        const _Rule(),
        _FriendsBlock(
          friends: friends,
          viewerIds: viewerIds,
          ticked: ticked,
          query: _query,
          removing: _removing,
          sensitive: _sensitive,
          running: _journey.status == JourneyStatus.active,
          busy: _sharing,
          onQuery: (q) => setState(() => _query = q),
          onToggle: (id) => setState(() {
            final next = {..._ticked!};
            if (!next.remove(id)) next.add(id);
            _ticked = next;
          }),
          onSelectAll: () => setState(
            () => _ticked = {
              for (final f in friends)
                if (!viewerIds.contains(f.userId)) f.userId,
            },
          ),
          onClear: () => setState(() => _ticked = {}),
          onRemove: _unshareFriend,
          onShare: () => _share(ticked.toList()),
        ),
        const _Rule(),
        _LinkBlock(
          journey: _journey,
          state: state,
          canManage: owner,
          sensitive: _sensitive,
          under18: _under18,
          busy: _linkBusy,
          linkUri: state.publicToken == null
              ? null
              : _linkUri(state.publicToken!),
          onLink: (on) => _setLink(on),
          onReset: () => _setLink(true, reset: true),
          onPublic: _setPublic,
          onInsights: () => _open(SharingPaths.insights(_journey.id)),
        ),
        if (state.viewers.isNotEmpty || state.linkOn) ...[
          const SizedBox(height: UiSpace.md),
          UiTextAction(
            key: const ValueKey('share-stop'),
            label: l10n.sharing_stopSharing,
            color: danger,
            onPressed: () => _stopSharing(owner: owner),
          ),
        ],
        if (_isGroup && myConsent?.status == ShareConsentStatus.accepted)
          UiTextAction(
            key: const ValueKey('share-withdraw'),
            label: l10n.sharing_removeMyPhotos,
            color: danger,
            onPressed: _withdraw,
          ),
      ],
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(top: UiSpace.md, bottom: 6),
    child: UiDivider(),
  );
}

/// Story cover thumb (or style tile), eyebrow, title and Edit story.
class _PreviewRow extends ConsumerWidget {
  const _PreviewRow({
    required this.journey,
    required this.story,
    required this.onEdit,
  });

  final Journey journey;
  final JourneyStory story;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = SharingL10n.of(context);
    final style = uiStyleForSkin(personaSkinOf(journey));
    final coverId = story.coverCheckInId;
    final cover = coverId == null
        ? null
        : ref
              .watch(sharingCheckInsProvider(journey.id))
              .value
              ?.where((ci) => ci.id == coverId)
              .firstOrNull;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 66),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(UiRadius.thumb),
            child: SizedBox(
              width: 52,
              height: 52,
              child: cover != null
                  ? StoragePhoto(path: cover.thumbPath, cacheWidth: 160)
                  : ColoredBox(
                      color: style.accent,
                      child: Icon(
                        uiJourneyIcon(journey.emoji, journey.templateId),
                        color: style.onAccent,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: UiSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UiEyebrow(l10n.sharing_shareThisJourney.toUpperCase()),
                Text(
                  story.title ?? journey.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: sharingLabel(context, size: 15),
                ),
              ],
            ),
          ),
          Flexible(
            child: UiTextAction(
              key: const ValueKey('share-edit-story'),
              label: l10n.sharing_editStory,
              size: 13,
              onPressed: onEdit,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsentBlock extends StatelessWidget {
  const _ConsentBlock({
    required this.consents,
    required this.needsConsent,
    required this.onAsk,
  });

  final List<ShareConsent> consents;
  final bool needsConsent;
  final VoidCallback onAsk;

  @override
  Widget build(BuildContext context) {
    final l10n = SharingL10n.of(context);
    final ui = context.ui;
    return Column(
      key: const ValueKey('share-consent'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UiListHeading(title: l10n.sharing_consentTitle),
        for (final s in consents)
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 46),
            child: Row(
              key: ValueKey('share-consent-${s.member.userId}'),
              children: [
                PersonAvatar(person: s.member, size: 30),
                const SizedBox(width: UiSpace.sm),
                Expanded(
                  child: Text(
                    s.member.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: sharingLabel(context, size: 13),
                  ),
                ),
                Icon(
                  switch (s.status) {
                    ShareConsentStatus.accepted => Icons.check_rounded,
                    ShareConsentStatus.pending => Icons.schedule_rounded,
                    ShareConsentStatus.declined => Icons.block_rounded,
                    ShareConsentStatus.withdrawn => Icons.undo_rounded,
                  },
                  size: 16,
                  color: s.status == ShareConsentStatus.accepted
                      ? ui.success
                      : ui.inkMuted,
                ),
                const SizedBox(width: 4),
                Text(switch (s.status) {
                  ShareConsentStatus.accepted => l10n.sharing_consentAgreed,
                  ShareConsentStatus.pending => l10n.sharing_consentWaiting,
                  ShareConsentStatus.declined => l10n.sharing_consentDeclined,
                  ShareConsentStatus.withdrawn => l10n.sharing_consentWithdrawn,
                }, style: UiText.body(size: 12, color: ui.inkMuted)),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            l10n.sharing_consentHelper,
            style: UiText.body(size: 12, color: ui.inkMuted),
          ),
        ),
        if (needsConsent) ...[
          Text(
            l10n.sharing_askGroupHint,
            style: UiText.body(size: 13, color: ui.warn),
          ),
          const SizedBox(height: UiSpace.sm),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: SharingPillButton(
              key: const ValueKey('share-ask-group'),
              icon: Icons.groups_rounded,
              label: l10n.sharing_askGroup,
              onPressed: onAsk,
            ),
          ),
        ],
      ],
    );
  }
}

class _FriendsBlock extends StatelessWidget {
  const _FriendsBlock({
    required this.friends,
    required this.viewerIds,
    required this.ticked,
    required this.query,
    required this.removing,
    required this.sensitive,
    required this.running,
    required this.busy,
    required this.onQuery,
    required this.onToggle,
    required this.onSelectAll,
    required this.onClear,
    required this.onRemove,
    required this.onShare,
  });

  final List<PersonSummary> friends;
  final Set<String> viewerIds;
  final Set<String> ticked;
  final String query;
  final Set<String> removing;
  final bool sensitive;
  final bool running;
  final bool busy;
  final ValueChanged<String> onQuery;
  final ValueChanged<String> onToggle;
  final VoidCallback onSelectAll;
  final VoidCallback onClear;
  final ValueChanged<PersonSummary> onRemove;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final l10n = SharingL10n.of(context);
    final ui = context.ui;
    final q = query.trim().toLowerCase();
    final shown = q.isEmpty
        ? friends
        : [
            for (final f in friends)
              if (f.displayName.toLowerCase().contains(q) ||
                  f.username.toLowerCase().contains(q))
                f,
          ];
    Widget note(String s) => Padding(
      padding: const EdgeInsets.only(top: UiSpace.sm),
      child: Text(s, style: UiText.body(size: 12, color: ui.inkMuted)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  l10n.sharing_friends,
                  style: UiText.h2(size: 18, color: ui.ink),
                ),
              ),
            ),
            if (friends.isNotEmpty)
              Flexible(
                flex: 2,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  children: [
                    UiTextAction(
                      key: const ValueKey('share-select-all'),
                      label: l10n.sharing_selectAll,
                      size: 12,
                      color: ui.inkMuted,
                      onPressed: onSelectAll,
                    ),
                    UiTextAction(
                      key: const ValueKey('share-clear'),
                      label: l10n.sharing_clear,
                      size: 12,
                      color: ui.inkMuted,
                      onPressed: onClear,
                    ),
                  ],
                ),
              ),
          ],
        ),
        if (friends.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: UiSpace.md),
            child: Text(
              l10n.sharing_noFriends,
              key: const ValueKey('share-no-friends'),
              style: UiText.muted(color: ui.inkMuted, size: 14),
            ),
          ),
        if (friends.length > 10)
          Padding(
            padding: const EdgeInsets.only(bottom: UiSpace.sm),
            child: TextField(
              key: const ValueKey('share-search'),
              onChanged: onQuery,
              style: UiText.body(size: 15, color: ui.ink),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: l10n.sharing_searchFriends,
                filled: true,
                fillColor: ui.surfaceInput,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(UiRadius.input),
                  borderSide: BorderSide(color: ui.inputBorder),
                ),
              ),
            ),
          ),
        for (final f in shown)
          _FriendRow(
            friend: f,
            alreadyShared: viewerIds.contains(f.userId),
            ticked: ticked.contains(f.userId),
            removing: removing.contains(f.userId),
            onToggle: () => onToggle(f.userId),
            onRemove: () => onRemove(f),
          ),
        if (sensitive) note(l10n.sharing_sensitiveHelper),
        if (running) note(l10n.sharing_runningHelper),
        const SizedBox(height: UiSpace.md),
        UiButton(
          key: const ValueKey('share-submit'),
          label: ticked.isEmpty
              ? l10n.sharing_pickFriends
              : l10n.sharing_shareWith(ticked.length),
          onPressed: ticked.isEmpty || busy ? null : onShare,
        ),
      ],
    );
  }
}

class _FriendRow extends StatelessWidget {
  const _FriendRow({
    required this.friend,
    required this.alreadyShared,
    required this.ticked,
    required this.removing,
    required this.onToggle,
    required this.onRemove,
  });

  final PersonSummary friend;
  final bool alreadyShared;
  final bool ticked;
  final bool removing;
  final VoidCallback onToggle;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = SharingL10n.of(context);
    final ui = context.ui;
    final subtitle = Text(
      alreadyShared ? l10n.sharing_canSee : '@${friend.username}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: UiText.body(size: 12, color: ui.inkMuted),
    );
    if (alreadyShared) {
      return UiRow(
        title: friend.displayName,
        leading: PersonAvatar(person: friend, size: 32),
        subtitle: subtitle,
        showChevron: false,
        minHeight: 56,
        trailing: UiTextAction(
          key: ValueKey('share-remove-${friend.userId}'),
          label: l10n.sharing_remove,
          color: ui.danger,
          size: 13,
          onPressed: removing ? null : onRemove,
        ),
      );
    }
    return Semantics(
      checked: ticked,
      label: friend.displayName,
      excludeSemantics: true,
      onTap: onToggle,
      child: UiRow(
        key: ValueKey('share-friend-${friend.userId}'),
        title: friend.displayName,
        leading: PersonAvatar(person: friend, size: 32),
        subtitle: subtitle,
        showChevron: false,
        minHeight: 56,
        onPressed: onToggle,
        trailing: SizedBox(
          width: 48,
          height: 48,
          child: Center(child: SharingCheckSquare(checked: ticked)),
        ),
      ),
    );
  }
}

class _LinkBlock extends ConsumerWidget {
  const _LinkBlock({
    required this.journey,
    required this.state,
    required this.canManage,
    required this.sensitive,
    required this.under18,
    required this.busy,
    required this.linkUri,
    required this.onLink,
    required this.onReset,
    required this.onPublic,
    required this.onInsights,
  });

  final Journey journey;
  final JourneyShareState state;
  final bool canManage;
  final bool sensitive;
  final bool under18;
  final bool busy;
  final Uri? linkUri;
  final ValueChanged<bool> onLink;
  final VoidCallback onReset;
  final Future<void> Function(PublicSettings, {required bool turningOn})
  onPublic;
  final VoidCallback onInsights;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = SharingL10n.of(context);
    final ui = context.ui;
    // S9: only ended / archived (retold journeys are created ended).
    final eligible = journey.status != JourneyStatus.active;

    Widget locked(String title, String sub) => Opacity(
      opacity: 0.7,
      child: UiRow(
        key: const ValueKey('share-link-locked'),
        title: title,
        leading: Icon(Icons.lock_outline_rounded, color: ui.ink),
        subtitle: Text(sub, style: UiText.body(size: 12, color: ui.inkMuted)),
        showChevron: false,
        divider: false,
      ),
    );

    final children = <Widget>[UiListHeading(title: l10n.sharing_publicLink)];
    if (!eligible) {
      children.add(
        locked(l10n.sharing_linkLockedTitle, l10n.sharing_linkLockedSub),
      );
    } else if (!canManage) {
      children.add(
        locked(
          l10n.sharing_linkOwnerOnly,
          state.linkOn ? l10n.sharing_linkOn : l10n.sharing_linkOff,
        ),
      );
    } else {
      final settings = state.publicSettings;
      children.addAll([
        UiSwitchRow(
          key: const ValueKey('share-link-switch'),
          label: l10n.sharing_linkOn,
          subtitle: state.linkOn
              ? (linkUri?.toString() ?? l10n.sharing_linkOn)
              : l10n.sharing_linkOff,
          value: state.linkOn,
          onChanged: under18 || busy ? null : onLink,
        ),
        if (under18)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: UiSpace.sm),
            child: Text(
              l10n.sharing_under18,
              key: const ValueKey('share-under18'),
              style: sharingLabel(context, size: 12, color: ui.warn),
            ),
          ),
        if (state.linkOn) ...[
          if (sensitive)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  Icon(Icons.blur_on_rounded, size: 18, color: ui.inkMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.sharing_blurredPreview,
                      style: UiText.body(size: 12, color: ui.inkMuted),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                SharingPillButton(
                  key: const ValueKey('share-copy-link'),
                  icon: Icons.copy_rounded,
                  label: l10n.sharing_copyLink,
                  onPressed: linkUri == null
                      ? null
                      : () async {
                          await Clipboard.setData(
                            ClipboardData(text: linkUri.toString()),
                          );
                          if (context.mounted) {
                            showSharingSnack(context, l10n.sharing_linkCopied);
                          }
                        },
                ),
                SharingPillButton(
                  key: const ValueKey('share-reset-link'),
                  icon: Icons.refresh_rounded,
                  label: l10n.sharing_resetLink,
                  onPressed: busy ? null : onReset,
                ),
              ],
            ),
          ),
          Text(
            l10n.sharing_linkHelper,
            style: UiText.body(size: 12, color: ui.inkMuted),
          ),
          const SizedBox(height: 6),
          UiSwitchRow(
            key: const ValueKey('share-show-counts'),
            label: l10n.sharing_showCounts,
            subtitle: l10n.sharing_showCountsHint,
            value: settings.showCounts,
            onChanged: (v) => onPublic(
              PublicSettings(
                showCounts: v,
                allowPublicReactions: settings.allowPublicReactions,
                allowViewerRequests: settings.allowViewerRequests,
              ),
              turningOn: v,
            ),
          ),
          UiSwitchRow(
            key: const ValueKey('share-allow-reactions'),
            label: l10n.sharing_letAnyoneReact,
            subtitle: l10n.sharing_letAnyoneReactHint,
            value: settings.allowPublicReactions,
            onChanged: (v) => onPublic(
              PublicSettings(
                showCounts: settings.showCounts,
                allowPublicReactions: v,
                allowViewerRequests: settings.allowViewerRequests,
              ),
              turningOn: v,
            ),
          ),
          UiSwitchRow(
            key: const ValueKey('share-allow-requests'),
            label: l10n.sharing_allowRequests,
            subtitle: l10n.sharing_allowRequestsHint,
            value: settings.allowViewerRequests,
            divider: false,
            onChanged: (v) => onPublic(
              PublicSettings(
                showCounts: settings.showCounts,
                allowPublicReactions: settings.allowPublicReactions,
                allowViewerRequests: v,
              ),
              turningOn: v,
            ),
          ),
        ],
      ]);
    }
    if (eligible && state.linkOn) {
      final insights = ref.watch(journeyInsightsProvider(journey.id)).value;
      if (insights != null) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(top: UiSpace.md),
            child: UiCard(
              key: const ValueKey('share-stats'),
              radius: UiRadius.menu,
              color: ui.fill,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              onPressed: onInsights,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      l10n.sharing_statsLine(
                        compactCount(context, insights.views),
                        compactCount(
                          context,
                          insights.likesFromFriends +
                              insights.likesFromStrangers,
                        ),
                        compactCount(context, insights.started),
                      ),
                      textAlign: TextAlign.center,
                      style: sharingLabel(context, size: 13),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: ui.ink),
                ],
              ),
            ),
          ),
        );
      }
    }
    return Column(
      key: const ValueKey('share-link-block'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

/// Warm warning before a sensitive journey gets a public link (S10, R2-06).
Future<bool> showSensitiveLinkWarning(BuildContext context) async {
  final l10n = SharingL10n.of(context);
  final cancel = MaterialLocalizations.of(context).cancelButtonLabel;
  final result = await showUiSheet<bool>(
    context: context,
    builder: (context) {
      final ui = context.ui;
      Widget bullet(IconData icon, String s) => Padding(
        padding: const EdgeInsets.only(bottom: UiSpace.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: ui.ink),
            const SizedBox(width: 10),
            Expanded(
              child: Text(s, style: UiText.body(size: 14, color: ui.ink)),
            ),
          ],
        ),
      );
      return Column(
        key: const ValueKey('share-sensitive-warning'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.sharing_warnTitle, style: UiText.h2(color: ui.ink)),
          const SizedBox(height: UiSpace.lg),
          bullet(Icons.groups_rounded, l10n.sharing_warnAnyone),
          bullet(Icons.visibility_outlined, l10n.sharing_warnSelected),
          bullet(Icons.undo_rounded, l10n.sharing_warnUndo),
          const SizedBox(height: UiSpace.sm),
          UiButton(
            key: const ValueKey('share-warning-confirm'),
            label: l10n.sharing_warnTurnOn,
            onPressed: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: UiSpace.sm),
          UiButton.ghost(
            label: cancel,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

/// Same warm tone before a public switch on a sensitive journey (S28).
Future<bool> showSensitiveSwitchWarning(BuildContext context) {
  final l10n = SharingL10n.of(context);
  return confirmSharingAction(
    context,
    title: l10n.sharing_warnSwitchTitle,
    message: l10n.sharing_warnSwitchBody,
    confirmLabel: l10n.sharing_warnSwitchConfirm,
  );
}
