import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderException;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/journey_clock.dart';
import '../../../app/providers.dart';

import '../../../shared/time_zones.dart';

export '../../../app/journey_clock.dart';

/// Shared-preferences key the camera reads to preselect a journey (FR-C1).
/// "Check in now" on the journey screen writes it before opening `/capture`.
const String lastJourneyPrefsKey = 'camera.lastJourneyId';

/// Query parameter added to `/capture` by "Check in now" (same value as
/// [lastJourneyPrefsKey]).
const String captureJourneyParam = 'journeyId';

/// Repository streams must not retry on their own: the repositories already
/// handle offline/sync, and retry timers would leak into widget tests.
Duration? _noRetry(int _, Object _) => null;

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

/// Ids whose expired window the app has an end request in flight for.
final _settleRequestedProvider = Provider<Set<String>>((ref) => <String>{});

/// Days after the last day during which the server still takes late check-ins
/// (`0006_social.sql`: `local_date >= today - 3`, only while `active`).
const int lateCheckInGraceDays = 3;

/// [j] as it really is at [now]: a fixed-term journey past its end date is
/// shown `ended` at once (display state only, B-B7 / A-B14). The repository
/// closes it (server and other members) only once the late-upload window of
/// [lateCheckInGraceDays] is over and nothing of it is waiting in the outbox:
/// ending earlier would make the server reject the queued uploads.
Journey settleJourney(Ref ref, Journey j, DateTime now) {
  final today = journeyLocalDate(j.timezone, now);
  final settled = j.settledOn(today);
  if (identical(settled, j)) return j;
  if (!j.isPastEndOn(today.addDays(-lateCheckInGraceDays))) return settled;
  final userId = ref.read(currentUserIdProvider);
  if ((userId == null || userId == j.ownerId) &&
      ref.read(_settleRequestedProvider).add(j.id)) {
    // The repository refuses (offline error) while uploads are pending; the
    // id is released so the next quarter-hour tick retries.
    unawaited(
      ref
          .read(journeyRepositoryProvider)
          .end(j.id)
          .then(
            (_) {},
            onError: (_) => ref.read(_settleRequestedProvider).remove(j.id),
          ),
    );
  }
  return settled;
}

/// Journeys shown on the Journeys tab (active, ended and archived ones the
/// repository still lists). The database stream is subscribed once; the clock
/// only re-maps its last value.
final journeysListProvider = StreamProvider.autoDispose<List<Journey>>((ref) {
  return mapWithNow(
    ref,
    ref.watch(journeyRepositoryProvider).watchActive(),
    (all, now) => [for (final j in all) settleJourney(ref, j, now)],
  );
}, retry: _noRetry);

/// Journeys the caller archived on this device (Hub shelf "Archived").
final archivedJourneysProvider = StreamProvider.autoDispose<List<Journey>>(
  (ref) => ref.watch(journeyRepositoryProvider).watchArchived(),
  retry: _noRetry,
);

/// Ids of the journeys the caller pinned (per-user, also local-only). The
/// list provider already orders pinned journeys first.
final pinnedJourneyIdsProvider = StreamProvider.autoDispose<Set<String>>(
  (ref) => ref.watch(journeyRepositoryProvider).watchPinnedJourneyIds(),
  retry: _noRetry,
);

final journeyByIdProvider = StreamProvider.autoDispose.family<Journey?, String>(
  (ref, id) => mapWithNow(
    ref,
    ref.watch(journeyRepositoryProvider).watch(id),
    (j, now) => j == null ? null : settleJourney(ref, j, now),
  ),
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
