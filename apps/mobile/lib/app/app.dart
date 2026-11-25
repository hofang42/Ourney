import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart' show JourneyStatus;

import '../data/data_providers.dart' show serverPullsProvider;
import '../features/import/data/import_providers.dart'
    show importResumeProvider;
import '../features/journeys/data/journeys_providers.dart'
    show journeysClockProvider, timeZoneWarmupProvider;
import '../features/journeys/journeys_paths.dart';
import '../features/journeys/ui/day_ticker.dart';
import '../features/onboarding/l10n/generated/onboarding_localizations.dart';
import '../features/profile/settings_providers.dart' show themeModeProvider;
import '../features/profile/share_privacy_sync.dart' show SharePrivacyHealHook;
import '../features/reminders/data/reminder_scheduler.dart';
import '../features/update/data/update_providers.dart';
import '../features/update/ui/update_gate_screen.dart';
import '../features/widgets/data/widget_sync_controller.dart'
    show WidgetLifecycleHook;
import '../l10n/generated/app_localizations.dart';
import '../shared/time_zones.dart' show journeyLocalDate;
import '../ui/ui.dart';
import 'account_reset.dart';
import 'locale_override.dart';
import 'localization.dart';
import 'overlays/reminder_banner.dart';
import 'providers.dart';
import 'router.dart';
import 'theme/app_theme.dart' show OurneyTextScaleClamp;

