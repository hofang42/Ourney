import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../ui/ui.dart';
import '../../domain/journey_progress.dart';
import '../../domain/run_stats.dart';
import '../../domain/timeline_window.dart';
import '../../domain/weight_trend.dart';
import '../../l10n/generated/journeys_localizations.dart';
import '../journey_photo.dart';
import 'journey_timeline.dart' show wrapTimelineDayHero;
import 'timeline_common.dart';

String _decimal(BuildContext context, double value) => NumberFormat(
  '0.0',
  Localizations.localeOf(context).toString(),
).format(value);

class RunStatStrip extends StatelessWidget {
  const RunStatStrip({
    required this.stats,
    required this.isRunning,
    required this.day,
    super.key,
  });
  final RunStats stats;
  final bool isRunning;
  final int day;

  @override
  Widget build(BuildContext context) {
    final l = JourneysL10n.of(context);
    final ui = context.ui;
    final big = MediaQuery.textScalerOf(context).scale(10) > 12;
    return LayoutBuilder(
      builder: (context, box) {
        final available = box.maxWidth - UiSpace.sm * 2;
        Widget stat(
          String value,
          String label, {
          bool hero = false,
          bool pace = false,
        }) => SizedBox(
          width: big
              ? (box.maxWidth - UiSpace.md) / 2
              : available *
                    (hero
                        ? .42
                        : pace
                        ? .33
                        : .25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: UiText.display(
                  size: hero ? 32 : 22,
                  color: ui.ink,
                ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
              ),
              Text(label, style: UiText.muted(color: ui.inkMuted, size: 12)),
            ],
          ),
        );
        return Wrap(
          key: const ValueKey('journey-home-flexer-header'),
          spacing: big ? UiSpace.md : UiSpace.sm,
          runSpacing: UiSpace.md,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            if (isRunning && stats.totalKm > 0)
              stat(
                '${_decimal(context, stats.totalKm)} km',
                l.journeys_runTotalKm,
                hero: true,
              ),
            stat(
              '${stats.runs}',
              isRunning ? l.journeys_runCount : l.journeys_sessionCount,
            ),
            if (isRunning && stats.avgPaceSec != null)
              stat(
                l.journeys_extraPace(formatPace(stats.avgPaceSec!)),
                l.journeys_runAvgPace,
                pace: true,
              )
            else if (stats.totalKm == 0 || !isRunning)
              stat('$day', l.journeys_runDay),
          ],
        );
      },
    );
  }
}

class FlexerTimeline extends StatelessWidget {
  const FlexerTimeline({
    required this.days,
    required this.onTapDay,
    this.summary,
    this.allDays,
    this.isRunning = true,
    super.key,
  });
  final List<TimelineDay> days;
  final List<TimelineDay>? allDays;
  final TimelineSummary? summary;
  final bool isRunning;
  final ValueChanged<TimelineDay> onTapDay;

  @override
  Widget build(BuildContext context) {
    final elapsed = (allDays ?? days)
        .where((d) => d.state != DayState.future)
        .toList();
    final stats = RunStats.from(elapsed);
    return Column(
      key: const ValueKey('journey-timeline'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RunStatStrip(
          stats: stats,
          isRunning: isRunning,
          day: summary?.currentDay ?? (elapsed.lastOrNull?.dayNumber ?? 1),
        ),
        if (isRunning && stats.totalKm > 0) ...[
          const SizedBox(height: UiSpace.lg),
          RunKmBars(
            stats: stats,
            totalDays: elapsed.lastOrNull?.dayNumber ?? 1,
            onTapDay: onTapDay,
          ),
        ],
        const SizedBox(height: UiSpace.xl),
        JourneyWeekGrid(days: days, onTapDay: onTapDay, showKm: isRunning),
      ],
    );
  }
}

/// A tap anywhere in the distance plot opens the nearest recorded mark.
class RunKmBars extends StatelessWidget {
  const RunKmBars({
    required this.stats,
    required this.totalDays,
    required this.onTapDay,
    super.key,
  });
  final RunStats stats;
  final int totalDays;
  final ValueChanged<TimelineDay> onTapDay;

