import 'package:flutter/painting.dart';

/// WCAG 2.x contrast ratio of two opaque colors (>= 1). The one helper the
/// kit uses for every contrast decision (label on accent, field border,
/// avatar ink, icon halos).
double uiContrast(Color a, Color b) {
  final x = a.computeLuminance() + 0.05;
  final y = b.computeLuminance() + 0.05;
  return x > y ? x / y : y / x;
}
