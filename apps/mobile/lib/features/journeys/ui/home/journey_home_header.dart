import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../../data/group_daily_checkins_provider.dart';
import '../../../../ui/ui.dart';
import '../../domain/journey_title.dart';
import '../../domain/run_stats.dart';
import '../../domain/wrapped_story.dart';
import '../../l10n/generated/journeys_localizations.dart';

/// The distinct top of each skin's Journey Home (Figma `SquadJourneyHome`
/// progress chip + trophy, `MemoryJourneyHome` film chip, `CoupleJourneyHome`
/// pair header, `FlexerJourneyHome` summary, `MinimalJourneyHome` month
/// header). Quiet has none: its intro and weight chart are the header.
class JourneyHomeSkinHeader extends ConsumerWidget {
  const JourneyHomeSkinHeader({
    required this.journey,
    required this.skin,
    required this.day,
    required this.streak,
    required this.stats,
    required this.now,
    this.onTrophy,
    super.key,
  });

  final Journey journey;
  final PersonaSkinId skin;
  final int day;
  final int streak;
  final WrappedStats stats;
  final DateTime now;

  /// Trophy tap (finish story when done, share card before).
  final VoidCallback? onTrophy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = JourneysL10n.of(context);
    return switch (skin) {
      PersonaSkinId.quietTransformer ||
      PersonaSkinId.aestheticFlexer => const SizedBox.shrink(),
      PersonaSkinId.accountabilitySquad => _Squad(
        journey: journey,
        day: day,
        onTrophy: onTrophy,
      ),
      PersonaSkinId.memoryCollectors => _Film(
        frames: stats.moments,
        total: int.tryParse('${journey.dna?['film']}') ?? 24,
        l10n: l10n,
      ),
      PersonaSkinId.coupleRituals => _Couple(
        journey: journey,
        streak: streak,
        total: stats.total,
      ),
      PersonaSkinId.minimalistHabit => _Month(journeyId: journey.id),
    };
  }
}

Widget _pill(BuildContext context, Widget child, {Key? key}) {
  final ui = context.ui;
  return Container(
    key: key,
    padding: const EdgeInsets.symmetric(
      horizontal: UiSpace.md,
      vertical: UiSpace.sm,
    ),
    decoration: BoxDecoration(
      color: ui.surface,
      borderRadius: BorderRadius.circular(UiRadius.capsule),
      border: Border.all(color: ui.outline, width: 1.5),
    ),
    child: child,
  );
}

/// Overlapping avatars (`SquadAvatarStack`), up to five plus a "+n" disc.
class JourneyAvatarStack extends StatelessWidget {
  const JourneyAvatarStack({required this.members, this.size = 28, super.key});

