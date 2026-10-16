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
]) {
  SharedPreferencesAsyncPlatform.instance =
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
}) async {
  tester.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  final prefs = await testPrefs({
    if (onboarded) OnboardingComplete.prefsKey: true,
    if (eulaAccepted) SafetyPrefs.eulaAccepted: true,
  });
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
  FakeAuthRepository({this.userId});

  String? userId;
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
  Stream<String?> watchUserId() => _changes.stream;

  @override
  Future<void> sendOtp(String email) async {}

  @override
  Future<void> verifyOtp(String email, String code) async => emit('u1');

  @override
  Future<void> signOut() async => emit(null);

  @override
  Future<void> deleteAccount() async => emit(null);
}
