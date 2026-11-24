import 'app_routes.dart';

/// Custom URL scheme registered by the platform projects (`ourney://`).
const String kDeepLinkScheme = 'ourney';

/// Canonical web domain for Universal Links / App Links (`https://ourney.tech`).
const String kDeepLinkWebHost = 'ourney.tech';

/// Who is (or is not) signed in, as seen by the router.
enum AuthStatus {
  /// No backend configured (FR-A5): there is no sign-in at all.
  localOnly,

  /// Backend configured and a session exists.
  signedIn,

  /// Backend configured and no session: guarded routes go to `/auth`.
  signedOut,
}

/// Maps custom-scheme (`ourney://{friend,f,join,j,journey,p}/<id>`) and web
/// (`https://ourney.tech/{f,j,join,p}/<id>`) deep links to an in-app route.
/// Returns null for non-deep-link URIs or unallowlisted hosts/paths.
String? normalizeDeepLink(Uri uri) {
  final query = uri.hasQuery ? '?${uri.query}' : '';
  if (uri.scheme == kDeepLinkScheme) {
    final host = uri.host.toLowerCase();
    final rest = uri.path;
    if (host.isEmpty) {
      if (rest.isEmpty || rest == '/') return AppRoutes.capture;
      return null;
    }
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length != 1) return null;
    final id = Uri.encodeComponent(segments.single);
    final prefix = switch (host) {
      'friend' || 'f' => '/f',
      'join' || 'j' => '/join',
      'journey' => '/journey',
      'p' => '/p',
      _ => null,
    };
    if (prefix == null) return null;
    return '$prefix/$id$query';
  }

  if (uri.scheme == 'https' || uri.scheme == 'http') {
    if (uri.host.toLowerCase() != kDeepLinkWebHost) return null;
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length != 2) return null;
    final kind = segments[0].toLowerCase();
    final id = Uri.encodeComponent(segments[1]);
    final prefix = switch (kind) {
      'f' => '/f',
      'j' || 'join' => '/join',
      'p' => '/p',
      _ => null,
    };
    if (prefix == null) return null;
    return '$prefix/$id$query';
  }

  return null;
}

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

  Uri inAppUri = uri;
  final bool isExternalUri = uri.hasScheme || uri.hasAuthority;
  if (isExternalUri) {
    final normalized = normalizeDeepLink(uri);
    if (normalized == null) return AppRoutes.capture;
    inAppUri = Uri.parse(normalized);
  }

  final rawPath = inAppUri.path.isEmpty ? '/' : inAppUri.path;
  if (rawPath == '/') return AppRoutes.capture;
  final path = rawPath;

  bool under(List<String> prefixes) =>
      prefixes.any((p) => pathHasPrefix(path, p));

  if (!onboarded) {
    if (pathHasPrefix(path, kEulaAcceptPath)) {
      return _carryFrom(AppRoutes.onboarding, inAppUri);
    }
    if (under(_preOnboardingPrefixes)) return null;
    return _withFrom(AppRoutes.onboarding, inAppUri);
  }

  if (auth == AuthStatus.signedOut) {
    if (pathHasPrefix(path, kEulaAcceptPath)) {
      return _carryFrom(AppRoutes.auth, inAppUri);
    }
    if (under(preAuthPrefixes)) {
      // Onboarding is done; continue to sign-in, keeping the target.
      if (pathHasPrefix(path, AppRoutes.onboarding)) {
        return _carryFrom(AppRoutes.auth, inAppUri);
      }
      return null;
    }
    return _withFrom(AppRoutes.auth, inAppUri);
  }

  // Apple Guideline 1.2: a signed-in user accepts the terms before seeing
  // any user content. Local-only mode has no other users: no gate.
  if (auth == AuthStatus.signedIn && !eulaAccepted) {
    if (pathHasPrefix(path, AppRoutes.safety)) return null;
    final leavingGate =
        pathHasPrefix(path, AppRoutes.onboarding) ||
        pathHasPrefix(path, AppRoutes.auth);
    final target = leavingGate
        ? (safeFrom(inAppUri) ?? AppRoutes.capture)
        : _inAppTarget(inAppUri);
    if (target == AppRoutes.capture) return kEulaAcceptPath;
    return Uri(
      path: kEulaAcceptPath,
      queryParameters: {AppRoutes.fromParam: target},
    ).toString();
  }

  // Gates already satisfied: leave onboarding/auth/EULA gate for the saved target.
  if (pathHasPrefix(path, AppRoutes.onboarding) ||
      pathHasPrefix(path, AppRoutes.auth) ||
      pathHasPrefix(path, kEulaAcceptPath)) {
    return safeFrom(inAppUri) ?? AppRoutes.capture;
  }
  if (isExternalUri) {
    return inAppUri.toString();
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
  if (uri.hasScheme || uri.hasAuthority) {
    return normalizeDeepLink(uri) ?? AppRoutes.capture;
  }
  final path = uri.path.isEmpty ? '/' : uri.path;
  return uri.hasQuery ? '$path?${uri.query}' : path;
}

String _withFrom(String gate, Uri original) {
  final target = _inAppTarget(original);
  if (target == AppRoutes.capture ||
      pathHasPrefix(target, AppRoutes.onboarding) ||
      pathHasPrefix(target, AppRoutes.auth) ||
      pathHasPrefix(target, kEulaAcceptPath)) {
    return gate;
  }
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
