import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../tokens.dart';
import '../typography.dart';
import 'ourney_icons.dart';
import 'pressable.dart';
import 'skin_scope.dart';

/// The five reaction ids (match the `reactions.emoji` CHECK), in display order.
const List<String> uiReactionIds = ['clap', 'flex', 'heart', 'laugh', 'fire'];

/// A pill of the five V2 reactions drawn with Ourney sticker icons (never
/// emoji). Each reaction is a 38dp sticker disc inside a 48dp hit target.
/// [selected] is the reaction the viewer already gave; [counts] adds a small
/// count badge. [labels] maps each id in [uiReactionIds] to its localized
/// semantics label (supplied by the caller from l10n).
class UiReactionBar extends StatelessWidget {
  const UiReactionBar({
    required this.onReact,
    required this.labels,
    this.selected,
    this.counts,
    super.key,
  });

  final ValueChanged<String> onReact;
  final Map<String, String> labels;
  final String? selected;
  final Map<String, int>? counts;

  static const double visual = 38;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    // Scrolls horizontally instead of shrinking: hit targets stay 48dp.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      // Room for the 2dp hard shadow, which the scroll view would clip.
      clipBehavior: Clip.none,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ui.surface,
          borderRadius: BorderRadius.circular(UiRadius.capsule),
          border: ui.stickerBorder(UiBorder.thin),
          boxShadow: ui.hardShadow(UiShadow.tiny),
        ),
        child: Padding(
          padding: const EdgeInsets.all(UiSpace.xs),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final id in uiReactionIds)
                _ReactionButton(
                  id: id,
                  selected: selected == id,
                  count: counts?[id] ?? 0,
                  label: labels[id] ?? id,
                  onReact: onReact,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReactionButton extends StatefulWidget {
  const _ReactionButton({
    required this.id,
    required this.selected,
    required this.count,
    required this.label,
    required this.onReact,
  });

  final String id;
  final bool selected;
  final int count;
  final String label;
  final ValueChanged<String> onReact;

  @override
  State<_ReactionButton> createState() => _ReactionButtonState();
}

class _ReactionButtonState extends State<_ReactionButton> {
  final GlobalKey<UiReactionSparkState> _sparkKey =
      GlobalKey<UiReactionSparkState>();
  late int _prevCount;

  @override
  void initState() {
    super.initState();
    _prevCount = widget.count;
  }

  @override
  void didUpdateWidget(covariant _ReactionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.count != oldWidget.count) {
      _prevCount = oldWidget.count;
    }
  }

  void _handlePress() {
    _sparkKey.currentState?.trigger(adding: !widget.selected);
    widget.onReact(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final count = widget.count;
    final selected = widget.selected;
    final semantic = count > 0 ? '${widget.label}, $count' : widget.label;
    return UiPressable(
      onPressed: _handlePress,
      selected: selected,
      semanticLabel: semantic,
      excludeChildSemantics: true,
      centerChild: true,
      borderRadius: BorderRadius.circular(UiRadius.capsule),
      child: SizedBox.square(
        dimension: UiSize.tap,
        child: Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                key: ValueKey('reaction-disc-${widget.id}'),
                width: UiReactionBar.visual,
                height: UiReactionBar.visual,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? ui.brand : ui.fill,
                  border: selected
                      ? Border.all(color: ui.outline, width: UiBorder.thin)
                      : null,
                ),
                child: UiReactionSpark(
                  key: _sparkKey,
                  id: widget.id,
                  selected: selected,
                  child: OurneyIcon(
                    name: 'react-${widget.id}',
                    size: 24,
                    active: true,
                  ),
                ),
              ),
              if (count > 0)
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 18),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: ui.surface,
                      borderRadius: BorderRadius.circular(UiRadius.capsule),
                      border: Border.all(
                        color: ui.outline,
                        width: UiBorder.hairline,
                      ),
                    ),
                    child: MediaQuery.withClampedTextScaling(
                      maxScaleFactor: 1.35,
                      child: UiCountRoll(
                        value: count,
                        initialValue: _prevCount,
                        duration: UiMotion.normal,
                        curve: UiCurves.easeOutStrong,
                        slideDistance: 8.0,
                        textAlign: TextAlign.center,
                        style: UiText.body(
                          size: 10,
                          weight: FontWeight.w700,
                          height: 1.3,
                          color: ui.ink,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared reaction icon choreographer & 5-particle vector sticker burst
/// (Moment #4) used by both [UiReactionBar] and Squad Wall `ReactionBar`.
///
/// - **Add (`adding: true`):**
///   - Fires [UiHaptics.pressLight] immediately.
///   - `0–70ms` (*Anticipation*): Compresses `scale(1.0 -> 0.84)` and tilts
///     `0 -> -8deg`.
///   - `70–310ms` (*Spring Pop*): Rebounds `scale(0.84 -> 1.24 -> 1.0)` +
///     `-8deg -> 0deg` driven by [SpringSimulation] with [UiSprings.bouncy].
///   - `90–480ms` (*Vector Sticker Burst*): Radiates 5 mini geometric vector
///     sticker sparks (`18–28dp` radial travel, `opacity 1 -> 0`,
///     [UiCurves.easeOutStrong]) in `ui.accent` & `ui.brand`.
/// - **Remove (`adding: false`):**
///   - Fires [UiHaptics.selection] immediately.
///   - Skips the particle burst and plays a `140ms` `scale(1.0 -> 0.92 -> 1.0)`
///     settle.
/// - **Reduce Motion:** Zero spring overshoot, zero tilt, zero particle burst.
class UiReactionSpark extends StatefulWidget {
  const UiReactionSpark({
    required this.id,
    required this.selected,
    required this.child,
    super.key,
  });

  final String id;
  final bool selected;
  final Widget child;

  @override
  State<UiReactionSpark> createState() => UiReactionSparkState();
}

class UiReactionSparkState extends State<UiReactionSpark>
    with SingleTickerProviderStateMixin {
  static const Duration _kAddDuration = Duration(milliseconds: 480);
  static const Duration _kRemoveDuration = Duration(milliseconds: 140);
  static const double _kAnticipationScale = 0.84;
  static const double _kRemoveDipScale = 0.92;
  static const double _kMaxTiltRad = -8.0 * math.pi / 180.0;

  static final SpringSimulation _kBouncyPopSpring = SpringSimulation(
    UiSprings.bouncy,
    _kAnticipationScale,
    1.0,
    14.5,
  );

  static final SpringSimulation _kGentlePopSpring = SpringSimulation(
    UiSprings.gentle,
    _kAnticipationScale,
    1.0,
    0.0,
  );

  AnimationController? _ctrl;
  bool _isAdding = true;

  AnimationController _ensureController(Duration duration) {
    var ctrl = _ctrl;
    if (ctrl == null) {
      ctrl = AnimationController(vsync: this, duration: duration)
        ..addStatusListener(_onStatusChanged);
      _ctrl = ctrl;
    } else {
      ctrl.duration = duration;
    }
    return ctrl;
  }

  void _onStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed ||
        status == AnimationStatus.dismissed) {
      if (mounted) setState(() {});
    }
  }

  /// Triggers the reaction pop/burst (when [adding] is `true`) or settle
  /// (when [adding] is `false`) and emits the paired haptic on the user commit
  /// frame when [haptic] is `true`.
  void trigger({required bool adding, bool haptic = true}) {
    if (haptic) {
      if (adding) {
        unawaited(UiHaptics.pressLight());
      } else {
        unawaited(UiHaptics.selection());
      }
    }
    if (!mounted || UiMotion.reduced(context)) {
      _ctrl?.stop();
      _ctrl?.value = 0.0;
      return;
    }
    setState(() {
      _isAdding = adding;
    });
    final ctrl = _ensureController(adding ? _kAddDuration : _kRemoveDuration);
    ctrl.forward(from: 0.0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (UiMotion.reduced(context) && (_ctrl?.isAnimating ?? false)) {
      _ctrl?.stop();
      _ctrl?.value = 0.0;
    }
  }

  @override
  void dispose() {
    _ctrl?.removeStatusListener(_onStatusChanged);
    _ctrl?.dispose();
    super.dispose();
  }

  ({double scale, double tilt}) _evaluateIconTransform({
    required bool calmSkin,
  }) {
    final ctrl = _ctrl;
    if (ctrl == null || !ctrl.isAnimating) {
      return (scale: 1.0, tilt: 0.0);
    }
    if (!_isAdding) {
      final t = ctrl.value.clamp(0.0, 1.0);
      final dip = math.sin(t * math.pi);
      final scale = lerpDouble(1.0, _kRemoveDipScale, dip)!;
      return (scale: scale, tilt: 0.0);
    }
    final elapsedMs = ctrl.value * 480.0;
    final maxTilt = calmSkin ? 0.0 : _kMaxTiltRad;
    if (elapsedMs <= 70.0) {
      final t = UiCurves.easeOutStrong.transform(
        (elapsedMs / 70.0).clamp(0.0, 1.0),
      );
      return (
        scale: lerpDouble(1.0, _kAnticipationScale, t)!,
        tilt: lerpDouble(0.0, maxTilt, t)!,
      );
    }
    if (elapsedMs < 310.0) {
      final tau = (elapsedMs - 70.0) / 1000.0;
      final spring = calmSkin ? _kGentlePopSpring : _kBouncyPopSpring;
      final scale = spring.x(tau);
      final tiltProgress = UiCurves.easeOutStrong.transform(
        ((elapsedMs - 70.0) / 240.0).clamp(0.0, 1.0),
      );
      final tilt = lerpDouble(maxTilt, 0.0, tiltProgress)!;
      return (scale: scale, tilt: tilt);
    }
    return (scale: 1.0, tilt: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final reduced = UiMotion.reduced(context);
    final ctrl = _ctrl;
    final animating = !reduced && ctrl != null && ctrl.isAnimating;
    if (!animating) {
      return widget.child;
    }
    final ui = context.ui;
    final skinId = UiSkinScope.maybeOf(context)?.skin.id;
    final springDesc = UiSprings.forSkin(skinId ?? 'squad');
    final calmSkin = identical(springDesc, UiSprings.gentle);
    final suppressBurst = skinId == 'quiet';

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        if (_isAdding && !suppressBurst)
          Positioned.fill(
            child: ExcludeSemantics(
              child: IgnorePointer(
                child: RepaintBoundary(
                  key: ValueKey('reaction-burst-${widget.id}'),
                  child: CustomPaint(
                    key: ValueKey('reaction-burst-canvas-${widget.id}'),
                    painter: UiReactionBurstPainter(
                      animation: ctrl,
                      accentColor: ui.accent,
                      secondaryColor: ui.brand,
                      outlineColor: ui.outline,
                    ),
                  ),
                ),
              ),
            ),
          ),
        AnimatedBuilder(
          animation: ctrl,
          child: widget.child,
          builder: (context, child) {
            final (:scale, :tilt) = _evaluateIconTransform(calmSkin: calmSkin);
            return Transform.rotate(
              key: ValueKey('reaction-tilt-${widget.id}'),
              angle: tilt,
              child: Transform.scale(
                key: ValueKey('reaction-scale-${widget.id}'),
                scale: scale,
                child: child,
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Zero-allocation [CustomPainter] that radiates 5 mini geometric Neo-Brutalist
/// sticker particles (`18–28dp` radial travel, `opacity 1 -> 0` over
/// `90–480ms`) in `ui.accent` and `ui.brand`.
class UiReactionBurstPainter extends CustomPainter {
  UiReactionBurstPainter({
    required this.animation,
    required this.accentColor,
    required this.secondaryColor,
    required this.outlineColor,
  }) : super(repaint: animation);

  final Animation<double> animation;
  final Color accentColor;
  final Color secondaryColor;
  final Color outlineColor;

  static const List<double> _kAngles = <double>[
    -1.5707963, // top (-90 deg)
    -0.3490659, // top-right (-20 deg)
    0.7853982, // bottom-right (45 deg)
    2.3561945, // bottom-left (135 deg)
    -2.7925268, // top-left (-160 deg)
  ];

  /// Radial travel distances strictly within `18–28dp` (Moment #4 spec).
  static const List<double> _kTravelDistances = <double>[
    24.0,
    20.0,
    26.0,
    19.0,
    28.0,
  ];

  static const List<double> _kParticleRadii = <double>[
    3.2,
    2.8,
    3.4,
    2.6,
    3.0,
  ];

  final Paint _fillPaint = Paint()..style = PaintingStyle.fill;
  final Paint _strokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2
    ..strokeJoin = StrokeJoin.round;
  final Path _sparkPath = Path();

  /// Normalized burst progress in `[0.0, 1.0]` during `90–480ms` (`0.0` before
  /// `90ms`, `1.0` at `480ms`).
  double get burstProgress {
    final elapsedMs = animation.value * 480.0;
    if (elapsedMs <= 90.0) return 0.0;
    if (elapsedMs >= 480.0) return 1.0;
    return ((elapsedMs - 90.0) / 390.0).clamp(0.0, 1.0);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final elapsedMs = animation.value * 480.0;
    if (elapsedMs <= 90.0 || elapsedMs >= 480.0) return;

    final rawT = ((elapsedMs - 90.0) / 390.0).clamp(0.0, 1.0);
    final travelT = UiCurves.easeOutStrong.transform(rawT);
    final alpha = (1.0 - UiCurves.easeOutStrong.transform(rawT)).clamp(
      0.0,
      1.0,
    );
    if (alpha <= 0.001) return;

    final center = Offset(size.width / 2.0, size.height / 2.0);
    final scaleFactor = lerpDouble(1.0, 0.55, rawT)!;
    _strokePaint.color = outlineColor.withValues(alpha: alpha);

    for (var i = 0; i < 5; i++) {
      final angle = _kAngles[i];
      final distance = _kTravelDistances[i] * travelT;
      final pos = Offset(
        center.dx + math.cos(angle) * distance,
        center.dy + math.sin(angle) * distance,
      );
      final r = _kParticleRadii[i] * scaleFactor;
      final baseColor = i.isEven ? accentColor : secondaryColor;
      _fillPaint.color = baseColor.withValues(alpha: alpha);

      if (i % 3 == 0) {
        // Diamond sticker particle.
        _sparkPath
          ..reset()
          ..moveTo(pos.dx, pos.dy - r * 1.25)
          ..lineTo(pos.dx + r * 1.25, pos.dy)
          ..lineTo(pos.dx, pos.dy + r * 1.25)
          ..lineTo(pos.dx - r * 1.25, pos.dy)
          ..close();
        canvas
          ..drawPath(_sparkPath, _fillPaint)
          ..drawPath(_sparkPath, _strokePaint);
      } else if (i % 3 == 1) {
        // 4-point geometric vector spark.
        final inner = r * 0.48;
        final outer = r * 1.35;
        _sparkPath
          ..reset()
          ..moveTo(pos.dx, pos.dy - outer)
          ..lineTo(pos.dx + inner, pos.dy - inner)
          ..lineTo(pos.dx + outer, pos.dy)
          ..lineTo(pos.dx + inner, pos.dy + inner)
          ..lineTo(pos.dx, pos.dy + outer)
          ..lineTo(pos.dx - inner, pos.dy + inner)
          ..lineTo(pos.dx - outer, pos.dy)
          ..lineTo(pos.dx - inner, pos.dy - inner)
          ..close();
        canvas
          ..drawPath(_sparkPath, _fillPaint)
          ..drawPath(_sparkPath, _strokePaint);
      } else {
        // Crisp circular sticker dot.
        canvas
          ..drawCircle(pos, r, _fillPaint)
          ..drawCircle(pos, r, _strokePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant UiReactionBurstPainter oldDelegate) =>
      oldDelegate.animation != animation ||
      oldDelegate.accentColor != accentColor ||
      oldDelegate.secondaryColor != secondaryColor ||
      oldDelegate.outlineColor != outlineColor;
}