  @override
  Widget build(BuildContext context) {
    final l = JourneysL10n.of(context);
    final weekly = totalDays > longJourneyDays;
    final count = weekly ? (totalDays / 7).ceil() : totalDays;
    if (count <= 0) return const SizedBox.shrink();
    final groups = <int, List<RunDay>>{
      for (final d in stats.days)
        if (!weekly && d.day.dayNumber <= totalDays) d.day.dayNumber - 1: [d],
      if (weekly)
        for (final w in stats.weeks)
          if (w.number <= count) w.number - 1: w.days,
    };
    final values = <int, double>{
      for (final e in groups.entries)
        e.key: e.value.fold(0.0, (sum, d) => sum + d.km),
    };
    final maximum = values.values.fold(0.0, math.max);
    return Column(
      children: [
        SizedBox(
          height: 64,
          child: LayoutBuilder(
            builder: (context, box) {
              final pitch = box.maxWidth / count;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                excludeFromSemantics: true,
                onTapUp: groups.isEmpty
                    ? null
                    : (details) {
                        final dx = details.localPosition.dx;
                        final nearest = groups.keys.reduce((a, b) {
                          final distanceA = (dx - (a + .5) * pitch).abs();
                          final distanceB = (dx - (b + .5) * pitch).abs();
                          return distanceA <= distanceB ? a : b;
                        });
                        onTapDay(groups[nearest]!.last.day);
                      },
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _KmPainter(
                          values,
                          count,
                          maximum,
                          timelineAccent(context),
                          context.ui.divider,
                          weekly: weekly,
                        ),
                      ),
                    ),
                    for (final e in groups.entries)
                      Positioned(
                        left: e.key * pitch,
                        top: 0,
                        bottom: 0,
                        width: pitch,
                        child: Semantics(
                          key: ValueKey(
                            weekly
                                ? 'run-week-bar-${e.key + 1}'
                                : 'run-bar-${e.value.first.day.date}',
                          ),
                          label: weekly
                              ? l.journeys_weekKm(
                                  e.key + 1,
                                  _decimal(context, values[e.key]!),
                                )
                              : values[e.key]! > 0
                              ? l.journeys_semRunBar(
                                  e.value.first.day.dayNumber,
                                  _decimal(context, values[e.key]!),
                                )
                              : l.journeys_semRunBarNone(
                                  e.value.first.day.dayNumber,
                                ),
                          button: true,
                          container: true,
                          onTap: () => onTapDay(e.value.last.day),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: UiSpace.xs),
        LayoutBuilder(
          builder: (context, box) {
            // In daily mode each label spans the days before the next
            // hairline. Weekly mode leaves several bars per label.
            final weeks = (totalDays / 7).ceil();
            final slots = math.max(1, (box.maxWidth / 64).floor());
            final step = weekly ? math.max(4, (weeks / slots).ceil()) : 1;
            return Row(
              children: [
                for (var week = 0; week < weeks; week += step)
                  Expanded(
                    flex: weekly
                        ? math.min(step, weeks - week)
                        : math.min(7, totalDays - week * 7),
                    child: weekly && week > 0 && weeks - week < step
                        ? const SizedBox.shrink()
                        : Text(
                            l.journeys_weekLabel(week + 1),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: UiText.muted(
                              size: 10,
                              color: context.ui.inkMuted,
                            ),
                          ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _KmPainter extends CustomPainter {
  const _KmPainter(
    this.values,
    this.count,
    this.maximum,
    this.accent,
    this.divider, {
    required this.weekly,
  });
  final Map<int, double> values;
  final int count;
  final double maximum;
  final Color accent;
  final Color divider;
  final bool weekly;
  @override
  void paint(Canvas canvas, Size size) {
    if (count <= 0) return;
    final pitch = size.width / count;
    final paint = Paint()..color = accent;
    for (final e in values.entries) {
      final height = maximum > 0 ? math.max(4.0, e.value / maximum * 60) : 4.0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            e.key * pitch + pitch * .18,
            size.height - height,
            pitch * .64,
            height,
          ),
          const Radius.circular(2),
        ),
        paint,
      );
    }
    if (!weekly) {
      paint
        ..color = divider
        ..strokeWidth = .5;
      for (var i = 7; i < count; i += 7) {
        canvas.drawLine(
          Offset(i * pitch, 0),
          Offset(i * pitch, size.height),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _KmPainter old) =>
      old.values != values ||
      old.accent != accent ||
      old.divider != divider ||
      old.maximum != maximum ||
      old.weekly != weekly ||
      old.count != count;
}

/// Shared checked-day photo log, ordered by journey week, newest first.
class JourneyWeekGrid extends StatelessWidget {
  const JourneyWeekGrid({
    required this.days,
    required this.onTapDay,
    this.showKm = false,
    this.aspectRatio = 4 / 5,
    super.key,
  });
  final List<TimelineDay> days;
  final ValueChanged<TimelineDay> onTapDay;
  final bool showKm;
  final double aspectRatio;

  List<RunWeek> get weeks => RunStats.from(days).weeks.reversed.toList();

  /// Month archive uses lazy grids and week headings without partial totals.
  List<Widget> slivers(BuildContext context) {
    final l = JourneysL10n.of(context);
    final gap = MediaQuery.sizeOf(context).width >= 360 ? 12.0 : 8.0;
    return [
      for (final w in weeks) ...[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: UiSpace.md),
            child: Semantics(
              header: true,
              child: Text(
                l.journeys_weekLabel(w.number),
                style: timelineHeading(context),
              ),
            ),
          ),
        ),
        SliverLayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.crossAxisExtent - gap * 2) / 3;
            final entries = w.days.reversed.toList();
            return SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _tile(context, entries[i], width),
                childCount: entries.length,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: gap,
                crossAxisSpacing: gap,
                childAspectRatio: aspectRatio,
              ),
            );
          },
        ),
        const SliverToBoxAdapter(child: SizedBox(height: UiSpace.md)),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l = JourneysL10n.of(context);
    final groups = weeks;
    if (groups.isEmpty) {
      return UiEmptyState(
        glyph: const OurneyIcon(name: 'gallery', size: 24),
        title: l.journeys_photoLogEmpty,
      );
    }
    return LayoutBuilder(
      builder: (context, box) {
        final gap = MediaQuery.sizeOf(context).width >= 360 ? 12.0 : 8.0;
        final width = (box.maxWidth - gap * 2) / 3;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final w in groups) ...[
              Semantics(
                header: true,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: UiSpace.md),
                  child: Text(
                    showKm && w.km > 0
                        ? l.journeys_weekKm(w.number, _decimal(context, w.km))
                        : l.journeys_weekLabel(w.number),
                    style: timelineHeading(context),
                  ),
                ),
              ),
              Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final d in w.days.reversed)
                    SizedBox(
                      width: width,
                      child: AspectRatio(
                        aspectRatio: aspectRatio,
                        child: _tile(context, d, width),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: UiSpace.xl),
            ],
          ],
        );
      },
    );
  }

  Widget _tile(BuildContext context, RunDay run, double width) {
    final d = run.day;
    return TimelineDayTap(
      day: d,
      onTap: onTapDay,
      child: wrapTimelineDayHero(
        d,
        Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(UiRadius.otp),
              child: TimelineTile(
                day: d,
                size: width,
                height: width / aspectRatio,
                cacheWidth: (width * MediaQuery.devicePixelRatioOf(context))
                    .ceil(),
              ),
            ),
            if (showKm && run.km > 0)
              Positioned(
                left: 6,
                bottom: 6,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: math.max(0, width - 12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: context.ui.surface,
                    borderRadius: BorderRadius.circular(UiRadius.capsule),
                  ),
                  child: Text(
                    '${_decimal(context, run.km)} km',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: UiText.body(
                      size: 11,
                      weight: FontWeight.w700,
                      color: context.ui.ink,
                    ),
                  ),
                ),
              ),
            if (d.checkIn?.fromLibrary ?? false)
              const Positioned(
                top: 6,
                right: 6,
                child: OurneyIcon(name: 'gallery', size: 18),
              ),
          ],
        ),
      ),
    );
  }
}

