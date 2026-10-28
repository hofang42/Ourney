import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/providers.dart';
import '../../../shared/time_zones.dart';

/// Repository streams handle offline/sync themselves; Riverpod must not
/// retry (timers would also leak into widget tests).
Duration? _noRetry(int _, Object _) => null;

/// Share state of a journey for its owner / a member (SCR-82).
final shareStateProvider = StreamProvider.autoDispose
    .family<JourneyShareState, String>(
      (ref, id) => ref.watch(sharingRepositoryProvider).watchShareState(id),
      retry: _noRetry,
    );

/// The caller's accepted friends (pending requests left out).
final acceptedFriendsProvider = StreamProvider.autoDispose<List<PersonSummary>>(
  (ref) => ref
      .watch(friendRepositoryProvider)
      .watchFriendships()
      .map(
        (all) => [
          for (final f in all)
            if (f.isFriend) f.person,
        ],
      ),
  retry: _noRetry,
);

/// Hub → Shared with me (S8, S26).
final sharedWithMeProvider =
    StreamProvider.autoDispose<List<SharedJourneySummary>>(
      (ref) => ref.watch(sharingRepositoryProvider).watchSharedWithMe(),
      retry: _noRetry,
    );

/// Consents of the members of a group journey (S29–S31).
final shareConsentsProvider = StreamProvider.autoDispose
    .family<List<ShareConsent>, String>(
      (ref, id) =>
          ref.watch(shareConsentRepositoryProvider).watchForJourney(id),
      retry: _noRetry,
    );

/// SCR-88 numbers.
final journeyInsightsProvider = FutureProvider.autoDispose
    .family<JourneyInsights, String>(
      (ref, id) => ref.watch(insightsRepositoryProvider).journeyInsights(id),
      retry: _noRetry,
    );

final sharingJourneyProvider = StreamProvider.autoDispose
    .family<Journey?, String>(
      (ref, id) => ref.watch(journeyRepositoryProvider).watch(id),
      retry: _noRetry,
    );

/// Every check-in of a journey the caller can see (cover picker).
final sharingCheckInsProvider = StreamProvider.autoDispose
    .family<List<CheckIn>, String>(
      (ref, id) => ref.watch(checkInRepositoryProvider).watchForJourney(id),
      retry: _noRetry,
    );

/// Which shared journey to open: by id (friend / member) or by public token
/// (signed-in stranger with the link).
typedef SharedViewKey = ({String id, bool byToken});

/// SCR-84 view (records a view on the server).
final sharedViewProvider = FutureProvider.autoDispose
    .family<SharedJourneyView, SharedViewKey>((ref, key) {
      final repo = ref.watch(sharingRepositoryProvider);
      return key.byToken ? repo.openPublic(key.id) : repo.openShared(key.id);
    }, retry: _noRetry);

/// SCR-87 frame.
final followFrameProvider = FutureProvider.autoDispose
    .family<JourneyFrame, String>(
      (ref, id) => ref.watch(sharingRepositoryProvider).followFrame(id),
      retry: _noRetry,
    );

/// Local file of a storage object (photos, thumbnails, avatars).
final storageFileProvider = FutureProvider.autoDispose.family<String, String>(
  (ref, path) => ref.watch(mediaStoreProvider).localFileFor(path),
  retry: _noRetry,
);

// --- retell (SCR-28) ---------------------------------------------------------

/// A photo picked from the library for a retold journey.
class RetellPhoto {
  const RetellPhoto({required this.path, required this.modified});

  /// Original file on local disk (the picker's copy).
  final String path;

  /// File last-modified time: the default day of the photo.
  final DateTime modified;
}

/// Multi-select library picker. Injectable so widget tests need no plugin.
abstract interface class RetellPhotoPicker {
  /// Empty when the user cancels.
  Future<List<RetellPhoto>> pickPhotos();
}

class ImagePickerRetellPicker implements RetellPhotoPicker {
  ImagePickerRetellPicker([ImagePicker? picker])
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<List<RetellPhoto>> pickPhotos() async {
    // Compression to 1080px/q70 happens before each submit; the picker only
    // bounds very large originals.
    final files = await _picker.pickMultiImage(
      maxWidth: 4096,
      maxHeight: 4096,
      requestFullMetadata: false,
    );
    return [
      for (final f in files)
        RetellPhoto(path: f.path, modified: await f.lastModified()),
    ];
  }
}

final retellPhotoPickerProvider = Provider<RetellPhotoPicker>(
  (ref) => ImagePickerRetellPicker(),
);

/// `captured_at` of a retold photo: noon of [date] in the journey's time
/// zone, so the server derives exactly that `local_date`.
DateTime noonInZone(LocalDate date, String timezone) {
  final naive = DateTime.utc(date.year, date.month, date.day, 12);
  return naive.subtract(timeZoneOffsetAt(timezone, naive));
}
