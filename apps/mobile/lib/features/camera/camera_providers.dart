import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/providers.dart';
import '../../shared/time_zones.dart';
import '../journeys/data/journeys_providers.dart';

/// Repository errors surface in the UI with a retry button; never retry on
/// a timer (no hidden work on the camera screen, NFR-1).
Duration? _noRetry(int _, Object _) => null;

/// Active journeys for the journey chip row (FR-C1). A journey whose last
/// day is over in ITS time zone takes no photo (B-B7); the clock re-filters at
/// midnight without resubscribing to the database.
final captureJourneysProvider = StreamProvider.autoDispose<List<Journey>>(
  (ref) => mapWithNow(
    ref,
    ref.watch(journeyRepositoryProvider).watchActive(),
    (all, now) => [
      for (final j in all)
        if (j.status == JourneyStatus.active &&
            !j.isPastEndOn(journeyLocalDate(j.timezone, now)))
          j,
    ],
  ),
  retry: _noRetry,
);

/// Shared-preferences keys owned by the camera feature.
abstract final class CameraPrefs {
  /// Journey chosen last in the chip row (FR-C1).
  static const lastJourneyId = ActiveJourneyId.prefsKey;

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

/// Every journey (active and ended) for the picker sheet sections.
final capturePickerJourneysProvider = StreamProvider.autoDispose<List<Journey>>(
  (ref) => mapWithNow(
    ref,
    ref.watch(journeyRepositoryProvider).watchActive(),
    (all, now) => [
      for (final j in all) j.settledOn(journeyLocalDate(j.timezone, now)),
    ],
  ),
  retry: _noRetry,
);

/// Ids of the journeys already shot today, by each journey's own calendar day.
final captureShotTodayProvider = FutureProvider.autoDispose<Set<String>>((
  ref,
) async {
  final journeys = await ref.watch(capturePickerJourneysProvider.future);
  final now = ref.watch(journeysNowProvider);
  final shot = <String>{};
  for (final j in journeys) {
    final today = journeyLocalDate(j.timezone, now);
    final list = await ref.watch(myCheckInsProvider(j.id).future);
    if (list.any((c) => c.localDate == today)) shot.add(j.id);
  }
  return shot;
}, retry: _noRetry);
