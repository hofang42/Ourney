import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../data/data_context.dart' show checkinDraftDirName;

/// Output of [PhotoCompressor.compress]: JPEG files on local disk, ready for
/// `CheckInDraft.photoFile` / `thumbFile`.
class CompressedPhoto {
  const CompressedPhoto({required this.photoFile, required this.thumbFile});

  final String photoFile;
  final String thumbFile;
}

class PhotoCompressException implements Exception {
  const PhotoCompressException([this.detail]);
  final String? detail;

  @override
  String toString() => 'PhotoCompressException($detail)';
}

/// On-device compression (FR-C5). Injectable so widget tests do not need the
/// native plugin.
abstract interface class PhotoCompressor {
  /// Throws [PhotoCompressException].
  Future<CompressedPhoto> compress(String sourcePath);
}

/// [PhotoCompressor] backed by flutter_image_compress 2.5.
///
/// `compressAndGetFile` scales by `max(1, min(w / minWidth, h / minHeight))`
/// (never upscales), so `minWidth == minHeight == 1080` gives a 1080px short
/// side. EXIF orientation is applied (`autoCorrectionAngle`) and EXIF is
/// dropped (`keepExif: false`), which also strips GPS metadata.
class FlutterImagePhotoCompressor implements PhotoCompressor {
  const FlutterImagePhotoCompressor();

  static const int photoSide = 1080;
  static const int photoQuality = 70;
  static const int thumbSide = 320;
  static const int thumbQuality = 60;

  /// Files live in app support storage (not the purgeable temp dir) until
  /// the upload queue in lib/data has sent them.
  static Future<Directory> _dir() async {
    final base = await getApplicationSupportDirectory();
    // Wiped with the rest of the local data (DataContext.wipeLocal).
    final dir = Directory(p.join(base.path, checkinDraftDirName));
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  @override
  Future<CompressedPhoto> compress(String sourcePath) async {
    final dir = await _dir();
    final id = const Uuid().v4();
    final photoPath = p.join(dir.path, '$id.jpg');
    final thumbPath = p.join(dir.path, '${id}_t.jpg');
    final photo = await FlutterImageCompress.compressAndGetFile(
      sourcePath,
      photoPath,
      minWidth: photoSide,
      minHeight: photoSide,
      quality: photoQuality,
    );
    if (photo == null) throw const PhotoCompressException('photo');
    final thumb = await FlutterImageCompress.compressAndGetFile(
      photo.path,
      thumbPath,
      minWidth: thumbSide,
      minHeight: thumbSide,
      quality: thumbQuality,
    );
    if (thumb == null) throw const PhotoCompressException('thumbnail');
    return CompressedPhoto(photoFile: photo.path, thumbFile: thumb.path);
  }
}

final photoCompressorProvider = Provider<PhotoCompressor>(
  (ref) => const FlutterImagePhotoCompressor(),
);

/// Deletes check-in draft files once they are no longer needed: the
/// compressed photo/thumbnail after a successful submit (the repository has
/// copied them into the media store) or a failed one (a retry compresses
/// again), and the raw camera/picker file after posting or discarding.
abstract interface class DraftFiles {
  /// Never throws; missing files are ignored.
  Future<void> discard(Iterable<String> paths);
}

/// Deletes only files inside the app's temporary directory (camera and
/// picker output) or the check-in draft folder, never anything else (a
/// picker could in theory hand back an original from the user's library).
class LocalDraftFiles implements DraftFiles {
  const LocalDraftFiles();

  @override
  Future<void> discard(Iterable<String> paths) async {
    try {
      final roots = [
        (await getTemporaryDirectory()).path,
        p.join(
          (await getApplicationSupportDirectory()).path,
          checkinDraftDirName,
        ),
      ];
      for (final path in paths) {
        if (!roots.any((r) => p.isWithin(r, path))) continue;
        final f = File(path);
        if (f.existsSync()) await f.delete();
      }
    } on Object {
      // Best effort: leftovers are removed with the local data anyway.
    }
  }
}

final draftFilesProvider = Provider<DraftFiles>(
  (ref) => const LocalDraftFiles(),
);
