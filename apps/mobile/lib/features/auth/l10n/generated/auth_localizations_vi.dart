// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'auth_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AuthL10nVi extends AuthL10n {
  AuthL10nVi([String locale = 'vi']) : super(locale);

  @override
  String get auth_codeTitle => 'nhập mã.';

  @override
  String get auth_otpHelper =>
      'Không thấy thư? Xem mục thư rác hoặc quảng cáo.';

  @override
  String get auth_title => 'đăng nhập.';

  @override
  String get auth_subtitle =>
      'Nhập email, Ourney gửi bạn mã 6 số. Không cần mật khẩu.';

  @override
  String get auth_emailLabel => 'Email';

  @override
  String get auth_emailHint => 'ban@vidu.com';

  @override
  String get auth_emailInvalid => 'Email này chưa đúng định dạng.';

  @override
  String get auth_sendCode => 'Gửi mã';

  @override
  String get auth_sending => 'Đang gửi…';

  @override
  String auth_codeSentTo(String email) {
    return 'Mã 6 số đã được gửi tới $email.';
  }

  @override
  String get auth_codeLabel => 'Mã 6 số';

  @override
  String get auth_codeInvalidFormat => 'Mã gồm đúng 6 chữ số.';

  @override
  String get auth_verify => 'Xác nhận';

  @override
  String get auth_verifying => 'Đang kiểm tra…';

  @override
  String get auth_resend => 'Gửi lại mã';

  @override
  String auth_resendIn(int seconds) {
    return 'Gửi lại sau $seconds giây';
  }

  @override
  String get auth_codeResent => 'Đã gửi mã mới. Kiểm tra hộp thư nhé.';

  @override
  String get auth_changeEmail => 'Đổi email';

  @override
  String get auth_errorWrongCode =>
      'Mã không đúng hoặc đã hết hạn. Kiểm tra lại hoặc gửi mã mới.';

  @override
  String get auth_errorRateLimited =>
      'Bạn thử hơi nhiều rồi. Đợi một chút rồi thử lại nhé.';

  @override
  String get auth_errorOffline => 'Không có mạng. Kết nối lại rồi thử nhé.';

  @override
  String get auth_errorGeneric => 'Có lỗi xảy ra. Thử lại nhé.';

  @override
  String get auth_eyebrow => 'OURNEY';

  @override
  String get auth_eyebrowCheck => 'KIỂM TRA EMAIL';

  @override
  String get auth_terms => 'Điều khoản';

  @override
  String get auth_privacy => 'Quyền riêng tư';

  @override
  String auth_digitSemantics(int n) {
    return 'Chữ số $n trên 6';
  }

  @override
  String get auth_tabEmail => 'Email';

  @override
  String get auth_tabPhone => 'Số điện thoại';

  @override
  String get auth_phoneLabel => 'Số điện thoại';

  @override
  String get auth_phoneHint => '912 345 678';

  @override
  String get auth_phonePrefix => '+84';

  @override
  String get auth_phoneInvalid =>
      'Số điện thoại Việt Nam cần 9–10 số sau 0 hoặc +84.';

  @override
  String get auth_phoneSubtitle =>
      'Nhập số điện thoại, Ourney gửi mã 6 số qua SMS.';

  @override
  String get auth_sendSms => 'Gửi mã SMS';

  @override
  String auth_smsSentTo(String phone) {
    return 'Mã 6 số đã gửi qua SMS tới $phone.';
  }

  @override
  String get auth_changePhone => 'Đổi số điện thoại';

  @override
  String get auth_passwordLabel => 'Mật khẩu';

  @override
  String get auth_newPasswordLabel => 'Mật khẩu mới';

  @override
  String get auth_passwordShort => 'Mật khẩu cần ít nhất 8 ký tự.';

  @override
  String get auth_showPassword => 'Hiện mật khẩu';

  @override
  String get auth_hidePassword => 'Ẩn mật khẩu';

  @override
  String get auth_signIn => 'Đăng nhập';

  @override
  String get auth_usePassword => 'Dùng mật khẩu';

  @override
  String get auth_useCode => 'Dùng mã đăng nhập';

  @override
  String get auth_forgot => 'Quên mật khẩu?';

  @override
  String get auth_createAccount => 'Tạo tài khoản bằng mật khẩu';

  @override
  String get auth_haveAccount => 'Đã có tài khoản? Đăng nhập';

  @override
  String get auth_signUpTitle => 'tạo tài khoản.';

  @override
  String get auth_signUpSubtitle =>
      'Dùng email và mật khẩu của bạn. Có thể cần xác nhận bằng mã gửi qua email.';

  @override
  String get auth_signUpButton => 'Tạo tài khoản';

  @override
  String get auth_resetTitle => 'đặt lại mật khẩu.';

  @override
  String get auth_resetSubtitle =>
      'Nhập email, Ourney gửi mã 6 số để đặt mật khẩu mới.';

  @override
  String get auth_resetConfirm => 'Đặt mật khẩu';

  @override
  String get auth_backToSignIn => 'Quay lại đăng nhập';

  @override
  String get auth_errorWrongPassword => 'Email hoặc mật khẩu chưa đúng.';

  @override
  String get auth_errorEmailTaken =>
      'Email này đã có tài khoản. Hãy đăng nhập.';
}
