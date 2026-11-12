import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../ui/ui.dart';
import '../data/journeys_providers.dart';
import '../domain/journey_progress.dart';
import '../l10n/generated/journeys_localizations.dart';
import 'journey_actions.dart';
import 'journey_style.dart';

/// Opens the **Today sheet** (V1.0 `TodaySheet`): what is still waiting for
/// today's photo, streaks about to break first. Picking a journey opens the
/// camera for it.
Future<void> showTodaySheet(BuildContext context) => showUiSheet<void>(
  context: context,
  builder: (context) => const TodaySheetContent(),
);

class TodaySheetContent extends ConsumerWidget {
  const TodaySheetContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = JourneysL10n.of(context);
    final ui = context.ui;
    final journeys = ref.watch(journeysListProvider).value ?? const [];
    final active = JourneyBuckets(journeys).active;
    final now = ref.watch(journeysNowProvider);
    final progress = <JourneyProgress>[
      for (final j in active)
        if (ref.watch(myCheckInsProvider(j.id)).value case final c?)
          JourneyProgress.compute(
            journey: j,
            membership: ref.watch(myMembershipProvider(j.id)).value,
            checkIns: c,
            now: now,
          ),
    ];
    final pending = [
      for (final p in progress)
        if (!p.checkedInToday) p,
    ];
    final atRisk = [
      for (final p in pending)
        if (p.summary.current > 0) p,
    ];
    final rest = [
      for (final p in pending)
        if (p.summary.current == 0) p,
    ];
    final doneCount = progress.length - pending.length;
    final allDone = progress.isNotEmpty && pending.isEmpty;

    void open(String id) {
      Navigator.of(context).pop();
      unawaited(checkInNow(context, ref, id));
    }

    return Column(
      key: const ValueKey('today-sheet'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (allDone) ...[
          const Center(child: UiCheckBadge(size: 64)),
          const SizedBox(height: UiSpace.md),
          Semantics(
            header: true,
            child: Text(
              l10n.journeys_allDoneTitle,
              textAlign: TextAlign.center,
              style: UiText.h2(color: ui.ink),
            ),
          ),
          Text(
            l10n.journeys_doneOf(doneCount, progress.length),
            textAlign: TextAlign.center,
            style: UiText.muted(color: ui.inkMuted),
          ),
          const SizedBox(height: UiSpace.lg),
          for (final p in progress)
            _TodayRow(
              progress: p,
              trailing: UiTag(label: l10n.journeys_addMore, bordered: true),
              onPressed: () => open(p.journey.id),
            ),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UiEyebrow(l10n.journeys_todayLeft(pending.length)),
                    Semantics(
                      header: true,
                      child: Text(
                        l10n.journeys_todayLabel,
                        style: UiText.h1(color: ui.ink),
                      ),
                    ),
                  ],
                ),
              ),
              UiProgressRing(
                value: progress.isEmpty ? 0 : doneCount / progress.length,
                label: '$doneCount/${progress.length}',
                size: 64,
              ),
            ],
          ),
          const SizedBox(height: UiSpace.lg),
          UiButton.secondary(
            label: l10n.journeys_openJourneys,
            icon: Icons.chevron_right_rounded,
            onPressed: () {
              Navigator.of(context).pop();
              context.go(AppRoutes.journeys);
            },
          ),
          if (atRisk.isNotEmpty)
            _Group(
              title: l10n.journeys_todayAtRisk,
              children: [
                for (final p in atRisk)
                  _TodayRow(
                    progress: p,
                    warn: true,
                    onPressed: () => open(p.journey.id),
                  ),
              ],
            ),
          if (rest.isNotEmpty)
            _Group(
              title: l10n.journeys_todayRest,
              children: [
                for (final p in rest)
                  _TodayRow(progress: p, onPressed: () => open(p.journey.id)),
              ],
            ),
        ],
      ],
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: UiSpace.xl),
        UiEyebrow(title),
        const SizedBox(height: 6),
        ...children,
      ],
    );
  }
}

class _TodayRow extends StatelessWidget {
  const _TodayRow({
    required this.progress,
    required this.onPressed,
    this.warn = false,
    this.trailing,
  });

  final JourneyProgress progress;
  final VoidCallback onPressed;
  final bool warn;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = JourneysL10n.of(context);
    final ui = context.ui;
    final journey = progress.journey;
    final style = styleOfJourney(journey);
    return UiRow(
      key: ValueKey('today-row-${journey.id}'),
      title: journey.title,
      minHeight: 64,
      onPressed: onPressed,
      showChevron: trailing == null,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: style.accent,
          borderRadius: BorderRadius.circular(UiRadius.thumb),
        ),
        child: Icon(
          uiJourneyIcon(journey.emoji, journey.templateId),
          size: 20,
          color: style.onAccent,
        ),
      ),
      subtitle: Text(
        style.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: UiText.body(size: 11, color: ui.inkMuted),
      ),
      trailing:
          trailing ??
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                warn
                    ? Icons.schedule_rounded
                    : Icons.local_fire_department_rounded,
                size: 15,
                color: warn ? ui.warn : ui.flame,
              ),
              const SizedBox(width: 3),
              Text(
                '${progress.summary.current}',
                semanticsLabel:
                    '${progress.summary.current} ${l10n.journeys_streakDaysLabel}',
                style: UiText.body(
                  size: 13,
                  weight: FontWeight.w700,
                  height: 1.3,
                  color: ui.ink,
                ),
              ),
            ],
          ),
    );
  }
}
