import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app_shell.dart';
import 'feature_routes.dart';
import 'navigator_keys.dart';

/// Well-known paths. Features should build links with these helpers.
abstract final class AppRoutes {
  static const capture = '/capture';
  static const journeys = '/journeys';
  static const groups = '/groups';
  static const auth = '/auth';
  static const onboarding = '/onboarding';
  static const profile = '/profile';
  static const safety = '/safety';

  /// `ourney://join/<code>` lands here (declared in groups routes).
  static String join(String code) => '/join/${Uri.encodeComponent(code)}';

  /// `ourney://journey/<id>` lands here (declared in journeys routes).
  static String journey(String id) => '/journey/${Uri.encodeComponent(id)}';

  static String share(String journeyId) =>
      '/share/${Uri.encodeComponent(journeyId)}';
}

/// Custom URL scheme registered by the platform projects.
const String kDeepLinkScheme = 'ourney';

/// Maps `ourney://join/<code>` and `ourney://journey/<id>` (host = first
/// segment) to an in-app path. Returns null for non-deep-link URIs.
String? normalizeDeepLink(Uri uri) {
  if (uri.scheme != kDeepLinkScheme) return null;
  final host = uri.host;
  final rest = uri.path; // "/<code>" or ""
  final path = host.isEmpty ? rest : '/$host$rest';
  final query = uri.hasQuery ? '?${uri.query}' : '';
  return '$path$query';
}

GoRouter createRouter({
  String initialLocation = AppRoutes.capture,
  GlobalKey<NavigatorState>? navigatorKey,
  List<NavigatorObserver>? observers,
}) {
  return GoRouter(
    navigatorKey: navigatorKey ?? rootNavigatorKey,
    initialLocation: initialLocation,
    observers: observers,
    redirect: (context, state) => normalizeDeepLink(state.uri),
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: FeatureRoutes.journeysTab),
          StatefulShellBranch(
            initialLocation: AppRoutes.capture,
            routes: FeatureRoutes.captureTab,
          ),
          StatefulShellBranch(routes: FeatureRoutes.groupsTab),
        ],
      ),
      ...FeatureRoutes.standalone,
    ],
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final router = createRouter();
  ref.onDispose(router.dispose);
  return router;
});
