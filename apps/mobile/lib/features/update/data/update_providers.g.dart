// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Seeded before runApp so a cached gate can be evaluated synchronously.

@ProviderFor(packageInfo)
final packageInfoProvider = PackageInfoProvider._();

/// Seeded before runApp so a cached gate can be evaluated synchronously.

final class PackageInfoProvider
    extends $FunctionalProvider<PackageInfo?, PackageInfo?, PackageInfo?>
    with $Provider<PackageInfo?> {
  /// Seeded before runApp so a cached gate can be evaluated synchronously.
  PackageInfoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'packageInfoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$packageInfoHash();

  @$internal
  @override
  $ProviderElement<PackageInfo?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PackageInfo? create(Ref ref) {
    return packageInfo(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PackageInfo? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PackageInfo?>(value),
    );
  }
}

String _$packageInfoHash() => r'2a7c0f3591674adadbedbc24a619d23815acdb74';

@ProviderFor(updatePlatform)
final updatePlatformProvider = UpdatePlatformProvider._();

final class UpdatePlatformProvider
    extends
        $FunctionalProvider<UpdatePlatform?, UpdatePlatform?, UpdatePlatform?>
    with $Provider<UpdatePlatform?> {
  UpdatePlatformProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updatePlatformProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updatePlatformHash();

  @$internal
  @override
  $ProviderElement<UpdatePlatform?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  UpdatePlatform? create(Ref ref) {
    return updatePlatform(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UpdatePlatform? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UpdatePlatform?>(value),
    );
  }
}

String _$updatePlatformHash() => r'fca118ffd7d7e46b88f2f41da0c42d949c9b398c';

@ProviderFor(appUpdateEnabled)
final appUpdateEnabledProvider = AppUpdateEnabledProvider._();

final class AppUpdateEnabledProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  AppUpdateEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appUpdateEnabledProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appUpdateEnabledHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return appUpdateEnabled(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$appUpdateEnabledHash() => r'3d612e6925445116bace95a0c9c9ee63596ba83d';

@ProviderFor(updateManifestSource)
final updateManifestSourceProvider = UpdateManifestSourceProvider._();

final class UpdateManifestSourceProvider
    extends
        $FunctionalProvider<
          UpdateManifestSource?,
          UpdateManifestSource?,
          UpdateManifestSource?
        >
    with $Provider<UpdateManifestSource?> {
  UpdateManifestSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updateManifestSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updateManifestSourceHash();

  @$internal
  @override
  $ProviderElement<UpdateManifestSource?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  UpdateManifestSource? create(Ref ref) {
    return updateManifestSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UpdateManifestSource? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UpdateManifestSource?>(value),
    );
  }
}

String _$updateManifestSourceHash() =>
    r'3333ce28d7137532abec268fa03049689c23364f';

@ProviderFor(appUpdateClock)
final appUpdateClockProvider = AppUpdateClockProvider._();

final class AppUpdateClockProvider
    extends $FunctionalProvider<Clock, Clock, Clock>
    with $Provider<Clock> {
  AppUpdateClockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appUpdateClockProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appUpdateClockHash();

  @$internal
  @override
  $ProviderElement<Clock> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Clock create(Ref ref) {
    return appUpdateClock(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Clock value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Clock>(value),
    );
  }
}

String _$appUpdateClockHash() => r'f8f442d98f3ac0a3c7dbb3916108d76cec42d7ca';

@ProviderFor(appUpdateConnectivityChanges)
final appUpdateConnectivityChangesProvider =
    AppUpdateConnectivityChangesProvider._();

final class AppUpdateConnectivityChangesProvider
    extends
        $FunctionalProvider<
          Stream<bool> Function(),
          Stream<bool> Function(),
          Stream<bool> Function()
        >
    with $Provider<Stream<bool> Function()> {
  AppUpdateConnectivityChangesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appUpdateConnectivityChangesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appUpdateConnectivityChangesHash();

  @$internal
  @override
  $ProviderElement<Stream<bool> Function()> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Stream<bool> Function() create(Ref ref) {
    return appUpdateConnectivityChanges(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Stream<bool> Function() value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Stream<bool> Function()>(value),
    );
  }
}

String _$appUpdateConnectivityChangesHash() =>
    r'da0e9600a9d94d27230e50fe2acef2d4c3791726';

@ProviderFor(appUpdateLauncher)
final appUpdateLauncherProvider = AppUpdateLauncherProvider._();

final class AppUpdateLauncherProvider
    extends
        $FunctionalProvider<
          Future<bool> Function(Uri),
          Future<bool> Function(Uri),
          Future<bool> Function(Uri)
        >
    with $Provider<Future<bool> Function(Uri)> {
  AppUpdateLauncherProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appUpdateLauncherProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appUpdateLauncherHash();

  @$internal
  @override
  $ProviderElement<Future<bool> Function(Uri)> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Future<bool> Function(Uri) create(Ref ref) {
    return appUpdateLauncher(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Future<bool> Function(Uri) value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Future<bool> Function(Uri)>(value),
    );
  }
}

String _$appUpdateLauncherHash() => r'1f456af0e04978f29cd76cc7aae27dfbdc7cfcd5';

/// Bound at the app root to start checking after the first frame and recheck
/// when the app resumes or regains connectivity.

@ProviderFor(appUpdateLifecycle)
final appUpdateLifecycleProvider = AppUpdateLifecycleProvider._();

/// Bound at the app root to start checking after the first frame and recheck
/// when the app resumes or regains connectivity.

final class AppUpdateLifecycleProvider
    extends $FunctionalProvider<void, void, void>
    with $Provider<void> {
  /// Bound at the app root to start checking after the first frame and recheck
  /// when the app resumes or regains connectivity.
  AppUpdateLifecycleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appUpdateLifecycleProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appUpdateLifecycleHash();

  @$internal
  @override
  $ProviderElement<void> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  void create(Ref ref) {
    return appUpdateLifecycle(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$appUpdateLifecycleHash() =>
    r'92cd51c689bb05a1047d04ad275988540cedc226';

@ProviderFor(AppUpdateController)
final appUpdateControllerProvider = AppUpdateControllerProvider._();

final class AppUpdateControllerProvider
    extends $NotifierProvider<AppUpdateController, AppUpdateState> {
  AppUpdateControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appUpdateControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appUpdateControllerHash();

  @$internal
  @override
  AppUpdateController create() => AppUpdateController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppUpdateState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppUpdateState>(value),
    );
  }
}

String _$appUpdateControllerHash() =>
    r'f1884584980f282ae89a741a1834516d767b4f5a';

abstract class _$AppUpdateController extends $Notifier<AppUpdateState> {
  AppUpdateState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AppUpdateState, AppUpdateState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AppUpdateState, AppUpdateState>,
              AppUpdateState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
