import 'package:flutter/material.dart';

import '../app/theme/motion.dart';
import '../app/theme/tokens.dart';

/// "Check-in stamp": 0.6s keyframe animation. The child drops in oversized
/// and transparent, overshoots to 1.15x, then settles at 1.0 (haptic on
/// impact). With reduce-motion it is a plain 0.2s fade.
///
/// Re-plays whenever [playKey] changes.
class StampAnimation extends StatefulWidget {
  const StampAnimation({
    required this.child,
    this.playKey = 0,
    this.haptic = true,
    this.onCompleted,
    super.key,
  });

  final Widget child;
  final Object playKey;
  final bool haptic;
  final VoidCallback? onCompleted;

  @override
  State<StampAnimation> createState() => _StampAnimationState();
}

class _StampAnimationState extends State<StampAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: OurneyDurations.stamp)
        ..addStatusListener((s) {
          if (s == AnimationStatus.completed) widget.onCompleted?.call();
        });

  // Scale keyframes: 1.6 -> 1.15 (overshoot, impact) -> 1.0.
  static final _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 1.6,
        end: OurneyCurves.stampOvershoot,
      ).chain(CurveTween(curve: Curves.easeIn)),
      weight: 50,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: OurneyCurves.stampOvershoot,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOutBack)),
      weight: 50,
    ),
  ]);

  static final _rotation = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: -0.12, end: 0.04), weight: 50),
    TweenSequenceItem(tween: Tween(begin: 0.04, end: 0.0), weight: 50),
  ]);

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _play();
    }
  }

  @override
  void didUpdateWidget(StampAnimation old) {
    super.didUpdateWidget(old);
    if (old.playKey != widget.playKey) _play();
  }

  void _play() {
    final reduced = OurneyMotion.reduced(context);
    _ctrl.duration = OurneyMotion.duration(context, OurneyDurations.stamp);
    _ctrl.forward(from: 0);
    if (widget.haptic) {
      if (reduced) {
        OurneyHaptics.success();
      } else {
        Future<void>.delayed(OurneyDurations.stamp * 0.5, () {
          if (mounted) OurneyHaptics.success();
        });
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = OurneyMotion.reduced(context);
    return AnimatedBuilder(
      animation: _ctrl,
      child: widget.child,
      builder: (context, child) {
        final t = _ctrl.value;
        if (reduced) return Opacity(opacity: t, child: child);
        return Opacity(
          opacity: (t / 0.25).clamp(0.0, 1.0),
          child: Transform.rotate(
            angle: _rotation.transform(t),
            child: Transform.scale(scale: _scale.transform(t), child: child),
          ),
        );
      },
    );
  }
}
