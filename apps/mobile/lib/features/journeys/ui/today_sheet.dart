import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/journey_style_name.dart';
import '../../../ui/ui.dart';
import '../data/journeys_providers.dart';
import '../domain/journey_progress.dart';
import '../l10n/generated/journeys_localizations.dart';
import 'journey_actions.dart';
import 'journey_errors.dart';
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
    final app = AppLocalizations.of(context);
    final ui = context.ui;
    final journeysAsync = ref.watch(journeysListProvider);
    final journeys = journeysAsync.value ?? const [];
    final active = JourneyBuckets(journeys).active;
    final now = ref.watch(journeysNowProvider);
    var anyLoading = journeysAsync.isLoading && !journeysAsync.hasValue;
    Object? firstError = journeysAsync.hasValue ? null : journeysAsync.error;
    final progress = <JourneyProgress>[];
    for (final j in active) {
      final checkInsAsync = ref.watch(myCheckInsProvider(j.id));
      if (checkInsAsync.value case final c?) {
        progress.add(
          JourneyProgress.compute(
            journey: j,
            membership: ref.watch(myMembershipProvider(j.id)).value,
            checkIns: c,
            now: now,
          ),
        );
      } else if (checkInsAsync.isLoading) {
        anyLoading = true;
      } else if (checkInsAsync.hasError) {
        firstError ??= checkInsAsync.error;
      }
    }
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
        if (progress.isEmpty && anyLoading)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: UiSpace.xl),
            child: Center(
              child: UiSpinner(
                key: const ValueKey('today-sheet-loading'),
                semanticsLabel: app.common_loading,
              ),
            ),
          )
        else if (progress.isEmpty && firstError != null)
          UiEmptyState(
            key: const ValueKey('today-sheet-error'),
            glyph: const OurneyIcon(name: 'error', size: 40),
            title: journeyErrorMessage(context, firstError),
            actionLabel: app.common_retry,
            onAction: () {
              ref.invalidate(journeysListProvider);
              for (final j in active) {
                ref.invalidate(myCheckInsProvider(j.id));
              }
            },
          )
        else if (allDone) ...[
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
              trailing: UiTag(label: l10n.journeys_addMoreTag, bordered: true),
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
            glyph: const OurneyIcon(
              name: 'chevron-right',
              size: 20,
              flat: true,
            ),
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
        child: uiJourneyGlyph(
          journey.emoji,
          journey.templateId,
          size: 20,
          color: style.onAccent,
        ),
      ),
      subtitle: Text(
        journeyStyleName(context, style),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: UiText.body(size: 11, color: ui.inkMuted),
      ),
      trailing:
          trailing ??
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OurneyIcon(
                name: progress.showStreak ? 'flame' : 'camera',
                size: 15,
                flat: true,
                color: progress.showStreak ? ui.flame : ui.inkMuted,
              ),
              const SizedBox(width: 3),
              Text(
                progress.showStreak
                    ? '${progress.summary.current}'
                    : l10n.journeys_wrappedPhotoDays(
                        progress.checkInsByDate.length,
                      ),
                semanticsLabel: progress.showStreak
                    ? '${progress.summary.current} ${l10n.journeys_streakDaysLabel}'
                    : l10n.journeys_wrappedPhotoDays(
                        progress.checkInsByDate.length,
                      ),
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
