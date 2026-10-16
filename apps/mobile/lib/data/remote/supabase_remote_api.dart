import 'dart:async';
import 'dart:io';

import 'package:ourney_core/ourney_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'error_mapping.dart';
import 'remote_api.dart';

/// Signed URL lifetime (NFR-3).
const Duration signedUrlTtl = Duration(hours: 1);

/// [RemoteApi] backed by a real [SupabaseClient]. Kept deliberately thin: all
/// decisions live in the sync/repository layer, which is tested with a fake.
class SupabaseRemoteApi implements RemoteApi {
  SupabaseRemoteApi(this._client, {HttpClient? httpClient})
    : _http = httpClient ?? HttpClient();

  final SupabaseClient _client;
  final HttpClient _http;

  StorageFileApi get _media => _client.storage.from(mediaBucket);

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Stream<String?> watchUserId() =>
      _client.auth.onAuthStateChange.map((s) => s.session?.user.id).distinct();

  @override
  Future<void> sendOtp(String email) => guardRemote(
    () =>
        _client.auth.signInWithOtp(email: email.trim(), shouldCreateUser: true),
  );

  @override
  Future<void> verifyOtp(String email, String code) => guardRemote(() async {
    await _client.auth.verifyOTP(
      email: email.trim(),
      token: code.trim(),
      type: OtpType.email,
    );
  });

  @override
  Future<void> signOut({bool global = false}) async {
    if (global) {
      try {
        await _client.auth.signOut(scope: SignOutScope.global);
        return;
      } on Object {
        // Offline or server error: still end the session on this device.
      }
    }
    try {
      await _client.auth.signOut(scope: SignOutScope.local);
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
    final List<RemoteRow> rows = limit == null
        ? await ordered
        : await ordered.limit(limit);
    return rows;
  });

  @override
  Future<void> upsert(
    String table,
    RemoteRow row, {
    required String onConflict,
  }) => guardRemote(() async {
    await _client.from(table).upsert(row, onConflict: onConflict);
  });

  @override
  Future<void> insert(String table, RemoteRow row) => guardRemote(() async {
    await _client.from(table).insert(row);
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
        .select();
    return rows;
  });

  @override
  Future<Object?> rpc(String fn, [Map<String, dynamic> params = const {}]) =>
      guardRemote(() async {
        final Object? result = await _client.rpc<Object?>(fn, params: params);
        return result;
      });

  @override
  Future<Object?> invokeFunction(String name, {Object? body}) =>
      guardRemote(() async {
        final res = await _client.functions.invoke(name, body: body);
        return res.data;
      });

  @override
  Future<void> uploadFile(String path, File file) => guardRemote(() async {
    await _media.upload(
      path,
      file,
      fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
    );
  });

  @override
  Future<List<String>> listFiles(String prefix) => guardRemote(() async {
    final objects = await _media.list(path: prefix);
    return [
      for (final o in objects)
        if (o.id != null) '$prefix/${o.name}',
    ];
  });

  @override
  Future<void> removeFiles(List<String> paths) => guardRemote(() async {
    for (var i = 0; i < paths.length; i += 100) {
      final end = i + 100 > paths.length ? paths.length : i + 100;
      await _media.remove(paths.sublist(i, end));
    }
  });

  @override
  Future<void> downloadToFile(String path, File target) =>
      guardRemote(() async {
        final url = await _media.createSignedUrl(path, signedUrlTtl.inSeconds);
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
