import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../../ui/ui.dart';
import '../../domain/journey_progress.dart';
import '../../domain/journey_time.dart';
import '../../domain/run_stats.dart';
import '../../domain/timeline_window.dart';
import '../../l10n/generated/journeys_localizations.dart';
import '../journey_photo.dart';
import 'journey_timeline.dart' show wrapTimelineDayHero;
import 'photo_log_timelines.dart';
import 'timeline_common.dart';

/// Exact extents of the By month archive. Every row has a known height (no
/// measuring), so the lazy lists place month headers exactly and a jump to a
/// month lands on its header.
abstract final class ArchiveGeometry {
  /// Collapsed month body: 88dp row + 8dp gap.
  static const double collapsedExtent = 96;

  /// Weekday letters above an expanded month.
  static const double weekdayExtent = 24;

  /// Gap below an expanded month.
  static const double gapExtent = 12;

  /// Year divider.
  static const double yearExtent = 36;

  /// Cover thumbnail side of a collapsed month.
  static const double cover = 56;

  /// Pitch (cell + hit box) of the grid: seven columns, never below the 48dp
  /// touch target (narrow phones let the grid bleed into the gutters, like
  /// the minimal calendar).
  static double pitchFor(double contentWidth) =>
      math.max(UiSize.tap, contentWidth / 7);

  /// Blank cells before the first day: the weekday of [first] relative to
  /// the locale's first weekday (0 = Sunday).
  static int leading(LocalDate first, int firstDayOfWeekIndex) =>
      (displayDate(first).weekday % 7 - firstDayOfWeekIndex + 7) % 7;

  static int rowsOf(MonthBucket m, int firstDayOfWeekIndex) =>
      ((leading(m.first, firstDayOfWeekIndex) + m.days) / 7).ceil();
}

/// Title of a month: `THÁNG 10 2026`.
String monthTitle(BuildContext context, MonthBucket m) => DateFormat(
  'MMMM y',
  Localizations.localeOf(context).toString(),
).format(DateTime(m.year, m.month)).toUpperCase();

/// Month in running text: `tháng 10 2026`.
String monthPlain(BuildContext context, MonthBucket m) => DateFormat(
  'MMMM y',
  Localizations.localeOf(context).toString(),
).format(DateTime(m.year, m.month));

/// Short month for the jump chips: `Thg 10`.
String monthShort(BuildContext context, MonthBucket m) =>
    toBeginningOfSentenceCase(
      DateFormat(
        'MMM',
        Localizations.localeOf(context).toString(),
      ).format(DateTime(m.year, m.month)),
    );

/// The By month archive as slivers: one [SliverMainAxisGroup] per month,
/// newest first, each a pinned [UiMonthHeader] over a lazily built body.
/// Headers are always built (they are the headings a screen reader jumps
/// between); bodies build only the rows in view. A collapsed month is a
/// 3-cover row with a heat strip; an open one a 7-column grid, one lazy row
/// per week.
List<Widget> buildArchiveSlivers({
  required BuildContext context,
  required TimelineIndex index,
  required Set<int> open,
  required Map<int, GlobalKey> headerKeys,
  required Color paper,
  required Color accent,
  required ValueChanged<int> onToggle,
  required ValueChanged<TimelineDay> onTapDay,
}) {
  final l10n = JourneysL10n.of(context);
  final material = MaterialLocalizations.of(context);
  final firstDay = material.firstDayOfWeekIndex;
  final screen = MediaQuery.sizeOf(context).width;
  final gutter = UiSpace.gutter(screen);
  final contentWidth = math.min(screen, UiSpace.maxContent(screen)) - 2 * gutter;
  final pitch = ArchiveGeometry.pitchFor(contentWidth);
  final headerExtent = UiMonthHeader.extentOf(context);
  final dpr = MediaQuery.devicePixelRatioOf(context);
  final months = index.months;
  final multiYear = months.length > 1 && months.first.year != months.last.year;

  final out = <Widget>[];
  for (var i = months.length - 1; i >= 0; i--) {
    final m = months[i];
    if (multiYear && (i == months.length - 1 || months[i + 1].year != m.year)) {
      out.add(_YearDivider(year: m.year));
    }
    final skin = UiSkinScope.maybeOf(context)?.skin.id;
    if (skin == 'quiet' || skin == 'flexer') {
      final days = index.progress.range(m.first, m.last);
      final key = headerKeys.putIfAbsent(m.id, GlobalKey.new);
      final grid = JourneyWeekGrid(
        days: days,
        onTapDay: onTapDay,
        showKm: skin == 'flexer' && isRunJourney(index.progress.journey),
        aspectRatio: skin == 'quiet' ? 3 / 4 : 4 / 5,
      );
      out.add(
        SliverToBoxAdapter(
          child: UiMonthHeader(
            key: key,
            title: monthTitle(context, m),
            summary: l10n.journeys_monthSummary(m.checked, m.days, m.photos),
            expanded: open.contains(m.id),
            accent: accent,
            background: paper,
            semanticLabel: l10n.journeys_monthA11y(
              monthPlain(context, m),
              m.checked,
              m.days,
              m.photos,
            ),
            semanticHint: open.contains(m.id)
                ? l10n.journeys_monthCollapseHint
                : l10n.journeys_monthExpandHint,
            onPressed: () => onToggle(m.id),
          ),
        ),
      );
      if (open.contains(m.id)) out.addAll(grid.slivers(context));
      continue;
    }
    final isOpen = open.contains(m.id);
    final title = monthTitle(context, m);
    final plain = monthPlain(context, m);
    final summary = l10n.journeys_monthSummary(m.checked, m.days, m.photos);
    final key = headerKeys.putIfAbsent(m.id, GlobalKey.new);
    out.add(
      _ArchiveMonthGroup(
        key: ValueKey('archive-month-${m.id}'),
        month: m,
        index: index,
        isOpen: isOpen,
        headerKey: key,
        headerExtent: headerExtent,
        title: title,
        plain: plain,
        summary: summary,
        paper: paper,
        accent: accent,
        pitch: pitch,
        firstDay: firstDay,
        dpr: dpr,
        onToggle: onToggle,
        onTapDay: onTapDay,
      ),
    );
  }
  return out;
}

