import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/app_routes.dart';
import 'package:ourney/app/redirect.dart';

String? r(
  String location, {
  bool onboarded = true,
  AuthStatus? auth,
  bool eula = true,
}) => resolveRedirect(
  uri: Uri.parse(location),
  onboarded: onboarded,
  auth: auth ?? AuthStatus.localOnly,
  eulaAccepted: eula,
);

void main() {
  group('normalizeDeepLink', () {
    test('maps custom scheme and https://ourney.tech links to in-app paths', () {
      expect(
        normalizeDeepLink(Uri.parse('ourney://join/ABC123')),
        '/join/ABC123',
      );
      expect(
        normalizeDeepLink(Uri.parse('ourney://journey/j-42?x=1')),
        '/journey/j-42?x=1',
      );
      expect(
        normalizeDeepLink(Uri.parse('ourney://friend/tok123')),
        '/f/tok123',
      );
      expect(
        normalizeDeepLink(Uri.parse('ourney://p/pubtok123')),
        '/p/pubtok123',
      );
      expect(
        normalizeDeepLink(Uri.parse('https://ourney.tech/f/tok123')),
        '/f/tok123',
      );
      expect(
        normalizeDeepLink(Uri.parse('https://ourney.tech/j/ABCD1234')),
        '/join/ABCD1234',
      );
      expect(
        normalizeDeepLink(Uri.parse('https://ourney.tech/p/pubtok123')),
        '/p/pubtok123',
      );
      expect(normalizeDeepLink(Uri.parse('ourney://')), AppRoutes.capture);
      expect(normalizeDeepLink(Uri.parse('/capture')), isNull);
      expect(normalizeDeepLink(Uri.parse('https://x.dev/join/A')), isNull);
    });

    test('rejects unallowlisted custom-scheme and https hosts/paths (FS-05, DE-14)', () {
      expect(
        normalizeDeepLink(Uri.parse('ourney://profile/delete-account')),
        isNull,
      );
      expect(
        normalizeDeepLink(Uri.parse('ourney://safety/eula/accept')),
        isNull,
      );
      expect(
        normalizeDeepLink(Uri.parse('ourney:///profile/delete-account')),
        isNull,
      );
      expect(
        normalizeDeepLink(Uri.parse('ourney://friend')),
        isNull,
      );
      expect(
        normalizeDeepLink(Uri.parse('https://ourney.tech/profile/delete-account')),
        isNull,
      );
      expect(
        normalizeDeepLink(Uri.parse('https://ourney.tech/safety/eula/accept')),
        isNull,
      );
      expect(
        normalizeDeepLink(Uri.parse('https://ourney.tech/f/')),
        isNull,
      );
      expect(
        r('ourney://profile/delete-account', auth: AuthStatus.signedIn),
        AppRoutes.capture,
      );
      expect(
        r('https://ourney.tech/profile/delete-account', auth: AuthStatus.signedIn),
        AppRoutes.capture,
      );
      expect(
        r('https://ourney.tech/profile/delete-account', onboarded: false),
        AppRoutes.capture,
      );
    });
  });

  group('resolveRedirect', () {
    test('root goes to capture', () {
      expect(r('/'), AppRoutes.capture);
    });

    test('onboarded local-only user is never redirected', () {
      expect(r('/capture'), isNull);
      expect(r('/journey/1'), isNull);
      expect(r('/groups'), isNull);
    });

    test('not onboarded: everything goes to onboarding with from=', () {
      expect(r('/capture', onboarded: false), AppRoutes.onboarding);
      expect(
        r('/journey/1', onboarded: false),
        '/onboarding?from=%2Fjourney%2F1',
      );
      expect(r('/onboarding', onboarded: false), isNull);
      expect(r('/safety/terms', onboarded: false), isNull);
    });

    test('local-only leaves /onboarding and /auth for the target', () {
      expect(r('/onboarding?from=%2Fjoin%2FX'), '/join/X');
      expect(r('/onboarding'), AppRoutes.capture);
      expect(r('/auth'), AppRoutes.capture);
    });

    test('signed out with backend: guarded paths go to /auth', () {
      const out = AuthStatus.signedOut;
      expect(r('/capture', auth: out), AppRoutes.auth);
      expect(r('/groups', auth: out), '/auth?from=%2Fgroups');
      expect(r('/auth', auth: out), isNull);
      expect(r('/safety', auth: out), isNull);
      // Finishing onboarding continues to sign-in, keeping the target.
      expect(
        r('/onboarding?from=%2Fjoin%2FX', auth: out),
        '/auth?from=%2Fjoin%2FX',
      );
      expect(r('/onboarding', auth: out), AppRoutes.auth);
    });

    test('signed in leaves /auth for the target', () {
      const inn = AuthStatus.signedIn;
      expect(r('/auth?from=%2Fjoin%2FX', auth: inn), '/join/X');
      expect(r('/auth', auth: inn), AppRoutes.capture);
      expect(r('/groups', auth: inn), isNull);
    });

    test('EULA gate: signed in without acceptance (FR-F3)', () {
      const inn = AuthStatus.signedIn;
      expect(r('/capture', auth: inn, eula: false), kEulaAcceptPath);
      expect(
        r('/groups', auth: inn, eula: false),
        '$kEulaAcceptPath?from=%2Fgroups',
      );
      // Leaving /auth keeps the saved target.
      expect(
        r('/auth?from=%2Fjoin%2FX', auth: inn, eula: false),
        '$kEulaAcceptPath?from=%2Fjoin%2FX',
      );
      expect(r('/auth', auth: inn, eula: false), kEulaAcceptPath);
      // Safety pages (the gate itself, terms, privacy) stay reachable.
      expect(
        r('$kEulaAcceptPath?from=%2Fgroups', auth: inn, eula: false),
        isNull,
      );
      expect(r('/safety/privacy', auth: inn, eula: false), isNull);
      // Accepted: no gate, and kEulaAcceptPath bounces away (FS-05).
      expect(r('/groups', auth: inn), isNull);
      expect(r(kEulaAcceptPath, auth: inn), AppRoutes.capture);
      expect(
        r('$kEulaAcceptPath?from=%2Fgroups', auth: inn),
        AppRoutes.groups,
      );
    });

    test('EULA gate never applies to local-only or signed-out users', () {
      expect(r('/capture', eula: false), isNull);
      expect(r('/journey/1', eula: false), isNull);
      expect(
        r('/groups', auth: AuthStatus.signedOut, eula: false),
        '/auth?from=%2Fgroups',
      );
      expect(
        r('/capture', onboarded: false, eula: false),
        AppRoutes.onboarding,
      );
      // Navigating directly to kEulaAcceptPath bounces localOnly, signedOut,
      // and un-onboarded users away so they are never trapped (FS-05 / DE-06).
      expect(r(kEulaAcceptPath), AppRoutes.capture);
      expect(r(kEulaAcceptPath, eula: false), AppRoutes.capture);
      expect(r(kEulaAcceptPath, auth: AuthStatus.signedOut), AppRoutes.auth);
      expect(
        r('$kEulaAcceptPath?from=%2Fgroups', auth: AuthStatus.signedOut),
        '/auth?from=%2Fgroups',
      );
      expect(r(kEulaAcceptPath, onboarded: false), AppRoutes.onboarding);
    });

    test('deep links are normalised before any gate', () {
      expect(r('ourney://join/X', onboarded: false), '/join/X');
      expect(r('ourney://p/tok123', onboarded: false), '/p/tok123');
    });

    test('a universal link keeps only its in-app path in from= (A-B13)', () {
      const link = 'https://ourney.tech/f/tok123456';
      final gate = r(link, onboarded: false)!;
      expect(gate, '/onboarding?from=%2Ff%2Ftok123456');
      final toAuth = r(gate, auth: AuthStatus.signedOut)!;
      expect(toAuth, '/auth?from=%2Ff%2Ftok123456');
      expect(r(toAuth, auth: AuthStatus.signedIn), '/f/tok123456');
      expect(
        r(link, auth: AuthStatus.signedIn, eula: false),
        '$kEulaAcceptPath?from=%2Ff%2Ftok123456',
      );
      // Group universal link /j/<code> normalises to /join/<code> (FS-05).
      expect(
        r('https://ourney.tech/j/ABCD1234', auth: AuthStatus.signedIn),
        '/join/ABCD1234',
      );
      expect(
        r('https://ourney.tech/j/ABCD1234', onboarded: false),
        '/onboarding?from=%2Fjoin%2FABCD1234',
      );
      // Public journey universal link /p/<token> maps to /p/<token> (DE-01).
      expect(
        r('https://ourney.tech/p/pubtok123', auth: AuthStatus.signedIn),
        '/p/pubtok123',
      );
      expect(
        r('https://ourney.tech/p/pubtok123', onboarded: false),
        '/onboarding?from=%2Fp%2Fpubtok123',
      );
    });
  });

  group('safeFrom', () {
    Uri u(String from) =>
        Uri(path: '/auth', queryParameters: {AppRoutes.fromParam: from});

    test('accepts in-app paths only', () {
      expect(safeFrom(u('/journey/1?tab=2')), '/journey/1?tab=2');
      expect(safeFrom(u('//evil.com/x')), isNull);
      expect(safeFrom(u('https://evil.com')), isNull);
      expect(safeFrom(u('journey/1')), isNull);
      expect(safeFrom(u('/auth')), isNull);
      expect(safeFrom(u('/onboarding')), isNull);
      expect(safeFrom(u(kEulaAcceptPath)), isNull);
      expect(safeFrom(Uri.parse('/auth')), isNull);
    });
  });

  test('pathHasPrefix matches whole segments', () {
    expect(pathHasPrefix('/journey/1', '/journey'), isTrue);
    expect(pathHasPrefix('/journey', '/journey'), isTrue);
    expect(pathHasPrefix('/journeys', '/journey'), isFalse);
  });
}
