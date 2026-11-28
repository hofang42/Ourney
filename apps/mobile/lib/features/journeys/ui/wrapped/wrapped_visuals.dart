import 'dart:math' as math;
import 'dart:ui' as ui_;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../../ui/ui.dart';
import '../../domain/wrapped_story.dart';
import '../journey_photo.dart';

/// Photo and data visuals used on the Wrapped summary card.
class WrappedVisual extends StatelessWidget {
  const WrappedVisual({
    required this.skin,
    required this.stats,
    required this.page,
    this.isRun,
    this.blurPhotos = false,
    this.exporting = false,
    this.hiddenPhotoIds = const {},
    super.key,
  });

  final PersonaSkinId skin;
  final WrappedStats stats;
  final int page;
  final bool? isRun;
  final bool blurPhotos;
  final bool exporting;
  final Set<String> hiddenPhotoIds;

  @override
  Widget build(BuildContext context) {
    final layout = stats.coupleSlots.isNotEmpty
        ? PersonaSkinId.coupleRituals
        : skin;
    final photos = [
      for (final photo in stats.photos)
        if (!_isHidden(photo)) photo,
    ];
    final visibleSlots = [
      for (final slot in stats.coupleSlots)
        if (!exporting || slot.isMine)
          ?_slotPhoto(slot.checkIn, slot.isMine, photos.lastOrNull),
    ];
    final visual = switch (layout) {
      PersonaSkinId.quietTransformer => _PhotoFrames(
        key: const ValueKey('wrapped-quiet-photos'),
        photos: [
          if (photos.isNotEmpty) photos.first,
          if (photos.length > 1) photos.last,
        ],
        blur: blurPhotos,
      ),
      PersonaSkinId.accountabilitySquad => const Center(
        child: SizedBox.square(
          key: ValueKey('wrapped-summary-trophy'),
          dimension: 54,
          child: OurneyIcon(name: 'trophy', size: 54, active: true),
        ),
      ),
      PersonaSkinId.memoryCollectors => _Film(
        key: const ValueKey('wrapped-memory-film'),
        photos: photos.reversed.take(4).toList(),
        blur: blurPhotos,
      ),
      PersonaSkinId.coupleRituals => _PhotoFrames(
        key: const ValueKey('wrapped-couple-frame'),
        photos: stats.coupleSlots.isEmpty ? [?photos.lastOrNull] : visibleSlots,
        blur: blurPhotos,
        couple: true,
      ),
      PersonaSkinId.aestheticFlexer => WrappedBars(
        key: const ValueKey('wrapped-flexer-bars'),
        values: (isRun ?? stats.kmPerDay.isNotEmpty)
            ? stats.kmPerDay
            : stats.minutesPerDay,
      ),
      PersonaSkinId.minimalistHabit => WrappedChain(
        key: const ValueKey('wrapped-minimal-chain'),
        days: stats.chainDays,
        start: stats.memberStart,
      ),
    };
    return RepaintBoundary(child: visual);
  }

  bool _isHidden(CheckIn checkIn) =>
      exporting && hiddenPhotoIds.contains(checkIn.id);

  CheckIn? _slotPhoto(CheckIn? photo, bool isMine, CheckIn? fallback) {
    if (photo != null && !_isHidden(photo)) return photo;
    return isMine ? fallback : null;
  }
}

class _PhotoFrames extends StatelessWidget {
  const _PhotoFrames({
    required this.photos,
    required this.blur,
    this.couple = false,
    super.key,
  });

