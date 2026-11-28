import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/data/data_context.dart';
import 'package:ourney/data/db/app_database.dart';
import 'package:ourney/data/local_store.dart';
import 'package:ourney/data/media_store.dart';
import 'package:ourney/data/remote/remote_api.dart';
import 'package:ourney/data/repositories/check_in_repository.dart';
import 'package:ourney/data/sync/outbox.dart';
import 'package:ourney/data/sync/sync_engine.dart';
import 'package:ourney_core/ourney_core.dart';

import 'data_test_helpers.dart';

const _photoId = 'photo';
const _journeyId = 'journey';
const _me = 'author';
const _timeout = Timeout(Duration(seconds: 30));

class _HeldUploadRemote extends FakeRemoteApi {
  _HeldUploadRemote() : super(userId: _me);

  final uploadStarted = Completer<void>();
  final finishUpload = Completer<void>();

  @override
  Future<void> uploadFile(String path, File file) async {
    if (!uploadStarted.isCompleted) uploadStarted.complete();
    await finishUpload.future;
    await super.uploadFile(path, file);
  }
}

class _ObservedOutbox extends Outbox {
  _ObservedOutbox(super.db, {required super.executor, required super.timer});

  final exclusiveRequested = Completer<void>();

  @override
  Future<T> exclusive<T>(Future<T> Function() fn) {
    if (!exclusiveRequested.isCompleted) exclusiveRequested.complete();
    return super.exclusive(fn);
  }
}

