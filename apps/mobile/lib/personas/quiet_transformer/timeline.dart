import 'package:flutter/material.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/theme/app_theme.dart' show displayStyle;
import '../../app/theme/persona_theme.dart';
import '../../features/journeys/domain/journey_progress.dart';
import '../../features/journeys/ui/journey_photo.dart';
import '../../features/journeys/ui/timeline_grid.dart';
import '../../shared/color_utils.dart';
import '../../shared/dashed_placeholder.dart';
import '../../shared/layout.dart';
import '../../shared/persona_pill.dart';
import '../persona_contract.dart';
import 'l10n/generated/quiet_transformer_localizations.dart';
import 'metric_curve_painter.dart';

/// **Task Q1** (`PersonaSkinId.quietTransformer` — `connectedWeightCurve`):
/// Top smooth weight/metric trend curve (`65.2 KG -> 62.0 KG`) connected
/// directly into a vertical photo milestone spine (`DAY 01`, `DAY 07 ★`,
/// `DAY 14 ★`, `DAY N · TODAY`).
///
/// Respects FR-B7: when `data.hideMetric` is true or `journey.metricName` is
/// null, hides exact metric numbers and the trend curve.
class ConnectedWeightCurveTimeline extends StatelessWidget {
  const ConnectedWeightCurveTimeline({required this.data, super.key});

  final PersonaTimelineData data;

  /// Selects days displayed on the vertical milestone spine: all reached days
  /// (checked-in, missed, or today), or Day 1 if the journey has not started.
  static List<TimelineDay> visibleSpineDays(List<TimelineDay> allDays) {
    if (allDays.isEmpty) return const [];
    final reached = [
      for (final d in allDays)
        if (d.state != DayState.future && d.state != DayState.notCounted) d,
    ];
    return reached.isEmpty ? [allDays.first] : reached;
  }

  static bool isMilestoneDay(TimelineDay day) =>
      day.dayNumber == 1 ||
      day.isToday ||
      (day.dayNumber > 1 && day.dayNumber % 7 == 0);

