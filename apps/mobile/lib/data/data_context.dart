import 'dart:async';
import 'dart:io';

import 'package:ourney_core/ourney_core.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import 'db/app_database.dart';
import 'journey_clock.dart';
import 'local_store.dart';
import 'media_store.dart';
import 'remote/remote_api.dart';
import 'sync/outbox.dart';
import 'sync/sync_engine.dart';

/// Folder (next to the media root, in Application Support) holding the
/// compressed check-in drafts written by the checkin feature before
/// `CheckInRepository.submit` copies them into the media store.
const String checkinDraftDirName = 'checkin_media';

/// Everything a repository needs. In local-only mode [remote], [outbox] and
/// [sync] are null and [userIdOf] returns the persisted guest id.
class DataContext {
  DataContext({
    required this.db,
    required this.files,
    required this.media,
    required this.clock,
    required this._userIdOf,
    this.remote,
    this.outbox,
    this.sync,
    String Function()? newId,
  }) : store = LocalStore(db, files),
       newId = newId ?? const Uuid().v4 {
    // Leftovers of wipes that were interrupted before deleting their trash.
    unawaited(MediaWipe.recover(db, [files.root, _draftsDir]));
  }

  /// Check-in drafts folder (next to the media root).
  Directory get _draftsDir =>
      Directory(p.join(files.root.parent.path, checkinDraftDirName));

  final AppDatabase db;
  final MediaFiles files;
  final CachedMediaStore media;
  final JourneyClock clock;
  final LocalStore store;
  final RemoteApi? remote;
  final Outbox? outbox;
  final SyncEngine? sync;
  final String Function() newId;
  final String? Function() _userIdOf;

  bool get localOnly => remote == null;

  /// The user whose data is cached: guest id (local-only) or the signed-in
  /// Supabase user. Null when signed out.
  String? get userId => _userIdOf();

  String requireUserId() =>
      _userIdOf() ??
      (throw const OurneyException(OurneyErrorCode.unauthenticated));

  /// The server, or `offline` in local-only mode (feature needs a server).
  RemoteApi requireRemote() =>
      remote ??
      (throw const OurneyException(
        OurneyErrorCode.offline,
        'local-only mode: this needs a server',
      ));

  /// [requireUserId] for write paths: also records the signed-in user as the
  /// cache owner before the first local write, so a later pull never mistakes
  /// this user's offline rows for a previous account's leftovers.
  Future<String> claimUserId() async {
    final me = requireUserId();
    await sync?.ensureOwner(me);
    return me;
  }

  DateTime now() => clock.now();

  /// Removes every cached row and file (account deletion, sign-out),
  /// including leftover check-in drafts.
  Future<void> wipeLocal() async {
    // Stop pulls still running for the old session before they refill it.
    sync?.invalidateSession();
    // Rows + marker + media renamed to trash in one step (see [MediaWipe]):
    // a failure anywhere keeps rows and files together, and the trash is only
    // deleted after the commit. The marker survives a late in-flight write:
    // the next user to sign in finds an owner that is not them and wipes again.
    Future<void> wipe() => MediaWipe.run(
      db,
      [files.root, _draftsDir],
      (moveMedia) => db.transaction(() async {
        await db.wipe();
        if (sync != null) await db.writeCursor(ownerCursorKey, wipedOwner);
        await moveMedia();
      }),
    );
    // Never while a queue read-modify-write runs: its restore path would
    // write rows into the wiped outbox.
    final queue = outbox;
    await (queue == null ? wipe() : queue.exclusive(wipe));
    sync?.notifyChanged();
  }
}
