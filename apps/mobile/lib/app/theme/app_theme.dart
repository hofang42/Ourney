import 'package:flutter/material.dart';
import 'package:ourney_core/ourney_core.dart';

import 'persona_theme.dart';
import 'tokens.dart';

const String kBodyFont = 'BeVietnamPro';
const String kDisplayFont = 'BricolageGrotesque';

/// Display style on the Bricolage Grotesque variable font (weight axis).
TextStyle displayStyle({
  required double size,
  int weight = 800,
  Color? color,
  double height = 1.1,
}) => TextStyle(
  fontFamily: kDisplayFont,
  fontSize: size,
  fontWeight: FontWeight.values[(weight ~/ 100) - 1],
  fontVariations: [FontVariation('wght', weight.toDouble())],
  height: height,
  color: color,
  fontFamilyFallback: const [kBodyFont],
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
  return TextTheme(
    displayLarge: displayStyle(size: 34, color: c.ink),
    displayMedium: displayStyle(size: 28, color: c.ink),
    displaySmall: displayStyle(size: 22, color: c.ink),
    headlineLarge: displayStyle(size: 34, color: c.ink),
    headlineMedium: displayStyle(size: 28, color: c.ink),
    headlineSmall: displayStyle(size: 22, color: c.ink),
    titleLarge: body(18, FontWeight.w700),
    titleMedium: body(16, FontWeight.w600),
    titleSmall: body(14, FontWeight.w600),
    bodyLarge: body(16, FontWeight.w400),
    bodyMedium: body(14, FontWeight.w400),
    bodySmall: body(12, FontWeight.w400, color: c.inkMuted),
    labelLarge: body(16, FontWeight.w600),
    labelMedium: body(14, FontWeight.w500),
    labelSmall: body(12, FontWeight.w600, color: c.inkMuted),
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
    outlineVariant: c.border,
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
      titleTextStyle: text.titleLarge,
    ),
    cardTheme: CardThemeData(
      color: c.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(OurneyRadii.card),
        side: BorderSide(color: c.border),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface,
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
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.primaryDeep,
        foregroundColor: c.onPrimaryDeep,
        minimumSize: const Size(OurneySizes.minTap, 48),
        shape: shape,
        textStyle: text.titleMedium,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.ink,
        minimumSize: const Size(OurneySizes.minTap, 48),
        side: BorderSide(color: c.border),
        shape: shape,
        textStyle: text.titleMedium,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.primaryDeep,
        minimumSize: const Size(OurneySizes.minTap, OurneySizes.minTap),
        textStyle: text.titleSmall,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surface,
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
        borderSide: BorderSide(color: c.primaryDeep, width: 2),
      ),
    ),
    dividerTheme: DividerThemeData(color: c.border, space: 1, thickness: 1),
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
