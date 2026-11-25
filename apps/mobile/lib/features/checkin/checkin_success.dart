import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data' show Float32List;
import 'dart:ui' show lerpDouble;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:intl/intl.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../personas/persona_contract.dart' show personaSkinOf;
import '../../ui/ui.dart';
import '../groups/ui/group_photo.dart';
import 'checkin_progress.dart';
import 'l10n/generated/checkin_localizations.dart';

/// Success state after posting (FR-C8, App.tsx `Posted`): per-skin V2
/// celebration hero (Rank #1 Phase 2a), rolling streak counter + flame
/// ignition (Phase 2b), rubber stamp slam (Phase 2c), milestone sticker
/// confetti climax (Rank #2), then Done (and Share at a milestone). Without a
/// milestone the screen closes by itself so a check-in stays within 3 taps
/// (FR-C4).
class CheckinSuccessView extends StatefulWidget {
  const CheckinSuccessView({
    required this.outcome,
    required this.haptics,
    required this.onDone,
    required this.onShare,
    this.holdAutoClose,
    this.journey,
    super.key,
  });

  final CheckInOutcome outcome;
  final Journey? journey;
  final bool haptics;
  final VoidCallback onDone;
  final VoidCallback onShare;

  /// The plain success state closes [autoCloseDelay] after this completes
  /// (B-B2): the notification offer opened on top of this screen must not
  /// be popped by the auto-close, nor the screen while the OS asks.
  final Future<void>? holdAutoClose;

  /// How long the plain (no milestone) success state stays on screen.
  static const autoCloseDelay = Duration(milliseconds: 1800);

  @override
  State<CheckinSuccessView> createState() => _CheckinSuccessViewState();
}

