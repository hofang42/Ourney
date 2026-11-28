import 'dart:async';

import 'package:ourney/features/import/data/import_files.dart';
import 'package:ourney/features/import/data/import_job.dart';
import 'package:ourney/features/import/data/import_job_store.dart';
import 'package:ourney/features/import/data/import_photo_picker.dart';
import 'package:ourney/features/import/data/photo_dates.dart';
import 'package:ourney_core/ourney_core.dart';

/// A photo the fake library holds. [taken] is the EXIF capture time (wall
/// clock); without it only [modified] can date the photo.
ImportPhoto fakePhoto(
  String path, {
  DateTime? taken,
  DateTime? modified,
  int? size,
  String? fingerprint,
  int? offsetMinutes,
}) => ImportPhoto(
  path: path,
  // Defaults to a plausible, old file time so tests are not "cache copies".
  modified: modified ?? DateTime(2020, 1, 1, 10),
  exif: taken == null
      ? null
      : ExifMoment(
          date: LocalDate(taken.year, taken.month, taken.day),
          secondsOfDay: taken.hour * 3600 + taken.minute * 60 + taken.second,
          offsetMinutes: offsetMinutes,
        ),
  size: size,
  fingerprint: fingerprint,
);

class FakeImportPicker implements ImportPhotoPicker {
  FakeImportPicker(this.photos, {this.lost = const [], this.fail = false});

  /// What the next picks return (the same list each time).
  List<ImportPhoto> photos;
  final List<ImportPhoto> lost;
  bool fail;
  int picks = 0;
  int? lastLimit;

  @override
  Future<List<ImportPhoto>> pickPhotos({int limit = importMaxPhotos}) async {
    picks++;
    lastLimit = limit;
    if (fail) throw StateError('picker boom');
    return photos;
  }

  @override
  Future<List<ImportPhoto>> recoverLost() async => lost;
}

/// In-memory [ImportJobStore] (shared across a test's "app restarts").
class InMemoryImportJobStore implements ImportJobStore {
  final Map<String, ImportJob> jobs = {};
  final _changes = StreamController<String>.broadcast();

  @override
  Future<void> create(ImportJob job) async {
    jobs[job.id] = job;
    _changes.add(job.id);
  }

  @override
  Future<ImportJob?> get(String id) async => jobs[id];

  @override
  Future<List<ImportJob>> unfinished() async => [
    ...(jobs.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt))),
  ];

  @override
  Stream<ImportJob?> watch(String id) async* {
    yield jobs[id];
    await for (final changed in _changes.stream) {
      if (changed == id) yield jobs[id];
    }
  }

  ImportJob _with(
    ImportJob j, {
    ImportPhase? phase,
    List<ImportJobPhoto>? photos,
    bool? paused,
    ImportFailure? createFailure,
    bool clearCreateFailure = false,
  }) => ImportJob(
    ownerId: j.ownerId,
    paused: paused ?? j.paused,
    createFailure: clearCreateFailure ? null : createFailure ?? j.createFailure,
    id: j.id,
    title: j.title,
    emoji: j.emoji,
    templateId: j.templateId,
    firstDate: j.firstDate,
    lastDate: j.lastDate,
    timezone: j.timezone,
    createdAt: j.createdAt,
    layout: j.layout,
    continues: j.continues,
    phase: phase ?? j.phase,
    photos: photos ?? j.photos,
  );

  @override
  Future<void> setPhase(String id, ImportPhase phase) async {
    final j = jobs[id];
    if (j == null) return;
    jobs[id] = _with(j, phase: phase);
    _changes.add(id);
  }

  @override
  Future<void> setPaused(String id, {required bool paused}) async {
    final j = jobs[id];
    if (j == null) return;
    jobs[id] = _with(j, paused: paused);
    _changes.add(id);
  }

  @override
  Future<void> setCreateFailure(String id, ImportFailure? failure) async {
    final j = jobs[id];
    if (j == null) return;
    jobs[id] = _with(
      j,
      createFailure: failure,
      clearCreateFailure: failure == null,
    );
    _changes.add(id);
  }

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
  }) async {
    final j = jobs[jobId];
    if (j == null) return;
    jobs[jobId] = _with(
      j,
      photos: [
        for (final p in j.photos)
          if (p.id != photoId)
            p
          else
            ImportJobPhoto(
              id: p.id,
              caption: p.caption,
              position: p.position,
              date: p.date,
              secondsOfDay: p.secondsOfDay,
              offsetMinutes: p.offsetMinutes,
              dedupeKey: p.dedupeKey,
              sourcePath: clearSource ? null : sourcePath ?? p.sourcePath,
              photoFile: clearFiles ? null : photoFile ?? p.photoFile,
              thumbFile: clearFiles ? null : thumbFile ?? p.thumbFile,
              state: state ?? p.state,
              failure: clearFailure ? null : failure ?? p.failure,
            ),
      ],
    );
    _changes.add(jobId);
  }

  @override
  Future<void> delete(String id) async {
    jobs.remove(id);
    _changes.add(id);
  }
}

/// [ImportFiles] for widget tests whose picked paths are not real files: no
/// copy is made, the source path is the "kept" path.
class FakeImportFiles implements ImportFiles {
  final List<String> deletedJobs = [];

  @override
  Future<String> keep(String jobId, String photoId, String sourcePath) async =>
      sourcePath;

  @override
  Future<void> deleteJob(String jobId) async => deletedJobs.add(jobId);

  @override
  Future<void> sweep(Set<String> keepJobIds) async {}
}
