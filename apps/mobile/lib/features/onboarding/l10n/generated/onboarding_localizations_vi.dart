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
  String get onboarding_cameraTitle => 'cho Ourney dùng camera.';

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
  String get onboarding_notNow => 'để sau vậy.';

  @override
  String onboarding_quizStep(int n) {
    return 'Câu $n/3';
  }

  @override
  String get onboarding_quizBack => 'Câu trước';

  @override
  String get onboarding_quizQ1 => 'bạn đang muốn kiên trì điều gì?';

  @override
  String get onboarding_quizQ2 => 'đi một mình hay có hội?';

  @override
  String get onboarding_quizQ3 => 'bạn hay quên vào lúc nào?';

  @override
  String get onboarding_goalWeight => 'Giảm cân';

  @override
  String get onboarding_goalEnglish => 'Học tiếng Anh';

  @override
  String get onboarding_goalWorkout => 'Tập luyện';

  @override
  String get onboarding_goalTrip => 'Một chuyến đi';

  @override
  String get onboarding_goalCouple => 'Nghi thức của hai đứa';

  @override
  String get onboarding_goalHabit => 'Một thói quen nhỏ';

  @override
  String get onboarding_whoSolo => 'Một mình';

  @override
  String get onboarding_whoSoloHint => 'chỉ mình bạn thấy';

  @override
  String get onboarding_whoGroup => 'Rủ hội bạn';

  @override
  String get onboarding_whoGroupHint => 'tối đa 10 người';

  @override
  String get onboarding_whoCouple => 'Chỉ hai đứa';

  @override
  String get onboarding_whoCoupleHint => 'ghép đôi, chỉ hai người';

  @override
  String get onboarding_coupleStyleHint =>
      'mình sẽ dùng phong cách Hai đứa mình';

  @override
  String get onboarding_remMorning => 'Sáng sớm';

  @override
  String get onboarding_remNoon => 'Trưa';

  @override
  String get onboarding_remNight => 'Tối muộn';

  @override
  String onboarding_remHint(String time) {
    return 'gợi ý nhắc lúc $time';
  }

  @override
  String get onboarding_quizResultTitle => 'hành trình đầu tiên của bạn.';

  @override
  String onboarding_quizRemind(String time) {
    return 'Nhắc $time';
  }

  @override
  String get onboarding_quizContinue => 'Tiếp tục';

  @override
  String get onboarding_quizStart => 'Bắt đầu thôi';
}
