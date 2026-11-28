import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../data/group_daily_checkins_provider.dart';
import '../../../../ui/ui.dart';
import '../../domain/journey_progress.dart';
import '../../domain/timeline_window.dart';
import '../../l10n/generated/journeys_localizations.dart';
import '../journey_photo.dart';
import 'journey_timeline.dart' show wrapTimelineDayHero;
import 'timeline_cards.dart';
import 'timeline_common.dart';

export 'photo_log_timelines.dart';

String _dayText(BuildContext context, TimelineDay d) =>
    JourneysL10n.of(context).journeys_dayOpen(d.dayNumber);

String _dateText(BuildContext context, TimelineDay d) =>
    MaterialLocalizations.of(context).formatShortDate(displayDateOf(d));

DateTime displayDateOf(TimelineDay d) =>
    DateTime(d.date.year, d.date.month, d.date.day);

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
    final accentText = timelineAccentText(context);
    if (day.state == DayState.checkedIn || day.state == DayState.today) {
      return wrapTimelineDayHero(
        day,
        TimelineTile(day: day, size: size, round: true),
        borderRadiusBegin: BorderRadius.circular(size),
      );
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
        color: day.state == DayState.missed ? ui.ink : accentText,
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
    final accentText = timelineAccentText(context);
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
            color: accentText,
          ),
          foreground: accentText,
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
                child: wrapTimelineDayHero(
                  day,
                  TimelineTile(day: day, size: 96),
                ),
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

/// Authored photo slots on either side of the Couple timeline.
class CoupleTimeline extends StatelessWidget {
  const CoupleTimeline({
    required this.days,
    required this.onTapDay,
    this.selfName,
    this.partnerName,
    this.selfOnRight = false,
    super.key,
  });

  final List<TimelineDay> days;
  final ValueChanged<TimelineDay> onTapDay;

  /// Persisted couple names; null falls back to You / Partner.
  final String? selfName;
  final String? partnerName;
  final bool selfOnRight;

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
            selfOnRight: selfOnRight,
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
    this.selfOnRight = false,
  });

  final TimelineDay day;
  final ValueChanged<TimelineDay> onTap;
  final String? selfName;
  final String? partnerName;
  final bool selfOnRight;

  static const double _spine = 44;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final l10n = JourneysL10n.of(context);
    final accent = timelineAccent(context);
    final done = day.canOpen;
    final slots = day.coupleSlots.isNotEmpty
        ? day.coupleSlots
        : [
            CouplePhotoSlot(
              isMine: true,
              displayName: selfName,
              checkIn: day.checkIn,
            ),
            CouplePhotoSlot(displayName: partnerName),
          ];
    final ordered = day.coupleSlots.isEmpty && selfOnRight
        ? slots.reversed.toList()
        : slots;
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
            Widget half(CouplePhotoSlot slot) => _CoupleHalf(
              label: slot.displayName?.trim().isNotEmpty == true
                  ? slot.displayName!.trim()
                  : slot.isMine
                  ? l10n.journeys_coupleYou
                  : l10n.journeys_ticketPartner,
              child: _tile(context, slot, s),
            );
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
                        Expanded(child: half(ordered.first)),
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
                        Expanded(child: half(ordered.last)),
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

  Widget _tile(BuildContext context, CouplePhotoSlot slot, double size) {
    final ui = context.ui;
    final l10n = JourneysL10n.of(context);
    final photo = slot.checkIn;
    if (photo != null && day.state != DayState.future) {
      final tile = ClipRRect(
        key: ValueKey(
          slot.isMine ? 'couple-own-photo' : 'couple-partner-photo',
        ),
        borderRadius: BorderRadius.circular(UiRadius.otp),
        child: SizedBox.square(
          dimension: size,
          child: JourneyPhoto(checkIn: photo, cacheWidth: 320),
        ),
      );
      return photo.id == day.viewerPhoto?.id
          ? wrapTimelineDayHero(day, tile)
          : tile;
    }
    if (slot.isMine && day.state == DayState.today) {
      return TimelineTile(day: day, size: size);
    }
    final label = slot.photoUnavailable
        ? l10n.journeys_photoUnavailable
        : !slot.isMine && day.isToday
        ? l10n.journeys_coupleWaiting
        : null;
    return CustomPaint(
      key: ValueKey(slot.isMine ? 'couple-own-slot' : 'couple-partner-slot'),
      foregroundPainter: DashedOutlinePainter(
        color: ui.border,
        width: 1.5,
        radius: UiRadius.otp,
      ),
      child: SizedBox.square(
        dimension: size,
        child: label == null
            ? null
            : Center(
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Text(
                    label,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: UiText.muted(color: ui.inkMuted, size: 11),
                  ),
                ),
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
                                    : wrapTimelineDayHero(
                                        cells[r * 7 + i]!,
                                        TimelineGridCell(
                                          day: cells[r * 7 + i]!,
                                          size: tile,
                                          hit: pitch,
                                          onTap: onTapDay,
                                        ),
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
