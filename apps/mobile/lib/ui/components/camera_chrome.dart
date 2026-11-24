import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../tokens.dart';
import '../typography.dart';
import 'ourney_icons.dart';
import 'pressable.dart';

/// `.glass-chip`: frosted paper capsule with ink text, used over the always
/// dark camera (journey picker, "N today" counter). 48dp tall, label
/// ellipsizes at 250dp.
class UiGlassChip extends StatelessWidget {
  const UiGlassChip({
    required this.label,
    @Deprecated('Use leadingGlyph (an OurneyIcon name)') this.leading,
    @Deprecated('Use trailingGlyph (an OurneyIcon name)') this.trailing,
    this.leadingGlyph,
    this.trailingGlyph,
    this.onPressed,
    this.semanticLabel,
    super.key,
  });

  final String label;
  final IconData? leading;
  final IconData? trailing;

  /// [OurneyIcon] names drawn flat in ink.
  final String? leadingGlyph;
  final String? trailingGlyph;
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
              if (leading != null || leadingGlyph != null) ...[
                leadingGlyph != null
                    ? OurneyIcon(
                        name: leadingGlyph!,
                        size: 18,
                        flat: true,
                        color: _ink,
                      )
                    : Icon(leading, size: 17, color: _ink),
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
              if (trailing != null || trailingGlyph != null) ...[
                const SizedBox(width: 7),
                trailingGlyph != null
                    ? OurneyIcon(
                        name: trailingGlyph!,
                        size: 18,
                        flat: true,
                        color: _ink,
                      )
                    : Icon(trailing, size: 17, color: _ink),
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
    @Deprecated('Use glyph (an OurneyIcon name)') this.icon,
    this.glyph,
    required this.label,
    required this.onPressed,
    this.emphasis = UiCameraToolEmphasis.none,
    this.accent,
    this.onAccent,
    super.key,
  }) : assert(icon != null || glyph != null, 'icon or glyph is required');

  final IconData? icon;

  /// [OurneyIcon] name, drawn flat in white (64% when disabled).
  final String? glyph;
  final String label;
  final VoidCallback? onPressed;

  /// Toggle state shown by shape, not color alone: outline ring (e.g. flash
  /// auto) or a solid white disc with a dark glyph (flash on).
  final UiCameraToolEmphasis emphasis;

  /// Journey accent: fills the disc of a [UiCameraToolEmphasis.filled] tool
  /// (flash on, grid on) instead of white. The glyph uses [onAccent].
  final Color? accent;

  /// Glyph colour on the [accent] disc (the journey style's `onAccent`);
  /// defaults to the dark camera bg, which fails contrast on accents whose
  /// label colour is white.
  final Color? onAccent;

  @override
  Widget build(BuildContext context) {
    final filled = emphasis == UiCameraToolEmphasis.filled;
    final color = onPressed == null
        ? const Color(0x66FFFFFF)
        : filled
        ? (accent == null ? UiCamera.bg : (onAccent ?? UiCamera.bg))
        : UiCamera.ink;
    final glyphWidget = glyph != null
        ? OurneyIcon(name: glyph!, size: 22, flat: true, color: color)
        : Icon(icon, size: 22, color: color);
    return UiPressable(
      onPressed: onPressed,
      semanticLabel: label,
      selected: emphasis != UiCameraToolEmphasis.none,
      excludeChildSemantics: true,
      centerChild: true,
      child: emphasis == UiCameraToolEmphasis.none
          ? glyphWidget
          : Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled ? (accent ?? UiCamera.ink) : null,
                border: Border.all(
                  color: filled ? (accent ?? UiCamera.ink) : UiCamera.ink,
                  width: 2,
                ),
              ),
              child: glyphWidget,
            ),
    );
  }
}

/// State drawn around a [UiCameraTool] glyph.
enum UiCameraToolEmphasis { none, outline, filled }

/// Colour of a [UiCameraStatusPill].
enum UiCameraStatusTone { neutral, danger }

/// Transient state label inside the viewfinder (flash mode, "no flash",
/// capture failed). It replaces the toast, which landed on the shutter: it
/// sits at the top of the preview, never near the dock.
///
/// Glass dark capsule, at least 32dp tall, glyph plus up to two lines of text. Fades in over
/// 150ms and out over 200ms (no fade under Reduce Motion). It is
/// hidden from the semantics tree: callers announce the message with
/// `SemanticsService.sendAnnouncement` (not a live region, which can move
/// VoiceOver focus) on every show, repeats included. The caller owns the hold timer
/// (1.2s, 1.5s under Reduce Motion) and flips [visible].
class UiCameraStatusPill extends StatelessWidget {
  const UiCameraStatusPill({
    required this.message,
    required this.visible,
    this.glyph,
    this.tone = UiCameraStatusTone.neutral,
    super.key,
  });

  final String message;
  final bool visible;

  /// [OurneyIcon] name drawn before the text.
  final String? glyph;
  final UiCameraStatusTone tone;

  static const double height = 32;

  @override
  Widget build(BuildContext context) {
    final danger = tone == UiCameraStatusTone.danger;
    final color = danger ? OurneyUi.dark.danger : UiCamera.ink;
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: UiMotion.of(
          context,
          Duration(milliseconds: visible ? 150 : 200),
        ),
        child: ExcludeSemantics(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(UiRadius.capsule),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                key: const ValueKey('ui-camera-status-pill'),
                constraints: const BoxConstraints(minHeight: height),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xB3000000),
                  borderRadius: BorderRadius.circular(UiRadius.capsule),
                  border: Border.all(
                    color: danger ? color : UiCamera.dockBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (glyph != null) ...[
                      OurneyIcon(
                        name: glyph!,
                        size: 16,
                        flat: true,
                        color: color,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: UiText.body(
                          size: 13,
                          weight: FontWeight.w600,
                          height: 1.3,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
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
                    child: OurneyIcon(
                      name: 'gallery',
                      size: 20,
                      flat: true,
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
                  color: i == index
                      ? UiCamera.ink
                      : UiCamera.ink.withValues(alpha: 0.33),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
