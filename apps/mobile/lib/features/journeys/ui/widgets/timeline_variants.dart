import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../ui/ui.dart';
import '../../domain/journey_progress.dart';
import '../../l10n/generated/journeys_localizations.dart';
import 'timeline_common.dart';

String _dayText(BuildContext context, TimelineDay d) =>
    JourneysL10n.of(context).journeys_dayOpen(d.dayNumber);

String _dateText(BuildContext context, TimelineDay d) =>
    MaterialLocalizations.of(context).formatShortDate(displayDateOf(d));

DateTime displayDateOf(TimelineDay d) =>
    DateTime(d.date.year, d.date.month, d.date.day);

/// Quiet transformer: progress curve on top, vertical rail of nodes below.
class QuietTimeline extends StatelessWidget {
  const QuietTimeline({required this.days, required this.onTapDay, super.key});

  final List<TimelineDay> days;
  final ValueChanged<TimelineDay> onTapDay;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final accent = timelineAccent(context);
    final metric = <double>[
      for (final d in days)
        if (d.checkIn?.metricValue != null) d.checkIn!.metricValue!,
    ];
    final series = metric.length >= 2 ? metric : cumulativeSeries(days);
    return Column(
      key: const ValueKey('journey-timeline'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: Container(
            key: const ValueKey('timeline-curve'),
            height: 84,
            margin: const EdgeInsets.only(bottom: UiSpace.md),
            decoration: BoxDecoration(
              color: ui.surface,
              borderRadius: BorderRadius.circular(UiRadius.card),
              border: Border.all(color: ui.border),
            ),
            child: CustomPaint(
              painter: CurvePainter(
                values: series,
                color: accent,
                dotColor: accent,
                fillColor: accent.withValues(alpha: 0.12),
              ),
            ),
          ),
        ),
        for (var i = 0; i < days.length; i++)
          _QuietRow(
            day: days[i],
            first: i == 0,
            last: i == days.length - 1,
            onTap: onTapDay,
          ),
      ],
    );
  }
}

class _QuietRow extends StatelessWidget {
  const _QuietRow({
    required this.day,
    required this.first,
    required this.last,
    required this.onTap,
  });

  final TimelineDay day;
  final bool first;
  final bool last;
  final ValueChanged<TimelineDay> onTap;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final accent = timelineAccent(context);
    final done = day.state == DayState.checkedIn;
    return TimelineDayTap(
      day: day,
      onTap: onTap,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 32,
              child: CustomPaint(
                painter: RailPainter(color: ui.border),
                child: Align(
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done ? accent : ui.bg,
                      border: Border.all(
                        color: day.isToday ? accent : ui.ink,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: UiSpace.sm),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _dayText(context, day),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: timelineHeading(context),
                          ),
                          Text(
                            _dateText(context, day),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: UiText.muted(color: ui.inkMuted, size: 12),
                          ),
                        ],
                      ),
                    ),
                    if (day.state == DayState.checkedIn ||
                        day.state == DayState.today)
                      TimelineTile(day: day, size: 44),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Accountability squad: stepping stones on an S-path up to the trophy.
class SquadTimeline extends StatelessWidget {
  const SquadTimeline({required this.days, required this.onTapDay, super.key});

  final List<TimelineDay> days;
  final ValueChanged<TimelineDay> onTapDay;

