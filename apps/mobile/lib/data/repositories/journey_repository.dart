import 'dart:async';

import 'package:drift/drift.dart';
import 'package:ourney_core/ourney_core.dart';

import '../data_context.dart';
import '../db/app_database.dart';
import '../local_store.dart';
import '../mapping.dart';
import '../sync/outbox.dart';

class DataJourneyRepository implements JourneyRepository {
  DataJourneyRepository(this.ctx);

  final DataContext ctx;

  AppDatabase get _db => ctx.db;

  /// Journeys where [me] is an active member, joined with that membership.
  JoinedSelectStatement<HasResultSet, dynamic> _mine(String me) =>
      _db.select(_db.journeys).join([
        innerJoin(
          _db.memberships,
          _db.memberships.journeyId.equalsExp(_db.journeys.id) &
              _db.memberships.userId.equals(me) &
              _db.memberships.status.equals(MemberStatus.active.wireName),
        ),
      ]);

  @override
  Stream<List<Journey>> watchActive() {
    final me = ctx.userId;
    if (me == null) return Stream.value(const []);
    final q = _mine(me)
      ..where(
        _db.journeys.status.equals(JourneyStatus.archived.wireName).not() &
            _db.journeys.localArchived.equals(false),
      )
      ..orderBy([
        OrderingTerm.desc(_db.journeys.startDate),
        OrderingTerm.asc(_db.journeys.id),
      ]);
    return q.watch().map(
      (rows) => [for (final r in rows) journeyFromRow(r.readTable(_db.journeys))],
    );
  }

  @override
  Stream<Journey?> watch(String journeyId) =>
      (_db.select(_db.journeys)..where((t) => t.id.equals(journeyId)))
          .watchSingleOrNull()
          .map((r) => r == null ? null : journeyFromRow(r));

  Future<int> _activeCount(String me) async {
    final rows =
        await (_mine(me)..where(
              _db.journeys.status.equals(JourneyStatus.active.wireName),
            ))
            .get();
    return rows.length;
  }

  @override
  Future<Journey> create(JourneyDraft draft) async {
    if (validateJourneyTitle(draft.title) != null ||
        validateDurationDays(draft.durationDays) != null ||
        validateJourneyVisibility(draft.kind, draft.visibility) != null) {
      throw const OurneyException(OurneyErrorCode.invalid);
    }
    final me = ctx.requireUserId();
    if (!canCreateJourney(await _activeCount(me))) {
      throw const JourneyLimitException();
    }
    final id = ctx.newId();
    final visibility = normalizedVisibility(draft.kind, draft.visibility);
    final needsServer =
        draft.kind == JourneyKind.group || visibility == JourneyVisibility.link;

    final remote = ctx.remote;
    if (remote == null) {
      if (needsServer) ctx.requireRemote();
      return _insertLocal(id, me, draft, visibility);
    }

    final params = createJourneyParams(id, draft);
    try {
      final row = await remote.rpc('create_journey', params);
      if (row is! Map) {
        throw const OurneyException(OurneyErrorCode.unknown, 'no row');
      }
      await ctx.store.applyJourney(row.cast<String, dynamic>());
      await _insertMembership(id, me, draft.hideMetricDefault);
      final saved = await (_db.select(
        _db.journeys,
      )..where((t) => t.id.equals(id))).getSingle();
      return journeyFromRow(saved);
    } on OurneyException catch (e) {
      if (e.error == OurneyErrorCode.limit) throw JourneyLimitException(e.detail);
      if (e.error != OurneyErrorCode.offline || needsServer) rethrow;
    }
    // Solo + offline: create locally, the outbox replays `create_journey`
    // (idempotent on p_id) before any check-in of this journey.
    final journey = await _insertLocal(id, me, draft, visibility);
    await ctx.outbox!.enqueue(OutboxKind.createJourney, journeyKey(id), params);
    return journey;
  }

  Future<Journey> _insertLocal(
    String id,
    String me,
    JourneyDraft d,
    JourneyVisibility visibility,
  ) async {
    await _db.transaction(() async {
      await _db
          .into(_db.journeys)
          .insert(
            JourneysCompanion.insert(
              id: id,
              ownerId: me,
              kind: d.kind.wireName,
              templateId: d.templateId.wireName,
              title: d.title.trim(),
              emoji: d.emoji,
              metricName: Value(d.metricName),
              metricUnit: Value(d.metricUnit),
              hideMetricDefault: Value(d.hideMetricDefault),
              startDate: d.startDate,
              durationDays: Value(d.durationDays),
              timezone: d.timezone,
              visibility: visibility.wireName,
              status: JourneyStatus.active.wireName,
              maxMembers: Value(d.kind == JourneyKind.solo ? 1 : maxGroupMembers),
            ),
          );
      await _insertMembership(id, me, d.hideMetricDefault);
    });
    final row = await (_db.select(
      _db.journeys,
    )..where((t) => t.id.equals(id))).getSingle();
    return journeyFromRow(row);
  }

