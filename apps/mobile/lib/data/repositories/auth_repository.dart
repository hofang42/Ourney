import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:ourney_core/ourney_core.dart';

import '../data_context.dart';
import '../db/app_database.dart' show ProfilesCompanion;
import '../remote/remote_api.dart';

/// How long sign-out waits for the outbox to drain before wiping.
const Duration signOutFlushTimeout = Duration(seconds: 5);

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
  String? get signInIdentifier => null;

  @override
  int? get acceptedTermsVersion => null;

  @override
  Future<void> recordTermsAccepted(int version) async {}

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
  Future<bool> hasPassword() async => false;

  @override
  Future<void> updatePassword(
    String newPassword, {
    required String code,
    bool signOutOthers = false,
  }) async => _needsServer();

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
  String? get signInIdentifier => remote.signInIdentifier;

  @override
  int? get acceptedTermsVersion => remote.acceptedTermsVersion;

  @override
  Future<void> recordTermsAccepted(int version) async {
    await remote.recordTermsAccepted(version);
    final me = remote.currentUserId;
    if (me != null) {
      final recorded = remote.acceptedTermsVersion ?? version;
      final existing = await (ctx.db.select(
        ctx.db.profiles,
      )..where((t) => t.id.equals(me))).getSingleOrNull();
      if (existing != null && recorded > existing.termsVersion) {
        await (ctx.db.update(
          ctx.db.profiles,
        )..where((t) => t.id.equals(me))).write(
          ProfilesCompanion(termsVersion: Value(recorded)),
        );
      }
    }
  }

  @override
  Stream<String?> watchUserId() => remote.watchUserId();

  @override
  Future<void> sendOtp(String email) => remote.sendOtp(email);

  @override
  Future<void> verifyOtp(String email, String code) async {
    await remote.verifyOtp(email, code);
    _syncSoon();
  }

  /// Runs pull sync only once the signed-in account has a `profiles` row
  /// (returning account), deferring initial sync for brand-new accounts until
  /// `DataProfileRepository.upsertMe` creates the profile on `/profile/setup`
  /// (H1).
  Future<void> syncWhenProfileReady() async {
    final sync = ctx.sync;
    final me = remote.currentUserId;
    if (sync == null || me == null) return;
    try {
      await sync.ensureOwner(me);
      var row = await (ctx.db.select(
        ctx.db.profiles,
      )..where((t) => t.id.equals(me))).getSingleOrNull();
      if (row == null) {
        final rows = await remote.select('profiles', eq: {'id': me});
        for (final r in rows) {
          await ctx.store.applyProfile(r);
        }
        row = await (ctx.db.select(
          ctx.db.profiles,
        )..where((t) => t.id.equals(me))).getSingleOrNull();
      }
      if (row != null && remote.currentUserId == me) {
        await sync.syncNow();
      }
    } on Object {
      // Offline or no profile yet: sync runs after profile setup or reconnect.
    }
  }

  void _syncSoon() {
    unawaited(syncWhenProfileReady());
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
  Future<bool> hasPassword() => remote.hasPassword();

  @override
  Future<void> updatePassword(
    String newPassword, {
    required String code,
    bool signOutOthers = false,
  }) => remote.updatePassword(
    newPassword,
    code: code,
    signOutOthers: signOutOthers,
  );

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
    // Unsent check-ins are lost with the wipe: give the outbox one last short
    // chance while the session is still valid (offline fails fast).
    final outbox = ctx.outbox;
    if (outbox != null && remote.currentUserId != null) {
      try {
        await outbox.flush(force: true).timeout(signOutFlushTimeout);
      } on Object catch (e) {
        debugPrint('auth: outbox flush before sign-out skipped: $e');
      }
    }
    try {
      await remote.signOut(global: true).timeout(signOutFlushTimeout);
    } on Object catch (e) {
      debugPrint('auth: global sign-out timed out or failed ($e); falling back to local sign-out');
      await remote.signOut();
    }
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
    try {
      await remote.invokeFunction(
        deleteAccountFunction,
        body: {'action': 'delete', 'code': code ?? ''},
      );
    } on OurneyException catch (e) {
      // Only the server's explicit "that account no longer exists" (410) is
      // read as success: a retry after a lost response, or a deletion made
      // on another device. A plain 401 (revoked or expired session), a wrong
      // code or any other failure stays an error, so local data is never
      // wiped while the account may still exist.
      if (e.error != OurneyErrorCode.alreadyDeleted) rethrow;
      debugPrint('auth: account already deleted on the server');
    }
    // Sign out first: a sync starting between the wipe and the sign-out
    // would pull the deleted account's rows back into the cache.
    await remote.signOut();
    await ctx.wipeLocal();
  }
}
