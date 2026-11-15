import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../ui/ui.dart';
import 'l10n/generated/camera_localizations.dart';

/// The persona HUD drawn over the live preview (CLAUDE.md section 4):
/// ghost-align vault (quiet), study timer (squad), film stamp (memory),
/// half-frame duo (couple), bold HUD / film strip / minimal stamp (flexer)
/// and nothing at all for the zero-text minimalist. Always-dark camera
/// chrome, so it reads on any preview in light and dark themes.
class CaptureSkinOverlay extends StatefulWidget {
  const CaptureSkinOverlay({
    required this.skin,
    required this.dayNumber,
    required this.streak,
    super.key,
  });

  final PersonaSkinId skin;
  final int dayNumber;
  final int streak;

  @override
  State<CaptureSkinOverlay> createState() => _CaptureSkinOverlayState();
}

enum _FlexHud { bold, stamp, strip }

class _CaptureSkinOverlayState extends State<CaptureSkinOverlay> {
  bool _ghost = true;
  _FlexHud _hud = _FlexHud.bold;

  @override
  Widget build(BuildContext context) {
    return switch (widget.skin) {
      PersonaSkinId.quietTransformer => _quiet(context),
      PersonaSkinId.accountabilitySquad => _squad(context),
      PersonaSkinId.memoryCollectors => _memory(context),
      PersonaSkinId.coupleRituals => _couple(context),
      PersonaSkinId.aestheticFlexer => _flexer(context),
      PersonaSkinId.minimalistHabit => const SizedBox.shrink(
        key: ValueKey('overlay-zero-text'),
      ),
    };
  }