  static const double _row = 76;
  static const double _stone = 56;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final accent = timelineAccent(context);
    final total = days.length + 1; // + trophy
    return LayoutBuilder(
      key: const ValueKey('journey-timeline'),
      builder: (context, c) {
        final w = c.maxWidth;
        double cx(int i) => w * (0.5 + 0.3 * math.sin(i * math.pi / 2));
        final points = [
          for (var i = 0; i < total; i++) Offset(cx(i), i * _row + _row / 2),
        ];
        return SizedBox(
          height: total * _row,
          child: Stack(
            children: [
              Positioned.fill(
                child: ExcludeSemantics(
                  child: CustomPaint(
                    painter: DashedPathPainter(
                      points: points,
                      color: ui.border,
                      curved: true,
                    ),
                  ),
                ),
              ),
              for (var i = 0; i < days.length; i++)
                Positioned(
                  left: points[i].dx - _stone / 2,
                  top: points[i].dy - _stone / 2,
                  child: TimelineDayTap(
                    day: days[i],
                    onTap: onTapDay,
                    minSize: _stone,
                    child: _Stone(day: days[i], size: _stone),
                  ),
                ),
              Positioned(
                left: points.last.dx - _stone / 2,
                top: points.last.dy - _stone / 2,
                child: ExcludeSemantics(
                  child: Container(
                    key: const ValueKey('timeline-trophy'),
                    width: _stone,
                    height: _stone,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withValues(alpha: 0.2),
                      border: Border.all(color: ui.ink, width: 2),
                    ),
                    child: const Center(
                      child: OurneyIcon(name: 'trophy', size: 30),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Stone extends StatelessWidget {
  const _Stone({required this.day, required this.size});

  final TimelineDay day;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final accent = timelineAccent(context);
    if (day.state == DayState.checkedIn || day.state == DayState.today) {
      return TimelineTile(day: day, size: size, round: true);
    }
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: day.state == DayState.missed ? ui.surface : ui.fill,
        border: Border.all(
          color: day.state == DayState.missed ? ui.border : ui.divider,
        ),
      ),
      child: TimelineNumber(
        '${day.dayNumber}',
        color: day.state == DayState.missed ? ui.ink : accent.withAlpha(150),
        size: 14,
      ),
    );
  }
}

/// Memory collectors: a stitched thread with taped polaroids either side.
class MemoryTimeline extends StatelessWidget {
  const MemoryTimeline({required this.days, required this.onTapDay, super.key});

  final List<TimelineDay> days;
  final ValueChanged<TimelineDay> onTapDay;

  @override
  Widget build(BuildContext context) {
    final accent = timelineAccent(context);
    return Stack(
      key: const ValueKey('journey-timeline'),
      children: [
        Positioned.fill(
          child: ExcludeSemantics(
            child: LayoutBuilder(
              builder: (context, c) => CustomPaint(
                painter: DashedPathPainter(
                  points: [
                    Offset(c.maxWidth / 2, 0),
                    Offset(c.maxWidth / 2, c.maxHeight),
                  ],
                  color: accent,
                  width: 2,
                  dash: 6,
                  gap: 5,
                ),
              ),
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < days.length; i++)
              _ScrapRow(day: days[i], index: i, onTap: onTapDay),
          ],
        ),
      ],
    );
  }
}

class _ScrapRow extends StatelessWidget {
  const _ScrapRow({
    required this.day,
    required this.index,
    required this.onTap,
  });

  final TimelineDay day;
  final int index;
  final ValueChanged<TimelineDay> onTap;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final accent = timelineAccent(context);
    final left = index.isEven;
    final photo =
        day.state == DayState.checkedIn || day.state == DayState.today;
    if (!photo) {
      return TimelineDayTap(
        day: day,
        onTap: onTap,
        child: Center(
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ui.bg,
              border: Border.all(color: ui.border),
            ),
            child: TimelineNumber(
              '${day.dayNumber}',
              color: ui.inkMuted,
              size: 11,
            ),
          ),
        ),
      );
    }
    final card = TimelineDayTap(
      day: day,
      onTap: onTap,
      minSize: 96,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: UiPolaroid(
              tilt: left ? -1 : 1.2,
              photo: AspectRatio(
                aspectRatio: 1,
                child: TimelineTile(day: day, size: 96),
              ),
              footer: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _dayText(context, day),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: timelineHeading(context, size: 13),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: Container(
              width: 36,
              height: 14,
              color: accent.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 9,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: left ? card : const SizedBox.shrink(),
            ),
          ),
          const Spacer(flex: 2),
          Expanded(
            flex: 9,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: left ? const SizedBox.shrink() : card,
            ),
          ),
        ],
      ),
    );
  }
}

