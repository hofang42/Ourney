import 'package:flutter/material.dart';

/// Shell design tokens ("Neutral by design", Ourney V1.0 Figma Make).
///
/// The shell is neutral: off-white paper, near-black ink and one brand
/// coral. Journey styles (personas) lead indicators and fills, never body
/// copy.
///
/// Contrast rules (from the design's token review):
/// * [ink] on [bg] 18.03:1, on [surface] 18.85:1.
/// * Brand buttons use [primary] with [onPrimary] ink text (5.41:1); the
///   brand is never a text color.
/// * [inkMuted] on [surfaceSunken] 5.67:1.
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
    required this.surfaceSunken,
    required this.surfaceRaised,
    required this.divider,
    required this.warning,
    required this.flame,
    required this.successSoft,
    required this.onSuccessSoft,
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

  /// Segmented controls, muted chips and disabled buttons.
  final Color surfaceSunken;

  /// Selected segment / pressed surface in dark mode, raised chips.
  final Color surfaceRaised;

  /// Hairlines between list rows (lighter than [border]).
  final Color divider;

  /// "Ends in 3h" style deadline text; readable on [bg].
  final Color warning;

  /// Streak flame fill.
  final Color flame;

  /// "All done" check badge.
  final Color successSoft;
  final Color onSuccessSoft;

  static const light = OurneyColors(
    bg: Color(0xFFFAFAF7),
    surface: Color(0xFFFFFFFF),
    ink: Color(0xFF111114),
    inkMuted: Color(0xFF5E5E66),
    primary: Color(0xFFFF3B5C),
    onPrimary: Color(0xFF111114),
    primaryDeep: Color(0xFFFF3B5C),
    onPrimaryDeep: Color(0xFF111114),
    accent: Color(0xFF6D4BF0),
    streak: Color(0xFFD97706),
    success: Color(0xFF15803D),
    sun: Color(0xFFFFD93D),
    border: Color(0xFFD9D9D3),
    danger: Color(0xFFD92D20),
    surfaceSunken: Color(0xFFF1F1EC),
    surfaceRaised: Color(0xFFFFFFFF),
    divider: Color(0xFFE6E6E0),
    warning: Color(0xFFB33A0A),
    flame: Color(0xFFD97706),
    successSoft: Color(0xFFDCFCE7),
    onSuccessSoft: Color(0xFF166534),
  );

  static const dark = OurneyColors(
    bg: Color(0xFF0B0B0E),
    surface: Color(0xFF16161B),
    ink: Color(0xFFF4F4F6),
    inkMuted: Color(0xFFA1A1AA),
    primary: Color(0xFFFF3B5C),
    onPrimary: Color(0xFF111114),
    primaryDeep: Color(0xFFFF3B5C),
    onPrimaryDeep: Color(0xFF111114),
    accent: Color(0xFF9D85FF),
    streak: Color(0xFFF59E0B),
    success: Color(0xFF4ADE80),
    sun: Color(0xFFFFD93D),
    border: Color(0xFF34343A),
    danger: Color(0xFFFF6B5E),
    surfaceSunken: Color(0xFF101014),
    surfaceRaised: Color(0xFF26262D),
    divider: Color(0xFF26262D),
    warning: Color(0xFFFF9A62),
    flame: Color(0xFFF59E0B),
    successSoft: Color(0xFF14532D),
    onSuccessSoft: Color(0xFFDCFCE7),
  );

  /// Camera/media surfaces are always dark, regardless of theme.
  static const cameraBg = Color(0xFF000000);

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF3B5C), Color(0xFF6D4BF0)],
  );

  static const warmGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF9F1C), Color(0xFFFF3B5C)],
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
    Color? surfaceSunken,
    Color? surfaceRaised,
    Color? divider,
    Color? warning,
    Color? flame,
    Color? successSoft,
    Color? onSuccessSoft,
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
    surfaceSunken: surfaceSunken ?? this.surfaceSunken,
    surfaceRaised: surfaceRaised ?? this.surfaceRaised,
    divider: divider ?? this.divider,
    warning: warning ?? this.warning,
    flame: flame ?? this.flame,
    successSoft: successSoft ?? this.successSoft,
    onSuccessSoft: onSuccessSoft ?? this.onSuccessSoft,
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
      surfaceSunken: l(surfaceSunken, other.surfaceSunken),
      surfaceRaised: l(surfaceRaised, other.surfaceRaised),
      divider: l(divider, other.divider),
      warning: l(warning, other.warning),
      flame: l(flame, other.flame),
      successSoft: l(successSoft, other.successSoft),
      onSuccessSoft: l(onSuccessSoft, other.onSuccessSoft),
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

/// Corner radii. The V1.0 shell is flat and editorial: today/journey cards
/// are square-cornered and outlined, thumbnails 12, menus 16, sheets 28,
/// every button a capsule.
abstract final class OurneyRadii {
  static const double none = 0;
  static const double thumb = 12;
  static const double chip = 12;
  static const double menu = 16;
  static const double card = 20;
  static const double sheet = 28;
  static const double media = 32;
  static const double capsule = 999;
}

/// Fixed component sizes.
abstract final class OurneySizes {
  /// Minimum touch target.
  static const double minTap = 48;

  /// Primary button height (compact: 44).
  static const double button = 52;
  static const double buttonCompact = 44;
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
