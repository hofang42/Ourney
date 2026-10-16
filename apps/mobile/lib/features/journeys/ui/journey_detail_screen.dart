import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/app_routes.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/chunky_button.dart';
import '../../../shared/empty_state.dart';
import '../../../shared/ourney_card.dart';
import '../../../shared/placeholder_screen.dart';
import '../../../shared/streak_flame.dart';
import '../../reminders/data/reminder_scheduler.dart';
import '../data/journeys_providers.dart';
import '../domain/journey_progress.dart';
import '../journeys_paths.dart';
import '../l10n/generated/journeys_localizations.dart';
import 'journey_errors.dart';
import 'timeline_grid.dart';

enum _Action { end, archive, delete }

/// What the caller may do with a journey (FR-B6, docs/02 §9.1).
class JourneyPermissions {
  const JourneyPermissions({
    required this.journey,
    required this.membership,
    required this.currentUserId,
  });

  final Journey journey;
  final Membership? membership;
  final String? currentUserId;

  bool get isOwner {
    final m = membership;
    if (m != null) return m.role == MemberRole.owner;
    // Local-only mode has no user id: every (solo) journey is the caller's.
    return currentUserId == null || journey.ownerId == currentUserId;
  }

  bool get isActive => journey.status == JourneyStatus.active;
  bool get canCheckIn => isActive && (membership?.isActive ?? true);
  bool get canEnd => isOwner && isActive;
  bool get canArchive => journey.status == JourneyStatus.ended;

  /// Owner only. For a group the server also requires the owner to be alone
  /// and answers `not_alone` otherwise (mapped to a message).
  bool get canDelete => isOwner;
}

/// `/journey/:id`: stats (FR-B5), calendar timeline (FR-B4), actions (FR-B6).
class JourneyDetailScreen extends ConsumerWidget {
  const JourneyDetailScreen({required this.journeyId, super.key});

  final String journeyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = JourneysL10n.of(context);
    final app = AppLocalizations.of(context);
    final journeyAsync = ref.watch(journeyByIdProvider(journeyId));