class _ArchiveMonthGroup extends StatefulWidget {
  const _ArchiveMonthGroup({
    required this.month,
    required this.index,
    required this.isOpen,
    required this.headerKey,
    required this.headerExtent,
    required this.title,
    required this.plain,
    required this.summary,
    required this.paper,
    required this.accent,
    required this.pitch,
    required this.firstDay,
    required this.dpr,
    required this.onToggle,
    required this.onTapDay,
    super.key,
  });

  final MonthBucket month;
  final TimelineIndex index;
  final bool isOpen;
  final GlobalKey headerKey;
  final double headerExtent;
  final String title;
  final String plain;
  final String summary;
  final Color paper;
  final Color accent;
  final double pitch;
  final int firstDay;
  final double dpr;
  final ValueChanged<int> onToggle;
  final ValueChanged<TimelineDay> onTapDay;

  @override
  State<_ArchiveMonthGroup> createState() => _ArchiveMonthGroupState();
}

class _ArchiveMonthGroupState extends State<_ArchiveMonthGroup> {
  bool _animateToggle = false;
  Timer? _toggleTimer;

  @override
  void didUpdateWidget(covariant _ArchiveMonthGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isOpen != widget.isOpen) {
      _toggleTimer?.cancel();
      if (!UiMotion.reduced(context)) {
        _animateToggle = true;
        _toggleTimer = Timer(const Duration(milliseconds: 180), () {
          _animateToggle = false;
        });
      } else {
        _animateToggle = false;
      }
    }
  }

  @override
  void dispose() {
    _toggleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = JourneysL10n.of(context);
    final m = widget.month;
    final isOpen = widget.isOpen;
    return SliverMainAxisGroup(
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _FixedHeaderDelegate(
            extent: widget.headerExtent,
            child: Stack(
              fit: StackFit.passthrough,
              children: [
                UiMonthHeader(
                  key: widget.headerKey,
                  title: widget.title,
                  summary: widget.summary,
                  expanded: isOpen,
                  accent: widget.accent,
                  background: widget.paper,
                  semanticLabel: l10n.journeys_monthA11y(
                    widget.plain,
                    m.checked,
                    m.days,
                    m.photos,
                  ),
                  semanticHint: isOpen
                      ? l10n.journeys_monthCollapseHint
                      : l10n.journeys_monthExpandHint,
                  onPressed: () {
                    unawaited(UiHaptics.selection());
                    widget.onToggle(m.id);
                  },
                ),
                PositionedDirectional(
                  end: 0,
                  top: 0,
                  bottom: 1,
                  width: UiSize.tap,
                  child: IgnorePointer(
                    child: ExcludeSemantics(
                      child: ColoredBox(
                        color: widget.paper,
                        child: Center(
                          child: AnimatedRotation(
                            key: ValueKey('archive-chevron-${m.id}'),
                            turns: isOpen ? 0.25 : 0.0,
                            duration: UiMotion.of(
                              context,
                              const Duration(milliseconds: 180),
                            ),
                            curve: UiCurves.easeOutStrong,
                            child: OurneyIcon(
                              name: 'chevron-right',
                              size: 20,
                              flat: true,
                              color: context.ui.ink,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isOpen)
          _MonthGrid(
            month: m,
            index: widget.index,
            accent: widget.accent,
            pitch: widget.pitch,
            firstDay: widget.firstDay,
            dpr: widget.dpr,
            animateEntrance: _animateToggle,
            onTapDay: widget.onTapDay,
          )
        else
          SliverFixedExtentList.builder(
            itemExtent: ArchiveGeometry.collapsedExtent,
            itemCount: 1,
            itemBuilder: (context, _) => _ArchiveToggleAnimator(
              key: ValueKey('archive-collapsed-anim-${m.id}'),
              animate: _animateToggle,
              child: _CollapsedMonth(
                month: m,
                accent: widget.accent,
                dpr: widget.dpr,
              ),
            ),
          ),
      ],
    );
  }
}

class _FixedHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _FixedHeaderDelegate({required this.extent, required this.child});

  final double extent;
  final Widget child;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => child;

  @override
  bool shouldRebuild(_FixedHeaderDelegate old) => true;
}

class _YearDivider extends StatelessWidget {
  const _YearDivider({required this.year});

  final int year;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return SliverToBoxAdapter(
      child: ExcludeSemantics(
        child: SizedBox(
          height: ArchiveGeometry.yearExtent,
          child: Row(
            children: [
              Text(
                '$year',
                style: UiText.body(
                  size: 12,
                  weight: FontWeight.w700,
                  height: 1.4,
                  color: ui.inkMuted,
                ),
              ),
              const SizedBox(width: UiSpace.sm),
              Expanded(child: Divider(height: 1, color: ui.divider)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Collapsed month: up to three cover thumbnails and a heat strip with one
/// bar per day. Decorative: the header carries the month's single node.
class _CollapsedMonth extends StatelessWidget {
  const _CollapsedMonth({
    required this.month,
    required this.accent,
    required this.dpr,
  });

  final MonthBucket month;
  final Color accent;
  final double dpr;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final cacheWidth = (ArchiveGeometry.cover * dpr).ceil();
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          key: ValueKey('archive-collapsed-${month.id}'),
          children: [
            for (final c in month.covers)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 6),
                child: SizedBox.square(
                  dimension: ArchiveGeometry.cover,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(UiRadius.otp),
                    child: JourneyPhoto(checkIn: c, cacheWidth: cacheWidth),
                  ),
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: 6),
                child: SizedBox(
                  height: 28,
                  child: CustomPaint(
                    painter: HeatStripPainter(
                      heat: month.heat,
                      on: accent,
                      off: ui.border,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One slim bar per day: the accent when the day has a photo, a hairline
/// when it was missed (state shows by shape, not only by color).
class HeatStripPainter extends CustomPainter {
  const HeatStripPainter({
    required this.heat,
    required this.on,
    required this.off,
  });

  final List<bool> heat;
  final Color on;
  final Color off;

  @override
  void paint(Canvas canvas, Size size) {
    final n = heat.length;
    if (n == 0) return;
    const gap = 2.0;
    final w = math.max(1.0, (size.width - gap * (n - 1)) / n);
    final onPaint = Paint()..color = on;
    final offPaint = Paint()..color = off;
    for (var i = 0; i < n; i++) {
      final x = i * (w + gap);
      if (heat[i]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, 0, w, size.height),
            const Radius.circular(1.5),
          ),
          onPaint,
        );
      } else {
        canvas.drawRect(
          Rect.fromLTWH(x, size.height - 2, w, 2),
          offPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(HeatStripPainter old) =>
      !listEquals(old.heat, heat) || old.on != on || old.off != off;
}

/// Open month: weekday letters, one lazy row per week and a gap. Day cells
/// are built from [TimelineIndex.progress] only when their row scrolls in.
class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.index,
    required this.accent,
    required this.pitch,
    required this.firstDay,
    required this.dpr,
    required this.onTapDay,
    this.animateEntrance = false,
  });

  final MonthBucket month;
  final TimelineIndex index;
  final Color accent;
  final double pitch;
  final int firstDay;
  final double dpr;
  final ValueChanged<TimelineDay> onTapDay;
  final bool animateEntrance;

  @override
  Widget build(BuildContext context) {
    final leading = ArchiveGeometry.leading(month.first, firstDay);
    final rows = ArchiveGeometry.rowsOf(month, firstDay);
    final tile = pitch - 3;
    return SliverVariedExtentList.builder(
      itemCount: rows + 2,
      itemExtentBuilder: (i, _) => i == 0
          ? ArchiveGeometry.weekdayExtent
          : i == rows + 1
          ? ArchiveGeometry.gapExtent
          : pitch,
      itemBuilder: (context, i) {
        if (i == 0) {
          return _WeekdayRow(pitch: pitch, firstDay: firstDay);
        }
        if (i == rows + 1) return const SizedBox.shrink();
        final r = i - 1;
        // Offset into the month's days for each column of this row.
        bool inMonth(int off) => off >= 0 && off < month.days;
        bool checked(int off) => inMonth(off) && month.heat[off];
        final offs = [for (var c = 0; c < 7; c++) r * 7 + c - leading];
        final rowWidget = OverflowBox(
          minWidth: pitch * 7,
          maxWidth: pitch * 7,
          child: Stack(
            children: [
              Positioned.fill(
                child: ExcludeSemantics(
                  child: CustomPaint(
                    painter: ChainRowPainter(
                      checked: [for (final o in offs) checked(o)],
                      joinsPrevious:
                          checked(offs.first) && checked(offs.first - 1),
                      joinsNext: checked(offs.last) && checked(offs.last + 1),
                      cell: tile,
                      pitch: pitch,
                      color: accent,
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  for (final o in offs)
                    SizedBox.square(
                      dimension: pitch,
                      child: inMonth(o)
                          ? _cell(month.first.addDays(o), tile)
                          : null,
                    ),
                ],
              ),
            ],
          ),
        );
        if (!animateEntrance) return rowWidget;
        return _ArchiveToggleAnimator(
          key: ValueKey('archive-row-anim-${month.id}-$r'),
          animate: animateEntrance,
          child: rowWidget,
        );
      },
    );
  }

  Widget _cell(LocalDate date, double tile) {
    final day = index.progress.dayAt(date);
    return wrapTimelineDayHero(
      day,
      TimelineGridCell(
        day: day,
        size: tile,
        hit: pitch,
        cacheWidth: (tile * dpr).ceil(),
        onTap: onTapDay,
      ),
    );
  }
}

/// Plays a 180ms [FadeTransition] + subtle `-4dp -> 0` vertical slide
/// ([UiCurves.easeOutStrong]) when a month is interactively toggled open or
/// collapsed, while preserving exact sliver item extents for lazy scroll jumps.
class _ArchiveToggleAnimator extends StatefulWidget {
  const _ArchiveToggleAnimator({
    required this.animate,
    required this.child,
    super.key,
  });

  final bool animate;
  final Widget child;

  @override
  State<_ArchiveToggleAnimator> createState() => _ArchiveToggleAnimatorState();
}

class _ArchiveToggleAnimatorState extends State<_ArchiveToggleAnimator>
    with SingleTickerProviderStateMixin {
  static const Duration _kDuration = Duration(milliseconds: 180);

  AnimationController? _ctrl;
  CurvedAnimation? _curved;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      if (widget.animate && !UiMotion.reduced(context)) {
        final ctrl = AnimationController(vsync: this, duration: _kDuration);
        _ctrl = ctrl;
        _curved = CurvedAnimation(parent: ctrl, curve: UiCurves.easeOutStrong);
        ctrl.forward(from: 0.0);
      }
    } else if (UiMotion.reduced(context) && (_ctrl?.isAnimating ?? false)) {
      _ctrl?.value = 1.0;
    }
  }

  @override
  void dispose() {
    _curved?.dispose();
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = _curved;
    if (UiMotion.reduced(context) || curved == null) {
      return widget.child;
    }
    final faded = FadeTransition(opacity: curved, child: widget.child);
    return AnimatedBuilder(
      animation: curved,
      child: faded,
      builder: (context, child) {
        final dy = (1.0 - curved.value) * -4.0;
        return Transform.translate(
          offset: Offset(0, dy),
          child: child,
        );
      },
    );
  }
}

class _WeekdayRow extends StatelessWidget {
  const _WeekdayRow({required this.pitch, required this.firstDay});

  final double pitch;
  final int firstDay;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final material = MaterialLocalizations.of(context);
    return ExcludeSemantics(
      child: OverflowBox(
        minWidth: pitch * 7,
        maxWidth: pitch * 7,
        child: Row(
          children: [
            for (var i = 0; i < 7; i++)
              SizedBox(
                width: pitch,
                child: Padding(
                  padding: const EdgeInsets.only(right: 3),
                  child: Text(
                    material.narrowWeekdays[(firstDay + i) % 7],
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    textScaler: MediaQuery.textScalerOf(
                      context,
                    ).clamp(maxScaleFactor: 1.35),
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
    );
  }
}
