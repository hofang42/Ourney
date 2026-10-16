import 'package:go_router/go_router.dart';

import '../../shared/placeholder_screen.dart';

/// PLACEHOLDER: the profile feature agent replaces this file.
/// Keep exporting `List<RouteBase> profileRoutes` (full-screen, outside the tab shell).
final List<RouteBase> profileRoutes = [
  GoRoute(
    path: '/profile',
    builder: (context, state) => const PlaceholderScreen(name: 'profile'),
  ),
];
