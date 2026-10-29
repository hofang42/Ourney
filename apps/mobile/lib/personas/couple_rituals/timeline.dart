import 'package:flutter/material.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/theme/app_theme.dart' show displayStyle;
import '../../app/theme/persona_theme.dart';
import '../../app/theme/tokens.dart';
import '../../features/journeys/domain/journey_progress.dart';
import '../../features/journeys/ui/journey_photo.dart';
import '../../shared/dashed_placeholder.dart';
import '../../shared/layout.dart';
import '../../shared/persona_pill.dart';
import '../persona_contract.dart';
import 'l10n/generated/couple_rituals_localizations.dart';

/// **Task D2** (`PersonaSkinId.coupleRituals` — `duoSplitTimeline`):
/// Vertical timeline where each reached day is a paired horizontal diptych card:
/// - **Left**: Current user's photo (`myName`, defaults to localized "You").
/// - **Center**: Heart / Flame milestone node connecting the vertical spine.
/// - **Right**: Partner's photo (`partnerName`, defaults to localized
///   "Partner"), or a dashed waiting slot (`Waiting for {name}`).
/// - Never hardcodes gendered "His/Her" strings (`docs/TASKS.md` §3 D2).
class DuoSplitTimeline extends StatelessWidget {
  const DuoSplitTimeline({required this.data, super.key});

  final PersonaTimelineData data;

  static List<TimelineDay> visibleDuoDays(List<TimelineDay> allDays) {
    if (allDays.isEmpty) return const [];
    final reached = [
      for (final d in allDays)
        if (d.state != DayState.future && d.state != DayState.notCounted) d,
    ];
    return reached.isEmpty ? [allDays.first] : reached;
  }

  @override
  Widget build(BuildContext context) {
    final pTheme = OurneyPersonaTheme.of(context);
    final l10n = CoupleRitualsL10n.of(context);
    final items = visibleDuoDays(data.days);
    final myLabel = (data.myName != null && data.myName!.trim().isNotEmpty)
        ? data.myName!.trim()
        : l10n.couple_rituals_meDefault;
    final partnerLabel =
        (data.partnerName != null && data.partnerName!.trim().isNotEmpty)
        ? data.partnerName!.trim()
        : l10n.couple_rituals_partnerDefault;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final cardPad = OurneyLayout.cardPadding(width);

        final column = Column(
          key: const ValueKey('d2-duo-split-timeline'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                PersonaPill(
                  key: const ValueKey('d2-style-pill'),
                  icon: Icons.favorite_rounded,
                  label: l10n.couple_rituals_name,
                  emphasized: true,
                ),
                PersonaPill(
                  key: const ValueKey('d2-streak-pill'),
                  icon: Icons.local_fire_department_rounded,
                  label: l10n.couple_rituals_streakLabel(data.currentStreak),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              key: const ValueKey('journey-timeline'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < items.length; i++)
                  _DuoDiptychDayCard(
                    key: ValueKey('d2-day-card-${items[i].dayNumber}'),
                    day: items[i],
                    myLabel: myLabel,
                    partnerLabel: partnerLabel,
                    partnerCheckIn: data.partnerCheckInsByDate[items[i].date],
                    padding: cardPad,
                    isLast: i == items.length - 1,
                    pTheme: pTheme,
                    l10n: l10n,
                    onTap: data.onTapDay == null
                        ? null
                        : () => data.onTapDay!(items[i]),
                    photoBuilder: data.photoBuilder,
                    partnerPhotoBuilder: data.partnerPhotoBuilder,
                  ),
              ],
            ),
          ],
        );

        if (data.shrinkWrap) return column;
        return SingleChildScrollView(physics: data.physics, child: column);
      },
    );
  }
}

class _DuoDiptychDayCard extends StatelessWidget {
  const _DuoDiptychDayCard({
    required this.day,
    required this.myLabel,
    required this.partnerLabel,
    required this.partnerCheckIn,
    required this.padding,
    required this.isLast,
    required this.pTheme,
    required this.l10n,
    required this.onTap,
    required this.photoBuilder,
    required this.partnerPhotoBuilder,
    super.key,
  });

