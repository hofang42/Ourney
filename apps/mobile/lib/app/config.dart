import 'package:flutter/foundation.dart';

/// Build-time configuration, read from `--dart-define` (or
/// `--dart-define-from-file=env.json`, see `env.example.json`):
///
///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
///
/// When either value is missing the app runs in **local-only mode** (FR-A5):
/// `Supabase.initialize` is skipped, nothing leaves the device, solo journeys
/// work and group features show a "needs server" state.
///
/// Consume it through `appConfigProvider` (lib/app/providers.dart), never by
/// calling [AppConfig.fromEnvironment] from feature code, so tests can
/// override it.
@immutable
class AppConfig {
  const AppConfig({required this.supabaseUrl, required this.supabaseAnonKey});

  /// Local-only configuration (no backend). Handy for tests.
  const AppConfig.localOnly() : supabaseUrl = '', supabaseAnonKey = '';

  factory AppConfig.fromEnvironment() => AppConfig(
    supabaseUrl: const String.fromEnvironment(supabaseUrlKey).trim(),
    supabaseAnonKey: const String.fromEnvironment(supabaseAnonKeyKey).trim(),
  );

  static const supabaseUrlKey = 'SUPABASE_URL';
  static const supabaseAnonKeyKey = 'SUPABASE_ANON_KEY';

  final String supabaseUrl;

  /// The Supabase anon/publishable key. Public by design: RLS protects data.
  final String supabaseAnonKey;

  /// True when no backend is configured (FR-A5).
  bool get localOnly => supabaseUrl.isEmpty || supabaseAnonKey.isEmpty;

  /// True when Supabase is configured and initialised at startup.
  bool get hasBackend => !localOnly;

  @override
  bool operator ==(Object other) =>
      other is AppConfig &&
      other.supabaseUrl == supabaseUrl &&
      other.supabaseAnonKey == supabaseAnonKey;

  @override
  int get hashCode => Object.hash(supabaseUrl, supabaseAnonKey);

  @override
  String toString() =>
      'AppConfig(${localOnly ? 'local-only' : 'backend: $supabaseUrl'})';
}
