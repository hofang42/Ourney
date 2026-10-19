import 'package:flutter/material.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/theme/persona_theme.dart';
import '../../features/journeys/domain/journey_progress.dart';
import '../../features/journeys/ui/journey_photo.dart';
import 'l10n/generated/accountability_squad_localizations.dart';
import 'persona_palette.dart';
import 'persona_widgets.dart';
import 'winding_path_painter.dart';

/// **Task S1** (`PersonaSkinId.accountabilitySquad` — `steppingStoneQuest`):
/// Vertical S-curve winding stepping-stone trail leading up to the Day N Trophy,
/// with tilted Polaroid study checkpoints along the path.
///
/// Reuses [WindingPathPainter] (which **M1** also uses for `scrapbookThread`).
/// Uses `CustomScrollView` + `SliverList.builder` so 30+ days scroll smoothly
/// without building off-screen Polaroid subtrees eagerly.
class SteppingStoneQuestTimeline extends StatelessWidget {
  const SteppingStoneQuestTimeline({
    required this.journey,
    required this.days,
    this.onTapDay,
    this.photoBuilder,
    this.shrinkWrap = false,
    this.physics,
    super.key,
  });

  final Journey journey;
  final List<TimelineDay> days;
  final ValueChanged<TimelineDay>? onTapDay;

  /// Optional custom photo widget builder (useful for deterministic widget tests).
  final Widget Function(BuildContext context, TimelineDay day)? photoBuilder;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  /// Selects the stops drawn along the trail: every day that is behind the
  /// traveller (checked in or today). Days still ahead are not drawn as
  /// Polaroids; the trophy at the top of the road stands for the goal, as in
  /// the reference board. Before the first day, only Day 1 is shown.
  static List<TimelineDay> visibleCheckpoints(List<TimelineDay> allDays) {
    if (allDays.isEmpty) return const [];
    final reached = [
      for (final d in allDays)
        if (d.state != DayState.future) d,
    ];
    return reached.isEmpty ? [allDays.first] : reached;
  }

