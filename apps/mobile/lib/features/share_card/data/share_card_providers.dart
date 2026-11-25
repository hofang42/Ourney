import 'package:clock/clock.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderException;
import 'package:ourney_core/ourney_core.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/providers.dart';
import 'share_card_exporter.dart';

/// Repository streams must not retry on their own (the repositories handle
/// offline/sync; retry timers would leak into widget tests).
Duration? _noRetry(int _, Object _) => null;

/// Wall clock for "today" (streak, day N). Override in tests.
final shareCardClockProvider = Provider<Clock>((ref) => const Clock());

final shareJourneyProvider = StreamProvider.autoDispose
    .family<Journey?, String>(
      (ref, id) => ref.watch(journeyRepositoryProvider).watch(id),
      retry: _noRetry,
    );

final shareMembershipProvider = StreamProvider.autoDispose
    .family<Membership?, String>(
      (ref, id) => ref.watch(journeyRepositoryProvider).watchMyMembership(id),
      retry: _noRetry,
    );

/// The caller's own check-ins (the card only ever shows the caller's
/// photos). Local-only mode has no user id: the membership's is used, or
/// every check-in (all of them are the caller's without a server).
final shareCheckInsProvider = StreamProvider.autoDispose
    .family<List<CheckIn>, String>((ref, id) {
      final userId =
          ref.watch(currentUserIdProvider) ??
          ref.watch(shareMembershipProvider(id)).value?.userId;
      return ref
          .watch(checkInRepositoryProvider)
          .watchForJourney(id, userId: userId);
    }, retry: _noRetry);

/// Local file of a check-in photo: the on-device file while it is not
/// uploaded, else [MediaStore.localFileFor] (disk cache keyed by path).
final shareCardPhotoFileProvider = FutureProvider.autoDispose
    .family<String, ({String storagePath, String? localFile})>((ref, key) {
      final local = key.localFile;
      if (local != null) return local;
      return ref.watch(mediaStoreProvider).localFileFor(key.storagePath);
    }, retry: _noRetry);

/// Opens the system share sheet with a card image (FR-E2). Injectable so
/// tests can assert what is shared.
abstract interface class ShareCardSharer {
  Future<void> shareImage({
    required String path,
    required String mimeType,
    String? text,
    Rect? origin,
  });
}

/// share_plus 13: `SharePlus.instance.share(ShareParams(...))`.
class SharePlusShareCardSharer implements ShareCardSharer {
  const SharePlusShareCardSharer();

  @override
  Future<void> shareImage({
    required String path,
    required String mimeType,
    String? text,
    Rect? origin,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path, mimeType: mimeType)],
        text: text,
        // Required on iPad (popover anchor).
        sharePositionOrigin: origin,
      ),
    );
  }
}

final shareCardSharerProvider = Provider<ShareCardSharer>(
  (ref) => const SharePlusShareCardSharer(),
);

/// Error thrown when saving an exported share card to the device photo gallery
/// fails (e.g. `PERMISSION_DENIED`, `INVALID_FILE`, `SAVE_FAILED`).
class ShareCardSaveException implements Exception {
  const ShareCardSaveException({
    required this.code,
    this.message,
  });

  final String code;
  final String? message;

  bool get isPermissionDenied => code == 'PERMISSION_DENIED';

  @override
  String toString() => 'ShareCardSaveException($code, $message)';
}

/// Saves an exported share-card image file to the device photo gallery so the
/// user can keep it locally. Injectable so tests can assert what is saved.
abstract interface class ShareCardSaver {
  Future<String> saveImage({
    required String path,
    required String mimeType,
  });
}

class PlatformShareCardSaver implements ShareCardSaver {
  const PlatformShareCardSaver();

  static const channel = MethodChannel('ourney/media_saver');

  @override
  Future<String> saveImage({
    required String path,
    required String mimeType,
  }) async {
    final ext = mimeType == 'image/jpeg' ? 'jpg' : 'png';
    final fileName =
        'ourney-card-${DateTime.now().millisecondsSinceEpoch}.$ext';
    try {
      final saved = await channel.invokeMethod<String>('saveImage', {
        'path': path,
        'mimeType': mimeType,
        'fileName': fileName,
      });
      if (saved != null && saved.isNotEmpty) return saved;
      throw const ShareCardSaveException(
        code: 'SAVE_FAILED',
        message: 'Empty result from native media saver',
      );
    } on PlatformException catch (e) {
      throw ShareCardSaveException(code: e.code, message: e.message);
    } on MissingPluginException catch (e) {
      throw ShareCardSaveException(
        code: 'UNAVAILABLE',
        message: e.message,
      );
    }
  }
}

final shareCardSaverProvider = Provider<ShareCardSaver>(
  (ref) => const PlatformShareCardSaver(),
);

final shareCardExporterProvider = Provider<ShareCardExporter>(
  (ref) => ShareCardExporter(),
);

/// Unwraps Riverpod's [ProviderException] (a dependency in error state).
Object shareRootError(Object error) {
  var e = error;
  while (e is ProviderException) {
    e = e.exception;
  }
  return e;
}

/// True while the data layer is not wired (placeholder repositories throw
/// [UnimplementedError] until B1 lands).
bool shareNotWired(Object error) => shareRootError(error) is UnimplementedError;
