import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:ourney_core/ourney_core.dart';

import 'persona_theme.dart';
import 'tokens.dart';

const String kBodyFont = 'BeVietnamPro';
const String kDisplayFont = 'BricolageGrotesque';

/// Display style on the Bricolage Grotesque variable font (weight axis).
///
/// V1.0 headings are Bricolage 700 with tight tracking (-0.04em at h1,
/// -0.025em at h2); [tracking] is in em.
TextStyle displayStyle({
  required double size,
  int weight = 800,
  Color? color,
  double height = 1.1,
  double tracking = 0,
}) => TextStyle(
  fontFamily: kDisplayFont,
  fontSize: size,
  fontWeight: FontWeight.values[(weight ~/ 100) - 1],
  fontVariations: [FontVariation('wght', weight.toDouble())],
  height: height,
  letterSpacing: size * tracking,
  color: color,
  fontFamilyFallback: const [kBodyFont],
);

/// Section heading ("Your journeys"): Bricolage 700, 18-22pt.
TextStyle headingStyle({double size = 22, Color? color}) => displayStyle(
  size: size,
  weight: 700,
  height: 1.3,
  tracking: -0.025,
  color: color,
);

/// Small uppercase label ("TODAY", "JOURNEY STYLES"): 10-12pt, bold,
/// wide tracking.
TextStyle eyebrowStyle({double size = 12, Color? color}) => TextStyle(
  fontFamily: kBodyFont,
  fontSize: size,
  fontWeight: FontWeight.w700,
  height: 1.4,
  letterSpacing: size * 0.1,
  color: color,
);

/// Large figures (streak, share card): Display 800, 72-120pt.
TextStyle bigNumberStyle({double size = 96, Color? color}) =>
    displayStyle(size: size, color: color, height: 1);

TextTheme _textTheme(OurneyColors c) {
  TextStyle body(double size, FontWeight w, {Color? color}) => TextStyle(
    fontFamily: kBodyFont,
    fontSize: size,
    fontWeight: w,
    color: color ?? c.ink,
    height: 1.4,
  );
  TextStyle h(double size, double tracking) => displayStyle(
    size: size,
    weight: 700,
    height: 1.2,
    tracking: tracking,
    color: c.ink,
  );
  return TextTheme(
    displayLarge: h(34, -0.04),
    displayMedium: h(30, -0.04),
    displaySmall: h(26, -0.03),
    headlineLarge: h(30, -0.04),
    headlineMedium: h(26, -0.03),
    headlineSmall: h(22, -0.025),
    titleLarge: body(18, FontWeight.w700),
    titleMedium: body(15, FontWeight.w700),
    titleSmall: body(14, FontWeight.w600),
    bodyLarge: body(16, FontWeight.w400),
    bodyMedium: body(15, FontWeight.w400),
    bodySmall: body(12, FontWeight.w400, color: c.inkMuted),
    labelLarge: body(15, FontWeight.w700),
    labelMedium: body(14, FontWeight.w600),
    labelSmall: body(11, FontWeight.w600, color: c.inkMuted),
  );
}

