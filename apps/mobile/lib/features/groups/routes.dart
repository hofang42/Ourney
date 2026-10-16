import 'package:go_router/go_router.dart';

import '../../shared/placeholder_screen.dart';

/// PLACEHOLDER: the groups feature agent replaces this file.
/// Keep exporting `List<RouteBase> groupsRoutes`. These routes live in the
/// Nhom tab of the shell. `/join/:code` is the target of the
/// `ourney://join/<code>` deep link.
final List<RouteBase> groupsRoutes = [
  GoRoute(
    path: '/groups',
    builder: (context, state) => const PlaceholderScreen(name: 'groups'),
  ),
  GoRoute(
    path: '/join/:code',
    builder: (context, state) =>
        PlaceholderScreen(name: 'join ${state.pathParameters['code']}'),
  ),
];
