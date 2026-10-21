import 'package:flutter/material.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/theme/app_theme.dart' show displayStyle;
import '../../app/theme/persona_theme.dart';
import '../../features/journeys/domain/journey_progress.dart';
import '../../features/journeys/ui/journey_photo.dart';
import '../../features/journeys/ui/timeline_grid.dart';
import '../../shared/dashed_placeholder.dart';
import '../../shared/layout.dart';
import '../../shared/persona_pill.dart';
import '../persona_contract.dart';
import '../quiet_transformer/metric_curve_painter.dart';
import '../quiet_transformer/timeline.dart' show ConnectedWeightCurveTimeline;
import 'l10n/generated/aesthetic_flexer_localizations.dart';

/// **Task R1** (`PersonaSkinId.aestheticFlexer` — `athleticTelemetry`):
/// - Reuses [MetricCurvePainter] from Q1 (`glow: true` in `pTheme.secondaryAccent`).
/// - When the journey has no metric (such as the default `workout30` template)
///   or `data.hideMetric` is true, omits the metric sparkline and renders the
///   active-days/streak telemetry header plus the glowing vertical day spine
///   (`docs/TASKS.md` R1).
class AthleticTelemetryTimeline extends StatelessWidget {
  const AthleticTelemetryTimeline({required this.data, super.key});

  final PersonaTimelineData data;

  @override
  Widget build(BuildContext context) {
    final pTheme = OurneyPersonaTheme.of(context);
    final l10n = AestheticFlexerL10n.of(context);
    final journey = data.journey;
    final hasMetricConfig =
        !data.hideMetric &&
        journey.metricName != null &&
        journey.metricName!.trim().isNotEmpty;
    final series = MetricSeries.fromDays(data.days);
    final showSparkline = hasMetricConfig && !series.isEmpty;
    final spineDays = ConnectedWeightCurveTimeline.visibleSpineDays(data.days);
    final totalDays = journey.durationDays ?? data.days.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final cardPad = OurneyLayout.cardPadding(width);

        final column = Column(
          key: const ValueKey('r1-athletic-telemetry'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                PersonaPill(
                  key: const ValueKey('r1-style-pill'),
                  icon: Icons.bolt_rounded,
                  emphasized: true,
                  label: l10n.aesthetic_flexer_name,
                ),
                PersonaPill(
                  key: const ValueKey('r1-active-pill'),
                  icon: Icons.local_fire_department_rounded,
                  label: l10n.aesthetic_flexer_activeDaysHeader(
                    data.checkInCount,
                    totalDays < 1 ? 1 : totalDays,
                    data.currentStreak,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (showSparkline) ...[
              _TelemetrySparklineCard(
                journey: journey,
                series: series,
                padding: cardPad,
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(start: 23),
                  child: Container(
                    width: 2.5,
                    height: 16,
                    color: pTheme.secondaryAccent,
                  ),
                ),
              ),
            ],
            for (var i = 0; i < spineDays.length; i++)
              _AthleticSpineNode(
                key: ValueKey('r1-spine-day-${spineDays[i].dayNumber}'),
                day: spineDays[i],
                unit: journey.metricUnit,
                hideMetric: !hasMetricConfig,
                isLast: i == spineDays.length - 1,
                onTap: data.onTapDay == null
                    ? null
                    : () => data.onTapDay!(spineDays[i]),
                photoBuilder: data.photoBuilder,
              ),
            if (data.days.isNotEmpty) ...[
              const SizedBox(height: 16),
              TimelineGrid(
                days: data.days,
                onTapDay: (d) => data.onTapDay?.call(d),
              ),
            ],
          ],
        );

        if (data.shrinkWrap) return column;
        return SingleChildScrollView(
          physics: data.physics,
          child: column,
        );
      },
    );
  }
}

class _TelemetrySparklineCard extends StatelessWidget {
  const _TelemetrySparklineCard({
    required this.journey,
    required this.series,
    required this.padding,
  });

  final Journey journey;
  final MetricSeries series;
  final double padding;

