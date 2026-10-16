import 'dart:async';

import 'package:drift/drift.dart';
import 'package:ourney_core/ourney_core.dart';

import '../db/app_database.dart';
import '../local_store.dart';
import '../mapping.dart';
import '../remote/remote_api.dart';
import 'outbox.dart';

/// Pull rows changed since the cursor minus this overlap: `updated_at` is the
/// writer's transaction start, so rows can commit slightly "in the past".
/// Re-applying a row is idempotent.
const Duration pullOverlap = Duration(minutes: 1);
const int pullPageSize = 1000;

/// Cursor key holding the user id the cache belongs to.
const String ownerCursorKey = '_owner';

/// Supabase-mode sync: executes outbox items ([execute]) and pulls server
/// changes by `updated_at` cursor ([syncNow]).
class SyncEngine {
  SyncEngine({
    required this.db,
    required this.store,
    required this.remote,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final AppDatabase db;
  final LocalStore store;
  final RemoteApi remote;
  final DateTime Function() _now;

  /// Set right after construction (the outbox needs [execute] first).
  late final Outbox outbox;

  Future<SyncResult>? _pulling;
  bool _pullAgain = false;
  final _changes = StreamController<void>.broadcast();

  /// Fires after server data was applied locally (pull, outbox success).
  Stream<void> get changes => _changes.stream;

  void notifyChanged() {
    if (!_changes.isClosed) _changes.add(null);
  }

  /// Wipes the cache when it belongs to a different user than [userId].
  Future<void> ensureOwner(String userId) async {
    final owner = await db.readCursor(ownerCursorKey);
    if (owner == userId) return;
    if (owner != null) {
      await db.wipe();
      await store.files.wipe();
    }
    await db.writeCursor(ownerCursorKey, userId);
  }

  // --- push -------------------------------------------------------------------

  Future<void> execute(OutboxKind kind, Map<String, dynamic> p) async {
    switch (kind) {
      case OutboxKind.createJourney:
        final row = await remote.rpc('create_journey', p.cast<String, dynamic>());
        if (row is Map) await store.applyJourney(row.cast<String, dynamic>());
      case OutboxKind.upsertCheckIn:
        await _pushCheckIn(p['id'] as String);
      case OutboxKind.deleteMedia:
        final paths = <String>{
          ...(p['paths'] as List? ?? const []).cast<String>(),
        };
        for (final prefix in (p['prefixes'] as List? ?? const []).cast<String>()) {
          paths.addAll(await remote.listFiles(prefix));
        }
        if (paths.isNotEmpty) await remote.removeFiles(paths.toList());
      case OutboxKind.react:
        final emoji = p['emoji'] as String?;
        if (emoji != null) {
          await remote.upsert('reactions', {
            'checkin_id': p['checkin_id'],
            'user_id': p['user_id'],
            'emoji': emoji,
            'deleted_at': null,
          }, onConflict: 'checkin_id,user_id');
        } else {
          await remote.update(
            'reactions',
            {'deleted_at': _now().toUtc().toIso8601String()},
            match: {
              'checkin_id': p['checkin_id'] as String,
              'user_id': p['user_id'] as String,
            },
          );
        }
      case OutboxKind.updateMembership:
        await remote.update(
          'memberships',
          {
            if (p.containsKey('hide_metric')) 'hide_metric': p['hide_metric'],
            if (p.containsKey('blur_media')) 'blur_media': p['blur_media'],
          },
          match: {
            'journey_id': p['journey_id'] as String,
            'user_id': p['user_id'] as String,
          },
        );
    }
    notifyChanged();
  }

  Future<void> _pushCheckIn(String id) async {
    final row = await (db.select(
      db.checkIns,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null || row.uploaded) return; // replaced by a retake, or done
    final photo = store.files.fileFor(row.photoPath);
    final thumb = store.files.fileFor(row.thumbPath);
    if (!photo.existsSync() || !thumb.existsSync()) {
      throw OurneyException(OurneyErrorCode.invalid, 'missing media for $id');
    }
    // Media first so nobody sees a row without its photo.
    await remote.uploadFile(row.photoPath, photo);
    await remote.uploadFile(row.thumbPath, thumb);
    await remote.upsert(
      'check_ins',
      checkInToRemote(row),
      onConflict: 'journey_id,user_id,local_date',
    );
    await (db.update(db.checkIns)..where((t) => t.id.equals(id))).write(
      const CheckInsCompanion(uploaded: Value(true)),
    );
  }

  // --- pull -------------------------------------------------------------------

  /// Pulls every table changed since its cursor. Concurrent calls coalesce.
  Future<SyncResult> syncNow() {
    if (_pulling != null) {
      _pullAgain = true;
      return _pulling!;
    }
    final run = _pullLoop().whenComplete(() => _pulling = null);
    _pulling = run;
    return run;
  }

  Future<SyncResult> _pullLoop() async {
    SyncResult result;
    do {
      _pullAgain = false;
      result = await _pullOnce();
    } while (_pullAgain && result is SyncOk);
    return result;
  }

  Future<SyncResult> _pullOnce() async {
    final me = remote.currentUserId;
    if (me == null) return const SyncFailed('signed out');
    try {
      await ensureOwner(me);
      final pending = await outbox.pendingKeys();
      await _pullTable('journeys', store.applyJourney);
      await _pullTable('memberships', (r) => store.applyMembership(r, me: me));
      await _pullTable('check_ins', (r) => store.applyCheckIn(r, pending));
      await _pullTable(
        'reactions',
        (r) => store.applyReaction(r, pending, me: me),
      );
      await _pullTable(
        'blocks',
        (r) => store.applyBlock(r, me: me),
        eq: {'blocker_id': me},
      );
      await _pullTable('profiles', store.applyProfile, eq: {'id': me});
      notifyChanged();
      return const SyncOk();
    } on OurneyException catch (e) {
      if (e.error == OurneyErrorCode.offline) return const SyncOffline();
      return SyncFailed(e.toString());
    }
  }

  Future<void> _pullTable(
    String table,
    Future<void> Function(RemoteRow) apply, {
    Map<String, Object> eq = const {},
  }) async {
    final key = eq.isEmpty ? table : '$table?${eq.keys.join(',')}';
    var cursor = await db.readCursor(key);
    var since = cursor == null
        ? null
        : DateTime.parse(
            cursor,
          ).toUtc().subtract(pullOverlap).toIso8601String();
    while (true) {
      final rows = await remote.select(
        table,
        eq: eq,
        updatedSince: since,
        limit: pullPageSize,
      );
      if (rows.isEmpty) return;
      await db.transaction(() async {
        for (final r in rows) {
          await apply(r);
        }
      });
      final last = rows.last['updated_at'] as String?;
      if (last == null) return;
      final advanced = last != cursor;
      cursor = last;
      await db.writeCursor(key, last);
      if (rows.length < pullPageSize || !advanced) return;
      since = DateTime.parse(last).toUtc().toIso8601String();
    }
  }

  /// Full refresh of one journey (after join/rejoin, unblock, or when a
  /// group screen opens): rows that disappeared server-side without a
  /// tombstone (RLS: blocks, reports) are dropped locally.
  Future<void> pullJourney(String journeyId) async {
    final me = remote.currentUserId;
    if (me == null) return;
    final pending = await outbox.pendingKeys();
    final journeys = await remote.select('journeys', eq: {'id': journeyId});
    if (journeys.isEmpty) {
      if (!pending.contains(journeyKey(journeyId))) {
        await store.purgeJourney(journeyId);
      }
      notifyChanged();
      return;
    }
    final members = await remote.select(
      'memberships',
      eq: {'journey_id': journeyId},
    );
    final checkIns = await remote.select(
      'check_ins',
      eq: {'journey_id': journeyId},
      onlyLive: true,
    );
    final ids = [for (final c in checkIns) c['id'] as String];
    final reactions = <RemoteRow>[];
    for (var i = 0; i < ids.length; i += 100) {
      final chunk = ids.sublist(i, i + 100 > ids.length ? ids.length : i + 100);
      reactions.addAll(
        await remote.select(
          'reactions',
          inList: {'checkin_id': chunk},
          onlyLive: true,
        ),
      );
    }

    await db.transaction(() async {
      await store.applyJourney(journeys.first);
      for (final m in members) {
        await store.applyMembership(m, me: me);
      }
      final live = ids.toSet();
      final stale = await (db.select(db.checkIns)..where(
            (t) =>
                t.journeyId.equals(journeyId) &
                t.uploaded.equals(true) &
                t.id.isNotIn(live),
          ))
          .get();
      await store.deleteCheckIns(stale);
      for (final c in checkIns) {
        await store.applyCheckIn(c, pending);
      }
      final liveReactions = {
        for (final r in reactions) '${r['checkin_id']}|${r['user_id']}',
      };
      final local = await (db.select(
        db.reactions,
      )..where((t) => t.checkInId.isIn(ids))).get();
      for (final r in local) {
        final mine = r.userId == me && pending.contains(reactionKey(r.checkInId));
        if (!mine && !liveReactions.contains('${r.checkInId}|${r.userId}')) {
          await (db.delete(db.reactions)..where(
                (t) =>
                    t.checkInId.equals(r.checkInId) & t.userId.equals(r.userId),
              ))
              .go();
        }
      }
      for (final r in reactions) {
        await store.applyReaction(r, pending, me: me);
      }
    });
    notifyChanged();
  }

  void dispose() {
    unawaited(_changes.close());
  }
}
