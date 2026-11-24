import 'app_routes.dart';

/// Custom URL scheme registered by the platform projects (`ourney://`).
const String kDeepLinkScheme = 'ourney';

/// Who is (or is not) signed in, as seen by the router.
enum AuthStatus {
  /// No backend configured (FR-A5): there is no sign-in at all.
  localOnly,

  /// Backend configured and a session exists.
  signedIn,

  /// Backend configured and no session: guarded routes go to `/auth`.
  signedOut,
}

/// Allowed hosts for custom-scheme deep links (`ourney://<host>/<id>`).
const Set<String> _allowedDeepLinkHosts = {'join', 'journey', 'friend'};

/// Maps `ourney://join/<code>`, `ourney://journey/<id>`, and
/// `ourney://friend/<token>` (host = first segment) to an in-app path.
/// Returns null for non-deep-link URIs or unallowlisted `ourney://` hosts.
String? normalizeDeepLink(Uri uri) {
  if (uri.scheme != kDeepLinkScheme) return null;
  final host = uri.host;
  final rest = uri.path; // "/<code>" or ""
  if (host.isEmpty) {
    if (rest.isEmpty || rest == '/') return AppRoutes.capture;
    return null;
  }
  if (!_allowedDeepLinkHosts.contains(host)) return null;
  // `ourney://friend/<token>` is the friend invite link (`/f/<token>`).
  final segment = host == 'friend' ? 'f' : host;
  final path = '/$segment$rest';
  final query = uri.hasQuery ? '?${uri.query}' : '';
  return '$path$query';
}

String _normalizeWebInvitePath(String path) =>
    path.startsWith('/j/') && path.length > 3
    ? '/join/${path.substring(3)}'
    : path;

/// Paths reachable before onboarding is finished.
const List<String> _preOnboardingPrefixes = [
  AppRoutes.onboarding,
  AppRoutes.safety,
];

/// EULA acceptance gate (FR-F3), owned by the safety feature
/// (`SafetyPaths.eulaAccept`). Kept as a literal here: lib/app must not
/// import feature internals from the redirect policy.
const String kEulaAcceptPath = '${AppRoutes.safety}/eula/accept';

/// Pure redirect policy used by the app router (unit-tested).
///
/// Order: deep-link normalisation -> onboarding gate -> auth gate (only when
/// a backend is configured) -> EULA gate (signed in only) -> bounce away
/// from finished gates.
/// The original location is preserved in `?from=` and restored afterwards,
/// so a deep link opened on a fresh install still lands after onboarding.
String? resolveRedirect({
  required Uri uri,
  required bool onboarded,
  required AuthStatus auth,
  bool eulaAccepted = true,
}) {
  if (uri.scheme == kDeepLinkScheme) {
    return normalizeDeepLink(uri) ?? AppRoutes.capture;
  }

  final rawPath = uri.path.isEmpty ? '/' : uri.path;
  if (rawPath == '/') return AppRoutes.capture;
  final path = _normalizeWebInvitePath(rawPath);

  bool under(List<String> prefixes) =>
      prefixes.any((p) => pathHasPrefix(path, p));

  if (!onboarded) {
    if (under(_preOnboardingPrefixes)) return null;
    return _withFrom(AppRoutes.onboarding, uri);
  }

  if (auth == AuthStatus.signedOut) {
    if (under(preAuthPrefixes)) {
      // Onboarding is done; continue to sign-in, keeping the target.
      if (pathHasPrefix(path, AppRoutes.onboarding)) {
        return _carryFrom(AppRoutes.auth, uri);
      }
      return null;
    }
    return _withFrom(AppRoutes.auth, uri);
  }

  // Apple Guideline 1.2: a signed-in user accepts the terms before seeing
  // any user content. Local-only mode has no other users: no gate.
  if (auth == AuthStatus.signedIn && !eulaAccepted) {
    if (pathHasPrefix(path, AppRoutes.safety)) return null;
    final leavingGate =
        pathHasPrefix(path, AppRoutes.onboarding) ||
        pathHasPrefix(path, AppRoutes.auth);
    final target = leavingGate
        ? (safeFrom(uri) ?? AppRoutes.capture)
        : _inAppTarget(uri);
    if (target == AppRoutes.capture) return kEulaAcceptPath;
    return Uri(
      path: kEulaAcceptPath,
      queryParameters: {AppRoutes.fromParam: target},
    ).toString();
  }

  // Gates already satisfied: leave onboarding/auth/EULA gate for the saved target.
  if (pathHasPrefix(path, AppRoutes.onboarding) ||
      pathHasPrefix(path, AppRoutes.auth) ||
      (auth == AuthStatus.signedIn && pathHasPrefix(path, kEulaAcceptPath))) {
    return safeFrom(uri) ?? AppRoutes.capture;
  }
  if (path != rawPath) {
    return uri.hasQuery ? '$path?${uri.query}' : path;
  }
  return null;
}

/// The `?from=` target of [uri] if it is a safe in-app path, else null.
String? safeFrom(Uri uri) {
  final from = uri.queryParameters[AppRoutes.fromParam];
  if (from == null || from.isEmpty) return null;
  // Only in-app absolute paths; never another scheme/host or `//host`.
  if (!from.startsWith('/') || from.startsWith('//')) return null;
  final target = Uri.tryParse(from);
  if (target == null || target.hasScheme || target.hasAuthority) return null;
  if (pathHasPrefix(target.path, AppRoutes.onboarding) ||
      pathHasPrefix(target.path, AppRoutes.auth) ||
      pathHasPrefix(target.path, kEulaAcceptPath)) {
    return null;
  }
  return from;
}

/// The in-app part (`path?query`) of [uri]. A universal link such as
/// `https://ourney.tech/f/<token>` reaches the router with scheme and host;
/// keeping them in `?from=` would make [safeFrom] reject the target later.
String _inAppTarget(Uri uri) {
  final rawPath = uri.path.isEmpty ? '/' : uri.path;
  final path = _normalizeWebInvitePath(rawPath);
  if (!uri.hasScheme && !uri.hasAuthority && path == rawPath) {
    return uri.toString();
  }
  return uri.hasQuery ? '$path?${uri.query}' : path;
}

String _withFrom(String gate, Uri original) {
  final target = _inAppTarget(original);
  if (target == AppRoutes.capture) return gate;
  return Uri(
    path: gate,
    queryParameters: {AppRoutes.fromParam: target},
  ).toString();
}

String _carryFrom(String gate, Uri current) {
  final from = safeFrom(current);
  if (from == null) return gate;
  return Uri(
    path: gate,
    queryParameters: {AppRoutes.fromParam: from},
  ).toString();
}
