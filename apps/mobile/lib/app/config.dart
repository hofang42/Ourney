import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Build-time configuration, read from `--dart-define`:
///
///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
///
/// When either value is empty the app runs in local-only mode:
/// `Supabase.initialize` is skipped and nothing leaves the device.
class AppConfig {
  const AppConfig({required this.supabaseUrl, required this.supabaseAnonKey});

  factory AppConfig.fromEnvironment() => const AppConfig(
        supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
        supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
      );

  final String supabaseUrl;
  final String supabaseAnonKey;

  bool get localOnly => supabaseUrl.isEmpty || supabaseAnonKey.isEmpty;
}

final appConfigProvider =
    Provider<AppConfig>((ref) => AppConfig.fromEnvironment());
