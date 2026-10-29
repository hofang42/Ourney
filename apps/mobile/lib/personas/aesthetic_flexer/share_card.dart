import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/theme/app_theme.dart' show displayStyle;
import '../../app/theme/persona_theme.dart';
import '../../app/theme/tokens.dart';
import '../../features/journeys/ui/journey_photo.dart';
import '../../shared/dashed_placeholder.dart';
import '../../shared/layout.dart';
import '../../shared/ourney_primary_button.dart';
import '../../shared/persona_pill.dart';
import '../persona_contract.dart';
import '../quiet_transformer/metric_curve_painter.dart';
import 'l10n/generated/aesthetic_flexer_localizations.dart';

/// **Task R3** (`PersonaSkinId.aestheticFlexer` — `transparentStorySticker`):
/// - 9:16 vertical Story preview card with bold telemetry overlay and a
///   21-bar active streak heatmap at bottom (`N DAYS ACTIVE`).
/// - Active vs missed days are distinguished by both height/shape and color
///   (never color alone — `docs/TASKS.md` R3).
/// - Electric Coral `Share to Story` CTA button calling `data.onShare`.
class TransparentStoryStickerShareCard extends StatelessWidget {
  const TransparentStoryStickerShareCard({required this.data, super.key});

  final PersonaShareData data;

  static const int heatmapBarCount = 21;

  /// Computes a boolean list of length [heatmapBarCount] representing whether
  /// each day in the window (trailing 21 days ending at `currentDayNumber`)
  /// has a check-in.
  static List<bool> buildHeatmap(
    Journey journey,
    Iterable<CheckIn> checkIns,
    int currentDayNumber,
  ) {
    final doneDates = {for (final c in checkIns) c.localDate};
    final endDay = math.max(1, currentDayNumber);
    final startDay = endDay - heatmapBarCount + 1;
    return [
      for (var d = startDay; d <= endDay; d++)
        d >= 1 && doneDates.contains(journey.startDate.addDays(d - 1)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final pTheme = OurneyPersonaTheme.of(context);
    final l10n = AestheticFlexerL10n.of(context);
    final sorted = data.sortedCheckIns;
    final latest = sorted.lastOrNull;
    final latestWithMetric = sorted.reversed
        .where((c) => c.metricValue != null)
        .firstOrNull;
    final heatmap = buildHeatmap(data.journey, sorted, data.dayNumber);
    final activeCount = {for (final c in sorted) c.localDate}.length;
    final dayDigits = data.dayNumber.toString().padLeft(2, '0');
    final metricVal = data.hideMetric ? null : latestWithMetric?.metricValue;
    final metricStr = metricVal == null
        ? null
        : MetricSeries.formatValue(metricVal, data.journey.metricUnit);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final pad = OurneyLayout.cardPadding(width);

        return Container(
          key: const ValueKey('r3-transparent-story-sticker'),
          padding: EdgeInsets.all(pad),
          decoration: BoxDecoration(
            color: pTheme.surface,
            borderRadius: BorderRadius.circular(pTheme.cardRadius),
            border: Border.all(color: pTheme.border, width: pTheme.borderWidth),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  PersonaPill(
                    icon: Icons.bolt_rounded,
                    label: l10n.aesthetic_flexer_name,
                  ),
                  PersonaPill(
                    key: const ValueKey('r3-active-days-pill'),
                    emphasized: true,
                    label: l10n.aesthetic_flexer_daysActiveBadge(activeCount),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 9:16 Story Frame Preview (capped in width so 320dp tests scroll cleanly).
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 260),
                  child: AspectRatio(
                    aspectRatio: 9 / 16,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ColoredBox(
                            color: const Color(0xFF0B0C0E),
                            child: latest != null
                                ? (data.photoBuilder != null
                                      ? data.photoBuilder!(context, latest)
                                      : JourneyPhoto(checkIn: latest))
                                : Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: DashedPlaceholder(
                                      icon: Icons.fitness_center_rounded,
                                      label: l10n.aesthetic_flexer_waitingPhoto,
                                    ),
                                  ),
                          ),
                          // Dark bottom gradient scrim so typography & heatmap pop.
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0x44000000),
                                  Color(0x00000000),
                                  Color(0xCC090A0F),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        '${l10n.aesthetic_flexer_milestoneDay(dayDigits)} · ',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: OurneyColors.mediaWhite,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.local_fire_department_rounded,
                                      size: 14,
                                      color: pTheme.primaryAccent,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      '${data.currentStreak}',
                                      style: const TextStyle(
                                        color: OurneyColors.mediaWhite,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      data.journey.title.toUpperCase(),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: displayStyle(
                                        size: 18,
                                        weight: 800,
                                        color: OurneyColors.mediaWhite,
                                        height: 1.25,
                                      ),
                                    ),
                                    if (metricStr != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        metricStr,
                                        key: const ValueKey('r3-story-metric'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: displayStyle(
                                          size: 16,
                                          weight: 800,
                                          color: pTheme.secondaryAccent,
                                          height: 1.25,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 10),
                                    // 21-bar active streak heatmap (height + dot + color).
                                    SizedBox(
                                      key: const ValueKey('r3-heatmap-strip'),
                                      height: 26,
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          for (
                                            var i = 0;
                                            i < heatmap.length;
                                            i++
                                          ) ...[
                                            if (i > 0) const SizedBox(width: 3),
                                            Expanded(
                                              child: _HeatmapBar(
                                                key: ValueKey(
                                                  'r3-heatmap-bar-$i',
                                                ),
                                                active: heatmap[i],
                                                activeColor:
                                                    pTheme.secondaryAccent,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              OurneyPrimaryButton(
                key: const ValueKey('r3-share-story-button'),
                label: l10n.aesthetic_flexer_shareStoryButton,
                icon: Icons.ios_share_rounded,
                onPressed: data.onShare,
              ),
              if (data.publicLinkSection != null &&
                  data.journey.kind == JourneyKind.solo) ...[
                const SizedBox(height: 12),
                data.publicLinkSection!,
              ],
            ],
          ),
        );
      },
    );
  }
}

class _HeatmapBar extends StatelessWidget {
  const _HeatmapBar({
    required this.active,
    required this.activeColor,
    super.key,
  });

  final bool active;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    // Active bars are full height (24dp) with a solid fill; missed/inactive
    // bars are short (8dp) hollow/dimmed ticks so they are distinguishable
    // without relying on color alone.
    return Container(
      height: active ? 24 : 8,
      decoration: BoxDecoration(
        color: active
            ? activeColor
            : OurneyColors.mediaWhite.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
