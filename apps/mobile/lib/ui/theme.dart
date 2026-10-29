import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:ourney_core/ourney_core.dart';

import '../app/theme/persona_theme.dart';
import '../app/theme/tokens.dart' show OurneyColors;
import 'tokens.dart';
import 'typography.dart';

/// Builds the app [ThemeData] from the V1.0 tokens.
///
/// The base (scaffold, text, inputs, sheets, switches) comes from
/// [OurneyUi]; the persona skin only contributes the [OurneyPersonaTheme]
/// extension (journey accents), it never recolors the shell.
///
/// Extensions installed: [OurneyUi] (this kit), [OurneyPersonaTheme] and the
/// legacy `OurneyColors` that screens not yet rebuilt still read.
abstract final class OurneyTheme {
  static ThemeData build(Brightness brightness, [PersonaSkinId? skin]) {
    final ui = brightness == Brightness.dark ? OurneyUi.dark : OurneyUi.light;
    final legacy = brightness == Brightness.dark
        ? OurneyColors.dark
        : OurneyColors.light;
    final persona = skin != null
        ? OurneyPersonaTheme.forSkin(skin, brightness)
        : OurneyPersonaTheme.editorialNeutralBase(brightness);

    final scheme = ColorScheme(
      brightness: brightness,
      primary: ui.brand,
      onPrimary: ui.onBrand,
      secondary: legacy.accent,
      onSecondary: ui.isDark ? ui.bg : Colors.white,
      tertiary: ui.flame,
      onTertiary: OurneyUi.light.ink,
      error: ui.danger,
      onError: ui.isDark ? ui.bg : Colors.white,
      surface: ui.surface,
      onSurface: ui.ink,
      onSurfaceVariant: ui.inkMuted,
      outline: ui.border,
      outlineVariant: ui.divider,
      surfaceContainerHighest: ui.fill,
      inverseSurface: ui.ink,
      onInverseSurface: ui.bg,
    );

    final text = _textTheme(ui);
    const capsule = StadiumBorder();

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: ui.bg,
      canvasColor: ui.bg,
      fontFamily: UiFonts.body,
      textTheme: text,
      extensions: [ui, legacy, persona],
      splashFactory: NoSplash.splashFactory,
      focusColor: ui.focus,
      appBarTheme: AppBarTheme(
        backgroundColor: ui.bg,
        foregroundColor: ui.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: text.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: ui.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(side: BorderSide(color: ui.divider)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: ui.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        textStyle: text.labelMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UiRadius.menu),
          side: BorderSide(color: ui.border),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ui.ink,
        contentTextStyle: text.labelMedium?.copyWith(
          color: ui.bg,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(0, UiSize.tap)),
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? ui.fillSelected : ui.fill,
          ),
          foregroundColor: WidgetStatePropertyAll(ui.ink),
          side: const WidgetStatePropertyAll(BorderSide.none),
          textStyle: WidgetStatePropertyAll(text.labelMedium),
          shape: const WidgetStatePropertyAll(capsule),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: ui.bg,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: ui.grabber,
        dragHandleSize: const Size(42, 5),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(UiRadius.sheet),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: ui.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UiRadius.sheet),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ui.brand,
          foregroundColor: ui.onBrand,
          disabledBackgroundColor: ui.fill,
          disabledForegroundColor: ui.inkMuted,
          minimumSize: const Size(UiSize.tap, UiSize.button),
          padding: const EdgeInsets.symmetric(horizontal: UiSpace.xxl),
          shape: capsule,
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ui.ink,
          backgroundColor: ui.surface,
          minimumSize: const Size(UiSize.tap, UiSize.button),
          padding: const EdgeInsets.symmetric(horizontal: UiSpace.xxl),
          side: BorderSide(color: ui.border),
          shape: capsule,
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ui.ink,
          minimumSize: const Size(UiSize.tap, UiSize.tap),
          textStyle: text.titleSmall,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: ui.ink,
          minimumSize: const Size.square(UiSize.tap),
          iconSize: 21,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: ui.brand,
        foregroundColor: ui.onBrand,
        elevation: 0,
        highlightElevation: 0,
        shape: capsule,
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? ui.ink : ui.fill,
        ),
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? ui.bg : ui.inkMuted,
        ),
        trackOutlineColor: WidgetStatePropertyAll(ui.border),
      ),
      listTileTheme: ListTileThemeData(iconColor: ui.ink, textColor: ui.ink),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ui.surfaceInput,
        hintStyle: text.bodyMedium?.copyWith(color: ui.inkMuted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: UiSpace.lg,
          vertical: UiSpace.md,
        ),
        border: _border(ui.inputBorder),
        enabledBorder: _border(ui.inputBorder),
        focusedBorder: _border(ui.ink, 2),
        errorBorder: _border(ui.danger),
        focusedErrorBorder: _border(ui.danger, 2),
      ),
      dividerTheme: DividerThemeData(color: ui.divider, space: 1, thickness: 1),
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

  static OutlineInputBorder _border(Color c, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(UiRadius.input),
        borderSide: BorderSide(color: c, width: width),
      );

  static TextTheme _textTheme(OurneyUi ui) {
    TextStyle b(double size, FontWeight w, {Color? color}) =>
        UiText.body(size: size, weight: w, color: color ?? ui.ink);
    TextStyle h(double size, double tracking) => UiText.display(
      size: size,
      height: 1.3,
      tracking: tracking,
      color: ui.ink,
    );
    return TextTheme(
      displayLarge: h(34, -0.04),
      displayMedium: h(30, -0.04),
      displaySmall: h(26, -0.03),
      headlineLarge: h(30, -0.04),
      headlineMedium: h(26, -0.03),
      headlineSmall: h(22, -0.025),
      titleLarge: b(18, FontWeight.w700),
      titleMedium: b(15, FontWeight.w700),
      titleSmall: b(14, FontWeight.w600),
      bodyLarge: b(16, FontWeight.w400),
      bodyMedium: b(15, FontWeight.w400),
      bodySmall: b(12, FontWeight.w400, color: ui.inkMuted),
      labelLarge: b(15, FontWeight.w700),
      labelMedium: b(14, FontWeight.w600),
      labelSmall: b(11, FontWeight.w600, color: ui.inkMuted),
    );
  }
}

/// Uses [platform] transitions normally and a plain fade when the OS asks
/// for reduced motion.
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
