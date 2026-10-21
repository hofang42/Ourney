import 'package:flutter/material.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/theme/app_theme.dart' show displayStyle;
import '../../app/theme/persona_theme.dart';
import '../../features/journeys/ui/journey_photo.dart';
import '../../shared/color_utils.dart';
import '../../shared/dashed_placeholder.dart';
import '../../shared/layout.dart';
import '../../shared/ourney_primary_button.dart';
import '../../shared/persona_pill.dart';
import '../persona_contract.dart';
import 'l10n/generated/minimalist_habit_localizations.dart';

/// **Task Z3** (`PersonaSkinId.minimalistHabit` — `zenSummaryCard`):
/// Minimalist typographic poster:
/// - `{done} / {total} DAYS COMPLETED` (or `{done} DAYS COMPLETED` when
///   open-ended),
/// - `{percent}% CONSISTENCY` pill in Braun Coral-Orange (`pTheme.primaryAccent`),
/// - One featured 1:1 square photo frame,
/// - Matte charcoal (`pTheme.secondaryAccent`) `Export Minimal Card` button.
class ZenSummaryCardShareCard extends StatelessWidget {
  const ZenSummaryCardShareCard({required this.data, super.key});

  final PersonaShareData data;

  /// Computes consistency percentage (`0..100`) from completed days vs elapsed
  /// days (`dayNumber`).
  static int computeConsistencyPercent({
    required int checkInCount,
    required int dayNumber,
  }) {
    final denom = dayNumber < 1 ? 1 : dayNumber;
    return ((checkInCount / denom) * 100).round().clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    final pTheme = OurneyPersonaTheme.of(context);
    final l10n = MinimalistHabitL10n.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sorted = data.sortedCheckIns;
    final featured = sorted.lastOrNull;
    final doneCount = {for (final c in sorted) c.localDate}.length;
    final totalDays = data.journey.durationDays;
    final consistency = computeConsistencyPercent(
      checkInCount: doneCount,
      dayNumber: data.dayNumber,
    );

    final completedText = totalDays != null
        ? l10n.minimalist_habit_summaryCompleted(doneCount, totalDays)
        : l10n.minimalist_habit_summaryOpen(doneCount);

    // Matte charcoal button in Light mode (`pTheme.secondaryAccent`) or
    // Braun Coral-Orange in Dark mode.
    final ctaBg = isDark ? pTheme.primaryAccent : pTheme.secondaryAccent;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final maxW = OurneyLayout.contentMaxWidth(width);
        final pad = OurneyLayout.cardPadding(width);

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: Container(
              key: const ValueKey('z3-zen-summary-card'),
              padding: EdgeInsets.all(pad),
              decoration: BoxDecoration(
                color: pTheme.surface,
                borderRadius: BorderRadius.circular(pTheme.cardRadius),
                border: Border.all(
                  color: pTheme.border,
                  width: pTheme.borderWidth,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      PersonaPill(
                        key: const ValueKey('z3-style-pill'),
                        label: l10n.minimalist_habit_name,
                      ),
                      PersonaPill(
                        key: const ValueKey('z3-consistency-pill'),
                        emphasized: true,
                        label: l10n.minimalist_habit_summaryConsistency(
                          consistency,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    completedText,
                    key: const ValueKey('z3-completed-headline'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: displayStyle(
                      size: 20,
                      weight: 800,
                      color: pTheme.ink,
                      height: 1.25,
                    ).copyWith(letterSpacing: -0.3),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.journey.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: pTheme.inkMuted,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 280),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: ClipRRect(
                          key: const ValueKey('z3-featured-square'),
                          borderRadius: BorderRadius.circular(12),
                          child: featured != null
                              ? (data.photoBuilder != null
                                    ? data.photoBuilder!(context, featured)
                                    : JourneyPhoto(
                                        checkIn: featured,
                                        thumbnail: false,
                                      ))
                              : DashedPlaceholder(
                                  icon: Icons.photo_camera_outlined,
                                  label: l10n.minimalist_habit_noPhotoYet,
                                  radius: 12,
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OurneyPrimaryButton(
                    key: const ValueKey('z3-export-minimal-btn'),
                    label: l10n.minimalist_habit_exportCardButton,
                    icon: Icons.ios_share_rounded,
                    backgroundColor: ctaBg,
                    foregroundColor: readableOn(ctaBg),
                    onPressed: data.onShare,
                  ),
                  if (data.publicLinkSection != null &&
                      data.journey.kind == JourneyKind.solo) ...[
                    const SizedBox(height: 12),
                    data.publicLinkSection!,
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
