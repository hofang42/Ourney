import 'package:flutter/widgets.dart';

import '../../domain/journey_progress.dart';
import '../journey_style.dart';
import 'timeline_variants.dart';

/// The journey detail timeline in the variant of [skinId] (`quiet`, `squad`,
/// `memory`, `couple`, `flexer`, `minimal`; V2 skin ids). Every variant keeps
/// the `journey-timeline` key, one `day-<date>` node per day and opens
/// [onTapDay] for checked-in days. Colors come from the `UiSkinScope` above.
class JourneyTimeline extends StatelessWidget {
  const JourneyTimeline({
    required this.skinId,
    required this.days,
    required this.pal,
    required this.onTapDay,
    this.selfName,
    this.partnerName,
    super.key,
  });

  /// Couple names of the journey (couple skin only).
  final String? selfName;
  final String? partnerName;

  final String skinId;
  final List<TimelineDay> days;
  final JourneyPalette pal;
  final ValueChanged<TimelineDay> onTapDay;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const SizedBox.shrink();
    return switch (skinId) {
      'quiet' => QuietTimeline(days: days, onTapDay: onTapDay),
      'squad' => SquadTimeline(days: days, onTapDay: onTapDay),
      'memory' => MemoryTimeline(days: days, onTapDay: onTapDay),
      'couple' => CoupleTimeline(
        days: days,
        onTapDay: onTapDay,
        selfName: selfName,
        partnerName: partnerName,
      ),
      'flexer' => FlexerTimeline(days: days, onTapDay: onTapDay),
      _ => MinimalTimeline(days: days, onTapDay: onTapDay),
    };
  }
}
