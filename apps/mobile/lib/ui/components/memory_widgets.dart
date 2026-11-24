import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../tokens.dart';
import '../typography.dart';
import 'ourney_icons.dart';

/// `.success-mark`: 44dp green disc with a white check (Posted screen).
class UiSuccessMark extends StatelessWidget {
  const UiSuccessMark({this.size = 44, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFF15803D),
          shape: BoxShape.circle,
        ),
        child: OurneyIcon(
          name: 'check',
          size: size * 0.55,
          flat: true,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// `.stamp`: rotated double-border rubber stamp ("DAY 25").
///
/// When [animate] is `true` (Check-in Success Phase 2c), slams from
/// `scale(1.22 -> 1.0)` with a `-4deg` tilt settle starting at [delay]
/// (`360ms`) over [duration] (`320ms`) using [UiSprings.forSkin] and fires
/// [UiHaptics.stampImpact] at the contact frame (`460ms`). At `t < delay` and
/// under Reduce Motion, holds its resting `1.0` scale and `-8deg` tilt so
/// initial layout bounds never shift.
class UiStamp extends StatefulWidget {
  const UiStamp(
    this.text, {
    this.color,
    this.animate = false,
    this.skinId,
    this.delay = const Duration(milliseconds: 360),
    this.duration = const Duration(milliseconds: 320),
    this.haptics = false,
    super.key,
  });

  final String text;
  final Color? color;
  final bool animate;
  final Object? skinId;
  final Duration delay;
  final Duration duration;
  final bool haptics;

  @override
  State<UiStamp> createState() => _UiStampState();
}

class _UiStampState extends State<UiStamp> with SingleTickerProviderStateMixin {
  AnimationController? _ctrl;
  bool _started = false;
  bool _hapticFired = false;

  Duration get _totalDuration => widget.delay + widget.duration;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = UiMotion.reduced(context);
    if (!_started) {
      _started = true;
      if (widget.animate && !reduced) {
        final ctrl = AnimationController(
          vsync: this,
          duration: _totalDuration,
        )..addListener(_onTick);
        _ctrl = ctrl;
        ctrl.forward(from: 0.0);
      }
    } else if (reduced && (_ctrl?.isAnimating ?? false)) {
      _ctrl?.stop();
      _ctrl?.value = 1.0;
    }
  }

  void _onTick() {
    final ctrl = _ctrl;
    if (ctrl == null || !mounted) return;
    final totalMs = _totalDuration.inMilliseconds;
    final elapsedMs = ctrl.value * totalMs;
    final contactMs = widget.delay.inMilliseconds + 100;
    if (elapsedMs >= contactMs && !_hapticFired) {
      _hapticFired = true;
      if (widget.haptics) {
        unawaited(UiHaptics.stampImpact());
      }
    }
  }

  @override
  void dispose() {
    _ctrl?.removeListener(_onTick);
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.color ?? context.ui.warn;
    const baseAngle = -8 * math.pi / 180;
    final stampBox = Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: context.ui.surface.withValues(alpha: 0.6),
        border: Border.all(color: c, width: 3),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          widget.text,
          maxLines: 1,
          style: UiText.body(
            size: 12,
            weight: FontWeight.w700,
            height: 1.3,
            tracking: 0.04,
            color: c,
          ),
        ),
      ),
    );

    final ctrl = _ctrl;
    if (!widget.animate || UiMotion.reduced(context) || ctrl == null) {
      return Transform.rotate(angle: baseAngle, child: stampBox);
    }

    final spring = UiSprings.forSkin(widget.skinId ?? 'squad');
    final sim = SpringSimulation(spring, 0.0, 1.0, 0.0);
    final delayMs = widget.delay.inMilliseconds.toDouble();
    final durMs = math.max(1, widget.duration.inMilliseconds).toDouble();
    final totalMs = delayMs + durMs;

    return AnimatedBuilder(
      animation: ctrl,
      child: stampBox,
      builder: (context, child) {
        final elapsedMs = ctrl.value * totalMs;
        if (elapsedMs <= delayMs || ctrl.isCompleted) {
          return Transform.rotate(angle: baseAngle, child: child);
        }
        final localT = ((elapsedMs - delayMs) / durMs).clamp(0.0, 1.0);
        final springProgress = sim.x(localT * 0.35).clamp(0.0, 1.15);
        final scale = lerpDouble(1.22, 1.0, springProgress)!;
        final extraAngle =
            lerpDouble(-4 * math.pi / 180, 0.0, springProgress)!;
        return Transform.rotate(
          angle: baseAngle + extraAngle,
          child: Transform.scale(
            key: const ValueKey('ui-stamp-slam-scale'),
            scale: scale,
            child: child,
          ),
        );
      },
    );
  }
}

/// Flame + big number + unit (`.streak-celebrate`, `.shared-streak`).
///
/// When [initialValue] differs from [value] or [animate] is `true` (Check-in
/// Success Phase 2b), rolls the streak digit vertically from `streak - 1 ->
/// streak` via [UiCountRoll] (`520ms`, [UiCurves.easeOutStrong]) after [delay]
/// (`180ms`), ignites `OurneyIcon('flame')` (`scale 0.84 -> 1.18 -> 1.0` via
/// [UiSprings.forSkin], or `1.0 -> 1.04 -> 1.0` gentle glow for `quiet`), and
/// fires [UiHaptics.selection] at digit lock-in (`t = 540ms`).
class UiStreakNumber extends StatefulWidget {
  const UiStreakNumber({
    required this.value,
    required this.unit,
    this.initialValue,
    this.skinId,
    this.delay = const Duration(milliseconds: 180),
    this.animate = false,
    this.haptics = false,
    this.size = 86,
    this.semanticLabel,
    super.key,
  });

