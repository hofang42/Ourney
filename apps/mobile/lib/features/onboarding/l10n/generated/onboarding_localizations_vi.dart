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
  String get onboarding_skip => 'Bỏ qua';

  @override
  String get onboarding_cameraTitle => 'cho ourney dùng camera.';

  @override
  String get onboarding_cameraBody =>
      'Để chụp tấm đầu tiên của hành trình. Ảnh chỉ hiện với người trong hành trình đó.';

  @override
  String get onboarding_cameraAllow => 'Cho phép';

  @override
  String get onboarding_nudgeTitle => 'để mình khẽ nhắc trước khi chuỗi đứt.';

  @override
  String get onboarding_nudgeAllow => 'Cho phép';

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
  String get onboarding_quizQ2 => 'đi một mình hay cùng nhóm?';

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
  String get onboarding_whoGroup => 'Rủ nhóm bạn';

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

  @override
  String get onboarding_splashTagline1 => 'chụp một tấm.';

  @override
  String get onboarding_splashTagline2 => 'giữ một chuỗi.';

  @override
  String get onboarding_splashTagline3 => 'đi cùng nhau.';

  @override
  String get onboarding_splashStart => 'Bắt đầu';

  @override
  String get onboarding_splashOpening => 'Đang mở';

  @override
  String get onboarding_resultCouple => 'hai đứa mình.';

  @override
  String get onboarding_permissionClose => 'Đóng';

  @override
  String onboarding_nudgeBody(String time) {
    return 'Bật nhắc để mình nhắc bạn lúc $time. Có thể trễ tuỳ máy.';
  }
}
