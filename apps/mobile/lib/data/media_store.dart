import 'dart:async';
import 'dart:io';

import 'package:ourney_core/ourney_core.dart';
import 'package:path/path.dart' as p;

import 'remote/remote_api.dart';

/// On-disk media, laid out exactly like the storage bucket:
/// `<root>/checkins/{journey}/{user}/{id}.jpg`, `<root>/avatars/{user}/{uuid}.jpg`.
///
/// The same folder holds the user's own photos (written at capture time, the
/// source of the upload) and downloaded copies of other members' photos, so
/// the cache is keyed by storage path and never by (changing) signed URLs.
class MediaFiles {
  MediaFiles(this.root);

  final Directory root;

  File fileFor(String storagePath) {
    if (storagePath.contains('..') || p.isAbsolute(storagePath)) {
      throw const OurneyException(OurneyErrorCode.invalid, 'bad storage path');
    }
    return File(p.joinAll([root.path, ...storagePath.split('/')]));
  }

  /// Copies [sourceFile] to the slot for [storagePath].
  Future<File> importFile(String sourceFile, String storagePath) async {
    final target = fileFor(storagePath);
    await target.parent.create(recursive: true);
    return File(sourceFile).copy(target.path);
  }

  Future<File> writeBytes(String storagePath, List<int> bytes) async {
    final target = fileFor(storagePath);
    await target.parent.create(recursive: true);
    return target.writeAsBytes(bytes, flush: true);
  }

  Future<void> delete(Iterable<String> storagePaths) async {
    for (final path in storagePaths) {
      final f = fileFor(path);
      if (f.existsSync()) await f.delete();
    }
  }

  /// Removes a whole folder, e.g. `checkins/{journeyId}`.
  Future<void> deleteFolder(String storagePrefix) async {
    final dir = Directory(p.joinAll([root.path, ...storagePrefix.split('/')]));
    if (dir.existsSync()) await dir.delete(recursive: true);
  }

  Future<void> wipe() async {
    if (root.existsSync()) await root.delete(recursive: true);
  }
}

/// [MediaStore] implementation.
///
/// `localFileFor(path)` returns an absolute file path that can be shown with
/// `Image.file(File(path))`:
/// * own photos come straight from disk (also before they are uploaded);
/// * remote photos are downloaded once through a signed URL (TTL 1 h) and
///   cached by storage path.
///
/// Throws [OurneyException] `notFound` when the file is not on disk and
/// cannot be fetched (local-only mode, or no read access), `offline` when the
/// download failed for lack of network.
class CachedMediaStore implements MediaStore {
  CachedMediaStore(this.files, {this.remote});

  final MediaFiles files;
  final RemoteApi? remote;
  final Map<String, Future<String>> _inFlight = {};

  @override
  Future<String> localFileFor(String storagePath) {
    final file = files.fileFor(storagePath);
    if (file.existsSync()) return Future.value(file.path);
    final api = remote;
    if (api == null) {
      return Future.error(
        OurneyException(OurneyErrorCode.notFound, storagePath),
      );
    }
    return _inFlight.putIfAbsent(storagePath, () async {
      try {
        await file.parent.create(recursive: true);
        final tmp = File('${file.path}.part');
        await api.downloadToFile(storagePath, tmp);
        await tmp.rename(file.path);
        return file.path;
      } finally {
        unawaited(_inFlight.remove(storagePath));
      }
    });
  }

  /// Drops a cached copy (e.g. after a block or a tombstone).
  Future<void> evict(Iterable<String> storagePaths) => files.delete(storagePaths);
}
