// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The signed-in user's profile (null when none exists yet, signed out or
/// local-only). Errors surface to the UI, which offers a retry button.

@ProviderFor(myProfile)
final myProfileProvider = MyProfileProvider._();

/// The signed-in user's profile (null when none exists yet, signed out or
/// local-only). Errors surface to the UI, which offers a retry button.

final class MyProfileProvider
    extends
        $FunctionalProvider<AsyncValue<Profile?>, Profile?, Stream<Profile?>>
    with $FutureModifier<Profile?>, $StreamProvider<Profile?> {
  /// The signed-in user's profile (null when none exists yet, signed out or
  /// local-only). Errors surface to the UI, which offers a retry button.
  MyProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: _noRetry,
        name: r'myProfileProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myProfileHash();

  @$internal
  @override
  $StreamProviderElement<Profile?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Profile?> create(Ref ref) {
    return myProfile(ref);
  }
}

String _$myProfileHash() => r'95de4d85205b6e2247f0efb9e38a48915093a410';

/// Local file for an avatar storage path (MediaStore disk cache).

@ProviderFor(avatarFile)
final avatarFileProvider = AvatarFileFamily._();

/// Local file for an avatar storage path (MediaStore disk cache).

final class AvatarFileProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  /// Local file for an avatar storage path (MediaStore disk cache).
  AvatarFileProvider._({
    required AvatarFileFamily super.from,
    required String super.argument,
  }) : super(
         retry: _noRetry,
         name: r'avatarFileProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$avatarFileHash();

  @override
  String toString() {
    return r'avatarFileProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    final argument = this.argument as String;
    return avatarFile(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AvatarFileProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$avatarFileHash() => r'8ea4d49504b60b890a4b058bc34789d6f19eb196';

/// Local file for an avatar storage path (MediaStore disk cache).

final class AvatarFileFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String>, String> {
  AvatarFileFamily._()
    : super(
        retry: _noRetry,
        name: r'avatarFileProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Local file for an avatar storage path (MediaStore disk cache).

  AvatarFileProvider call(String storagePath) =>
      AvatarFileProvider._(argument: storagePath, from: this);

  @override
  String toString() => r'avatarFileProvider';
}

/// Picks and compresses an avatar to JPEG. Overridden in tests.

@ProviderFor(avatarPicker)
final avatarPickerProvider = AvatarPickerProvider._();

/// Picks and compresses an avatar to JPEG. Overridden in tests.

final class AvatarPickerProvider
    extends $FunctionalProvider<AvatarPicker, AvatarPicker, AvatarPicker>
    with $Provider<AvatarPicker> {
  /// Picks and compresses an avatar to JPEG. Overridden in tests.
  AvatarPickerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'avatarPickerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$avatarPickerHash();

  @$internal
  @override
  $ProviderElement<AvatarPicker> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AvatarPicker create(Ref ref) {
    return avatarPicker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AvatarPicker value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AvatarPicker>(value),
    );
  }
}

String _$avatarPickerHash() => r'1d2e40a0491288c19bc037c0835c97a1bd0cb62e';
