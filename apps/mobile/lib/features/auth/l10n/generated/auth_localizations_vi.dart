// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'auth_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AuthL10nVi extends AuthL10n {
  AuthL10nVi([String locale = 'vi']) : super(locale);

  @override
  String get auth_title => 'Đăng nhập';

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
  String get auth_codeTitle => 'Nhập mã';

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
  String get auth_termsNote =>
      'Khi tiếp tục, bạn đồng ý với điều khoản sử dụng và chính sách quyền riêng tư của Ourney.';

  @override
  String get auth_termsLink => 'Xem điều khoản';

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
}
