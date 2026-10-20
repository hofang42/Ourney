import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'quiet_transformer_localizations_en.dart';
import 'quiet_transformer_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of QuietTransformerL10n
/// returned by `QuietTransformerL10n.of(context)`.
///
/// Applications need to include `QuietTransformerL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/quiet_transformer_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: QuietTransformerL10n.localizationsDelegates,
///   supportedLocales: QuietTransformerL10n.supportedLocales,
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
/// be consistent with the languages listed in the QuietTransformerL10n.supportedLocales
/// property.
abstract class QuietTransformerL10n {
  QuietTransformerL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static QuietTransformerL10n of(BuildContext context) {
    return Localizations.of<QuietTransformerL10n>(
      context,
      QuietTransformerL10n,
    )!;
  }

  static const LocalizationsDelegate<QuietTransformerL10n> delegate =
      _QuietTransformerL10nDelegate();

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
  /// **'Thay đổi thầm lặng'**
  String get quiet_transformer_name;

  /// Ngày thứ N của hành trình
  ///
  /// In vi, this message translates to:
  /// **'Ngày {day}'**
  String quiet_transformer_dayLabel(int day);

  /// Chuỗi ngày liên tiếp
  ///
  /// In vi, this message translates to:
  /// **'Chuỗi {streak} ngày'**
  String quiet_transformer_streakLabel(int streak);

  /// Số lần check-in
  ///
  /// In vi, this message translates to:
  /// **'{count} lần check-in'**
  String quiet_transformer_checkInsLabel(int count);
}

class _QuietTransformerL10nDelegate
    extends LocalizationsDelegate<QuietTransformerL10n> {
  const _QuietTransformerL10nDelegate();

  @override
  Future<QuietTransformerL10n> load(Locale locale) {
    return SynchronousFuture<QuietTransformerL10n>(
      lookupQuietTransformerL10n(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_QuietTransformerL10nDelegate old) => false;
}

QuietTransformerL10n lookupQuietTransformerL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return QuietTransformerL10nEn();
    case 'vi':
      return QuietTransformerL10nVi();
  }

  throw FlutterError(
    'QuietTransformerL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
