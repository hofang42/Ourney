// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'reminders_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class RemindersL10nVi extends RemindersL10n {
  RemindersL10nVi([String locale = 'vi']) : super(locale);

  @override
  String get reminders_title => 'Nhắc nhở';

  @override
  String get reminders_intro =>
      'Chọn giờ nhắc cho từng hành trình. Ourney chỉ nhắc vào những ngày bạn chưa check-in.';

  @override
  String get reminders_journeysHeader => 'Hành trình';

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
  String get reminders_streakAlertTitle => 'Cảnh báo streak lúc 21:00';

  @override
  String get reminders_streakAlertSubtitle =>
      'Nếu đến 21:00 bạn vẫn chưa check-in mà đang có streak.';

  @override
  String get reminders_emptyTitle => 'Chưa có hành trình nào';

  @override
  String get reminders_emptyMessage =>
      'Tạo một hành trình rồi quay lại đây để đặt giờ nhắc.';

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
      'Ourney chỉ gửi những lời nhắc bạn đặt, và báo lúc 21:00 khi streak sắp mất. Không quảng cáo.';

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
  String get reminders_alertTitle => 'Streak sắp mất';

  @override
  String reminders_alertBody(String journey, int count) {
    return '$journey: chuỗi $count ngày sẽ mất lúc nửa đêm. Một tấm ảnh là giữ được.';
  }

  @override
  String get reminders_channelName => 'Nhắc check-in';

  @override
  String get reminders_channelDescription =>
      'Lời nhắc check-in hằng ngày và cảnh báo streak sắp mất.';
}
