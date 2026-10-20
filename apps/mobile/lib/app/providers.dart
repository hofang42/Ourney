// App-wide Riverpod providers consumed by every feature.
//
// Feature agents: read these, do not redefine them. Repository providers are
// placeholders until the Data/Sync agent (B1) supplies implementations via
// lib/app/data_overrides.dart. In tests, override what you need:
//
//   ProviderScope(overrides: [
//     appConfigProvider.overrideWithValue(const AppConfig.localOnly()),
//     journeyRepositoryProvider.overrideWithValue(FakeJourneyRepository()),
//   ], child: ...)
//
// Regenerate providers.g.dart with:
//   dart run build_runner build
import 'package:ourney_core/ourney_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../personas/persona_contract.dart';
import 'config.dart';
import 'redirect.dart';
import 'theme/motion.dart';

part 'providers.g.dart';

/// Never retry on a timer (no hidden work behind the theme or the camera).
Duration? _noRetry(int _, Object _) => null;

// ---------------------------------------------------------------------------
// Configuration & platform singletons (overridden in main.dart).
// ---------------------------------------------------------------------------

/// Build-time config (`--dart-define`). Overridden in main.dart with the
/// value used to decide whether Supabase was initialised.
@Riverpod(keepAlive: true)
AppConfig appConfig(Ref ref) => AppConfig.fromEnvironment();

/// Key-value store for small settings. Created before `runApp` in main.dart.
///
/// Key convention: `<feature>.<name>` (e.g. `camera.lastJourneyId`).
@Riverpod(keepAlive: true)
SharedPreferencesWithCache sharedPreferences(Ref ref) =>
    throw UnimplementedError(
      'sharedPreferencesProvider must be overridden (main.dart / tests).',
    );

/// Supabase client, or null in local-only mode (FR-A5). Only the data layer
/// (lib/data) should touch it; features go through repositories.
@Riverpod(keepAlive: true)
SupabaseClient? supabaseClient(Ref ref) {
  final config = ref.watch(appConfigProvider);
  return config.localOnly ? null : Supabase.instance.client;
}

// ---------------------------------------------------------------------------
// Repository contracts (packages/ourney_core/lib/src/contracts/repositories.dart).
// Implemented by B1 in lib/data and wired through data_overrides.dart.
// ---------------------------------------------------------------------------

Never _notWired(String name) => throw UnimplementedError(
  '$name is not wired yet: B1 (lib/data) provides it via '
  'lib/app/data_overrides.dart. Override it in tests.',
);

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) => _notWired('authRepositoryProvider');

@Riverpod(keepAlive: true)
ProfileRepository profileRepository(Ref ref) =>
    _notWired('profileRepositoryProvider');

@Riverpod(keepAlive: true)
JourneyRepository journeyRepository(Ref ref) =>
    _notWired('journeyRepositoryProvider');

@Riverpod(keepAlive: true)
CheckInRepository checkInRepository(Ref ref) =>
    _notWired('checkInRepositoryProvider');

/// Group features need the server: in local-only mode show the
/// "needs server" state (`NeedsServerView`) instead of calling this.
@Riverpod(keepAlive: true)
GroupRepository groupRepository(Ref ref) =>
    _notWired('groupRepositoryProvider');

@Riverpod(keepAlive: true)
SafetyRepository safetyRepository(Ref ref) =>
    _notWired('safetyRepositoryProvider');

@Riverpod(keepAlive: true)
MediaStore mediaStore(Ref ref) => _notWired('mediaStoreProvider');

// ---------------------------------------------------------------------------
// Session state used by the router.
// ---------------------------------------------------------------------------

/// Signed-in user id (null when signed out or local-only). Seeded
/// synchronously from [AuthRepository.currentUserId] so the router never sees
/// a loading state, then follows [AuthRepository.watchUserId].
@Riverpod(keepAlive: true)
class CurrentUserId extends _$CurrentUserId {
  @override
  String? build() {
    if (ref.watch(appConfigProvider).localOnly) return null;
    final AuthRepository repo;
    try {
      repo = ref.watch(authRepositoryProvider);
    } on Object {
      // Repository not wired yet (before B1): behave as signed out.
      return null;
    }
    final sub = repo.watchUserId().listen((id) => state = id);
    ref.onDispose(sub.cancel);
    return repo.currentUserId;
  }
}

