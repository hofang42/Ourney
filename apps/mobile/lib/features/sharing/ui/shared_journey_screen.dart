import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/app_routes.dart';
import '../../../app/providers.dart';
import '../../../ui/ui.dart';
import '../data/sharing_providers.dart';
import '../l10n/generated/sharing_localizations.dart';
import '../sharing_paths.dart';
import 'sharing_widgets.dart';

/// SCR-84: a journey as a friend / member (`/shared/:journeyId`) or a
/// signed-in stranger with the link (`/p/:token`) sees it.
class SharedJourneyScreen extends ConsumerWidget {
  const SharedJourneyScreen.byId({required String journeyId, super.key})
    : id = journeyId,
      byToken = false;

  const SharedJourneyScreen.byToken({required String token, super.key})
    : id = token,
      byToken = true;

  final String id;
  final bool byToken;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(appConfigProvider).localOnly) {
      return const SharingPage(children: [SharingNeedsServer()]);
    }
    final key = (id: id, byToken: byToken);
    final async = ref.watch(sharedViewProvider(key));
    final view = async.value;
    if (view != null) return _SharedJourneyBody(view: view, viewKey: key);
    if (async.hasError) {
      final code = sharingErrorCode(async.error!);
      if (code == OurneyErrorCode.forbidden ||
          code == OurneyErrorCode.notFound) {
        return const _PrivateNow();
      }
      return SharingPage(
        children: [
          SharingErrorView(
            error: async.error!,
            onRetry: () => ref.invalidate(sharedViewProvider(key)),
          ),
        ],
      );
    }
    return const SharingPage(children: [SharingLoading()]);
  }
}

class _PrivateNow extends StatelessWidget {
  const _PrivateNow();

  @override
  Widget build(BuildContext context) {
    final l10n = SharingL10n.of(context);
    return SharingPage(
      scaffoldKey: const ValueKey('shared-private-now'),
      onBack: () => sharingBack(context),
      children: [
        UiEmptyState(
          icon: Icons.lock_outline_rounded,
          title: l10n.sharing_privateNow,
          actionLabel: l10n.sharing_goBack,
          onAction: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.journeys),
        ),
      ],
    );
  }
}

/// Optimistic like state of one photo.
typedef _Like = ({bool liked, int count});

class _SharedJourneyBody extends ConsumerStatefulWidget {
  const _SharedJourneyBody({required this.view, required this.viewKey});

  final SharedJourneyView view;
  final SharedViewKey viewKey;

  @override
  ConsumerState<_SharedJourneyBody> createState() => _SharedJourneyBodyState();
}

class _SharedJourneyBodyState extends ConsumerState<_SharedJourneyBody> {
  final Map<String, _Like> _likes = {};
  bool _introOpen = false;
  bool _requested = false;
  bool _replying = false;

  SharedJourneyView get _view => widget.view;

  _Like _likeOf(SharedPhoto p) =>
      _likes[p.checkInId] ?? (liked: p.likedByMe, count: p.likeCount);

  final _liking = <String>{};

  Future<void> _toggleLike(SharedPhoto p) async {
    // One call per photo at a time, so a rollback never undoes a newer tap.
    if (!_liking.add(p.checkInId)) return;
    try {
      await _toggleLikeOnce(p);
    } finally {
      _liking.remove(p.checkInId);
    }
  }

