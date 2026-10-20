import 'package:flutter/painting.dart';

const Color _readableDark = Color(0xFF1E1B18);
const Color _readableLight = Color(0xFFFFFFFF);

/// WCAG contrast ratio of two opaque colors (1:1 .. 21:1).
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// Text/icon color to draw on top of [background]: white or the dark ink,
/// whichever contrasts more. Persona accents run from deep terracotta to
/// amber, so the choice cannot be fixed per theme.
Color readableOn(Color background) =>
    contrastRatio(_readableLight, background) >=
        contrastRatio(_readableDark, background)
    ? _readableLight
    : _readableDark;

/// [color] with its HSL lightness shifted by [amount] (negative = darker).
Color shiftLightness(Color color, double amount) {
  final hsl = HSLColor.fromColor(color);
  return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
}
