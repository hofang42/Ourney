import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../../ui/ui.dart';
import '../../domain/journey_progress.dart';
import '../../domain/timeline_window.dart';
import '../../l10n/generated/journeys_localizations.dart';
import '../journey_photo.dart';
import 'timeline_cards.dart';
import 'timeline_common.dart';

String _dayText(BuildContext context, TimelineDay d) =>
    JourneysL10n.of(context).journeys_dayOpen(d.dayNumber);

String _dateText(BuildContext context, TimelineDay d) =>
    MaterialLocalizations.of(context).formatShortDate(displayDateOf(d));

DateTime displayDateOf(TimelineDay d) =>
    DateTime(d.date.year, d.date.month, d.date.day);

/// Quiet transformer: weight curve with private axis labels (hold to reveal),
/// a vertical rail of nodes captioned like the Figma timeline, and a
/// milestones row.
class QuietTimeline extends StatefulWidget {
  const QuietTimeline({
    required this.days,
    required this.onTapDay,
    this.summary,
    this.short,
    this.onShortChanged,
    super.key,
  });

  final List<TimelineDay> days;
  final ValueChanged<TimelineDay> onTapDay;

  /// Whole-journey numbers when [days] is only a window of the journey.
  final TimelineSummary? summary;

  /// The 30D / All choice when the screen keeps it (else kept here).
  final bool? short;
  final ValueChanged<bool>? onShortChanged;

  @override
  State<QuietTimeline> createState() => _QuietTimelineState();
}

class _QuietTimelineState extends State<QuietTimeline> {
  bool _revealed = false;

  /// Long journeys: the curve shows the last 30 days instead of all of it.
  bool _range30 = false;

  void _reveal(bool v) {
    if (_revealed != v) setState(() => _revealed = v);
  }

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final l10n = JourneysL10n.of(context);
    final accent = timelineAccent(context);
    final days = widget.days;
    final sum = widget.summary ?? TimelineSummary.fromDays(days);
    final ranged = sum.curve30 != null;
    final short = ranged && (widget.short ?? _range30);
    void setShort(bool v) {
      if (widget.onShortChanged != null) {
        widget.onShortChanged!(v);
      } else {
        setState(() => _range30 = v);
      }
    }

    final series = short ? sum.curve30! : sum.curve;
    final metricCount = short ? sum.metric30Count : sum.metricCount;
    String axis(int i) {
      if (!_revealed || metricCount < 2) return '••,•';
      return l10n.journeys_quietAxis(
        (i == 0 ? series.first : series.last).toStringAsFixed(1),
      );
    }

