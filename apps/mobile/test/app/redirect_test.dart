import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/app_routes.dart';
import 'package:ourney/app/redirect.dart';

String? r(String location, {bool onboarded = true, AuthStatus? auth}) =>
    resolveRedirect(
      uri: Uri.parse(location),
      onboarded: onboarded,
      auth: auth ?? AuthStatus.localOnly,
    );

void main() {
  group('normalizeDeepLink', () {
    test('maps the custom scheme to in-app paths', () {
      expect(
        normalizeDeepLink(Uri.parse('ourney://join/ABC123')),
        '/join/ABC123',
      );
      expect(
        normalizeDeepLink(Uri.parse('ourney://journey/j-42?x=1')),
        '/journey/j-42?x=1',
      );
      expect(normalizeDeepLink(Uri.parse('ourney://')), AppRoutes.capture);
      expect(normalizeDeepLink(Uri.parse('/capture')), isNull);
      expect(normalizeDeepLink(Uri.parse('https://x.dev/join/A')), isNull);
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

    test('deep links are normalised before any gate', () {
      expect(r('ourney://join/X', onboarded: false), '/join/X');
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
      expect(safeFrom(Uri.parse('/auth')), isNull);
    });
  });

  test('pathHasPrefix matches whole segments', () {
    expect(pathHasPrefix('/journey/1', '/journey'), isTrue);
    expect(pathHasPrefix('/journey', '/journey'), isTrue);
    expect(pathHasPrefix('/journeys', '/journey'), isFalse);
  });
}
