import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:exif/exif.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'photo_dates.dart';

/// A photo picked from the library for a retold journey.
class ImportPhoto {
  const ImportPhoto({
    required this.path,
    required this.modified,
    this.exif,
    this.size,
    this.fingerprint,
  });

  /// The picker's copy of the original file (never a compressed one).
  final String path;

  /// The file's modified time: the picker's copy time on most devices, so it
  /// is only a fallback ([resolvePhotoMoment] checks it is plausible).
  final DateTime modified;

  /// The camera's capture time (`DateTimeOriginal` + `OffsetTimeOriginal`).
  final ExifMoment? exif;

  /// Size in bytes (with the capture time it recognises a photo picked twice).
  final int? size;

  /// Hash of the file's content, when computed.
  final String? fingerprint;

  /// Two picks of the same photo share this key: the content hash when there
  /// is one, else capture time + size, else the path.
  String get dedupeKey {
    final f = fingerprint;
    if (f != null) return 'h:$f';
    final e = exif;
    if (e != null && size != null) {
      return 'e:${e.date}:${e.secondsOfDay}:$size';
    }
    return 'p:$path';
  }
}

/// Multi-select library picker. Injectable so widget tests need no plugin.
abstract interface class ImportPhotoPicker {
  /// Opens the system picker; empty when the user cancels. [limit] caps how
  /// many photos one pick may return.
  Future<List<ImportPhoto>> pickPhotos({int limit = importMaxPhotos});

  /// Photos picked before Android killed the app (`retrieveLostData`); empty
  /// when there are none or on other platforms.
  Future<List<ImportPhoto>> recoverLost();
}

/// How much of a file is read for its EXIF block (it sits in the first
/// segments of a JPEG; HEIC keeps it in an early `meta` box).
const int _headBytes = 1024 * 1024;

/// The capture time of an image's bytes, or null (no EXIF, unreadable).
Future<ExifMoment?> readExifMoment(Uint8List head) async {
  try {
    final tags = await readExifFromBytes(head);
    String? tag(String key) => tags[key]?.printable;
    final original = tag('EXIF DateTimeOriginal');
    final moment = parseExifDateTime(
      original ?? tag('EXIF DateTimeDigitized'),
      offset: original != null
          ? tag('EXIF OffsetTimeOriginal')
          : tag('EXIF OffsetTimeDigitized'),
    );
    return moment;
  } on Object catch (e) {
    debugPrint('import: EXIF read failed: $e');
    return null;
  }
}

class ImagePickerImportPicker implements ImportPhotoPicker {
  ImagePickerImportPicker([ImagePicker? picker])
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<List<ImportPhoto>> pickPhotos({int limit = importMaxPhotos}) async {
    // No maxWidth/maxHeight: the picker would re-encode and drop the EXIF
    // block; the compressor resizes to 1080px before the upload anyway.
    // requestFullMetadata stays true (the default): on iOS the picker only
    // hands over the original bytes, EXIF block included, with it, and the
    // automatic dating depends on that block.
    final files = await _picker.pickMultiImage(limit: limit < 2 ? 2 : limit);
    return _describe(files);
  }

  @override
  Future<List<ImportPhoto>> recoverLost() async {
    if (!Platform.isAndroid) return const [];
    try {
      final lost = await _picker.retrieveLostData();
      if (lost.isEmpty || lost.type == RetrieveType.video) return const [];
      return await _describe(lost.files ?? const []);
    } on Object catch (e) {
      debugPrint('import: retrieveLostData failed: $e');
      return const [];
    }
  }

  Future<List<ImportPhoto>> _describe(List<XFile> files) async {
    final out = <ImportPhoto>[];
    for (final f in files) {
      try {
        out.add(await _describeOne(f));
      } on Object catch (e) {
        // One unreadable file must not drop the others.
        debugPrint('import: cannot read ${f.name}: $e');
      }
    }
    return out;
  }

  Future<ImportPhoto> _describeOne(XFile f) async {
    final file = File(f.path);
    final size = await file.length();
    final modified = await f.lastModified();
    final raf = await file.open();
    Uint8List head;
    Uint8List tail = Uint8List(0);
    try {
      head = await raf.read(size < _headBytes ? size : _headBytes);
      if (size > _headBytes) {
        await raf.setPosition(size - 64 * 1024);
        tail = await raf.read(64 * 1024);
      }
    } finally {
      await raf.close();
    }
    final hash = sha1.convert([
      ...head.take(64 * 1024),
      ...tail,
      ...'$size'.codeUnits,
    ]).toString();
    return ImportPhoto(
      path: f.path,
      modified: modified,
      exif: await readExifMoment(head),
      size: size,
      fingerprint: hash,
    );
  }
}

final importPhotoPickerProvider = Provider<ImportPhotoPicker>(
  (ref) => ImagePickerImportPicker(),
);
