import 'package:flutter/material.dart';

import '../skins.dart';
import '../tokens.dart';
import '../typography.dart';

/// What [UiSkinScope.of] returns.
@immutable
class UiSkinScopeData {
  const UiSkinScopeData({
    required this.skin,
    required this.variantIndex,
    required this.variant,
    required this.headingFont,
  });

  final UiSkin skin;
  final int variantIndex;

  /// The variant after V2's overrides (minimal variant 1 in dark mode).
  final UiSkinVariant variant;

  /// Bundled font family for headings in this skin.
  final String headingFont;
}

class _UiSkinTween extends Tween<OurneyUi> {
  _UiSkinTween({super.end});

  @override
  OurneyUi lerp(double t) => begin!.lerp(end!, t);
}

class _SkinInherited extends InheritedWidget {
  const _SkinInherited({required this.data, required super.child});

  final UiSkinScopeData data;

  @override
  bool updateShouldNotify(_SkinInherited old) =>
      old.data.skin.id != data.skin.id ||
      old.data.variantIndex != data.variantIndex ||
      old.data.variant.button != data.variant.button;
}

/// Recolors everything below it with a V2 journey skin: wraps [Theme] with
/// the [OurneyUi] from `uiSkinById(skinId).apply(base, variantIndex: variant)`
/// for the current brightness, cross-fading over 320ms (instant under
/// reduce-motion). Descendants read it through `context.ui`, and the skin
/// itself through [UiSkinScope.of].
class UiSkinScope extends StatelessWidget {
  const UiSkinScope({
    required this.skinId,
    required this.child,
    this.variant = 0,
    super.key,
  });

  final String skinId;
  final int variant;
  final Widget child;

  /// The nearest scope; throws when there is none.
  static UiSkinScopeData of(BuildContext context) {
    final data = maybeOf(context);
    assert(data != null, 'No UiSkinScope found in context');
    return data!;
  }

  static UiSkinScopeData? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SkinInherited>()?.data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final skin = uiSkinById(skinId);
    final base = theme.brightness == Brightness.dark
        ? OurneyUi.dark
        : OurneyUi.light;
    final target = skin.apply(base, variantIndex: variant);
    final data = UiSkinScopeData(
      skin: skin,
      variantIndex: variant,
      variant: skin.resolvedVariant(variant, base.brightness),
      headingFont: UiFonts.forHeading(skin.headingFont),
    );
    return TweenAnimationBuilder<OurneyUi>(
      tween: _UiSkinTween(end: target),
      duration: UiMotion.of(context, UiMotion.theme),
      builder: (context, ui, child) {
        final others = theme.extensions.values.where((e) => e is! OurneyUi);
        return Theme(
          data: theme.copyWith(
            scaffoldBackgroundColor: ui.bg,
            extensions: [...others, ui],
          ),
          child: child!,
        );
      },
      child: _SkinInherited(data: data, child: child),
    );
  }
}
