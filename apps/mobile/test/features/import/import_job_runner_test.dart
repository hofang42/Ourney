import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/data/db/app_database.dart';
import 'package:ourney/features/checkin/photo_compressor.dart';
import 'package:ourney/features/import/data/import_draft.dart';
import 'package:ourney/features/import/data/import_files.dart';
import 'package:ourney/features/import/data/import_job.dart';
import 'package:ourney/features/import/data/import_job_runner.dart';
import 'package:ourney/features/import/data/import_job_store.dart';
import 'package:ourney/features/import/data/import_types.dart';
import 'package:ourney_core/ourney_core.dart';

import '../journeys/journeys_fakes.dart' show testNow, testTz;

/// What the server holds: journeys by id and check-ins by id, so a repeated
/// id is a no-op exactly like the real (idempotent) repositories. Files are
/// real (a temp dir) and deleted by the real [LocalDraftFiles], so a runner
/// that deleted the picker's originals would show here.
class Env {
  Env(this.tmp)
    : picker = Directory('${tmp.path}/picker')..createSync(),
      jobs = Directory('${tmp.path}/jobs')..createSync(),
      compressed = Directory('${tmp.path}/compressed')..createSync();

  final Directory tmp;
  final Directory picker;
  final Directory jobs;
  final Directory compressed;

  final Map<String, ImportedJourneyDraft> journeys = {};
  final Map<String, CheckInDraft> checkIns = {};
  int createCalls = 0;
  int submitCalls = 0;
  final Set<String> failPhotos = {};

  /// Completes when a held create / submit has been reached (real IO runs in
  /// between, so a test waits for this instead of pumping).
  Completer<void> reached = Completer<void>();
  Completer<void>? holdCreate;
  Completer<void>? holdSubmit;
  String? holdOnPhoto;
  Object failure = const OurneyException(OurneyErrorCode.offline);
  Object? createFailure;
  String? signedIn = 'u1';
  bool policyPaused = false;

  /// Where the "OS temp dir" is: elsewhere, so picked files are copied.
  late final Directory osTemp = Directory('${tmp.path}/os_temp')..createSync();

  /// Copy mode (the picker's files are not in the temp dir).
  late final ImportFiles files = LocalImportFiles(
    rootOf: () async => jobs,
    tempOf: () async => osTemp,
  );

  /// Move mode: the picker's folder is the temp dir.
  late final ImportFiles movingFiles = LocalImportFiles(
    rootOf: () async => jobs,
    tempOf: () async => picker,
  );

  /// A real picked file.
  String original(String name) {
    final f = File('${picker.path}/$name.jpg')..writeAsBytesSync([1, 2, 3]);
    return f.path;
  }

  bool exists(String path) => File(path).existsSync();

  ImportJobRunner runner(ImportJobStore store, {ImportFiles? with_}) =>
      ImportJobRunner(
        store: store,
        files: with_ ?? files,
        currentUserId: () => signedIn,
        now: () => testNow,
        policyPaused: () => policyPaused,
        compress: (src) async {
          final name = src.split(RegExp(r'[\\/]')).last;
          final photo = File('${compressed.path}/$name.c')
            ..writeAsBytesSync([9]);
          final thumb = File('${compressed.path}/$name.t')
            ..writeAsBytesSync([8]);
          return CompressedPhoto(photoFile: photo.path, thumbFile: thumb.path);
        },
        createJourney: (draft) async {
          createCalls++;
          if (holdCreate != null) {
            reached.complete();
            await holdCreate!.future;
          }
          final fail = createFailure;
          if (fail != null) throw fail;
          journeys.putIfAbsent(draft.id, () => draft);
          return Journey(
            id: draft.id,
            ownerId: 'u1',
            kind: JourneyKind.solo,
            templateId: draft.templateId,
            title: draft.title,
            emoji: draft.emoji,
            startDate: draft.firstDate,
            timezone: draft.timezone,
            visibility: JourneyVisibility.private,
            status: JourneyStatus.ended,
          );
        },
        submit: (d) async {
          submitCalls++;
          if (d.id == holdOnPhoto) {
            reached.complete();
            await holdSubmit!.future;
          }
          if (failPhotos.contains(d.id)) throw failure;
          checkIns.putIfAbsent(d.id!, () => d);
        },
        discardFiles: LocalDraftFiles(rootsOf: () async => [tmp.path]).discard,
      );

