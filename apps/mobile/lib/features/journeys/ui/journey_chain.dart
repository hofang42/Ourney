import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../../../ui/ui.dart';
import '../domain/journey_progress.dart';
import '../domain/journey_time.dart';
import '../l10n/generated/journeys_localizations.dart';
import 'journey_photo.dart';
import 'journey_style.dart';

/// The journey calendar (V1.0 `.chain-grid`, FR-B4): seven columns aligned
/// to the locale's first weekday, one square per journey day, with the
/// accent chain running through every week that has a photo. State is shown
/// by content, not only by color: photo (checked in), hairline (missed),
/// dashed accent + camera (today), faded (future / not counted).
class JourneyChain extends StatelessWidget {
  const JourneyChain({
    required this.days,
    required this.pal,
    required this.onTapDay,
    super.key,
  });

  final List<TimelineDay> days;
  final JourneyPalette pal;
  final ValueChanged<TimelineDay> onTapDay;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const SizedBox.shrink();
    final material = MaterialLocalizations.of(context);
    final ui = context.ui;
    final first = material.firstDayOfWeekIndex; // 0 = Sunday
    final startWeekday = displayDate(days.first.date).weekday % 7;
    final leading = (startWeekday - first + 7) % 7;
    final headers = [
      for (var i = 0; i < 7; i++) material.narrowWeekdays[(first + i) % 7],
    ];
    final cells = <TimelineDay?>[
      for (var i = 0; i < leading; i++) null,
      ...days,
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    const gap = 3.0;

    return Column(
      key: const ValueKey('journey-timeline'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: Row(
            children: [
              for (final h in headers)
                Expanded(
                  child: Text(
                    h,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: UiText.body(
                      size: 10,
                      height: 1.3,
                      color: ui.inkMuted,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 7),
        for (var r = 0; r < cells.length ~/ 7; r++)
          Padding(
            padding: EdgeInsets.only(
              bottom: r == cells.length ~/ 7 - 1 ? 0 : gap,
            ),
            child: _Week(
              days: cells.sublist(r * 7, r * 7 + 7),
              pal: pal,
              gap: gap,
              onTapDay: onTapDay,
            ),
          ),
      ],
    );
  }
}

class _Week extends StatelessWidget {
  const _Week({
    required this.days,
    required this.pal,
    required this.gap,
    required this.onTapDay,
  });

  final List<TimelineDay?> days;
  final JourneyPalette pal;
  final double gap;
  final ValueChanged<TimelineDay> onTapDay;

  @override
  Widget build(BuildContext context) {
    final chained = days.any((d) => d?.state == DayState.checkedIn);
    return Stack(
      children: [
        if (chained)
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, c) => Align(
                child: Container(
                  height: 2,
                  margin: EdgeInsets.symmetric(horizontal: c.maxWidth / 14),
                  color: pal.accent,
                ),
              ),
            ),
          ),
        Row(
          children: [
            for (var i = 0; i < 7; i++) ...[
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: days[i] == null
                      ? const SizedBox.shrink()
                      : _Cell(
                          day: days[i]!,
                          pal: pal,
                          onTap: () => onTapDay(days[i]!),
                        ),
                ),
              ),
              if (i < 6) SizedBox(width: gap),
            ],
          ],
        ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.day, required this.pal, required this.onTap});

  final TimelineDay day;
  final JourneyPalette pal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = JourneysL10n.of(context);
    final ui = context.ui;
    final dateText = MaterialLocalizations.of(context)
        .formatMediumDate(displayDate(day.date));
    final label = switch (day.state) {
      DayState.checkedIn => l10n.journeys_cellChecked(day.dayNumber, dateText),
      DayState.missed => l10n.journeys_cellMissed(day.dayNumber, dateText),
      DayState.today => l10n.journeys_cellToday(day.dayNumber, dateText),
      DayState.future => l10n.journeys_cellFuture(day.dayNumber, dateText),
      DayState.notCounted => l10n.journeys_cellNotCounted(
        day.dayNumber,
        dateText,
      ),
    };
    final number = Text(
      '${day.date.day}',
      textScaler: TextScaler.noScaling,
      style: UiText.body(
        size: 10,
        weight: day.isToday ? FontWeight.w800 : FontWeight.w600,
        height: 1.2,
        color: switch (day.state) {
          DayState.future || DayState.notCounted => ui.inkMuted,
          DayState.today => pal.accent,
          _ => ui.ink,
        },
      ),
    );

    final Widget content = switch (day.state) {
      DayState.checkedIn => Stack(
        fit: StackFit.expand,
        children: [
          JourneyPhoto(checkIn: day.checkIn!, cacheWidth: 160),
          Positioned(
            left: 3,
            top: 2,
            child: Text(
              '${day.date.day}',
              textScaler: TextScaler.noScaling,
              style: UiText.body(
                size: 9,
                weight: FontWeight.w700,
                height: 1.2,
                color: UiCamera.ink,
              ).copyWith(shadows: const [Shadow(blurRadius: 3)]),
            ),
          ),
        ],
      ),
      DayState.missed => DecoratedBox(
        decoration: BoxDecoration(
          color: ui.surface,
          border: Border.all(color: ui.border),
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 3, 0, 0),
            child: number,
          ),
        ),
      ),
      DayState.today => CustomPaint(
        key: const ValueKey('journey-today-ring'),
        foregroundPainter: _DashedRectPainter(color: pal.accent, width: 2),
        child: ColoredBox(
          color: ui.surface,
          child: Stack(
            children: [
              Positioned(left: 4, top: 3, child: number),
              Center(
                child: Icon(Icons.add_rounded, size: 18, color: pal.accent),
              ),
            ],
          ),
        ),
      ),
      DayState.future || DayState.notCounted => DecoratedBox(
        decoration: BoxDecoration(
          color: ui.fill,
          border: Border.all(color: ui.divider),
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 3, 0, 0),
            child: number,
          ),
        ),
      ),
    };

    final tappable = day.state == DayState.checkedIn;
    return Semantics(
      key: ValueKey('day-${day.date}'),
      label: label,
      button: tappable,
      onTap: tappable ? onTap : null,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: tappable ? onTap : null,
        child: content,
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  const _DashedRectPainter({required this.color, required this.width});

  final Color color;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    final path = Path()..addRect((Offset.zero & size).deflate(width / 2));
    for (final PathMetric m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 5), paint);
        d += 8;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRectPainter old) =>
      old.color != color || old.width != width;
}