class OurneyApp extends ConsumerWidget {
  const OurneyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    // Keep the haptics toggle mirrored into OurneyHaptics.enabled.
    ref.watch(hapticsEnabledProvider);
    // Sign-out / account deletion clears the previous account's local state.
    ref.watch(accountSessionResetProvider);
    ref.watch(appUpdateLifecycleProvider);
    // A retold journey a kill interrupted is finished in the background.
    ref.watch(importResumeProvider);
    // tz database decoded after the first frame (camera ready < 1 s).
    ref.watch(timeZoneWarmupProvider);
    // The active journey's persona colors the whole app; the router is not
    // rebuilt when it changes (docs/06 §1 Q1).
    final skin = ref.watch(activePersonaSkinProvider);
    final locale = ref.watch(localeOverrideProvider);
    final onboarded = ref.watch(onboardingCompleteProvider);
    final serverPulls = ref.watch(serverPullsProvider);
    final a11y =
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures;
    final reduceMotion = a11y.disableAnimations || a11y.reduceMotion;
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).app_name,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      locale: locale,
      theme: OurneyTheme.build(Brightness.light, skin),
      darkTheme: OurneyTheme.build(Brightness.dark, skin),
      themeMode: ref.watch(themeModeProvider),
      themeAnimationDuration: reduceMotion
          ? UiMotion.reducedFade
          : UiMotion.theme,
      themeAnimationCurve: UiCurves.easeOutStrong,
      supportedLocales: ourneySupportedLocales,
      localizationsDelegates: ourneyLocalizationsDelegates,
      // Reminders: reschedule on start/resume, open the journey camera on a
      // notification or banner tap (FR-G1, FR-G2), falling back gracefully if
      // the journey was deleted.
      builder: (context, child) => DayTicker(
        child: SharePrivacyHealHook(
          serverPulls: serverPulls,
          child: ReminderLifecycleHook(
            onOpenJourney: (id) =>
                unawaited(_openReminderJourney(ref, router, id)),
            child: WidgetLifecycleHook(
              child: OurneyTextScaleClamp(
                // In-app reminder banner (V2 `ReminderNotification`): shown while
                // `reminderBannerProvider` holds a value; a tap opens the camera.
                // Suppressed when `UpdateGateHost` presents the forced gate.
                child: _SplashGate(
                  returning: onboarded,
                  child: UpdateGateHost(
                    child: ReminderBannerHost(
                      onOpenJourneyCamera: (id) =>
                          unawaited(_openReminderJourney(ref, router, id)),
                      child: child ?? const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openReminderJourney(
    WidgetRef ref,
    GoRouter router,
    String id,
  ) async {
    var active = true;
    try {
      final journeys = await ref
          .read(journeyRepositoryProvider)
          .watchActive()
          .first
          .timeout(const Duration(seconds: 2));
      final now = ref.read(journeysClockProvider).now();
      active = journeys.any(
        (j) =>
            j.id == id &&
            j.status == JourneyStatus.active &&
            !j.isPastEndOn(journeyLocalDate(j.timezone, now)),
      );
    } on Object {
      active = true;
    }
    if (active) {
      unawaited(ref.read(activeJourneyIdProvider.notifier).select(id));
    }
    router.go(active ? JourneysPaths.captureFor(id) : AppRoutes.capture);
  }
}

/// V2 `SplashFlow` over the first frames of every launch, then fades out.
///
/// First launch ([returning] false): stickers, ransom-note wordmark and a
/// tagline that rotates every 1.2s; it holds for 2.4s and a tap skips ahead.
/// Returning person: wordmark and spinner for 650ms. Reduced motion keeps the
/// first tagline and removes the rotation and fades.
class _SplashGate extends StatefulWidget {
  const _SplashGate({required this.returning, required this.child});

  final bool returning;
  final Widget child;

  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate>
    with SingleTickerProviderStateMixin {
  static const _taglineEvery = 1200;

  late final int _holdMs = widget.returning ? 650 : 2400;
  late final int _normalFadeMs = widget.returning ? 200 : 300;
  int _fadeMs = 300;
  bool _reduced = false;
  bool _started = false;
  int _taglineIndex = 0;
  bool _ignoring = false;
  bool _completed = false;

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: _holdMs + _normalFadeMs),
  )..addListener(_onTick);

  CurvedAnimation? _fadeCurved;
  late Animation<double> _opacityAnim = const AlwaysStoppedAnimation<double>(
    1.0,
  );

  void _configureFade(bool reduced) {
    final nextFadeMs = reduced
        ? UiMotion.reducedFade.inMilliseconds
        : _normalFadeMs;
    if (_started && _reduced == reduced && _fadeMs == nextFadeMs) return;
    _reduced = reduced;
    _fadeMs = nextFadeMs;
    final totalMs = _holdMs + _fadeMs;
    _c.duration = Duration(milliseconds: totalMs);
    _fadeCurved?.dispose();
    final holdEnd = _holdMs / totalMs;
    final curved = CurvedAnimation(
      parent: _c,
      curve: Interval(
        holdEnd,
        1.0,
        curve: reduced ? Curves.linear : UiCurves.easeOutStrong,
      ),
    );
    _fadeCurved = curved;
    _opacityAnim = ReverseAnimation(curved);
  }

  void _onTick() {
    if (!mounted) return;
    final total = _holdMs + _fadeMs;
    final elapsed = _c.value * total;
    final t = ((elapsed - _holdMs) / _fadeMs).clamp(0.0, 1.0);
    final nextIndex = _reduced ? 0 : (elapsed ~/ _taglineEvery);
    final nextIgnoring = t > 0.5;
    final nextCompleted = _c.isCompleted;
    if (nextIndex != _taglineIndex ||
        nextIgnoring != _ignoring ||
        nextCompleted != _completed) {
      setState(() {
        _taglineIndex = nextIndex;
        _ignoring = nextIgnoring;
        _completed = nextCompleted;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = UiMotion.reduced(context);
    _configureFade(reduced);
    if (!_started) {
      _started = true;
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.removeListener(_onTick);
    _fadeCurved?.dispose();
    _c.dispose();
    super.dispose();
  }

  /// A tap on the first-launch splash jumps to the fade-out (V2: tap starts).
  void _skipHold() {
    final holdEnd = _holdMs / (_holdMs + _fadeMs);
    if (_c.value < holdEnd) _c.forward(from: holdEnd);
  }

  @override
  Widget build(BuildContext context) {
    if (_completed || _c.isCompleted) return widget.child;
    final reduce = UiMotion.reduced(context);
    final l10n = OnboardingL10n.of(context);
    final taglines = [
      l10n.onboarding_splashTagline1,
      l10n.onboarding_splashTagline2,
      l10n.onboarding_splashTagline3,
    ];
    final index = reduce ? 0 : (_taglineIndex % taglines.length);
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        IgnorePointer(
          ignoring: _ignoring,
          child: FadeTransition(
            opacity: _opacityAnim,
            child: Semantics(
              button: !widget.returning,
              label: widget.returning
                  ? l10n.onboarding_splashOpening
                  : l10n.onboarding_splashStart,
              excludeSemantics: true,
              onTap: widget.returning ? null : _skipHold,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.returning ? null : _skipHold,
                child: UiSplash(
                  returning: widget.returning,
                  firstLaunch: !widget.returning,
                  tagline: widget.returning ? null : taglines[index],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
