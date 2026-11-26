import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../ui/ui.dart';

/// Which reminder the in-app banner shows (V2 `banner.kind`).
enum ReminderBannerKind { daily, streak }

/// Content of one in-app reminder banner (V2 `store.reminderBanner`).
@immutable
class ReminderBannerData {
  const ReminderBannerData({
    required this.journeyId,
    required this.journeyName,
    required this.skinId,
    required this.kind,
    this.streak = 0,
    this.day = 1,
    this.deadline = '00:00',
  });

  final String journeyId;
  final String journeyName;

  /// `quiet`, `squad`, `memory`, `couple`, `flexer` or `minimal`.
  final String skinId;
  final ReminderBannerKind kind;
  final int streak;
  final int day;

  /// Local time (HH:mm) the streak stays open until.
  final String deadline;
}

/// State holder of the in-app banner; `null` means hidden.
class ReminderBannerController extends Notifier<ReminderBannerData?> {
  @override
  ReminderBannerData? build() => null;

  void show(ReminderBannerData data) => state = data;
  void dismiss() => state = null;
}

final reminderBannerProvider =
    NotifierProvider<ReminderBannerController, ReminderBannerData?>(
      ReminderBannerController.new,
    );

/// The localized banner line for [data] (per-skin voice, V2 `reminderCopy`).
String reminderBannerCopy(AppLocalizations l, ReminderBannerData data) {
  final streak = data.streak;
  if (data.kind == ReminderBannerKind.daily) {
    return switch (data.skinId) {
      'squad' => l.reminderBanner_daily_squad,
      'memory' => l.reminderBanner_daily_memory,
      'couple' => l.reminderBanner_daily_couple,
      'flexer' => l.reminderBanner_daily_flexer,
      'minimal' => l.reminderBanner_daily_minimal(data.day),
      _ => l.reminderBanner_daily_quiet,
    };
  }
  return switch (data.skinId) {
    'squad' => l.reminderBanner_streak_squad(streak),
    'memory' => l.reminderBanner_streak_memory,
    'couple' => l.reminderBanner_streak_couple(streak),
    'flexer' => l.reminderBanner_streak_flexer(streak),
    'minimal' => l.reminderBanner_streak_minimal(streak),
    _ => l.reminderBanner_streak_quiet(streak),
  };
}

/// V2 `ReminderNotification` / `.reminder-banner`: dark translucent card
/// pinned to the top (`220ms` slide-in `-28dp -> 0`, `160ms` exit `0 -> -16dp`,
/// `150ms` opacity-only fade with reduced motion), orange app icon,
/// "Ourney - bây giờ", journey name and the per-skin line. A tap opens the
/// camera ([onOpen]); the close button or an upward swipe dismisses.
/// Dark in both themes on purpose (it imitates a system notification).
class ReminderBanner extends StatefulWidget {
  const ReminderBanner({
    required this.data,
    required this.onOpen,
    required this.onDismiss,
    this.animation,
    this.onSwipeDismissed,
    super.key,
  });

  final ReminderBannerData data;
  final VoidCallback onOpen;
  final VoidCallback onDismiss;

  /// Optional external animation driven by [ReminderBannerHost] so exit
  /// animations (`160ms` upward `-16dp` slide + fade) play before unmount.
  final Animation<double>? animation;

  /// Optional callback fired when [Dismissible] finishes swiping upward.
  final VoidCallback? onSwipeDismissed;

  static const _card = Color(0xF01C1C1E);
  static const _text = Color(0xFFF8F8F8);
  static const _muted = Color(0xFFBBBBBB);
  static const _icon = Color(0xFFFF8A3D);

  @override
  State<ReminderBanner> createState() => _ReminderBannerState();
}

