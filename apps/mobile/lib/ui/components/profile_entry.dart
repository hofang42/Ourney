import 'package:flutter/material.dart';

import '../tokens.dart';
import 'avatar.dart';
import 'pressable.dart';

/// Top-bar entry to the profile: the user's initials avatar, or a neutral
/// person glyph when there is no profile (guest / local-only).
class UiProfileEntry extends StatelessWidget {
  const UiProfileEntry({
    required this.label,
    required this.onPressed,
    this.name,
    this.size = 36,
    this.onDark = false,
    super.key,
  });

  final String label;
  final String? name;
  final VoidCallback onPressed;
  final double size;

  /// On the always-dark camera chrome.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final n = name?.trim();
    final Widget face = n == null || n.isEmpty
        ? Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: onDark ? const Color(0x22FFFFFF) : ui.fill,
              border: Border.all(
                color: onDark ? UiCamera.dockBorder : ui.border,
              ),
            ),
            child: Icon(
              Icons.person_outline_rounded,
              size: size * 0.55,
              color: onDark ? UiCamera.ink : ui.ink,
            ),
          )
        : UiAvatar(name: n, colorIndex: UiAvatar.indexFor(n), size: size);
    return UiPressable(
      onPressed: onPressed,
      semanticLabel: label,
      excludeChildSemantics: true,
      centerChild: true,
      child: face,
    );
  }
}
