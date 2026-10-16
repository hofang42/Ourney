import 'package:go_router/go_router.dart';

import '../../shared/placeholder_screen.dart';

/// PLACEHOLDER: the camera feature agent replaces this file.
/// Keep exporting `List<RouteBase> cameraRoutes`. These routes live in the
/// middle (Capture) tab of the shell; `/capture` is the app's start page.
final List<RouteBase> cameraRoutes = [
  GoRoute(
    path: '/capture',
    builder: (context, state) => const PlaceholderScreen(name: 'camera'),
  ),
];
