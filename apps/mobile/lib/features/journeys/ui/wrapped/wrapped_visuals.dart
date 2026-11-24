import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui_;

import 'package:flutter/material.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../../ui/ui.dart';
import '../../domain/wrapped_story.dart';
import '../journey_photo.dart';

/// `WrappedVisual`: the drawing above a story headline, per skin. Built from
/// the journey's own photos where the Figma shows photos, and from drawn
/// shapes (curve, trophy path, bars, chain) elsewhere.
class WrappedVisual extends StatelessWidget {
  const WrappedVisual({
    required this.skin,
    required this.stats,
    required this.page,
    this.blurPhotos = false,
    super.key,
  });

  final PersonaSkinId skin;
  final WrappedStats stats;
  final int page;
  final bool blurPhotos;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final visual = switch (skin) {
      PersonaSkinId.quietTransformer =>
        page == 2
            ? _Curve(
                key: const ValueKey('wrapped-quiet-curve'),
                color: ui.accent,
                points: const [
                  Offset(0, .82),
                  Offset(.28, .63),
                  Offset(.43, .77),
                  Offset(.6, .37),
                  Offset(.84, .23),
                  Offset(1, .1),
                ],
                smooth: true,
              )
            : _Photos(
                key: const ValueKey('wrapped-quiet-photos'),
                photos: _firstLast(stats.photos),
                blur: blurPhotos,
              ),
      PersonaSkinId.accountabilitySquad =>
        page == 2
            ? _Trophy(
                key: const ValueKey('wrapped-trophy'),
                days: stats.days,
                total: stats.total,
              )
            : Row(
                key: const ValueKey('wrapped-squad-path'),
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < 4; i++)
                    Container(
                      width: 17,
                      height: 17,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: ui.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: ui.outline, width: 2),
                      ),
                    ),
                  const OurneyIcon(name: 'trophy', size: 28, active: true),
                ],
              ),
      PersonaSkinId.memoryCollectors => _Film(
        key: const ValueKey('wrapped-memory-film'),
        photos: stats.photos.reversed.take(4).toList(),
      ),
      PersonaSkinId.coupleRituals => Row(
        key: const ValueKey('wrapped-couple-frame'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _Frame(
            checkIn: stats.photos.isEmpty ? null : stats.photos.first,
            partner: false,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: OurneyIcon(name: 'heart', size: 34, active: true),
          ),
          _Frame(
            checkIn: stats.photos.isEmpty ? null : stats.photos.last,
            partner: true,
          ),
        ],
      ),
      PersonaSkinId.aestheticFlexer =>
        page == 2
            ? _Curve(
                key: const ValueKey('wrapped-flexer-chart'),
                color: ui.accent,
                points: const [
                  Offset(0, .82),
                  Offset(.14, .68),
                  Offset(.28, .73),
                  Offset(.4, .39),
                  Offset(.54, .54),
                  Offset(.68, .24),
                  Offset(.82, .36),
                  Offset(1, .08),
                ],
              )
            : _Bars(
                key: const ValueKey('wrapped-flexer-bars'),
                done: stats.days,
                total: stats.total,
                color: ui.accent,
              ),
      PersonaSkinId.minimalistHabit => _Chain(
        key: const ValueKey('wrapped-minimal-chain'),
        done: stats.days,
        total: stats.total,
        color: ui.accent,
      ),
    };
    return RepaintBoundary(child: visual);
  }

  static List<CheckIn> _firstLast(List<CheckIn> all) => all.isEmpty
      ? const []
      : all.length == 1
      ? [all.first]
      : [all.first, all.last];
}

/// Climax slide trophy: rises `32dp` over `560ms` ([UiCurves.stampDecel]) with
/// a [UiCountRoll] odometer badge and celebratory double-beat haptic.
class _Trophy extends StatefulWidget {
  const _Trophy({
    required this.days,
    required this.total,
    super.key,
  });

  final int days;
  final int total;

  @override
  State<_Trophy> createState() => _TrophyState();
}

