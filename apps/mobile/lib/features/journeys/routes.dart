import 'package:go_router/go_router.dart';

import '../../shared/placeholder_screen.dart';

/// PLACEHOLDER: the journeys feature agent replaces this file.
/// Keep exporting `List<RouteBase> journeysRoutes`. These routes live in the
/// Journeys tab of the shell. `/journey/:id` is the target of the
/// `ourney://journey/<id>` deep link.
final List<RouteBase> journeysRoutes = [
  GoRoute(
    path: '/journeys',
    builder: (context, state) => const PlaceholderScreen(name: 'journeys'),
  ),
  GoRoute(
    path: '/journey/:id',
    builder: (context, state) =>
        PlaceholderScreen(name: 'journey ${state.pathParameters['id']}'),
  ),
];
