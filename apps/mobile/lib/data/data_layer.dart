import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ourney_core/ourney_core.dart';

import 'data_context.dart';
import 'db/app_database.dart';
import 'journey_clock.dart';
import 'local_store.dart';
import 'media_store.dart';
import 'remote/remote_api.dart';
import 'repositories/auth_repository.dart';
import 'repositories/check_in_repository.dart';
import 'repositories/group_repository.dart';
import 'repositories/journey_repository.dart';
import 'repositories/profile_repository.dart';
import 'repositories/safety_repository.dart';
import 'sync/outbox.dart';
import 'sync/sync_engine.dart';
import 'sync/sync_triggers.dart';

/// Every repository of one mode, built over a shared [DataContext].
///
/// * [DataLayer.localOnly]: no backend (FR-A5). Solo journeys and check-ins
///   live in drift + local files; group/safety/sign-in calls throw
///   [OurneyException] `offline`.
/// * [DataLayer.supabase]: local-first writes, persisted outbox pushed to
///   Supabase, pull sync by `updated_at` cursor, triggered on start,
///   connectivity regained, app resume and sign-in.
class DataLayer {
  DataLayer._(this.ctx, this.auth);

  factory DataLayer.localOnly({
    required AppDatabase db,
    required Directory mediaRoot,
    required String guestUserId,
    JourneyClock? clock,
    String Function()? newId,
  }) {
    final files = MediaFiles(mediaRoot);
    final ctx = DataContext(
      db: db,
      files: files,
      media: CachedMediaStore(files),
      clock: clock ?? JourneyClock(),
      userIdOf: () => guestUserId,
      newId: newId,
    );
    return DataLayer._(ctx, LocalAuthRepository(ctx, guestUserId: guestUserId));
  }

  factory DataLayer.supabase({
    required AppDatabase db,
    required Directory mediaRoot,
    required RemoteApi remote,
    JourneyClock? clock,
    String Function()? newId,
    Timer Function(Duration, void Function())? timer,
    Stream<List<ConnectivityResult>>? connectivity,
    bool listenLifecycle = true,
    bool autoSync = true,
  }) {
    final files = MediaFiles(mediaRoot);
    final journeyClock = clock ?? JourneyClock();
    final sync = SyncEngine(
      db: db,
      store: LocalStore(db, files),
      remote: remote,
      now: journeyClock.now,
    );
    final outbox = Outbox(
      db,
      executor: sync.execute,
      now: journeyClock.now,
      timer: timer,
    );
    sync.outbox = outbox;
    final ctx = DataContext(
      db: db,
      files: files,
      media: CachedMediaStore(files, remote: remote),
      clock: journeyClock,
      userIdOf: () => remote.currentUserId,
      remote: remote,
      outbox: outbox,
      sync: sync,
      newId: newId,
    );
    final layer = DataLayer._(ctx, SupabaseAuthRepository(ctx, remote));
    if (autoSync) {
      layer._triggers = SyncTriggers(
        onTrigger: () => unawaited(layer.syncNow()),
        connectivity: connectivity,
        listenLifecycle: listenLifecycle,
      );
      layer._authSub = remote.watchUserId().listen((id) {
        if (id != null) unawaited(layer.syncNow());
      });
    }
    return layer;
  }

  final DataContext ctx;
  final AuthRepository auth;
  SyncTriggers? _triggers;
  StreamSubscription<String?>? _authSub;

  late final ProfileRepository profiles = DataProfileRepository(ctx);
  late final JourneyRepository journeys = DataJourneyRepository(ctx);
  late final CheckInRepository checkIns = DataCheckInRepository(ctx);
  late final GroupRepository groups = DataGroupRepository(ctx);
  late final SafetyRepository safety = DataSafetyRepository(ctx);
  MediaStore get media => ctx.media;

  bool get isLocalOnly => ctx.localOnly;

  /// Pushes the outbox (ignoring backoff) then pulls server changes. Never
  /// throws; returns [SyncOk] in local-only mode.
  Future<SyncResult> syncNow() async {
    final sync = ctx.sync;
    if (sync == null || ctx.remote?.currentUserId == null) {
      return ctx.localOnly ? const SyncOk() : const SyncFailed('signed out');
    }
    try {
      // Pull first: it claims the cache for the signed-in user (wiping
      // another user's leftovers) before anything is pushed.
      final pulled = await sync.syncNow();
      await ctx.outbox!.flush(force: true);
      return pulled;
    } on Object catch (e) {
      return SyncFailed(e.toString());
    }
  }

  Future<void> dispose() async {
    _triggers?.dispose();
    await _authSub?.cancel();
    ctx.outbox?.dispose();
    ctx.sync?.dispose();
  }
}
