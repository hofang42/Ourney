import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../data/db/app_database.dart';
import 'import_job.dart';

/// Durable home of import jobs: a job survives the app being killed, so the
/// photos and the journey are finished (or retried) at the next launch.
abstract interface class ImportJobStore {
  /// Saves a new job with all its photos.
  Future<void> create(ImportJob job);

  Future<ImportJob?> get(String id);

  /// Every job still stored (not yet fully saved and left), oldest first.
  Future<List<ImportJob>> unfinished();

  /// Emits the job on every change (null once deleted).
  Stream<ImportJob?> watch(String id);

  Future<void> setPhase(String id, ImportPhase phase);

  Future<void> setPaused(String id, {required bool paused});

  /// Records why creating the journey failed (null clears it).
  Future<void> setCreateFailure(String id, ImportFailure? failure);

  /// Updates one photo. [photoFile]/[thumbFile] set the prepared files;
  /// [clearSource] forgets the picked original once it is no longer needed.
  Future<void> updatePhoto(
    String jobId,
    String photoId, {
    ImportPhotoState? state,
    ImportFailure? failure,
    bool clearFailure = false,
    String? photoFile,
    String? thumbFile,
    bool clearFiles = false,
    bool clearSource = false,
    String? sourcePath,
  });

  /// Removes the job and its photo rows.
  Future<void> delete(String id);
}

final importJobStoreProvider = Provider<ImportJobStore>(
  (ref) => throw UnimplementedError(
    'importJobStoreProvider is overridden by dataOverrides().',
  ),
);

class DriftImportJobStore implements ImportJobStore {
  DriftImportJobStore(this._db);

  final AppDatabase _db;

  @override
  Future<void> create(ImportJob job) => _db.transaction(() async {
    await _db
        .into(_db.importJobs)
        .insert(
          ImportJobsCompanion.insert(
            id: job.id,
            title: job.title,
            emoji: job.emoji,
            templateId: job.templateId.wireName,
            layout: Value(job.layout?.wireName),
            startDate: job.firstDate,
            endDate: job.lastDate,
            timezone: job.timezone,
            continues: Value(job.continues),
            phase: job.phase.wire,
            ownerId: job.ownerId,
            paused: Value(job.paused),
            createFailure: Value(job.createFailure?.wire),
            createdAt: job.createdAt,
          ),
          mode: InsertMode.insertOrReplace,
        );
    for (final p in job.photos) {
      await _db
          .into(_db.importJobPhotos)
          .insert(
            ImportJobPhotosCompanion.insert(
              id: p.id,
              jobId: job.id,
              position: p.position,
              sourcePath: Value(p.sourcePath),
              photoFile: Value(p.photoFile),
              thumbFile: Value(p.thumbFile),
              localDate: p.date,
              secondsOfDay: p.secondsOfDay,
              offsetMinutes: Value(p.offsetMinutes),
              dedupeKey: Value(p.dedupeKey),
              state: p.state.wire,
              failure: Value(p.failure?.wire),
            ),
            mode: InsertMode.insertOrReplace,
          );
    }
  });

  Future<ImportJob?> _load(ImportJobRow? row) async {
    if (row == null) return null;
    final photos =
        await (_db.select(_db.importJobPhotos)
              ..where((t) => t.jobId.equals(row.id))
              ..orderBy([(t) => OrderingTerm.asc(t.position)]))
            .get();
    return ImportJob(
      id: row.id,
      title: row.title,
      emoji: row.emoji,
      templateId: TemplateId.fromWire(row.templateId),
      firstDate: row.startDate,
      lastDate: row.endDate,
      timezone: row.timezone,
      layout: row.layout == null ? null : PersonaSkinId.fromWire(row.layout!),
      continues: row.continues,
      phase: ImportPhase.fromWire(row.phase),
      ownerId: row.ownerId,
      paused: row.paused,
      createFailure: ImportFailure.fromWire(row.createFailure),
      createdAt: row.createdAt,
      photos: [
        for (final p in photos)
          ImportJobPhoto(
            id: p.id,
            position: p.position,
            sourcePath: p.sourcePath,
            photoFile: p.photoFile,
            thumbFile: p.thumbFile,
            date: p.localDate,
            secondsOfDay: p.secondsOfDay,
            offsetMinutes: p.offsetMinutes,
            dedupeKey: p.dedupeKey,
            state: ImportPhotoState.fromWire(p.state),
            failure: ImportFailure.fromWire(p.failure),
          ),
      ],
    );
  }

  @override
  Future<ImportJob?> get(String id) async => _load(
    await (_db.select(
      _db.importJobs,
    )..where((t) => t.id.equals(id))).getSingleOrNull(),
  );

  @override
  Future<List<ImportJob>> unfinished() async {
    final rows = await (_db.select(
      _db.importJobs,
    )..orderBy([(t) => OrderingTerm.asc(t.createdAt)])).get();
    return [for (final r in rows) ?await _load(r)];
  }

  @override
  Stream<ImportJob?> watch(String id) {
    // Re-reads the whole job when either table changes.
    return _db
        .customSelect(
          'SELECT 1',
          readsFrom: {_db.importJobs, _db.importJobPhotos},
        )
        .watch()
        .asyncMap((_) => get(id));
  }

  @override
  Future<void> setPhase(String id, ImportPhase phase) =>
      (_db.update(_db.importJobs)..where((t) => t.id.equals(id))).write(
        ImportJobsCompanion(phase: Value(phase.wire)),
      );

  @override
  Future<void> setPaused(String id, {required bool paused}) =>
      (_db.update(_db.importJobs)..where((t) => t.id.equals(id))).write(
        ImportJobsCompanion(paused: Value(paused)),
      );

  @override
  Future<void> setCreateFailure(String id, ImportFailure? failure) =>
      (_db.update(_db.importJobs)..where((t) => t.id.equals(id))).write(
        ImportJobsCompanion(createFailure: Value(failure?.wire)),
      );

  @override
  Future<void> updatePhoto(
    String jobId,
    String photoId, {
    ImportPhotoState? state,
    ImportFailure? failure,
    bool clearFailure = false,
    String? photoFile,
    String? thumbFile,
    bool clearFiles = false,
    bool clearSource = false,
    String? sourcePath,
  }) =>
      (_db.update(
        _db.importJobPhotos,
      )..where((t) => t.jobId.equals(jobId) & t.id.equals(photoId))).write(
        ImportJobPhotosCompanion(
          state: state == null ? const Value.absent() : Value(state.wire),
          failure: clearFailure
              ? const Value(null)
              : failure == null
              ? const Value.absent()
              : Value(failure.wire),
          photoFile: clearFiles
              ? const Value(null)
              : photoFile == null
              ? const Value.absent()
              : Value(photoFile),
          thumbFile: clearFiles
              ? const Value(null)
              : thumbFile == null
              ? const Value.absent()
              : Value(thumbFile),
          sourcePath: clearSource
              ? const Value(null)
              : sourcePath == null
              ? const Value.absent()
              : Value(sourcePath),
        ),
      );

  @override
  Future<void> delete(String id) => _db.transaction(() async {
    await (_db.delete(
      _db.importJobPhotos,
    )..where((t) => t.jobId.equals(id))).go();
    await (_db.delete(_db.importJobs)..where((t) => t.id.equals(id))).go();
  });
}
