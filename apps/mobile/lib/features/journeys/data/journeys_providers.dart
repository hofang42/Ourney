import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderException;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/providers.dart';
import '../../../shared/time_zones.dart';

/// Shared-preferences key the camera reads to preselect a journey (FR-C1).
/// "Check in now" on the journey screen writes it before opening `/capture`.
const String lastJourneyPrefsKey = 'camera.lastJourneyId';

/// Query parameter added to `/capture` by "Check in now" (same value as
/// [lastJourneyPrefsKey]).
const String captureJourneyParam = 'journeyId';

/// Repository streams must not retry on their own: the repositories already
/// handle offline/sync, and retry timers would leak into widget tests.
Duration? _noRetry(int _, Object _) => null;

/// Wall clock for "today" computations. Override in tests.
final journeysClockProvider = Provider<Clock>((ref) => const Clock());

/// IANA name of the device time zone: the default for new journeys.
/// Override in tests (it uses a platform channel).
final deviceTimezoneProvider = FutureProvider<String>((ref) async {
  try {
    final info = await FlutterTimezone.getLocalTimezone();
    // Stored on the journey: always canonical (Asia/Saigon ->
    // Asia/Ho_Chi_Minh); an unknown name uses the logged best guess.
    if (info.identifier.isNotEmpty) {
      return resolveTimeZone(info.identifier).name;
    }
  } on Object {
    // Fall through: unsupported platform or channel missing.
  }
  return guessTimeZoneForOffset(DateTime.now().timeZoneOffset).name;
}, retry: _noRetry);

/// Journeys shown on the Journeys tab (active, ended and archived ones the
/// repository still lists).
final journeysListProvider = StreamProvider.autoDispose<List<Journey>>(
  (ref) => ref.watch(journeyRepositoryProvider).watchActive(),
  retry: _noRetry,
);

final journeyByIdProvider = StreamProvider.autoDispose.family<Journey?, String>(
  (ref, id) => ref.watch(journeyRepositoryProvider).watch(id),
  retry: _noRetry,
);

final myMembershipProvider = StreamProvider.autoDispose
    .family<Membership?, String>(
      (ref, id) => ref.watch(journeyRepositoryProvider).watchMyMembership(id),
      retry: _noRetry,
    );

/// The caller's own check-ins in a journey. Local-only mode has no user id;
/// then the membership's user id is used (or every check-in, which in
/// local-only mode are all the caller's: groups need the server).
final myCheckInsProvider = StreamProvider.autoDispose
    .family<List<CheckIn>, String>((ref, id) {
      final userId =
          ref.watch(currentUserIdProvider) ??
          ref.watch(myMembershipProvider(id)).value?.userId;
      return ref
          .watch(checkInRepositoryProvider)
          .watchForJourney(id, userId: userId);
    }, retry: _noRetry);

/// Unwraps Riverpod's [ProviderException] (a dependency in error state).
Object rootError(Object error) {
  var e = error;
  while (e is ProviderException) {
    e = e.exception;
  }
  return e;
}

/// True when the data layer is not wired yet (placeholder repositories
/// throw [UnimplementedError] until B1 lands).
bool isNotWired(Object error) => rootError(error) is UnimplementedError;
