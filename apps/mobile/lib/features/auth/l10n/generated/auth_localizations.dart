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
  /// **'Không thấy thư? Xem mục Thư rác hoặc Quảng cáo.'**
  String get auth_otpHelperEmail;

  /// Title of the sign-in screen (email step).
  ///
  /// In vi, this message translates to:
  /// **'vào ourney.'**
  String get auth_title;

  /// Explains email OTP sign-in (FR-A1).
  ///
  /// In vi, this message translates to:
  /// **'Nhập email, mình gửi mã 6 số. Chưa có tài khoản thì Ourney tạo luôn.'**
  String get auth_subtitle;

  /// Email field label.
  ///
  /// In vi, this message translates to:
  /// **'Email'**
  String get auth_emailLabel;

  /// Email field placeholder.
  ///
  /// In vi, this message translates to:
  /// **'ten@email.com'**
  String get auth_emailHint;

  /// Validation error for the email field.
  ///
  /// In vi, this message translates to:
  /// **'Email chưa đúng dạng. Ví dụ: ten@gmail.com'**
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

  /// OTP field label.
  ///
  /// In vi, this message translates to:
  /// **'Mã 6 số'**
  String get auth_codeLabel;

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
  /// **'Đã gửi mã mới. Mã cũ không dùng được nữa.'**
  String get auth_codeResent;

  /// Go back to the email step.
  ///
  /// In vi, this message translates to:
  /// **'Đổi email'**
  String get auth_changeEmail;

  /// OTP rejected (invalid / expired).
  ///
  /// In vi, this message translates to:
  /// **'Mã chưa đúng hoặc đã hết hạn. Kiểm tra lại rồi nhập lại.'**
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

  /// Footer link to the terms.
  ///
  /// In vi, this message translates to:
  /// **'Điều khoản sử dụng'**
  String get auth_terms;

  /// Footer link to the privacy policy.
  ///
  /// In vi, this message translates to:
  /// **'Chính sách quyền riêng tư.'**
  String get auth_privacy;

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
  /// **'Nhập số điện thoại, mình gửi mã 6 số qua SMS. Chưa có tài khoản thì Ourney tạo luôn.'**
  String get auth_phoneSubtitle;

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
  /// **'Đăng nhập bằng mật khẩu'**
  String get auth_usePassword;

  /// Link to switch to emailed-code mode.
  ///
  /// In vi, this message translates to:
  /// **'Dùng mã thay thế'**
  String get auth_useCode;

  /// Link to the reset / first-time password flow.
  ///
  /// In vi, this message translates to:
  /// **'Quên hoặc chưa đặt mật khẩu?'**
  String get auth_forgot;

  /// Reset title.
  ///
  /// In vi, this message translates to:
  /// **'đặt mật khẩu mới.'**
  String get auth_resetTitle;

  /// Reset subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Nhập email, Ourney gửi mã 6 số để bạn đặt mật khẩu.'**
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

  /// Non-enumerating password sign-in error.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu chưa đúng, hoặc tài khoản này chưa đặt mật khẩu.'**
  String get auth_errorWrongPassword;

  /// One-tap button after failed password sign-in to send an email OTP code.
  ///
  /// In vi, this message translates to:
  /// **'Gửi mã đăng nhập cho email này'**
  String get auth_sendCodeForEmail;

  /// Sending a code failed (not offline, not rate limited).
  ///
  /// In vi, this message translates to:
  /// **'Chưa gửi được mã. Thử lại sau ít phút.'**
  String get auth_errorSendFailed;

  /// Before the (bold) email or phone the code went to.
  ///
  /// In vi, this message translates to:
  /// **'Mã 6 số vừa gửi tới'**
  String get auth_codeSentPrefix;

  /// Offline banner (.flow-offline).
  ///
  /// In vi, this message translates to:
  /// **'Chưa có mạng nên chưa gửi được mã. Bật mạng rồi thử lại.'**
  String get auth_offlineBanner;

  /// Retry action of the offline banner.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get auth_retry;

  /// Shown after the code was accepted.
  ///
  /// In vi, this message translates to:
  /// **'Xong rồi. Chào bạn.'**
  String get auth_success;

  /// Start of the legal line under the sign-in form.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục đồng nghĩa bạn đồng ý với'**
  String get auth_legalIntro;

  /// Between Terms and Privacy in the legal line.
  ///
  /// In vi, this message translates to:
  /// **'(không dung thứ nội dung phản cảm) và'**
  String get auth_legalAnd;

  /// Back button semantics on the code step.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại'**
  String get auth_back;

  /// Screen reader label of the email/phone method switch.
  ///
  /// In vi, this message translates to:
  /// **'Cách nhận mã'**
  String get auth_methodLabel;

  /// Title of the password sign-in form.
  ///
  /// In vi, this message translates to:
  /// **'đăng nhập bằng mật khẩu.'**
  String get auth_passwordTitle;

  /// Helper under the code step when the code went by SMS.
  ///
  /// In vi, this message translates to:
  /// **'Chưa nhận được SMS? Đợi một chút rồi bấm Gửi lại mã.'**
  String get auth_otpHelperSms;

  /// SMS sign-in is switched off on the server.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập bằng SMS tạm thời chưa dùng được. Dùng email nhé.'**
  String get auth_errorPhoneUnavailable;

  /// The SMS could not be sent.
  ///
  /// In vi, this message translates to:
  /// **'Chưa gửi được SMS. Kiểm tra số rồi thử lại sau ít phút.'**
  String get auth_errorSmsFailed;

  /// Password reset failed because the new password equals the old password.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu mới cần khác mật khẩu hiện tại.'**
  String get auth_errorSamePassword;
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
