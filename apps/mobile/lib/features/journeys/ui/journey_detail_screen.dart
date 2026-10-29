import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/app_routes.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/persona_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../data/group_daily_checkins_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../personas/active_journey_sync.dart';
import '../../../personas/persona_contract.dart';
import '../../../personas/persona_switchers.dart';
import '../../../shared/empty_state.dart';
import '../../../shared/ourney_primary_button.dart';
import '../../../shared/placeholder_screen.dart';
import '../../reminders/data/reminder_scheduler.dart';
import '../../sharing/sharing.dart';
import '../data/journeys_providers.dart';
import '../domain/journey_progress.dart';
import '../domain/journey_time.dart';
import '../journeys_paths.dart';
import '../l10n/generated/journeys_localizations.dart';
import 'day_ticker.dart';
import 'journey_errors.dart';

enum _Action { card, end, archive, delete }

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
            now: ref.watch(journeysNowProvider),
          )
        : null;

    final actions = [
      if (!ref.watch(appConfigProvider).localOnly) _Action.card,
      if (perms.canEnd) _Action.end,
      if (perms.canArchive) _Action.archive,
      if (perms.canDelete) _Action.delete,
    ];

    final brightness = Theme.of(context).brightness;
    final style = OurneyPersonaTheme.forSkin(
      personaSkinOf(journey),
      brightness,
    );
    final c = OurneyColors.of(context);
    // V1.0: the journey screen sits on its style's paper; dark mode keeps
    // the shell's near-black so photos stay the brightest thing.
    final paper = brightness == Brightness.dark ? c.bg : style.background;
    final rule = brightness == Brightness.dark
        ? c.divider
        : style.ink.withValues(alpha: 0.14);

    return DayTicker(
      child: ActiveJourneySync(
        journeyId: journey.id,
        child: Scaffold(
          key: const ValueKey('journey-detail'),
          backgroundColor: paper,
          appBar: AppBar(
            backgroundColor: paper,
            toolbarHeight: 64,
            centerTitle: true,
            title: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  journey.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                _PrivacyTag(visibility: journey.visibility),
              ],
            ),
            actions: [
              IconButton(
                key: const ValueKey('journey-share'),
                tooltip: l10n.journeys_share,
                icon: const Icon(Icons.ios_share_rounded),
                onPressed: () => ref.read(appConfigProvider).localOnly
                    ? context.push(AppRoutes.share(journey.id))
                    : showShareJourneySheet(context, journey),
              ),
              if (actions.isNotEmpty)
                PopupMenuButton<_Action>(
                  key: const ValueKey('journey-more'),
                  tooltip: l10n.journeys_moreActions,
                  icon: const Icon(Icons.more_horiz_rounded),
                  onSelected: (a) => _run(context, ref, journey, a),
                  itemBuilder: (context) => [
                    for (final a in actions)
                      PopupMenuItem(
                        key: ValueKey('journey-action-${a.name}'),
                        value: a,
                        child: Text(switch (a) {
                          _Action.card => l10n.journeys_shareCard,
                          _Action.end => l10n.journeys_endJourney,
                          _Action.archive => l10n.journeys_archive,
                          _Action.delete => l10n.journeys_delete,
                        }),
                      ),
                  ],
                )
              else
                const SizedBox(width: OurneySpacing.sm),
            ],
          ),
          floatingActionButton: perms.canCheckIn
              ? OurneyPrimaryButton(
                  key: const ValueKey('journey-checkin'),
                  expand: false,
                  label: progress?.checkedInToday ?? false
                      ? l10n.journeys_addMore
                      : l10n.journeys_checkInNow,
                  icon: Icons.photo_camera_outlined,
                  backgroundColor: style.primaryAccent,
                  onPressed: () => checkInNow(context, ref, journey.id),
                )
              : null,
          body: SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 104),
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: rule)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      OurneySpacing.screenMargin,
                      22,
                      OurneySpacing.screenMargin,
                      8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!perms.isActive) const _ReadOnlyBanner(),
                        Text(
                          _dateRange(context, journey).toUpperCase(),
                          style: eyebrowStyle(color: c.inkMuted),
                        ),
                        const SizedBox(height: 4),
                        Semantics(
                          header: true,
                          child: Text(
                            journey.title,
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                        ),
                        const SizedBox(height: 22),
                        if (progress != null)
                          _Stats(
                            progress: progress,
                            accent: style.primaryAccent,
                            rule: rule,
                          ),
                      ],
                    ),
                  ),
                ),
                if (journey.kind == JourneyKind.group)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      OurneySpacing.screenMargin,
                      OurneySpacing.lg,
                      OurneySpacing.screenMargin,
                      0,
                    ),
                    child: OutlinedButton.icon(
                      key: const ValueKey('journey-open-group'),
                      icon: const Icon(Icons.people_outline_rounded, size: 18),
                      label: Text(l10n.journeys_openGroup),
                      onPressed: () => context.go(AppRoutes.groups),
                    ),
                  ),
                Container(
                  margin: const EdgeInsets.only(top: 18),
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.symmetric(
                      horizontal: BorderSide(color: rule),
                    ),
                  ),
                  child: Semantics(
                    header: true,
                    child: Container(
                      height: 54,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: style.primaryAccent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Text(
                        l10n.journeys_timelineTitle,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    OurneySpacing.screenMargin,
                    OurneySpacing.xl,
                    OurneySpacing.screenMargin,
                    0,
                  ),
                  child: progress == null
                      ? const Padding(
                          padding: EdgeInsets.all(OurneySpacing.xl),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : Builder(
                          builder: (context) {
                            final groupSnap = ref.watch(
                              groupDailySnapshotProvider(journey),
                            );
                            return PersonaTimelineSwitcher(
                              skin: personaSkinOf(journey),
                              data: PersonaTimelineData.fromProgress(
                                progress,
                                hideMetric:
                                    membership?.hideMetric ??
                                    journey.hideMetricDefault,
                                myName: groupSnap.myName,
                                partnerName: groupSnap.partnerName,
                                partnerCheckInsByDate:
                                    groupSnap.partnerCheckInsByDate,
                                onTapDay: (d) => context.push(
                                  JourneysPaths.day(journey.id, d.date),
                                ),
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                              ),
                            );
                          },
                        ),
                ),
                if (membership != null && perms.isActive)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: OurneySpacing.screenMargin,
                    ),
                    child: _PrivacySection(
                      journey: journey,
                      membership: membership,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// "MON 28 SEP — TUE 27 OCT", or "Since MON 28 SEP" when open-ended.
  static String _dateRange(BuildContext context, Journey journey) {
    final l10n = JourneysL10n.of(context);
    final f = DateFormat(
      'EEE d MMM',
      Localizations.localeOf(context).toString(),
    );
    final start = f.format(displayDate(journey.startDate));
    final end = journey.endDate;
    return end == null
        ? l10n.journeys_sinceDate(start)
        : l10n.journeys_dateRange(start, f.format(displayDate(end)));
  }

  /// Opens the camera with this journey preselected: makes it the active
  /// journey (`camera.lastJourneyId`) and passes `?journeyId=`.
  static Future<void> checkInNow(
    BuildContext context,
    WidgetRef ref,
    String journeyId,
  ) async {
    final router = GoRouter.of(context);
    // Through the provider, not prefs: the open camera listens to it.
    await ref.read(activeJourneyIdProvider.notifier).select(journeyId);
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
      case _Action.card:
        unawaited(context.push(AppRoutes.share(journey.id)));
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
          color: c.surfaceSunken,
          border: Border.all(color: c.border),
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

/// FR-B5 (V1.0 hero): "Day N / M" with the percent and a thin progress
/// rule, then a 4-column stat row: current streak, longest, moments and
/// percent complete. Regularity only, no ranking or metric comparison
/// (FR-D5).
class _Stats extends StatelessWidget {
  const _Stats({
    required this.progress,
    required this.accent,
    required this.rule,
  });

  final JourneyProgress progress;
  final Color accent;
  final Color rule;

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
    final label = TextStyle(
      fontFamily: kBodyFont,
      fontSize: 14,
      fontWeight: FontWeight.w700,
      height: 1.35,
      color: c.ink,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          key: const ValueKey('stat-day'),
          container: true,
          label: '${l10n.journeys_statDay}: $dayText',
          excludeSemantics: true,
          child: Row(
            children: [
              Expanded(child: Text(dayText, style: label)),
              if (percent != null)
                Text(
                  l10n.journeys_percent(percent),
                  style: label.copyWith(
                    fontWeight: FontWeight.w500,
                    color: c.inkMuted,
                  ),
                ),
            ],
          ),
        ),
        if (percent != null) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 5,
            child: LinearProgressIndicator(
              value: s.progress,
              minHeight: 5,
              color: accent,
              backgroundColor: rule,
              borderRadius: BorderRadius.zero,
            ),
          ),
        ],
        const SizedBox(height: 25),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StatCell(
                key: const ValueKey('stat-current'),
                label: l10n.journeys_statCurrent,
                shortLabel: l10n.journeys_statCurrentShort,
                semantics: app.streak_semantics(s.current),
                icon: Icons.local_fire_department_rounded,
                value: '${s.current}',
                unit: l10n.journeys_daysUnit,
                rule: rule,
              ),
              _StatCell(
                key: const ValueKey('stat-best'),
                label: l10n.journeys_statBest,
                semantics: app.streak_days(s.best),
                value: '${s.best}',
                rule: rule,
              ),
              _StatCell(
                key: const ValueKey('stat-moments'),
                label: l10n.journeys_statMoments,
                semantics: '${progress.checkInsByDate.length}',
                value: '${progress.checkInsByDate.length}',
                rule: percent == null ? null : rule,
              ),
              if (percent != null)
                _StatCell(
                  key: const ValueKey('stat-percent'),
                  label: l10n.journeys_statComplete,
                  semantics: l10n.journeys_percent(percent),
                  value: l10n.journeys_percent(percent),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One column of the stat row: tiny uppercase label, big Bricolage value,
/// hairline on the right (except the last one).
class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.semantics,
    required this.value,
    this.icon,
    this.unit,
    this.rule,
    this.shortLabel,
    super.key,
  });

  final String label;

  /// Visible label when [label] is too long for a quarter column.
  final String? shortLabel;
  final String semantics;
  final String value;
  final IconData? icon;
  final String? unit;
  final Color? rule;

  @override
  Widget build(BuildContext context) {
    final c = OurneyColors.of(context);
    return Expanded(
      child: Semantics(
        container: true,
        label: '$label: $semantics',
        excludeSemantics: true,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: rule == null
                ? null
                : Border(right: BorderSide(color: rule!)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 11, color: c.flame),
                    const SizedBox(width: 2),
                  ],
                  Flexible(
                    child: Text(
                      (shortLabel ?? label).toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: eyebrowStyle(
                        size: 8,
                        color: c.inkMuted,
                      ).copyWith(letterSpacing: 0.4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text.rich(
                  TextSpan(
                    text: value,
                    children: [
                      if (unit != null)
                        TextSpan(
                          text: ' $unit',
                          style: TextStyle(
                            fontFamily: kBodyFont,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: c.inkMuted,
                          ),
                        ),
                    ],
                  ),
                  style: displayStyle(size: 22, weight: 700, color: c.ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Visibility under the title: lock / link / people + word.
class _PrivacyTag extends StatelessWidget {
  const _PrivacyTag({required this.visibility});

  final JourneyVisibility visibility;

  @override
  Widget build(BuildContext context) {
    final l10n = JourneysL10n.of(context);
    final c = OurneyColors.of(context);
    final (IconData icon, String text) = switch (visibility) {
      JourneyVisibility.private => (
        Icons.lock_outline_rounded,
        l10n.journeys_privacyPrivate,
      ),
      JourneyVisibility.link => (Icons.link_rounded, l10n.journeys_privacyLink),
      JourneyVisibility.group => (
        Icons.people_outline_rounded,
        l10n.journeys_privacyGroup,
      ),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: c.inkMuted),
        const SizedBox(width: 3),
        Text(
          text,
          style: TextStyle(
            fontFamily: kBodyFont,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: c.inkMuted,
          ),
        ),
      ],
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
