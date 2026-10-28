import 'dart:async';
import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/motion.dart';
import '../../app/theme/tokens.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/chunky_button.dart';
import '../../shared/color_utils.dart';
import '../../shared/stamp_animation.dart';
import '../../shared/streak_flame.dart';
import '../journeys/ui/journey_photo.dart';
import 'checkin_progress.dart';
import 'l10n/generated/checkin_localizations.dart';

/// Success state after posting (FR-C8, V1.0 "Moment posted"): green
/// success mark, "Chain kept." (or the milestone), the photo with a stamped
/// day number (0.6s, haptic on impact), a big streak count, confetti at
/// milestones. Under Reduce Motion the stamp is a
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
        Milestone.sevenDays => l10n.checkin_milestone7,
        Milestone.thirtyDays => l10n.checkin_milestone30,
        Milestone.completed => l10n.checkin_milestoneFinish,
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
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExcludeSemantics(
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c.success,
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: readableOn(c.success),
                      ),
                    ),
                  ),
                  const SizedBox(height: OurneySpacing.md),
                  Text(
                    l10n.checkin_posted.toUpperCase(),
                    style: eyebrowStyle(size: 13, color: c.success),
                  ),
                  const SizedBox(height: OurneySpacing.xs),
                  Semantics(
                    header: true,
                    child: Text(
                      milestoneTitle ?? l10n.checkin_chainKept,
                      key: milestoneTitle == null
                          ? null
                          : const ValueKey('checkin-milestone'),
                      textAlign: TextAlign.center,
                      style: text.headlineLarge,
                    ),
                  ),
                  const SizedBox(height: OurneySpacing.xl),
                  StampAnimation(
                    haptic: widget.haptics,
                    child: _PhotoStamp(
                      checkIn: outcome.checkIn,
                      label:
                          DateFormat(
                                'd MMM',
                                Localizations.localeOf(context).toString(),
                              )
                              .format(
                                DateTime(
                                  outcome.checkIn.localDate.year,
                                  outcome.checkIn.localDate.month,
                                  outcome.checkIn.localDate.day,
                                ),
                              )
                              .toUpperCase(),
                    ),
                  ),
                  const SizedBox(height: OurneySpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      StreakFlame(
                        key: const ValueKey('checkin-streak'),
                        days: outcome.streakAfter,
                        size: 56,
                        semanticLabel: common.streak_semantics(
                          outcome.streakAfter,
                        ),
                      ),
                      const SizedBox(width: OurneySpacing.sm),
                      ExcludeSemantics(
                        child: Text(
                          l10n.checkin_daysUnit(outcome.streakAfter),
                          style: text.bodyLarge?.copyWith(color: c.inkMuted),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: OurneySpacing.sm),
                  Text(
                    outcome.replaced
                        ? l10n.checkin_replaced
                        : milestoneTitle != null
                        ? l10n.checkin_milestoneMessage
                        : l10n.checkin_streakPlusOne,
                    textAlign: TextAlign.center,
                    style: text.bodyMedium?.copyWith(
                      color: c.inkMuted,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: OurneySpacing.xl),
                  if (milestoneTitle != null) ...[
                    ChunkyButton(
                      key: const ValueKey('checkin-share'),
                      label: l10n.checkin_share,
                      icon: Icons.ios_share_rounded,
                      onPressed: widget.onShare,
                    ),
                    const SizedBox(height: OurneySpacing.sm),
                  ],
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

/// The posted photo in a white card with a rotated double-ruled stamp
/// ("DAY 25", V1.0 `.stamp`).
class _PhotoStamp extends StatelessWidget {
  const _PhotoStamp({required this.checkIn, required this.label});

  final CheckIn checkIn;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = OurneyColors.of(context);
    return Container(
      padding: const EdgeInsets.all(OurneySpacing.md),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(OurneyRadii.card),
        border: Border.all(color: c.border),
      ),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(OurneyRadii.thumb),
              child: JourneyPhoto(
                checkIn: checkIn,
                thumbnail: false,
                fallback: ColoredBox(color: c.surfaceSunken),
              ),
            ),
          ),
          Positioned(
            right: 8,
            bottom: 8,
            child: Transform.rotate(
              angle: -0.14,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: c.surface.withValues(alpha: 0.85),
                  border: Border.all(color: c.warning, width: 1.5),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: c.warning, width: 1.5),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: c.warning,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
