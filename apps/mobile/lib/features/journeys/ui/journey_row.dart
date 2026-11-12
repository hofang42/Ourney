import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/app_routes.dart';
import '../../../app/providers.dart';
import '../../../ui/ui.dart';
import '../data/journeys_providers.dart';
import '../domain/journey_progress.dart';
import '../l10n/generated/journeys_localizations.dart';
import 'journey_actions.dart';
import 'journey_photo.dart';
import 'journey_style.dart';

/// Privacy glyph + word of a journey (V1.0 `Privacy`).
class JourneyPrivacy extends StatelessWidget {
  const JourneyPrivacy({required this.journey, this.color, super.key});

  final Journey journey;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final l10n = JourneysL10n.of(context);
    final (type, label) = switch (journey.visibility) {
      JourneyVisibility.private => (
        UiPrivacy.private,
        l10n.journeys_privacyPrivate,
      ),
      JourneyVisibility.link => (UiPrivacy.link, l10n.journeys_privacyLink),
      JourneyVisibility.group => (
        skinOfJourney(journey) == PersonaSkinId.coupleRituals
            ? UiPrivacy.couple
            : UiPrivacy.squad,
        l10n.journeys_privacyGroup,
      ),
    };
    return UiPrivacyTag(type: type, label: label, color: color);
  }
}

/// One journey row on the hub (V1.0 `.journey-row`): 66dp thumbnail (latest
/// photo, or the journey icon on its style paper), title, style dot + name,
/// then streak, today status (icon + word, not color only) and visibility.
class JourneyRow extends ConsumerWidget {
  const JourneyRow({required this.journey, this.hideStreak = false, super.key});

  final Journey journey;

  /// The Today card already shows this journey's streak.
  final bool hideStreak;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = JourneysL10n.of(context);
    final ui = context.ui;
    final membership = ref.watch(myMembershipProvider(journey.id));
    final checkIns = ref.watch(myCheckInsProvider(journey.id));
    final progress = checkIns.hasValue
        ? JourneyProgress.compute(
            journey: journey,
            membership: membership.value,
            checkIns: checkIns.value!,
            now: ref.watch(journeysNowProvider),
          )
        : null;
    final active = journey.status == JourneyStatus.active;
    final style = styleOfJourney(journey);
    final pal = JourneyPalette.of(context, style);
    final latest = progress == null ? null : latestCheckIn(progress);

    final dayText = progress == null ? null : journeyDayOf(l10n, progress);
    final done = active && (progress?.checkedInToday ?? false);
    final statusText = switch (journey.status) {
      JourneyStatus.active =>
        progress == null
            ? null
            : (done ? l10n.journeys_rowDone : l10n.journeys_rowNotYet),
      JourneyStatus.ended => l10n.journeys_statusEnded,
      JourneyStatus.archived => l10n.journeys_statusArchived,
    };

    final meta = UiText.body(
      size: 11,
      weight: FontWeight.w500,
      height: 1.35,
      color: ui.inkMuted,
    );

    return UiRow(
      key: ValueKey('journey-card-${journey.id}'),
      title: journey.title,
      minHeight: 94,
      leading: ClipRRect(
        key: ValueKey('journey-badge-${journey.id}'),
        borderRadius: BorderRadius.circular(UiRadius.thumb),
        child: SizedBox.square(
          dimension: 66,
          child: latest != null
              ? JourneyPhoto(checkIn: latest, cacheWidth: 200)
              : ColoredBox(
                  color: pal.paper,
                  child: Icon(
                    uiJourneyIcon(journey.emoji, journey.templateId),
                    size: 28,
                    color: pal.ink,
                  ),
                ),
        ),
      ),
      subtitle: UiStyleLabel(
        dot: style.accent,
        label: [
          style.name,
          ?dayText,
          if (journey.origin == JourneyOrigin.imported) l10n.journeys_imported,
        ].join(' · '),
      ),
      meta: Wrap(
        spacing: 10,
        runSpacing: 2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (progress != null && active && !hideStreak)
            _Meta(
              icon: Icons.local_fire_department_rounded,
              iconColor: ui.flame,
              text: '${progress.summary.current}',
              style: meta,
            ),
          if (statusText != null)
            _Meta(
              key: ValueKey('journey-status-${journey.id}'),
              icon: !active
                  ? Icons.flag_outlined
                  : done
                  ? Icons.check_rounded
                  : Icons.circle_outlined,
              iconColor: done ? ui.success : ui.inkMuted,
              text: statusText,
              style: done ? meta.copyWith(color: ui.success) : meta,
            ),
          JourneyPrivacy(journey: journey),
        ],
      ),
      onPressed: () {
        if (active) {
          unawaited(
            ref.read(activeJourneyIdProvider.notifier).select(journey.id),
          );
        }
        context.push(AppRoutes.journey(journey.id));
      },
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({
    required this.icon,
    required this.iconColor,
    required this.text,
    required this.style,
    super.key,
  });

  final IconData icon;
  final Color iconColor;
  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: iconColor),
        const SizedBox(width: 3),
        Text(text, style: style),
      ],
    );
  }
}
