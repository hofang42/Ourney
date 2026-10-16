// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'onboarding_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class OnboardingL10nVi extends OnboardingL10n {
  OnboardingL10nVi([String locale = 'vi']) : super(locale);

  @override
  String get onboarding_title => 'Chào mừng đến Ourney';

  @override
  String get onboarding_start => 'Bắt đầu';

  @override
  String get onboarding_next => 'Tiếp tục';

  @override
  String get onboarding_skip => 'Bỏ qua';

  @override
  String get onboarding_valueTitle => 'Mỗi ngày một tấm. Thấy rõ mình tiến bộ.';

  @override
  String get onboarding_valueBody =>
      'Ourney biến thói quen nhỏ thành một hành trình: giảm cân, học tiếng Anh, tập luyện hay một chuyến đi.';

  @override
  String get onboarding_howTitle => 'Check-in chỉ mất 5 giây';

  @override
  String get onboarding_howStep1 => 'Mở app là chụp ngay';

  @override
  String get onboarding_howStep2 =>
      'Gắn ảnh vào hành trình, thêm ghi chú hoặc số đo';

  @override
  String get onboarding_howStep3 => 'Giữ chuỗi ngày và rủ bạn bè cùng làm';

  @override
  String get onboarding_readyTitle => 'Sẵn sàng chưa?';

  @override
  String get onboarding_readyBody =>
      'Ourney chỉ xin quyền camera và thông báo đúng lúc cần, không làm phiền bạn ngay bây giờ.';

  @override
  String onboarding_pageSemantics(int current, int total) {
    return 'Trang $current trên $total';
  }
}
