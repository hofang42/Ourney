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
import '../data/create_progress.dart';
import '../data/journeys_providers.dart';
import '../domain/journey_progress.dart';
import '../l10n/generated/journeys_localizations.dart';
import 'day_ticker.dart';
import 'home/journey_home_intro.dart' show journeyHomeOfflineProvider;
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

  /// No cap on running journeys (SRS FR-B3, owner decision 2026-11-12).
  static Future<void> startCreate(BuildContext context) =>
      context.push(AppRoutes.journeyNew);

  @override
  ConsumerState<JourneysListScreen> createState() => _JourneysListState();
}

class _JourneysListState extends ConsumerState<JourneysListScreen> {
  /// Null until the user picks a segment (then the hub may default to the
  /// shelf when nothing runs).
  HubSegment? _segment;
  bool _menuOpen = false;

  @override
  Widget build(BuildContext context) {
    final l10n = JourneysL10n.of(context);
    final journeys = ref.watch(journeysListProvider);
    // A remembered segment pick goes stale when Active flips between empty
    // and non-empty, or when another account signs in.
    ref.listen<AsyncValue<List<Journey>>>(journeysListProvider, (prev, next) {
      final was = prev?.value?.any((j) => j.status == JourneyStatus.active);
      final now = next.value?.any((j) => j.status == JourneyStatus.active);
      if (was != null && now != null && was != now && _segment != null) {
        setState(() => _segment = null);
      }
    });
    ref.listen<String?>(currentUserIdProvider, (_, _) {
      if (_segment != null) setState(() => _segment = null);
    });

    if (journeys.hasError && isNotWired(journeys.error!)) {
      // Data layer (B1) not wired yet.
      return UiScaffold(
        key: const ValueKey('placeholder-journeys'),
        child: UiStateCard(
          kind: UiStateCardKind.empty,
          title: l10n.journeys_title,
        ),
      );
    }

    final buckets = journeys.hasValue ? JourneyBuckets(journeys.value!) : null;
    // Only archived journeys left: the hub still opens (on the shelf) so they
    // can be restored; Day Zero is for a Hub with nothing at all.
    final archivedAsync = ref.watch(archivedJourneysProvider);
    final archivedValue = archivedAsync.value;
    final hasArchived = archivedValue?.isNotEmpty ?? false;

    final Widget body;
    if (buckets != null &&
        buckets.isEmpty &&
        archivedValue == null &&
        !archivedAsync.hasError) {
      // Archived list not known yet: not Day Zero for an archive-only user.
      body = const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [_HubHeader(), _HubNotices(), _HubSkeleton()],
      );
    } else if (buckets != null && buckets.isEmpty && archivedAsync.hasError) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _HubHeader(),
          const _HubNotices(),
          UiStateCard(
            key: const ValueKey('journeys-error'),
            kind: UiStateCardKind.error,
            title: l10n.journeys_hubErrorTitle,
            actionLabel: AppLocalizations.of(context).common_retry,
            onAction: () => ref.invalidate(archivedJourneysProvider),
          ),
        ],
      );
    } else if (buckets != null && buckets.isEmpty && !hasArchived) {
      body = _DayZero(onStart: () => JourneysListScreen.startCreate(context));
    } else if (buckets != null) {
      body = _HubBody(
        buckets: buckets,
        segment:
            _segment ??
            (buckets.active.isEmpty &&
                    (buckets.finished.isNotEmpty || hasArchived)
                ? HubSegment.shelf
                : HubSegment.active),
        onSegment: (s) => setState(() => _segment = s),
        menuOpen: _menuOpen,
        onMenu: () => setState(() => _menuOpen = !_menuOpen),
        onCloseMenu: () => setState(() => _menuOpen = false),
      );
    } else if (journeys.hasError) {
      final offline =
          rootError(journeys.error!) is OurneyException &&
          (rootError(journeys.error!) as OurneyException).error ==
              OurneyErrorCode.offline;
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _HubHeader(),
          const _HubNotices(),
          UiStateCard(
            key: const ValueKey('journeys-error'),
            kind: offline ? UiStateCardKind.offline : UiStateCardKind.error,
            title: l10n.journeys_hubErrorTitle,
            actionLabel: AppLocalizations.of(context).common_retry,
            onAction: () => ref.invalidate(journeysListProvider),
          ),
        ],
      );
    } else {
      body = const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [_HubHeader(), _HubNotices(), _HubSkeleton()],
      );
    }

    return DayTicker(
      child: UiScaffold(
        key: const ValueKey('journeys-list'),
        padBottom: UiSpace.xxl,
        child: body,
      ),
    );
  }
}

