import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../../ui/ui.dart';
import '../../domain/journey_progress.dart';
import '../../domain/journey_time.dart';
import '../../domain/timeline_window.dart';
import '../../l10n/generated/journeys_localizations.dart';
import '../journey_photo.dart';
import 'journey_timeline.dart' show wrapTimelineDayHero;
import 'timeline_common.dart';

/// Tracks month ids toggled interactively by the user so only user-initiated
/// expand/collapse transitions play the 180ms accordion fade+size entrance
/// (never lazy rows scrolling into view).
final Set<int> _toggledArchiveMonths = <int>{};

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
  required String skinId,
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
    final isOpen = open.contains(m.id);
    final animateToggle = _toggledArchiveMonths.contains(m.id);
    final title = monthTitle(context, m);
    final plain = monthPlain(context, m);
    final summary = l10n.journeys_monthSummary(m.checked, m.days, m.photos);
    final key = headerKeys.putIfAbsent(m.id, GlobalKey.new);
    out.add(
      SliverMainAxisGroup(
        key: ValueKey('archive-month-${m.id}'),
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _FixedHeaderDelegate(
              extent: headerExtent,
              child: Stack(
                fit: StackFit.passthrough,
                children: [
                  UiMonthHeader(
                    key: key,
                    title: title,
                    summary: summary,
                    expanded: isOpen,
                    accent: accent,
                    background: paper,
                    semanticLabel: l10n.journeys_monthA11y(
                      plain,
                      m.checked,
                      m.days,
                      m.photos,
                    ),
                    semanticHint: isOpen
                        ? l10n.journeys_monthCollapseHint
                        : l10n.journeys_monthExpandHint,
                    onPressed: () {
                      unawaited(UiHaptics.selection());
                      _toggledArchiveMonths.add(m.id);
                      onToggle(m.id);
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
                          color: paper,
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
              index: index,
              skinId: skinId,
              accent: accent,
              pitch: pitch,
              firstDay: firstDay,
              dpr: dpr,
              animateEntrance: animateToggle,
              onTapDay: onTapDay,
            )
          else
            SliverFixedExtentList.builder(
              itemExtent: ArchiveGeometry.collapsedExtent,
              itemCount: 1,
              itemBuilder: (context, _) => _ArchiveToggleAnimator(
                key: ValueKey('archive-collapsed-anim-${m.id}'),
                monthId: m.id,
                animate: animateToggle,
                child: _CollapsedMonth(
                  month: m,
                  accent: accent,
                  dpr: dpr,
                ),
              ),
            ),
        ],
      ),
    );
  }
  return out;
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
    required this.skinId,
    required this.accent,
    required this.pitch,
    required this.firstDay,
    required this.dpr,
    required this.onTapDay,
    this.animateEntrance = false,
  });

  final MonthBucket month;
  final TimelineIndex index;
  final String skinId;
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
          monthId: month.id,
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
        partner: skinId == 'couple' && day.partnerCheckIn != null,
        onTap: onTapDay,
      ),
    );
  }
}

/// Plays a 180ms [FadeTransition] + [AnimatedSize] ([UiCurves.easeOutStrong])
/// when a month is interactively toggled open or collapsed, while preserving
/// exact sliver item extents for lazy scroll jumps.
class _ArchiveToggleAnimator extends StatefulWidget {
  const _ArchiveToggleAnimator({
    required this.monthId,
    required this.animate,
    required this.child,
    super.key,
  });

  final int monthId;
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
        ctrl.forward(from: 0.0).whenCompleteOrCancel(() {
          _toggledArchiveMonths.remove(widget.monthId);
        });
      } else {
        _toggledArchiveMonths.remove(widget.monthId);
      }
    } else if (UiMotion.reduced(context) && (_ctrl?.isAnimating ?? false)) {
      _ctrl?.value = 1.0;
      _toggledArchiveMonths.remove(widget.monthId);
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
    return AnimatedSize(
      duration: UiMotion.of(context, _kDuration),
      curve: UiCurves.easeOutStrong,
      alignment: Alignment.topCenter,
      child: FadeTransition(
        opacity: curved,
        child: widget.child,
      ),
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