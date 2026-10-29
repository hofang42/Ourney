import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'onboarding_localizations_en.dart';
import 'onboarding_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of OnboardingL10n
/// returned by `OnboardingL10n.of(context)`.
///
/// Applications need to include `OnboardingL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/onboarding_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: OnboardingL10n.localizationsDelegates,
///   supportedLocales: OnboardingL10n.supportedLocales,
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
/// be consistent with the languages listed in the OnboardingL10n.supportedLocales
/// property.
abstract class OnboardingL10n {
  OnboardingL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static OnboardingL10n of(BuildContext context) {
    return Localizations.of<OnboardingL10n>(context, OnboardingL10n)!;
  }

  static const LocalizationsDelegate<OnboardingL10n> delegate =
      _OnboardingL10nDelegate();

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

  /// Feature title / app welcome (used in tests and accessibility).
  ///
  /// In vi, this message translates to:
  /// **'Chào mừng đến Ourney'**
  String get onboarding_title;

  /// Button that moves to the next onboarding page (and finishes on the last).
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục'**
  String get onboarding_next;

  /// Top-right button that finishes onboarding immediately.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ qua'**
  String get onboarding_skip;

  /// Chip on page 1 that switches the app language; shows the OTHER language's name.
  ///
  /// In vi, this message translates to:
  /// **'English'**
  String get onboarding_languageSwitch;

  /// Screen reader hint of the language chip.
  ///
  /// In vi, this message translates to:
  /// **'Đổi ngôn ngữ'**
  String get onboarding_languageSwitchHint;

  /// Page 1 headline.
  ///
  /// In vi, this message translates to:
  /// **'Từng tấm ảnh. Cả một câu chuyện.'**
  String get onboarding_page1Title;

  /// Page 1 body.
  ///
  /// In vi, this message translates to:
  /// **'Ghi lại hôm nay để thấy câu chuyện lớn dần.'**
  String get onboarding_page1Body;

  /// Page 2 headline.
  ///
  /// In vi, this message translates to:
  /// **'Hành trình nào cũng được. Một mình, cùng nhóm, hay cùng người thương.'**
  String get onboarding_page2Title;

  /// Page 2 body.
  ///
  /// In vi, this message translates to:
  /// **'Chọn cách đồng hành phù hợp với bạn.'**
  String get onboarding_page2Body;

  /// Page 3 headline.
  ///
  /// In vi, this message translates to:
  /// **'Biến hành trình thành thứ đáng để chia sẻ.'**
  String get onboarding_page3Title;

  /// Page 3 body.
  ///
  /// In vi, this message translates to:
  /// **'Tạo nên những bản tổng kết bạn muốn giữ mãi.'**
  String get onboarding_page3Body;

  /// Title on the sample recap card in the page 3 illustration.
  ///
  /// In vi, this message translates to:
  /// **'30 ngày yên tĩnh'**
  String get onboarding_recapTitle;

  /// Subtitle on the sample recap card.
  ///
  /// In vi, this message translates to:
  /// **'Đọc sách mỗi ngày · Tháng 10'**
  String get onboarding_recapSubtitle;

  /// Label on the sample story sticker in the page 3 illustration.
  ///
  /// In vi, this message translates to:
  /// **'Đáng để chia sẻ'**
  String get onboarding_recapShare;

  /// Screen reader label of the page indicator.
  ///
  /// In vi, this message translates to:
  /// **'Trang {current} trên {total}'**
  String onboarding_pageSemantics(int current, int total);

  /// Title of the camera permission sheet.
  ///
  /// In vi, this message translates to:
  /// **'Cho phép dùng camera'**
  String get onboarding_cameraTitle;

  /// Body of the camera permission sheet.
  ///
  /// In vi, this message translates to:
  /// **'Ourney cần camera để chụp ảnh hôm nay.'**
  String get onboarding_cameraBody;

  /// Primary button of the camera permission sheet.
  ///
  /// In vi, this message translates to:
  /// **'Cho phép camera'**
  String get onboarding_cameraAllow;

  /// Title of the notification permission sheet.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc bạn lúc {time} ngày mai nhé?'**
  String onboarding_nudgeTitle(String time);

  /// Primary button of the notification sheet.
  ///
  /// In vi, this message translates to:
  /// **'Bật nhắc nhở'**
  String get onboarding_nudgeAllow;

  /// Secondary button of the permission sheets.
  ///
  /// In vi, this message translates to:
  /// **'Để sau'**
  String get onboarding_notNow;
}

class _OnboardingL10nDelegate extends LocalizationsDelegate<OnboardingL10n> {
  const _OnboardingL10nDelegate();

  @override
  Future<OnboardingL10n> load(Locale locale) {
    return SynchronousFuture<OnboardingL10n>(lookupOnboardingL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_OnboardingL10nDelegate old) => false;
}

OnboardingL10n lookupOnboardingL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return OnboardingL10nEn();
    case 'vi':
      return OnboardingL10nVi();
  }

  throw FlutterError(
    'OnboardingL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
