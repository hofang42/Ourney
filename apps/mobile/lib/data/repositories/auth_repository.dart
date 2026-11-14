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
  Future<void> sendPhoneOtp(String e164Phone) async => _needsServer();

  @override
  Future<void> verifyPhoneOtp(String e164Phone, String code) async =>
      _needsServer();

  @override
  Future<bool> signUpWithPassword(String email, String password) async =>
      _needsServer();

  @override
  Future<void> confirmSignUp(String email, String code) async => _needsServer();

  @override
  Future<void> signInWithPassword(String email, String password) async =>
      _needsServer();

  @override
  Future<void> sendPasswordReset(String email) async => _needsServer();

  @override
  Future<void> resetPassword(
    String email,
    String code,
    String newPassword,
  ) async => _needsServer();

  @override
  Future<void> requestDeleteCode() async {}

  @override
  Future<void> signOut() async {}

  /// Nothing lives on a server: wipes the local database and media.
  @override
  Future<void> deleteAccount({String? code}) => ctx.wipeLocal();
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

  void _syncSoon() {
    final sync = ctx.sync;
    if (sync != null) unawaited(sync.syncNow());
  }

  @override
  Future<void> sendPhoneOtp(String e164Phone) => remote.sendPhoneOtp(e164Phone);

  @override
  Future<void> verifyPhoneOtp(String e164Phone, String code) async {
    await remote.verifyPhoneOtp(e164Phone, code);
    _syncSoon();
  }

  @override
  Future<bool> signUpWithPassword(String email, String password) async {
    final needsCode = await remote.signUpWithPassword(email, password);
    if (!needsCode) _syncSoon();
    return needsCode;
  }

  @override
  Future<void> confirmSignUp(String email, String code) async {
    await remote.confirmSignUp(email, code);
    _syncSoon();
  }

  @override
  Future<void> signInWithPassword(String email, String password) async {
    await remote.signInWithPassword(email, password);
    _syncSoon();
  }

  @override
  Future<void> sendPasswordReset(String email) =>
      remote.sendPasswordReset(email);

  @override
  Future<void> resetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    await remote.resetPassword(email, code, newPassword);
    _syncSoon();
  }

  @override
  Future<void> requestDeleteCode() async {
    if (remote.currentUserId == null) {
      throw const OurneyException(OurneyErrorCode.unauthenticated);
    }
    await remote.invokeFunction(
      deleteAccountFunction,
      body: const {'action': 'send'},
    );
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
  Future<void> deleteAccount({String? code}) async {
    if (remote.currentUserId == null) {
      throw const OurneyException(OurneyErrorCode.unauthenticated);
    }
    await remote.invokeFunction(
      deleteAccountFunction,
      body: {'action': 'delete', 'code': code ?? ''},
    );
    await ctx.wipeLocal();
    await remote.signOut();
  }
}
