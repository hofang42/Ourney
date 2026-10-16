import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import 'onboarding_screen.dart';

/// Onboarding (FR-A3): at most 3 pages, no permission prompts.
///
/// Contract (lib/features/README.md): keep exporting
/// `List<RouteBase> onboardingRoutes`; top-level paths must start with
/// `/onboarding`. Full-screen (outside the tab shell).
///
/// The router sends every location here until onboarding is complete.
/// [OnboardingScreen] calls `onboardingCompleteProvider.notifier.complete()`
/// and the router redirect then moves on by itself (to `/auth` when a backend
/// is configured and nobody is signed in, else to the `?from=` target or
/// `/capture`).
final List<RouteBase> onboardingRoutes = [
  GoRoute(
    path: AppRoutes.onboarding,
    builder: (context, state) => const OnboardingScreen(),
  ),
];
