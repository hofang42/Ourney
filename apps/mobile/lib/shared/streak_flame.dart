import 'package:flutter/material.dart';

import '../app/theme/app_theme.dart';
import '../app/theme/motion.dart';
import '../app/theme/tokens.dart';

/// Streak flame with a day count. When [atRisk] the flame flickers (phase
/// animation: scale + tilt) and an exclamation badge appears so the state is
/// not conveyed by color/motion alone. With reduce-motion the flame is static.
class StreakFlame extends StatefulWidget {
  const StreakFlame({
    required this.days,
    this.atRisk = false,
    this.size = 32,
    this.showCount = true,
    this.semanticLabel,
    super.key,
  });

  final int days;
  final bool atRisk;
  final double size;
  final bool showCount;
  final String? semanticLabel;

  @override
  State<StreakFlame> createState() => _StreakFlameState();
}

class _StreakFlameState extends State<StreakFlame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: OurneyDurations.flame,
  );
  bool _reduced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = OurneyMotion.reduced(context);
    _sync();
  }

  @override
  void didUpdateWidget(StreakFlame old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    final animate = widget.atRisk && !_reduced;
    if (animate && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!animate && _ctrl.isAnimating) {
      _ctrl
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = OurneyColors.of(context);
    final flame = AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_ctrl.value);
        return Transform.rotate(
          angle: (t - 0.5) * 0.12,
          child: Transform.scale(scale: 1 + t * 0.14, child: child),
        );
      },
      child: Icon(
        Icons.local_fire_department_rounded,
        size: widget.size,
        color: c.streak,
      ),
    );

    return Semantics(
      label: widget.semanticLabel ?? '${widget.days}',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                flame,
                if (widget.atRisk)
                  Positioned(
                    right: -widget.size * 0.1,
                    top: -widget.size * 0.05,
                    child: Container(
                      width: widget.size * 0.4,
                      height: widget.size * 0.4,
                      decoration: BoxDecoration(
                        color: c.primaryDeep,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.priority_high_rounded,
                        size: widget.size * 0.28,
                        color: c.onPrimaryDeep,
                      ),
                    ),
                  ),
              ],
            ),
            if (widget.showCount) ...[
              SizedBox(width: widget.size * 0.15),
              Text(
                '${widget.days}',
                style: displayStyle(size: widget.size * 0.9, color: c.ink),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
