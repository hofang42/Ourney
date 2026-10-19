import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/theme/persona_theme.dart';
import '../../app/theme/tokens.dart' show OurneyColors;
import 'l10n/generated/accountability_squad_localizations.dart';
import 'persona_palette.dart';
import 'persona_widgets.dart';

/// **Task S2** (`PersonaSkinId.accountabilitySquad` — `studyTimerSnap`):
/// Camera HUD overlay displaying:
/// - Top tactile pill: `<study minutes> · 🔥 <streak>` (hides the study minutes
///   part when the journey has no metric or metric is hidden).
/// - Bottom glass timestamp pill: e.g., `06:15 AM`.
class StudyTimerSnapHud extends StatelessWidget {
  const StudyTimerSnapHud({
    required this.journey,
    required this.streak,
    required this.capturedAt,
    this.metricValue,
    this.hideMetric = false,
    this.viewfinderChild,
    this.borderRadius,
    super.key,
  });

  final Journey journey;
  final int streak;
  final DateTime capturedAt;
  final double? metricValue;
  final bool hideMetric;

  /// Optional camera preview widget placed behind the HUD overlay.
  final Widget? viewfinderChild;

  /// Corner radius of the frame (`null` = the skin's card radius, `0` for a
  /// full-bleed capture screen).
  final double? borderRadius;

  static String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  /// Formats [dt] as `HH:MM AM/PM` matching `P2 · center` (`06:15 AM`).
  static String formatTimestamp(DateTime dt) {
    final hour24 = dt.hour;
    final period = hour24 >= 12 ? 'PM' : 'AM';
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final h = hour12.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    final pTheme = OurneyPersonaTheme.of(context);
    final l10n = AccountabilitySquadL10n.of(context);

    final hasMetricConfigured =
        !hideMetric &&
        (journey.metricName != null || journey.metricUnit != null) &&
        metricValue != null;

    final streakPart = l10n.accountability_squad_streakBadge(streak);
    final String topLabel;
    if (hasMetricConfigured) {
      final valStr = _formatNumber(metricValue!);
      final unitStr = (journey.metricUnit ?? '').trim().toUpperCase();
      final studyPart = l10n.accountability_squad_studyMetricBadge(
        valStr,
        unitStr,
      );
      topLabel = '$studyPart · $streakPart';
    } else {
      topLabel = streakPart;
    }

    final timeString = formatTimestamp(capturedAt);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius ?? pTheme.cardRadius),
      child: ColoredBox(
        // Camera/media surfaces always stay dark (CLAUDE.md §2.2).
        color: OurneyColors.cameraBg,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ?viewfinderChild,
            // Scrims keep the pill and timestamp legible on bright scenes
            // without tinting the middle of the frame.
            const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0, 0.22, 0.78, 1],
                    colors: [
                      PersonaPalette.scrimTop,
                      PersonaPalette.transparent,
                      PersonaPalette.transparent,
                      PersonaPalette.scrimBottom,
                    ],
                  ),
                ),
              ),
            ),
            // Top tactile study timer + streak pill
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
                child: SquadPersonaPill(
                  key: const ValueKey('s2-study-streak-pill'),
                  leading: hasMetricConfigured
                      ? Icon(
                          Icons.menu_book_rounded,
                          size: 16,
                          color: pTheme.ink,
                        )
                      : null,
                  label: topLabel,
                  backgroundColor: pTheme.surface,
                  foregroundColor: pTheme.ink,
                  borderColor: pTheme.border,
                ),
              ),
            ),
            // Bottom frosted timestamp badge
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      key: const ValueKey('s2-timestamp-pill'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: PersonaPalette.glassFill,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: PersonaPalette.glassStroke),
                      ),
                      child: Text(
                        timeString,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: PersonaPalette.onGlass,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
