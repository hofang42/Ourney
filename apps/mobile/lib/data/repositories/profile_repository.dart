import 'dart:async';

import 'package:drift/drift.dart';
import 'package:ourney_core/ourney_core.dart';

import '../data_context.dart';
import '../db/app_database.dart';
import '../mapping.dart';
import '../remote/remote_api.dart';

/// The caller's profile. Local-only: kept in drift only. Supabase: written to
/// `profiles` online (username uniqueness needs the server) and mirrored in
/// drift; pull sync keeps it fresh.
class DataProfileRepository implements ProfileRepository {
  DataProfileRepository(this.ctx);

  final DataContext ctx;

  AppDatabase get _db => ctx.db;

  /// Supabase mode: when the profile is not cached yet (first sign-in on
  /// this device) it is fetched from `profiles` BEFORE the first event, so a
  /// `null` really means "no profile yet" (→ profile setup), never "not
  /// loaded". If that fetch fails (e.g. `offline`) the stream emits the
  /// [OurneyException] instead of a misleading null.
  @override
  Stream<Profile?> watchMe() async* {
    final me = ctx.userId;
    if (me == null) {
      yield null;
      return;
    }
    final remote = ctx.remote;
    final cached = await _local(me);
    if (remote != null && cached == null) {
      final rows = await remote.select('profiles', eq: {'id': me});
      for (final r in rows) {
        await ctx.store.applyProfile(r);
      }
    } else if (remote != null &&
        (remote.acceptedTermsVersion == null || cached!.termsVersion <= 0)) {
      // Cold start with a cached profile row: refresh own profile in the
      // background so `terms_version` populates both `remote` and Drift
      // without delaying the first cached emission (H2).
      unawaited(_refreshOwnProfile(remote, me));
    }
    yield* (_db.select(_db.profiles)..where((t) => t.id.equals(me)))
        .watchSingleOrNull()
        .map((r) => r == null ? null : profileFromRow(r));
  }

  Future<void> _refreshOwnProfile(RemoteApi remote, String me) async {
    try {
      final rows = await remote.select('profiles', eq: {'id': me});
      if (ctx.userId != me) return;
      for (final r in rows) {
        await ctx.store.applyProfile(r);
      }
    } on Object {
      // Offline on cold start: cached `ProfileRow.termsVersion` still works.
    }
  }

  Future<ProfileRow?> _local(String me) => (_db.select(
    _db.profiles,
  )..where((t) => t.id.equals(me))).getSingleOrNull();

  /// Throws `invalid` for a bad username/display name (and, server-side, for
  /// a username that is already taken: unique violation 23505).
  @override
  Future<void> upsertMe({
    required String username,
    required String displayName,
  }) async {
    final name = displayName.trim();
    if (validateUsername(username) != null ||
        validateDisplayName(name) != null) {
      throw const OurneyException(OurneyErrorCode.invalid);
    }
    final me = await ctx.claimUserId();
    final remote = ctx.remote;
    if (remote != null) {
      // Update first: an upsert would also SET id, which is not granted.
      final values = {'username': username, 'display_name': name};
      final updated = await remote.update(
        'profiles',
        values,
        match: {'id': me},
      );
      if (updated.isEmpty) {
        await remote.insert('profiles', {'id': me, ...values});
      }
    }
    final existing = await _local(me);
    final serverTerms = remote?.acceptedTermsVersion ?? 0;
    final currentTerms = existing?.termsVersion ?? 0;
    await _db
        .into(_db.profiles)
        .insertOnConflictUpdate(
          ProfilesCompanion(
            id: Value(me),
            username: Value(username),
            displayName: Value(name),
            avatarPath: Value(existing?.avatarPath),
            termsVersion: Value(
              serverTerms > currentTerms ? serverTerms : currentTerms,
            ),
          ),
        );
    if (existing == null && ctx.sync != null) {
      unawaited(ctx.sync!.syncNow());
    }
  }

  /// Stores the JPEG at `avatars/{me}/{new uuid}.jpg` (a new path per upload
  /// so caches never serve a stale avatar) and removes the previous one.
  /// Requires a profile (call [upsertMe] first), else `notFound`.
  @override
  Future<void> setAvatar(List<int> jpegBytes) async {
    final me = await ctx.claimUserId();
    final existing = await _local(me);
    if (existing == null) throw const OurneyException(OurneyErrorCode.notFound);
    final path = avatarPath(me, ctx.newId());
    final file = await ctx.files.writeBytes(path, jpegBytes);
    final old = existing.avatarPath;
    final remote = ctx.remote;
    if (remote != null) {
      try {
        await remote.uploadFile(path, file);
        await remote.update(
          'profiles',
          {'avatar_path': path},
          match: {'id': me},
        );
      } on Object {
        await ctx.files.delete([path]);
        rethrow;
      }
      if (old != null) {
        try {
          await remote.removeFiles([old]);
        } on OurneyException {
          // Orphaned old avatar: harmless, removed with the account.
        }
      }
    }
    await (_db.update(_db.profiles)..where((t) => t.id.equals(me))).write(
      ProfilesCompanion(avatarPath: Value(path)),
    );
    if (old != null) await ctx.files.delete([old]);
  }
}
