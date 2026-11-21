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
    this.safeBottom,
    this.padTop = 12,
    this.padBottom = 28,
    this.gutter = true,
    super.key,
  });

  final Widget child;
  final Color? background;

  /// Pinned below the content, above the keyboard / safe area
  /// (e.g. a dock or the primary button). Always kept clear of the bottom
  /// safe-area inset, so callers must not add it themselves.
  final Widget? bottom;
  final bool scroll;

  /// Whether [SafeArea] insets the bottom edge. When `null`, scrolling pages
  /// without a [bottom] slot keep [SafeArea]'s bottom disabled and add the
  /// bottom inset inside the scroll padding so content extends behind a glass
  /// dock; non-scrolling pages without [bottom] keep [SafeArea]'s bottom on.
  final bool? safeBottom;
  final double padTop;
  final double padBottom;
  final bool gutter;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final width = MediaQuery.sizeOf(context).width;
    final h = gutter ? UiSpace.gutter(width) : 0.0;
    return Scaffold(
      backgroundColor: background ?? ui.bg,
      resizeToAvoidBottomInset: true,
      body: Builder(
        builder: (context) {
          final useSafeBottom = safeBottom ?? (!scroll && bottom == null);
          final bottomInset = !useSafeBottom && bottom == null
              ? MediaQuery.paddingOf(context).bottom
              : 0.0;
          Widget body = Padding(
            padding: EdgeInsets.fromLTRB(
              h,
              padTop,
              h,
              padBottom + (scroll ? bottomInset : 0),
            ),
            child: child,
          );
          if (scroll) {
            body = SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: body,
            );
          }
          return SafeArea(
            bottom: useSafeBottom,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: UiSpace.maxContent(width),
                ),
                child: Column(
                  children: [
                    Expanded(child: body),
                    // The pinned slot always clears the home indicator /
                    // gesture bar (U1). Inside it the bottom padding is
                    // consumed, so children reading it get 0 (no double pad).
                    if (bottom case final pinned?)
                      SafeArea(
                        top: false,
                        left: false,
                        right: false,
                        child: pinned,
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