class QuietTimeline extends StatefulWidget {
  const QuietTimeline({
    required this.days,
    required this.onTapDay,
    this.allDays,
    this.short,
    this.onShortChanged,
    this.numbersShown,
    this.onNumbersChanged,
    super.key,
  });
  final List<TimelineDay> days;
  final List<TimelineDay>? allDays;
  final ValueChanged<TimelineDay> onTapDay;
  final bool? short;
  final ValueChanged<bool>? onShortChanged;
  final bool? numbersShown;
  final ValueChanged<bool>? onNumbersChanged;
  @override
  State<QuietTimeline> createState() => _QuietTimelineState();
}

class _QuietTimelineState extends State<QuietTimeline> {
  bool _shown = false;
  bool _short = false;
  @override
  void didUpdateWidget(covariant QuietTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.days.firstOrNull?.checkIn?.journeyId !=
        widget.days.firstOrNull?.checkIn?.journeyId) {
      _shown = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = JourneysL10n.of(context);
    final all = (widget.allDays ?? widget.days)
        .where((d) => d.state != DayState.future)
        .toList();
    final short = widget.short ?? _short;
    final shown = widget.numbersShown ?? _shown;
    final raw = [for (final d in all) d.metricValue];
    final trend = WeightTrend.from(raw);
    final hasMetric = raw.any((v) => v != null);
    return Column(
      key: const ValueKey('journey-timeline'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (all.length > 31)
          Padding(
            padding: const EdgeInsets.only(bottom: UiSpace.md),
            child: Wrap(
              spacing: UiSpace.sm,
              children: [
                for (final range in [true, false])
                  UiChip(
                    label: range ? l.journeys_range30 : l.journeys_rangeAll,
                    selected: range == short,
                    onPressed: () {
                      setState(() => _short = range);
                      widget.onShortChanged?.call(range);
                    },
                  ),
              ],
            ),
          ),
        if (hasMetric || all.every((d) => d.state != DayState.checkedIn)) ...[
          WeightTrendCard(
            trend: trend,
            shown: shown,
            rangeDays: short ? 30 : null,
            onToggle: () {
              if (widget.onNumbersChanged != null) {
                widget.onNumbersChanged!(!shown);
              } else {
                setState(() => _shown = !shown);
              }
            },
          ),
          const SizedBox(height: UiSpace.xl),
        ],
        FirstLatestPair(days: all, onTapDay: widget.onTapDay),
        JourneyWeekGrid(
          days: widget.days,
          onTapDay: widget.onTapDay,
          aspectRatio: 3 / 4,
        ),
      ],
    );
  }
}

