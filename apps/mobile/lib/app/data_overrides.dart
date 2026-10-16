import 'package:flutter_riverpod/misc.dart' show Override;

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
Future<List<Override>> createDataOverrides(AppConfig config) async =>
    const <Override>[];