  final List<({String id, String name})> members;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final shown = members.take(5).toList();
    final extra = members.length - shown.length;
    final step = size * 0.65;
    final n = shown.length + (extra > 0 ? 1 : 0);
    return SizedBox(
      key: const ValueKey('journey-avatar-stack'),
      width: n == 0 ? 0 : size + (n - 1) * step,
      height: size,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            PositionedDirectional(
              start: i * step,
              child: UiAvatar(
                name: shown[i].name,
                colorIndex: UiAvatar.indexFor(shown[i].id),
                size: size,
              ),
            ),
          if (extra > 0)
            PositionedDirectional(
              start: shown.length * step,
              child: Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ui.fill,
                  shape: BoxShape.circle,
                  border: Border.all(color: ui.outline, width: 1.5),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Text(
                      '+$extra',
                      maxLines: 1,
                      style: UiText.fieldLabel(color: ui.ink),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Squad extends ConsumerWidget {
  const _Squad({required this.journey, required this.day, this.onTrophy});

  final Journey journey;
  final int day;
  final VoidCallback? onTrophy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = JourneysL10n.of(context);
    final ui = context.ui;
    final members =
        ref.watch(groupMembersTodaySafeProvider(journey.id)).value ??
        const <MemberToday>[];
    final done = members.where((m) => m.checkedIn).length;
    final total = members.isEmpty ? 1 : members.length;
    final trophy =
        (journey.dna?['trophy'] as String?)?.trim().toUpperCase() ??
        l10n.journeys_home_trophyDefault;
    final duration = journey.durationDays;
    final chipText = duration == null
        ? l10n.journeys_home_squadChipOpen(journey.title.toUpperCase())
        : keepNumberWithUnit(
            titleStatesLength(journey.title)
                ? journey.title.toUpperCase()
                : l10n.journeys_home_squadChip(
                    journey.title.toUpperCase(),
                    duration,
                  ),
          );
    final trophySubtitle = duration == null
        ? l10n.journeys_home_trophyOpen
        : l10n.journeys_home_trophyDay(duration);
    return Column(
      key: const ValueKey('journey-home-squad-header'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _pill(
          context,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const OurneyIcon(name: 'flame', size: 17, flat: true),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      chipText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: UiText.eyebrow(color: ui.ink),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (members.isNotEmpty) ...[
                    JourneyAvatarStack(
                      members: [
                        for (final m in members)
                          (id: m.userId, name: m.displayName),
                      ],
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      l10n.journeys_home_squadToday(done, total),
                      key: const ValueKey('journey-squad-today'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: UiText.eyebrow(color: ui.ink),
                    ),
                  ),
                ],
              ),
            ],
          ),
          key: const ValueKey('journey-squad-chip'),
        ),
        const SizedBox(height: UiSpace.md),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: UiPressable(
            key: const ValueKey('journey-squad-trophy'),
            onPressed: onTrophy,
            semanticLabel: '$trophy, $trophySubtitle',
            excludeChildSemantics: true,
            borderRadius: BorderRadius.circular(UiRadius.menu),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: UiSpace.md,
                vertical: UiSpace.sm,
              ),
              decoration: BoxDecoration(
                color: ui.surface,
                borderRadius: BorderRadius.circular(UiRadius.menu),
                border: Border.all(color: ui.outline, width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const OurneyIcon(name: 'trophy', size: 38, active: true),
                  const SizedBox(width: UiSpace.sm),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trophy,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: UiText.h2(
                            color: ui.ink,
                            size: 16,
                          ).copyWith(height: 1.3),
                        ),
                        Text(
                          trophySubtitle,
                          style: UiText.eyebrow(color: ui.inkMuted),
                        ),
                      ],
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

class _Film extends StatelessWidget {
  const _Film({required this.frames, required this.total, required this.l10n});

  final int frames;
  final int total;
  final JourneysL10n l10n;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return Column(
      key: const ValueKey('journey-home-film-header'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _pill(
          context,
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const OurneyIcon(name: 'gallery', size: 19, flat: true),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  l10n.journeys_home_filmRoll(frames, total),
                  key: const ValueKey('journey-film-chip'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.eyebrow(color: ui.ink),
                ),
              ),
            ],
          ),
        ),
        if (frames >= total)
          Padding(
            padding: const EdgeInsets.only(top: UiSpace.sm),
            child: Text(
              l10n.journeys_home_rollNote(total),
              key: const ValueKey('journey-film-note'),
              style: UiText.muted(color: ui.inkMuted).copyWith(height: 1.45),
            ),
          ),
      ],
    );
  }
}

class _Couple extends ConsumerWidget {
  const _Couple({
    required this.journey,
    required this.streak,
    required this.total,
  });

