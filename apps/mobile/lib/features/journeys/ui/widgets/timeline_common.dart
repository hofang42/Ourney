import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import '../../../../ui/ui.dart';
import '../../domain/journey_progress.dart';
import '../../domain/journey_time.dart';
import '../../l10n/generated/journeys_localizations.dart';
import '../journey_photo.dart';

export '../../domain/timeline_window.dart' show cumulativeSeries;

/// Accent of the journey skin in scope (the selected variant).
Color timelineAccent(BuildContext context) =>
    UiSkinScope.maybeOf(context)?.variant.accent ?? context.ui.brand;

/// Text- and icon-safe accent of the journey skin in scope (>= 4.5:1 on bg
/// and surface). Fills and lines keep [timelineAccent].
Color timelineAccentText(BuildContext context) => context.ui.accentText;

/// Heading style of the skin in scope (falls back to the body font).
TextStyle timelineHeading(BuildContext context, {double size = 15}) {
  final scope = UiSkinScope.maybeOf(context);
  final color = context.ui.ink;
  return scope == null
      ? UiText.body(size: size, weight: FontWeight.w700, color: color)
      : UiText.heading(font: scope.headingFont, size: size, color: color);
}

/// Screen-reader label of a day ("Day 3, Oct 12, 2026: missed").
String timelineDayLabel(BuildContext context, TimelineDay day) {
  final l10n = JourneysL10n.of(context);
  final date = MaterialLocalizations.of(context)
      .formatMediumDate(displayDate(day.date));
  if (day.state != DayState.checkedIn && day.canOpen) {
    return l10n.journeys_cellChecked(day.dayNumber, date);
  }
  return switch (day.state) {
    DayState.checkedIn => l10n.journeys_cellChecked(day.dayNumber, date),
    DayState.missed => l10n.journeys_cellMissed(day.dayNumber, date),
    DayState.quiet => l10n.journeys_cellQuiet(day.dayNumber, date),
    DayState.today => l10n.journeys_cellToday(day.dayNumber, date),
    DayState.future => l10n.journeys_cellFuture(day.dayNumber, date),
    DayState.notCounted => l10n.journeys_cellNotCounted(day.dayNumber, date),
  };
}

/// Tappable day of any timeline variant: carries the `day-<date>` key, the
/// semantics label and opens the viewer only for checked-in days.
class TimelineDayTap extends StatelessWidget {
  const TimelineDayTap({
    required this.day,
    required this.onTap,
    required this.child,
    this.minSize = 48,
    super.key,
  });

  final TimelineDay day;
  final ValueChanged<TimelineDay> onTap;
  final Widget child;
  final double minSize;

  @override
  Widget build(BuildContext context) {
    final tappable = day.canOpen;
    return Semantics(
      key: ValueKey('day-${day.date}'),
      label: timelineDayLabel(context, day),
      button: tappable,
      onTap: tappable ? () => onTap(day) : null,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: tappable ? () => onTap(day) : null,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: minSize, minHeight: minSize),
          child: child,
        ),
      ),
    );
  }
}

/// A square/round tile showing the state of [day]: the photo when checked in,
/// a dashed accent ring with a plus when today, hairline when missed, faded
/// when upcoming. Round when [round].
class TimelineTile extends StatelessWidget {
  const TimelineTile({
    required this.day,
    required this.size,
    this.round = false,
    this.cacheWidth = 200,
    super.key,
  });

  final TimelineDay day;
  final double size;
  final bool round;

