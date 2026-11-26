import 'package:drift/drift.dart';
import 'package:ourney_core/ourney_core.dart';

import 'db/app_database.dart';
import 'mapping.dart';
import 'media_store.dart';
import 'remote/remote_api.dart';
import 'sync/outbox.dart';

/// Outbox entity keys (see `upload_queue.entity_key`).
/// One key per check-in: several check-ins per day are allowed (FR-C7, 0014).
String checkInKey(String checkInId) => 'checkin:$checkInId';
String reactionKey(String checkInId) => 'react:$checkInId';
String membershipKey(String journeyId) => 'membership:$journeyId';
String journeyKey(String journeyId) => 'journey:$journeyId';

/// Cache mutations shared by repositories and pull sync.
class LocalStore {
  LocalStore(this.db, this.files);

  final AppDatabase db;
  final MediaFiles files;

  // --- deletes ----------------------------------------------------------------

  /// Removes a journey and everything cached under it (rows and media).
  Future<void> purgeJourney(String journeyId) async {
    await db.transaction(() async {
      final ids =
          await (db.selectOnly(db.checkIns)
                ..addColumns([db.checkIns.id])
                ..where(db.checkIns.journeyId.equals(journeyId)))
              .map((r) => r.read(db.checkIns.id)!)
              .get();
      // Queued uploads for rows that no longer exist would only fail (or
      // resurrect data); media deletions stay, they must still run.
      await (db.delete(db.uploadQueue)..where(
            (t) =>
                t.kind.equals(OutboxKind.deleteMedia.wire).not() &
                t.entityKey.isIn([
                  journeyKey(journeyId),
                  '${journeyKey(journeyId)}:extras',
                  '${journeyKey(journeyId)}:edit',
                  '${journeyKey(journeyId)}:couple',
                  membershipKey(journeyId),
                  for (final id in ids) ...[checkInKey(id), reactionKey(id)],
                ]),
          ))
          .go();
      await (db.delete(db.reactions)..where((t) => t.checkInId.isIn(ids))).go();
      await (db.delete(
        db.checkIns,
      )..where((t) => t.journeyId.equals(journeyId))).go();
      await (db.delete(
        db.memberships,
      )..where((t) => t.journeyId.equals(journeyId))).go();
      await (db.delete(db.journeys)..where((t) => t.id.equals(journeyId))).go();
    });
    await files.deleteFolder('checkins/$journeyId');
  }

  Future<void> deleteCheckIns(List<CheckInRow> rows) async {
    if (rows.isEmpty) return;
    final ids = [for (final r in rows) r.id];
    await db.transaction(() async {
      await (db.delete(db.reactions)..where((t) => t.checkInId.isIn(ids))).go();
      await (db.delete(db.checkIns)..where((t) => t.id.isIn(ids))).go();
    });
    await files.delete([
      for (final r in rows) ...[
        r.photoPath,
        r.thumbPath,
        if (r.partnerPhotoPath != null) r.partnerPhotoPath!,
      ],
    ]);
  }

  /// Drops everything cached from [userId] (after a block / removal).
  Future<void> forgetUserContent(String userId, {String? journeyId}) async {
    final rows =
        await (db.select(db.checkIns)..where(
              (t) =>
                  t.userId.equals(userId) &
                  (journeyId == null
                      ? const Constant(true)
                      : t.journeyId.equals(journeyId)),
            ))
            .get();
    await deleteCheckIns(rows);
    if (journeyId == null) {
      await (db.delete(
        db.reactions,
      )..where((t) => t.userId.equals(userId))).go();
      await files.deleteFolder('avatars/$userId');
    }
  }

  // --- applying server rows ---------------------------------------------------

  Future<void> applyJourney(RemoteRow r) async {
    if (isTombstone(r)) {
      await purgeJourney(r['id'] as String);
      return;
    }
    await db.into(db.journeys).insertOnConflictUpdate(journeyFromRemote(r));
  }

  Future<void> applyMembership(RemoteRow r, {required String me}) async {
    final m = membershipFromRemote(r);
    if (m.userId.value == me && m.status.value == MemberStatus.left.wireName) {
      // We left or were removed: the journey is no longer ours to show.
      await purgeJourney(m.journeyId.value);
      return;
    }
    await db.into(db.memberships).insertOnConflictUpdate(m);
    if (m.userId.value != me && m.hideMetric.value) {
      // The member now hides their metric: drop values cached earlier.
      await (db.update(db.checkIns)..where(
            (t) =>
                t.journeyId.equals(m.journeyId.value) &
                t.userId.equals(m.userId.value),
          ))
          .write(const CheckInsCompanion(metricValue: Value(null)));
    }
    if (m.userId.value != me && m.hideExtras.value) {
      // Same for the extras (mood, minutes, km ...) of a member who hides them.
      await (db.update(db.checkIns)..where(
            (t) =>
                t.journeyId.equals(m.journeyId.value) &
                t.userId.equals(m.userId.value),
          ))
          .write(const CheckInsCompanion(extras: Value('{}')));
    }
  }

