import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/app_routes.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../ui/ui.dart';
import '../data/journeys_providers.dart';
import '../domain/journey_time.dart';
import '../l10n/generated/journeys_localizations.dart';
import 'journey_extras.dart';
import 'journey_photo.dart';

/// `/journey/:id/day/:date`: the caller's photos of that day (swipe through
/// several, B-B6) with caption and metric, on the camera black. The metric starts
/// hidden when the journey or the caller hides it (FR-B7) and can be
/// revealed on this device.
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
  bool _revealMetric = false;
  // Created once the day's photos are known: it opens on the latest one.
  PageController? _pages;
  int _page = 0;

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
              curve: const Interval(
                0.45,
                1.0,
                curve: UiCurves.easeOutStrong,
              ),
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
    super.dispose();
  }

  static final _muted = UiCamera.onPhoto.withValues(alpha: 0.64);

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
    final unitVel = dy < 1.0
        ? 0.0
        : (-vy / current.dy).clamp(
            -25.0,
            25.0,
          );
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
    final l10n = JourneysL10n.of(context);
    final app = AppLocalizations.of(context);
    final reduced = UiMotion.reduced(context);
    final journey = ref.watch(journeyByIdProvider(widget.journeyId)).value;
    final membership = ref.watch(myMembershipProvider(widget.journeyId)).value;
    final checkIns = ref.watch(myCheckInsProvider(widget.journeyId));
    final date = widget.date;
    // Every photo of the day, oldest first (several a day since `0014`).
    final dayCheckIns = date == null
        ? const <CheckIn>[]
        : ([
            for (final c in checkIns.value ?? const <CheckIn>[])
              if (c.localDate == date) c,
          ]..sort((a, b) => a.capturedAt.compareTo(b.capturedAt)));
    final count = dayCheckIns.length;
    if (count > 0 && _pages == null) {
      _page = count - 1;
      _pages = PageController(initialPage: count - 1);
    }
    final index = count == 0 ? 0 : _page.clamp(0, count - 1);
    final checkIn = count == 0 ? null : dayCheckIns[index];

    final hidden =
        (membership?.hideMetric ?? journey?.hideMetricDefault ?? false) &&
        !_revealMetric;
    final dateText = date == null
        ? ''
        : MaterialLocalizations.of(context).formatFullDate(displayDate(date));

    Widget? photoFrame;
    if (checkIn != null) {
      final rawFrame = ClipRRect(
        borderRadius: BorderRadius.circular(UiRadius.card),
        child: AspectRatio(
          aspectRatio: 1,
          child: Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
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
                  return Semantics(
                    image: true,
                    label: c.caption ?? dateText,
                    child: JourneyPhoto(
                      key: i == index
                          ? const ValueKey('journey-day-photo')
                          : null,
                      checkIn: c,
                      thumbnail: false,
                      fallback: Center(
                        child: Text(
                          l10n.journeys_photoUnavailable,
                          style: UiText.body(size: 14, color: _muted),
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (count > 1)
                Positioned(
                  right: UiSpace.sm,
                  bottom: UiSpace.sm,
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
                        color: UiCamera.bg.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(
                          UiRadius.capsule,
                        ),
                      ),
                      child: Text(
                        l10n.journeys_dayPhotoCount(index + 1, count),
                        style: UiText.body(
                          size: 12,
                          weight: FontWeight.w700,
                          height: 1.3,
                          color: UiCamera.onPhoto,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );

      final heroFrame = UiHero(
        tag: UiHeroTags.dayPhoto(checkIn.id),
        borderRadiusBegin: BorderRadius.circular(UiRadius.otp),
        borderRadiusEnd: BorderRadius.circular(UiRadius.card),
        child: rawFrame,
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
          child: heroFrame,
          builder: (context, offset, child) {
            if (reduced || offset == Offset.zero) return child!;
            final progress = (offset.dy.abs() / 260.0).clamp(0.0, 1.0);
            final scale = lerpDouble(1.0, 0.84, progress)!;
            return Transform.translate(
              key: const ValueKey('journey-day-drag-transform'),
              offset: offset,
              child: Transform.scale(
                key: const ValueKey('journey-day-drag-scale'),
                scale: scale,
                child: child,
              ),
            );
          },
        ),
      );
    }

    Widget? metadataChrome;
    if (checkIn != null) {
      final chromeColumn = Column(
        key: const ValueKey('journey-day-chrome'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: UiSpace.lg),
          if (checkIn.fromLibrary)
            Row(
              children: [
                OurneyIcon(
                  name: 'gallery',
                  size: 18,
                  flat: true,
                  color: _muted,
                ),
                const SizedBox(width: UiSpace.xs),
                Flexible(
                  child: Text(
                    l10n.journeys_fromLibrary,
                    style: UiText.body(size: 12, color: _muted),
                  ),
                ),
              ],
            ),
          if (checkIn.caption != null && checkIn.caption!.isNotEmpty) ...[
            const SizedBox(height: UiSpace.sm),
            Text(
              checkIn.caption!,
              key: const ValueKey('journey-day-caption'),
              style: UiText.body(
                size: 16,
                height: 1.5,
                color: UiCamera.onPhoto,
              ),
            ),
          ],
          if (journeyExtrasParts(context, checkIn.extras) case final parts
              when parts.isNotEmpty) ...[
            const SizedBox(height: UiSpace.sm),
            Text(
              parts.join(' · '),
              key: const ValueKey('journey-day-extras'),
              style: UiText.body(size: 14, height: 1.45, color: _muted),
            ),
          ],
          if (checkIn.metricValue != null) ...[
            const SizedBox(height: UiSpace.md),
            _MetricRow(
              name: journey?.metricName,
              unit: journey?.metricUnit,
              value: checkIn.metricValue!,
              hidden: hidden,
              onReveal: () {
                unawaited(UiHaptics.selection());
                setState(() => _revealMetric = true);
              },
            ),
          ],
        ],
      );
      final chromeFade = _chromeFade;
      metadataChrome = (!reduced && chromeFade != null)
          ? FadeTransition(
              key: const ValueKey('journey-day-chrome-fade'),
              opacity: chromeFade,
              child: chromeColumn,
            )
          : chromeColumn;
    }

    final contentColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            UiIconButton(
              glyph: const OurneyIcon(
                name: 'back',
                size: 21,
                flat: true,
                color: UiCamera.onPhoto,
              ),
              label: l10n.journeys_back,
              color: UiCamera.onPhoto,
              onPressed: _close,
            ),
            Expanded(
              child: Text(
                dateText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: UiText.body(
                  size: 14,
                  weight: FontWeight.w700,
                  height: 1.4,
                  color: UiCamera.onPhoto,
                ),
              ),
            ),
            const SizedBox(width: UiSize.tap),
          ],
        ),
        const SizedBox(height: UiSpace.sm),
        if (checkIn == null)
          Padding(
            padding: const EdgeInsets.only(top: 120),
            child: Center(
              child: checkIns.isLoading
                  ? UiSpinner(
                      color: UiCamera.ink,
                      semanticsLabel: app.common_loading,
                    )
                  : Text(
                      l10n.journeys_noCheckIn,
                      textAlign: TextAlign.center,
                      style: UiText.body(
                        size: 16,
                        height: 1.5,
                        color: UiCamera.onPhoto,
                      ),
                    ),
            ),
          )
        else ...[
          ?photoFrame,
          ?metadataChrome,
        ],
      ],
    );

    return ValueListenableBuilder<Offset>(
      valueListenable: _dragOffset,
      child: contentColumn,
      builder: (context, offset, child) {
        final progress = reduced
            ? 0.0
            : (offset.dy.abs() / 260.0).clamp(0.0, 1.0);
        final backdropAlpha = lerpDouble(1.0, 0.0, progress)!;
        return UiScaffold(
          key: const ValueKey('journey-day-viewer'),
          background: UiCamera.bg.withValues(alpha: backdropAlpha),
          padTop: 0,
          child: child!,
        );
      },
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.name,
    required this.unit,
    required this.value,
    required this.hidden,
    required this.onReveal,
  });

  final String? name;
  final String? unit;
  final double value;
  final bool hidden;
  final VoidCallback onReveal;

  @override
  Widget build(BuildContext context) {
    final l10n = JourneysL10n.of(context);
    final number = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    final shown = [number, ?unit].join(' ');
    final strong = UiText.body(
      size: 16,
      weight: FontWeight.w700,
      height: 1.4,
      color: UiCamera.onPhoto,
    );
    return Wrap(
      key: const ValueKey('journey-day-metric'),
      spacing: UiSpace.sm,
      runSpacing: UiSpace.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (name != null)
          Text(
            '$name:',
            style: UiText.body(
              size: 14,
              height: 1.4,
              color: UiCamera.onPhoto.withValues(alpha: 0.64),
            ),
          ),
        UiFadeThroughSwitcher(
          duration: const Duration(milliseconds: 140),
          scaleBegin: 1.0,
          instantOnReduceMotion: true,
          alignment: AlignmentDirectional.centerStart,
          child: hidden
              ? Row(
                  key: const ValueKey('journey-day-metric-hidden'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const OurneyIcon(
                      name: 'eye-off',
                      size: 18,
                      flat: true,
                      color: UiCamera.onPhoto,
                    ),
                    const SizedBox(width: UiSpace.xs),
                    Text(l10n.journeys_metricHidden, style: strong),
                    const SizedBox(width: UiSpace.sm),
                    UiTextAction(
                      key: const ValueKey('journey-day-reveal'),
                      label: l10n.journeys_showMetric,
                      color: UiCamera.onPhoto,
                      underline: true,
                      onPressed: onReveal,
                    ),
                  ],
                )
              : Text(
                  shown,
                  key: const ValueKey('journey-day-metric-shown'),
                  style: strong,
                ),
        ),
      ],
    );
  }
}
