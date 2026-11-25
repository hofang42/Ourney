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

/// [RemoteApi] backed by a real [SupabaseClient]. Kept deliberately thin: all
/// decisions live in the sync/repository layer, which is tested with a fake.
class SupabaseRemoteApi implements RemoteApi {
  SupabaseRemoteApi(this._client, {HttpClient? httpClient})
    : _http = httpClient ?? HttpClient();

  final SupabaseClient _client;
  final HttpClient _http;
  String? _termsUserId;
  int? _acceptedTermsVersion;
  String? _verifiedRecoveryKey;

  StorageFileApi _bucket(String path) =>
      _client.storage.from(storageBucketFor(path));

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Stream<String?> watchUserId() =>
      _client.auth.onAuthStateChange.map((s) => s.session?.user.id).distinct();

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
      });

  @override
  Future<void> sendPasswordReset(String email) => guardRemote(
    () => _client.auth
        .resetPasswordForEmail(email.trim())
        .timeout(remoteRequestTimeout),
  );

  @override
  Future<void> resetPassword(String email, String code, String newPassword) =>
      guardRemote(() async {
        final trimmedEmail = email.trim();
        final trimmedCode = code.trim();
        final recoveryKey = '${trimmedEmail.toLowerCase()}:$trimmedCode';
        final currentEmail = _client.auth.currentUser?.email;
        if (_verifiedRecoveryKey != recoveryKey ||
            currentEmail == null ||
            currentEmail.toLowerCase() != trimmedEmail.toLowerCase()) {
          await _client.auth
              .verifyOTP(
                email: trimmedEmail,
                token: trimmedCode,
                type: OtpType.recovery,
              )
              .timeout(remoteRequestTimeout);
          _verifiedRecoveryKey = recoveryKey;
        }
        await _client.auth
            .updateUser(UserAttributes(password: newPassword))
            .timeout(remoteRequestTimeout);
        _verifiedRecoveryKey = null;
        await _signOutOthersBestEffort();
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
  Future<void> sendReauthentication() => guardRemote(() async {
    await _client.auth.reauthenticate().timeout(remoteRequestTimeout);
  });

  @override
  Future<void> updatePassword(
    String newPassword, {
    String? currentPassword,
    String? nonce,
    bool signOutOthers = false,
  }) => guardRemote(() async {
    if (currentPassword != null) {
      final email = _client.auth.currentUser?.email;
      if (email == null || email.isEmpty) {
        throw const OurneyException(OurneyErrorCode.invalid);
      }
      await _client.auth
          .signInWithPassword(email: email, password: currentPassword)
          .timeout(remoteRequestTimeout);
    }
    await _client.auth
        .updateUser(
          UserAttributes(
            password: newPassword,
            nonce: nonce?.trim(),
          ),
        )
        .timeout(remoteRequestTimeout);
    if (signOutOthers) {
      await _signOutOthersBestEffort();
    }
  });

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
    _verifiedRecoveryKey = null;
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
