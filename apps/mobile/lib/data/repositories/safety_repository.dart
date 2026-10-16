import 'dart:async';

import 'package:ourney_core/ourney_core.dart';

import '../data_context.dart';
import '../db/app_database.dart';

/// Report/block need the server; in local-only mode they throw `offline`
/// and [watchBlockedIds] stays empty.
class DataSafetyRepository implements SafetyRepository {
  DataSafetyRepository(this.ctx);

  final DataContext ctx;

  AppDatabase get _db => ctx.db;

  @override
  Future<void> report({
    String? checkInId,
    String? userId,
    required ReportReason reason,
    String? note,
  }) async {
    if (checkInId == null && userId == null) {
      throw const OurneyException(OurneyErrorCode.invalid);
    }
    final remote = ctx.requireRemote();
    await remote.rpc('report_content', {
      'p_checkin': checkInId,
      'p_user': userId,
      'p_reason': reason.wireName,
      'p_note': note,
    });
    if (checkInId != null) {
      // RLS hides reported check-ins from the reporter: mirror it at once.
      final rows = await (_db.select(
        _db.checkIns,
      )..where((t) => t.id.equals(checkInId))).get();
      await ctx.store.deleteCheckIns(rows);
      ctx.sync?.notifyChanged();
    }
  }

  @override
  Future<void> block(String userId) async {
    final remote = ctx.requireRemote();
    if (userId == ctx.userId) {
      throw const OurneyException(OurneyErrorCode.invalid);
    }
    await remote.rpc('block_user', {'p_user': userId});
    await _db
        .into(_db.blocks)
        .insertOnConflictUpdate(BlocksCompanion.insert(blockedId: userId));
    await ctx.store.forgetUserContent(userId);
    ctx.sync?.notifyChanged();
  }

  @override
  Future<void> unblock(String userId) async {
    final remote = ctx.requireRemote();
    await remote.rpc('unblock_user', {'p_user': userId});
    await (_db.delete(
      _db.blocks,
    )..where((t) => t.blockedId.equals(userId))).go();
    // Their check-ins are visible again: refetch the group journeys.
    final sync = ctx.sync;
    if (sync == null) return;
    final groups = await (_db.select(
      _db.journeys,
    )..where((t) => t.kind.equals(JourneyKind.group.wireName))).get();
    for (final j in groups) {
      unawaited(sync.pullJourney(j.id).catchError((Object _) {}));
    }
  }

  @override
  Stream<Set<String>> watchBlockedIds() => _db
      .select(_db.blocks)
      .watch()
      .map((rows) => {for (final r in rows) r.blockedId});
}
