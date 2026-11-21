import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart'
    show ValueNotifier, debugPrint, debugPrintStack;
import 'package:ourney_core/ourney_core.dart';

import '../../../shared/time_zones.dart';
import '../../checkin/photo_compressor.dart';
import 'import_files.dart';
import 'import_job.dart';
import 'import_job_store.dart';
import 'photo_dates.dart';

/// How one [ImportJobRunner.run] ended.
enum ImportRunEnd {
  /// Every photo was handled (some may be marked failed).
  finished,

  /// The person paused saving (at any step); the job waits for them.
  paused,

  /// Dropped: it no longer belongs to the signed-in account (another person
  /// signed in, or its rows are gone).
  discarded,

  /// Nobody is signed in (an expired session): the job stops where it is and
  /// is kept, for whoever started it.
  signedOut,

  /// The journey could not be created; the job keeps the reason.
  createFailed,
}

/// Logs why an import step failed: the error code, the raw detail and the
/// stack (the person only ever sees a generic message).
void logImportError(String what, Object error, StackTrace stack) {
  if (error is OurneyException) {
    debugPrint('import: $what: code=${error.code} detail=${error.detail}');
  } else {
    debugPrint('import: $what: ${error.runtimeType}: $error');
  }
  debugPrintStack(stackTrace: stack, maxFrames: 8);
}

class ImportRunResult {
  const ImportRunResult(this.end, {this.error});

  final ImportRunEnd end;
  final Object? error;
}

/// Runs import jobs: compress and copy every photo, create the journey with
/// the job's client id, then submit one check-in per photo with the photo's
/// own id. Every step is written to the [ImportJobStore] first, so a run that
/// is killed picks up where it stopped and never duplicates the journey or a
/// check-in (the server create and [CheckInDraft.id] are both idempotent).
///
/// A job belongs to the account that started it: before every step the runner
/// checks the signed-in user, and stops (dropping the job) when it changed.
class ImportJobRunner {
  ImportJobRunner({
    required this.store,
    required this.files,
    required this.currentUserId,
    required this.compress,
    required this.createJourney,
    required this.submit,
    required this.discardFiles,
    required this.now,
    this.onJourneyCreated,
    this.onFinished,
  });

  final ImportJobStore store;
  final ImportFiles files;

  /// The signed-in account (null: signed out).
  final String? Function() currentUserId;
  final Future<CompressedPhoto> Function(String sourcePath) compress;
  final Future<Journey> Function(ImportedJourneyDraft draft) createJourney;
  final Future<void> Function(CheckInDraft draft) submit;

  /// Deletes compressed copies (never throws).
  final Future<void> Function(Iterable<String> paths) discardFiles;
  final DateTime Function() now;
  final Future<void> Function(Journey journey)? onJourneyCreated;
  final Future<void> Function(ImportJob job)? onFinished;

  /// Ids of the jobs being run right now.
  final ValueNotifier<Set<String>> active = ValueNotifier(const {});
  final Set<String> _cancelled = {};

  bool isRunning(String jobId) => active.value.contains(jobId);

  void _setActive(String id, {required bool on}) {
    final next = {...active.value};
    on ? next.add(id) : next.remove(id);
    active.value = next;
  }

  /// Asks a running job to stop after the photo it is on.
  void cancel(String jobId) {
    if (isRunning(jobId)) _cancelled.add(jobId);
  }

  /// Job folders that must survive a sweep although their rows may be missing
  /// for a moment: a job being stored, or one reopened by "Edit details".
  final Set<String> _protected = {};

  /// Stores [job]. Its photos are moved into the job's folder one by one when
  /// the job runs (so progress shows and Pause works).
  Future<ImportJob> enqueue(ImportJob job) async {
    _protected.add(job.id);
    try {
      await store.create(job);
      return job;
    } on Object {
      await files.deleteJob(job.id);
      rethrow;
    } finally {
      // The rows protect it from here on.
      _protected.remove(job.id);
    }
  }

