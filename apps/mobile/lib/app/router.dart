import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/camera/capture_screen.dart' show CaptureScreen;
import '../features/profile/profile_providers.dart'
    show profileGateStatusProvider;
import 'app_routes.dart';
import 'app_shell.dart';
import 'feature_routes.dart';
import 'navigator_keys.dart';
import 'overlays/not_found_screen.dart';
import 'providers.dart';
import 'redirect.dart';

export 'app_routes.dart';
export 'redirect.dart'
    show
        AuthStatus,
        ProfileGateStatus,
        kDeepLinkScheme,
        kMalformedInviteSegment,
        malformedInviteFallback,
        normalizeDeepLink;

/// Builds the app router from the per-feature route registry
/// ([FeatureRoutes]). [redirect] defaults to deep-link normalisation only;
/// the app passes the onboarding/auth policy via [routerProvider].
GoRouter createRouter({
  String initialLocation = AppRoutes.capture,
  GlobalKey<NavigatorState>? navigatorKey,
  List<NavigatorObserver>? observers,
  GoRouterRedirect? redirect,
  Listenable? refreshListenable,
}) {
  return GoRouter(
    navigatorKey: navigatorKey ?? rootNavigatorKey,
    initialLocation: initialLocation,
    observers: observers,
    errorBuilder: (context, state) => const NotFoundRedirect(),
    refreshListenable: refreshListenable,
    redirect:
        redirect ??
        (context, state) => (state.uri.hasScheme || state.uri.hasAuthority)
            ? (normalizeDeepLink(state.uri) ??
                  malformedInviteFallback(state.uri) ??
                  AppRoutes.capture)
            : null,
    routes: [
      StatefulShellRoute(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        navigatorContainerBuilder: (context, navigationShell, children) =>
            UiShellBranchContainer(
              currentIndex: navigationShell.currentIndex,
              children: children,
            ),
        branches: [
          StatefulShellBranch(
            initialLocation: AppRoutes.journeys,
            routes: FeatureRoutes.journeysTab,
          ),
          StatefulShellBranch(
            initialLocation: AppRoutes.groups,
            routes: FeatureRoutes.groupsTab,
          ),
          StatefulShellBranch(
            initialLocation: AppRoutes.capture,
            routes: FeatureRoutes.captureTab,
          ),
          StatefulShellBranch(
            initialLocation: AppRoutes.inbox,
            routes: FeatureRoutes.activityTab,
          ),
          StatefulShellBranch(
            initialLocation: AppRoutes.profile,
            routes: FeatureRoutes.profileTab,
          ),
        ],
      ),
      ...FeatureRoutes.standalone,
    ],
  );
}

/// The app's router. Camera-first (FR-C1): starts at `/capture`; redirects to
/// `/onboarding` until onboarding is complete and to `/auth` when a backend
/// is configured and nobody is signed in (see [resolveRedirect]).
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  void bump(Object? _, Object? _) => refresh.value++;
  ref
    ..listen(onboardingCompleteProvider, bump)
    ..listen(authStatusProvider, bump)
    ..listen(profileGateStatusProvider, bump);

  String? redirectFor(Uri uri) => resolveRedirect(
    uri: uri,
    onboarded: ref.read(onboardingCompleteProvider),
    auth: ref.read(authStatusProvider),
    profileGate: ref.read(profileGateStatusProvider),
  );

  final router = createRouter(
    refreshListenable: refresh,
    redirect: (context, state) {
      final location = redirectFor(state.uri);
      if (state.uri.scheme != kDeepLinkScheme || location == null) {
        return location;
      }
      final target = Uri.parse(location);
      final id = target.queryParameters[CaptureScreen.journeyIdParam];
      if (target.path != AppRoutes.capture || id == null || id.isEmpty) {
        return location;
      }
      final gate = redirectFor(target);
      if (gate != null) return gate;

      // The camera page can be reused when the same widget URL is tapped
      // again. Apply the selection before publishing the capture route.
      return Future<String>.microtask(() {
        if (ref.mounted) {
          unawaited(ref.read(activeJourneyIdProvider.notifier).select(id));
        }
        return location;
      });
    },
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});
