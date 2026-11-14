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
  String get profile_usernameHelper =>
      '3–20 ký tự: chữ thường, số, dấu _ và dấu chấm';

  @override
  String profile_usernameTooShort(int min) {
    return 'Tối thiểu $min ký tự.';
  }

  @override
  String profile_usernameTooLong(int max) {
    return 'Tối đa $max ký tự.';
  }

  @override
  String get profile_usernameInvalidChars =>
      'Chỉ dùng chữ thường a–z, số, dấu _ và dấu chấm.';

  @override
  String get profile_usernameTaken =>
      'Tên này đã có người dùng. Chọn tên khác nhé.';

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
  String get profile_sectionSettings => 'cài đặt';

  @override
  String get profile_reminders => 'Nhắc nhở';

  @override
  String get profile_remindersSubtitle => 'Giờ nhắc check-in mỗi ngày';

  @override
  String get profile_haptics => 'Rung phản hồi';

  @override
  String get profile_language => 'Ngôn ngữ';

  @override
  String get profile_languageNote =>
      'Theo ngôn ngữ của máy. Mặc định là tiếng Việt.';

  @override
  String get profile_safety => 'Điều khoản, quyền riêng tư & liên hệ';

  @override
  String get profile_sectionAccount => 'tài khoản';

  @override
  String get profile_signOut => 'Đăng xuất';

  @override
  String get profile_signOutTitle => 'Đăng xuất khỏi Ourney?';

  @override
  String get profile_signOutMessage =>
      'Khi đăng xuất, ảnh và dữ liệu lưu trên máy này sẽ bị xoá, kể cả các check-in chưa gửi lên. Những gì đã đồng bộ sẽ trở lại khi bạn đăng nhập lại bằng email.';

  @override
  String get profile_deleteAccount => 'Xoá tài khoản';

  @override
  String get profile_deleteTitle => 'Xoá tài khoản vĩnh viễn?';

  @override
  String get profile_deleteMessage =>
      'Hồ sơ, hành trình, check-in và toàn bộ ảnh của bạn sẽ bị xoá khỏi máy chủ và máy này. Nhóm bạn đang tham gia được chuyển cho thành viên tham gia sớm nhất. Không thể hoàn tác.';

  @override
  String profile_deleteTypeToConfirm(String phrase) {
    return 'Gõ $phrase để xác nhận';
  }

  @override
  String get profile_deleteConfirmWord => 'XOA';

  @override
  String get profile_deleteConfirmButton => 'Xoá vĩnh viễn';

  @override
  String get profile_deleting => 'Đang xoá…';

  @override
  String get profile_deleteErrorRetry =>
      'Chưa xoá xong. Thử lại để xoá nốt phần còn lại nhé.';

  @override
  String get profile_deleteErrorReauth =>
      'Phiên đăng nhập đã hết hạn. Đăng nhập lại rồi xoá nhé.';

  @override
  String get profile_back => 'Quay lại';

  @override
  String get profile_statSnaps => 'tổng ngày check-in';

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
  String get profile_badgeUnlocked => 'đã mở khoá';

  @override
  String get profile_badgeLocked => 'chưa mở khoá';

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
  String get profile_deleteOtpLabel => 'Mã xác nhận xoá tài khoản gồm 6 số';

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
  String get profile_deleteDoneTitle => 'Đã xoá tài khoản.';

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
}
