import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:ourney_core/ourney_core.dart';
import 'package:path/path.dart' as p;

import 'db/app_database.dart';
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
}

/// Wipes media folders together with a database transaction without ever
/// losing files whose rows survive.
///
/// One rule: **only trash recorded in the committed DB may be deleted**.
/// * Inside the transaction the live folders are renamed to
///   `<dir>.trash-<ts>`, and the paths of that trash AND of every older
///   `.trash-*` / `.restore-*` sibling (their rows are wiped by the same
///   transaction) are recorded under [pendingTrashCursorKey].
/// * After the commit the recorded paths are deleted and the record cleared.
/// * If the transaction throws, the new trash is put back (merged into the
///   live folder when the UI re-created it meanwhile).
/// * A trash that is NOT recorded belongs to a wipe that never committed
///   (crash): [recover] merges it back into the live folder, never deletes it.
/// * Everything runs behind one async lock, so recovery can never overlap a
///   wipe.
abstract final class MediaWipe {
  static const _trash = '.trash-';
  static const _restore = '.restore-';

  static Future<void> _tail = Future<void>.value();
  static final Set<Future<void>> _background = {};

  /// Completes when every background trash delete started so far is done
  /// (tests, graceful shutdown).
  static Future<void> settled() async {
    while (_background.isNotEmpty) {
      await Future.wait(List.of(_background));
    }
  }

  static Future<T> _locked<T>(Future<T> Function() body) async {
    final previous = _tail;
    final done = Completer<void>();
    _tail = done.future;
    await previous;
    try {
      return await body();
    } finally {
      done.complete();
    }
  }

  /// The record. Throws when it is unreadable: callers must not overwrite
  /// it then.
  static Future<List<String>> _recorded(AppDatabase db) async {
    final raw = await db.readCursor(pendingTrashCursorKey);
    if (raw == null || raw.isEmpty) return [];
    return [for (final e in jsonDecode(raw) as List) e as String];
  }

  static Iterable<Directory> _siblings(Directory dir) {
    final parent = dir.parent;
    if (!parent.existsSync()) return const [];
    final base = p.basename(dir.path);
    return [
      for (final e in parent.listSync())
        if (e is Directory &&
            (p.basename(e.path).startsWith('$base$_trash') ||
                p.basename(e.path).startsWith('$base$_restore')))
          e,
    ];
  }

  /// Startup recovery: deletes the recorded (committed) trash and merges
  /// every unrecorded one back.
  static Future<void> recover(AppDatabase db, Iterable<Directory> dirs) =>
      _locked(() => _recover(db, dirs));

  static Future<void> _recover(AppDatabase db, Iterable<Directory> dirs) async {
    try {
      await _deleteRecorded(db);
      for (final dir in dirs) {
        for (final e in _siblings(dir)) {
          // Re-read right before deciding what this folder is.
          if ((await _recorded(db)).contains(e.path)) continue;
          await _restoreInto(e, dir);
        }
      }
    } on Object catch (e) {
      // An unreadable record stops here: nothing is deleted or overwritten.
      debugPrint('media wipe: recover failed: $e');
    }
  }

  /// Deletes every recorded path (one failure does not block the others) and
  /// removes the ones gone from the record.
  static Future<void> _deleteRecorded(AppDatabase db) async {
    final recorded = await _recorded(db);
    final gone = <String>[];
    for (final path in recorded) {
      try {
        final d = Directory(path);
        if (d.existsSync()) await d.delete(recursive: true);
        gone.add(path);
      } on PathNotFoundException {
        // A file deep inside may vanish mid-delete; only drop the record
        // once the folder itself is gone, or recovery would merge the rest.
        if (!Directory(path).existsSync()) gone.add(path);
      } on Object catch (e) {
        debugPrint('media wipe: could not delete $path: $e');
      }
    }
    if (gone.isEmpty) return;
    await db.transaction(() async {
      final left = (await _recorded(db)).where((x) => !gone.contains(x));
      await db.writeCursor(pendingTrashCursorKey, jsonEncode(left.toList()));
    });
  }