  Future<void> _insertMembership(String id, String me, bool hideMetric) => _db
      .into(_db.memberships)
      .insert(
        MembershipsCompanion.insert(
          journeyId: id,
          userId: me,
          role: MemberRole.owner.wireName,
          status: MemberStatus.active.wireName,
          joinedAt: ctx.now(),
          hideMetric: Value(hideMetric),
        ),
        mode: InsertMode.insertOrIgnore,
      );

  Future<JourneyRow> _requireLocal(String journeyId) async {
    final row = await (_db.select(
      _db.journeys,
    )..where((t) => t.id.equals(journeyId))).getSingleOrNull();
    if (row == null) throw const OurneyException(OurneyErrorCode.notFound);
    return row;
  }

  /// Sends queued writes first so RPCs never race a pending `create_journey`.
  Future<void> _flushFirst() async {
    final outbox = ctx.outbox;
    if (outbox != null) await outbox.flush(force: true);
  }

  @override
  Future<void> end(String journeyId) async {
    final remote = ctx.remote;
    if (remote == null) {
      final row = await _requireLocal(journeyId);
      if (row.status != JourneyStatus.active.wireName) {
        throw const OurneyException(OurneyErrorCode.ended);
      }
      await _setStatus(journeyId, JourneyStatus.ended);
      return;
    }
    await _flushFirst();
    final row = await remote.rpc('end_journey', {'journey': journeyId});
    if (row is Map) {
      await ctx.store.applyJourney(row.cast<String, dynamic>());
    } else {
      await _setStatus(journeyId, JourneyStatus.ended);
    }
  }

  Future<void> _setStatus(String journeyId, JourneyStatus status) =>
      (_db.update(_db.journeys)..where((t) => t.id.equals(journeyId))).write(
        JourneysCompanion(status: Value(status.wireName)),
      );

  @override
  Future<void> archive(String journeyId) async {
    await _requireLocal(journeyId);
    await (_db.update(_db.journeys)..where((t) => t.id.equals(journeyId)))
        .write(const JourneysCompanion(localArchived: Value(true)));
  }

  @override
  Future<void> delete(String journeyId) async {
    final remote = ctx.remote;
    if (remote == null) {
      await _requireLocal(journeyId);
      await ctx.store.purgeJourney(journeyId);
      return;
    }
    final me = ctx.requireUserId();
    await _flushFirst();
    await remote.rpc('delete_journey', {'journey': journeyId});
    final own = await (_db.select(
      _db.checkIns,
    )..where((t) => t.journeyId.equals(journeyId) & t.userId.equals(me))).get();
    await ctx.store.purgeJourney(journeyId);
    // The RPC only tombstones rows: remove our objects via the Storage API
    // (queued, so it is retried if the network drops now).
    final outbox = ctx.outbox!;
    await outbox.enqueue(OutboxKind.deleteMedia, journeyKey(journeyId), {
      'prefixes': ['checkins/$journeyId/$me'],
      'paths': [for (final c in own) ...[c.photoPath, c.thumbPath]],
    });
    unawaited(outbox.flush());
  }

  @override
  Future<String?> setPublicLink(String journeyId, {required bool enabled}) async {
    final remote = ctx.requireRemote();
    await _flushFirst();
    final token = await remote.rpc('set_public_link', {
      'journey': journeyId,
      'enabled': enabled,
    });
    final value = token is String ? token : null;
    await (_db.update(_db.journeys)..where((t) => t.id.equals(journeyId))).write(
      JourneysCompanion(
        publicToken: Value(value),
        visibility: Value(
          (value == null ? JourneyVisibility.private : JourneyVisibility.link)
              .wireName,
        ),
      ),
    );
    return value;
  }

  @override
  Stream<Membership?> watchMyMembership(String journeyId) {
    final me = ctx.userId;
    if (me == null) return Stream.value(null);
    return (_db.select(_db.memberships)..where(
          (t) => t.journeyId.equals(journeyId) & t.userId.equals(me),
        ))
        .watchSingleOrNull()
        .map((r) => r == null ? null : membershipFromRow(r));
  }

  @override
  Future<void> updateMyMembership(
    String journeyId, {
    bool? hideMetric,
    bool? blurMedia,
  }) async {
    if (hideMetric == null && blurMedia == null) return;
    final me = ctx.requireUserId();
    final updated =
        await (_db.update(_db.memberships)..where(
              (t) => t.journeyId.equals(journeyId) & t.userId.equals(me),
            ))
            .write(
              MembershipsCompanion(
                hideMetric: hideMetric == null
                    ? const Value.absent()
                    : Value(hideMetric),
                blurMedia: blurMedia == null
                    ? const Value.absent()
                    : Value(blurMedia),
              ),
            );
    if (updated == 0) throw const OurneyException(OurneyErrorCode.notFound);
    final outbox = ctx.outbox;
    if (outbox == null) return;
    await outbox.enqueue(OutboxKind.updateMembership, membershipKey(journeyId), {
      'journey_id': journeyId,
      'user_id': me,
      'hide_metric': ?hideMetric,
      'blur_media': ?blurMedia,
    });
    unawaited(outbox.flush());
  }
}
