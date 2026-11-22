import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';

/// Whether the server accepts phone (SMS) sign-in. Probes the public
/// `GET /auth/v1/settings` endpoint once per app run (`external.phone`).
///
/// False in local-only mode and on any error, so the Phone option only shows
/// when it can really work (docs/runbooks/hosted-supabase.md, section 6.1).
/// Tests override it with `phoneAuthAvailableProvider.overrideWith(...)`.
final phoneAuthAvailableProvider = FutureProvider<bool>((ref) async {
  final config = ref.watch(appConfigProvider);
  if (config.localOnly) return false;
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
  try {
    final base = config.supabaseUrl.replaceAll(RegExp(r'/+$'), '');
    final request = await client
        .getUrl(Uri.parse('$base/auth/v1/settings'))
        .timeout(const Duration(seconds: 5));
    request.headers.set('apikey', config.supabaseAnonKey);
    final response = await request.close().timeout(const Duration(seconds: 5));
    if (response.statusCode != 200) {
      await response.drain<void>();
      return false;
    }
    final body = await response
        .transform(utf8.decoder)
        .join()
        .timeout(const Duration(seconds: 5));
    final json = jsonDecode(body);
    final external = json is Map ? json['external'] : null;
    return external is Map && external['phone'] == true;
  } on Object {
    return false;
  } finally {
    client.close(force: true);
  }
});
