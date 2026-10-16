import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// App name. Not translated.
  ///
  /// In vi, this message translates to:
  /// **'Ourney'**
  String get app_name;

  /// Bottom bar tab: list of journeys (docs/03: Journeys · Chụp · Nhóm).
  ///
  /// In vi, this message translates to:
  /// **'Journeys'**
  String get nav_journeys;

  /// Bottom bar center button: open the camera.
  ///
  /// In vi, this message translates to:
  /// **'Chụp'**
  String get nav_capture;

  /// Bottom bar tab: groups.
  ///
  /// In vi, this message translates to:
  /// **'Nhóm'**
  String get nav_groups;

  /// No description provided for @common_retry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get common_retry;

  /// No description provided for @common_cancel.
  ///
  /// In vi, this message translates to:
  /// **'Hủy'**
  String get common_cancel;

  /// No description provided for @common_ok.
  ///
  /// In vi, this message translates to:
  /// **'OK'**
  String get common_ok;

  /// No description provided for @common_close.
  ///
  /// In vi, this message translates to:
  /// **'Đóng'**
  String get common_close;

  /// No description provided for @common_save.
  ///
  /// In vi, this message translates to:
  /// **'Lưu'**
  String get common_save;

  /// No description provided for @common_loading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải…'**
  String get common_loading;

  /// No description provided for @common_errorGeneric.
  ///
  /// In vi, this message translates to:
  /// **'Có lỗi xảy ra. Thử lại nhé.'**
  String get common_errorGeneric;

  /// No description provided for @common_offline.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đang offline. Ourney sẽ tự đồng bộ khi có mạng.'**
  String get common_offline;

  /// No description provided for @empty_default_title.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có gì ở đây'**
  String get empty_default_title;

  /// No description provided for @streak_days.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{{count} ngày}}'**
  String streak_days(int count);

  /// No description provided for @streak_semantics.
  ///
  /// In vi, this message translates to:
  /// **'Chuỗi {count, plural, other{{count} ngày}}'**
  String streak_semantics(int count);

  /// No description provided for @streak_atRisk.
  ///
  /// In vi, this message translates to:
  /// **'Sắp mất chuỗi'**
  String get streak_atRisk;

  /// Local-only mode (FR-A5): shown where a feature needs the backend, e.g. groups.
  ///
  /// In vi, this message translates to:
  /// **'Cần kết nối máy chủ'**
  String get needsServer_title;

  /// No description provided for @needsServer_message.
  ///
  /// In vi, this message translates to:
  /// **'Bản này đang chạy chế độ chỉ trên máy. Hành trình một mình vẫn dùng bình thường, còn nhóm thì cần máy chủ.'**
  String get needsServer_message;

  /// No description provided for @placeholder_comingSoon.
  ///
  /// In vi, this message translates to:
  /// **'Sắp ra mắt'**
  String get placeholder_comingSoon;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