    final total = sum.totalDays;
    final current = sum.currentDay;
    final marks = <int>{7, total ~/ 2, total}.where((d) => d <= total).toList()
      ..sort();
    String markLabel(int d) => d == total
        ? l10n.journeys_quietFinish
        : d == 7
        ? l10n.journeys_quietWeek
        : l10n.journeys_quietHalf;
    final holdLabel = _revealed
        ? l10n.journeys_quietHolding
        : l10n.journeys_quietHold;
    return Column(
      key: const ValueKey('journey-timeline'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          key: const ValueKey('timeline-curve'),
          margin: const EdgeInsets.only(bottom: UiSpace.md),
          padding: const EdgeInsets.all(UiSpace.md),
          decoration: BoxDecoration(
            color: ui.surface,
            borderRadius: BorderRadius.circular(UiRadius.card),
            border: Border.all(color: ui.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (ranged) ...[
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Wrap(
                    spacing: UiSpace.sm,
                    children: [
                      UiChip(
                        key: const ValueKey('quiet-range-30'),
                        label: l10n.journeys_range30,
                        selected: short,
                        onPressed: () => setShort(true),
                      ),
                      UiChip(
                        key: const ValueKey('quiet-range-all'),
                        label: l10n.journeys_rangeAll,
                        selected: !short,
                        onPressed: () => setShort(false),
                      ),
                    ],
                  ),
                ),
                if (short && metricCount < 2 && sum.metricCount >= 2)
                  Padding(
                    key: const ValueKey('quiet-range-fallback'),
                    padding: const EdgeInsets.only(top: UiSpace.xs),
                    child: Text(
                      l10n.journeys_range30Pace,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: UiText.body(
                        size: 12,
                        height: 1.4,
                        color: ui.inkMuted,
                      ),
                    ),
                  ),
                const SizedBox(height: UiSpace.xs),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: TimelineNumber(
                      axis(0),
                      mono: true,
                      size: 12,
                      color: ui.inkMuted,
                    ),
                  ),
                  Flexible(
                    child: TimelineNumber(
                      axis(1),
                      mono: true,
                      size: 12,
                      color: ui.inkMuted,
                    ),
                  ),
                ],
              ),
              ExcludeSemantics(
                child: SizedBox(
                  height: 84,
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: CurvePainter(
                        values: series,
                        color: accent,
                        fillColor: accent.withValues(alpha: 0.12),
                        endDotsOnly: true,
                        dotColor: accent,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: UiSpace.sm),
              Align(
                child: Semantics(
                  key: const ValueKey('quiet-hold'),
                  button: true,
                  label: holdLabel,
                  hint: l10n.journeys_quietHoldHint,
                  onTap: () => _reveal(!_revealed),
                  excludeSemantics: true,
                  child: Listener(
                    onPointerDown: (_) => _reveal(true),
                    onPointerUp: (_) => _reveal(false),
                    onPointerCancel: (_) => _reveal(false),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: UiSize.tap,
                        minHeight: UiSize.tap,
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(
                          horizontal: UiSpace.md,
                        ),
                        decoration: BoxDecoration(
                          color: _revealed
                              ? accent.withValues(alpha: 0.2)
                              : ui.fill,
                          borderRadius: BorderRadius.circular(UiRadius.capsule),
                          border: Border.all(color: ui.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            OurneyIcon(
                              name: _revealed ? 'eye' : 'eye-off',
                              size: 18,
                              flat: true,
                              color: ui.ink,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                holdLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: UiText.body(
                                  size: 13,
                                  height: 1.4,
                                  weight: FontWeight.w700,
                                  color: ui.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        for (var i = 0; i < days.length; i++)
          _QuietRow(
            day: days[i],
            first: i == 0,
            last: i == days.length - 1,
            onTap: widget.onTapDay,
            tag: days[i].isToday
                ? l10n.journeys_quietToday
                : marks.contains(days[i].dayNumber)
                ? markLabel(days[i].dayNumber)
                : null,
          ),
        const SizedBox(height: UiSpace.md),
        Row(
          key: const ValueKey('quiet-milestones'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final m in marks)
              Expanded(
                child: Column(
                  children: [
                    OurneyIcon(
                      name: 'star',
                      size: 20,
                      flat: m > current,
                      color: m > current ? ui.inkMuted : null,
                    ),
                    Text(
                      l10n.journeys_quietDayTag(m),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: UiText.muted(color: ui.inkMuted, size: 11),
                    ),
                    Text(
                      markLabel(m),
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: UiText.body(
                        size: 12,
                        height: 1.35,
                        weight: FontWeight.w700,
                        color: ui.ink,
                      ),
                    ),
                  ],
                ),
              ),
          ],
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
    this.tag,
  });

  final TimelineDay day;
  final bool first;
  final bool last;
  final ValueChanged<TimelineDay> onTap;
  final String? tag;

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
                        color: day.isToday ? accent : ui.outline,
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
                            tag == null
                                ? _dateText(context, day)
                                : '${_dateText(context, day)} · $tag',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: UiText.muted(color: ui.inkMuted, size: 12),
                          ),
                          if (day.state == DayState.missed)
                            Text(
                              JourneysL10n.of(context).journeys_quietMissed,
                              maxLines: 2,
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
  const SquadTimeline({
    required this.days,
    required this.onTapDay,
    this.window,
    this.onOpenEarlier,
    super.key,
  });

  final List<TimelineDay> days;
  final ValueChanged<TimelineDay> onTapDay;

  /// Long journeys: [days] is the Recent window and the path starts with a
  /// "section start" stone that stands for every earlier day.
  final TimelineWindow? window;
  final VoidCallback? onOpenEarlier;

  static const double _row = 76;
  static const double _stone = 56;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final accent = timelineAccent(context);
    final section = window != null && window!.hasEarlier;
    final skip = section ? 1 : 0;
    final total = days.length + 1 + skip; // + section stone + trophy
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
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: DashedPathPainter(
                        points: points,
                        color: ui.border,
                        curved: true,
                      ),
                    ),
                  ),
                ),
              ),
              if (section)
                Positioned(
                  left: points[0].dx - _stone / 2,
                  top: points[0].dy - _stone / 2,
                  child: TimelineSectionStone(
                    window: window!,
                    size: _stone,
                    onPressed: onOpenEarlier,
                  ),
                ),
              for (var i = 0; i < days.length; i++)
                Positioned(
                  left: points[i + skip].dx - _stone / 2,
                  top: points[i + skip].dy - _stone / 2,
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
                      border: Border.all(color: ui.outline, width: 2),
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
  const MemoryTimeline({
    required this.days,
    required this.onTapDay,
    this.showOfflineStamps = false,
    this.summary,
    super.key,
  });

  final List<TimelineDay> days;
  final ValueChanged<TimelineDay> onTapDay;

  /// Whole-journey numbers when [days] is only a window of the journey.
  final TimelineSummary? summary;

  /// Only with a backend: local-only check-ins are never uploaded.
  final bool showOfflineStamps;

  @override
  Widget build(BuildContext context) {
    final accent = timelineAccent(context);
    final frames =
        summary?.frames ??
        days
            .where(
              (d) => d.state == DayState.checkedIn || d.state == DayState.today,
            )
            // Every photo is a frame (several a day since `0014`, B-B5).
            .fold<int>(0, (n, d) => n + d.photoCount);
    final roll = Padding(
      padding: const EdgeInsets.only(bottom: UiSpace.sm),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: UiTag(
          key: const ValueKey('timeline-film-roll'),
          label: JourneysL10n.of(context).journeys_memoryFilmRoll(frames),
          glyph: OurneyIcon(
            name: 'camera',
            size: 12,
            flat: true,
            color: accent,
          ),
          foreground: accent,
        ),
      ),
    );
    final thread = Stack(
      key: const ValueKey('journey-timeline'),
      children: [
        Positioned.fill(
          child: ExcludeSemantics(
            child: LayoutBuilder(
              builder: (context, c) {
                final pts = [
                  for (var i = 0; i <= days.length; i++)
                    Offset(
                      c.maxWidth * (i.isEven ? 0.46 : 0.54),
                      c.maxHeight * i / days.length,
                    ),
                ];
                final ui = context.ui;
                return Stack(
                  children: [
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: DashedPathPainter(
                            // Scrapbook thread: weaves between the polaroids.
                            points: pts,
                            curved: true,
                            color: accent,
                            width: 2,
                            dash: 6,
                            gap: 5,
                          ),
                        ),
                      ),
                    ),
                    // Knots tied along the thread (four, like the Figma).
                    for (var k = 1; k <= 4; k++)
                      if (pts.length > k * 2)
                        Positioned(
                          key: ValueKey('timeline-knot-$k'),
                          left: pts[(pts.length - 1) * k ~/ 5].dx - 5,
                          top: pts[(pts.length - 1) * k ~/ 5].dy - 5,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: ui.bg,
                              border: Border.all(color: accent, width: 2),
                            ),
                          ),
                        ),
                  ],
                );
              },
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < days.length; i++)
              _ScrapRow(
                day: days[i],
                index: i,
                onTap: onTapDay,
                showOfflineStamp: showOfflineStamps,
              ),
          ],
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [roll, thread],
    );
  }
}

class _ScrapRow extends StatelessWidget {
  const _ScrapRow({
    required this.day,
    required this.index,
    required this.onTap,
    required this.showOfflineStamp,
  });