  /// Decode width of the photo: grid cells pass cell size x pixel ratio.
  final int cacheWidth;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final accent = timelineAccent(context);
    final accentText = timelineAccentText(context);
    final radius = round
        ? BorderRadius.circular(size)
        : BorderRadius.circular(UiRadius.otp);
    final Widget inner = switch (day.state) {
      DayState.checkedIn =>
        day.checkIn == null
            ? ColoredBox(
                color: ui.success.withValues(alpha: 0.18),
                child: Center(
                  child: OurneyIcon(name: 'check', size: size * 0.5),
                ),
              )
            : JourneyPhoto(checkIn: day.checkIn!, cacheWidth: cacheWidth),
      DayState.today => CustomPaint(
        key: const ValueKey('journey-today-ring'),
        foregroundPainter: DashedOutlinePainter(
          color: accent,
          width: 2,
          radius: round ? size : UiRadius.otp,
        ),
        child: ColoredBox(
          color: ui.surface,
          child: Center(
            child: OurneyIcon(
              name: 'plus',
              size: size * 0.42,
              color: accentText,
              inkColor: accentText,
            ),
          ),
        ),
      ),
      DayState.missed => DecoratedBox(
        decoration: BoxDecoration(
          color: ui.surface,
          border: Border.all(color: ui.border),
          borderRadius: radius,
        ),
      ),
      DayState.future || DayState.notCounted || DayState.quiet => DecoratedBox(
        decoration: BoxDecoration(
          color: ui.fill,
          border: Border.all(color: ui.divider),
          borderRadius: radius,
        ),
      ),
    };
    return SizedBox.square(
      dimension: size,
      child: ClipRRect(borderRadius: radius, child: inner),
    );
  }
}

/// Day number text that ignores the text scale (it lives inside fixed nodes).
class TimelineNumber extends StatelessWidget {
  const TimelineNumber(
    this.text, {
    this.color,
    this.size = 11,
    this.mono = false,
    super.key,
  });

  final String text;
  final Color? color;
  final double size;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final style = UiText.body(
      size: size,
      weight: FontWeight.w800,
      height: 1.3,
      color: color ?? context.ui.ink,
    );
    return Text(
      text,
      maxLines: 1,
      textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.35),
      style: mono ? style.copyWith(fontFamily: UiFonts.mono) : style,
    );
  }
}

/// Dashed rounded outline (today).
class DashedOutlinePainter extends CustomPainter {
  const DashedOutlinePainter({
    required this.color,
    required this.width,
    this.radius = 8,
  });

  final Color color;
  final double width;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(width / 2),
          Radius.circular(math.min(radius, size.shortestSide / 2)),
        ),
      );
    for (final PathMetric m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 5), paint);
        d += 8;
      }
    }
  }

  @override
  bool shouldRepaint(DashedOutlinePainter old) =>
      old.color != color || old.width != width || old.radius != radius;
}

/// Smooth (or straight) line through [values] scaled to the box.
class CurvePainter extends CustomPainter {
  const CurvePainter({
    required this.values,
    required this.color,
    this.dotColor,
    this.strokeWidth = 2.5,
    this.smooth = true,
    this.fillColor,
    this.endDotsOnly = false,
  });

  final List<double> values;
  final Color color;
  final Color? dotColor;
  final double strokeWidth;
  final bool smooth;
  final Color? fillColor;

  /// Dots only on the first and last point (Figma quiet curve).
  final bool endDotsOnly;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final lo = values.reduce(math.min);
    final hi = values.reduce(math.max);
    final span = hi - lo == 0 ? 1.0 : hi - lo;
    const pad = 6.0;
    Offset at(int i) => Offset(
      pad + (size.width - pad * 2) * i / (values.length - 1),
      size.height - pad - (size.height - pad * 2) * (values[i] - lo) / span,
    );
    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < values.length; i++) {
      final a = at(i - 1);
      final b = at(i);
      if (smooth) {
        final mx = (a.dx + b.dx) / 2;
        path.cubicTo(mx, a.dy, mx, b.dy, b.dx, b.dy);
      } else {
        path.lineTo(b.dx, b.dy);
      }
    }
    if (fillColor != null) {
      final fill = Path.from(path)
        ..lineTo(at(values.length - 1).dx, size.height)
        ..lineTo(at(0).dx, size.height)
        ..close();
      canvas.drawPath(fill, Paint()..color = fillColor!);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    if (dotColor != null) {
      for (var i = 0; i < values.length; i++) {
        if (endDotsOnly && i != 0 && i != values.length - 1) continue;
        canvas.drawCircle(
          at(i),
          endDotsOnly ? 5 : 3,
          Paint()..color = dotColor!,
        );
      }
    }
  }

  @override
  bool shouldRepaint(CurvePainter old) =>
      !listEquals(old.values, values) ||
      old.color != color ||
      old.dotColor != dotColor ||
      old.fillColor != fillColor ||
      old.endDotsOnly != endDotsOnly;
}

