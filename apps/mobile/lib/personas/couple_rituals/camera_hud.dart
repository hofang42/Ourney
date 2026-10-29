import 'dart:ui';

import 'package:flutter/material.dart';

import '../../app/theme/persona_theme.dart';
import '../../app/theme/tokens.dart';
import '../../features/journeys/ui/journey_photo.dart';
import '../../shared/dashed_placeholder.dart';
import '../../shared/persona_pill.dart';
import '../persona_contract.dart';
import 'l10n/generated/couple_rituals_localizations.dart';

/// **Task D3** (`PersonaSkinId.coupleRituals` — `halfFrameDuo`):
/// Split half-frame camera HUD where:
/// - **Left half**: Displays the partner's already-snapped photo for today
///   (`{name} · Snapped`) or a dashed waiting slot (`Waiting for {name}`).
/// - **Right half**: Displays the live camera [PersonaCameraData.viewfinder]
///   with a subtle prompt (`Snap your half · Complete the pair`).
/// - Preserves the full camera sensor output without restarting the camera.
class HalfFrameDuoHud extends StatelessWidget {
  const HalfFrameDuoHud({required this.data, super.key});

  final PersonaCameraData data;

  // Persona-specific viewfinder backdrop: always dark, theme-independent.
  static const Color _mediaBg = Color(0xFF141113);

  @override
  Widget build(BuildContext context) {
    final pTheme = OurneyPersonaTheme.of(context);
    final l10n = CoupleRitualsL10n.of(context);
    final partnerLabel =
        (data.partnerName != null && data.partnerName!.trim().isNotEmpty)
        ? data.partnerName!.trim()
        : l10n.couple_rituals_partnerDefault;
    final partnerCheckIn = data.partnerTodayCheckIn;

    final Widget leftContent;
    if (partnerCheckIn != null) {
      leftContent = Stack(
        key: const ValueKey('d3-partner-snapped'),
        fit: StackFit.expand,
        children: [
          if (data.partnerPhotoBuilder != null)
            data.partnerPhotoBuilder!(context, partnerCheckIn)
          else
            JourneyPhoto(checkIn: partnerCheckIn, thumbnail: false),
          Positioned(
            left: 8,
            right: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: OurneyColors.mediaBlack.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                l10n.couple_rituals_partnerDoneBadge(partnerLabel),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: OurneyColors.mediaWhite,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      leftContent = ColoredBox(
        key: const ValueKey('d3-partner-waiting'),
        color: _mediaBg,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Center(
            child: DashedPlaceholder(
              icon: Icons.favorite_border_rounded,
              label: l10n.couple_rituals_waitingPartner(partnerLabel),
              color: OurneyColors.mediaWhite.withValues(alpha: 0.7),
              radius: 14,
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(data.borderRadius ?? 20),
      child: ColoredBox(
        color: _mediaBg,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: leftContent),
                Container(
                  width: 2,
                  color: pTheme.primaryAccent.withValues(alpha: 0.75),
                ),
                Expanded(
                  child: Stack(
                    key: const ValueKey('d3-my-viewfinder-half'),
                    fit: StackFit.expand,
                    children: [
                      data.viewfinder,
                      Positioned(
                        left: 8,
                        right: 8,
                        bottom: 8,
                        child: IgnorePointer(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 5,
                                ),
                                color: OurneyColors.mediaBlack.withValues(
                                  alpha: 0.55,
                                ),
                                child: Text(
                                  l10n.couple_rituals_completePairHint,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: OurneyColors.mediaWhite,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    height: 1.25,
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
              ],
            ),
            // Top pill overlay
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: IgnorePointer(
                child: Center(
                  child: PersonaPill(
                    key: const ValueKey('d3-top-pill'),
                    icon: Icons.favorite_rounded,
                    label:
                        '${l10n.couple_rituals_name} · ${l10n.couple_rituals_streakLabel(data.currentStreak)}',
                  ),
                ),
              ),
            ),
            // Center heart stitch linking left & right frames
            Center(
              child: IgnorePointer(
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: pTheme.primaryAccent,
                    border: Border.all(
                      color: OurneyColors.mediaWhite,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    size: 16,
                    color: OurneyColors.mediaWhite,
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
