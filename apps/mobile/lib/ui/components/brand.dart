import 'package:flutter/material.dart';

import '../tokens.dart';
import '../typography.dart';

/// `.wordmark`: "ourney" in Bricolage 800 with -0.07em tracking.
class UiWordmark extends StatelessWidget {
  const UiWordmark({this.size = 46, this.color, super.key});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Ourney',
    excludeSemantics: true,
    child: Text(
      'ourney',
      maxLines: 1,
      style: UiText.wordmark(size: size, color: color ?? context.ui.ink),
    ),
  );
}

/// `.splash-screen`: coral field with the ink wordmark, centered.
class UiSplash extends StatelessWidget {
  const UiSplash({super.key});

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return ColoredBox(
      key: const ValueKey('ui-splash'),
      color: ui.brand,
      child: Center(child: UiWordmark(color: ui.onBrand)),
    );
  }
}
