import 'dart:async';
import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/motion.dart';
import '../../app/theme/tokens.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/chunky_button.dart';
import '../../shared/stamp_animation.dart';
import '../../shared/streak_flame.dart';
import 'checkin_progress.dart';
import 'l10n/generated/checkin_localizations.dart';

/// Success state after posting (FR-C8): stamp (0.6s, haptic on impact),
/// streak +1, confetti at milestones. Under Reduce Motion the stamp is a
/// 0.2s fade and there is no confetti. Without a milestone the screen closes
/// by itself so a check-in stays within 3 taps (FR-C4).
class CheckinSuccessView extends StatefulWidget {
  const CheckinSuccessView({
    required this.outcome,
    required this.haptics,
    required this.onDone,
    required this.onShare,
    super.key,
  });

  final CheckInOutcome outcome;
  final bool haptics;
  final VoidCallback onDone;
  final VoidCallback onShare;

  /// How long the plain (no milestone) success state stays on screen.
  static const autoCloseDelay = Duration(milliseconds: 1800);

  @override
  State<CheckinSuccessView> createState() => _CheckinSuccessViewState();
}

class _CheckinSuccessViewState extends State<CheckinSuccessView> {
  final _confetti = ConfettiController(duration: OurneyDurations.confetti);
  Timer? _autoClose;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (widget.outcome.milestone != null) {
      if (OurneyMotion.allowsDecoration(context)) _confetti.play();
    } else {
      _autoClose = Timer(CheckinSuccessView.autoCloseDelay, widget.onDone);
    }
  }

  @override
  void dispose() {
    _autoClose?.cancel();
    _confetti.dispose();
    super.dispose();
  }

  String? _milestoneTitle(CheckinL10n l10n) =>
      switch (widget.outcome.milestone) {
        Milestone.streak7 => l10n.checkin_milestone7,
        Milestone.streak30 => l10n.checkin_milestone30,
        Milestone.finish => l10n.checkin_milestoneFinish,
        null => null,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = CheckinL10n.of(context);
    final common = AppLocalizations.of(context);
    final c = OurneyColors.of(context);
    final text = Theme.of(context).textTheme;
    final outcome = widget.outcome;
    final milestoneTitle = _milestoneTitle(l10n);

    return Stack(
      children: [
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(OurneySpacing.screenMargin),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StampAnimation(
                  haptic: widget.haptics,
                  child: _Stamp(label: l10n.checkin_stamp),
                ),
                const SizedBox(height: OurneySpacing.xxl),
                StreakFlame(
                  key: const ValueKey('checkin-streak'),
                  days: outcome.streakAfter,
                  size: 48,
                  semanticLabel: common.streak_semantics(outcome.streakAfter),
                ),
                const SizedBox(height: OurneySpacing.sm),
                Text(
                  outcome.replaced
                      ? l10n.checkin_replaced
                      : l10n.checkin_streakPlusOne,
                  textAlign: TextAlign.center,
                  style: text.titleMedium?.copyWith(color: c.inkMuted),
                ),
                if (milestoneTitle != null) ...[
                  const SizedBox(height: OurneySpacing.xl),
                  Text(
                    milestoneTitle,
                    key: const ValueKey('checkin-milestone'),
                    textAlign: TextAlign.center,
                    style: text.displaySmall,
                  ),
                  const SizedBox(height: OurneySpacing.sm),
                  Text(
                    l10n.checkin_milestoneMessage,
                    textAlign: TextAlign.center,
                    style: text.bodyMedium?.copyWith(color: c.inkMuted),
                  ),
                  const SizedBox(height: OurneySpacing.xl),
                  ChunkyButton(
                    key: const ValueKey('checkin-share'),
                    label: l10n.checkin_share,
                    icon: Icons.ios_share_rounded,
                    onPressed: widget.onShare,
                  ),
                ],
                const SizedBox(height: OurneySpacing.lg),
                ChunkyButton(
                  key: const ValueKey('checkin-done'),
                  label: l10n.checkin_done,
                  variant: ChunkyVariant.neutral,
                  onPressed: widget.onDone,
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ExcludeSemantics(
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirection: math.pi / 2,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 24,
              emissionFrequency: 0.05,
              gravity: 0.25,
              colors: [c.primary, c.accent, c.streak, c.success, c.sun],
            ),
          ),
        ),
      ],
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = OurneyColors.of(context);
    return Transform.rotate(
      angle: -0.08,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: OurneySpacing.xl,
          vertical: OurneySpacing.md,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(OurneyRadii.card),
          border: Border.all(color: c.primaryDeep, width: 4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_rounded, color: c.primaryDeep, size: 36),
            const SizedBox(width: OurneySpacing.sm),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: displayStyle(size: 30, color: c.primaryDeep),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
