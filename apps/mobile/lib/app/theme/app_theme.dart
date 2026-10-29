import 'package:flutter/material.dart';
import 'package:ourney_core/ourney_core.dart' show PersonaSkinId;

import '../../ui/theme.dart' show OurneyTheme;

export '../../ui/theme.dart' show ReducedMotionAwareTransitionsBuilder;

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

/// The app theme. Delegates to the V1.0 UI kit (`lib/ui/theme.dart`); kept
/// under this name for call sites that predate the kit.
ThemeData buildAppTheme(Brightness brightness, [PersonaSkinId? skin]) =>
    OurneyTheme.build(brightness, skin);

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
