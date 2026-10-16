import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import '../../app/redirect.dart' show safeFrom;
import 'auth_screen.dart';

/// Sign-in (FR-A1), reachable only when a backend is configured: the router
/// never shows `/auth` in local-only mode and leaves it once a user id exists.
/// Profile setup after the first sign-in lives at `/profile/setup` (profile
/// feature) because `/auth/*` is left as soon as the user is signed in.
///
/// Contract (lib/features/README.md): keep exporting
/// `List<RouteBase> authRoutes`. Full-screen (outside the tab shell).
final List<RouteBase> authRoutes = [
  GoRoute(
    path: AppRoutes.auth,
    builder: (context, state) => AuthScreen(from: safeFrom(state.uri)),
  ),
];
