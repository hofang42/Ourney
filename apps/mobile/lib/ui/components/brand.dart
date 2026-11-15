import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens.dart';
import '../typography.dart';
import 'flow_kit.dart';

/// `.wordmark`: "ourney" in Bricolage 800 with -0.07em tracking.
class UiWordmark extends StatelessWidget {
  const UiWordmark({this.size = 46, this.color, super.key});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Ourney',
    excludeSemantics: true,
    child: Text(
      'ourney',
      maxLines: 1,
      style: UiText.wordmark(size: size, color: color ?? context.ui.ink),
    ),
  );
}

/// V2 `SplashFlow`: the cream field with the ransom-note wordmark, centered.
///
/// First launch ([returning] false): six tilted goal stickers scattered at
/// the edges and a [tagline] under the wordmark (the caller rotates it; each
/// new line fades in over 300ms). Returning person ([returning] true): the
/// wordmark alone with a small spinner under it. Reduced motion stops the
/// spinner and the tagline fade.
class UiSplash extends StatelessWidget {
  const UiSplash({this.tagline, this.returning = false, super.key});

  final String? tagline;
  final bool returning;

  /// Design frame the sticker offsets were drawn on (V2 phone, 390x844).
  static const _frameH = 844.0;

  // (goal, left, right, top, bottom, degrees) from `.sticker-1..6`.
  static const _stickers =
      <(UiFlowGoal, double?, double?, double?, double?, double)>[
        (UiFlowGoal.weight, 32, null, 112, null, -8),
        (UiFlowGoal.english, null, 30, 150, null, 6),
        (UiFlowGoal.workout, 44, null, null, 152, 5),
        (UiFlowGoal.trip, null, 42, null, 126, -6),
        (UiFlowGoal.couple, null, 25, 318, null, 8),
        (UiFlowGoal.habit, 24, null, 335, null, -4),
      ];

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    const size = 174.0;
    return ColoredBox(
      key: const ValueKey('ui-splash'),
      color: ui.bg,
      child: LayoutBuilder(
        builder: (context, box) {
          // Vertical offsets follow the available height so the stickers
          // never crowd the wordmark on short screens.
          final fy = math.min(1.0, box.maxHeight / _frameH);
          return Stack(
            fit: StackFit.expand,
            children: [
              if (!returning)
                for (final (goal, l, r, t, b, deg) in _stickers)
                  Positioned(
                    left: l,
                    right: r,
                    top: t == null ? null : t * fy,
                    bottom: b == null ? null : b * fy,
                    child: ExcludeSemantics(
                      child: UiStickerTile(
                        color: goal.color,
                        degrees: deg,
                        child: UiGoalGlyph(goal: goal, size: 31),
                      ),
                    ),
                  ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: size,
                      height: size * .3,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const UiRansomWordmark(size: size),
                          if (returning)
                            Positioned(
                              left: size / 2 - 15,
                              top: 76,
                              child: _Loader(animate: !reduce),
                            ),
                        ],
                      ),
                    ),
                    if (tagline != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
                        child: TweenAnimationBuilder<double>(
                          key: ValueKey(tagline),
                          tween: Tween(begin: reduce ? 1 : 0, end: 1),
                          duration: UiMotion.of(
                            context,
                            const Duration(milliseconds: 300),
                          ),
                          curve: Curves.easeOut,
                          builder: (context, t, child) =>
                              Opacity(opacity: t, child: child),
                          child: Text(
                            tagline!,
                            textAlign: TextAlign.center,
                            style: UiText.body(
                              size: 18,
                              weight: FontWeight.w500,
                              // `.app-dark .splash-flow > p`: full ink.
                              color: ui.isDark ? ui.ink : ui.inkMuted,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// `.returning-loader`: 30dp ring, ink at 18% with a brand arc, 700ms/turn.
class _Loader extends StatefulWidget {
  const _Loader({required this.animate});

  final bool animate;

  @override
  State<_Loader> createState() => _LoaderState();
}

class _LoaderState extends State<_Loader> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _c.repeat();
  }

  @override
  void didUpdateWidget(_Loader old) {
    super.didUpdateWidget(old);
    if (widget.animate && !_c.isAnimating) _c.repeat();
    if (!widget.animate) _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return Semantics(
      label: 'ourney',
      child: RotationTransition(
        turns: _c,
        child: SizedBox(
          width: 30,
          height: 30,
          child: CustomPaint(
            painter: _RingPainter(
              track: ui.ink.withValues(alpha: .18),
              arc: ui.brand,
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.track, required this.arc});

  final Color track;
  final Color arc;

  @override
  void paint(Canvas canvas, Size size) {
    const w = 3.0;
    final rect = (Offset.zero & size).deflate(w / 2);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w;
    canvas.drawArc(rect, 0, math.pi * 2, false, p..color = track);
    // Only the top quarter is coloured (`border-top-color`).
    canvas.drawArc(rect, -math.pi * 3 / 4, math.pi / 2, false, p..color = arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.track != track || old.arc != arc;
}
