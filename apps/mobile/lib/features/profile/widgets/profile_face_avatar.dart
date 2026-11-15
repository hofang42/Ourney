import 'package:flutter/material.dart';

import '../../../ui/ui.dart';

/// Avatar swatch colors of ProfileSetupFlow (`avatarColors` in flow.tsx).
const List<Color> profileAvatarColors = [
  Color(0xFF7EE8A2),
  Color(0xFFFFD84D),
  Color(0xFFCF9FFF),
  Color(0xFFFFB347),
  Color(0xFFFF7E7E),
  Color(0xFF7EC8E3),
];

const _faceInk = Color(0xFF1A1A1A);

/// `.profile-avatar-large`: 96dp blob (35/50/42/56% corners), 2dp ink outline,
/// 4dp hard shadow, hair, eyes and smile. A picked [image] replaces the face.
class ProfileFaceAvatar extends StatelessWidget {
  const ProfileFaceAvatar({required this.color, this.image, super.key});

  final Color color;
  final ImageProvider<Object>? image;

  static const double size = 96;

  static const _radius = BorderRadius.only(
    topLeft: Radius.elliptical(size * 0.35, size * 0.35),
    topRight: Radius.elliptical(size * 0.50, size * 0.50),
    bottomRight: Radius.elliptical(size * 0.42, size * 0.42),
    bottomLeft: Radius.elliptical(size * 0.56, size * 0.56),
  );

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: _radius,
        border: ui.stickerBorder(),
        boxShadow: ui.hardShadow(),
        image: image == null
            ? null
            : DecorationImage(image: image!, fit: BoxFit.cover),
      ),
      child: image != null
          ? null
          : Stack(
              clipBehavior: Clip.none,
              children: [
                // Offsets follow the CSS (measured from the padding box).
                Positioned(
                  left: 17,
                  top: 17,
                  child: Container(
                    width: 58,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Color(0xFF33251F),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.elliptical(29, 14),
                        topRight: Radius.elliptical(29, 14),
                        bottomRight: Radius.elliptical(20, 10),
                        bottomLeft: Radius.elliptical(22, 11),
                      ),
                    ),
                  ),
                ),
                for (final left in const [31.0, 54.0])
                  Positioned(
                    left: left,
                    top: 50,
                    child: Container(
                      width: 7,
                      height: 9,
                      decoration: BoxDecoration(
                        color: _faceInk,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                Positioned(
                  left: 35,
                  bottom: 21,
                  child: Container(
                    width: 22,
                    height: 11,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: _faceInk, width: 3),
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(11),
                        bottomRight: Radius.circular(11),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// `.avatar-options`: the six color swatches (48dp, 2dp `#1A1A1A` outline;
/// the selected one 3dp with a 2dp ink hard shadow and a check).
class ProfileAvatarSwatches extends StatelessWidget {
  const ProfileAvatarSwatches({
    required this.selected,
    required this.onSelected,
    required this.label,
    required this.itemLabel,
    super.key,
  });

  final int selected;
  final ValueChanged<int> onSelected;
  final String label;
  final String Function(int n) itemLabel;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return Semantics(
      container: true,
      label: label,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 7,
        runSpacing: 7,
        children: [
          for (var i = 0; i < profileAvatarColors.length; i++)
            UiPressable(
              key: ValueKey('profile-avatar-color-$i'),
              onPressed: () => onSelected(i),
              selected: selected == i,
              semanticLabel: itemLabel(i + 1),
              excludeChildSemantics: true,
              borderRadius: BorderRadius.circular(UiRadius.capsule),
              minSize: const Size.square(48),
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: profileAvatarColors[i],
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _faceInk,
                    width: selected == i ? 3 : UiBorder.standard,
                  ),
                  boxShadow: selected == i
                      ? UiShadow.hard(ui.outline, UiShadow.tiny)
                      : null,
                ),
                child: selected == i
                    ? const OurneyIcon(
                        name: 'check',
                        size: 17,
                        flat: true,
                        color: _faceInk,
                      )
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}
