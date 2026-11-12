import 'package:flutter/material.dart';

/// Ourney V1.0 design tokens, transcribed from the Figma Make prototype
/// (`design/figma-v1/index.css`). The CSS has no custom properties for the
/// shell: light values are the literals in the base rules and dark values are
/// the `.appearance-dark` overrides. Both are named here once.
///
/// Read colors with `context.ui` (see [OurneyUiContext]); never hardcode a
/// light-only or dark-only color in a widget.
@immutable
class OurneyUi extends ThemeExtension<OurneyUi> {
  const OurneyUi({
    required this.brightness,
    required this.bg,
    required this.surface,
    required this.surfaceInput,
    required this.fill,
    required this.fillSelected,
    required this.ink,
    required this.inkMuted,
    required this.inkSoft,
    required this.border,
    required this.inputBorder,
    required this.divider,
    required this.chevron,
    required this.brand,
    required this.onBrand,
    required this.focus,
    required this.success,
    required this.successSoft,
    required this.warn,
    required this.danger,
    required this.flame,
    required this.grabber,
    required this.scrim,
    required this.dockBg,
    required this.dockBorder,
    required this.permissionIconBg,
    required this.shadow,
  });

  final Brightness brightness;

  /// `.shell-screen` / `.bottom-sheet` background.
  final Color bg;

  /// Cards, rows, menus, secondary buttons (`white` / `#16161b`).
  final Color surface;

  /// Text inputs and language chip (`white` / `#18181b`).
  final Color surfaceInput;

  /// `.segments`, muted tiles, permission icon (`#f1f1ec` / `#101014`).
  final Color fill;

  /// Selected segment (`white` / `#26262d`).
  final Color fillSelected;

  final Color ink;
  final Color inkMuted;

  /// `.text-action` (`#45454c` / `#d4d4d8`).
  final Color inkSoft;

  final Color border;
  final Color inputBorder;
  final Color divider;
  final Color chevron;

  /// Brand coral. Same in both modes; text on it is [onBrand] ink.
  final Color brand;
  final Color onBrand;

  /// Keyboard focus ring (`outline: 3px solid #0284c7`).
  final Color focus;

  /// Green text/icon (`#166534` / `#4ade80`) and its tinted badge fill.
  final Color success;
  final Color successSoft;

  /// Deadline / locked text (`#b33a0a` / `#ff9a62`).
  final Color warn;

  /// Unread dot, destructive (`#d92d20`).
  final Color danger;

  /// Streak flame (`#d97706`).
  final Color flame;

  final Color grabber;
  final Color scrim;
  final Color dockBg;
  final Color dockBorder;
  final Color permissionIconBg;
  final Color shadow;

  bool get isDark => brightness == Brightness.dark;

  static const light = OurneyUi(
    brightness: Brightness.light,
    bg: Color(0xFFFAFAF7),
    surface: Color(0xFFFFFFFF),
    surfaceInput: Color(0xFFFFFFFF),
    fill: Color(0xFFF1F1EC),
    fillSelected: Color(0xFFFFFFFF),
    ink: Color(0xFF111114),
    inkMuted: Color(0xFF5E5E66),
    inkSoft: Color(0xFF45454C),
    border: Color(0xFFD9D9D3),
    inputBorder: Color(0xFFCFCFC9),
    divider: Color(0xFFE6E6E0),
    chevron: Color(0xFF8C8C94),
    brand: Color(0xFFFF3B5C),
    onBrand: Color(0xFF111114),
    focus: Color(0xFF0284C7),
    success: Color(0xFF166534),
    successSoft: Color(0xFFDCFCE7),
    warn: Color(0xFFB33A0A),
    danger: Color(0xFFD92D20),
    flame: Color(0xFFD97706),
    grabber: Color(0xFFD1D1CC),
    scrim: Color(0x88000000),
    dockBg: Color(0xEBFFFFFF),
    dockBorder: Color(0xFFE6E6E0),
    permissionIconBg: Color(0xFFF1F1EC),
    shadow: Color(0x26101014),
  );

  static const dark = OurneyUi(
    brightness: Brightness.dark,
    bg: Color(0xFF0B0B0E),
    surface: Color(0xFF16161B),
    surfaceInput: Color(0xFF18181B),
    fill: Color(0xFF101014),
    fillSelected: Color(0xFF26262D),
    ink: Color(0xFFF4F4F6),
    inkMuted: Color(0xFFA1A1AA),
    inkSoft: Color(0xFFD4D4D8),
    border: Color(0xFF34343A),
    inputBorder: Color(0xFF34343A),
    divider: Color(0xFF26262D),
    chevron: Color(0xFF8C8C94),
    brand: Color(0xFFFF3B5C),
    onBrand: Color(0xFF111114),
    focus: Color(0xFF38BDF8),
    success: Color(0xFF4ADE80),
    successSoft: Color(0xFF14532D),
    warn: Color(0xFFFF9A62),
    danger: Color(0xFFFF6B5E),
    flame: Color(0xFFF59E0B),
    grabber: Color(0xFF45454C),
    scrim: Color(0x88000000),
    dockBg: Color(0xEB16161B),
    dockBorder: Color(0xFF26262D),
    permissionIconBg: Color(0xFF26262D),
    shadow: Color(0x66000000),
  );

