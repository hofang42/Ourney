import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:ourney_core/ourney_core.dart';

import '../data_context.dart';
import '../db/app_database.dart';
import '../local_store.dart';
import '../mapping.dart';
import '../sync/outbox.dart';

/// Server tolerance for `captured_at` in the future (check_ins trigger).
const Duration capturedAtTolerance = Duration(minutes: 10);

class DataCheckInRepository implements CheckInRepository {
  DataCheckInRepository(this.ctx);

  final DataContext ctx;

  AppDatabase get _db => ctx.db;

  /// Newest first. Check-ins of blocked users are left out.
  @override
  Stream<List<CheckIn>> watchForJourney(String journeyId, {String? userId}) {
    final blocked = _db.selectOnly(_db.blocks)
      ..addColumns([_db.blocks.blockedId]);
    final q = _db.select(_db.checkIns)
      ..where(
        (t) =>
            t.journeyId.equals(journeyId) &
            (userId == null ? const Constant(true) : t.userId.equals(userId)) &
            t.userId.isInQuery(blocked).not(),
      )
      ..orderBy([
        (t) => OrderingTerm.desc(t.localDate),
        (t) => OrderingTerm.asc(t.userId),
        // Several photos a day (0014): newest first, stable on ties.
        (t) => OrderingTerm.desc(t.capturedAt),
        (t) => OrderingTerm.desc(t.id),
      ]);
    return q.watch().map((rows) => [for (final r in rows) _toModel(r)]);
  }

  CheckIn _toModel(CheckInRow r) {
    final partner = r.partnerPhotoPath;
    return checkInFromRow(
      r,
      localPhotoFile: ctx.files.fileFor(r.photoPath).path,
      localPartnerPhotoFile: partner == null
          ? null
          : ctx.files.fileFor(partner).path,
    );
  }

