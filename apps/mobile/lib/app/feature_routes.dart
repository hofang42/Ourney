import 'package:go_router/go_router.dart';

import '../features/auth/routes.dart';
import '../features/camera/routes.dart';
import '../features/groups/routes.dart';
import '../features/journeys/routes.dart';
import '../features/onboarding/routes.dart';
import '../features/profile/routes.dart';
import '../features/safety/routes.dart';
import '../features/share_card/routes.dart';

/// Route registry. Each feature owns `lib/features/<name>/routes.dart`
/// exporting `List<RouteBase> <name>Routes`; this file only wires them.
///
/// * Tab routes render inside the bottom-bar shell (state kept per tab).
///   Journeys: `journeysRoutes`, Capture: `cameraRoutes`, Nhom: `groupsRoutes`.
/// * Standalone routes are full-screen on the root navigator.
/// * Use `rootNavigatorKey` (navigator_keys.dart) as `parentNavigatorKey` for
///   a tab-owned route that must cover the bottom bar (e.g. check-in review).
abstract final class FeatureRoutes {
  static List<RouteBase> get journeysTab => journeysRoutes;
  static List<RouteBase> get captureTab => cameraRoutes;
  static List<RouteBase> get groupsTab => groupsRoutes;

  static List<RouteBase> get standalone => [
        ...authRoutes,
        ...onboardingRoutes,
        ...profileRoutes,
        ...shareCardRoutes,
        ...safetyRoutes,
      ];
}
