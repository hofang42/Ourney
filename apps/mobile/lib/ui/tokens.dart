import 'package:flutter/material.dart';

import 'contrast.dart';
export 'motion.dart';

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
    required this.fieldBorder,
    required this.divider,
    required this.chevron,
    required this.brand,
    required this.onBrand,
    this.brandText = const Color(0xFFB4470F),
    required this.onAccent,
    required this.accent,
    this.accentText = const Color(0xFFB4470F),
    this.switchThumb = const Color(0xFF1A1A1A),
    required this.onDanger,
    required this.focus,
    required this.success,
    required this.successSoft,
    required this.warn,
    this.timeCue = const Color(0xFF8A4300),
    required this.danger,
    required this.flame,
    required this.grabber,
    required this.scrim,
    required this.dockBg,
    required this.dockBorder,
    required this.permissionIconBg,
    required this.shadow,
    required this.outline,
    required this.hardShadowColor,
    required this.sheet,
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

  /// Rest outline of text fields, areas, search pills and code boxes. Unlike
  /// [border] (hairline dividers and cards) it reaches 3:1 against the field
  /// fill ([fill]) so the control is perceivable (WCAG 1.4.11).
  final Color fieldBorder;
  final Color divider;
  final Color chevron;

  /// Brand orange `#FF8A3D` (V2). Same in both modes; text on it is [onBrand] ink.
  final Color brand;
  final Color onBrand;

  /// Text-safe orange (`#B4470F` light / `#FFC39B` dark, >= 4.5:1 on paper and
  /// card surfaces) when the brand orange is used for small text or flat icons.
  final Color brandText;

  /// Label / glyph color on an [accent] fill (selected chips, badges). Picked
  /// per accent so it reaches 4.5:1 in both modes (see [onAccentFor]).
  final Color onAccent;

  /// Journey accent (V2 `--skin-accent`): sheet top shadow, progress, nodes.
  /// The neutral shell uses the brand orange; `UiSkin.apply` swaps in the
  /// skin variant's accent while `brand` stays the button fill.
  final Color accent;

  /// Text- and icon-safe counterpart of [accent] that auto-darkens (light) or
  /// auto-lightens (dark) to >= 4.5:1 against both [bg] and [surface] (WCAG
  /// 1.4.3). Fills keep the bright [accent].
  final Color accentText;

  /// Active switch thumb color on a [brand] track (`#1B1916` in dark mode or
  /// [ink] in light mode when >= 3:1 on [brand], else [onBrand]).
  final Color switchThumb;

  /// Label/icon color on a [danger] fill (destructive buttons).
  final Color onDanger;

  /// Keyboard focus ring (`outline: 3px solid #0284c7`).
  final Color focus;

  /// Green text/icon (`#287747` / `#4ADE80`) and its tinted badge fill.
  final Color success;
  final Color successSoft;

  /// Deadline / locked text (`#B33A0A` / `#FF9A62`).
  final Color warn;

  /// Calm evening / time-window cue (`#8A4300` / `#F2A93B`).
  final Color timeCue;

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

  /// Sticker border of cards, buttons, dock and inputs. Light: ink (V2
  /// `var(--ink)`). Dark: a mid tone so cream does not glow (3:1+ on bg).
  final Color outline;

  /// Opaque hard-offset shadow color. Light: ink. Dark: darker than bg, a
  /// cut-out drop rather than a light slab.
  final Color hardShadowColor;

  /// Bottom sheet and dialog background. Light: bg. Dark: one step above bg
  /// so a sheet reads as lifted over the dimmed page.
  final Color sheet;

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
    fieldBorder: Color(0xFF8A8378),
    divider: Color(0xFFEADFCC),
    chevron: Color(0xFF8A8378),
    brand: Color(0xFFFF8A3D),
    onBrand: Color(0xFF1A1A1A),
    brandText: Color(0xFFB4470F),
    onAccent: Color(0xFF1A1A1A),
    accent: Color(0xFFFF8A3D),
    accentText: Color(0xFFB4470F),
    switchThumb: Color(0xFF1A1A1A),
    onDanger: Color(0xFFFFFFFF),
    focus: Color(0xFF0284C7),
    success: Color(0xFF287747),
    successSoft: Color(0xFFDCFCE7),
    warn: Color(0xFFB33A0A),
    timeCue: Color(0xFF8A4300),
    danger: Color(0xFFB3261E),
    flame: Color(0xFFD97706),
    grabber: Color(0xFFD6CCBB),
    scrim: Color(0x88000000),
    dockBg: Color(0xEBFFFFFF),
    dockBorder: Color(0xFF1A1A1A),
    permissionIconBg: Color(0xFFF6EEDF),
    shadow: Color(0x261A1A1A),
    outline: Color(0xFF1A1A1A),
    hardShadowColor: Color(0xFF1A1A1A),
    sheet: Color(0xFFFFF8EE),
  );

  static const dark = OurneyUi(
    brightness: Brightness.dark,
    bg: Color(0xFF1B1916),
    surface: Color(0xFF25221E),
    surfaceInput: Color(0xFF25221E),
    fill: Color(0xFF2A2722),
    fillSelected: Color(0xFF36322C),
    ink: Color(0xFFECE5D8),
    inkMuted: Color(0xFFB3AA9C),
    inkSoft: Color(0xFFD2C9BA),
    border: Color(0xFF3C3A35),
    fieldBorder: Color(0xFF79756D),
    divider: Color(0xFF312E29),
    chevron: Color(0xFF8A8378),
    brand: Color(0xFFFF8A3D),
    onBrand: Color(0xFF1A1A1A),
    brandText: Color(0xFFFFC39B),
    onAccent: Color(0xFF1A1A1A),
    accent: Color(0xFFFF8A3D),
    accentText: Color(0xFFFFC39B),
    switchThumb: Color(0xFF1B1916),
    onDanger: Color(0xFF1A1A1A),
    focus: Color(0xFF5EC4F0),
    success: Color(0xFF6FCF8E),
    successSoft: Color(0xFF1F3B2A),
    warn: Color(0xFFF2A070),
    timeCue: Color(0xFFF2A93B),
    danger: Color(0xFFF2A097),
    flame: Color(0xFFF2A93B),
    grabber: Color(0xFF5A534A),
    scrim: Color(0x88000000),
    dockBg: Color(0xEB25221E),
    dockBorder: Color(0xFF79756D),
    permissionIconBg: Color(0xFF2A2722),
    shadow: Color(0x66000000),
    outline: Color(0xFF79756D),
    hardShadowColor: Color(0xFF0C0B0A),
    sheet: Color(0xFF211F1B),
  );

  /// The readable label color on [accent]: [preferred] (ink) when it reaches
  /// 4.5:1, else white, else black. Black / white always clear 4.5:1 on one
  /// side of any accent.
  static Color onAccentFor(
    Color accent, {
    Color preferred = const Color(0xFF1A1A1A),
  }) {
    for (final c in [preferred, const Color(0xFFFFFFFF)]) {
      if (uiContrast(c, accent) >= 4.5) return c;
    }
    return const Color(0xFF000000);
  }

  /// Text- and icon-safe counterpart of [accent] that reaches >= 4.5:1 against
  /// both [bg] and [surface] (WCAG 1.4.3). Fills keep the bright [accent].
  static Color accentTextFor(
    Color accent, {
    required Color bg,
    required Color surface,
    required Brightness brightness,
  }) {
    final dark = brightness == Brightness.dark;
    if (accent == const Color(0xFFFF8A3D) ||
        accent == const Color(0xFFEA580C) ||
        accent == const Color(0xFFF07A3A) ||
        (!dark && accent == const Color(0xFFFF9F1C))) {
      return dark ? const Color(0xFFFFC39B) : const Color(0xFFB4470F);
    }
    if (!dark && accent == const Color(0xFF3DE88C)) {
      return const Color(0xFF047857);
    }
    bool passes(Color c) =>
        uiContrast(c, bg) >= 4.5 && uiContrast(c, surface) >= 4.5;
    if (passes(accent)) return accent;
    final hsl = HSLColor.fromColor(accent);
    for (var step = 1; step <= 100; step++) {
      final delta = step * 0.01;
      final nextL = dark
          ? (hsl.lightness + delta).clamp(0.0, 1.0)
          : (hsl.lightness - delta).clamp(0.0, 1.0);
      final candidate = hsl.withLightness(nextL).toColor();
      if (passes(candidate)) return candidate;
    }
    return dark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
  }

  /// Active switch thumb color on a [brand] track: `#1B1916` in dark mode (or
  /// [ink] in light mode) when it reaches 3:1 on [brand], falling back to
  /// [onBrand] on dark button fills (WCAG 1.4.11).
  static Color switchThumbFor({
    required Brightness brightness,
    required Color brand,
    required Color ink,
    required Color onBrand,
  }) {
    final preferred = brightness == Brightness.dark
        ? const Color(0xFF1B1916)
        : ink;
    return uiContrast(preferred, brand) >= 3.0 ? preferred : onBrand;
  }

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
    Color? fieldBorder,
    Color? divider,
    Color? brand,
    Color? onBrand,
    Color? brandText,
    Color? onAccent,
    Color? grabber,
    Color? dockBg,
    Color? dockBorder,
    Color? permissionIconBg,
    Color? accent,
    Color? accentText,
    Color? switchThumb,
    Color? outline,
    Color? hardShadowColor,
    Color? sheet,
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
    fieldBorder: fieldBorder ?? this.fieldBorder,
    divider: divider ?? this.divider,
    chevron: chevron,
    brand: brand ?? this.brand,
    onBrand: onBrand ?? this.onBrand,
    brandText: brandText ?? this.brandText,
    onAccent: onAccent ?? this.onAccent,
    accent: accent ?? this.accent,
    accentText: accentText ?? this.accentText,
    switchThumb: switchThumb ?? this.switchThumb,
    onDanger: onDanger,
    focus: focus,
    success: success,
    successSoft: successSoft,
    warn: warn,
    timeCue: timeCue,
    danger: danger,
    flame: flame,
    grabber: grabber ?? this.grabber,
    scrim: scrim,
    dockBg: dockBg ?? this.dockBg,
    dockBorder: dockBorder ?? this.dockBorder,
    permissionIconBg: permissionIconBg ?? this.permissionIconBg,
    shadow: shadow,
    outline: outline ?? this.outline,
    hardShadowColor: hardShadowColor ?? this.hardShadowColor,
    sheet: sheet ?? this.sheet,
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
      fieldBorder: l(fieldBorder, other.fieldBorder),
      divider: l(divider, other.divider),
      chevron: l(chevron, other.chevron),
      brand: l(brand, other.brand),
      onBrand: l(onBrand, other.onBrand),
      brandText: l(brandText, other.brandText),
      onAccent: l(onAccent, other.onAccent),
      accent: l(accent, other.accent),
      accentText: l(accentText, other.accentText),
      switchThumb: l(switchThumb, other.switchThumb),
      onDanger: l(onDanger, other.onDanger),
      focus: l(focus, other.focus),
      success: l(success, other.success),
      successSoft: l(successSoft, other.successSoft),
      warn: l(warn, other.warn),
      timeCue: l(timeCue, other.timeCue),
      danger: l(danger, other.danger),
      flame: l(flame, other.flame),
      grabber: l(grabber, other.grabber),
      scrim: l(scrim, other.scrim),
      dockBg: l(dockBg, other.dockBg),
      dockBorder: l(dockBorder, other.dockBorder),
      permissionIconBg: l(permissionIconBg, other.permissionIconBg),
      shadow: l(shadow, other.shadow),
      outline: l(outline, other.outline),
      hardShadowColor: l(hardShadowColor, other.hardShadowColor),
      sheet: l(sheet, other.sheet),
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
  static const ink = Color(0xFFF5F0E6);

  /// Text and glyphs drawn over a photo or scrim on a screen that follows the
  /// app theme: always white, never the cream camera ink.
  static const onPhoto = Color(0xFFFFFFFF);

  /// Disabled / secondary camera glyphs (white at 64%).
  static const muted = Color(0xA3F5F0E6);

  /// V2 camera chip outline (`2px #F5F0E6`) and its hard shadow (`2px 2px 0 #000`).
  static const outline = Color(0xFFF5F0E6);
  static const shadow = Color(0xFF000000);
}

