// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'reminders_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class RemindersL10nVi extends RemindersL10n {
  RemindersL10nVi([String locale = 'vi']) : super(locale);

  @override
  String get reminders_title => 'nhắc nhở.';

  @override
  String get reminders_intro =>
      'Chọn giờ nhắc cho từng hành trình. Ourney chỉ nhắc vào những ngày bạn chưa check-in.';

  @override
  String get reminders_journeysHeader => 'hành trình';

  @override
  String reminders_toggleLabel(String journey) {
    return 'Nhắc cho $journey';
  }

  @override
  String reminders_timeOn(String time) {
    return 'Nhắc lúc $time mỗi ngày';
  }

  @override
  String get reminders_timeOff => 'Đang tắt';

  @override
  String reminders_changeTime(String time) {
    return 'Đổi giờ nhắc ($time)';
  }

  @override
  String get reminders_pickTimeHelp => 'Giờ nhắc check-in';

  @override
  String get reminders_streakAlertTitle => 'Nhắc chụp ảnh lúc 21:00';

  @override
  String get reminders_streakAlertSubtitle =>
      'Nhắc lúc 21:00 nếu hôm nay bạn chưa chụp ảnh.';

  @override
  String get reminders_emptyTitle => 'Chưa có hành trình nào';

  @override
  String get reminders_emptyCreate => 'Tạo hành trình';

  @override
  String get reminders_emptyMessage =>
      'Có hành trình rồi thì đặt giờ nhắc ở đây.';

  @override
  String get reminders_loadError =>
      'Không tải được danh sách hành trình. Thử lại sau nhé.';

  @override
  String get reminders_retry => 'Thử lại';

  @override
  String get reminders_deniedTitle => 'Thông báo đang tắt';

  @override
  String get reminders_deniedMessage =>
      'Giờ nhắc vẫn được lưu, nhưng cần bật thông báo cho Ourney trong Cài đặt thì nhắc nhở mới hiện.';

  @override
  String get reminders_openSettings => 'Mở Cài đặt';

  @override
  String get reminders_permissionTitle => 'Bật thông báo nhé?';

  @override
  String get reminders_permissionMessage =>
      'Ourney chỉ gửi giờ nhắc bạn chọn và một lời nhắc nhẹ lúc 21:00 nếu hôm nay bạn chưa chụp. Không quảng cáo.';

  @override
  String get reminders_permissionContinue => 'Tiếp tục';

  @override
  String get reminders_permissionNotNow => 'Để sau';

  @override
  String get reminders_notifTitle => 'Đến giờ check-in rồi';

  @override
  String reminders_notifBody(String journey) {
    return '$journey: chụp một tấm cho hôm nay nào.';
  }

  @override
  String get reminders_alertTitle => 'Hôm nay bạn muốn lưu tấm nào?';

  @override
  String reminders_alertBody(String journey) {
    return '$journey: một tấm hôm nay là đủ rồi.';
  }

  @override
  String reminders_alertBodyAt(String journey, String time) {
    return '$journey: một tấm hôm nay là đủ rồi (ngày mới của hành trình bắt đầu lúc $time).';
  }

  @override
  String get reminders_channelName => 'Nhắc check-in';

  @override
  String get reminders_channelDescription =>
      'Lời nhắc check-in hằng ngày và lời nhắc nhẹ buổi tối.';
}
