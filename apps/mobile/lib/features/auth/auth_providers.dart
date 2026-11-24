import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';

/// Whether the server accepts phone (SMS) sign-in. Probes the public
/// `GET /auth/v1/settings` endpoint (`external.phone`).
///
/// False in local-only mode. Network and 5xx failures throw instead of being
/// cached as `false`, and `autoDispose` re-probes when `/auth` opens again
/// (docs/runbooks/hosted-supabase.md, section 6.1).
/// Tests override it with `phoneAuthAvailableProvider.overrideWith(...)`.
final phoneAuthAvailableProvider = FutureProvider.autoDispose<bool>(
  (ref) async {
    final config = ref.watch(appConfigProvider);
    if (config.localOnly) return false;
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      final base = config.supabaseUrl.replaceAll(RegExp(r'/+$'), '');
      final request = await client
          .getUrl(Uri.parse('$base/auth/v1/settings'))
          .timeout(const Duration(seconds: 5));
      request.headers.set('apikey', config.supabaseAnonKey);
      final response = await request.close().timeout(
        const Duration(seconds: 5),
      );
      if (response.statusCode >= 500) {
        await response.drain<void>();
        throw HttpException('settings probe HTTP ${response.statusCode}');
      }
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
    } finally {
      client.close(force: true);
    }
  },
  retry: (_, _) => null,
);
