import 'package:flutter/material.dart';

import '../tokens.dart';

/// Page frame for every kit screen: paper background, safe area, responsive
/// horizontal gutter (16 / 20 / 24dp) and a centered max-width column
/// (480dp phones, 520dp tablets). Scrolls by default so large text and the
/// keyboard never overflow.
class UiScaffold extends StatefulWidget {
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

  /// Height of the pinned [bottom] slot of the [UiScaffold] on the current
  /// route (0 when there is none). `showUiToast` adds it to its offset so a
  /// toast clears the primary button instead of covering it.
  static double pinnedBottomHeightOf(BuildContext context) {
    // The caller's own route first; a toast from a bottom sheet (its route
    // has no scaffold) falls back to the page below, registered under the
    // shared messenger. Limitation: with several pinned scaffolds under one
    // messenger and no route match, the most recently built one wins.
    for (final scope in _scopesOf(context)) {
      final box = _pinnedKeys[scope]?.currentContext?.findRenderObject();
      if (box is RenderBox && box.hasSize) return box.size.height;
    }
    return 0;
  }

  @override
  State<UiScaffold> createState() => _UiScaffoldState();
}

/// Pinned-slot keys per route (or per messenger when there is no route).
final Expando<GlobalKey> _pinnedKeys = Expando<GlobalKey>('UiScaffold pinned');

List<Object> _scopesOf(BuildContext context) => [
  ?ModalRoute.of(context),
  ?ScaffoldMessenger.maybeOf(context),
];

class _UiScaffoldState extends State<UiScaffold> {
  final _pinnedKey = GlobalKey(debugLabel: 'ui-scaffold-pinned');
  List<Object> _scopes = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _register();
  }

  @override
  void didUpdateWidget(UiScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    _register();
  }

  void _register() {
    _scopes = _scopesOf(context);
    for (final scope in _scopes) {
      _pinnedKeys[scope] = widget.bottom == null ? null : _pinnedKey;
    }
  }

  @override
  void dispose() {
    for (final scope in _scopes) {
      if (identical(_pinnedKeys[scope], _pinnedKey)) _pinnedKeys[scope] = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final background = widget.background;
    final bottom = widget.bottom;
    final scroll = widget.scroll;
    final padTop = widget.padTop;
    final padBottom = widget.padBottom;
    final child = widget.child;
    final ui = context.ui;
    final width = MediaQuery.sizeOf(context).width;
    final h = widget.gutter ? UiSpace.gutter(width) : 0.0;
    return Scaffold(
      backgroundColor: background ?? ui.bg,
      resizeToAvoidBottomInset: true,
      body: Builder(
        builder: (context) {
          final useSafeBottom =
              widget.safeBottom ?? (!scroll && bottom == null);
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
                      KeyedSubtree(
                        key: _pinnedKey,
                        child: SafeArea(
                          top: false,
                          left: false,
                          right: false,
                          child: pinned,
                        ),
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
