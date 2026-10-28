/// Route paths owned by each feature. Build links with these constants and
/// helpers (`context.go(AppRoutes.journey(id))`) instead of string literals.
///
/// Ownership rule (enforced by test/app/route_registry_test.dart): every
/// top-level route in `lib/features/<f>/routes.dart` must start with one of
/// the prefixes listed for `<f>` in [featureRoutePrefixes]. Sub-routes are
/// free-form children of those (e.g. `/journeys/new`, `/safety/report`).
///
/// Adding a new top-level prefix is an Orchestrator change to this file.
abstract final class AppRoutes {
  // camera — Capture tab (center). The app's initial location (FR-C1).
  static const capture = '/capture';

  // checkin — full screen on the root navigator (covers the bottom bar).
  static const checkin = '/checkin';

  // journeys — Journeys tab.
  static const journeys = '/journeys';
  static const journeyNew = '/journeys/new';

  /// Journey detail/timeline. Target of `ourney://journey/<id>`.
  static String journey(String id) => '/journey/${Uri.encodeComponent(id)}';

  // groups — Groups tab. Shows "needs server" in local-only mode.
  static const groups = '/groups';

  /// Join by invite code. Target of `ourney://join/<code>`.
  static String join(String code) => '/join/${Uri.encodeComponent(code)}';

  // Full-screen (outside the tab shell).
  static const onboarding = '/onboarding';
  static const auth = '/auth';
  static const profile = '/profile';
  static const safety = '/safety';
  static const reminders = '/reminders';

  /// Share card for a journey (C2).
  static String share(String journeyId) =>
      '/share/${Uri.encodeComponent(journeyId)}';

  // social — full screen on the root navigator. Need the server.
  static const friends = '/friends';
  static const friendsAdd = '/friends/add';
  static const inbox = '/inbox';

  /// 1-1 conversation tied to a journey (SCR-86).
  static String chat(String conversationId) =>
      '/chat/${Uri.encodeComponent(conversationId)}';

  /// Friend invite link. Target of `ourney://friend/<token>` and
  /// `https://ourney.app/f/<token>`.
  static String friendInvite(String token) =>
      '/f/${Uri.encodeComponent(token)}';

  /// Query parameter carrying the location to return to after onboarding or
  /// sign-in (set by the router redirect).
  static const fromParam = 'from';
}

/// Top-level path prefixes each feature may declare. Keys are the folder
/// names under `lib/features/`.
const Map<String, List<String>> featureRoutePrefixes = {
  'auth': [AppRoutes.auth],
  'onboarding': [AppRoutes.onboarding],
  'profile': [AppRoutes.profile],
  'camera': [AppRoutes.capture],
  'checkin': [AppRoutes.checkin],
  'journeys': [AppRoutes.journeys, '/journey'],
  'groups': [AppRoutes.groups, '/join'],
  'share_card': ['/share'],
  'safety': [AppRoutes.safety],
  'reminders': [AppRoutes.reminders],
  'social': [AppRoutes.friends, AppRoutes.inbox, '/chat', '/f'],
};

/// Paths reachable before onboarding/sign-in is complete. Everything else is
/// guarded by the router redirect (lib/app/redirect.dart).
const List<String> preAuthPrefixes = [
  AppRoutes.onboarding,
  AppRoutes.auth,
  // EULA, privacy and contact pages must be readable before sign-in.
  AppRoutes.safety,
];

/// True when [path] equals [prefix] or is a sub-path of it.
bool pathHasPrefix(String path, String prefix) =>
    path == prefix || path.startsWith('$prefix/');
