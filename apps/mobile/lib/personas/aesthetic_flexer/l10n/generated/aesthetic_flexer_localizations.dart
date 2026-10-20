import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'aesthetic_flexer_localizations_en.dart';
import 'aesthetic_flexer_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AestheticFlexerL10n
/// returned by `AestheticFlexerL10n.of(context)`.
///
/// Applications need to include `AestheticFlexerL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/aesthetic_flexer_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AestheticFlexerL10n.localizationsDelegates,
///   supportedLocales: AestheticFlexerL10n.supportedLocales,
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
/// be consistent with the languages listed in the AestheticFlexerL10n.supportedLocales
/// property.
abstract class AestheticFlexerL10n {
  AestheticFlexerL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AestheticFlexerL10n of(BuildContext context) {
    return Localizations.of<AestheticFlexerL10n>(context, AestheticFlexerL10n)!;
  }

  static const LocalizationsDelegate<AestheticFlexerL10n> delegate =
      _AestheticFlexerL10nDelegate();

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

  /// Tên phong cách, hiện ở nhãn đầu màn
  ///
  /// In vi, this message translates to:
  /// **'Khoe nhịp tập'**
  String get aesthetic_flexer_name;

  /// Ngày thứ N của hành trình
  ///
  /// In vi, this message translates to:
  /// **'Ngày {day}'**
  String aesthetic_flexer_dayLabel(int day);

  /// Chuỗi ngày liên tiếp
  ///
  /// In vi, this message translates to:
  /// **'Chuỗi {streak} ngày'**
  String aesthetic_flexer_streakLabel(int streak);

  /// Số lần check-in
  ///
  /// In vi, this message translates to:
  /// **'{count} lần check-in'**
  String aesthetic_flexer_checkInsLabel(int count);
}

class _AestheticFlexerL10nDelegate
    extends LocalizationsDelegate<AestheticFlexerL10n> {
  const _AestheticFlexerL10nDelegate();

  @override
  Future<AestheticFlexerL10n> load(Locale locale) {
    return SynchronousFuture<AestheticFlexerL10n>(
      lookupAestheticFlexerL10n(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AestheticFlexerL10nDelegate old) => false;
}

AestheticFlexerL10n lookupAestheticFlexerL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AestheticFlexerL10nEn();
    case 'vi':
      return AestheticFlexerL10nVi();
  }

  throw FlutterError(
    'AestheticFlexerL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
