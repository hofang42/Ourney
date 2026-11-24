import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'components/ourney_icons.dart';
import 'skins.dart';
import 'tokens.dart';

/// Canonical V2 skin identifiers matching [uiSkins] in `skins.dart`.
enum UiSkinId {
  quiet('quiet'),
  squad('squad'),
  memory('memory'),
  couple('couple'),
  flexer('flexer'),
  minimal('minimal');

  const UiSkinId(this.id);
  final String id;

  static UiSkinId fromId(String id) =>
      values.firstWhere((e) => e.id == id, orElse: () => minimal);
}

/// Physics spring presets (`flutter/physics.dart`).
/// Use with `AnimationController.unbounded` + `SpringSimulation` for
/// interruptible gestures and organic micro-overshoots.
abstract final class UiSprings {
  /// Snappy, virtually non-bouncy settle (`ratio: 0.92`) for sheets, PiP snap,
  /// swipe-to-dismiss recovery, and card deck detents.
  static final SpringDescription snappy = SpringDescription.withDampingRatio(
    mass: 1.0,
    stiffness: 420.0,
    ratio: 0.92,
  );

  /// Playful tactile overshoot (`ratio: 0.68`) for reactions, rubber stamps,
  /// heart seals, and `squad` / `couple` / `flexer` celebration accents.
  static final SpringDescription bouncy = SpringDescription.withDampingRatio(
    mass: 1.0,
    stiffness: 380.0,
    ratio: 0.68,
  );

  /// Critically damped (`ratio: 1.0`) calm spring for `quiet` skin (`weightLoss`)
  /// and opacity/scale effects that must never oscillate.
  static final SpringDescription gentle = SpringDescription.withDampingRatio(
    mass: 1.0,
    stiffness: 240.0,
    ratio: 1.0,
  );

  /// Picks the right celebration spring for a [UiSkinId], [UiSkin], or skin id
  /// string (`quiet` and `minimal` never bounce).
  static SpringDescription forSkin(Object skin) {
    final id = switch (skin) {
      final UiSkinId s => s.id,
      final UiSkin s => s.id,
      final String s => s,
      _ => '$skin',
    };
    return switch (id) {
      'quiet' || 'quietTransformer' || 'minimal' || 'minimalistHabit' => gentle,
      _ => bouncy,
    };
  }
}

/// Centralized Taptic / Haptic feedback contract.
/// Swallows platform exceptions safely in headless widget tests and respects
/// the user's haptics preference via [enabled].
abstract final class UiHaptics {
  static bool enabled = true;

  static Future<void> selection() => _safe(HapticFeedback.selectionClick);
  static Future<void> pressLight() => _safe(HapticFeedback.lightImpact);
  static Future<void> reject() => _safe(HapticFeedback.lightImpact);
  static Future<void> shutterMedium() => _safe(HapticFeedback.mediumImpact);
  static Future<void> stampImpact() => _safe(HapticFeedback.mediumImpact);
  static Future<void> warning() => _safe(HapticFeedback.heavyImpact);

  /// Double-beat celebratory Taptic pattern for Check-in Milestone seals.
  static Future<void> milestoneSuccess() async {
    if (!enabled) return;
    await _safe(HapticFeedback.mediumImpact);
    await Future<void>.delayed(const Duration(milliseconds: 110));
    if (!enabled) return;
    await _safe(HapticFeedback.lightImpact);
  }

  static Future<void> _safe(Future<void> Function() fn) async {
    if (!enabled) return;
    try {
      await fn();
    } catch (_) {
      // No-op when platform channel is unavailable.
    }
  }
}

/// Canonical cross-feature Hero tags so parallel feature modules never collide.
abstract final class UiHeroTags {
  static String journeyBadge(String journeyId) => 'journey-badge-$journeyId';
  static String journeyCover(String journeyId) => 'journey-cover-$journeyId';
  static String capturePhoto(String localKey) => 'capture-photo-$localKey';
  static String dayPhoto(String entryId) => 'day-photo-$entryId';
  static String sharePreview(String journeyId) => 'share-preview-$journeyId';
}

/// Shared-element [Hero] wrapper that automatically disables flight under
/// Reduce Motion (`MediaQuery.disableAnimations` or iOS `reduceMotion`) and
/// optionally tweens [BorderRadius] in flight so Neo-Brutalist borders stay
/// crisp.
class UiHero extends StatelessWidget {
  const UiHero({
    required this.tag,
    required this.child,
    this.flightShuttleBuilder,
    this.placeholderBuilder,
    this.transitionOnUserGestures = false,
    this.borderRadiusBegin,
    this.borderRadiusEnd,
    super.key,
  });

