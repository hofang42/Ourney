import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;

import 'data_context.dart';
import 'db/app_database.dart';
import 'local_store.dart' show checkInKey, reactionKey;
import 'sync/outbox.dart';

/// A check-in the outbox gave up uploading (permanent server error or too many
/// failed attempts). The photo is still on the device.
class DeadUpload {
  const DeadUpload({
    required this.queueId,
    required this.checkInId,
    required this.journeyId,
    this.lastError,
  });

  final int queueId;
  final String checkInId;
  final String journeyId;
  final String? lastError;
}

/// Lets the UI surface dead check-in uploads and offer Retry / Discard.
class DeadUploads {
  DeadUploads(this._ctx);

  final DataContext _ctx;

  /// Dead check-in uploads of [journeyId] (all journeys when null).
  Stream<List<DeadUpload>> watch({String? journeyId}) {
    final outbox = _ctx.outbox;
    if (outbox == null) return Stream.value(const []);
    return outbox.watchDead(kind: OutboxKind.upsertCheckIn).asyncMap((
      rows,
    ) async {
      final out = <DeadUpload>[];
      for (final r in rows) {
        final id = _checkInId(r);
        if (id == null) continue;
        final c = await (_ctx.db.select(
          _ctx.db.checkIns,
        )..where((t) => t.id.equals(id))).getSingleOrNull();
        if (c == null || c.uploaded) continue;
        if (journeyId != null && c.journeyId != journeyId) continue;
        out.add(
          DeadUpload(
            queueId: r.id,
            checkInId: id,
            journeyId: c.journeyId,
            lastError: r.lastError,
          ),
        );
      }
      return out;
    });
  }

  /// Puts [items] back in the queue and uploads them now.
  Future<void> retry(List<DeadUpload> items) async {
    final outbox = _ctx.outbox;
    if (outbox == null || items.isEmpty) return;
    await outbox.retryDead([for (final i in items) i.queueId]);
  }

  /// Drops [items] and the local check-ins (and photos) they were for.
  Future<void> discard(List<DeadUpload> items) async {
    final outbox = _ctx.outbox;
    if (outbox == null || items.isEmpty) return;
    final db = _ctx.db;
    final wanted = [for (final i in items) i.checkInId];
    late final List<CheckInRow> local;
    // Rows are read inside the transaction, so what is deleted is exactly
    // what was seen; queue rows and check-ins go together, or neither does.
    await db.transaction(() async {
      final rows = await (db.select(
        db.checkIns,
      )..where((t) => t.id.isIn(wanted))).get();
      // Only rows that never reached the server: an uploaded one stays.
      local = [
        for (final r in rows)
          if (!r.uploaded) r,
      ];
      final ids = [for (final r in local) r.id];
      await outbox.deleteItems([for (final i in items) i.queueId]);
      // Any other item for these check-ins (a queued reaction, a second
      // upload) would fail once the row is gone.
      await (db.delete(db.uploadQueue)..where(
            (t) => t.entityKey.isIn([
              for (final id in ids) ...[checkInKey(id), reactionKey(id)],
            ]),
          ))
          .go();
      await (db.delete(db.reactions)..where((t) => t.checkInId.isIn(ids))).go();
      await (db.delete(db.checkIns)..where((t) => t.id.isIn(ids))).go();
    });
    debugPrint('dead uploads: discarded ${local.length} check-in(s)');
    await _ctx.files.delete([
      for (final r in local) ...[
        r.photoPath,
        r.thumbPath,
        if (r.partnerPhotoPath != null) r.partnerPhotoPath!,
      ],
    ]);
    // The pull skipped server versions while these were pending.
    for (final j in {for (final i in items) i.journeyId}) {
      try {
        await _ctx.sync?.pullJourney(j);
      } on Object catch (e) {
        debugPrint('dead uploads: re-pull of $j failed: $e');
      }
    }
  }

  static String? _checkInId(OutboxRow row) {
    try {
      final id = (jsonDecode(row.payload) as Map)['id'];
      return id is String ? id : null;
    } on Object {
      return null;
    }
  }
}