  /// "Edit details" is done with the folder of [jobId] (a new job took it over,
  /// or the flow closed).
  void release(String jobId) => _protected.remove(jobId);

  /// Finishes (or tidies) every stored job; called at app launch and when the
  /// signed-in account changes.
  Future<void> resumeAll() async {
    final me = currentUserId();
    if (me == null) return;
    for (final job in await store.unfinished()) {
      if (isRunning(job.id)) continue;
      if (job.ownerId != me) {
        // Another account's leftover: never run, never kept.
        await discard(job.id);
        continue;
      }
      if (job.phase == ImportPhase.preparing && job.pending == 0) {
        // Every photo failed before a journey existed: nothing to resume.
        await discard(job.id);
        continue;
      }
      if (job.phase == ImportPhase.done && job.complete) {
        await _remove(job);
      } else if (!job.paused &&
          (job.pending > 0 || job.phase == ImportPhase.creating)) {
        await run(job.id);
      }
    }
    await sweepOrphans();
  }

  /// Deletes job folders that no stored job (and no job being stored or
  /// reopened) owns. The stored ids are read again right here: a job stored
  /// since the start of a resume must not lose its files.
  Future<void> sweepOrphans() async {
    final stored = {for (final j in await store.unfinished()) j.id};
    await files.sweep({...stored, ..._protected});
  }

  Future<void> _remove(ImportJob job) async {
    await store.delete(job.id);
    await files.deleteJob(job.id);
  }

  /// Runs [jobId] from wherever it stopped (also clears a pause).
  Future<ImportRunResult> run(String jobId) async {
    if (isRunning(jobId)) return const ImportRunResult(ImportRunEnd.finished);
    _cancelled.remove(jobId);
    _setActive(jobId, on: true);
    try {
      return await _run(jobId);
    } finally {
      _cancelled.remove(jobId);
      _setActive(jobId, on: false);
    }
  }

  bool _stop(String id) => _cancelled.contains(id);

  /// The job if it is still this account's and still stored, else null.
  Future<ImportJob?> _own(String id, String owner) async {
    final me = currentUserId();
    if (me == null || me != owner) return null;
    final job = await store.get(id);
    return job?.ownerId == owner ? job : null;
  }

  /// The job is no longer ours to run. An expired session (nobody signed in)
  /// keeps it, for whoever started it; a different account, or deleted rows,
  /// drops it with its files.
  Future<ImportRunResult> _lost(String id, String owner) async {
    if (currentUserId() == null) {
      return const ImportRunResult(ImportRunEnd.signedOut);
    }
    await discard(id);
    return const ImportRunResult(ImportRunEnd.discarded);
  }

