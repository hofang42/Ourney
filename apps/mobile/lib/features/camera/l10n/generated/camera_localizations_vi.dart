// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'camera_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class CameraL10nVi extends CameraL10n {
  CameraL10nVi([String locale = 'vi']) : super(locale);

  @override
  String get camera_title => 'Chụp check-in';

  @override
  String get camera_shutter => 'Chụp ảnh check-in';

  @override
  String camera_shutterFor(String journey) {
    return 'Chụp ảnh check-in cho $journey';
  }

  @override
  String get camera_flashOff => 'Đèn flash: tắt';

  @override
  String get camera_flashAuto => 'Đèn flash: tự động';

  @override
  String get camera_flashOn => 'Đèn flash: bật';

  @override
  String get camera_switchLens => 'Đổi camera trước/sau';

  @override
  String get camera_gallery => 'Chọn ảnh từ thư viện';

  @override
  String get camera_journeyPicker => 'Chọn hành trình';

  @override
  String get camera_journeysError => 'Không tải được hành trình';

  @override
  String get camera_noJourneyTitle => 'Bắt đầu hành trình đầu tiên';

  @override
  String get camera_noJourneyMessage =>
      'Tạo một hành trình, rồi mỗi ngày chụp một tấm để giữ chuỗi.';

  @override
  String get camera_noJourneyAction => 'Tạo hành trình';

  @override
  String get camera_prePromptTitle => 'Mỗi ngày một tấm ảnh';

  @override
  String get camera_prePromptMessage =>
      'Ourney cần camera để bạn chụp ảnh check-in. Ảnh chỉ được đăng khi bạn bấm Đăng.';

  @override
  String get camera_prePromptAction => 'Cho phép camera';

  @override
  String get camera_deniedTitle => 'Chưa có quyền camera';

  @override
  String get camera_deniedMessage =>
      'Bật quyền camera để chụp check-in. Bạn vẫn có thể chọn ảnh từ thư viện.';

  @override
  String get camera_deniedSettingsPath =>
      'Vào Cài đặt › Ứng dụng › Ourney › Quyền › Camera, bật lên rồi quay lại.';

  @override
  String get camera_openSettings => 'Mở Cài đặt';

  @override
  String get camera_restrictedMessage =>
      'Camera đang bị giới hạn trên máy này. Bạn vẫn có thể chọn ảnh từ thư viện.';

  @override
  String get camera_unavailableTitle => 'Không tìm thấy camera';

  @override
  String get camera_unavailableMessage =>
      'Máy này không có camera dùng được. Hãy chọn ảnh từ thư viện.';

  @override
  String get camera_failedTitle => 'Camera chưa mở được';

  @override
  String get camera_starting => 'Đang mở camera…';

  @override
  String get camera_captureFailed => 'Chụp chưa được. Thử lại nhé.';

  @override
  String get camera_grid => 'Lưới căn khung';

  @override
  String camera_dayHud(int day) {
    return 'Ngày $day';
  }

  @override
  String get camera_swipeHint => 'Vuốt để sang hành trình khác';

  @override
  String camera_streakChip(int days) {
    return 'Chuỗi $days ngày';
  }
}
