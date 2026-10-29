import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/theme/motion.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../ui/ui.dart';
import '../groups/ui/group_photo.dart';
import 'checkin_progress.dart';
import 'l10n/generated/checkin_localizations.dart';

/// Success state after posting (FR-C8, App.tsx `Posted`): green success
/// mark, "Chain kept." (or the milestone), a four-week mini calendar with
/// today's photo and a day stamp, the streak count, then Done (and Share at
/// a milestone). Without a milestone the screen closes by itself so a
/// check-in stays within 3 taps (FR-C4).
class CheckinSuccessView extends StatefulWidget {
  const CheckinSuccessView({
    required this.outcome,
    required this.haptics,
    required this.onDone,
    required this.onShare,
    this.journey,
    super.key,
  });

  final CheckInOutcome outcome;
  final Journey? journey;
  final bool haptics;
  final VoidCallback onDone;
  final VoidCallback onShare;

  /// How long the plain (no milestone) success state stays on screen.
  static const autoCloseDelay = Duration(milliseconds: 1800);

  @override
  State<CheckinSuccessView> createState() => _CheckinSuccessViewState();
}

class _CheckinSuccessViewState extends State<CheckinSuccessView> {
  Timer? _autoClose;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (widget.haptics) OurneyHaptics.success();
    if (widget.outcome.milestone == null) {
      _autoClose = Timer(CheckinSuccessView.autoCloseDelay, widget.onDone);
    }
  }

  @override
  void dispose() {
    _autoClose?.cancel();
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
    final ui = context.ui;
    final outcome = widget.outcome;
    final milestoneTitle = _milestoneTitle(l10n);
    final date = outcome.checkIn.localDate;
    final journey = widget.journey;
    final day = journey == null
        ? null
        : (journey.startDate.daysUntil(date) + 1).clamp(1, 100000);

    return UiScaffold(
      key: const ValueKey('checkin-success-screen'),
      background: ui.isDark ? ui.bg : const Color(0xFFF5F3EE),
      padTop: 40,
      bottom: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: UiSpace.maxContent(MediaQuery.sizeOf(context).width),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              UiSpace.gutter(MediaQuery.sizeOf(context).width),
              UiSpace.sm,
              UiSpace.gutter(MediaQuery.sizeOf(context).width),
              UiSpace.xxl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (milestoneTitle != null) ...[
                  UiButton(
                    key: const ValueKey('checkin-share'),
                    label: l10n.checkin_share,
                    icon: Icons.ios_share_rounded,
                    onPressed: widget.onShare,
                  ),
                  const SizedBox(height: UiSpace.sm),
                ],
                UiButton.secondary(
                  key: const ValueKey('checkin-done'),
                  label: l10n.checkin_done,
                  onPressed: widget.onDone,
                ),
              ],
            ),
          ),
        ),
      ),
      child: Column(
        children: [
          const UiSuccessMark(),
          const SizedBox(height: UiSpace.md),
          Text(
            l10n.checkin_posted,
            textAlign: TextAlign.center,
            style: UiText.body(
              size: 13,
              weight: FontWeight.w700,
              height: 1.4,
              color: ui.success,
            ),
          ),
          const SizedBox(height: UiSpace.xs),
          Semantics(
            header: true,
            child: Text(
              milestoneTitle ?? l10n.checkin_chainKept,
              key: milestoneTitle == null
                  ? null
                  : const ValueKey('checkin-milestone'),
              textAlign: TextAlign.center,
              style: UiText.h1(color: ui.ink),
            ),
          ),
          const SizedBox(height: UiSpace.xl),
          _MiniCalendar(
            checkIn: outcome.checkIn,
            streak: outcome.streakAfter,
            stamp: day == null ? null : l10n.checkin_dayStamp(day),
          ),
          const SizedBox(height: UiSpace.lg),
          KeyedSubtree(
            key: const ValueKey('checkin-streak'),
            child: UiStreakNumber(
              value: outcome.streakAfter,
              unit: l10n.checkin_daysUnit(outcome.streakAfter),
              semanticLabel: common.streak_semantics(outcome.streakAfter),
            ),
          ),
          const SizedBox(height: UiSpace.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: UiSpace.xl),
            child: Text(
              outcome.replaced
                  ? l10n.checkin_replaced
                  : milestoneTitle != null
                  ? l10n.checkin_milestoneMessage
                  : l10n.checkin_streakPlusOne,
              textAlign: TextAlign.center,
              style: UiText.muted(color: ui.inkMuted, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

/// `.mini-calendar`: four Monday-first weeks ending with the current week.
/// The streak days before today are tinted with a check, today shows the
/// posted photo; cells after today stay empty.
class _MiniCalendar extends StatelessWidget {
  const _MiniCalendar({
    required this.checkIn,
    required this.streak,
    required this.stamp,
  });

  final CheckIn checkIn;
  final int streak;
  final String? stamp;

  @override
  Widget build(BuildContext context) {
    final l10n = CheckinL10n.of(context);
    final ui = context.ui;
    final locale = Localizations.localeOf(context).toString();
    final d = checkIn.localDate;
    final weekday = DateTime(d.year, d.month, d.day).weekday; // 1 = Monday
    final todayIndex = 21 + weekday - 1;
    const warm = Color(0xFFFBDCCA);
    return Semantics(
      label: l10n.checkin_calendarSemantics(28),
      child: ExcludeSemantics(
        child: UiCard(
          radius: UiRadius.card,
          color: ui.surface,
          padding: const EdgeInsets.all(12),
          child: Stack(
            children: [
              Column(
                children: [
                  Row(
                    children: [
                      for (var i = 0; i < 7; i++)
                        Expanded(
                          child: Text(
                            DateFormat.E(locale)
                                .format(DateTime(2024, 1, 1 + i))
                                .substring(0, 2),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            style: UiText.body(
                              size: 11,
                              height: 1.4,
                              color: ui.inkMuted,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  for (var r = 0; r < 4; r++)
                    Padding(
                      padding: EdgeInsets.only(top: r == 0 ? 0 : 4),
                      child: Row(
                        children: [
                          for (var c = 0; c < 7; c++) ...[
                            if (c > 0) const SizedBox(width: 4),
                            Expanded(
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: _cell(ui, r * 7 + c, todayIndex, warm),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
              if (stamp != null)
                Positioned(right: 0, bottom: 0, child: UiStamp(stamp!)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cell(OurneyUi ui, int i, int todayIndex, Color warm) {
    if (i == todayIndex) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: const Color(0xFFEA580C), width: 3),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: GroupPhoto(checkIn: checkIn),
        ),
      );
    }
    final filled = i < todayIndex && todayIndex - i <= streak - 1;
    return Container(
      decoration: BoxDecoration(
        color: i > todayIndex
            ? ui.fill
            : filled
            ? (ui.isDark ? ui.successSoft : warm)
            : ui.fill,
        borderRadius: BorderRadius.circular(5),
      ),
      child: filled
          ? Icon(
              Icons.check_rounded,
              size: 11,
              color: ui.isDark ? ui.success : ui.warn,
            )
          : null,
    );
  }
}
