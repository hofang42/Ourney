import 'dart:async';

import 'package:drift/drift.dart';
import 'package:ourney_core/ourney_core.dart';

import '../data_context.dart';
import '../db/app_database.dart';
import '../local_store.dart';
import '../mapping.dart';
import '../remote/remote_api.dart';
import '../sync/outbox.dart';

/// Group features. Every call needs the server: in local-only mode they throw
/// [GroupException] `offline` (UI shows `NeedsServerView` instead).
class DataGroupRepository implements GroupRepository {
  DataGroupRepository(
    this.ctx, {
    this.todayRefresh = const Duration(minutes: 1),
  });

  final DataContext ctx;

  /// How often an open "today" board re-fetches `group_today`.
  final Duration todayRefresh;

  AppDatabase get _db => ctx.db;

  RemoteApi _remote() {
    final remote = ctx.remote;
    if (remote == null) {
      throw const GroupException.of(OurneyErrorCode.offline, 'local-only mode');
    }
    return remote;
  }

  /// Runs a server call, rethrowing failures as [GroupException].
  Future<T> _group<T>(Future<T> Function(RemoteApi remote) body) async {
    final remote = _remote();
    try {
      return await body(remote);
    } on GroupException {
      rethrow;
    } on OurneyException catch (e) {
      throw GroupException.of(e.error, e.detail);
    }
  }

  Future<void> _flushFirst() async {
    final outbox = ctx.outbox;
    if (outbox != null) await outbox.flush(force: true);
  }

  @override
  Future<String> joinByCode(String code) => _group((remote) async {
    final normalized = normalizeInviteCode(code);
    if (validateInviteCode(normalized) != null) {
      throw const GroupException.of(OurneyErrorCode.notFound);
    }
    final row = await remote.rpc('join_by_code', {'code': normalized});
    if (row is! Map) throw const GroupException.of(OurneyErrorCode.unknown);
    final journey = row.cast<String, dynamic>();
    final id = journey['id'] as String;
    await ctx.store.applyJourney(journey);
    // Rejoin restores earlier check-ins: refetch the whole journey.
    await ctx.sync?.pullJourney(id);
    return id;
  });

  @override
  Future<String> rotateInviteCode(String journeyId) => _group((remote) async {
    final code = await remote.rpc('rotate_invite', {'journey': journeyId});
    if (code is! String) throw const GroupException.of(OurneyErrorCode.unknown);
    await (_db.update(_db.journeys)..where((t) => t.id.equals(journeyId)))
        .write(JourneysCompanion(inviteCode: Value(code)));
    return code;
  });

  /// Emits `group_today` now, after every sync/upload, and every
  /// [todayRefresh] while listened to. Errors are [GroupException]s; the
  /// caller's own check-in for today is filled in from the local cache while
  /// its upload is pending.
  @override
  Stream<List<MemberToday>> watchToday(String journeyId) {
    late final StreamController<List<MemberToday>> controller;
    StreamSubscription<void>? changes;
    Timer? timer;
    var busy = false;
    var again = false;

    Future<void> load() async {
      if (busy) {
        again = true;
        return;
      }
      busy = true;
      try {
        do {
          again = false;
          try {
            final list = await _fetchToday(journeyId);
            if (!controller.isClosed) controller.add(list);
          } on OurneyException catch (e, st) {
            if (!controller.isClosed) {
              controller.addError(
                e is GroupException ? e : GroupException.of(e.error, e.detail),
                st,
              );
            }
          }
        } while (again && !controller.isClosed);
      } finally {
        busy = false;
      }
    }

    controller = StreamController<List<MemberToday>>(
      onListen: () {
        unawaited(load());
        // Reconcile the cache for this journey (blocks/reports have no
        // tombstones), then refresh on every later change.
        final sync = ctx.sync;
        if (sync != null) {
          unawaited(sync.pullJourney(journeyId).catchError((Object _) {}));
          changes = sync.changes.listen((_) => unawaited(load()));
        }
        timer = Timer.periodic(todayRefresh, (_) => unawaited(load()));
      },
      onCancel: () async {
        timer?.cancel();
        await changes?.cancel();
      },
    );
    return controller.stream;
  }

