import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/persona_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../personas/persona_contract.dart';
import '../../../shared/color_utils.dart';
import '../../../shared/needs_server_view.dart';
import '../../../shared/ourney_primary_button.dart';
import '../../../shared/template_icons.dart';
import '../data/sharing_providers.dart';
import '../l10n/generated/sharing_localizations.dart';
import '../sharing_paths.dart';
import 'sharing_widgets.dart';

/// Templates whose shares start private (S7, S28). Glow-up / baby templates
/// of the spec do not exist in the v1 enum.
bool isSensitiveTemplate(TemplateId id) => id == TemplateId.weightLoss;

/// Opens "Share this journey" (SCR-82) as a draggable bottom sheet over the
/// root navigator. Exported for the journey screen / shelf (integrator).
Future<void> showShareJourneySheet(BuildContext context, Journey journey) {
  final c = OurneyColors.of(context);
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: c.bg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(OurneyRadii.sheet),
      ),
    ),
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 1,
      builder: (context, controller) => ShareJourneyPanel(
        key: const ValueKey('share-journey-sheet'),
        journey: journey,
        inSheet: true,
        scrollController: controller,
      ),
    ),
  );
}

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
    return Scaffold(
      key: const ValueKey('share-journey-screen'),
      appBar: AppBar(
        centerTitle: true,
        title: SharingNavTitle(title: l10n.sharing_shareThisJourney),
      ),
      body: SafeArea(
        top: false,
        child: switch (journey) {
          null => const NeedsServerView(),
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
      ),
    );
  }
}

/// Body of SCR-82: story preview, group consent, friends, public link.
class ShareJourneyPanel extends ConsumerStatefulWidget {
  const ShareJourneyPanel({
    required this.journey,
    this.inSheet = false,
    this.scrollController,
    super.key,
  });

  final Journey journey;
  final bool inSheet;
  final ScrollController? scrollController;

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
      return const NeedsServerView();
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

    return SharingColumn(
      builder: (context, gutter) => ListView(
        controller: widget.scrollController,
        padding: EdgeInsets.fromLTRB(
          gutter,
          widget.inSheet ? 0 : OurneySpacing.lg,
          gutter,
          OurneySpacing.xxl + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          if (widget.inSheet) const _Grabber(),
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
            const SizedBox(height: OurneySpacing.md),
            _DangerButton(
              key: const ValueKey('share-stop'),
              label: SharingL10n.of(context).sharing_stopSharing,
              onPressed: () => _stopSharing(owner: owner),
            ),
          ],
          if (_isGroup && myConsent?.status == ShareConsentStatus.accepted)
            _DangerButton(
              key: const ValueKey('share-withdraw'),
              label: SharingL10n.of(context).sharing_removeMyPhotos,
              onPressed: _withdraw,
            ),
        ],
      ),
    );
  }
}

class _Grabber extends StatelessWidget {
  const _Grabber();

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 42,
      height: 5,
      margin: const EdgeInsets.only(top: 12, bottom: 16),
      decoration: BoxDecoration(
        color: OurneyColors.of(context).border,
        borderRadius: BorderRadius.circular(99),
      ),
    ),
  );
}

