import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/app_routes.dart';
import 'package:ourney/app/config.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/features/safety/data/safety_providers.dart';
import 'package:ourney/features/safety/safety_paths.dart';
import 'package:ourney/ui/components/ourney_icons.dart';

import '../../app/test_helpers.dart';
import 'safety_fakes.dart';

class _SlowTermsAuthRepository extends FakeAuthRepository {
  _SlowTermsAuthRepository({super.userId});

  final Completer<void> blocker = Completer<void>();

  @override
  Future<void> recordTermsAccepted(int version) async {
    recordedTerms.add(version);
    await blocker.future;
    termsVersion = version;
  }
}

void main() {
  group('hub (FR-F3)', () {
    testWidgets('reachable before onboarding; links to the three pages', (
      tester,
    ) async {
      final c = await pumpOurneyApp(tester, onboarded: false);
      await goTo(tester, c, AppRoutes.safety);
      expect(locationOf(c), AppRoutes.safety);
      expect(byKey('safety-hub'), findsOneWidget);
      // Local-only: no one to block.
      expect(byKey('safety-hub-blocked'), findsNothing);

      await tester.tap(byKey('safety-hub-eula'));
      await tester.pumpAndSettle();
      expect(byKey('safety-eula'), findsOneWidget);
      expect(find.text('2. Không dung thứ nội dung phản cảm'), findsOneWidget);
      await tester.tap(
        find.byWidgetPredicate((w) => w is OurneyIcon && w.name == 'back'),
      );
      await tester.pumpAndSettle();

      await tester.tap(byKey('safety-hub-privacy'));
      await tester.pumpAndSettle();
      expect(byKey('safety-privacy'), findsOneWidget);
      expect(find.textContaining('Không bán dữ liệu'), findsOneWidget);
      await tester.tap(
        find.byWidgetPredicate((w) => w is OurneyIcon && w.name == 'back'),
      );
      await tester.pumpAndSettle();

      await tester.tap(byKey('safety-hub-contact'));
      await tester.pumpAndSettle();
      expect(byKey('safety-contact'), findsOneWidget);
      expect(find.text(AppConfig.defaultSupportEmail), findsOneWidget);
    });

    testWidgets('signed in: blocked people entry', (tester) async {
      final c = await pumpSignedInApp(tester);
      await goTo(tester, c, AppRoutes.safety);
      await tester.tap(byKey('safety-hub-blocked'));
      await tester.pumpAndSettle();
      expect(byKey('safety-blocked'), findsOneWidget);
    });

    testWidgets('legal pages in English, deep-linked, at 2x text', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final c = await pumpOurneyApp(tester, locale: const Locale('en'));
      await goTo(tester, c, SafetyPaths.eula);
      expect(
        find.text('2. Zero tolerance for objectionable content'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Profile > Settings > Delete account'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await goTo(tester, c, SafetyPaths.privacy);
      expect(find.text('What we store'), findsOneWidget);
      expect(
        find.textContaining('Your email or phone number'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Profile > Settings > Delete account'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Profile > Settings > Contact'),
        findsOneWidget,
      );
      // Back from a deep link goes to the hub.
      await tester.tap(
        find.byWidgetPredicate((w) => w is OurneyIcon && w.name == 'back'),
      );
      await tester.pumpAndSettle();
      expect(locationOf(c), AppRoutes.safety);
      expect(tester.takeException(), isNull);
    });
  });

  group('contact', () {
    testWidgets('send opens a mailto link; failure explains', (tester) async {
      final launched = <Uri>[];
      var ok = true;
      final c = await pumpOurneyApp(
        tester,
        overrides: [
          safetyUrlLauncherProvider.overrideWithValue((uri) async {
            launched.add(uri);
            return ok;
          }),
        ],
      );
      await goTo(tester, c, SafetyPaths.contact);
      await tester.tap(byKey('safety-contact-send'));
      await tester.pumpAndSettle();
      expect(launched.single.scheme, 'mailto');
      expect(launched.single.path, AppConfig.defaultSupportEmail);

      ok = false;
      await tester.tap(byKey('safety-contact-send'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Không mở được ứng dụng email'),
        findsOneWidget,
      );
    });

    testWidgets('uses the configured SUPPORT_EMAIL (H4)', (tester) async {
      const custom = 'help@example.com';
      final launched = <Uri>[];
      final c = await pumpOurneyApp(
        tester,
        config: const AppConfig(
          supabaseUrl: '',
          supabaseAnonKey: '',
          supportEmail: custom,
        ),
        overrides: [
          safetyUrlLauncherProvider.overrideWithValue((uri) async {
            launched.add(uri);
            return true;
          }),
        ],
      );
      await goTo(tester, c, SafetyPaths.contact);
      expect(find.text(custom), findsOneWidget);
      expect(find.text(AppConfig.defaultSupportEmail), findsNothing);
      await tester.tap(byKey('safety-contact-send'));
      await tester.pumpAndSettle();
      expect(launched.single.path, custom);
    });

    testWidgets('copy puts the address on the clipboard', (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied =
                (call.arguments as Map<Object?, Object?>)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final c = await pumpOurneyApp(tester);
      await goTo(tester, c, SafetyPaths.contact);
      await tester.tap(byKey('safety-contact-copy'));
      await tester.pumpAndSettle();
      expect(copied, AppConfig.defaultSupportEmail);
      expect(find.text('Đã sao chép địa chỉ email.'), findsOneWidget);
    });
  });

  group('EULA gate', () {
    testWidgets('one tap agrees: stores the flag, records on the account', (
      tester,
    ) async {
      final auth = FakeAuthRepository(userId: 'u1');
      final c = await pumpSignedInApp(tester, eulaAccepted: false, auth: auth);
      expect(c.read(eulaAcceptedProvider), isFalse);
      await goTo(
        tester,
        c,
        Uri(
          path: SafetyPaths.eulaAccept,
          queryParameters: {AppRoutes.fromParam: SafetyPaths.contact},
        ).toString(),
      );
      expect(byKey('safety-eula-accept'), findsOneWidget);
      expect(byKey('safety-eula-checkbox'), findsNothing);

      await tester.tap(byKey('safety-eula-accept-button'));
      await tester.pumpAndSettle();

      expect(c.read(eulaAcceptedProvider), isTrue);
      expect(
        c
            .read(sharedPreferencesProvider)
            .getInt(SafetyPrefs.termsVersionFor('u1')),
        kTermsVersion,
      );
      expect(auth.recordedTerms, [kTermsVersion]);
      expect(locationOf(c), SafetyPaths.contact);
    });

    testWidgets(
      'accept navigates immediately without blocking on a slow network call '
      '(M3)',
      (tester) async {
        final auth = _SlowTermsAuthRepository(userId: 'u1');
        final c = await pumpSignedInApp(
          tester,
          eulaAccepted: false,
          auth: auth,
        );
        await goTo(
          tester,
          c,
          Uri(
            path: SafetyPaths.eulaAccept,
            queryParameters: {AppRoutes.fromParam: SafetyPaths.contact},
          ).toString(),
        );
        await tester.tap(byKey('safety-eula-accept-button'));
        await tester.pumpAndSettle();

        expect(c.read(eulaAcceptedProvider), isTrue);
        expect(
          c
              .read(sharedPreferencesProvider)
              .getInt(SafetyPrefs.termsVersionFor('u1')),
          kTermsVersion,
        );
        expect(auth.recordedTerms, [kTermsVersion]);
        expect(locationOf(c), SafetyPaths.contact);
        auth.blocker.complete();
      },
    );

    testWidgets('gate offers sign out', (tester) async {
      final c = await pumpSignedInApp(tester, eulaAccepted: false);
      await goTo(tester, c, SafetyPaths.eulaAccept);
      await tester.ensureVisible(byKey('safety-eula-sign-out'));
      await tester.tap(byKey('safety-eula-sign-out'));
      await tester.pumpAndSettle();
      expect(byKey('profile-signout-dialog'), findsOneWidget);
    });

    testWidgets('an account that already accepted is never asked', (
      tester,
    ) async {
      final c = await pumpSignedInApp(
        tester,
        eulaAccepted: false,
        auth: FakeAuthRepository(userId: 'u1', termsVersion: kTermsVersion),
      );
      expect(c.read(eulaAcceptedProvider), isTrue);
      expect(
        c
            .read(sharedPreferencesProvider)
            .getInt(SafetyPrefs.termsVersionFor('u1')),
        kTermsVersion,
      );
      await goTo(tester, c, AppRoutes.capture);
      expect(locationOf(c), isNot(startsWith(SafetyPaths.eulaAccept)));
    });

    testWidgets(
      'an older accepted version or legacy boolean is asked again and never '
      'forges server consent (H1)',
      (tester) async {
        final auth = FakeAuthRepository(userId: 'u1', termsVersion: 1);
        final prefs = await testPrefs({
          OnboardingComplete.prefsKey: true,
          SafetyPrefs.eulaAccepted: true,
          SafetyPrefs.termsVersionFor('u1'): 1,
        });
        final c = ProviderContainer(
          overrides: [
            appConfigProvider.overrideWithValue(testBackendConfig),
            sharedPreferencesProvider.overrideWithValue(prefs),
            supabaseClientProvider.overrideWithValue(null),
            authRepositoryProvider.overrideWithValue(auth),
            termsVersionProvider.overrideWithValue(2),
          ],
        );
        addTearDown(c.dispose);

        expect(c.read(eulaAcceptedProvider), isFalse);
        expect(auth.recordedTerms, isEmpty);
      },
    );

    testWidgets('unsafe from target falls back to the camera', (tester) async {
      final c = await pumpOurneyApp(tester);
      await goTo(
        tester,
        c,
        '${SafetyPaths.eulaAccept}?from=${Uri.encodeComponent('https://evil.example')}',
      );
      await tester.tap(byKey('safety-eula-accept-button'));
      await tester.pumpAndSettle();
      expect(locationOf(c), startsWith(AppRoutes.capture));
    });

    test('provider reads and resets the stored flag', () async {
      final prefs = await testPrefs({SafetyPrefs.eulaAccepted: true});
      final c = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(c.dispose);
      expect(c.read(eulaAcceptedProvider), isTrue);
      await c.read(eulaAcceptedProvider.notifier).reset();
      expect(c.read(eulaAcceptedProvider), isFalse);
      expect(prefs.getBool(SafetyPrefs.eulaAccepted), isNull);
    });
  });
}
