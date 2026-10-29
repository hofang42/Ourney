import 'package:flutter/material.dart';

import '../../../app/theme/tokens.dart';
import '../../../shared/dashed_border_painter.dart';
import '../domain/journey_progress.dart';
import '../domain/journey_time.dart';
import '../l10n/generated/journeys_localizations.dart';
import 'journey_photo.dart';

/// Calendar-grid timeline (FR-B4, docs/03 "lưới lịch 7 cột"): one cell per
/// journey day, aligned to the locale's first weekday.
class TimelineGrid extends StatelessWidget {
  const TimelineGrid({required this.days, required this.onTapDay, super.key});

  final List<TimelineDay> days;
  final ValueChanged<TimelineDay> onTapDay;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const SizedBox.shrink();
    final material = MaterialLocalizations.of(context);
    final c = OurneyColors.of(context);
    final first = material.firstDayOfWeekIndex; // 0 = Sunday
    final startWeekday = displayDate(days.first.date).weekday % 7;
    final leading = (startWeekday - first + 7) % 7;
    final headers = [
      for (var i = 0; i < 7; i++) material.narrowWeekdays[(first + i) % 7],
    ];

    return Column(
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
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: c.inkMuted),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: OurneySpacing.sm),
        GridView.builder(
          key: const ValueKey('journey-timeline'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
          ),
          itemCount: leading + days.length,
          itemBuilder: (context, i) {
            if (i < leading) return const SizedBox.shrink();
            final day = days[i - leading];
            return DayCell(day: day, onTap: () => onTapDay(day));
          },
        ),
      ],
    );
  }
}

/// One timeline cell. State is conveyed by shape and content, not only by
/// color: photo (checked in), dashed outline (missed), thick ring + dot
/// (today), faded number (future / not counted).
class DayCell extends StatelessWidget {
  const DayCell({
    required this.day,
    required this.onTap,
    this.childOverride,
    super.key,
  });

  final TimelineDay day;
  final VoidCallback onTap;

  /// Optional persona visual override (e.g. Z1 `_ChainDayCell` visuals).
  final Widget? childOverride;

  DayState get state => day.state;

  @override
  Widget build(BuildContext context) {
    final l10n = JourneysL10n.of(context);
    final c = OurneyColors.of(context);
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
    final radius = BorderRadius.circular(OurneyRadii.chip);
    final number = FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        '${day.date.day}',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: switch (day.state) {
            DayState.future || DayState.notCounted => c.inkMuted,
            _ => c.ink,
          },
          fontWeight: day.isToday ? FontWeight.w800 : null,
        ),
      ),
    );

    final Widget content = switch (day.state) {
      DayState.checkedIn => Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: radius,
            child: JourneyPhoto(checkIn: day.checkIn!, cacheWidth: 160),
          ),
          Positioned(
            left: 3,
            top: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: OurneyColors.mediaBlack.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${day.date.day}',
                textScaler: TextScaler.noScaling,
                style: const TextStyle(
                  fontSize: 10,
                  color: OurneyColors.mediaWhite,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
      DayState.missed => CustomPaint(
        painter: DashedBorderPainter(
          color: c.inkMuted,
          radius: radius,
          strokeWidth: 1.5,
        ),
        child: Center(child: number),
      ),
      DayState.today => DecoratedBox(
        decoration: BoxDecoration(
          color: c.primary.withValues(alpha: 0.12),
          borderRadius: radius,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(child: number),
            Icon(Icons.photo_camera_rounded, size: 12, color: c.primaryDeep),
          ],
        ),
      ),
      DayState.future || DayState.notCounted => Opacity(
        opacity: 0.6,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: c.inkMuted.withValues(alpha: 0.08),
            borderRadius: radius,
          ),
          child: Center(child: number),
        ),
      ),
    };

    final cell = day.isToday
        ? Container(
            key: const ValueKey('journey-today-ring'),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: c.primaryDeep, width: 2.5),
            ),
            padding: const EdgeInsets.all(2),
            child: childOverride ?? content,
          )
        : (childOverride ?? content);

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
        child: cell,
      ),
    );
  }
}
