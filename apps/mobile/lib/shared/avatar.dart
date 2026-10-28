import 'package:flutter/material.dart';

import '../app/theme/tokens.dart';
import 'color_utils.dart';

/// Circular avatar: image or deterministic initials on a solid color from
/// the V1.0 avatar palette. [checkedIn] adds a success ring plus a check
/// badge (not color-only).
class Avatar extends StatelessWidget {
  const Avatar({
    required this.name,
    this.image,
    this.size = 44,
    this.checkedIn = false,
    super.key,
  });

  final String name;
  final ImageProvider? image;
  final double size;
  final bool checkedIn;

  /// Avatar fills from the V1.0 design.
  static const palette = [
    Color(0xFFE15B72),
    Color(0xFF6D4BF0),
    Color(0xFF2AA7E0),
    Color(0xFF10B981),
    Color(0xFFFF9F1C),
  ];

  static String initialsOf(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final c = OurneyColors.of(context);
    final tint = palette[name.hashCode.abs() % palette.length];
    final ring = checkedIn ? 3.0 : 0.0;
    final inner = size - ring * 2 - (checkedIn ? 2 : 0);

    final face = CircleAvatar(
      radius: inner / 2,
      backgroundColor: tint,
      foregroundImage: image,
      child: Text(
        initialsOf(name),
        style: TextStyle(
          fontFamily: 'BeVietnamPro',
          fontWeight: FontWeight.w700,
          fontSize: inner * 0.38,
          color: readableOn(tint),
        ),
      ),
    );

    return Semantics(
      label: name,
      image: true,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(checkedIn ? 1 : 0),
              decoration: checkedIn
                  ? BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: c.success, width: ring),
                    )
                  : null,
              child: face,
            ),
            if (checkedIn)
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: size * 0.34,
                  height: size * 0.34,
                  decoration: BoxDecoration(
                    color: c.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: c.bg, width: 2),
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: size * 0.22,
                    color: OurneyColors.light.ink,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