  final TimelineDay day;
  final String myLabel;
  final String partnerLabel;
  final CheckIn? partnerCheckIn;
  final double padding;
  final bool isLast;
  final OurneyPersonaTheme pTheme;
  final CoupleRitualsL10n l10n;
  final VoidCallback? onTap;
  final PersonaDayPhotoBuilder? photoBuilder;
  final PersonaCheckInPhotoBuilder? partnerPhotoBuilder;

  @override
  Widget build(BuildContext context) {
    final dayStr = day.dayNumber.toString().padLeft(2, '0');
    final headerText = day.isToday
        ? l10n.couple_rituals_todayHeader(dayStr)
        : l10n.couple_rituals_dayHeader(dayStr);
    final bothDone = day.checkIn != null && partnerCheckIn != null;
    final isMilestone =
        day.dayNumber == 1 || day.isToday || day.dayNumber % 7 == 0;

    final Widget mySide = day.checkIn != null
        ? (photoBuilder != null
              ? photoBuilder!(context, day)
              : JourneyPhoto(checkIn: day.checkIn!, thumbnail: true))
        : DashedPlaceholder(
            icon: Icons.photo_camera_outlined,
            label: myLabel,
            radius: 14,
          );

    final Widget partnerSide = partnerCheckIn != null
        ? (partnerPhotoBuilder != null
              ? partnerPhotoBuilder!(context, partnerCheckIn!)
              : JourneyPhoto(checkIn: partnerCheckIn!, thumbnail: true))
        : DashedPlaceholder(
            key: ValueKey('d2-partner-waiting-${day.dayNumber}'),
            icon: Icons.favorite_border_rounded,
            label: l10n.couple_rituals_waitingPartner(partnerLabel),
            radius: 14,
          );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: onTap != null,
          label: headerText,
          child: Material(
            color: pTheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(pTheme.cardRadius),
              side: BorderSide(
                color: day.isToday ? pTheme.primaryAccent : pTheme.border,
                width: day.isToday ? 1.5 : pTheme.borderWidth,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: OurneyLayout.minTouchTarget,
                ),
                child: Padding(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              headerText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: displayStyle(
                                size: 13.5,
                                weight: 700,
                                color: pTheme.ink,
                                height: 1.35,
                              ).copyWith(letterSpacing: 0.5),
                            ),
                          ),
                          Icon(
                            bothDone
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 18,
                            color: bothDone
                                ? pTheme.primaryAccent
                                : pTheme.inkMuted,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _HalfFrameTile(
                                  nameLabel: myLabel,
                                  pTheme: pTheme,
                                  child: mySide,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _HalfFrameTile(
                                  nameLabel: partnerLabel,
                                  pTheme: pTheme,
                                  child: partnerSide,
                                ),
                              ),
                            ],
                          ),
                          // Center Heart / Flame connector badge bridging the diptych
                          Container(
                            key: ValueKey('d2-center-node-${day.dayNumber}'),
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: bothDone || day.isToday
                                  ? pTheme.primaryAccent
                                  : pTheme.surfaceElevated,
                              border: Border.all(
                                color: pTheme.surface,
                                width: 2.5,
                              ),
                            ),
                            child: Icon(
                              isMilestone
                                  ? Icons.local_fire_department_rounded
                                  : Icons.favorite_rounded,
                              size: 16,
                              color: bothDone || day.isToday
                                  ? OurneyColors.mediaWhite
                                  : pTheme.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (!isLast)
          Container(
            width: 2,
            height: 14,
            color: pTheme.primaryAccent.withValues(alpha: 0.4),
          ),
      ],
    );
  }
}

class _HalfFrameTile extends StatelessWidget {
  const _HalfFrameTile({
    required this.nameLabel,
    required this.pTheme,
    required this.child,
  });

  final String nameLabel;
  final OurneyPersonaTheme pTheme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: child,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          nameLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: pTheme.inkMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}
