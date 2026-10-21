import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart' show displayStyle;
import '../../app/theme/persona_theme.dart';
import '../../features/journeys/domain/journey_progress.dart';
import '../../features/journeys/domain/journey_time.dart';
import '../../features/journeys/l10n/generated/journeys_localizations.dart';
import '../../features/journeys/ui/journey_photo.dart';
import '../../features/journeys/ui/timeline_grid.dart' show DayCell;
import '../../shared/layout.dart';
import '../../shared/persona_pill.dart';
import '../persona_contract.dart';
import 'l10n/generated/minimalist_habit_localizations.dart';

/// **Task Z1** (`PersonaSkinId.minimalistHabit` — `chainCalendarGrid`):
/// 7-column monthly calendar grid (`MONTH · N DAY STREAK`) where:
/// - Completed days (`DayState.checkedIn`) are square photo thumbnails linked
///   horizontally by a continuous Braun Coral-Orange (`pTheme.primaryAccent`)
///   chain line across adjacent checked-in days.
/// - Missed and future days are clean dashed squares (`01..30`) so state is
///   never conveyed by color alone (FR-B4).
/// - Built without modifying `features/journeys/ui/timeline_grid.dart` (`docs/TASKS.md` Z1).
class ChainCalendarGridTimeline extends StatelessWidget {
  const ChainCalendarGridTimeline({required this.data, super.key});

  final PersonaTimelineData data;

  @override
  Widget build(BuildContext context) {
    final pTheme = OurneyPersonaTheme.of(context);
    final l10n = MinimalistHabitL10n.of(context);
    final days = data.days;
    final monthNumber = days.isEmpty ? 1 : days.last.date.month;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final pad = OurneyLayout.cardPadding(width);

        final card = Container(
          key: const ValueKey('z1-chain-calendar-grid'),
          padding: EdgeInsets.all(pad),
          decoration: BoxDecoration(
            color: pTheme.surface,
            borderRadius: BorderRadius.circular(pTheme.cardRadius),
            border: Border.all(color: pTheme.border, width: pTheme.borderWidth),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  PersonaPill(
                    key: const ValueKey('z1-style-pill'),
                    icon: Icons.grid_view_rounded,
                    label: l10n.minimalist_habit_name,
                  ),
                  PersonaPill(
                    key: const ValueKey('z1-day-pill'),
                    emphasized: true,
                    label: l10n.minimalist_habit_dayLabel(data.dayNumber),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                l10n.minimalist_habit_monthStreakHeader(
                  monthNumber,
                  data.currentStreak,
                ),
                key: const ValueKey('z1-month-streak-header'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: displayStyle(
                  size: 16,
                  weight: 800,
                  color: pTheme.ink,
                  height: 1.3,
                ).copyWith(letterSpacing: 0.4),
              ),
              const SizedBox(height: 12),
              if (days.isNotEmpty)
                _ChainGridBody(
                  days: days,
                  pTheme: pTheme,
                  onTapDay: data.onTapDay,
                  photoBuilder: data.photoBuilder,
                ),
            ],
          ),
        );

        if (data.shrinkWrap) return card;
        return SingleChildScrollView(
          physics: data.physics,
          child: card,
        );
      },
    );
  }
}

class _ChainGridBody extends StatelessWidget {
  const _ChainGridBody({
    required this.days,
    required this.pTheme,
    required this.onTapDay,
    required this.photoBuilder,
  });

  final List<TimelineDay> days;
  final OurneyPersonaTheme pTheme;
  final ValueChanged<TimelineDay>? onTapDay;
  final PersonaDayPhotoBuilder? photoBuilder;

  static const double _gap = 8;

  @override
  Widget build(BuildContext context) {
    final material = MaterialLocalizations.of(context);
    final first = material.firstDayOfWeekIndex; // 0 = Sunday
    final startWeekday = displayDate(days.first.date).weekday % 7;
    final leading = (startWeekday - first + 7) % 7;
    final headers = [
      for (var i = 0; i < 7; i++) material.narrowWeekdays[(first + i) % 7],
    ];
    final totalSlots = leading + days.length;
    final rowCount = (totalSlots / 7).ceil();

    return Column(
      key: const ValueKey('journey-timeline'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
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
                    style: TextStyle(
                      color: pTheme.inkMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        for (var r = 0; r < rowCount; r++) ...[
          if (r > 0) const SizedBox(height: _gap),
          _ChainRow(
            rowIndex: r,
            leading: leading,
            days: days,
            pTheme: pTheme,
            onTapDay: onTapDay,
            photoBuilder: photoBuilder,
          ),
        ],
      ],
    );
  }
}

class _ChainRow extends StatelessWidget {
  const _ChainRow({
    required this.rowIndex,
    required this.leading,
    required this.days,
    required this.pTheme,
    required this.onTapDay,
    required this.photoBuilder,
  });

  final int rowIndex;
  final int leading;
  final List<TimelineDay> days;
  final OurneyPersonaTheme pTheme;
  final ValueChanged<TimelineDay>? onTapDay;
  final PersonaDayPhotoBuilder? photoBuilder;

  TimelineDay? _dayAt(int col) {
    final idx = rowIndex * 7 + col - leading;
    if (idx < 0 || idx >= days.length) return null;
    return days[idx];
  }