  String _time() {
    final n = clock.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(n.hour)}:${two(n.minute)}';
  }

  String _date() {
    final n = clock.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return "${two(n.day)}.${two(n.month)}.'${two(n.year % 100)}";
  }

  Widget _quiet(BuildContext context) {
    final l10n = CameraL10n.of(context);
    return Stack(
      key: const ValueKey('overlay-quiet'),
      fit: StackFit.expand,
      children: [
        if (_ghost)
          const IgnorePointer(
            child: CustomPaint(
              key: ValueKey('overlay-ghost'),
              painter: _GhostPainter(),
            ),
          ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 44,
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 4,
            children: [
              _Chip(
                label: _ghost ? l10n.camera_ghostOn : l10n.camera_ghostOff,
                glyph: _ghost ? 'eye' : 'eye-off',
                onPressed: () => setState(() => _ghost = !_ghost),
                keyName: 'overlay-ghost-toggle',
              ),
              _Chip(
                label: l10n.camera_privateVault,
                glyph: 'lock',
                keyName: 'overlay-vault',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _squad(BuildContext context) {
    final l10n = CameraL10n.of(context);
    return Stack(
      key: const ValueKey('overlay-squad'),
      fit: StackFit.expand,
      children: [
        Positioned(
          left: 16,
          right: 16,
          bottom: 44,
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 4,
            children: [
              _Chip(
                label: l10n.camera_studyStreak(widget.streak),
                glyph: 'flame',
                keyName: 'overlay-study',
              ),
              _Mono(_time(), keyName: 'overlay-time'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _memory(BuildContext context) {
    final l10n = CameraL10n.of(context);
    return Stack(
      key: const ValueKey('overlay-memory'),
      fit: StackFit.expand,
      children: [
        Positioned(
          left: 16,
          bottom: 44,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: _Mono(l10n.camera_filmRoll, keyName: 'overlay-film'),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: _Mono(
                  _date(),
                  keyName: 'overlay-film-date',
                  color: const Color(0xFFFFB347),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _couple(BuildContext context) {
    final l10n = CameraL10n.of(context);
    return Stack(
      key: const ValueKey('overlay-couple'),
      fit: StackFit.expand,
      children: [
        // Left half: the partner's photo slot; right half stays live.
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FractionallySizedBox(
            widthFactor: 0.5,
            heightFactor: 1,
            child: ColoredBox(
              color: UiCamera.bg.withValues(alpha: 0.72),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Center(
                  child: Text(
                    l10n.camera_partnerWaiting,
                    textAlign: TextAlign.center,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                    style: UiText.body(
                      size: 13,
                      height: 1.4,
                      color: UiCamera.ink,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const Center(
          child: SizedBox(
            width: 2,
            child: ColoredBox(
              key: ValueKey('overlay-half-divider'),
              color: UiCamera.outline,
              child: SizedBox.expand(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _flexer(BuildContext context) {
    final l10n = CameraL10n.of(context);
    final labels = {
      _FlexHud.bold: l10n.camera_hudBold,
      _FlexHud.stamp: l10n.camera_hudStamp,
      _FlexHud.strip: l10n.camera_hudStrip,
    };
    return Stack(
      key: const ValueKey('overlay-flexer'),
      fit: StackFit.expand,
      children: [
        if (_hud == _FlexHud.strip)
          const IgnorePointer(
            child: CustomPaint(
              key: ValueKey('overlay-film-strip'),
              painter: _StripPainter(),
            ),
          ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 84,
          child: switch (_hud) {
            _FlexHud.bold => _Chip(
              label: l10n.camera_dayStreakBold(widget.dayNumber, widget.streak),
              glyph: 'flame',
              keyName: 'overlay-hud-bold',
            ),
            _FlexHud.stamp => _Mono(
              '${l10n.camera_dayHud(widget.dayNumber)} · ${_date()}',
              keyName: 'overlay-hud-stamp',
            ),
            _FlexHud.strip => _Mono(
              l10n.camera_dayHud(widget.dayNumber),
              keyName: 'overlay-hud-strip',
            ),
          },
        ),
        Positioned(
          left: 8,
          right: 8,
          bottom: 40,
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 2,
            children: [
              for (final h in _FlexHud.values)
                _Chip(
                  label: labels[h]!,
                  glyph: _hud == h ? 'check' : null,
                  onPressed: () => setState(() => _hud = h),
                  keyName: 'overlay-hud-pick-${h.name}',
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Glass pill on the preview; [onPressed] makes it a 48dp-tall toggle.
class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.keyName,
    this.glyph,
    this.onPressed,
  });

  final String label;
  final String keyName;
  final String? glyph;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final chip = UiGlassChip(
      key: ValueKey(keyName),
      label: label,
      leadingGlyph: glyph,
      onPressed: onPressed,
    );
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width - 64,
      ),
      child: chip,
    );
  }
}

/// Mono caption stamped on the preview (time, film roll, date).
class _Mono extends StatelessWidget {
  const _Mono(this.text, {required this.keyName, this.color = UiCamera.ink});

  final String text;
  final String keyName;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      key: ValueKey(keyName),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style:
          UiText.body(
            size: 13,
            weight: FontWeight.w700,
            height: 1.35,
            color: color,
          ).copyWith(
            fontFamily: UiFonts.mono,
            shadows: const [Shadow(color: UiCamera.shadow, blurRadius: 3)],
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

/// Film-strip sprocket holes along both short edges.
class _StripPainter extends CustomPainter {
  const _StripPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final band = Paint()..color = UiCamera.bg.withValues(alpha: 0.7);
    final hole = Paint()..color = UiCamera.ink.withValues(alpha: 0.7);
    canvas
      ..drawRect(Rect.fromLTWH(0, 0, 14, size.height), band)
      ..drawRect(Rect.fromLTWH(size.width - 14, 0, 14, size.height), band);
    for (var y = 10.0; y < size.height - 8; y += 22) {
      canvas
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(4, y, 6, 10),
            const Radius.circular(2),
          ),
          hole,
        )
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(size.width - 10, y, 6, 10),
            const Radius.circular(2),
          ),
          hole,
        );
    }
  }

  @override
  bool shouldRepaint(_StripPainter old) => false;
}