class _TrophyState extends State<_Trophy>
    with SingleTickerProviderStateMixin {
  static const Duration _kDuration = Duration(milliseconds: 560);

  AnimationController? _ctrl;
  CurvedAnimation? _curved;
  Timer? _secondBeatTimer;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      if (!UiMotion.reduced(context)) {
        final ctrl = AnimationController(vsync: this, duration: _kDuration);
        _ctrl = ctrl;
        _curved = CurvedAnimation(parent: ctrl, curve: UiCurves.stampDecel);
        ctrl.forward(from: 0.0);
        // Double-beat milestone haptic (mediumImpact + 110ms lightImpact) using
        // a disposable Timer so widget disposal in tests never leaves a
        // pending timer.
        if (UiHaptics.enabled) {
          unawaited(UiHaptics.stampImpact());
          _secondBeatTimer = Timer(const Duration(milliseconds: 110), () {
            if (mounted && UiHaptics.enabled) {
              unawaited(UiHaptics.pressLight());
            }
          });
        }
      }
    } else if (UiMotion.reduced(context) && (_ctrl?.isAnimating ?? false)) {
      _ctrl?.value = 1.0;
    }
  }

  @override
  void dispose() {
    _secondBeatTimer?.cancel();
    _curved?.dispose();
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final reduced = UiMotion.reduced(context);
    final curved = _curved;
    final pct = widget.total <= 0
        ? 100
        : ((widget.days / widget.total) * 100).round().clamp(0, 100);
    final badge = ExcludeSemantics(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const OurneyIcon(
            name: 'trophy',
            size: 94,
            active: true,
            semanticLabel: null,
          ),
          const SizedBox(height: UiSpace.xs),
          UiCountRoll(
            key: const ValueKey('wrapped-trophy-count'),
            value: pct,
            initialValue: math.max(0, pct - 1),
            format: (v) => '${widget.days}/${widget.total} · $v%',
            style: UiText.eyebrow(color: ui.inkMuted),
          ),
        ],
      ),
    );
    if (reduced || curved == null) return badge;
    final faded = FadeTransition(opacity: curved, child: badge);
    return AnimatedBuilder(
      animation: curved,
      child: faded,
      builder: (context, child) {
        final dy = (1.0 - curved.value) * 32.0;
        return Transform.translate(
          offset: Offset(0, dy),
          child: child,
        );
      },
    );
  }
}

class _Frame extends StatelessWidget {
  const _Frame({required this.checkIn, required this.partner});

  final CheckIn? checkIn;
  final bool partner;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final c = checkIn;
    return Flexible(
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 120),
          decoration: BoxDecoration(
            color: ui.fill,
            borderRadius: BorderRadius.circular(UiRadius.input),
            border: Border.all(color: ui.outline, width: 2),
          ),
          clipBehavior: Clip.antiAlias,
          child: c == null
              ? null
              : JourneyPhoto(
                  checkIn: c,
                  partner: partner && c.partnerPhotoPath != null,
                  fallback: const SizedBox.shrink(),
                ),
        ),
      ),
    );
  }
}

class _Photos extends StatelessWidget {
  const _Photos({required this.photos, required this.blur, super.key});

  final List<CheckIn> photos;
  final bool blur;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final items = photos.isEmpty ? <CheckIn?>[null, null] : photos;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final c in items)
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 130),
                  decoration: BoxDecoration(
                    color: ui.fill,
                    borderRadius: BorderRadius.circular(UiRadius.input),
                    border: Border.all(color: ui.outline, width: 1.5),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: c == null
                      ? null
                      : ImageFiltered(
                          enabled: blur,
                          imageFilter: ui_.ImageFilter.blur(
                            sigmaX: 14,
                            sigmaY: 14,
                          ),
                          child: JourneyPhoto(
                            checkIn: c,
                            fallback: const SizedBox.shrink(),
                          ),
                        ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Film extends StatelessWidget {
  const _Film({required this.photos, super.key});

  final List<CheckIn> photos;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final items = photos.isEmpty
        ? List<CheckIn?>.filled(4, null)
        : <CheckIn?>[...photos];
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final c in items)
          SizedBox(
            width: 68,
            height: 88,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: ui.fill,
                border: Border.all(color: ui.outline, width: 2),
              ),
              child: c == null
                  ? null
                  : JourneyPhoto(checkIn: c, fallback: const SizedBox.shrink()),
            ),
          ),
      ],
    );
  }
}

