// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(dataEnvironment)
final dataEnvironmentProvider = DataEnvironmentProvider._();

final class DataEnvironmentProvider
    extends
        $FunctionalProvider<DataEnvironment, DataEnvironment, DataEnvironment>
    with $Provider<DataEnvironment> {
  DataEnvironmentProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dataEnvironmentProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dataEnvironmentHash();

  @$internal
  @override
  $ProviderElement<DataEnvironment> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DataEnvironment create(Ref ref) {
    return dataEnvironment(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DataEnvironment value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DataEnvironment>(value),
    );
  }
}

String _$dataEnvironmentHash() => r'a30ac1fa41557a5975934069069c9796a617291a';

/// Builds the repositories for the configured mode: Supabase when a client
/// exists (or a test [DataEnvironment.remote]), local-only otherwise.

@ProviderFor(dataLayer)
final dataLayerProvider = DataLayerProvider._();

/// Builds the repositories for the configured mode: Supabase when a client
/// exists (or a test [DataEnvironment.remote]), local-only otherwise.

final class DataLayerProvider
    extends $FunctionalProvider<DataLayer, DataLayer, DataLayer>
    with $Provider<DataLayer> {
  /// Builds the repositories for the configured mode: Supabase when a client
  /// exists (or a test [DataEnvironment.remote]), local-only otherwise.
  DataLayerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dataLayerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dataLayerHash();

  @$internal
  @override
  $ProviderElement<DataLayer> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DataLayer create(Ref ref) {
    return dataLayer(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DataLayer value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DataLayer>(value),
    );
  }
}

String _$dataLayerHash() => r'a53e1cc2953afc54b68a228f61d20852decc9ac1';

/// Absolute path of a displayable file for a storage path (check-in photo or
/// thumbnail, avatar): own media straight from disk, other members' media
/// downloaded once through a 1 h signed URL and cached by path.
///
/// ```dart
/// final file = ref.watch(mediaFileProvider(checkIn.thumbPath));
/// file.when(data: (p) => Image.file(File(p)), ...);
/// ```

@ProviderFor(mediaFile)
final mediaFileProvider = MediaFileFamily._();

/// Absolute path of a displayable file for a storage path (check-in photo or
/// thumbnail, avatar): own media straight from disk, other members' media
/// downloaded once through a 1 h signed URL and cached by path.
///
/// ```dart
/// final file = ref.watch(mediaFileProvider(checkIn.thumbPath));
/// file.when(data: (p) => Image.file(File(p)), ...);
/// ```

final class MediaFileProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  /// Absolute path of a displayable file for a storage path (check-in photo or
  /// thumbnail, avatar): own media straight from disk, other members' media
  /// downloaded once through a 1 h signed URL and cached by path.
  ///
  /// ```dart
  /// final file = ref.watch(mediaFileProvider(checkIn.thumbPath));
  /// file.when(data: (p) => Image.file(File(p)), ...);
  /// ```
  MediaFileProvider._({
    required MediaFileFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'mediaFileProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$mediaFileHash();

  @override
  String toString() {
    return r'mediaFileProvider'
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
    return mediaFile(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MediaFileProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$mediaFileHash() => r'd5bd52b329bd862c309fef987c9d9fc2f70ebd58';

/// Absolute path of a displayable file for a storage path (check-in photo or
/// thumbnail, avatar): own media straight from disk, other members' media
/// downloaded once through a 1 h signed URL and cached by path.
///
/// ```dart
/// final file = ref.watch(mediaFileProvider(checkIn.thumbPath));
/// file.when(data: (p) => Image.file(File(p)), ...);
/// ```

final class MediaFileFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String>, String> {
  MediaFileFamily._()
    : super(
        retry: null,
        name: r'mediaFileProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Absolute path of a displayable file for a storage path (check-in photo or
  /// thumbnail, avatar): own media straight from disk, other members' media
  /// downloaded once through a 1 h signed URL and cached by path.
  ///
  /// ```dart
  /// final file = ref.watch(mediaFileProvider(checkIn.thumbPath));
  /// file.when(data: (p) => Image.file(File(p)), ...);
  /// ```

  MediaFileProvider call(String storagePath) =>
      MediaFileProvider._(argument: storagePath, from: this);

  @override
  String toString() => r'mediaFileProvider';
}