  final TimelineDay day;
  final int index;
  final ValueChanged<TimelineDay> onTap;
  final bool showOfflineStamp;

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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      day.state == DayState.today
                          ? JourneysL10n.of(context).journeys_memoryToday
                          : _dayText(context, day),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: timelineHeading(context, size: 13),
                    ),
                    if (showOfflineStamp &&
                        day.checkIn != null &&
                        !day.checkIn!.uploaded)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: UiTag(
                          key: ValueKey('timeline-offline-${day.dayNumber}'),
                          label: JourneysL10n.of(context)
                              .journeys_memoryOffline,
                          foreground: ui.inkMuted,
                        ),
                      ),
                  ],
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
  const CoupleTimeline({
    required this.days,
    required this.onTapDay,
    this.selfName,
    this.partnerName,
    super.key,
  });

  final List<TimelineDay> days;
  final ValueChanged<TimelineDay> onTapDay;

  /// Persisted couple names; null falls back to You / Partner.
  final String? selfName;
  final String? partnerName;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('journey-timeline'),
      children: [
        for (final d in days)
          _CouplePair(
            day: d,
            onTap: onTapDay,
            selfName: selfName,
            partnerName: partnerName,
          ),
      ],
    );
  }
}

class _CouplePair extends StatelessWidget {
  const _CouplePair({
    required this.day,
    required this.onTap,
    this.selfName,
    this.partnerName,
  });

