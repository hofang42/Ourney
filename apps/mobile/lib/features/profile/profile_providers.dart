import 'package:ourney_core/ourney_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../app/providers.dart';
import 'avatar_picker.dart';

part 'profile_providers.g.dart';

Duration? _noRetry(int retryCount, Object error) => null;

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
