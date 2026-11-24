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
  bool _enlarged = false;
  Timer? _shrink;

  @override
  void dispose() {
    _shrink?.cancel();
    super.dispose();
  }

  void _enlarge() {
    _shrink?.cancel();
    setState(() => _enlarged = true);
    _shrink = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _enlarged = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.skin) {
      case PersonaSkinId.quietTransformer:
        if (!widget.showGhost) return const SizedBox.shrink();
        return const IgnorePointer(
          child: CustomPaint(
            key: ValueKey('overlay-ghost'),
            size: Size.infinite,
            painter: _GhostPainter(),
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
    return Stack(fit: StackFit.expand, children: [_pip(context, file)]);
  }

  Widget _pip(BuildContext context, String file) {
    final l10n = CameraL10n.of(context);
    final image = Image.file(
      File(file),
      key: const ValueKey('overlay-partner-photo'),
      fit: BoxFit.cover,
      excludeFromSemantics: true,
      errorBuilder: (_, _, _) => const SizedBox.expand(),
    );
    if (_enlarged) {
      // Half frame: the partner's photo fills the left half of the preview.
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: FractionallySizedBox(
          widthFactor: 0.5,
          heightFactor: 1,
          child: GestureDetector(
            key: const ValueKey('overlay-partner-half'),
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _enlarged = false),
            child: Semantics(
              button: true,
              label: l10n.camera_partnerPhoto,
              hint: l10n.camera_partnerPhotoShrinkHint,
              excludeSemantics: true,
              child: ColoredBox(color: UiCamera.bg, child: image),
            ),
          ),
        ),
      );
    }
    return PositionedDirectional(
      start: 14,
      top: CaptureSkinOverlay.pipTop,
      width: CaptureSkinOverlay.pipWidth,
      height: CaptureSkinOverlay.pipHeight,
      child: UiPressable(
        key: const ValueKey('overlay-partner-pip'),
        onPressed: _enlarge,
        semanticLabel: l10n.camera_partnerPhoto,
        semanticHint: l10n.camera_partnerPhotoEnlargeHint,
        excludeChildSemantics: true,
        borderRadius: BorderRadius.circular(UiRadius.thumb),
        minSize: const Size(UiSize.tap, UiSize.tap),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: UiCamera.bg,
            borderRadius: BorderRadius.circular(UiRadius.thumb),
            border: Border.all(color: UiCamera.outline, width: 2),
          ),
          child: image,
        ),
      ),
    );
  }
}

/// Day-1 silhouette (head and shoulders) to align today's pose against.
class _GhostPainter extends CustomPainter {
  const _GhostPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = UiCamera.ink.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final cx = size.width / 2;
    final head = Rect.fromCenter(
      center: Offset(cx, size.height * 0.30),
      width: size.width * 0.26,
      height: size.height * 0.2,
    );
    canvas.drawOval(head, paint);
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
    canvas.drawPath(shoulders, paint);
  }

  @override
  bool shouldRepaint(_GhostPainter old) => false;
}