  @override
  Widget build(BuildContext context) {
    final pTheme = OurneyPersonaTheme.of(context);
    final l10n = QuietTransformerL10n.of(context);
    final journey = data.journey;
    final hasMetricConfig =
        journey.metricName != null && journey.metricName!.trim().isNotEmpty;
    final series = MetricSeries.fromDays(data.days);
    final spineDays = visibleSpineDays(data.days);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final cardPad = OurneyLayout.cardPadding(width);

        final column = Column(
          key: const ValueKey('q1-connected-weight-curve'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                PersonaPill(
                  key: const ValueKey('q1-vault-pill'),
                  icon: Icons.lock_rounded,
                  label: l10n.quiet_transformer_vaultPill(data.dayNumber),
                ),
                PersonaPill(
                  key: const ValueKey('q1-streak-pill'),
                  icon: Icons.local_fire_department_rounded,
                  label: l10n.quiet_transformer_streakLabel(data.currentStreak),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (hasMetricConfig) ...[
              _TrendCurveCard(
                journey: journey,
                series: series,
                hideMetric: data.hideMetric,
                padding: cardPad,
              ),
              // Vertical connector linking the trend card directly into the
              // photo milestone spine.
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(start: 23),
                  child: Container(
                    width: 2.5,
                    height: 16,
                    color: pTheme.primaryAccent.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ],
            for (var i = 0; i < spineDays.length; i++)
              _MilestoneSpineRow(
                key: ValueKey('q1-spine-day-${spineDays[i].dayNumber}'),
                day: spineDays[i],
                unit: journey.metricUnit,
                startValue: series.startValue,
                hideMetric: data.hideMetric || !hasMetricConfig,
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

class _TrendCurveCard extends StatelessWidget {
  const _TrendCurveCard({
    required this.journey,
    required this.series,
    required this.hideMetric,
    required this.padding,
  });

  final Journey journey;
  final MetricSeries series;
  final bool hideMetric;
  final double padding;

  @override
  Widget build(BuildContext context) {
    final pTheme = OurneyPersonaTheme.of(context);
    final l10n = QuietTransformerL10n.of(context);
    final metricName = journey.metricName ?? '';
    final unit = journey.metricUnit;

    if (hideMetric) {
      return Container(
        key: const ValueKey('q1-curve-hidden'),
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: pTheme.surface,
          borderRadius: BorderRadius.circular(pTheme.cardRadius),
          border: Border.all(color: pTheme.border, width: pTheme.borderWidth),
        ),
        child: Row(
          children: [
            Icon(
              Icons.visibility_off_rounded,
              color: pTheme.primaryAccent,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.quiet_transformer_metricHiddenBadge,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: pTheme.ink,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final delta = series.delta;
    final startText = series.hasCurve
        ? MetricSeries.formatValue(series.startValue!, unit)
        : null;
    final latestText = (series.hasCurve || series.isSingle)
        ? MetricSeries.formatValue(series.latestValue!, unit)
        : null;

    return Container(
      key: const ValueKey('q1-curve-card'),
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: pTheme.surface,
        borderRadius: BorderRadius.circular(pTheme.cardRadius),
        border: Border.all(color: pTheme.border, width: pTheme.borderWidth),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.show_chart_rounded,
                size: 18,
                color: pTheme.primaryAccent,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.quiet_transformer_trendTitle(metricName),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: pTheme.inkMuted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ),
              if (delta != null)
                Container(
                  key: const ValueKey('q1-curve-delta'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: pTheme.primaryAccent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    MetricSeries.formatDelta(delta, unit),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: pTheme.primaryAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                ),
            ],
          ),
          if (latestText != null) ...[
            const SizedBox(height: 6),
            Row(
              key: const ValueKey('q1-curve-summary'),
              children: [
                if (startText != null) ...[
                  Flexible(
                    child: Text(
                      startText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: displayStyle(
                        size: 19,
                        weight: 700,
                        color: pTheme.inkMuted,
                        height: 1.3,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      Icons.trending_flat_rounded,
                      size: 18,
                      color: pTheme.primaryAccent,
                    ),
                  ),
                ],
                Flexible(
                  child: Text(
                    latestText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: displayStyle(
                      size: 19,
                      weight: 700,
                      color: pTheme.ink,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            height: 88,
            child: CustomPaint(
              key: const ValueKey('q1-curve-canvas'),
              painter: MetricCurvePainter(
                points: series.points,
                lineColor: pTheme.primaryAccent,
                gridColor: pTheme.border.withValues(alpha: 0.6),
                dotStrokeColor: pTheme.surface,
              ),
              child: series.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          l10n.quiet_transformer_trendEmpty,
                          key: const ValueKey('q1-curve-empty-text'),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: pTheme.inkMuted,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                        ),
                      ),
                    )
                  : (series.isSingle
                        ? Align(
                            alignment: Alignment.bottomCenter,
                            child: Text(
                              l10n.quiet_transformer_trendSingle,
                              key: const ValueKey('q1-curve-single-text'),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: pTheme.inkMuted,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                height: 1.35,
                              ),
                            ),
                          )
                        : null),
            ),
          ),
        ],
      ),
    );
  }
}

class _MilestoneSpineRow extends StatelessWidget {
  const _MilestoneSpineRow({
    required this.day,
    required this.unit,
    required this.startValue,
    required this.hideMetric,
    required this.isLast,
    required this.onTap,
    required this.photoBuilder,
    super.key,
  });

  final TimelineDay day;
  final String? unit;
  final double? startValue;
  final bool hideMetric;
  final bool isLast;
  final VoidCallback? onTap;
  final PersonaDayPhotoBuilder? photoBuilder;

  @override
  Widget build(BuildContext context) {
    final pTheme = OurneyPersonaTheme.of(context);
    final l10n = QuietTransformerL10n.of(context);
    final dayDigits = day.dayNumber.toString().padLeft(2, '0');
    final isStar = day.dayNumber > 1 && day.dayNumber % 7 == 0;
    final milestone = ConnectedWeightCurveTimeline.isMilestoneDay(day);
    final checkedIn = day.checkIn != null;

    final String title = day.isToday
        ? l10n.quiet_transformer_milestoneToday(dayDigits)
        : (day.dayNumber == 1
              ? l10n.quiet_transformer_milestoneStart
              : (isStar
                    ? l10n.quiet_transformer_milestoneWeek(dayDigits)
                    : l10n.quiet_transformer_milestoneDay(dayDigits)));

    final val = hideMetric ? null : day.checkIn?.metricValue;
    final metricText = val == null
        ? null
        : MetricSeries.formatValue(val, unit);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Container(
                  width: milestone ? 26 : 18,
                  height: milestone ? 26 : 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: checkedIn || day.isToday
                        ? pTheme.primaryAccent
                        : pTheme.surfaceElevated,
                    border: Border.all(
                      color: pTheme.border,
                      width: pTheme.borderWidth,
                    ),
                  ),
                  child: milestone
                      ? Icon(
                          isStar
                              ? Icons.star_rounded
                              : (day.isToday
                                    ? Icons.bolt_rounded
                                    : Icons.flag_rounded),
                          size: 14,
                          color: checkedIn || day.isToday
                              ? readableOn(pTheme.primaryAccent)
                              : pTheme.inkMuted,
                        )
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2.5,
                      color: pTheme.primaryAccent.withValues(alpha: 0.45),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: Semantics(
                button: onTap != null,
                label: title,
                child: Material(
                  color: pTheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(pTheme.cardRadius),
                    side: BorderSide(
                      color: day.isToday
                          ? pTheme.primaryAccent
                          : pTheme.border,
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
                                    : DashedPlaceholder(
                                        icon: Icons.photo_camera_outlined,
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
                                  Row(
                                    children: [
                                      if (isStar) ...[
                                        Icon(
                                          Icons.star_rounded,
                                          size: 16,
                                          color: pTheme.secondaryAccent,
                                        ),
                                        const SizedBox(width: 4),
                                      ],
                                      Expanded(
                                        child: Text(
                                          title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: pTheme.ink,
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w800,
                                            height: 1.35,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (metricText != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      metricText,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: pTheme.primaryAccent,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        height: 1.35,
                                      ),
                                    ),
                                  ] else if (day.checkIn?.caption != null &&
                                      day.checkIn!.caption!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      day.checkIn!.caption!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: pTheme.inkMuted,
                                        fontSize: 12.5,
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
          ),
        ],
      ),
    );
  }
}
