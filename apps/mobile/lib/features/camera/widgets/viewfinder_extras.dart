import 'dart:io';

import 'package:flutter/material.dart';

import '../../../ui/ui.dart';
import '../l10n/generated/camera_localizations.dart';

/// 3x3 framing grid over the viewfinder.
class CameraGrid extends StatelessWidget {
  const CameraGrid({super.key});

  @override
  Widget build(BuildContext context) =>
      const IgnorePointer(child: CustomPaint(painter: _GridPainter()));
}

class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = UiCamera.ink.withValues(alpha: 0.4)
      ..strokeWidth = 1;
    for (var i = 1; i < 3; i++) {
      final x = size.width * i / 3;
      final y = size.height * i / 3;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}

/// Figma `camera-latest-photo`: the latest photo of today in the bottom-left
/// corner of the viewfinder with the day's photo count ("3 ảnh", bugs.md A1
/// item 4). Several photos per day are allowed (FR-C7), so this shows that
/// the earlier ones are kept. Tapping opens the journey.
class LatestPhotoThumb extends StatelessWidget {
  const LatestPhotoThumb({
    required this.count,
    required this.onPressed,
    this.file,
    super.key,
  });

  final int count;
  final String? file;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = CameraL10n.of(context);
    final path = file;
    return UiPressable(
      onPressed: onPressed,
      semanticLabel: l10n.camera_openToday(count),
      excludeChildSemantics: true,
      borderRadius: BorderRadius.circular(UiRadius.thumb),
      child: SizedBox(
        width: 56,
        height: 56,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: UiCamera.dock,
                  borderRadius: BorderRadius.circular(UiRadius.thumb),
                  border: Border.all(
                    color: UiCamera.outline,
                    width: UiBorder.standard,
                  ),
                  boxShadow: UiShadow.hard(UiCamera.shadow, UiShadow.tiny),
                ),
                child: path == null || path.isEmpty
                    ? const Center(
                        child: OurneyIcon(
                          name: 'image',
                          flat: true,
                          size: 22,
                          color: UiCamera.ink,
                        ),
                      )
                    : Image.file(
                        File(path),
                        fit: BoxFit.cover,
                        excludeFromSemantics: true,
                        errorBuilder: (_, _, _) => const SizedBox.expand(),
                      ),
              ),
            ),
            Positioned(
              right: -6,
              bottom: -6,
              child: Container(
                key: const ValueKey('capture-today-count'),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: UiCamera.outline,
                  borderRadius: BorderRadius.circular(UiRadius.capsule),
                  border: Border.all(color: UiCamera.shadow),
                ),
                child: Text(
                  l10n.camera_photoCount(count),
                  maxLines: 1,
                  style: UiText.body(
                    size: 11,
                    weight: FontWeight.w700,
                    height: 1.3,
                    color: UiCamera.shadow,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
