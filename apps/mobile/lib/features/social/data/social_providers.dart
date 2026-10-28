import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderException;
import 'package:image_picker/image_picker.dart';
import 'package:ourney_core/ourney_core.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/providers.dart';

/// Repository streams never retry on a timer (the data layer handles
/// offline/sync, and timers would leak into widget tests).
Duration? _noRetry(int _, Object _) => null;

/// Friends and pending requests in both directions (SCR-80, SCR-85).
final friendshipsProvider = StreamProvider.autoDispose<List<Friendship>>(
  (ref) => ref.watch(friendRepositoryProvider).watchFriendships(),
  retry: _noRetry,
);

/// Conversations of the caller, newest first (SCR-85).
final conversationsProvider = StreamProvider.autoDispose<List<Conversation>>(
  (ref) => ref.watch(chatRepositoryProvider).watchConversations(),
  retry: _noRetry,
);

/// Messages of one conversation, oldest first (SCR-86).
final chatMessagesProvider = StreamProvider.autoDispose
    .family<List<ChatMessage>, String>(
      (ref, id) => ref.watch(chatRepositoryProvider).watchMessages(id),
      retry: _noRetry,
    );

/// The caller's pending group share consent requests (S29, inbox).
final pendingConsentsProvider = StreamProvider.autoDispose<List<ShareConsent>>(
  (ref) => ref.watch(shareConsentRepositoryProvider).watchMyPending(),
  retry: _noRetry,
);

/// Counts behind the Hub inbox dot (S16, S27).
final inboxCountsProvider = StreamProvider.autoDispose<InboxCounts>(
  (ref) => ref.watch(insightsRepositoryProvider).watchInboxCounts(),
  retry: _noRetry,
);

/// Resolves a storage path (chat photo, replied-to thumbnail) to a local
/// file through the [MediaStore] disk cache.
final socialMediaFileProvider = FutureProvider.autoDispose
    .family<String, String>(
      (ref, storagePath) =>
          ref.watch(mediaStoreProvider).localFileFor(storagePath),
      retry: _noRetry,
    );

/// The caller's invite token, created on first use and kept for the app
/// session: `createInvite` rotates, so it is not called on every visit.
final myInviteTokenProvider = NotifierProvider<MyInviteToken, String?>(
  MyInviteToken.new,
);

class MyInviteToken extends Notifier<String?> {
  Future<String>? _pending;

  @override
  String? build() => null;

  /// Returns the session's token, creating it once.
  Future<String> ensure() {
    final current = state;
    if (current != null) return Future.value(current);
    return _pending ??= ref
        .read(friendRepositoryProvider)
        .createInvite()
        .then((token) {
          state = token;
          return token;
        })
        .whenComplete(() => _pending = null);
  }
}

/// Opens the system share sheet with [text]. Override in tests.
typedef SocialShareLauncher = Future<void> Function(String text);

final socialShareLauncherProvider = Provider<SocialShareLauncher>(
  (ref) => (text) async {
    await SharePlus.instance.share(ShareParams(text: text));
  },
);

/// Copies [text] to the clipboard. Override in tests.
final socialClipboardProvider = Provider<Future<void> Function(String text)>(
  (ref) =>
      (text) => Clipboard.setData(ClipboardData(text: text)),
);

/// Thrown by [ChatPhotoPicker] when the picked image cannot be compressed.
class ChatPhotoException implements Exception {
  const ChatPhotoException([this.detail]);
  final String? detail;

  @override
  String toString() => 'ChatPhotoException($detail)';
}

/// Picks a chat photo and returns it as compressed JPEG bytes (null when the
/// user cancels). Injectable so widget tests need no native plugin.
abstract interface class ChatPhotoPicker {
  Future<List<int>?> pick({required bool camera});
}

/// image_picker + flutter_image_compress, with the check-in settings
/// (1080px short side, quality 70, EXIF and GPS dropped).
class DeviceChatPhotoPicker implements ChatPhotoPicker {
  const DeviceChatPhotoPicker();

  static const int side = 1080;
  static const int quality = 70;

  @override
  Future<List<int>?> pick({required bool camera}) async {
    final file = await ImagePicker().pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
    );
    if (file == null) return null;
    final bytes = await FlutterImageCompress.compressWithFile(
      file.path,
      minWidth: side,
      minHeight: side,
      quality: quality,
    );
    if (bytes == null || bytes.isEmpty) {
      throw const ChatPhotoException('compress');
    }
    return bytes;
  }
}

final chatPhotoPickerProvider = Provider<ChatPhotoPicker>(
  (ref) => const DeviceChatPhotoPicker(),
);

/// Unwraps Riverpod's [ProviderException].
Object socialRootError(Object error) {
  var e = error;
  while (e is ProviderException) {
    e = e.exception;
  }
  return e;
}

/// The error code of a repository failure, or null for anything else.
OurneyErrorCode? socialErrorCode(Object error) {
  final e = socialRootError(error);
  return e is OurneyException ? e.error : null;
}
