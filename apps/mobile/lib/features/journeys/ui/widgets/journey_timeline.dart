import 'package:flutter/widgets.dart';

import '../../../../ui/ui.dart';
import '../../domain/journey_progress.dart';
import '../../domain/timeline_window.dart';
import '../journey_style.dart';
import 'timeline_cards.dart';
import 'timeline_variants.dart';

/// Wraps a checked-in [day]'s photo cell in a [UiHero] keyed by
/// [UiHeroTags.dayPhoto] so tapping it flies smoothly into `DayViewerScreen`
/// (and back on pop or interactive vertical drag-to-dismiss).
Widget wrapTimelineDayHero(
  TimelineDay day,
  Widget child, {
  BorderRadius? borderRadiusBegin,
}) {
  final entryId = day.checkIn?.id;
  if (day.state != DayState.checkedIn || entryId == null) return child;
  return UiHero(
    tag: UiHeroTags.dayPhoto(entryId),
    borderRadiusBegin:
        borderRadiusBegin ?? BorderRadius.circular(UiRadius.otp),
    borderRadiusEnd: BorderRadius.circular(UiRadius.card),
    child: child,
  );
}

/// The journey detail timeline in the variant of [skinId] (`quiet`, `squad`,
/// `memory`, `couple`, `flexer`, `minimal`; V2 skin ids). Every variant keeps
/// the `journey-timeline` key, one `day-<date>` node per day and opens
/// [onTapDay] for checked-in days. Colors come from the `UiSkinScope` above.
///
/// Long journeys pass the Recent [window] (and the whole-journey [summary]):
/// [days] is then only the window, with an "Earlier" link above it and the
/// finish card below.
class JourneyTimeline extends StatelessWidget {
  const JourneyTimeline({
    required this.skinId,
    required this.days,
    required this.pal,
    required this.onTapDay,
    this.selfName,
    this.partnerName,
    this.selfOnRight = false,
    this.showOfflineStamps = false,
    this.startingWeight,
    this.isOpenEnded = false,
    this.showMilestones = true,
    this.summary,
    this.window,
    this.onOpenEarlier,
    this.rangeShort,
    this.onRangeChanged,
    super.key,
  });

  /// Offline stamps need a server to sync to; local-only never shows them.
  final bool showOfflineStamps;

  /// Baseline weight from Create Flow (`UX-02`), prepended to the quiet curve.
  final double? startingWeight;

  /// True when the journey has no fixed duration (`durationDays == null`).
  final bool isOpenEnded;

  /// Whether [QuietTimeline] renders its inline milestone stars (`false` on
  /// [JourneyDetailScreen] where [JourneyHomeMilestones] already renders them).
  final bool showMilestones;

  /// Couple names of the journey (couple skin only).
  final String? selfName;
  final String? partnerName;

  /// True when the owner chose the right-hand diptych slot (`dna['side'] == 'right'`).
  final bool selfOnRight;

  final String skinId;
  final List<TimelineDay> days;
  final JourneyPalette pal;
  final ValueChanged<TimelineDay> onTapDay;

  /// Whole-journey curves and totals (long journeys).
  final TimelineSummary? summary;

  /// The Recent window (long journeys).
  final TimelineWindow? window;

  /// Switches to the By month archive at the month before the window.
  final VoidCallback? onOpenEarlier;

  /// Quiet curve range kept by the screen (null: the widget keeps it).
  final bool? rangeShort;
  final ValueChanged<bool>? onRangeChanged;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      // Nothing to list, but the finish card still tells the way.
      final w = window;
      return w != null && w.hasEndCap
          ? TimelineEndCap(window: w)
          : const SizedBox.shrink();
    }
    final core = switch (skinId) {
      'quiet' => QuietTimeline(
        days: days,
        onTapDay: onTapDay,
        summary: summary,
        short: rangeShort,
        onShortChanged: onRangeChanged,
        startingWeight: startingWeight,
        isOpenEnded: isOpenEnded,
        showMilestones: showMilestones,
      ),
      'squad' => SquadTimeline(
        days: days,
        onTapDay: onTapDay,
        window: window,
        onOpenEarlier: onOpenEarlier,
      ),
      'memory' => MemoryTimeline(
        days: days,
        onTapDay: onTapDay,
        showOfflineStamps: showOfflineStamps,
        summary: summary,
      ),
      'couple' => CoupleTimeline(
        days: days,
        onTapDay: onTapDay,
        selfName: selfName,
        partnerName: partnerName,
        selfOnRight: selfOnRight,
      ),
      'flexer' => FlexerTimeline(
        days: days,
        onTapDay: onTapDay,
        summary: summary,
      ),
      _ => MinimalTimeline(days: days, onTapDay: onTapDay),
    };
    final w = window;
    if (w == null) return core;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (w.hasEarlier && skinId != 'squad' && onOpenEarlier != null)
          TimelineEarlierLink(window: w, onPressed: onOpenEarlier!),
        core,
        if (w.hasEndCap) TimelineEndCap(window: w),
      ],
    );
  }
}