  /// Merges [trash] into [dir]; a name already in [dir] wins (fresh cache).
  /// Anything that could not be merged (merge error, or a file where the
  /// other side has a folder) is kept as `<dir>.restore-<ts>`.
  static Future<void> _restoreInto(Directory trash, Directory dir) async {
    var keep = false;
    try {
      if (!dir.existsSync()) {
        await trash.rename(dir.path);
        return;
      }
      keep = await _merge(trash, dir);
    } on Object catch (e) {
      debugPrint('media wipe: merge failed for ${trash.path}: $e');
      keep = true;
    }
    try {
      if (!trash.existsSync()) return;
      if (!keep) {
        await trash.delete(recursive: true);
      } else if (!p.basename(trash.path).contains(_restore)) {
        await trash.rename(
          '${dir.path}$_restore${DateTime.now().microsecondsSinceEpoch}',
        );
      }
    } on Object catch (e) {
      debugPrint('media wipe: could not finish ${trash.path}: $e');
    }
  }

  /// Moves [src] entries into [dst]; returns true when something could not
  /// be merged and must be kept.
  static Future<bool> _merge(Directory src, Directory dst) async {
    var conflict = false;
    for (final e in src.listSync()) {
      final target = p.join(dst.path, p.basename(e.path));
      final type = FileSystemEntity.typeSync(target);
      if (type == FileSystemEntityType.notFound) {
        await e.rename(target);
      } else if (e is Directory && type == FileSystemEntityType.directory) {
        if (await _merge(e, Directory(target))) conflict = true;
        if (e.existsSync() && e.listSync().isEmpty) await e.delete();
      } else if (e is File && type == FileSystemEntityType.file) {
        // Same name: the live copy (a fresh download) wins.
        await e.delete();
      } else {
        conflict = true; // file vs folder: keep the old one
      }
    }
    return conflict;
  }

  /// Runs [transaction], handing it a `moveMedia` step to call inside it
  /// (after the rows are wiped). Must not be called from inside another
  /// transaction: its commit would only be a savepoint.
  static Future<void> run(
    AppDatabase db,
    List<Directory> dirs,
    Future<void> Function(Future<void> Function() moveMedia) transaction,
  ) => _locked(() async {
    await _recover(db, dirs);
    final moved = <({Directory dir, Directory trash})>[];
    Future<void> moveMedia() async {
      // An unreadable record is replaced: `older` already lists every trash
      // folder on disk, and this transaction wipes their rows anyway.
      List<String> before;
      try {
        before = await _recorded(db);
      } on Object {
        before = const [];
      }
      final older = [
        for (final dir in dirs) ..._siblings(dir).map((d) => d.path),
      ];
      for (final dir in dirs) {
        if (!dir.existsSync()) continue;
        final trash = Directory(
          '${dir.path}$_trash${DateTime.now().microsecondsSinceEpoch}',
        );
        await dir.rename(trash.path);
        moved.add((dir: dir, trash: trash));
      }
      // Same transaction as the wipe: recorded only if it commits.
      final all = <String>{
        ...before,
        ...older,
        for (final m in moved) m.trash.path,
      };
      await db.writeCursor(pendingTrashCursorKey, jsonEncode(all.toList()));
    }

    try {
      await transaction(moveMedia);
    } on Object {
      for (final m in moved.reversed) {
        await _restoreInto(m.trash, m.dir);
      }
      rethrow;
    }
    // Committed: delete in the background, outside any transaction zone.
    final job = Zone.root.run(
      () => _locked(() => _deleteRecorded(db)).catchError((Object e) {
        debugPrint('media wipe: trash left (recorded, swept later): $e');
      }),
    );
    _background.add(job);
    unawaited(job.whenComplete(() => _background.remove(job)));
  });
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
  Future<void> evict(Iterable<String> storagePaths) =>
      files.delete(storagePaths);
}
