// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'update_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class UpdateL10nVi extends UpdateL10n {
  UpdateL10nVi([String locale = 'vi']) : super(locale);

  @override
  String update_hubTitle(String version) {
    return 'Có bản Ourney $version mới';
  }

  @override
  String get update_hubFallbackSub =>
      'Cập nhật nhẹ để trải nghiệm các cải tiến mới nhất khi bạn tiện.';

  @override
  String get update_hubAction => 'Xem';

  @override
  String get update_hubDismissLabel => 'Ẩn lời nhắc bản cập nhật này';

  @override
  String update_softEyebrow(String version) {
    return 'BẢN MỚI · $version';
  }

  @override
  String update_softTitle(String version) {
    return 'Có bản Ourney $version mới';
  }

  @override
  String get update_softSubtitle =>
      'Một vài điểm mới đã sẵn sàng cho hành trình của bạn. Bạn có thể cập nhật ngay hoặc để lúc khác.';

  @override
  String get update_ctaUpdate => 'Cập nhật ngay';

  @override
  String get update_ctaLater => 'Để sau';

  @override
  String update_ctaSkipVersion(String version) {
    return 'Bỏ qua bản $version';
  }

  @override
  String get update_androidInstallHint =>
      'Tải xong, mở file Ourney.apk trên thanh thông báo để cài đè. Hành trình và ảnh của bạn vẫn giữ nguyên.';

  @override
  String update_gateEyebrow(String version) {
    return 'CẬP NHẬT CẦN THIẾT · $version';
  }

  @override
  String get update_gateTitle => 'Cập nhật Ourney để tiếp tục';

  @override
  String update_gateBody(String installed, String latest) {
    return 'Bản $installed trên máy cần nâng lên $latest để đồng bộ an toàn với hệ thống mới. Mọi hành trình và ảnh đã chụp của bạn vẫn được giữ nguyên.';
  }

  @override
  String update_gateIosManualHint(String latest) {
    return 'Vui lòng cài bản Ourney $latest mới nhất qua TestFlight hoặc công cụ cài đặt bạn đang dùng để tiếp tục.';
  }

  @override
  String update_gateWhatsNewToggle(String version) {
    return 'Xem có gì mới ở bản $version';
  }

  @override
  String get update_gateOfflineNotice =>
      'Bạn đang ngoại tuyến. Kết nối mạng để tải bản cập nhật hoặc kiểm tra lại.';

  @override
  String get update_ctaRetryCheck => 'Kiểm tra lại';

  @override
  String get update_ctaContactSupport => 'Cần hỗ trợ cài đặt?';

  @override
  String get update_launchFailed =>
      'Không mở được trình duyệt. Bạn có thể tải trực tiếp tại ourney.tech.';

  @override
  String update_whatsNewEyebrow(String version) {
    return 'ĐÃ CẬP NHẬT · $version';
  }

  @override
  String update_whatsNewTitle(String version) {
    return 'Có gì mới ở Ourney $version';
  }

  @override
  String get update_whatsNewDone => 'Tuyệt vời';
}
