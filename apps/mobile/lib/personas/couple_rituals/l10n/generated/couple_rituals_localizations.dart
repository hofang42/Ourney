import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'couple_rituals_localizations_en.dart';
import 'couple_rituals_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of CoupleRitualsL10n
/// returned by `CoupleRitualsL10n.of(context)`.
///
/// Applications need to include `CoupleRitualsL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/couple_rituals_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: CoupleRitualsL10n.localizationsDelegates,
///   supportedLocales: CoupleRitualsL10n.supportedLocales,
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
/// be consistent with the languages listed in the CoupleRitualsL10n.supportedLocales
/// property.
abstract class CoupleRitualsL10n {
  CoupleRitualsL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static CoupleRitualsL10n of(BuildContext context) {
    return Localizations.of<CoupleRitualsL10n>(context, CoupleRitualsL10n)!;
  }

  static const LocalizationsDelegate<CoupleRitualsL10n> delegate =
      _CoupleRitualsL10nDelegate();

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
  /// **'Nghi thức đôi'**
  String get couple_rituals_name;

  /// Ngày thứ N của hành trình
  ///
  /// In vi, this message translates to:
  /// **'Ngày {day}'**
  String couple_rituals_dayLabel(int day);

  /// Chuỗi ngày liên tiếp
  ///
  /// In vi, this message translates to:
  /// **'Chuỗi {streak} ngày'**
  String couple_rituals_streakLabel(int streak);

  /// Số lần check-in
  ///
  /// In vi, this message translates to:
  /// **'{count} lần check-in'**
  String couple_rituals_checkInsLabel(int count);

  /// Tên mặc định của người dùng hiện tại
  ///
  /// In vi, this message translates to:
  /// **'Bạn'**
  String get couple_rituals_meDefault;

  /// Tên mặc định của thành viên còn lại
  ///
  /// In vi, this message translates to:
  /// **'Người đồng hành'**
  String get couple_rituals_partnerDefault;

  /// Ô chờ khi người kia chưa chụp hôm nay
  ///
  /// In vi, this message translates to:
  /// **'Đang chờ {name}'**
  String couple_rituals_waitingPartner(String name);

  /// Nhãn hướng dẫn trên nửa khung ngắm của màn chụp đôi
  ///
  /// In vi, this message translates to:
  /// **'Chụp nửa của bạn · Ghép trọn đôi'**
  String get couple_rituals_completePairHint;

  /// Nhãn trên nửa ảnh đã chụp của người kia
  ///
  /// In vi, this message translates to:
  /// **'{name} · Đã chụp'**
  String couple_rituals_partnerDoneBadge(String name);

  /// Tiêu đề tấm poster ghép ảnh của hai người
  ///
  /// In vi, this message translates to:
  /// **'{days} NGÀY · {moments} KHOẢNH KHẮC'**
  String couple_rituals_mosaicTitle(int days, int moments);

  /// Nút chia sẻ thiệp cặp đôi
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ câu chuyện của hai đứa'**
  String get couple_rituals_shareStoryButton;

  /// Nhãn ngày trên trục đôi
  ///
  /// In vi, this message translates to:
  /// **'NGÀY {day}'**
  String couple_rituals_dayHeader(String day);

  /// Nhãn ngày hôm nay trên trục đôi
  ///
  /// In vi, this message translates to:
  /// **'NGÀY {day} · HÔM NAY'**
  String couple_rituals_todayHeader(String day);
}

class _CoupleRitualsL10nDelegate
    extends LocalizationsDelegate<CoupleRitualsL10n> {
  const _CoupleRitualsL10nDelegate();

  @override
  Future<CoupleRitualsL10n> load(Locale locale) {
    return SynchronousFuture<CoupleRitualsL10n>(
      lookupCoupleRitualsL10n(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_CoupleRitualsL10nDelegate old) => false;
}

CoupleRitualsL10n lookupCoupleRitualsL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return CoupleRitualsL10nEn();
    case 'vi':
      return CoupleRitualsL10nVi();
  }

  throw FlutterError(
    'CoupleRitualsL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
