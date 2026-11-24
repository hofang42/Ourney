import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../data/data_context.dart' show checkinDraftDirName;

/// The app-owned copies an import job keeps of the photos the person picked,
/// so the OS cannot purge them (picker cache) before a resume.
///
/// Each job has one folder; every copy is named after its photo id. Nothing
/// here ever touches the picker's own files.
abstract interface class ImportFiles {
  /// Puts [sourcePath] into the job's folder as [photoId] and returns the new
  /// path. A picker temp file is moved (no second copy on disk); any other
  /// file is copied. A file that is already there is returned as is. Throws
  /// when the source cannot be read.
  Future<String> keep(String jobId, String photoId, String sourcePath);

  /// Deletes the job's folder (never throws).
  Future<void> deleteJob(String jobId);

  /// Deletes every job folder except those of [keepJobIds]: leftovers of jobs
  /// whose rows are gone (another account's wipe, a crash).
  Future<void> sweep(Set<String> keepJobIds);
}

/// Folders live inside the check-in draft directory, which
/// `DataContext.wipeLocal` already deletes on sign-out.
class LocalImportFiles implements ImportFiles {
  /// [rootOf] is the folder holding the job folders and [tempOf] the picker's
  /// temp folder (both replaced in tests).
  LocalImportFiles({
    Future<Directory> Function()? rootOf,
    Future<Directory> Function()? tempOf,
  }) : _rootOf = rootOf ?? _defaultRoot,
       _tempOf = tempOf ?? getTemporaryDirectory;

  final Future<Directory> Function() _rootOf;
  final Future<Directory> Function() _tempOf;

  static Future<Directory> _defaultRoot() async {
    final base = await getApplicationSupportDirectory();
    return Directory(p.join(base.path, checkinDraftDirName, 'import_jobs'));
  }

  @override
  Future<String> keep(String jobId, String photoId, String sourcePath) async {
    final root = await _rootOf();
    final dir = Directory(p.join(root.path, jobId));
    final target = p.join(dir.path, '$photoId${p.extension(sourcePath)}');
    if (p.equals(target, sourcePath)) return target;
    await dir.create(recursive: true);
    final source = File(sourcePath);
    if (!source.existsSync()) {
      throw FileSystemException('source is gone', sourcePath);
    }
    final temp = await _tempOf();
    if (p.isWithin(temp.path, sourcePath)) {
      // Our own temp copy: move it, so the photo is on disk once.
      try {
        await source.rename(target);
        return target;
      } on FileSystemException {
        // Another volume: copy, then delete the temp file right away.
        await source.copy(target);
        try {
          await source.delete();
        } on FileSystemException {
          // The OS purges the cache anyway.
        }
        return target;
      }
    }
    // Not ours to delete (a library file): copy only.
    await source.copy(target);
    return target;
  }

  @override
  Future<void> deleteJob(String jobId) async {
    try {
      final dir = Directory(p.join((await _rootOf()).path, jobId));
      if (dir.existsSync()) await dir.delete(recursive: true);
    } on Object {
      // Best effort: leftovers are swept at the next resume.
    }
  }

  @override
  Future<void> sweep(Set<String> keepJobIds) async {
    try {
      final root = await _rootOf();
      if (!root.existsSync()) return;
      for (final e in root.listSync()) {
        if (e is Directory && !keepJobIds.contains(p.basename(e.path))) {
          await e.delete(recursive: true);
        }
      }
    } on Object {
      // Best effort.
    }
  }
}

final importFilesProvider = Provider<ImportFiles>((ref) => LocalImportFiles());