  static OurneyUi of(BuildContext context) =>
      Theme.of(context).extension<OurneyUi>() ??
      (Theme.of(context).brightness == Brightness.dark ? dark : light);

  @override
  OurneyUi copyWith({Color? brand, Color? onBrand}) => OurneyUi(
    brightness: brightness,
    bg: bg,
    surface: surface,
    surfaceInput: surfaceInput,
    fill: fill,
    fillSelected: fillSelected,
    ink: ink,
    inkMuted: inkMuted,
    inkSoft: inkSoft,
    border: border,
    inputBorder: inputBorder,
    divider: divider,
    chevron: chevron,
    brand: brand ?? this.brand,
    onBrand: onBrand ?? this.onBrand,
    focus: focus,
    success: success,
    successSoft: successSoft,
    warn: warn,
    danger: danger,
    flame: flame,
    grabber: grabber,
    scrim: scrim,
    dockBg: dockBg,
    dockBorder: dockBorder,
    permissionIconBg: permissionIconBg,
    shadow: shadow,
  );

  @override
  OurneyUi lerp(ThemeExtension<OurneyUi>? other, double t) {
    if (other is! OurneyUi) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return OurneyUi(
      brightness: t < 0.5 ? brightness : other.brightness,
      bg: l(bg, other.bg),
      surface: l(surface, other.surface),
      surfaceInput: l(surfaceInput, other.surfaceInput),
      fill: l(fill, other.fill),
      fillSelected: l(fillSelected, other.fillSelected),
      ink: l(ink, other.ink),
      inkMuted: l(inkMuted, other.inkMuted),
      inkSoft: l(inkSoft, other.inkSoft),
      border: l(border, other.border),
      inputBorder: l(inputBorder, other.inputBorder),
      divider: l(divider, other.divider),
      chevron: l(chevron, other.chevron),
      brand: l(brand, other.brand),
      onBrand: l(onBrand, other.onBrand),
      focus: l(focus, other.focus),
      success: l(success, other.success),
      successSoft: l(successSoft, other.successSoft),
      warn: l(warn, other.warn),
      danger: l(danger, other.danger),
      flame: l(flame, other.flame),
      grabber: l(grabber, other.grabber),
      scrim: l(scrim, other.scrim),
      dockBg: l(dockBg, other.dockBg),
      dockBorder: l(dockBorder, other.dockBorder),
      permissionIconBg: l(permissionIconBg, other.permissionIconBg),
      shadow: l(shadow, other.shadow),
    );
  }
}

extension OurneyUiContext on BuildContext {
  /// The Ourney V1.0 palette for the current brightness.
  OurneyUi get ui => OurneyUi.of(this);
}

/// Always-dark camera chrome (`.camera-screen`, `.camera-dock`).
abstract final class UiCamera {
  static const bg = Color(0xFF07070A);
  static const dock = Color(0xEB111114);
  static const dockBorder = Color(0x29FFFFFF);
  static const ink = Color(0xFFFFFFFF);
}

/// Radii used across index.css.
abstract final class UiRadius {
  static const double input = 12;
  static const double otp = 10;
  static const double thumb = 12;
  static const double menu = 16;
  static const double card = 20;
  static const double sheet = 28;
  static const double viewfinder = 32;
  static const double capsule = 999;
}

/// Spacing scale and responsive gutters (CLAUDE.md section 3).
abstract final class UiSpace {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double huge = 32;

  /// Horizontal screen padding for [width] (dp).
  static double gutter(double width) {
    if (width < 360) return 16;
    if (width < 410) return 20;
    return 24;
  }

  /// Max content width: 480 on large phones, 520 on tablets.
  static double maxContent(double width) => width >= 600 ? 520 : 480;
}

/// Fixed sizes.
abstract final class UiSize {
  static const double tap = 48;
  static const double button = 52;
  static const double buttonCompact = 44;
  static const double input = 52;
  static const double otp = 54;
  static const double avatar = 28;
  static const double avatarLarge = 40;
  static const double avatarXL = 88;
  static const double shutter = 76;
  static const double shutterInner = 64;
  static const double snapPillW = 56;
  static const double snapPillH = 40;
  static const double dockMin = 78;
  static const double permissionIcon = 62;
}

/// Motion.
abstract final class UiMotion {
  /// `button:active { transform: scale(.96); transition: 110ms }`.
  static const press = Duration(milliseconds: 110);
  static const pressScale = 0.96;

  /// `@keyframes sheetIn` (280ms ease-out).
  static const sheet = Duration(milliseconds: 280);

  /// Colour transitions between journey styles (320ms).
  static const theme = Duration(milliseconds: 320);

  static Duration of(BuildContext context, Duration d) =>
      (MediaQuery.maybeDisableAnimationsOf(context) ?? false)
      ? Duration.zero
      : d;
}