  final Object tag;
  final Widget child;
  final HeroFlightShuttleBuilder? flightShuttleBuilder;
  final HeroPlaceholderBuilder? placeholderBuilder;
  final bool transitionOnUserGestures;
  final BorderRadius? borderRadiusBegin;
  final BorderRadius? borderRadiusEnd;

  @override
  Widget build(BuildContext context) {
    HeroFlightShuttleBuilder? shuttle = flightShuttleBuilder;
    if (shuttle == null &&
        (borderRadiusBegin != null || borderRadiusEnd != null)) {
      final begin = borderRadiusBegin ?? borderRadiusEnd ?? BorderRadius.zero;
      final end = borderRadiusEnd ?? borderRadiusBegin ?? BorderRadius.zero;
      final tween = BorderRadiusTween(begin: begin, end: end);
      shuttle = (flightContext, animation, direction, fromContext, toContext) {
        final target = direction == HeroFlightDirection.push
            ? toContext.widget
            : fromContext.widget;
        return AnimatedBuilder(
          animation: animation,
          child: target,
          builder: (context, child) => ClipRRect(
            borderRadius: tween.evaluate(animation) ?? end,
            child: child,
          ),
        );
      };
    }
    return HeroMode(
      enabled: !UiMotion.reduced(context),
      child: Hero(
        tag: tag,
        flightShuttleBuilder: shuttle,
        placeholderBuilder: placeholderBuilder,
        transitionOnUserGestures: transitionOnUserGestures,
        child: child,
      ),
    );
  }
}

/// GoRouter page transition kinds.
enum UiPageTransition { sharedZ, sharedX, verticalSheet, fadeThrough }

/// Reduce-motion-aware `CustomTransitionPage` factory for `GoRoute.pageBuilder`.
CustomTransitionPage<T> buildUiPage<T>({
  required GoRouterState state,
  required Widget child,
  UiPageTransition kind = UiPageTransition.sharedZ,
  Duration transitionDuration = UiMotion.page,
  Duration reverseTransitionDuration = UiMotion.sheetExit,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: transitionDuration,
    reverseTransitionDuration: reverseTransitionDuration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (UiMotion.reduced(context)) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.linear),
          child: child,
        );
      }
      return switch (kind) {
        UiPageTransition.sharedZ => SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.scaled,
          fillColor: Colors.transparent,
          child: child,
        ),
        UiPageTransition.sharedX => SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.horizontal,
          fillColor: Colors.transparent,
          child: child,
        ),
        UiPageTransition.fadeThrough => FadeThroughTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          fillColor: Colors.transparent,
          child: child,
        ),
        UiPageTransition.verticalSheet => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: UiCurves.drawer)),
          child: FadeTransition(opacity: animation, child: child),
        ),
      };
    },
  );
}

/// Direction-aware step switcher for multi-step flows (Onboarding Quiz,
/// Create-Journey 5-Step Flow, DNA sub-pages, Journey Wrapped slides, and
/// Camera viewfinder journey swipe).
///
/// When [direction] >= 0 (Next / forward), the incoming child slides in from
/// the right (`+slideOffset -> 0`) while the outgoing child slides left
/// (`0 -> -slideOffset`). When [direction] < 0 (Back / reverse), the directions
/// invert. Under Reduce Motion, spatial sliding collapses to an opacity-only
/// crossfade over [UiMotion.reducedFade] (`150ms`).
class UiDirectionalSwitcher extends StatelessWidget {
  const UiDirectionalSwitcher({
    required this.child,
    this.step,
    this.direction = 1,
    this.duration = UiMotion.medium,
    this.slideOffset = 18.0,
    this.animateSize = false,
    this.alignment = Alignment.topCenter,
    super.key,
  });

  final Widget child;

  /// Optional step identifier used to key [child] when [child.key] is null.
  final Object? step;

  /// `>= 0` for forward (Next), `< 0` for backward (Back).
  final int direction;

  final Duration duration;

  /// Horizontal travel distance in logical pixels (`18dp` default).
  final double slideOffset;

