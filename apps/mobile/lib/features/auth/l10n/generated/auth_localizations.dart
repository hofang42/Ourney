import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'auth_localizations_en.dart';
import 'auth_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AuthL10n
/// returned by `AuthL10n.of(context)`.
///
/// Applications need to include `AuthL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/auth_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AuthL10n.localizationsDelegates,
///   supportedLocales: AuthL10n.supportedLocales,
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
/// be consistent with the languages listed in the AuthL10n.supportedLocales
/// property.
abstract class AuthL10n {
  AuthL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AuthL10n of(BuildContext context) {
    return Localizations.of<AuthL10n>(context, AuthL10n)!;
  }

  static const LocalizationsDelegate<AuthL10n> delegate = _AuthL10nDelegate();

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

  /// Title of the code step.
  ///
  /// In vi, this message translates to:
  /// **'nhập mã.'**
  String get auth_codeTitle;

  /// Helper under the code step.
  ///
  /// In vi, this message translates to:
  /// **'Không thấy thư? Xem mục thư rác hoặc quảng cáo.'**
  String get auth_otpHelper;

  /// Title of the sign-in screen (email step).
  ///
  /// In vi, this message translates to:
  /// **'đăng nhập.'**
  String get auth_title;

  /// Explains email OTP sign-in (FR-A1).
  ///
  /// In vi, this message translates to:
  /// **'Nhập email, Ourney gửi bạn mã 6 số. Không cần mật khẩu.'**
  String get auth_subtitle;

  /// Email field label.
  ///
  /// In vi, this message translates to:
  /// **'Email'**
  String get auth_emailLabel;

  /// Email field placeholder.
  ///
  /// In vi, this message translates to:
  /// **'ban@vidu.com'**
  String get auth_emailHint;

  /// Validation error for the email field.
  ///
  /// In vi, this message translates to:
  /// **'Email này chưa đúng định dạng.'**
  String get auth_emailInvalid;

  /// Button that sends the OTP email.
  ///
  /// In vi, this message translates to:
  /// **'Gửi mã'**
  String get auth_sendCode;

  /// Button label while the OTP is being sent.
  ///
  /// In vi, this message translates to:
  /// **'Đang gửi…'**
  String get auth_sending;

  /// Below the OTP title.
  ///
  /// In vi, this message translates to:
  /// **'Mã 6 số đã được gửi tới {email}.'**
  String auth_codeSentTo(String email);

  /// OTP field label.
  ///
  /// In vi, this message translates to:
  /// **'Mã 6 số'**
  String get auth_codeLabel;

  /// Validation error for the OTP field.
  ///
  /// In vi, this message translates to:
  /// **'Mã gồm đúng 6 chữ số.'**
  String get auth_codeInvalidFormat;

  /// Button that verifies the OTP.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận'**
  String get auth_verify;

  /// Button label while the OTP is being verified.
  ///
  /// In vi, this message translates to:
  /// **'Đang kiểm tra…'**
  String get auth_verifying;

  /// Resend OTP button.
  ///
  /// In vi, this message translates to:
  /// **'Gửi lại mã'**
  String get auth_resend;

  /// Resend OTP button during the cooldown.
  ///
  /// In vi, this message translates to:
  /// **'Gửi lại sau {seconds} giây'**
  String auth_resendIn(int seconds);

  /// Confirmation after resending the OTP.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi mã mới. Kiểm tra hộp thư nhé.'**
  String get auth_codeResent;

  /// Go back to the email step.
  ///
  /// In vi, this message translates to:
  /// **'Đổi email'**
  String get auth_changeEmail;

  /// OTP rejected (invalid / expired).
  ///
  /// In vi, this message translates to:
  /// **'Mã không đúng hoặc đã hết hạn. Kiểm tra lại hoặc gửi mã mới.'**
  String get auth_errorWrongCode;

  /// Too many OTP requests or attempts.
  ///
  /// In vi, this message translates to:
  /// **'Bạn thử hơi nhiều rồi. Đợi một chút rồi thử lại nhé.'**
  String get auth_errorRateLimited;

  /// No connection.
  ///
  /// In vi, this message translates to:
  /// **'Không có mạng. Kết nối lại rồi thử nhé.'**
  String get auth_errorOffline;

  /// Any other sign-in error.
  ///
  /// In vi, this message translates to:
  /// **'Có lỗi xảy ra. Thử lại nhé.'**
  String get auth_errorGeneric;

  /// Small label above the sign-in headline.
  ///
  /// In vi, this message translates to:
  /// **'OURNEY'**
  String get auth_eyebrow;

  /// Small label above the headline on the code step.
  ///
  /// In vi, this message translates to:
  /// **'KIỂM TRA EMAIL'**
  String get auth_eyebrowCheck;

  /// Footer link to the terms.
  ///
  /// In vi, this message translates to:
  /// **'Điều khoản'**
  String get auth_terms;

  /// Footer link to the privacy policy.
  ///
  /// In vi, this message translates to:
  /// **'Quyền riêng tư'**
  String get auth_privacy;

  /// Screen reader label of one OTP digit box.
  ///
  /// In vi, this message translates to:
  /// **'Chữ số {n} trên 6'**
  String auth_digitSemantics(int n);