class _Curve extends StatefulWidget {
  const _Curve({
    required this.color,
    required this.points,
    this.smooth = false,
    super.key,
  });

  final Color color;
  final List<Offset> points;
  final bool smooth;

  @override
  State<_Curve> createState() => _CurveState();
}

class _CurveState extends State<_Curve> with SingleTickerProviderStateMixin {
  static const Duration _kDuration = Duration(milliseconds: 680);

  AnimationController? _revealCtrl;
  CurvedAnimation? _curved;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      if (!UiMotion.reduced(context)) {
        final ctrl = AnimationController(vsync: this, duration: _kDuration);
        _revealCtrl = ctrl;
        _curved = CurvedAnimation(parent: ctrl, curve: UiCurves.easeOutStrong);
        ctrl.forward(from: 0.0);
      }
    } else if (UiMotion.reduced(context) &&
        (_revealCtrl?.isAnimating ?? false)) {
      _revealCtrl?.value = 1.0;
    }
  }

  @override
  void dispose() {
    _curved?.dispose();
    _revealCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = UiMotion.reduced(context);
    final progress = reduced
        ? const AlwaysStoppedAnimation<double>(1.0)
        : (_curved ?? const AlwaysStoppedAnimation<double>(1.0));
    return ExcludeSemantics(
      child: SizedBox(
        height: 110,
        width: double.infinity,
        child: CustomPaint(
          painter: _CurvePainter(
            widget.color,
            widget.points,
            widget.smooth,
            progress,
          ),
        ),
      ),
    );
  }
}

class _CurvePainter extends CustomPainter {
  _CurvePainter(this.color, this.points, this.smooth, this.progress)
    : _strokePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
      _dotPaint = Paint()..color = color,
      super(repaint: progress);

  final Color color;
  final List<Offset> points;
  final bool smooth;
  final Animation<double> progress;
  final Paint _strokePaint;
  final Paint _dotPaint;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value.clamp(0.0, 1.0);
    if (t <= 0.0) return;

    final pts = [
      for (final p in points)
        Offset(6 + p.dx * (size.width - 12), 6 + p.dy * (size.height - 12)),
    ];
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      if (smooth) {
        final mid = (pts[i - 1].dx + pts[i].dx) / 2;
        path.cubicTo(mid, pts[i - 1].dy, mid, pts[i].dy, pts[i].dx, pts[i].dy);
      } else {
        path.lineTo(pts[i].dx, pts[i].dy);
      }
    }
    if (t >= 1.0) {
      canvas.drawPath(path, _strokePaint);
      canvas.drawCircle(pts.last, 7, _dotPaint);
      return;
    }

    final partial = Path();
    for (final ui_.PathMetric m in path.computeMetrics()) {
      partial.addPath(m.extractPath(0.0, m.length * t), Offset.zero);
    }
    canvas.drawPath(partial, _strokePaint);
    if (t >= 0.85) {
      final dotScale = ((t - 0.85) / 0.15).clamp(0.0, 1.0);
      canvas.drawCircle(pts.last, 7.0 * dotScale, _dotPaint);
    }
  }

  @override
  bool shouldRepaint(_CurvePainter old) =>
      old.color != color ||
      old.points != points ||
      old.smooth != smooth ||
      old.progress != progress;
}

class _Bars extends StatefulWidget {
  const _Bars({
    required this.done,
    required this.total,
    required this.color,
    super.key,
  });

  final int done;
  final int total;
  final Color color;

  @override
  State<_Bars> createState() => _BarsState();
}

class _BarsState extends State<_Bars> with SingleTickerProviderStateMixin {
  static const Duration _kDuration = Duration(milliseconds: 620);

