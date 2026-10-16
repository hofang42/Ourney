import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/app/router.dart';
import 'package:ourney/features/profile/avatar_picker.dart';
import 'package:ourney/features/profile/profile_providers.dart';
import 'package:ourney_core/ourney_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/test_helpers.dart';

/// Records calls and lets each auth step fail with a chosen error.
class RecordingAuthRepository extends FakeAuthRepository {
  RecordingAuthRepository({super.userId});

  final List<String> calls = [];
  Object? sendOtpError;
  Object? verifyOtpError;
  Object? deleteError;
  Object? signOutError;

  @override
  Future<void> sendOtp(String email) async {
    calls.add('sendOtp:$email');
    if (sendOtpError case final e?) throw e;
  }

  @override
  Future<void> verifyOtp(String email, String code) async {
    calls.add('verifyOtp:$email:$code');
    if (verifyOtpError case final e?) throw e;
    emit('u1');
  }

  @override
  Future<void> signOut() async {
    calls.add('signOut');
    if (signOutError case final e?) throw e;
    emit(null);
  }

  @override
  Future<void> deleteAccount() async {
    calls.add('deleteAccount');
    if (deleteError case final e?) throw e;
    emit(null);
  }
}

/// In-memory [ProfileRepository]; `upsertMe` fails for [takenUsernames]
/// the way the data layer maps a UNIQUE violation (23505 → `invalid`).
class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository([this.profile]);

  Profile? profile;
  final Set<String> takenUsernames = {};
  Object? upsertError;
  Object? avatarError;
  final List<String> calls = [];
  List<int>? avatarBytes;
  final _changes = StreamController<Profile?>.broadcast();

  @override
  Stream<Profile?> watchMe() async* {
    yield profile;
    yield* _changes.stream;
  }

  @override
  Future<void> upsertMe({
    required String username,
    required String displayName,
  }) async {
    calls.add('upsertMe:$username:$displayName');
    if (upsertError case final e?) throw e;
    if (takenUsernames.contains(username)) {
      throw const OurneyException(OurneyErrorCode.invalid, '23505');
    }
    profile = Profile(
      id: 'u1',
      username: username,
      displayName: displayName,
      avatarPath: profile?.avatarPath,
    );
    _changes.add(profile);
  }

  @override
  Future<void> setAvatar(List<int> jpegBytes) async {
    calls.add('setAvatar:${jpegBytes.length}');
    if (avatarError case final e?) throw e;
    avatarBytes = jpegBytes;
    final p = profile!;
    profile = Profile(
      id: p.id,
      username: p.username,
      displayName: p.displayName,
      avatarPath: 'avatars/u1.jpg',
    );
    _changes.add(profile);
  }
}

class FakeMediaStore implements MediaStore {
  @override
  // No real file in tests: the avatar falls back to initials.
  Future<String> localFileFor(String storagePath) async =>
      throw const OurneyException(OurneyErrorCode.notFound);
}

class FakeAvatarPicker implements AvatarPicker {
  FakeAvatarPicker([this.bytes]);

  Uint8List? bytes;
  AvatarSource? lastSource;

  @override
  Future<Uint8List?> pick(AvatarSource source) async {
    lastSource = source;
    return bytes;
  }
}

const aliceProfile = Profile(
  id: 'u1',
  username: 'alice',
  displayName: 'Alice Nguyen',
);

/// Pumps the real app with a backend config and the fakes above.
Future<ProviderContainer> pumpBackendApp(
  WidgetTester tester, {
  required RecordingAuthRepository auth,
  FakeProfileRepository? profiles,
  FakeAvatarPicker? picker,
  bool onboarded = true,
}) => pumpOurneyApp(
  tester,
  config: testBackendConfig,
  auth: auth,
  onboarded: onboarded,
  overrides: [
    profileRepositoryProvider.overrideWithValue(
      profiles ?? FakeProfileRepository(),
    ),
    mediaStoreProvider.overrideWithValue(FakeMediaStore()),
    avatarPickerProvider.overrideWithValue(picker ?? FakeAvatarPicker()),
  ],
);

String location(ProviderContainer c) =>
    c.read(routerProvider).routerDelegate.currentConfiguration.uri.toString();

Future<void> goTo(WidgetTester tester, ProviderContainer c, String path) async {
  c.read(routerProvider).go(path);
  await tester.pumpAndSettle();
}

Finder byKey(String key) => find.byKey(ValueKey(key));
