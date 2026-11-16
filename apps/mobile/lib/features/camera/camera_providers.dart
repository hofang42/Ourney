import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/providers.dart';
import '../journeys/data/journeys_providers.dart';

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
  (ref) => ref.watch(journeyRepositoryProvider).watchActive(),
  retry: _noRetry,
);

/// Ids of the journeys already shot today, by the device-local calendar day
/// (the journey timezone database is never loaded on the camera, NFR-1).
final captureShotTodayProvider = FutureProvider.autoDispose<Set<String>>((
  ref,
) async {
  final journeys = await ref.watch(capturePickerJourneysProvider.future);
  final n = clock.now();
  final today = LocalDate(n.year, n.month, n.day);
  final shot = <String>{};
  for (final j in journeys) {
    final list = await ref.watch(myCheckInsProvider(j.id).future);
    if (list.any((c) => c.localDate == today)) shot.add(j.id);
  }
  return shot;
}, retry: _noRetry);
