import 'package:flutter/material.dart';

import '../tokens.dart';
import '../typography.dart';
import 'pressable.dart';

/// `avatarColors` from App.tsx.
const List<Color> uiAvatarColors = [
  Color(0xFFE15B72),
  Color(0xFF6D4BF0),
  Color(0xFF2AA7E0),
  Color(0xFF10B981),
  Color(0xFFFF9F1C),
];

/// `.avatar`: initial on a colored disc with a 2dp paper ring. 28dp by
/// default, 40dp large, 88dp for the profile picker. Pass [image] to show a
/// photo instead of the initial.
class UiAvatar extends StatelessWidget {
  const UiAvatar({
    required this.name,
    this.colorIndex = 0,
    this.size = UiSize.avatar,
    this.image,
    this.ring = true,
    this.semanticLabel,
    super.key,
  });

  final String name;
  final int colorIndex;
  final double size;
  final ImageProvider<Object>? image;
  final bool ring;
  final String? semanticLabel;

  /// Stable color for a string (e.g. a user id) so the same person always
  /// gets the same disc.
  static int indexFor(String seed) {
    var h = 0;
    for (final c in seed.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return h % uiAvatarColors.length;
  }

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final initial = name.trim().isEmpty
        ? '?'
        : String.fromCharCode(name.trim().runes.first).toUpperCase();
    return Semantics(
      label: semanticLabel ?? name,
      image: true,
      excludeSemantics: true,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: uiAvatarColors[colorIndex % uiAvatarColors.length],
          shape: BoxShape.circle,
          border: ring ? Border.all(color: ui.surface, width: 2) : null,
          image: image == null
              ? null
              : DecorationImage(image: image!, fit: BoxFit.cover),
        ),
        child: image != null
            ? null
            : Text(
                initial,
                style: UiText.body(
                  size: size * 0.43,
                  weight: FontWeight.w700,
                  height: 1.2,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

/// `.avatar-picker`: 88dp avatar with an ink camera badge, tappable.
class UiAvatarPicker extends StatelessWidget {
  const UiAvatarPicker({
    required this.name,
    required this.label,
    required this.onPressed,
    this.colorIndex = 0,
    this.image,
    super.key,
  });

  final String name;
  final String label;
  final VoidCallback? onPressed;
  final int colorIndex;
  final ImageProvider<Object>? image;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return UiPressable(
      onPressed: onPressed,
      semanticLabel: label,
      excludeChildSemantics: true,
      minSize: const Size.square(UiSize.avatarXL),
      child: SizedBox(
        width: UiSize.avatarXL,
        height: UiSize.avatarXL,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            UiAvatar(
              name: name,
              colorIndex: colorIndex,
              size: UiSize.avatarXL,
              image: image,
              ring: false,
            ),
            Positioned(
              right: -2,
              bottom: 1,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: ui.ink,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.photo_camera_outlined,
                  size: 16,
                  color: ui.bg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
