import '../../ui/tokens.dart';

/// Legacy animation durations and curves forwarded to [UiMotion] and [UiCurves].
abstract final class OurneyDurations {
  static const tap = UiMotion.press;
  static const flash = UiMotion.micro;
  static const navigation = UiMotion.page;
  static const stamp = UiMotion.stamp;
  static const reducedFade = UiMotion.reducedFade;
  static const confetti = UiMotion.confetti;
  static const flame = UiMotion.celebration;

  /// Colors morph when the active journey changes persona (docs/06 §1 Q1).
  static const personaTheme = UiMotion.theme;

  /// Persona layouts cross-fade when the active journey changes persona.
  static const personaSwitch = UiMotion.sheetEnter;
}

abstract final class OurneyCurves {
  static const tap = UiCurves.easeOutStrong;
  static const emphasized = UiCurves.dockOvershoot;

  /// Stamp overshoot peak scale.
  static const double stampOvershoot = 1.15;
}