class _CheckinSuccessViewState extends State<CheckinSuccessView>
    with SingleTickerProviderStateMixin {
  Timer? _autoClose;
  bool _started = false;
  bool _confettiStarted = false;
  bool _confettiStopped = false;
  bool _milestoneFirstBeatFired = false;
  bool _milestoneSecondBeatFired = false;
  int _particleIndex = 0;

  late final AnimationController _timelineCtrl = AnimationController(
    vsync: this,
    duration: UiMotion.confetti,
  )..addListener(_onTimelineTick)
   ..addStatusListener(_onTimelineStatus);

  late final Animation<double> _ctaOpacity = _timelineCtrl.drive(
    CurveTween(
      curve: const Interval(
        220 / 1600,
        440 / 1600,
        curve: UiCurves.easeOutStrong,
      ),
    ),
  );

  late final Animation<double> _milestoneBannerOpacity = _timelineCtrl.drive(
    CurveTween(
      curve: const Interval(
        440 / 1600,
        520 / 1600,
        curve: UiCurves.easeOutStrong,
      ),
    ),
  );

  late final Animation<double> _memoryDevelopAnim = _timelineCtrl.drive(
    CurveTween(
      curve: const Interval(
        0.0,
        1100 / 1600,
        curve: UiCurves.easeOutStrong,
      ),
    ),
  );
  late final Animation<double> _memoryOpacity = _timelineCtrl.drive(
    Tween<double>(begin: 0.35, end: 1.0).chain(
      CurveTween(
        curve: const Interval(
          0.0,
          1100 / 1600,
          curve: UiCurves.easeOutStrong,
        ),
      ),
    ),
  );

  late final Animation<double> _squadTrophyAnim = _timelineCtrl.drive(
    CurveTween(
      curve: const Interval(
        0.0,
        620 / 1600,
        curve: UiCurves.stampDecel,
      ),
    ),
  );

  late final Animation<double> _minimalDotAnim = _timelineCtrl.drive(
    CurveTween(
      curve: const Interval(
        0.0,
        380 / 1600,
        curve: UiCurves.easeOutStrong,
      ),
    ),
  );

  late final Animation<double> _defaultMarkAnim = _timelineCtrl.drive(
    CurveTween(
      curve: const Interval(
        0.0,
        220 / 1600,
        curve: UiCurves.easeOutStrong,
      ),
    ),
  );

  ConfettiController? _confettiCtrl;

  ConfettiController _ensureConfettiController() =>
      _confettiCtrl ??= ConfettiController(
        duration: const Duration(seconds: 10),
      );

  static final SpringSimulation _quietSealSim = SpringSimulation(
    UiSprings.gentle,
    0.0,
    1.0,
    0.0,
  );
  static final SpringSimulation _bouncySealSim = SpringSimulation(
    UiSprings.bouncy,
    0.0,
    1.0,
    0.0,
  );
  static final SpringSimulation _coupleClickSim = SpringSimulation(
    UiSprings.snappy,
    0.0,
    1.0,
    0.0,
  );
  static final SpringSimulation _coupleHeartSim = SpringSimulation(
    UiSprings.bouncy,
    0.0,
    1.0,
    0.0,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = UiMotion.reduced(context);
    if (!_started) {
      _started = true;
      if (reduced) {
        if (widget.haptics && !widget.outcome.extraPhoto) {
          unawaited(UiHaptics.selection());
        }
        _timelineCtrl.duration = UiMotion.reducedFade;
        _timelineCtrl.forward(from: 0.0);
      } else {
        _timelineCtrl.duration = UiMotion.confetti;
        _timelineCtrl.forward(from: 0.0);
      }
      if (widget.outcome.milestone == null) unawaited(_armAutoClose());
    } else if (reduced && _timelineCtrl.duration != UiMotion.reducedFade) {
      _stopConfettiIfNeeded();
      _timelineCtrl.stop();
      _timelineCtrl.value = 1.0;
    }
  }

  void _onTimelineTick() {
    if (!mounted || UiMotion.reduced(context)) return;
    if (widget.outcome.milestone == null || widget.outcome.extraPhoto) return;

    final elapsedMs = _timelineCtrl.value * UiMotion.confetti.inMilliseconds;
    if (elapsedMs >= 440 && !_milestoneFirstBeatFired) {
      _milestoneFirstBeatFired = true;
      if (widget.haptics) {
        unawaited(UiHaptics.stampImpact());
      }
    }
    if (elapsedMs >= 440 && elapsedMs < 1400 && !_confettiStarted) {
      _confettiStarted = true;
      _ensureConfettiController().play();
    }
    if (elapsedMs >= 550 && !_milestoneSecondBeatFired) {
      _milestoneSecondBeatFired = true;
      if (widget.haptics) {
        unawaited(UiHaptics.pressLight());
      }
    }
    if (elapsedMs >= 1400 && _confettiStarted && !_confettiStopped) {
      _stopConfettiIfNeeded();
    }
  }

  void _onTimelineStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _stopConfettiIfNeeded();
    }
  }

  void _stopConfettiIfNeeded() {
    if (_confettiStarted && !_confettiStopped) {
      _confettiStopped = true;
      _confettiCtrl?.stop(clearAllParticles: true);
    }
  }

  Future<void> _armAutoClose() async {
    final hold = widget.holdAutoClose;
    if (hold != null) {
      try {
        await hold;
      } on Object {
        // The offer never throws; close anyway if it somehow does.
      }
    }
    if (!mounted) return;
    _autoClose = Timer(CheckinSuccessView.autoCloseDelay, widget.onDone);
  }

  @override
  void dispose() {
    _autoClose?.cancel();
    _timelineCtrl.removeListener(_onTimelineTick);
    _timelineCtrl.removeStatusListener(_onTimelineStatus);
    _confettiCtrl?.dispose();
    _timelineCtrl.dispose();
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

  /// Custom Neo-Brutalist die-cut particle paths (crisp 8x5 paper rectangles,
  /// 6x6 diamonds, and vector heart path for `couple`).
  Path _buildParticlePath(Size size, String? skin) {
    if (skin == 'couple') {
      final w = math.max(8.0, size.width);
      final h = math.max(8.0, size.height);
      return Path()
        ..moveTo(w * 0.5, h * 0.9)
        ..cubicTo(w * 0.1, h * 0.6, 0.0, h * 0.25, w * 0.25, h * 0.1)
        ..cubicTo(w * 0.4, 0.0, w * 0.5, h * 0.15, w * 0.5, h * 0.28)
        ..cubicTo(w * 0.5, h * 0.15, w * 0.6, 0.0, w * 0.75, h * 0.1)
        ..cubicTo(w, h * 0.25, w * 0.9, h * 0.6, w * 0.5, h * 0.9)
        ..close();
    }
    final useDiamond = skin == 'quiet' || (_particleIndex++).isOdd;
    if (useDiamond) {
      const d = 6.0;
      return Path()
        ..moveTo(d / 2, 0)
        ..lineTo(d, d / 2)
        ..lineTo(d / 2, d)
        ..lineTo(0, d / 2)
        ..close();
    }
    return Path()..addRect(const Rect.fromLTWH(0, 0, 8, 5));
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
    final reduced = UiMotion.reduced(context);
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
    final j = journey;
    final isCoupleAudience = j != null
        ? (j.kind == JourneyKind.group &&
              (j.maxMembers == 2 || j.coupleSelfName != null || skin == 'couple'))
        : skin == 'couple';
    final isSharedLink =
        j != null &&
        (j.visibility == JourneyVisibility.link ||
            (j.publicToken != null && j.publicToken!.trim().isNotEmpty));
    final audienceMessage = isCoupleAudience
        ? l10n.checkin_done_coupleSent
        : (j != null && j.kind == JourneyKind.group)
        ? l10n.checkin_done_sharedSquad
        : isSharedLink
        ? l10n.checkin_done_sharedLink
        : l10n.checkin_done_savedPrivate;
    final message = outcome.extraPhoto
        ? l10n.checkin_photoAdded(outcome.photoOfDay)
        : milestoneTitle != null
        ? l10n.checkin_milestoneMessage
        : audienceMessage;
    final shout = skin == 'flexer' || skin == 'minimal';

    final shareButton = milestoneTitle == null
        ? null
        : _buildShareCta(l10n, ui, reduced);

    final ctaColumn = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (shareButton != null) ...[
          shareButton,
          const SizedBox(height: UiSpace.sm),
        ],
        UiButton.secondary(
          key: const ValueKey('checkin-done'),
          label: l10n.checkin_done,
          onPressed: widget.onDone,
        ),
      ],
    );

    final Widget animatedCtas = reduced
        ? ctaColumn
        : FadeTransition(
            opacity: _ctaOpacity,
            child: AnimatedBuilder(
              animation: _ctaOpacity,
              child: ctaColumn,
              builder: (context, child) {
                final dy = (1.0 - _ctaOpacity.value) * 6.0;
                return Transform.translate(
                  key: const ValueKey('checkin-cta-translate'),
                  offset: Offset(0, dy),
                  child: child,
                );
              },
            ),
          );

    final scaffold = UiScaffold(
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
            child: animatedCtas,
          ),
        ),
      ),
      child: Column(
        children: [
          _hero(context, l10n, skin, day, milestone, reduced),
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
              initialValue: outcome.extraPhoto
                  ? outcome.streakAfter
                  : outcome.streakBefore,
              skinId: skin,
              animate: !outcome.extraPhoto,
              haptics:
                  widget.haptics && milestone == null && !outcome.extraPhoto,
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

    Widget result = scaffold;
    if (milestone != null && !reduced) {
      final isQuiet = skin == 'quiet';
      result = Stack(
        fit: StackFit.passthrough,
        children: [
          scaffold,
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                key: const ValueKey('checkin-milestone-confetti'),
                child: Align(
                  alignment: const Alignment(0.0, -0.55),
                  child: ConfettiWidget(
                    confettiController: _ensureConfettiController(),
                    blastDirectionality: BlastDirectionality.explosive,
                    numberOfParticles: isQuiet ? 8 : 18,
                    emissionFrequency: 0.08,
                    maxBlastForce: isQuiet ? 12 : 18,
                    minBlastForce: isQuiet ? 5 : 8,
                    gravity: isQuiet ? 0.12 : 0.28,
                    shouldLoop: false,
                    minimumSize: const Size(6, 5),
                    maximumSize: const Size(10, 8),
                    colors: isQuiet
                        ? <Color>[ui.accent, ui.success, ui.ink]
                        : <Color>[ui.accent, ui.brand, ui.ink],
                    createParticlePath: (size) =>
                        _buildParticlePath(size, skin),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (reduced) {
      return FadeTransition(
        key: const ValueKey('checkin-success-reduced-fade'),
        opacity: _timelineCtrl,
        child: result,
      );
    }
    return result;
  }

  /// Rank #2 (`520ms`): "Create Milestone Card" CTA pulses its sticker border
  /// highlight once (`260ms`).
  Widget _buildShareCta(CheckinL10n l10n, OurneyUi ui, bool reduced) {
    final shareBtn = UiButton(
      key: const ValueKey('checkin-share'),
      label: _shareLabel(l10n),
      glyph: const OurneyIcon(name: 'share', size: 20),
      onPressed: widget.onShare,
    );
    if (reduced) return shareBtn;
    return AnimatedBuilder(
      animation: _timelineCtrl,
      child: shareBtn,
      builder: (context, child) {
        final elapsedMs =
            _timelineCtrl.value * UiMotion.confetti.inMilliseconds;
        double pulseAlpha = 0.0;
        if (elapsedMs > 520 && elapsedMs < 780) {
          final localT = (elapsedMs - 520) / 260;
          pulseAlpha = math.sin(localT * math.pi);
        }
        if (pulseAlpha <= 0.01) return child!;
        return DecoratedBox(
          key: const ValueKey('checkin-share-highlight'),
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(UiRadius.capsule),
            border: Border.all(
              color: ui.accent.withValues(alpha: pulseAlpha),
              width: 3,
            ),
          ),
          child: child,
        );
      },
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

  /// High-exposure warm sepia matrix at `t = 0.0` interpolating smoothly to
  /// the identity matrix at `t = 1.0` (`memory` Polaroid chemical develop).
  /// Allocates a fresh 20-element [Float32List] per call because
  /// [ColorFilter.matrix] stores the list reference without copying and compares
  /// lists in [ColorFilter.operator ==].
  static Float32List _chemicalDevelopMatrix(double t) {
    final inv = 1.0 - t;
    final lift = inv * 48.0;
    final m = Float32List(20)..[18] = 1.0;
    m[0] = lerpDouble(0.39, 1.0, t)!;
    m[1] = lerpDouble(0.76, 0.0, t)!;
    m[2] = lerpDouble(0.18, 0.0, t)!;
    m[4] = lift;
    m[5] = lerpDouble(0.35, 0.0, t)!;
    m[6] = lerpDouble(0.68, 1.0, t)!;
    m[7] = lerpDouble(0.16, 0.0, t)!;
    m[9] = lift * 0.9;
    m[10] = lerpDouble(0.27, 0.0, t)!;
    m[11] = lerpDouble(0.53, 0.0, t)!;
    m[12] = lerpDouble(0.13, 1.0, t)!;
    m[14] = lift * 0.7;
    return m;
  }

  /// Per-skin hero (Figma QuietDone seal, SquadDone rising trophy + stamp,
  /// MemoryDone developing photo, CoupleDone diptych click + heart seal,
  /// FlexerDone telemetry ring sweep + pulse, MinimalDone ink-dot bloom).
  /// Milestones add the skin's vector star/heart seal row at `440ms`.
  Widget _hero(
    BuildContext context,
    CheckinL10n l10n,
    String? skin,
    int? day,
    Milestone? milestone,
    bool reduced,
  ) {
    final ui = context.ui;
    final d = day ?? 1;
    final outcome = widget.outcome;
    final celebrateHeroHaptics =
        widget.haptics && milestone == null && !outcome.extraPhoto;
    final sealSim =
        (skin == 'quiet' || skin == 'minimal') ? _quietSealSim : _bouncySealSim;

    final starRow = Row(
      key: const ValueKey('checkin-milestone-banner'),
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
    );

    final confettiRow = milestone == null
        ? const <Widget>[]
        : <Widget>[
            if (reduced)
              starRow
            else
              FadeTransition(
                key: const ValueKey('checkin-milestone-banner-fade'),
                opacity: _milestoneBannerOpacity,
                child: AnimatedBuilder(
                  animation: _timelineCtrl,
                  child: starRow,
                  builder: (context, child) {
                    final elapsedMs =
                        _timelineCtrl.value * UiMotion.confetti.inMilliseconds;
                    if (elapsedMs <= 440) {
                      return child!;
                    }
                    final localT = ((elapsedMs - 440) / 360).clamp(0.0, 1.0);
                    final p = sealSim.x(localT * 0.35).clamp(0.0, 1.15);
                    final scale = skin == 'quiet'
                        ? lerpDouble(0.97, 1.0, p.clamp(0.0, 1.0))!
                        : lerpDouble(1.18, 1.0, p)!;
                    return Transform.scale(
                      key: const ValueKey('checkin-milestone-banner-scale'),
                      scale: scale,
                      child: child,
                    );
                  },
                ),
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
        final sealCard = Container(
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
              OurneyIcon(
                name: 'check',
                size: 18,
                color: ui.ink,
                flat: true,
              ),
            ],
          ),
        );
        return Column(
          children: [
            ...confettiRow,
            Stack(
              alignment: Alignment.center,
              children: [
                RepaintBoundary(
                  key: const ValueKey('checkin-quiet-dots'),
                  child: SizedBox(
                    width: 220,
                    height: 68,
                    child: CustomPaint(
                      painter: _QuietDotsPainter(
                        animation: _timelineCtrl,
                        color: ui.accent,
                        reduced: reduced,
                      ),
                    ),
                  ),
                ),
                if (reduced)
                  KeyedSubtree(
                    key: const ValueKey('checkin-quiet-seal'),
                    child: sealCard,
                  )
                else
                  AnimatedBuilder(
                    animation: _timelineCtrl,
                    child: sealCard,
                    builder: (context, child) {
                      final elapsedMs =
                          _timelineCtrl.value *
                          UiMotion.confetti.inMilliseconds;
                      final localT = (elapsedMs / 520.0).clamp(0.0, 1.0);
                      final p = _quietSealSim.x(localT * 0.45).clamp(0.0, 1.0);
                      final scale = lerpDouble(0.97, 1.0, p)!;
                      return Transform.scale(
                        key: const ValueKey('checkin-quiet-seal'),
                        scale: scale,
                        child: child,
                      );
                    },
                  ),
              ],
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
        final trophyIcon = OurneyIcon(
          name: 'trophy',
          active: true,
          size: cup ? 72 : 56,
        );
        final Widget animatedTrophy = reduced
            ? KeyedSubtree(
                key: const ValueKey('checkin-squad-trophy'),
                child: trophyIcon,
              )
            : FadeTransition(
                opacity: _squadTrophyAnim,
                child: AnimatedBuilder(
                  animation: _squadTrophyAnim,
                  child: trophyIcon,
                  builder: (context, child) {
                    final dy = (1.0 - _squadTrophyAnim.value) * 48.0;
                    return Transform.translate(
                      key: const ValueKey('checkin-squad-trophy'),
                      offset: Offset(0, dy),
                      child: child,
                    );
                  },
                ),
              );
        return Column(
          children: [
            if (!cup) ...confettiRow,
            animatedTrophy,
            const SizedBox(height: UiSpace.sm),
            UiStamp(
              text,
              color: ui.accent,
              animate: !outcome.extraPhoto,
              skinId: 'squad',
              haptics: celebrateHeroHaptics,
            ),
          ],
        );
      case 'memory':
        final polaroidCard = UiPolaroid(
          photo: AspectRatio(
            aspectRatio: 1,
            child: ClipRect(
              child: GroupPhoto(
                checkIn: widget.outcome.checkIn,
                decodeWidth: 168,
              ),
            ),
          ),
          footer: const SizedBox(height: 14),
          tilt: -3,
        );
        final Widget developedPolaroid = reduced
            ? polaroidCard
            : FadeTransition(
                opacity: _memoryOpacity,
                child: AnimatedBuilder(
                  animation: _memoryDevelopAnim,
                  child: polaroidCard,
                  builder: (context, child) {
                    final t = _memoryDevelopAnim.value;
                    if (t >= 0.999) return child!;
                    return ColorFiltered(
                      key: const ValueKey('checkin-memory-develop-filter'),
                      colorFilter: ColorFilter.matrix(
                        _chemicalDevelopMatrix(t),
                      ),
                      child: child,
                    );
                  },
                ),
              );
        return Column(
          children: [
            ...confettiRow,
            // The photo gets a square slot: an unconstrained Image.file
            // takes its natural size and spills over the title below. The
            // vertical padding leaves room for the tilted corners.
            Padding(
              padding: const EdgeInsets.symmetric(vertical: UiSpace.sm),
              child: SizedBox(
                key: const ValueKey('checkin-polaroid'),
                width: (MediaQuery.sizeOf(context).width * 0.46).clamp(
                  120.0,
                  168.0,
                ),
                child: developedPolaroid,
              ),
            ),
            const SizedBox(height: UiSpace.md),
            // Room for the -8 degree tilt: about width * sin(8) / 2.
            Padding(
              key: const ValueKey('checkin-stamp'),
              padding: EdgeInsets.symmetric(
                vertical: MediaQuery.sizeOf(context).width * 0.07,
              ),
              child: UiStamp(
                l10n.checkin_done_memoryStamp(d),
                animate: !outcome.extraPhoto,
                skinId: 'memory',
                haptics: celebrateHeroHaptics,
              ),
            ),
          ],
        );
      case 'couple':
        final leftPhoto = ClipRRect(
          borderRadius: const BorderRadiusDirectional.horizontal(
            start: Radius.circular(UiRadius.card),
          ).resolve(Directionality.of(context)),
          child: SizedBox(
            width: 68,
            height: 112,
            child: GroupPhoto(
              checkIn: widget.outcome.checkIn,
              decodeWidth: 120,
            ),
          ),
        );
        final rightPhoto = ClipRRect(
          borderRadius: const BorderRadiusDirectional.horizontal(
            end: Radius.circular(UiRadius.card),
          ).resolve(Directionality.of(context)),
          child: SizedBox(
            width: 68,
            height: 112,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: ui.fill,
                border: Border.all(color: ui.outline, width: UiBorder.thin),
              ),
              child: Center(
                child: OurneyIcon(
                  name: 'heart',
                  size: 24,
                  color: ui.accent,
                  active: true,
                ),
              ),
            ),
          ),
        );
        final heartRing = ring(
          const OurneyIcon(name: 'heart', active: true, size: 36),
          72,
        );
        return Column(
          children: [
            ...confettiRow,
            if (reduced)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  KeyedSubtree(
                    key: const ValueKey('checkin-couple-left'),
                    child: leftPhoto,
                  ),
                  const SizedBox(width: 2),
                  KeyedSubtree(
                    key: const ValueKey('checkin-couple-right'),
                    child: rightPhoto,
                  ),
                ],
              )
            else
              AnimatedBuilder(
                animation: _timelineCtrl,
                child: leftPhoto,
                builder: (context, leftChild) {
                  final elapsedMs =
                      _timelineCtrl.value * UiMotion.confetti.inMilliseconds;
                  final localT = (elapsedMs / 560.0).clamp(0.0, 1.0);
                  final p = _coupleClickSim.x(localT * 0.35).clamp(0.0, 1.05);
                  final gapOffset = lerpDouble(36.0, 0.0, p)!;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.translate(
                        key: const ValueKey('checkin-couple-left'),
                        offset: Offset(-gapOffset, 0),
                        child: leftChild,
                      ),
                      const SizedBox(width: 2),
                      Transform.translate(
                        key: const ValueKey('checkin-couple-right'),
                        offset: Offset(gapOffset, 0),
                        child: rightPhoto,
                      ),
                    ],
                  );
                },
              ),
            const SizedBox(height: UiSpace.sm),
            if (reduced)
              KeyedSubtree(
                key: const ValueKey('checkin-couple-heart'),
                child: heartRing,
              )
            else
              AnimatedBuilder(
                animation: _timelineCtrl,
                child: heartRing,
                builder: (context, child) {
                  final elapsedMs =
                      _timelineCtrl.value * UiMotion.confetti.inMilliseconds;
                  final localT = (elapsedMs / 560.0).clamp(0.0, 1.0);
                  final p = _coupleHeartSim.x(localT * 0.35).clamp(0.0, 1.25);
                  final scale = lerpDouble(0.84, 1.0, p)!;
                  return Transform.scale(
                    key: const ValueKey('checkin-couple-heart'),
                    scale: scale,
                    child: child,
                  );
                },
              ),
          ],
        );
      case 'flexer':
        final dayLabel = Text(
          '$d',
          maxLines: 1,
          style: UiText.h1(color: ui.ink, size: 44),
        );
        final ringBox = SizedBox(
          width: 112,
          height: 112,
          child: CustomPaint(
            painter: _FlexerRingPainter(
              animation: _timelineCtrl,
              reduced: reduced,
              surfaceColor: ui.surface,
              trackColor: ui.border,
              accentColor: ui.accent,
            ),
            child: Center(child: dayLabel),
          ),
        );
        return Column(
          children: [
            ...confettiRow,
            RepaintBoundary(
              key: const ValueKey('checkin-flexer-ring-boundary'),
              child: reduced
                  ? KeyedSubtree(
                      key: const ValueKey('checkin-flexer-ring'),
                      child: ring(dayLabel, 112),
                    )
                  : AnimatedBuilder(
                      animation: _timelineCtrl,
                      child: ringBox,
                      builder: (context, child) {
                        final elapsedMs =
                            _timelineCtrl.value *
                            UiMotion.confetti.inMilliseconds;
                        final rawT = (elapsedMs / 680.0).clamp(0.0, 1.0);
                        final double scale;
                        if (rawT >= 1.0) {
                          scale = 1.0;
                        } else if (rawT < 0.6) {
                          scale = lerpDouble(
                            0.94,
                            1.02,
                            UiCurves.easeOutStrong.transform(rawT / 0.6),
                          )!;
                        } else {
                          scale = lerpDouble(
                            1.02,
                            1.0,
                            UiCurves.stampDecel.transform((rawT - 0.6) / 0.4),
                          )!;
                        }
                        return Transform.scale(
                          key: const ValueKey('checkin-flexer-ring'),
                          scale: scale,
                          child: child,
                        );
                      },
                    ),
            ),
          ],
        );
      case 'minimal':
        final dot = Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: ui.accent,
            shape: BoxShape.circle,
          ),
        );
        return Column(
          children: [
            ...confettiRow,
            if (reduced)
              KeyedSubtree(
                key: const ValueKey('checkin-minimal-dot'),
                child: dot,
              )
            else
              FadeTransition(
                opacity: _minimalDotAnim,
                child: AnimatedBuilder(
                  animation: _minimalDotAnim,
                  child: dot,
                  builder: (context, child) {
                    final scale = lerpDouble(
                      0.86,
                      1.0,
                      _minimalDotAnim.value,
                    )!;
                    return Transform.scale(
                      key: const ValueKey('checkin-minimal-dot'),
                      scale: scale,
                      child: child,
                    );
                  },
                ),
              ),
          ],
        );
      default:
        const mark = UiSuccessMark();
        if (reduced) return mark;
        return FadeTransition(
          opacity: _defaultMarkAnim,
          child: AnimatedBuilder(
            animation: _defaultMarkAnim,
            child: mark,
            builder: (context, child) {
              final scale = lerpDouble(0.92, 1.0, _defaultMarkAnim.value)!;
              return Transform.scale(scale: scale, child: child);
            },
          ),
        );
    }
  }
}

