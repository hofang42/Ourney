import 'package:flutter/material.dart';

import '../../../ui/ui.dart';

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