  final List<CheckIn> photos;
  final bool blur;
  final bool couple;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final heartWidth = couple ? 50.0 : 12.0;
        final width = math.min(
          couple ? 120.0 : 130.0,
          photos.length == 1
              ? constraints.maxWidth
              : (constraints.maxWidth - heartWidth) / 2,
        );
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _frame(context, photos.first, width),
            if (photos.length > 1) ...[
              SizedBox(
                width: heartWidth,
                child: couple
                    ? const OurneyIcon(name: 'heart', size: 34, active: true)
                    : null,
              ),
              _frame(context, photos.last, width),
            ],
          ],
        );
      },
    );
  }

  Widget _frame(BuildContext context, CheckIn checkIn, double width) {
    final ui = context.ui;
    return Container(
      key: ValueKey('wrapped-summary-photo-${checkIn.id}'),
      width: width,
      height: width * 4 / 3,
      decoration: BoxDecoration(
        color: ui.fill,
        borderRadius: BorderRadius.circular(UiRadius.input),
        border: Border.all(color: ui.outline, width: couple ? 2 : 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: WrappedPhoto(checkIn: checkIn, blur: blur),
    );
  }
}

class _Film extends StatelessWidget {
  const _Film({required this.photos, required this.blur, super.key});

  final List<CheckIn> photos;
  final bool blur;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final photo in photos)
          Container(
            width: 68,
            height: 88,
            decoration: BoxDecoration(
              color: ui.fill,
              border: Border.all(color: ui.outline, width: 2),
            ),
            clipBehavior: Clip.hardEdge,
            child: WrappedPhoto(checkIn: photo, blur: blur),
          ),
      ],
    );
  }
}

/// Same bounded thumbnail source for story frames and the exported summary.
class WrappedPhoto extends StatelessWidget {
  const WrappedPhoto({
    required this.checkIn,
    required this.blur,
    this.cacheWidth,
    this.thumbnail = true,
    super.key,
  });

