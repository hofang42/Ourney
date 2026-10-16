// Riverpod wiring of the data layer (B1). Features never import this file
// except for [mediaFileProvider]; they use the repository providers declared
// in lib/app/providers.dart, which createDataOverrides() points here.
import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../app/providers.dart';
import 'data_layer.dart';
import 'db/app_database.dart';
import 'remote/remote_api.dart';
import 'remote/supabase_remote_api.dart';

part 'data_providers.g.dart';

/// Platform resources the data layer runs on (opened in createDataOverrides,
/// in-memory in tests).
class DataEnvironment {
  const DataEnvironment({
    required this.db,
    required this.mediaRoot,
    this.remote,
    this.connectivity,
    this.listenLifecycle = true,
    this.autoSync = true,
  });

  final AppDatabase db;

  /// Media cache root (laid out like the `media` bucket).
  final Directory mediaRoot;

  /// Test seam: replaces the Supabase transport (forces Supabase mode).
  final RemoteApi? remote;

  /// Connectivity changes (connectivity_plus); null disables that trigger.
  final Stream<List<ConnectivityResult>> Function()? connectivity;
  final bool listenLifecycle;
  final bool autoSync;
}

/// Shared-preferences key of the local-only guest user id.
const String guestUserIdKey = 'data.guestUserId';

/// The stable guest id (created and persisted on first use).
String guestUserIdFrom(SharedPreferencesWithCache prefs) {
  final existing = prefs.getString(guestUserIdKey);
  if (existing != null && existing.isNotEmpty) return existing;
  final id = const Uuid().v4();
  // The cache updates synchronously; the platform write completes later.
  unawaited(prefs.setString(guestUserIdKey, id));
  return id;
}

@Riverpod(keepAlive: true)
DataEnvironment dataEnvironment(Ref ref) => throw UnimplementedError(
  'dataEnvironmentProvider is overridden by createDataOverrides().',
);

/// Builds the repositories for the configured mode: Supabase when a client
/// exists (or a test [DataEnvironment.remote]), local-only otherwise.
@Riverpod(keepAlive: true)
DataLayer dataLayer(Ref ref) {
  final env = ref.watch(dataEnvironmentProvider);
  final client = ref.watch(supabaseClientProvider);
  final remote =
      env.remote ?? (client == null ? null : SupabaseRemoteApi(client));
  final DataLayer layer;
  if (remote == null) {
    layer = DataLayer.localOnly(
      db: env.db,
      mediaRoot: env.mediaRoot,
      guestUserId: guestUserIdFrom(ref.watch(sharedPreferencesProvider)),
    );
  } else {
    layer = DataLayer.supabase(
      db: env.db,
      mediaRoot: env.mediaRoot,
      remote: remote,
      connectivity: env.connectivity?.call(),
      listenLifecycle: env.listenLifecycle,
      autoSync: env.autoSync,
    );
  }
  ref.onDispose(layer.dispose);
  return layer;
}

/// Absolute path of a displayable file for a storage path (check-in photo or
/// thumbnail, avatar): own media straight from disk, other members' media
/// downloaded once through a 1 h signed URL and cached by path.
///
/// ```dart
/// final file = ref.watch(mediaFileProvider(checkIn.thumbPath));
/// file.when(data: (p) => Image.file(File(p)), ...);
/// ```
@riverpod
Future<String> mediaFile(Ref ref, String storagePath) =>
    ref.watch(mediaStoreProvider).localFileFor(storagePath);

/// Overrides for the placeholder repository providers of lib/app/providers.dart.
List<Override> dataOverrides(DataEnvironment env) => [
  dataEnvironmentProvider.overrideWithValue(env),
  authRepositoryProvider.overrideWith(
    (ref) => ref.watch(dataLayerProvider).auth,
  ),
  profileRepositoryProvider.overrideWith(
    (ref) => ref.watch(dataLayerProvider).profiles,
  ),
  journeyRepositoryProvider.overrideWith(
    (ref) => ref.watch(dataLayerProvider).journeys,
  ),
  checkInRepositoryProvider.overrideWith(
    (ref) => ref.watch(dataLayerProvider).checkIns,
  ),
  groupRepositoryProvider.overrideWith(
    (ref) => ref.watch(dataLayerProvider).groups,
  ),
  safetyRepositoryProvider.overrideWith(
    (ref) => ref.watch(dataLayerProvider).safety,
  ),
  mediaStoreProvider.overrideWith((ref) => ref.watch(dataLayerProvider).media),
];
