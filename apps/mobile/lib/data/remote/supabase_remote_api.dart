import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:ourney_core/ourney_core.dart'
    show OurneyErrorCode, OurneyException;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'error_mapping.dart';
import 'remote_api.dart';

/// Signed URL lifetime (NFR-3).
const Duration signedUrlTtl = Duration(hours: 1);

/// Default network timeout for RPCs, queries and storage metadata calls (FS-27).
const Duration remoteRequestTimeout = Duration(seconds: 30);

/// Default network timeout for storage binary uploads (FS-27).
const Duration remoteUploadTimeout = Duration(seconds: 45);

/// Network timeout for global sign-out before falling back to local sign-out (FS-27).
const Duration remoteSignOutTimeout = Duration(seconds: 5);

/// Maximum lifetime for reusing an already-verified recovery OTP within the
/// same password reset/update flow after `updateUser` fails (R-2).
const Duration verifiedRecoveryTtl = Duration(minutes: 5);

/// [RemoteApi] backed by a real [SupabaseClient]. Kept deliberately thin: all
/// decisions live in the sync/repository layer, which is tested with a fake.
class SupabaseRemoteApi implements RemoteApi {
  SupabaseRemoteApi(
    this._client, {
    HttpClient? httpClient,
    DateTime Function()? now,
  }) : _http = httpClient ?? HttpClient(),
       _now = now ?? DateTime.now;

  final SupabaseClient _client;
  final HttpClient _http;
  final DateTime Function() _now;
  String? _termsUserId;
  int? _acceptedTermsVersion;
  String? _verifiedRecoveryKey;
  DateTime? _verifiedRecoveryAt;
  bool _resetInFlight = false;
  String? _preResetUserId;
  final StreamController<String?> _resetRelease =
      StreamController<String?>.broadcast();

  void _clearVerifiedRecovery() {
    _verifiedRecoveryKey = null;
    _verifiedRecoveryAt = null;
  }

  bool _hasValidVerifiedRecovery(String recoveryKey) {
    final key = _verifiedRecoveryKey;
    final at = _verifiedRecoveryAt;
    if (key == null || at == null || key != recoveryKey) return false;
    if (_now().difference(at) > verifiedRecoveryTtl) {
      _clearVerifiedRecovery();
      return false;
    }
    return true;
  }

  void _rememberVerifiedRecovery(String recoveryKey) {
    _verifiedRecoveryKey = recoveryKey;
    _verifiedRecoveryAt = _now();
  }

  StorageFileApi _bucket(String path) =>
      _client.storage.from(storageBucketFor(path));

  @override
  String? get currentUserId =>
      _resetInFlight ? _preResetUserId : _client.auth.currentUser?.id;

  @override
  Stream<String?> watchUserId() {
    late final StreamController<String?> controller;
    StreamSubscription<AuthState>? authSub;
    StreamSubscription<String?>? releaseSub;
    controller = StreamController<String?>(
      onListen: () {
        authSub = _client.auth.onAuthStateChange.listen(
          (s) {
            if (s.event == AuthChangeEvent.signedOut) {
              _clearVerifiedRecovery();
            }
            if (_resetInFlight) return;
            if (!controller.isClosed) {
              controller.add(s.session?.user.id);
            }
          },
          onError: (Object e, StackTrace st) {
            if (!controller.isClosed) controller.addError(e, st);
          },
        );
        releaseSub = _resetRelease.stream.listen((uid) {
          if (!controller.isClosed) {
            controller.add(uid);
          }
        });
      },
      onCancel: () async {
        await authSub?.cancel();
        await releaseSub?.cancel();
      },
    );
    return controller.stream.distinct();
  }

  void _releaseResetHold({bool emit = false}) {
    final wasHeld = _resetInFlight;
    _resetInFlight = false;
    _preResetUserId = null;
    if (emit && wasHeld) {
      _resetRelease.add(_client.auth.currentUser?.id);
    }
  }