/// Calm breathing emerald dots behind the `quiet` celebration seal.
class _QuietDotsPainter extends CustomPainter {
  _QuietDotsPainter({
    required this.animation,
    required this.color,
    required this.reduced,
  }) : _dotPaint = Paint()..style = PaintingStyle.fill,
       super(repaint: reduced ? null : animation);

  final Animation<double> animation;
  final Color color;
  final bool reduced;
  final Paint _dotPaint;

  static const List<Offset> _normalizedOffsets = <Offset>[
    Offset(0.08, 0.25),
    Offset(0.18, 0.72),
    Offset(0.28, 0.18),
    Offset(0.82, 0.22),
    Offset(0.90, 0.68),
    Offset(0.74, 0.78),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final alpha = reduced
        ? 0.24
        : (lerpDouble(0.12, 0.24, animation.value)! +
                  0.12 * math.sin(animation.value * math.pi))
              .clamp(0.12, 0.36);
    _dotPaint.color = color.withValues(alpha: alpha);
    for (final norm in _normalizedOffsets) {
      canvas.drawCircle(
        Offset(size.width * norm.dx, size.height * norm.dy),
        2.5,
        _dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_QuietDotsPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.reduced != reduced;
}

/// Neon telemetry ring sweep painter for the `flexer` check-in celebration.
class _FlexerRingPainter extends CustomPainter {
  _FlexerRingPainter({
    required this.animation,
    required this.surfaceColor,
    required this.trackColor,
    required this.accentColor,
    this.reduced = false,
  }) : _fillPaint = Paint()
         ..color = surfaceColor
         ..style = PaintingStyle.fill,
       _trackPaint = Paint()
         ..color = trackColor
         ..style = PaintingStyle.stroke
         ..strokeWidth = _kStrokeWidth,
       _arcPaint = Paint()
         ..color = accentColor
         ..style = PaintingStyle.stroke
         ..strokeCap = StrokeCap.round
         ..strokeWidth = _kStrokeWidth,
       super(repaint: reduced ? null : animation);

  static const double _kStrokeWidth = 6.0;

  final Animation<double> animation;
  final bool reduced;
  final Color surfaceColor;
  final Color trackColor;
  final Color accentColor;

  final Paint _fillPaint;
  final Paint _trackPaint;
  final Paint _arcPaint;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - _kStrokeWidth) / 2;
    canvas.drawCircle(center, radius, _fillPaint);
    canvas.drawCircle(center, radius, _trackPaint);
    final double clamped;
    if (reduced) {
      clamped = 1.0;
    } else {
      final elapsedMs = animation.value * UiMotion.confetti.inMilliseconds;
      final rawT = (elapsedMs / 680.0).clamp(0.0, 1.0);
      clamped = UiCurves.stampDecel.transform(rawT).clamp(0.0, 1.0);
    }
    if (clamped > 0.0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * clamped,
        false,
        _arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_FlexerRingPainter oldDelegate) =>
      oldDelegate.animation != animation ||
      oldDelegate.reduced != reduced ||
      oldDelegate.surfaceColor != surfaceColor ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.accentColor != accentColor;
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
