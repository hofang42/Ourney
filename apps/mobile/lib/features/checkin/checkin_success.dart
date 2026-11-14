import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/theme/motion.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../personas/persona_contract.dart' show personaSkinOf;
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

  /// Figma Done screens name the milestone share action per skin.
  String _shareLabel(CheckinL10n l10n) {
    final j = widget.journey;
    if (j == null) return l10n.checkin_share;
    return switch (uiSkinIdFor(personaSkinOf(j))) {
      'memory' => l10n.checkin_shareSkinMemory,
      'couple' => l10n.checkin_shareSkinCouple,
      'flexer' => l10n.checkin_shareSkinFlexer,
      'minimal' => l10n.checkin_shareSkinMinimal,
      'quiet' => l10n.checkin_shareSkinQuiet,
      _ => l10n.checkin_share,
    };
  }

  @override
  Widget build(BuildContext context) {
    final journey = widget.journey;
    // Inside a journey the screen wears its V2 skin ("world").
    return journey == null
        ? _content(context)
        : UiSkinScope(
            skinId: uiSkinIdFor(personaSkinOf(journey)),
            child: Builder(builder: _content),
          );
  }

  Widget _content(BuildContext context) {
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
    final skin = journey == null ? null : uiSkinIdFor(personaSkinOf(journey));
    final milestone = outcome.milestone;
    // Figma Done screens: a per-skin hero, the streak, one calm line.
    final headline = _headline(l10n, skin, day ?? 1, outcome.streakAfter);
    final message = outcome.replaced
        ? l10n.checkin_replaced
        : milestoneTitle != null
        ? l10n.checkin_milestoneMessage
        : skin == 'couple'
        ? l10n.checkin_done_coupleSent
        : l10n.checkin_done_savedPrivate;
    final shout = skin == 'flexer' || skin == 'minimal';

    return UiScaffold(
      key: const ValueKey('checkin-success-screen'),
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
                    label: _shareLabel(l10n),
                    glyph: const OurneyIcon(name: 'share', size: 20),
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
          _hero(context, l10n, skin, day, milestone),
          const SizedBox(height: UiSpace.lg),
          Semantics(
            header: true,
            child: Text(
              headline,
              key: milestoneTitle == null
                  ? null
                  : const ValueKey('checkin-milestone'),
              textAlign: TextAlign.center,
              style: skin == 'squad' || shout
                  ? UiText.h2(color: ui.ink)
                  : UiText.h1(color: ui.ink),
            ),
          ),
          const SizedBox(height: UiSpace.md),
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
              message,
              textAlign: TextAlign.center,
              style: UiText.muted(color: ui.inkMuted, size: 16),
            ),
          ),
          if (skin == null) ...[
            const SizedBox(height: UiSpace.lg),
            _MiniCalendar(
              checkIn: outcome.checkIn,
              streak: outcome.streakAfter,
              stamp: null,
            ),
          ],
        ],
      ),
    );
  }

  String _headline(CheckinL10n l10n, String? skin, int day, int streak) {
    final m = widget.outcome.milestone;
    final title = _milestoneTitle(l10n);
    if (m == Milestone.completed) return title!;
    switch (skin) {
      case 'couple':
        return m == null
            ? l10n.checkin_done_coupleDay(day)
            : (m == Milestone.sevenDays
                  ? l10n.checkin_done_coupleWeek
                  : l10n.checkin_done_coupleFull30);
      case 'flexer':
        return m == null
            ? l10n.checkin_done_flexerDay(day, streak)
            : m == Milestone.sevenDays
            ? l10n.checkin_done_flexerWeek
            : l10n.checkin_done_flexerFinish;
      case 'minimal':
        return m == null
            ? l10n.checkin_done_minimalDone
            : m == Milestone.sevenDays
            ? l10n.checkin_done_minimalWeek
            : l10n.checkin_done_minimalFull;
      default:
        return title ?? l10n.checkin_chainKept;
    }
  }

  /// Per-skin hero (Figma QuietDone seal, SquadDone stamp, MemoryDone
  /// developing photo, CoupleDone photo + heart seal, FlexerDone pulse ring,
  /// MinimalDone dot). Milestones add the skin's confetti row.
  Widget _hero(
    BuildContext context,
    CheckinL10n l10n,
    String? skin,
    int? day,
    Milestone? milestone,
  ) {
    final ui = context.ui;
    final d = day ?? 1;
    final confetti = milestone == null
        ? const <Widget>[]
        : <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 5; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: OurneyIcon(
                      name: skin == 'couple' ? 'heart' : 'star',
                      active: true,
                      size: 18,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: UiSpace.sm),
          ];

    Widget ring(Widget child, double size) => Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ui.surface,
        border: Border.all(color: ui.accent, width: 6),
      ),
      child: child,
    );

    switch (skin) {
      case 'quiet':
        return Column(
          children: [
            ...confetti,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: ui.surface,
                borderRadius: BorderRadius.circular(UiRadius.sheet),
                border: ui.stickerBorder(),
                boxShadow: ui.hardShadow(),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      l10n.checkin_dayStamp(d),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: UiText.body(
                        size: 14,
                        weight: FontWeight.w800,
                        height: 1.4,
                        color: ui.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  OurneyIcon(name: 'check', size: 18, color: ui.ink),
                ],
              ),
            ),
          ],
        );
      case 'squad':
        final text = milestone == null
            ? l10n.checkin_done_stampChecked
            : milestone == Milestone.sevenDays
            ? l10n.checkin_done_stampWeek1
            : l10n.checkin_done_stampCup;
        final cup = milestone != null && milestone != Milestone.sevenDays;
        return Column(
          children: [
            if (cup) ...[
              const OurneyIcon(name: 'trophy', active: true, size: 72),
              const SizedBox(height: UiSpace.sm),
            ] else
              ...confetti,
            UiStamp(text, color: ui.accent),
          ],
        );
      case 'memory':
        return Column(
          children: [
            ...confetti,
            SizedBox(
              width: 168,
              height: 190,
              child: UiPolaroid(
                photo: GroupPhoto(checkIn: widget.outcome.checkIn),
                footer: const SizedBox.shrink(),
                tilt: -3,
              ),
            ),
            const SizedBox(height: UiSpace.md),
            UiStamp(l10n.checkin_done_memoryStamp(d)),
          ],
        );
      case 'couple':
        return Column(
          children: [
            ...confetti,
            SizedBox(
              width: 120,
              height: 120,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(UiRadius.card),
                child: GroupPhoto(checkIn: widget.outcome.checkIn),
              ),
            ),
            const SizedBox(height: UiSpace.sm),
            ring(const OurneyIcon(name: 'heart', active: true, size: 36), 72),
          ],
        );
      case 'flexer':
        return Column(
          children: [
            ...confetti,
            ring(
              Text(
                '$d',
                maxLines: 1,
                style: UiText.h1(color: ui.ink, size: 44),
              ),
              112,
            ),
          ],
        );
      case 'minimal':
        return Column(
          children: [
            ...confetti,
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: ui.accent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        );
      default:
        return const UiSuccessMark();
    }
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
    final warm = ui.accent.withValues(alpha: 0.22);
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
          border: Border.all(color: ui.accent, width: 3),
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
          ? OurneyIcon(
              name: 'check',
              flat: true,
              size: 11,
              color: ui.isDark ? ui.success : ui.warn,
            )
          : null,
    );
  }
}
