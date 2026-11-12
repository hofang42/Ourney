import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/reminders/data/reminder_scheduler.dart';
import '../l10n/generated/app_localizations.dart';
import '../ui/ui.dart';
import 'locale_override.dart';
import 'localization.dart';
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
      themeMode: ThemeMode.system,
      themeAnimationDuration: reduceMotion
          ? OurneyDurations.reducedFade
          : OurneyDurations.personaTheme,
      themeAnimationCurve: Curves.easeOutCubic,
      supportedLocales: ourneySupportedLocales,
      localizationsDelegates: ourneyLocalizationsDelegates,
      // Reminders: reschedule on start/resume, open the journey on a
      // notification tap (FR-G1, FR-G2).
      builder: (context, child) => ReminderLifecycleHook(
        onOpenJourney: (id) => router.go(AppRoutes.journey(id)),
        child: OurneyTextScaleClamp(
          child: _SplashGate(
            enabled: !onboarded,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

/// Shows the V1.0 splash (coral field, ink wordmark) over the very first
/// frames of a first launch (before onboarding), then fades it out.
class _SplashGate extends StatefulWidget {
  const _SplashGate({required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  bool _started = false;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      _started = true;
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_started || _c.isCompleted) return widget.child;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            // Hold the splash for the first 60%, then fade it out.
            final t = ((_c.value - 0.6) / 0.4).clamp(0.0, 1.0);
            if (_c.isCompleted) return const SizedBox.shrink();
            return IgnorePointer(
              ignoring: t > 0.5,
              child: Opacity(
                opacity: reduce ? (t < 1 ? 1 : 0) : 1 - t,
                child: const UiSplash(),
              ),
            );
          },
        ),
      ],
    );
  }
}
