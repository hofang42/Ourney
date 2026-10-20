import 'package:flutter/widgets.dart';

/// Width classes of `CLAUDE.md` §3.
enum OurneyWidthClass {
  /// `< 360dp`: iPhone SE / mini.
  compact,

  /// `360dp .. < 410dp`: iPhone 16, Galaxy S24.
  standard,

  /// `410dp .. < 600dp`: Pro Max / large phones.
  large,

  /// `>= 600dp`: tablets and foldables.
  tablet,
}

/// Responsive spacing rules every screen shares (`CLAUDE.md` §2–3).
///
/// All numbers live here so a screen never hardcodes a pixel width. Pass the
/// width of the *available* space (`LayoutBuilder` constraints), not the
/// screen, when the screen sits inside a narrower pane.
abstract final class OurneyLayout {
  static const double compactMaxWidth = 360;
  static const double standardMaxWidth = 410;
  static const double largeMaxWidth = 600;

  /// Minimum touch target (`>= 44pt` iOS HIG, `48dp` Material).
  static const double minTouchTarget = 48;

  /// Primary button height; the compact variant is 44.
  static const double primaryButtonHeight = 52;
  static const double compactButtonHeight = 44;

  /// Widest a card or card grid may grow on large phones.
  static const double maxCardWidth = 480;

  /// Widest a single-column feed may grow on tablets and foldables.
  static const double maxFeedWidth = 520;

  /// Dynamic Type ceiling the layouts are verified against.
  static const double maxTextScale = 1.35;

  static OurneyWidthClass classOf(double width) {
    if (width < compactMaxWidth) return OurneyWidthClass.compact;
    if (width < standardMaxWidth) return OurneyWidthClass.standard;
    if (width < largeMaxWidth) return OurneyWidthClass.large;
    return OurneyWidthClass.tablet;
  }

  /// Horizontal screen padding: 16 (compact), 20 (standard), 24 (larger).
  static double horizontalPadding(double width) => switch (classOf(width)) {
    OurneyWidthClass.compact => 16,
    OurneyWidthClass.standard => 20,
    OurneyWidthClass.large || OurneyWidthClass.tablet => 24,
  };

  /// Inner padding of a card: 12 on compact phones, 16 elsewhere.
  static double cardPadding(double width) =>
      classOf(width) == OurneyWidthClass.compact ? 12 : 16;

  /// Gap between grid cells (2x2 Polaroid grids...): 8 compact, 12 elsewhere.
  static double gridSpacing(double width) =>
      classOf(width) == OurneyWidthClass.compact ? 8 : 12;

  /// Widest content column for [width]: a 520dp feed on tablets, a 480dp card
  /// on phones, and never wider than [width] itself.
  static double contentMaxWidth(double width) {
    final cap = classOf(width) == OurneyWidthClass.tablet
        ? maxFeedWidth
        : maxCardWidth;
    return width < cap ? width : cap;
  }

  /// Width of one column in a grid of [columns] inside [width], after the
  /// horizontal padding and the gaps between cells.
  static double gridCellWidth(double width, {int columns = 2}) {
    final inner = contentMaxWidth(width) - 2 * horizontalPadding(width);
    final gaps = gridSpacing(width) * (columns - 1);
    return (inner - gaps) / columns;
  }

  /// Safe-area and keyboard insets that screens must respect.
  static EdgeInsets safeInsets(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final view = MediaQuery.viewInsetsOf(context);
    return EdgeInsets.fromLTRB(
      padding.left,
      padding.top,
      padding.right,
      padding.bottom > view.bottom ? padding.bottom : view.bottom,
    );
  }
}

/// Centers [child] in a column no wider than [OurneyLayout.contentMaxWidth]
/// and applies the horizontal padding of the available width.
class OurneyResponsiveBody extends StatelessWidget {
  const OurneyResponsiveBody({
    required this.child,
    this.applyHorizontalPadding = true,
    super.key,
  });

  final Widget child;

  /// Set false when the child (a `ListView` with its own padding) already
  /// pads itself.
  final bool applyHorizontalPadding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final inner = SizedBox(
          width: OurneyLayout.contentMaxWidth(width),
          child: applyHorizontalPadding
              ? Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: OurneyLayout.horizontalPadding(width),
                  ),
                  child: child,
                )
              : child,
        );
        return Align(alignment: Alignment.topCenter, child: inner);
      },
    );
  }
}