  Future<ImportRunResult> _run(String id) async {
    var job = await store.get(id);
    if (job == null) return const ImportRunResult(ImportRunEnd.finished);
    final owner = job.ownerId;
    if (await _own(id, owner) == null) return _lost(id, owner);
    if (job.paused) await store.setPaused(id, paused: false);

    if (job.phase == ImportPhase.preparing) {
      for (final photo in job.photos) {
        if (_stop(id)) return _pausePreparing(id);
        if (photo.state == ImportPhotoState.saved || photo.prepared) continue;
        if (photo.state == ImportPhotoState.failed &&
            photo.failure == ImportFailure.unreadable &&
            photo.sourcePath == null) {
          continue; // nothing to read
        }
        if (await _own(id, owner) == null) return _lost(id, owner);
        await _prepare(id, photo);
      }
      final now = await _own(id, owner);
      if (now == null) return _lost(id, owner);
      job = now;
      if (_stop(id)) return _pausePreparing(id);
      if (!job.photos.any((p) => p.prepared)) {
        // Nothing usable: the photos stay marked failed, no journey is made.
        return const ImportRunResult(ImportRunEnd.finished);
      }
      await store.setPhase(id, ImportPhase.creating);
      job = await store.get(id) ?? job;
    }

    if (job.phase == ImportPhase.creating) {
      if (await _own(id, owner) == null) return _lost(id, owner);
      await store.setCreateFailure(id, null);
      // A zone the database does not know is refused for good: say so without
      // asking the server (the person can not fix it by trying again).
      if (job.timezone.isNotEmpty && !isKnownTimeZone(job.timezone)) {
        await store.setCreateFailure(id, ImportFailure.invalid);
        return const ImportRunResult(
          ImportRunEnd.createFailed,
          error: OurneyException(OurneyErrorCode.invalid, 'timezone'),
        );
      }
      try {
        final journey = await createJourney(job.draft);
        await onJourneyCreated?.call(journey);
      } on Object catch (e, st) {
        logImportError('create journey failed', e, st);
        if (await _own(id, owner) == null) return _lost(id, owner);
        await store.setCreateFailure(id, _createFailureOf(e));
        return ImportRunResult(ImportRunEnd.createFailed, error: e);
      }
      await store.setPhase(id, ImportPhase.uploading);
      job = await store.get(id) ?? job;
    }

    if (job.phase == ImportPhase.uploading) {
      for (final photo in job.photos) {
        if (_stop(id)) {
          await store.setPaused(id, paused: true);
          return const ImportRunResult(ImportRunEnd.paused);
        }
        if (photo.state != ImportPhotoState.pending) continue;
        final current = await _own(id, owner);
        if (current == null) return _lost(id, owner);
        await _upload(current, photo);
      }
      if (await _own(id, owner) == null) return _lost(id, owner);
      await store.setPhase(id, ImportPhase.done);
      final done = await store.get(id);
      if (done != null) await onFinished?.call(done);
    }
    return const ImportRunResult(ImportRunEnd.finished);
  }

  /// A real pause while preparing: every picked file that is not in the job
  /// folder yet is moved there first (cheap: renames), so the screen closing
  /// afterwards can not strand the job. Compression waits for Continue.
  Future<ImportRunResult> _pausePreparing(String id) async {
    final job = await store.get(id);
    if (job != null) {
      for (final photo in job.photos) {
        final picked = photo.sourcePath;
        if (picked == null || photo.state == ImportPhotoState.saved) continue;
        try {
          final kept = await files.keep(id, photo.id, picked);
          if (kept != picked) {
            await store.updatePhoto(id, photo.id, sourcePath: kept);
          }
        } on Object catch (e, st) {
          logImportError('cannot keep ${photo.id}', e, st);
          await store.updatePhoto(
            id,
            photo.id,
            state: ImportPhotoState.failed,
            failure: ImportFailure.unreadable,
          );
        }
      }
    }
    await store.setPaused(id, paused: true);
    return const ImportRunResult(ImportRunEnd.paused);
  }

  /// Moves [photo]'s picked file into the job folder, then compresses it.
  /// A file that is gone or unreadable marks only this photo failed.
  Future<ImportJobPhoto> _prepare(String jobId, ImportJobPhoto photo) async {
    try {
      final picked = photo.sourcePath;
      if (picked == null) throw const PhotoCompressException('no source');
      final source = await files.keep(jobId, photo.id, picked);
      if (source != picked) {
        await store.updatePhoto(jobId, photo.id, sourcePath: source);
      }
      final out = await compress(source);
      await store.updatePhoto(
        jobId,
        photo.id,
        photoFile: out.photoFile,
        thumbFile: out.thumbFile,
        clearFailure: true,
      );
      return ImportJobPhoto(
        id: photo.id,
        position: photo.position,
        date: photo.date,
        secondsOfDay: photo.secondsOfDay,
        offsetMinutes: photo.offsetMinutes,
        dedupeKey: photo.dedupeKey,
        sourcePath: source,
        photoFile: out.photoFile,
        thumbFile: out.thumbFile,
      );
    } on Object catch (e, st) {
      logImportError('cannot prepare ${photo.id}', e, st);
      await store.updatePhoto(
        jobId,
        photo.id,
        state: ImportPhotoState.failed,
        failure: ImportFailure.unreadable,
      );
      return photo;
    }
  }