  final int value;
  final String unit;
  final int? initialValue;
  final Object? skinId;
  final Duration delay;
  final bool animate;
  final bool haptics;
  final double size;
  final String? semanticLabel;

  @override
  State<UiStreakNumber> createState() => _UiStreakNumberState();
}

class _UiStreakNumberState extends State<UiStreakNumber>
    with SingleTickerProviderStateMixin {
  AnimationController? _ctrl;
  bool _started = false;
  bool _hapticFired = false;

  int get _fromValue {
    if (widget.initialValue != null) return widget.initialValue!;
    if (widget.animate && widget.value > 0) return widget.value - 1;
    return widget.value;
  }

  bool get _shouldAnimate =>
      widget.animate ||
      (widget.initialValue != null && widget.initialValue != widget.value);

  Duration get _totalDuration => widget.delay + UiMotion.countRoll;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = UiMotion.reduced(context);
    if (!_started) {
      _started = true;
      if (_shouldAnimate && !reduced) {
        final ctrl = AnimationController(
          vsync: this,
          duration: _totalDuration,
        )..addListener(_onTick);
        _ctrl = ctrl;
        ctrl.forward(from: 0.0);
      }
    } else if (reduced && (_ctrl?.isAnimating ?? false)) {
      _ctrl?.stop();
      _ctrl?.value = 1.0;
    }
  }

  void _onTick() {
    final ctrl = _ctrl;
    if (ctrl == null || !mounted) return;
    final elapsedMs = ctrl.value * _totalDuration.inMilliseconds;
    final lockInMs = widget.delay.inMilliseconds + 360;
    if (elapsedMs >= lockInMs && !_hapticFired) {
      _hapticFired = true;
      if (widget.haptics) {
        unawaited(UiHaptics.selection());
      }
    }
  }

  @override
  void dispose() {
    _ctrl?.removeListener(_onTick);
    _ctrl?.dispose();
    super.dispose();
  }

  double _flameScaleFor(double localT, bool isGentle) {
    if (localT <= 0.0 || localT >= 1.0) return 1.0;
    if (isGentle) {
      return 1.0 + 0.04 * math.sin(localT * math.pi);
    }
    if (localT < 0.45) {
      final p = UiCurves.easeOutStrong.transform(localT / 0.45);
      return lerpDouble(0.84, 1.18, p)!;
    }
    final p = UiCurves.stampDecel.transform((localT - 0.45) / 0.55);
    return lerpDouble(1.18, 1.0, p)!;
  }

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final reduced = UiMotion.reduced(context);
    final animateNow = _shouldAnimate && !reduced;
    final numberStyle = UiText.display(
      size: widget.size,
      weight: 800,
      height: 1.1,
      tracking: -0.07,
      color: ui.ink,
    );

    final flameIcon = OurneyIcon(
      name: 'flame',
      size: widget.size * 0.38,
      color: ui.flame,
    );

    final ctrl = _ctrl;
    final totalMs = math.max(1, _totalDuration.inMilliseconds);
    final delayFraction =
        (widget.delay.inMilliseconds / totalMs).clamp(0.0, 0.85);
    final isGentle =
        identical(UiSprings.forSkin(widget.skinId ?? 'squad'), UiSprings.gentle);

    final Widget flameWidget = (!animateNow || ctrl == null)
        ? flameIcon
        : AnimatedBuilder(
            animation: ctrl,
            child: flameIcon,
            builder: (context, child) {
              final t = ctrl.value;
              final localT = t <= delayFraction
                  ? 0.0
                  : ((t - delayFraction) / (1.0 - delayFraction))
                        .clamp(0.0, 1.0);
              final scale = _flameScaleFor(localT, isGentle);
              return Transform.scale(
                key: const ValueKey('ui-streak-flame-scale'),
                scale: scale,
                child: child,
              );
            },
          );

    final Widget numberWidget = animateNow && _fromValue != widget.value
        ? UiCountRoll(
            value: widget.value,
            initialValue: _fromValue,
            duration: _totalDuration,
            curve: delayFraction > 0
                ? Interval(delayFraction, 1.0, curve: UiCurves.easeOutStrong)
                : UiCurves.easeOutStrong,
            style: numberStyle,
          )
        : Text('${widget.value}', style: numberStyle);

    return Semantics(
      label: widget.semanticLabel ?? '${widget.value} ${widget.unit}',
      excludeSemantics: true,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            flameWidget,
            numberWidget,
            const SizedBox(width: 8),
            Text(widget.unit, style: UiText.body(size: 16, color: ui.inkMuted)),
          ],
        ),
      ),
    );
  }
}

/// `.polaroid`: tilted card with a hard border and offset shadow (squad
/// wall). [photo] fills the top; [footer] sits under it.
class UiPolaroid extends StatelessWidget {
  const UiPolaroid({
    required this.photo,
    required this.footer,
    this.tilt = -1,
    super.key,
  });

  final Widget photo;
  final Widget footer;

  /// Degrees; odd/even tiles alternate -1 / +1.2.
  final double tilt;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final edge = ui.isDark ? ui.outline : const Color(0xFF1E1B18);
    final shadow = ui.isDark ? ui.hardShadowColor : edge;
    return Transform.rotate(
      angle: tilt * math.pi / 180,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: ui.isDark ? ui.surface : const Color(0xFFFFFDF9),
          border: Border.all(color: edge, width: 2),
          boxShadow: [BoxShadow(color: shadow, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [photo, footer],
        ),
      ),
    );
  }
}

/// Centers [child] in the available area and scrolls when it is taller
/// (empty / error states at large text on short phones).
class UiFillScroll extends StatelessWidget {
  const UiFillScroll({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: c.hasBoundedHeight ? c.maxHeight : 0,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}
