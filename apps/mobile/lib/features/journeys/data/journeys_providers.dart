import 'dart:async';

import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderException;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/journey_clock.dart';
import '../../../app/providers.dart';
import '../../../data/sync/outbox.dart' show isTransient;

import '../../../shared/time_zones.dart';
import '../domain/journey_progress.dart';
import '../domain/timeline_window.dart';

export '../../../app/journey_clock.dart';

/// Shared-preferences key the camera reads to preselect a journey (FR-C1).
/// "Check in now" on the journey screen writes it before opening `/capture`.
const String lastJourneyPrefsKey = 'camera.lastJourneyId';

/// Query parameter added to `/capture` by "Check in now" (same value as
/// [lastJourneyPrefsKey]).
const String captureJourneyParam = 'journeyId';

/// Per-journey starting weight (kg) chosen during the weight-loss onboarding
/// wizard. Kept in local preferences so it stays private to this device
/// (`0012_journey_edit.sql`: `journeys.dna` is readable by every member).
const String journeyStartingWeightPrefPrefix = 'journeys.startingWeight.';

String journeyStartingWeightPrefKey(String journeyId) =>
    '$journeyStartingWeightPrefPrefix$journeyId';

/// Per-journey preference for the camera's day-1 ghost alignment guide.
const String journeyGhostGuidePrefPrefix = 'camera.ghostGuide.';

String journeyGhostGuidePrefKey(String journeyId) =>
    '$journeyGhostGuidePrefPrefix$journeyId';

/// True when [key] is a per-journey local preference (starting weight or
/// ghost alignment guide) that must be wiped on sign-out / account reset.
bool isPerJourneyAccountPrefKey(String key) =>
    key.startsWith(journeyStartingWeightPrefPrefix) ||
    key.startsWith(journeyGhostGuidePrefPrefix);

/// Repository streams must not retry on their own: the repositories already
/// handle offline/sync, and retry timers would leak into widget tests.
Duration? _noRetry(int _, Object _) => null;

/// IANA name of the device time zone: the default for new journeys.
/// Override in tests (it uses a platform channel).
final deviceTimezoneProvider = FutureProvider<String>((ref) async {
  final id = await ref.watch(_deviceZoneIdProvider.future);
  // Stored on the journey: always canonical (Asia/Saigon ->
  // Asia/Ho_Chi_Minh); an unknown name uses the logged best guess.
  if (id != null) return resolveTimeZone(id).name;
  return guessTimeZoneForOffset(DateTime.now().timeZoneOffset).name;
}, retry: _noRetry);

/// Raw platform zone id, registered for the tz fast path without touching the
/// tz database (null when unsupported).
final _deviceZoneIdProvider = FutureProvider<String?>((ref) async {
  try {
    final info = await FlutterTimezone.getLocalTimezone();
    if (info.identifier.isNotEmpty) {
      registerDeviceTimeZone(info.identifier);
      return info.identifier;
    }
  } on Object {
    // Unsupported platform or channel missing.
  }
  return null;
}, retry: _noRetry);

/// Registers the device zone and decodes the tz database once the first frame
/// is out, so no later lookup pays for it (watched by the app root; the
/// camera's first frame uses the fast path of `journeyLocalDate`).
final timeZoneWarmupProvider = Provider<void>((ref) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(() async {
      // Registers the device zone; a hung or failed platform call must not
      // hold the decode back, so it is not awaited.
      unawaited(
        ref
            .read(_deviceZoneIdProvider.future)
            .then((_) {}, onError: (Object _) {}),
      );
      // Let a couple of frames pass before the synchronous decode.
      final binding = WidgetsBinding.instance;
      await binding.endOfFrame;
      await binding.endOfFrame;
      ensureTimeZonesLoaded();
    }());
  });
}, retry: _noRetry);

/// Auto-end bookkeeping: ids with a request in flight (or done) and, after a
/// refusal, the next quarter-hour tick at which the id may be tried again.
class _SettleState {
  final requested = <String>{};
  final retryAt = <String, DateTime>{};
}