  Future<void> _upload(ImportJob job, ImportJobPhoto photo) async {
    var current = photo;
    if (!current.prepared) {
      current = await _prepare(job.id, photo);
      if (!current.prepared) return;
    }
    try {
      await submit(
        CheckInDraft(
          id: current.id,
          journeyId: job.id,
          capturedAt: importCapturedAt(
            date: current.date,
            secondsOfDay: current.secondsOfDay,
            offsetMinutes: current.offsetMinutes,
            timezone: job.timezone,
            now: now(),
            position: current.position,
          ),
          photoFile: current.photoFile!,
          thumbFile: current.thumbFile!,
          fromLibrary: true,
        ),
      );
      await store.updatePhoto(
        job.id,
        current.id,
        state: ImportPhotoState.saved,
        clearFailure: true,
        clearFiles: true,
        clearSource: true,
      );
    } on Object catch (e, st) {
      logImportError('photo ${current.id} failed', e, st);
      await store.updatePhoto(
        job.id,
        current.id,
        state: ImportPhotoState.failed,
        failure: _failureOf(e),
      );
      return;
    }
    // Saved: the compressed copies and the kept original are not needed. A
    // failed photo keeps them for the retry.
    await discardFiles([
      current.photoFile!,
      current.thumbFile!,
      ?current.sourcePath,
    ]);
  }

  ImportFailure _failureOf(Object e) => switch (e) {
    OurneyException(error: OurneyErrorCode.offline) => ImportFailure.offline,
    OurneyException(error: OurneyErrorCode.invalidCapturedAt) =>
      ImportFailure.badDate,
    PhotoCompressException() ||
    FileSystemException() => ImportFailure.unreadable,
    SocketException() => ImportFailure.offline,
    _ => ImportFailure.unknown,
  };

  ImportFailure _createFailureOf(Object e) => switch (e) {
    OurneyException(error: OurneyErrorCode.offline) => ImportFailure.offline,
    // Permanent refusals: trying again cannot change the answer.
    OurneyException(
      error: OurneyErrorCode.invalid ||
          OurneyErrorCode.invalidCapturedAt ||
          OurneyErrorCode.forbidden,
    ) =>
      ImportFailure.invalid,
    SocketException() => ImportFailure.offline,
    _ => ImportFailure.unknown,
  };

  /// Marks the failed photos pending again and runs the job.
  Future<ImportRunResult> retryFailed(String jobId) async {
    final job = await store.get(jobId);
    if (job == null) return const ImportRunResult(ImportRunEnd.finished);
    for (final p in job.photos) {
      if (p.state == ImportPhotoState.failed) {
        await store.updatePhoto(
          jobId,
          p.id,
          state: ImportPhotoState.pending,
          clearFailure: true,
        );
      }
    }
    // A journey that already exists goes straight back to the uploads.
    if (job.phase == ImportPhase.done) {
      await store.setPhase(jobId, ImportPhase.uploading);
    }
    return run(jobId);
  }

  /// Drops the job's rows and every file it owns (photos already saved stay
  /// in the journey). The picker's own files are never touched.
  Future<void> discard(String jobId) async {
    final job = await store.get(jobId);
    if (job != null) {
      await discardFiles([
        for (final p in job.photos) ...[?p.photoFile, ?p.thumbFile],
      ]);
      await store.delete(jobId);
    }
    _protected.remove(jobId);
    await files.deleteJob(jobId);
  }

  /// Drops the job's rows and compressed copies but keeps the kept originals,
  /// so the flow can show them again ("Edit details") and save under the same
  /// ids. Returns the job as it was.
  Future<ImportJob?> reopen(String jobId) async {
    final job = await store.get(jobId);
    if (job == null) return null;
    // Protect the folder first: between the delete and the next store it has
    // no rows, and a sweep must not take it.
    _protected.add(jobId);
    await discardFiles([
      for (final p in job.photos) ...[?p.photoFile, ?p.thumbFile],
    ]);
    await store.delete(jobId);
    return job;
  }
}
