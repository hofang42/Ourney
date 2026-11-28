import 'package:flutter/material.dart';

import '../../../../ui/ui.dart';
import '../../l10n/generated/journeys_localizations.dart';

/// Metric samples of a journey, oldest first (check-ins with a value only).
typedef MetricSeries = List<double>;

/// Day numbers of the three milestone cards (`quiet-milestones`): the first
/// week, the middle, the finish. Open-ended journeys use 7 / 14 / 30.
List<int> homeMilestoneDays(int? total) {
  if (total == null) return const [7, 14, 30];
  final days = <int>{
    if (total > 7) 7,
    if (total > 14) (total / 2).round(),
    total,
  }..removeWhere((d) => d < 1);
  return (days.toList()..sort());
}

String _milestoneLabel(JourneysL10n l, int day, int? total) {
  if (total != null && day == total) return l.journeys_home_msFinish;
  if (day == 7) return l.journeys_home_msWeek;
  return l.journeys_home_msHalf;
}

/// `quiet-milestones` / per-skin milestone cards: star disc, "NGÀY 07",
/// label. Reached ones are filled with the skin accent.
class JourneyHomeMilestones extends StatelessWidget {
  const JourneyHomeMilestones({
    required this.day,
    required this.total,
    required this.accent,
    required this.onAccent,
    super.key,
  });

  final int day;
  final int? total;
  final Color accent;
  final Color onAccent;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final l10n = JourneysL10n.of(context);
    final days = homeMilestoneDays(total);
    return Row(
      key: const ValueKey('journey-home-milestones'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final d in days)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Semantics(
                container: true,
                label:
                    '${_milestoneLabel(l10n, d, total)}, '
                    '${l10n.journeys_home_msDay(d)}',
                excludeSemantics: true,
                child: Column(
                  children: [
                    Container(
                      key: ValueKey('journey-milestone-$d'),
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: day >= d ? accent : ui.fill,
                        shape: BoxShape.circle,
                        border: Border.all(color: ui.border),
                      ),
                      child: OurneyIcon(
                        name: 'star',
                        size: 17,
                        flat: true,
                        color: day >= d ? onAccent : ui.inkMuted,
                      ),
                    ),
                    const SizedBox(height: UiSpace.xs),
                    Text(
                      l10n.journeys_home_msDay(d),
                      style: UiText.eyebrow(color: ui.inkMuted),
                    ),
                    Text(
                      _milestoneLabel(l10n, d, total),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: UiText.body(
                        size: 13,
                        weight: FontWeight.w700,
                        height: 1.35,
                        color: ui.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// "Hội hôm nay" (groups only) and "Tạo thiệp" (`quiet-home-actions`).
class JourneyHomeActions extends StatelessWidget {
  const JourneyHomeActions({
    required this.onShare,
    this.onSquad,
    this.onWrapped,
    super.key,
  });

  final VoidCallback onShare;

  /// Null for solo journeys (no squad row, as in Figma `journey.shared`).
  final VoidCallback? onSquad;

  /// Ended journeys: opens the finish story ("Xem tổng kết").
  final VoidCallback? onWrapped;

  @override
  Widget build(BuildContext context) {
    final l10n = JourneysL10n.of(context);
    return Column(
      key: const ValueKey('journey-home-actions'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (onWrapped != null) ...[
          UiButton(
            key: const ValueKey('journey-home-wrapped'),
            glyph: const OurneyIcon(name: 'trophy', size: 19, flat: true),
            label: l10n.journeys_home_viewWrapped,
            onPressed: onWrapped,
          ),
          const SizedBox(height: UiSpace.sm),
        ],
        if (onSquad != null) ...[
          UiButton.secondary(
            key: const ValueKey('journey-home-squad'),
            glyph: const OurneyIcon(name: 'squad', size: 19, flat: true),
            label: l10n.journeys_home_actionSquad,
            onPressed: onSquad,
          ),
          const SizedBox(height: UiSpace.sm),
        ],
        UiButton.secondary(
          key: const ValueKey('journey-home-card'),
          glyph: const OurneyIcon(name: 'share', size: 19, flat: true),
          label: l10n.journeys_home_actionCard,
          onPressed: onShare,
        ),
      ],
    );
  }
}

/// Progress chip of the squad / flexer homes (`squad-progress-chip`,
/// `flexer-attendance-chip`): days shot out of days elapsed.
class JourneyHomeAttendance extends StatelessWidget {
  const JourneyHomeAttendance({
    required this.done,
    required this.total,
    super.key,
  });

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        key: const ValueKey('journey-home-attendance'),
        padding: const EdgeInsets.symmetric(
          horizontal: UiSpace.md,
          vertical: UiSpace.sm,
        ),
        decoration: BoxDecoration(
          color: ui.fill,
          borderRadius: BorderRadius.circular(UiRadius.capsule),
          border: Border.all(color: ui.border),
        ),
        child: Text(
          JourneysL10n.of(context).journeys_home_attendance(done, total),
          style: UiText.eyebrow(color: ui.ink),
        ),
      ),
    );
  }
}
