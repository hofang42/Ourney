import 'package:flutter/material.dart';

import '../tokens.dart';

/// `button:active { transform: scale(.96); transition: transform 110ms }`
/// plus the `:focus-visible` 3px ring. Every tappable surface in the kit is
/// built on this. Guarantees a 48x48 hit area.
class UiPressable extends StatefulWidget {
  const UiPressable({
    required this.child,
    required this.onPressed,
    this.semanticLabel,
    this.minSize = const Size(UiSize.tap, UiSize.tap),
    this.borderRadius = const BorderRadius.all(
      Radius.circular(UiRadius.capsule),
    ),
    this.excludeChildSemantics = false,
    this.selected,
    this.centerChild = false,
    this.shadowColor,
    this.shadowOffset = 0,
    super.key,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final Size minSize;
  final BorderRadius borderRadius;
  final bool excludeChildSemantics;
  final bool? selected;

  /// Center [child] inside the (>= 48dp) hit area instead of stretching it
  /// to fill it: a 44dp button or 40dp pill keeps its visual size.
  final bool centerChild;

  /// V2 sticker press: a hard offset shadow of [shadowOffset] dp in
  /// [shadowColor]. On press the child translates by the offset and the
  /// shadow disappears (`translate(4px,4px); box-shadow: none`) instead of
  /// scaling. Leave [shadowOffset] at 0 for the plain 0.96 scale press.
  final Color? shadowColor;
  final double shadowOffset;

  @override
  State<UiPressable> createState() => _UiPressableState();
}

class _UiPressableState extends State<UiPressable> {
  bool _down = false;
  bool _focused = false;

  bool get _enabled => widget.onPressed != null;

  void _setDown(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final sticker = widget.shadowOffset > 0;
    final pressed = _down && _enabled;
    Widget content = AnimatedScale(
      scale: pressed && !sticker ? UiMotion.pressScale : 1,
      duration: UiMotion.of(context, UiMotion.press),
      curve: Curves.easeOut,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          border: _focused
              ? Border.all(color: ui.focus, width: 3)
              : const Border.fromBorderSide(BorderSide.none),
        ),
        child: widget.child,
      ),
    );
    if (sticker) {
      final offset = widget.shadowOffset;
      content = AnimatedContainer(
        duration: UiMotion.of(context, UiMotion.press),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(
          pressed ? offset : 0,
          pressed ? offset : 0,
          0,
        ),
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          boxShadow: pressed || !_enabled
              ? const []
              : UiShadow.hard(widget.shadowColor ?? ui.outline, offset),
        ),
        child: content,
      );
    }
    content = ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: widget.minSize.width,
        minHeight: widget.minSize.height,
      ),
      child: widget.centerChild
          ? Center(widthFactor: 1, heightFactor: 1, child: content)
          : content,
    );
    return Semantics(
      button: true,
      enabled: _enabled,
      selected: widget.selected,
      label: widget.semanticLabel,
      excludeSemantics: widget.excludeChildSemantics,
      onTap: widget.onPressed,
      child: FocusableActionDetector(
        enabled: _enabled,
        mouseCursor: _enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onPressed?.call();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _enabled ? (_) => _setDown(true) : null,
          onTapUp: _enabled ? (_) => _setDown(false) : null,
          onTapCancel: () => _setDown(false),
          onTap: widget.onPressed,
          child: content,
        ),
      ),
    );
  }
}
