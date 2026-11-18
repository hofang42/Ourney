import 'dart:async';
import 'dart:convert';

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
        // Pinned journeys (my own preference) come first.
        OrderingTerm.desc(_db.memberships.pinned),
        OrderingTerm.desc(_db.journeys.startDate),
        OrderingTerm.asc(_db.journeys.id),
      ]);
    return q.watch().map(
      (rows) => [
        for (final r in rows) journeyFromRow(r.readTable(_db.journeys)),
      ],
    );
  }

  @override
  Stream<Set<String>> watchPinnedJourneyIds() {
    final me = ctx.userId;
    if (me == null) return Stream.value(const <String>{});
    return (_db.select(_db.memberships)
          ..where((t) => t.userId.equals(me) & t.pinned.equals(true)))
        .watch()
        .map((rows) => {for (final r in rows) r.journeyId});
  }

  @override
  Stream<Journey?> watch(String journeyId) =>
      (_db.select(_db.journeys)..where((t) => t.id.equals(journeyId)))
          .watchSingleOrNull()
          .map((r) => r == null ? null : journeyFromRow(r));

  @override
  Future<Journey> create(JourneyDraft draft) async {
    if (validateJourneyTitle(draft.title) != null ||
        validateDurationDays(draft.durationDays) != null ||
        validateJourneyVisibility(draft.kind, draft.visibility) != null ||
        validateCoupleNames(draft.coupleSelfName, draft.couplePartnerName) !=
            null) {
      throw const OurneyException(OurneyErrorCode.invalid);
    }
    final me = ctx.requireUserId();
    // Retry of a create that already landed locally: same journey back.
    if (draft.id case final clientId?) {
      final existing = await (_db.select(
        _db.journeys,
      )..where((t) => t.id.equals(clientId))).getSingleOrNull();
      if (existing != null) {
        // A-B12: the earlier attempt may have died between `create_journey`
        // and the extras; put back whatever the row is missing.
        await _reapplyMissingExtras(existing, draft);
        return journeyFromRow(
          await (_db.select(
            _db.journeys,
          )..where((t) => t.id.equals(clientId))).getSingle(),
        );
      }
    }
    final id = draft.id ?? ctx.newId();
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
      await _applyExtras(id, draft);
      final saved = await (_db.select(
        _db.journeys,
      )..where((t) => t.id.equals(id))).getSingle();
      return journeyFromRow(saved);
    } on OurneyException catch (e) {
      if (e.error != OurneyErrorCode.offline || needsServer) rethrow;
    }
    // Solo + offline: create locally, the outbox replays `create_journey`
    // (idempotent on p_id) before any check-in of this journey.
    final journey = await _insertLocal(id, me, draft, visibility);
    await ctx.outbox!.enqueue(OutboxKind.createJourney, journeyKey(id), params);
    final extras = _extrasUpdate(draft);
    if (extras != null) {
      await ctx.outbox!.enqueue(
        OutboxKind.updateJourney,
        '${journeyKey(id)}:extras',
        updateJourneyParams(id, extras),
      );
    }
    return journey;
  }

  JourneyUpdate? _extrasUpdate(JourneyDraft d) {
    final u = JourneyUpdate(
      layout: d.layout,
      cover: d.cover,
      color: d.color,
      reminderTime: d.reminderTime,
      dna: d.dna,
    );
    return u.isEmpty ? null : u;
  }

  /// `create_journey` has no edit fields: send them right after so the row
  /// carries the create-flow answers. They are written locally first and
  /// queued through the outbox on any retryable failure, so a transient error
  /// never loses them nor fails a create that already landed. Only a
  /// rejection (invalid / forbidden) is surfaced.
  Future<void> _applyExtras(String id, JourneyDraft d) async {
    final extras = _extrasUpdate(d);
    if (extras == null) return;
    await _writeLocal(id, extras);
    try {
      final row = await ctx.remote!.rpc(
        'update_journey',
        updateJourneyParams(id, extras),
      );
      if (row is Map) await ctx.store.applyJourney(row.cast<String, dynamic>());
    } on OurneyException catch (e) {
      if (e.error == OurneyErrorCode.invalid ||
          e.error == OurneyErrorCode.forbidden) {
        rethrow;
      }
      final outbox = ctx.outbox;
      if (outbox != null) {
        await outbox.enqueue(
          OutboxKind.updateJourney,
          '${journeyKey(id)}:extras',
          updateJourneyParams(id, extras),
        );
        unawaited(outbox.flush());
      }
    }
  }

  /// Retry of a create whose row exists: re-apply the extras the row lacks
  /// (and that are not already queued). A rejection is not raised again.
  Future<void> _reapplyMissingExtras(JourneyRow row, JourneyDraft d) async {
    final extras = _extrasUpdate(d);
    if (extras == null) return;
    final complete =
        (extras.layout == null || row.layout == extras.layout!.wireName) &&
        (extras.cover == null || row.cover == extras.cover) &&
        (extras.color == null || row.color == extras.color) &&
        (extras.reminderTime == null ||
            row.reminderTime == extras.reminderTime) &&
        (extras.dna == null || row.dna == jsonEncode(extras.dna));
    if (complete) return;
    final queued = await ctx.outbox?.pendingKeys() ?? const <String>{};
    if (queued.contains('${journeyKey(row.id)}:extras')) return;
    if (ctx.remote == null) {
      await _writeLocal(row.id, extras);
      return;
    }
    try {
      await _applyExtras(row.id, d);
    } on OurneyException {
      // Already surfaced on the first attempt; the journey exists.
    }
  }

  static final RegExp _hhmm = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

  @override
  Future<Journey> update(String journeyId, JourneyUpdate update) async {
    final badRange =
        (update.cover != null && (update.cover! < 0 || update.cover! > 2)) ||
        (update.color != null && (update.color! < 0 || update.color! > 2));
    if ((update.title != null && validateJourneyTitle(update.title!) != null) ||
        badRange ||
        (update.reminderTime != null &&
            !_hhmm.hasMatch(update.reminderTime!))) {
      throw const OurneyException(OurneyErrorCode.invalid);
    }
    final row = await _requireLocal(journeyId);
    if (row.status != JourneyStatus.active.wireName) {
      throw const OurneyException(OurneyErrorCode.ended);
    }
    final group = row.kind == JourneyKind.group.wireName;
    final remote = ctx.remote;
    if (remote != null) {
      await _flushFirst();
      try {
        final res = await remote.rpc(
          'update_journey',
          updateJourneyParams(journeyId, update),
        );
        if (res is Map) {
          await ctx.store.applyJourney(res.cast<String, dynamic>());
          return journeyFromRow(await _requireLocal(journeyId));
        }
      } on OurneyException catch (e) {
        if (e.error != OurneyErrorCode.offline || group) rethrow;
      }
    } else if (group) {
      ctx.requireRemote();
    }
    // Local-only or offline solo: write now, replay through the outbox.
    await _writeLocal(journeyId, update);
    final outbox = ctx.outbox;
    if (outbox != null) {
      await outbox.enqueue(
        OutboxKind.updateJourney,
        '${journeyKey(journeyId)}:edit',
        updateJourneyParams(journeyId, update),
      );
      unawaited(outbox.flush());
    }
    return journeyFromRow(await _requireLocal(journeyId));
  }

  /// Applies [update] to the cached row (what `update_journey` would store).
  Future<void> _writeLocal(String journeyId, JourneyUpdate update) {
    Value<T?> pick<T>(String key, T? v, Value<T?> Function(T) wrap) =>
        update.clear.contains(key)
        ? const Value(null)
        : v == null
        ? const Value.absent()
        : wrap(v);
    return (_db.update(
      _db.journeys,
    )..where((t) => t.id.equals(journeyId))).write(
      JourneysCompanion(
        title: update.title == null
            ? const Value.absent()
            : Value(update.title!.trim()),
        layout: pick<String>('layout', update.layout?.wireName, Value.new),
        cover: pick<int>('cover', update.cover, Value.new),
        color: pick<int>('color', update.color, Value.new),
        reminderTime: pick<String>(
          'reminder_time',
          update.reminderTime,
          Value.new,
        ),
        dna: pick<String>(
          'dna',
          update.dna == null ? null : jsonEncode(update.dna),
          Value.new,
        ),
      ),
    );
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
              layout: Value(d.layout?.wireName),
              cover: Value(d.cover),
              color: Value(d.color),
              reminderTime: Value(d.reminderTime),
              dna: Value(d.dna == null ? null : jsonEncode(d.dna)),
              coupleSelfName: Value(d.coupleSelfName?.trim()),
              couplePartnerName: Value(d.couplePartnerName?.trim()),
              startDate: d.startDate,
              durationDays: Value(d.durationDays),
              timezone: d.timezone,
              visibility: visibility.wireName,
              status: JourneyStatus.active.wireName,
              maxMembers: Value(maxMembersForDraft(d)),
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
      'paths': [
        for (final c in own) ...[
          c.photoPath,
          c.thumbPath,
          if (c.partnerPhotoPath != null) c.partnerPhotoPath!,
        ],
      ],
    });
    unawaited(outbox.flush());
  }

  @override
  Future<String?> setPublicLink(
    String journeyId, {
    required bool enabled,
  }) async {
    final remote = ctx.requireRemote();
    await _flushFirst();
    final token = await remote.rpc('set_public_link', {
      'journey': journeyId,
      'enabled': enabled,
    });
    final value = token is String ? token : null;
    final local = await (_db.select(
      _db.journeys,
    )..where((t) => t.id.equals(journeyId))).getSingleOrNull();
    // Group journeys stay `group` (0006): only solo ones flip to `link`.
    final solo = local == null || local.kind == JourneyKind.solo.wireName;
    await (_db.update(
      _db.journeys,
    )..where((t) => t.id.equals(journeyId))).write(
      JourneysCompanion(
        publicToken: Value(value),
        visibility: solo
            ? Value(
                (value == null
                        ? JourneyVisibility.private
                        : JourneyVisibility.link)
                    .wireName,
              )
            : const Value.absent(),
      ),
    );
    return value;
  }

  @override
  Stream<Membership?> watchMyMembership(String journeyId) {
    final me = ctx.userId;
    if (me == null) return Stream.value(null);
    return (_db.select(_db.memberships)
          ..where((t) => t.journeyId.equals(journeyId) & t.userId.equals(me)))
        .watchSingleOrNull()
        .map((r) => r == null ? null : membershipFromRow(r));
  }

  @override
  Future<void> updateMyMembership(
    String journeyId, {
    bool? hideMetric,
    bool? blurMedia,
    bool? hideExtras,
    bool? pinned,
  }) async {
    if (hideMetric == null &&
        blurMedia == null &&
        hideExtras == null &&
        pinned == null) {
      return;
    }
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
                hideExtras: hideExtras == null
                    ? const Value.absent()
                    : Value(hideExtras),
                pinned: pinned == null ? const Value.absent() : Value(pinned),
              ),
            );
    if (updated == 0) throw const OurneyException(OurneyErrorCode.notFound);
    final outbox = ctx.outbox;
    if (outbox == null) return;
    await outbox.enqueue(
      OutboxKind.updateMembership,
      membershipKey(journeyId),
      {
        'journey_id': journeyId,
        'user_id': me,
        'hide_metric': ?hideMetric,
        'blur_media': ?blurMedia,
        'hide_extras': ?hideExtras,
        'pinned': ?pinned,
      },
    );
    unawaited(outbox.flush());
  }
}
