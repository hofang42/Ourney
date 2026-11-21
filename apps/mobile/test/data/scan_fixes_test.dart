import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/data/data_layer.dart';
import 'package:ourney/data/db/app_database.dart';
import 'package:ourney/data/local_store.dart';
import 'package:ourney/data/sync/outbox.dart';
import 'package:ourney_core/ourney_core.dart';

import 'data_test_helpers.dart';

const me = 'bbbbbbbb-0000-4000-8000-000000000001';
const jid = 'dddddddd-0000-4000-8000-000000000001';
const offline = OurneyException(OurneyErrorCode.offline);

void main() {
  late AppDatabase db;
  late Directory media;
  late Directory camera;
  late FakeRemoteApi remote;
  late DataLayer layer;

  setUp(() async {
    db = memoryDb();
    media = tempDir();
    camera = tempDir();
    remote = FakeRemoteApi(userId: me);
    layer = supabaseLayer(
      db: db,
      media: media,
      clock: TestClock(DateTime.utc(2026, 10, 16, 2)),
      remote: remote,
    );
    remote.tables['journeys'] = [journeyRow(jid, ownerId: me)];
    remote.tables['memberships'] = [membershipRow(jid, me)];
    await layer.syncNow();
  });

  Future<CheckIn> checkIn(String name) {
    final shot = fakeCapture(camera, name);
    return layer.checkIns.submit(
      CheckInDraft(
        journeyId: jid,
        capturedAt: DateTime.utc(2026, 10, 16, 1),
        photoFile: shot.photo,
        thumbFile: shot.thumb,
      ),
    );
  }

  Future<List<OutboxRow>> queue() => db.select(db.uploadQueue).get();

  test('L2 a check-in and its outbox item are saved together', () async {
    remote.failure = offline;
    final c = await checkIn('a');
    expect([for (final q in await queue()) q.entityKey], [checkInKey(c.id)]);
  });

  test('L2 a failed save leaves no row and no media behind', () async {
    int files() => media.existsSync()
        ? media.listSync(recursive: true).whereType<File>().length
        : 0;
    final before = files();
    final shot = fakeCapture(camera, 'x');
    File(shot.thumb).deleteSync();
    await expectLater(
      layer.checkIns.submit(
        CheckInDraft(
          journeyId: jid,
          capturedAt: DateTime.utc(2026, 10, 16, 1),
          photoFile: shot.photo,
          thumbFile: shot.thumb,
        ),
      ),
      throwsA(anything),
    );
    expect(await db.select(db.checkIns).get(), isEmpty);
    expect(files(), before);
  });

  test('L2 the sync sweep re-queues a check-in without a queue row', () async {
    remote.failure = offline;
    final c = await checkIn('a');
    await db.delete(db.uploadQueue).go();
    expect(await layer.ctx.sync!.enqueueOrphanUploads(me), 1);
    expect([for (final q in await queue()) q.entityKey], [checkInKey(c.id)]);
    // Idempotent.
    expect(await layer.ctx.sync!.enqueueOrphanUploads(me), 0);
  });

  test('L4 a pending local journey edit survives the pull', () async {
    await db
        .update(db.journeys)
        .write(const JourneysCompanion(title: Value('Local title')));
    await layer.ctx.outbox!.enqueue(
      OutboxKind.updateJourney,
      '${journeyKey(jid)}:edit',
      {'id': jid},
    );
    remote.tables['journeys'] = [
      journeyRow(
        jid,
        ownerId: me,
        updatedAt: '2026-10-17T01:00:00.000000+00:00',
      ),
    ];
    await layer.ctx.sync!.syncNow();
    final j = await (db.select(
      db.journeys,
    )..where((t) => t.id.equals(jid))).getSingle();
    expect(j.title, 'Local title');
  });

  test('L4 a pending membership change survives the pull', () async {
    await db
        .update(db.memberships)
        .write(const MembershipsCompanion(hideMetric: Value(false)));
    await layer.ctx.outbox!.enqueue(
      OutboxKind.updateMembership,
      membershipKey(jid),
      {'journey_id': jid, 'user_id': me},
    );
    remote.tables['memberships'] = [
      membershipRow(jid, me, updatedAt: '2026-10-17T01:00:00.000000+00:00'),
    ];
    await layer.ctx.sync!.syncNow();
    final m = await db.select(db.memberships).getSingle();
    expect(m.hideMetric, isFalse);
  });

  test('L16 purging a journey cancels its queued uploads', () async {
    remote.failure = offline;
    await checkIn('a');
    await layer.ctx.outbox!.enqueue(
      OutboxKind.updateMembership,
      membershipKey(jid),
      {'journey_id': jid},
    );
    await layer.ctx.outbox!.enqueue(OutboxKind.deleteMedia, journeyKey(jid), {
      'prefixes': <String>[],
      'paths': <String>[],
    });
    expect(await queue(), hasLength(3));
    await layer.ctx.store.purgeJourney(jid);
    // Only the media deletion is kept: it still has to run.
    expect(
      [for (final q in await queue()) q.kind],
      [OutboxKind.deleteMedia.wire],
    );
  });

  test('L7 sign-out sends the pending uploads first', () async {
    remote.failure = offline;
    await checkIn('a');
    remote.failure = null;
    await layer.auth.signOut();
    expect(remote.uploaded, isNotEmpty);
    final order = [for (final c in remote.calls) c.method];
    expect(order.indexOf('upload'), lessThan(order.indexOf('signOut')));
  });

  group('L1 dead uploads', () {
    Future<CheckIn> deadCheckIn() async {
      remote.failure = offline;
      final c = await checkIn('a');
      await db
          .update(db.uploadQueue)
          .write(
            const UploadQueueCompanion(
              dead: Value(true),
              lastError: Value('x'),
            ),
          );
      remote.failure = null;
      return c;
    }

    test('are listed per journey', () async {
      final c = await deadCheckIn();
      final dead = layer.deadUploads!;
      final items = await dead.watch(journeyId: jid).first;
      expect(items.single.checkInId, c.id);
      expect(await dead.watch(journeyId: 'other').first, isEmpty);
    });

    test('retry revives and uploads them', () async {
      await deadCheckIn();
      final dead = layer.deadUploads!;
      await dead.retry(await dead.watch().first);
      await layer.ctx.outbox!.flush(force: true);
      expect(remote.uploaded, isNotEmpty);
      expect(await dead.watch().first, isEmpty);
    });

    test('discard removes the queue item and the local check-in', () async {
      await deadCheckIn();
      final dead = layer.deadUploads!;
      await dead.discard(await dead.watch().first);
      expect(await queue(), isEmpty);
      expect(await db.select(db.checkIns).get(), isEmpty);
    });
  });

  group('round 2', () {
    const partner = 'cccccccc-0000-4000-8000-000000000002';

    Future<void> pendingMine() => layer.ctx.outbox!.enqueue(
      OutboxKind.updateMembership,
      membershipKey(jid),
      {'journey_id': jid, 'user_id': me},
    );

    test('a partner joining is applied while my change is pending', () async {
      await pendingMine();
      remote.tables['memberships'] = [
        membershipRow(jid, me, updatedAt: '2026-10-17T01:00:00.000000+00:00'),
        membershipRow(
          jid,
          partner,
          role: 'member',
          updatedAt: '2026-10-17T01:00:00.000000+00:00',
        ),
      ];
      await layer.ctx.sync!.syncNow();
      final ids = [
        for (final m in await db.select(db.memberships).get()) m.userId,
      ];
      expect(ids, contains(partner));
    });

    test('my left row is applied and purges the journey', () async {
      await pendingMine();
      remote.tables['memberships'] = [
        membershipRow(
          jid,
          me,
          status: 'left',
          updatedAt: '2026-10-17T01:00:00.000000+00:00',
        ),
      ];
      await layer.ctx.sync!.syncNow();
      expect(await db.select(db.journeys).get(), isEmpty);
      expect(await db.select(db.memberships).get(), isEmpty);
    });

    test('discarding a dead upload re-pulls its journey', () async {
      remote.failure = offline;
      await checkIn('a');
      await db
          .update(db.uploadQueue)
          .write(const UploadQueueCompanion(dead: Value(true)));
      remote.failure = null;
      remote.tables['journeys'] = [
        journeyRow(
          jid,
          ownerId: me,
          updatedAt: '2026-10-17T01:00:00.000000+00:00',
        )..['title'] = 'Server v2',
      ];
      final dead = layer.deadUploads!;
      await dead.discard(await dead.watch().first);

      final j = await db.select(db.journeys).getSingle();
      expect(j.title, 'Server v2');
      expect(await queue(), isEmpty);
    });

    test('a forced flush asked during a running one ignores backoff', () async {
      final gate = Completer<void>();
      final done = <String>[];
      final outbox = Outbox(
        db,
        executor: (kind, payload) async {
          if (payload['id'] == 'a') await gate.future;
          done.add(payload['id'] as String);
        },
      );
      addTearDown(outbox.dispose);
      await outbox.enqueue(OutboxKind.react, 'react:a', {'id': 'a'});
      await outbox.enqueue(OutboxKind.react, 'react:b', {
        'id': 'b',
      }, delay: const Duration(hours: 1));
      final first = outbox.flush();
      await Future<void>.delayed(Duration.zero);
      final forced = outbox.flush(force: true);
      gate.complete();
      await first;
      await forced;
      expect(done, ['a', 'b']);
    });

    test('H1 an item that dies triggers a re-pull of its journey', () async {
      remote.failure = offline;
      await checkIn('a');
      remote.failure = null;
      remote.failOnce.add(const OurneyException(OurneyErrorCode.forbidden));
      final before = remote.callsOf('select').length;
      await layer.ctx.outbox!.flush(force: true);
      for (
        var i = 0;
        i < 50 && remote.callsOf('select').length == before;
        i++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      expect(remote.callsOf('select').length, greaterThan(before));
      expect(await layer.deadUploads!.watch().first, hasLength(1));
    });

    group('M1 a local-only journey is never purged', () {
      Future<(Journey, CheckIn)> localOnly() async {
        remote.failure = offline;
        final j = await layer.journeys.create(soloDraft());
        final shot = fakeCapture(camera, 'm');
        final c = await layer.checkIns.submit(
          CheckInDraft(
            journeyId: j.id,
            capturedAt: DateTime.utc(2026, 10, 16, 1),
            photoFile: shot.photo,
            thumbFile: shot.thumb,
          ),
        );
        await (db.update(db.uploadQueue)
              ..where((t) => t.entityKey.equals(checkInKey(c.id))))
            .write(const UploadQueueCompanion(dead: Value(true)));
        remote.failure = null;
        return (j, c);
      }

      test('repullAfterDrop', () async {
        final (j, c) = await localOnly();
        await layer.ctx.sync!.repullAfterDrop(
          OutboxKind.upsertCheckIn,
          checkInKey(c.id),
        );
        final ids = [for (final r in await db.select(db.journeys).get()) r.id];
        expect(ids, contains(j.id));
      });

      test('discarding its dead check-in', () async {
        final (j, _) = await localOnly();
        final dead = layer.deadUploads!;
        await dead.discard(await dead.watch().first);
        final ids = [for (final r in await db.select(db.journeys).get()) r.id];
        expect(ids, contains(j.id));
        expect(await db.select(db.checkIns).get(), isEmpty);
      });

      test('even when its create_journey item is dead', () async {
        final (j, c) = await localOnly();
        await (db.update(db.uploadQueue)
              ..where((t) => t.entityKey.equals(journeyKey(j.id))))
            .write(const UploadQueueCompanion(dead: Value(true)));
        await layer.ctx.sync!.pullJourney(j.id);
        final ids = [for (final r in await db.select(db.journeys).get()) r.id];
        expect(ids, contains(j.id));
        expect(c.journeyId, j.id);
      });
    });

    test('L11 discard also drops other items of the check-in', () async {
      remote.failure = offline;
      final c = await checkIn('a');
      await db
          .update(db.uploadQueue)
          .write(const UploadQueueCompanion(dead: Value(true)));
      await layer.ctx.outbox!.enqueue(OutboxKind.react, reactionKey(c.id), {
        'id': c.id,
      });
      remote.failure = null;
      final dead = layer.deadUploads!;
      await dead.discard(await dead.watch().first);
      expect(await queue(), isEmpty);
    });

    test('L11 a left purge cleans dead membership items', () async {
      await db
          .into(db.uploadQueue)
          .insert(
            UploadQueueCompanion.insert(
              kind: OutboxKind.updateMembership.wire,
              entityKey: membershipKey(jid),
              payload: '{}',
              createdAt: DateTime.utc(2026, 10, 16),
              dead: const Value(true),
            ),
          );
      await layer.ctx.store.purgeJourney(jid);
      expect(await queue(), isEmpty);
    });

    test('N2 only already_deleted counts as already deleted', () async {
      remote.failOnce.add(const OurneyException(OurneyErrorCode.offline));
      await expectLater(
        layer.auth.deleteAccount(code: '123456'),
        throwsA(isA<OurneyException>()),
      );
      remote.failOnce.add(
        const OurneyException(OurneyErrorCode.alreadyDeleted),
      );
      await layer.auth.deleteAccount(code: '123456');
      expect(remote.callsOf('signOut'), isNotEmpty);
    });

    test(
      'N2 a 401 stays an error, even on a retry, and keeps local data',
      () async {
        remote.failOnce.add(const OurneyException(OurneyErrorCode.offline));
        await expectLater(
          layer.auth.deleteAccount(code: '123456'),
          throwsA(isA<OurneyException>()),
        );
        remote.failOnce.add(
          const OurneyException(OurneyErrorCode.unauthenticated),
        );
        await expectLater(
          layer.auth.deleteAccount(code: '123456'),
          throwsA(
            isA<OurneyException>().having(
              (e) => e.error,
              'error',
              OurneyErrorCode.unauthenticated,
            ),
          ),
        );
        expect(remote.callsOf('signOut'), isEmpty);
        expect(await db.select(db.journeys).get(), isNotEmpty);
      },
    );

    test('N7 a dead non-create item does not keep a deleted journey', () async {
      await db
          .into(db.uploadQueue)
          .insert(
            UploadQueueCompanion.insert(
              kind: OutboxKind.updateMembership.wire,
              entityKey: membershipKey(jid),
              payload: '{}',
              createdAt: DateTime.utc(2026, 10, 16),
              dead: const Value(true),
            ),
          );
      remote.tables['journeys'] = [];
      await layer.ctx.sync!.pullJourney(jid);
      expect(await db.select(db.journeys).get(), isEmpty);
    });
  });
}
