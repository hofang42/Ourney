// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'profile_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class ProfileL10nVi extends ProfileL10n {
  ProfileL10nVi([String locale = 'vi']) : super(locale);

  @override
  String get profile_deleteItemProfile => 'Hồ sơ của bạn';

  @override
  String get profile_deleteItemJourneys => 'Mọi hành trình và ảnh';

  @override
  String get profile_deleteItemGroups => 'Tư cách thành viên trong các nhóm';

  @override
  String get profile_editScreenTitle => 'sửa hồ sơ.';

  @override
  String get profile_title => 'hồ sơ.';

  @override
  String get profile_setupTitle => 'hồ sơ của bạn.';

  @override
  String get profile_setupSubtitle =>
      'Bạn bè sẽ thấy tên và ảnh này khi cùng đi hành trình.';

  @override
  String get profile_editTitle => 'Sửa hồ sơ';

  @override
  String get profile_usernameLabel => 'Tên người dùng';

  @override
  String get profile_usernameHelper => '3–20 ký tự: a–z, 0–9, _ .';

  @override
  String profile_usernameTooShort(int min) {
    return 'Tối thiểu $min ký tự.';
  }

  @override
  String profile_usernameTooLong(int max) {
    return 'Tối đa $max ký tự.';
  }

  @override
  String get profile_usernameInvalidChars => 'Chỉ dùng a–z, 0–9, _ .';

  @override
  String get profile_usernameTaken => 'Tên này đã có người dùng';

  @override
  String get profile_usernameUnavailable => 'Tên này không dùng được';

  @override
  String get profile_displayNameLabel => 'Tên hiển thị';

  @override
  String get profile_displayNameEmpty => 'Nhập tên hiển thị.';

  @override
  String profile_displayNameTooLong(int max) {
    return 'Tối đa $max ký tự.';
  }

  @override
  String get profile_avatarAdd => 'Thêm ảnh đại diện';

  @override
  String get profile_avatarOptional => 'Không bắt buộc';

  @override
  String get profile_avatarChange => 'Đổi ảnh đại diện';

  @override
  String get profile_avatarFromGallery => 'Chọn từ thư viện';

  @override
  String get profile_avatarFromCamera => 'Chụp ảnh mới';

  @override
  String get profile_avatarError =>
      'Không tải được ảnh đại diện lên. Thử lại nhé.';

  @override
  String profile_avatarSemantics(String name) {
    return 'Ảnh đại diện của $name';
  }

  @override
  String get profile_save => 'Lưu';

  @override
  String get profile_continue => 'Xong';

  @override
  String get profile_saving => 'Đang lưu…';

  @override
  String get profile_saveError => 'Không lưu được hồ sơ. Thử lại nhé.';

  @override
  String get profile_saveContentPolicy =>
      'Hãy thử tên người dùng hoặc tên hiển thị khác.';

  @override
  String get profile_offlineError => 'Không có mạng. Kết nối lại rồi thử nhé.';

  @override
  String get profile_loadError => 'Không tải được hồ sơ.';

  @override
  String get profile_completeTitle => 'Hoàn tất hồ sơ';

  @override
  String get profile_completeMessage =>
      'Chọn tên người dùng để bạn bè nhận ra bạn.';

  @override
  String get profile_guestName => 'Khách';

  @override
  String get profile_guestTitle => 'Chế độ chỉ trên máy';

  @override
  String get profile_guestMessage =>
      'Dữ liệu của bạn chỉ nằm trên máy này. Hành trình một mình dùng đầy đủ; đăng nhập và nhóm cần máy chủ.';

  @override
  String get profile_signOut => 'Đăng xuất';

  @override
  String get profile_signOutTitle => 'Đăng xuất khỏi Ourney?';

  @override
  String get profile_signOutMessage =>
      'Khi đăng xuất, ảnh và dữ liệu lưu trên máy này sẽ bị xóa, kể cả các check-in chưa gửi lên. Những gì đã đồng bộ sẽ trở lại khi bạn đăng nhập lại bằng tài khoản này.';

  @override
  String get profile_deleteTitle => 'Xóa tài khoản vĩnh viễn?';

  @override
  String get profile_deleteMessage =>
      'Hồ sơ, hành trình, check-in và toàn bộ ảnh của bạn sẽ bị xóa khỏi máy chủ và máy này. Nhóm bạn đang tham gia được chuyển cho thành viên tham gia sớm nhất. Không thể hoàn tác.';

  @override
  String profile_deleteTypeToConfirm(String phrase) {
    return 'Gõ $phrase để xác nhận';
  }

  @override
  String get profile_deleteConfirmWord => 'XOA';

  @override
  String get profile_deleteConfirmButton => 'Xóa vĩnh viễn';

  @override
  String get profile_deleting => 'Đang xóa…';

  @override
  String get profile_deleteErrorRetry =>
      'Chưa xóa xong. Thử lại để xóa nốt phần còn lại nhé.';

  @override
  String get profile_deleteErrorReauth =>
      'Phiên đăng nhập đã hết hạn. Đăng nhập lại rồi xóa nhé.';

  @override
  String get profile_back => 'Quay lại';

  @override
  String get profile_statSnaps => 'tổng lần check-in';

  @override
  String get profile_statLongest => 'chuỗi dài nhất';

  @override
  String get profile_statDone => 'hành trình đã xong';

  @override
  String get profile_badgesTitle => 'huy hiệu đều đặn.';

  @override
  String get profile_badge7 => 'Đều 7 ngày';

  @override
  String get profile_badge30 => 'Đều 30 ngày';

  @override
  String get profile_badgeFinish => 'Về đích đầu tiên';

  @override
  String get profile_badge100 => 'Đủ 100 ngày';

  @override
  String get profile_badge7Rule => 'Có mặt đủ 7 ngày liên tiếp.';

  @override
  String get profile_badge30Rule => 'Có mặt đủ 30 ngày liên tiếp.';

  @override
  String get profile_badgeFinishRule => 'Hoàn thành hành trình đầu tiên.';

  @override
  String get profile_badge100Rule => 'Check-in đủ 100 ngày.';

  @override
  String get profile_badgeUnlocked => 'đã mở khóa';

  @override
  String get profile_badgeLocked => 'chưa mở khóa';

  @override
  String get profile_deleteUnderstand =>
      'Tôi hiểu việc này không thể hoàn tác.';

  @override
  String get profile_deleteOwnerNote =>
      'Nếu bạn là chủ nhóm, quyền chủ nhóm chuyển cho người vào sớm nhất.';

  @override
  String get profile_deleteKeep => 'Giữ tài khoản';

  @override
  String get profile_deleteContinue => 'Tiếp tục';

  @override
  String get profile_deleteOtpTitle => 'xác nhận bằng mã.';

  @override
  String get profile_deleteOtpLead =>
      'Mã gồm 6 số vừa gửi tới email hoặc số điện thoại của tài khoản này.';

  @override
  String get profile_deleteOtpLabel => 'Mã xác nhận xóa tài khoản gồm 6 số';

  @override
  String get profile_deleteOtpWrong => 'Mã chưa đúng. Kiểm tra lại nhé.';

  @override
  String get profile_deleteResend => 'Gửi lại mã';

  @override
  String profile_deleteResendIn(int seconds) {
    return 'Gửi lại sau ${seconds}s';
  }

  @override
  String get profile_deleteCodeSent => 'Đã gửi mã mới.';

  @override
  String get profile_deleteDoneTitle => 'Đã xóa tài khoản.';

  @override
  String get profile_deleteDoneBody => 'Cảm ơn bạn đã dùng Ourney.';

  @override
  String get profile_deleteDoneButton => 'Về màn đầu';

  @override
  String get profile_deleteBackToSettings => 'Về cài đặt';

  @override
  String profile_deleteStepSemantics(int current, int total) {
    return 'Bước $current trên $total';
  }

  @override
  String get profile_usernameAvailable => 'Dùng được';

  @override
  String get profile_settings_title => 'cài đặt.';

  @override
  String get profile_settings_back => 'Quay lại';

  @override
  String get profile_settings_secAccount => 'tài khoản';

  @override
  String get profile_settings_editProfile => 'Sửa hồ sơ';

  @override
  String get profile_settings_secReminders => 'nhắc nhở';

  @override
  String get profile_settings_remindersRow => 'Nhắc nhở hằng ngày';

  @override
  String get profile_settings_remindersSub =>
      'Giờ nhắc từng hành trình và nhắc buổi tối lúc 21:00';

  @override
  String get profile_settings_widgetsRow => 'Tiện ích & Live Activity';

  @override
  String get profile_settings_widgetsSub =>
      'Tiện ích màn hình chính, màn hình khóa và khung giờ chụp buổi tối';

  @override
  String get profile_settings_themeLight => 'Sáng';

  @override
  String get profile_settings_themeDark => 'Tối';

  @override
  String get profile_settings_themeSystem => 'Theo máy';

  @override
  String get profile_settings_themeLabel => 'Chế độ giao diện';

  @override
  String get profile_settings_langVi => 'Việt';

  @override
  String get profile_settings_langEn => 'English';

  @override
  String get profile_settings_appIcon => 'Icon ứng dụng';

  @override
  String get profile_settings_appIconNote =>
      'Đổi icon trên màn hình chính. Trên một số máy Android, ứng dụng có thể tự đóng hoặc tải lại khi đổi icon.';

  @override
  String get profile_settings_iconDefault => 'Mặc định';

  @override
  String get profile_settings_iconYellow => 'Vàng hội';

  @override
  String get profile_settings_iconGreen => 'Xanh ngọc';

  @override
  String get profile_settings_iconCoral => 'Hồng đôi';

  @override
  String get profile_settings_iconViolet => 'Tím tập';

  @override
  String get profile_settings_iconSky => 'Xanh trời';

  @override
  String get profile_settings_iconDark => 'Đêm tối';

  @override
  String get profile_settings_iconMinimal => 'Tối giản';

  @override
  String profile_settings_iconSemantic(String name) {
    return 'Icon ứng dụng $name';
  }

  @override
  String get profile_settings_secPrivacy => 'riêng tư & an toàn';

  @override
  String get profile_settings_hideKg => 'Ẩn số kg khi chia sẻ';

  @override
  String get profile_settings_blurPhotos => 'Làm mờ ảnh khi chia sẻ';

  @override
  String get profile_settings_blocked => 'Người bị chặn';

  @override
  String get profile_settings_blockedSub => 'Xem và bỏ chặn';

  @override
  String get profile_settings_secInfo => 'thông tin';

  @override
  String get profile_settings_featureRequests => 'Góp ý & đề xuất tính năng';

  @override
  String get profile_settings_featureRequestsSub =>
      'Bình chọn ý tưởng hoặc gửi đề xuất mới';

  @override
  String get profile_settings_eula => 'Điều khoản sử dụng (EULA)';

  @override
  String get profile_settings_privacyPolicy => 'Chính sách riêng tư';

  @override
  String get profile_settings_contact => 'Liên hệ';

  @override
  String get profile_settings_version => 'Phiên bản';

  @override
  String get profile_settings_signOut => 'Đăng xuất';

  @override
  String get profile_settings_delete => 'Xóa tài khoản';

  @override
  String get profile_settingsEntry => 'Cài đặt';

  @override
  String profile_signOutPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Còn $count ảnh chưa gửi lên. Ourney sẽ thử gửi trước khi đăng xuất; ảnh nào chưa gửi được sẽ mất.',
    );
    return '$_temp0';
  }

  @override
  String get profile_settings_secAppearance => 'giao diện & ngôn ngữ';

  @override
  String get profile_settings_signedInWith => 'Đăng nhập bằng';

  @override
  String get profile_settings_haptics => 'Rung phản hồi';

  @override
  String get profile_settings_shareNote =>
      'Áp dụng cho ảnh chia sẻ ra ngoài và trong nhóm';

  @override
  String get profile_settings_themeEyebrow => 'GIAO DIỆN';

  @override
  String get profile_settings_languageEyebrow => 'NGÔN NGỮ';

  @override
  String get profile_settings_secSecurity => 'bảo mật';

  @override
  String get profile_settings_setPassword => 'Đặt mật khẩu';

  @override
  String get profile_settings_setPasswordSub =>
      'Tùy chọn — bạn vẫn luôn đăng nhập được bằng mã 6 số';

  @override
  String get profile_settings_changePassword => 'Đổi mật khẩu';

  @override
  String get profile_settings_changePasswordSub =>
      'Đang bật song song với mã đăng nhập 6 số';

  @override
  String get profile_settings_passwordPhoneOnly => 'Mật khẩu';

  @override
  String get profile_settings_passwordPhoneOnlySub =>
      'Tài khoản số điện thoại đăng nhập bằng mã SMS';

  @override
  String get profile_password_setTitle => 'đặt mật khẩu.';

  @override
  String profile_password_setLead(String email) {
    return 'Bạn có thể đăng nhập bằng mật khẩu này hoặc mã 6 số gửi tới $email.';
  }

  @override
  String get profile_password_changeTitle => 'đổi mật khẩu.';

  @override
  String get profile_password_newLabel => 'Mật khẩu mới';

  @override
  String get profile_password_shortError => 'Mật khẩu cần ít nhất 8 ký tự.';

  @override
  String get profile_password_sameError =>
      'Mật khẩu mới cần khác mật khẩu hiện tại.';

  @override
  String get profile_password_signOutOthers =>
      'Đăng xuất khỏi các thiết bị khác';

  @override
  String get profile_password_signOutOthersSub =>
      'Giữ phiên đăng nhập trên máy này';

  @override
  String get profile_password_continue => 'Tiếp tục';

  @override
  String get profile_password_sending => 'Đang gửi mã…';

  @override
  String get profile_password_save => 'Lưu mật khẩu';

  @override
  String get profile_password_saving => 'Đang lưu…';

  @override
  String get profile_password_codeTitle => 'xác minh bằng mã.';

  @override
  String profile_password_codeLead(String email) {
    return 'Nhập mã 6 số vừa gửi tới $email để lưu mật khẩu.';
  }

  @override
  String get profile_password_codeLabel => 'Mã xác minh 6 số';

  @override
  String get profile_password_codeWrong =>
      'Mã chưa đúng hoặc đã hết hạn. Kiểm tra lại nhé.';

  @override
  String get profile_password_resend => 'Gửi lại mã';

  @override
  String profile_password_resendIn(int seconds) {
    return 'Gửi lại sau ${seconds}s';
  }

  @override
  String get profile_password_codeResent => 'Đã gửi mã mới.';

  @override
  String get profile_password_rateLimited =>
      'Bạn thử hơi nhiều rồi. Đợi một chút rồi thử lại nhé.';

  @override
  String get profile_password_sendError =>
      'Chưa gửi được mã xác minh. Thử lại nhé.';

  @override
  String get profile_password_saveError =>
      'Chưa lưu được mật khẩu. Thử lại nhé.';

  @override
  String get profile_password_savedSet => 'Đã đặt mật khẩu.';

  @override
  String get profile_password_savedChanged => 'Đã đổi mật khẩu.';

  @override
  String get profile_password_show => 'Hiện mật khẩu';

  @override
  String get profile_password_hide => 'Ẩn mật khẩu';
}
