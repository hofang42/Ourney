import 'package:flutter/material.dart';

/// Animation durations and curves (docs/03 "Chuyen dong").
abstract final class OurneyDurations {
  static const tap = Duration(milliseconds: 120);
  static const flash = Duration(milliseconds: 100);
  static const navigation = Duration(milliseconds: 400);
  static const stamp = Duration(milliseconds: 600);
  static const reducedFade = Duration(milliseconds: 200);
  static const confetti = Duration(milliseconds: 1800);
  static const flame = Duration(milliseconds: 900);

  /// Colors morph when the active journey changes persona (docs/06 §1 Q1).
  static const personaTheme = Duration(milliseconds: 320);

  /// Persona layouts cross-fade when the active journey changes persona.
  static const personaSwitch = Duration(milliseconds: 260);
}

abstract final class OurneyCurves {
  static const tap = Curves.easeOut;
  static const emphasized = Curves.easeOutBack;

  /// Stamp overshoot peak scale.
  static const double stampOvershoot = 1.15;
}
