import 'package:go_router/go_router.dart';

import '../../shared/placeholder_screen.dart';

/// PLACEHOLDER: the safety feature agent replaces this file.
/// Keep exporting `List<RouteBase> safetyRoutes` (full-screen, outside the tab shell).
final List<RouteBase> safetyRoutes = [
  GoRoute(
    path: '/safety',
    builder: (context, state) => const PlaceholderScreen(name: 'safety'),
  ),
];
