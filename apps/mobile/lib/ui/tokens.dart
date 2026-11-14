import 'package:flutter/material.dart';

/// Ourney design tokens. The shell palette is the V2 shell from the Figma
/// Make prototype (`design/ourney-v2-app/src/app/app.css`, light `.system`
/// values and `.mode-dark` overrides); structure and names come from V1.0
/// (`design/figma-v1/`). Journey skins recolor it via `UiSkin.apply`.
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
    required this.accent,
    required this.onDanger,
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

  /// Cards, rows, menus, secondary buttons (`#FFFFFF` / `#1C1B19`).
  final Color surface;

  /// Text inputs and language chip (`#FFFFFF` / `#1C1B19`).
  final Color surfaceInput;

  /// `.segments`, muted tiles, permission icon (`#F6EEDF` / `#262420`).
  final Color fill;

  /// Selected segment (`#FFFFFF` / `#2E2B27`).
  final Color fillSelected;

  final Color ink;
  final Color inkMuted;

  /// `.text-action` (`#3F3A34` / `#D6CFC3`).
  final Color inkSoft;

  final Color border;
  final Color inputBorder;
  final Color divider;
  final Color chevron;

  /// Brand orange `#FF8A3D` (V2). Same in both modes; text on it is [onBrand] ink.
  final Color brand;
  final Color onBrand;

  /// Journey accent (V2 `--skin-accent`): sheet top shadow, progress, nodes.
  /// The neutral shell uses the brand orange; `UiSkin.apply` swaps in the
  /// skin variant's accent while `brand` stays the button fill.
  final Color accent;

  /// Label/icon color on a [danger] fill (destructive buttons).
  final Color onDanger;

  /// Keyboard focus ring (`outline: 3px solid #0284c7`).
  final Color focus;

  /// Green text/icon (`#287747` / `#4ADE80`) and its tinted badge fill.
  final Color success;
  final Color successSoft;

  /// Deadline / locked text (`#B33A0A` / `#FF9A62`).
  final Color warn;

  /// Unread dot, destructive (`#B3261E` / `#FF9C94`).
  final Color danger;

  /// Streak flame (`#D97706` / `#F59E0B`).
  final Color flame;

  final Color grabber;
  final Color scrim;
  final Color dockBg;
  final Color dockBorder;
  final Color permissionIconBg;

  /// Soft translucent shadow for blurred `BoxShadow`s (menus, artwork, share
  /// preview). V2 hard shadows are opaque ink: use `hardShadow()` instead.
  final Color shadow;

  bool get isDark => brightness == Brightness.dark;

  static const light = OurneyUi(
    brightness: Brightness.light,
    bg: Color(0xFFFFF8EE),
    surface: Color(0xFFFFFFFF),
    surfaceInput: Color(0xFFFFFFFF),
    fill: Color(0xFFF6EEDF),
    fillSelected: Color(0xFFFFFFFF),
    ink: Color(0xFF1A1A1A),
    inkMuted: Color(0xFF5A544C),
    inkSoft: Color(0xFF3F3A34),
    border: Color(0xFFDCD2C2),
    inputBorder: Color(0xFF1A1A1A),
    divider: Color(0xFFEADFCC),
    chevron: Color(0xFF8A8378),
    brand: Color(0xFFFF8A3D),
    onBrand: Color(0xFF1A1A1A),
    accent: Color(0xFFFF8A3D),
    onDanger: Color(0xFFFFFFFF),
    focus: Color(0xFF0284C7),
    success: Color(0xFF287747),
    successSoft: Color(0xFFDCFCE7),
    warn: Color(0xFFB33A0A),
    danger: Color(0xFFB3261E),
    flame: Color(0xFFD97706),
    grabber: Color(0xFFD6CCBB),
    scrim: Color(0x88000000),
    dockBg: Color(0xEBFFFFFF),
    dockBorder: Color(0xFF1A1A1A),
    permissionIconBg: Color(0xFFF6EEDF),
    shadow: Color(0x261A1A1A),
  );

  static const dark = OurneyUi(
    brightness: Brightness.dark,
    bg: Color(0xFF121212),
    surface: Color(0xFF1C1B19),
    surfaceInput: Color(0xFF1C1B19),
    fill: Color(0xFF262420),
    fillSelected: Color(0xFF2E2B27),
    ink: Color(0xFFF5F0E6),
    inkMuted: Color(0xFFB8B0A4),
    inkSoft: Color(0xFFD6CFC3),
    border: Color(0xFF3A3733),
    inputBorder: Color(0xFFF5F0E6),
    divider: Color(0xFF2A2825),
    chevron: Color(0xFF8A8378),
    brand: Color(0xFFFF8A3D),
    onBrand: Color(0xFF1A1A1A),
    accent: Color(0xFFFF8A3D),
    onDanger: Color(0xFF1A1A1A),
    focus: Color(0xFF38BDF8),
    success: Color(0xFF4ADE80),
    successSoft: Color(0xFF14532D),
    warn: Color(0xFFFF9A62),
    danger: Color(0xFFFF9C94),
    flame: Color(0xFFF59E0B),
    grabber: Color(0xFF45413B),
    scrim: Color(0x88000000),
    dockBg: Color(0xEB1C1B19),
    dockBorder: Color(0xFFF5F0E6),
    permissionIconBg: Color(0xFF2E2B27),
    shadow: Color(0x66000000),
  );

  static OurneyUi of(BuildContext context) =>
      Theme.of(context).extension<OurneyUi>() ??
      (Theme.of(context).brightness == Brightness.dark ? dark : light);

  @override
  OurneyUi copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceInput,
    Color? fill,
    Color? fillSelected,
    Color? ink,
    Color? inkMuted,
    Color? inkSoft,
    Color? border,
    Color? inputBorder,
    Color? divider,
    Color? brand,
    Color? onBrand,
    Color? grabber,
    Color? dockBg,
    Color? dockBorder,
    Color? permissionIconBg,
    Color? accent,
  }) => OurneyUi(
    brightness: brightness,
    bg: bg ?? this.bg,
    surface: surface ?? this.surface,
    surfaceInput: surfaceInput ?? this.surfaceInput,
    fill: fill ?? this.fill,
    fillSelected: fillSelected ?? this.fillSelected,
    ink: ink ?? this.ink,
    inkMuted: inkMuted ?? this.inkMuted,
    inkSoft: inkSoft ?? this.inkSoft,
    border: border ?? this.border,
    inputBorder: inputBorder ?? this.inputBorder,
    divider: divider ?? this.divider,
    chevron: chevron,
    brand: brand ?? this.brand,
    onBrand: onBrand ?? this.onBrand,
    accent: accent ?? this.accent,
    onDanger: onDanger,
    focus: focus,
    success: success,
    successSoft: successSoft,
    warn: warn,
    danger: danger,
    flame: flame,
    grabber: grabber ?? this.grabber,
    scrim: scrim,
    dockBg: dockBg ?? this.dockBg,
    dockBorder: dockBorder ?? this.dockBorder,
    permissionIconBg: permissionIconBg ?? this.permissionIconBg,
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
      accent: l(accent, other.accent),
      onDanger: l(onDanger, other.onDanger),
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

  /// Disabled / secondary camera glyphs (white at 64%).
  static const muted = Color(0xA3FFFFFF);

  /// V2 camera chip outline (`2px #F5F0E6`) and its hard shadow (`2px 2px 0 #000`).
  static const outline = Color(0xFFF5F0E6);
  static const shadow = Color(0xFF000000);
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

/// V2 "sticker" outline widths (`2px solid var(--ink)`; quiet skin 1.5px).
abstract final class UiBorder {
  static const double standard = 2;
  static const double thin = 1.5;
  static const double hairline = 1;
}

/// V2 hard-offset shadows (`4px 4px 0 ink`). No blur, ever.
abstract final class UiShadow {
  /// Primary button, cards, answer cards.
  static const double large = 4;

  /// Secondary button, chips, shutter, disc.
  static const double small = 3;

  /// Toast, tiny stickers.
  static const double tiny = 2;

  static List<BoxShadow> hard(Color color, [double offset = large]) => [
    BoxShadow(color: color, offset: Offset(offset, offset)),
  ];
}

/// Sticker-language helpers on the active palette.
extension OurneyUiSticker on OurneyUi {
  /// Outline color of buttons, cards and docks (V2 `var(--ink)`).
  Color get outline => ink;

  /// `Border.all(2, ink)`, optionally thinner for the quiet skin.
  Border stickerBorder([double width = UiBorder.standard]) =>
      Border.all(color: outline, width: width);

  /// Hard offset shadow in the ink color (`4px 4px 0 ink`).
  List<BoxShadow> hardShadow([double offset = UiShadow.large]) =>
      UiShadow.hard(outline, offset);
}