  @override
  String? get signInIdentifier {
    final user = _client.auth.currentUser;
    final email = user?.email;
    if (email != null && email.isNotEmpty) return email;
    final phone = user?.phone;
    return phone != null && phone.isNotEmpty ? phone : null;
  }

  @override
  int? get acceptedTermsVersion {
    final uid = currentUserId;
    if (uid == null || uid != _termsUserId) return null;
    return _acceptedTermsVersion;
  }

  void _rememberTermsFromProfiles(List<RemoteRow> rows) {
    final uid = currentUserId;
    if (uid == null) return;
    for (final r in rows) {
      if (r['id'] == uid && r['terms_version'] is num) {
        final v = (r['terms_version'] as num).toInt();
        if (_termsUserId != uid || v > (_acceptedTermsVersion ?? 0)) {
          _termsUserId = uid;
          _acceptedTermsVersion = v;
        }
      }
    }
  }

  @override
  Future<void> recordTermsAccepted(int version) => guardRemote(() async {
    final res = await _client
        .rpc<Object?>('accept_terms', params: {'p_version': version})
        .timeout(const Duration(seconds: 10));
    final uid = currentUserId;
    if (uid != null) {
      final recorded = res is num ? res.toInt() : version;
      if (_termsUserId != uid || recorded > (_acceptedTermsVersion ?? 0)) {
        _termsUserId = uid;
        _acceptedTermsVersion = recorded;
      }
    }
  });

  @override
  Future<void> sendOtp(String email) => guardRemote(
    () => _client.auth
        .signInWithOtp(email: email.trim(), shouldCreateUser: true)
        .timeout(remoteRequestTimeout),
  );

  @override
  Future<void> verifyOtp(String email, String code) => guardRemote(() async {
    await _client.auth
        .verifyOTP(
          email: email.trim(),
          token: code.trim(),
          type: OtpType.email,
        )
        .timeout(remoteRequestTimeout);
    _clearVerifiedRecovery();
    _releaseResetHold(emit: true);
  });

  @override
  Future<void> sendPhoneOtp(String e164Phone) => guardRemote(
    () => _client.auth
        .signInWithOtp(phone: e164Phone, shouldCreateUser: true)
        .timeout(remoteRequestTimeout),
  );

  @override
  Future<void> verifyPhoneOtp(String e164Phone, String code) =>
      guardRemote(() async {
        await _client.auth
            .verifyOTP(
              phone: e164Phone,
              token: code.trim(),
              type: OtpType.sms,
            )
            .timeout(remoteRequestTimeout);
        _clearVerifiedRecovery();
        _releaseResetHold(emit: true);
      });

  @override
  Future<bool> signUpWithPassword(String email, String password) =>
      guardRemote(() async {
        final res = await _client.auth
            .signUp(
              email: email.trim(),
              password: password,
            )
            .timeout(remoteRequestTimeout);
        if (res.session != null) {
          _clearVerifiedRecovery();
          _releaseResetHold(emit: true);
        }
        return res.session == null;
      });

  @override
  Future<void> confirmSignUp(String email, String code) =>
      guardRemote(() async {
        await _client.auth
            .verifyOTP(
              email: email.trim(),
              token: code.trim(),
              type: OtpType.signup,
            )
            .timeout(remoteRequestTimeout);
        _clearVerifiedRecovery();
        _releaseResetHold(emit: true);
      });

  @override
  Future<void> signInWithPassword(String email, String password) =>
      guardRemote(() async {
        await _client.auth
            .signInWithPassword(
              email: email.trim(),
              password: password,
            )
            .timeout(remoteRequestTimeout);
        _clearVerifiedRecovery();
        _releaseResetHold(emit: true);
      });

  @override
  Future<void> sendPasswordReset(String email) => guardRemote(() async {
    _clearVerifiedRecovery();
    await _client.auth
        .resetPasswordForEmail(email.trim())
        .timeout(remoteRequestTimeout);
  });

