import 'package:flutter/material.dart';

import '../skins.dart';
import '../theme.dart' show OurneyTheme;
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
class UiSkinScope extends StatefulWidget {
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
  State<UiSkinScope> createState() => _UiSkinScopeState();
}

class _UiSkinScopeState extends State<UiSkinScope> {
  // Cached so unrelated rebuilds hand the TweenAnimationBuilder an equal end
  // value and do not restart the 320ms cross-fade.
  Brightness? _brightness;
  String? _skinId;
  int? _variant;
  late OurneyUi _target;
  late UiSkinScopeData _data;

  void _resolve(Brightness brightness) {
    if (_brightness == brightness &&
        _skinId == widget.skinId &&
        _variant == widget.variant) {
      return;
    }
    final skin = uiSkinById(widget.skinId);
    final base = brightness == Brightness.dark ? OurneyUi.dark : OurneyUi.light;
    _brightness = brightness;
    _skinId = widget.skinId;
    _variant = widget.variant;
    _target = skin.apply(base, variantIndex: widget.variant);
    _data = UiSkinScopeData(
      skin: skin,
      variantIndex: widget.variant,
      variant: skin.resolvedVariant(widget.variant, base.brightness),
      headingFont: UiFonts.forHeading(skin.headingFont),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    _resolve(theme.brightness);
    return TweenAnimationBuilder<OurneyUi>(
      tween: _UiSkinTween(end: _target),
      duration: UiMotion.of(context, UiMotion.theme),
      builder: (context, ui, child) {
        // Rebuild the palette-dependent Material parts from the scoped ui.
        final themed = OurneyTheme.fromUi(ui);
        final others = theme.extensions.values.where((e) => e is! OurneyUi);
        return Theme(
          data: theme.copyWith(
            scaffoldBackgroundColor: ui.bg,
            canvasColor: ui.bg,
            colorScheme: themed.colorScheme,
            textTheme: themed.textTheme,
            focusColor: themed.focusColor,
            appBarTheme: themed.appBarTheme,
            cardTheme: themed.cardTheme,
            popupMenuTheme: themed.popupMenuTheme,
            snackBarTheme: themed.snackBarTheme,
            segmentedButtonTheme: themed.segmentedButtonTheme,
            bottomSheetTheme: themed.bottomSheetTheme,
            dialogTheme: themed.dialogTheme,
            filledButtonTheme: themed.filledButtonTheme,
            outlinedButtonTheme: themed.outlinedButtonTheme,
            textButtonTheme: themed.textButtonTheme,
            iconButtonTheme: themed.iconButtonTheme,
            floatingActionButtonTheme: themed.floatingActionButtonTheme,
            switchTheme: themed.switchTheme,
            listTileTheme: themed.listTileTheme,
            inputDecorationTheme: themed.inputDecorationTheme,
            dividerTheme: themed.dividerTheme,
            extensions: [...others, ui],
          ),
          child: child!,
        );
      },
      child: _SkinInherited(data: _data, child: widget.child),
    );
  }
}