class _Rule extends StatelessWidget {
  const _Rule();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 14, bottom: 6),
    child: Divider(height: 1, color: OurneyColors.of(context).divider),
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
    final c = OurneyColors.of(context);
    final style = OurneyPersonaTheme.forSkin(
      personaSkinOf(journey),
      Theme.of(context).brightness,
    );
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
            borderRadius: BorderRadius.circular(9),
            child: SizedBox(
              width: 52,
              height: 52,
              child: cover != null
                  ? StoragePhoto(path: cover.thumbPath, cacheWidth: 160)
                  : ColoredBox(
                      color: style.primaryAccent,
                      child: Icon(
                        journeyIcon(journey.emoji, journey.templateId),
                        color: readableOn(style.primaryAccent),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: OurneySpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.sharing_shareThisJourney.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: eyebrowStyle(size: 10, color: c.inkMuted),
                ),
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
            child: TextButton(
              key: const ValueKey('share-edit-story'),
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                foregroundColor: c.ink,
              ),
              onPressed: onEdit,
              child: Text(
                l10n.sharing_editStory,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: sharingLabel(context, size: 13),
              ),
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
    final c = OurneyColors.of(context);
    return Column(
      key: const ValueKey('share-consent'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SharingSectionHeader(title: l10n.sharing_consentTitle),
        for (final s in consents)
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 46),
            child: Row(
              key: ValueKey('share-consent-${s.member.userId}'),
              children: [
                PersonAvatar(person: s.member, size: 30),
                const SizedBox(width: OurneySpacing.sm),
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
                      ? c.success
                      : c.inkMuted,
                ),
                const SizedBox(width: 4),
                Text(switch (s.status) {
                  ShareConsentStatus.accepted => l10n.sharing_consentAgreed,
                  ShareConsentStatus.pending => l10n.sharing_consentWaiting,
                  ShareConsentStatus.declined => l10n.sharing_consentDeclined,
                  ShareConsentStatus.withdrawn => l10n.sharing_consentWithdrawn,
                }, style: sharingBody(context, size: 12, color: c.inkMuted)),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            l10n.sharing_consentHelper,
            style: sharingBody(context, size: 12, color: c.inkMuted),
          ),
        ),
        if (needsConsent) ...[
          Text(
            l10n.sharing_askGroupHint,
            style: sharingBody(context, size: 13, color: c.warning),
          ),
          const SizedBox(height: OurneySpacing.sm),
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
    final c = OurneyColors.of(context);
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
      padding: const EdgeInsets.only(top: 8),
      child: Text(s, style: sharingBody(context, size: 12, color: c.inkMuted)),
    );
    TextButton headerAction(String key, String label, VoidCallback onTap) =>
        TextButton(
          key: ValueKey(key),
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            foregroundColor: c.inkMuted,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          onPressed: onTap,
          child: Text(label, style: sharingLabel(context, size: 12)),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SharingSectionHeader(
          title: l10n.sharing_friends,
          trailing: friends.isEmpty
              ? null
              : [
                  headerAction(
                    'share-select-all',
                    l10n.sharing_selectAll,
                    onSelectAll,
                  ),
                  headerAction('share-clear', l10n.sharing_clear, onClear),
                ],
        ),
        if (friends.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: OurneySpacing.md),
            child: Text(
              l10n.sharing_noFriends,
              key: const ValueKey('share-no-friends'),
              style: sharingBody(context, color: c.inkMuted),
            ),
          ),
        if (friends.length > 10)
          Padding(
            padding: const EdgeInsets.only(bottom: OurneySpacing.sm),
            child: TextField(
              key: const ValueKey('share-search'),
              onChanged: onQuery,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: l10n.sharing_searchFriends,
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
        const SizedBox(height: OurneySpacing.md),
        OurneyPrimaryButton(
          key: const ValueKey('share-submit'),
          label: ticked.isEmpty
              ? l10n.sharing_pickFriends
              : l10n.sharing_shareWith(ticked.length),
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
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
    final c = OurneyColors.of(context);
    final body = Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.divider)),
      ),
      child: Row(
        children: [
          PersonAvatar(person: friend, size: 32),
          const SizedBox(width: OurneySpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  friend.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: sharingLabel(context, size: 14),
                ),
                Text(
                  alreadyShared ? l10n.sharing_canSee : '@${friend.username}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: sharingBody(context, size: 12, color: c.inkMuted),
                ),
              ],
            ),
          ),
          if (alreadyShared)
            TextButton(
              key: ValueKey('share-remove-${friend.userId}'),
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                foregroundColor: c.danger,
              ),
              onPressed: removing ? null : onRemove,
              child: Semantics(
                label: l10n.sharing_removeFriendShare(friend.displayName),
                excludeSemantics: true,
                child: Text(
                  l10n.sharing_remove,
                  style: sharingLabel(context, size: 13, color: c.danger),
                ),
              ),
            )
          else
            SizedBox(
              width: 48,
              height: 48,
              child: Center(child: _CheckSquare(checked: ticked)),
            ),
        ],
      ),
    );
    if (alreadyShared) return body;
    return Semantics(
      checked: ticked,
      label: friend.displayName,
      excludeSemantics: true,
      onTap: onToggle,
      child: InkWell(
        key: ValueKey('share-friend-${friend.userId}'),
        onTap: onToggle,
        child: body,
      ),
    );
  }
}

