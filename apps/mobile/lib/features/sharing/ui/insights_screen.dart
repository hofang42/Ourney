import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/providers.dart';
import '../../../personas/persona_contract.dart';
import '../../../ui/ui.dart';
import '../data/sharing_providers.dart';
import '../l10n/generated/sharing_localizations.dart';
import 'sharing_widgets.dart';

/// Days drawn by the views chart.
const int insightsChartDays = 30;

/// The last [days] daily counts ending on the latest day in [byDay] (or
/// [today] when later), missing days as zero, oldest first.
List<DailyCount> fillDays(
  List<DailyCount> byDay, {
  required LocalDate today,
  int days = insightsChartDays,
}) {
  var end = today;
  for (final d in byDay) {
    if (d.day.isAfter(end)) end = d.day;
  }
  final counts = {for (final d in byDay) d.day: d.count};
  return [
    for (var i = days - 1; i >= 0; i--)
      DailyCount(end.addDays(-i), counts[end.addDays(-i)] ?? 0),
  ];
}

/// `/sharing/:journeyId/insights` (SCR-88): views (numbers only, never who),
/// likes split friends / others, follow-alongs, the caller's likers (S20).
class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({required this.journeyId, super.key});

  final String journeyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = SharingL10n.of(context);
    if (ref.watch(appConfigProvider).localOnly) {
      return SharingPage(
        title: l10n.sharing_insightsTitle,
        children: const [SharingNeedsServer()],
      );
    }
    final journey = ref.watch(sharingJourneyProvider(journeyId)).value;
    final async = ref.watch(journeyInsightsProvider(journeyId));
    final insights = async.value;
    final subtitle = journey == null
        ? l10n.sharing_insightsTitle
        : '${l10n.sharing_insightsTitle} · '
              '${uiStyleForSkin(personaSkinOf(journey)).name}';

    return SharingPage(
      scaffoldKey: const ValueKey('insights'),
      title: journey?.title ?? l10n.sharing_insightsTitle,
      subtitle: subtitle,
      children: [
        if (insights != null)
          _InsightsBody(
            journey: journey,
            insights: insights,
            journeyId: journeyId,
          )
        else if (async.hasError)
          SharingErrorView(
            error: async.error!,
            onRetry: () => ref.invalidate(journeyInsightsProvider(journeyId)),
          )
        else
          const SharingLoading(),
      ],
    );
  }
}

class _InsightsBody extends ConsumerWidget {
  const _InsightsBody({
    required this.journey,
    required this.insights,
    required this.journeyId,
  });

  final Journey? journey;
  final JourneyInsights insights;
  final String journeyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = SharingL10n.of(context);
    final ui = context.ui;
    final i = insights;
    final state = ref.watch(shareStateProvider(journeyId)).value;
    final accent = journey == null
        ? ui.brand
        : uiStyleForSkin(personaSkinOf(journey!)).accent;
    // fillDays already extends to a later view day; the chart ends today.
    final days = fillDays(i.viewsByDay, today: _today());
    final peak = days.fold<int>(0, (m, d) => math.max(m, d.count));

