import 'package:go_router/go_router.dart';

import '../features/auth/routes.dart';
import '../features/camera/routes.dart';
import '../features/checkin/routes.dart';
import '../features/groups/routes.dart';
import '../features/journeys/routes.dart';
import '../features/onboarding/routes.dart';
import '../features/profile/routes.dart';
import '../features/reminders/routes.dart';
import '../features/safety/routes.dart';
import '../features/share_card/routes.dart';
import '../features/sharing/routes.dart';
import '../features/social/routes.dart';

/// Route registry. Each feature owns `lib/features/<name>/routes.dart`
/// exporting `List<RouteBase> <name>Routes`; this file only wires them.
/// See lib/features/README.md for the full convention.
///
/// * Tab routes render inside the bottom-bar shell (state kept per tab):
///   Journeys = `journeysRoutes`, Capture = `cameraRoutes`,
///   Groups = `groupsRoutes`.
/// * Standalone routes are full-screen on the root navigator.
/// * A tab-owned route that must cover the bottom bar sets
///   `parentNavigatorKey: rootNavigatorKey` (lib/app/navigator_keys.dart).
abstract final class FeatureRoutes {
  static List<RouteBase> get journeysTab => journeysRoutes;
  static List<RouteBase> get captureTab => cameraRoutes;
  static List<RouteBase> get groupsTab => groupsRoutes;

  static List<RouteBase> get standalone => [
    ...onboardingRoutes,
    ...authRoutes,
    ...profileRoutes,
    ...checkinRoutes,
    ...shareCardRoutes,
    ...safetyRoutes,
    ...remindersRoutes,
    ...socialRoutes,
    ...sharingRoutes,
  ];

  /// Every feature's routes keyed by folder name (used by tests to enforce
  /// path ownership, see `featureRoutePrefixes`).
  static Map<String, List<RouteBase>> get byFeature => {
    'auth': authRoutes,
    'onboarding': onboardingRoutes,
    'profile': profileRoutes,
    'camera': cameraRoutes,
    'checkin': checkinRoutes,
    'journeys': journeysRoutes,
    'groups': groupsRoutes,
    'share_card': shareCardRoutes,
    'safety': safetyRoutes,
    'reminders': remindersRoutes,
    'social': socialRoutes,
    'sharing': sharingRoutes,
  };
}
