import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens.dart';
import '../typography.dart';
import 'ourney_icons.dart';
import 'pressable.dart';

/// `.flow-error` / `.username-status`: bare warning icon (20) plus 13dp
/// danger text, no box. [success] gives the `.available` variant (check icon,
/// success color).
class UiFlowError extends StatelessWidget {
  const UiFlowError({required this.message, this.success = false, super.key});

  final String message;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final color = success ? ui.success : ui.danger;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: success
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: OurneyIcon(
                name: success ? 'check' : 'warning',
                size: 20,
                flat: true,
                color: color,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                message,
                style: UiText.body(size: 13, height: 1.4, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UiFlowTab<T> {
  const UiFlowTab({required this.value, required this.label, this.key});

  final T value;
  final String label;
  final Key? key;
}

/// `.login-tabs`: two-segment tab bar, 2dp outline, 12dp radius, the active
/// tab filled sticker amber (`#FFB347`, ink label in both themes).
class UiFlowTabs<T> extends StatelessWidget {
  const UiFlowTabs({
    required this.tabs,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final List<UiFlowTab<T>> tabs;
  final T value;
  final ValueChanged<T> onChanged;

  static const _active = Color(0xFFFFB347);
  static const _activeInk = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(UiRadius.input),
        border: ui.stickerBorder(),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < tabs.length; i++) ...[
              if (i > 0) Container(width: UiBorder.standard, color: ui.outline),
              Expanded(
                child: UiPressable(
                  key: tabs[i].key,
                  onPressed: () => onChanged(tabs[i].value),
                  selected: tabs[i].value == value,
                  semanticLabel: tabs[i].label,
                  excludeChildSemantics: true,
                  borderRadius: BorderRadius.zero,
                  minSize: const Size(UiSize.tap, 48),
                  child: Container(
                    alignment: Alignment.center,
                    constraints: const BoxConstraints(minHeight: 48),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    color: tabs[i].value == value ? _active : ui.surface,
                    child: Text(
                      tabs[i].label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: UiText.body(
                        size: 15,
                        weight: FontWeight.w700,
                        height: 1.3,
                        color: tabs[i].value == value ? _activeInk : ui.ink,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// `.timer-ring`: 24dp ring that drains as [fraction] goes from 1 to 0.
class UiTimerRing extends StatelessWidget {
  const UiTimerRing({required this.fraction, super.key});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return ExcludeSemantics(
      child: CustomPaint(
        size: const Size.square(24),
        painter: _RingPainter(
          fraction: fraction.clamp(0, 1).toDouble(),
          track: ui.ink.withValues(alpha: 0.15),
          fill: ui.brand,
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.fraction,
    required this.track,
    required this.fill,
  });

  final double fraction;
  final Color track;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    final r = (Offset.zero & size).deflate(2);
    canvas.drawArc(r, 0, math.pi * 2, false, p..color = track);
    canvas.drawArc(
      r,
      -math.pi / 2,
      math.pi * 2 * fraction,
      false,
      p..color = fill,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction || old.track != track || old.fill != fill;
}