  /// Whether to wrap the switcher in an [AnimatedSize] container.
  final bool animateSize;

  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final reduced = UiMotion.reduced(context);
    final effectiveDuration = reduced ? UiMotion.reducedFade : duration;
    final keyedChild = (step != null && child.key == null)
        ? KeyedSubtree(key: ValueKey<Object?>(step), child: child)
        : child;
    final activeKey = keyedChild.key;
    final sign = direction >= 0 ? 1.0 : -1.0;

    Widget switcher = AnimatedSwitcher(
      duration: effectiveDuration,
      reverseDuration: effectiveDuration,
      switchInCurve: reduced ? Curves.linear : UiCurves.easeOutStrong,
      switchOutCurve: reduced ? Curves.linear : UiCurves.easeOutStrong,
      layoutBuilder: (currentChild, previousChildren) => Stack(
        alignment: alignment,
        children: <Widget>[
          ...previousChildren,
          ?currentChild,
        ],
      ),
      transitionBuilder: (widgetChild, animation) {
        if (reduced) {
          return SlideTransition(
            position: const AlwaysStoppedAnimation<Offset>(Offset.zero),
            child: Transform.translate(
              offset: Offset.zero,
              child: FadeTransition(opacity: animation, child: widgetChild),
            ),
          );
        }
        final isIncoming = widgetChild.key == activeKey;
        final itemSign = isIncoming ? sign : -sign;
        final slideFraction = (slideOffset / 360.0).clamp(0.01, 0.25);
        final posAnim = Tween<Offset>(
          begin: Offset(itemSign * slideFraction * 0.25, 0),
          end: Offset.zero,
        ).animate(animation);
        final faded = FadeTransition(opacity: animation, child: widgetChild);
        return SlideTransition(
          position: posAnim,
          child: AnimatedBuilder(
            animation: animation,
            child: faded,
            builder: (context, child) {
              final dx = (1.0 - animation.value) * itemSign * slideOffset;
              return Transform.translate(
                offset: Offset(dx, 0),
                child: child,
              );
            },
          ),
        );
      },
      child: keyedChild,
    );

    if (animateSize) {
      switcher = AnimatedSize(
        duration: UiMotion.of(context, duration),
        curve: UiCurves.easeOutStrong,
        alignment: alignment,
        child: switcher,
      );
    }
    return switcher;
  }
}

/// First-mount wave stagger item with non-uniform shrinking delays
/// `[0ms, 45ms, 80ms, 105ms, 120ms]` capped at index 4.
///
/// Slides upward by [offsetY] (`8dp -> 0`) + [FadeTransition] over [duration]
/// (`200ms`, [UiCurves.easeOutStrong]). Under Reduce Motion (or when
/// `enabled: false`), renders immediately at resting position with zero delay
/// and zero spatial offset.
class UiStaggerItem extends StatefulWidget {
  const UiStaggerItem({
    required this.index,
    required this.child,
    this.enabled = true,
    this.duration = UiMotion.normal,
    this.offsetY = 8.0,
    super.key,
  });

  final int index;
  final Widget child;
  final bool enabled;
  final Duration duration;
  final double offsetY;

  static const List<Duration> waveDelays = <Duration>[
    Duration.zero,
    Duration(milliseconds: 45),
    Duration(milliseconds: 80),
    Duration(milliseconds: 105),
    Duration(milliseconds: 120),
  ];

  /// Returns the non-uniform shrinking delay for [index], capped at index 4.
  static Duration delayFor(int index) {
    if (index <= 0) return Duration.zero;
    final clamped = index < waveDelays.length ? index : waveDelays.length - 1;
    return waveDelays[clamped];
  }

  @override
  State<UiStaggerItem> createState() => _UiStaggerItemState();
}