  final CheckIn checkIn;
  final bool blur;
  final int? cacheWidth;
  final bool thumbnail;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: ImageFiltered(
        enabled: blur,
        imageFilter: ui_.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: JourneyPhoto(
          key: ValueKey(checkIn.id),
          checkIn: checkIn,
          cacheWidth: cacheWidth,
          thumbnail: thumbnail,
          fallback: const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class WrappedCurve extends StatefulWidget {
  const WrappedCurve({
    required this.values,
    this.smooth = false,
    this.paused = false,
    super.key,
  });

  final List<double> values;
  final bool smooth;

  final bool paused;

  @override
  State<WrappedCurve> createState() => _CurveState();
}

class _CurveState extends State<WrappedCurve>
    with SingleTickerProviderStateMixin {
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
        if (!widget.paused) ctrl.forward(from: 0.0);
      }
    } else if (UiMotion.reduced(context) &&
        (_revealCtrl?.isAnimating ?? false)) {
      _revealCtrl?.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant WrappedCurve oldWidget) {
    super.didUpdateWidget(oldWidget);
    final ctrl = _revealCtrl;
    if (ctrl == null || ctrl.isCompleted || UiMotion.reduced(context)) return;
    if (widget.paused) {
      ctrl.stop();
    } else if (!ctrl.isAnimating) {
      ctrl.forward();
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
    final values = widget.values;
    if (values.length < 2) return const SizedBox.shrink();
    final min = values.reduce(math.min);
    final max = values.reduce(math.max);
    final range = max - min;
    final points = [
      for (var i = 0; i < values.length; i++)
        Offset(
          i / (values.length - 1),
          range == 0 ? .5 : (max - values[i]) / range,
        ),
    ];
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
            context.ui.accent,
            points,
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

class WrappedBars extends StatefulWidget {
  const WrappedBars({required this.values, this.paused = false, super.key});

  final Map<LocalDate, num> values;

  final bool paused;

  @override
  State<WrappedBars> createState() => _BarsState();
}

class _BarsState extends State<WrappedBars>
    with SingleTickerProviderStateMixin {
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
        if (!widget.paused) ctrl.forward(from: 0.0);
      }
    } else if (UiMotion.reduced(context) && (_ctrl?.isAnimating ?? false)) {
      _ctrl?.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant WrappedBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    final ctrl = _ctrl;
    if (ctrl == null || ctrl.isCompleted || UiMotion.reduced(context)) return;
    if (widget.paused) {
      ctrl.stop();
    } else if (!ctrl.isAnimating) {
      ctrl.forward();
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  List<num> _barValues() {
    final dates = widget.values.keys.toList()..sort();
    if (dates.isEmpty) return const [];
    final first = dates.first;
    final span = first.daysUntil(dates.last) + 1;
    if (span <= 30) {
      return [for (final date in dates) widget.values[date]!];
    }

    final weekday = DateTime.utc(first.year, first.month, first.day).weekday;
    final monday = first.addDays(1 - weekday);
    final weekCount = monday.daysUntil(dates.last) ~/ 7 + 1;
    final weeksPerBar = (weekCount / 30).ceil();
    final daysPerBar = 7 * weeksPerBar;
    final buckets = <int, num>{};
    for (final date in dates) {
      final bucket = monday.daysUntil(date) ~/ daysPerBar;
      buckets.update(
        bucket,
        (total) => total + widget.values[date]!,
        ifAbsent: () => widget.values[date]!,
      );
    }
    return buckets.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final reduced = UiMotion.reduced(context);
    final ctrl = _ctrl;
    final values = _barValues();
    if (values.isEmpty) return const SizedBox.shrink();
    final peak = values.reduce(math.max);
    if (peak <= 0) return const SizedBox.shrink();
    final n = values.length;
    final decoration = BoxDecoration(
      color: ui.accent,
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
                    decoration: decoration,
                    fullHeight: 96 * values[i] / peak,
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
    required double fullHeight,
  }) {
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

class WrappedChain extends StatefulWidget {
  const WrappedChain({
    required this.days,
    required this.start,
    this.paused = false,
    super.key,
  });

  final List<bool> days;
  final LocalDate? start;

  final bool paused;

  @override
  State<WrappedChain> createState() => _ChainState();
}

class _ChainState extends State<WrappedChain>
    with SingleTickerProviderStateMixin {
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
        if (!widget.paused) ctrl.forward(from: 0.0);
      }
    } else if (UiMotion.reduced(context) && (_ctrl?.isAnimating ?? false)) {
      _ctrl?.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant WrappedChain oldWidget) {
    super.didUpdateWidget(oldWidget);
    final ctrl = _ctrl;
    if (ctrl == null || ctrl.isCompleted || UiMotion.reduced(context)) return;
    if (widget.paused) {
      ctrl.stop();
    } else if (!ctrl.isAnimating) {
      ctrl.forward();
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
    final n = widget.days.length;
    final start = widget.start;
    if (n > 60 && start != null) {
      return ExcludeSemantics(child: _monthRows(context, start));
    }
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
          color: ui.accent,
          shape: BoxShape.circle,
          border: Border.all(color: ui.accent, width: 1.5),
        ),
      ),
    );

    return ExcludeSemantics(
      child: Align(
        child: SizedBox(
          width: 7 * 18 + 6 * 6,
          child: Wrap(
            alignment: WrapAlignment.start,
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < n; i++)
                widget.days[i]
                    ? _buildDoneTile(
                        ui: ui,
                        i: i,
                        dayCount: n,
                        reduced: reduced,
                        ctrl: ctrl,
                        unreadBox: unreadBox,
                        doneBox: doneBox,
                      )
                    : unreadBox,
            ],
          ),
        ),
      ),
    );
  }

  Widget _monthRows(BuildContext context, LocalDate start) {
    final ui = context.ui;
    final monthCounts = <DateTime, int>{};
    for (var i = 0; i < widget.days.length; i++) {
      final date = start.addDays(i);
      final month = DateTime(date.year, date.month);
      monthCounts.update(
        month,
        (count) => count + (widget.days[i] ? 1 : 0),
        ifAbsent: () => widget.days[i] ? 1 : 0,
      );
    }
    final locale = Localizations.localeOf(context).toString();
    final dateFormat = DateFormat.yMMM(locale);
    final countFormat = NumberFormat.decimalPattern(locale);
    final style = UiText.body(size: 14, height: 1.35, color: ui.ink);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final entry in monthCounts.entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Expanded(
                  child: Text(dateFormat.format(entry.key), style: style),
                ),
                Text(countFormat.format(entry.value), style: style),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDoneTile({
    required OurneyUi ui,
    required int i,
    required int dayCount,
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
    final start = dayCount <= 1 ? 0.0 : (i / (dayCount - 1)) * 0.72;
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
        final fillColor = Color.lerp(Colors.transparent, ui.accent, tileT)!;
        final borderColor = Color.lerp(ui.border, ui.accent, tileT)!;
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
