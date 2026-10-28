import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/data_providers.dart';
import '../data/db/app_database.dart';
import 'config.dart';

/// Hand-off point for the Data/Sync agent (B1).
///
/// B1 owns the BODY of this function (the only file in lib/app/ a feature
/// agent may edit): open the drift database, build the repositories from
/// lib/data and return the overrides for the placeholder providers declared
/// in providers.dart, e.g.
///
/// ```dart
/// final db = AppDatabase();
/// return [
///   journeyRepositoryProvider.overrideWithValue(DriftJourneyRepository(db)),
///   ...
/// ];
/// ```
///
/// Called once from main.dart after Supabase is initialised (when
/// [AppConfig.hasBackend]) and before `runApp`. Keep it fast: the camera must
/// be ready < 1s warm / < 2s cold (NFR-1), so defer heavy work.
Future<List<Override>> createDataOverrides(AppConfig config) async {
  // The database opens lazily in a background isolate (drift_flutter); the
  // repositories and sync triggers are built on first use (dataLayerProvider).
  // The mode follows supabaseClientProvider (null in local-only).
  //
  // Private app data lives in Application Support, not Documents (Documents
  // is user-visible on iOS via Files/iTunes file sharing). Android backups
  // are disabled in AndroidManifest.xml (allowBackup=false). iOS still
  // includes Application Support in iCloud/device backups: excluding it
  // needs NSURLIsExcludedFromBackupKey, which path_provider cannot set
  // (documented in docs/contracts/schema.md, "Client storage").
  final support = await getApplicationSupportDirectory();
  return dataOverrides(
    DataEnvironment(
      db: AppDatabase(
        driftDatabase(
          name: 'ourney',
          native: const DriftNativeOptions(
            databaseDirectory: getApplicationSupportDirectory,
          ),
        ),
      ),
      mediaRoot: Directory(p.join(support.path, 'media')),
      connectivity: config.hasBackend
          ? () => Connectivity().onConnectivityChanged
          : null,
    ),
    // Social v1.3 is server-only: local-only keeps those providers unwired
    // (the UI shows NeedsServerView).
    social: config.hasBackend,
  );
}
