import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/app_routes.dart';
import '../../../app/theme/tokens.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/chunky_button.dart';
import '../../../shared/empty_state.dart';
import '../../../shared/ourney_card.dart';
import '../../../shared/placeholder_screen.dart';
import '../../../shared/profile_button.dart';
import '../../../shared/streak_flame.dart';
import '../data/journeys_providers.dart';
import '../domain/journey_progress.dart';
import '../l10n/generated/journeys_localizations.dart';
import 'journey_errors.dart';

/// Journeys tab (`/journeys`): running journeys, then finished ones, and the
/// "new journey" FAB guarded by the 3-active-journeys rule (FR-B3).
class JourneysListScreen extends ConsumerWidget {
  const JourneysListScreen({super.key});

  static Future<void> startCreate(BuildContext context, JourneyBuckets b) {
    if (!b.canCreate) return showJourneyLimitDialog(context);
    return context.push(AppRoutes.journeyNew);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = JourneysL10n.of(context);
    final journeys = ref.watch(journeysListProvider);

    if (journeys.hasError && isNotWired(journeys.error!)) {
      // Data layer (B1) not wired yet.
      return PlaceholderScreen(id: 'journeys', title: l10n.journeys_title);
    }

    final buckets = journeys.hasValue ? JourneyBuckets(journeys.value!) : null;

    final Widget body;
    if (buckets != null) {
      body = buckets.isEmpty
          ? EmptyState(
              key: const ValueKey('journeys-empty'),
              icon: Icons.route_rounded,
              title: l10n.journeys_emptyTitle,
              message: l10n.journeys_emptyMessage,
              actionLabel: l10n.journeys_newJourney,
              onAction: () => startCreate(context, buckets),
            )
          : _JourneyList(buckets: buckets);
    } else if (journeys.hasError) {
      body = EmptyState(
        key: const ValueKey('journeys-error'),
        icon: Icons.error_outline_rounded,
        title: l10n.journeys_loadError,
        message: journeyErrorMessage(context, journeys.error!),
        actionLabel: AppLocalizations.of(context).common_retry,
        onAction: () => ref.invalidate(journeysListProvider),
      );
    } else {
      body = Center(
        child: CircularProgressIndicator(
          semanticsLabel: AppLocalizations.of(context).common_loading,
        ),
      );
    }

    return Scaffold(
      key: const ValueKey('journeys-list'),
      appBar: AppBar(
        title: Text(l10n.journeys_title),
        actions: const [ProfileButton()],
      ),
      body: SafeArea(child: body),
      floatingActionButton: buckets == null || buckets.isEmpty
          ? null
          : FloatingActionButton.extended(
              key: const ValueKey('journeys-new'),
              onPressed: () => startCreate(context, buckets),
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.journeys_newJourney),
            ),
    );
  }
}

class _JourneyList extends StatelessWidget {
  const _JourneyList({required this.buckets});

  final JourneyBuckets buckets;

  @override
  Widget build(BuildContext context) {
    final l10n = JourneysL10n.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        OurneySpacing.screenMargin,
        OurneySpacing.lg,
        OurneySpacing.screenMargin,
        96,
      ),
      children: [
        if (buckets.active.isNotEmpty) ...[
          _SectionHeader(
            '${l10n.journeys_activeSection} · '
            '${buckets.activeCount}/$maxActiveJourneys',
          ),
          for (final j in buckets.active) JourneyCard(journey: j),
        ],
        if (buckets.active.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: OurneySpacing.lg),
            child: ChunkyButton(
              label: l10n.journeys_newJourney,
              icon: Icons.add_rounded,
              onPressed: () => JourneysListScreen.startCreate(context, buckets),
            ),
          ),
        if (buckets.finished.isNotEmpty) ...[
          _SectionHeader(l10n.journeys_finishedSection),
          for (final j in buckets.finished) JourneyCard(journey: j),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: OurneySpacing.sm,
        bottom: OurneySpacing.md,
      ),
      child: Semantics(
        header: true,
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}

/// One journey on the Journeys tab: emoji, title, day N/M, streak flame and
/// whether today is done (icon + text, not color only).
class JourneyCard extends ConsumerWidget {
  const JourneyCard({required this.journey, super.key});

  final Journey journey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = JourneysL10n.of(context);
    final app = AppLocalizations.of(context);
    final c = OurneyColors.of(context);
    final text = Theme.of(context).textTheme;
    final membership = ref.watch(myMembershipProvider(journey.id));
    final checkIns = ref.watch(myCheckInsProvider(journey.id));
    final progress = checkIns.hasValue
        ? JourneyProgress.compute(
            journey: journey,
            membership: membership.value,
            checkIns: checkIns.value!,
            now: ref.watch(journeysClockProvider).now(),
          )
        : null;
    final active = journey.status == JourneyStatus.active;

    final dayText = progress == null
        ? null
        : (progress.totalDays == null
              ? l10n.journeys_dayOpen(progress.dayNumber)
              : l10n.journeys_dayOf(progress.dayNumber, progress.totalDays!));
    final statusText = switch (journey.status) {
      JourneyStatus.active =>
        progress == null
            ? null
            : (progress.checkedInToday
                  ? l10n.journeys_checkedToday
                  : l10n.journeys_notCheckedToday),
      JourneyStatus.ended => l10n.journeys_statusEnded,
      JourneyStatus.archived => l10n.journeys_statusArchived,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: OurneySpacing.md),
      child: OurneyCard(
        key: ValueKey('journey-card-${journey.id}'),
        onTap: () => context.push(AppRoutes.journey(journey.id)),
        child: Row(
          children: [
            ExcludeSemantics(
              child: Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color:
                      (journey.kind == JourneyKind.group ? c.accent : c.primary)
                          .withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(OurneyRadii.chip),
                ),
                child: Text(
                  journey.emoji,
                  textScaler: TextScaler.noScaling,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(width: OurneySpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    journey.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleMedium,
                  ),
                  const SizedBox(height: OurneySpacing.xs),
                  Wrap(
                    spacing: OurneySpacing.sm,
                    runSpacing: OurneySpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (dayText != null) Text(dayText, style: text.bodySmall),
                      if (journey.kind == JourneyKind.group)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.groups_rounded,
                              size: 16,
                              color: c.inkMuted,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              l10n.journeys_kindGroup,
                              style: text.bodySmall,
                            ),
                          ],
                        ),
                    ],
                  ),
                  if (statusText != null) ...[
                    const SizedBox(height: OurneySpacing.xs),
                    Row(
                      key: ValueKey('journey-status-${journey.id}'),
                      children: [
                        Icon(
                          !active
                              ? Icons.flag_rounded
                              : (progress!.checkedInToday
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked_rounded),
                          size: 18,
                          color: active && progress!.checkedInToday
                              ? c.success
                              : c.inkMuted,
                        ),
                        const SizedBox(width: OurneySpacing.xs),
                        Flexible(
                          child: Text(
                            statusText,
                            style: text.bodySmall?.copyWith(color: c.ink),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (progress != null) ...[
              const SizedBox(width: OurneySpacing.sm),
              StreakFlame(
                days: progress.summary.current,
                atRisk: active && progress.summary.atRisk,
                size: 26,
                semanticLabel: app.streak_semantics(progress.summary.current),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
