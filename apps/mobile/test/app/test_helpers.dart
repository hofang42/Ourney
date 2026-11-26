import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/app.dart';
import 'package:ourney/app/config.dart';
import 'package:ourney/app/localization.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/app/theme/app_theme.dart';
import 'package:ourney/features/safety/data/safety_providers.dart';
import 'package:ourney_core/ourney_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Widget harness with the app theme and every localization delegate.
Widget testApp(
  Widget child, {
  Brightness brightness = Brightness.light,
  Locale locale = const Locale('vi'),
}) {
  return MaterialApp(
    theme: buildAppTheme(brightness),
    locale: locale,
    localizationsDelegates: ourneyLocalizationsDelegates,
    supportedLocales: ourneySupportedLocales,
    home: Scaffold(body: Center(child: child)),
  );
}

/// In-memory shared preferences seeded with [values].
Future<SharedPreferencesWithCache> testPrefs([
  Map<String, Object> values = const {},
  SharedPreferencesAsyncPlatform Function(Map<String, Object>)? prefsPlatform,
]) {
  SharedPreferencesAsyncPlatform.instance =
      prefsPlatform?.call(values) ??
      InMemorySharedPreferencesAsync.withData(values);
  return SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(),
  );
}

const testBackendConfig = AppConfig(
  supabaseUrl: 'https://example.supabase.co',
  supabaseAnonKey: 'anon',
);

/// Pumps the real [OurneyApp] (router, shell, theme) with test overrides.
/// Defaults: local-only, onboarding done, EULA accepted, Vietnamese.
Future<ProviderContainer> pumpOurneyApp(
  WidgetTester tester, {
  AppConfig config = const AppConfig.localOnly(),
  bool onboarded = true,
  bool eulaAccepted = true,
  AuthRepository? auth,
  List<Override> overrides = const [],
  Locale locale = const Locale('vi'),
  Map<String, Object> initialPrefs = const {},
  SharedPreferencesAsyncPlatform Function(Map<String, Object>)? prefsPlatform,
}) async {
  tester.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  final prefs = await testPrefs({
    if (onboarded) OnboardingComplete.prefsKey: true,
    if (eulaAccepted) ...{
      SafetyPrefs.eulaAccepted: true,
      SafetyPrefs.termsVersionFor(auth?.currentUserId ?? 'u1'): kTermsVersion,
    },
    ...initialPrefs,
  }, prefsPlatform);
  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(config),
      sharedPreferencesProvider.overrideWithValue(prefs),
      // Supabase is never initialised in tests.
      supabaseClientProvider.overrideWithValue(null),
      if (auth != null) authRepositoryProvider.overrideWithValue(auth),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const OurneyApp()),
  );
  await tester.pumpAndSettle();
  return container;
}

/// Minimal controllable [AuthRepository] for router/provider tests.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.userId,
    this.termsVersion,
    this.identifier,
    this.hasPasswordValue = false,
  });

  String? userId;

  /// Terms version recorded on the (fake) account.
  int? termsVersion;
  String? identifier;
  bool hasPasswordValue;
  final recordedTerms = <int>[];
  final _changes = StreamController<String?>.broadcast();

  void emit(String? userId) {
    this.userId = userId;
    _changes.add(userId);
  }

  @override
  String? get currentUserId => userId;

  @override
  bool get isLocalOnly => false;

  @override
  String? get signInIdentifier =>
      userId == null ? null : (identifier ?? 'me@example.com');

  @override
  int? get acceptedTermsVersion => termsVersion;

  @override
  Future<void> recordTermsAccepted(int version) async {
    recordedTerms.add(version);
    termsVersion = version;
  }

  @override
  Stream<String?> watchUserId() => _changes.stream;

  @override
  Future<void> sendOtp(String email) async {}

  @override
  Future<void> verifyOtp(String email, String code) async => emit('u1');

  @override
  Future<void> sendPhoneOtp(String e164Phone) async {}

  @override
  Future<void> verifyPhoneOtp(String e164Phone, String code) async =>
      emit('u1');

  @override
  Future<bool> signUpWithPassword(String email, String password) async => false;

  @override
  Future<void> confirmSignUp(String email, String code) async => emit('u1');

  @override
  Future<void> signInWithPassword(String email, String password) async =>
      emit('u1');

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> resetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    hasPasswordValue = true;
    emit('u1');
  }

  @override
  Future<bool> hasPassword() async => userId != null && hasPasswordValue;

  @override
  Future<void> updatePassword(
    String newPassword, {
    required String code,
    bool signOutOthers = false,
  }) async {
    hasPasswordValue = true;
  }

  int cancelPasswordFlowCalls = 0;

  @override
  Future<void> cancelPasswordFlow() async {
    cancelPasswordFlowCalls++;
  }

  @override
  Future<DeleteCodeChallenge> requestDeleteCode({bool resend = false}) async =>
      DeleteCodeChallenge(hasPassword: hasPasswordValue);

  @override
  Future<void> signOut() async => emit(null);

  @override
  Future<void> deleteAccount({String? code, String? password}) async =>
      emit(null);
}