  @override
  Widget build(BuildContext context) {
    final rowDays = [for (var c = 0; c < 7; c++) _dayAt(c)];
    final checkedCols = [
      for (var c = 0; c < 7; c++)
        rowDays[c]?.state == DayState.checkedIn,
    ];

    return Stack(
      alignment: Alignment.center,
      children: [
        // Continuous horizontal Braun-orange chain line linking adjacent
        // completed days in this week row.
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              key: ValueKey('z1-chain-line-row-$rowIndex'),
              painter: _HorizontalChainPainter(
                checkedCols: checkedCols,
                color: pTheme.primaryAccent,
              ),
            ),
          ),
        ),
        Row(
          children: [
            for (var c = 0; c < 7; c++) ...[
              if (c > 0) const SizedBox(width: _ChainGridBody._gap),
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: rowDays[c] == null
                      ? const SizedBox.shrink()
                      : KeyedSubtree(
                          key: ValueKey('z1-day-${rowDays[c]!.date}'),
                          child: photoBuilder == null
                              ? DayCell(
                                  day: rowDays[c]!,
                                  onTap: () => onTapDay?.call(rowDays[c]!),
                                )
                              : _ChainDayCell(
                                  day: rowDays[c]!,
                                  pTheme: pTheme,
                                  onTap: onTapDay == null
                                      ? null
                                      : () => onTapDay!(rowDays[c]!),
                                  photoBuilder: photoBuilder,
                                ),
                        ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _HorizontalChainPainter extends CustomPainter {
  const _HorizontalChainPainter({
    required this.checkedCols,
    required this.color,
  });

  final List<bool> checkedCols;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final cellW = (size.width - 6 * _ChainGridBody._gap) / 7;
    if (cellW <= 0) return;
    final cy = size.height / 2;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    for (var c = 0; c < 6; c++) {
      if (checkedCols[c] && checkedCols[c + 1]) {
        final x1 = c * (cellW + _ChainGridBody._gap) + cellW * 0.5;
        final x2 = (c + 1) * (cellW + _ChainGridBody._gap) + cellW * 0.5;
        canvas.drawLine(Offset(x1, cy), Offset(x2, cy), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_HorizontalChainPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.checkedCols != checkedCols;
}

class _ChainDayCell extends StatelessWidget {
  const _ChainDayCell({
    required this.day,
    required this.pTheme,
    required this.onTap,
    required this.photoBuilder,
  });

  final TimelineDay day;
  final OurneyPersonaTheme pTheme;
  final VoidCallback? onTap;
  final PersonaDayPhotoBuilder? photoBuilder;

  @override
  Widget build(BuildContext context) {
    final journeysL10n = Localizations.of<JourneysL10n>(context, JourneysL10n);
    final dateText = MaterialLocalizations.of(
      context,
    ).formatMediumDate(displayDate(day.date));
    final semanticLabel = journeysL10n == null
        ? 'Day ${day.dayNumber}'
        : switch (day.state) {
            DayState.checkedIn => journeysL10n.journeys_cellChecked(
              day.dayNumber,
              dateText,
            ),
            DayState.missed => journeysL10n.journeys_cellMissed(
              day.dayNumber,
              dateText,
            ),
            DayState.today => journeysL10n.journeys_cellToday(
              day.dayNumber,
              dateText,
            ),
            DayState.future => journeysL10n.journeys_cellFuture(
              day.dayNumber,
              dateText,
            ),
            DayState.notCounted => journeysL10n.journeys_cellNotCounted(
              day.dayNumber,
              dateText,
            ),
          };

    final dayNumStr = day.dayNumber.toString().padLeft(2, '0');
    final radius = BorderRadius.circular(8);

    final Widget inner = switch (day.state) {
      DayState.checkedIn => Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: radius,
            child: photoBuilder != null
                ? photoBuilder!(context, day)
                : JourneyPhoto(checkIn: day.checkIn!, cacheWidth: 160),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: pTheme.primaryAccent, width: 2),
            ),
          ),
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: pTheme.primaryAccent,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 10,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      DayState.today => DecoratedBox(
        decoration: BoxDecoration(
          color: pTheme.surfaceElevated,
          borderRadius: radius,
          border: Border.all(color: pTheme.primaryAccent, width: 2),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Text(
                dayNumStr,
                style: TextStyle(
                  color: pTheme.primaryAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
      DayState.missed || DayState.future || DayState.notCounted => CustomPaint(
        painter: _SquareDashedBorderPainter(
          color: day.state == DayState.missed
              ? pTheme.inkMuted
              : pTheme.inkMuted.withValues(alpha: 0.55),
          radius: 8,
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Text(
                dayNumStr,
                style: TextStyle(
                  color: pTheme.inkMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    };

    final tappable = day.state == DayState.checkedIn && onTap != null;
    return Semantics(
      key: ValueKey('z1-day-${day.date}'),
      label: semanticLabel,
      button: tappable,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: tappable ? onTap : null,
        child: inner,
      ),
    );
  }
}

class _SquareDashedBorderPainter extends CustomPainter {
  const _SquareDashedBorderPainter({
    required this.color,
    required this.radius,
  });

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25;
    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(0.75),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    const dash = 4.0;
    const gap = 3.0;
    for (final PathMetric metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = distance + dash;
        canvas.drawPath(
          metric.extractPath(
            distance,
            end > metric.length ? metric.length : end,
          ),
          paint,
        );
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_SquareDashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
