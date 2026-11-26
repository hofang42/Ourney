// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'widgets_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class WidgetsL10nVi extends WidgetsL10n {
  WidgetsL10nVi([String locale = 'vi']) : super(locale);

  @override
  String get widgets_title => 'tiện ích.';

  @override
  String get widgets_back => 'Quay lại';

  @override
  String get widgets_intro =>
      'Đặt chuỗi ngày, mục tiêu hôm nay và tiến độ nhóm ngay trên Màn hình chính hoặc Màn hình khóa. Số cân nặng (kg) và mục tiêu riêng tư không bao giờ xuất hiện trên tiện ích.';

  @override
  String get widgets_appGroupUnavailable =>
      'Bản cài này chưa cho widget đọc dữ liệu. Widget sẽ hoạt động ở bản TestFlight/App Store hoặc khi cài qua AltStore/SideStore.';

  @override
  String get widgets_diagnosticsTitle => 'Chẩn đoán tiện ích';

  @override
  String get widgets_diagnosticsEmpty =>
      'Chưa ghi nhận sự kiện nào của tiện ích.';

  @override
  String get widgets_diagnosticsCopy => 'Sao chép nhật ký';

  @override
  String get widgets_diagnosticsCopied => 'Đã sao chép nhật ký tiện ích';

  @override
  String get widgets_secPreview => 'xem trước tiện ích';

  @override
  String get widgets_tabToday => 'Hôm nay';

  @override
  String get widgets_tabStreak => 'Chuỗi';

  @override
  String get widgets_tabSquad => 'Đồng đội';

  @override
  String get widgets_previewSampleTitle => 'Tự học IELTS 30 ngày';

  @override
  String get widgets_previewSampleBadge => 'Xem trước mẫu';

  @override
  String get widgets_previewYou => 'Bạn';

  @override
  String widgets_previewDayOf(int day, int total) {
    return 'Ngày $day/$total';
  }

  @override
  String widgets_previewDayOpen(int day) {
    return 'Ngày $day';
  }

  @override
  String widgets_previewStreakDays(int count) {
    return '$count ngày liên tiếp';
  }

  @override
  String get widgets_previewSnapCta => 'Chụp ngay';

  @override
  String get widgets_previewDoneBadge => 'Đã chụp hôm nay';

  @override
  String get widgets_previewAtRiskBadge => 'Vẫn kịp hôm nay · đến nửa đêm';

  @override
  String get widgets_previewPendingBadge => 'Chưa chụp hôm nay';

  @override
  String widgets_previewSquadCount(int done, int total) {
    return '$done/$total đã check-in hôm nay';
  }

  @override
  String get widgets_previewPhotoHiddenNote => 'Đã ẩn ảnh trên tiện ích';

  @override
  String get widgets_previewPhotoBlurredNote => 'Ảnh được làm mờ tự động';

  @override
  String get widgets_previewPhotoClearNote =>
      'Ảnh hiển thị rõ trên Màn hình chính';

  @override
  String get widgets_secPrivacy => 'riêng tư & hiển thị';

  @override
  String get widgets_photoModeEyebrow => 'ẢNH TRÊN TIỆN ÍCH MÀN HÌNH CHÍNH';

  @override
  String get widgets_photoModeSmart => 'Thông minh';

  @override
  String get widgets_photoModeBlurred => 'Làm mờ';

  @override
  String get widgets_photoModeOff => 'Ẩn ảnh';

  @override
  String get widgets_photoModeClear => 'Rõ nét';

  @override
  String get widgets_photoModeSmartNote =>
      'Tự động làm mờ ảnh hành trình giảm cân và chỉ hiện ảnh đại diện trong tiện ích nhóm. Số kg không bao giờ xuất hiện.';

  @override
  String get widgets_photoModeBlurredNote =>
      'Mọi ảnh check-in trên tiện ích Màn hình chính đều được làm mờ trước khi lưu. Số kg không bao giờ xuất hiện.';

  @override
  String get widgets_photoModeOffNote =>
      'Không hiển thị bất kỳ ảnh nào trên tiện ích; chỉ hiện biểu tượng sticker, chuỗi ngày và chữ cái đại diện.';

  @override
  String get widgets_photoModeClearNote =>
      'Hiển thị ảnh check-in rõ nét trên Màn hình chính khi đã mở khóa máy. Màn hình khóa vẫn không bao giờ hiện ảnh hay số kg.';

  @override
  String get widgets_redactTitlesLabel =>
      'Ẩn tên hành trình trên Màn hình khóa';

  @override
  String get widgets_redactTitlesSub =>
      'Trên Màn hình khóa, tiện ích khóa và Live Activity chỉ hiện \"Ourney\" thay vì tên hành trình cụ thể.';

  @override
  String get widgets_redactTitlesSubAndroid =>
      'Trên Màn hình khóa, cập nhật trực tiếp chỉ hiện \"Ourney\" thay vì tên hành trình cụ thể.';

  @override
  String get widgets_secLiveActivity => 'khung giờ buổi tối';

  @override
  String get widgets_liveActivityLabel => 'Live Activity & khung giờ chụp tối';

  @override
  String get widgets_liveActivityLabelAndroid =>
      'Cập nhật trực tiếp & khung giờ thanh trạng thái';

  @override
  String get widgets_liveActivitySub =>
      'Hiện khung giờ chụp trên Dynamic Island / Màn hình khóa từ 30 phút trước giờ nhắc (hoặc từ 18:00 khi đang có chuỗi) và tự tắt ngay khi bạn chụp xong.';

  @override
  String get widgets_liveActivitySubAndroid =>
      'Hiện khung giờ chụp trên thanh trạng thái và Màn hình khóa từ 30 phút trước giờ nhắc (hoặc từ 18:00 khi đang có chuỗi) và tự tắt ngay khi bạn chụp xong.';

  @override
  String get widgets_secSetup => 'cách thêm ra màn hình chính';

  @override
  String get widgets_setupStep1Title =>
      '1. Chạm và giữ Màn hình chính hoặc Màn hình khóa';

  @override
  String get widgets_setupStep1TitleAndroid => '1. Chạm và giữ Màn hình chính';

  @override
  String get widgets_setupStep1Body =>
      'Chạm giữ vùng trống đến khi các biểu tượng rung nhẹ, sau đó chọn Sửa hoặc Tiện ích (Widgets).';

  @override
  String get widgets_setupStep2Title => '2. Tìm Ourney trong thư viện tiện ích';

  @override
  String get widgets_setupStep2Body =>
      'Chọn mẫu Hôm nay (2×2, 4×2, 4×4), Chuỗi sticker (2×2) hoặc Đồng đội (4×2, 4×4).';

  @override
  String get widgets_setupStep3Title =>
      '3. Chạm \"Chụp ngay\" để mở thẳng máy ảnh';

  @override
  String get widgets_setupStep3Body =>
      'Mỗi tiện ích mở thẳng khung ngắm của đúng hành trình đó trong chưa đầy 1 giây.';
}