/// Radii used across index.css.
abstract final class UiRadius {
  static const double input = 16;

  /// Text inputs and text areas (kit fields).
  static const double field = 16;
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

/// Unified duration tokens for Ourney V2.
/// Always resolve via [UiMotion.of] (or check [UiMotion.reduced]) so
/// `MediaQuery.disableAnimations` collapses spatial motion automatically.
abstract final class UiMotion {
  static const Duration instant = Duration.zero;

  /// Ultra-fast micro-feedback (shutter flash attack, hold-to-reveal snap).
  static const Duration micro = Duration(milliseconds: 90);

  /// Soft Neo-Brutalism tactile press (`translate(offset, offset)`).
  static const Duration press = Duration(milliseconds: 110);

  /// Reduced-motion gentle opacity crossfade when state change needs bridging.
  static const Duration reducedFade = Duration(milliseconds: 150);

  /// High-frequency UI switches: tab content fade, Ghost toggle, toast exit.
  static const Duration fast = Duration(milliseconds: 160);

  /// Standard popovers, menus, dock glyph bounce, skeleton->content crossfade.
  static const Duration normal = Duration(milliseconds: 200);

  /// Step flows (Onboarding Quiz, Create Flow), AnimatedSize, Segmented pill.
  static const Duration medium = Duration(milliseconds: 220);