  @override
  Future<void> resetPassword(String email, String code, String newPassword) =>
      guardRemote(() async {
        final trimmedEmail = email.trim();
        final trimmedCode = code.trim();
        if (!_resetInFlight) {
          _preResetUserId = _client.auth.currentUser?.id;
          _resetInFlight = true;
        }
        final currentEmail = _client.auth.currentUser?.email;
        final currentUid = _client.auth.currentUser?.id ?? '';
        final recoveryKey =
            '$currentUid:${trimmedEmail.toLowerCase()}:$trimmedCode';
        final needsVerify =
            currentUid.isEmpty ||
            !_hasValidVerifiedRecovery(recoveryKey) ||
            currentEmail == null ||
            currentEmail.toLowerCase() != trimmedEmail.toLowerCase();
        if (needsVerify) {
          try {
            await _client.auth
                .verifyOTP(
                  email: trimmedEmail,
                  token: trimmedCode,
                  type: OtpType.recovery,
                )
                .timeout(remoteRequestTimeout);
            await _client.realtime.setAuth(
              _client.auth.currentSession?.accessToken,
            );
          } on Object {
            if (_verifiedRecoveryKey == null) {
              _releaseResetHold();
            }
            rethrow;
          }
          final verifiedUid = _client.auth.currentUser?.id ?? '';
          _rememberVerifiedRecovery(
            '$verifiedUid:${trimmedEmail.toLowerCase()}:$trimmedCode',
          );
        }
        try {
          await _client.auth
              .updateUser(UserAttributes(password: newPassword))
              .timeout(remoteRequestTimeout);
        } on AuthException catch (e) {
          if (e.code != 'same_password') rethrow;
        }
        _clearVerifiedRecovery();
        await _signOutOthersBestEffort();
        _releaseResetHold(emit: true);
      });

  @override
  Future<bool> hasPassword() => guardRemote(() async {
    if (currentUserId == null) return false;
    final res = await _client
        .rpc<Object?>('auth_has_password')
        .timeout(remoteRequestTimeout);
    return res == true;
  });

  @override
  Future<void> updatePassword(
    String newPassword, {
    required String code,
    bool signOutOthers = false,
  }) => guardRemote(() async {
    final email = _client.auth.currentUser?.email?.trim();
    if (email == null || email.isEmpty) {
      throw const OurneyException(OurneyErrorCode.invalid);
    }
    final trimmedCode = code.trim();
    if (trimmedCode.isEmpty) {
      throw const OurneyException(OurneyErrorCode.invalid);
    }
    final currentUid = _client.auth.currentUser?.id ?? '';
    final recoveryKey = '$currentUid:${email.toLowerCase()}:$trimmedCode';
    if (currentUid.isEmpty || !_hasValidVerifiedRecovery(recoveryKey)) {
      await _client.auth
          .verifyOTP(
            email: email,
            token: trimmedCode,
            type: OtpType.recovery,
          )
          .timeout(remoteRequestTimeout);
      await _client.realtime.setAuth(
        _client.auth.currentSession?.accessToken,
      );
      final verifiedUid = _client.auth.currentUser?.id ?? '';
      _rememberVerifiedRecovery(
        '$verifiedUid:${email.toLowerCase()}:$trimmedCode',
      );
    }
    await _client.auth
        .updateUser(UserAttributes(password: newPassword))
        .timeout(remoteRequestTimeout);
    _clearVerifiedRecovery();
    if (signOutOthers) {
      await _signOutOthersBestEffort();
    }
  });

  @override
  Future<void> cancelPasswordFlow() async {
    _clearVerifiedRecovery();
    if (!_resetInFlight) return;
    final shouldSignOut =
        _preResetUserId == null && _client.auth.currentSession != null;
    try {
      if (shouldSignOut) {
        try {
          await _client.auth
              .signOut(scope: SignOutScope.local)
              .timeout(remoteSignOutTimeout);
        } on Object {
          // Local sign-out only clears the stored session; ignore errors.
        }
      }
    } finally {
      _releaseResetHold();
    }
  }

