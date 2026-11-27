import 'package:flutter/material.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../personas/persona_contract.dart';
import '../../../shared/journey_style_name.dart';
import '../../../ui/ui.dart';

/// The V1.0 journey style (paper, ink, accent) of a persona skin. The six
/// skins map 1:1, in order, to the first six entries of [uiJourneyStyles].
UiJourneyStyle journeyStyleFor(PersonaSkinId skin) =>
    uiJourneyStyles[skin.index];

/// Skin of [journey] (Couple Rituals is `custom` + heart / 2-person group).
PersonaSkinId skinOfJourney(Journey journey) => personaSkinOf(journey);

UiJourneyStyle styleOfJourney(Journey journey) =>
    journeyStyleFor(skinOfJourney(journey));

/// Colors of a screen painted in a journey style. Light mode takes the
/// style's paper and ink; dark mode shares one near-black base for every
/// style and keeps only the accent (V1.0 `.appearance-dark` overrides).
@immutable
class JourneyPalette {
  const JourneyPalette({
    required this.paper,
    required this.ink,
    required this.accent,
    required this.accentText,
    required this.onAccent,
    required this.outline,
    required this.name,
  });

  factory JourneyPalette.of(BuildContext context, UiJourneyStyle style) {
    final dark = context.ui.isDark;
    // Inside a UiSkinScope the chosen variant (and its dark accent) wins.
    final scoped = UiSkinScope.maybeOf(context) != null;
    final paper = dark ? context.ui.bg : style.paper;
    return JourneyPalette(
      paper: paper,
      ink: dark ? context.ui.ink : style.ink,
      accent: scoped ? context.ui.accent : style.accent,
      accentText: scoped
          ? context.ui.accentText
          : OurneyUi.accentTextFor(
              style.accent,
              bg: paper,
              surface: context.ui.surface,
              brightness: context.ui.brightness,
            ),
      onAccent: scoped ? context.ui.onAccent : style.onAccent,
      outline: dark ? context.ui.outline : style.ink,
      name: journeyStyleName(context, style),
    );
  }

  final Color paper;
  final Color ink;
  final Color accent;
  final Color accentText;
  final Color onAccent;

  /// Border color of cards on [paper]: [ink] in light, the mid-tone dark
  /// outline in dark so cream ink never frames every card.
  final Color outline;
  final String name;

  Color inkAt(double opacity) => ink.withValues(alpha: opacity);
}
