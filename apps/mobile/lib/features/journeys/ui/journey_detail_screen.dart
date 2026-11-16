import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/app_routes.dart';
import '../../../app/overlays/missed_day_overlay.dart';
import '../../../app/providers.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../ui/ui.dart';
import '../../groups/ui/invite_sheet.dart';
import '../../reminders/data/reminder_scheduler.dart';
import '../../sharing/sharing.dart';
import '../data/journeys_providers.dart';
import '../domain/journey_progress.dart';
import '../domain/journey_time.dart';
import '../domain/wrapped_story.dart';
import '../journeys_paths.dart';
import '../l10n/generated/journeys_localizations.dart';
import 'couple_rename_sheet.dart';
import 'day_ticker.dart';
import 'home/journey_home_header.dart';
import 'home/journey_home_intro.dart';
import 'home/journey_home_sections.dart';
import 'journey_actions.dart';
import 'journey_errors.dart';
import 'journey_row.dart';
import 'journey_style.dart';
import 'widgets/journey_timeline.dart';

enum _Action { edit, wrapped, pin, invite, renameCouple, end, archive, delete }

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
          glyph: const OurneyIcon(name: 'journeys', size: 40),
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
                glyph: const OurneyIcon(name: 'search', size: 40),
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
      if (perms.isOwner && perms.isActive) _Action.edit,
      if (!perms.isActive) _Action.wrapped,
      if (membership?.isActive ?? false) _Action.pin,
      if (perms.isActive &&
          journey.kind == JourneyKind.group &&
          (membership?.isActive ?? false) &&
          !ref.watch(appConfigProvider).localOnly)
        _Action.invite,
      if (perms.canEnd && journey.coupleSelfName != null) _Action.renameCouple,
      if (perms.canEnd) _Action.end,
      if (perms.canArchive) _Action.archive,
      if (perms.canDelete) _Action.delete,
    ];

    final gutter = UiSpace.gutter(MediaQuery.sizeOf(context).width);

    return UiSkinScope(
      skinId: uiSkinIdFor(skinOfJourney(journey)),
      variant: journey.color ?? 0,
      // Read tokens from inside the scope so the skin applies.
      child: Builder(
        builder: (context) {
          final ui = context.ui;
          final pal = JourneyPalette.of(context, styleOfJourney(journey));
          final skin = uiSkinIdFor(skinOfJourney(journey));
          final missedDay = progress
              ?.timeline()
              .where((d) => d.state == DayState.missed)
              .map((d) => d.dayNumber)
              .fold<int?>(null, (a, b) => a == null || b > a ? b : a);
          final home = DayTicker(
            child: ActiveJourneyScope(
              journeyId: journey.id,
              child: UiScaffold(
                key: const ValueKey('journey-detail'),
                background: pal.paper,
                padTop: 0,
                padBottom: 24,
                bottom: perms.canCheckIn
                    ? Padding(
                        padding: EdgeInsets.fromLTRB(
                          gutter,
                          UiSpace.sm,
                          gutter,
                          20,
                        ),
                        child: Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: UiButton(
                            key: const ValueKey('journey-checkin'),
                            label: progress?.checkedInToday ?? false
                                ? l10n.journeys_addMore
                                : l10n.journeys_checkInNow,
                            glyph: const OurneyIcon(
                              name: 'camera',
                              size: 20,
                              flat: true,
                            ),
                            accent: pal.accent,
                            onAccent: pal.onAccent,
                            expand: false,
                            onPressed: () =>
                                checkInNow(context, ref, journey.id),
                          ),
                        ),
                      )
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    UiMenuAnchor(
                      open: _menuOpen && actions.isNotEmpty,
                      onClose: () => setState(() => _menuOpen = false),
                      anchor: _Header(
                        journey: journey,
                        canMore: actions.isNotEmpty,
                        onBack: _back,
                        onShare: () => _share(context, journey),
                        onMore: () => setState(() => _menuOpen = !_menuOpen),
                      ),
                      menu: UiMenuSurface(
                          children: [
                            for (final a in actions)
                              UiMenuItem(
                                key: ValueKey('journey-action-${a.name}'),
                                glyph: switch (a) {
                                  _Action.edit => 'pencil',
                                  _Action.wrapped => 'trophy',
                                  _Action.pin => 'star',
                                  _Action.invite => 'squad',
                                  _Action.renameCouple => 'edit',
                                  _Action.end => 'flag',
                                  _Action.archive => 'inbox',
                                  _Action.delete => 'trash',
                                },
                                destructive: a == _Action.delete,
                                label: switch (a) {
                                  _Action.edit => l10n.journeys_edit_menu,
                                  _Action.wrapped => l10n.journeys_wrapped_menu,
                                  _Action.pin =>
                                    (membership?.pinned ?? false)
                                        ? l10n.journeys_unpin
                                        : l10n.journeys_pin,
                                  _Action.invite => l10n.journeys_inviteAction,
                                  _Action.renameCouple =>
                                    l10n.journeys_renameCouple,
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
                    if (progress != null)
                      JourneyHomeIntro(
                        skin: uiSkinIdFor(skinOfJourney(journey)),
                        day: progress.dayNumber,
                        total: journey.durationDays,
                        streak: progress.summary.current,
                        now: ref.watch(journeysNowProvider),
                        offline:
                            ref.watch(journeyHomeOfflineProvider).value ??
                            false,
                        readOnly: !perms.isActive,
                      ),
                    if (progress != null) const SizedBox(height: UiSpace.lg),
                    UiEyebrow(_dateRange(context, journey).toUpperCase()),
                    const SizedBox(height: 4),
                    Semantics(
                      header: true,
                      child: Text(
                        journey.title,
                        style: UiText.h1(color: ui.ink),
                      ),
                    ),
                    const SizedBox(height: 22),
                    if (progress != null) ...[
                      if (skin != 'quiet') ...[
                        JourneyHomeSkinHeader(
                          journey: journey,
                          skin: skinOfJourney(journey),
                          day: progress.dayNumber,
                          streak: progress.summary.current,
                          stats: WrappedStats.from(progress),
                          now: ref.watch(journeysNowProvider),
                          onTrophy: () => context.push(
                            perms.isActive
                                ? AppRoutes.share(journey.id)
                                : JourneysPaths.wrapped(journey.id),
                          ),
                        ),
                        const SizedBox(height: UiSpace.lg),
                      ],
                      if (skin == 'quiet' || skin == 'flexer') ...[
                        JourneyHomeChart(
                          skin: skin,
                          values: _metricSeries(progress),
                          accent: pal.accent,
                          unit: journey.metricUnit ?? '',
                          maskable: skin == 'quiet',
                        ),
                        const SizedBox(height: UiSpace.lg),
                      ],
                    ],
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
                      JourneyTimeline(
                        skinId: uiSkinIdFor(skinOfJourney(journey)),
                        days: progress.timeline(),
                        pal: pal,
                        selfName: journey.coupleSelfName,
                        partnerName: journey.couplePartnerName,
                        showOfflineStamps: !ref
                            .watch(appConfigProvider)
                            .localOnly,
                        onTapDay: (d) =>
                            context.push(JourneysPaths.day(journey.id, d.date)),
                      ),
                    if (progress != null) ...[
                      const SizedBox(height: UiSpace.xl),
                      JourneyHomeMilestones(
                        day: progress.dayNumber,
                        total: journey.durationDays,
                        accent: pal.accent,
                        onAccent: pal.onAccent,
                      ),
                    ],
                    const SizedBox(height: UiSpace.xl),
                    JourneyHomeActions(
                      onWrapped: perms.isActive
                          ? null
                          : () =>
                                context.push(JourneysPaths.wrapped(journey.id)),
                      onShare: () => _share(context, journey),
                      onSquad: journey.kind == JourneyKind.group
                          ? () => context.go(AppRoutes.groups)
                          : null,
                    ),
                    const SizedBox(height: UiSpace.lg),
                    if (membership != null && perms.isActive)
                      _PrivacySection(journey: journey, membership: membership),
                  ],
                ),
              ),
            ),
          );
          return Stack(
            children: [
              home,
              if (missedDay != null && (skin == 'quiet' || skin == 'squad'))
                PositionedDirectional(
                  end: 18,
                  bottom: 118,
                  child: MissedDayOverlay(skinId: skin, day: missedDay),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Metric values of the journey, oldest first.
  List<double> _metricSeries(JourneyProgress p) {
    final days = p.checkInsByDate.keys.toList()..sort((a, b) => a.compareTo(b));
    return [for (final d in days) ?p.checkInsByDate[d]!.metricValue];
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
            icon: 'image',
            title: l10n.journeys_shareMakeCard,
            hint: l10n.journeys_shareMakeCardHint,
            onPressed: () => Navigator.of(context).pop(true),
          ),
          _ShareOption(
            key: const ValueKey('journey-share-friends'),
            icon: 'share',
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
      case _Action.edit:
        unawaited(router.push(JourneysPaths.edit(journey.id)));
      case _Action.wrapped:
        unawaited(router.push(JourneysPaths.wrapped(journey.id)));
      case _Action.pin:
        final pinned =
            ref.read(myMembershipProvider(journey.id)).value?.pinned ?? false;
        await _guard(
          context,
          () => repo.updateMyMembership(journey.id, pinned: !pinned),
        );
      case _Action.invite:
        await showGroupInviteSheet(context, journey.id);
      case _Action.renameCouple:
        await showCoupleRenameSheet(context, journey);
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
          // Ending a journey opens its finish story (Figma wrapped).
          if (context.mounted) router.go(JourneysPaths.wrapped(journey.id));
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
            glyph: const OurneyIcon(name: 'back', size: 21, flat: true),
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
            glyph: const OurneyIcon(name: 'share', size: 21, flat: true),
            label: l10n.journeys_share,
            onPressed: onShare,
          ),
          if (canMore)
            UiIconButton(
              key: const ValueKey('journey-more'),
              glyph: const OurneyIcon(name: 'more', size: 21, flat: true),
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

  final String icon;
  final String title;
  final String hint;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return UiRow(
      title: title,
      minHeight: 70,
      leading: OurneyIcon(name: icon, size: 22, flat: true, color: ui.ink),
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

    Future<void> update({
      bool? hideMetric,
      bool? blurMedia,
      bool? hideExtras,
    }) async {
      try {
        await repo.updateMyMembership(
          journey.id,
          hideMetric: hideMetric,
          blurMedia: blurMedia,
          hideExtras: hideExtras,
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
        if (journey.kind != JourneyKind.solo)
          UiSwitchRow(
            key: const ValueKey('journey-pref-hide-extras'),
            label: l10n.journeys_hideExtras,
            value: membership.hideExtras,
            onChanged: (v) => update(hideExtras: v),
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