  /// Bottom sheet / modal entrance (`UiCurves.drawer`).
  static const Duration sheetEnter = Duration(milliseconds: 260);

  /// Bottom sheet / modal / page reverse exit (~73% of enter).
  static const Duration sheetExit = Duration(milliseconds: 190);

  /// Legacy alias kept so existing `UiMotion.sheet` callers stay clean.
  static const Duration sheet = sheetEnter;

  /// Floating dock selection capsule slide (`UiCurves.dockOvershoot`).
  static const Duration dockPill = Duration(milliseconds: 280);

  /// Skin palette morph (`MaterialApp.themeAnimationDuration` & `UiSkinScope`)
  /// and standard `CustomTransitionPage` forward push.
  static const Duration theme = Duration(milliseconds: 320);
  static const Duration page = Duration(milliseconds: 320);

  /// Rare-tier celebration beats (streak digit roll, rubber stamp, trophy rise).
  static const Duration countRoll = Duration(milliseconds: 520);
  static const Duration stamp = Duration(milliseconds: 540);
  static const Duration celebration = Duration(milliseconds: 700);

  /// Analog `memory` Polaroid chemical develop (`app.css:8440`).
  static const Duration develop = Duration(milliseconds: 1100);

  /// Milestone sticker confetti lifetime (Days 7 / 14 / 21 / 30 / Finish).
  static const Duration confetti = Duration(milliseconds: 1600);