  /// Sign-in method tab.
  ///
  /// In vi, this message translates to:
  /// **'Email'**
  String get auth_tabEmail;

  /// Sign-in method tab.
  ///
  /// In vi, this message translates to:
  /// **'Số điện thoại'**
  String get auth_tabPhone;

  /// Phone field label.
  ///
  /// In vi, this message translates to:
  /// **'Số điện thoại'**
  String get auth_phoneLabel;

  /// Phone field hint (Vietnamese mobile without the leading 0).
  ///
  /// In vi, this message translates to:
  /// **'912 345 678'**
  String get auth_phoneHint;

  /// Country prefix inside the phone field.
  ///
  /// In vi, this message translates to:
  /// **'+84'**
  String get auth_phonePrefix;

  /// Phone validation error.
  ///
  /// In vi, this message translates to:
  /// **'Số điện thoại Việt Nam cần 9–10 số sau 0 hoặc +84.'**
  String get auth_phoneInvalid;

  /// Subtitle of the phone form.
  ///
  /// In vi, this message translates to:
  /// **'Nhập số điện thoại, Ourney gửi mã 6 số qua SMS.'**
  String get auth_phoneSubtitle;

  /// Button: send an SMS code.
  ///
  /// In vi, this message translates to:
  /// **'Gửi mã SMS'**
  String get auth_sendSms;

  /// Below the OTP title for phone.
  ///
  /// In vi, this message translates to:
  /// **'Mã 6 số đã gửi qua SMS tới {phone}.'**
  String auth_smsSentTo(String phone);

  /// Back to the phone form.
  ///
  /// In vi, this message translates to:
  /// **'Đổi số điện thoại'**
  String get auth_changePhone;

  /// Password field label.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu'**
  String get auth_passwordLabel;

  /// New password field label.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu mới'**
  String get auth_newPasswordLabel;

  /// Password validation error.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu cần ít nhất 8 ký tự.'**
  String get auth_passwordShort;

  /// Semantics of the reveal toggle.
  ///
  /// In vi, this message translates to:
  /// **'Hiện mật khẩu'**
  String get auth_showPassword;

  /// Semantics of the reveal toggle.
  ///
  /// In vi, this message translates to:
  /// **'Ẩn mật khẩu'**
  String get auth_hidePassword;

  /// Button: sign in with a password.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập'**
  String get auth_signIn;

  /// Link to switch to password mode.
  ///
  /// In vi, this message translates to:
  /// **'Dùng mật khẩu'**
  String get auth_usePassword;

  /// Link to switch to emailed-code mode.
  ///
  /// In vi, this message translates to:
  /// **'Dùng mã đăng nhập'**
  String get auth_useCode;

  /// Link to the reset flow.
  ///
  /// In vi, this message translates to:
  /// **'Quên mật khẩu?'**
  String get auth_forgot;

  /// Link to sign-up.
  ///
  /// In vi, this message translates to:
  /// **'Tạo tài khoản bằng mật khẩu'**
  String get auth_createAccount;

  /// Link back to sign-in.
  ///
  /// In vi, this message translates to:
  /// **'Đã có tài khoản? Đăng nhập'**
  String get auth_haveAccount;

  /// Sign-up title.
  ///
  /// In vi, this message translates to:
  /// **'tạo tài khoản.'**
  String get auth_signUpTitle;

  /// Sign-up subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Dùng email và mật khẩu của bạn. Có thể cần xác nhận bằng mã gửi qua email.'**
  String get auth_signUpSubtitle;

  /// Sign-up button.
  ///
  /// In vi, this message translates to:
  /// **'Tạo tài khoản'**
  String get auth_signUpButton;

  /// Reset title.
  ///
  /// In vi, this message translates to:
  /// **'đặt lại mật khẩu.'**
  String get auth_resetTitle;

  /// Reset subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Nhập email, Ourney gửi mã 6 số để đặt mật khẩu mới.'**
  String get auth_resetSubtitle;

  /// Button: confirm code + new password.
  ///
  /// In vi, this message translates to:
  /// **'Đặt mật khẩu'**
  String get auth_resetConfirm;

  /// Link back to sign-in.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại đăng nhập'**
  String get auth_backToSignIn;

  /// Password sign-in error.
  ///
  /// In vi, this message translates to:
  /// **'Email hoặc mật khẩu chưa đúng.'**
  String get auth_errorWrongPassword;

  /// Sign-up error.
  ///
  /// In vi, this message translates to:
  /// **'Email này đã có tài khoản. Hãy đăng nhập.'**
  String get auth_errorEmailTaken;
}

class _AuthL10nDelegate extends LocalizationsDelegate<AuthL10n> {
  const _AuthL10nDelegate();

  @override
  Future<AuthL10n> load(Locale locale) {
    return SynchronousFuture<AuthL10n>(lookupAuthL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AuthL10nDelegate old) => false;
}

AuthL10n lookupAuthL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AuthL10nEn();
    case 'vi':
      return AuthL10nVi();
  }

  throw FlutterError(
    'AuthL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
