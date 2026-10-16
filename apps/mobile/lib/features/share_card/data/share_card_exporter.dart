import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/share_card_content.dart';

/// An encoded card image ready to be written to disk.
class ShareCardImage {
  const ShareCardImage({
    required this.bytes,
    required this.width,
    required this.height,
    required this.format,
  });

  final Uint8List bytes;
  final int width;
  final int height;
  final ShareCardImageFormat format;
}

enum ShareCardImageFormat {
  png('png', 'image/png'),
  jpeg('jpg', 'image/jpeg');

  const ShareCardImageFormat(this.extension, this.mimeType);
  final String extension;
  final String mimeType;
}

/// A card image written to a temporary file.
class ShareCardFile {
  const ShareCardFile({required this.path, required this.image});

  final String path;
  final ShareCardImage image;

  String get mimeType => image.format.mimeType;
}

/// Re-encodes PNG bytes as JPEG at the same pixel size.
typedef ShareCardJpegEncoder = Future<Uint8List> Function(
  Uint8List png, {
  required int width,
  required int height,
  required int quality,
});

Future<Uint8List> _flutterImageCompressJpeg(
  Uint8List png, {
  required int width,
  required int height,
  required int quality,
}) => FlutterImageCompress.compressWithList(
  png,
  // Equal to the source size: the plugin only scales down, never up.
  minWidth: width,
  minHeight: height,
  quality: quality,
  format: CompressFormat.jpeg,
);

/// Renders the card's [RenderRepaintBoundary] at the exact output size
/// (FR-E1), encodes it (PNG, or JPEG when the PNG is over [maxBytes]) and
/// writes it to the temporary directory (FR-E2).
class ShareCardExporter {
  ShareCardExporter({
    ShareCardJpegEncoder? jpegEncoder,
    Future<Directory> Function()? tempDirectory,
    this.maxBytes = 1000000,
  }) : _jpeg = jpegEncoder ?? _flutterImageCompressJpeg,
       _tempDirectory = tempDirectory ?? getTemporaryDirectory;

  final ShareCardJpegEncoder _jpeg;
  final Future<Directory> Function() _tempDirectory;

  /// Target upper bound for the shared file (messaging apps recompress
  /// anything bigger).
  final int maxBytes;

  /// JPEG qualities tried in order until the file fits in [maxBytes].
  static const jpegQualities = [92, 85, 75];

  /// Captures [boundary] (laid out at [ShareCardFormat.logicalSize]) at
  /// [ShareCardFormat.pixelRatio]. Throws [StateError] if the boundary does
  /// not produce exactly the format's pixel size.
  Future<ui.Image> capture(
    RenderRepaintBoundary boundary,
    ShareCardFormat format,
  ) async {
    final ratio = format.pixelWidth / boundary.size.width;
    final image = await boundary.toImage(pixelRatio: ratio);
    if (image.width != format.pixelWidth ||
        image.height != format.pixelHeight) {
      final got = '${image.width}x${image.height}';
      image.dispose();
      throw StateError(
        'Share card rendered at $got, expected '
        '${format.pixelWidth}x${format.pixelHeight}',
      );
    }
    return image;
  }

  /// PNG when it fits in [maxBytes]; otherwise the smallest JPEG that does
  /// (or the smallest one tried). Falls back to the PNG if JPEG encoding is
  /// unavailable.
  Future<ShareCardImage> encode(ui.Image image) async {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) throw StateError('PNG encoding failed');
    final png = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    var best = ShareCardImage(
      bytes: png,
      width: image.width,
      height: image.height,
      format: ShareCardImageFormat.png,
    );
    if (png.length <= maxBytes) return best;
    for (final quality in jpegQualities) {
      final Uint8List jpeg;
      try {
        jpeg = await _jpeg(
          png,
          width: image.width,
          height: image.height,
          quality: quality,
        );
      } on Object {
        return best;
      }
      if (jpeg.isEmpty) return best;
      if (jpeg.length < best.bytes.length) {
        best = ShareCardImage(
          bytes: jpeg,
          width: image.width,
          height: image.height,
          format: ShareCardImageFormat.jpeg,
        );
      }
      if (jpeg.length <= maxBytes) break;
    }
    return best;
  }

  /// Writes [image] as `<baseName>.<ext>` in the temporary directory
  /// (overwriting the previous card of the same name).
  Future<String> write(ShareCardImage image, String baseName) async {
    final dir = await _tempDirectory();
    final file = File(p.join(dir.path, '$baseName.${image.format.extension}'));
    await file.writeAsBytes(image.bytes, flush: true);
    return file.path;
  }

  /// [capture] + [encode] + [write].
  Future<ShareCardFile> export(
    RenderRepaintBoundary boundary,
    ShareCardFormat format, {
    required String baseName,
  }) async {
    final image = await capture(boundary, format);
    try {
      final encoded = await encode(image);
      return ShareCardFile(
        path: await write(encoded, baseName),
        image: encoded,
      );
    } finally {
      image.dispose();
    }
  }
}

/// File name (without extension) for a journey's card: only safe chars.
String shareCardBaseName(String journeyId, ShareCardFormat format) {
  final safe = journeyId.replaceAll(RegExp('[^A-Za-z0-9_-]'), '');
  final id = safe.isEmpty ? 'journey' : safe;
  return 'ourney-$id-${format.name}';
}
