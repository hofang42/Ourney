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
    Widget content = AnimatedScale(
      scale: _down && _enabled ? UiMotion.pressScale : 1,
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
