import 'package:flutter/material.dart';

import '../tokens.dart';

/// Page frame for every kit screen: paper background, safe area, responsive
/// horizontal gutter (16 / 20 / 24dp) and a centered max-width column
/// (480dp phones, 520dp tablets). Scrolls by default so large text and the
/// keyboard never overflow.
class UiScaffold extends StatelessWidget {
  const UiScaffold({
    required this.child,
    this.background,
    this.bottom,
    this.scroll = true,
    this.padTop = 12,
    this.padBottom = 28,
    this.gutter = true,
    super.key,
  });

  final Widget child;
  final Color? background;

  /// Pinned below the content, above the keyboard / safe area
  /// (e.g. a dock or the primary button).
  final Widget? bottom;
  final bool scroll;
  final double padTop;
  final double padBottom;
  final bool gutter;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final width = MediaQuery.sizeOf(context).width;
    final h = gutter ? UiSpace.gutter(width) : 0.0;
    Widget body = Padding(
      padding: EdgeInsets.fromLTRB(h, padTop, h, padBottom),
      child: child,
    );
    if (scroll) {
      body = SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: body,
      );
    }
    return Scaffold(
      backgroundColor: background ?? ui.bg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: bottom == null,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: UiSpace.maxContent(width)),
            child: Column(
              children: [
                Expanded(child: body),
                ?bottom,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
