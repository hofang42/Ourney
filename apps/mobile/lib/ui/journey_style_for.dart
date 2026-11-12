import 'package:ourney_core/ourney_core.dart';

import 'journey_styles.dart';

/// The Figma journey style (accent, paper, ink) for a persona skin. The six
/// skins map 1:1 onto the first six entries of [uiJourneyStyles].
UiJourneyStyle uiStyleForSkin(PersonaSkinId skin) =>
    uiJourneyStyles[skin.index.clamp(0, uiJourneyStyles.length - 1)];