  Future<List<MemberToday>> _fetchToday(String journeyId) => _group((
    remote,
  ) async {
    final journey = await (_db.select(
      _db.journeys,
    )..where((t) => t.id.equals(journeyId))).getSingleOrNull();
    final rows = await remote.rpc('group_today', {'journey': journeyId});
    final list = (rows as List? ?? const []).cast<Map<dynamic, dynamic>>();
    final today = journey == null ? null : ctx.clock.today(journey.timezone);
    final me = ctx.userId;
    final result = <MemberToday>[];
    for (final raw in list) {
      final r = raw.cast<String, dynamic>();
      final captured = r['captured_at'];
      final day =
          today ??
          (captured == null
              ? ctx.clock.localDate(ctx.now(), 'UTC')
              : LocalDate.parse((captured as String).substring(0, 10)));
      var member = memberTodayFromRemote(r, journeyId: journeyId, today: day);
      if (member.userId == me && member.todayCheckIn == null && today != null) {
        final local = await _localCheckIn(journeyId, me!, today);
        if (local != null) {
          member = MemberToday(
            userId: member.userId,
            username: member.username,
            displayName: member.displayName,
            avatarPath: member.avatarPath,
            role: member.role,
            currentStreak: member.currentStreak,
            todayCheckIn: local,
          );
        }
      }
      result.add(member);
    }
    return result;
  });

  Future<CheckIn?> _localCheckIn(
    String journeyId,
    String me,
    LocalDate day,
  ) async {
    final row =
        await (_db.select(_db.checkIns)..where(
              (t) =>
                  t.journeyId.equals(journeyId) &
                  t.userId.equals(me) &
                  t.localDate.equalsValue(day),
            ))
            .getSingleOrNull();
    if (row == null) return null;
    return checkInFromRow(
      row,
      localPhotoFile: ctx.files.fileFor(row.photoPath).path,
    );
  }

  @override
  Future<void> react(String checkInId, String emoji) async {
    _remote();
    if (!reactionEmojis.contains(emoji)) {
      throw const GroupException.of(OurneyErrorCode.invalid);
    }
    await _assertActive(checkInId);
    final me = ctx.requireUserId();
    await _db
        .into(_db.reactions)
        .insertOnConflictUpdate(
          ReactionsCompanion.insert(
            checkInId: checkInId,
            userId: me,
            emoji: emoji,
            createdAt: ctx.now(),
          ),
        );
    await _queueReaction(checkInId, me, emoji);
  }

  @override
  Future<void> unreact(String checkInId) async {
    _remote();
    await _assertActive(checkInId);
    final me = ctx.requireUserId();
    await (_db.delete(
      _db.reactions,
    )..where((t) => t.checkInId.equals(checkInId) & t.userId.equals(me))).go();
    await _queueReaction(checkInId, me, null);
  }

  Future<void> _queueReaction(
    String checkInId,
    String me,
    String? emoji,
  ) async {
    final outbox = ctx.outbox!;
    final key = reactionKey(checkInId);
    await outbox.cancel(key);
    await outbox.enqueue(OutboxKind.react, key, {
      'checkin_id': checkInId,
      'user_id': me,
      'emoji': emoji,
    });
    unawaited(outbox.flush());
  }

  /// Reactions are read-only once the journey is not active (`ended`).
  Future<void> _assertActive(String checkInId) async {
    final q = _db.select(_db.checkIns).join([
      innerJoin(
        _db.journeys,
        _db.journeys.id.equalsExp(_db.checkIns.journeyId),
      ),
    ])..where(_db.checkIns.id.equals(checkInId));
    final row = await q.getSingleOrNull();
    if (row == null) return; // unknown locally: let the server decide
    final status = row.readTable(_db.journeys).status;
    if (status != JourneyStatus.active.wireName) {
      throw const GroupException.of(OurneyErrorCode.ended);
    }
  }

  @override
  Stream<List<Reaction>> watchReactions(String checkInId) {
    final blocked = _db.selectOnly(_db.blocks)
      ..addColumns([_db.blocks.blockedId]);
    final q = _db.select(_db.reactions)
      ..where(
        (t) =>
            t.checkInId.equals(checkInId) & t.userId.isInQuery(blocked).not(),
      )
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
    return q.watch().map((rows) => [for (final r in rows) reactionFromRow(r)]);
  }

  @override
  Future<void> leave(String journeyId) => _group((remote) async {
    await _flushFirst();
    await remote.rpc('leave_journey', {'journey': journeyId});
    await ctx.store.purgeJourney(journeyId);
    ctx.sync?.notifyChanged();
  });

  @override
  Future<void> removeMember(String journeyId, String userId) => _group((
    remote,
  ) async {
    await remote.rpc('remove_member', {'journey': journeyId, 'member': userId});
    await (_db.update(_db.memberships)..where(
          (t) => t.journeyId.equals(journeyId) & t.userId.equals(userId),
        ))
        .write(
          MembershipsCompanion(
            status: Value(MemberStatus.left.wireName),
            role: Value(MemberRole.member.wireName),
          ),
        );
    await ctx.store.forgetUserContent(userId, journeyId: journeyId);
    ctx.sync?.notifyChanged();
  });
}
