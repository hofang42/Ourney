import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../ui/ui.dart';
import 'l10n/generated/camera_localizations.dart';

/// What is drawn over the live preview, apart from the status pill and the
/// streak chip. One shared camera for every persona (CLAUDE.md section 4):
/// the persona only recolors the accent, plus two functional guides:
///
/// - quiet transformer: the day-1 ghost silhouette ([showGhost], toggled by
///   the top-bar ghost tool);
/// - couple rituals: the partner's latest photo as a 72x96 PiP thumbnail at
///   the top-start corner. Tap it to see it as a half frame for 3s.
///
/// Everything else is empty: no stamps, clocks or HUD pickers.
class CaptureSkinOverlay extends StatefulWidget {
  const CaptureSkinOverlay({
    required this.skin,
    this.showGhost = true,
    this.partnerPhotoFile,
    super.key,
  });

  final PersonaSkinId skin;

  /// Quiet: draw the day-1 silhouette guide.
  final bool showGhost;

  /// Couple: local file of the partner's latest photo, when there is one.
  final String? partnerPhotoFile;

  /// PiP thumbnail size and its inset from the preview corner.
  static const double pipWidth = 72;
  static const double pipHeight = 96;
  static const double pipTop = 52;

  @override
  State<CaptureSkinOverlay> createState() => _CaptureSkinOverlayState();
}

class _CaptureSkinOverlayState extends State<CaptureSkinOverlay> {
  final GlobalKey _frameKey = GlobalKey();
  bool _enlarged = false;
  Timer? _shrink;

  @override
  void dispose() {
    _shrink?.cancel();
    super.dispose();
  }

  void _enlarge() {
    _shrink?.cancel();
    unawaited(UiHaptics.selection());
    setState(() => _enlarged = true);
    _shrink = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _enlarged = false);
    });
  }

  void _collapse() {
    _shrink?.cancel();
    unawaited(UiHaptics.selection());
    setState(() => _enlarged = false);
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.skin) {
      case PersonaSkinId.quietTransformer:
        return IgnorePointer(
          child: AnimatedOpacity(
            key: const ValueKey('overlay-ghost-fade'),
            opacity: widget.showGhost ? 1.0 : 0.0,
            duration: UiMotion.fadeOf(context, UiMotion.fast),
            curve: UiCurves.easeOutStrong,
            child: CustomPaint(
              key: widget.showGhost ? const ValueKey('overlay-ghost') : null,
              size: Size.infinite,
              painter: const _GhostPainter(),
            ),
          ),
        );
      case PersonaSkinId.coupleRituals:
        return _partner(context);
      case PersonaSkinId.accountabilitySquad:
      case PersonaSkinId.memoryCollectors:
      case PersonaSkinId.aestheticFlexer:
      case PersonaSkinId.minimalistHabit:
        return const SizedBox.shrink(key: ValueKey('overlay-none'));
    }
  }

  Widget _partner(BuildContext context) {
    final file = widget.partnerPhotoFile;
    if (file == null) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 240.0;
        final maxH =
            constraints.maxHeight.isFinite ? constraints.maxHeight : 320.0;
        return Stack(
          fit: StackFit.expand,
          children: [_pip(context, file, maxW, maxH)],
        );
      },
    );
  }

  Widget _pip(
    BuildContext context,
    String file,
    double maxW,
    double maxH,
  ) {
    final l10n = CameraL10n.of(context);
    final morphDuration = UiMotion.of(context, UiMotion.sheetEnter);
    final textDirection = Directionality.of(context);
    final targetRadius = (_enlarged
            ? const BorderRadiusDirectional.horizontal(
                start: Radius.circular(UiRadius.viewfinder),
              )
            : BorderRadiusDirectional.circular(UiRadius.thumb))
        .resolve(textDirection);
    final image = Image.file(
      File(file),
      key: const ValueKey('overlay-partner-photo'),
      fit: BoxFit.cover,
      excludeFromSemantics: true,
      errorBuilder: (_, _, _) => const SizedBox.expand(),
    );

    final frame = AnimatedContainer(
      key: _frameKey,
      duration: morphDuration,
      curve: UiCurves.drawer,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: UiCamera.bg,
        borderRadius: targetRadius,
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: targetRadius,
        border: Border.all(
          color: UiCamera.outline.withValues(alpha: _enlarged ? 0.0 : 1.0),
          width: UiBorder.standard,
        ),
      ),
      child: image,
    );

    return AnimatedPositionedDirectional(
      duration: morphDuration,
      curve: UiCurves.drawer,
      start: _enlarged ? 0.0 : 14.0,
      top: _enlarged ? 0.0 : CaptureSkinOverlay.pipTop,
      width: _enlarged ? maxW * 0.5 : CaptureSkinOverlay.pipWidth,
      height: _enlarged ? maxH : CaptureSkinOverlay.pipHeight,
      child: _enlarged
          ? GestureDetector(
              key: const ValueKey('overlay-partner-half'),
              behavior: HitTestBehavior.opaque,
              onTap: _collapse,
              child: Semantics(
                button: true,
                label: l10n.camera_partnerPhoto,
                hint: l10n.camera_partnerPhotoShrinkHint,
                excludeSemantics: true,
                child: frame,
              ),
            )
          : UiPressable(
              key: const ValueKey('overlay-partner-pip'),
              onPressed: _enlarge,
              pressOffset: UiShadow.tiny,
              pressScale: 1.0,
              semanticLabel: l10n.camera_partnerPhoto,
              semanticHint: l10n.camera_partnerPhotoEnlargeHint,
              excludeChildSemantics: true,
              borderRadius: BorderRadius.circular(UiRadius.thumb),
              minSize: const Size(UiSize.tap, UiSize.tap),
              child: frame,
            ),
    );
  }
}

/// Day-1 silhouette (head and shoulders) to align today's pose against.
class _GhostPainter extends CustomPainter {
  const _GhostPainter();

  static final Paint _paint = Paint()
    ..color = UiCamera.ink.withValues(alpha: 0.55)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final head = Rect.fromCenter(
      center: Offset(cx, size.height * 0.30),
      width: size.width * 0.26,
      height: size.height * 0.2,
    );
    canvas.drawOval(head, _paint);
    final shoulders = Path()
      ..moveTo(size.width * 0.14, size.height * 0.78)
      ..cubicTo(
        size.width * 0.14,
        size.height * 0.56,
        size.width * 0.32,
        size.height * 0.5,
        cx,
        size.height * 0.5,
      )
      ..cubicTo(
        size.width * 0.68,
        size.height * 0.5,
        size.width * 0.86,
        size.height * 0.56,
        size.width * 0.86,
        size.height * 0.78,
      );
    canvas.drawPath(shoulders, _paint);
  }

  @override
  bool shouldRepaint(_GhostPainter old) => false;
}
