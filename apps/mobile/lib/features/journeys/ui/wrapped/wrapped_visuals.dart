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
    this.exporting = false,
    this.hiddenPhotoIds = const {},
    super.key,
  });

  final PersonaSkinId skin;
  final WrappedStats stats;
  final int page;
  final bool blurPhotos;
  final bool exporting;
  final Set<String> hiddenPhotoIds;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final layout = stats.coupleSlots.isNotEmpty
        ? PersonaSkinId.coupleRituals
        : skin;
    final visual = switch (layout) {
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
                photos: _firstLast(_visiblePhotos),
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
        photos: _visiblePhotos.reversed.take(4).toList(),
        blur: blurPhotos,
      ),
      PersonaSkinId.coupleRituals => Row(
        key: const ValueKey('wrapped-couple-frame'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _Frame(checkIn: _couplePhoto(0), blur: blurPhotos),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: OurneyIcon(name: 'heart', size: 34, active: true),
          ),
          _Frame(checkIn: _couplePhoto(1), blur: blurPhotos),
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

  List<CheckIn> get _visiblePhotos =>
      exporting && hiddenPhotoIds.isNotEmpty
      ? [
          for (final c in stats.photos)
            if (!hiddenPhotoIds.contains(c.id)) c,
        ]
      : stats.photos;

  static List<CheckIn> _firstLast(List<CheckIn> all) => all.isEmpty
      ? const []
      : all.length == 1
      ? [all.first]
      : [all.first, all.last];

  CheckIn? _couplePhoto(int index) {
    final ownPhotos = _visiblePhotos;
    if (stats.coupleSlots.isEmpty) {
      return index == 0 ? ownPhotos.lastOrNull : null;
    }
    final slot = stats.coupleSlots[index];
    final photo = slot.checkIn;
    if (!exporting) return photo;
    if (!slot.isMine) return null;
    if (photo != null && !hiddenPhotoIds.contains(photo.id)) return photo;
    return ownPhotos.lastOrNull;
  }
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
  static const Duration _kFirstBeatDelay = Duration(milliseconds: 360);
  static const Duration _kSecondBeatDelay = Duration(milliseconds: 470);

  AnimationController? _ctrl;
  CurvedAnimation? _curved;
  Timer? _firstBeatTimer;
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
        // Double-beat milestone haptic (mediumImpact + 110ms lightImpact) synced
        // to the trophy rise settle / count climax (~360ms & ~470ms) via
        // disposable Timers.
        if (UiHaptics.enabled && TickerMode.valuesOf(context).enabled) {
          _firstBeatTimer = Timer(_kFirstBeatDelay, () {
            if (mounted &&
                UiHaptics.enabled &&
                TickerMode.valuesOf(context).enabled) {
              unawaited(UiHaptics.stampImpact());
            }
          });
          _secondBeatTimer = Timer(_kSecondBeatDelay, () {
            if (mounted &&
                UiHaptics.enabled &&
                TickerMode.valuesOf(context).enabled) {
              unawaited(UiHaptics.pressLight());
            }
          });
        }
      } else if (UiHaptics.enabled && TickerMode.valuesOf(context).enabled) {
        unawaited(UiHaptics.stampImpact());
      }
    } else if (UiMotion.reduced(context) && (_ctrl?.isAnimating ?? false)) {
      _firstBeatTimer?.cancel();
      _secondBeatTimer?.cancel();
      _ctrl?.value = 1.0;
    }
  }

  @override
  void dispose() {
    _firstBeatTimer?.cancel();
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
  const _Frame({required this.checkIn, required this.blur});

  final CheckIn? checkIn;
  final bool blur;

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
              : ImageFiltered(
                  enabled: blur,
                  imageFilter: ui_.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: JourneyPhoto(
                    key: ValueKey(c.id),
                    checkIn: c,
                    fallback: const SizedBox.shrink(),
                  ),
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
  const _Film({required this.photos, this.blur = false, super.key});

  final List<CheckIn> photos;
  final bool blur;

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
                  : ClipRect(
                      child: ImageFiltered(
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

  Size? _cachedSize;
  final List<Offset> _pts = <Offset>[];
  final Path _fullPath = Path();
  final Path _partialPath = Path();
  final List<ui_.PathMetric> _metrics = <ui_.PathMetric>[];

  void _ensureGeometry(Size size) {
    if (_cachedSize == size) return;
    _cachedSize = size;
    _pts
      ..clear()
      ..addAll([
        for (final p in points)
          Offset(6 + p.dx * (size.width - 12), 6 + p.dy * (size.height - 12)),
      ]);
    _fullPath
      ..reset()
      ..moveTo(_pts.first.dx, _pts.first.dy);
    for (var i = 1; i < _pts.length; i++) {
      if (smooth) {
        final mid = (_pts[i - 1].dx + _pts[i].dx) / 2;
        _fullPath.cubicTo(
          mid,
          _pts[i - 1].dy,
          mid,
          _pts[i].dy,
          _pts[i].dx,
          _pts[i].dy,
        );
      } else {
        _fullPath.lineTo(_pts[i].dx, _pts[i].dy);
      }
    }
    _metrics
      ..clear()
      ..addAll(_fullPath.computeMetrics());
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final t = progress.value.clamp(0.0, 1.0);
    if (t <= 0.0) return;

    _ensureGeometry(size);
    if (t >= 1.0) {
      canvas.drawPath(_fullPath, _strokePaint);
      canvas.drawCircle(_pts.last, 7, _dotPaint);
      return;
    }

    _partialPath.reset();
    for (final ui_.PathMetric m in _metrics) {
      _partialPath.addPath(m.extractPath(0.0, m.length * t), Offset.zero);
    }
    canvas.drawPath(_partialPath, _strokePaint);
    if (t >= 0.85) {
      final dotScale = ((t - 0.85) / 0.15).clamp(0.0, 1.0);
      canvas.drawCircle(_pts.last, 7.0 * dotScale, _dotPaint);
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
    final doneDecoration = BoxDecoration(
      color: widget.color,
      borderRadius: const BorderRadius.all(Radius.circular(3)),
    );
    final pendingDecoration = BoxDecoration(
      color: ui.fill,
      borderRadius: const BorderRadius.all(Radius.circular(3)),
    );

    return ExcludeSemantics(
      child: SizedBox(
        height: 96,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < n; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: _buildBarItem(
                    i: i,
                    n: n,
                    reduced: reduced,
                    ctrl: ctrl,
                    decoration: i < widget.done
                        ? doneDecoration
                        : pendingDecoration,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarItem({
    required int i,
    required int n,
    required bool reduced,
    required AnimationController? ctrl,
    required BoxDecoration decoration,
  }) {
    final fullHeight = 24 + ((i * 37) % 60).toDouble();
    final staticBar = SizedBox(
      width: double.infinity,
      height: fullHeight,
      child: DecoratedBox(decoration: decoration),
    );
    if (reduced || ctrl == null) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: Transform.scale(
          key: ValueKey('wrapped-bar-scale-$i'),
          scaleY: 1.0,
          alignment: Alignment.bottomCenter,
          child: staticBar,
        ),
      );
    }
    final start = n <= 1 ? 0.0 : (i / (n - 1)) * 0.45;
    return Align(
      alignment: Alignment.bottomCenter,
      child: AnimatedBuilder(
        animation: ctrl,
        child: staticBar,
        builder: (context, child) {
          final masterT = ctrl.value;
          final raw = ((masterT - start) / 0.55).clamp(0.0, 1.0);
          final barT = masterT >= 1.0
              ? 1.0
              : UiCurves.easeOutStrong.transform(raw);
          return Transform.scale(
            key: ValueKey('wrapped-bar-scale-$i'),
            scaleY: barT,
            alignment: Alignment.bottomCenter,
            child: child,
          );
        },
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
    final unreadBox = SizedBox(
      width: 18,
      height: 18,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: ui.border, width: 1.5),
        ),
      ),
    );
    final doneBox = SizedBox(
      width: 18,
      height: 18,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          border: Border.all(color: widget.color, width: 1.5),
        ),
      ),
    );

    return ExcludeSemantics(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: [
          for (var i = 0; i < n; i++)
            i >= completed
                ? unreadBox
                : _buildDoneTile(
                    ui: ui,
                    i: i,
                    completed: completed,
                    reduced: reduced,
                    ctrl: ctrl,
                    unreadBox: unreadBox,
                    doneBox: doneBox,
                  ),
        ],
      ),
    );
  }

  Widget _buildDoneTile({
    required OurneyUi ui,
    required int i,
    required int completed,
    required bool reduced,
    required AnimationController? ctrl,
    required Widget unreadBox,
    required Widget doneBox,
  }) {
    if (reduced || ctrl == null) {
      return Transform.scale(
        key: ValueKey('wrapped-chain-tile-$i'),
        scale: 1.0,
        child: doneBox,
      );
    }
    final start = completed <= 1 ? 0.0 : (i / (completed - 1)) * 0.72;
    return AnimatedBuilder(
      animation: ctrl,
      child: doneBox,
      builder: (context, child) {
        final masterT = ctrl.value;
        final raw = ((masterT - start) / 0.28).clamp(0.0, 1.0);
        if (raw <= 0.0) {
          return Transform.scale(
            key: ValueKey('wrapped-chain-tile-$i'),
            scale: 0.86,
            child: unreadBox,
          );
        }
        if (raw >= 1.0 || masterT >= 1.0) {
          return Transform.scale(
            key: ValueKey('wrapped-chain-tile-$i'),
            scale: 1.0,
            child: child,
          );
        }
        final tileT = UiCurves.easeOutStrong.transform(raw);
        final scale = ui_.lerpDouble(0.86, 1.0, tileT)!;
        final fillColor = Color.lerp(
          Colors.transparent,
          widget.color,
          tileT,
        )!;
        final borderColor = Color.lerp(ui.border, widget.color, tileT)!;
        return Transform.scale(
          key: ValueKey('wrapped-chain-tile-$i'),
          scale: scale,
          child: SizedBox(
            width: 18,
            height: 18,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: fillColor,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 1.5),
              ),
            ),
          ),
        );
      },
    );
  }
}
