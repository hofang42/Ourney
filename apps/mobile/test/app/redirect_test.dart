import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/app_routes.dart';
import 'package:ourney/app/redirect.dart';

String? r(
  String location, {
  bool onboarded = true,
  AuthStatus? auth,
  ProfileGateStatus profileGate = ProfileGateStatus.ready,
}) => resolveRedirect(
  uri: Uri.parse(location),
  onboarded: onboarded,
  auth: auth ?? AuthStatus.localOnly,
  profileGate: profileGate,
);

void main() {
  group('normalizeDeepLink', () {
    test('maps custom scheme and https://ourney.tech links to in-app paths', () {
      expect(
        normalizeDeepLink(Uri.parse('ourney://join/ABC123')),
        '/join/ABC123',
      );
      expect(
        normalizeDeepLink(Uri.parse('ourney://j/ABC123')),
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
        normalizeDeepLink(Uri.parse('ourney://f/tok123')),
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
        normalizeDeepLink(Uri.parse('HTTPS://OURNEY.TECH/J/ABCD1234')),
        '/join/ABCD1234',
      );
      expect(
        normalizeDeepLink(Uri.parse('HTTPS://OURNEY.TECH/JOIN/ABCD1234')),
        '/join/ABCD1234',
      );
      expect(
        normalizeDeepLink(Uri.parse('HTTPS://OURNEY.TECH/F/tok123')),
        '/f/tok123',
      );
      expect(
        normalizeDeepLink(Uri.parse('HTTPS://OURNEY.TECH/P/pubtok123')),
        '/p/pubtok123',
      );
      expect(
        normalizeDeepLink(Uri.parse('https://ourney.tech/p/pubtok123')),
        '/p/pubtok123',
      );
      const slug = '7-ngay-da-lat-abcdefghijklmnop';
      expect(
        normalizeDeepLink(Uri.parse('https://ourney.tech/p/$slug')),
        '/p/$slug',
      );
      expect(normalizeDeepLink(Uri.parse('ourney://')), AppRoutes.capture);
      expect(normalizeDeepLink(Uri.parse('ourney://capture')), AppRoutes.capture);
      expect(
        normalizeDeepLink(Uri.parse('ourney://capture?journeyId=j-42')),
        '/capture?journeyId=j-42',
      );
      expect(
        normalizeDeepLink(Uri.parse('ourney://capture/j-42')),
        '/capture?journeyId=j-42',
      );
      expect(
        normalizeDeepLink(Uri.parse('ourney://journeys')),
        AppRoutes.journeys,
      );
      expect(
        normalizeDeepLink(Uri.parse('ourney://journeys/new')),
        AppRoutes.journeyNew,
      );
      expect(
        normalizeDeepLink(Uri.parse('ourney://groups')),
        AppRoutes.groups,
      );
      expect(
        normalizeDeepLink(Uri.parse('ourney://groups/g-99')),
        '/groups/g-99',
      );
      expect(normalizeDeepLink(Uri.parse('/capture')), isNull);
      expect(normalizeDeepLink(Uri.parse('https://x.dev/join/A')), isNull);
    });

    test(
      'AndroidManifest.xml registers every custom-scheme host accepted by normalizeDeepLink (High-R2-1)',
      () {
        final manifest = File(
          'android/app/src/main/AndroidManifest.xml',
        ).readAsStringSync();
        final declaredHosts = RegExp(
          r'<data\s+android:scheme="ourney"\s+android:host="([^"]+)"\s*/>',
        ).allMatches(manifest).map((m) => m.group(1)!).toSet();
        const baseHosts = {'join', 'j', 'journey', 'friend', 'f', 'p'};
        const widgetHosts = {'capture', 'journeys', 'groups'};
        for (final host in baseHosts) {
          expect(
            normalizeDeepLink(Uri.parse('ourney://$host/test123')),
            isNotNull,
            reason: 'normalizeDeepLink must accept ourney://$host/<id>',
          );
        }
        expect(
          normalizeDeepLink(Uri.parse('ourney://capture/test123')),
          '/capture?journeyId=test123',
        );
        expect(
          normalizeDeepLink(Uri.parse('ourney://journeys/new')),
          AppRoutes.journeyNew,
        );
        expect(
          normalizeDeepLink(Uri.parse('ourney://groups/test123')),
          '/groups/test123',
        );
        expect(declaredHosts, containsAll(baseHosts));
        expect(
          declaredHosts.difference({...baseHosts, ...widgetHosts}),
          isEmpty,
        );
      },
    );

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
      // UX-30: truncated or extra-segment invite links redirect to the invite
      // screen's invalid-link route instead of silently landing on /capture.
      expect(
        r('https://ourney.tech/j/', auth: AuthStatus.signedIn),
        '/join/$kMalformedInviteSegment',
      );
      expect(
        r('https://ourney.tech/j/ABCD1234/extra', auth: AuthStatus.signedIn),
        '/join/$kMalformedInviteSegment',
      );
      expect(
        r('ourney://j/', auth: AuthStatus.signedIn),
        '/join/$kMalformedInviteSegment',
      );
      expect(
        r('https://ourney.tech/f/', auth: AuthStatus.signedIn),
        '/f/$kMalformedInviteSegment',
      );
      expect(
        r('ourney://f/', auth: AuthStatus.signedIn),
        '/f/$kMalformedInviteSegment',
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
    });

    test('DE-07: signing out on /profile/setup returns to /auth keeping ?from=',
        () {
      const out = AuthStatus.signedOut;
      expect(r(kProfileSetupPath, auth: out), AppRoutes.auth);
      expect(
        r('$kProfileSetupPath?from=%2Fjoin%2FX', auth: out),
        '/auth?from=%2Fjoin%2FX',
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

    test(
      'DE-04 / H1 / P2: signed in holds on /auth and /capture while '
      'profileGate is unknown, redirects cold-start deep links to /auth?from=, '
      'and redirects to /profile/setup when profileGate is needsSetup',
      () {
        const inn = AuthStatus.signedIn;
        expect(
          r('/auth?from=%2Ff%2Ftok123', auth: inn, profileGate: ProfileGateStatus.unknown),
          isNull,
        );
        expect(
          r('/auth', auth: inn, profileGate: ProfileGateStatus.unknown),
          isNull,
        );
        expect(
          r('/capture', auth: inn, profileGate: ProfileGateStatus.unknown),
          isNull,
        );
        // P2: cold-start deep links while profileGate is unknown redirect to
        // /auth?from=... instead of mounting /f or /join targets prematurely.
        expect(
          r('/f/tok123', auth: inn, profileGate: ProfileGateStatus.unknown),
          '/auth?from=%2Ff%2Ftok123',
        );
        expect(
          r('/join/ABCD1234', auth: inn, profileGate: ProfileGateStatus.unknown),
          '/auth?from=%2Fjoin%2FABCD1234',
        );
        expect(
          r(
            '/auth?from=%2Ff%2Ftok123',
            auth: inn,
            profileGate: ProfileGateStatus.needsSetup,
          ),
          '$kProfileSetupPath?from=%2Ff%2Ftok123',
        );
        expect(
          r(
            '/capture',
            auth: inn,
            profileGate: ProfileGateStatus.needsSetup,
          ),
          kProfileSetupPath,
        );
        expect(
          r(
            '/join/ABCD1234',
            auth: inn,
            profileGate: ProfileGateStatus.needsSetup,
          ),
          '$kProfileSetupPath?from=%2Fjoin%2FABCD1234',
        );
        expect(
          r(
            kProfileSetupPath,
            auth: inn,
            profileGate: ProfileGateStatus.needsSetup,
          ),
          isNull,
        );
        expect(
          r(
            '/safety/eula',
            auth: inn,
            profileGate: ProfileGateStatus.needsSetup,
          ),
          isNull,
        );
      },
    );
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
      expect(safeFrom(u(kProfileSetupPath)), isNull);
      expect(safeFrom(Uri.parse('/auth')), isNull);
    });
  });

  test('pathHasPrefix matches whole segments', () {
    expect(pathHasPrefix('/journey/1', '/journey'), isTrue);
    expect(pathHasPrefix('/journey', '/journey'), isTrue);
    expect(pathHasPrefix('/journeys', '/journey'), isFalse);
  });
}