/// Couple rituals: your photo left, heart node on the spine, the day on the
/// partner's side.
class CoupleTimeline extends StatelessWidget {
  const CoupleTimeline({required this.days, required this.onTapDay, super.key});

  final List<TimelineDay> days;
  final ValueChanged<TimelineDay> onTapDay;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('journey-timeline'),
      children: [for (final d in days) _CouplePair(day: d, onTap: onTapDay)],
    );
  }
}

class _CouplePair extends StatelessWidget {
  const _CouplePair({required this.day, required this.onTap});

  final TimelineDay day;
  final ValueChanged<TimelineDay> onTap;

  static const double _spine = 44;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final l10n = JourneysL10n.of(context);
    final accent = timelineAccent(context);
    final done = day.state == DayState.checkedIn;
    final waiting =
        day.state == DayState.checkedIn || day.state == DayState.today;
    final header = [
      _dayText(context, day),
      _dateText(context, day),
      if (day.isToday) l10n.journeys_todayLabel,
    ].join(' · ');
    return TimelineDayTap(
      day: day,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: LayoutBuilder(
          builder: (context, c) {
            final s = math.min((c.maxWidth - _spine) / 2, 120.0);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  header.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: UiText.muted(color: ui.inkMuted, size: 11),
                ),
                const SizedBox(height: 6),
                Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Positioned.fill(
                      child: ExcludeSemantics(
                        child: CustomPaint(
                          painter: RailPainter(color: ui.border),
                        ),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _CoupleHalf(
                            label: l10n.journeys_coupleYou,
                            child: TimelineTile(day: day, size: s),
                          ),
                        ),
                        SizedBox(
                          width: _spine,
                          height: s,
                          child: Center(
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: done
                                    ? accent.withValues(alpha: 0.25)
                                    : ui.bg,
                              ),
                              child: Center(
                                child: OurneyIcon(
                                  name: 'heart',
                                  size: 22,
                                  color: done ? accent : ui.fill,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: _CoupleHalf(
                            label: l10n.journeys_ticketPartner,
                            child: CustomPaint(
                              key: const ValueKey('couple-partner-slot'),
                              foregroundPainter: DashedOutlinePainter(
                                color: ui.border,
                                width: 1.5,
                                radius: UiRadius.otp,
                              ),
                              child: SizedBox.square(
                                dimension: s,
                                child: waiting
                                    ? Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(6),
                                          child: Text(
                                            l10n.journeys_coupleWaiting,
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                            style: UiText.muted(
                                              color: ui.inkMuted,
                                              size: 11,
                                            ),
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CoupleHalf extends StatelessWidget {
  const _CoupleHalf({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: timelineHeading(context, size: 13),
        ),
      ],
    );
  }
}

/// Minimal habit: 7-column photo calendar aligned to the locale's first
/// weekday, with one continuous accent line through consecutive checked-in
/// days that wraps from the end of a week to the start of the next.
class MinimalTimeline extends StatelessWidget {
  const MinimalTimeline({
    required this.days,
    required this.onTapDay,
    super.key,
  });

  final List<TimelineDay> days;
  final ValueChanged<TimelineDay> onTapDay;

  static const double _gap = 3;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final accent = timelineAccent(context);
    final material = MaterialLocalizations.of(context);
    final first = material.firstDayOfWeekIndex; // 0 = Sunday
    final leading = (displayDateOf(days.first).weekday % 7 - first + 7) % 7;
    final cells = <TimelineDay?>[
      for (var i = 0; i < leading; i++) null,
      ...days,
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    final rows = cells.length ~/ 7;
    return Column(
      key: const ValueKey('journey-timeline'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Text(
                    material.narrowWeekdays[(first + i) % 7],
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
        LayoutBuilder(
          builder: (context, c) {
            final cell = (c.maxWidth - _gap * 6) / 7;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: ExcludeSemantics(
                    child: CustomPaint(
                      key: const ValueKey('timeline-chain-line'),
                      painter: ChainLinePainter(
                        runs: chainRuns(cells),
                        cell: cell,
                        gap: _gap,
                        color: accent,
                      ),
                    ),
                  ),
                ),
                Column(
                  children: [
                    for (var r = 0; r < rows; r++)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: r == rows - 1 ? 0 : _gap,
                        ),
                        child: Row(
                          children: [
                            for (var i = 0; i < 7; i++) ...[
                              SizedBox.square(
                                dimension: cell,
                                child: cells[r * 7 + i] == null
                                    ? null
                                    : _MinimalCell(
                                        day: cells[r * 7 + i]!,
                                        size: cell,
                                        onTap: onTapDay,
                                      ),
                              ),
                              if (i < 6) const SizedBox(width: _gap),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _MinimalCell extends StatelessWidget {
  const _MinimalCell({
    required this.day,
    required this.size,
    required this.onTap,
  });

  final TimelineDay day;
  final double size;
  final ValueChanged<TimelineDay> onTap;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final photo = day.state == DayState.checkedIn;
    final color = photo
        ? UiCamera.ink
        : day.state == DayState.today
        ? timelineAccent(context)
        : day.state == DayState.missed
        ? ui.ink
        : ui.inkMuted;
    return TimelineDayTap(
      day: day,
      onTap: onTap,
      minSize: 0,
      child: Stack(
        children: [
          TimelineTile(day: day, size: size),
          Positioned(
            left: 3,
            top: 2,
            child: ExcludeSemantics(
              child: Text(
                '${day.date.day}',
                textScaler: TextScaler.noScaling,
                style:
                    UiText.body(
                      size: 9,
                      weight: FontWeight.w700,
                      height: 1.2,
                      color: color,
                    ).copyWith(
                      shadows: photo ? const [Shadow(blurRadius: 3)] : null,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Aesthetic flexer: telemetry pace sparkline above mono run nodes.
class FlexerTimeline extends StatelessWidget {
  const FlexerTimeline({required this.days, required this.onTapDay, super.key});

  final List<TimelineDay> days;
  final ValueChanged<TimelineDay> onTapDay;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final accent = timelineAccent(context);
    final series = cumulativeSeries(days);
    final done = days.where((d) => d.state == DayState.checkedIn).length;
    return Column(
      key: const ValueKey('journey-timeline'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: Container(
            key: const ValueKey('timeline-pace'),
            height: 88,
            margin: const EdgeInsets.only(bottom: UiSpace.md),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            decoration: BoxDecoration(
              color: ui.surface,
              borderRadius: BorderRadius.circular(UiRadius.card),
              border: Border.all(color: ui.border),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: CurvePainter(
                      values: series,
                      color: accent,
                      smooth: false,
                      strokeWidth: 3,
                    ),
                  ),
                ),
                Align(
                  alignment: AlignmentDirectional.topStart,
                  child: TimelineNumber(
                    '$done/${days.length}',
                    mono: true,
                    size: 13,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
        ),
        for (final d in days)
          TimelineDayTap(
            day: d,
            onTap: onTapDay,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 44,
                    child: TimelineNumber(
                      'D${d.dayNumber.toString().padLeft(2, '0')}',
                      mono: true,
                      size: 12,
                      color: d.state == DayState.checkedIn
                          ? ui.ink
                          : ui.inkMuted,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: d.state == DayState.checkedIn ? accent : ui.fill,
                        borderRadius: BorderRadius.circular(5),
                        border: d.isToday
                            ? Border.all(color: accent, width: 2)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: UiSpace.sm),
                  TimelineTile(day: d, size: 40),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
