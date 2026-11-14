import 'package:ourney_core/ourney_core.dart';

import '../../../data/data_context.dart';
import '../../../data/remote/remote_api.dart';

/// [GroupInviteRepository] over the Supabase RPCs of migration 0008. Needs the
/// server: with no remote (local-only mode) every call throws
/// [GroupException] `offline`, and the UI shows the "needs server" state.
class DataGroupInviteRepository implements GroupInviteRepository {
  DataGroupInviteRepository(this.ctx);

  final DataContext ctx;

  Future<T> _call<T>(Future<T> Function(RemoteApi remote) body) async {
    final remote = ctx.remote;
    if (remote == null) {
      throw const GroupException.of(OurneyErrorCode.offline, 'local-only mode');
    }
    try {
      return await body(remote);
    } on GroupException {
      rethrow;
    } on OurneyException catch (e) {
      throw GroupException.of(e.error, e.detail);
    }
  }

  @override
  Future<GroupPreview> previewByCode(String code) => _call((remote) async {
    final normalized = normalizeInviteCode(code);
    if (validateInviteCode(normalized) != null) {
      throw const GroupException.of(OurneyErrorCode.notFound);
    }
    final row = await remote.rpc('preview_group_by_code', {
      'p_code': normalized,
    });
    if (row is! Map) throw const GroupException.of(OurneyErrorCode.notFound);
    return GroupPreview.fromJson(row.cast<String, dynamic>());
  });

  @override
  Future<List<GroupInvitation>> pending() => _call((remote) async {
    final rows = await remote.rpc('my_group_invitations');
    if (rows is! List) return const [];
    return [
      for (final r in rows)
        if (r is Map) GroupInvitation.fromJson(r.cast<String, dynamic>()),
    ];
  });

  @override
  Future<void> send(String journeyId, {String? userId, String? handle}) =>
      _call((remote) async {
        await remote.rpc('send_group_invitation', {
          'p_journey': journeyId,
          'p_user': userId,
          'p_handle': handle,
        });
      });

  @override
  Future<String> accept(String invitationId) => _call((remote) async {
    final row = await remote.rpc('accept_group_invitation', {
      'p_invitation': invitationId,
    });
    if (row is! Map) throw const GroupException.of(OurneyErrorCode.unknown);
    final journey = row.cast<String, dynamic>();
    final id = journey['id'] as String?;
    if (id == null) throw const GroupException.of(OurneyErrorCode.notFound);
    await ctx.store.applyJourney(journey);
    await ctx.sync?.pullJourney(id);
    return id;
  });

  @override
  Future<void> decline(String invitationId) => _call((remote) async {
    await remote.rpc('decline_group_invitation', {
      'p_invitation': invitationId,
    });
  });
}

/// Used when the data layer is not available (local-only mode, tests): every
/// call fails with `offline`.
class UnavailableGroupInviteRepository implements GroupInviteRepository {
  const UnavailableGroupInviteRepository();

  static const _offline = GroupException.of(OurneyErrorCode.offline);

  @override
  Future<GroupPreview> previewByCode(String code) async => throw _offline;
  @override
  Future<List<GroupInvitation>> pending() async => throw _offline;
  @override
  Future<void> send(String journeyId, {String? userId, String? handle}) async =>
      throw _offline;
  @override
  Future<String> accept(String invitationId) async => throw _offline;
  @override
  Future<void> decline(String invitationId) async => throw _offline;
}
