import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/app_routes.dart';
import '../../../app/providers.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../ui/ui.dart';
import '../../profile/profile_providers.dart';
import '../../sharing/sharing.dart';
import '../../social/social.dart';
import '../data/journeys_providers.dart';
import '../domain/journey_progress.dart';
import '../l10n/generated/journeys_localizations.dart';
import 'day_ticker.dart';
import 'journey_errors.dart';
import 'journey_row.dart';
import 'shelf_view.dart';
import 'today_card.dart';

/// Hub segment: running journeys, the shelf (ended + archived) or journeys
/// others shared with me.
enum HubSegment { active, shelf, shared }

/// **Global Hub** (`/journeys`, Ourney V1.0 `Hub`):
///
/// * greeting + add menu + inbox + profile,
/// * "N journeys still need today's photo",
/// * the **Today card** for the next journey without a photo today, drawn in
///   that journey's style, or an "All done" row once everything is posted,
/// * "Your journeys" with Active / Shelf / Shared segments.
///
/// Without journeys it is the **day-zero hub** (`DayZeroHub`).
class JourneysListScreen extends ConsumerStatefulWidget {
  const JourneysListScreen({super.key});

  static Future<void> startCreate(BuildContext context, JourneyBuckets b) {
    if (!b.canCreate) return showJourneyLimitDialog(context);
    return context.push(AppRoutes.journeyNew);
  }

  @override
  ConsumerState<JourneysListScreen> createState() => _JourneysListState();
}

class _JourneysListState extends ConsumerState<JourneysListScreen> {
  HubSegment _segment = HubSegment.active;
  bool _menuOpen = false;

  @override
  Widget build(BuildContext context) {
    final l10n = JourneysL10n.of(context);
    final journeys = ref.watch(journeysListProvider);

    if (journeys.hasError && isNotWired(journeys.error!)) {
      // Data layer (B1) not wired yet.
      return UiScaffold(
        key: const ValueKey('placeholder-journeys'),
        child: UiEmptyState(
          icon: Icons.route_rounded,
          title: l10n.journeys_title,
        ),
      );
    }

    final buckets = journeys.hasValue ? JourneyBuckets(journeys.value!) : null;

    final Widget body;
    if (buckets != null && buckets.isEmpty) {
      body = _DayZero(
        onStart: () => JourneysListScreen.startCreate(context, buckets),
      );
    } else if (buckets != null) {
      body = _HubBody(
        buckets: buckets,
        segment: _segment,
        onSegment: (s) => setState(() => _segment = s),
        menuOpen: _menuOpen,
        onMenu: () => setState(() => _menuOpen = !_menuOpen),
        onCloseMenu: () => setState(() => _menuOpen = false),
      );
    } else if (journeys.hasError) {
      body = Column(
        children: [
          const _HubHeader(),
          UiEmptyState(
            key: const ValueKey('journeys-error'),
            icon: Icons.error_outline_rounded,
            title: l10n.journeys_loadError,
            body: journeyErrorMessage(context, journeys.error!),
            actionLabel: AppLocalizations.of(context).common_retry,
            onAction: () => ref.invalidate(journeysListProvider),
          ),
        ],
      );
    } else {
      body = Column(
        children: [
          const _HubHeader(),
          const SizedBox(height: 80),
          Center(
            child: CircularProgressIndicator(
              semanticsLabel: AppLocalizations.of(context).common_loading,
            ),
          ),
        ],
      );
    }

    return DayTicker(
      child: UiScaffold(
        key: const ValueKey('journeys-list'),
        padBottom: 120,
        child: body,
      ),
    );
  }
}

/// Greeting row: "Good evening, Linh" + add + inbox + profile avatar.
class _HubHeader extends ConsumerWidget {
  const _HubHeader({this.onAdd, this.hello = false});

  /// Null hides the add button (the empty hub offers its own start button).
  final VoidCallback? onAdd;

