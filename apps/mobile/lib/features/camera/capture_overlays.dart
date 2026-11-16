import 'dart:async';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../ui/ui.dart';
import 'l10n/generated/camera_localizations.dart';

/// The persona HUD drawn over the live preview (CLAUDE.md section 4):
/// ghost-align vault (quiet), study proof stamp (squad), film stamp (memory),
/// half-frame duo (couple), bold HUD / film strip / minimal stamp (flexer)
/// and nothing at all for the zero-text minimalist. Always-dark camera
/// chrome, so it reads on any preview in light and dark themes.
class CaptureSkinOverlay extends StatefulWidget {
  const CaptureSkinOverlay({
    required this.skin,
    required this.dayNumber,
    required this.streak,
    this.lastPace,
    this.lastWeight,
    this.lastWeightKg,
    this.onWeightChanged,
    this.lastKm,
    this.lastMinutes,
    this.partnerPhotoFile,
    super.key,
  });

  final PersonaSkinId skin;
  final int dayNumber;
  final int streak;

  /// Flexer: pace of the last check-in that logged one (e.g. `5:30`).
  final String? lastPace;

  /// Quiet: last weigh-in, already formatted with its unit. Display only:
  /// saving a weight stays in the check-in flow.
  final String? lastWeight;

  /// Quiet: last weigh-in as a number; the slider starts from it.
  final double? lastWeightKg;

  /// Quiet: called with the slider value (0.1 step). Null hides the slider.
  final ValueChanged<double>? onWeightChanged;

  /// Flexer: distance (km) of the last check-in that logged one.
  final double? lastKm;

  /// Squad: study minutes logged at the last check-in (Post extras).
  final int? lastMinutes;

  /// Couple: local file of the partner's latest photo, when there is one.
  final String? partnerPhotoFile;

  @override
  State<CaptureSkinOverlay> createState() => _CaptureSkinOverlayState();
}

enum _FlexHud { bold, stamp, strip }

class _CaptureSkinOverlayState extends State<CaptureSkinOverlay> {
  bool _ghost = true;
  _FlexHud _hud = _FlexHud.bold;
  late double _kg = _clampKg(widget.lastWeightKg ?? 60);

  static double _clampKg(double v) =>
      ((v.clamp(30.0, 200.0)) * 10).round() / 10;

  // Squad: the clock stamp (Figma `squad-camera-time`) follows the minute.
  // Bug #9: this used to be a stopwatch counting from when the camera
  // opened, which measured nothing the squad cares about.
  Timer? _minute;

  @override
  void initState() {
    super.initState();
    if (widget.skin == PersonaSkinId.accountabilitySquad) {
      _minute = Timer.periodic(const Duration(seconds: 20), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _minute?.cancel();
    super.dispose();
  }

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
        if (widget.lastWeight != null || widget.onWeightChanged != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 92,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.onWeightChanged != null)
                  _weightSlider(context, l10n),
                if (widget.lastWeight != null)
                  _Mono(
                    l10n.camera_lastWeight(widget.lastWeight!),
                    keyName: 'overlay-weight',
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _weightSlider(BuildContext context, CameraL10n l10n) {
    final value = '${_kg.toStringAsFixed(1)} kg';
    return Row(
      key: const ValueKey('overlay-weight-slider-row'),
      children: [
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: UiCamera.ink,
              inactiveTrackColor: UiCamera.outline,
              thumbColor: UiCamera.ink,
              overlayColor: UiCamera.ink.withValues(alpha: 0.2),
            ),
            child: Semantics(
              label: l10n.camera_weightSliderLabel,
              value: value,
              child: SizedBox(
                height: 48,
                child: Slider(
                  key: const ValueKey('overlay-weight-slider'),
                  min: 30,
                  max: 200,
                  divisions: 1700,
                  value: _kg,
                  semanticFormatterCallback: (v) =>
                      '${v.toStringAsFixed(1)} kg',
                  onChanged: (v) {
                    final kg = _clampKg(v);
                    setState(() => _kg = kg);
                    widget.onWeightChanged?.call(kg);
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        ExcludeSemantics(child: _Mono(value, keyName: 'overlay-weight-value')),
      ],
    );
  }

  /// Accountability Squad (`studyTimerSnap`, Figma squad camera): a proof
  /// stamp the squad can trust, the wall-clock time of the shot, plus what
  /// the member studied last time and the streak at stake. No stopwatch.
  Widget _squad(BuildContext context) {
    final l10n = CameraL10n.of(context);
    final minutes = widget.lastMinutes;
    return Stack(
      key: const ValueKey('overlay-squad'),
      fit: StackFit.expand,
      children: [
        Positioned(
          left: 16,
          right: 16,
          top: 64,
          child: Center(
            child: Text(
              _time(),
              key: const ValueKey('overlay-time'),
              maxLines: 1,
              style:
                  UiText.body(
                    size: 44,
                    weight: FontWeight.w700,
                    height: 1.3,
                    color: UiCamera.ink,
                  ).copyWith(
                    fontFamily: UiFonts.mono,
                    shadows: const [
                      Shadow(color: UiCamera.shadow, offset: Offset(2, 2)),
                    ],
                  ),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 84,
          child: Center(
            child: _Chip(
              label: minutes == null
                  ? l10n.camera_squadStreak(widget.streak)
                  : l10n.camera_squadLastStudy(minutes, widget.streak),
              glyph: minutes == null ? 'flame' : 'book',
              keyName: 'overlay-study',
            ),
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
              child: widget.partnerPhotoFile != null
                  ? Image.file(
                      File(widget.partnerPhotoFile!),
                      key: const ValueKey('overlay-partner-photo'),
                      fit: BoxFit.cover,
                      excludeFromSemantics: true,
                      errorBuilder: (_, _, _) => const SizedBox.expand(),
                    )
                  : Padding(
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
        if (widget.lastPace != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 124,
            child: _Mono(
              widget.lastKm == null
                  ? l10n.camera_lastPace(widget.lastPace!)
                  : l10n.camera_lastPaceKm(
                      widget.lastPace!,
                      widget.lastKm!.toStringAsFixed(1),
                    ),
              keyName: 'overlay-pace',
            ),
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
