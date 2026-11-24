import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../app/providers.dart';
import '../domain/widget_snapshot.dart';
import 'widget_bridge_gateway.dart';

/// Directory name inside the temporary directory holding prepared widget
/// thumbnails (`<temp>/widget_thumbs/`).
const String kWidgetThumbsTempDirName = 'widget_thumbs';

/// Gaussian blur sigma applied in Dart before a privacy-blurred thumbnail is
/// handed across the bridge (§7.1).
const double kWidgetPrivacyBlurSigma = 18.0;

/// Prepares downsampled (`<= 320px` hero, `<= 160px` grid/avatar) and
/// pre-blurred JPEGs/images in `<temp>/widget_thumbs/` before handing their
/// paths to `MethodChannel('ourney/widgets').invokeMethod('syncSnapshot')`
/// (§4.2, §7.1, §9).
abstract interface class WidgetThumbPreparer {
  /// Resolves and prepares [requests], returning only the entries whose source
  /// files are available on local disk. Never throws.
  Future<List<WidgetThumbPayload>> prepare(List<WidgetThumbRequest> requests);

  /// Wipes all cached files under `<temp>/widget_thumbs/` (called on sign-out /
  /// account reset). Never throws.
  Future<void> clearCache();
}

/// Default on-device [WidgetThumbPreparer].
class LocalWidgetThumbPreparer implements WidgetThumbPreparer {
  const LocalWidgetThumbPreparer(
    this._ref, {
    this.tempDirProvider,
    this.enableNativeTransforms = true,
  });

  final Ref _ref;
  final Future<Directory> Function()? tempDirProvider;

  /// When `false` (e.g. in pure unit tests without a running Flutter engine
  /// image codec), skips `FlutterImageCompress` / `dart:ui` re-encoding and
  /// passes the resolved local file path directly.
  final bool enableNativeTransforms;

  static const Duration _resolveTimeout = Duration(seconds: 2);

  Future<Directory?> _thumbDir({bool create = true}) async {
    try {
      final base =
          await (tempDirProvider?.call() ?? getTemporaryDirectory());
      final dir = Directory(p.join(base.path, kWidgetThumbsTempDirName));
      if (create && !dir.existsSync()) {
        await dir.create(recursive: true);
      }
      return dir;
    } on Object {
      return null;
    }
  }

  Future<String?> _resolveLocalSource(WidgetThumbRequest req) async {
    final local = req.localFilePath;
    if (local != null && local.isNotEmpty) {
      try {
        if (File(local).existsSync()) return local;
      } on Object {
        // Fall through to storagePath lookup.
      }
    }
    if (req.storagePath.isNotEmpty) {
      try {
        if (File(req.storagePath).existsSync()) return req.storagePath;
      } on Object {
        // Not a direct file path; query MediaStore below.
      }
      try {
        final store = _ref.read(mediaStoreProvider);
        final resolved = await store
            .localFileFor(req.storagePath)
            .timeout(_resolveTimeout);
        if (resolved.isNotEmpty && File(resolved).existsSync()) {
          return resolved;
        }
      } on Object {
        return null;
      }
    }
    return null;
  }

  @override
  Future<List<WidgetThumbPayload>> prepare(
    List<WidgetThumbRequest> requests,
  ) async {
    if (requests.isEmpty) return const [];
    final dir = await _thumbDir();
    final out = <WidgetThumbPayload>[];

    for (final req in requests) {
      final sourcePath = await _resolveLocalSource(req);
      if (sourcePath == null) continue;

      var targetPath = sourcePath;
      if (enableNativeTransforms && dir != null) {
        final preparedFile = File(p.join(dir.path, req.id));
        if (preparedFile.existsSync() && preparedFile.lengthSync() > 0) {
          targetPath = preparedFile.path;
        } else if (req.blur) {
          final blurredPath = await _renderBlurredImage(
            sourcePath: sourcePath,
            targetPath: preparedFile.path,
            maxSide: req.maxSide,
          );
          if (blurredPath != null) {
            targetPath = blurredPath;
          }
        } else {
          final compressedPath = await _downsampleIfNeeded(
            sourcePath: sourcePath,
            targetPath: preparedFile.path,
            maxSide: req.maxSide,
          );
          targetPath = compressedPath ?? sourcePath;
        }
      }

      out.add(
        WidgetThumbPayload(
          id: req.id,
          sourcePath: targetPath,
          maxSide: req.maxSide,
          blur: req.blur,
        ),
      );
    }

    return out;
  }

  Future<String?> _downsampleIfNeeded({
    required String sourcePath,
    required String targetPath,
    required int maxSide,
  }) async {
    try {
      final result = await FlutterImageCompress.compressAndGetFile(
        sourcePath,
        targetPath,
        minWidth: maxSide,
        minHeight: maxSide,
        quality: 65,
      );
      if (result != null && File(result.path).existsSync()) {
        return result.path;
      }
    } on Object {
      // Plugin unavailable in test environment: fall back to sourcePath.
    }
    return null;
  }

  /// Renders a pre-blurred (`sigma = 18`) downsampled image in Dart so raw
  /// unblurred weight-loss or privacy-blurred photos never touch the shared
  /// widget container (§7.1).
  Future<String?> _renderBlurredImage({
    required String sourcePath,
    required String targetPath,
    required int maxSide,
  }) async {
    try {
      final bytes = await File(sourcePath).readAsBytes();
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: maxSide,
      );
      final frame = await codec.getNextFrame();
      final srcImage = frame.image;
      final srcW = srcImage.width.toDouble();
      final srcH = srcImage.height.toDouble();
      final scale = math.min(1.0, maxSide / math.min(srcW, srcH));
      final dstW = math.max(1, (srcW * scale).round());
      final dstH = math.max(1, (srcH * scale).round());

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(
        recorder,
        ui.Rect.fromLTWH(0, 0, dstW.toDouble(), dstH.toDouble()),
      );
      final paint = ui.Paint()
        ..imageFilter = ui.ImageFilter.blur(
          sigmaX: kWidgetPrivacyBlurSigma,
          sigmaY: kWidgetPrivacyBlurSigma,
          tileMode: ui.TileMode.clamp,
        );
      canvas.drawImageRect(
        srcImage,
        ui.Rect.fromLTWH(0, 0, srcW, srcH),
        ui.Rect.fromLTWH(0, 0, dstW.toDouble(), dstH.toDouble()),
        paint,
      );
      final picture = recorder.endRecording();
      final blurredImage = await picture.toImage(dstW, dstH);
      final byteData = await blurredImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      srcImage.dispose();
      blurredImage.dispose();
      if (byteData == null) return null;

      final pngBytes = byteData.buffer.asUint8List();
      final outFile = File(targetPath);
      await outFile.writeAsBytes(pngBytes, flush: true);
      return outFile.path;
    } on Object {
      return null;
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      final dir = await _thumbDir(create: false);
      if (dir != null && dir.existsSync()) {
        await dir.delete(recursive: true);
      }
    } on Object {
      // Best-effort cleanup.
    }
  }
}

final widgetThumbPreparerProvider = Provider<WidgetThumbPreparer>(
  LocalWidgetThumbPreparer.new,
);