  final TimelineDay day;
  final ValueChanged<TimelineDay> onTap;
  final String? selfName;
  final String? partnerName;

  static const double _spine = 44;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final l10n = JourneysL10n.of(context);
    final accent = timelineAccent(context);
    final done = day.state == DayState.checkedIn;
    final partnerPhoto = day.partnerCheckIn;
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
                            label: selfName ?? l10n.journeys_coupleYou,
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
                                child: done
                                    ? OurneyIcon(
                                        name: 'heart',
                                        size: 22,
                                        color: accent,
                                        inkColor: ui.ink,
                                      )
                                    : OurneyIcon(
                                        name: 'heart',
                                        size: 22,
                                        flat: true,
                                        color: ui.inkMuted,
                                      ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: _CoupleHalf(
                            label: partnerName ?? l10n.journeys_ticketPartner,
                            child: partnerPhoto != null
                                ? _PartnerTile(checkIn: partnerPhoto, size: s)
                                : CustomPaint(
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
                                                padding: const EdgeInsets.all(
                                                  6,
                                                ),
                                                child: Text(
                                                  l10n.journeys_coupleWaiting,
                                                  maxLines: 3,
                                                  overflow:
                                                      TextOverflow.ellipsis,
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

/// The partner's photo in the pair row (replaces the waiting slot).
class _PartnerTile extends StatelessWidget {
  const _PartnerTile({required this.checkIn, required this.size});

  final CheckIn checkIn;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l10n = JourneysL10n.of(context);
    return Semantics(
      image: true,
      label: l10n.journeys_partnerPhotoSemantics,
      child: ClipRRect(
        key: const ValueKey('couple-partner-photo'),
        borderRadius: BorderRadius.circular(UiRadius.otp),
        child: SizedBox.square(
          dimension: size,
          child: JourneyPhoto(checkIn: checkIn, partner: true, cacheWidth: 320),
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
    return LayoutBuilder(
      builder: (context, c) {
        // U5: every day is a >= 48dp hit box. When 7 columns do not fit the
        // gutters (360dp phones) the calendar may bleed into them; the tile
        // keeps its look (pitch minus the hairline gap).
        final pitch = math.max(UiSize.tap, c.maxWidth / 7);
        final tile = pitch - _gap;
        final total = pitch * 7;
        return FractionallySizedBox(
          alignment: Alignment.topCenter,
          widthFactor: total / c.maxWidth,
          child: Column(
            key: const ValueKey('journey-timeline'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ExcludeSemantics(
                child: Row(
                  children: [
                    for (var i = 0; i < 7; i++)
                      SizedBox(
                        width: pitch,
                        child: Padding(
                          padding: const EdgeInsets.only(right: _gap),
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
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 7),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: ExcludeSemantics(
                      child: CustomPaint(
                        key: const ValueKey('timeline-chain-line'),
                        painter: ChainLinePainter(
                          runs: chainRuns(cells),
                          cell: tile,
                          gap: _gap,
                          color: accent,
                        ),
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      for (var r = 0; r < rows; r++)
                        Row(
                          children: [
                            for (var i = 0; i < 7; i++)
                              SizedBox.square(
                                dimension: pitch,
                                child: cells[r * 7 + i] == null
                                    ? null
                                    : TimelineGridCell(
                                        day: cells[r * 7 + i]!,
                                        size: tile,
                                        hit: pitch,
                                        onTap: onTapDay,
                                      ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Aesthetic flexer: telemetry pace sparkline above mono run nodes.
class FlexerTimeline extends StatelessWidget {
  const FlexerTimeline({
    required this.days,
    required this.onTapDay,
    this.summary,
    super.key,
  });

  final List<TimelineDay> days;
  final ValueChanged<TimelineDay> onTapDay;

  /// Whole-journey numbers when [days] is only a window of the journey.
  final TimelineSummary? summary;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final accent = timelineAccent(context);
    final sum = summary ?? TimelineSummary.fromDays(days);
    final series = sum.pace;
    final done = sum.done;
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
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: CurvePainter(
                        values: series,
                        color: accent,
                        smooth: false,
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: AlignmentDirectional.topStart,
                  child: TimelineNumber(
                    '$done/${sum.totalDays}',
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
