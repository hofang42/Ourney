import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/persona_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../personas/persona_contract.dart';
import '../../../shared/needs_server_view.dart';
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
      return Scaffold(
        appBar: AppBar(
          title: SharingNavTitle(title: l10n.sharing_insightsTitle),
        ),
        body: const SafeArea(child: NeedsServerView()),
      );
    }
    final journey = ref.watch(sharingJourneyProvider(journeyId)).value;
    final async = ref.watch(journeyInsightsProvider(journeyId));
    final insights = async.value;
    final subtitle = journey == null
        ? l10n.sharing_insightsTitle
        : '${l10n.sharing_insightsTitle} · '
              '${personaStyleName(personaSkinOf(journey))}';

    return Scaffold(
      key: const ValueKey('insights'),
      appBar: AppBar(
        centerTitle: true,
        title: SharingNavTitle(
          title: journey?.title ?? l10n.sharing_insightsTitle,
          subtitle: subtitle,
        ),
      ),
      body: SafeArea(
        top: false,
        child: insights != null
            ? _InsightsBody(
                journey: journey,
                insights: insights,
                journeyId: journeyId,
              )
            : async.hasError
            ? SharingErrorView(
                error: async.error!,
                onRetry: () =>
                    ref.invalidate(journeyInsightsProvider(journeyId)),
              )
            : const SharingLoading(),
      ),
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
    final c = OurneyColors.of(context);
    final i = insights;
    final state = ref.watch(shareStateProvider(journeyId)).value;
    final accent = journey == null
        ? c.primary
        : OurneyPersonaTheme.forSkin(
            personaSkinOf(journey!),
            Theme.of(context).brightness,
          ).primaryAccent;
    final days = fillDays(
      i.viewsByDay,
      today: i.viewsByDay.isEmpty
          ? _today()
          : i.viewsByDay
                .map((d) => d.day)
                .reduce((a, b) => a.isAfter(b) ? a : b),
    );
    final peak = days.fold<int>(0, (m, d) => math.max(m, d.count));

    Widget tile(String key, String label, int value, String delta) => Expanded(
      child: Container(
        key: ValueKey(key),
        constraints: const BoxConstraints(minHeight: 118),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: eyebrowStyle(size: 10, color: c.inkMuted),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                compactCount(context, value),
                style: displayStyle(size: 30, color: c.ink),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              delta,
              style: sharingBody(context, size: 11, color: c.success),
            ),
          ],
        ),
      ),
    );

    return SharingColumn(
      builder: (context, gutter) => ListView(
        padding: EdgeInsets.fromLTRB(gutter, 20, gutter, 40),
        children: [
          if (state != null && !state.linkOn)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                l10n.sharing_linkOffNote,
                key: const ValueKey('insights-link-off'),
                style: sharingLabel(context, size: 13, color: c.warning),
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
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.surface,
              border: Border.all(color: c.divider),
            ),
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
                            style: headingStyle(size: 16),
                          ),
                          Text(
                            l10n.sharing_viewsPerDay,
                            style: sharingBody(
                              context,
                              size: 12,
                              color: c.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      l10n.sharing_last30Days,
                      style: sharingLabel(context, size: 12, color: c.inkMuted),
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
                        baseline: c.divider,
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
                        style: sharingBody(
                          context,
                          size: 11,
                          color: c.inkMuted,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        formatLocalDate(context, days.last.day),
                        textAlign: TextAlign.end,
                        style: sharingBody(
                          context,
                          size: 11,
                          color: c.inkMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            key: const ValueKey('insights-split'),
            constraints: const BoxConstraints(minHeight: 54),
            decoration: BoxDecoration(
              border: Border.symmetric(
                horizontal: BorderSide(color: c.divider),
              ),
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
          const SizedBox(height: 20),
          Semantics(
            header: true,
            child: Text(
              l10n.sharing_likersTitle,
              style: headingStyle(size: 17),
            ),
          ),
          const SizedBox(height: 6),
          if (i.likers.isEmpty)
            Text(
              l10n.sharing_noLikers,
              style: sharingBody(context, color: c.inkMuted),
            ),
          for (final p in i.likers)
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Row(
                key: ValueKey('insights-liker-${p.userId}'),
                children: [
                  PersonAvatar(person: p, size: 38),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          p.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: sharingLabel(context, size: 14),
                        ),
                        Text(
                          '@${p.username}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: sharingBody(
                            context,
                            size: 12,
                            color: c.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Container(
            key: const ValueKey('insights-privacy'),
            padding: const EdgeInsets.all(14),
            color: c.surfaceSunken,
            child: Text(
              l10n.sharing_privacyNote,
              style: sharingBody(context, size: 13, color: c.inkMuted),
            ),
          ),
        ],
      ),
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
      canvas.drawRect(
        Rect.fromLTWH(i * slot + gap / 2, size.height - 1 - h, slot - gap, h),
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
