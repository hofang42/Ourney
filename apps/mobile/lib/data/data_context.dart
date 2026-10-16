import 'package:ourney_core/ourney_core.dart';
import 'package:uuid/uuid.dart';

import 'db/app_database.dart';
import 'journey_clock.dart';
import 'local_store.dart';
import 'media_store.dart';
import 'remote/remote_api.dart';
import 'sync/outbox.dart';
import 'sync/sync_engine.dart';

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
       newId = newId ?? const Uuid().v4;

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

  DateTime now() => clock.now();
}
