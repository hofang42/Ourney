// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'journeys_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class JourneysL10nVi extends JourneysL10n {
  JourneysL10nVi([String locale = 'vi']) : super(locale);

  @override
  String get journeys_title => 'Hành trình';

  @override
  String get journeys_activeSection => 'Đang chạy';

  @override
  String get journeys_finishedSection => 'Trên kệ';

  @override
  String get journeys_emptyTitle => 'Chưa có hành trình nào';

  @override
  String get journeys_emptyMessage =>
      'Bắt đầu hành trình đầu tiên: mỗi ngày một tấm ảnh.';

  @override
  String get journeys_newJourney => 'Hành trình mới';

  @override
  String get journeys_limitTitle => 'Bạn đang chạy 3 hành trình';

  @override
  String get journeys_limitMessage =>
      'Mỗi người chạy tối đa 3 hành trình cùng lúc để việc đăng ảnh luôn nhẹ nhàng. Kết thúc một hành trình rồi bắt đầu cái mới nhé.';

  @override
  String journeys_dayOf(int day, int total) {
    return 'Ngày $day/$total';
  }

  @override
  String journeys_dayOpen(int day) {
    return 'Ngày $day';
  }

  @override
  String get journeys_checkedToday => 'Hôm nay đã check-in';

  @override
  String get journeys_notCheckedToday => 'Hôm nay chưa check-in';

  @override
  String get journeys_statusEnded => 'Đã kết thúc';

  @override
  String get journeys_statusArchived => 'Đã lưu trữ';

  @override
  String get journeys_kindSolo => 'Một mình';

  @override
  String get journeys_kindGroup => 'Nhóm';

  @override
  String get journeys_loadError => 'Không tải được hành trình.';

  @override
  String get journeys_pickTemplateTitle => 'Chọn kiểu hành trình';

  @override
  String journeys_templateDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ngày',
    );
    return '$_temp0';
  }

  @override
  String get journeys_templateCustomHint => 'Tự đặt mọi thứ';

  @override
  String get journeys_templateCoupleTitle => 'Nghi thức cặp đôi';

  @override
  String get journeys_templateCoupleHint =>
      'Hai người cùng lưu khoảnh khắc mỗi ngày';

  @override
  String get journeys_personaPreviewLabel => 'Xem trước giao diện';

  @override
  String get journeys_continueTemplateButton => 'Tiếp tục với kiểu này';

  @override
  String get journeys_createTitle => 'Tạo hành trình';

  @override
  String get journeys_fieldTitle => 'Tên hành trình';

  @override
  String get journeys_fieldEmoji => 'Biểu tượng';

  @override
  String journeys_emojiSemantics(String emoji) {
    return 'Biểu tượng $emoji';
  }

  @override
  String get journeys_fieldKind => 'Một mình hay cùng nhóm?';

  @override
  String get journeys_groupNeedsServer =>
      'Hành trình nhóm cần máy chủ. Bản này đang chạy chỉ trên máy.';

  @override
  String get journeys_fieldDuration => 'Thời lượng';

  @override
  String get journeys_durationCustom => 'Số ngày';

  @override
  String get journeys_openEnded => 'Không giới hạn';

  @override
  String get journeys_fieldMetric => 'Theo dõi một con số';

  @override
  String get journeys_fieldMetricHint => 'Ví dụ: cân nặng, số phút học';

  @override
  String get journeys_metricName => 'Tên chỉ số';

  @override
  String get journeys_metricUnit => 'Đơn vị';

  @override
  String get journeys_hideMetric => 'Ẩn con số với người khác';

  @override
  String get journeys_blurOnShare => 'Làm mờ ảnh khi chia sẻ ra ngoài';

  @override
  String get journeys_fieldVisibility => 'Ai xem được?';

  @override
  String get journeys_visibilityPrivate => 'Chỉ mình tôi';

  @override
  String get journeys_visibilityLink => 'Ai có link';

  @override
  String get journeys_visibilityGroup => 'Thành viên trong nhóm';

  @override
  String get journeys_linkNeedsServer => 'Link chia sẻ cần máy chủ.';

  @override
  String get journeys_fieldTimezone => 'Múi giờ';

  @override
  String get journeys_createButton => 'Bắt đầu hành trình';

  @override
  String get journeys_errorTitleEmpty => 'Đặt tên cho hành trình nhé.';

  @override
  String journeys_errorTitleTooLong(int max) {
    return 'Tên dài tối đa $max ký tự.';
  }

  @override
  String journeys_errorDuration(int min, int max) {
    return 'Thời lượng từ $min đến $max ngày.';
  }

  @override
  String get journeys_errorMetricName => 'Nhập tên chỉ số.';

  @override
  String get journeys_errorVisibility =>
      'Kiểu hiển thị này không dùng được cho hành trình này.';

  @override
  String get journeys_errorNotAlone =>
      'Nhóm vẫn còn thành viên khác nên chưa xoá được. Bạn có thể kết thúc hành trình.';

  @override
  String get journeys_errorForbidden => 'Chỉ chủ hành trình làm được việc này.';

  @override
  String get journeys_errorEnded => 'Hành trình này đã kết thúc.';

  @override
  String get journeys_errorNotFound => 'Không tìm thấy hành trình.';

  @override
  String get journeys_statCurrent => 'Chuỗi hiện tại';

  @override
  String get journeys_statBest => 'Dài nhất';

  @override
  String get journeys_statComplete => 'Hoàn thành';

  @override
  String get journeys_statDay => 'Tiến độ';

  @override
  String journeys_percent(int value) {
    return '$value%';
  }

  @override
  String get journeys_checkInNow => 'Check-in ngay';

  @override
  String get journeys_share => 'Chia sẻ';

  @override
  String get journeys_openGroup => 'Xem nhóm';

  @override
  String get journeys_endJourney => 'Kết thúc hành trình';

  @override
  String get journeys_endConfirmTitle => 'Kết thúc hành trình?';

  @override
  String get journeys_endConfirmMessage =>
      'Sau khi kết thúc, hành trình chỉ xem được và không check-in thêm được nữa.';

  @override
  String get journeys_archive => 'Lưu trữ';

  @override
  String get journeys_delete => 'Xoá hành trình';

  @override
  String get journeys_deleteConfirmTitle => 'Xoá hành trình?';

  @override
  String get journeys_deleteConfirmMessage =>
      'Mọi ảnh của bạn trong hành trình này sẽ bị xoá. Không hoàn tác được.';

  @override
  String get journeys_readOnlyBanner => 'Hành trình đã kết thúc. Chỉ xem.';

  @override
  String get journeys_moreActions => 'Thêm thao tác';

  @override
  String get journeys_timelineTitle => 'Dòng thời gian';

  @override
  String get journeys_privacyTitle => 'Riêng tư';

  @override
  String journeys_cellChecked(int day, String date) {
    return 'Ngày $day, $date: đã check-in';
  }

  @override
  String journeys_cellMissed(int day, String date) {
    return 'Ngày $day, $date: bỏ lỡ';
  }

  @override
  String journeys_cellToday(int day, String date) {
    return 'Ngày $day, $date: hôm nay, chưa check-in';
  }

  @override
  String journeys_cellFuture(int day, String date) {
    return 'Ngày $day, $date: sắp tới';
  }

  @override
  String journeys_cellNotCounted(int day, String date) {
    return 'Ngày $day, $date: trước khi bạn tham gia';
  }

  @override
  String get journeys_today => 'Hôm nay';

  @override
  String get journeys_fromLibrary => 'Từ thư viện';

  @override
  String get journeys_metricHidden => 'Đang ẩn';

  @override
  String get journeys_showMetric => 'Hiện con số';

  @override
  String get journeys_photoUnavailable => 'Ảnh chưa tải được';

  @override
  String get journeys_noCheckIn => 'Chưa có ảnh cho ngày này';

  @override
  String get journeys_greetingMorning => 'Chào buổi sáng';

  @override
  String get journeys_greetingAfternoon => 'Chào buổi chiều';

  @override
  String get journeys_greetingEvening => 'Chào buổi tối';

  @override
  String journeys_greetingNamed(String greeting, String name) {
    return '$greeting, $name';
  }

  @override
  String journeys_remainingToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Còn $count hành trình chờ ảnh hôm nay.',
    );
    return '$_temp0';
  }

  @override
  String get journeys_allDonePrompt =>
      'Hôm nay xong hết rồi. Hẹn bạn ngày mai.';

  @override
  String get journeys_allDoneTitle => 'Xong hết hôm nay';

  @override
  String get journeys_todayLabel => 'Hôm nay';

  @override
  String journeys_dayShort(int day, int total) {
    return 'Ngày $day/$total';
  }

  @override
  String get journeys_streakWord => 'ngày liên tiếp';

  @override
  String journeys_endsInHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: 'Còn $hours giờ',
    );
    return '$_temp0';
  }

  @override
  String get journeys_endsSoon => 'Còn chưa tới 1 giờ';

  @override
  String get journeys_startsToday => 'Bắt đầu hôm nay';

  @override
  String get journeys_lastSevenDays => 'Bảy ngày gần nhất';

  @override
  String get journeys_snapToday => 'Chụp hôm nay';

  @override
  String get journeys_yourJourneys => 'Hành trình của bạn';

  @override
  String get journeys_rowDone => 'Xong';

  @override
  String get journeys_rowNotYet => 'Chưa';

  @override
  String get journeys_privacyPrivate => 'Riêng tư';

  @override
  String get journeys_privacyLink => 'Bật link';

  @override
  String get journeys_privacyGroup => 'Nhóm';

  @override
  String get journeys_addJourney => 'Thêm hành trình';

  @override
  String get journeys_shelfEmpty =>
      'Hành trình đã xong sẽ nằm ở đây để bạn xem lại.';

  @override
  String get journeys_activeEmpty => 'Hiện chưa có hành trình nào đang chạy.';

  @override
  String get journeys_tagWeightLoss => 'Nhìn những thay đổi nhỏ cộng lại.';

  @override
  String get journeys_tagEnglish => 'Giữ động lực cho cả nhóm.';

  @override
  String get journeys_tagTravel => 'Lưu lại từng ngày đi xa.';

  @override
  String get journeys_tagCouple => 'Nhớ về từng khoảnh khắc chung.';

  @override
  String get journeys_tagWorkout => 'Tiến lên qua từng buổi tập.';

  @override
  String get journeys_tagCustom => 'Tạo theo cách của bạn.';

  @override
  String get journeys_modeSoloOnly => 'Chỉ cá nhân';

  @override
  String get journeys_modeSoloGroup => 'Cá nhân · Nhóm';

  @override
  String get journeys_modeCoupleOnly => 'Chỉ cặp đôi';

  @override
  String get journeys_styleLocked => 'Phong cách không đổi được sau khi tạo';

  @override
  String get journeys_moreOptions => 'Tùy chọn khác';
}
