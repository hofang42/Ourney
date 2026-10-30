import 'package:flutter/material.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../ui/ui.dart';

/// The V1.0 journey style (paper, ink, accent) of a persona skin. The six
/// skins map 1:1, in order, to the first six entries of [uiJourneyStyles].
UiJourneyStyle journeyStyleFor(PersonaSkinId skin) =>
    uiJourneyStyles[skin.index];

/// Skin of [journey] (Couple Rituals is `custom` + heart / 2-person group).
PersonaSkinId skinOfJourney(Journey journey) => personaSkinForTemplate(
  journey.templateId,
  kind: journey.kind,
  maxMembers: journey.maxMembers,
  emoji: journey.emoji,
);

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
    required this.onAccent,
    required this.name,
  });

  factory JourneyPalette.of(BuildContext context, UiJourneyStyle style) {
    final dark = context.ui.isDark;
    return JourneyPalette(
      paper: dark ? const Color(0xFF0E0E10) : style.paper,
      ink: dark ? const Color(0xFFF4F4F5) : style.ink,
      accent: style.accent,
      onAccent: style.onAccent,
      name: style.name,
    );
  }

  final Color paper;
  final Color ink;
  final Color accent;
  final Color onAccent;
  final String name;

  Color inkAt(double opacity) => ink.withValues(alpha: opacity);
}