  @override
  Widget build(BuildContext context) {
    final pTheme = OurneyPersonaTheme.of(context);
    final l10n = AestheticFlexerL10n.of(context);
    final unit = journey.metricUnit;
    final totalStr = MetricSeries.formatValue(series.total, unit);
    final latestStr = MetricSeries.formatValue(series.latestValue ?? 0, unit);

    return Container(
      key: const ValueKey('r1-sparkline-card'),
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: pTheme.surface,
        borderRadius: BorderRadius.circular(pTheme.cardRadius),
        border: Border.all(
          color: pTheme.secondaryAccent.withValues(alpha: 0.55),
          width: pTheme.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.aesthetic_flexer_telemetryHeader(totalStr, latestStr),
            key: const ValueKey('r1-telemetry-header'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: displayStyle(
              size: 16,
              weight: 800,
              color: pTheme.secondaryAccent,
              height: 1.3,
            ).copyWith(letterSpacing: 0.5),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 84,
            child: CustomPaint(
              key: const ValueKey('r1-sparkline-canvas'),
              painter: MetricCurvePainter(
                points: series.points,
                lineColor: pTheme.secondaryAccent,
                gridColor: pTheme.border.withValues(alpha: 0.55),
                dotStrokeColor: pTheme.surface,
                glow: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AthleticSpineNode extends StatelessWidget {
  const _AthleticSpineNode({
    required this.day,
    required this.unit,
    required this.hideMetric,
    required this.isLast,
    required this.onTap,
    required this.photoBuilder,
    super.key,
  });

  final TimelineDay day;
  final String? unit;
  final bool hideMetric;
  final bool isLast;
  final VoidCallback? onTap;
  final PersonaDayPhotoBuilder? photoBuilder;

  @override
  Widget build(BuildContext context) {
    final pTheme = OurneyPersonaTheme.of(context);
    final l10n = AestheticFlexerL10n.of(context);
    final dayDigits = day.dayNumber.toString().padLeft(2, '0');
    final isStar = day.dayNumber > 1 && day.dayNumber % 7 == 0;
    final checkedIn = day.checkIn != null;

    final String label = day.isToday
        ? l10n.aesthetic_flexer_milestoneToday(dayDigits)
        : (day.dayNumber == 1
              ? l10n.aesthetic_flexer_milestoneStart
              : (isStar
                    ? l10n.aesthetic_flexer_milestoneStar(dayDigits)
                    : l10n.aesthetic_flexer_milestoneDay(dayDigits)));

    final val = hideMetric ? null : day.checkIn?.metricValue;
    final metricText = val == null ? null : MetricSeries.formatValue(val, unit);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: checkedIn || day.isToday
                        ? pTheme.secondaryAccent
                        : pTheme.surfaceElevated,
                    border: Border.all(
                      color: pTheme.border,
                      width: pTheme.borderWidth,
                    ),
                  ),
                  child: Icon(
                    isStar
                        ? Icons.star_rounded
                        : (checkedIn
                              ? Icons.check_rounded
                              : Icons.bolt_rounded),
                    size: 14,
                    color: checkedIn || day.isToday
                        ? Colors.black
                        : pTheme.inkMuted,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2.5,
                      color: pTheme.secondaryAccent.withValues(alpha: 0.65),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: Material(
                color: pTheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(pTheme.cardRadius),
                  side: BorderSide(
                    color: day.isToday ? pTheme.primaryAccent : pTheme.border,
                    width: day.isToday ? 1.5 : pTheme.borderWidth,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onTap,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: OurneyLayout.minTouchTarget,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 64,
                            height: 64,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: checkedIn
                                  ? (photoBuilder != null
                                        ? photoBuilder!(context, day)
                                        : JourneyPhoto(
                                            checkIn: day.checkIn!,
                                            thumbnail: true,
                                          ))
                                  : const DashedPlaceholder(
                                      icon: Icons.fitness_center_rounded,
                                      radius: 12,
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: displayStyle(
                                    size: 14,
                                    weight: 800,
                                    color: pTheme.ink,
                                    height: 1.3,
                                  ),
                                ),
                                if (metricText != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    metricText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: pTheme.secondaryAccent,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: pTheme.inkMuted,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
