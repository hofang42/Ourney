import 'package:flutter/material.dart';

/// Design tokens from docs/03-design-system.md. Colors are defined in code.
///
/// Contrast rules:
/// * White text on [primary] / gradients: bold text >= 18pt only (3:1).
/// * Body text on a coral background: use [primaryDeep] as the fill and
///   [onPrimaryDeep] as the text (>= 4.5:1 in both modes).
/// * [sun] is decorative only; text on it must be [ink] light value.
@immutable
class OurneyColors extends ThemeExtension<OurneyColors> {
  const OurneyColors({
    required this.bg,
    required this.surface,
    required this.ink,
    required this.inkMuted,
    required this.primary,
    required this.onPrimary,
    required this.primaryDeep,
    required this.onPrimaryDeep,
    required this.accent,
    required this.streak,
    required this.success,
    required this.sun,
    required this.border,
    required this.danger,
  });

  final Color bg;
  final Color surface;
  final Color ink;
  final Color inkMuted;
  final Color primary;

  /// Text/icon color on [primary]. White in light mode (bold >= 18pt only),
  /// dark ink in dark mode (the dark coral is too light for white).
  final Color onPrimary;
  final Color primaryDeep;

  /// Text color for use on [primaryDeep]; guaranteed >= 4.5:1.
  final Color onPrimaryDeep;
  final Color accent;
  final Color streak;
  final Color success;
  final Color sun;
  final Color border;
  final Color danger;

  static const light = OurneyColors(
    bg: Color(0xFFFFF8F0),
    surface: Color(0xFFFFFFFF),
    ink: Color(0xFF1A1A22),
    inkMuted: Color(0xFF5C5C6B),
    primary: Color(0xFFFF4D6D),
    onPrimary: Color(0xFFFFFFFF),
    primaryDeep: Color(0xFFE11D48),
    onPrimaryDeep: Color(0xFFFFFFFF),
    accent: Color(0xFF7C5CFF),
    streak: Color(0xFFFF9F1C),
    success: Color(0xFF2BD97C),
    sun: Color(0xFFFFD93D),
    border: Color(0x1F1A1A22),
    danger: Color(0xFFB42318),
  );

  static const dark = OurneyColors(
    bg: Color(0xFF0F0F14),
    surface: Color(0xFF1C1C24),
    ink: Color(0xFFF5F5FA),
    inkMuted: Color(0xFFA8A8B8),
    primary: Color(0xFFFF6B88),
    onPrimary: Color(0xFF0F0F14),
    primaryDeep: Color(0xFFFB7185),
    onPrimaryDeep: Color(0xFF0F0F14),
    accent: Color(0xFF9D85FF),
    streak: Color(0xFFFFB547),
    success: Color(0xFF3DE88C),
    sun: Color(0xFFFFD93D),
    border: Color(0x24F5F5FA),
    danger: Color(0xFFFDA29B),
  );

  /// Camera/media surfaces are always dark, regardless of theme.
  static const cameraBg = Color(0xFF000000);

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF4D6D), Color(0xFF7C5CFF)],
  );

  static const warmGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF9F1C), Color(0xFFFF4D6D)],
  );

  static OurneyColors of(BuildContext context) =>
      Theme.of(context).extension<OurneyColors>() ??
      (Theme.of(context).brightness == Brightness.dark ? dark : light);

  @override
  OurneyColors copyWith({
    Color? bg,
    Color? surface,
    Color? ink,
    Color? inkMuted,
    Color? primary,
    Color? onPrimary,
    Color? primaryDeep,
    Color? onPrimaryDeep,
    Color? accent,
    Color? streak,
    Color? success,
    Color? sun,
    Color? border,
    Color? danger,
  }) => OurneyColors(
    bg: bg ?? this.bg,
    surface: surface ?? this.surface,
    ink: ink ?? this.ink,
    inkMuted: inkMuted ?? this.inkMuted,
    primary: primary ?? this.primary,
    onPrimary: onPrimary ?? this.onPrimary,
    primaryDeep: primaryDeep ?? this.primaryDeep,
    onPrimaryDeep: onPrimaryDeep ?? this.onPrimaryDeep,
    accent: accent ?? this.accent,
    streak: streak ?? this.streak,
    success: success ?? this.success,
    sun: sun ?? this.sun,
    border: border ?? this.border,
    danger: danger ?? this.danger,
  );

  @override
  OurneyColors lerp(ThemeExtension<OurneyColors>? other, double t) {
    if (other is! OurneyColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return OurneyColors(
      bg: l(bg, other.bg),
      surface: l(surface, other.surface),
      ink: l(ink, other.ink),
      inkMuted: l(inkMuted, other.inkMuted),
      primary: l(primary, other.primary),
      onPrimary: l(onPrimary, other.onPrimary),
      primaryDeep: l(primaryDeep, other.primaryDeep),
      onPrimaryDeep: l(onPrimaryDeep, other.onPrimaryDeep),
      accent: l(accent, other.accent),
      streak: l(streak, other.streak),
      success: l(success, other.success),
      sun: l(sun, other.sun),
      border: l(border, other.border),
      danger: l(danger, other.danger),
    );
  }
}

/// Spacing scale 4/8/12/16/24/32 and screen margin 20.
abstract final class OurneySpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double screenMargin = 20;
}

/// Corner radii: chip 12, card 20, sheet 28, media 32, capsule buttons.
abstract final class OurneyRadii {
  static const double chip = 12;
  static const double card = 20;
  static const double sheet = 28;
  static const double media = 32;
  static const double capsule = 999;
}

/// Fixed component sizes.
abstract final class OurneySizes {
  /// Minimum touch target.
  static const double minTap = 44;
  static const double captureButton = 76;
  static const double chunkyEdge = 4;
  static const double chunkySink = 3;
}

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