void main() {
  late AppDatabase db;
  late Directory media;
  late TestClock clock;
  late FakeRemoteApi remote;
  late _ObservedOutbox queue;
  late DataCheckInRepository repository;

  void useRemote(FakeRemoteApi? api) {
    final files = MediaFiles(media);
    if (api != null) {
      final sync = SyncEngine(
        db: db,
        store: LocalStore(db, files),
        remote: api,
        now: clock.call,
      );
      queue = _ObservedOutbox(
        db,
        executor: sync.execute,
        timer: RecordingTimers().call,
      );
      sync.outbox = queue;
      addTearDown(queue.dispose);
    }
    repository = DataCheckInRepository(
      DataContext(
        db: db,
        files: files,
        media: CachedMediaStore(files, remote: api),
        clock: testJourneyClock(clock),
        userIdOf: () => _me,
        remote: api,
        outbox: api == null ? null : queue,
      ),
    );
  }

  setUp(() {
    db = memoryDb();
    media = tempDir();
    clock = TestClock(DateTime.utc(2026, 11, 27));
    remote = FakeRemoteApi(userId: _me);
  });

  Future<void> seed({
    bool uploaded = false,
    String author = _me,
    bool moderated = false,
  }) async {
    const photo = 'photos/$_photoId.jpg';
    const thumb = 'photos/${_photoId}_t.jpg';
    final files = MediaFiles(media);
    await files.writeBytes(photo, [1, 2, 3]);
    await files.writeBytes(thumb, [4, 5]);
    await db
        .into(db.checkIns)
        .insert(
          CheckInsCompanion.insert(
            id: _photoId,
            journeyId: _journeyId,
            userId: author,
            localDate: const LocalDate(2026, 11, 27),
            capturedAt: clock.value,
            fromLibrary: const Value(true),
            photoPath: photo,
            thumbPath: thumb,
            caption: const Value('Original'),
            uploaded: Value(uploaded),
            moderated: Value(moderated),
          ),
        );
  }

  Future<int> enqueue() => queue.enqueue(
    OutboxKind.upsertCheckIn,
    checkInKey(_photoId),
    {'id': _photoId},
  );

  List<RemoteCall> callsToCheckIns(String method) => [
    for (final call in remote.callsOf(method))
      if (call.target == 'check_ins') call,
  ];

  Object? pushedCaption() {
    final args = callsToCheckIns('upsert').single.args! as RemoteRow;
    return (args['row'] as RemoteRow)['caption'];
  }

  Matcher throwsCode(OurneyErrorCode code) =>
      throwsA(isA<OurneyException>().having((e) => e.error, 'error', code));

  test(
    'pending edit keeps the live queued write in place and uploads the new '
    'caption',
    () async {
      useRemote(remote);
      await seed();
      queue.setPaused(true);
      final originalId = await enqueue();
      // Queued after the upload and dependent on it (a reaction on the row).
      final laterId = await queue.enqueue(
        OutboxKind.react,
        'reaction:$_photoId',
        {'checkInId': _photoId},
      );

      final saved = await repository.updateCaption(_photoId, '  Bữa tối  ');

      expect(saved.caption, 'Bữa tối');
      expect(saved.uploaded, isFalse);
      final rows = await queue.pendingRows();
      expect([for (final r in rows) r.id], [originalId, laterId]);
      await queue.cancel('reaction:$_photoId');
      queue.setPaused(false);
      await queue.flush();
      expect(pushedCaption(), 'Bữa tối');
      expect((await db.select(db.checkIns).getSingle()).uploaded, isTrue);
    },
    timeout: _timeout,
  );

  test(
    'editing a policy-dead caption replaces the dead item and uploads',
    () async {
      useRemote(remote);
      await seed();
      remote.failure = const OurneyException(OurneyErrorCode.contentPolicy);
      final originalId = await enqueue();
      await queue.flush();
      expect((await queue.watchDead().first).single.id, originalId);
      remote.failure = null;

      await repository.updateCaption(_photoId, 'Revised');
      await queue.flush();

      expect(await queue.watchDead().first, isEmpty);
      expect(pushedCaption(), 'Revised');
    },
    timeout: _timeout,
  );

  test(
    'a pending row with no queued write gets one',
    () async {
      useRemote(remote);
      await seed();
      queue.setPaused(true);

      await repository.updateCaption(_photoId, 'Revised');

      final row = (await queue.pendingRows()).single;
      expect(row.entityKey, checkInKey(_photoId));
      expect(row.kind, OutboxKind.upsertCheckIn.wire);
    },
    timeout: _timeout,
  );

  test(
    'uploaded caption updates only the caption, with blank sent as null',
    () async {
      useRemote(remote);
      await seed(uploaded: true);

      final updated = await repository.updateCaption(_photoId, ' \n ');

      expect(callsToCheckIns('update').single.args, {
        'values': {'caption': null},
        'match': {'id': _photoId},
      });
      expect(updated.caption, isNull);
      expect(updated.uploaded, isTrue);
      expect(await queue.pendingRows(), isEmpty);
    },
    timeout: _timeout,
  );

  for (final error in [
    OurneyErrorCode.offline,
    OurneyErrorCode.contentPolicy,
    OurneyErrorCode.forbidden,
  ]) {
    test(
      'a remote ${error.name} leaves the local caption and queue untouched',
      () async {
        useRemote(remote);
        await seed(uploaded: true);
        if (error == OurneyErrorCode.forbidden) {
          remote.updateResult = [];
        } else {
          remote.failure = OurneyException(error);
        }
        await expectLater(
          repository.updateCaption(_photoId, 'Revised'),
          throwsCode(error),
        );
        expect((await db.select(db.checkIns).getSingle()).caption, 'Original');
        expect(await queue.pendingRows(), isEmpty);
      },
      timeout: _timeout,
    );
  }

  test(
    'an upload that completes during the edit uses the remote update path',
    () async {
      final heldRemote = _HeldUploadRemote();
      remote = heldRemote;
      useRemote(remote);
      await seed();
      await enqueue();
      final upload = queue.flush();

      await heldRemote.uploadStarted.future;
      final edit = repository.updateCaption(_photoId, 'Revised');
      await queue.exclusiveRequested.future;
      heldRemote.finishUpload.complete();
      await upload;
      final updated = await edit;

      expect(pushedCaption(), 'Original');
      expect(callsToCheckIns('update').single.args, {
        'values': {'caption': 'Revised'},
        'match': {'id': _photoId},
      });
      expect(updated.uploaded, isTrue);
      expect(updated.caption, 'Revised');
      expect(await queue.pendingRows(), isEmpty);
    },
    timeout: _timeout,
  );

  test('local-only check-ins can be edited without a queue', () async {
    useRemote(null);
    await seed();
    final updated = await repository.updateCaption(_photoId, '  Revised  ');
    expect(updated.caption, 'Revised');
    expect(updated.uploaded, isFalse);
    expect((await db.select(db.checkIns).getSingle()).caption, 'Revised');
    final capped = await repository.updateCaption(_photoId, 'ả' * 141);
    expect(capped.caption, 'ả' * captionMax);
  }, timeout: _timeout);

  test('missing, foreign and moderated rows fail before any write', () async {
    useRemote(remote);
    await expectLater(
      repository.updateCaption(_photoId, 'Revised'),
      throwsCode(OurneyErrorCode.notFound),
    );
    await seed(author: 'another user');
    await expectLater(
      repository.updateCaption(_photoId, 'Revised'),
      throwsCode(OurneyErrorCode.forbidden),
    );
    await db.delete(db.checkIns).go();
    await seed(uploaded: true, moderated: true);
    await expectLater(
      repository.updateCaption(_photoId, 'Revised'),
      throwsCode(OurneyErrorCode.forbidden),
    );
    expect(remote.calls, isEmpty);
    expect(await queue.pendingRows(), isEmpty);
    expect((await db.select(db.checkIns).getSingle()).caption, 'Original');
  }, timeout: _timeout);
}
