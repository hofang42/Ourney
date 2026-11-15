// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'import_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class ImportL10nVi extends ImportL10n {
  ImportL10nVi([String locale = 'vi']) : super(locale);

  @override
  String get import_headerTitle => 'nhập hành trình cũ.';

  @override
  String get import_back => 'Quay lại';

  @override
  String get import_setupTitle => 'Chọn loại và giao diện.';

  @override
  String get import_type_weight => 'Giảm cân';

  @override
  String get import_type_study => 'Tiếng Anh';

  @override
  String get import_type_trip => 'Chuyến đi';

  @override
  String get import_type_couple => 'Cặp đôi';

  @override
  String get import_type_workout => 'Tập luyện';

  @override
  String get import_type_custom => 'Tự đặt';

  @override
  String get import_placeLabel => 'Tên hoặc địa điểm';

  @override
  String get import_placeHint => 'Hành trình đã qua';

  @override
  String get import_layoutHeading => 'Giao diện';

  @override
  String get import_layout_quiet => 'Quiet';

  @override
  String get import_layout_memory => 'Memory';

  @override
  String get import_layout_flexer => 'Flexer';

  @override
  String get import_layout_minimal => 'Minimalist';

  @override
  String get import_layoutNote =>
      'Một số giao diện cần thêm dữ liệu nên không hiện.';

  @override
  String get import_previewLabel => 'XEM TRƯỚC';

  @override
  String get import_previewHud => 'HUD máy ảnh';

  @override
  String get import_pickOld => 'Chọn ảnh cũ';

  @override
  String get import_libraryTitle => 'Chọn ảnh cũ.';

  @override
  String get import_libraryIntro =>
      'Chọn nhiều ảnh. Ourney đọc ngày chụp để xếp vào hành trình.';

  @override
  String get import_openLibrary => 'Chọn từ thư viện';

  @override
  String get import_addMore => 'Thêm ảnh';

  @override
  String get import_libraryEmptyTitle => 'Chưa có ảnh nào';

  @override
  String get import_libraryEmptyBody =>
      'Chọn ảnh cũ từ thư viện để dựng lại hành trình.';

  @override
  String get import_noDate => 'Không có ngày';

  @override
  String import_selectPhoto(String date) {
    return 'Chọn ảnh $date';
  }

  @override
  String import_deselectPhoto(String date) {
    return 'Bỏ chọn ảnh $date';
  }

  @override
  String import_reviewButton(int count) {
    return 'Xem lại $count ảnh';
  }

  @override
  String get import_reviewTitle => 'Xem lại trong dòng thời gian.';

  @override
  String import_dayLabel(int day) {
    return 'Ngày $day';
  }

  @override
  String get import_noPhotos => 'Chưa có ảnh';

  @override
  String import_fromLibrary(String date) {
    return '$date · từ thư viện';
  }

  @override
  String get import_extraInDay => 'ảnh thêm trong ngày';

  @override
  String get import_undatedTitle => 'Chưa có ngày';

  @override
  String get import_assignDate => 'Gán ngày';

  @override
  String get import_drop => 'Bỏ';

  @override
  String get import_startLabel => 'Bắt đầu';

  @override
  String get import_endLabel => 'Kết thúc';

  @override
  String get import_continueTitle => 'Chụp tiếp';

  @override
  String get import_continueBody =>
      'Chuỗi bắt đầu từ ảnh chụp thật đầu tiên; ảnh nhập không tính chuỗi.';

  @override
  String get import_privateNote =>
      'Số kg vẫn ẩn và ảnh vẫn làm mờ khi chia sẻ.';

  @override
  String get import_save => 'Lưu hành trình';

  @override
  String import_saving(int done, int total) {
    return 'Đang lưu $done/$total ảnh…';
  }

  @override
  String import_failed(int count) {
    return '$count ảnh chưa lưu được';
  }

  @override
  String get import_retry => 'Thử lại';

  @override
  String get import_openJourney => 'Mở hành trình';

  @override
  String get import_errorNoPhotos => 'Chọn ít nhất một ảnh có ngày.';

  @override
  String get import_errorUndated => 'Gán ngày hoặc bỏ các ảnh chưa có ngày.';

  @override
  String get import_errorTitle => 'Nhập tên hoặc địa điểm.';

  @override
  String get import_errorOutside => 'Có ảnh nằm ngoài khoảng ngày đã chọn.';

  @override
  String get import_errorFuture => 'Ngày kết thúc không thể ở tương lai.';

  @override
  String get import_errorRange => 'Hành trình tối đa 366 ngày.';

  @override
  String get import_errorGeneric => 'Không lưu được hành trình. Thử lại nhé.';

  @override
  String get import_pickFailed => 'Không mở được thư viện ảnh.';
}