  /// Applies a `check_in_extras` row; same contract as [applyMetric].
  Future<bool> applyExtras(RemoteRow r, {required String me}) async {
    final e = extrasFromRemote(r);
    final row = await (db.select(
      db.checkIns,
    )..where((t) => t.id.equals(e.checkInId))).getSingleOrNull();
    if (row == null) return false;
    // Defence in depth (RLS already withholds them): never cache another
    // member's extras while they hide them.
    final hidden =
        row.userId != me &&
        await (db.select(db.memberships)..where(
                  (t) =>
                      t.journeyId.equals(row.journeyId) &
                      t.userId.equals(row.userId) &
                      t.hideExtras.equals(true),
                ))
                .getSingleOrNull() !=
            null;
    if (row.uploaded && !hidden) {
      await (db.update(db.checkIns)..where((t) => t.id.equals(e.checkInId)))
          .write(CheckInsCompanion(extras: Value(e.extras)));
    }
    return true;
  }

  /// Applies a `check_in_metrics` row. Returns false when the check-in is
  /// not cached yet (the caller fetches it, then applies again). A local,
  /// not yet uploaded take is never overwritten.
  Future<bool> applyMetric(RemoteRow r) async {
    final m = metricFromRemote(r);
    final row = await (db.select(
      db.checkIns,
    )..where((t) => t.id.equals(m.checkInId))).getSingleOrNull();
    if (row == null) return false;
    if (row.uploaded) {
      await (db.update(db.checkIns)..where((t) => t.id.equals(m.checkInId)))
          .write(CheckInsCompanion(metricValue: Value(m.value)));
    }
    return true;
  }

  /// A `checkin_tombstones` entry: another member's check-in was deleted,
  /// hidden (author left / removed) or moderated.
  Future<void> applyCheckInTombstone(String checkInId) async {
    final rows = await (db.select(
      db.checkIns,
    )..where((t) => t.id.equals(checkInId) & t.uploaded.equals(true))).get();
    await deleteCheckIns(rows);
  }

  Future<void> applyCheckIn(RemoteRow r, Set<String> pending) async {
    final id = r['id'] as String;
    if (isTombstone(r)) {
      final rows = await (db.select(
        db.checkIns,
      )..where((t) => t.id.equals(id) & t.uploaded.equals(true))).get();
      await deleteCheckIns(rows);
      return;
    }
    if (pending.contains(checkInKey(id))) return;
    // Several check-ins per day are separate rows (FR-C7, 0014): a pulled
    // row never replaces another photo of the same day.
    await db.into(db.checkIns).insertOnConflictUpdate(checkInFromRemote(r));
  }

  Future<void> applyReaction(
    RemoteRow r,
    Set<String> pending, {
    required String me,
  }) async {
    final checkInId = r['checkin_id'] as String;
    final userId = r['user_id'] as String;
    if (userId == me && pending.contains(reactionKey(checkInId))) return;
    if (isTombstone(r)) {
      await (db.delete(db.reactions)..where(
            (t) => t.checkInId.equals(checkInId) & t.userId.equals(userId),
          ))
          .go();
      return;
    }
    await db.into(db.reactions).insertOnConflictUpdate(reactionFromRemote(r));
  }

  Future<void> applyBlock(RemoteRow r, {required String me}) async {
    if (r['blocker_id'] != me) return;
    final blocked = r['blocked_id'] as String;
    if (isTombstone(r)) {
      await (db.delete(
        db.blocks,
      )..where((t) => t.blockedId.equals(blocked))).go();
      return;
    }
    await db
        .into(db.blocks)
        .insertOnConflictUpdate(
          BlocksCompanion(
            blockedId: Value(blocked),
            updatedAt: Value(r['updated_at'] as String?),
          ),
        );
    await forgetUserContent(blocked);
  }

  Future<void> applyProfile(RemoteRow r) async {
    if (isTombstone(r)) {
      await (db.delete(
        db.profiles,
      )..where((t) => t.id.equals(r['id']! as String))).go();
      return;
    }
    await db.into(db.profiles).insertOnConflictUpdate(profileFromRemote(r));
  }
}
