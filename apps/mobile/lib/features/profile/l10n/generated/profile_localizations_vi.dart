// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'profile_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class ProfileL10nVi extends ProfileL10n {
  ProfileL10nVi([String locale = 'vi']) : super(locale);

  @override
  String get profile_title => 'Hồ sơ';

  @override
  String get profile_setupTitle => 'Tạo hồ sơ';

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
  String get profile_continue => 'Tiếp tục';

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
  String get profile_sectionSettings => 'Cài đặt';

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
  String get profile_sectionAccount => 'Tài khoản';

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
}
