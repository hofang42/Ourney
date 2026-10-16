import 'package:go_router/go_router.dart';

import '../../shared/placeholder_screen.dart';

/// PLACEHOLDER: the onboarding feature agent replaces this file.
/// Keep exporting `List<RouteBase> onboardingRoutes` (full-screen, outside the tab shell).
final List<RouteBase> onboardingRoutes = [
  GoRoute(
    path: '/onboarding',
    builder: (context, state) =>
        const PlaceholderScreen(name: 'onboarding'),
  ),
];
