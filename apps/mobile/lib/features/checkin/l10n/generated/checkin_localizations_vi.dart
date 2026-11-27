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
  String get checkin_postMemory => 'Dán vào sổ';

  @override
  String get checkin_captionLabelMemory => 'Ghi lại một dòng';

  @override
  String get checkin_captionLabelFlexer => 'Hôm nay chạy thế nào?';

  @override
  String get checkin_posting => 'Đang đăng…';

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
  String checkin_photoAdded(int n) {
    return 'Đã thêm ảnh thứ $n';
  }

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
  String get checkin_shareSkinMemory => 'Chia sẻ poster chuyến đi';

  @override
  String get checkin_shareSkinCouple => 'Chia sẻ câu chuyện';

  @override
  String get checkin_shareSkinFlexer => 'Chia sẻ lên Story';

  @override
  String get checkin_shareSkinMinimal => 'Xuất thẻ';

  @override
  String get checkin_shareSkinQuiet => 'Tạo thiệp';

  @override
  String get checkin_done_saved => 'Đã lưu vào hành trình của bạn.';

  @override
  String get checkin_done_savedPrivate => 'Đã lưu. Chỉ mình bạn thấy.';

  @override
  String get checkin_done_futureMembers =>
      'Đã gửi ảnh lên nhóm. Người tham gia sau có thể xem ảnh này.';

  @override
  String get checkin_done_coupleFutureMembers =>
      'Đã lưu nửa ảnh của bạn. Người ấy tham gia sau có thể xem ảnh này.';

  @override
  String get checkin_done_sharedSquad => 'Đã gửi ảnh lên nhóm rồi.';

  @override
  String get checkin_done_sharedLink => 'Đã hiển thị trên hành trình chia sẻ.';

  @override
  String get checkin_done_pendingGroup =>
      'Đã lưu ảnh của bạn, có mạng sẽ gửi lên nhóm';

  @override
  String get checkin_done_pendingCouple =>
      'Đã lưu nửa ảnh của bạn, có mạng sẽ gửi cho người ấy';

  @override
  String get checkin_done_pending => 'Đã lưu ảnh trên máy. Có mạng sẽ đồng bộ.';

  @override
  String get checkin_done_uploadFailed =>
      'Đã lưu ảnh trên máy. Bạn có thể thử gửi lại từ hành trình.';

  @override
  String checkin_resumeDraft(String journey) {
    return 'Mở lại bản nháp cho $journey';
  }

  @override
  String get checkin_draftCue => 'Bản nháp · chạm để mở lại';

  @override
  String get checkin_discardDraft => 'Bỏ bản nháp';

  @override
  String get checkin_chooseAnother => 'Chọn ảnh khác';

  @override
  String get checkin_done_stampChecked => 'ĐÃ ĐIỂM DANH';

  @override
  String get checkin_done_stampWeek1 => 'TUẦN 1 XONG';

  @override
  String get checkin_done_stampCup => 'CÚP VỀ TAY';

  @override
  String checkin_done_memoryStamp(int day) {
    return 'ĐÃ DÁN · NGÀY $day HÀNH TRÌNH';
  }

  @override
  String checkin_done_coupleDay(int day) {
    return 'Ngày $day';
  }

  @override
  String get checkin_done_coupleSent => 'Đã gửi nửa ảnh của bạn rồi.';

  @override
  String get checkin_done_coupleWeek => 'Tuần đầu bên nhau';

  @override
  String get checkin_done_coupleFull30 => 'Tròn 30 ngày';

  @override
  String checkin_done_flexerDay(int day, int streak) {
    return 'NGÀY $day. $streak NGÀY LIỀN.';
  }

  @override
  String get checkin_done_flexerWeek => 'TUẦN ĐẦU XONG';

  @override
  String get checkin_done_flexerFinish => 'VỀ ĐÍCH';

  @override
  String get checkin_done_minimalDone => 'XONG.';

  @override
  String get checkin_done_minimalWeek => '7 NGÀY LIỀN';

  @override
  String get checkin_done_minimalFull => 'ĐỦ 30 NGÀY';

  @override
  String get checkin_done => 'Xong';

  @override
  String checkin_chainKept(int day) {
    return 'Đã lưu ảnh ngày $day';
  }

  @override
  String checkin_daysUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ngày',
    );
    return '$_temp0';
  }

  @override
  String get checkin_retake => 'Chụp lại';

  @override
  String get checkin_privacyPrivate => 'Chỉ mình bạn';

  @override
  String get checkin_privacyPending => 'Trong hành trình này';

  @override
  String get checkin_privacyFutureMembers => 'Người tham gia sau có thể xem';

  @override
  String get checkin_privacyShared => 'Đã chia sẻ';

  @override
  String get checkin_privacyCouple => 'Cặp đôi';

  @override
  String get checkin_privacySquad => 'Nhóm';

  @override
  String checkin_dayStamp(int day) {
    return 'NGÀY $day';
  }

  @override
  String checkin_calendarSemantics(int days) {
    return 'Lịch $days ngày gần nhất, hôm nay có ảnh';
  }

  @override
  String get checkin_extraMoodLabel => 'Hôm nay bạn cảm thấy thế nào?';

  @override
  String get checkin_extraMoodLight => 'Nhẹ nhõm';

  @override
  String get checkin_extraMoodNormal => 'Bình thường';

  @override
  String get checkin_extraMoodTired => 'Hơi mệt';

  @override
  String get checkin_extraMinutesLabel => 'Hôm nay học bao lâu?';

  @override
  String checkin_extraMinutesValue(int minutes) {
    return '$minutes phút';
  }

  @override
  String get checkin_extraMinutesOther => 'Khác';

  @override
  String get checkin_extraMinutesLess => 'Giảm năm phút';

  @override
  String get checkin_extraMinutesMore => 'Tăng năm phút';

  @override
  String get checkin_extraPlaceLabel => 'Bạn đang ở đâu?';

  @override
  String get checkin_extraPlaceHint => 'Tìm một nơi...';

  @override
  String get checkin_extraDishLabel => 'Món hôm nay';

  @override
  String get checkin_extraDishHint => 'Để trống cũng được';

  @override
  String get checkin_extraMomentLabel => 'Khoảnh khắc hôm nay';

  @override
  String get checkin_extraMomentHint => 'Để trống cũng được';

  @override
  String get checkin_extraCookLabel => 'Ai nấu?';

  @override
  String get checkin_extraYou => 'Bạn';

  @override
  String get checkin_extraPartner => 'Người ấy';

  @override
  String get checkin_extraHeartsLabel => 'Bữa này mấy tim?';

  @override
  String get checkin_extraHeartsMomentLabel => 'Hôm nay mấy tim?';

  @override
  String checkin_extraHeartsValue(int count) {
    return '$count tim';
  }

  @override
  String get checkin_coupleInvite => 'Mời người ấy tham gia';

  @override
  String get checkin_coupleWaiting => 'Chờ người ấy đăng ảnh';

  @override
  String get checkin_extraPaceLabel => 'Nhịp chạy (phút/km)';

  @override
  String get checkin_extraPaceInvalid => 'Nhịp không hợp lệ, giây phải dưới 60';

  @override
  String get checkin_extraKmLabel => 'Quãng đường (km)';

  @override
  String get checkin_extraKmHint => 'VD: 5,3';

  @override
  String get checkin_extraKmInvalid =>
      'Quãng đường từ 0,1 đến 500 km, một chữ số thập phân';

  @override
  String get checkin_extraBackspace => 'Xóa một số';

  @override
  String get checkin_details => 'Chi tiết';

  @override
  String checkin_captionLimitReached(int max) {
    return 'Đã đạt giới hạn $max ký tự';
  }

  @override
  String checkin_metricLast(String value) {
    return 'Lần trước: $value';
  }
}
