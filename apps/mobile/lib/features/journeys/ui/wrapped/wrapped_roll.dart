import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../../ui/ui.dart';
import '../../domain/wrapped_story.dart';
import '../../l10n/generated/journeys_localizations.dart';
import '../journey_photo.dart';
import 'wrapped_visuals.dart';

const _deckCacheWidth = 480;

/// Warms the roll's bounded deck of thumbnails while the first beat is visible.
class WrappedRollPrecache extends ConsumerStatefulWidget {
  const WrappedRollPrecache({
    required this.stats,
    required this.child,
    super.key,
  });

  final WrappedStats stats;
  final Widget child;

  @override
  ConsumerState<WrappedRollPrecache> createState() =>
      _WrappedRollPrecacheState();
}

class _WrappedRollPrecacheState extends ConsumerState<WrappedRollPrecache> {
  final _cached = <ImageProvider>{};

  @override
  Widget build(BuildContext context) {
    if (widget.stats.photos.length >= 4 && !UiMotion.reduced(context)) {
      for (final checkIn in widget.stats.sampleRiffle()) {
        final provider = JourneyPhoto.watchThumbnail(
          checkIn,
          ref,
          cacheWidth: _deckCacheWidth,
        );
        if (provider == null || !_cached.add(provider)) continue;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            unawaited(
              precacheImage(provider, context, onError: (error, stack) {}),
            );
          }
        });
      }
    }
    return widget.child;
  }
}

/// Reveals a photo deck one card at a time before settling into a contact sheet.
class WrappedRoll extends StatefulWidget {
  const WrappedRoll({
    required this.stats,
    required this.blurPhotos,
    this.paused = false,
    super.key,
  });

  final WrappedStats stats;
  final bool blurPhotos;
  final bool paused;

  @override
  State<WrappedRoll> createState() => _WrappedRollState();
}

class _WrappedRollState extends State<WrappedRoll>
    with SingleTickerProviderStateMixin {
  static const _cardMs = 300;
  static const _settleMs = 400;
  AnimationController? _animation;

  int get _deckMs => widget.stats.sampleRiffle().length * _cardMs;
  Duration get _fullDuration => Duration(milliseconds: _deckMs + _settleMs);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (UiMotion.reduced(context)) {
      final animation = _animation;
      if (animation != null && !animation.isCompleted) {
        animation.stop();
        animation.value = 1;
      }
      return;
    }
    _animation ??= AnimationController(vsync: this, duration: _fullDuration)
      ..addStatusListener(_onStatus);
    _updateMotion();
  }

  @override
  void didUpdateWidget(covariant WrappedRoll oldWidget) {
    super.didUpdateWidget(oldWidget);
    _animation?.duration = _fullDuration;
    if (oldWidget.paused != widget.paused) _updateMotion();
  }

  void _updateMotion() {
    final animation = _animation;
    if (animation == null || animation.isCompleted) return;
    if (widget.paused || UiMotion.reduced(context)) {
      animation.stop();
    } else if (!animation.isAnimating) {
      animation.forward();
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !UiMotion.reduced(context)) {
      unawaited(UiHaptics.pressLight());
    }
  }

  @override
  void dispose() {
    _animation?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wall = _PhotoWall(stats: widget.stats, blur: widget.blurPhotos);
    final animation = _animation;
    if (UiMotion.reduced(context) || animation == null) return wall;

    final deck = widget.stats.sampleRiffle();
    if (deck.isEmpty) return wall;
    final deckMs = deck.length * _cardMs;
    return LayoutBuilder(
      builder: (context, constraints) {
        final deckWidth = math.min(constraints.maxWidth * .70, 240.0);
        return AnimatedBuilder(
          animation: animation,
          child: wall,
          builder: (context, child) {
            if (animation.isCompleted) return child!;
            final ms = (animation.value * (deckMs + _settleMs)).roundToDouble();
            final settle = UiCurves.easeInOutStrong.transform(
              ((ms - deckMs) / _settleMs).clamp(0.0, 1.0),
            );
            return Stack(
              alignment: Alignment.center,
              children: [
                if (settle > 0)
                  Transform.scale(
                    scale: .88 + settle * .12,
                    child: Opacity(opacity: settle, child: child!),
                  )
                else
                  Offstage(child: child!),
                Opacity(
                  opacity: 1 - settle,
                  child: Transform.scale(
                    scale: 1 - settle * .18,
                    child: SizedBox(
                      width: deckWidth,
                      height: deckWidth * 4 / 3 + UiSpace.lg,
                      child: _deck(deck, ms),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _deck(List<CheckIn> deck, double ms) {
    final index = math.min(ms ~/ _cardMs, deck.length - 1);
    final enter = UiCurves.easeOutStrong.transform(
      ((ms - index * _cardMs) / 230).clamp(0.0, 1.0),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = math.max(0, index - 2); i <= index; i++)
          Positioned(
            key: ValueKey(deck[i].id),
            top: (index - i) * 3,
            left: (index - i) * 3,
            right: (index - i) * 3,
            child: _deckCard(deck[i], i, i == index ? enter : 1),
          ),
      ],
    );
  }

  Widget _deckCard(CheckIn checkIn, int index, double enter) {
    final ui = context.ui;
    final angle = (index.isEven ? -3 : 3) * math.pi / 180;
    final offset = (index.isEven ? -24 : 24) * (1 - enter);
    return Transform.translate(
      offset: Offset(offset, 0),
      child: Transform.rotate(
        angle: angle,
        child: Opacity(
          opacity: enter,
          child: AspectRatio(
            aspectRatio: 3 / 4,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: ui.surface,
                borderRadius: BorderRadius.circular(UiRadius.thumb),
                border: Border.all(color: ui.outline, width: UiBorder.standard),
                boxShadow: [
                  BoxShadow(
                    color: ui.hardShadowColor,
                    offset: const Offset(UiShadow.tiny, UiShadow.tiny),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(UiSpace.sm),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(UiRadius.otp),
                  child: WrappedPhoto(
                    checkIn: checkIn,
                    blur: widget.blurPhotos,
                    cacheWidth: _deckCacheWidth,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoWall extends StatelessWidget {
  const _PhotoWall({required this.stats, required this.blur});

  final WrappedStats stats;
  final bool blur;

  @override
  Widget build(BuildContext context) {
    final l10n = JourneysL10n.of(context);
    final ui = context.ui;
    final photos = stats.sampleWall();
    final extra = stats.photos.length - photos.length;
    final columns = switch (photos.length) {
      <= 4 => 2,
      <= 8 => 3,
      <= 16 => 4,
      _ => 5,
    };
    const gap = UiSpace.xs * 1.5;
    return LayoutBuilder(
      key: const ValueKey('wrapped-roll-wall'),
      builder: (context, constraints) {
        final tileWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final photo in photos)
                  Container(
                    width: tileWidth,
                    height: tileWidth * 4 / 3,
                    decoration: BoxDecoration(
                      color: ui.fill,
                      border: Border.all(color: ui.outline),
                      borderRadius: BorderRadius.circular(UiSpace.xs),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: WrappedPhoto(
                      checkIn: photo,
                      blur: blur,
                      cacheWidth: 240,
                    ),
                  ),
              ],
            ),
            if (extra > 0)
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: UiSpace.sm),
                  child: Text(
                    l10n.journeys_wrapped_rollMore(extra),
                    style: UiText.body(
                      size: 13,
                      weight: FontWeight.w800,
                      color: ui.ink,
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
