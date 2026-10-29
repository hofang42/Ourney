import 'package:flutter/widgets.dart';
import 'package:ourney_core/ourney_core.dart';

import 'accountability_squad/l10n/generated/accountability_squad_localizations.dart';
import 'accountability_squad/share_card.dart';
import 'accountability_squad/timeline.dart';
import 'aesthetic_flexer/share_card.dart';
import 'aesthetic_flexer/timeline.dart';
import 'couple_rituals/share_card.dart';
import 'couple_rituals/timeline.dart';
import 'memory_collectors/share_card.dart';
import 'memory_collectors/timeline.dart';
import 'minimalist_habit/share_card.dart';
import 'minimalist_habit/timeline.dart';
import 'persona_contract.dart';
import 'persona_placeholder.dart';
import 'quiet_transformer/share_card.dart';
import 'quiet_transformer/timeline.dart';

typedef PersonaTimelineBuilder = Widget Function(
  BuildContext context,
  PersonaTimelineData data,
);
typedef PersonaShareBuilder = Widget Function(
  BuildContext context,
  PersonaShareData data,
);
typedef PersonaGroupBuilder = Widget Function(
  BuildContext context,
  PersonaGroupData data,
);

/// The three screens (and, for some personas, the group wall) of one
/// persona. This is the only place that knows which widget draws what.
///
/// When you finish a persona, change its entry below to your final widget
/// and keep the signature `Widget Function(BuildContext, Persona...Data)`.
@immutable
class PersonaStyle {
  const PersonaStyle({
    required this.skin,
    required this.timeline,
    required this.share,
    this.group,
  });

  final PersonaSkinId skin;
  final PersonaTimelineBuilder timeline;
  final PersonaShareBuilder share;

  /// Squad wall for the group tab. Null: the group screen keeps its
  /// default member list.
  final PersonaGroupBuilder? group;
}

/// The style of [skin].
PersonaStyle personaStyleFor(PersonaSkinId skin) => _styles[skin]!;

final Map<PersonaSkinId, PersonaStyle> _styles = {
  PersonaSkinId.quietTransformer: PersonaStyle(
    skin: PersonaSkinId.quietTransformer,
    timeline: (_, d) => ConnectedWeightCurveTimeline(data: d),
    share: (_, d) => SideBySideArchiveShareCard(data: d),
  ),
  PersonaSkinId.accountabilitySquad: PersonaStyle(
    skin: PersonaSkinId.accountabilitySquad,
    timeline: (_, d) => SteppingStoneQuestTimeline(
      journey: d.journey,
      days: d.days,
      onTapDay: d.onTapDay,
      photoBuilder: d.photoBuilder,
      shrinkWrap: d.shrinkWrap,
      physics: d.physics,
    ),
    // S3 is the squad wall; it needs the group members, which the share
    // screen does not load, so the share board is a summary card until a
    // follow-up wires the members in.
    share: (_, d) => _SquadSummary(data: d),
    group: (_, d) => SquadPolaroidWall(
      journey: d.journey,
      members: d.members,
      reactionsEnabled: d.reactionsEnabled,
      onNudge: d.onNudge,
      photoBuilder: d.photoBuilder,
      shrinkWrap: d.shrinkWrap,
      physics: d.physics,
    ),
  ),
  PersonaSkinId.memoryCollectors: PersonaStyle(
    skin: PersonaSkinId.memoryCollectors,
    timeline: (_, d) => ScrapbookThreadTimeline(
      journey: d.journey,
      days: d.days,
      onTapDay: d.onTapDay,
      photoBuilder: d.photoBuilder,
      shrinkWrap: d.shrinkWrap,
      physics: d.physics,
    ),
    share: (_, d) => FilmContactSheetShareCard(
      journey: d.journey,
      checkIns: d.checkIns,
      onSharePoster: d.onShare,
      publicLinkSection: d.publicLinkSection,
      photoBuilder: d.photoBuilder,
      shrinkWrap: d.shrinkWrap,
      physics: d.physics,
    ),
  ),
  PersonaSkinId.coupleRituals: PersonaStyle(
    skin: PersonaSkinId.coupleRituals,
    timeline: (_, d) => DuoSplitTimeline(data: d),
    share: (_, d) => CoupleMosaicPosterShareCard(data: d),
  ),
  PersonaSkinId.aestheticFlexer: PersonaStyle(
    skin: PersonaSkinId.aestheticFlexer,
    timeline: (_, d) => AthleticTelemetryTimeline(data: d),
    share: (_, d) => TransparentStoryStickerShareCard(data: d),
  ),
  PersonaSkinId.minimalistHabit: PersonaStyle(
    skin: PersonaSkinId.minimalistHabit,
    timeline: (_, d) => ChainCalendarGridTimeline(data: d),
    share: (_, d) => ZenSummaryCardShareCard(data: d),
  ),
};

/// Summary card of the squad persona's share board (see [PersonaStyle.share]).
class _SquadSummary extends StatelessWidget {
  const _SquadSummary({required this.data});

  final PersonaShareData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AccountabilitySquadL10n.of(context);
    final days = data.journey.durationDays;
    return PlaceholderShareBoard(
      data: data,
      styleName: l10n.accountability_squad_streakBadge(data.currentStreak),
      facts: [if (days != null) l10n.accountability_squad_daysDuration(days)],
    );
  }
}