    if (journeyAsync.hasError && isNotWired(journeyAsync.error!)) {
      return PlaceholderScreen(id: 'journey', title: l10n.journeys_title);
    }
    final journey = journeyAsync.value;
    if (journey == null) {
      return Scaffold(
        key: const ValueKey('journey-detail-empty'),
        appBar: AppBar(),
        body: SafeArea(
          child: journeyAsync.isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    semanticsLabel: app.common_loading,
                  ),
                )
              : EmptyState(
                  icon: Icons.search_off_rounded,
                  title: journeyAsync.hasError
                      ? journeyErrorMessage(context, journeyAsync.error!)
                      : l10n.journeys_errorNotFound,
                  actionLabel: l10n.journeys_title,
                  onAction: () => context.go(AppRoutes.journeys),
                ),
        ),
      );
    }

    final membership = ref.watch(myMembershipProvider(journeyId)).value;
    final checkIns = ref.watch(myCheckInsProvider(journeyId));
    final perms = JourneyPermissions(
      journey: journey,
      membership: membership,
      currentUserId: ref.watch(currentUserIdProvider),
    );
    final progress = checkIns.hasValue
        ? JourneyProgress.compute(
            journey: journey,
            membership: membership,
            checkIns: checkIns.value!,
            now: ref.watch(journeysClockProvider).now(),
          )
        : null;

    final actions = [
      if (perms.canEnd) _Action.end,
      if (perms.canArchive) _Action.archive,
      if (perms.canDelete) _Action.delete,
    ];

    return Scaffold(
      key: const ValueKey('journey-detail'),
      appBar: AppBar(
        title: Text(
          '${journey.emoji} ${journey.title}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            key: const ValueKey('journey-share'),
            tooltip: l10n.journeys_share,
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: () => context.push(AppRoutes.share(journey.id)),
          ),
          if (actions.isNotEmpty)
            PopupMenuButton<_Action>(
              key: const ValueKey('journey-more'),
              tooltip: l10n.journeys_moreActions,
              onSelected: (a) => _run(context, ref, journey, a),
              itemBuilder: (context) => [
                for (final a in actions)
                  PopupMenuItem(
                    key: ValueKey('journey-action-${a.name}'),
                    value: a,
                    child: Text(switch (a) {
                      _Action.end => l10n.journeys_endJourney,
                      _Action.archive => l10n.journeys_archive,
                      _Action.delete => l10n.journeys_delete,
                    }),
                  ),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            OurneySpacing.screenMargin,
            OurneySpacing.sm,
            OurneySpacing.screenMargin,
            OurneySpacing.xxl,
          ),
          children: [
            if (!perms.isActive) const _ReadOnlyBanner(),
            if (progress != null) _Stats(progress: progress),
            const SizedBox(height: OurneySpacing.lg),
            if (perms.canCheckIn)
              Padding(
                padding: const EdgeInsets.only(bottom: OurneySpacing.md),
                child: ChunkyButton(
                  key: const ValueKey('journey-checkin'),
                  label: l10n.journeys_checkInNow,
                  icon: Icons.photo_camera_rounded,
                  onPressed: () => checkInNow(context, ref, journey.id),
                ),
              ),
            if (journey.kind == JourneyKind.group)
              Padding(
                padding: const EdgeInsets.only(bottom: OurneySpacing.md),
                child: ChunkyButton(
                  key: const ValueKey('journey-open-group'),
                  label: l10n.journeys_openGroup,
                  icon: Icons.groups_rounded,
                  variant: ChunkyVariant.neutral,
                  onPressed: () => context.go(AppRoutes.groups),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(
                top: OurneySpacing.lg,
                bottom: OurneySpacing.md,
              ),
              child: Semantics(
                header: true,
                child: Text(
                  l10n.journeys_timelineTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            if (progress == null)
              const Padding(
                padding: EdgeInsets.all(OurneySpacing.xl),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              TimelineGrid(
                days: progress.timeline(),
                onTapDay: (d) =>
                    context.push(JourneysPaths.day(journey.id, d.date)),
              ),
            if (membership != null && perms.isActive)
              _PrivacySection(journey: journey, membership: membership),
          ],
        ),
      ),
    );
  }

  /// Opens the camera with this journey preselected: writes
  /// `camera.lastJourneyId` and passes `?journeyId=` (see README.md).
  static Future<void> checkInNow(
    BuildContext context,
    WidgetRef ref,
    String journeyId,
  ) async {
    final router = GoRouter.of(context);
    await ref
        .read(sharedPreferencesProvider)
        .setString(lastJourneyPrefsKey, journeyId);
    router.go(JourneysPaths.captureFor(journeyId));
  }

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    Journey journey,
    _Action action,
  ) async {
    final l10n = JourneysL10n.of(context);
    final repo = ref.read(journeyRepositoryProvider);
    final router = GoRouter.of(context);
    // Ended, archived and deleted journeys lose their reminders (FR-G1).
    final reminders = ref.read(reminderSchedulerProvider);
    switch (action) {
      case _Action.end:
        final ok = await confirmJourneyAction(
          context,
          title: l10n.journeys_endConfirmTitle,
          message: l10n.journeys_endConfirmMessage,
          confirmLabel: l10n.journeys_endJourney,
        );
        if (!ok || !context.mounted) return;
        if (await _guard(context, () => repo.end(journey.id))) {
          unawaited(reminders.reschedule());
        }
      case _Action.archive:
        if (await _guard(context, () => repo.archive(journey.id))) {
          unawaited(reminders.reschedule());
          router.go(AppRoutes.journeys);
        }
      case _Action.delete:
        final ok = await confirmJourneyAction(
          context,
          title: l10n.journeys_deleteConfirmTitle,
          message: l10n.journeys_deleteConfirmMessage,
          confirmLabel: l10n.journeys_delete,
          destructive: true,
        );
        if (!ok || !context.mounted) return;
        if (await _guard(context, () => repo.delete(journey.id))) {
          unawaited(reminders.reschedule());
          router.go(AppRoutes.journeys);
        }
    }
  }

  /// Runs [op]; on failure shows the mapped message. True on success.
  Future<bool> _guard(BuildContext context, Future<void> Function() op) async {
    try {
      await op();
      return true;
    } on Object catch (e) {
      if (context.mounted) {
        showJourneySnack(context, journeyErrorMessage(context, e));
      }
      return false;
    }
  }
}

class _ReadOnlyBanner extends StatelessWidget {
  const _ReadOnlyBanner();

  @override
  Widget build(BuildContext context) {
    final c = OurneyColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: OurneySpacing.md),
      child: Container(
        key: const ValueKey('journey-read-only'),
        padding: const EdgeInsets.all(OurneySpacing.md),
        decoration: BoxDecoration(
          color: c.inkMuted.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(OurneyRadii.chip),
        ),
        child: Row(
          children: [
            Icon(Icons.flag_rounded, color: c.ink),
            const SizedBox(width: OurneySpacing.sm),
            Expanded(
              child: Text(
                JourneysL10n.of(context).journeys_readOnlyBanner,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// FR-B5: current streak, longest, % complete, day N/M. Regularity only, no
/// ranking or metric comparison (FR-D5).
class _Stats extends StatelessWidget {
  const _Stats({required this.progress});

  final JourneyProgress progress;

  @override
  Widget build(BuildContext context) {
    final l10n = JourneysL10n.of(context);
    final app = AppLocalizations.of(context);
    final c = OurneyColors.of(context);
    final s = progress.summary;
    final percent = progress.percentComplete;
    final dayText = progress.totalDays == null
        ? l10n.journeys_dayOpen(progress.dayNumber)
        : l10n.journeys_dayOf(progress.dayNumber, progress.totalDays!);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - OurneySpacing.md) / 2;
        return Wrap(
          spacing: OurneySpacing.md,
          runSpacing: OurneySpacing.md,
          children: [
            _StatTile(
              key: const ValueKey('stat-current'),
              width: width,
              label: l10n.journeys_statCurrent,
              semantics: app.streak_semantics(s.current),
              value: StreakFlame(
                days: s.current,
                atRisk: progress.isActive && s.atRisk,
                size: 28,
                semanticLabel: app.streak_semantics(s.current),
              ),
            ),
            _StatTile(
              key: const ValueKey('stat-best'),
              width: width,
              label: l10n.journeys_statBest,
              semantics: app.streak_days(s.best),
              value: _Big(app.streak_days(s.best)),
            ),
            if (percent != null)
              _StatTile(
                key: const ValueKey('stat-percent'),
                width: width,
                label: l10n.journeys_statComplete,
                semantics: l10n.journeys_percent(percent),
                value: _Big(l10n.journeys_percent(percent)),
                footer: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: s.progress,
                    minHeight: 6,
                    color: c.success,
                    backgroundColor: c.inkMuted.withValues(alpha: 0.15),
                  ),
                ),
              ),
            _StatTile(
              key: const ValueKey('stat-day'),
              width: width,
              label: l10n.journeys_statDay,
              semantics: dayText,
              value: _Big(dayText),
            ),
          ],
        );
      },
    );
  }
}

class _Big extends StatelessWidget {
  const _Big(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: displayStyle(size: 22, color: OurneyColors.of(context).ink),
  );
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.width,
    required this.label,
    required this.value,
    required this.semantics,
    this.footer,
    super.key,
  });

  final double width;
  final String label;
  final Widget value;
  final String semantics;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: OurneyCard(
        padding: const EdgeInsets.all(OurneySpacing.md),
        child: Semantics(
          label: '$label: $semantics',
          excludeSemantics: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: OurneySpacing.xs),
              value,
              if (footer != null) ...[
                const SizedBox(height: OurneySpacing.sm),
                footer!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// FR-B7 personal settings: hide my metric, blur my photos on outside
/// shares (`updateMyMembership`).
class _PrivacySection extends ConsumerWidget {
  const _PrivacySection({required this.journey, required this.membership});

  final Journey journey;
  final Membership membership;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = JourneysL10n.of(context);
    final repo = ref.read(journeyRepositoryProvider);

    Future<void> update({bool? hideMetric, bool? blurMedia}) async {
      try {
        await repo.updateMyMembership(
          journey.id,
          hideMetric: hideMetric,
          blurMedia: blurMedia,
        );
      } on Object catch (e) {
        if (context.mounted) {
          showJourneySnack(context, journeyErrorMessage(context, e));
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: OurneySpacing.xl,
            bottom: OurneySpacing.sm,
          ),
          child: Semantics(
            header: true,
            child: Text(
              l10n.journeys_privacyTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        if (journey.metricName != null)
          SwitchListTile(
            key: const ValueKey('journey-pref-hide-metric'),
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.visibility_off_rounded),
            title: Text(l10n.journeys_hideMetric),
            value: membership.hideMetric,
            onChanged: (v) => update(hideMetric: v),
          ),
        SwitchListTile(
          key: const ValueKey('journey-pref-blur'),
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.blur_on_rounded),
          title: Text(l10n.journeys_blurOnShare),
          value: membership.blurMedia,
          onChanged: (v) => update(blurMedia: v),
        ),
      ],
    );
  }
}
