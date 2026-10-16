import 'dart:ui' show Rect;

import 'package:clock/clock.dart';
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
