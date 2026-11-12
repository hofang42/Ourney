import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../tokens.dart';
import '../typography.dart';
import 'pressable.dart';

/// `.glass-chip`: frosted paper capsule with ink text, used over the always
/// dark camera (journey picker, "N today" counter). 48dp tall, label
/// ellipsizes at 250dp.
class UiGlassChip extends StatelessWidget {
  const UiGlassChip({
    required this.label,
    this.leading,
    this.trailing,
    this.onPressed,
    this.semanticLabel,
    super.key,
  });

  final String label;
  final IconData? leading;
  final IconData? trailing;
  final VoidCallback? onPressed;
  final String? semanticLabel;

  static const _paper = Color(0xE0FFFFFF);
  static const _ink = Color(0xFF111114);

  @override
  Widget build(BuildContext context) {
    final body = ClipRRect(
      borderRadius: BorderRadius.circular(UiRadius.capsule),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: UiSize.tap,
            maxWidth: 250,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: _paper,
            borderRadius: BorderRadius.circular(UiRadius.capsule),
            border: Border.all(color: const Color(0x1F000000)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[
                Icon(leading, size: 17, color: _ink),
                const SizedBox(width: 7),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.body(
                    size: 14,
                    weight: FontWeight.w600,
                    height: 1.3,
                    color: _ink,
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 7),
                Icon(trailing, size: 17, color: _ink),
              ],
            ],
          ),
        ),
      ),
    );
    if (onPressed == null) {
      return Semantics(label: semanticLabel ?? label, child: body);
    }
    return UiPressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel ?? label,
      excludeChildSemantics: true,
      centerChild: true,
      child: body,
    );
  }
}

/// `.day-hud`: 40dp paper pill pinned on the viewfinder ("Day 23").
class UiDayHud extends StatelessWidget {
  const UiDayHud(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 40, maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xE0FFFFFF),
        borderRadius: BorderRadius.circular(UiRadius.capsule),
        border: Border.all(color: const Color(0x33000000)),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: UiText.body(
          size: 14,
          weight: FontWeight.w600,
          height: 1.3,
          color: const Color(0xFF111114),
        ),
      ),
    );
  }
}

/// `.camera-tools .icon-button` / `.camera-secondary-controls .icon-button`:
/// white glyph button on the dark camera (flash, grid, flip).
class UiCameraTool extends StatelessWidget {
  const UiCameraTool({
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return UiPressable(
      onPressed: onPressed,
      semanticLabel: label,
      excludeChildSemantics: true,
      centerChild: true,
      child: Icon(
        icon,
        size: 22,
        color: onPressed == null ? const Color(0x66FFFFFF) : UiCamera.ink,
      ),
    );
  }
}

/// `.library-thumb`: 48dp rounded outline button opening the photo library.
class UiLibraryThumb extends StatelessWidget {
  const UiLibraryThumb({
    required this.label,
    required this.onPressed,
    this.image,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final ImageProvider<Object>? image;

  @override
  Widget build(BuildContext context) {
    return UiPressable(
      onPressed: onPressed,
      semanticLabel: label,
      excludeChildSemantics: true,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x99FFFFFF)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: image != null
              ? Image(image: image!, fit: BoxFit.cover)
              : const ColoredBox(
                  color: Color(0x22FFFFFF),
                  child: Center(
                    child: Icon(
                      Icons.photo_library_outlined,
                      size: 20,
                      color: UiCamera.ink,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

/// `.page-dots`: one dot per unfinished journey; the current one is a wide
/// white pill.
class UiPageDots extends StatelessWidget {
  const UiPageDots({required this.count, required this.index, super.key});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: 12,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < count; i++)
              AnimatedContainer(
                duration: UiMotion.of(context, UiMotion.press),
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                width: i == index ? 16 : 5,
                height: 5,
                decoration: BoxDecoration(
                  color: i == index ? UiCamera.ink : const Color(0x55FFFFFF),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
