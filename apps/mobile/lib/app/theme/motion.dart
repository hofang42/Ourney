import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens.dart';

/// Motion helpers honoring the platform "reduce motion" setting
/// (`MediaQuery.disableAnimations`). Under reduce motion every animation is
/// replaced by a 0.2s fade and decorative loops/confetti are skipped.
abstract final class OurneyMotion {
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [normal] duration, or the 0.2s fade duration under reduce motion.
  static Duration duration(BuildContext context, Duration normal) =>
      reduced(context) ? OurneyDurations.reducedFade : normal;

  /// [normal] duration, or zero under reduce motion (for movement that must
  /// not be replaced by a fade, e.g. press-sink).
  static Duration movement(BuildContext context, Duration normal) =>
      reduced(context) ? Duration.zero : normal;

  /// Whether decorative effects (confetti, looping flame) may run.
  static bool allowsDecoration(BuildContext context) => !reduced(context);

  /// Spring-like page transition (0.4s) or a 0.2s fade under reduce motion.
  static Widget pageTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (reduced(context)) {
      return FadeTransition(opacity: animation, child: child);
    }
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeIn,
    );
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
        child: child,
      ),
    );
  }
}

/// Haptics with a global off switch ("haptic tat duoc").
abstract final class OurneyHaptics {
  static bool enabled = true;

  static void _run(Future<void> Function() f) {
    if (!enabled) return;
    f().catchError((Object _) {});
  }

  static void selection() => _run(HapticFeedback.selectionClick);
  static void light() => _run(HapticFeedback.lightImpact);
  static void medium() => _run(HapticFeedback.mediumImpact);
  static void success() => _run(HapticFeedback.heavyImpact);
  static void warning() => _run(HapticFeedback.vibrate);
}
