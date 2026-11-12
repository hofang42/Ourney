import 'package:flutter/material.dart';

import '../../ui/ui.dart';

/// Illustrations of the three onboarding pages (`.onboarding-art art-1..3`).
/// The prototype uses stock photos; here the "photos" are tinted tiles with a
/// vector glyph so the app ships with no remote or bundled imagery.

const double _deg = 3.1415926535 / 180;

/// Page 1: a tilted 3x2 contact sheet of polaroid-bordered tiles.
class OnboardingArtMemories extends StatelessWidget {
  const OnboardingArtMemories({super.key});

  static const _tiles = [
    (Icons.menu_book_outlined, 5),
    (Icons.edit_note_rounded, 1),
    (Icons.map_outlined, 2),
    (Icons.restaurant_outlined, 3),
    (Icons.directions_run_rounded, 4),
    (Icons.home_outlined, 7),
  ];

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return ExcludeSemantics(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Transform.rotate(
          angle: -4 * _deg,
          child: SizedBox(
            width: 3 * 104 + 16,
            height: 2 * 136 + 8,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < _tiles.length; i++)
                  Transform.translate(
                    offset: Offset(0, (i - 2) * 3.0),
                    child: Container(
                      width: 104,
                      height: 136,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.white, width: 6),
                        boxShadow: [
                          BoxShadow(
                            color: ui.shadow,
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              uiJourneyStyles[_tiles[i].$2].paper,
                              uiJourneyStyles[_tiles[i].$2].accent.withValues(
                                alpha: 0.55,
                              ),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            _tiles[i].$1,
                            size: 34,
                            color: uiJourneyStyles[_tiles[i].$2].ink,
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
    );
  }
}

/// Page 2: the ten journey styles fanned out like a hand of cards.
class OnboardingArtStyles extends StatelessWidget {
  const OnboardingArtStyles({super.key});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: 320,
          height: 230,
          child: Stack(
            alignment: Alignment.center,
            children: [
              for (var i = 0; i < uiJourneyStyles.length; i++)
                Transform.translate(
                  offset: Offset((i - 4.5) * 5, 0),
                  child: Transform.rotate(
                    angle: (i - 4.5) * 4 * _deg,
                    child: Container(
                      width: 205,
                      height: 112,
                      padding: const EdgeInsets.all(14),
                      alignment: Alignment.topLeft,
                      decoration: BoxDecoration(
                        color: uiJourneyStyles[i].paper,
                        border: Border(
                          top: BorderSide(
                            color: uiJourneyStyles[i].accent,
                            width: 10,
                          ),
                          left: const BorderSide(color: Color(0xFF111114)),
                          right: const BorderSide(color: Color(0xFF111114)),
                          bottom: const BorderSide(color: Color(0xFF111114)),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1A111114),
                            blurRadius: 24,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Text(
                        uiJourneyStyles[i].name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: UiText.display(
                          size: 15,
                          height: 1.3,
                          color: const Color(0xFF111114),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Page 3: a recap card and a story sticker, "worth sharing".
class OnboardingArtRecap extends StatelessWidget {
  const OnboardingArtRecap({
    required this.title,
    required this.subtitle,
    required this.shareLabel,
    super.key,
  });

  final String title;
  final String subtitle;
  final String shareLabel;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return ExcludeSemantics(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: 330,
          height: 360,
          child: Stack(
            children: [
              Positioned(
                left: 36,
                top: 30,
                child: Transform.rotate(
                  angle: -4 * _deg,
                  child: Container(
                    width: 230,
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 18),
                    decoration: BoxDecoration(
                      color: ui.surface,
                      boxShadow: [
                        BoxShadow(
                          color: ui.shadow,
                          blurRadius: 40,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 245,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                uiJourneyStyles[5].paper,
                                uiJourneyStyles[5].accent.withValues(
                                  alpha: 0.6,
                                ),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.menu_book_outlined,
                              size: 54,
                              color: uiJourneyStyles[5].ink,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: UiText.display(
                            size: 20,
                            height: 1.3,
                            color: ui.ink,
                          ),
                        ),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: UiText.body(
                            size: 13,
                            height: 1.4,
                            color: ui.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 4,
                bottom: 24,
                child: Transform.rotate(
                  angle: 7 * _deg,
                  child: Container(
                    width: 126,
                    height: 90,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ui.brand,
                      boxShadow: [
                        BoxShadow(
                          color: ui.shadow,
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(
                          Icons.ios_share_rounded,
                          size: 22,
                          color: ui.onBrand,
                        ),
                        Text(
                          shareLabel,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: UiText.body(
                            size: 13,
                            weight: FontWeight.w700,
                            height: 1.3,
                            color: ui.onBrand,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