  @override
  Widget build(BuildContext context) {
    final pTheme = OurneyPersonaTheme.of(context);
    final l10n = AccountabilitySquadL10n.of(context);

    // Display top-down from latest checkpoint / trophy at top to Day 01 at bottom
    // matching P2 · left reference board ("DAY 30 GOAL" trophy at top, then
    // "DAY 21 · TODAY", "DAY 14 ★ WEEK 2", "DAY 07 ★ WEEK 1", "DAY 01 · START").
    final checkpoints = visibleCheckpoints(days).reversed.toList();
    final todayIndex = checkpoints.indexWhere((d) => d.isToday);
    final goalDays =
        journey.durationDays ?? (days.isNotEmpty ? days.last.dayNumber : 30);

    final durationBadge = journey.durationDays != null
        ? l10n.accountability_squad_daysDuration(journey.durationDays!)
        : l10n.accountability_squad_openDuration;
    final topPillText =
        '${journey.emoji} ${journey.title.toUpperCase()} · $durationBadge';

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final hPad = PersonaLayout.horizontalPadding(width);

        return CustomScrollView(
          key: const ValueKey('stepping-stone-quest-scroll'),
          shrinkWrap: shrinkWrap,
          physics: physics,
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 8),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    SquadPersonaPill(
                      key: const ValueKey('s1-top-pill'),
                      expand: true,
                      label: topPillText,
                    ),
                    const SizedBox(height: 10),
                    _TrophyGoalHeader(
                      key: const ValueKey('s1-goal-trophy'),
                      goalDay: goalDays,
                      label: l10n.accountability_squad_dayGoalTrophy(goalDays),
                      pTheme: pTheme,
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 28),
              sliver: SliverList.builder(
                itemCount: checkpoints.length,
                itemBuilder: (context, index) {
                  final day = checkpoints[index];
                  final isLeft = index.isEven;
                  return _SteppingStoneSegment(
                    key: ValueKey('s1-node-day-${day.dayNumber}'),
                    day: day,
                    isLeft: isLeft,
                    hasPrev: index > 0,
                    hasNext: index < checkpoints.length - 1,
                    index: index,
                    todayIndex: todayIndex,
                    l10n: l10n,
                    pTheme: pTheme,
                    onTap: onTapDay == null ? null : () => onTapDay!(day),
                    photoBuilder: photoBuilder,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TrophyGoalHeader extends StatelessWidget {
  const _TrophyGoalHeader({
    required this.goalDay,
    required this.label,
    required this.pTheme,
    super.key,
  });

  final int goalDay;
  final String label;
  final OurneyPersonaTheme pTheme;

  /// Trophy gold stays the same in both themes (it is an illustration, not a
  /// surface), with a warm halo that reads on cream and on night navy alike.
  static const Color _gold = PersonaPalette.trophyGold;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _gold.withValues(alpha: 0.38),
                    _gold.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
            const Icon(Icons.emoji_events_rounded, size: 60, color: _gold),
          ],
        ),
        const SizedBox(height: 2),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 128),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: pTheme.ink,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              height: 1.3,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _SteppingStoneSegment extends StatelessWidget {
  const _SteppingStoneSegment({
    required this.day,
    required this.isLeft,
    required this.hasPrev,
    required this.hasNext,
    required this.index,
    required this.todayIndex,
    required this.l10n,
    required this.pTheme,
    required this.onTap,
    required this.photoBuilder,
    super.key,
  });

  final TimelineDay day;
  final bool isLeft;
  final bool hasPrev;
  final bool hasNext;

  /// Position in the top-down list and the index of today's stop (`-1` when
  /// the journey has no "today"): the road is highlighted from today up to the
  /// trophy.
  final int index;
  final int todayIndex;
  final AccountabilitySquadL10n l10n;
  final OurneyPersonaTheme pTheme;
  final VoidCallback? onTap;
  final Widget Function(BuildContext context, TimelineDay day)? photoBuilder;

  String _captionFor(TimelineDay d) {
    final numStr = d.dayNumber.toString().padLeft(2, '0');
    if (d.isToday) {
      return l10n.accountability_squad_dayTodayLabel(numStr);
    }
    if (d.dayNumber == 1) {
      return l10n.accountability_squad_dayStartLabel(numStr);
    }
    if (d.dayNumber % 7 == 0) {
      return l10n.accountability_squad_dayWeekMilestone(
        numStr,
        d.dayNumber ~/ 7,
      );
    }
    return l10n.accountability_squad_dayRegularLabel(numStr);
  }

  @override
  Widget build(BuildContext context) {
    final caption = _captionFor(day);
    final tilt = isLeft ? -0.05 : 0.05;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth.clamp(
          240.0,
          PersonaLayout.maxContentWidth,
        );
        final cardWidth = (maxW * 0.31).clamp(100.0, 150.0);
        // Neighbouring stops sit on opposite sides, so the slots overlap
        // vertically and the road reads as one tight winding path.
        final segmentHeight = cardWidth * 0.66 + 14.0;
        final nodeY = segmentHeight * 0.5;

        // Road nodes: it swings toward the side that holds this day's card,
        // and each node's neighbours sit on the opposite side.
        double nodeX(bool left) => left ? maxW * 0.40 : maxW * 0.60;
        final prevNode = Offset(
          hasPrev ? nodeX(!isLeft) : maxW * 0.5,
          hasPrev ? nodeY - segmentHeight : 0,
        );
        final node = Offset(nodeX(isLeft), nodeY);
        final nextNode = Offset(
          hasNext ? nodeX(!isLeft) : maxW * 0.5,
          nodeY + segmentHeight,
        );

        // Orange = the stretch still to walk: from today up to the trophy.
        final lowerAhead = todayIndex >= 0 && index < todayIndex;
        final upperAhead = todayIndex >= 0 && index <= todayIndex;
        final int activeFrom;
        final int activeTo;
        if (upperAhead && lowerAhead) {
          activeFrom = 0;
          activeTo = 2;
        } else if (upperAhead) {
          activeFrom = 0;
          activeTo = 1;
        } else {
          activeFrom = 0;
          activeTo = -1;
        }

        final Widget photoChild;
        if (photoBuilder != null) {
          photoChild = photoBuilder!(context, day);
        } else if (day.checkIn != null) {
          photoChild = JourneyPhoto(checkIn: day.checkIn!, cacheWidth: 280);
        } else {
          photoChild = _PlaceholderDayPhoto(
            day: day,
            missedLabel: l10n.accountability_squad_missedSlot,
            pTheme: pTheme,
          );
        }

        final stop = SizedBox(
          width: cardWidth,
          child: SquadPolaroidFrame(
            photo: photoChild,
            caption: caption,
            tiltRadians: tilt,
            chipCaption: true,
            highlighted: day.isToday,
            onTap: onTap,
          ),
        );

        return Center(
          child: SizedBox(
            width: maxW,
            height: segmentHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: WindingPathPainter(
                      waypoints: [prevNode, node, nextNode],
                      activeIndex: activeTo,
                      activeFromIndex: activeFrom,
                      style: WindingPathStyle.steppingStoneRibbon,
                      roundStart: !hasPrev,
                      clipToBand: true,
                      activeColor: pTheme.primaryAccent,
                      inactiveColor: pTheme.surfaceElevated,
                      outlineColor: pTheme.border,
                      ribbonWidth: (maxW * 0.085).clamp(24.0, 36.0),
                      outlineWidth: pTheme.borderWidth,
                    ),
                  ),
                ),
                // Positioned (not Align) so a taller card at large text scales
                // grows past the slot instead of overflowing it.
                Positioned(
                  top: (segmentHeight - cardWidth) / 2 - 6,
                  left: isLeft ? 0 : null,
                  right: isLeft ? null : 0,
                  child: stop,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PlaceholderDayPhoto extends StatelessWidget {
  const _PlaceholderDayPhoto({
    required this.day,
    required this.missedLabel,
    required this.pTheme,
  });

  final TimelineDay day;
  final String missedLabel;
  final OurneyPersonaTheme pTheme;

  @override
  Widget build(BuildContext context) {
    final isToday = day.isToday;
    return Container(
      color: pTheme.surfaceElevated,
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isToday
                ? Icons.camera_alt_rounded
                : day.state == DayState.future
                ? Icons.flag_outlined
                : Icons.menu_book_rounded,
            size: 26,
            color: isToday ? pTheme.primaryAccent : pTheme.inkMuted,
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              missedLabel,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: pTheme.inkMuted,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