/// Dashed path through [points] (straight or S-curved segments).
class DashedPathPainter extends CustomPainter {
  const DashedPathPainter({
    required this.points,
    required this.color,
    this.width = 3,
    this.dash = 8,
    this.gap = 7,
    this.curved = false,
  });

  final List<Offset> points;
  final Color color;
  final double width;
  final double dash;
  final double gap;
  final bool curved;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1];
      final b = points[i];
      if (curved) {
        final my = (a.dy + b.dy) / 2;
        path.cubicTo(a.dx, my, b.dx, my, b.dx, b.dy);
      } else {
        path.lineTo(b.dx, b.dy);
      }
    }
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    for (final PathMetric m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + dash), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(DashedPathPainter old) =>
      !listEquals(old.points, points) ||
      old.color != color ||
      old.curved != curved ||
      old.width != width ||
      old.dash != dash ||
      old.gap != gap;
}

/// Vertical solid rail (quiet / couple spines).
class RailPainter extends CustomPainter {
  const RailPainter({required this.color, this.width = 2});

  final Color color;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      Paint()
        ..color = color
        ..strokeWidth = width,
    );
  }

  @override
  bool shouldRepaint(RailPainter old) =>
      old.color != color || old.width != width;
}

/// Runs of consecutive checked-in grid indexes (a run needs 2+ days). [cells]
/// is the 7-column grid, `null` for the blanks around the journey.
List<List<int>> chainRuns(List<TimelineDay?> cells) {
  final runs = <List<int>>[];
  List<int>? run;
  for (var i = 0; i < cells.length; i++) {
    if (cells[i]?.state == DayState.checkedIn) {
      if (run == null) {
        run = [i];
        runs.add(run);
      } else {
        run.add(i);
      }
    } else {
      run = null;
    }
  }
  return [
    for (final r in runs)
      if (r.length > 1) r,
  ];
}

/// The continuous accent line of the minimal chain calendar: through the
/// centre of every consecutive checked-in day, leaving the right edge and
/// re-entering from the left where a run wraps to the next week.
class ChainLinePainter extends CustomPainter {
  const ChainLinePainter({
    required this.runs,
    required this.cell,
    required this.gap,
    required this.color,
  });

  final List<List<int>> runs;
  final double cell;
  final double gap;
  final Color color;