ThemeData buildAppTheme(Brightness brightness, [PersonaSkinId? skin]) {
  final c = brightness == Brightness.dark
      ? OurneyColors.dark
      : OurneyColors.light;
  final persona = skin != null
      ? OurneyPersonaTheme.forSkin(skin, brightness)
      : OurneyPersonaTheme.editorialNeutralBase(brightness);
  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.primary,
    onPrimary: c.onPrimary,
    secondary: c.accent,
    onSecondary: brightness == Brightness.dark
        ? OurneyColors.dark.bg
        : Colors.white,
    tertiary: c.streak,
    onTertiary: OurneyColors.light.ink,
    error: c.danger,
    onError: brightness == Brightness.dark
        ? OurneyColors.dark.bg
        : Colors.white,
    surface: c.surface,
    onSurface: c.ink,
    onSurfaceVariant: c.inkMuted,
    outline: c.border,
    outlineVariant: c.divider,
    surfaceContainerHighest: c.surfaceSunken,
    inverseSurface: c.ink,
    onInverseSurface: c.bg,
  );
  final text = _textTheme(c);
  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(OurneyRadii.capsule),
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.bg,
    canvasColor: c.bg,
    fontFamily: kBodyFont,
    textTheme: text,
    extensions: [c, persona],
    splashFactory: NoSplash.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: c.bg,
      foregroundColor: c.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: text.titleLarge,
    ),
    cardTheme: CardThemeData(
      color: c.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(side: BorderSide(color: c.divider)),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: c.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      textStyle: text.labelMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(OurneyRadii.menu),
        side: BorderSide(color: c.border),
      ),
    ),
    // V1.0 toast: ink bar with paper text (fixed, so it never hides the
    // primary action above it).
    snackBarTheme: SnackBarThemeData(
      backgroundColor: brightness == Brightness.dark ? c.surfaceRaised : c.ink,
      contentTextStyle: text.labelMedium?.copyWith(
        color: brightness == Brightness.dark ? c.ink : c.bg,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? c.surfaceRaised
              : c.surfaceSunken,
        ),
        foregroundColor: WidgetStatePropertyAll(c.ink),
        side: const WidgetStatePropertyAll(BorderSide.none),
        textStyle: WidgetStatePropertyAll(text.labelMedium),
        shape: const WidgetStatePropertyAll(StadiumBorder()),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.bg,
      surfaceTintColor: Colors.transparent,
      dragHandleColor: brightness == Brightness.dark
          ? const Color(0xFF45454C)
          : const Color(0xFFD1D1CC),
      dragHandleSize: const Size(42, 5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(OurneyRadii.sheet),
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(OurneyRadii.sheet),
      ),
    ),
    // Brand button: coral fill, ink label (5.41:1); disabled = sunken.
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.primary,
        foregroundColor: c.onPrimary,
        disabledBackgroundColor: c.surfaceSunken,
        disabledForegroundColor: c.inkMuted,
        minimumSize: const Size(OurneySizes.minTap, OurneySizes.button),
        padding: const EdgeInsets.symmetric(horizontal: OurneySpacing.xl),
        shape: shape,
        textStyle: text.labelLarge,
      ),
    ),
    // Secondary wide: surface fill with a hairline border.
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.ink,
        backgroundColor: c.surface,
        minimumSize: const Size(OurneySizes.minTap, OurneySizes.button),
        padding: const EdgeInsets.symmetric(horizontal: OurneySpacing.xl),
        side: BorderSide(color: c.border),
        shape: shape,
        textStyle: text.labelLarge,
      ),
    ),
    // Text actions are ink, never brand-colored (the brand is not
    // text-safe on paper).
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.ink,
        minimumSize: const Size(OurneySizes.minTap, OurneySizes.minTap),
        textStyle: text.titleSmall,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: c.ink,
        minimumSize: const Size.square(OurneySizes.minTap),
        iconSize: 21,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: c.primary,
      foregroundColor: c.onPrimary,
      elevation: 0,
      highlightElevation: 0,
      shape: const StadiumBorder(),
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? c.ink : c.surfaceSunken,
      ),
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? c.bg : c.inkMuted,
      ),
      trackOutlineColor: WidgetStatePropertyAll(c.border),
    ),
    listTileTheme: ListTileThemeData(iconColor: c.ink, textColor: c.ink),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surface,
      hintStyle: text.bodyMedium?.copyWith(color: c.inkMuted),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: OurneySpacing.lg,
        vertical: OurneySpacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(OurneyRadii.chip),
        borderSide: BorderSide(color: c.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(OurneyRadii.chip),
        borderSide: BorderSide(color: c.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(OurneyRadii.chip),
        borderSide: BorderSide(color: c.ink, width: 2),
      ),
    ),
    dividerTheme: DividerThemeData(color: c.divider, space: 1, thickness: 1),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.iOS: ReducedMotionAwareTransitionsBuilder(
          CupertinoPageTransitionsBuilder(),
        ),
        TargetPlatform.android: ReducedMotionAwareTransitionsBuilder(
          FadeForwardsPageTransitionsBuilder(),
        ),
      },
    ),
  );
}

/// Uses [platform] transitions normally and a plain fade when the OS asks
/// for reduced motion (`MediaQuery.disableAnimations`, docs/03).
class ReducedMotionAwareTransitionsBuilder extends PageTransitionsBuilder {
  const ReducedMotionAwareTransitionsBuilder(this.platform);

  final PageTransitionsBuilder platform;

  @override
  Duration get transitionDuration => platform.transitionDuration;

  @override
  Duration get reverseTransitionDuration => platform.reverseTransitionDuration;

  @override
  DelegatedTransitionBuilder? get delegatedTransition {
    final delegate = platform.delegatedTransition;
    if (delegate == null) return null;
    return (context, animation, secondaryAnimation, allowSnapshotting, child) {
      if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return child;
      return delegate(
        context,
        animation,
        secondaryAnimation,
        allowSnapshotting,
        child,
      );
    };
  }

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      return FadeTransition(opacity: animation, child: child);
    }
    return platform.buildTransitions(
      route,
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}

/// Text scaling policy (NFR-5): honour the system text size up to
/// [maxScale] (200%, roughly iOS AX2–AX3 for body text) so layouts stay
/// usable. Applied once around the whole app in `MaterialApp.builder`.
/// Compact chrome (tab labels) may clamp further locally.
class OurneyTextScaleClamp extends StatelessWidget {
  const OurneyTextScaleClamp({required this.child, super.key});

  static const double maxScale = 2;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return MediaQuery(
      data: mq.copyWith(
        textScaler: mq.textScaler.clamp(maxScaleFactor: maxScale),
      ),
      child: child,
    );
  }
}
