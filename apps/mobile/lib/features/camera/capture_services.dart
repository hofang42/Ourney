import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

/// Picks one photo from the library (FR-C3). Returns the file path, or null
/// when the user cancels.
abstract interface class GalleryPicker {
  Future<String?> pickPhoto();
}

class ImagePickerGallery implements GalleryPicker {
  ImagePickerGallery([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<String?> pickPhoto() async {
    // Compression to 1080px/q70 happens later in /checkin (FR-C5); the
    // picker only bounds very large originals.
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 4096,
      maxHeight: 4096,
      requestFullMetadata: false,
    );
    return file?.path;
  }
}

final galleryPickerProvider = Provider<GalleryPicker>(
  (ref) => ImagePickerGallery(),
);

/// Opens this app's page in the system Settings so the user can grant the
/// camera permission after denying it.
abstract interface class AppSettingsOpener {
  /// Whether [open] can work on this platform.
  bool get supported;

  /// Returns false when the page could not be opened.
  Future<bool> open();
}

/// iOS: `UIApplication.openSettingsURLString` is the `app-settings:` URL,
/// opened through url_launcher. Android has no URL for the app details page
/// (it needs `ACTION_APPLICATION_DETAILS_SETTINGS`, which url_launcher cannot
/// send), so the UI shows the Settings path as text there instead.
class UrlLauncherSettingsOpener implements AppSettingsOpener {
  const UrlLauncherSettingsOpener();

  static final Uri settingsUri = Uri.parse('app-settings:');

  @override
  bool get supported => defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Future<bool> open() async {
    if (!supported) return false;
    try {
      return await launchUrl(settingsUri);
    } on Object {
      return false;
    }
  }
}

final appSettingsOpenerProvider = Provider<AppSettingsOpener>(
  (ref) => const UrlLauncherSettingsOpener(),
);
