import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/app_routes.dart';
import '../../../app/providers.dart';
import '../../../data/group_daily_checkins_provider.dart';
import '../../../ui/ui.dart';
import '../../groups/data/groups_providers.dart';
import '../../groups/ui/reaction_bar.dart';
import '../data/journeys_providers.dart';
import '../domain/day_neighbors.dart';
import '../l10n/generated/journeys_localizations.dart';
import 'day_photo_fullscreen.dart';
import 'day_viewer_parts.dart';
import 'journey_actions.dart';
import 'journey_errors.dart';
import 'journey_photo.dart';
import 'journey_style.dart';

/// A day's photos, metadata and nearest openable check-ins.
/// Couple journeys show each person's visible contribution on its own page.
class DayViewerScreen extends ConsumerStatefulWidget {
  const DayViewerScreen({
    required this.journeyId,
    required this.date,
    super.key,
  });

  final String journeyId;
  final LocalDate? date;

  static LocalDate? parseDate(String? raw) {
    if (raw == null) return null;
    try {
      return LocalDate.parse(raw);
    } on FormatException {
      return null;
    }
  }

  @override
  ConsumerState<DayViewerScreen> createState() => _DayViewerScreenState();
}

class _DayViewerScreenState extends ConsumerState<DayViewerScreen>
    with SingleTickerProviderStateMixin {
  // Created once the day's photos are known: it opens on the latest one.
  PageController? _pages;
  int _page = 0;
  late LocalDate? _date = widget.date;
  final _ratios = <String, double>{};
  final _decoded = <String>{};
  final _imagePaths = <String, String>{};
  final _imageListeners = <String, (ImageStream, ImageStreamListener)>{};

  /// Interactive vertical drag-to-dismiss state. Updates [_dragOffset] directly
  /// without full-screen [setState] and rebounds via [UiSprings.snappy].
  final ValueNotifier<Offset> _dragOffset = ValueNotifier<Offset>(Offset.zero);
  AnimationController? _reboundCtrl;
  Offset _dragStartLocal = Offset.zero;
  Offset _rawDrag = Offset.zero;
  Offset _reboundFrom = Offset.zero;

  Animation<double>? _routeAnim;
  CurvedAnimation? _chromeFade;

  AnimationController _ensureReboundController() {
    var ctrl = _reboundCtrl;
    if (ctrl != null) return ctrl;
    ctrl = AnimationController.unbounded(vsync: this)
      ..addListener(_onReboundTick);
    _reboundCtrl = ctrl;
    return ctrl;
  }

  void _onReboundTick() {
    final ctrl = _reboundCtrl;
    if (!mounted || ctrl == null) return;
    if (!ctrl.isAnimating) {
      _dragOffset.value = Offset.zero;
      return;
    }
    _dragOffset.value =
        Offset.lerp(_reboundFrom, Offset.zero, ctrl.value) ?? Offset.zero;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final routeAnim = ModalRoute.of(context)?.animation;
    if (!identical(routeAnim, _routeAnim)) {
      _chromeFade?.dispose();
      _routeAnim = routeAnim;
      _chromeFade = routeAnim == null
          ? null
          : CurvedAnimation(
              parent: routeAnim,
              curve: const Interval(0.45, 1.0, curve: UiCurves.easeOutStrong),
            );
    }
  }

  @override
  void dispose() {
    _reboundCtrl?.removeListener(_onReboundTick);
    _reboundCtrl?.dispose();
    _dragOffset.dispose();
    _chromeFade?.dispose();
    _pages?.dispose();
    for (final entry in _imageListeners.values) {
      entry.$1.removeListener(entry.$2);
    }
    super.dispose();
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.journey(widget.journeyId));
    }
  }

  void _onVerticalDragStart(DragStartDetails details) {
    _reboundCtrl?.stop();
    final current = _dragOffset.value;
    _dragStartLocal =
        details.localPosition - Offset(current.dx / 0.35, current.dy);
    _rawDrag = current;
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    final raw = details.localPosition - _dragStartLocal;
    _rawDrag = Offset(raw.dx * 0.35, raw.dy);
    if (!UiMotion.reduced(context)) {
      _dragOffset.value = _rawDrag;
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final reduced = UiMotion.reduced(context);
    final current = reduced ? _rawDrag : _dragOffset.value;
    _rawDrag = Offset.zero;
    final dy = current.dy.abs();
    final vy = details.velocity.pixelsPerSecond.dy;
    final sameDirectionFling =
        (current.dy == 0.0 || (vy * current.dy) > 0.0) && vy.abs() > 750.0;
    if (dy > 110.0 || sameDirectionFling) {
      _dragOffset.value = Offset.zero;
      _close();
      return;
    }
    if (reduced || current == Offset.zero) {
      _dragOffset.value = Offset.zero;
      return;
    }
    _reboundFrom = current;
    final unitVel = dy < 1.0 ? 0.0 : (-vy / current.dy).clamp(-25.0, 25.0);
    final sim = SpringSimulation(UiSprings.snappy, 0.0, 1.0, unitVel);
    final ctrl = _ensureReboundController();
    unawaited(
      ctrl.animateWith(sim).then((_) {
        if (mounted) _dragOffset.value = Offset.zero;
      }),
    );
  }

  void _onVerticalDragCancel() {
    _rawDrag = Offset.zero;
    if (_dragOffset.value == Offset.zero) return;
    _dragOffset.value = Offset.zero;
  }

  @override
  Widget build(BuildContext context) {
    final journey = ref.watch(journeyByIdProvider(widget.journeyId)).value;
    final child = Builder(builder: _buildDetail);
    return journey == null
        ? child
        : UiSkinScope(
            skinId: uiSkinIdFor(skinOfJourney(journey)),
            variant: journey.color ?? 0,
            child: child,
          );
  }

  void _selectDate(LocalDate date) {
    if (date == _date) return;
    final old = _pages;
    setState(() {
      _date = date;
      _pages = null;
      _page = 0;
    });
    // Detach the old PageView before disposing its controller.
    WidgetsBinding.instance.addPostFrameCallback((_) => old?.dispose());
    unawaited(UiHaptics.selection());
  }

  void _resolvePhoto(CheckIn checkIn) {
    final resolved = ref.watch(mediaFileProvider(checkIn.photoPath));
    final path = checkIn.localPhotoFile ?? resolved.value;
    if (path == null || _imagePaths[checkIn.id] == path) return;
    _imagePaths[checkIn.id] = path;
    final stream = FileImage(File(path)).resolve(const ImageConfiguration());
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        _ratios.putIfAbsent(
          checkIn.id,
          () => (info.image.width / info.image.height).clamp(3 / 4, 4 / 3),
        );
        _decoded.add(checkIn.id);
        info.dispose();
        stream.removeListener(listener);
        _imageListeners.remove(checkIn.id);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
      },
      onError: (Object error, StackTrace? stack) {
        _ratios.remove(checkIn.id);
        _decoded.remove(checkIn.id);
        stream.removeListener(listener);
        _imageListeners.remove(checkIn.id);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
      },
    );
    final old = _imageListeners.remove(checkIn.id);
    if (old != null) old.$1.removeListener(old.$2);
    _imageListeners[checkIn.id] = (stream, listener);
    stream.addListener(listener);
  }

  Widget _buildDetail(BuildContext context) {
    final ui = context.ui;
    final l10n = JourneysL10n.of(context);
    final reduced = UiMotion.reduced(context);
    final journeyAsync = ref.watch(journeyByIdProvider(widget.journeyId));
    final journey = journeyAsync.value;
    final checkIns = ref.watch(myCheckInsProvider(widget.journeyId));
    final date = _date;
    final me = ref.watch(currentUserIdProvider);
    final membership = ref.watch(myMembershipProvider(widget.journeyId)).value;
    final couple = journey == null
        ? GroupDailySnapshot.empty
        : ref.watch(groupDailySnapshotProvider(journey));
    final paired = journey != null && isCoupleGroup(journey);
    final ownPhotos = [
      for (final c in checkIns.value ?? const <CheckIn>[])
        if (c.localDate == date) c,
    ]..sort(compareCheckIns);
    final slots = !paired || date == null
        ? const <CouplePhotoSlot>[]
        : couple.memberIds.isEmpty
        ? [
            CouplePhotoSlot(
              userId: me,
              isMine: true,
              checkIn: ownPhotos.lastOrNull,
            ),
            const CouplePhotoSlot(),
          ]
        : couple.slotsOn(date, ownPhoto: ownPhotos.lastOrNull);
    final selected = {for (final slot in slots) ?slot.checkIn?.id};
    final dayCheckIns = paired && date != null
        ? [
            for (final slot in [
              ...slots.where((s) => s.isMine),
              ...slots.where((s) => !s.isMine),
            ])
              ?slot.checkIn,
            ...([
              for (final c in ownPhotos)
                if (!selected.contains(c.id)) c,
              for (final c in couple.photosOn(date))
                if (c.userId == couple.partnerId && !selected.contains(c.id)) c,
            ]..sort(compareCheckIns)),
          ]
        : ownPhotos;
    final waiting = journey == null && journeyAsync.isLoading;
    final count = journey == null ? 0 : dayCheckIns.length;
    if (count > 0 && _pages == null) {
      _page = paired ? 0 : count - 1;
      _pages = PageController(initialPage: _page);
    }
    final index = count == 0 ? 0 : _page.clamp(0, count - 1);
    final checkIn = count == 0 ? null : dayCheckIns[index];
    if (checkIn != null) _resolvePhoto(checkIn);
    final ownMetadata = checkIn != null && (!paired || checkIn.userId == me);
    final openable = <LocalDate, CheckIn>{};
    void addOpenable(CheckIn c) {
      final old = openable[c.localDate];
      if (old == null || compareCheckIns(c, old) > 0) openable[c.localDate] = c;
    }

    for (final c in checkIns.value ?? const <CheckIn>[]) {
      addOpenable(c);
    }
    if (paired) {
      for (final photos in couple.photosByDate.values) {
        for (final c in photos) {
          if (c.userId == couple.partnerId) addOpenable(c);
        }
      }
    }
    final neighbors = date == null
        ? (prev: null, next: null)
        : dayNeighbors(openable.keys, date);
    final perms = journey == null
        ? null
        : JourneyPermissions(
            journey: journey,
            membership: membership,
            currentUserId: me,
          );
    final today = journey == null
        ? null
        : ref
              .watch(journeyTimelineIndexProvider(widget.journeyId))
              ?.progress
              .today;
    Widget? reactions;
    if (checkIn != null &&
        journey != null &&
        journey.kind != JourneyKind.solo &&
        !ref.watch(appConfigProvider).localOnly &&
        checkIn.uploaded &&
        (membership?.isActive ?? false)) {
      final state = ref.watch(groupReactionsProvider(checkIn.id));
      final blocked =
          ref.watch(groupBlockedIdsProvider).value ?? const <String>{};
      final visible =
          state.value?.where((r) => !blocked.contains(r.userId)).isNotEmpty ??
          false;
      if (!state.isLoading &&
          !state.hasError &&
          (checkIn.userId != me || visible)) {
        reactions = Padding(
          padding: const EdgeInsets.only(top: UiSpace.md),
          child: ReactionBar(
            key: ValueKey(checkIn.id),
            checkInId: checkIn.id,
            enabled: checkIn.userId != me && perms!.isActive,
          ),
        );
      }
    }
    Widget? photoFrame;
    if (checkIn != null) {
      void expand() {
        if (!_decoded.contains(checkIn.id)) return;
        unawaited(
          Navigator.of(context, rootNavigator: true).push<void>(
            PageRouteBuilder<void>(
              transitionDuration: reduced
                  ? Duration.zero
                  : const Duration(milliseconds: 180),
              reverseTransitionDuration: reduced
                  ? Duration.zero
                  : const Duration(milliseconds: 180),
              pageBuilder: (_, _, _) => DayPhotoFullscreen(checkIn: checkIn),
              transitionsBuilder: (_, animation, _, child) =>
                  FadeTransition(opacity: animation, child: child),
            ),
          ),
        );
      }

      final ratio = checkIn.fromLibrary ? _ratios[checkIn.id] ?? 3 / 4 : 3 / 4;
      final safeHeight =
          MediaQuery.sizeOf(context).height -
          MediaQuery.paddingOf(context).vertical;
      final frame = LayoutBuilder(
        builder: (context, constraints) {
          final height = math.min(
            constraints.maxWidth / ratio,
            safeHeight * .62,
          );
          return Center(
            child: Container(
              width: height * ratio,
              height: height,
              decoration: BoxDecoration(
                color: ui.fill,
                borderRadius: BorderRadius.circular(UiRadius.card),
                border: Border.all(color: ui.outline, width: 2),
                boxShadow: ui.hardShadow(UiShadow.large),
              ),
              padding: const EdgeInsets.all(2),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(UiRadius.card - 2),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    KeyedSubtree(
                      key: ValueKey(date),
                      child: PageView.builder(
                        key: const ValueKey('journey-day-pages'),
                        controller: _pages,
                        itemCount: count,
                        onPageChanged: (i) {
                          if (i != _page) {
                            unawaited(UiHaptics.selection());
                            setState(() => _page = i);
                          }
                        },
                        itemBuilder: (_, i) {
                          final c = dayCheckIns[i];
                          return GestureDetector(
                            onTap: _decoded.contains(c.id) ? expand : null,
                            child: Semantics(
                              image: true,
                              label: c.caption ?? '',
                              child: JourneyPhoto(
                                key: i == index
                                    ? const ValueKey('journey-day-photo')
                                    : null,
                                checkIn: c,
                                thumbnail: false,
                                fallback: Center(
                                  child: Text(
                                    l10n.journeys_photoUnavailable,
                                    textAlign: TextAlign.center,
                                    style: UiText.body(
                                      size: 14,
                                      height: 1.3,
                                      color: ui.inkMuted,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (count > 1)
                      PositionedDirectional(
                        end: UiSpace.sm,
                        top: UiSpace.sm,
                        child: Semantics(
                          label: l10n.journeys_dayPhotoCountSemantics(
                            index + 1,
                            count,
                          ),
                          excludeSemantics: true,
                          child: Container(
                            key: const ValueKey('journey-day-counter'),
                            padding: const EdgeInsets.symmetric(
                              horizontal: UiSpace.sm,
                              vertical: UiSpace.xs,
                            ),
                            decoration: BoxDecoration(
                              color: UiCamera.bg.withValues(alpha: .55),
                              borderRadius: BorderRadius.circular(
                                UiRadius.capsule,
                              ),
                            ),
                            child: Text(
                              l10n.journeys_dayPhotoCount(index + 1, count),
                              style: UiText.body(
                                size: 12,
                                height: 1.3,
                                weight: FontWeight.w700,
                                color: UiCamera.onPhoto,
                              ),
                            ),
                          ),
                        ),
                      ),
                    PositionedDirectional(
                      end: UiSpace.sm,
                      bottom: UiSpace.sm,
                      child: Container(
                        decoration: BoxDecoration(
                          color: UiCamera.bg.withValues(alpha: .55),
                          borderRadius: BorderRadius.circular(UiRadius.capsule),
                        ),
                        child: UiIconButton(
                          glyph: const OurneyIcon(
                            name: 'image',
                            color: UiCamera.onPhoto,
                            flat: true,
                          ),
                          label: l10n.journeys_dayViewFull,
                          onPressed: _decoded.contains(checkIn.id)
                              ? expand
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
      final sized = reduced
          ? frame
          : AnimatedSize(
              duration: const Duration(milliseconds: 180),
              alignment: Alignment.topCenter,
              child: frame,
            );
      final hero = UiHero(
        tag: UiHeroTags.dayPhoto(checkIn.id),
        borderRadiusBegin: BorderRadius.circular(UiRadius.otp),
        borderRadiusEnd: BorderRadius.circular(UiRadius.card),
        child: sized,
      );
      photoFrame = GestureDetector(
        key: const ValueKey('journey-day-drag-surface'),
        behavior: HitTestBehavior.translucent,
        onVerticalDragStart: _onVerticalDragStart,
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onVerticalDragEnd,
        onVerticalDragCancel: _onVerticalDragCancel,
        child: ValueListenableBuilder<Offset>(
          valueListenable: _dragOffset,
          child: hero,
          builder: (context, offset, child) {
            if (reduced || offset == Offset.zero) return child!;
            final progress = (offset.dy.abs() / 260).clamp(0.0, 1.0);
            return Transform.translate(
              key: const ValueKey('journey-day-drag-transform'),
              offset: offset,
              child: Transform.scale(
                key: const ValueKey('journey-day-drag-scale'),
                scale: lerpDouble(1, .84, progress)!,
                child: child,
              ),
            );
          },
        ),
      );
    }
    Widget metadata = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (ownMetadata) ...[
          DayFacts(checkIn: checkIn, journey: journey),
          DayCaptionSlot(caption: checkIn.caption),
        ],
        ?reactions,
      ],
    );
    if (!reduced && _chromeFade != null) {
      metadata = FadeTransition(
        key: const ValueKey('journey-day-chrome-fade'),
        opacity: _chromeFade!,
        child: metadata,
      );
    }
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DayViewerHeader(
          journey: journey,
          date: date,
          checkIn: checkIn,
          now: ref.watch(journeysNowProvider),
          onBack: _close,
        ),
        if (paired && slots.isNotEmpty)
          DayPeopleSwitch(
            slots: slots,
            selectedId: checkIn?.id,
            onSelect: (id) {
              final i = dayCheckIns.indexWhere((c) => c.id == id);
              if (i < 0) return;
              if (reduced) {
                _pages?.jumpToPage(i);
              } else {
                _pages?.animateToPage(
                  i,
                  duration: const Duration(milliseconds: 180),
                  curve: UiCurves.easeOutStrong,
                );
              }
            },
          ),
        if (photoFrame != null)
          photoFrame
        else
          DayEmptyState(
            loading: checkIns.isLoading || waiting,
            error: checkIns.hasError || journeyAsync.hasError
                ? journeyErrorMessage(
                    context,
                    (checkIns.error ?? journeyAsync.error)!,
                  )
                : journey == null && !waiting
                ? l10n.journeys_errorNotFound
                : null,
            onRetry: () {
              ref.invalidate(journeyByIdProvider(widget.journeyId));
              ref.invalidate(myCheckInsProvider(widget.journeyId));
            },
            onOpenJourney: () =>
                context.go(AppRoutes.journey(widget.journeyId)),
            onCheckIn:
                date != null && date == today && (perms?.canCheckIn ?? false)
                ? () => checkInNow(context, ref, widget.journeyId)
                : null,
          ),
        metadata,
      ],
    );
    return ValueListenableBuilder<Offset>(
      valueListenable: _dragOffset,
      child: body,
      builder: (context, offset, child) {
        final progress = reduced
            ? 0.0
            : (offset.dy.abs() / 260).clamp(0.0, 1.0);
        return UiScaffold.slivers(
          key: const ValueKey('journey-day-viewer'),
          background: ui.bg.withValues(alpha: lerpDouble(1, 0, progress)!),
          padTop: 0,
          safeBottom: true,
          padBottom: 0,
          slivers: [
            SliverToBoxAdapter(child: child),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Align(
                alignment: AlignmentDirectional.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: UiSpace.md,
                    bottom: UiSpace.md,
                  ),
                  child: SizedBox(
                    height: neighbors.prev == null && neighbors.next == null
                        ? 0
                        : 56,
                    child: DayNeighborNav(
                      previous: openable[neighbors.prev],
                      next: openable[neighbors.next],
                      onSelect: _selectDate,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
