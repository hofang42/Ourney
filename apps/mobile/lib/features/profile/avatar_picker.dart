import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

enum AvatarSource { gallery, camera }

/// Lets the user pick an avatar and returns it as JPEG bytes, or null when
/// cancelled. The OS permission prompt (photos/camera) appears here, in
/// context, never during onboarding (FR-A3).
abstract interface class AvatarPicker {
  Future<Uint8List?> pick(AvatarSource source);
}

/// [AvatarPicker] backed by `image_picker` + `flutter_image_compress`
/// (re-encodes HEIC/PNG to a small JPEG, strips EXIF).
class ImagePickerAvatarPicker implements AvatarPicker {
  const ImagePickerAvatarPicker();

  static const int _size = 512;

  @override
  Future<Uint8List?> pick(AvatarSource source) async {
    final file = await ImagePicker().pickImage(
      source: source == AvatarSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      preferredCameraDevice: CameraDevice.front,
      requestFullMetadata: false,
    );
    if (file == null) return null;
    final raw = await file.readAsBytes();
    return FlutterImageCompress.compressWithList(
      raw,
      minWidth: _size,
      minHeight: _size,
      quality: 85,
    );
  }
}
