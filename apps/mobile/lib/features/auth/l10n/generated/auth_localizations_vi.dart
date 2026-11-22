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
  String get auth_otpHelperEmail =>
      'Không thấy thư? Xem mục Thư rác hoặc Quảng cáo.';

  @override
  String get auth_title => 'vào ourney.';

  @override
  String get auth_subtitle =>
      'Nhập email, mình gửi mã 6 số. Chưa có tài khoản thì Ourney tạo luôn.';

  @override
  String get auth_emailLabel => 'Email';

  @override
  String get auth_emailHint => 'ten@email.com';

  @override
  String get auth_emailInvalid => 'Email chưa đúng dạng. Ví dụ: ten@gmail.com';

  @override
  String get auth_sendCode => 'Gửi mã';

  @override
  String get auth_sending => 'Đang gửi…';

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
  String get auth_codeResent => 'Đã gửi mã mới. Mã cũ không dùng được nữa.';

  @override
  String get auth_changeEmail => 'Đổi email';

  @override
  String get auth_errorWrongCode =>
      'Mã chưa đúng hoặc đã hết hạn. Kiểm tra lại rồi nhập lại.';

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
  String get auth_privacy => 'Chính sách riêng tư';

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
      'Nhập số điện thoại, mình gửi mã 6 số qua SMS. Chưa có tài khoản thì Ourney tạo luôn.';

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
  String get auth_usePassword => 'Đăng nhập bằng mật khẩu';

  @override
  String get auth_useCode => 'Dùng mã thay thế';

  @override
  String get auth_forgot => 'Quên mật khẩu?';

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
  String get auth_errorWrongPassword =>
      'Sai mật khẩu. Thử lại hoặc đăng nhập bằng mã.';

  @override
  String get auth_errorSendFailed => 'Chưa gửi được mã. Thử lại sau ít phút.';

  @override
  String get auth_codeSentPrefix => 'Mã 6 số vừa gửi tới';

  @override
  String get auth_offlineBanner =>
      'Chưa có mạng nên chưa gửi được mã. Bật mạng rồi thử lại.';

  @override
  String get auth_retry => 'Thử lại';

  @override
  String get auth_success => 'Xong rồi. Chào bạn.';

  @override
  String get auth_legalIntro => 'Bấm \"Gửi mã\" là bạn đồng ý với';

  @override
  String get auth_legalAnd => 'và';

  @override
  String get auth_back => 'Quay lại';

  @override
  String get auth_methodLabel => 'Cách nhận mã';

  @override
  String get auth_passwordTitle => 'đăng nhập bằng mật khẩu.';

  @override
  String get auth_otpHelperSms =>
      'Chưa nhận được SMS? Đợi một chút rồi bấm Gửi lại mã.';

  @override
  String get auth_errorPhoneUnavailable =>
      'Đăng nhập bằng SMS tạm thời chưa dùng được. Dùng email nhé.';

  @override
  String get auth_errorSmsFailed =>
      'Chưa gửi được SMS. Kiểm tra số rồi thử lại sau ít phút.';
}
