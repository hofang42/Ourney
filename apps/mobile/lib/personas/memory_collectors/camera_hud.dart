import 'package:flutter/material.dart';
import 'package:ourney_core/ourney_core.dart';

import '../accountability_squad/persona_palette.dart';
import 'l10n/generated/memory_collectors_localizations.dart';

/// **Task M2** (`PersonaSkinId.memoryCollectors` — `disposableFilmStamp`):
/// Disposable film camera HUD overlay:
/// - Cream pill above the frame: `CUỘN PHIM n/N` / `FILM ROLL n/N` (`n` =
///   check-in count, `N` = `journey.durationDays`; or `#n` for open-ended
///   journeys).
/// - Bottom-left amber monospace date stamp (`16 OCT '26`) rendered strictly
///   as a UI overlay layer (never burned into the compressed JPEG, preserving
///   FR-C5).
/// - Temperature and location (`15°C DA LAT`) from the AI reference mockup are
///   intentionally omitted because `Journey`/`CheckIn` do not store weather or
///   geolocation (`docs/TASKS.md` §2 & §3 M2).
class DisposableFilmStampHud extends StatelessWidget {
  const DisposableFilmStampHud({
    required this.journey,
    required this.checkInCount,
    required this.date,
    this.viewfinderChild,
    this.bottomBar,
    super.key,
  });

  final Journey journey;
  final int checkInCount;
  final LocalDate date;
  final Widget? viewfinderChild;

  /// The capture screen's own controls (shutter), laid out under the frame.
  final Widget? bottomBar;

  static const List<String> _months = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];

  /// Formats [d] in classic 35mm quartz date-back style: `16 OCT '26`.
  static String formatFilmDateStamp(LocalDate d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = _months[(d.month - 1).clamp(0, 11)];
    final yr = (d.year % 100).toString().padLeft(2, '0');
    return "$day $month '$yr";
  }

  @override
  Widget build(BuildContext context) {
    final l10n = MemoryCollectorsL10n.of(context);

    final totalDays = journey.durationDays;
    final usedFrames = checkInCount.clamp(0, totalDays ?? 9999);
    final rollLabel = totalDays != null
        ? l10n.memory_collectors_filmRollBounded(usedFrames, totalDays)
        : l10n.memory_collectors_filmRollOpen(usedFrames);

    final stampText = formatFilmDateStamp(date);

    return ColoredBox(
      // Camera/media surfaces are always dark, whatever the app theme.
      color: PersonaPalette.filmCameraBackground,
      child: Column(
        children: [
          const SizedBox(height: 12),
          // FILM ROLL n/N sits above the frame, like the roll counter on a
          // disposable camera.
          Container(
            key: const ValueKey('m2-film-roll-pill'),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: PersonaPalette.filmPaper,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              rollLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: PersonaPalette.filmPaperInk,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                height: 1.3,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const ColoredBox(color: PersonaPalette.filmBlack),
                    ?viewfinderChild,
                    // Film vignette and a soft dark edge, as if the frame
                    // were seen through a cheap single-use lens.
                    const IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            radius: 1.05,
                            colors: [
                              PersonaPalette.transparent,
                              PersonaPalette.vignetteEdge,
                            ],
                            stops: [0.6, 1],
                          ),
                        ),
                      ),
                    ),
                    IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: PersonaPalette.filmRim,
                            width: 4,
                          ),
                        ),
                      ),
                    ),
                    // Amber quartz date stamp: a UI overlay, never burned into
                    // the compressed JPEG (FR-C5).
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: IgnorePointer(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                          child: Text(
                            stampText,
                            key: const ValueKey('m2-amber-date-stamp'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: PersonaPalette.filmAmber,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              fontFamily: PersonaPalette.stampFontFamily,
                              height: 1.3,
                              letterSpacing: 1.6,
                              shadows: [
                                Shadow(
                                  color: PersonaPalette.filmAmberGlow,
                                  blurRadius: 8,
                                ),
                                Shadow(
                                  color: PersonaPalette.stampShadow,
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (bottomBar != null) bottomBar! else const SizedBox(height: 16),
        ],
      ),
    );
  }
}
