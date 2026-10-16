import 'dart:async';

import 'package:drift/drift.dart';
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
      ]);
    return q.watch().map((rows) => [for (final r in rows) _toModel(r)]);
  }

  CheckIn _toModel(CheckInRow r) =>
      checkInFromRow(r, localPhotoFile: ctx.files.fileFor(r.photoPath).path);

  @override
  Future<CheckIn> submit(CheckInDraft draft) async {
    final me = ctx.requireUserId();
    final journey = await (_db.select(
      _db.journeys,
    )..where((t) => t.id.equals(draft.journeyId))).getSingleOrNull();
    if (journey == null) throw const OurneyException(OurneyErrorCode.notFound);
    if (journey.status != JourneyStatus.active.wireName) {
      throw const OurneyException(OurneyErrorCode.ended);
    }
    if (validateCaption(draft.caption) != null ||
        validateMetricValue(draft.metricValue) != null) {
      throw const OurneyException(OurneyErrorCode.invalid);
    }
    if (draft.capturedAt.isAfter(ctx.now().add(capturedAtTolerance))) {
      throw const OurneyException(OurneyErrorCode.invalidCapturedAt);
    }
    final localDate = ctx.clock.localDate(draft.capturedAt, journey.timezone);
    final duration = journey.durationDays;
    if (duration != null &&
        localDate.isAfter(journey.startDate.addDays(duration - 1))) {
      throw const OurneyException(OurneyErrorCode.ended);
    }

    final id = ctx.newId();
    final photoPath = checkInPhotoPath(journey.id, me, id);
    final thumbPath = checkInThumbPath(journey.id, me, id);
    await ctx.files.importFile(draft.photoFile, photoPath);
    await ctx.files.importFile(draft.thumbFile, thumbPath);

    final old = await _db.transaction(() async {
      final previous =
          await (_db.select(_db.checkIns)..where(
                (t) =>
                    t.journeyId.equals(journey.id) &
                    t.userId.equals(me) &
                    t.localDate.equalsValue(localDate),
              ))
              .getSingleOrNull();
      if (previous != null) {
        await (_db.delete(
          _db.reactions,
        )..where((t) => t.checkInId.equals(previous.id))).go();
        await (_db.delete(
          _db.checkIns,
        )..where((t) => t.id.equals(previous.id))).go();
      }
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
            ),
          );
      return previous;
    });
    if (old != null) await ctx.files.delete([old.photoPath, old.thumbPath]);

    final outbox = ctx.outbox;
    if (outbox != null) {
      final key = checkInKey(journey.id, me, localDate);
      // A retake replaces a not-yet-sent take; the server row (if any) is
      // replaced by the upsert on (journey_id, user_id, local_date).
      await outbox.cancel(key, kind: OutboxKind.upsertCheckIn);
      await outbox.enqueue(OutboxKind.upsertCheckIn, key, {'id': id});
      if (old != null) {
        await outbox.enqueue(OutboxKind.deleteMedia, 'media:${old.id}', {
          'paths': [old.photoPath, old.thumbPath],
        });
      }
      unawaited(outbox.flush());
    }

    final saved = await (_db.select(
      _db.checkIns,
    )..where((t) => t.id.equals(id))).getSingle();
    return _toModel(saved);
  }

  @override
  Stream<int> watchPendingUploads() =>
      ctx.outbox?.watchPending(kind: OutboxKind.upsertCheckIn) ??
      Stream.value(0);
}