class WeightTrendCard extends StatelessWidget {
  const WeightTrendCard({
    required this.trend,
    required this.shown,
    required this.onToggle,
    this.rangeDays,
    super.key,
  });
  final WeightTrend? trend;
  final bool shown;
  final VoidCallback onToggle;
  final int? rangeDays;
  @override
  Widget build(BuildContext context) {
    final l = JourneysL10n.of(context);
    final ui = context.ui;
    final t = trend;
    if (t == null) {
      return UiCard(
        key: const ValueKey('weight-trend-empty'),
        child: Text(
          l.journeys_trendNeedMore,
          style: UiText.body(color: ui.ink),
        ),
      );
    }
    final direction = switch (t.direction) {
      TrendDirection.down => l.journeys_trendDown,
      TrendDirection.flat => l.journeys_trendFlat,
      TrendDirection.up => l.journeys_trendUp,
    };
    final start = rangeDays == null
        ? 0
        : math.max(0, t.trend.length - rangeDays!);
    final visible = t.trend.sublist(start);
    final raw = t.raw.sublist(start);
    final points = [...visible.nonNulls, if (shown) ...raw.nonNulls];
    final low = (points.isEmpty ? t.latestTrend : points.reduce(math.min)) - 1;
    final high = (points.isEmpty ? t.latestTrend : points.reduce(math.max)) + 1;
    final delta =
        '${t.changeSinceFirst < 0 ? '−' : '+'}${_decimal(context, t.changeSinceFirst.abs())}';
    final toggleLabel = shown ? l.journeys_hideNumbers : l.journeys_showNumbers;
    return UiCard(
      key: const ValueKey('weight-trend-card'),
      shadowOffset: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l.journeys_weightTrend(direction),
                  style: UiText.body(color: ui.ink, weight: FontWeight.w700),
                ),
              ),
              Semantics(
                container: true,
                excludeSemantics: true,
                button: true,
                toggled: shown,
                label: toggleLabel,
                onTap: onToggle,
                child: UiIconButton(
                  key: const ValueKey('weight-trend-toggle'),
                  glyph: OurneyIcon(
                    name: shown ? 'eye-off' : 'eye',
                    size: 22,
                    flat: true,
                    color: ui.inkMuted,
                  ),
                  label: toggleLabel,
                  onPressed: onToggle,
                ),
              ),
            ],
          ),
          if (shown) ...[
            Text(
              '${_decimal(context, t.latestTrend)} kg',
              style: UiText.display(size: 32, color: ui.ink),
            ),
            Text(
              l.journeys_trendChange(delta),
              style: UiText.muted(color: ui.inkMuted),
            ),
          ],
          const SizedBox(height: UiSpace.md),
          SizedBox(
            height: shown ? 120 : 88,
            child: CustomPaint(
              key: const ValueKey('weight-trend-line'),
              painter: _WeightPainter(
                visible,
                shown ? raw : const [],
                low,
                high,
                timelineAccent(context),
                ui.inkMuted,
              ),
            ),
          ),
          const SizedBox(height: UiSpace.md),
          Text(
            l.journeys_trendFooter(t.count),
            style: UiText.muted(size: 12, color: ui.inkMuted),
          ),
        ],
      ),
    );
  }
}

