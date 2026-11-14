import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../../../../ui/ui.dart';
import '../../domain/journey_progress.dart';
import '../../domain/journey_time.dart';
import '../../l10n/generated/journeys_localizations.dart';
import '../journey_photo.dart';

/// Accent of the journey skin in scope (the selected variant).
Color timelineAccent(BuildContext context) =>
    UiSkinScope.maybeOf(context)?.variant.accent ?? context.ui.brand;

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
  return switch (day.state) {
    DayState.checkedIn => l10n.journeys_cellChecked(day.dayNumber, date),
    DayState.missed => l10n.journeys_cellMissed(day.dayNumber, date),
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
    final tappable = day.state == DayState.checkedIn;
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
    super.key,
  });

  final TimelineDay day;
  final double size;
  final bool round;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final accent = timelineAccent(context);
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
            : JourneyPhoto(checkIn: day.checkIn!, cacheWidth: 200),
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
              color: accent,
              inkColor: accent,
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
      DayState.future || DayState.notCounted => DecoratedBox(
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
      height: 1.2,
      color: color ?? context.ui.ink,
    );
    return Text(
      text,
      maxLines: 1,
      textScaler: TextScaler.noScaling,
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

/// Cumulative check-in count per day up to today (the "pace" series).
List<double> cumulativeSeries(List<TimelineDay> days) {
  var n = 0;
  final out = <double>[];
  for (final d in days) {
    if (d.state == DayState.future) break;
    if (d.state == DayState.checkedIn) n++;
    out.add(n.toDouble());
  }
  return out;
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
  });

  final List<double> values;
  final Color color;
  final Color? dotColor;
  final double strokeWidth;
  final bool smooth;
  final Color? fillColor;

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
        canvas.drawCircle(at(i), 3, Paint()..color = dotColor!);
      }
    }
  }

  @override
  bool shouldRepaint(CurvePainter old) =>
      old.values != values ||
      old.color != color ||
      old.dotColor != dotColor ||
      old.fillColor != fillColor;
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
      old.points != points || old.color != color || old.curved != curved;
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
      old.runs != runs ||
      old.cell != cell ||
      old.gap != gap ||
      old.color != color;
}