/// Figma Hub header: the "hành trình." title, an add button and the
/// "chào {name}." greeting underneath. Profile and activity are dock tabs.
class _HubHeader extends ConsumerWidget {
  const _HubHeader({
    this.onAdd,
    this.menu,
    this.menuOpen = false,
    this.onCloseMenu,
  });

  /// Null hides the add button (the empty hub offers its own start button).
  final VoidCallback? onAdd;

  /// Add menu floated under the add button while [menuOpen].
  final Widget? menu;
  final bool menuOpen;
  final VoidCallback? onCloseMenu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = JourneysL10n.of(context);
    final ui = context.ui;
    final name = ref.watch(myProfileProvider).value?.displayName.trim();
    final first = name == null || name.isEmpty
        ? null
        : name.split(RegExp(r'\s+')).last;
    final bar = UiTopBar(
      title: l10n.journeys_hubTitle,
      actions: [
        if (onAdd != null)
          UiIconButton(
            key: const ValueKey('journeys-new'),
            glyph: const OurneyIcon(name: 'plus', size: 24),
            label: l10n.journeys_addJourney,
            onPressed: onAdd,
          ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (menu case final menu?)
          UiMenuAnchor(
            open: menuOpen,
            onClose: onCloseMenu ?? () {},
            anchor: bar,
            menu: menu,
          )
        else
          bar,
        Padding(
          padding: const EdgeInsets.only(top: UiSpace.md),
          child: Semantics(
            header: true,
            child: Text(
              first == null
                  ? l10n.journeys_hubGreetingNoName
                  : l10n.journeys_hubGreeting(first),
              key: const ValueKey('hub-greeting'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: UiText.h1(color: ui.ink, size: 28).copyWith(height: 1.3),
            ),
          ),
        ),
      ],
    );
  }
}

/// Offline banner ("đang lưu trên máy, có mạng sẽ tự gửi") and the resume
/// card of an unfinished create flow, shared by every Hub state.
class _HubNotices extends ConsumerWidget {
  const _HubNotices();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = JourneysL10n.of(context);
    final ui = context.ui;
    final offline = ref.watch(journeyHomeOfflineProvider).value ?? false;
    final resume = ref.watch(createProgressProvider);
    if (!offline && resume == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: UiSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (offline)
            UiBanner(
              key: const ValueKey('hub-offline-banner'),
              message: l10n.journeys_hubOffline,
            ),
          if (offline && resume != null) const SizedBox(height: UiSpace.sm),
          if (resume != null)
            UiCard(
              key: const ValueKey('hub-create-progress'),
              onPressed: () => context.push(AppRoutes.journeyNewResume),
              semanticLabel:
                  '${l10n.journeys_hubResumeTitle}, ${l10n.journeys_hubResumeStep(resume)}',
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.journeys_hubResumeTitle,
                          style: UiText.body(
                            size: 15,
                            weight: FontWeight.w800,
                            height: 1.35,
                            color: ui.ink,
                          ),
                        ),
                        Text(
                          l10n.journeys_hubResumeStep(resume),
                          style: UiText.muted(
                            color: ui.inkMuted,
                            size: 13,
                          ).copyWith(height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const OurneyIcon(name: 'chevron-right', size: 20, flat: true),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Figma `HubSkeleton`: hero block and three card placeholders.
class _HubSkeleton extends StatelessWidget {
  const _HubSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: UiSpace.lg),
      child: Semantics(
        label: JourneysL10n.of(context).journeys_hubLoading,
        child: Column(
          key: const ValueKey('journeys-loading'),
          children: [
            const UiSkeleton(height: 132, radius: UiRadius.card),
            for (var i = 0; i < 3; i++) ...[
              const SizedBox(height: UiSpace.md),
              const Row(
                children: [
                  UiSkeleton(width: 64, height: 64, circle: true),
                  SizedBox(width: UiSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        UiSkeleton(height: 18),
                        SizedBox(height: 8),
                        UiSkeleton(width: 120, height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Figma empty Hub state: camera sticker, "chưa có hành trình nào.", a
/// one-line promise and the start button.
class _DayZero extends StatelessWidget {
  const _DayZero({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = JourneysL10n.of(context);
    final ui = context.ui;
    return Column(
      key: const ValueKey('journeys-empty'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _HubHeader(),
        const _HubNotices(),
        const SizedBox(height: UiSpace.xxl),
        Center(
          child: Container(
            width: 88,
            height: 88,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: UiTypePastel.weightLoss,
              shape: BoxShape.circle,
              border: Border.all(color: ui.ink, width: 2),
            ),
            child: const OurneyIcon(name: 'camera', size: 40, active: true),
          ),
        ),
        const SizedBox(height: UiSpace.lg),
        Semantics(
          header: true,
          child: Text(
            l10n.journeys_hubEmptyTitle,
            textAlign: TextAlign.center,
            style: UiText.h2(color: ui.ink).copyWith(height: 1.3),
          ),
        ),
        const SizedBox(height: UiSpace.sm),
        Text(
          l10n.journeys_hubEmptyBody,
          textAlign: TextAlign.center,
          style: UiText.body(size: 16, height: 1.5, color: ui.inkMuted),
        ),
        const SizedBox(height: UiSpace.xl),
        UiButton(
          key: const ValueKey('journeys-start-first'),
          label: l10n.journeys_dayZeroStart,
          onPressed: onStart,
        ),
      ],
    );
  }
}

/// Streak lengths that swap the hero's flame for the trophy.
const _milestones = {7, 14, 21, 30, 50, 100, 200, 365};

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
    final bestStreak = progress.values.fold<int>(
      0,
      (m, p) => p.summary.current > m ? p.summary.current : m,
    );
    final heroState = allDone && _milestones.contains(bestStreak)
        ? UiStreakHeroState.milestone
        : allDone
        ? UiStreakHeroState.done
        : next?.journey.visibility == JourneyVisibility.group
        ? UiStreakHeroState.group
        : UiStreakHeroState.normal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HubHeader(
          onAdd: onMenu,
          menuOpen: menuOpen,
          onCloseMenu: onCloseMenu,
          menu: UiMenuSurface(
            width: 260,
            children: [
              UiMenuItem(
                key: const ValueKey('journeys-menu-new'),
                glyph: 'plus',
                label: l10n.journeys_newJourney,
                onPressed: () {
                  onCloseMenu();
                  JourneysListScreen.startCreate(context);
                },
              ),
              if (online)
                UiMenuItem(
                  key: const ValueKey('journeys-menu-retell'),
                  glyph: 'sparkle',
                  label: l10n.journeys_retell,
                  onPressed: () {
                    onCloseMenu();
                    context.push(AppRoutes.retell);
                  },
                ),
            ],
          ),
        ),
        const _HubNotices(),
        const SizedBox(height: UiSpace.sm),
        UiStreakHero(
          key: const ValueKey('journeys-hub-hero'),
          streak: bestStreak,
          title: allDone
              ? l10n.journeys_allDonePrompt
              : l10n.journeys_remainingToday(pending.length),
          state: heroState,
        ),
        const SizedBox(height: UiSpace.lg),
        if (next != null)
          TodayCard(progress: next)
        else if (allDone)
          _AllDoneRow(count: buckets.active.length),
        const SizedBox(height: UiSpace.xl),
        Row(
          key: const ValueKey('hub-section-heading'),
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  l10n.journeys_hubSection,
                  style: UiText.h2(color: ui.ink, size: 20),
                ),
              ),
            ),
            const OurneyIcon(name: 'journeys', size: 17, flat: true),
            const SizedBox(width: 4),
            Text(
              l10n.journeys_hubRunning(buckets.activeCount),
              style: UiText.eyebrow(color: ui.inkMuted),
            ),
          ],
        ),
        const SizedBox(height: UiSpace.sm),
        UiSegmented<HubSegment>(
          scrollable: true,
          value: segment,
          onChanged: onSegment,
          segments: [
            UiSegment(
              key: const ValueKey('hub-segment-active'),
              value: HubSegment.active,
              label: '${l10n.journeys_activeSection} · ${buckets.activeCount}',
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
                : Column(
                    children: [
                      for (final j in buckets.active) JourneyRow(journey: j),
                      _NewJourneyCard(
                        onTap: () => JourneysListScreen.startCreate(context),
                      ),
                    ],
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
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ui.successSoft,
              shape: BoxShape.circle,
            ),
            child: const OurneyIcon(name: 'check', size: 20),
          ),
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

/// `.new-journey-card`: "hành trình mới." at the end of the list.
class _NewJourneyCard extends StatelessWidget {
  const _NewJourneyCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = JourneysL10n.of(context);
    final ui = context.ui;
    return UiCard(
      key: const ValueKey('journeys-new-card'),
      onPressed: onTap,
      semanticLabel:
          '${l10n.journeys_hubNewTitle}, ${l10n.journeys_hubNewHint}',
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: UiTypePastel.english,
              shape: BoxShape.circle,
              border: Border.all(color: ui.ink, width: 2),
            ),
            child: const OurneyIcon(name: 'send', size: 32, active: true),
          ),
          const SizedBox(width: UiSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.journeys_hubNewTitle,
                  style: UiText.h2(color: ui.ink, size: 18),
                ),
                Text(
                  l10n.journeys_hubNewHint,
                  style: UiText.muted(
                    color: ui.inkMuted,
                    size: 13,
                  ).copyWith(height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
