import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/config.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/app/redirect.dart';
import 'package:ourney/app/theme/motion.dart';
import 'package:ourney/features/safety/data/safety_providers.dart';

import 'test_helpers.dart';

Future<ProviderContainer> container({
  AppConfig config = const AppConfig.localOnly(),
  Map<String, Object> prefs = const {},
  FakeAuthRepository? auth,
}) async {
  final c = ProviderContainer.test(
    overrides: [
      appConfigProvider.overrideWithValue(config),
      sharedPreferencesProvider.overrideWithValue(await testPrefs(prefs)),
      if (auth != null) authRepositoryProvider.overrideWithValue(auth),
    ],
  );
  return c;
}

void main() {
  group('AppConfig', () {
    test('local-only when dart-defines are absent (FR-A5)', () {
      expect(AppConfig.fromEnvironment().localOnly, isTrue);
      expect(const AppConfig.localOnly().hasBackend, isFalse);
      expect(testBackendConfig.localOnly, isFalse);
      expect(
        const AppConfig(
          supabaseUrl: 'https://x.supabase.co',
          supabaseAnonKey: '',
        ).localOnly,
        isTrue,
      );
    });
  });

  group('AppConfig support email (H4)', () {
    test('falls back to the placeholder when SUPPORT_EMAIL is not defined', () {
      // The test run passes no --dart-define, so this is the default path.
      expect(AppConfig.fromEnvironment().supportEmail, 'support@ourney.app');
      expect(const AppConfig.localOnly().supportEmail, 'support@ourney.app');
      expect(testBackendConfig.supportEmail, AppConfig.defaultSupportEmail);
    });

    test('resolveSupportEmail trims and falls back when blank', () {
      const fallback = AppConfig.defaultSupportEmail;
      expect(
        AppConfig.resolveSupportEmail(' me@example.com '),
        'me@example.com',
      );
      expect(AppConfig.resolveSupportEmail(''), fallback);
      expect(AppConfig.resolveSupportEmail('  '), fallback);
    });

    test('is part of equality', () {
      const a = AppConfig(supabaseUrl: 'u', supabaseAnonKey: 'k');
      const b = AppConfig(
        supabaseUrl: 'u',
        supabaseAnonKey: 'k',
        supportEmail: 'me@example.com',
      );
      expect(a == b, isFalse);
      expect(a.hashCode == b.hashCode, isFalse);
    });

    test('supportEmailProvider follows appConfigProvider', () async {
      final c = await container(
        config: const AppConfig(
          supabaseUrl: '',
          supabaseAnonKey: '',
          supportEmail: 'help@example.com',
        ),
      );
      expect(c.read(supportEmailProvider), 'help@example.com');
      final d = await container();
      expect(d.read(supportEmailProvider), 'support@ourney.app');
    });
  });

  group('placeholder repositories', () {
    test('throw UnimplementedError until B1 wires them', () async {
      final c = await container();
      for (final p in <ProviderListenable<Object?>>[
        authRepositoryProvider,
        profileRepositoryProvider,
        journeyRepositoryProvider,
        checkInRepositoryProvider,
        groupRepositoryProvider,
        safetyRepositoryProvider,
        mediaStoreProvider,
      ]) {
        expect(
          () => c.read(p),
          throwsA(
            isA<ProviderException>().having(
              (e) => e.exception,
              'exception',
              isA<UnimplementedError>(),
            ),
          ),
        );
      }
    });

    test('supabaseClient is null in local-only mode', () async {
      final c = await container();
      expect(c.read(supabaseClientProvider), isNull);
    });
  });

  group('auth status', () {
    test('local-only', () async {
      final c = await container(auth: FakeAuthRepository(userId: 'u1'));
      expect(c.read(authStatusProvider), AuthStatus.localOnly);
      expect(c.read(currentUserIdProvider), isNull);
    });

    test('follows the auth repository when a backend is configured', () async {
      final auth = FakeAuthRepository(userId: 'u1');
      final c = await container(config: testBackendConfig, auth: auth);
      final sub = c.listen(authStatusProvider, (_, _) {});
      addTearDown(sub.close);
      expect(c.read(authStatusProvider), AuthStatus.signedIn);
      auth.emit(null);
      await Future<void>.delayed(Duration.zero);
      expect(c.read(authStatusProvider), AuthStatus.signedOut);
    });

    test('unwired repository with backend = signed out', () async {
      final c = await container(config: testBackendConfig);
      expect(c.read(authStatusProvider), AuthStatus.signedOut);
    });
  });

  group('settings', () {
    test('onboarding flag persists', () async {
      final c = await container();
      expect(c.read(onboardingCompleteProvider), isFalse);
      await c.read(onboardingCompleteProvider.notifier).complete();
      expect(c.read(onboardingCompleteProvider), isTrue);
      expect(
        c.read(sharedPreferencesProvider).getBool(OnboardingComplete.prefsKey),
        isTrue,
      );
      await c.read(onboardingCompleteProvider.notifier).reset();
      expect(c.read(onboardingCompleteProvider), isFalse);
    });

    test('haptics toggle mirrors into OurneyHaptics', () async {
      addTearDown(() => OurneyHaptics.enabled = true);
      final c = await container(prefs: {HapticsEnabled.prefsKey: false});
      expect(c.read(hapticsEnabledProvider), isFalse);
      expect(OurneyHaptics.enabled, isFalse);
      await c.read(hapticsEnabledProvider.notifier).set(enabled: true);
      expect(OurneyHaptics.enabled, isTrue);
    });
  });
}