  /// Day-zero greeting ("Hi, Linh") instead of the time-of-day one.
  final bool hello;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = JourneysL10n.of(context);
    final now = ref.watch(journeysNowProvider);
    final name = ref.watch(myProfileProvider).value?.displayName.trim();
    final first = name == null || name.isEmpty
        ? null
        : name.split(RegExp(r'\s+')).last;
    final greeting = now.hour < 12
        ? l10n.journeys_greetingMorning
        : now.hour < 18
        ? l10n.journeys_greetingAfternoon
        : l10n.journeys_greetingEvening;
    final title = first == null
        ? (hello ? l10n.journeys_title : greeting)
        : (hello
              ? l10n.journeys_greetingHi(first)
              : l10n.journeys_greetingNamed(greeting, first));
    return UiTopBar(
      title: title,
      actions: [
        if (onAdd != null)
          UiIconButton(
            key: const ValueKey('journeys-new'),
            icon: Icons.add_rounded,
            label: l10n.journeys_addJourney,
            onPressed: onAdd,
          ),
        const InboxButton(),
        _ProfileEntry(name: name),
      ],
    );
  }
}

/// Avatar button to `/profile` (settings, reminders, safety).
class _ProfileEntry extends StatelessWidget {
  const _ProfileEntry({required this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final label = AppLocalizations.of(context).nav_profile;
    final hasName = name != null && name!.isNotEmpty;
    return UiPressable(
      key: const ValueKey('profile-entry'),
      onPressed: () => context.push(AppRoutes.profile),
      semanticLabel: label,
      excludeChildSemantics: true,
      child: Center(
        child: hasName
            ? UiAvatar(
                name: name!,
                size: UiSize.avatarLarge,
                colorIndex: UiAvatar.indexFor(name!),
              )
            : Container(
                width: UiSize.avatarLarge,
                height: UiSize.avatarLarge,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ui.fill,
                  border: Border.all(color: ui.border),
                ),
                child: Icon(
                  Icons.person_outline_rounded,
                  size: 22,
                  color: ui.ink,
                ),
              ),
      ),
    );
  }
}

/// `DayZeroHub`: nothing to track yet, one clear way to start.
class _DayZero extends StatelessWidget {
  const _DayZero({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = JourneysL10n.of(context);
    final ui = context.ui;
    final height = MediaQuery.sizeOf(context).height;
    return Column(
      key: const ValueKey('journeys-empty'),
      children: [
        const _HubHeader(hello: true),
        SizedBox(height: height * 0.18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            l10n.journeys_dayZeroBody,
            textAlign: TextAlign.center,
            style: UiText.body(size: 17, height: 1.6, color: ui.ink),
          ),
        ),
        const SizedBox(height: UiSpace.xxl),
        UiButton(
          key: const ValueKey('journeys-start-first'),
          label: l10n.journeys_dayZeroStart,
          expand: false,
          onPressed: onStart,
        ),
      ],
    );
  }
}

/// Progress of every running journey, watched together so the hub can
/// count what is left for today and pick the Today card.
class _HubBody extends ConsumerWidget {
  const _HubBody({
    required this.buckets,
    required this.segment,
    required this.onSegment,
    required this.menuOpen,
    required this.onMenu,
    required this.onCloseMenu,
  });

