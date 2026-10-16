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

  /// Eyebrow on the first onboarding page (also the feature title).
  ///
  /// In vi, this message translates to:
  /// **'Chào mừng đến Ourney'**
  String get onboarding_title;

  /// Button on the last onboarding page that finishes onboarding.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu'**
  String get onboarding_start;

  /// Button that moves to the next onboarding page.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục'**
  String get onboarding_next;

  /// Top-right button that finishes onboarding immediately.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ qua'**
  String get onboarding_skip;

  /// Page 1 (value proposition) headline.
  ///
  /// In vi, this message translates to:
  /// **'Mỗi ngày một tấm. Thấy rõ mình tiến bộ.'**
  String get onboarding_valueTitle;

  /// Page 1 body.
  ///
  /// In vi, this message translates to:
  /// **'Ourney biến thói quen nhỏ thành một hành trình: giảm cân, học tiếng Anh, tập luyện hay một chuyến đi.'**
  String get onboarding_valueBody;

  /// Page 2 (how check-in works) headline.
  ///
  /// In vi, this message translates to:
  /// **'Check-in chỉ mất 5 giây'**
  String get onboarding_howTitle;

  /// Page 2, step 1.
  ///
  /// In vi, this message translates to:
  /// **'Mở app là chụp ngay'**
  String get onboarding_howStep1;

  /// Page 2, step 2.
  ///
  /// In vi, this message translates to:
  /// **'Gắn ảnh vào hành trình, thêm ghi chú hoặc số đo'**
  String get onboarding_howStep2;

  /// Page 2, step 3.
  ///
  /// In vi, this message translates to:
  /// **'Giữ chuỗi ngày và rủ bạn bè cùng làm'**
  String get onboarding_howStep3;

  /// Page 3 headline.
  ///
  /// In vi, this message translates to:
  /// **'Sẵn sàng chưa?'**
  String get onboarding_readyTitle;

  /// Page 3 body: permissions are asked in context (FR-A3).
  ///
  /// In vi, this message translates to:
  /// **'Ourney chỉ xin quyền camera và thông báo đúng lúc cần, không làm phiền bạn ngay bây giờ.'**
  String get onboarding_readyBody;

  /// Screen reader label of the page indicator.
  ///
  /// In vi, this message translates to:
  /// **'Trang {current} trên {total}'**
  String onboarding_pageSemantics(int current, int total);
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
