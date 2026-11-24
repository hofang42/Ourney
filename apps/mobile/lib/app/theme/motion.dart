import 'dart:async';

import 'package:flutter/material.dart';

import '../../ui/tokens.dart';

/// Legacy motion helpers forwarded to [UiMotion] and [UiCurves].
/// Under reduce motion (`MediaQuery.disableAnimations`) every animation is
/// replaced by a fast fade and decorative loops/confetti are skipped.
abstract final class OurneyMotion {
  static bool reduced(BuildContext context) => UiMotion.reduced(context);

  /// [normal] duration, or [UiMotion.reducedFade] under reduce motion.
  static Duration duration(BuildContext context, Duration normal) =>
      UiMotion.fadeOf(context, normal);

  /// [normal] duration, or zero under reduce motion (for movement that must
  /// not be replaced by a fade, e.g. press-sink).
  static Duration movement(BuildContext context, Duration normal) =>
      UiMotion.of(context, normal);

  /// Whether decorative effects (confetti, looping flame) may run.
  static bool allowsDecoration(BuildContext context) =>
      !UiMotion.reduced(context);

  /// Spring-like page transition or a fade under reduce motion.
  static Widget pageTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (reduced(context)) {
      return FadeTransition(opacity: animation, child: child);
    }
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(
          begin: UiMotion.popMinScale,
          end: 1,
        ).chain(CurveTween(curve: UiCurves.easeOutStrong)).animate(animation),
        child: child,
      ),
    );
  }
}

/// Legacy haptics facade forwarded to [UiHaptics] (sharing the global
/// [UiHaptics.enabled] toggle).
abstract final class OurneyHaptics {
  static bool get enabled => UiHaptics.enabled;
  static set enabled(bool value) => UiHaptics.enabled = value;

  static void selection() => unawaited(UiHaptics.selection());
  static void light() => unawaited(UiHaptics.pressLight());
  static void medium() => unawaited(UiHaptics.shutterMedium());
  static void success() => unawaited(UiHaptics.success());
  static void warning() => unawaited(UiHaptics.warning());
}
