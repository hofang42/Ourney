import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/data/data_layer.dart';
import 'package:ourney/data/data_providers.dart';
import 'package:ourney/data/db/app_database.dart';
import 'package:ourney/data/local_store.dart' show membershipKey;
import 'package:ourney/data/media_store.dart' show MediaWipe;
import 'package:ourney/data/remote/remote_api.dart';
import 'package:ourney/data/sync/outbox.dart';
import 'package:ourney/features/profile/settings_providers.dart';
import 'package:ourney/features/profile/share_privacy_sync.dart';
import 'package:ourney_core/ourney_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/test_helpers.dart';
import '../../data/data_test_helpers.dart';

class _MembershipRemote extends FakeRemoteApi {
  final writes = <String>[];

  @override
  Future<List<RemoteRow>> update(
    String table,
    RemoteRow values, {
    required Map<String, Object> match,
  }) async {
    await super.update(table, values, match: match);
    final updated = <RemoteRow>[];
    for (final row in tables[table] ?? const <RemoteRow>[]) {
      if (match.entries.every((entry) => row[entry.key] == entry.value)) {
        row.addAll(values);
        writes.add(row['journey_id'] as String);
        updated.add({...row});
      }
    }
    return updated;
  }
}

void main() {
  test(
    'offline cold launches repair each weight membership only once',
    () async {
      const archived = 'archived';
      const stranded = 'stranded';
      const hidden = 'hidden';
      const pending = 'pending';
      const study = 'study';
      const localFlags = {
        archived: false,
        stranded: true,
        hidden: true,
        pending: false,
        study: false,
      };
      final remote = _MembershipRemote()
        ..failure = const OurneyException(OurneyErrorCode.offline);
      final me = remote.currentUserId!;
      remote.tables['memberships'] = [
        for (final id in localFlags.keys)
          membershipRow(id, me)..['hide_metric'] = id == hidden,
      ];
      final dbFile = File('${tempDir().path}/ourney.sqlite');
      final media = tempDir();
      final clock = TestClock(DateTime.utc(2026, 10, 16, 2));
      await testPrefs({
        SharePrivacyPrefs.hideWeight: true,
        SharePrivacyPrefs.blurPhotos: true,
        // A previous process can commit an update before clearing this retry.
        SharePrivacyPrefs.pendingHeal:
            '{"user":"$me","items":{"$pending":{"h":true,"b":true}}}',
      });

      Future<void> launch(
        Future<void> Function(DataLayer, ProviderContainer) run,
      ) async {
        final db = AppDatabase(NativeDatabase(dbFile));
        final env = DataEnvironment(db: db, mediaRoot: media, remote: remote);
        final layer = DataLayer.supabase(
          db: db,
          mediaRoot: media,
          remote: remote,
          clock: testJourneyClock(clock),
          listenLifecycle: false,
          autoSync: false,
        );
        final container = ProviderContainer(
          overrides: [
            ...dataOverrides(env),
            dataLayerProvider.overrideWithValue(layer),
            appConfigProvider.overrideWithValue(testBackendConfig),
            sharedPreferencesProvider.overrideWithValue(
              await SharedPreferencesWithCache.create(
                cacheOptions: const SharedPreferencesWithCacheOptions(),
              ),
            ),
          ],
        );
        try {
          await run(layer, container);
        } finally {
          container.dispose();
          await layer.dispose();
          await MediaWipe.settled();
          await db.close();
        }
      }

      final queueIds = <String, int>{};
      await launch((layer, container) async {
        await layer.ctx.claimUserId();
        for (final entry in localFlags.entries) {
          final id = entry.key;
          final journey = journeyRow(
            id,
            ownerId: me,
            status: id == archived ? 'archived' : 'active',
          );
          if (id == study) {
            journey['template_id'] = 'custom';
            journey['metric_name'] = 'Study time';
            journey['metric_unit'] = 'min';
          }
          (remote.tables['journeys'] ??= []).add(journey);
          await layer.ctx.store.applyJourney(journey);
          await layer.ctx.store.applyMembership(
            membershipRow(id, me)..['hide_metric'] = entry.value,
            me: me,
          );
        }
        final outbox = layer.ctx.outbox!;
        final existingId = await outbox.enqueue(
          OutboxKind.updateMembership,
          membershipKey(pending),
          {
            'journey_id': pending,
            'user_id': me,
            'hide_metric': true,
            'blur_media': true,
          },
        );
        await healSharePrivacy(container);
        await outbox.flush();
        expect(pendingSharePrivacy(container), isEmpty);
        final rows = await outbox.pendingRows();
        queueIds.addEntries(rows.map((row) => MapEntry(row.entityKey, row.id)));
        expect(rows, hasLength(4));
        expect(
          queueIds.keys.toSet(),
          {archived, stranded, hidden, pending}.map(membershipKey).toSet(),
        );
        expect(queueIds[membershipKey(pending)], existingId);
        for (final id in [archived, stranded, hidden, pending]) {
          expect(
            (await layer.journeys.watchMyMembership(id).first)?.hideMetric,
            isTrue,
          );
        }
        expect(
          (await layer.journeys.watchMyMembership(study).first)?.hideMetric,
          isFalse,
        );
      });

      for (var restart = 0; restart < 2; restart++) {
        await launch((layer, container) async {
          await healSharePrivacy(container);
          final rows = await layer.ctx.outbox!.pendingRows();
          expect(rows, hasLength(queueIds.length));
          expect({for (final row in rows) row.entityKey: row.id}, queueIds);
        });
      }
      expect(remote.writes, isEmpty);

      remote.failure = null;
      await launch((layer, container) async {
        expect(await layer.syncNow(), isA<SyncOk>());
        expect(await layer.ctx.outbox!.pendingRows(), isEmpty);
        await healSharePrivacy(container);
        expect(await layer.ctx.outbox!.pendingRows(), isEmpty);
      });
      expect(remote.writes, unorderedEquals([archived, stranded, pending]));
      expect(
        remote.tables['memberships']!
            .singleWhere((row) => row['journey_id'] == pending)['blur_media'],
        isTrue,
      );
    },
  );
}
