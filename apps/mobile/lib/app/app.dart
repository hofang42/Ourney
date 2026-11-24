import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart' show JourneyStatus;

import '../features/import/data/import_providers.dart'
    show importResumeProvider;
import '../features/journeys/data/journeys_providers.dart'
    show timeZoneWarmupProvider;
import '../features/journeys/journeys_paths.dart';
import '../features/journeys/ui/day_ticker.dart';
import '../features/onboarding/l10n/generated/onboarding_localizations.dart';
import '../features/profile/settings_providers.dart' show themeModeProvider;
import '../features/profile/share_privacy_sync.dart' show SharePrivacyHealHook;
import '../features/reminders/data/reminder_scheduler.dart';
import '../l10n/generated/app_localizations.dart';
import '../ui/ui.dart';
import 'account_reset.dart';
import 'locale_override.dart';
import 'localization.dart';
import 'overlays/reminder_banner.dart';
import 'providers.dart';
import 'router.dart';
import 'theme/app_theme.dart' show OurneyTextScaleClamp;
import 'theme/tokens.dart' show OurneyDurations;

class OurneyApp extends ConsumerWidget {
  const OurneyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    // Keep the haptics toggle mirrored into OurneyHaptics.enabled.
    ref.watch(hapticsEnabledProvider);
    // Sign-out / account deletion clears the previous account's local state.
    ref.watch(accountSessionResetProvider);
    // A retold journey a kill interrupted is finished in the background.
    ref.watch(importResumeProvider);
    // tz database decoded after the first frame (camera ready < 1 s).
    ref.watch(timeZoneWarmupProvider);
    // The active journey's persona colors the whole app; the router is not
    // rebuilt when it changes (docs/06 §1 Q1).
    final skin = ref.watch(activePersonaSkinProvider);
    final locale = ref.watch(localeOverrideProvider);
    final onboarded = ref.watch(onboardingCompleteProvider);
    final reduceMotion = WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations;
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).app_name,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      locale: locale,
      theme: OurneyTheme.build(Brightness.light, skin),
      darkTheme: OurneyTheme.build(Brightness.dark, skin),
      themeMode: ref.watch(themeModeProvider),
      themeAnimationDuration: reduceMotion
          ? OurneyDurations.reducedFade
          : OurneyDurations.personaTheme,
      themeAnimationCurve: Curves.easeOutCubic,
      supportedLocales: ourneySupportedLocales,
      localizationsDelegates: ourneyLocalizationsDelegates,
      // Reminders: reschedule on start/resume, open the journey camera on a
      // notification or banner tap (FR-G1, FR-G2), falling back gracefully if
      // the journey was deleted.
      builder: (context, child) => DayTicker(
        child: SharePrivacyHealHook(
          child: ReminderLifecycleHook(
            onOpenJourney: (id) =>
                unawaited(_openReminderJourney(ref, router, id)),
            child: OurneyTextScaleClamp(
              // In-app reminder banner (V2 `ReminderNotification`): shown while
              // `reminderBannerProvider` holds a value; a tap opens the camera.
              child: ReminderBannerHost(
                onOpenJourneyCamera: (id) =>
                    unawaited(_openReminderJourney(ref, router, id)),
                child: _SplashGate(
                  returning: onboarded,
                  child: child ?? const SizedBox.shrink(),
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
      final journey = await ref
          .read(journeyRepositoryProvider)
          .watch(id)
          .first
          .timeout(const Duration(seconds: 2));
      active = journey != null && journey.status == JourneyStatus.active;
    } on Object {
      active = true;
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
  late final int _fadeMs = widget.returning ? 200 : 300;
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: _holdMs + _fadeMs),
  );

  @override
  void initState() {
    super.initState();
    _c.forward();
  }

  @override
  void dispose() {
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
    if (_c.isCompleted) return widget.child;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final l10n = OnboardingL10n.of(context);
    final taglines = [
      l10n.onboarding_splashTagline1,
      l10n.onboarding_splashTagline2,
      l10n.onboarding_splashTagline3,
    ];
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            if (_c.isCompleted) return const SizedBox.shrink();
            final total = _holdMs + _fadeMs;
            final elapsed = _c.value * total;
            final t = ((elapsed - _holdMs) / _fadeMs).clamp(0.0, 1.0);
            final index = reduce
                ? 0
                : (elapsed ~/ _taglineEvery) % taglines.length;
            return IgnorePointer(
              ignoring: t > 0.5,
              child: Opacity(
                opacity: reduce ? (t < 1 ? 1 : 0) : 1 - t,
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
                      tagline: widget.returning ? null : taglines[index],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