    Widget tile(String key, String label, int value, String delta) => Expanded(
      child: UiCard(
        key: ValueKey(key),
        radius: UiRadius.menu,
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UiEyebrow(label.toUpperCase()),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                compactCount(context, value),
                style: UiText.display(size: 30, color: ui.ink),
              ),
            ),
            const SizedBox(height: 6),
            Text(delta, style: UiText.body(size: 11, color: ui.success)),
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: UiSpace.lg),
        if (state != null && !state.linkOn)
          Padding(
            padding: const EdgeInsets.only(bottom: UiSpace.md),
            child: Text(
              l10n.sharing_linkOffNote,
              key: const ValueKey('insights-link-off'),
              style: sharingLabel(context, size: 13, color: ui.warn),
            ),
          ),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              tile(
                'insights-views',
                l10n.sharing_views,
                i.views,
                l10n.sharing_newViewersWeek(i.viewsThisWeek),
              ),
              const SizedBox(width: 6),
              tile(
                'insights-likes',
                l10n.sharing_likes,
                i.likesFromFriends + i.likesFromStrangers,
                l10n.sharing_thisWeek(i.likesThisWeek),
              ),
              const SizedBox(width: 6),
              tile(
                'insights-started',
                l10n.sharing_started,
                i.started,
                l10n.sharing_thisWeek(i.startedThisWeek),
              ),
            ],
          ),
        ),
        const SizedBox(height: UiSpace.lg),
        UiCard(
          radius: UiRadius.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.sharing_views,
                          style: UiText.h2(size: 16, color: ui.ink),
                        ),
                        Text(
                          l10n.sharing_viewsPerDay,
                          style: UiText.body(size: 12, color: ui.inkMuted),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    l10n.sharing_last30Days,
                    style: sharingLabel(context, size: 12, color: ui.inkMuted),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Semantics(
                label: l10n.sharing_chartSemantics(peak),
                excludeSemantics: true,
                child: SizedBox(
                  key: const ValueKey('insights-chart'),
                  height: 150,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: ViewsBarChartPainter(
                      counts: [for (final d in days) d.count],
                      bar: accent,
                      baseline: ui.divider,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      formatLocalDate(context, days.first.day),
                      style: UiText.body(size: 11, color: ui.inkMuted),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      formatLocalDate(context, days.last.day),
                      textAlign: TextAlign.end,
                      style: UiText.body(size: 11, color: ui.inkMuted),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: UiSpace.lg),
        Container(
          key: const ValueKey('insights-split'),
          constraints: const BoxConstraints(minHeight: 54),
          decoration: BoxDecoration(
            border: Border.symmetric(horizontal: BorderSide(color: ui.divider)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.sharing_likesFriends(i.likesFromFriends),
                  textAlign: TextAlign.center,
                  style: sharingLabel(context, size: 13),
                ),
              ),
              Expanded(
                child: Text(
                  l10n.sharing_likesOthers(i.likesFromStrangers),
                  textAlign: TextAlign.center,
                  style: sharingLabel(context, size: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: UiSpace.xl),
        UiListHeading(title: l10n.sharing_likersTitle),
        const SizedBox(height: 6),
        if (i.likers.isEmpty)
          Text(
            l10n.sharing_noLikers,
            style: UiText.muted(color: ui.inkMuted, size: 14),
          ),
        for (final p in i.likers)
          UiRow(
            key: ValueKey('insights-liker-${p.userId}'),
            title: p.displayName,
            leading: PersonAvatar(person: p, size: 38),
            subtitle: Text(
              '@${p.username}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: UiText.body(size: 12, color: ui.inkMuted),
            ),
            showChevron: false,
          ),
        const SizedBox(height: UiSpace.lg),
        Container(
          key: const ValueKey('insights-privacy'),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: ui.fill,
            borderRadius: BorderRadius.circular(UiRadius.menu),
          ),
          child: Text(
            l10n.sharing_privacyNote,
            style: UiText.body(size: 13, color: ui.inkMuted),
          ),
        ),
      ],
    );
  }

  static LocalDate _today() {
    final now = DateTime.now();
    return LocalDate(now.year, now.month, now.day);
  }
}

/// Daily views as bars on a hairline baseline (SCR-88). Purely visual: the
/// numbers are announced through the chart's semantics label.
class ViewsBarChartPainter extends CustomPainter {
  ViewsBarChartPainter({
    required this.counts,
    required this.bar,
    required this.baseline,
  });

  final List<int> counts;
  final Color bar;
  final Color baseline;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = baseline
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height - 0.5),
      Offset(size.width, size.height - 0.5),
      line,
    );
    if (counts.isEmpty) return;
    final peak = counts.reduce(math.max);
    final slot = size.width / counts.length;
    final gap = math.min(4.0, slot * 0.25);
    final paint = Paint()..color = bar;
    for (var i = 0; i < counts.length; i++) {
      final v = counts[i];
      if (v <= 0 || peak == 0) continue;
      final h = math.max(2.0, (size.height - 1) * v / peak);
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(i * slot + gap / 2, size.height - 1 - h, slot - gap, h),
          topLeft: const Radius.circular(2),
          topRight: const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ViewsBarChartPainter old) =>
      old.bar != bar || old.baseline != baseline || !_same(old.counts, counts);

  static bool _same(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
