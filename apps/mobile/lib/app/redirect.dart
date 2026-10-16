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

/// Maps `ourney://join/<code>` and `ourney://journey/<id>` (host = first
/// segment) to an in-app path. Returns null for non-deep-link URIs.
String? normalizeDeepLink(Uri uri) {
  if (uri.scheme != kDeepLinkScheme) return null;
  final host = uri.host;
  final rest = uri.path; // "/<code>" or ""
  var path = host.isEmpty ? rest : '/$host$rest';
  if (path.isEmpty) path = AppRoutes.capture;
  final query = uri.hasQuery ? '?${uri.query}' : '';
  return '$path$query';
}

/// Paths reachable before onboarding is finished.
const List<String> _preOnboardingPrefixes = [
  AppRoutes.onboarding,
  AppRoutes.safety,
];

/// Pure redirect policy used by the app router (unit-tested).
///
/// Order: deep-link normalisation -> onboarding gate -> auth gate (only when
/// a backend is configured) -> bounce away from finished gates.
/// The original location is preserved in `?from=` and restored afterwards,
/// so a deep link opened on a fresh install still lands after onboarding.
String? resolveRedirect({
  required Uri uri,
  required bool onboarded,
  required AuthStatus auth,
}) {
  final deepLink = normalizeDeepLink(uri);
  if (deepLink != null) return deepLink;

  final path = uri.path.isEmpty ? '/' : uri.path;
  if (path == '/') return AppRoutes.capture;

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

  // Gates already satisfied: leave onboarding/auth for the saved target.
  if (pathHasPrefix(path, AppRoutes.onboarding) ||
      pathHasPrefix(path, AppRoutes.auth)) {
    return safeFrom(uri) ?? AppRoutes.capture;
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
      pathHasPrefix(target.path, AppRoutes.auth)) {
    return null;
  }
  return from;
}

String _withFrom(String gate, Uri original) {
  final target = original.toString();
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