  final Journey journey;
  final int streak;
  final int total;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = JourneysL10n.of(context);
    final ui = context.ui;
    final self = (journey.coupleSelfName?.trim().isNotEmpty ?? false)
        ? journey.coupleSelfName!.trim()
        : l10n.journeys_coupleYou;
    final partner = (journey.couplePartnerName?.trim().isNotEmpty ?? false)
        ? journey.couplePartnerName!.trim()
        : l10n.journeys_ticketPartner;
    final selfOnRight = journey.dna?['side'] == 'right';
    final members =
        ref.watch(groupMembersTodaySafeProvider(journey.id)).value ??
        const <MemberToday>[];
    final shot = members.where((m) => m.checkedIn).length;
    final ritual = switch (journey.dna?['ritual']) {
      'cook' => l10n.journeys_home_ritualCook,
      'save' => l10n.journeys_home_ritualSave,
      'ldr' => l10n.journeys_home_ritualLdr,
      _ => l10n.journeys_home_ritualOther,
    };
    final status = members.length < 2
        ? null
        : shot >= 2
        ? l10n.journeys_home_pairBoth
        : shot == 0
        ? l10n.journeys_home_pairNeither
        : l10n.journeys_home_pairWaiting(
            members
                    .where((m) => !m.checkedIn)
                    .map((m) => m.displayName)
                    .firstOrNull ??
                partner,
          );
    return Column(
      key: const ValueKey('journey-home-couple-header'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.journeys_home_coupleLine(total, ritual),
                style: UiText.h2(
                  color: ui.ink,
                  size: 18,
                ).copyWith(height: 1.35),
              ),
            ),
            const SizedBox(width: 6),
            const OurneyIcon(name: 'flame', size: 20, flat: true),
            const SizedBox(width: 4),
            Text('$streak', style: UiText.h2(color: ui.ink, size: 18)),
          ],
        ),
        const SizedBox(height: UiSpace.md),
        Row(
          key: const ValueKey('journey-couple-pair'),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Person(
              name: selfOnRight ? partner : self,
              id: '${selfOnRight ? 'partner' : 'self'}-${journey.id}',
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: UiSpace.md),
              child: OurneyIcon(name: 'heart', size: 30, active: true),
            ),
            _Person(
              name: selfOnRight ? self : partner,
              id: '${selfOnRight ? 'self' : 'partner'}-${journey.id}',
            ),
          ],
        ),
        if (status != null)
          Padding(
            padding: const EdgeInsets.only(top: UiSpace.sm),
            child: Text(
              status,
              key: const ValueKey('journey-couple-status'),
              textAlign: TextAlign.center,
              style: UiText.muted(color: ui.inkMuted).copyWith(height: 1.4),
            ),
          ),
      ],
    );
  }
}

class _Person extends StatelessWidget {
  const _Person({required this.name, required this.id});

  final String name;
  final String id;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return Flexible(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          UiAvatar(
            name: name.isEmpty ? '?' : name,
            colorIndex: UiAvatar.indexFor(id),
            size: 52,
          ),
          const SizedBox(height: 4),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: UiText.eyebrow(color: ui.ink).copyWith(height: 1.4),
          ),
        ],
      ),
    );
  }
}

/// Today's group attendance, shown once above the workout stats.
class JourneyWorkoutMembers extends ConsumerWidget {
  const JourneyWorkoutMembers({required this.journey, super.key});

  final Journey journey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(groupMembersTodaySafeProvider(journey.id)).value ??
        const <MemberToday>[];
    if (journey.kind != JourneyKind.group || members.length <= 1) {
      return const SizedBox.shrink();
    }
    final done = members.where((m) => m.checkedIn).length;
    final l10n = JourneysL10n.of(context);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: _pill(context, Text(
        isRunJourney(journey)
            ? l10n.journeys_home_flexRan(done, members.length)
            : l10n.journeys_home_flexTrained(done, members.length),
        style: UiText.eyebrow(color: context.ui.inkMuted),
      ), key: const ValueKey('journey-workout-members')),
    );
  }
}

class _Month extends ConsumerWidget {
  const _Month({required this.journeyId});

  final String journeyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = JourneysL10n.of(context);
    final ui = context.ui;
    final members =
        ref.watch(groupMembersTodaySafeProvider(journeyId)).value ??
        const <MemberToday>[];
    final done = members.where((m) => m.checkedIn).length;
    return Column(
      key: const ValueKey('journey-home-minimal-header'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (members.length > 1)
          _pill(
            context,
            Text(
              l10n.journeys_home_minimalDone(done, members.length),
              style: UiText.eyebrow(color: ui.ink),
            ),
          ),
      ],
    );
  }
}
