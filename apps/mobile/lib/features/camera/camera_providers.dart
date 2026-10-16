import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/providers.dart';

/// Repository errors surface in the UI with a retry button; never retry on
/// a timer (no hidden work on the camera screen, NFR-1).
Duration? _noRetry(int _, Object _) => null;

/// Active journeys for the journey chip row (FR-C1).
final captureJourneysProvider = StreamProvider.autoDispose<List<Journey>>(
  (ref) => ref
      .watch(journeyRepositoryProvider)
      .watchActive()
      .map(
        (all) => [
          for (final j in all)
            if (j.status == JourneyStatus.active) j,
        ],
      ),
  retry: _noRetry,
);

/// Shared-preferences keys owned by the camera feature.
abstract final class CameraPrefs {
  /// Journey chosen last in the chip row (FR-C1).
  static const lastJourneyId = 'camera.lastJourneyId';

  /// Set once the in-context pre-prompt was accepted and the OS camera
  /// prompt was triggered, so later launches open the camera at once.
  static const permissionAsked = 'camera.permissionAsked';

  static String? readLastJourneyId(SharedPreferencesWithCache prefs) =>
      prefs.getString(lastJourneyId);

  static Future<void> writeLastJourneyId(
    SharedPreferencesWithCache prefs,
    String id,
  ) => prefs.setString(lastJourneyId, id);
}

/// The journey to preselect: the remembered one when still active, else the
/// first active journey. Null when there is none.
Journey? pickInitialJourney(List<Journey> journeys, String? lastId) {
  if (journeys.isEmpty) return null;
  for (final j in journeys) {
    if (j.id == lastId) return j;
  }
  return journeys.first;
}