  final JourneyBuckets buckets;
  final HubSegment segment;
  final ValueChanged<HubSegment> onSegment;
  final bool menuOpen;
  final VoidCallback onMenu;
  final VoidCallback onCloseMenu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = JourneysL10n.of(context);
    final ui = context.ui;
    final now = ref.watch(journeysNowProvider);
    final progress = <String, JourneyProgress>{};
    for (final j in buckets.active) {
      final checkIns = ref.watch(myCheckInsProvider(j.id));
      if (!checkIns.hasValue) continue;
      progress[j.id] = JourneyProgress.compute(
        journey: j,
        membership: ref.watch(myMembershipProvider(j.id)).value,
        checkIns: checkIns.value!,
        now: now,
      );
    }
    final pending = [
      for (final j in buckets.active)
        if (progress[j.id] case final p? when !p.checkedInToday) p,
    ];
    final known = progress.length == buckets.active.length;
    final activeId =
        ref.watch(activeJourneyProvider).value?.id ??
        ref.watch(activeJourneyIdProvider);
    final next = pending.isEmpty
        ? null
        : pending.firstWhere(
            (p) => p.journey.id == activeId,
            orElse: () => pending.first,
          );
    final allDone = known && buckets.active.isNotEmpty && pending.isEmpty;
    final online = !ref.watch(appConfigProvider).localOnly;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HubHeader(onAdd: onMenu),
        if (menuOpen)
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: UiMenuSurface(
              width: 260,
              children: [
                UiMenuItem(
                  key: const ValueKey('journeys-menu-new'),
                  icon: Icons.add_rounded,
                  label: l10n.journeys_newJourney,
                  onPressed: () {
                    onCloseMenu();
                    JourneysListScreen.startCreate(context, buckets);
                  },
                ),
                if (online)
                  UiMenuItem(
                    key: const ValueKey('journeys-menu-retell'),
                    icon: Icons.image_outlined,
                    label: l10n.journeys_retell,
                    onPressed: () {
                      onCloseMenu();
                      context.push(AppRoutes.retell);
                    },
                  ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 18),
          child: Text(
            key: const ValueKey('journeys-hub-prompt'),
            allDone
                ? l10n.journeys_allDonePrompt
                : l10n.journeys_remainingToday(pending.length),
            style: UiText.muted(size: 14, color: ui.inkMuted),
          ),
        ),
        if (next != null)
          TodayCard(progress: next)
        else if (allDone)
          _AllDoneRow(count: buckets.active.length),
        const SizedBox(height: UiSpace.xl),
        UiListHeading(title: l10n.journeys_yourJourneys),
        const SizedBox(height: UiSpace.sm),
        UiSegmented<HubSegment>(
          scrollable: true,
          value: segment,
          onChanged: onSegment,
          segments: [
            UiSegment(
              key: const ValueKey('hub-segment-active'),
              value: HubSegment.active,
              label:
                  '${l10n.journeys_activeSection} · '
                  '${buckets.activeCount}/$maxActiveJourneys',
            ),
            UiSegment(
              key: const ValueKey('hub-segment-shelf'),
              value: HubSegment.shelf,
              label: l10n.journeys_finishedSection,
            ),
            if (online)
              UiSegment(
                key: const ValueKey('hub-segment-shared'),
                value: HubSegment.shared,
                label: l10n.journeys_sharedSection,
              ),
          ],
        ),
        const SizedBox(height: UiSpace.md),
        switch (segment) {
          HubSegment.shared => const SharedWithMeList(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
          ),
          HubSegment.shelf => ShelfView(
            journeys: buckets.finished,
            online: online,
          ),
          HubSegment.active =>
            buckets.active.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      l10n.journeys_activeEmpty,
                      textAlign: TextAlign.center,
                      style: UiText.muted(color: ui.inkMuted),
                    ),
                  )
                : DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: ui.divider)),
                    ),
                    child: Column(
                      children: [
                        for (final j in buckets.active)
                          JourneyRow(
                            journey: j,
                            hideStreak: next?.journey.id == j.id,
                          ),
                      ],
                    ),
                  ),
        },
      ],
    );
  }
}

/// `.hub-all-done`: every running journey has today's photo.
class _AllDoneRow extends StatelessWidget {
  const _AllDoneRow({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return UiCard(
      key: const ValueKey('journeys-all-done'),
      padding: const EdgeInsets.symmetric(
        horizontal: UiSpace.lg,
        vertical: UiSpace.md,
      ),
      child: Row(
        children: [
          const UiCheckBadge(),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              JourneysL10n.of(context).journeys_allDoneTitle,
              style: UiText.body(
                size: 14,
                weight: FontWeight.w700,
                height: 1.35,
                color: ui.ink,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count/$count',
            style: UiText.body(
              size: 12,
              weight: FontWeight.w700,
              height: 1.3,
              color: ui.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}
