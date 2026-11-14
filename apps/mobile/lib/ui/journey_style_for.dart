import 'package:ourney_core/ourney_core.dart';

import 'journey_styles.dart';

/// The Figma journey style (accent, paper, ink) for a persona skin. The six
/// skins map 1:1 onto the first six entries of [uiJourneyStyles].
UiJourneyStyle uiStyleForSkin(PersonaSkinId skin) =>
    uiJourneyStyles[skin.index.clamp(0, uiJourneyStyles.length - 1)];

/// V2 skin id (`quiet`, `squad`, `memory`, `couple`, `flexer`, `minimal`) of a
/// persona skin, for `uiSkinById` (`lib/ui/skins.dart`). Single source of truth:
/// screens must not keep their own mapping.
String uiSkinIdFor(PersonaSkinId skin) => switch (skin) {
  PersonaSkinId.quietTransformer => 'quiet',
  PersonaSkinId.accountabilitySquad => 'squad',
  PersonaSkinId.memoryCollectors => 'memory',
  PersonaSkinId.coupleRituals => 'couple',
  PersonaSkinId.aestheticFlexer => 'flexer',
  PersonaSkinId.minimalistHabit => 'minimal',
};
