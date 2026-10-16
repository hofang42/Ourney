import 'dart:async';

import 'package:ourney_core/ourney_core.dart';

import '../data_context.dart';
import '../remote/remote_api.dart';

/// Local-only mode (FR-A5): there is no account. Per the contract
/// [currentUserId] is null and [watchUserId] emits null; the data layer
/// stores rows under a stable on-device guest id ([guestUserId], kept in
/// shared preferences) so the cache already has the server's shape.
class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository(this.ctx, {required this.guestUserId});

  final DataContext ctx;

  /// Stable UUID owning every local row (journeys, memberships, check-ins).
  final String guestUserId;

  @override
  String? get currentUserId => null;

  @override
  bool get isLocalOnly => true;

  @override
  Stream<String?> watchUserId() => Stream<String?>.value(null);

  static Never _needsServer() => throw const OurneyException(
    OurneyErrorCode.offline,
    'local-only mode: sign-in needs a server',
  );

  @override
  Future<void> sendOtp(String email) async => _needsServer();

  @override
  Future<void> verifyOtp(String email, String code) async => _needsServer();

  @override
  Future<void> signOut() async {}

  /// Nothing lives on a server: wipes the local database and media.
  @override
  Future<void> deleteAccount() => ctx.wipeLocal();
}

/// Supabase email-OTP auth. The cache is tied to the signed-in user (see
/// `SyncEngine.ensureOwner`); signing in triggers a sync.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this.ctx, this.remote);

  final DataContext ctx;
  final RemoteApi remote;

  @override
  String? get currentUserId => remote.currentUserId;

  @override
  bool get isLocalOnly => false;

  @override
  Stream<String?> watchUserId() => remote.watchUserId();

  @override
  Future<void> sendOtp(String email) => remote.sendOtp(email);

  @override
  Future<void> verifyOtp(String email, String code) async {
    await remote.verifyOtp(email, code);
    final sync = ctx.sync;
    if (sync != null) unawaited(sync.syncNow());
  }

  /// Global sign-out (every device's refresh token is revoked, local-only
  /// fallback when offline), then wipes the local cache: rows, outbox
  /// (unsent check-ins are lost) and media, so nothing of the account stays
  /// on the device.
  @override
  Future<void> signOut() async {
    await remote.signOut(global: true);
    await ctx.wipeLocal();
  }

  /// Edge Function `delete-account` (POST with the user's JWT), then wipes
  /// the local cache and the session. Errors are mapped [OurneyException]s
  /// (`unauthenticated`, `storage*`, `deleteFailed`, `offline`); nothing local
  /// is touched when the server call fails, so it is safe to retry.
  @override
  Future<void> deleteAccount() async {
    if (remote.currentUserId == null) {
      throw const OurneyException(OurneyErrorCode.unauthenticated);
    }
    await remote.invokeFunction(deleteAccountFunction);
    await ctx.wipeLocal();
    await remote.signOut();
  }
}
