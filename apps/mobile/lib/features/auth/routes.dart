import 'package:go_router/go_router.dart';

import '../../shared/placeholder_screen.dart';

/// PLACEHOLDER: the auth feature agent replaces this file.
/// Keep exporting `List<RouteBase> authRoutes` (full-screen, outside the tab shell).
final List<RouteBase> authRoutes = [
  GoRoute(
    path: '/auth',
    builder: (context, state) => const PlaceholderScreen(name: 'auth'),
  ),
];
