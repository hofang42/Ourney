// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Build-time config (`--dart-define`). Overridden in main.dart with the
/// value used to decide whether Supabase was initialised.

@ProviderFor(appConfig)
final appConfigProvider = AppConfigProvider._();

/// Build-time config (`--dart-define`). Overridden in main.dart with the
/// value used to decide whether Supabase was initialised.

final class AppConfigProvider
    extends $FunctionalProvider<AppConfig, AppConfig, AppConfig>
    with $Provider<AppConfig> {
  /// Build-time config (`--dart-define`). Overridden in main.dart with the
  /// value used to decide whether Supabase was initialised.
  AppConfigProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appConfigProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appConfigHash();

  @$internal
  @override
  $ProviderElement<AppConfig> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppConfig create(Ref ref) {
    return appConfig(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppConfig value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppConfig>(value),
    );
  }
}

String _$appConfigHash() => r'87f9d20a2d92252672162b2ce97547b7b2479239';

/// Key-value store for small settings. Created before `runApp` in main.dart.
///
/// Key convention: `<feature>.<name>` (e.g. `camera.lastJourneyId`).

@ProviderFor(sharedPreferences)
final sharedPreferencesProvider = SharedPreferencesProvider._();

/// Key-value store for small settings. Created before `runApp` in main.dart.
///
/// Key convention: `<feature>.<name>` (e.g. `camera.lastJourneyId`).

final class SharedPreferencesProvider
    extends
        $FunctionalProvider<
          SharedPreferencesWithCache,
          SharedPreferencesWithCache,
          SharedPreferencesWithCache
        >
    with $Provider<SharedPreferencesWithCache> {
  /// Key-value store for small settings. Created before `runApp` in main.dart.
  ///
  /// Key convention: `<feature>.<name>` (e.g. `camera.lastJourneyId`).
  SharedPreferencesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sharedPreferencesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sharedPreferencesHash();

  @$internal
  @override
  $ProviderElement<SharedPreferencesWithCache> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SharedPreferencesWithCache create(Ref ref) {
    return sharedPreferences(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SharedPreferencesWithCache value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SharedPreferencesWithCache>(value),
    );
  }
}

String _$sharedPreferencesHash() => r'be8ca6d9fee8e616effef94b25963c66f91c757f';

/// Supabase client, or null in local-only mode (FR-A5). Only the data layer
/// (lib/data) should touch it; features go through repositories.

@ProviderFor(supabaseClient)
final supabaseClientProvider = SupabaseClientProvider._();

/// Supabase client, or null in local-only mode (FR-A5). Only the data layer
/// (lib/data) should touch it; features go through repositories.

final class SupabaseClientProvider
    extends
        $FunctionalProvider<SupabaseClient?, SupabaseClient?, SupabaseClient?>
    with $Provider<SupabaseClient?> {
  /// Supabase client, or null in local-only mode (FR-A5). Only the data layer
  /// (lib/data) should touch it; features go through repositories.
  SupabaseClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'supabaseClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$supabaseClientHash();

  @$internal
  @override
  $ProviderElement<SupabaseClient?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SupabaseClient? create(Ref ref) {
    return supabaseClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SupabaseClient? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SupabaseClient?>(value),
    );
  }
}

String _$supabaseClientHash() => r'f072194e355c248c9aa5d9fbecbc3eebb02e3666';

@ProviderFor(authRepository)
final authRepositoryProvider = AuthRepositoryProvider._();

final class AuthRepositoryProvider
    extends $FunctionalProvider<AuthRepository, AuthRepository, AuthRepository>
    with $Provider<AuthRepository> {
  AuthRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authRepositoryHash();

  @$internal
  @override
  $ProviderElement<AuthRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthRepository create(Ref ref) {
    return authRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthRepository>(value),
    );
  }
}

String _$authRepositoryHash() => r'f56cdafb52dca5a995c058c2c6e9908193b97637';

@ProviderFor(profileRepository)
final profileRepositoryProvider = ProfileRepositoryProvider._();

