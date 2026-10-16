import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney/app/config.dart';
import 'package:ourney/app/localization.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/app/router.dart';
import 'package:ourney/app/theme/app_theme.dart';
import 'package:ourney/features/safety/data/safety_providers.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/test_helpers.dart';

class ReportCall {
  ReportCall(this.checkInId, this.userId, this.reason, this.note);
  final String? checkInId;
  final String? userId;
  final ReportReason reason;
  final String? note;
}

class FakeSafetyRepository implements SafetyRepository {
  FakeSafetyRepository({Set<String>? blocked}) : _blocked = {...?blocked};

  final Set<String> _blocked;
  final reports = <ReportCall>[];
  Object? reportError;
  Object? blockError;
  final _changes = StreamController<Set<String>>.broadcast();

  Set<String> get blocked => {..._blocked};

  @override
  Future<void> report({
    String? checkInId,
    String? userId,
    required ReportReason reason,
    String? note,
  }) async {
    if (reportError != null) throw reportError!;
    reports.add(ReportCall(checkInId, userId, reason, note));
  }

  @override
  Future<void> block(String userId) async {
    if (blockError != null) throw blockError!;
    _blocked.add(userId);
    _changes.add(blocked);
  }

  @override
  Future<void> unblock(String userId) async {
    _blocked.remove(userId);
    _changes.add(blocked);
  }

  @override
  Stream<Set<String>> watchBlockedIds() async* {
    yield blocked;
    yield* _changes.stream;
  }
}

/// Plain MaterialApp + ProviderScope (no router) for sheet/dialog tests.
Future<ProviderContainer> pumpSafetyHarness(
  WidgetTester tester, {
  required Widget Function(BuildContext context) builder,
  FakeSafetyRepository? repo,
  AppConfig config = testBackendConfig,
  Map<String, Object> prefs = const {},
  Locale locale = const Locale('vi'),
  List<Override> overrides = const [],
}) async {
  final p = await testPrefs(prefs);
  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(config),
      sharedPreferencesProvider.overrideWithValue(p),
      safetyRepositoryProvider.overrideWithValue(
        repo ?? FakeSafetyRepository(),
      ),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildAppTheme(Brightness.light),
        locale: locale,
        localizationsDelegates: ourneyLocalizationsDelegates,
        supportedLocales: ourneySupportedLocales,
        home: Scaffold(
          body: Center(child: Builder(builder: builder)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

/// The real app (router) signed in against a fake backend.
Future<ProviderContainer> pumpSignedInApp(
  WidgetTester tester, {
  FakeSafetyRepository? repo,
  List<Override> overrides = const [],
  Locale locale = const Locale('vi'),
}) => pumpOurneyApp(
  tester,
  config: testBackendConfig,
  auth: FakeAuthRepository(userId: 'u1'),
  locale: locale,
  overrides: [
    safetyRepositoryProvider.overrideWithValue(repo ?? FakeSafetyRepository()),
    safetyUrlLauncherProvider.overrideWithValue((_) async => true),
    ...overrides,
  ],
);

GoRouter routerOf(ProviderContainer c) => c.read(routerProvider);

String locationOf(ProviderContainer c) =>
    routerOf(c).routerDelegate.currentConfiguration.uri.toString();

Future<void> goTo(WidgetTester tester, ProviderContainer c, String path) async {
  routerOf(c).go(path);
  await tester.pumpAndSettle();
}

Finder byKey(String key) => find.byKey(ValueKey(key));
