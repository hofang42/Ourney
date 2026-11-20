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
}