/// Auth state as seen by the router redirect.
@Riverpod(keepAlive: true)
AuthStatus authStatus(Ref ref) {
  if (ref.watch(appConfigProvider).localOnly) return AuthStatus.localOnly;
  return ref.watch(currentUserIdProvider) == null
      ? AuthStatus.signedOut
      : AuthStatus.signedIn;
}

// ---------------------------------------------------------------------------
// App settings persisted in shared preferences.
// ---------------------------------------------------------------------------

/// Whether onboarding (FR-A3) has been completed on this device. The
/// onboarding feature calls `complete()`; the router then leaves
/// `/onboarding` on its own (back to the `?from=` target or `/capture`).
@Riverpod(keepAlive: true)
class OnboardingComplete extends _$OnboardingComplete {
  static const prefsKey = 'app.onboardingComplete';

  @override
  bool build() =>
      ref.watch(sharedPreferencesProvider).getBool(prefsKey) ?? false;

  Future<void> complete() async {
    state = true;
    await ref.read(sharedPreferencesProvider).setBool(prefsKey, true);
  }

  /// Debug/QA helper and account deletion: show onboarding again.
  Future<void> reset() async {
    state = false;
    await ref.read(sharedPreferencesProvider).remove(prefsKey);
  }
}

/// User toggle for haptics ("haptic tắt được", design system checklist).
/// Mirrors the value into [OurneyHaptics.enabled] so widgets need no ref.
@Riverpod(keepAlive: true)
class HapticsEnabled extends _$HapticsEnabled {
  static const prefsKey = 'app.hapticsEnabled';

  @override
  bool build() {
    final value =
        ref.watch(sharedPreferencesProvider).getBool(prefsKey) ?? true;
    OurneyHaptics.enabled = value;
    return value;
  }

  Future<void> set({required bool enabled}) async {
    state = enabled;
    OurneyHaptics.enabled = enabled;
    await ref.read(sharedPreferencesProvider).setBool(prefsKey, enabled);
  }
}

// ---------------------------------------------------------------------------
// Active journey and persona skin (F2, docs/06 §1 Q1).
// ---------------------------------------------------------------------------

/// The journey the user is working in. Its persona skin themes the whole
/// app; switching it never rebuilds the router or restarts the camera.
///
/// Stored in `camera.lastJourneyId`, the same key the capture screen has
/// always used for the journey chip, so both stay in step.
@Riverpod(keepAlive: true)
class ActiveJourneyId extends _$ActiveJourneyId {
  static const prefsKey = 'camera.lastJourneyId';

  @override
  String? build() => ref.watch(sharedPreferencesProvider).getString(prefsKey);

  /// Makes [id] the active journey and remembers it across launches.
  Future<void> select(String id) async {
    if (state == id) return;
    state = id;
    await ref.read(sharedPreferencesProvider).setString(prefsKey, id);
  }
}

/// The active journey: the remembered one while it is still active, else the
/// first active journey (what the capture screen preselects), else null.
@Riverpod(keepAlive: true, retry: _noRetry)
Stream<Journey?> activeJourney(Ref ref) {
  final id = ref.watch(activeJourneyIdProvider);
  return ref.watch(journeyRepositoryProvider).watchActive().map((all) {
    final active = [
      for (final j in all)
        if (j.status == JourneyStatus.active) j,
    ];
    for (final j in active) {
      if (j.id == id) return j;
    }
    return active.firstOrNull;
  });
}

/// Persona skin of the active journey, or null for the neutral Ourney base
/// (no journey yet, or the repository is not available).
@Riverpod(keepAlive: true)
PersonaSkinId? activePersonaSkin(Ref ref) {
  final journey = ref.watch(activeJourneyProvider).value;
  return journey == null ? null : personaSkinOf(journey);
}
