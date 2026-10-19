import 'package:flutter/material.dart';

/// Colours that do **not** come from [OurneyPersonaTheme] because they belong
/// to an illustration or to a camera/media surface, which stays the same in
/// light and dark (`CLAUDE.md` §1.2, `OurneyColors.cameraBg`).
///
/// Everything that must follow the theme (surfaces, ink, accents, borders)
/// reads `OurneyPersonaTheme.of(context)` instead, so keep this class small:
/// adding a colour here means it will not change with the theme.
abstract final class PersonaPalette {
  // --- Illustration ---------------------------------------------------------

  /// Trophy at the end of the S1 road.
  static const Color trophyGold = Color(0xFFF6B21A);

  // --- Camera / media surfaces (always dark) --------------------------------

  /// Darkening at the top and bottom edge of a camera preview so overlays stay
  /// legible on bright scenes.
  static const Color scrimTop = Color(0x66000000);
  static const Color scrimBottom = Color(0x73000000);
  static const Color transparent = Color(0x00000000);

  /// Frosted pill over a camera preview (S2 timestamp).
  static const Color glassFill = Color(0x8C000000);
  static const Color glassStroke = Color(0x2EFFFFFF);
  static const Color onGlass = Color(0xFFFFFFFF);

  // --- Film (Persona 3) -----------------------------------------------------

  /// Unexposed film / contact-sheet base.
  static const Color filmBlack = Color(0xFF141312);

  /// Page behind the M2 viewfinder.
  static const Color filmCameraBackground = Color(0xFF1A1511);

  /// Empty frame while a photo loads.
  static const Color filmFrame = Color(0xFF262320);

  /// Cream roll counter pill and its ink.
  static const Color filmPaper = Color(0xFFF4EFE6);
  static const Color filmPaperInk = Color(0xFF231F1E);

  /// Quartz date-back amber: stamp, frame numbers.
  static const Color filmAmber = Color(0xFFFF9E2C);
  static const Color filmAmberGlow = Color(0x99FF7A00);

  /// Muted copy on the film base.
  static const Color filmMuted = Color(0xFFA8A096);

  /// Soft dark rim around the M2 frame.
  static const Color filmRim = Color(0x991A1511);
  static const Color vignetteEdge = Color(0x66000000);
  static const Color stampShadow = Color(0xAA000000);

  /// Date-back typeface (a fixed-width face, never the body font).
  static const String stampFontFamily = 'monospace';

  // --- Derived colours ------------------------------------------------------

  static const Color _inkOnLight = Color(0xFF1E1B18);

  /// Readable text/icon colour on top of [accent] in either theme: white on a
  /// dark accent (terracotta, purple), dark ink on a light one (amber).
  static Color onAccent(Color accent) =>
      ThemeData.estimateBrightnessForColor(accent) == Brightness.dark
      ? Colors.white
      : _inkOnLight;

  /// Drop shadow under a Polaroid / card: deeper on dark surfaces.
  static Color cardShadow(Brightness brightness, {double lightAlpha = 0.14}) =>
      Colors.black.withValues(
        alpha: brightness == Brightness.dark ? 0.45 : lightAlpha,
      );

  /// Translucent masking tape holding a Polaroid.
  static Color maskingTape(Brightness brightness) =>
      brightness == Brightness.dark
      ? const Color(0xFFD6C7A9).withValues(alpha: 0.42)
      : const Color(0xFFE4D8BE).withValues(alpha: 0.88);
}

/// Layout rules from `CLAUDE.md` §2–3 that every persona screen shares.
abstract final class PersonaLayout {
  /// Minimum touch target (`>= 44pt` iOS HIG, `48dp` Material).
  static const double minTouchTarget = 48;

  /// Primary button height; compact variant is 44.
  static const double primaryButtonHeight = 52;

  /// Widest a single-column feed or card grid may grow (large phones/tablets).
  static const double maxContentWidth = 480;

  /// Horizontal screen padding by width: 16 (< 360), 20 (< 410), 24 above.
  static double horizontalPadding(double width) => width < 360
      ? 16.0
      : width < 410
      ? 20.0
      : 24.0;
}
