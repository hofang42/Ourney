// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'update_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class UpdateL10nEn extends UpdateL10n {
  UpdateL10nEn([String locale = 'en']) : super(locale);

  @override
  String update_hubTitle(String version) {
    return 'Ourney $version is ready';
  }

  @override
  String get update_hubFallbackSub =>
      'Update whenever you have a moment to try the latest improvements.';

  @override
  String get update_hubAction => 'View';

  @override
  String get update_hubDismissLabel => 'Hide notice for this update';

  @override
  String update_softEyebrow(String version) {
    return 'NEW VERSION · $version';
  }

  @override
  String update_softTitle(String version) {
    return 'Ourney $version is here';
  }

  @override
  String get update_softSubtitle =>
      'A few thoughtful improvements are ready for your journeys. Update now or whenever suits you.';

  @override
  String get update_ctaUpdate => 'Update now';

  @override
  String get update_ctaLater => 'Not now';

  @override
  String update_ctaSkipVersion(String version) {
    return 'Skip version $version';
  }

  @override
  String get update_androidInstallHint =>
      'Once downloaded, open Ourney.apk from your notifications to install. Your journeys and photos stay intact.';

  @override
  String update_gateEyebrow(String version) {
    return 'REQUIRED UPDATE · $version';
  }

  @override
  String get update_gateTitle => 'Update Ourney to continue';

  @override
  String update_gateBody(String installed, String latest) {
    return 'Version $installed needs an update to $latest to stay safely in sync. All of your journeys and photos remain intact on your device.';
  }

  @override
  String update_gateIosManualHint(String latest) {
    return 'Please install Ourney $latest via TestFlight or your installation tool to continue.';
  }

  @override
  String update_gateWhatsNewToggle(String version) {
    return 'See what\'s new in $version';
  }

  @override
  String get update_gateOfflineNotice =>
      'You\'re offline. Connect to the internet to download the update or check again.';

  @override
  String get update_ctaRetryCheck => 'Check again';

  @override
  String get update_ctaContactSupport => 'Need help updating?';

  @override
  String get update_launchFailed =>
      'Couldn\'t open your browser. You can download the update at ourney.tech.';

  @override
  String update_whatsNewEyebrow(String version) {
    return 'UPDATED · $version';
  }

  @override
  String update_whatsNewTitle(String version) {
    return 'What\'s new in Ourney $version';
  }

  @override
  String get update_whatsNewDone => 'Got it';
}
