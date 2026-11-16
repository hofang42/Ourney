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
    final me = ctx.requireUserId();
    final journey = await (_db.select(
      _db.journeys,
    )..where((t) => t.id.equals(draft.journeyId))).getSingleOrNull();
    if (journey == null) throw const OurneyException(OurneyErrorCode.notFound);
    if (journey.status != JourneyStatus.active.wireName) {
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
    if (duration != null &&
        localDate.isAfter(journey.startDate.addDays(duration - 1))) {
      throw const OurneyException(OurneyErrorCode.ended);
    }

    final id = ctx.newId();
    final photoPath = checkInPhotoPath(journey.id, me, id);
    final thumbPath = checkInThumbPath(journey.id, me, id);
    await ctx.files.importFile(draft.photoFile, photoPath);
    await ctx.files.importFile(draft.thumbFile, thumbPath);
    final partnerFile = draft.partnerPhotoFile;
    final partnerPath = partnerFile == null
        ? null
        : checkInPartnerPhotoPath(journey.id, me, id);
    if (partnerFile != null) {
      await ctx.files.importFile(partnerFile, partnerPath!);
    }

    // Posting again the same day adds a photo (FR-C7, migration 0014): the
    // earlier check-ins of that day stay, and the streak counts the day once.
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
            partnerPhotoPath: Value(partnerPath),
          ),
        );

    final outbox = ctx.outbox;
    if (outbox != null) {
      // One upload per check-in, upserted on its id.
      await outbox.enqueue(OutboxKind.upsertCheckIn, checkInKey(id), {
        'id': id,
      });
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
