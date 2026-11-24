import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart'
    show
        AsyncValue,
        FutureProvider,
        Notifier,
        NotifierProvider,
        Provider;
import 'package:ourney_core/ourney_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../app/providers.dart';
import '../../app/redirect.dart' show ProfileGateStatus;
import '../../shared/time_zones.dart';
import 'avatar_picker.dart';

part 'profile_providers.g.dart';

Duration? _noRetry(int retryCount, Object error) => null;

/// Bounded wait for `myProfileProvider` before falling back to
/// [ProfileGateStatus.needsSetup] so a hung profile stream never traps `/auth`
/// (DE-04 / H1).
final profileGateTimeoutProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 10),
);

/// Session-scoped profile gate consumed by `routerProvider` (`resolveRedirect`).
///
/// - [ProfileGateStatus.ready]: local-only mode, signed out, unwired
///   `ProfileRepository` in tests, or the signed-in account has a profile row.
/// - [ProfileGateStatus.unknown]: signed in and awaiting the initial
///   `myProfileProvider` emission (with a bounded timeout).
/// - [ProfileGateStatus.needsSetup]: `myProfileProvider` yielded `null`,
///   errored, or timed out with no profile row.
class ProfileGateNotifier extends Notifier<ProfileGateStatus> {
  Timer? _timeout;

  @override
  ProfileGateStatus build() {
    _timeout?.cancel();
    _timeout = null;
    ref.onDispose(() {
      _timeout?.cancel();
      _timeout = null;
    });
    if (ref.watch(appConfigProvider).localOnly) {
      return ProfileGateStatus.ready;
    }
    if (ref.watch(currentUserIdProvider) == null) {
      return ProfileGateStatus.ready;
    }
    try {
      ref.watch(profileRepositoryProvider);
    } on Object {
      // ProfileRepository not wired in this test: skip profile setup gate.
      return ProfileGateStatus.ready;
    }
    final profileAsync = ref.watch(myProfileProvider);
    if (profileAsync.hasValue) {
      return profileAsync.value != null
          ? ProfileGateStatus.ready
          : ProfileGateStatus.needsSetup;
    }
    if (profileAsync.hasError) {
      return ProfileGateStatus.needsSetup;
    }
    final duration = ref.watch(profileGateTimeoutProvider);
    _timeout = Timer(duration, () {
      state = ProfileGateStatus.needsSetup;
    });
    return ProfileGateStatus.unknown;
  }
}

final profileGateStatusProvider =
    NotifierProvider<ProfileGateNotifier, ProfileGateStatus>(
      ProfileGateNotifier.new,
    );

/// The signed-in user's profile (null when none exists yet, signed out or
/// local-only). Errors surface to the UI, which offers a retry button.
@Riverpod(retry: _noRetry)
Stream<Profile?> myProfile(Ref ref) {
  if (ref.watch(appConfigProvider).localOnly) return Stream.value(null);
  // Re-subscribe when the account changes (sign-out / another sign-in).
  if (ref.watch(currentUserIdProvider) == null) return Stream.value(null);
  return ref.watch(profileRepositoryProvider).watchMe();
}

/// Local file for an avatar storage path (MediaStore disk cache).
@Riverpod(retry: _noRetry)
Future<String> avatarFile(Ref ref, String storagePath) =>
    ref.watch(mediaStoreProvider).localFileFor(storagePath);

/// Picks and compresses an avatar to JPEG. Overridden in tests.
@Riverpod(keepAlive: true)
AvatarPicker avatarPicker(Ref ref) => const ImagePickerAvatarPicker();

/// Server-backed account extras (stats RPC, onboarding quiz column). Null in
/// local-only mode; wired by `dataOverrides` when a backend is configured.
final accountInsightsRepositoryProvider = Provider<AccountInsightsRepository?>(
  (ref) => null,
);

/// Streak / snaps / journeys for the profile screen. Signed in: server RPC
/// `profile_stats` (falls back to local data when it fails, e.g. offline).
/// Signed out or local-only: computed from the journeys and check-ins on this
/// device.
final profileStatsProvider = FutureProvider.autoDispose<ProfileStats>((
  ref,
) async {
  final repo = ref.watch(accountInsightsRepositoryProvider);
  if (repo != null && ref.watch(currentUserIdProvider) != null) {
    try {
      return await repo.fetchStats();
    } on Object {
      // Offline: show what this device knows.
    }
  }
  final journeyRepo = ref.watch(journeyRepositoryProvider);
  final checkIns = ref.watch(checkInRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  // Same set as the server's `profile_stats` (every active membership,
  // archived and ended journeys included).
  // Remaining gap: the server's `total_snaps` counts all my check-ins in
  // any journey, even one I left; here only journeys I am still in count.
  final journeys = await journeyRepo.allMine();
  final byJourney = <String, List<CheckIn>>{};
  final joined = <String, LocalDate>{};
  for (final j in journeys) {
    final m = await journeyRepo.watchMyMembership(j.id).first;
    // Own check-ins only: group journeys also hold other members' photos.
    byJourney[j.id] = await checkIns
        .watchForJourney(j.id, userId: userId ?? m?.userId)
        .first;
    if (m != null) {
      joined[j.id] = localDateOf(
        m.joinedAt,
        timeZoneOffsetAt(j.timezone, m.joinedAt),
      );
    }
  }
  final now = DateTime.now().toUtc();
  return computeLocalProfileStats(
    journeys: journeys,
    checkInsByJourney: byJourney,
    joinedLocalDateByJourney: joined,
    today: (tz) => localDateOf(now, timeZoneOffsetAt(tz, now)),
  );
});
