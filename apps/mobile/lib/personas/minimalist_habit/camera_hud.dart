import 'package:flutter/material.dart';

import '../../app/theme/persona_theme.dart';
import '../../shared/persona_pill.dart';
import '../persona_contract.dart';
import 'l10n/generated/minimalist_habit_localizations.dart';

/// **Task Z2** (`PersonaSkinId.minimalistHabit` — `zeroText3Sec`):
/// Clean Braun/Dieter Rams minimalist camera HUD:
/// - Single top pill (`{TITLE} · DAY {N}`),
/// - Zero text input fields on the HUD,
/// - Subtle Braun Coral-Orange (`pTheme.primaryAccent`) focus reticle and
///   bottom 1-tap hint (`1 tap · Zero typing required`).
class ZeroText3SecHud extends StatelessWidget {
  const ZeroText3SecHud({required this.data, super.key});

  final PersonaCameraData data;

  static const Color _mediaBg = Color(0xFF0E0E10);

  int get _dayNumber {
    if (data.checkInCount > 0) return data.checkInCount + 1;
    final days = data.journey.startDate.daysUntil(data.date) + 1;
    return days < 1 ? 1 : days;
  }

  @override
  Widget build(BuildContext context) {
    final pTheme = OurneyPersonaTheme.of(context);
    final l10n = MinimalistHabitL10n.of(context);
    final pillText = l10n.minimalist_habit_cameraPill(
      data.journey.title.toUpperCase(),
      _dayNumber,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(data.borderRadius ?? 16),
      child: ColoredBox(
        key: const ValueKey('z2-zero-text-hud'),
        color: _mediaBg,
        child: Stack(
          fit: StackFit.expand,
          children: [
            data.viewfinder,
            // Minimalist Braun-orange corner frame ticks
            IgnorePointer(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: CustomPaint(
                  painter: _MinimalistReticlePainter(
                    color: pTheme.primaryAccent.withValues(alpha: 0.75),
                  ),
                ),
              ),
            ),
            // Single top pill: `{TITLE} · DAY {N}`
            Positioned(
              top: 14,
              left: 56,
              right: 56,
              child: IgnorePointer(
                child: Center(
                  child: PersonaPill(
                    key: const ValueKey('z2-top-pill'),
                    label: pillText,
                  ),
                ),
              ),
            ),
            // Bottom minimal 3-sec check-in indicator with Braun orange dot
            Positioned(
              bottom: 14,
              left: 16,
              right: 16,
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    key: const ValueKey('z2-quick-snap-badge'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.58),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: pTheme.primaryAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            l10n.minimalist_habit_quickSnapHint,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
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

class _MinimalistReticlePainter extends CustomPainter {
  const _MinimalistReticlePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const len = 16.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    final w = size.width;
    final h = size.height;
    // Top-left
    canvas.drawLine(Offset.zero, const Offset(len, 0), paint);
    canvas.drawLine(Offset.zero, const Offset(0, len), paint);
    // Top-right
    canvas.drawLine(Offset(w - len, 0), Offset(w, 0), paint);
    canvas.drawLine(Offset(w, 0), Offset(w, len), paint);
    // Bottom-left
    canvas.drawLine(Offset(0, h - len), Offset(0, h), paint);
    canvas.drawLine(Offset(0, h), Offset(len, h), paint);
    // Bottom-right
    canvas.drawLine(Offset(w - len, h), Offset(w, h), paint);
    canvas.drawLine(Offset(w, h - len), Offset(w, h), paint);
  }

  @override
  bool shouldRepaint(_MinimalistReticlePainter oldDelegate) =>
      oldDelegate.color != color;
}