class _ReminderBannerState extends State<ReminderBanner>
    with SingleTickerProviderStateMixin {
  static const double _kEnterOffsetDy = -28.0;
  static const double _kExitOffsetDy = -16.0;

  AnimationController? _fallbackCtrl;
  CurvedAnimation? _curved;
  Animation<double>? _boundParent;
  bool _started = false;
  double _lastDy = _kEnterOffsetDy;
  double _reverseStartT = 1.0;
  double _reverseStartDy = 0.0;

  Animation<double> get _anim => widget.animation ?? _ensureFallback();

  AnimationController _ensureFallback() {
    return _fallbackCtrl ??= AnimationController(
      vsync: this,
      duration: UiMotion.medium,
      reverseDuration: UiMotion.fast,
    );
  }

  void _onAnimStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.reverse) {
      _reverseStartT = _curved?.value ?? _anim.value;
      _reverseStartDy = _lastDy;
    } else if (status == AnimationStatus.forward) {
      _reverseStartT = 1.0;
      _reverseStartDy = 0.0;
    }
  }

  void _syncCurvedAnimation() {
    final parent = _anim;
    if (identical(parent, _boundParent) && _curved != null) {
      return;
    }
    _boundParent?.removeStatusListener(_onAnimStatusChanged);
    _curved?.dispose();
    _boundParent = parent;
    parent.addStatusListener(_onAnimStatusChanged);
    _curved = CurvedAnimation(
      parent: parent,
      curve: UiCurves.easeOutStrong,
      reverseCurve: UiCurves.easeOutStrong.flipped,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      if (widget.animation == null) {
        final ctrl = _ensureFallback();
        ctrl.duration = UiMotion.fadeOf(context, UiMotion.medium);
        ctrl.reverseDuration = UiMotion.fadeOf(context, UiMotion.fast);
        ctrl.forward();
      }
    }
    _syncCurvedAnimation();
  }

  @override
  void didUpdateWidget(covariant ReminderBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation) {
      _syncCurvedAnimation();
    }
  }

  @override
  void dispose() {
    _boundParent?.removeStatusListener(_onAnimStatusChanged);
    _curved?.dispose();
    _fallbackCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final data = widget.data;
    final body = reminderBannerCopy(l, data);
    final title = data.journeyName.isEmpty
        ? l.reminderBanner_appName
        : data.journeyName;
    final reduced = UiMotion.reduced(context);
    _syncCurvedAnimation();
    final anim = _anim;
    final curved = _curved!;

    final Widget cardContent = Semantics(
      container: true,
      liveRegion: true,
      label: '${l.reminderBanner_appName}, $title, $body',
      child: Container(
        constraints: const BoxConstraints(minHeight: 104),
        decoration: BoxDecoration(
          color: ReminderBanner._card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x38FFFFFF)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x52000000),
              blurRadius: 32,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: InkWell(
                key: const ValueKey('reminder-banner-open'),
                borderRadius: BorderRadius.circular(20),
                onTap: widget.onOpen,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(13, 13, 8, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: ReminderBanner._icon,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: const OurneyIcon(
                          name: 'activity',
                          size: 19,
                          flat: true,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ExcludeSemantics(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: l.reminderBanner_appName,
                                      style: UiText.body(
                                        size: 12,
                                        weight: FontWeight.w800,
                                        height: 1.3,
                                        color: ReminderBanner._text,
                                      ),
                                    ),
                                    TextSpan(
                                      text: '  ${l.reminderBanner_now}',
                                      style: UiText.body(
                                        size: 12,
                                        weight: FontWeight.w500,
                                        height: 1.3,
                                        color: ReminderBanner._muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: UiText.body(
                                  size: 14,
                                  weight: FontWeight.w800,
                                  height: 1.3,
                                  color: ReminderBanner._text,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                body,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: UiText.body(
                                  size: 13,
                                  height: 1.35,
                                  color: ReminderBanner._text,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Semantics(
              button: true,
              label: l.reminderBanner_close,
              child: InkWell(
                key: const ValueKey('reminder-banner-dismiss'),
                onTap: widget.onDismiss,
                child: const SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: OurneyIcon(
                      name: 'close',
                      size: 18,
                      flat: true,
                      color: ReminderBanner._text,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final faded = FadeTransition(
      opacity: reduced ? anim : curved,
      child: cardContent,
    );
    final Widget animatedCard = reduced
        ? faded
        : AnimatedBuilder(
            animation: curved,
            child: faded,
            builder: (context, child) {
              final t = curved.value;
              final double dy;
              if (anim.status == AnimationStatus.reverse) {
                final progress = _reverseStartT > 1e-4
                    ? (1.0 - (t / _reverseStartT)).clamp(0.0, 1.0)
                    : 1.0;
                dy = lerpDouble(_reverseStartDy, _kExitOffsetDy, progress)!;
              } else {
                dy = (1.0 - t) * _kEnterOffsetDy;
              }
              _lastDy = dy;
              return Transform.translate(
                key: const ValueKey('reminder-banner-translate'),
                offset: Offset(0, dy),
                child: child,
              );
            },
          );

    // The banner sits above the router's pages (MaterialApp builder), so its
    // InkWell needs its own Material.
    return Material(
      type: MaterialType.transparency,
      child: Dismissible(
        key: ValueKey('reminder-banner-${data.journeyId}'),
        direction: DismissDirection.up,
        dismissThresholds: const {DismissDirection.up: 0.25},
        onDismissed: (_) =>
            (widget.onSwipeDismissed ?? widget.onDismiss).call(),
        child: animatedCard,
      ),
    );
  }
}

/// Overlays the in-app banner at the top of [child] while
/// [reminderBannerProvider] holds a value, and drives the `160ms` upward
/// (`-16dp`) exit animation before unmounting the banner on dismiss. Place it
/// inside the app's `MaterialApp.builder` (needs Directionality and
/// Localizations).
class ReminderBannerHost extends ConsumerStatefulWidget {
  const ReminderBannerHost({
    required this.child,
    required this.onOpenJourneyCamera,
    super.key,
  });

  final Widget child;

  /// Opens the camera of the journey whose banner was tapped.
  final void Function(String journeyId) onOpenJourneyCamera;

  @override
  ConsumerState<ReminderBannerHost> createState() => _ReminderBannerHostState();
}

class _ReminderBannerHostState extends ConsumerState<ReminderBannerHost>
    with SingleTickerProviderStateMixin {
  ReminderBannerData? _displayedData;
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: UiMotion.medium,
    reverseDuration: UiMotion.fast,
  )..addStatusListener(_onStatusChanged);

  void _onStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.dismissed &&
        mounted &&
        ref.read(reminderBannerProvider) == null &&
        _displayedData != null) {
      setState(() {
        _displayedData = null;
      });
    }
  }

  void _syncDurations() {
    _ctrl.duration = UiMotion.fadeOf(context, UiMotion.medium);
    _ctrl.reverseDuration = UiMotion.fadeOf(context, UiMotion.fast);
  }

  @override
  void initState() {
    super.initState();
    final initial = ref.read(reminderBannerProvider);
    if (initial != null) {
      _displayedData = initial;
      _ctrl.value = 1.0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncDurations();
  }

  @override
  void dispose() {
    _ctrl.removeStatusListener(_onStatusChanged);
    _ctrl.dispose();
    super.dispose();
  }

  void _handleDismiss() {
    if (ref.read(reminderBannerProvider) != null) {
      ref.read(reminderBannerProvider.notifier).dismiss();
    }
    _syncDurations();
    _ctrl.reverse();
  }

  void _handleSwipeDismiss() {
    _ctrl.stop();
    _ctrl.value = 0.0;
    setState(() {
      _displayedData = null;
    });
    ref.read(reminderBannerProvider.notifier).dismiss();
  }

  @override
  Widget build(BuildContext context) {
    final liveData = ref.watch(reminderBannerProvider);
    ref.listen<ReminderBannerData?>(reminderBannerProvider, (prev, next) {
      _syncDurations();
      if (next != null) {
        setState(() {
          _displayedData = next;
        });
        _ctrl.forward(from: 0.0);
      } else if (_displayedData != null) {
        _ctrl.reverse();
      }
    });

    final activeData = _displayedData;
    return Stack(
      children: [
        widget.child,
        if (activeData != null)
          Positioned(
            top: MediaQuery.paddingOf(context).top + 10,
            left: 10,
            right: 10,
            child: IgnorePointer(
              ignoring: liveData == null,
              child: ReminderBanner(
                data: activeData,
                animation: _ctrl,
                onOpen: () {
                  if (ref.read(reminderBannerProvider) == null) return;
                  final journeyId = activeData.journeyId;
                  _handleDismiss();
                  widget.onOpenJourneyCamera(journeyId);
                },
                onDismiss: _handleDismiss,
                onSwipeDismissed: _handleSwipeDismiss,
              ),
            ),
          ),
      ],
    );
  }
}
