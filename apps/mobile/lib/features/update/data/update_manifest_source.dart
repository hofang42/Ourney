import 'package:ourney_core/ourney_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class UpdateManifestSource {
  Future<AppUpdateManifest> fetch(UpdatePlatform platform);
}

final class SupabaseUpdateManifestSource implements UpdateManifestSource {
  const SupabaseUpdateManifestSource(this._client);

  final SupabaseClient _client;

  @override
  Future<AppUpdateManifest> fetch(UpdatePlatform platform) async {
    final json = await _client
        .rpc<Object?>(
          'get_app_version_policy',
          params: {'p_platform': platform.name},
        )
        .timeout(const Duration(seconds: 4));
    final manifest = AppUpdateManifest.tryFromJson(json);
    if (manifest == null || manifest.platform != platform) {
      throw const FormatException('Invalid app version policy');
    }
    return manifest;
  }
}