  Future<void> _signOutOthersBestEffort() async {
    try {
      await _client.auth
          .signOut(scope: SignOutScope.others)
          .timeout(remoteSignOutTimeout);
    } on Object {
      // Best-effort revocation of other devices; keep the active session.
    }
  }

  @override
  Future<void> signOut({bool global = false}) async {
    _termsUserId = null;
    _acceptedTermsVersion = null;
    _clearVerifiedRecovery();
    _releaseResetHold();
    if (global) {
      try {
        await _client.auth
            .signOut(scope: SignOutScope.global)
            .timeout(remoteSignOutTimeout);
        return;
      } on Object {
        // Offline, timed out, or server error: still end the session on this device.
      }
    }
    try {
      await _client.auth
          .signOut(scope: SignOutScope.local)
          .timeout(remoteSignOutTimeout);
    } on Object {
      // Local sign-out only clears the stored session; ignore server errors.
    }
  }

  @override
  Future<List<RemoteRow>> select(
    String table, {
    Map<String, Object> eq = const {},
    Map<String, List<Object>> inList = const {},
    String? updatedSince,
    bool onlyLive = false,
    int? limit,
  }) => guardRemote(() async {
    var q = _client.from(table).select();
    for (final e in eq.entries) {
      q = q.eq(e.key, e.value);
    }
    for (final e in inList.entries) {
      q = q.inFilter(e.key, e.value);
    }
    if (updatedSince != null) q = q.gte('updated_at', updatedSince);
    if (onlyLive) q = q.isFilter('deleted_at', null);
    final ordered = q.order('updated_at', ascending: true);
    final List<RemoteRow> rows = await (limit == null
            ? ordered
            : ordered.limit(limit))
        .timeout(remoteRequestTimeout);
    if (table == 'profiles') _rememberTermsFromProfiles(rows);
    return rows;
  });

  @override
  Future<void> upsert(
    String table,
    RemoteRow row, {
    required String onConflict,
  }) => guardRemote(() async {
    await _client
        .from(table)
        .upsert(row, onConflict: onConflict)
        .timeout(remoteRequestTimeout);
  });

  @override
  Future<void> insert(String table, RemoteRow row) => guardRemote(() async {
    await _client.from(table).insert(row).timeout(remoteRequestTimeout);
  });

  @override
  Future<void> delete(String table, {required Map<String, Object> match}) =>
      guardRemote(() async {
        await _client
            .from(table)
            .delete()
            .match(match)
            .timeout(remoteRequestTimeout);
      });

  @override
  Future<List<RemoteRow>> update(
    String table,
    RemoteRow values, {
    required Map<String, Object> match,
  }) => guardRemote(() async {
    final List<RemoteRow> rows = await _client
        .from(table)
        .update(values)
        .match(match)
        .select()
        .timeout(remoteRequestTimeout);
    if (table == 'profiles') _rememberTermsFromProfiles(rows);
    return rows;
  });

  @override
  Future<Object?> rpc(String fn, [Map<String, dynamic> params = const {}]) =>
      guardRemote(() async {
        final Object? result = await _client
            .rpc<Object?>(fn, params: params)
            .timeout(remoteRequestTimeout);
        return result;
      });

  @override
  Future<Object?> invokeFunction(String name, {Object? body}) =>
      guardRemote(() async {
        final res = await _client.functions
            .invoke(name, body: body)
            .timeout(remoteRequestTimeout);
        return res.data;
      });

