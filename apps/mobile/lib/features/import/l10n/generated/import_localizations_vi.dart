// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'import_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class ImportL10nVi extends ImportL10n {
  ImportL10nVi([String locale = 'vi']) : super(locale);

  @override
  String get import_headerTitle => 'Kể lại hành trình đã qua';

  @override
  String get import_back => 'Quay lại';

  @override
  String import_stepOf(int n) {
    return 'Bước $n/3';
  }

  @override
  String get import_photosTitle => 'Chọn ảnh của bạn.';

  @override
  String get import_photosIntro =>
      'Chọn ảnh của hành trình bạn muốn kể lại. Ourney đọc ngày chụp của từng ảnh để xếp vào dòng thời gian.';

  @override
  String get import_openLibrary => 'Mở thư viện ảnh';

  @override
  String get import_addMore => 'Thêm ảnh';

  @override
  String get import_libraryEmptyTitle => 'Chưa có ảnh nào';

  @override
  String get import_libraryEmptyBody =>
      'Chọn ảnh cũ trong thư viện để dựng lại hành trình.';

  @override
  String import_selectedCount(int selected, int total) {
    return 'Đã chọn $selected/$total ảnh';
  }

  @override
  String get import_selectAll => 'Chọn tất cả';

  @override
  String get import_selectNone => 'Bỏ chọn tất cả';

  @override
  String import_selectPhoto(String date) {
    return 'Chọn ảnh $date';
  }

  @override
  String import_deselectPhoto(String date) {
    return 'Bỏ chọn ảnh $date';
  }

  @override
  String import_nextTimeline(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ảnh',
    );
    return 'Tiếp · $_temp0';
  }

  @override
  String import_pickLimit(int max) {
    return 'Một hành trình nhận tối đa $max ảnh. Các ảnh dư đã được bỏ qua.';
  }

  @override
  String import_duplicatesSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã bỏ qua $count ảnh trùng',
    );
    return '$_temp0';
  }

  @override
  String get import_pickFailed => 'Không mở được thư viện ảnh.';

  @override
  String import_maxReached(int max) {
    return 'Bạn đã chọn đủ $max ảnh.';
  }

  @override
  String get import_timelineTitle => 'Kiểm tra dòng thời gian.';

  @override
  String get import_timelineIntro =>
      'Ngày lấy từ ảnh. Chạm vào lịch để đổi ngày, chạm vào ảnh để viết vài dòng.';

  @override
  String import_rangeLine(String range, String days) {
    return '$range · $days';
  }

  @override
  String import_days(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ngày',
    );
    return '$_temp0';
  }

  @override
  String import_dayLabel(int day) {
    return 'Ngày $day';
  }

  @override
  String import_dayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ảnh',
    );
    return '$_temp0';
  }

  @override
  String import_gapRow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ngày không có ảnh',
    );
    return '$_temp0';
  }

  @override
  String get import_undatedTitle => 'Chưa có ngày';

  @override
  String get import_undatedBody =>
      'Hãy đặt ngày hoặc xóa các ảnh này để tiếp tục.';

  @override
  String get import_setDateAllUndated => 'Đặt ngày cho tất cả';

  @override
  String import_editDate(String date) {
    return 'Đổi ngày của ảnh này, hiện là $date';
  }

  @override
  String get import_noDate => 'Chưa có ngày';

  @override
  String get import_selectMode => 'Chọn nhiều';

  @override
  String get import_selectDone => 'Xong';

  @override
  String import_bulkSetDate(int count) {
    return 'Đặt ngày · $count';
  }

  @override
  String import_bulkRemove(int count) {
    return 'Xóa · $count';
  }

  @override
  String get import_removePhoto => 'Xóa ảnh';

  @override
  String import_photoRemoved(int count) {
    return 'Đã bỏ $count ảnh khỏi danh sách.';
  }

  @override
  String get import_undo => 'Hoàn tác';

  @override
  String get import_sourceExif => 'Ngày chụp';

  @override
  String get import_sourceFile => 'Ngày của tệp';

  @override
  String get import_sourceManual => 'Bạn tự đặt';

  @override
  String get import_errorRange =>
      'Một hành trình dài tối đa 366 ngày. Hãy đổi bớt ngày hoặc xóa ảnh.';

  @override
  String get import_next => 'Tiếp';

  @override
  String get import_detailsTitle => 'Đặt tên cho hành trình.';

  @override
  String get import_nameLabel => 'Tên hoặc địa điểm';

  @override
  String get import_nameHint => 'Một hành trình đã qua';

  @override
  String get import_errorTitle => 'Hãy nhập tên cho hành trình.';

  @override
  String get import_typeHeading => 'Loại';

  @override
  String get import_type_weight => 'Giảm cân';

  @override
  String get import_type_study => 'Tiếng Anh';

  @override
  String get import_type_trip => 'Chuyến đi';

  @override
  String get import_type_workout => 'Tập luyện';

  @override
  String get import_type_custom => 'Tự đặt';

  @override
  String get import_layoutHeading => 'Giao diện';

  @override
  String get import_layout_quiet => 'Tĩnh lặng';

  @override
  String get import_layout_memory => 'Kỷ niệm';

  @override
  String get import_layout_flexer => 'Thể thao';

  @override
  String get import_layout_minimal => 'Tối giản';

  @override
  String get import_layoutNote =>
      'Một số giao diện cần thêm dữ liệu nên chỉ hiện với loại dùng chúng.';

  @override
  String get import_previewLabel => 'XEM TRƯỚC';

  @override
  String get import_previewHud => 'Check-in mỗi ngày';

  @override
  String get import_continueTitle => 'Vẫn đang tiếp tục?';

  @override
  String get import_continueBody =>
      'Giữ hành trình mở để bạn check-in tiếp. Chuỗi ngày chỉ tính các check-in mới, ảnh kể lại không được tính.';

  @override
  String get import_privacyNote =>
      'Chỉ mình bạn thấy hành trình này cho đến khi bạn chia sẻ. Ẩn cân nặng và làm mờ ảnh khi chia sẻ theo phần Cài đặt của bạn.';

  @override
  String get import_save => 'Lưu hành trình';

  @override
  String import_summaryLine(int count, String range) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ảnh',
    );
    return '$_temp0 · $range';
  }

  @override
  String get import_savingTitle => 'Đang lưu hành trình.';

  @override
  String import_preparing(int done, int total) {
    return 'Đang chuẩn bị ảnh… $done/$total';
  }

  @override
  String get import_creating => 'Đang tạo hành trình…';

  @override
  String import_saving(int done, int total) {
    return 'Đang lưu $done/$total ảnh…';
  }

  @override
  String get import_pause => 'Dừng lại';

  @override
  String get import_pauseHint =>
      'Bạn có thể dừng lại. Các ảnh còn lại được giữ trên máy cho đến khi bạn tiếp tục.';

  @override
  String get import_pausedTitle => 'Đã dừng.';

  @override
  String get import_pausedBody =>
      'Việc lưu đã dừng. Các ảnh còn lại được giữ trên máy cho đến khi bạn tiếp tục.';

  @override
  String get import_resume => 'Tiếp tục lưu';

  @override
  String get import_partialTitle => 'Một số ảnh chưa được lưu.';

  @override
  String get import_dateSheetTitle => 'Chọn ngày';

  @override
  String get import_dateDay => 'Ngày';

  @override
  String get import_dateMonth => 'Tháng';

  @override
  String get import_dateYear => 'Năm';

  @override
  String get import_dateCancel => 'Hủy';

  @override
  String get import_createMaybeLanded =>
      'Hành trình có thể đã được tạo. Hãy thử lại để hoàn tất, hoặc thoát ra: ảnh vẫn được giữ trên máy và việc lưu sẽ tiếp tục sau.';

  @override
  String get import_abandon => 'Bỏ hành trình này';

  @override
  String get import_abandonTitle => 'Bỏ hành trình này?';

  @override
  String get import_abandonBody =>
      'Sẽ không lưu thêm gì nữa và các ảnh giữ trên máy sẽ bị xóa. Hành trình vẫn có thể xuất hiện trong danh sách của bạn, nhưng trống.';

  @override
  String get import_abandonConfirm => 'Bỏ';

  @override
  String get import_signedOutTitle => 'Đã đăng xuất.';

  @override
  String get import_signedOutBody =>
      'Đăng nhập lại để tiếp tục lưu. Ảnh vẫn được giữ trên máy.';

  @override
  String get import_dateConfirm => 'Dùng ngày này';

  @override
  String get import_cancelling => 'Đang dừng…';

  @override
  String get import_photoPending => 'Đang chờ';

  @override
  String get import_photoSaved => 'Đã lưu';

  @override
  String get import_photoFailed => 'Chưa lưu';

  @override
  String get import_reason_unreadable => 'Không đọc được tệp ảnh nữa';

  @override
  String get import_reason_offline => 'Không có kết nối';

  @override
  String get import_reason_badDate => 'Ngày không hợp lệ cho hành trình';

  @override
  String get import_reason_unknown => 'Đã có lỗi xảy ra';

  @override
  String get import_doneTitle => 'Xong rồi.';

  @override
  String import_savedSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã lưu $count ảnh',
    );
    return '$_temp0';
  }

  @override
  String import_notSaved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ảnh chưa lưu',
    );
    return '$_temp0';
  }

  @override
  String get import_openJourney => 'Mở hành trình';

  @override
  String get import_retryFailed => 'Thử lại các ảnh chưa lưu';

  @override
  String get import_leaveRest => 'Bỏ các ảnh còn lại';

  @override
  String get import_tryAgain => 'Thử lại';

  @override
  String get import_editDetails => 'Sửa thông tin';

  @override
  String get import_errorInvalid =>
      'Thông tin hành trình bị từ chối. Hãy kiểm tra tên và ngày.';

  @override
  String get import_discardTitle => 'Rời đi mà chưa lưu?';

  @override
  String get import_discardBody =>
      'Bản sao ảnh mà Ourney giữ trên máy sẽ bị xóa (ảnh trong thư viện của bạn vẫn còn).';

  @override
  String get import_discardConfirm => 'Rời đi';

  @override
  String get import_discardKeep => 'Tiếp tục';

  @override
  String get import_captionAddHint => 'Thêm chú thích…';

  @override
  String import_captionSheetEyebrow(int day, String date) {
    return 'Ngày $day · $date';
  }

  @override
  String get import_captionHint => 'Bạn nhớ gì về tấm ảnh này?';

  @override
  String get import_captionHelper => 'Không bắt buộc. Sửa được sau khi lưu.';

  @override
  String get import_captionPrev => 'Ảnh trước';

  @override
  String get import_captionNext => 'Ảnh tiếp';

  @override
  String get import_captionDone => 'Xong';

  @override
  String get import_captionEditDate => 'Đổi ngày';

  @override
  String import_captionOpen(String date) {
    return 'Viết chú thích cho ảnh ngày $date';
  }

  @override
  String get import_discardCaptions => 'Chú thích bạn đã viết cũng sẽ mất.';

  @override
  String get import_captionHideKeyboard => 'Đóng bàn phím';

  @override
  String import_captionEdit(Object caption, Object date) {
    return 'Sửa chú thích cho ảnh ngày $date: $caption';
  }
}
