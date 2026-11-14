import 'dart:ui' as ui_;

import 'package:flutter/material.dart';

import '../tokens.dart';

/// Liquid-glass surface: frosted backdrop blur + saturation boost, a
/// translucent tint, the V2 2dp outline and a hard sticker shadow.
///
/// V2 uses it for the floating dock (`blur 20 saturate 160`), the flexer skin
/// panels and camera chips. CLAUDE.md: glass always keeps the 2dp outline and
/// hard shadow (the defaults here); the quiet skin's 1.5dp / 2dp exception is
/// passed by the caller. Rules baked in (ui-ux-pro-max "Glassmorphism"):
/// blur 10-20dp, tint 15-30% on photos, text contrast 4.5:1 stays the
/// caller's job (put [UiGlass] over a known background).
///
/// The hard shadow is drawn only outside the shape, so it never shows through
/// the translucent fill. Leave room for it (padding of [hardShadow] dp on the
/// right and bottom).
///
/// Falls back to an opaque [fallback] fill, no blur, when
/// `MediaQuery.highContrast` is on or the caller passes [reduceTransparency].
/// Flutter exposes no OS-level "Reduce Transparency" flag, so the app wires
/// its own Reduce Transparency setting into [reduceTransparency]. Either way
/// text never sits on a blurred photo for people who need clarity.
class UiGlass extends StatelessWidget {
  const UiGlass({
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(UiRadius.menu)),
    this.blur = 20,
    this.saturation = 1.6,
    this.tint,
    this.fallback,
    this.borderColor,
    this.borderWidth = UiBorder.standard,
    this.hardShadow = UiShadow.large,
    this.hardShadowColor,
    this.shadow = const [],
    this.padding,
    this.reduceTransparency = false,
    super.key,
  });

  /// A dark glass chip for always-dark camera chrome: `2px #F5F0E6` outline
  /// and a `2px 2px 0 #000` hard shadow (V2 `.active-journey-chip`).
  const UiGlass.camera({
    required this.child,
    this.borderRadius = const BorderRadius.all(
      Radius.circular(UiRadius.capsule),
    ),
    this.padding,
    this.reduceTransparency = false,
    this.borderWidth = UiBorder.standard,
    this.hardShadow = UiShadow.tiny,
    super.key,
  }) : blur = 16,
       saturation = 1.4,
       tint = const Color(0x66111114),
       fallback = const Color(0xFF111114),
       borderColor = UiCamera.outline,
       hardShadowColor = UiCamera.shadow,
       shadow = const [];

  final Widget child;
  final BorderRadius borderRadius;

  /// Gaussian sigma in dp (10-20 recommended).
  final double blur;

  /// 1 = unchanged; V2 dock uses 1.6.
  final double saturation;

  /// Translucent fill. Defaults to the palette surface at 70%.
  final Color? tint;

  /// Opaque fill when transparency is reduced. Defaults to palette surface.
  final Color? fallback;

  /// Outline color. Defaults to `context.ui.outline`.
  final Color? borderColor;
  final double borderWidth;

  /// Hard offset shadow in dp (0 = none), drawn outside the shape only.
  final double hardShadow;

  /// Hard shadow color. Defaults to `context.ui.outline`.
  final Color? hardShadowColor;

  /// Extra soft shadows (rarely needed; V2 glass uses the hard shadow).
  final List<BoxShadow> shadow;
  final EdgeInsetsGeometry? padding;

  /// App-level "reduce transparency" setting (V2 `reduceTransparency`).
  final bool reduceTransparency;

  /// Row-major 4x5 color matrix that scales saturation by [s].
  @visibleForTesting
  static List<double> saturationMatrix(double s) {
    const r = 0.2126, g = 0.7152, b = 0.0722;
    final inv = 1 - s;
    return <double>[
      r * inv + s, g * inv, b * inv, 0, 0, //
      r * inv, g * inv + s, b * inv, 0, 0, //
      r * inv, g * inv, b * inv + s, 0, 0, //
      0, 0, 0, 1, 0,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final media = MediaQuery.maybeOf(context);
    final solid = reduceTransparency || (media?.highContrast ?? false);
    final fill = solid
        ? (fallback ?? ui.surface)
        : (tint ?? ui.surface.withValues(alpha: 0.7));
    final edge = borderColor ?? ui.outline;

    Widget content = DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: borderRadius,
        border: Border.all(color: edge, width: borderWidth),
      ),
      child: padding == null ? child : Padding(padding: padding!, child: child),
    );

    // Clip both branches so content (photos) never spills past the rounded
    // corners, blurred or opaque.
    if (solid || blur <= 0) {
      content = ClipRRect(borderRadius: borderRadius, child: content);
    } else {
      content = ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ui_.ImageFilter.compose(
            outer: ColorFilter.matrix(saturationMatrix(saturation)),
            inner: ui_.ImageFilter.blur(
              sigmaX: blur,
              sigmaY: blur,
              tileMode: TileMode.clamp,
            ),
          ),
          child: content,
        ),
      );
    }

    if (shadow.isNotEmpty) {
      content = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: shadow,
        ),
        child: content,
      );
    }
    if (hardShadow <= 0) return content;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Hard shadow drawn only outside the shape so it never shows through
        // the translucent glass.
        Positioned.fill(
          child: ClipPath(
            clipper: _OutsideRRect(borderRadius, hardShadow + 2),
            child: Transform.translate(
              offset: Offset(hardShadow, hardShadow),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: hardShadowColor ?? ui.outline,
                  borderRadius: borderRadius,
                ),
              ),
            ),
          ),
        ),
        content,
      ],
    );
  }
}

/// Clips to everything outside a rounded rect (plus [bleed] around it).
class _OutsideRRect extends CustomClipper<Path> {
  const _OutsideRRect(this.radius, this.bleed);

  final BorderRadius radius;
  final double bleed;

  @override
  Path getClip(Size size) => Path()
    ..fillType = PathFillType.evenOdd
    ..addRect(
      Rect.fromLTWH(
        -bleed,
        -bleed,
        size.width + bleed * 2,
        size.height + bleed * 2,
      ),
    )
    ..addRRect(radius.toRRect(Offset.zero & size));

  @override
  bool shouldReclip(_OutsideRRect old) =>
      old.radius != radius || old.bleed != bleed;
}