  /// Scale factor ONLY for shadowless ghost/chromeless icon buttons.
  /// Bordered sticker surfaces (`shadowOffset > 0`) NEVER scale down.
  static const double pressScale = 0.96;

  /// Minimum initial scale for popover/card entrances (`never scale(0)`).
  static const double popMinScale = 0.95;

  /// True when the OS / user enabled Reduce Motion / Disable Animations
  /// (Android `MediaQuery.disableAnimations` or iOS
  /// `PlatformDispatcher.accessibilityFeatures.reduceMotion`).
  static bool reduced(BuildContext context) =>
      (MediaQuery.maybeDisableAnimationsOf(context) ?? false) ||
      (View.maybeOf(context)
              ?.platformDispatcher
              .accessibilityFeatures
              .reduceMotion ??
          WidgetsBinding
              .instance
              .platformDispatcher
              .accessibilityFeatures
              .reduceMotion);

  /// Returns [Duration.zero] when Reduce Motion is enabled, otherwise [d].
  static Duration of(BuildContext context, Duration d) =>
      reduced(context) ? Duration.zero : d;

  /// Returns [reducedFade] (`150ms`) under Reduce Motion when an opacity-only
  /// bridge aids comprehension, or [d] normally.
  static Duration fadeOf(BuildContext context, Duration d) =>
      reduced(context) ? reducedFade : d;
}

/// Authoritative cubic-bezier curves (Emil Kowalski + V2 CSS + Material 3).
/// Never use `Curves.easeIn` on entrances or invent ad-hoc `Cubic(...)` inline.
abstract final class UiCurves {
  /// Strong UI entrance/exit curve (`--ease-out: cubic-bezier(0.23, 1, 0.32, 1)`).
  static const Curve easeOutStrong = Cubic(0.23, 1.0, 0.32, 1.0);

  /// Strong on-screen morph / pill slide (`--ease-in-out: cubic-bezier(0.77, 0, 0.175, 1)`).
  static const Curve easeInOutStrong = Cubic(0.77, 0.0, 0.175, 1.0);

  /// iOS / Vaul bottom-sheet & drawer curve (`cubic-bezier(0.32, 0.72, 0, 1)`).
  static const Curve drawer = Cubic(0.32, 0.72, 0.0, 1.0);

  /// V2 dock pill & active glyph micro-overshoot (`app.css:15742`).
  static const Curve dockOvershoot = Cubic(0.20, 0.90, 0.30, 1.20);

  /// V2 trophy rise & stamp settle (`app.css:7509`, `cubic-bezier(0.2, 0.8, 0.2, 1)`).
  static const Curve stampDecel = Cubic(0.20, 0.80, 0.20, 1.00);

  /// Material 3 Emphasized Decelerate (shared-element Hero & page push).
  static const Curve m3Decelerate = Cubic(0.05, 0.70, 0.10, 1.00);

  /// Material 3 Emphasized Accelerate (exits).
  static const Curve m3Accelerate = Cubic(0.30, 0.00, 0.80, 0.15);
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
  /// `Border.all(2, ink)`, optionally thinner for the quiet skin.
  Border stickerBorder([double width = UiBorder.standard]) =>
      Border.all(color: outline, width: width);

  /// Hard offset shadow (`4px 4px 0`) in [hardShadowColor]: ink in light,
  /// darker than bg in dark.
  List<BoxShadow> hardShadow([double offset = UiShadow.large]) =>
      UiShadow.hard(hardShadowColor, offset);
}
