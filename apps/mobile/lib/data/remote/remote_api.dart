// Thin transport seam over supabase_flutter so the sync/repository logic can
// be tested with a fake (test/data/fake_remote_api.dart). Every method throws
// an [OurneyException] already mapped with `mapRemoteError`; network failures
// surface as `OurneyErrorCode.offline`.
import 'dart:io';

/// A row as returned by PostgREST (snake_case keys, ISO timestamps).
typedef RemoteRow = Map<String, dynamic>;

abstract interface class RemoteApi {
  // --- Auth -----------------------------------------------------------------
  String? get currentUserId;
  Stream<String?> watchUserId();
  Future<void> sendOtp(String email);
  Future<void> verifyOtp(String email, String code);

  /// Signs out. [global] also revokes the refresh tokens of every device
  /// (falls back to a local sign-out when the server is unreachable). Never
  /// throws.
  Future<void> signOut({bool global = false});

  // --- Database ---------------------------------------------------------------
  /// `select * from [table]` with equality / `in` filters, optionally only
  /// rows with `updated_at >= updatedSince`, ordered by `updated_at` asc.
  Future<List<RemoteRow>> select(
    String table, {
    Map<String, Object> eq = const {},
    Map<String, List<Object>> inList = const {},
    String? updatedSince,
    bool onlyLive = false,
    int? limit,
  });

  /// `insert ... on conflict ([onConflict]) do update`.
  Future<void> upsert(
    String table,
    RemoteRow row, {
    required String onConflict,
  });

  Future<void> insert(String table, RemoteRow row);

  /// `update [table] set [values] where [match]`; returns the updated rows.
  Future<List<RemoteRow>> update(
    String table,
    RemoteRow values, {
    required Map<String, Object> match,
  });

  /// `rpc/<fn>`. Returns the decoded JSON (row object, scalar, list, null).
  Future<Object?> rpc(String fn, [Map<String, dynamic> params = const {}]);

  /// POST to an Edge Function; returns the decoded JSON body.
  Future<Object?> invokeFunction(String name, {Object? body});

  // --- Storage (bucket `media`) --------------------------------------------
  /// Uploads [file] to [path] (overwrites; content type image/jpeg).
  Future<void> uploadFile(String path, File file);

  /// Names (full paths) of the objects directly under [prefix].
  Future<List<String>> listFiles(String prefix);
  Future<void> removeFiles(List<String> paths);

  /// Downloads [path] through a signed URL (TTL 1 h) into [target].
  Future<void> downloadToFile(String path, File target);
}
