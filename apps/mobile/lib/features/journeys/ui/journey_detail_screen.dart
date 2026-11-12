import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/app_routes.dart';
import '../../../app/providers.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../ui/ui.dart';
import '../../reminders/data/reminder_scheduler.dart';
import '../../sharing/sharing.dart';
import '../data/journeys_providers.dart';
import '../domain/journey_progress.dart';
import '../domain/journey_time.dart';
import '../journeys_paths.dart';
import '../l10n/generated/journeys_localizations.dart';
import 'day_ticker.dart';
import 'journey_actions.dart';
import 'journey_chain.dart';
import 'journey_errors.dart';
import 'journey_row.dart';
import 'journey_style.dart';

enum _Action { end, archive, delete }

/// `/journey/:id`, V1.0 `Detail`: back / title / share / more header, the
/// hero (date range, name, day N / M, progress and four stats), the journey
/// calendar and a check-in button. Stats are regularity only, no ranking or
/// metric comparison (FR-D5).
class JourneyDetailScreen extends ConsumerStatefulWidget {
  const JourneyDetailScreen({required this.journeyId, super.key});

  final String journeyId;

  @override
  ConsumerState<JourneyDetailScreen> createState() =>
      _JourneyDetailScreenState();
}

class _JourneyDetailScreenState extends ConsumerState<JourneyDetailScreen> {
  bool _menuOpen = false;

  String get journeyId => widget.journeyId;

