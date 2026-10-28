// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'checkin_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class CheckinL10nVi extends CheckinL10n {
  CheckinL10nVi([String locale = 'vi']) : super(locale);

  @override
  String get checkin_title => 'Check-in';

  @override
  String get checkin_photoSemantics => 'Ảnh check-in vừa chụp';

  @override
  String get checkin_fromLibrary => 'Từ thư viện';

  @override
  String get checkin_captionLabel => 'Chú thích';

  @override
  String get checkin_captionHint => 'Viết vài dòng (không bắt buộc)';

  @override
  String checkin_captionCounter(int count, int max) {
    return '$count/$max';
  }

  @override
  String checkin_captionCounterSemantics(int count, int max) {
    return 'Đã nhập $count trên $max ký tự';
  }

  @override
  String get checkin_metricInvalid => 'Nhập một số hợp lệ';

  @override
  String get checkin_metricPrivate => 'Chỉ mình bạn thấy số này';

  @override
  String get checkin_post => 'Đăng';

  @override
  String get checkin_posting => 'Đang đăng…';

  @override
  String get checkin_replaceTitle => 'Thay ảnh hôm nay?';

  @override
  String get checkin_replaceMessage =>
      'Hôm nay bạn đã check-in cho hành trình này. Ảnh mới sẽ thay ảnh cũ.';

  @override
  String get checkin_replaceConfirm => 'Thay ảnh';

  @override
  String get checkin_errorPhoto =>
      'Không xử lý được ảnh này. Thử ảnh khác nhé.';

  @override
  String get checkin_errorEnded =>
      'Hành trình đã kết thúc nên không check-in thêm được.';

  @override
  String get checkin_missingPhoto =>
      'Không tìm thấy ảnh. Quay lại và chụp lại nhé.';

  @override
  String get checkin_missingJourney => 'Không tìm thấy hành trình này.';

  @override
  String get checkin_stamp => 'Đã check-in!';

  @override
  String get checkin_streakPlusOne => '+1 ngày';

  @override
  String get checkin_replaced => 'Đã thay ảnh hôm nay';

  @override
  String get checkin_milestone7 => '7 ngày liên tục!';

  @override
  String get checkin_milestone30 => '30 ngày liên tục!';

  @override
  String get checkin_milestoneFinish => 'Về đích rồi!';

  @override
  String get checkin_milestoneMessage => 'Khoe thành tích với bạn bè nhé.';

  @override
  String get checkin_share => 'Chia sẻ';

  @override
  String get checkin_done => 'Xong';

  @override
  String get checkin_posted => 'Đã đăng khoảnh khắc';

  @override
  String get checkin_chainKept => 'Giữ được chuỗi.';

  @override
  String checkin_daysUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ngày',
    );
    return '$_temp0';
  }
}
