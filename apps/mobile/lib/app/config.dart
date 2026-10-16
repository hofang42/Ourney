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
///
/// `--dart-define=SUPPORT_EMAIL=...` (optional) sets the support mailbox shown
/// on the contact page; absent or blank falls back to [defaultSupportEmail].
@immutable
class AppConfig {
  const AppConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    this.supportEmail = defaultSupportEmail,
  });

  /// Local-only configuration (no backend). Handy for tests.
  const AppConfig.localOnly()
    : supabaseUrl = '',
      supabaseAnonKey = '',
      supportEmail = defaultSupportEmail;

  factory AppConfig.fromEnvironment() => AppConfig(
    supabaseUrl: const String.fromEnvironment(supabaseUrlKey).trim(),
    supabaseAnonKey: const String.fromEnvironment(supabaseAnonKeyKey).trim(),
    supportEmail: resolveSupportEmail(
      const String.fromEnvironment(
        supportEmailKey,
        defaultValue: defaultSupportEmail,
      ),
    ),
  );

  static const supabaseUrlKey = 'SUPABASE_URL';
  static const supabaseAnonKeyKey = 'SUPABASE_ANON_KEY';
  static const supportEmailKey = 'SUPPORT_EMAIL';

  /// Placeholder mailbox used until the owner sets `SUPPORT_EMAIL`
  /// (docs/adr/0002-support-email-and-legal-text.md).
  static const defaultSupportEmail = 'support@ourney.app';

  /// Trims [raw]; a blank value (e.g. `SUPPORT_EMAIL=` in a define file)
  /// falls back to [defaultSupportEmail].
  static String resolveSupportEmail(String raw) {
    final trimmed = raw.trim();
    return trimmed.isEmpty ? defaultSupportEmail : trimmed;
  }

  final String supabaseUrl;

  /// The Supabase anon/publishable key. Public by design: RLS protects data.
  final String supabaseAnonKey;

  /// Mailbox shown (and used for mailto) on the contact page.
  final String supportEmail;

  /// True when no backend is configured (FR-A5).
  bool get localOnly => supabaseUrl.isEmpty || supabaseAnonKey.isEmpty;

  /// True when Supabase is configured and initialised at startup.
  bool get hasBackend => !localOnly;

  @override
  bool operator ==(Object other) =>
      other is AppConfig &&
      other.supabaseUrl == supabaseUrl &&
      other.supabaseAnonKey == supabaseAnonKey &&
      other.supportEmail == supportEmail;

  @override
  int get hashCode => Object.hash(supabaseUrl, supabaseAnonKey, supportEmail);

  @override
  String toString() =>
      'AppConfig(${localOnly ? 'local-only' : 'backend: $supabaseUrl'})';
}
