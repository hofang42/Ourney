import 'package:flutter/material.dart';

/// Font families (bundled in pubspec.yaml).
abstract final class UiFonts {
  static const body = 'BeVietnamPro';
  static const display = 'BricolageGrotesque';

  // V2 skin heading fonts (bundled, OFL).
  static const spaceGrotesk = 'SpaceGrotesk';
  static const fraunces = 'Fraunces';
  static const playfair = 'PlayfairDisplay';
  static const barlowCondensed = 'BarlowCondensed';
  static const mono = 'SpaceMono';

  /// Bundled family for a V2 skin `headingFont` name (StyleGuide spelling).
  static String forHeading(String headingFont) => switch (headingFont) {
    'Fraunces' => fraunces,
    'Playfair Display' => playfair,
    'Barlow Condensed' => barlowCondensed,
    'Space Grotesk' => spaceGrotesk,
    _ => spaceGrotesk,
  };
}

/// Type styles from index.css. Vietnamese needs generous leading, so every
/// style keeps `height` within 1.3-1.5 except oversized numerals.
abstract final class UiText {
  static TextStyle display({
    required double size,
    int weight = 700,
    double height = 1.3,
    double tracking = 0,
    Color? color,
  }) => TextStyle(
    fontFamily: UiFonts.display,
    fontFamilyFallback: const [UiFonts.body],
    fontSize: size,
    fontWeight: FontWeight.values[(weight ~/ 100) - 1],
    fontVariations: [FontVariation('wght', weight.toDouble())],
    height: height,
    letterSpacing: size * tracking,
    color: color,
  );

  /// A V2 skin heading (`--heading-font`): the skin's family with Be Vietnam
  /// Pro as the diacritics fallback, variable weight where the font has one.
  static TextStyle heading({
    required String font,
    required double size,
    int weight = 600,
    double height = 1.3,
    double tracking = 0,
    Color? color,
  }) {
    final family = UiFonts.forHeading(font);
    final variable = family != UiFonts.barlowCondensed;
    return TextStyle(
      fontFamily: family,
      fontFamilyFallback: const [UiFonts.body],
      fontSize: size,
      fontWeight: FontWeight.values[((weight ~/ 100) - 1).clamp(0, 8)],
      fontVariations: variable
          ? [FontVariation('wght', weight.toDouble())]
          : null,
      height: height,
      letterSpacing: size * tracking,
      color: color,
    );
  }

  static TextStyle body({
    double size = 15,
    FontWeight weight = FontWeight.w400,
    double height = 1.4,
    double tracking = 0,
    Color? color,
  }) => TextStyle(
    fontFamily: UiFonts.body,
    fontSize: size,
    fontWeight: weight,
    height: height,
    letterSpacing: tracking == 0 ? null : size * tracking,
    color: color,
  );

  /// `h1`: 30 / 700 / -0.04em.
  static TextStyle h1({Color? color, double size = 30}) =>
      display(size: size, height: 1.3, tracking: -0.04, color: color);

  /// `h2`: 22 / 1.3 / 700 / -0.025em.
  static TextStyle h2({Color? color, double size = 22}) =>
      display(size: size, height: 1.3, tracking: -0.025, color: color);

  /// `.eyebrow`: 12 / 1.4 / 700 / 0.12em.
  static TextStyle eyebrow({Color? color}) =>
      body(size: 12, weight: FontWeight.w700, tracking: 0.12, color: color);

  /// `.muted`: 15 / 1.5.
  static TextStyle muted({Color? color, double size = 15}) =>
      body(size: size, height: 1.5, color: color);

  /// Buttons: 15 / 700.
  static TextStyle button({Color? color}) =>
      body(size: 15, weight: FontWeight.w700, height: 1.3, color: color);

  /// `.field-label`: 12 / 700.
  static TextStyle fieldLabel({Color? color}) =>
      body(size: 12, weight: FontWeight.w700, height: 1.4, color: color);

  /// `.wordmark`: Bricolage 800 / -0.07em.
  static TextStyle wordmark({double size = 46, Color? color}) => display(
    size: size,
    weight: 800,
    height: 1.2,
    tracking: -0.07,
    color: color,
  );
}
