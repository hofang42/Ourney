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

  /// Top-right button that finishes onboarding immediately.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ qua'**
  String get onboarding_skip;

  /// Title of the camera permission sheet.
  ///
  /// In vi, this message translates to:
  /// **'cho ourney dùng camera.'**
  String get onboarding_cameraTitle;

  /// Body of the camera permission sheet.
  ///
  /// In vi, this message translates to:
  /// **'Để chụp tấm đầu tiên của hành trình. Ảnh chỉ hiện với người trong hành trình đó.'**
  String get onboarding_cameraBody;

  /// Primary button of the camera permission sheet.
  ///
  /// In vi, this message translates to:
  /// **'Cho phép'**
  String get onboarding_cameraAllow;

  /// Title of the notification permission sheet.
  ///
  /// In vi, this message translates to:
  /// **'để ourney nhắc nhẹ vào giờ bạn chọn.'**
  String get onboarding_nudgeTitle;

  /// Primary button of the notification sheet.
  ///
  /// In vi, this message translates to:
  /// **'Cho phép'**
  String get onboarding_nudgeAllow;

  /// Secondary button of the permission sheets.
  ///
  /// In vi, this message translates to:
  /// **'để sau vậy.'**
  String get onboarding_notNow;

  /// Quiz progress label.
  ///
  /// In vi, this message translates to:
  /// **'Câu {n}/3'**
  String onboarding_quizStep(int n);

  /// Back button semantics.
  ///
  /// In vi, this message translates to:
  /// **'Câu trước'**
  String get onboarding_quizBack;

  /// Quiz question 1.
  ///
  /// In vi, this message translates to:
  /// **'bạn đang muốn kiên trì điều gì?'**
  String get onboarding_quizQ1;

  /// Quiz question 2.
  ///
  /// In vi, this message translates to:
  /// **'đi một mình hay cùng nhóm?'**
  String get onboarding_quizQ2;

  /// Quiz question 3.
  ///
  /// In vi, this message translates to:
  /// **'bạn muốn chụp vào khung giờ nào?'**
  String get onboarding_quizQ3;

  /// Goal option.
  ///
  /// In vi, this message translates to:
  /// **'Giảm cân'**
  String get onboarding_goalWeight;

  /// Goal option.
  ///
  /// In vi, this message translates to:
  /// **'Học tiếng Anh'**
  String get onboarding_goalEnglish;

  /// Goal option.
  ///
  /// In vi, this message translates to:
  /// **'Tập luyện'**
  String get onboarding_goalWorkout;

  /// Goal option.
  ///
  /// In vi, this message translates to:
  /// **'Một chuyến đi'**
  String get onboarding_goalTrip;

  /// Goal option.
  ///
  /// In vi, this message translates to:
  /// **'Nghi thức của hai đứa'**
  String get onboarding_goalCouple;

  /// Goal option.
  ///
  /// In vi, this message translates to:
  /// **'Một thói quen nhỏ'**
  String get onboarding_goalHabit;

  /// Company option.
  ///
  /// In vi, this message translates to:
  /// **'Một mình'**
  String get onboarding_whoSolo;

  /// Company hint.
  ///
  /// In vi, this message translates to:
  /// **'chỉ mình bạn thấy'**
  String get onboarding_whoSoloHint;

  /// Company option.
  ///
  /// In vi, this message translates to:
  /// **'Rủ nhóm bạn'**
  String get onboarding_whoGroup;

  /// Company hint.
  ///
  /// In vi, this message translates to:
  /// **'tối đa 10 người'**
  String get onboarding_whoGroupHint;

  /// Company option.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ hai đứa'**
  String get onboarding_whoCouple;

  /// Company hint.
  ///
  /// In vi, this message translates to:
  /// **'ghép đôi, chỉ hai người'**
  String get onboarding_whoCoupleHint;

  /// Shown when the couple option is chosen.
  ///
  /// In vi, this message translates to:
  /// **'Ourney sẽ dùng phong cách Hai đứa mình'**
  String get onboarding_coupleStyleHint;

  /// Reminder option.
  ///
  /// In vi, this message translates to:
  /// **'Sáng sớm'**
  String get onboarding_remMorning;

  /// Reminder option.
  ///
  /// In vi, this message translates to:
  /// **'Trưa'**
  String get onboarding_remNoon;

  /// Reminder option.
  ///
  /// In vi, this message translates to:
  /// **'Tối muộn'**
  String get onboarding_remNight;

  /// Reminder hint.
  ///
  /// In vi, this message translates to:
  /// **'gợi ý nhắc lúc {time}'**
  String onboarding_remHint(String time);

  /// Result card heading.
  ///
  /// In vi, this message translates to:
  /// **'hành trình đầu tiên của bạn.'**
  String get onboarding_quizResultTitle;

  /// Result card chip.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc {time}'**
  String onboarding_quizRemind(String time);

  /// Quiz continue button.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục'**
  String get onboarding_quizContinue;

  /// Quiz final button.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu thôi'**
  String get onboarding_quizStart;

  /// Splash tagline 1 (rotates with 2 and 3).
  ///
  /// In vi, this message translates to:
  /// **'Góp tấm hình,'**
  String get onboarding_splashTagline1;

  /// Splash tagline 2.
  ///
  /// In vi, this message translates to:
  /// **'giữ nhịp mình'**
  String get onboarding_splashTagline2;

  /// Splash tagline 3.
  ///
  /// In vi, this message translates to:
  /// **'đi cùng nhau.'**
  String get onboarding_splashTagline3;

  /// Screen reader label of the first-launch splash (tap to continue).
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu'**
  String get onboarding_splashStart;

  /// Screen reader label of the returning-user splash.
  ///
  /// In vi, this message translates to:
  /// **'Đang mở'**
  String get onboarding_splashOpening;

  /// Result card title when the couple option is chosen.
  ///
  /// In vi, this message translates to:
  /// **'hai đứa mình.'**
  String get onboarding_resultCouple;

  /// Close button of the permission sheets.
  ///
  /// In vi, this message translates to:
  /// **'Đóng'**
  String get onboarding_permissionClose;

  /// Body of the notification permission sheet.
  ///
  /// In vi, this message translates to:
  /// **'Bật nhắc để Ourney gửi lời nhắc lúc {time}. Có thể trễ tuỳ máy.'**
  String onboarding_nudgeBody(String time);

  /// First quiz question: skip the quiz and go to sign-in.
  ///
  /// In vi, this message translates to:
  /// **'Đã có tài khoản? Đăng nhập'**
  String get onboarding_haveAccount;
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