class _UiStaggerItemState extends State<UiStaggerItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final CurvedAnimation _curved = CurvedAnimation(
    parent: _ctrl,
    curve: UiCurves.easeOutStrong,
  );
  Timer? _delayTimer;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _startIfNeeded();
    } else if (UiMotion.reduced(context) && _ctrl.value < 1.0) {
      _delayTimer?.cancel();
      _delayTimer = null;
      _ctrl.value = 1.0;
    }
  }

  void _startIfNeeded() {
    if (!widget.enabled || UiMotion.reduced(context)) {
      _ctrl.value = 1.0;
      return;
    }
    final delay = UiStaggerItem.delayFor(widget.index);
    if (delay == Duration.zero) {
      _ctrl.forward();
    } else {
      _delayTimer = Timer(delay, () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void didUpdateWidget(covariant UiStaggerItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration != oldWidget.duration) {
      _ctrl.duration = widget.duration;
    }
    if (!widget.enabled && _ctrl.value < 1.0) {
      _delayTimer?.cancel();
      _delayTimer = null;
      _ctrl.value = 1.0;
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _curved.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || UiMotion.reduced(context)) {
      return Transform.translate(offset: Offset.zero, child: widget.child);
    }
    final faded = FadeTransition(opacity: _curved, child: widget.child);
    return AnimatedBuilder(
      animation: _curved,
      child: faded,
      builder: (context, child) {
        final dy = (1.0 - _curved.value) * widget.offsetY;
        return Transform.translate(
          offset: Offset(0, dy),
          child: child,
        );
      },
    );
  }
}

/// Vertical odometer digit roller (`N-1 -> N` or `N -> N-1`) for streak
/// numbers, wrapped totals, and optimistic reaction counters.
///
/// If [initialValue] is provided and differs from [value], rolls immediately on
/// first mount from [initialValue] to [value]. Also rolls automatically
/// whenever [value] updates. Under Reduce Motion, renders the final text
/// immediately with zero ticker or translation.
class UiCountRoll extends StatefulWidget {
  const UiCountRoll({
    required this.value,
    this.initialValue,
    this.style,
    this.duration = UiMotion.countRoll,
    this.curve = UiCurves.easeOutStrong,
    this.slideDistance = 14.0,
    this.format,
    this.textAlign,
    this.semanticsLabel,
    super.key,
  });

  final int value;
  final int? initialValue;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;
  final double slideDistance;
  final String Function(int value)? format;
  final TextAlign? textAlign;
  final String? semanticsLabel;

  @override
  State<UiCountRoll> createState() => _UiCountRollState();
}

class _UiCountRollState extends State<UiCountRoll>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late CurvedAnimation _curved = CurvedAnimation(
    parent: _ctrl,
    curve: widget.curve,
  );
  late Animation<double> _outOpacity = ReverseAnimation(_curved);

  late int _fromValue;
  late int _toValue;
  bool _didInit = false;

  @override
  void initState() {
    super.initState();
    _toValue = widget.value;
    _fromValue = widget.initialValue ?? widget.value;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInit) {
      _didInit = true;
      if (_fromValue != _toValue && !UiMotion.reduced(context)) {
        _ctrl.forward(from: 0.0);
      } else {
        _fromValue = _toValue;
        _ctrl.value = 1.0;
      }
    } else if (UiMotion.reduced(context) && _ctrl.isAnimating) {
      _fromValue = _toValue;
      _ctrl.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant UiCountRoll oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration != oldWidget.duration) {
      _ctrl.duration = widget.duration;
    }
    if (widget.curve != oldWidget.curve) {
      _curved.dispose();
      _curved = CurvedAnimation(parent: _ctrl, curve: widget.curve);
      _outOpacity = ReverseAnimation(_curved);
    }
    if (widget.value != _toValue) {
      _fromValue = _toValue;
      _toValue = widget.value;
      if (UiMotion.reduced(context)) {
        _fromValue = _toValue;
        _ctrl.value = 1.0;
      } else {
        _ctrl.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    _curved.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  String _format(int v) => widget.format != null ? widget.format!(v) : '$v';

  @override
  Widget build(BuildContext context) {
    final reduced = UiMotion.reduced(context);
    final currentText = _format(_toValue);
    if (reduced || _fromValue == _toValue) {
      return Text(
        currentText,
        style: widget.style,
        textAlign: widget.textAlign,
        semanticsLabel: widget.semanticsLabel,
      );
    }

    final previousText = _format(_fromValue);
    final goingUp = _toValue >= _fromValue;
    final dir = goingUp ? 1.0 : -1.0;
    final dist = widget.slideDistance;

    final outgoingChild = FadeTransition(
      opacity: _outOpacity,
      child: Text(
        previousText,
        style: widget.style,
        textAlign: widget.textAlign,
      ),
    );
    final incomingChild = FadeTransition(
      opacity: _curved,
      child: Text(
        currentText,
        style: widget.style,
        textAlign: widget.textAlign,
        semanticsLabel: widget.semanticsLabel,
      ),
    );

    return AnimatedBuilder(
      animation: _curved,
      builder: (context, _) {
        final t = _curved.value;
        if (t >= 1.0 && !_ctrl.isAnimating) {
          return Transform.translate(
            offset: Offset.zero,
            child: Text(
              currentText,
              style: widget.style,
              textAlign: widget.textAlign,
              semanticsLabel: widget.semanticsLabel,
            ),
          );
        }
        return ClipRect(
          child: Stack(
            alignment: Alignment.center,
            children: [
              ExcludeSemantics(
                child: Transform.translate(
                  offset: Offset(0, -dir * t * dist),
                  child: outgoingChild,
                ),
              ),
              Transform.translate(
                offset: Offset(0, dir * (1.0 - t) * dist),
                child: incomingChild,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Tactile Soft Neo-Brutalist pull-to-refresh wrapper (`36×36dp` circular
/// sticker badge with `2dp` `ui.outline`, `2dp` hard shadow, `ui.surface` fill,
/// and custom `OurneyIcon(name: 'refresh')` stroke).
///
/// - **Pull phase:** Rotates `OurneyIcon` proportionally to overscroll
///   (`0 -> 0.75` turns) and scales `0.85 -> 1.0`.
/// - **Threshold crossing (`pull >= 1.0`):** Fires [UiHaptics.selection] once
///   as the sticker snaps `scale(1.08 -> 1.0)` (`140ms`).
/// - **Refreshing phase:** Smooth `750ms` continuous rotation wrapped in
///   [RepaintBoundary] (or gentle opacity pulse under Reduce Motion).
/// - **Complete phase:** Collapses upward over `180ms` ([UiCurves.easeOutStrong]).
class UiRefreshScaffold extends StatefulWidget {
  const UiRefreshScaffold({
    required this.onRefresh,
    required this.child,
    this.triggerOffset = 72.0,
    this.maxPullExtent = 108.0,
    this.notificationPredicate = defaultScrollNotificationPredicate,
    this.semanticsLabel,
    super.key,
  });

  final Future<void> Function() onRefresh;
  final Widget child;
  final double triggerOffset;
  final double maxPullExtent;
  final ScrollNotificationPredicate notificationPredicate;
  final String? semanticsLabel;

  @override
  State<UiRefreshScaffold> createState() => _UiRefreshScaffoldState();
}

class _UiRefreshScaffoldState extends State<UiRefreshScaffold>
    with TickerProviderStateMixin {
  static const Duration _kSnapDuration = Duration(milliseconds: 140);
  static const Duration _kSpinDuration = Duration(milliseconds: 750);
  static const Duration _kCollapseDuration = Duration(milliseconds: 180);

  double _pullExtent = 0.0;
  double _collapseStartExtent = 0.0;
  bool _thresholdCrossed = false;
  bool _refreshing = false;

  late final AnimationController _spinCtrl = AnimationController(
    vsync: this,
    duration: _kSpinDuration,
  );
  late final AnimationController _snapCtrl = AnimationController(
    vsync: this,
    duration: _kSnapDuration,
  );
  late final AnimationController _collapseCtrl = AnimationController(
    vsync: this,
    duration: _kCollapseDuration,
  )..addListener(_onCollapseTick);
  late final CurvedAnimation _collapseCurved = CurvedAnimation(
    parent: _collapseCtrl,
    curve: UiCurves.easeOutStrong,
  );

  void _onCollapseTick() {
    if (!mounted) return;
    setState(() {
      _pullExtent = lerpDouble(_collapseStartExtent, 0.0, _collapseCurved.value)!;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_refreshing) {
      final shouldSpin =
          TickerMode.valuesOf(context).enabled && !UiMotion.reduced(context);
      if (!shouldSpin && _spinCtrl.isAnimating) {
        _spinCtrl.stop();
      } else if (shouldSpin && !_spinCtrl.isAnimating) {
        _spinCtrl.repeat();
      }
    }
  }

  @override
  void dispose() {
    _collapseCtrl.removeListener(_onCollapseTick);
    _collapseCurved.dispose();
    _collapseCtrl.dispose();
    _snapCtrl.dispose();
    _spinCtrl.dispose();
    super.dispose();
  }

  double get _progress =>
      (_pullExtent / widget.triggerOffset).clamp(0.0, 1.0);

  void _updatePull(double nextExtent) {
    final clamped = nextExtent.clamp(0.0, widget.maxPullExtent);
    final nextProgress = (clamped / widget.triggerOffset).clamp(0.0, 1.0);
    if (nextProgress >= 1.0 && !_thresholdCrossed) {
      _thresholdCrossed = true;
      unawaited(UiHaptics.selection());
      if (!UiMotion.reduced(context)) {
        _snapCtrl.forward(from: 0.0);
      }
    } else if (nextProgress < 1.0 && _thresholdCrossed) {
      _thresholdCrossed = false;
    }
    if (_pullExtent != clamped && mounted) {
      setState(() => _pullExtent = clamped);
    }
  }

  Future<void> _triggerRefresh() async {
    if (_refreshing) return;
    final reduced = UiMotion.reduced(context);
    setState(() {
      _refreshing = true;
      _pullExtent = widget.triggerOffset;
    });
    if (!reduced && TickerMode.valuesOf(context).enabled) {
      _spinCtrl.repeat();
    }
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        _spinCtrl.stop();
        _spinCtrl.value = 0.0;
        _thresholdCrossed = false;
        _refreshing = false;
        await _collapseToZero();
      }
    }
  }

  Future<void> _collapseToZero() async {
    if (!mounted) return;
    if (UiMotion.reduced(context) || _pullExtent <= 0.0) {
      setState(() => _pullExtent = 0.0);
      return;
    }
    _collapseStartExtent = _pullExtent;
    await _collapseCtrl.forward(from: 0.0);
    if (mounted) {
      setState(() => _pullExtent = 0.0);
    }
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (!widget.notificationPredicate(notification)) return false;
    if (_refreshing) return false;

    if (notification is ScrollStartNotification) {
      if (_collapseCtrl.isAnimating) {
        _collapseCtrl.stop();
      }
    } else if (notification is OverscrollNotification) {
      if (notification.metrics.extentBefore == 0.0 &&
          (notification.overscroll < 0.0 || _pullExtent > 0.0)) {
        _updatePull(_pullExtent - notification.overscroll);
      }
    } else if (notification is ScrollUpdateNotification) {
      final pixels = notification.metrics.pixels;
      final minExtent = notification.metrics.minScrollExtent;
      if (pixels < minExtent) {
        _updatePull(minExtent - pixels);
      } else if (_pullExtent > 0.0 && (notification.scrollDelta ?? 0.0) > 0.0) {
        _updatePull(_pullExtent - notification.scrollDelta!);
      }
    } else if (notification is ScrollEndNotification ||
        (notification is UserScrollNotification &&
            notification.direction == ScrollDirection.idle)) {
      if (_thresholdCrossed) {
        unawaited(_triggerRefresh());
      } else if (_pullExtent > 0.0) {
        unawaited(_collapseToZero());
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final reduced = UiMotion.reduced(context);
    final showBadge =
        _pullExtent > 0.5 || _refreshing || _collapseCtrl.isAnimating;

    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          widget.child,
          if (showBadge)
            Positioned(
              top: math.max(8.0, (_pullExtent * 0.55) - 20.0),
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Center(
                  child: RepaintBoundary(
                    key: const ValueKey('ui-refresh-badge'),
                    child: Semantics(
                      label: widget.semanticsLabel,
                      liveRegion: _refreshing,
                      child: _buildBadge(ui, reduced),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBadge(OurneyUi ui, bool reduced) {
    final progress = _progress;
    final baseScale = reduced ? 1.0 : lerpDouble(0.85, 1.0, progress)!;

    Widget icon = OurneyIcon(name: 'refresh', size: 18, color: ui.ink);
    if (_refreshing) {
      icon = reduced
          ? FadeTransition(
              opacity: const AlwaysStoppedAnimation<double>(0.78),
              child: icon,
            )
          : RotationTransition(turns: _spinCtrl, child: icon);
    } else if (!reduced) {
      icon = Transform.rotate(
        angle: progress * 0.75 * 2.0 * math.pi,
        child: icon,
      );
    }

    final badgeCore = SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned.fill(
            child: Transform.translate(
              offset: const Offset(UiShadow.tiny, UiShadow.tiny),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: ui.hardShadowColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: ui.surface,
              shape: BoxShape.circle,
              border: ui.stickerBorder(UiBorder.standard),
            ),
            child: Center(child: icon),
          ),
        ],
      ),
    );

    if (reduced) {
      return badgeCore;
    }

    return AnimatedBuilder(
      animation: _snapCtrl,
      child: badgeCore,
      builder: (context, child) {
        final snapT = UiCurves.easeOutStrong.transform(_snapCtrl.value);
        final snapBoost = _snapCtrl.isAnimating || _snapCtrl.value > 0
            ? lerpDouble(1.08, 1.0, snapT)!
            : 1.0;
        return Transform.scale(
          scale: baseScale * snapBoost,
          child: child,
        );
      },
    );
  }
}
