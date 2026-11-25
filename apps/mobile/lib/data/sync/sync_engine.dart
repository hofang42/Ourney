import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:ourney_core/ourney_core.dart';
import 'package:path/path.dart' as p;

import '../data_context.dart' show checkinDraftDirName;
import '../db/app_database.dart';
import '../local_store.dart';
import '../mapping.dart';
import '../media_store.dart' show MediaWipe;
import '../remote/remote_api.dart';
import 'outbox.dart';

/// Pull rows changed since the cursor minus this overlap: `updated_at` is the
/// writer's transaction start, so rows can commit slightly "in the past".
/// Re-applying a row is idempotent.
const Duration pullOverlap = Duration(minutes: 1);
const int pullPageSize = 1000;

/// Cursor key holding the user id the cache belongs to.
const String ownerCursorKey = '_owner';

/// Owner recorded by a wipe (sign-out, account deletion): belongs to nobody,
/// so whoever signs in next starts from an empty cache.
const String wipedOwner = '_wiped';

/// Cursor key of the `checkin_tombstones` RPC (other members' deletions).
const String tombstoneCursorKey = 'checkin_tombstones';

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
  bool _paused = false;

  bool get isPaused => _paused;

  void setPaused(bool paused) {
    _paused = paused;
    if (paused) invalidateSession();
  }

  /// Session generation: bumped by [invalidateSession] when the cache is
  /// wiped. A pull started in an older generation (or for another user)
  /// stops before its next local write instead of refilling the wiped cache
  /// with the previous account's rows and cursors.
  int _epoch = 0;

  /// Generation and user of the running [_pullOnce] (pulls are serialized).
  int _runEpoch = 0;
  String? _runUser;
  final _changes = StreamController<void>.broadcast();
  final _completedPulls = StreamController<void>.broadcast();

  /// Fires after server data was applied locally (pull, outbox success).
  Stream<void> get changes => _changes.stream;

  /// Fires when the full pull has applied the server's journeys and memberships.
  Stream<void> get completedPulls => _completedPulls.stream;

  void notifyChanged() {
    if (!_changes.isClosed) _changes.add(null);
  }

  /// Wipes the cache when it belongs to a different user than [userId], then
  /// records [userId] as the owner. Also called at sign-in and before local
  /// writes, so rows written right after signing in are owned from the start.
  ///
  /// A recorded owner other than [userId] (including [wipedOwner], left by a
  /// sign-out) or no owner at all means every row, queued write and media file
  /// belongs to somebody else (or to a write that was in flight while the
  /// session was wiped): all of it goes, the outbox too, so a stale queued
  /// write never runs under the new session. The current user's own offline
  /// writes are safe because they are only written after this recorded them
  /// as owner. Read, wipe and write of the owner happen in one transaction
  /// (drift serializes them), so concurrent callers cannot wipe each other's
  /// fresh writes.
  Future<void> ensureOwner(String userId, {bool checkRun = false}) async {
    if (await db.readCursor(ownerCursorKey) == userId) return;
    final drafts = Directory(
      p.join(store.files.root.parent.path, checkinDraftDirName),
    );
    // Rows, files and drafts of the previous owner (or of the wiped marker)
    // go together; see [MediaWipe] for the failure/rollback rules.
    await MediaWipe.run(
      db,
      [store.files.root, drafts],
      (moveMedia) => db.transaction(() async {
        if (checkRun) _checkRun();
        if (await db.readCursor(ownerCursorKey) == userId) return;
        await db.wipe();
        await moveMedia();
        await db.writeCursor(ownerCursorKey, userId);
      }),
    );
  }

  /// Called when the local cache is wiped (sign-out, account deletion):
  /// pulls still in flight for the old session write nothing more.
  void invalidateSession() => _epoch++;

  void _checkSession(int epoch, String? me) {
    if (_paused || epoch != _epoch || remote.currentUserId != me) {
      throw const _SessionChanged();
    }
  }

  void _checkRun() => _checkSession(_runEpoch, _runUser ?? '');

  /// Runs [body] in one transaction that first checks the pull still belongs
  /// to the current session (the wipe is a transaction too, so they never
  /// interleave).
  Future<void> _write(Future<void> Function() body) => db.transaction(() async {
    _checkRun();
    await body();
  });

  // --- push -------------------------------------------------------------------

  /// Applies a server journey row unless the session changed (sign-out wiped
  /// the cache) while the request was in flight.
  Future<void> _applyJourneyIfSession(
    Object? row,
    int epoch,
    String? user,
  ) async {
    if (row is! Map) return;
    if (epoch != _epoch || remote.currentUserId != user) return;
    await store.applyJourney(row.cast<String, dynamic>());
  }

  Future<void> execute(OutboxKind kind, Map<String, dynamic> p) async {
    final epoch = _epoch;
    final user = remote.currentUserId;
    void check() => _checkSession(epoch, user);
    check();
    switch (kind) {
      case OutboxKind.createJourney:
        final row = await remote.rpc(
          'create_journey',
          p.cast<String, dynamic>(),
        );
        await _applyJourneyIfSession(row, epoch, user);
      case OutboxKind.upsertCheckIn:
        await _pushCheckIn(p['id'] as String, check);
      case OutboxKind.deleteMedia:
        final paths = <String>{
          ...(p['paths'] as List? ?? const []).cast<String>(),
        };
        for (final prefix
            in (p['prefixes'] as List? ?? const []).cast<String>()) {
          check();
          paths.addAll(await remote.listFiles(prefix));
        }
        check();
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
      case OutboxKind.updateJourney:
        final row = await remote.rpc(
          'update_journey',
          p.cast<String, dynamic>(),
        );
        await _applyJourneyIfSession(row, epoch, user);
      case OutboxKind.renameCouple:
        final row = await remote.rpc(
          'rename_couple',
          p.cast<String, dynamic>(),
        );
        await _applyJourneyIfSession(row, epoch, user);
      case OutboxKind.updateMembership:
        final values = {
          if (p.containsKey('hide_metric')) 'hide_metric': p['hide_metric'],
          if (p.containsKey('blur_media')) 'blur_media': p['blur_media'],
          if (p.containsKey('hide_extras')) 'hide_extras': p['hide_extras'],
          if (p.containsKey('pinned')) 'pinned': p['pinned'],
        };
        await remote.update(
          'memberships',
          values,
          match: {
            'journey_id': p['journey_id'] as String,
            'user_id': p['user_id'] as String,
            // A legacy repair can only tell whether the bit was set on this
            // device. Avoid touching updated_at if it already reached server.
            if (values.length == 1 && values['hide_metric'] == true)
              'hide_metric': false,
          },
        );
    }
    check();
    notifyChanged();
  }

  Future<void> _pushCheckIn(String id, void Function() check) async {
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
    check();
    await remote.uploadFile(row.photoPath, photo);
    check();
    await remote.uploadFile(row.thumbPath, thumb);
    check();
    final partnerPath = row.partnerPhotoPath;
    if (partnerPath != null) {
      final partner = store.files.fileFor(partnerPath);
      if (!partner.existsSync()) {
        throw OurneyException(
          OurneyErrorCode.invalid,
          'missing partner media for $id',
        );
      }
      await remote.uploadFile(partnerPath, partner);
    }
    check();
    await remote.upsert('check_ins', checkInToRemote(row), onConflict: 'id');
    // Metrics live in their own table (RLS honours hide_metric, 0005).
    check();
    await remote.upsert(
      'check_in_metrics',
      checkInMetricToRemote(row),
      onConflict: 'checkin_id',
    );
    // Extras too (RLS honours hide_extras, 0011).
    check();
    await remote.upsert(
      'check_in_extras',
      checkInExtrasToRemote(row),
      onConflict: 'checkin_id',
    );
    check();
    await (db.update(db.checkIns)..where((t) => t.id.equals(id))).write(
      const CheckInsCompanion(uploaded: Value(true)),
    );
  }

  /// Own check-ins that were never uploaded and have no queue item at all
  /// (not even a dead one): a crash or an old bug lost their outbox row.
  /// Enqueues them again so they are not stuck local forever.
  Future<int> enqueueOrphanUploads(String me) async {
    final rows = await (db.select(
      db.checkIns,
    )..where((t) => t.userId.equals(me) & t.uploaded.equals(false))).get();
    if (rows.isEmpty) return 0;
    final queued = {
      for (final q in await db.select(db.uploadQueue).get()) q.entityKey,
    };
    var n = 0;
    for (final r in rows) {
      final key = checkInKey(r.id);
      if (queued.contains(key)) continue;
      await outbox.enqueue(OutboxKind.upsertCheckIn, key, {'id': r.id});
      n++;
    }
    if (n > 0) debugPrint('sync: re-queued $n orphan check-in upload(s)');
    return n;
  }

  // --- pull -------------------------------------------------------------------

  /// Pulls every table changed since its cursor. Concurrent calls coalesce.
  Future<SyncResult> syncNow() {
    if (_paused) return Future.value(const SyncFailed('update required'));
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
    int epoch;
    do {
      _pullAgain = false;
      epoch = _epoch;
      result = await _pullOnce();
      // A pull cut short by a session change still serves a sync requested
      // meanwhile (the next account signing in).
    } while (!_paused && _pullAgain && (result is SyncOk || epoch != _epoch));
    return result;
  }

  static bool _hasPendingJourneyWrite(Set<String> pending, String id) =>
      pending.contains(journeyKey(id)) ||
      pending.contains('${journeyKey(id)}:edit') ||
      pending.contains('${journeyKey(id)}:extras') ||
      pending.contains('${journeyKey(id)}:couple');

  Future<SyncResult> _pullOnce() async {
    final me = remote.currentUserId;
    if (me == null) return const SyncFailed('signed out');
    _runEpoch = _epoch;
    _runUser = me;
    try {
      // Not inside `_write`: the media wipe must not run in a nested
      // transaction (its commit would only be a savepoint).
      await ensureOwner(me, checkRun: true);
      _checkRun();
      await enqueueOrphanUploads(me);
      var pending = await outbox.pendingKeys();
      // A local edit still waiting in the outbox wins over the server copy
      // (it will be pushed, and the next pull brings the merged result).
      // Re-read per page: a flush may drain items while pulling.
      await _pullTable('journeys', (r) async {
        final id = r['id'];
        if (id is String &&
            !isTombstone(r) &&
            _hasPendingJourneyWrite(pending, id)) {
          return;
        }
        await store.applyJourney(r);
      }, onPage: () async => pending = await outbox.pendingKeys());
      await _pullTable('memberships', (r) async {
        final id = r['journey_id'];
        // Only MY pending change blocks my own row, and never a `left` row
        // (leaving/removal on the server wins and purges the journey).
        // Other members' rows always apply.
        final mine = r['user_id'] == me;
        final left = r['status'] == MemberStatus.left.wireName || isTombstone(r);
        if (id is String &&
            mine &&
            !left &&
            pending.contains(membershipKey(id))) {
          return;
        }
        await store.applyMembership(r, me: me);
      }, onPage: () async => pending = await outbox.pendingKeys());
      pending = await outbox.pendingKeys();
      await _pullTable(
        'check_ins',
        (r) => store.applyCheckIn(r, pending),
        onPage: () async => pending = await outbox.pendingKeys(),
      );
      await _pullTombstones();
      pending = await outbox.pendingKeys();
      await _pullMetrics(pending);
      pending = await outbox.pendingKeys();
      await _pullExtras(pending, me);
      pending = await outbox.pendingKeys();
      await _pullTable(
        'reactions',
        (r) => store.applyReaction(r, pending, me: me),
        onPage: () async => pending = await outbox.pendingKeys(),
      );
      await _pullTable(
        'blocks',
        (r) => store.applyBlock(r, me: me),
        eq: {'blocker_id': me},
      );
      await _pullTable('profiles', store.applyProfile, eq: {'id': me});
      _checkRun();
      notifyChanged();
      if (!_completedPulls.isClosed) _completedPulls.add(null);
      return const SyncOk();
    } on _SessionChanged {
      return const SyncFailed('session changed');
    } on OurneyException catch (e) {
      if (e.error == OurneyErrorCode.offline) return const SyncOffline();
      return SyncFailed(e.toString());
    }
  }

  Future<void> _pullTable(
    String table,
    Future<void> Function(RemoteRow) apply, {
    Map<String, Object> eq = const {},
    Future<void> Function()? onPage,
  }) => _pullPaged(
    eq.isEmpty ? table : '$table?${eq.keys.join(',')}',
    (since) =>
        remote.select(table, eq: eq, updatedSince: since, limit: pullPageSize),
    (rows) async {
      await onPage?.call();
      for (final r in rows) {
        await apply(r);
      }
    },
  );

  /// Other members' check-ins that were deleted, hidden (author left or was
  /// removed) or moderated. Since 0005 `check_ins` returns soft-deleted rows
  /// to their author only; everybody else gets ids from this RPC.
  Future<void> _pullTombstones() => _pullPaged(
    tombstoneCursorKey,
    (since) async {
      final res = await remote.rpc('checkin_tombstones', {
        'since': since,
        'lim': pullPageSize,
      });
      return [
        if (res is List)
          for (final r in res)
            if (r is Map) r.cast<String, dynamic>(),
      ];
    },
    (rows) async {
      for (final r in rows) {
        await store.applyCheckInTombstone(r['id'] as String);
      }
    },
  );

  /// `check_in_metrics` (own metrics, and others' unless they hide them).
  /// A metric whose check-in is not cached yet (it committed after the
  /// check-ins page was read) fetches that check-in first, so the value is
  /// not lost behind the cursor.
  Future<void> _pullMetrics(Set<String> pending) => _pullPaged(
    'check_in_metrics',
    (since) => remote.select(
      'check_in_metrics',
      updatedSince: since,
      limit: pullPageSize,
    ),
    (rows) => _applyCompanions(rows, pending, store.applyMetric),
  );

  /// `check_in_extras` (own extras, and others' unless they hide them).
  Future<void> _pullExtras(Set<String> pending, String me) => _pullPaged(
    'check_in_extras',
    (since) => remote.select(
      'check_in_extras',
      updatedSince: since,
      limit: pullPageSize,
    ),
    (rows) =>
        _applyCompanions(rows, pending, (r) => store.applyExtras(r, me: me)),
  );

  /// Applies per-check-in companion rows ([apply] returns false when the
  /// check-in is not cached), fetching the missing check-ins first.
  Future<void> _applyCompanions(
    List<RemoteRow> rows,
    Set<String> pending,
    Future<bool> Function(RemoteRow) apply,
  ) async {
    final missing = <String>{};
    await _write(() async {
      for (final r in rows) {
        if (!await apply(r)) missing.add(r['checkin_id'] as String);
      }
    });
    if (missing.isEmpty) return;
    final ids = missing.toList();
    final fetched = <RemoteRow>[];
    for (var i = 0; i < ids.length; i += 100) {
      _checkRun();
      final end = i + 100 > ids.length ? ids.length : i + 100;
      fetched.addAll(
        await remote.select(
          'check_ins',
          inList: {'id': ids.sublist(i, end)},
          onlyLive: true,
        ),
      );
    }
    if (fetched.isEmpty) return;
    await _write(() async {
      for (final c in fetched) {
        await store.applyCheckIn(c, pending);
      }
      for (final r in rows) {
        if (missing.contains(r['checkin_id'])) await apply(r);
      }
    });
  }

  /// Cursor-paged pull: [fetch] gets rows with `updated_at >= since`
  /// (ascending), [applyPage] stores one page (in one guarded transaction
  /// with its cursor).
  Future<void> _pullPaged(
    String key,
    Future<List<RemoteRow>> Function(String? since) fetch,
    Future<void> Function(List<RemoteRow> rows) applyPage,
  ) async {
    var cursor = await db.readCursor(key);
    var since = cursor == null
        ? null
        : DateTime.parse(cursor)
              .toUtc()
              .subtract(pullOverlap)
              .toIso8601String();
    while (true) {
      _checkRun();
      final rows = await fetch(since);
      _checkRun();
      if (rows.isEmpty) return;
      final last = rows.last['updated_at'] as String?;
      await _write(() async {
        await applyPage(rows);
        if (last != null) await db.writeCursor(key, last);
      });
      if (last == null) return;
      final advanced = last != cursor;
      cursor = last;
      if (rows.length < pullPageSize || !advanced) return;
      since = DateTime.parse(last).toUtc().toIso8601String();
    }
  }

  /// An outbox item was given up on or discarded: the pull skipped server
  /// versions of its entity while it was pending and the cursor moved on, so
  /// refresh that journey now. Never throws.
  Future<void> repullAfterDrop(OutboxKind? kind, String entityKey) async {
    // A dead create_journey must not purge the (only) local copy.
    if (kind == null ||
        kind == OutboxKind.createJourney ||
        kind == OutboxKind.deleteMedia) {
      return;
    }
    try {
      final parts = entityKey.split(':');
      final id = parts.length < 2 ? null : parts[1];
      if (id == null) return;
      String? journeyId;
      if (parts[0] == 'journey' || parts[0] == 'membership') {
        journeyId = id;
      } else {
        final c = await (db.select(
          db.checkIns,
        )..where((t) => t.id.equals(id))).getSingleOrNull();
        journeyId = c?.journeyId;
      }
      if (journeyId != null) await pullJourney(journeyId);
    } on Object catch (e) {
      debugPrint('sync: re-pull after a dropped item failed: $e');
    }
  }

  /// Full refresh of one journey (after join/rejoin, unblock, or when a
  /// group screen opens): rows that disappeared server-side without a
  /// tombstone (RLS: blocks, reports) are dropped locally.
  Future<void> pullJourney(String journeyId) async {
    final me = remote.currentUserId;
    if (_paused || me == null) return;
    final epoch = _epoch;
    try {
      await _pullJourney(journeyId, me, epoch);
    } on _SessionChanged {
      // Signed out meanwhile: the old account's rows must not come back.
    }
  }

  /// True when the journey may exist only on this device: live outbox work
  /// for it or its check-ins, or its own create_journey item (even dead).
  Future<bool> _hasQueuedWork(String journeyId) async {
    final ids =
        await (db.selectOnly(db.checkIns)
              ..addColumns([db.checkIns.id])
              ..where(db.checkIns.journeyId.equals(journeyId)))
            .map((r) => r.read(db.checkIns.id)!)
            .get();
    final keys = [
      journeyKey(journeyId),
      '${journeyKey(journeyId)}:extras',
      '${journeyKey(journeyId)}:edit',
      '${journeyKey(journeyId)}:couple',
      membershipKey(journeyId),
      for (final id in ids) ...[checkInKey(id), reactionKey(id)],
    ];
    final rows =
        await (db.select(db.uploadQueue)
              ..where(
                (t) =>
                    t.entityKey.isIn(keys) &
                    // Live work always protects. A dead item protects only
                    // when it is the journey's own create_journey: the mark
                    // of a journey the server never had. Other dead items
                    // (the server said no) must not keep a deleted journey.
                    (t.dead.equals(false) |
                        t.kind.equals(OutboxKind.createJourney.wire)),
              )
              ..limit(1))
            .get();
    return rows.isNotEmpty;
  }

  Future<void> _pullJourney(String journeyId, String me, int epoch) async {
    void check() => _checkSession(epoch, me);
    final journeys = await remote.select('journeys', eq: {'id': journeyId});
    check();
    if (journeys.isEmpty) {
      // Never purge a journey that exists only here: any queue row (live or
      // dead, e.g. its own create_journey) or an unsent check-in keeps it.
      if (!await _hasQueuedWork(journeyId)) {
        await db.transaction(() async {
          _checkSession(epoch, me);
          await store.purgeJourney(journeyId);
        });
      }
      notifyChanged();
      return;
    }
    final members = await remote.select(
      'memberships',
      eq: {'journey_id': journeyId},
    );
    check();
    final checkIns = await remote.select(
      'check_ins',
      eq: {'journey_id': journeyId},
      onlyLive: true,
    );
    check();
    final ids = [for (final c in checkIns) c['id'] as String];
    final metrics = await remote.select(
      'check_in_metrics',
      eq: {'journey_id': journeyId},
    );
    check();
    final extras = await remote.select(
      'check_in_extras',
      eq: {'journey_id': journeyId},
    );
    final reactions = <RemoteRow>[];
    for (var i = 0; i < ids.length; i += 100) {
      check();
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
      _checkSession(epoch, me);
      // Read pending inside the transaction so edits, membership toggles,
      // check-ins or reactions queued while the 6 HTTP calls were in flight
      // are never overwritten or deleted (FS-10).
      final freshPending = await outbox.pendingKeys();
      final journeyRow = journeys.first;
      if (isTombstone(journeyRow) ||
          !_hasPendingJourneyWrite(freshPending, journeyId)) {
        await store.applyJourney(journeyRow);
      }
      for (final m in members) {
        final mine = m['user_id'] == me;
        final left =
            m['status'] == MemberStatus.left.wireName || isTombstone(m);
        if (mine && !left && freshPending.contains(membershipKey(journeyId))) {
          continue;
        }
        await store.applyMembership(m, me: me);
      }
      final live = ids.toSet();
      // PostgREST caps a response at 1000 rows: a capped list is not the
      // whole journey, so it must not decide what was deleted remotely.
      final stale = checkIns.length >= pullPageSize
          ? const <CheckInRow>[]
          : await (db.select(db.checkIns)..where(
                  (t) =>
                      t.journeyId.equals(journeyId) &
                      t.uploaded.equals(true) &
                      t.id.isNotIn(live),
                ))
                .get();
      await store.deleteCheckIns(stale);
      for (final c in checkIns) {
        await store.applyCheckIn(c, freshPending);
      }
      for (final m in metrics) {
        await store.applyMetric(m);
      }
      for (final e in extras) {
        await store.applyExtras(e, me: me);
      }
      final liveReactions = {
        for (final r in reactions) '${r['checkin_id']}|${r['user_id']}',
      };
      final local = await (db.select(
        db.reactions,
      )..where((t) => t.checkInId.isIn(ids))).get();
      for (final r in local) {
        final mine =
            r.userId == me && freshPending.contains(reactionKey(r.checkInId));
        if (!mine && !liveReactions.contains('${r.checkInId}|${r.userId}')) {
          await (db.delete(db.reactions)..where(
                (t) =>
                    t.checkInId.equals(r.checkInId) & t.userId.equals(r.userId),
              ))
              .go();
        }
      }
      for (final r in reactions) {
        await store.applyReaction(r, freshPending, me: me);
      }
    });
    notifyChanged();
  }

  void dispose() {
    unawaited(_changes.close());
    unawaited(_completedPulls.close());
  }
}

/// A pull outlived its session (sign-out / account deletion wiped the cache).
class _SessionChanged implements Exception {
  const _SessionChanged();
}
