import 'package:drift/drift.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../data/data_context.dart';
import '../../../data/db/app_database.dart';

/// [GroupInviteAdminRepository] over the RPCs of migration 0010. Couple
/// renames also work in local-only mode (plain local write).
class DataGroupInviteAdminRepository implements GroupInviteAdminRepository {
  DataGroupInviteAdminRepository(this.ctx);

  final DataContext ctx;

  Future<T> _remote<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on GroupException {
      rethrow;
    } on OurneyException catch (e) {
      throw GroupException.of(e.error, e.detail);
    }
  }

  @override
  Future<List<SentGroupInvitation>> sent(String journeyId) => _remote(() async {
    final remote = ctx.remote;
    if (remote == null) {
      throw const GroupException.of(OurneyErrorCode.offline, 'local-only mode');
    }
    final rows = await remote.rpc('journey_pending_invitations', {
      'p_journey': journeyId,
    });
    if (rows is! List) return const [];
    return [
      for (final r in rows)
        if (r is Map) SentGroupInvitation.fromJson(r.cast<String, dynamic>()),
    ];
  });

  @override
  Future<void> revoke(String invitationId) => _remote(() async {
    final remote = ctx.remote;
    if (remote == null) {
      throw const GroupException.of(OurneyErrorCode.offline, 'local-only mode');
    }
    await remote.rpc('revoke_group_invitation', {'p_invitation': invitationId});
  });

  @override
  Future<void> renameCouple(String journeyId, String self, String partner) =>
      _remote(() async {
        final a = self.trim();
        final b = partner.trim();
        if (validateCoupleNames(a, b) != null || a.isEmpty) {
          throw const OurneyException(OurneyErrorCode.invalid);
        }
        final remote = ctx.remote;
        if (remote == null) {
          await (ctx.db.update(
            ctx.db.journeys,
          )..where((t) => t.id.equals(journeyId))).write(
            JourneysCompanion(
              coupleSelfName: Value(a),
              couplePartnerName: Value(b),
            ),
          );
          return;
        }
        final row = await remote.rpc('rename_couple', {
          'p_journey': journeyId,
          'p_self': a,
          'p_partner': b,
        });
        if (row is Map) {
          await ctx.store.applyJourney(row.cast<String, dynamic>());
        }
      });
}

/// Fallback when the data layer is not wired (tests): always offline.
class UnavailableGroupInviteAdminRepository
    implements GroupInviteAdminRepository {
  const UnavailableGroupInviteAdminRepository();

  static const _offline = GroupException.of(OurneyErrorCode.offline);

  @override
  Future<List<SentGroupInvitation>> sent(String journeyId) async =>
      throw _offline;
  @override
  Future<void> revoke(String invitationId) async => throw _offline;
  @override
  Future<void> renameCouple(String j, String s, String p) async =>
      throw _offline;
}
