import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/config.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/data/data_providers.dart';
import 'package:ourney_core/ourney_core.dart';

import '../app/test_helpers.dart';
import 'data_test_helpers.dart';

void main() {
  Future<ProviderContainer> make({
    Map<String, Object> prefs = const {},
    FakeRemoteApi? remote,
  }) async {
    final c = ProviderContainer.test(
      overrides: [
        appConfigProvider.overrideWithValue(
          remote == null ? const AppConfig.localOnly() : testBackendConfig,
        ),
        sharedPreferencesProvider.overrideWithValue(await testPrefs(prefs)),
        supabaseClientProvider.overrideWithValue(null),
        ...dataOverrides(
          DataEnvironment(
            db: memoryDb(),
            mediaRoot: tempDir(),
            remote: remote,
            listenLifecycle: false,
            autoSync: false,
          ),
        ),
      ],
    );
    return c;
  }

  test('local-only wiring: every repository resolves and works', () async {
    final c = await make();
    expect(c.read(authRepositoryProvider).isLocalOnly, isTrue);
    c
      ..read(profileRepositoryProvider)
      ..read(groupRepositoryProvider)
      ..read(safetyRepositoryProvider)
      ..read(mediaStoreProvider)
      ..read(checkInRepositoryProvider);
    final repo = c.read(journeyRepositoryProvider);
    await repo.create(
      soloDraft(start: const LocalDate(2026, 1, 1), durationDays: null),
    );
    expect(await repo.watchActive().first, hasLength(1));
    // The guest id was persisted for the next start.
    expect(
      c.read(sharedPreferencesProvider).getString(guestUserIdKey),
      isNotNull,
    );
  });

  test('guest id is stable across starts', () async {
    final c = await make(
      prefs: {guestUserIdKey: 'aaaaaaaa-0000-4000-8000-00000000000f'},
    );
    final j = await c
        .read(journeyRepositoryProvider)
        .create(
          soloDraft(start: const LocalDate(2026, 1, 1), durationDays: null),
        );
    expect(j.ownerId, 'aaaaaaaa-0000-4000-8000-00000000000f');
  });

  test('Supabase wiring follows the remote', () async {
    final c = await make(remote: FakeRemoteApi(userId: 'u1'));
    final auth = c.read(authRepositoryProvider);
    expect(auth.isLocalOnly, isFalse);
    expect(auth.currentUserId, 'u1');
  });

  test('social providers: wired with a server, unwired local-only', () async {
    final server = await make(remote: FakeRemoteApi(userId: 'u1'));
    expect(server.read(friendRepositoryProvider), isA<FriendRepository>());
    expect(server.read(sharingRepositoryProvider), isA<SharingRepository>());
    expect(
      server.read(shareConsentRepositoryProvider),
      isA<ShareConsentRepository>(),
    );
    expect(server.read(chatRepositoryProvider), isA<ChatRepository>());
    expect(server.read(insightsRepositoryProvider), isA<InsightsRepository>());

    final local = await make();
    for (final Object Function() read in [
      () => local.read(friendRepositoryProvider),
      () => local.read(sharingRepositoryProvider),
      () => local.read(shareConsentRepositoryProvider),
      () => local.read(chatRepositoryProvider),
      () => local.read(insightsRepositoryProvider),
    ]) {
      expect(
        read,
        throwsA(
          anyOf(
            isA<UnimplementedError>(),
            predicate((e) => '$e'.contains('UnimplementedError')),
          ),
        ),
      );
    }
  });
}
