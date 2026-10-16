import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Why the camera could not start.
enum CameraFailure {
  /// The user denied access; the OS may still show the prompt again
  /// (Android before "don't ask again").
  permissionDenied,

  /// Denied earlier and the OS will not prompt again (iOS
  /// `CameraAccessDeniedWithoutPrompt`): only Settings can fix it.
  permissionDeniedPermanently,

  /// Parental controls / MDM (iOS `CameraAccessRestricted`).
  restricted,

  /// No camera hardware or no camera plugin (emulator, tests, desktop).
  unavailable,

  /// Anything else reported by the plugin.
  failed,
}

class CameraStartException implements Exception {
  const CameraStartException(this.failure, [this.detail]);

  final CameraFailure failure;
  final String? detail;

  @override
  String toString() => 'CameraStartException($failure, $detail)';
}

/// Flash setting cycled by the flash toggle (FR-C2).
enum FlashSetting { off, auto, on }

/// Minimal camera surface used by the capture screen. The plugin-backed
/// implementation is [PluginCameraSession]; tests inject fakes through
/// [cameraSessionFactoryProvider].
abstract interface class CameraSession {
  /// Opens a camera (back by default). Requests the OS permission on first
  /// use. Throws [CameraStartException].
  Future<void> start({bool front = false});

  bool get isReady;

  /// Whether a front and a back camera both exist.
  bool get canSwitch;

  /// Whether the current lens supports flash (front cameras usually not).
  bool get hasFlash;

  bool get isFront;

  /// Live preview, cropped to fill its parent.
  Widget buildPreview();

  Future<void> setFlash(FlashSetting flash);

  /// Switches between front and back. Throws [CameraStartException].
  Future<void> switchLens();

  /// Takes a photo and returns its file path.
  Future<String> takePicture();

  /// Releases the camera (app paused, tab hidden, screen disposed). [start]
  /// may be called again afterwards.
  Future<void> stop();
}

typedef CameraSessionFactory = CameraSession Function();

/// Creates the session used by `/capture`. Overridden in tests.
final cameraSessionFactoryProvider = Provider<CameraSessionFactory>(
  (ref) => PluginCameraSession.new,
);

/// [CameraSession] backed by the `camera` plugin (0.12.x).
class PluginCameraSession implements CameraSession {
  CameraController? _controller;
  List<CameraDescription>? _cameras;

  @override
  bool get isReady => _controller?.value.isInitialized ?? false;

  @override
  bool get canSwitch {
    final cams = _cameras ?? const [];
    return cams.any((c) => c.lensDirection == CameraLensDirection.front) &&
        cams.any((c) => c.lensDirection != CameraLensDirection.front);
  }

  @override
  bool get isFront =>
      _controller?.description.lensDirection == CameraLensDirection.front;

  // The plugin exposes no flash capability query; front lenses on phones
  // have no flash unit, so the toggle is hidden for them.
  @override
  bool get hasFlash => isReady && !isFront;

  @override
  Future<void> start({bool front = false}) async {
    try {
      _cameras ??= await availableCameras();
    } on MissingPluginException catch (e) {
      throw CameraStartException(CameraFailure.unavailable, e.message);
    } on CameraException catch (e) {
      throw _map(e);
    }
    final cams = _cameras!;
    if (cams.isEmpty) {
      throw const CameraStartException(CameraFailure.unavailable);
    }
    final wanted = front ? CameraLensDirection.front : CameraLensDirection.back;
    final desc = cams.firstWhere(
      (c) => c.lensDirection == wanted,
      orElse: () => cams.first,
    );
    await stop();
    final controller = CameraController(
      desc,
      // ~1080p: enough for the 1080px upload, faster to open than `max`.
      ResolutionPreset.veryHigh,
      // Photos only: never trigger the microphone permission prompt.
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    _controller = controller;
    try {
      await controller.initialize();
    } on CameraException catch (e) {
      _controller = null;
      await controller.dispose();
      throw _map(e);
    }
  }

  @override
  Widget buildPreview() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return const SizedBox.expand();
    final size = c.value.previewSize;
    if (size == null) return CameraPreview(c);
    // previewSize is in landscape orientation; the app is portrait-only.
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: size.height,
          height: size.width,
          child: CameraPreview(c),
        ),
      ),
    );
  }

  @override
  Future<void> setFlash(FlashSetting flash) async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    await c.setFlashMode(switch (flash) {
      FlashSetting.off => FlashMode.off,
      FlashSetting.auto => FlashMode.auto,
      FlashSetting.on => FlashMode.always,
    });
  }

  @override
  Future<void> switchLens() => start(front: !isFront);

  @override
  Future<String> takePicture() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      throw const CameraStartException(CameraFailure.failed, 'not ready');
    }
    try {
      final file = await c.takePicture();
      return file.path;
    } on CameraException catch (e) {
      throw CameraStartException(CameraFailure.failed, e.code);
    }
  }

  @override
  Future<void> stop() async {
    final c = _controller;
    _controller = null;
    await c?.dispose();
  }

  /// Error codes documented in the camera README ("Handling camera access
  /// permissions"); the Android CameraX implementation reuses them.
  static CameraStartException _map(CameraException e) {
    final failure = switch (e.code) {
      'CameraAccessDenied' => CameraFailure.permissionDenied,
      'CameraAccessDeniedWithoutPrompt' =>
        CameraFailure.permissionDeniedPermanently,
      'CameraAccessRestricted' => CameraFailure.restricted,
      _ => CameraFailure.failed,
    };
    return CameraStartException(failure, '${e.code}: ${e.description}');
  }
}