final class ProfileRepositoryProvider
    extends
        $FunctionalProvider<
          ProfileRepository,
          ProfileRepository,
          ProfileRepository
        >
    with $Provider<ProfileRepository> {
  ProfileRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileRepositoryHash();

  @$internal
  @override
  $ProviderElement<ProfileRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProfileRepository create(Ref ref) {
    return profileRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfileRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfileRepository>(value),
    );
  }
}

String _$profileRepositoryHash() => r'fa62fbebbe8452998828f50b17813fb757f447b4';

@ProviderFor(journeyRepository)
final journeyRepositoryProvider = JourneyRepositoryProvider._();

final class JourneyRepositoryProvider
    extends
        $FunctionalProvider<
          JourneyRepository,
          JourneyRepository,
          JourneyRepository
        >
    with $Provider<JourneyRepository> {
  JourneyRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'journeyRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$journeyRepositoryHash();

  @$internal
  @override
  $ProviderElement<JourneyRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  JourneyRepository create(Ref ref) {
    return journeyRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(JourneyRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<JourneyRepository>(value),
    );
  }
}

String _$journeyRepositoryHash() => r'9f373db432952604ef37bbd7cd4fdafae53a0b17';

@ProviderFor(checkInRepository)
final checkInRepositoryProvider = CheckInRepositoryProvider._();

final class CheckInRepositoryProvider
    extends
        $FunctionalProvider<
          CheckInRepository,
          CheckInRepository,
          CheckInRepository
        >
    with $Provider<CheckInRepository> {
  CheckInRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'checkInRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$checkInRepositoryHash();

  @$internal
  @override
  $ProviderElement<CheckInRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CheckInRepository create(Ref ref) {
    return checkInRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CheckInRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CheckInRepository>(value),
    );
  }
}

String _$checkInRepositoryHash() => r'8c09f24b07905f42459dfdb0b8ed176e96267f67';

/// Group features need the server: in local-only mode show the
/// "needs server" state (`NeedsServerView`) instead of calling this.

@ProviderFor(groupRepository)
final groupRepositoryProvider = GroupRepositoryProvider._();

/// Group features need the server: in local-only mode show the
/// "needs server" state (`NeedsServerView`) instead of calling this.

final class GroupRepositoryProvider
    extends
        $FunctionalProvider<GroupRepository, GroupRepository, GroupRepository>
    with $Provider<GroupRepository> {
  /// Group features need the server: in local-only mode show the
  /// "needs server" state (`NeedsServerView`) instead of calling this.
  GroupRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'groupRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$groupRepositoryHash();

  @$internal
  @override
  $ProviderElement<GroupRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GroupRepository create(Ref ref) {
    return groupRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GroupRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GroupRepository>(value),
    );
  }
}

String _$groupRepositoryHash() => r'576f9430613ca165e2253db18aef2dc92e5c5356';

@ProviderFor(safetyRepository)
final safetyRepositoryProvider = SafetyRepositoryProvider._();

final class SafetyRepositoryProvider
    extends
        $FunctionalProvider<
          SafetyRepository,
          SafetyRepository,
          SafetyRepository
        >
    with $Provider<SafetyRepository> {
  SafetyRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'safetyRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$safetyRepositoryHash();

  @$internal
  @override
  $ProviderElement<SafetyRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SafetyRepository create(Ref ref) {
    return safetyRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SafetyRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SafetyRepository>(value),
    );
  }
}

String _$safetyRepositoryHash() => r'4b237ed6ef4776a0ec3d6313a310cc574b89d698';

@ProviderFor(mediaStore)
final mediaStoreProvider = MediaStoreProvider._();

final class MediaStoreProvider
    extends $FunctionalProvider<MediaStore, MediaStore, MediaStore>
    with $Provider<MediaStore> {
  MediaStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mediaStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mediaStoreHash();

  @$internal
  @override
  $ProviderElement<MediaStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MediaStore create(Ref ref) {
    return mediaStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MediaStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MediaStore>(value),
    );
  }
}

String _$mediaStoreHash() => r'231225f476f8448581ee65777d914af8b86fd912';

