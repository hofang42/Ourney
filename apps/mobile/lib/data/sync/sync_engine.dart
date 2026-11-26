import 'dart:async';
import 'dart:convert';
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

/// Sibling directory (next to the media root) holding unsynced check-in media
/// isolated per user ID when a different user signs in after a session expiry.
const String isolatedMediaDirName = 'isolated_media';

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
  /// When the previous owner was a real user ([ownerCursorKey] != [wipedOwner])
  /// whose session expired with unsynced local posts or queued outbox items,
  /// their unsynced queue, check-ins, journeys and media files are isolated
  /// under [isolatedOutboxCursorKey] and [isolatedMediaDirName] before the
  /// active cache is wiped for [userId] (so they are never uploaded under the
  /// new user, nor lost). If that user signs back in later, their isolated
  /// work is automatically restored and resumed.
  Future<void> ensureOwner(String userId, {bool checkRun = false}) async {
    final currentOwner = await db.readCursor(ownerCursorKey);
    if (currentOwner == userId) {
      if (await db.readCursor(isolatedOutboxCursorKey(userId)) != null) {
        await _restoreIsolatedWork(userId);
      }
      return;
    }
    if (currentOwner != null &&
        currentOwner != wipedOwner &&
        currentOwner != userId) {
      await enqueueOrphanUploads(currentOwner);
      await _isolateOwnerUnsyncedWork(currentOwner);
    }
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
    if (await db.readCursor(isolatedOutboxCursorKey(userId)) != null) {
      await _restoreIsolatedWork(userId);
    }
  }

  Directory _isolatedMediaRootFor(String userId) => Directory(
    p.join(store.files.root.parent.path, isolatedMediaDirName, userId),
  );

  /// True when [userId] has an isolated unsynced outbox/post bundle parked
  /// across an account switch.
  Future<bool> hasIsolatedWorkFor(String userId) async =>
      await db.readCursor(isolatedOutboxCursorKey(userId)) != null;

  /// Entity keys in [userId]'s isolated outbox bundle (empty when none).
  Future<List<String>> isolatedEntityKeysFor(String userId) async {
    final raw = await db.readCursor(isolatedOutboxCursorKey(userId));
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const [];
      final queue = decoded['uploadQueue'];
      if (queue is! List) return const [];
      return [
        for (final item in queue)
          if (item is Map && item['entityKey'] is String)
            item['entityKey'] as String,
      ];
    } on Object {
      return const [];
    }
  }

  /// Removes any isolated media directory for [userId] (on explicit sign-out
  /// or account deletion by [userId]).
  Future<void> deleteIsolatedMediaFor(String userId) async {
    final dir = _isolatedMediaRootFor(userId);
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
  }

  Future<Set<String>> _referencedJourneyIds(
    List<OutboxRow> queueRows,
    List<CheckInRow> unsyncedCheckIns,
    List<ImportJobRow> importJobs,
  ) async {
    final ids = <String>{
      for (final c in unsyncedCheckIns) c.journeyId,
      for (final j in importJobs) j.id,
    };
    final checkInIdsToLookup = <String>{};
    for (final q in queueRows) {
      final parts = q.entityKey.split(':');
      if (parts.length < 2) continue;
      final prefix = parts[0];
      final targetId = parts[1];
      if (prefix == 'journey' || prefix == 'membership') {
        ids.add(targetId);
      } else if (prefix == 'checkin' || prefix == 'react') {
        checkInIdsToLookup.add(targetId);
      }
    }
    if (checkInIdsToLookup.isNotEmpty) {
      final rows = await (db.select(
        db.checkIns,
      )..where((t) => t.id.isIn(checkInIdsToLookup))).get();
      for (final r in rows) {
        ids.add(r.journeyId);
      }
    }
    return ids;
  }

  /// Wipes all synced SQLite rows and cached private media on remote session
  /// revocation/expiry (F-08), while keeping any unsynced check-ins, their
  /// local media files, their parent journey metadata, and the outbox queue
  /// intact so they can resume after re-sign-in (F-10).
  Future<void> purgeSyncedOnSessionExpiry({
    required Directory draftsDir,
  }) async {
    final owner = await db.readCursor(ownerCursorKey);
    if (owner != null && owner != wipedOwner) {
      await enqueueOrphanUploads(owner);
    }
    final queueRows = await db.select(db.uploadQueue).get();
    final unsyncedCheckIns = await (db.select(
      db.checkIns,
    )..where((t) => t.uploaded.equals(false))).get();
    final importJobs = await db.select(db.importJobs).get();

    final hasUnsyncedWork =
        owner != null &&
        owner != wipedOwner &&
        (queueRows.isNotEmpty ||
            unsyncedCheckIns.isNotEmpty ||
            importJobs.isNotEmpty);

    if (!hasUnsyncedWork) {
      await MediaWipe.run(
        db,
        [store.files.root, draftsDir],
        (moveMedia) => db.transaction(() async {
          await db.wipe();
          await db.writeCursor(ownerCursorKey, wipedOwner);
          await moveMedia();
        }),
      );
      return;
    }

    final keptJourneyIds = await _referencedJourneyIds(
      queueRows,
      unsyncedCheckIns,
      importJobs,
    );
    final pendingReactionCheckInIds = <String>{
      for (final q in queueRows)
        if (q.entityKey.startsWith('react:'))
          q.entityKey.substring('react:'.length),
    };
    final syncedCheckIns = await (db.select(
      db.checkIns,
    )..where((t) => t.uploaded.equals(true))).get();
    final allJourneys = await db.select(db.journeys).get();
    final purgedJourneyIds = [
      for (final j in allJourneys)
        if (!keptJourneyIds.contains(j.id)) j.id,
    ];

    await db.transaction(() async {
      await db.delete(db.profiles).go();
      await db.delete(db.blocks).go();
      if (pendingReactionCheckInIds.isEmpty) {
        await db.delete(db.reactions).go();
      } else {
        await (db.delete(db.reactions)..where(
              (t) =>
                  (t.userId.equals(owner) &
                          t.checkInId.isIn(pendingReactionCheckInIds))
                      .not(),
            ))
            .go();
      }
      await (db.delete(db.checkIns)..where((t) => t.uploaded.equals(true))).go();
      await (db.delete(
        db.memberships,
      )..where((t) => t.userId.equals(owner).not())).go();
      if (purgedJourneyIds.isNotEmpty) {
        await (db.delete(
          db.memberships,
        )..where((t) => t.journeyId.isIn(purgedJourneyIds))).go();
        await (db.delete(
          db.journeys,
        )..where((t) => t.id.isIn(purgedJourneyIds))).go();
      }
      await (db.delete(db.syncCursor)..where(
            (t) =>
                t.tableKey.equals(ownerCursorKey).not() &
                t.tableKey.equals(pendingTrashCursorKey).not() &
                t.tableKey.like('$isolatedOutboxCursorPrefix%').not(),
          ))
          .go();
    });

    await store.files.delete([
      for (final r in syncedCheckIns) ...[
        r.photoPath,
        r.thumbPath,
        if (r.partnerPhotoPath != null) r.partnerPhotoPath!,
      ],
    ]);
    for (final jid in purgedJourneyIds) {
      await store.files.deleteFolder('checkins/$jid');
    }
    for (final jid in keptJourneyIds) {
      final jDir = Directory(p.join(store.files.root.path, 'checkins', jid));
      if (jDir.existsSync()) {
        for (final entry in jDir.listSync().whereType<Directory>()) {
          if (p.basename(entry.path) != owner) {
            await entry.delete(recursive: true);
          }
        }
      }
    }
    await store.files.deleteFolder('avatars');
    if (draftsDir.existsSync()) {
      await draftsDir.delete(recursive: true);
    }
  }

  Future<void> _isolateOwnerUnsyncedWork(String prevOwner) async {
    final queueRows = await db.select(db.uploadQueue).get();
    final unsyncedCheckIns = await (db.select(
      db.checkIns,
    )..where((t) => t.userId.equals(prevOwner) & t.uploaded.equals(false))).get();
    if (queueRows.isEmpty && unsyncedCheckIns.isEmpty) return;

    final keptJourneyIds = await _referencedJourneyIds(
      queueRows,
      unsyncedCheckIns,
      const [],
    );
    final journeys = keptJourneyIds.isEmpty
        ? const <JourneyRow>[]
        : await (db.select(
            db.journeys,
          )..where((t) => t.id.isIn(keptJourneyIds))).get();
    final memberships = keptJourneyIds.isEmpty
        ? const <MembershipRow>[]
        : await (db.select(db.memberships)..where(
                (t) =>
                    t.journeyId.isIn(keptJourneyIds) &
                    t.userId.equals(prevOwner),
              ))
              .get();
    final pendingReactionCheckInIds = <String>{
      for (final q in queueRows)
        if (q.entityKey.startsWith('react:'))
          q.entityKey.substring('react:'.length),
    };
    final reactions = pendingReactionCheckInIds.isEmpty
        ? const <ReactionRow>[]
        : await (db.select(db.reactions)..where(
                (t) =>
                    t.userId.equals(prevOwner) &
                    t.checkInId.isIn(pendingReactionCheckInIds),
              ))
              .get();

    final isoRoot = _isolatedMediaRootFor(prevOwner);
    for (final c in unsyncedCheckIns) {
      for (final relPath in [
        c.photoPath,
        c.thumbPath,
        if (c.partnerPhotoPath != null) c.partnerPhotoPath!,
      ]) {
        final src = store.files.fileFor(relPath);
        if (src.existsSync()) {
          final dst = File(p.joinAll([isoRoot.path, ...relPath.split('/')]));
          await dst.parent.create(recursive: true);
          await src.copy(dst.path);
        }
      }
    }

    Map<String, dynamic>? existing;
    final prevRaw = await db.readCursor(isolatedOutboxCursorKey(prevOwner));
    if (prevRaw != null && prevRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(prevRaw);
        if (decoded is Map) existing = decoded.cast<String, dynamic>();
      } on Object {
        existing = null;
      }
    }

    List<Map<String, dynamic>> mergeByKey(
      List<dynamic>? oldList,
      List<Map<String, dynamic>> freshList,
      String Function(Map<String, dynamic>) keyOf,
    ) {
      final byKey = <String, Map<String, dynamic>>{};
      for (final item in oldList ?? const []) {
        if (item is Map) {
          final m = item.cast<String, dynamic>();
          byKey[keyOf(m)] = m;
        }
      }
      for (final m in freshList) {
        byKey[keyOf(m)] = m;
      }
      return byKey.values.toList();
    }

    final bundle = <String, dynamic>{
      'ownerId': prevOwner,
      'journeys': mergeByKey(
        existing?['journeys'] as List?,
        [for (final j in journeys) _journeyRowToMap(j)],
        (m) => m['id'] as String,
      ),
      'memberships': mergeByKey(
        existing?['memberships'] as List?,
        [for (final m in memberships) _membershipRowToMap(m)],
        (m) => '${m['journeyId']}|${m['userId']}',
      ),
      'checkIns': mergeByKey(
        existing?['checkIns'] as List?,
        [for (final c in unsyncedCheckIns) _checkInRowToMap(c)],
        (m) => m['id'] as String,
      ),
      'reactions': mergeByKey(
        existing?['reactions'] as List?,
        [for (final r in reactions) _reactionRowToMap(r)],
        (m) => '${m['checkInId']}|${m['userId']}',
      ),
      'uploadQueue': mergeByKey(
        existing?['uploadQueue'] as List?,
        [for (final q in queueRows) _outboxRowToMap(q)],
        (m) => '${m['kind']}|${m['entityKey']}',
      ),
    };
    await db.writeCursor(
      isolatedOutboxCursorKey(prevOwner),
      jsonEncode(bundle),
    );
  }

  Future<void> _restoreIsolatedWork(String userId) async {
    final key = isolatedOutboxCursorKey(userId);
    final raw = await db.readCursor(key);
    if (raw == null || raw.isEmpty) return;

    Map<String, dynamic> bundle;
    try {
      bundle = (jsonDecode(raw) as Map).cast<String, dynamic>();
    } on Object {
      await (db.delete(
        db.syncCursor,
      )..where((t) => t.tableKey.equals(key))).go();
      return;
    }

    final isoRoot = _isolatedMediaRootFor(userId);
    if (isoRoot.existsSync()) {
      for (final entity in isoRoot.listSync(recursive: true)) {
        if (entity is File) {
          final rel = p
              .relative(entity.path, from: isoRoot.path)
              .replaceAll('\\', '/');
          final dst = store.files.fileFor(rel);
          if (!dst.existsSync()) {
            await dst.parent.create(recursive: true);
            await entity.copy(dst.path);
          }
        }
      }
    }

    await db.transaction(() async {
      for (final item in (bundle['journeys'] as List? ?? const [])) {
        if (item is Map) {
          await db
              .into(db.journeys)
              .insert(
                _journeyRowFromMap(item.cast<String, dynamic>()),
                mode: InsertMode.insertOrIgnore,
              );
        }
      }
      for (final item in (bundle['memberships'] as List? ?? const [])) {
        if (item is Map) {
          await db
              .into(db.memberships)
              .insert(
                _membershipRowFromMap(item.cast<String, dynamic>()),
                mode: InsertMode.insertOrIgnore,
              );
        }
      }
      for (final item in (bundle['checkIns'] as List? ?? const [])) {
        if (item is Map) {
          await db
              .into(db.checkIns)
              .insert(
                _checkInRowFromMap(item.cast<String, dynamic>()),
                mode: InsertMode.insertOrIgnore,
              );
        }
      }
      for (final item in (bundle['reactions'] as List? ?? const [])) {
        if (item is Map) {
          await db
              .into(db.reactions)
              .insert(
                _reactionRowFromMap(item.cast<String, dynamic>()),
                mode: InsertMode.insertOrIgnore,
              );
        }
      }
      final existingQueue = await db.select(db.uploadQueue).get();
      final existingKeys = {
        for (final q in existingQueue) '${q.kind}|${q.entityKey}',
      };
      for (final item in (bundle['uploadQueue'] as List? ?? const [])) {
        if (item is Map) {
          final m = item.cast<String, dynamic>();
          final composite = '${m['kind']}|${m['entityKey']}';
          if (existingKeys.add(composite)) {
            await db.into(db.uploadQueue).insert(_outboxCompanionFromMap(m));
          }
        }
      }
      await (db.delete(
        db.syncCursor,
      )..where((t) => t.tableKey.equals(key))).go();
    });

    if (isoRoot.existsSync()) {
      try {
        await isoRoot.delete(recursive: true);
      } on Object {
        // Best-effort cleanup after restore.
      }
    }
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
    if (user == null) {
      throw const OurneyException(
        OurneyErrorCode.unauthenticated,
        'signed out',
      );
    }
    final owner = await db.readCursor(ownerCursorKey);
    if (owner != null && owner != user) {
      throw const OurneyException(
        OurneyErrorCode.unauthenticated,
        'session owner mismatch',
      );
    }
    void check() => _checkSession(epoch, user);
    try {
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
    } on _SessionChanged {
      throw const OurneyException(
        OurneyErrorCode.unauthenticated,
        'session changed',
      );
    }
  }

  Future<void> _pushCheckIn(String id, void Function() check) async {
    final row = await (db.select(
      db.checkIns,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null || row.uploaded) return; // replaced by a retake, or done

    Future<RemoteRow?> findCommittedLegacyRow() async {
      check();
      final matches = await remote.select(
        'check_ins',
        eq: {'id': id, 'user_id': row.userId, 'journey_id': row.journeyId},
        limit: 1,
      );
      return matches.singleOrNull;
    }

    final legacyPath = row.partnerPhotoPath;
    // The old writer could have committed this row before a companion
    // write failed. Its media fields are immutable once it is on the server.
    var committed = legacyPath == null ? null : await findCommittedLegacyRow();
    if (committed == null) {
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
      final body = checkInToRemote(row);
      if (legacyPath == null) {
        await remote.upsert('check_ins', body, onConflict: 'id');
      } else {
        try {
          await remote.insert('check_ins', body);
        } on OurneyException catch (e) {
          // A concurrent legacy write can win between the lookup and
          // insert. Reconcile only when that row actually exists.
          if (e.error != OurneyErrorCode.invalid) rethrow;
          committed = await findCommittedLegacyRow();
          if (committed == null) rethrow;
        }
      }
    }

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
    final committedAttachment = committed?['partner_photo_path'] as String?;
    final discardedAttachment =
        legacyPath != null &&
            committedAttachment == null &&
            legacyPath == checkInPartnerPhotoPath(row.journeyId, row.userId, id)
        ? legacyPath
        : null;
    await db.transaction(() async {
      check();
      final updated =
          await (db.update(db.checkIns)..where((t) => t.id.equals(id))).write(
            CheckInsCompanion(
              uploaded: const Value(true),
              partnerPhotoPath: legacyPath == null
                  ? const Value.absent()
                  : Value(committedAttachment),
            ),
          );
      if (updated > 0 && discardedAttachment != null) {
        // An old attempt might have uploaded the object without its row.
        // Persist cleanup with reconciliation so it can retry independently.
        await outbox.enqueue(
          OutboxKind.deleteMedia,
          '${checkInKey(id)}:legacy-media',
          {
            'paths': [discardedAttachment],
          },
        );
      }
    });
    if (discardedAttachment != null) {
      try {
        await store.files.delete([discardedAttachment]);
      } on Object catch (e) {
        debugPrint('sync: legacy attachment cache cleanup failed: $e');
      }
    }
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
      var hadUnblock = false;
      await _pullTable(
        'blocks',
        (r) async {
          if (r['blocker_id'] == me && isTombstone(r)) {
            hadUnblock = true;
          }
          await store.applyBlock(r, me: me);
        },
        eq: {'blocker_id': me},
      );
      await _pullTable('profiles', store.applyProfile, eq: {'id': me});
      if (hadUnblock) {
        final groups = await (db.select(
          db.journeys,
        )..where((t) => t.kind.equals(JourneyKind.group.wireName))).get();
        for (final g in groups) {
          _checkRun();
          await _pullJourney(g.id, me, _runEpoch);
        }
      }
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

Map<String, dynamic> _journeyRowToMap(JourneyRow r) => {
  'id': r.id,
  'ownerId': r.ownerId,
  'kind': r.kind,
  'templateId': r.templateId,
  'title': r.title,
  'emoji': r.emoji,
  'metricName': r.metricName,
  'metricUnit': r.metricUnit,
  'hideMetricDefault': r.hideMetricDefault,
  'startDate': r.startDate.toString(),
  'durationDays': r.durationDays,
  'timezone': r.timezone,
  'visibility': r.visibility,
  'status': r.status,
  'inviteCode': r.inviteCode,
  'maxMembers': r.maxMembers,
  'publicToken': r.publicToken,
  'origin': r.origin,
  'coupleSelfName': r.coupleSelfName,
  'couplePartnerName': r.couplePartnerName,
  'layout': r.layout,
  'cover': r.cover,
  'color': r.color,
  'reminderTime': r.reminderTime,
  'dna': r.dna,
  'localArchived': r.localArchived,
  'updatedAt': r.updatedAt,
};

JourneysCompanion _journeyRowFromMap(Map<String, dynamic> m) =>
    JourneysCompanion.insert(
      id: m['id'] as String,
      ownerId: m['ownerId'] as String,
      kind: m['kind'] as String,
      templateId: m['templateId'] as String,
      title: m['title'] as String,
      emoji: m['emoji'] as String,
      metricName: Value(m['metricName'] as String?),
      metricUnit: Value(m['metricUnit'] as String?),
      hideMetricDefault: Value(m['hideMetricDefault'] as bool? ?? false),
      startDate: LocalDate.parse(m['startDate'] as String),
      durationDays: Value((m['durationDays'] as num?)?.toInt()),
      timezone: m['timezone'] as String,
      visibility: m['visibility'] as String,
      status: m['status'] as String,
      inviteCode: Value(m['inviteCode'] as String?),
      maxMembers: Value((m['maxMembers'] as num?)?.toInt() ?? 10),
      publicToken: Value(m['publicToken'] as String?),
      origin: Value(m['origin'] as String? ?? 'live'),
      coupleSelfName: Value(m['coupleSelfName'] as String?),
      couplePartnerName: Value(m['couplePartnerName'] as String?),
      layout: Value(m['layout'] as String?),
      cover: Value((m['cover'] as num?)?.toInt()),
      color: Value((m['color'] as num?)?.toInt()),
      reminderTime: Value(m['reminderTime'] as String?),
      dna: Value(m['dna'] as String?),
      localArchived: Value(m['localArchived'] as bool? ?? false),
      updatedAt: Value(m['updatedAt'] as String?),
    );

Map<String, dynamic> _membershipRowToMap(MembershipRow r) => {
  'journeyId': r.journeyId,
  'userId': r.userId,
  'role': r.role,
  'status': r.status,
  'joinedAt': r.joinedAt.toUtc().microsecondsSinceEpoch,
  'hideMetric': r.hideMetric,
  'blurMedia': r.blurMedia,
  'hideExtras': r.hideExtras,
  'pinned': r.pinned,
  'updatedAt': r.updatedAt,
};

MembershipsCompanion _membershipRowFromMap(Map<String, dynamic> m) =>
    MembershipsCompanion.insert(
      journeyId: m['journeyId'] as String,
      userId: m['userId'] as String,
      role: m['role'] as String,
      status: m['status'] as String,
      joinedAt: DateTime.fromMicrosecondsSinceEpoch(
        (m['joinedAt'] as num).toInt(),
        isUtc: true,
      ),
      hideMetric: Value(m['hideMetric'] as bool? ?? false),
      blurMedia: Value(m['blurMedia'] as bool? ?? false),
      hideExtras: Value(m['hideExtras'] as bool? ?? false),
      pinned: Value(m['pinned'] as bool? ?? false),
      updatedAt: Value(m['updatedAt'] as String?),
    );

Map<String, dynamic> _checkInRowToMap(CheckInRow r) => {
  'id': r.id,
  'journeyId': r.journeyId,
  'userId': r.userId,
  'localDate': r.localDate.toString(),
  'capturedAt': r.capturedAt.toUtc().microsecondsSinceEpoch,
  'photoPath': r.photoPath,
  'thumbPath': r.thumbPath,
  'fromLibrary': r.fromLibrary,
  'caption': r.caption,
  'metricValue': r.metricValue,
  'extras': r.extras,
  'partnerPhotoPath': r.partnerPhotoPath,
  'uploaded': r.uploaded,
  'updatedAt': r.updatedAt,
};

CheckInsCompanion _checkInRowFromMap(Map<String, dynamic> m) =>
    CheckInsCompanion.insert(
      id: m['id'] as String,
      journeyId: m['journeyId'] as String,
      userId: m['userId'] as String,
      localDate: LocalDate.parse(m['localDate'] as String),
      capturedAt: DateTime.fromMicrosecondsSinceEpoch(
        (m['capturedAt'] as num).toInt(),
        isUtc: true,
      ),
      photoPath: m['photoPath'] as String,
      thumbPath: m['thumbPath'] as String,
      fromLibrary: Value(m['fromLibrary'] as bool? ?? false),
      caption: Value(m['caption'] as String?),
      metricValue: Value((m['metricValue'] as num?)?.toDouble()),
      extras: Value(m['extras'] as String? ?? '{}'),
      partnerPhotoPath: Value(m['partnerPhotoPath'] as String?),
      uploaded: Value(m['uploaded'] as bool? ?? false),
      updatedAt: Value(m['updatedAt'] as String?),
    );

Map<String, dynamic> _reactionRowToMap(ReactionRow r) => {
  'checkInId': r.checkInId,
  'userId': r.userId,
  'emoji': r.emoji,
  'createdAt': r.createdAt.toUtc().microsecondsSinceEpoch,
  'updatedAt': r.updatedAt,
};

ReactionsCompanion _reactionRowFromMap(Map<String, dynamic> m) =>
    ReactionsCompanion.insert(
      checkInId: m['checkInId'] as String,
      userId: m['userId'] as String,
      emoji: m['emoji'] as String,
      createdAt: DateTime.fromMicrosecondsSinceEpoch(
        (m['createdAt'] as num).toInt(),
        isUtc: true,
      ),
      updatedAt: Value(m['updatedAt'] as String?),
    );

Map<String, dynamic> _outboxRowToMap(OutboxRow r) => {
  'kind': r.kind,
  'entityKey': r.entityKey,
  'payload': r.payload,
  'attempts': r.attempts,
  'nextAttemptAt': r.nextAttemptAt,
  'lastError': r.lastError,
  'dead': r.dead,
  'createdAt': r.createdAt.toUtc().microsecondsSinceEpoch,
};

UploadQueueCompanion _outboxCompanionFromMap(Map<String, dynamic> m) =>
    UploadQueueCompanion.insert(
      kind: m['kind'] as String,
      entityKey: m['entityKey'] as String,
      payload: m['payload'] as String,
      attempts: Value((m['attempts'] as num?)?.toInt() ?? 0),
      nextAttemptAt: Value((m['nextAttemptAt'] as num?)?.toInt() ?? 0),
      lastError: Value(m['lastError'] as String?),
      dead: Value(m['dead'] as bool? ?? false),
      createdAt: DateTime.fromMicrosecondsSinceEpoch(
        (m['createdAt'] as num).toInt(),
        isUtc: true,
      ),
    );