  AnimationController? _ctrl;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      if (!UiMotion.reduced(context)) {
        final ctrl = AnimationController(vsync: this, duration: _kDuration);
        _ctrl = ctrl;
        ctrl.forward(from: 0.0);
      }
    } else if (UiMotion.reduced(context) && (_ctrl?.isAnimating ?? false)) {
      _ctrl?.value = 1.0;
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final reduced = UiMotion.reduced(context);
    final ctrl = _ctrl;
    final n = widget.total.clamp(1, 30);

    Widget buildRow(double masterT) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < n; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: _buildBar(ui, i, n, masterT),
              ),
            ),
        ],
      );
    }

    return ExcludeSemantics(
      child: SizedBox(
        height: 96,
        child: (reduced || ctrl == null)
            ? buildRow(1.0)
            : AnimatedBuilder(
                animation: ctrl,
                builder: (context, _) => buildRow(ctrl.value),
              ),
      ),
    );
  }

  Widget _buildBar(OurneyUi ui, int i, int n, double masterT) {
    final fullHeight = 24 + ((i * 37) % 60).toDouble();
    final start = n <= 1 ? 0.0 : (i / (n - 1)) * 0.45;
    final raw = ((masterT - start) / 0.55).clamp(0.0, 1.0);
    final barT = masterT >= 1.0 ? 1.0 : UiCurves.easeOutStrong.transform(raw);
    return Align(
      alignment: Alignment.bottomCenter,
      child: Transform.scale(
        key: ValueKey('wrapped-bar-scale-$i'),
        scaleY: barT,
        alignment: Alignment.bottomCenter,
        child: Container(
          height: fullHeight,
          decoration: BoxDecoration(
            color: i < widget.done ? widget.color : ui.fill,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}

class _Chain extends StatefulWidget {
  const _Chain({
    required this.done,
    required this.total,
    required this.color,
    super.key,
  });

  final int done;
  final int total;
  final Color color;

  @override
  State<_Chain> createState() => _ChainState();
}

class _ChainState extends State<_Chain> with SingleTickerProviderStateMixin {
  static const Duration _kDuration = Duration(milliseconds: 580);

  AnimationController? _ctrl;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      if (!UiMotion.reduced(context)) {
        final ctrl = AnimationController(vsync: this, duration: _kDuration);
        _ctrl = ctrl;
        ctrl.forward(from: 0.0);
      }
    } else if (UiMotion.reduced(context) && (_ctrl?.isAnimating ?? false)) {
      _ctrl?.value = 1.0;
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final reduced = UiMotion.reduced(context);
    final ctrl = _ctrl;
    final n = widget.total.clamp(1, 60);
    final completed = widget.done.clamp(0, n);

    Widget buildWrap(double masterT) {
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: [
          for (var i = 0; i < n; i++) _buildTile(ui, i, completed, masterT),
        ],
      );
    }

    return ExcludeSemantics(
      child: (reduced || ctrl == null)
          ? buildWrap(1.0)
          : AnimatedBuilder(
              animation: ctrl,
              builder: (context, _) => buildWrap(ctrl.value),
            ),
    );
  }

  Widget _buildTile(OurneyUi ui, int i, int completed, double masterT) {
    final isDone = i < completed;
    if (!isDone) {
      return Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(color: ui.border, width: 1.5),
        ),
      );
    }
    final start = completed <= 1 ? 0.0 : (i / (completed - 1)) * 0.72;
    final raw = ((masterT - start) / 0.28).clamp(0.0, 1.0);
    final tileT = masterT >= 1.0 ? 1.0 : UiCurves.easeOutStrong.transform(raw);
    final scale = ui_.lerpDouble(0.86, 1.0, tileT)!;
    final fillColor = Color.lerp(Colors.transparent, widget.color, tileT)!;
    final borderColor = Color.lerp(ui.border, widget.color, tileT)!;

    return Transform.scale(
      key: ValueKey('wrapped-chain-tile-$i'),
      scale: scale,
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: fillColor,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 1.5),
        ),
      ),
    );
  }
}