/// Signed-in user id (null when signed out or local-only). Seeded
/// synchronously from [AuthRepository.currentUserId] so the router never sees
/// a loading state, then follows [AuthRepository.watchUserId].

@ProviderFor(CurrentUserId)
final currentUserIdProvider = CurrentUserIdProvider._();

/// Signed-in user id (null when signed out or local-only). Seeded
/// synchronously from [AuthRepository.currentUserId] so the router never sees
/// a loading state, then follows [AuthRepository.watchUserId].
final class CurrentUserIdProvider
    extends $NotifierProvider<CurrentUserId, String?> {
  /// Signed-in user id (null when signed out or local-only). Seeded
  /// synchronously from [AuthRepository.currentUserId] so the router never sees
  /// a loading state, then follows [AuthRepository.watchUserId].
  CurrentUserIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentUserIdProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentUserIdHash();

  @$internal
  @override
  CurrentUserId create() => CurrentUserId();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$currentUserIdHash() => r'9a89b56a01df044e6a15d819aa810c57fb9e31fa';

/// Signed-in user id (null when signed out or local-only). Seeded
/// synchronously from [AuthRepository.currentUserId] so the router never sees
/// a loading state, then follows [AuthRepository.watchUserId].

abstract class _$CurrentUserId extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Auth state as seen by the router redirect.

@ProviderFor(authStatus)
final authStatusProvider = AuthStatusProvider._();

/// Auth state as seen by the router redirect.

final class AuthStatusProvider
    extends $FunctionalProvider<AuthStatus, AuthStatus, AuthStatus>
    with $Provider<AuthStatus> {
  /// Auth state as seen by the router redirect.
  AuthStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authStatusProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authStatusHash();

  @$internal
  @override
  $ProviderElement<AuthStatus> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthStatus create(Ref ref) {
    return authStatus(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthStatus value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthStatus>(value),
    );
  }
}

String _$authStatusHash() => r'3ec719874db612d7fcb4d60512efc571fe505568';

/// Whether onboarding (FR-A3) has been completed on this device. The
/// onboarding feature calls `complete()`; the router then leaves
/// `/onboarding` on its own (back to the `?from=` target or `/capture`).

@ProviderFor(OnboardingComplete)
final onboardingCompleteProvider = OnboardingCompleteProvider._();

/// Whether onboarding (FR-A3) has been completed on this device. The
/// onboarding feature calls `complete()`; the router then leaves
/// `/onboarding` on its own (back to the `?from=` target or `/capture`).
final class OnboardingCompleteProvider
    extends $NotifierProvider<OnboardingComplete, bool> {
  /// Whether onboarding (FR-A3) has been completed on this device. The
  /// onboarding feature calls `complete()`; the router then leaves
  /// `/onboarding` on its own (back to the `?from=` target or `/capture`).
  OnboardingCompleteProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingCompleteProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingCompleteHash();

  @$internal
  @override
  OnboardingComplete create() => OnboardingComplete();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$onboardingCompleteHash() =>
    r'3955b0f223048fbe41ed5f74cfb8d60befc26758';

/// Whether onboarding (FR-A3) has been completed on this device. The
/// onboarding feature calls `complete()`; the router then leaves
/// `/onboarding` on its own (back to the `?from=` target or `/capture`).

abstract class _$OnboardingComplete extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// User toggle for haptics ("haptic tắt được", design system checklist).
/// Mirrors the value into [OurneyHaptics.enabled] so widgets need no ref.

@ProviderFor(HapticsEnabled)
final hapticsEnabledProvider = HapticsEnabledProvider._();

/// User toggle for haptics ("haptic tắt được", design system checklist).
/// Mirrors the value into [OurneyHaptics.enabled] so widgets need no ref.
final class HapticsEnabledProvider
    extends $NotifierProvider<HapticsEnabled, bool> {
  /// User toggle for haptics ("haptic tắt được", design system checklist).
  /// Mirrors the value into [OurneyHaptics.enabled] so widgets need no ref.
  HapticsEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hapticsEnabledProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hapticsEnabledHash();

  @$internal
  @override
  HapticsEnabled create() => HapticsEnabled();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$hapticsEnabledHash() => r'a442f41f6fbae10cdb27888ff55e6f683c4c8700';

/// User toggle for haptics ("haptic tắt được", design system checklist).
/// Mirrors the value into [OurneyHaptics.enabled] so widgets need no ref.

abstract class _$HapticsEnabled extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The journey the user is working in. Its persona skin themes the whole
/// app; switching it never rebuilds the router or restarts the camera.
///
/// Stored in `camera.lastJourneyId`, the same key the capture screen has
/// always used for the journey chip, so both stay in step.

@ProviderFor(ActiveJourneyId)
final activeJourneyIdProvider = ActiveJourneyIdProvider._();

/// The journey the user is working in. Its persona skin themes the whole
/// app; switching it never rebuilds the router or restarts the camera.
///
/// Stored in `camera.lastJourneyId`, the same key the capture screen has
/// always used for the journey chip, so both stay in step.
final class ActiveJourneyIdProvider
    extends $NotifierProvider<ActiveJourneyId, String?> {
  /// The journey the user is working in. Its persona skin themes the whole
  /// app; switching it never rebuilds the router or restarts the camera.
  ///
  /// Stored in `camera.lastJourneyId`, the same key the capture screen has
  /// always used for the journey chip, so both stay in step.
  ActiveJourneyIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeJourneyIdProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeJourneyIdHash();

  @$internal
  @override
  ActiveJourneyId create() => ActiveJourneyId();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$activeJourneyIdHash() => r'a4deb79e1deb25029ad757983f4e6bceeaa641e6';

/// The journey the user is working in. Its persona skin themes the whole
/// app; switching it never rebuilds the router or restarts the camera.
///
/// Stored in `camera.lastJourneyId`, the same key the capture screen has
/// always used for the journey chip, so both stay in step.

abstract class _$ActiveJourneyId extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The active journey: the remembered one while it is still active, else the
/// first active journey (what the capture screen preselects), else null.

@ProviderFor(activeJourney)
final activeJourneyProvider = ActiveJourneyProvider._();

/// The active journey: the remembered one while it is still active, else the
/// first active journey (what the capture screen preselects), else null.

final class ActiveJourneyProvider
    extends
        $FunctionalProvider<AsyncValue<Journey?>, Journey?, Stream<Journey?>>
    with $FutureModifier<Journey?>, $StreamProvider<Journey?> {
  /// The active journey: the remembered one while it is still active, else the
  /// first active journey (what the capture screen preselects), else null.
  ActiveJourneyProvider._()
    : super(
        from: null,
        argument: null,
        retry: _noRetry,
        name: r'activeJourneyProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeJourneyHash();

  @$internal
  @override
  $StreamProviderElement<Journey?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Journey?> create(Ref ref) {
    return activeJourney(ref);
  }
}

String _$activeJourneyHash() => r'1bc758aa43b9e9b68e86f0407a96bfa6cfcdaabe';

/// Persona skin of the active journey, or null for the neutral Ourney base
/// (no journey yet, or the repository is not available).

@ProviderFor(activePersonaSkin)
final activePersonaSkinProvider = ActivePersonaSkinProvider._();

/// Persona skin of the active journey, or null for the neutral Ourney base
/// (no journey yet, or the repository is not available).

final class ActivePersonaSkinProvider
    extends $FunctionalProvider<PersonaSkinId?, PersonaSkinId?, PersonaSkinId?>
    with $Provider<PersonaSkinId?> {
  /// Persona skin of the active journey, or null for the neutral Ourney base
  /// (no journey yet, or the repository is not available).
  ActivePersonaSkinProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activePersonaSkinProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activePersonaSkinHash();

  @$internal
  @override
  $ProviderElement<PersonaSkinId?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PersonaSkinId? create(Ref ref) {
    return activePersonaSkin(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PersonaSkinId? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PersonaSkinId?>(value),
    );
  }
}

String _$activePersonaSkinHash() => r'1e8e11222b4bf4131cc68bc2b61630e3d5d91fb4';