  Offset _at(int i) => Offset(
    (i % 7) * (cell + gap) + cell / 2,
    (i ~/ 7) * (cell + gap) + cell / 2,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round;
    for (final run in runs) {
      final path = Path()..moveTo(_at(run.first).dx, _at(run.first).dy);
      for (var k = 1; k < run.length; k++) {
        final a = _at(run[k - 1]);
        final b = _at(run[k]);
        if ((a.dy - b.dy).abs() > 1) {
          final mid = (a.dy + b.dy) / 2;
          path
            ..lineTo(size.width + 5, a.dy)
            ..lineTo(size.width + 5, mid)
            ..lineTo(-5, mid)
            ..lineTo(-5, b.dy);
        }
        path.lineTo(b.dx, b.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(ChainLinePainter old) =>
      !_sameRuns(old.runs, runs) ||
      old.cell != cell ||
      old.gap != gap ||
      old.color != color;
}

bool _sameRuns(List<List<int>> a, List<List<int>> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (!listEquals(a[i], b[i])) return false;
  }
  return true;
}

/// The accent line of one week row of the month grid: through the centre of
/// every pair of neighbouring checked-in days, with a stub leaving the right
/// edge when the run goes on in the next week ([joinsNext]) and one entering
/// from the left when it came from the previous week ([joinsPrevious]).
/// Same look as [ChainLinePainter], drawn per row so rows can be lazy.
class ChainRowPainter extends CustomPainter {
  const ChainRowPainter({
    required this.checked,
    required this.joinsPrevious,
    required this.joinsNext,
    required this.cell,
    required this.pitch,
    required this.color,
  });

  /// Seven flags, one per column.
  final List<bool> checked;
  final bool joinsPrevious;
  final bool joinsNext;
  final double cell;
  final double pitch;
  final Color color;

  Offset _at(int i) => Offset(i * pitch + cell / 2, cell / 2);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 6; i++) {
      if (checked[i] && checked[i + 1]) {
        canvas.drawLine(_at(i), _at(i + 1), paint);
      }
    }
    if (joinsNext && checked[6]) {
      canvas.drawLine(_at(6), Offset(7 * pitch + 5, _at(6).dy), paint);
    }
    if (joinsPrevious && checked[0]) {
      canvas.drawLine(Offset(-5, _at(0).dy), _at(0), paint);
    }
  }

  @override
  bool shouldRepaint(ChainRowPainter old) =>
      !listEquals(old.checked, checked) ||
      old.joinsPrevious != joinsPrevious ||
      old.joinsNext != joinsNext ||
      old.cell != cell ||
      old.pitch != pitch ||
      old.color != color;
}

/// One day of a 7-column grid (minimal calendar, month archive): the tile
/// with the date number on top of it, in a [hit] x [hit] (>= 48dp) tap box.
class TimelineGridCell extends StatelessWidget {
  const TimelineGridCell({
    required this.day,
    required this.size,
    required this.hit,
    required this.onTap,
    this.cacheWidth = 200,
    super.key,
  });

  final TimelineDay day;
  final double size;

  /// Side of the (>= 48dp) tap box; the tile sits in its top-left corner.
  final double hit;
  final ValueChanged<TimelineDay> onTap;
  final int cacheWidth;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final photo = day.canOpen;
    final hasCouplePhoto = day.coupleSlots.isNotEmpty && photo;
    final hasLeftPhoto = hasCouplePhoto
        ? day.coupleSlots.first.checkIn != null
        : (photo && day.checkIn != null);
    final color = hasLeftPhoto
        ? UiCamera.onPhoto
        : day.state == DayState.today
        ? timelineAccentText(context)
        : day.state == DayState.missed
        ? ui.ink
        : ui.inkMuted;
    return TimelineDayTap(
      day: day,
      onTap: onTap,
      minSize: hit,
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox.square(
          dimension: size,
          child: Stack(
            children: [
              if (!hasCouplePhoto)
                TimelineTile(day: day, size: size, cacheWidth: cacheWidth)
              else if (day.state == DayState.today)
                CustomPaint(
                  key: const ValueKey('journey-today-ring'),
                  foregroundPainter: DashedOutlinePainter(
                    color: timelineAccent(context),
                    width: 2,
                    radius: UiRadius.otp,
                  ),
                  child: _coupleSplitTile(ui.fill, photo),
                )
              else
                _coupleSplitTile(ui.fill, photo),
              Positioned(
                left: 3,
                top: 2,
                child: ExcludeSemantics(
                  child: Text(
                    '${day.date.day}',
                    textScaler: MediaQuery.textScalerOf(context)
                        .clamp(maxScaleFactor: 1.35),
                    style:
                        UiText.body(
                          size: 10,
                          weight: FontWeight.w700,
                          height: 1.3,
                          color: color,
                        ).copyWith(
                          shadows: hasLeftPhoto
                              ? const [
                                  Shadow(color: UiCamera.shadow, blurRadius: 3),
                                ]
                              : null,
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

  Widget _coupleSplitTile(Color fill, bool photo) => ClipRRect(
    borderRadius: BorderRadius.circular(UiRadius.otp),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final slot in day.coupleSlots)
          Expanded(
            child: ColoredBox(
              color: fill,
              child: slot.checkIn == null || !photo
                  ? null
                  : JourneyPhoto(
                      checkIn: slot.checkIn!,
                      cacheWidth: cacheWidth,
                    ),
            ),
          ),
      ],
    ),
  );
}