/// Square check box of the V1.0 design (ink fill when ticked).
class _CheckSquare extends StatelessWidget {
  const _CheckSquare({required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    final c = OurneyColors.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: checked ? c.ink : Colors.transparent,
        border: Border.all(color: checked ? c.ink : c.inkMuted),
      ),
      child: checked ? Icon(Icons.check_rounded, size: 16, color: c.bg) : null,
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
    final c = OurneyColors.of(context);
    // S9: only ended / archived (retold journeys are created ended).
    final eligible = journey.status != JourneyStatus.active;

    Widget locked(String title, String sub) => Opacity(
      opacity: 0.7,
      child: ConstrainedBox(
        key: const ValueKey('share-link-locked'),
        constraints: const BoxConstraints(minHeight: 66),
        child: Row(
          children: [
            Icon(Icons.lock_outline_rounded, color: c.ink),
            const SizedBox(width: OurneySpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: sharingLabel(context, size: 13)),
                  Text(
                    sub,
                    style: sharingBody(context, size: 12, color: c.inkMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    final children = <Widget>[
      SharingSectionHeader(title: l10n.sharing_publicLink),
    ];
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
        SharingSwitchRow(
          key: const ValueKey('share-link-switch'),
          title: l10n.sharing_linkOn,
          hint: state.linkOn
              ? (linkUri?.toString() ?? l10n.sharing_linkOn)
              : l10n.sharing_linkOff,
          value: state.linkOn,
          onChanged: under18 || busy ? null : onLink,
        ),
        if (under18)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              l10n.sharing_under18,
              key: const ValueKey('share-under18'),
              style: sharingLabel(context, size: 12, color: c.warning),
            ),
          ),
        if (state.linkOn) ...[
          if (sensitive)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  Icon(Icons.blur_on_rounded, size: 18, color: c.inkMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.sharing_blurredPreview,
                      style: sharingBody(context, size: 12, color: c.inkMuted),
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
            style: sharingBody(context, size: 12, color: c.inkMuted),
          ),
          const SizedBox(height: 6),
          SharingSwitchRow(
            key: const ValueKey('share-show-counts'),
            title: l10n.sharing_showCounts,
            hint: l10n.sharing_showCountsHint,
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
          SharingSwitchRow(
            key: const ValueKey('share-allow-reactions'),
            title: l10n.sharing_letAnyoneReact,
            hint: l10n.sharing_letAnyoneReactHint,
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
          SharingSwitchRow(
            key: const ValueKey('share-allow-requests'),
            title: l10n.sharing_allowRequests,
            hint: l10n.sharing_allowRequestsHint,
            value: settings.allowViewerRequests,
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
            padding: const EdgeInsets.only(top: OurneySpacing.md),
            child: Material(
              color: c.surfaceSunken,
              child: InkWell(
                key: const ValueKey('share-stats'),
                onTap: onInsights,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
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
                        Icon(Icons.chevron_right_rounded, color: c.ink),
                      ],
                    ),
                  ),
                ),
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

class _DangerButton extends StatelessWidget {
  const _DangerButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = OurneyColors.of(context);
    return TextButton(
      style: TextButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        foregroundColor: c.danger,
      ),
      onPressed: onPressed,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: sharingLabel(context, size: 15, color: c.danger),
      ),
    );
  }
}

/// Warm warning before a sensitive journey gets a public link (S10, R2-06).
Future<bool> showSensitiveLinkWarning(BuildContext context) async {
  final l10n = SharingL10n.of(context);
  final app = MaterialLocalizations.of(context);
  final result = await showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: _warmPaper(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(OurneyRadii.sheet),
      ),
    ),
    builder: (context) {
      final ink = _warmInk(context);
      Widget bullet(IconData icon, String s) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: ink),
            const SizedBox(width: 10),
            Expanded(
              child: Text(s, style: sharingBody(context, color: ink)),
            ),
          ],
        ),
      );
      return SingleChildScrollView(
        key: const ValueKey('share-sensitive-warning'),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.sharing_warnTitle,
              style: headingStyle(size: 22, color: ink),
            ),
            const SizedBox(height: 16),
            bullet(Icons.groups_rounded, l10n.sharing_warnAnyone),
            bullet(Icons.visibility_outlined, l10n.sharing_warnSelected),
            bullet(Icons.undo_rounded, l10n.sharing_warnUndo),
            const SizedBox(height: 8),
            OurneyPrimaryButton(
              key: const ValueKey('share-warning-confirm'),
              label: l10n.sharing_warnTurnOn,
              backgroundColor: OurneyColors.light.primary,
              foregroundColor: OurneyColors.light.onPrimary,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: 8),
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                foregroundColor: ink,
              ),
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(app.cancelButtonLabel),
            ),
          ],
        ),
      );
    },
  );
  return result ?? false;
}

/// Same warm tone before a public switch on a sensitive journey (S28).
Future<bool> showSensitiveSwitchWarning(BuildContext context) async {
  final l10n = SharingL10n.of(context);
  final ok = await confirmSharingAction(
    context,
    title: l10n.sharing_warnSwitchTitle,
    message: l10n.sharing_warnSwitchBody,
    confirmLabel: l10n.sharing_warnSwitchConfirm,
  );
  return ok;
}

Color _warmPaper(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFF2A2119)
    : const Color(0xFFFFF4DF);

Color _warmInk(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFFFFEBD0)
    : const Color(0xFF3F2B1D);
