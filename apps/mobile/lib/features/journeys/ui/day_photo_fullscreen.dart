import 'package:flutter/material.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../ui/ui.dart';
import 'journey_photo.dart';

/// Full image on the fixed camera canvas, independent of journey skin.
class DayPhotoFullscreen extends StatefulWidget {
  const DayPhotoFullscreen({required this.checkIn, super.key});
  final CheckIn checkIn;
  @override
  State<DayPhotoFullscreen> createState() => _DayPhotoFullscreenState();
}

class _DayPhotoFullscreenState extends State<DayPhotoFullscreen>
    with SingleTickerProviderStateMixin {
  final _transform = TransformationController();
  late final _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  )..addListener(_tick);
  Matrix4Tween? _tween;
  Offset _tap = Offset.zero;
  void _tick() {
    _transform.value = _tween!.transform(
      Curves.easeOut.transform(_animation.value),
    );
  }

  void _toggle() {
    _animation.stop();
    final zoomed = _transform.value.getMaxScaleOnAxis() > 1.01;
    final target = zoomed
        ? Matrix4.identity()
        : (Matrix4.identity()
            ..setEntry(0, 0, 2.5)
            ..setEntry(1, 1, 2.5)
            ..setEntry(0, 3, -_tap.dx * 1.5)
            ..setEntry(1, 3, -_tap.dy * 1.5));
    if (UiMotion.reduced(context)) {
      _transform.value = target;
      return;
    }
    _tween = Matrix4Tween(begin: _transform.value, end: target);
    _animation.forward(from: 0);
  }

  @override
  void dispose() {
    _animation.dispose();
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: UiCamera.bg,
    body: Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onDoubleTapDown: (d) => _tap = d.localPosition,
          onDoubleTap: _toggle,
          child: InteractiveViewer(
            transformationController: _transform,
            minScale: 1,
            maxScale: 4,
            onInteractionStart: (_) => _animation.stop(),
            child: JourneyPhoto(
              checkIn: widget.checkIn,
              thumbnail: false,
              fit: BoxFit.contain,
            ),
          ),
        ),
        PositionedDirectional(
          top: 0,
          end: UiSpace.sm,
          child: SafeArea(
            child: UiIconButton(
              glyph: const OurneyIcon(
                name: 'close',
                color: UiCamera.onPhoto,
                flat: true,
              ),
              label: AppLocalizations.of(context).common_close,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ],
    ),
  );
}