  Future<void> _toggleLikeOnce(SharedPhoto p) async {
    final l10n = SharingL10n.of(context);
    final before = _likeOf(p);
    final like = !before.liked;
    setState(
      () => _likes[p.checkInId] = (
        liked: like,
        count: math.max(0, before.count + (like ? 1 : -1)),
      ),
    );
    final repo = ref.read(sharingRepositoryProvider);
    try {
      if (like) {
        await repo.like(p.checkInId);
      } else {
        await repo.unlike(p.checkInId);
      }
      if (!mounted) return;
      final firstSave =
          like &&
          _view.role == ViewerRole.stranger &&
          !_view.saved &&
          !_likes.entries.any((e) => e.key != p.checkInId && e.value.liked);
      if (firstSave) showSharingSnack(context, l10n.sharing_savedSnack);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _likes[p.checkInId] = before);
      showSharingSnack(context, sharingErrorMessage(context, e));
    }
  }

  Future<void> _addFriend() async {
    final l10n = SharingL10n.of(context);
    setState(() => _requested = true);
    try {
      await ref
          .read(friendRepositoryProvider)
          .sendRequest(_view.owner.userId, fromJourneyId: _view.journeyId);
      if (mounted) showSharingSnack(context, l10n.sharing_requestSentSnack);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _requested = false);
      showSharingSnack(context, sharingErrorMessage(context, e));
    }
  }

  Future<void> _reply(SharedPhoto p) async {
    if (_replying) return;
    setState(() => _replying = true);
    try {
      final id = await ref
          .read(chatRepositoryProvider)
          .openForReply(_view.journeyId, checkInId: p.checkInId);
      if (mounted) await context.push(SharingPaths.chat(id));
    } on Object catch (e) {
      if (mounted) showSharingSnack(context, sharingErrorMessage(context, e));
    } finally {
      if (mounted) setState(() => _replying = false);
    }
  }

  int? _dayOf(SharedPhoto p) {
    final start = _view.startDate;
    if (start == null) return null;
    return start.daysUntil(p.localDate) + 1;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = SharingL10n.of(context);
    final ui = context.ui;
    final v = _view;
    final skin = personaSkinForTemplate(
      v.templateId,
      kind: v.kind,
      emoji: v.emoji,
    );
    final style = uiStyleForSkin(skin);
    final dark = ui.brightness == Brightness.dark;
    final paper = dark ? ui.bg : style.paper;
    final rule = dark ? ui.divider : style.ink.withValues(alpha: 0.16);
    final imported = v.origin == JourneyOrigin.imported;
    final photos = v.photos;
    final cover =
        photos
            .where((p) => p.checkInId == v.story.coverCheckInId)
            .firstOrNull ??
        photos.firstOrNull;
    final title = v.story.title ?? v.title;
    final gutter = UiSpace.gutter(MediaQuery.sizeOf(context).width);

    final String eyebrow;
    if (imported && photos.isNotEmpty) {
      eyebrow = l10n.sharing_importedRange(
        formatDateRange(context, photos.first.localDate, photos.last.localDate),
      );
    } else if (imported) {
      eyebrow = l10n.sharing_imported;
    } else if (v.status == JourneyStatus.active && photos.isNotEmpty) {
      eyebrow = l10n.sharing_liveDay(_dayOf(photos.last) ?? photos.length);
    } else {
      eyebrow = style.name;
    }
    final replyTo = v.kind == JourneyKind.group
        ? (v.sharedBy ?? v.owner).displayName
        : v.owner.displayName;

    final intro = v.story.intro;
    final longIntro = intro != null && intro.length > 160;

    Widget pad(Widget child, {double top = 0, double bottom = 0}) => Padding(
      padding: EdgeInsets.fromLTRB(gutter, top, gutter, bottom),
      child: child,
    );

    return KeyedSubtree(
      key: const ValueKey('shared-journey'),
      child: UiScaffold(
        background: paper,
        gutter: false,
        padTop: 0,
        padBottom: 16,
        bottom: v.canFollow
            ? Padding(
                padding: EdgeInsets.fromLTRB(
                  gutter,
                  UiSpace.sm,
                  gutter,
                  UiSpace.lg + MediaQuery.paddingOf(context).bottom,
                ),
                child: UiButton(
                  key: const ValueKey('shared-do-journey'),
                  label: l10n.sharing_doThisJourney,
                  accent: style.accent,
                  onAccent: style.onAccent,
                  onPressed: () =>
                      context.push(AppRoutes.followJourney(v.journeyId)),
                ),
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            pad(
              UiBackHeader(
                onBack: () => sharingBack(context),
                backLabel: MaterialLocalizations.of(context).backButtonTooltip,
                title: title,
                subtitle: v.owner.displayName,
              ),
            ),
            if (cover != null)
              AspectRatio(aspectRatio: 1, child: _Photo(photo: cover)),
            pad(
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (v.canAddOwner) ...[
                    Row(
                      children: [
                        PersonAvatar(person: v.owner, size: 28),
                        const SizedBox(width: UiSpace.sm),
                        Expanded(
                          child: Text(
                            v.owner.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: sharingLabel(context, size: 14),
                          ),
                        ),
                        const SizedBox(width: UiSpace.sm),
                        Flexible(
                          child: SharingPillButton(
                            key: const ValueKey('shared-add-friend'),
                            icon: _requested
                                ? Icons.check_rounded
                                : Icons.person_add_alt_1_rounded,
                            label: _requested
                                ? l10n.sharing_requested
                                : l10n.sharing_addFriend,
                            onPressed: _requested ? null : _addFriend,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: UiSpace.lg),
                  ],
                  KeyedSubtree(
                    key: const ValueKey('shared-eyebrow'),
                    child: UiEyebrow(eyebrow.toUpperCase()),
                  ),
                  const SizedBox(height: 3),
                  Semantics(
                    header: true,
                    child: Text(title, style: UiText.h1(color: ui.ink)),
                  ),
                  if (intro != null) ...[
                    const SizedBox(height: 9),
                    Text(
                      intro,
                      maxLines: longIntro && !_introOpen ? 4 : null,
                      overflow: longIntro && !_introOpen
                          ? TextOverflow.ellipsis
                          : null,
                      style: UiText.muted(color: ui.inkMuted),
                    ),
                    if (longIntro)
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: UiTextAction(
                          label: _introOpen
                              ? l10n.sharing_less
                              : l10n.sharing_more,
                          underline: true,
                          size: 13,
                          color: ui.ink,
                          alignment: Alignment.centerLeft,
                          onPressed: () =>
                              setState(() => _introOpen = !_introOpen),
                        ),
                      ),
                  ],
                  const SizedBox(height: 14),
                  _ProgressBox(view: v, rule: rule),
                  if (v.story.lessons != null)
                    Padding(
                      padding: const EdgeInsets.only(top: UiSpace.lg),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.symmetric(
                            horizontal: BorderSide(color: rule),
                          ),
                        ),
                        child: Theme(
                          data: Theme.of(context)
                              .copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            key: const ValueKey('shared-lessons'),
                            tilePadding: EdgeInsets.zero,
                            childrenPadding: const EdgeInsets.only(bottom: 12),
                            expandedAlignment: Alignment.centerLeft,
                            title: Text(
                              l10n.sharing_lessonsField,
                              style: sharingLabel(context, size: 14),
                            ),
                            children: [
                              Text(
                                v.story.lessons!,
                                style: sharingBody(context),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (v.likeCount != null && v.followCount != null)
                    Padding(
                      padding: const EdgeInsets.only(top: UiSpace.md),
                      child: Text(
                        l10n.sharing_counts(v.likeCount!, v.followCount!),
                        key: const ValueKey('shared-counts'),
                        style: sharingLabel(context, size: 13),
                      ),
                    ),
                  if (v.kind == JourneyKind.group && v.members.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: UiSpace.md),
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          for (final m in v.members)
                            PersonAvatar(person: m, size: 28),
                          if (v.sharedBy != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Text(
                                l10n.sharing_sharedBy(v.sharedBy!.displayName),
                                style: UiText.body(
                                  size: 12,
                                  color: ui.inkMuted,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
              top: 20,
              bottom: UiSpace.lg,
            ),
            Divider(height: 1, color: rule),
            if (photos.isEmpty)
              Padding(
                padding: const EdgeInsets.all(UiSpace.xl),
                child: Text(
                  l10n.sharing_noPhotosYet,
                  textAlign: TextAlign.center,
                  style: UiText.muted(color: ui.inkMuted, size: 14),
                ),
              ),
            for (final p in photos)
              pad(
                _Moment(
                  photo: p,
                  day: _dayOf(p),
                  like: _likeOf(p),
                  canReact: v.canReact,
                  canReply: v.canReply,
                  showCount: v.role == ViewerRole.member || v.likeCount != null,
                  metricUnit: v.metricUnit,
                  replyTo: replyTo,
                  rule: rule,
                  onLike: () => _toggleLike(p),
                  onReply: () => _reply(p),
                ),
                top: UiSpace.lg,
              ),
          ],
        ),
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.photo});

  final SharedPhoto photo;

  @override
  Widget build(BuildContext context) {
    final image = StoragePhoto(path: photo.photoPath, blurred: photo.blurred);
    if (!photo.blurred) return ExcludeSemantics(child: image);
    return Semantics(
      image: true,
      label: SharingL10n.of(context).sharing_photoBlurred,
      child: image,
    );
  }
}

class _ProgressBox extends StatelessWidget {
  const _ProgressBox({required this.view, required this.rule});

  final SharedJourneyView view;
  final Color rule;

  @override
  Widget build(BuildContext context) {
    final l10n = SharingL10n.of(context);
    final ui = context.ui;
    // S12: never a streak for a retold journey.
    final streak = view.origin == JourneyOrigin.imported
        ? null
        : view.currentStreak;
    final parts = <String>[
      if (view.origin == JourneyOrigin.imported) l10n.sharing_imported,
      l10n.sharing_moments(view.photos.length),
      if (view.durationDays != null) l10n.sharing_days(view.durationDays!),
    ];
    return Container(
      key: const ValueKey('shared-progress'),
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: rule),
        borderRadius: BorderRadius.circular(UiRadius.menu),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              parts.join(' · '),
              style: sharingLabel(context, size: 13),
            ),
          ),
          if (streak != null && streak > 0) ...[
            Icon(
              Icons.local_fire_department_rounded,
              size: 18,
              color: ui.flame,
            ),
            const SizedBox(width: 2),
            Text(
              '$streak',
              key: const ValueKey('shared-streak'),
              style: sharingLabel(context, size: 13),
            ),
          ],
        ],
      ),
    );
  }
}

class _Moment extends StatelessWidget {
  const _Moment({
    required this.photo,
    required this.day,
    required this.like,
    required this.canReact,
    required this.canReply,
    required this.showCount,
    required this.metricUnit,
    required this.replyTo,
    required this.rule,
    required this.onLike,
    required this.onReply,
  });

  final SharedPhoto photo;
  final int? day;
  final _Like like;
  final bool canReact;
  final bool canReply;
  final bool showCount;
  final String? metricUnit;
  final String replyTo;
  final Color rule;
  final VoidCallback onLike;
  final VoidCallback onReply;

  @override
  Widget build(BuildContext context) {
    final l10n = SharingL10n.of(context);
    final ui = context.ui;
    final label = day != null && day! > 0
        ? l10n.sharing_dayN(day!)
        : formatLocalDate(context, photo.localDate);
    final metric = photo.metricValue;
    return Container(
      key: ValueKey('shared-photo-${photo.checkInId}'),
      padding: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: rule)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 430),
            child: AspectRatio(
              aspectRatio: 4 / 5,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(UiRadius.menu),
                child: _Photo(photo: photo),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            [
              label,
              if (metric != null)
                '${_fmt(metric)}${metricUnit == null ? '' : ' $metricUnit'}',
            ].join(' · '),
            style: sharingLabel(context, size: 13),
          ),
          if (photo.caption != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(photo.caption!, style: sharingBody(context)),
            ),
          if (canReact || canReply)
            Padding(
              padding: const EdgeInsets.only(top: UiSpace.sm),
              child: Wrap(
                spacing: UiSpace.sm,
                runSpacing: UiSpace.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (canReact)
                    Semantics(
                      button: true,
                      toggled: like.liked,
                      label: like.liked
                          ? l10n.sharing_unlike
                          : l10n.sharing_like,
                      excludeSemantics: true,
                      child: UiPressable(
                        key: ValueKey('shared-like-${photo.checkInId}'),
                        onPressed: onLike,
                        minSize: const Size(56, UiSize.tap),
                        child: Container(
                          constraints: const BoxConstraints(
                            minHeight: UiSize.tap,
                            minWidth: 56,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: ui.surface,
                            border: Border.all(color: rule),
                            borderRadius: BorderRadius.circular(
                              UiRadius.capsule,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                like.liked
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                size: 20,
                                color: like.liked ? ui.danger : ui.ink,
                              ),
                              if (showCount && like.count > 0) ...[
                                const SizedBox(width: 5),
                                Text(
                                  '${like.count}',
                                  style: sharingLabel(context, size: 13),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (canReply)
                    UiButton.secondary(
                      key: ValueKey('shared-reply-${photo.checkInId}'),
                      label: l10n.sharing_reply,
                      icon: Icons.photo_camera_outlined,
                      compact: true,
                      expand: false,
                      onPressed: onReply,
                    ),
                ],
              ),
            ),
          if (canReply)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                l10n.sharing_replyHint(replyTo),
                style: UiText.body(size: 12, color: ui.inkMuted),
              ),
            ),
        ],
      ),
    );
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}
