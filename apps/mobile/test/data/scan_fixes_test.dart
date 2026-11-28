import 'dart:async';
import 'dart:convert' show jsonEncode;
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/data/data_layer.dart';
import 'package:ourney/data/db/app_database.dart';
import 'package:ourney/data/local_store.dart';
import 'package:ourney/data/media_store.dart';
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

    test(
      'policy-dead import keeps the photo and uploads without caption',
      () async {
        await (db.update(db.journeys)..where((t) => t.id.equals(jid))).write(
          const JourneysCompanion(origin: Value('imported')),
        );
        remote.failure = const OurneyException(OurneyErrorCode.contentPolicy);
        final capture = fakeCapture(camera, 'policy');
        await layer.checkIns.submit(
          CheckInDraft(
            journeyId: jid,
            capturedAt: DateTime.utc(2026, 10, 16, 1),
            photoFile: capture.photo,
            thumbFile: capture.thumb,
            caption: 'rejected words',
            fromLibrary: true,
          ),
        );
        await layer.ctx.outbox!.flush(force: true);
        expect((await queue()).single.dead, isTrue);
        remote.failure = null;
        final dead = layer.deadUploads!;
        final item = (await dead.watch().first).single;
        expect(item.isContentPolicy, isTrue);
        await dead.keepPhotoOnly(item);
        expect((await db.select(db.checkIns).getSingle()).caption, isNull);
        expect((await queue()).every((r) => !r.dead), isTrue);
        await layer.ctx.outbox!.flush(force: true);
        expect((await db.select(db.checkIns).getSingle()).uploaded, isTrue);
        expect(remote.uploaded, isNotEmpty);
        expect(await dead.watch().first, isEmpty);
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );

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
      final bId = await outbox.enqueue(
        OutboxKind.react,
        'react:b',
        {'id': 'b'},
        delay: const Duration(hours: 1),
      );
      // Simulate retry backoff (`attempts > 0`); initial `attempts == 0` delay
      // guards in-flight direct RPCs (F-30).
      await (db.update(db.uploadQueue)..where((t) => t.id.equals(bId))).write(
        const UploadQueueCompanion(attempts: Value(1)),
      );
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

  group('Fullscan Batch B regressions (FS-10, FS-11, FS-27, FS-28, FS-34, FS-37)', () {
    test('FS-10: _pullOnce and _pullJourney preserve queued :extras and membership toggles', () async {
      await (db.update(db.journeys)..where((t) => t.id.equals(jid))).write(
        const JourneysCompanion(
          layout: Value('aesthetic_flexer'),
          color: Value(2),
          reminderTime: Value('06:45'),
        ),
      );
      await layer.ctx.outbox!.enqueue(
        OutboxKind.updateJourney,
        '${journeyKey(jid)}:extras',
        {'p_journey': jid, 'p_layout': 'aesthetic_flexer', 'p_color': 2},
      );
      await (db.update(db.memberships)..where((t) => t.journeyId.equals(jid))).write(
        const MembershipsCompanion(
          hideMetric: Value(true),
          blurMedia: Value(true),
        ),
      );
      await layer.ctx.outbox!.enqueue(
        OutboxKind.updateMembership,
        membershipKey(jid),
        {'journey_id': jid, 'user_id': me, 'hide_metric': true, 'blur_media': true},
      );

      remote.tables['journeys'] = [
        journeyRow(
          jid,
          ownerId: me,
          updatedAt: '2026-10-18T01:00:00.000000+00:00',
        ),
      ];
      remote.tables['memberships'] = [
        membershipRow(
          jid,
          me,
          updatedAt: '2026-10-18T01:00:00.000000+00:00',
        )..['hide_metric'] = false
         ..['blur_media'] = false,
      ];

      await layer.ctx.sync!.syncNow();
      var j = await (db.select(db.journeys)..where((t) => t.id.equals(jid))).getSingle();
      expect(j.layout, 'aesthetic_flexer');
      expect(j.color, 2);
      expect(j.reminderTime, '06:45');

      await layer.ctx.sync!.pullJourney(jid);
      j = await (db.select(db.journeys)..where((t) => t.id.equals(jid))).getSingle();
      final m = await (db.select(db.memberships)..where((t) => t.journeyId.equals(jid))).getSingle();
      expect(j.layout, 'aesthetic_flexer');
      expect(j.color, 2);
      expect(m.hideMetric, isTrue);
      expect(m.blurMedia, isTrue);
    });

    test('FS-11: MediaWipe stores relative basenames and deletes trash after iOS container UUID rotation', () async {
      final container1 = tempDir();
      final container2 = tempDir();
      final media1 = Directory('${container1.path}/media')..createSync();
      File('${media1.path}/secret.jpg').writeAsStringSync('user-a-photo');

      // Record trash under container 1 (as if MediaWipe.run committed before app kill).
      final trashName = 'media.trash-1700000000';
      final trashInContainer2 = Directory('${container2.path}/$trashName')..createSync();
      File('${trashInContainer2.path}/secret.jpg').writeAsStringSync('user-a-photo');
      await db.writeCursor(
        pendingTrashCursorKey,
        jsonEncode(['${container1.path}/$trashName']),
      );

      final media2 = Directory('${container2.path}/media');
      await layer.ctx.files.delete(const []);
      // Recover under container 2 (simulating iOS app update assigning a new container UUID).
      await MediaWipe.recover(db, [media2]);
      expect(trashInContainer2.existsSync(), isFalse);
      expect(
        File('${media2.path}/secret.jpg').existsSync(),
        isFalse,
        reason: 'wiped User A photo must never be merged back into User B live media/',
      );
      expect(await db.readCursor(pendingTrashCursorKey), '[]');
    });

    test('FS-27: DeadUploads.watch skips already-uploaded check-ins and retry submit deduplicates queue', () async {
      remote.failure = offline;
      final shot = fakeCapture(camera, 'd1');
      const cid = 'eeeeeeee-0000-4000-8000-000000000099';
      final c = await layer.checkIns.submit(
        CheckInDraft(
          id: cid,
          journeyId: jid,
          capturedAt: DateTime.utc(2026, 10, 16, 1),
          photoFile: shot.photo,
          thumbFile: shot.thumb,
        ),
      );
      await (db.update(db.uploadQueue)..where((t) => t.entityKey.equals(checkInKey(c.id)))).write(
        const UploadQueueCompanion(dead: Value(true), lastError: Value('err')),
      );
      expect(await layer.deadUploads!.watch(journeyId: jid).first, hasLength(1));

      // Retrying submit with the same clientId replaces the dead row instead of duplicating it.
      await layer.checkIns.submit(
        CheckInDraft(
          id: cid,
          journeyId: jid,
          capturedAt: DateTime.utc(2026, 10, 16, 1),
          photoFile: shot.photo,
          thumbFile: shot.thumb,
        ),
      );
      final rowsForCheckIn = await (db.select(db.uploadQueue)
            ..where((t) => t.entityKey.equals(checkInKey(c.id))))
          .get();
      expect(rowsForCheckIn, hasLength(1));

      // If the check-in is already marked uploaded, DeadUploads.watch never surfaces a stale dead row.
      await (db.update(db.uploadQueue)..where((t) => t.entityKey.equals(checkInKey(c.id)))).write(
        const UploadQueueCompanion(dead: Value(true), lastError: Value('err')),
      );
      await (db.update(db.checkIns)..where((t) => t.id.equals(c.id))).write(
        const CheckInsCompanion(uploaded: Value(true)),
      );
      expect(await layer.deadUploads!.watch(journeyId: jid).first, isEmpty);
    });

    test('FS-28: setAvatar and sendPhoto reject empty or > 5 MB payloads', () async {
      await layer.profiles.upsertMe(username: 'linh', displayName: 'Linh');
      await expectLater(
        layer.profiles.setAvatar(const []),
        throwsA(
          isA<OurneyException>().having((e) => e.error, 'error', OurneyErrorCode.invalid),
        ),
      );
      final oversized = List<int>.filled(5 * 1024 * 1024 + 1, 1);
      await expectLater(
        layer.profiles.setAvatar(oversized),
        throwsA(
          isA<OurneyException>().having((e) => e.error, 'error', OurneyErrorCode.invalid),
        ),
      );
      await expectLater(
        layer.chat!.sendPhoto('conv-1', oversized),
        throwsA(
          isA<OurneyException>().having((e) => e.error, 'error', OurneyErrorCode.invalid),
        ),
      );
    });

    test('FS-34: AppDatabase sets foreign_keys and busy_timeout pragmas and creates import_job_photos index', () async {
      final fk = await db.customSelect('PRAGMA foreign_keys').getSingle();
      expect(fk.data.values.single, 1);
      final bt = await db.customSelect('PRAGMA busy_timeout').getSingle();
      expect(bt.data.values.single, 5000);
      final idx = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'index' "
            "AND name = 'import_job_photos_job_pos'",
          )
          .get();
      expect(idx, hasLength(1));
    });

    test('FS-37: MediaFiles.deleteFolder rejects path traversal and empty prefixes', () async {
      await expectLater(
        layer.ctx.files.deleteFolder(''),
        throwsA(isA<OurneyException>()),
      );
      await expectLater(
        layer.ctx.files.deleteFolder('../outside'),
        throwsA(isA<OurneyException>()),
      );
      await expectLater(
        layer.ctx.files.deleteFolder('checkins/../../outside'),
        throwsA(isA<OurneyException>()),
      );
    });

    test('blocking a user evicts their locally cached avatars', () async {
      const other = 'cccccccc-0000-4000-8000-000000000002';
      final blockedAvatar = await layer.ctx.files.writeBytes(
        'avatars/$other/cached.jpg',
        [1],
      );
      final ownAvatar = await layer.ctx.files.writeBytes(
        'avatars/$me/cached.jpg',
        [2],
      );

      await layer.safety.block(other);

      expect(await blockedAvatar.exists(), isFalse);
      expect(await ownAvatar.exists(), isTrue);
    });

    test('FS-07: DataSafetyRepository.report forwards optional messageId to report_content RPC', () async {
      await layer.safety.report(
        messageId: 'msg-123',
        reason: ReportReason.harassment,
        note: 'abusive',
      );
      final rpcs = {for (final c in remote.callsOf('rpc')) c.target: c.args};
      expect(rpcs['report_content'], {
        'p_checkin': null,
        'p_user': null,
        'p_reason': 'harassment',
        'p_note': 'abusive',
        'p_message': 'msg-123',
      });
    });

    test('FS-27: signOut falls back to local sign-out and wipes local data when global signOut times out', () async {
      remote.hangGlobalSignOut = true;
      await layer.auth.signOut();
      expect(await db.select(db.journeys).get(), isEmpty);
      expect(
        [for (final c in remote.callsOf('signOut')) c.target],
        ['global', 'local'],
      );
    });
  });

  group('Audit fixes F-08, F-10, F-26, F-30, F-31', () {
    const partner = 'cccccccc-0000-4000-8000-000000000002';

    test(
      'F-08: remote session revocation/expiry without unsynced work wipes local DB and cached media',
      () async {
        final photo = await layer.ctx.files.writeBytes(
          'checkins/$jid/$me/synced.jpg',
          [1, 2, 3],
        );
        final draft = File('${media.parent.path}/checkin_media/draft.jpg')
          ..createSync(recursive: true)
          ..writeAsBytesSync([4, 5]);
        await db.into(db.profiles).insertOnConflictUpdate(
          ProfilesCompanion.insert(
            id: me,
            username: 'me',
            displayName: 'Me',
          ),
        );
        expect(await db.select(db.journeys).get(), isNotEmpty);
        expect(photo.existsSync(), isTrue);
        expect(draft.existsSync(), isTrue);

        // Simulate remote session revocation / token expiry.
        remote.emitUser(null);
        await pumpEventQueue();
        await MediaWipe.settled();

        expect(await db.select(db.journeys).get(), isEmpty);
        expect(await db.select(db.memberships).get(), isEmpty);
        expect(await db.select(db.profiles).get(), isEmpty);
        expect(photo.existsSync(), isFalse);
        expect(draft.existsSync(), isFalse);
      },
    );

    test(
      'F-08 & F-10: remote session expiry wipes synced data/photos, pauses outbox without killing unsynced writes, and resumes on re-sign-in as same user',
      () async {
        // Seed a synced check-in on disk and in DB.
        const syncedId = 'eeeeeeee-0000-4000-8000-000000000010';
        final syncedPhotoPath = checkInPhotoPath(jid, me, syncedId);
        final syncedThumbPath = checkInThumbPath(jid, me, syncedId);
        final syncedPhoto = await layer.ctx.files.writeBytes(
          syncedPhotoPath,
          [9, 9],
        );
        final syncedThumb = await layer.ctx.files.writeBytes(
          syncedThumbPath,
          [8, 8],
        );
        final avatarFile = await layer.ctx.files.writeBytes(
          'avatars/$me/av.jpg',
          [7, 7],
        );
        await db.into(db.checkIns).insert(
          CheckInsCompanion.insert(
            id: syncedId,
            journeyId: jid,
            userId: me,
            localDate: const LocalDate(2026, 10, 15),
            capturedAt: DateTime.utc(2026, 10, 15, 1),
            photoPath: syncedPhotoPath,
            thumbPath: syncedThumbPath,
            uploaded: const Value(true),
          ),
        );
        await db.into(db.profiles).insertOnConflictUpdate(
          ProfilesCompanion.insert(
            id: me,
            username: 'me',
            displayName: 'Me',
          ),
        );

        // User submits an offline check-in.
        remote.failure = offline;
        final pending = await checkIn('unsynced_shot');
        final pendingPhotoFile = layer.ctx.files.fileFor(pending.photoPath);
        final pendingThumbFile = layer.ctx.files.fileFor(pending.thumbPath);
        expect(pendingPhotoFile.existsSync(), isTrue);

        // Remote session expires while offline/before retry.
        remote.failure = null;
        remote.emitUser(null);
        await pumpEventQueue();
        await MediaWipe.settled();

        // Synced check-in, profile, avatar, and synced photos are wiped (F-08).
        expect(await db.select(db.profiles).get(), isEmpty);
        expect(syncedPhoto.existsSync(), isFalse);
        expect(syncedThumb.existsSync(), isFalse);
        expect(avatarFile.existsSync(), isFalse);
        final remainingCheckIns = await db.select(db.checkIns).get();
        expect(remainingCheckIns.map((c) => c.id), [pending.id]);
        expect(pendingPhotoFile.existsSync(), isTrue);
        expect(pendingThumbFile.existsSync(), isTrue);

        // Even if the outbox flushes while signed out (remote.currentUserId == null)
        // and the server would reject anon with forbidden, SyncEngine blocks
        // anon execution with unauthenticated and Outbox pauses without killing
        // the item or incrementing attempts (F-10).
        remote.failure = const OurneyException(OurneyErrorCode.forbidden);
        final callsBefore = remote.calls.length;
        await layer.ctx.outbox!.flush(force: true);
        expect(remote.calls.length, callsBefore, reason: 'no anon server calls');
        final queuedWhileSignedOut = await queue();
        expect(queuedWhileSignedOut, hasLength(1));
        expect(queuedWhileSignedOut.single.dead, isFalse);
        expect(queuedWhileSignedOut.single.attempts, 0);

        // User signs back in as the same user (`me`): outbox resumes and uploads.
        remote.failure = null;
        remote.emitUser(me);
        await layer.syncNow();

        expect(remote.uploaded.keys, containsAll([
          pending.photoPath,
          pending.thumbPath,
        ]));
        expect(await queue(), isEmpty);
        final uploadedRow = await (db.select(
          db.checkIns,
        )..where((t) => t.id.equals(pending.id))).getSingle();
        expect(uploadedRow.uploaded, isTrue);
      },
    );

    test(
      'F-10 isolation: re-signing in as a different user isolates the old user queue (never uploads under new user) and restores it when old user returns',
      () async {
        remote.failure = offline;
        final pending = await checkIn('user_a_unsynced');
        expect(await queue(), hasLength(1));

        // Session expires, then User B (`partner`) signs in.
        remote.failure = null;
        remote.emitUser(null);
        await pumpEventQueue();
        await MediaWipe.settled();

        remote.tables['journeys'] = [
          journeyRow('journey-b', ownerId: partner),
        ];
        remote.tables['memberships'] = [
          membershipRow('journey-b', partner),
        ];
        remote.emitUser(partner);
        await layer.syncNow();
        await MediaWipe.settled();

        // User A's unsynced post was NOT uploaded under User B, and User B's
        // active queue and check-ins are clean.
        expect(remote.uploaded, isEmpty);
        expect(await queue(), isEmpty);
        expect(await db.select(db.checkIns).get(), isEmpty);
        expect(
          [for (final j in await db.select(db.journeys).get()) j.id],
          ['journey-b'],
        );
        expect(await layer.ctx.sync!.hasIsolatedWorkFor(me), isTrue);
        expect(
          await layer.ctx.sync!.isolatedEntityKeysFor(me),
          [checkInKey(pending.id)],
        );

        // Now User A (`me`) signs back in: isolated work is restored and uploaded!
        remote.tables['journeys'] = [journeyRow(jid, ownerId: me)];
        remote.tables['memberships'] = [membershipRow(jid, me)];
        remote.emitUser(me);
        await layer.syncNow();
        await MediaWipe.settled();

        expect(await layer.ctx.sync!.hasIsolatedWorkFor(me), isFalse);
        expect(remote.uploaded.keys, containsAll([
          pending.photoPath,
          pending.thumbPath,
        ]));
        expect(await queue(), isEmpty);
        final restoredCheckIn = await (db.select(
          db.checkIns,
        )..where((t) => t.id.equals(pending.id))).getSingle();
        expect(restoredCheckIn.uploaded, isTrue);
      },
    );

    test(
      'F-26: pulling a block from another device evicts blocked user media; pulling an unblock re-pulls group journeys',
      () async {
        const groupJid = 'dddddddd-0000-4000-8000-000000000099';
        const partnerCid = 'eeeeeeee-0000-4000-8000-000000000099';
        final partnerPhotoPath = checkInPhotoPath(groupJid, partner, partnerCid);
        final partnerThumbPath = checkInThumbPath(groupJid, partner, partnerCid);

        remote.tables['journeys'] = [
          journeyRow(groupJid, ownerId: me, kind: 'group', visibility: 'group'),
        ];
        remote.tables['memberships'] = [
          membershipRow(groupJid, me),
          membershipRow(groupJid, partner, role: 'member'),
        ];
        final partnerCheckInRow = {
          'id': partnerCid,
          'journey_id': groupJid,
          'user_id': partner,
          'local_date': '2026-10-16',
          'captured_at': '2026-10-16T01:00:00+00:00',
          'photo_path': partnerPhotoPath,
          'thumb_path': partnerThumbPath,
          'from_library': false,
          'caption': 'partner post',
          'metric_value': null,
          'updated_at': '2026-10-16T01:00:00.000000+00:00',
          'deleted_at': null,
        };
        remote.tables['check_ins'] = [partnerCheckInRow];
        await layer.syncNow();

        final cachedPhoto = await layer.ctx.files.writeBytes(
          partnerPhotoPath,
          [1, 2],
        );
        final cachedThumb = await layer.ctx.files.writeBytes(
          partnerThumbPath,
          [3, 4],
        );
        final cachedAvatar = await layer.ctx.files.writeBytes(
          'avatars/$partner/avatar.jpg',
          [5, 6],
        );
        expect(cachedPhoto.existsSync(), isTrue);
        expect(cachedThumb.existsSync(), isTrue);
        expect(cachedAvatar.existsSync(), isTrue);

        // Device 1 blocks partner; Device 2 pulls `blocks` table.
        remote.tables['blocks'] = [
          {
            'blocker_id': me,
            'blocked_id': partner,
            'updated_at': '2026-10-16T02:00:00.000000+00:00',
            'deleted_at': null,
          },
        ];
        // Server RLS hides blocked user's check-ins while blocked.
        remote.tables['check_ins'] = [];
        await layer.syncNow();

        expect(
          await (db.select(
            db.checkIns,
          )..where((t) => t.userId.equals(partner))).get(),
          isEmpty,
        );
        expect(cachedPhoto.existsSync(), isFalse);
        expect(cachedThumb.existsSync(), isFalse);
        expect(cachedAvatar.existsSync(), isFalse);

        // Device 1 unblocks partner; Device 2 pulls block tombstone.
        remote.tables['blocks'] = [
          {
            'blocker_id': me,
            'blocked_id': partner,
            'updated_at': '2026-10-16T03:00:00.000000+00:00',
            'deleted_at': '2026-10-16T03:00:00.000000+00:00',
          },
        ];
        remote.tables['check_ins'] = [partnerCheckInRow];
        await layer.syncNow();

        final repulled = await (db.select(
          db.checkIns,
        )..where((t) => t.id.equals(partnerCid))).getSingleOrNull();
        expect(repulled, isNotNull);
        expect(repulled!.caption, 'partner post');
      },
    );

    test(
      'F-30: Outbox.flush(force: true) respects initial enqueue delay guard (attempts == 0)',
      () async {
        final executed = <String>[];
        final clock = TestClock(DateTime.utc(2026, 10, 16, 2));
        final timers = RecordingTimers();
        final outbox = Outbox(
          db,
          executor: (kind, payload) async {
            executed.add('${kind.wire}:${payload['id']}');
          },
          now: clock.call,
          timer: timers.call,
        );
        addTearDown(outbox.dispose);

        await outbox.enqueue(
          OutboxKind.updateJourney,
          '${journeyKey(jid)}:extras',
          {'id': jid},
          delay: const Duration(seconds: 30),
        );

        // Forced flush while direct RPC is in flight (attempts == 0) must not
        // bypass the 30s delay guard.
        await outbox.flush(force: true);
        expect(executed, isEmpty);
        expect(timers.delays.last, const Duration(seconds: 30));

        // Once the 30s delay passes (or makeDue is called), it executes.
        clock.advance(const Duration(seconds: 31));
        await outbox.flush(force: true);
        expect(executed, ['update_journey:$jid']);
      },
    );

    test(
      'F-31: LocalStore.purgeJourney removes queued journey:<id>:couple (rename_couple) items',
      () async {
        await layer.ctx.outbox!.enqueue(
          OutboxKind.renameCouple,
          '${journeyKey(jid)}:couple',
          {'p_journey': jid, 'p_self': 'An', 'p_partner': 'Bình'},
        );
        expect(
          await layer.ctx.outbox!.pendingKeys(),
          contains('${journeyKey(jid)}:couple'),
        );

        await layer.ctx.store.purgeJourney(jid);

        expect(
          await layer.ctx.outbox!.pendingKeys(),
          isNot(contains('${journeyKey(jid)}:couple')),
        );
        expect(await queue(), isEmpty);
      },
    );
  });
}