final _settleRequestedProvider = Provider<_SettleState>(
  (ref) => _SettleState(),
);

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
  if (userId != null && userId != j.ownerId) return settled;
  // The state object is captured now: `ref` may be disposed by the time the
  // request settles (autoDispose list providers).
  final state = ref.read(_settleRequestedProvider);
  final retryAt = state.retryAt[j.id];
  if (retryAt != null && now.isBefore(retryAt)) return settled;
  if (state.requested.add(j.id)) {
    // The repository refuses (`syncPending` / offline) while uploads are
    // pending; the id is released and retried at the next quarter-hour tick,
    // never forcing an outbox flush from here (that would burn the retry
    // budget of failing uploads).
    unawaited(
      ref
          .read(journeyRepositoryProvider)
          .end(j.id, background: true)
          .then(
            (_) {},
            onError: (Object e) {
              // Only transient refusals retry; ended/forbidden/notFound stay
              // requested (the repository will not accept them later).
              final code = rootError(e) is OurneyException
                  ? (rootError(e) as OurneyException).error
                  : OurneyErrorCode.offline;
              if (code == OurneyErrorCode.syncPending || isTransient(code)) {
                state.requested.remove(j.id);
                state.retryAt[j.id] = now.add(untilNextQuarterHour(now));
              }
            },
          ),
    );
  }
  return settled;
}

/// Journeys shown on the Journeys tab (active, ended and archived ones the
/// repository still lists). The database stream is subscribed once; the clock
/// only re-maps its last value.
final journeysListProvider = StreamProvider.autoDispose<List<Journey>>((ref) {
  ref.watch(currentUserIdProvider);
  return mapWithNow(
    ref,
    ref.watch(journeyRepositoryProvider).watchActive(),
    (all, now) => [for (final j in all) settleJourney(ref, j, now)],
  );
}, retry: _noRetry);

/// Journeys the caller archived on this device (Hub shelf "Archived").
final archivedJourneysProvider = StreamProvider.autoDispose<List<Journey>>((
  ref,
) {
  ref.watch(currentUserIdProvider);
  return ref.watch(journeyRepositoryProvider).watchArchived();
}, retry: _noRetry);

/// Ids of the journeys the caller pinned (per-user, also local-only). The
/// list provider already orders pinned journeys first.
final pinnedJourneyIdsProvider = StreamProvider.autoDispose<Set<String>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(journeyRepositoryProvider).watchPinnedJourneyIds();
}, retry: _noRetry);

final journeyByIdProvider = StreamProvider.autoDispose.family<Journey?, String>(
  (ref, id) => mapWithNow(
    ref,
    ref.watch(journeyRepositoryProvider).watch(id),
    (j, now) => j == null ? null : settleJourney(ref, j, now),
  ),
  retry: _noRetry,
);

final myMembershipProvider = StreamProvider.autoDispose
    .family<Membership?, String>((ref, id) {
      ref.watch(currentUserIdProvider);
      return ref.watch(journeyRepositoryProvider).watchMyMembership(id);
    }, retry: _noRetry);

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

/// The caller's progress in a journey plus the month index of its timeline,
/// computed once per change of the journey, the membership, the check-ins or
/// of today (the 15-minute day ticker) instead of on every build of the
/// detail screen. Null until the check-ins have loaded.
final journeyTimelineIndexProvider = Provider.autoDispose
    .family<TimelineIndex?, String>((ref, id) {
      final journey = ref.watch(journeyByIdProvider(id)).value;
      final checkIns = ref.watch(myCheckInsProvider(id));
      if (journey == null || !checkIns.hasValue) return null;
      return TimelineIndex.build(
        JourneyProgress.compute(
          journey: journey,
          membership: ref.watch(myMembershipProvider(id)).value,
          checkIns: checkIns.value!,
          now: ref.watch(journeysNowProvider),
        ),
      );
    });

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
