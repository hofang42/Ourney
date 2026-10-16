import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../features/auth/l10n/generated/auth_localizations.dart';
import '../features/camera/l10n/generated/camera_localizations.dart';
import '../features/checkin/l10n/generated/checkin_localizations.dart';
import '../features/groups/l10n/generated/groups_localizations.dart';
import '../features/journeys/l10n/generated/journeys_localizations.dart';
import '../features/onboarding/l10n/generated/onboarding_localizations.dart';
import '../features/profile/l10n/generated/profile_localizations.dart';
import '../features/reminders/l10n/generated/reminders_localizations.dart';
import '../features/safety/l10n/generated/safety_localizations.dart';
import '../features/share_card/l10n/generated/share_card_localizations.dart';
import '../l10n/generated/app_localizations.dart';

/// Supported locales in fallback order: Vietnamese is the default (NFR-6).
/// Flutter's default resolution falls back to the FIRST entry when the
/// device language is neither vi nor en.
const List<Locale> ourneySupportedLocales = [Locale('vi'), Locale('en')];

/// Every localization delegate of the app: shared strings
/// ([AppLocalizations]), one class per feature (`<Feature>L10n`, generated
/// from `lib/features/<feature>/l10n/`) and the Flutter framework ones.
const List<LocalizationsDelegate<Object?>> ourneyLocalizationsDelegates = [
  AppLocalizations.delegate,
  AuthL10n.delegate,
  OnboardingL10n.delegate,
  ProfileL10n.delegate,
  CameraL10n.delegate,
  CheckinL10n.delegate,
  JourneysL10n.delegate,
  GroupsL10n.delegate,
  ShareCardL10n.delegate,
  SafetyL10n.delegate,
  RemindersL10n.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];