class _WeightPainter extends CustomPainter {
  const _WeightPainter(
    this.values,
    this.raw,
    this.low,
    this.high,
    this.accent,
    this.muted,
  );
  final List<double?> values;
  final List<double?> raw;
  final double low;
  final double high;
  final Color accent;
  final Color muted;
  @override
  void paint(Canvas canvas, Size size) {
    Offset point(int i, double v) => Offset(
      i * size.width / math.max(1, values.length - 1),
      size.height - ((v - low) / (high - low)).clamp(0, 1) * size.height,
    );
    final path = Path();
    var first = true;
    for (var i = 0; i < values.length; i++) {
      final v = values[i];
      if (v == null) continue;
      final p = point(i, v);
      if (first) {
        path.moveTo(p.dx, p.dy);
        first = false;
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    final dots = Paint()..color = muted.withValues(alpha: .35);
    for (var i = 0; i < raw.length; i++) {
      if (raw[i] != null) canvas.drawCircle(point(i, raw[i]!), 2, dots);
    }
  }

  @override
  bool shouldRepaint(covariant _WeightPainter old) =>
      values != old.values ||
      raw != old.raw ||
      low != old.low ||
      high != old.high ||
      accent != old.accent ||
      muted != old.muted;
}

class FirstLatestPair extends StatelessWidget {
  const FirstLatestPair({
    required this.days,
    required this.onTapDay,
    super.key,
  });
  final List<TimelineDay> days;
  final ValueChanged<TimelineDay> onTapDay;
  @override
  Widget build(BuildContext context) {
    final photos = [
      for (final day in days)
        if (day.state == DayState.checkedIn)
          for (final photo in day.checkIns)
            if (photo.photoPath.isNotEmpty) (day: day, photo: photo),
    ];
    if (photos.length < 2) return const SizedBox.shrink();
    final l = JourneysL10n.of(context);
    return Padding(
      key: const ValueKey('weight-first-latest'),
      padding: const EdgeInsets.only(bottom: UiSpace.xl),
      child: Semantics(
        label: l.journeys_firstLatest(
          photos.first.day.dayNumber,
          photos.last.day.dayNumber,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final d in [photos.first, photos.last]) ...[
              if (d == photos.last) const SizedBox(width: UiSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      aspectRatio: 3 / 4,
                      child: Semantics(
                        label: l.journeys_dayOpen(d.day.dayNumber),
                        button: true,
                        child: GestureDetector(
                          onTap: () => onTapDay(d.day),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(UiRadius.card),
                            child: JourneyPhoto(
                              checkIn: d.photo,
                              cacheWidth:
                                  ((MediaQuery.sizeOf(context).width -
                                              2 *
                                                  UiSpace.gutter(
                                                    MediaQuery.sizeOf(context)
                                                        .width,
                                                  ) -
                                              UiSpace.md) /
                                          2 *
                                          MediaQuery.devicePixelRatioOf(
                                            context,
                                          ))
                                      .ceil(),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: UiSpace.sm),
                    Text(
                      l.journeys_dayOpen(d.day.dayNumber),
                      style: UiText.muted(color: context.ui.inkMuted),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
