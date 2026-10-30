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
  String get onboarding_next => 'Tiếp tục';

  @override
  String get onboarding_skip => 'Bỏ qua';

  @override
  String get onboarding_languageSwitch => 'English';

  @override
  String get onboarding_languageSwitchHint => 'Đổi ngôn ngữ';

  @override
  String get onboarding_page1Title => 'Từng tấm ảnh. Cả một câu chuyện.';

  @override
  String get onboarding_page1Body =>
      'Ghi lại hôm nay để thấy câu chuyện lớn dần.';

  @override
  String get onboarding_page2Title =>
      'Hành trình nào cũng được. Một mình, cùng nhóm, hay cùng người thương.';

  @override
  String get onboarding_page2Body => 'Chọn cách đồng hành phù hợp với bạn.';

  @override
  String get onboarding_page3Title =>
      'Biến hành trình thành thứ đáng để chia sẻ.';

  @override
  String get onboarding_page3Body =>
      'Tạo nên những bản tổng kết bạn muốn giữ mãi.';

  @override
  String get onboarding_recapTitle => '30 ngày yên tĩnh';

  @override
  String get onboarding_recapSubtitle => 'Đọc sách mỗi ngày · Tháng 10';

  @override
  String get onboarding_recapShare => 'Đáng để chia sẻ';

  @override
  String onboarding_pageSemantics(int current, int total) {
    return 'Trang $current trên $total';
  }

  @override
  String get onboarding_cameraTitle => 'Cho phép dùng camera';

  @override
  String get onboarding_cameraBody => 'Ourney cần camera để chụp ảnh hôm nay.';

  @override
  String get onboarding_cameraAllow => 'Cho phép camera';

  @override
  String onboarding_nudgeTitle(String time) {
    return 'Nhắc bạn lúc $time ngày mai nhé?';
  }

  @override
  String get onboarding_nudgeAllow => 'Bật nhắc nhở';

  @override
  String get onboarding_notNow => 'Để sau';
}
