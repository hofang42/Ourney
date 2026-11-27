import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens.dart';
import '../typography.dart';
import 'flow_kit.dart';

export 'brand_logo_paths.dart';

/// V2 `SplashFlow`: the cream field with the ransom-note wordmark, centered.
///
/// First launch ([returning] false / [firstLaunch] true): six tilted goal
/// stickers scattered at the edges pop in with shrinking wave delays
/// `[0, 40, 75, 105, 130, 150]ms` (`scale 0.88 -> 1.0` + fade, `220ms`,
/// [UiCurves.dockOvershoot]), and a [tagline] under the wordmark rotates with
/// a [FadeTransition]. Returning person ([returning] true): the wordmark alone
/// with a small spinner under it. Reduced motion renders static stickers,
/// stops the spinner, and skips tagline fades.
class UiSplash extends StatefulWidget {
  const UiSplash({
    this.tagline,
    this.returning = false,
    bool? firstLaunch,
    super.key,
  }) : firstLaunch = firstLaunch ?? !returning;

  final String? tagline;
  final bool returning;
  final bool firstLaunch;

  /// Design frame the sticker offsets were drawn on (V2 phone, 390x844).
  static const _frameH = 844.0;

  /// Non-uniform shrinking wave delays for the 6 first-launch goal stickers.
  static const List<Duration> stickerWaveDelays = <Duration>[
    Duration.zero,
    Duration(milliseconds: 40),
    Duration(milliseconds: 75),
    Duration(milliseconds: 105),
    Duration(milliseconds: 130),
    Duration(milliseconds: 150),
  ];

  static const Duration stickerPopDuration = UiMotion.medium;

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
  State<UiSplash> createState() => _UiSplashState();
}

class _UiSplashState extends State<UiSplash>
    with SingleTickerProviderStateMixin {
  static final Duration _kTotalWaveDuration =
      UiSplash.stickerWaveDelays.last + UiSplash.stickerPopDuration;

  AnimationController? _waveCtrl;
  final List<CurvedAnimation> _scaleCurves = <CurvedAnimation>[];
  final List<CurvedAnimation> _fadeCurves = <CurvedAnimation>[];
  final List<Animation<double>> _scaleAnims = <Animation<double>>[];
  bool _started = false;

  bool get _showStickers => !widget.returning && widget.firstLaunch;

  void _ensureWaveAnimations() {
    if (_waveCtrl != null) return;
    final totalMs = _kTotalWaveDuration.inMilliseconds.toDouble();
    final popMs = UiSplash.stickerPopDuration.inMilliseconds.toDouble();
    final ctrl = AnimationController(
      vsync: this,
      duration: _kTotalWaveDuration,
    );
    _waveCtrl = ctrl;
    for (var i = 0; i < UiSplash._stickers.length; i++) {
      final startMs = UiSplash.stickerWaveDelays[i].inMilliseconds.toDouble();
      final begin = (startMs / totalMs).clamp(0.0, 1.0);
      final end = ((startMs + popMs) / totalMs).clamp(0.0, 1.0);
      final scaleCurve = CurvedAnimation(
        parent: ctrl,
        curve: Interval(begin, end, curve: UiCurves.dockOvershoot),
      );
      final fadeCurve = CurvedAnimation(
        parent: ctrl,
        curve: Interval(begin, end, curve: UiCurves.easeOutStrong),
      );
      _scaleCurves.add(scaleCurve);
      _fadeCurves.add(fadeCurve);
      _scaleAnims.add(Tween<double>(begin: 0.88, end: 1.0).animate(scaleCurve));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = UiMotion.reduced(context);
    if (!_started) {
      _started = true;
      if (_showStickers && !reduce) {
        _ensureWaveAnimations();
        _waveCtrl!.forward();
      }
    } else if (reduce && (_waveCtrl?.isAnimating ?? false)) {
      _waveCtrl?.value = 1.0;
    }
  }

  @override
  void dispose() {
    for (final c in _scaleCurves) {
      c.dispose();
    }
    for (final c in _fadeCurves) {
      c.dispose();
    }
    _waveCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final reduce = UiMotion.reduced(context);
    const size = 174.0;
    final animateStickers =
        _showStickers && !reduce && _scaleAnims.length == UiSplash._stickers.length;

    return ColoredBox(
      key: const ValueKey('ui-splash'),
      color: ui.bg,
      child: LayoutBuilder(
        builder: (context, box) {
          // Vertical offsets follow the available height so the stickers
          // never crowd the wordmark on short screens.
          final fy = math.min(1.0, box.maxHeight / UiSplash._frameH);
          return Stack(
            fit: StackFit.expand,
            children: [
              if (_showStickers)
                for (var i = 0; i < UiSplash._stickers.length; i++)
                  () {
                    final (goal, l, r, t, b, deg) = UiSplash._stickers[i];
                    Widget tile = UiStickerTile(
                      key: ValueKey('ui-splash-sticker-$i'),
                      color: goal.color,
                      degrees: deg,
                      child: UiGoalGlyph(goal: goal, size: 31),
                    );
                    if (animateStickers) {
                      tile = FadeTransition(
                        opacity: _fadeCurves[i],
                        child: ScaleTransition(
                          scale: _scaleAnims[i],
                          child: tile,
                        ),
                      );
                    }
                    return Positioned(
                      left: l,
                      right: r,
                      top: t == null ? null : t * fy,
                      bottom: b == null ? null : b * fy,
                      child: ExcludeSemantics(child: tile),
                    );
                  }(),
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
                          if (widget.returning)
                            Positioned(
                              left: size / 2 - 15,
                              top: 76,
                              child: RepaintBoundary(
                                child: _Loader(animate: !reduce),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (widget.tagline != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
                        child: UiFadeThroughSwitcher(
                          duration: UiMotion.normal,
                          scaleBegin: 1.0,
                          instantOnReduceMotion: true,
                          alignment: Alignment.center,
                          child: Text(
                            widget.tagline!,
                            key: ValueKey(widget.tagline),
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