  @override
  Stream<RemoteRow> watchInserts(
    String table, {
    String? column,
    String? value,
  }) {
    RealtimeChannel? channel;
    late final StreamController<RemoteRow> controller;
    controller = StreamController<RemoteRow>(
      onListen: () {
        final suffix = column == null ? '' : ':$column=$value';
        channel = _client
            .channel('ourney:$table$suffix:${_channelSeq++}')
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: table,
              filter: column == null || value == null
                  ? null
                  : PostgresChangeFilter(
                      type: PostgresChangeFilterType.eq,
                      column: column,
                      value: value,
                    ),
              callback: (payload) {
                if (!controller.isClosed) controller.add(payload.newRecord);
              },
            )
            .subscribe((status, error) {
              final failed =
                  status == RealtimeSubscribeStatus.channelError ||
                  status == RealtimeSubscribeStatus.timedOut;
              if ((failed || error != null) && !controller.isClosed) {
                controller.addError(
                  mapRemoteError(error ?? TimeoutException('realtime $status')),
                );
              }
            });
      },
      onCancel: () async {
        final c = channel;
        channel = null;
        if (c != null) {
          try {
            await _client.removeChannel(c);
          } on Object {
            // Already closed: nothing to release.
          }
        }
      },
    );
    return controller.stream;
  }

  static int _channelSeq = 0;

  static const _jpeg = FileOptions(upsert: true, contentType: 'image/jpeg');

  @override
  Future<void> uploadFile(String path, File file) => guardRemote(() async {
    await _bucket(
      path,
    ).upload(path, file, fileOptions: _jpeg).timeout(remoteUploadTimeout);
  });

  @override
  Future<void> uploadBytes(String path, List<int> bytes) =>
      guardRemote(() async {
        await _bucket(path)
            .uploadBinary(path, Uint8List.fromList(bytes), fileOptions: _jpeg)
            .timeout(remoteUploadTimeout);
      });

  @override
  Future<List<String>> listFiles(String prefix) => guardRemote(() async {
    // Storage lists 100 objects per call by default: page until short.
    const page = 100;
    final names = <String>[];
    for (var offset = 0; ; offset += page) {
      final objects = await _bucket(prefix)
          .list(
            path: prefix,
            searchOptions: SearchOptions(limit: page, offset: offset),
          )
          .timeout(remoteRequestTimeout);
      names.addAll([
        for (final o in objects)
          if (o.id != null) '$prefix/${o.name}',
      ]);
      if (objects.length < page) return names;
    }
  });

  @override
  Future<void> removeFiles(List<String> paths) => guardRemote(() async {
    for (var i = 0; i < paths.length; i += 100) {
      final end = i + 100 > paths.length ? paths.length : i + 100;
      final chunk = paths.sublist(i, end);
      // One request per bucket (checkins/avatars vs messages).
      final byBucket = <String, List<String>>{};
      for (final path in chunk) {
        (byBucket[storageBucketFor(path)] ??= []).add(path);
      }
      for (final e in byBucket.entries) {
        await _client.storage
            .from(e.key)
            .remove(e.value)
            .timeout(remoteRequestTimeout);
      }
    }
  });

  @override
  Future<void> downloadToFile(String path, File target) =>
      guardRemote(() async {
        // Readable when RLS allows it: own media, a group's media, a journey
        // shared with the caller (0006) or a conversation's photos.
        final url = await _bucket(path)
            .createSignedUrl(path, signedUrlTtl.inSeconds)
            .timeout(remoteRequestTimeout);
        final request = await _http
            .getUrl(Uri.parse(url))
            .timeout(const Duration(seconds: 20));
        final response = await request.close().timeout(
          const Duration(seconds: 60),
        );
        if (response.statusCode != HttpStatus.ok) {
          await response.drain<void>();
          throw StorageException(
            'download failed',
            statusCode: '${response.statusCode}',
          );
        }
        await target.parent.create(recursive: true);
        final sink = target.openWrite();
        try {
          await response.pipe(sink);
        } on Object {
          if (target.existsSync()) target.deleteSync();
          rethrow;
        }
      });
}
