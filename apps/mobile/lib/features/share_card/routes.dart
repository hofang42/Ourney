import 'package:go_router/go_router.dart';

import '../../shared/placeholder_screen.dart';

/// PLACEHOLDER: the share_card feature agent replaces this file.
/// Keep exporting `List<RouteBase> shareCardRoutes` (full-screen, outside the tab shell).
final List<RouteBase> shareCardRoutes = [
  GoRoute(
    path: '/share/:journeyId',
    builder: (context, state) => const PlaceholderScreen(name: 'share_card'),
  ),
];