  @override
  Future<CheckIn> submit(CheckInDraft draft) async {
    final me = await ctx.claimUserId();
    final journey = await (_db.select(
      _db.journeys,
    )..where((t) => t.id.equals(draft.journeyId))).getSingleOrNull();
    if (journey == null) throw const OurneyException(OurneyErrorCode.notFound);
    // A retry with the same client id (an import job photo) hands back the
    // row the first attempt created; it only makes sure the upload is queued.
    final clientId = draft.id;
    if (clientId != null) {
      final prior = await (_db.select(
        _db.checkIns,
      )..where((t) => t.id.equals(clientId))).getSingleOrNull();
      if (prior != null) {
        if (!prior.uploaded) {
          final queue = ctx.outbox;
          if (queue != null) {
            await _db.transaction(() async {
              await queue.cancel(
                checkInKey(prior.id),
                kind: OutboxKind.upsertCheckIn,
                includeDead: true,
              );
              await queue.enqueue(
                OutboxKind.upsertCheckIn,
                checkInKey(prior.id),
                {'id': prior.id},
              );
            });
            unawaited(queue.flush());
          }
        }
        return _toModel(prior);
      }
    }
    // Same rule as the `check_ins_before_write` trigger (0006): the owner of a
    // retold journey (origin `imported`, created `ended`) fills its dates in,
    // so it skips the "journey must be active" rule.
    final active = journey.status == JourneyStatus.active.wireName;
    // A live photo on a journey that is still going (active, no duration)
    // follows the normal rules (0016).
    final imported =
        journey.origin == JourneyOrigin.imported.wireName &&
        journey.ownerId == me &&
        !(active && journey.durationDays == null && !draft.fromLibrary);
    if (!imported && !active) {
      throw const OurneyException(OurneyErrorCode.ended);
    }
    if (imported && journey.durationDays == null && !active) {
      throw const OurneyException(OurneyErrorCode.ended);
    }
    if (validateCaption(draft.caption) != null ||
        validateMetricValue(draft.metricValue) != null ||
        draft.extras.normalized().validate() != null) {
      throw const OurneyException(OurneyErrorCode.invalid);
    }
    if (draft.capturedAt.isAfter(ctx.now().add(capturedAtTolerance))) {
      throw const OurneyException(OurneyErrorCode.invalidCapturedAt);
    }
    final localDate = ctx.clock.localDate(draft.capturedAt, journey.timezone);
    final duration = journey.durationDays;
    if (imported) {
      // Retold photos must land inside the journey's dates; a journey that
      // is still going (no duration) has no upper cap, like the
      // `check_ins_before_write` trigger (0016).
      if (localDate.compareTo(journey.startDate) < 0 ||
          (duration != null &&
              localDate.isAfter(journey.startDate.addDays(duration - 1)))) {
        throw const OurneyException(OurneyErrorCode.invalidCapturedAt);
      }
    } else if (duration != null &&
        localDate.isAfter(journey.startDate.addDays(duration - 1))) {
      throw const OurneyException(OurneyErrorCode.ended);
    }

    final id = clientId ?? ctx.newId();
    final photoPath = checkInPhotoPath(journey.id, me, id);
    final thumbPath = checkInThumbPath(journey.id, me, id);
    try {
      await ctx.files.importFile(draft.photoFile, photoPath);
      await ctx.files.importFile(draft.thumbFile, thumbPath);

      // The row and its outbox item commit together: a crash between the
      // two must not leave a check-in that is never uploaded.
      // Posting again the same day adds a photo (FR-C7, migration 0014): the
      // earlier check-ins of that day stay, and the streak counts the day
      // once.
      await _db.transaction(() async {
        await _db
            .into(_db.checkIns)
            .insert(
              CheckInsCompanion.insert(
                id: id,
                journeyId: journey.id,
                userId: me,
                localDate: localDate,
                capturedAt: draft.capturedAt.toUtc(),
                photoPath: photoPath,
                thumbPath: thumbPath,
                fromLibrary: Value(draft.fromLibrary),
                caption: Value(draft.caption),
                metricValue: Value(draft.metricValue),
                extras: Value(draft.extras.normalized().toJsonString()),
              ),
            );
        // One upload per check-in, upserted on its id.
        await ctx.outbox?.enqueue(OutboxKind.upsertCheckIn, checkInKey(id), {
          'id': id,
        });
      });
    } on Object catch (e) {
      debugPrint('check-in: save failed, removing its media: $e');
      try {
        await ctx.files.delete([photoPath, thumbPath]);
      } on Object catch (cleanup) {
        debugPrint('check-in: media cleanup failed: $cleanup');
      }
      rethrow;
    }
    final outbox = ctx.outbox;
    if (outbox != null) unawaited(outbox.flush());

    final saved = await (_db.select(
      _db.checkIns,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (saved == null) {
      throw const OurneyException(OurneyErrorCode.notFound);
    }
    return _toModel(saved);
  }

  @override
  Future<CheckIn> updateCaption(String checkInId, String? caption) async {
    final value = normalizeCaption(caption);
    if (validateCaption(value) != null) {
      throw const OurneyException(OurneyErrorCode.invalid);
    }
    final me = await ctx.claimUserId();
    final row = await _requireEditableCheckIn(checkInId, me);
    final queue = ctx.outbox;
    if (!row.uploaded && queue != null) {
      final saved = await queue.exclusive(
        () => _db.transaction(() async {
          final current = await _requireEditableCheckIn(checkInId, me);
          if (current.uploaded) return null;
          final updated = await _writeCaption(checkInId, me, value);
          final key = checkInKey(checkInId);
          await queue.cancel(
            key,
            kind: OutboxKind.upsertCheckIn,
            includeDead: true,
          );
          await queue.enqueue(OutboxKind.upsertCheckIn, key, {'id': checkInId});
          return updated;
        }),
      );
      if (saved != null) {
        unawaited(queue.flush());
        return _toModel(saved);
      }
    }

    final remote = ctx.remote;
    if (remote != null) {
      final updated = await remote.update(
        'check_ins',
        {'caption': value},
        match: {'id': checkInId},
      );
      // RLS can reject an update by filtering out the row.
      if (updated.isEmpty) {
        throw const OurneyException(OurneyErrorCode.forbidden);
      }
    }
    return _toModel(await _writeCaption(checkInId, me, value));
  }

  Future<CheckInRow> _requireEditableCheckIn(String id, String me) async {
    final row = await (_db.select(
      _db.checkIns,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) throw const OurneyException(OurneyErrorCode.notFound);
    if (row.userId != me || row.moderated) {
      throw const OurneyException(OurneyErrorCode.forbidden);
    }
    return row;
  }

  Future<CheckInRow> _writeCaption(String id, String me, String? value) async {
    final rows =
        await (_db.update(_db.checkIns)
              ..where((t) => t.id.equals(id) & t.userId.equals(me)))
            .writeReturning(CheckInsCompanion(caption: Value(value)));
    return rows.singleOrNull ??
        (throw const OurneyException(OurneyErrorCode.notFound));
  }

  @override
  Stream<int> watchPendingUploads() =>
      ctx.outbox?.watchPending(kind: OutboxKind.upsertCheckIn) ??
      Stream.value(0);
}