  @override
  Widget build(BuildContext context) {
    final l10n = JourneysL10n.of(context);
    final app = AppLocalizations.of(context);
    final journeyAsync = ref.watch(journeyByIdProvider(journeyId));

    if (journeyAsync.hasError && isNotWired(journeyAsync.error!)) {
      return UiScaffold(
        key: const ValueKey('placeholder-journey'),
        child: UiEmptyState(
          icon: Icons.route_rounded,
          title: l10n.journeys_title,
        ),
      );
    }
    final journey = journeyAsync.value;
    if (journey == null) {
      return UiScaffold(
        key: const ValueKey('journey-detail-empty'),
        padTop: 0,
        child: Column(
          children: [
            UiBackHeader(onBack: _back, backLabel: l10n.journeys_back),
            if (journeyAsync.isLoading)
              Padding(
                padding: const EdgeInsets.only(top: 120),
                child: Center(
                  child: CircularProgressIndicator(
                    semanticsLabel: app.common_loading,
                  ),
                ),
              )
            else
              UiEmptyState(
                icon: Icons.search_off_rounded,
                title: journeyAsync.hasError
                    ? journeyErrorMessage(context, journeyAsync.error!)
                    : l10n.journeys_errorNotFound,
                actionLabel: l10n.journeys_title,
                onAction: () => context.go(AppRoutes.journeys),
              ),
          ],
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
      if (perms.canEnd) _Action.end,
      if (perms.canArchive) _Action.archive,
      if (perms.canDelete) _Action.delete,
    ];

    final ui = context.ui;
    final pal = JourneyPalette.of(context, styleOfJourney(journey));
    final gutter = UiSpace.gutter(MediaQuery.sizeOf(context).width);

    return DayTicker(
      child: ActiveJourneyScope(
        journeyId: journey.id,
        child: UiScaffold(
          key: const ValueKey('journey-detail'),
          background: pal.paper,
          padTop: 0,
          padBottom: 24,
          bottom: perms.canCheckIn
              ? Padding(
                  padding: EdgeInsets.fromLTRB(gutter, UiSpace.sm, gutter, 20),
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: UiButton(
                      key: const ValueKey('journey-checkin'),
                      label: progress?.checkedInToday ?? false
                          ? l10n.journeys_addMore
                          : l10n.journeys_checkInNow,
                      icon: Icons.photo_camera_outlined,
                      accent: pal.accent,
                      onAccent: pal.onAccent,
                      expand: false,
                      onPressed: () => checkInNow(context, ref, journey.id),
                    ),
                  ),
                )
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(
                journey: journey,
                canMore: actions.isNotEmpty,
                onBack: _back,
                onShare: () => _share(context, journey),
                onMore: () => setState(() => _menuOpen = !_menuOpen),
              ),
              if (_menuOpen && actions.isNotEmpty)
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: UiMenuSurface(
                    children: [
                      for (final a in actions)
                        UiMenuItem(
                          key: ValueKey('journey-action-${a.name}'),
                          icon: switch (a) {
                            _Action.end => Icons.flag_outlined,
                            _Action.archive => Icons.inventory_2_outlined,
                            _Action.delete => Icons.delete_outline_rounded,
                          },
                          destructive: a == _Action.delete,
                          label: switch (a) {
                            _Action.end => l10n.journeys_endJourney,
                            _Action.archive => l10n.journeys_archive,
                            _Action.delete => l10n.journeys_delete,
                          },
                          onPressed: () {
                            setState(() => _menuOpen = false);
                            unawaited(_run(context, journey, a));
                          },
                        ),
                    ],
                  ),
                ),
              Divider(height: 1, color: ui.border),
              const SizedBox(height: 22),
              if (!perms.isActive) const _ReadOnlyBanner(),
              UiEyebrow(_dateRange(context, journey).toUpperCase()),
              const SizedBox(height: 4),
              Semantics(
                header: true,
                child: Text(journey.title, style: UiText.h1(color: ui.ink)),
              ),
              const SizedBox(height: 22),
              if (progress != null) _Stats(progress: progress, pal: pal),
              if (journey.kind == JourneyKind.group) ...[
                const SizedBox(height: UiSpace.lg),
                UiButton.secondary(
                  key: const ValueKey('journey-open-group'),
                  icon: Icons.people_outline_rounded,
                  label: l10n.journeys_openGroup,
                  onPressed: () => context.go(AppRoutes.groups),
                ),
              ],
              const SizedBox(height: 18),
              _SectionTab(
                title: l10n.journeys_timelineTitle,
                accent: pal.accent,
              ),
              const SizedBox(height: UiSpace.xl),
              if (progress == null)
                const Padding(
                  padding: EdgeInsets.all(UiSpace.xl),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                JourneyChain(
                  days: progress.timeline(),
                  pal: pal,
                  onTapDay: (d) =>
                      context.push(JourneysPaths.day(journey.id, d.date)),
                ),
              if (membership != null && perms.isActive)
                _PrivacySection(journey: journey, membership: membership),
            ],
          ),
        ),
      ),
    );
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.journeys);
    }
  }

  /// Local-only builds go straight to the share card; with a server the
  /// sheet offers the card or sharing the journey with friends.
  Future<void> _share(BuildContext context, Journey journey) async {
    if (ref.read(appConfigProvider).localOnly) {
      await context.push(AppRoutes.share(journey.id));
      return;
    }
    final l10n = JourneysL10n.of(context);
    final choice = await showUiSheet<bool>(
      context: context,
      builder: (context) => Column(
        key: const ValueKey('journey-share-sheet'),
        children: [
          _ShareOption(
            key: const ValueKey('journey-share-card'),
            icon: Icons.image_outlined,
            title: l10n.journeys_shareMakeCard,
            hint: l10n.journeys_shareMakeCardHint,
            onPressed: () => Navigator.of(context).pop(true),
          ),
          _ShareOption(
            key: const ValueKey('journey-share-friends'),
            icon: Icons.ios_share_rounded,
            title: l10n.journeys_shareJourney,
            hint: l10n.journeys_shareJourneyHint,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
    if (choice == null || !context.mounted) return;
    if (choice) {
      unawaited(context.push(AppRoutes.share(journey.id)));
    } else {
      await showShareJourneySheet(context, journey);
    }
  }

  /// "MON 28 SEP - TUE 27 OCT", or "Since MON 28 SEP" when open-ended.
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

  Future<void> _run(
    BuildContext context,
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

/// `.detail-nav`: back, centered name + privacy, share, more.
class _Header extends StatelessWidget {
  const _Header({
    required this.journey,
    required this.canMore,
    required this.onBack,
    required this.onShare,
    required this.onMore,
  });

  final Journey journey;
  final bool canMore;
  final VoidCallback onBack;
  final VoidCallback onShare;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final l10n = JourneysL10n.of(context);
    final ui = context.ui;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Row(
        children: [
          UiIconButton(
            icon: Icons.arrow_back_rounded,
            label: l10n.journeys_back,
            onPressed: onBack,
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  journey.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: UiText.body(
                    size: 14,
                    weight: FontWeight.w700,
                    height: 1.4,
                    color: ui.ink,
                  ),
                ),
                JourneyPrivacy(journey: journey),
              ],
            ),
          ),
          UiIconButton(
            key: const ValueKey('journey-share'),
            icon: Icons.ios_share_rounded,
            label: l10n.journeys_share,
            onPressed: onShare,
          ),
          if (canMore)
            UiIconButton(
              key: const ValueKey('journey-more'),
              icon: Icons.more_horiz_rounded,
              label: l10n.journeys_moreActions,
              onPressed: onMore,
            )
          else
            const SizedBox(width: UiSpace.sm),
        ],
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  const _ShareOption({
    required this.icon,
    required this.title,
    required this.hint,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String title;
  final String hint;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return UiRow(
      title: title,
      minHeight: 70,
      leading: Icon(icon, size: 22, color: ui.ink),
      subtitle: Text(
        hint,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: UiText.body(size: 11, color: ui.inkMuted),
      ),
      onPressed: onPressed,
    );
  }
}

class _ReadOnlyBanner extends StatelessWidget {
  const _ReadOnlyBanner();

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return Padding(
      padding: const EdgeInsets.only(bottom: UiSpace.md),
      child: UiCard(
        key: const ValueKey('journey-read-only'),
        color: ui.fill,
        padding: const EdgeInsets.all(UiSpace.md),
        child: Row(
          children: [
            Icon(Icons.flag_rounded, color: ui.ink),
            const SizedBox(width: UiSpace.sm),
            Expanded(
              child: Text(
                JourneysL10n.of(context).journeys_readOnlyBanner,
                style: UiText.body(size: 14, height: 1.45, color: ui.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `.detail-tabs` (one tab): the section title between two hairlines with
/// the accent underline.
class _SectionTab extends StatelessWidget {
  const _SectionTab({required this.title, required this.accent});

  final String title;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return Container(
      height: 54,
      decoration: BoxDecoration(
        border: Border.symmetric(horizontal: BorderSide(color: ui.border)),
      ),
      alignment: AlignmentDirectional.centerStart,
      child: Semantics(
        header: true,
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: accent, width: 3)),
          ),
          child: Text(
            title,
            style: UiText.body(
              size: 14,
              weight: FontWeight.w600,
              height: 1.3,
              color: ui.ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// FR-B5 (V1.0 hero): "Day N / M" with the percent and a thin progress bar,
/// then a 4-column stat row: current streak, longest, moments and percent
/// complete.
class _Stats extends StatelessWidget {
  const _Stats({required this.progress, required this.pal});

  final JourneyProgress progress;
  final JourneyPalette pal;

  @override
  Widget build(BuildContext context) {
    final l10n = JourneysL10n.of(context);
    final app = AppLocalizations.of(context);
    final ui = context.ui;
    final s = progress.summary;
    final percent = progress.percentComplete;
    final dayText = journeyDayOf(l10n, progress);
    final label = UiText.body(
      size: 14,
      weight: FontWeight.w700,
      height: 1.35,
      color: ui.ink,
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
                    color: ui.inkMuted,
                  ),
                ),
            ],
          ),
        ),
        if (percent != null) ...[
          const SizedBox(height: 8),
          UiProgressBar(value: s.progress, color: pal.accent),
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
                divider: true,
              ),
              _StatCell(
                key: const ValueKey('stat-best'),
                label: l10n.journeys_statBest,
                semantics: app.streak_days(s.best),
                value: '${s.best}',
                divider: true,
              ),
              _StatCell(
                key: const ValueKey('stat-moments'),
                label: l10n.journeys_statMoments,
                semantics: '${progress.checkInsByDate.length}',
                value: '${progress.checkInsByDate.length}',
                divider: percent != null,
              ),
              if (percent != null)
                _StatCell(
                  key: const ValueKey('stat-percent'),
                  label: l10n.journeys_statComplete,
                  semantics: l10n.journeys_percent(percent),
                  value: l10n.journeys_percent(percent),
                  divider: false,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One column of the stat row (`.stat-grid > div`): tiny label, big display
/// value, hairline on the right (except the last one).
class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.semantics,
    required this.value,
    required this.divider,
    this.icon,
    this.unit,
    this.shortLabel,
    super.key,
  });

  final String label;

  /// Visible label when [label] is too long for a quarter column.
  final String? shortLabel;
  final String semantics;
  final String value;
  final bool divider;
  final IconData? icon;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return Expanded(
      child: Semantics(
        container: true,
        label: '$label: $semantics',
        excludeSemantics: true,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: divider
                ? Border(right: BorderSide(color: ui.border))
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 11, color: ui.flame),
                    const SizedBox(width: 2),
                  ],
                  Flexible(
                    child: Text(
                      (shortLabel ?? label).toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: UiText.body(
                        size: 9,
                        weight: FontWeight.w700,
                        height: 1.3,
                        tracking: 0.05,
                        color: ui.inkMuted,
                      ),
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
                          style: UiText.body(
                            size: 10,
                            weight: FontWeight.w500,
                            color: ui.inkMuted,
                          ),
                        ),
                    ],
                  ),
                  style: UiText.display(size: 22, color: ui.ink),
                ),
              ),
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
        const SizedBox(height: UiSpace.xl),
        UiListHeading(title: l10n.journeys_privacyTitle),
        const SizedBox(height: UiSpace.xs),
        if (journey.metricName != null)
          UiSwitchRow(
            key: const ValueKey('journey-pref-hide-metric'),
            label: l10n.journeys_hideMetric,
            value: membership.hideMetric,
            onChanged: (v) => update(hideMetric: v),
          ),
        UiSwitchRow(
          key: const ValueKey('journey-pref-blur'),
          label: l10n.journeys_blurOnShare,
          value: membership.blurMedia,
          divider: false,
          onChanged: (v) => update(blurMedia: v),
        ),
      ],
    );
  }
}
