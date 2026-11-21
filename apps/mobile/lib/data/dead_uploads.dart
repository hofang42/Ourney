import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import 'data_context.dart';
import 'db/app_database.dart';
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
        if (c == null) continue;
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
    final rows = await (_ctx.db.select(
      _ctx.db.checkIns,
    )..where((t) => t.id.isIn([for (final i in items) i.checkInId]))).get();
    debugPrint('dead uploads: discarding ${rows.length} check-in(s)');
    await outbox.deleteItems([for (final i in items) i.queueId]);
    // Only rows that never reached the server: an uploaded one stays.
    await _ctx.store.deleteCheckIns([
      for (final r in rows)
        if (!r.uploaded) r,
    ]);
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