  /// A job of [photos] photos on 1, 2, 3... Feb 2024, ids `<id>-ph<i>`.
  ImportJob job(
    String id, {
    int photos = 4,
    String owner = 'u1',
    String timezone = testTz,
  }) => buildImportJob(
    id: id,
    ownerId: owner,
    title: 'Hoi An',
    type: importTypes.firstWhere((t) => t.id == 'trip'),
    layout: 'memory',
    continues: false,
    timezone: timezone,
    now: testNow,
    photos: [
      for (var i = 0; i < photos; i++)
        DraftPhoto(
          id: '$id-ph$i',
          path: original('$id-src$i'),
          dedupeKey: '$id-k$i',
          order: i,
          date: LocalDate(2024, 2, 1 + i),
        ),
    ],
  );

  Directory jobDir(String id) => Directory('${jobs.path}/$id');
}

void main() {
  late AppDatabase db;
  late ImportJobStore store;
  late Env env;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    store = DriftImportJobStore(db);
    final tmp = Directory.systemTemp.createTempSync('ourney_import_test');
    addTearDown(() {
      if (tmp.existsSync()) tmp.deleteSync(recursive: true);
    });
    env = Env(tmp);
  });

  test('the run keeps app-owned copies of the picked photos', () async {
    final job = env.job('j1', photos: 2);
    final runner = env.runner(store);
    await runner.enqueue(job);
    env.holdCreate = Completer<void>();
    unawaited(runner.run('j1'));
    await env.reached.future;
    final kept = (await store.get('j1'))!;
    for (final p in kept.photos) {
      expect(p.sourcePath, startsWith(env.jobs.path));
      expect(env.exists(p.sourcePath!), isTrue);
    }
    // Copy mode: the picker's originals are untouched.
    expect(env.exists(job.photos.first.sourcePath!), isTrue);
  });

  test('a picker temp file is moved, not copied', () async {
    final job = env.job('j1', photos: 2);
    final runner = env.runner(store, with_: env.movingFiles);
    await runner.enqueue(job);
    env.createFailure = const OurneyException(OurneyErrorCode.offline);
    await runner.run('j1');
    final kept = (await store.get('j1'))!;
    for (var i = 0; i < 2; i++) {
      expect(env.exists(kept.photos[i].sourcePath!), isTrue);
      expect(
        env.exists(job.photos[i].sourcePath!),
        isFalse,
        reason: 'one copy on disk, not two',
      );
    }
  });

  test('a missing picked file fails only that photo', () async {
    final job = env.job('j1', photos: 3);
    File(job.photos[1].sourcePath!).deleteSync();
    await env.runner(store).enqueue(job);
    await env.runner(store).run('j1');
    final saved = (await store.get('j1'))!;
    expect(saved.saved, 2);
    expect(saved.photos[1].state, ImportPhotoState.failed);
    expect(saved.photos[1].failure, ImportFailure.unreadable);
    expect(env.checkIns.keys, ['j1-ph0', 'j1-ph2']);
  });

  test(
    'a full run saves every photo, cleans up, keeps the originals',
    () async {
      final job = env.job('j1');
      await env.runner(store).enqueue(job);
      final res = await env.runner(store).run('j1');
      expect(res.end, ImportRunEnd.finished);
      final saved = (await store.get('j1'))!;
      expect(saved.phase, ImportPhase.done);
      expect(saved.complete, isTrue);
      expect(env.checkIns.keys, ['j1-ph0', 'j1-ph1', 'j1-ph2', 'j1-ph3']);
      expect(env.checkIns['j1-ph0']!.fromLibrary, isTrue);
      // Compressed copies and kept originals are deleted once saved (M10)...
      expect(env.compressed.listSync(), isEmpty);
      expect(env.jobDir('j1').listSync(), isEmpty);
      // ...and the picker's own files are never touched.
      for (final p in job.photos) {
        expect(env.exists(p.sourcePath!), isTrue);
      }
    },
  );

  test('killed mid-upload: the resume finishes without duplicates', () async {
    await env.runner(store).enqueue(env.job('j1'));
    env
      ..holdOnPhoto = 'j1-ph2'
      ..holdSubmit = Completer<void>();
    // This run never returns: the app was killed while photo 3 was on it.
    unawaited(env.runner(store).run('j1'));
    await env.reached.future;
    expect(env.checkIns.keys, ['j1-ph0', 'j1-ph1']);
    expect((await store.get('j1'))!.phase, ImportPhase.uploading);

    // Next launch: a new runner over the same database.
    env.holdOnPhoto = null;
    await env.runner(store).resumeAll();
    expect(env.checkIns.keys, ['j1-ph0', 'j1-ph1', 'j1-ph2', 'j1-ph3']);
    expect(env.journeys, hasLength(1));
    expect(env.createCalls, 1);
    // Photos 1-2 were saved; the one in flight and the last went out again.
    expect(env.submitCalls, 3 + 2);
    expect((await store.get('j1'))!.complete, isTrue);
  });

  test('forced gate leaves an interrupted import ready to resume', () async {
    final runner = env.runner(store);
    await runner.enqueue(env.job('j1', photos: 2));
    env
      ..holdOnPhoto = 'j1-ph0'
      ..holdSubmit = Completer<void>();
    final run = runner.resumeAll();
    await env.reached.future;
    env.policyPaused = true;
    env.failPhotos.add('j1-ph0');
    env.holdSubmit!.complete();
    await run;
    expect(env.submitCalls, 1);
    final job = (await store.get('j1'))!;
    expect(job.paused, isFalse);
    expect(job.pending, 2);

    env.policyPaused = false;
    env.holdOnPhoto = null;
    env.failPhotos.clear();
    await runner.resumeAll();
    expect((await store.get('j1'))!.complete, isTrue);
    expect(env.checkIns.keys, ['j1-ph0', 'j1-ph1']);
    expect(env.createCalls, 1);
  });

  test('killed while creating: the same journey id is sent again', () async {
    await env.runner(store).enqueue(env.job('j1'));
    env.holdCreate = Completer<void>();
    unawaited(env.runner(store).run('j1'));
    await env.reached.future;
    expect((await store.get('j1'))!.phase, ImportPhase.creating);
    expect(env.journeys, isEmpty);

    env.holdCreate = null;
    await env.runner(store).resumeAll();
    expect(env.journeys.keys, ['j1']);
    expect(env.checkIns, hasLength(4));
  });

  test('a check-in that landed but was not marked is not doubled', () async {
    await env.runner(store).enqueue(env.job('j1', photos: 2));
    env.checkIns['j1-ph0'] = CheckInDraft(
      id: 'j1-ph0',
      journeyId: 'j1',
      capturedAt: testNow,
      photoFile: 'x',
      thumbFile: 'y',
    );
    await env.runner(store).run('j1');
    expect(env.checkIns.keys, ['j1-ph0', 'j1-ph1']);
  });

  test('one failure keeps its reason; retry sends only that photo', () async {
    await env.runner(store).enqueue(env.job('j1'));
    env.failPhotos.add('j1-ph1');
    final runner = env.runner(store);
    await runner.run('j1');
    var saved = (await store.get('j1'))!;
    expect(saved.saved, 3);
    expect(saved.failed, 1);
    final failed = saved.photos.firstWhere((p) => p.id == 'j1-ph1');
    expect(failed.failure, ImportFailure.offline);
    // The compressed copies and the kept original stay for the retry.
    expect(env.exists(failed.photoFile!), isTrue);
    expect(env.exists(failed.sourcePath!), isTrue);

    env.failPhotos.clear();
    final before = env.submitCalls;
    await runner.retryFailed('j1');
    expect(env.submitCalls, before + 1);
    saved = (await store.get('j1'))!;
    expect(saved.complete, isTrue);
    expect(env.checkIns, hasLength(4));
  });

  test('a refused date is reported as such', () async {
    await env.runner(store).enqueue(env.job('j1', photos: 1));
    env
      ..failPhotos.add('j1-ph0')
      ..failure = const OurneyException(OurneyErrorCode.invalidCapturedAt);
    await env.runner(store).run('j1');
    expect(
      (await store.get('j1'))!.photos.single.failure,
      ImportFailure.badDate,
    );
  });

  test('pausing while preparing keeps the job and its files', () async {
    final job = env.job('j1');
    final runner = env.runner(store);
    await runner.enqueue(job);
    final run = runner.run('j1');
    runner.cancel('j1');
    final res = await run;
    expect(res.end, ImportRunEnd.paused);
    final j = (await store.get('j1'))!;
    expect(j.paused, isTrue);
    expect(env.journeys, isEmpty);
    // The flow still shows these photos: they must exist (H1).
    for (final p in job.photos) {
      expect(env.exists(p.sourcePath!), isTrue);
    }
    // The launch resume leaves it; Continue finishes it.
    await env.runner(store).resumeAll();
    expect(env.journeys, isEmpty);
    await runner.run('j1');
    expect((await store.get('j1'))!.complete, isTrue);
  });

  test('pause while preparing, close the screen, Continue saves all', () async {
    final job = env.job('j1');
    final runner = env.runner(store, with_: env.movingFiles);
    await runner.enqueue(job);
    final run = runner.run('j1');
    runner.cancel('j1');
    expect((await run).end, ImportRunEnd.paused);
    // Every picked file is already in the job folder...
    final paused = (await store.get('j1'))!;
    for (final p in paused.photos) {
      expect(p.sourcePath, startsWith(env.jobs.path));
      expect(env.exists(p.sourcePath!), isTrue);
    }
    // ...so the screen closing and tidying the picker's files strands nothing.
    for (final p in job.photos) {
      final f = File(p.sourcePath!);
      if (f.existsSync()) f.deleteSync();
    }
    await runner.run('j1');
    final done = (await store.get('j1'))!;
    expect(done.complete, isTrue);
    expect(env.checkIns, hasLength(4));
  });

  test('permanent refusals are marked invalid, so Edit is offered', () async {
    await env.runner(store).enqueue(env.job('j1', photos: 1));
    env.createFailure = const OurneyException(OurneyErrorCode.forbidden);
    await env.runner(store).run('j1');
    expect((await store.get('j1'))!.createFailure, ImportFailure.invalid);
  });

  test('an unknown time zone is refused without asking the server', () async {
    await env
        .runner(store)
        .enqueue(env.job('j1', photos: 1, timezone: 'Mars/Phobos'));
    final res = await env.runner(store).run('j1');
    expect(res.end, ImportRunEnd.createFailed);
    expect(env.createCalls, 0);
    expect((await store.get('j1'))!.createFailure, ImportFailure.invalid);
  });

  test('pausing during upload sticks: the launch resume leaves it', () async {
    await env.runner(store).enqueue(env.job('j1'));
    env
      ..holdOnPhoto = 'j1-ph1'
      ..holdSubmit = Completer<void>();
    final runner = env.runner(store);
    final run = runner.run('j1');
    await env.reached.future;
    runner.cancel('j1');
    env.holdSubmit!.complete();
    final res = await run;
    expect(res.end, ImportRunEnd.paused);
    var saved = (await store.get('j1'))!;
    expect(saved.paused, isTrue);
    expect(saved.saved, 2);

    env.holdOnPhoto = null;
    final calls = env.submitCalls;
    await env.runner(store).resumeAll();
    expect(env.submitCalls, calls, reason: 'a paused job is not continued');

    // The person continues from the flow.
    await env.runner(store).run('j1');
    saved = (await store.get('j1'))!;
    expect(saved.paused, isFalse);
    expect(saved.complete, isTrue);
  });

  test('a failed create is stored on the job and cleared on success', () async {
    await env.runner(store).enqueue(env.job('j1', photos: 1));
    env.createFailure = const OurneyException(OurneyErrorCode.offline);
    final res = await env.runner(store).run('j1');
    expect(res.end, ImportRunEnd.createFailed);
    var j = (await store.get('j1'))!;
    expect(j.phase, ImportPhase.creating);
    expect(j.createFailure, ImportFailure.offline);

    env
      ..createFailure = const OurneyException(OurneyErrorCode.invalid)
      ..createCalls = 0;
    await env.runner(store).run('j1');
    expect((await store.get('j1'))!.createFailure, ImportFailure.invalid);

    env.createFailure = null;
    await env.runner(store).run('j1');
    j = (await store.get('j1'))!;
    expect(j.createFailure, isNull);
    expect(j.complete, isTrue);
  });

  test(
    'an unreadable photo is marked failed and the rest still save',
    () async {
      final job = env.job('j1', photos: 2);
      await env.runner(store).enqueue(job);
      final good = env.runner(store);
      final runner = ImportJobRunner(
        store: store,
        files: env.files,
        currentUserId: () => 'u1',
        now: () => testNow,
        compress: (s) async {
          if (s.contains('j1-ph0')) throw const PhotoCompressException('photo');
          return good.compress(s);
        },
        createJourney: good.createJourney,
        submit: good.submit,
        discardFiles: good.discardFiles,
      );
      await runner.run('j1');
      final saved = (await store.get('j1'))!;
      expect(saved.photos.first.failure, ImportFailure.unreadable);
      expect(saved.saved, 1);
    },
  );

  test('the journey dates span the photos that can still be saved', () async {
    final job = env.job('j1', photos: 3);
    final base = job.draft;
    expect(base.firstDate, const LocalDate(2024, 2, 1));
    final failedFirst = ImportJob(
      id: job.id,
      title: job.title,
      emoji: job.emoji,
      templateId: job.templateId,
      firstDate: job.firstDate,
      lastDate: job.lastDate,
      timezone: job.timezone,
      createdAt: job.createdAt,
      ownerId: job.ownerId,
      photos: [
        for (final p in job.photos)
          ImportJobPhoto(
            id: p.id,
            position: p.position,
            date: p.date,
            secondsOfDay: p.secondsOfDay,
            state: p.position == 0
                ? ImportPhotoState.failed
                : ImportPhotoState.pending,
          ),
      ],
    );
    expect(failedFirst.draft.firstDate, const LocalDate(2024, 2, 2));
    expect(failedFirst.draft.lastDate, const LocalDate(2024, 2, 3));
  });

  group('resumeAll tidies', () {
    test(
      'finished jobs go, failures stay, other jobs keep their ids',
      () async {
        await env.runner(store).enqueue(env.job('done', photos: 1));
        await env.runner(store).run('done');
        await env.runner(store).enqueue(env.job('bad', photos: 1));
        env.failPhotos.add('bad-ph0');
        await env.runner(store).run('bad');
        await env.runner(store).resumeAll();
        expect(await store.get('done'), isNull);
        expect((await store.get('bad'))!.failed, 1);
        // Distinct photo ids per job.
        expect(env.checkIns.keys, ['done-ph0']);
      },
    );

    test('a job whose photos all failed before a journey is dropped', () async {
      final job = env.job('j1', photos: 2);
      await env.runner(store).enqueue(job);
      final good = env.runner(store);
      final broken = ImportJobRunner(
        store: store,
        files: env.files,
        currentUserId: () => 'u1',
        now: () => testNow,
        compress: (_) async => throw const PhotoCompressException('x'),
        createJourney: good.createJourney,
        submit: good.submit,
        discardFiles: good.discardFiles,
      );
      await broken.run('j1');
      final j = (await store.get('j1'))!;
      expect(j.phase, ImportPhase.preparing);
      expect(j.failed, 2);
      expect(env.journeys, isEmpty);

      await env.runner(store).resumeAll();
      expect(await store.get('j1'), isNull);
      expect(env.jobDir('j1').existsSync(), isFalse);
    });

    test('another account\'s job is deleted, never run', () async {
      await env.runner(store).enqueue(env.job('theirs', owner: 'u2'));
      await env.runner(store).enqueue(env.job('mine', photos: 1));
      await env.runner(store).resumeAll();
      expect(await store.get('theirs'), isNull);
      expect(env.jobDir('theirs').existsSync(), isFalse);
      expect(env.checkIns.keys, ['mine-ph0']);
      expect(env.journeys.keys, ['mine']);
    });

    test('nothing runs while signed out', () async {
      await env.runner(store).enqueue(env.job('j1', photos: 1));
      env.signedIn = null;
      await env.runner(store).resumeAll();
      expect(env.submitCalls, 0);
      expect(await store.get('j1'), isNotNull);
    });

    test('leftover folders of jobs without rows are swept', () async {
      await env.runner(store).enqueue(env.job('mine', photos: 1));
      // A wipe deleted the rows of another account's job, not its files.
      Directory('${env.jobs.path}/ghost').createSync();
      File('${env.jobs.path}/ghost/x.jpg').writeAsBytesSync([1]);
      env.signedIn = 'u1';
      await env.runner(store).resumeAll();
      expect(env.jobDir('ghost').existsSync(), isFalse);
    });
  });

  test('the job stops once the account changes mid-run', () async {
    await env.runner(store).enqueue(env.job('j1'));
    env
      ..holdOnPhoto = 'j1-ph1'
      ..holdSubmit = Completer<void>();
    final run = env.runner(store).run('j1');
    await env.reached.future;
    expect(env.checkIns.keys, ['j1-ph0']);

    // Another account signs in while photo 2 is on its way.
    env.signedIn = 'u2';
    env.holdSubmit!.complete();
    final res = await run;
    expect(res.end, ImportRunEnd.discarded);
    expect(env.checkIns.keys, ['j1-ph0', 'j1-ph1'], reason: 'in flight only');
    expect(await store.get('j1'), isNull);
    expect(env.jobDir('j1').existsSync(), isFalse);
  });

  test('wiping the rows mid-run stops the job too', () async {
    await env.runner(store).enqueue(env.job('j1'));
    env
      ..holdOnPhoto = 'j1-ph1'
      ..holdSubmit = Completer<void>();
    final run = env.runner(store).run('j1');
    await env.reached.future;
    await db.wipe(); // ensureOwner: another user's cache is cleared
    env.holdSubmit!.complete();
    final res = await run;
    expect(res.end, ImportRunEnd.discarded);
    expect(env.checkIns.keys, ['j1-ph0', 'j1-ph1']);
  });

  test('reopening keeps the kept copies and drops the rows', () async {
    final runner = env.runner(store);
    await runner.enqueue(env.job('j1', photos: 2));
    env.createFailure = const OurneyException(OurneyErrorCode.offline);
    await runner.run('j1');
    final before = (await store.get('j1'))!;
    final reopened = await runner.reopen('j1');
    expect(reopened!.photos, hasLength(2));
    expect(await store.get('j1'), isNull);
    for (final p in before.photos) {
      expect(env.exists(p.sourcePath!), isTrue);
    }
  });

  test('sweeping keeps stored and held folders, drops the rest', () async {
    final runner = env.runner(store);
    await runner.enqueue(env.job('stored', photos: 1));
    await runner.enqueue(env.job('held', photos: 1));
    env.createFailure = const OurneyException(OurneyErrorCode.offline);
    await runner.run('stored');
    await runner.run('held');
    await runner.reopen('held'); // rows gone, folder protected
    Directory('${env.jobs.path}/ghost').createSync();

    await runner.sweepOrphans();
    expect(env.jobDir('stored').existsSync(), isTrue);
    expect(env.jobDir('held').existsSync(), isTrue);
    expect(env.jobDir('ghost').existsSync(), isFalse);

    runner.release('held');
    await runner.sweepOrphans();
    expect(env.jobDir('held').existsSync(), isFalse);
    expect(env.jobDir('stored').existsSync(), isTrue);
  });

  test('an expired session stops the job but keeps it and its files', () async {
    await env.runner(store).enqueue(env.job('j1'));
    env
      ..holdOnPhoto = 'j1-ph1'
      ..holdSubmit = Completer<void>();
    final run = env.runner(store).run('j1');
    await env.reached.future;
    env.signedIn = null; // the session expired
    env.holdSubmit!.complete();
    final res = await run;
    expect(res.end, ImportRunEnd.signedOut);
    expect(await store.get('j1'), isNotNull);
    final kept = (await store.get('j1'))!;
    expect(
      kept.photos
          .where((p) => p.state == ImportPhotoState.pending)
          .every((p) => env.exists(p.sourcePath ?? p.photoFile!)),
      isTrue,
    );
    // A reset sweep does not delete files of a job whose rows survive.
    await env.runner(store).sweepOrphans();
    expect(env.jobDir('j1').existsSync(), isTrue);

    // The same person signs in again: the job finishes.
    env
      ..signedIn = 'u1'
      ..holdOnPhoto = null;
    await env.runner(store).resumeAll();
    expect((await store.get('j1'))!.complete, isTrue);
  });

  test('the database keeps the whole job', () async {
    await env.runner(store).enqueue(env.job('j1', photos: 2));
    await store.setPaused('j1', paused: true);
    await store.setCreateFailure('j1', ImportFailure.invalid);
    final j = (await store.get('j1'))!;
    expect(j.title, 'Hoi An');
    expect(j.ownerId, 'u1');
    expect(j.paused, isTrue);
    expect(j.createFailure, ImportFailure.invalid);
    expect(j.firstDate, const LocalDate(2024, 2, 1));
    expect(j.photos.map((p) => p.position), [0, 1]);
    expect(j.photos.first.dedupeKey, 'j1-k0');
    expect((await store.unfinished()).single.id, 'j1');
    await store.delete('j1');
    expect(await store.get('j1'), isNull);
  });
}
