// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'journeys_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class JourneysL10nVi extends JourneysL10n {
  JourneysL10nVi([String locale = 'vi']) : super(locale);

  @override
  String get journeys_title => 'Hành trình';

  @override
  String get journeys_activeSection => 'Đang chạy';

  @override
  String get journeys_finishedSection => 'Trên kệ';

  @override
  String get journeys_emptyTitle => 'Chưa có hành trình nào';

  @override
  String get journeys_emptyMessage =>
      'Bắt đầu hành trình đầu tiên: mỗi ngày một tấm ảnh.';

  @override
  String get journeys_newJourney => 'Hành trình mới';

  @override
  String journeys_dayOf(int day, int total) {
    return 'Ngày $day/$total';
  }

  @override
  String journeys_dayOpen(int day) {
    return 'Ngày $day';
  }

  @override
  String get journeys_checkedToday => 'Hôm nay đã check-in';

  @override
  String get journeys_notCheckedToday => 'Hôm nay chưa check-in';

  @override
  String get journeys_statusEnded => 'Đã kết thúc';

  @override
  String get journeys_statusArchived => 'Đã lưu trữ';

  @override
  String get journeys_kindSolo => 'Một mình';

  @override
  String get journeys_kindGroup => 'Nhóm';

  @override
  String get journeys_loadError => 'Không tải được hành trình.';

  @override
  String get journeys_pickTemplateTitle => 'Chọn kiểu hành trình';

  @override
  String journeys_templateDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ngày',
    );
    return '$_temp0';
  }

  @override
  String get journeys_templateCustomHint => 'Tự đặt mọi thứ';

  @override
  String get journeys_templateCoupleTitle => 'Nghi thức cặp đôi';

  @override
  String get journeys_templateCoupleHint =>
      'Hai người cùng lưu khoảnh khắc mỗi ngày';

  @override
  String get journeys_personaPreviewLabel => 'Xem trước giao diện';

  @override
  String get journeys_continueTemplateButton => 'Tiếp tục với kiểu này';

  @override
  String get journeys_createTitle => 'Tạo hành trình';

  @override
  String get journeys_fieldTitle => 'Tên hành trình';

  @override
  String get journeys_fieldEmoji => 'Biểu tượng';

  @override
  String journeys_emojiSemantics(String emoji) {
    return 'Biểu tượng $emoji';
  }

  @override
  String get journeys_fieldKind => 'Một mình hay cùng nhóm?';

  @override
  String get journeys_groupNeedsServer =>
      'Hành trình nhóm cần máy chủ. Bản này đang chạy chỉ trên máy.';

  @override
  String get journeys_fieldDuration => 'Thời lượng';

  @override
  String get journeys_durationCustom => 'Số ngày';

  @override
  String get journeys_openEnded => 'Không giới hạn';

  @override
  String get journeys_fieldMetric => 'Theo dõi một con số';

  @override
  String get journeys_fieldMetricHint => 'Ví dụ: cân nặng, số phút học';

  @override
  String get journeys_metricName => 'Tên chỉ số';

  @override
  String get journeys_metricUnit => 'Đơn vị';

  @override
  String get journeys_hideMetric => 'Ẩn con số với người khác';

  @override
  String get journeys_hideExtras =>
      'Ẩn tâm trạng, số phút và chi tiết với người khác';

  @override
  String get journeys_pin => 'Ghim lên đầu';

  @override
  String get journeys_unpin => 'Bỏ ghim';

  @override
  String get journeys_blurOnShare => 'Làm mờ ảnh khi chia sẻ ra ngoài';

  @override
  String get journeys_fieldVisibility => 'Ai xem được?';

  @override
  String get journeys_visibilityPrivate => 'Chỉ mình tôi';

  @override
  String get journeys_visibilityLink => 'Ai có link';

  @override
  String get journeys_visibilityGroup => 'Thành viên trong nhóm';

  @override
  String get journeys_linkNeedsServer => 'Link chia sẻ cần máy chủ.';

  @override
  String get journeys_fieldTimezone => 'Múi giờ';

  @override
  String get journeys_createButton => 'Bắt đầu hành trình';

  @override
  String get journeys_errorTitleEmpty => 'Đặt tên cho hành trình nhé.';

  @override
  String journeys_errorTitleTooLong(int max) {
    return 'Tên dài tối đa $max ký tự.';
  }

  @override
  String journeys_errorDuration(int min, int max) {
    return 'Thời lượng từ $min đến $max ngày.';
  }

  @override
  String get journeys_errorMetricName => 'Nhập tên chỉ số.';

  @override
  String get journeys_errorInvalid =>
      'Dữ liệu chưa hợp lệ. Kiểm tra lại rồi thử lại nhé.';

  @override
  String get journeys_errorLimit =>
      'Bạn có quá nhiều hành trình đang chạy. Kết thúc bớt một hành trình rồi thử lại nhé.';

  @override
  String get journeys_errorNotAlone =>
      'Nhóm vẫn còn thành viên khác nên chưa xóa được. Bạn có thể kết thúc hành trình.';

  @override
  String get journeys_errorForbidden => 'Chỉ chủ hành trình làm được việc này.';

  @override
  String get journeys_errorEnded => 'Hành trình này đã kết thúc.';

  @override
  String get journeys_errorSyncPending =>
      'Ảnh vẫn đang tải lên, thử lại sau ít phút.';

  @override
  String get journeys_errorNotFound => 'Không tìm thấy hành trình.';

  @override
  String get journeys_statCurrent => 'Chuỗi hiện tại';

  @override
  String get journeys_statBest => 'Dài nhất';

  @override
  String get journeys_statComplete => 'Hoàn thành';

  @override
  String get journeys_statDay => 'Tiến độ';

  @override
  String journeys_percent(int value) {
    return '$value%';
  }

  @override
  String get journeys_checkInNow => 'Check-in';

  @override
  String get journeys_share => 'Chia sẻ';

  @override
  String get journeys_openGroup => 'Xem nhóm';

  @override
  String get journeys_endJourney => 'Kết thúc hành trình';

  @override
  String get journeys_endConfirmTitle => 'Kết thúc hành trình?';

  @override
  String get journeys_endConfirmMessage =>
      'Sau khi kết thúc, hành trình chỉ xem được và không check-in thêm được nữa.';

  @override
  String get journeys_archive => 'Lưu trữ';

  @override
  String get journeys_archiveConfirmTitle => 'Lưu trữ hành trình?';

  @override
  String get journeys_archiveConfirmMessage =>
      'Hành trình sẽ được ẩn khỏi danh sách. Bạn có thể hoàn tác ngay sau khi lưu trữ.';

  @override
  String get journeys_archived => 'Đã lưu trữ hành trình';

  @override
  String get journeys_archiveUndo => 'Hoàn tác';

  @override
  String get journeys_archivedSection => 'Đã lưu trữ';

  @override
  String get journeys_unarchive => 'Bỏ lưu trữ';

  @override
  String get journeys_delete => 'Xóa hành trình';

  @override
  String get journeys_deleteConfirmTitle => 'Xóa hành trình?';

  @override
  String get journeys_deleteConfirmMessage =>
      'Mọi ảnh của bạn trong hành trình này sẽ bị xóa. Không hoàn tác được.';

  @override
  String get journeys_readOnlyBanner => 'Hành trình đã kết thúc. Chỉ xem.';

  @override
  String get journeys_moreActions => 'Thêm thao tác';

  @override
  String get journeys_timelineTitle => 'Dòng thời gian';

  @override
  String get journeys_privacyTitle => 'Riêng tư';

  @override
  String journeys_cellChecked(int day, String date) {
    return 'Ngày $day, $date: đã check-in';
  }

  @override
  String journeys_cellMissed(int day, String date) {
    return 'Ngày $day, $date: chưa chụp';
  }

  @override
  String journeys_cellToday(int day, String date) {
    return 'Ngày $day, $date: hôm nay, chưa check-in';
  }

  @override
  String journeys_cellFuture(int day, String date) {
    return 'Ngày $day, $date: sắp tới';
  }

  @override
  String journeys_cellNotCounted(int day, String date) {
    return 'Ngày $day, $date: trước khi bạn tham gia';
  }

  @override
  String get journeys_today => 'Hôm nay';

  @override
  String get journeys_fromLibrary => 'Từ thư viện';

  @override
  String get journeys_metricHidden => 'Đang ẩn';

  @override
  String get journeys_showMetric => 'Hiện con số';

  @override
  String get journeys_photoUnavailable => 'Ảnh chưa tải được';

  @override
  String get journeys_noCheckIn => 'Chưa có ảnh cho ngày này';

  @override
  String journeys_dayPhotoCount(int index, int count) {
    return '$index/$count';
  }

  @override
  String journeys_dayPhotoCountSemantics(int index, int count) {
    return 'Ảnh $index trên $count của ngày này. Vuốt để xem ảnh khác.';
  }

  @override
  String get journeys_greetingMorning => 'Chào buổi sáng';

  @override
  String get journeys_greetingAfternoon => 'Chào buổi chiều';

  @override
  String get journeys_greetingEvening => 'Chào buổi tối';

  @override
  String journeys_greetingNamed(String greeting, String name) {
    return '$greeting, $name';
  }

  @override
  String journeys_remainingToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Còn $count hành trình chờ ảnh hôm nay.',
    );
    return '$_temp0';
  }

  @override
  String get journeys_allDonePrompt =>
      'Hôm nay xong hết rồi. Hẹn bạn ngày mai.';

  @override
  String get journeys_allDoneTitle => 'Xong hết hôm nay';

  @override
  String get journeys_todayLabel => 'Hôm nay';

  @override
  String journeys_dayShort(int day, int total) {
    return 'Ngày $day/$total';
  }

  @override
  String get journeys_streakWord => 'ngày liên tiếp';

  @override
  String get journeys_openToday => 'Hôm nay đang mở';

  @override
  String get journeys_startsToday => 'Bắt đầu hôm nay';

  @override
  String get journeys_lastSevenDays => 'Bảy ngày gần nhất';

  @override
  String get journeys_snapToday => 'Chụp hôm nay';

  @override
  String get journeys_yourJourneys => 'Hành trình của bạn';

  @override
  String get journeys_rowDone => 'Xong';

  @override
  String get journeys_rowNotYet => 'Chưa';

  @override
  String get journeys_privacyPrivate => 'Riêng tư';

  @override
  String get journeys_privacyLink => 'Bật link';

  @override
  String get journeys_privacyGroup => 'Nhóm';

  @override
  String get journeys_addJourney => 'Thêm hành trình';

  @override
  String get journeys_shelfEmpty =>
      'Hành trình đã xong sẽ nằm ở đây để bạn xem lại.';

  @override
  String get journeys_activeEmpty => 'Hiện chưa có hành trình nào đang chạy.';

  @override
  String get journeys_tagWeightLoss => 'Nhìn những thay đổi nhỏ cộng lại.';

  @override
  String get journeys_tagEnglish => 'Giữ động lực cho cả nhóm.';

  @override
  String get journeys_tagTravel => 'Lưu lại từng ngày đi xa.';

  @override
  String get journeys_tagCouple => 'Nhớ về từng khoảnh khắc chung.';

  @override
  String get journeys_tagWorkout => 'Tiến lên qua từng buổi tập.';

  @override
  String get journeys_tagCustom => 'Tạo theo cách của bạn.';

  @override
  String get journeys_modeSoloOnly => 'Chỉ cá nhân';

  @override
  String get journeys_modeSoloGroup => 'Cá nhân · Nhóm';

  @override
  String get journeys_modeCoupleOnly => 'Chỉ cặp đôi';

  @override
  String get journeys_styleLocked => 'Phong cách không đổi được sau khi tạo';

  @override
  String get journeys_moreOptions => 'Tùy chọn khác';

  @override
  String get journeys_statMoments => 'Khoảnh khắc';

  @override
  String get journeys_daysUnit => 'ngày';

  @override
  String journeys_dateRange(String start, String end) {
    return '$start — $end';
  }

  @override
  String journeys_sinceDate(String start) {
    return 'Từ $start';
  }

  @override
  String get journeys_addMore => 'Chụp thêm ảnh hôm nay';

  @override
  String get journeys_statCurrentShort => 'Hiện tại';

  @override
  String get journeys_sharedSection => 'Được chia sẻ';

  @override
  String get journeys_retell => 'Kể lại hành trình đã qua';

  @override
  String get journeys_imported => 'Kể lại';

  @override
  String get journeys_shareCard => 'Tạo thẻ chia sẻ';

  @override
  String get journeys_back => 'Quay lại';

  @override
  String get journeys_shelfIntro =>
      'Những hành trình đã xong, được giữ như album.';

  @override
  String get journeys_dayZeroBody =>
      'Mỗi ngày một tấm ảnh để giữ lại hành trình. Bắt đầu với điều bạn quan tâm.';

  @override
  String get journeys_dayZeroStart => 'Tạo hành trình đầu tiên';

  @override
  String journeys_greetingHi(String name) {
    return 'Chào $name';
  }

  @override
  String journeys_todayLeft(int count) {
    return 'Còn $count';
  }

  @override
  String get journeys_todayAtRisk => 'Đang có chuỗi';

  @override
  String get journeys_todayRest => 'Còn lại';

  @override
  String get journeys_openJourneys => 'Mở hành trình';

  @override
  String journeys_doneOf(int done, int total) {
    return '$done/$total đã xong';
  }

  @override
  String get journeys_shareMakeCard => 'Tạo thẻ chia sẻ';

  @override
  String get journeys_shareMakeCardHint => 'Chia sẻ một khoảnh khắc';

  @override
  String get journeys_shareJourney => 'Chia sẻ hành trình này';

  @override
  String get journeys_shareJourneyHint => 'Chọn bạn bè có thể theo dõi';

  @override
  String journeys_albumDays(int done, int total) {
    return '$done/$total ngày';
  }

  @override
  String journeys_albumMoments(int count) {
    return '$count khoảnh khắc';
  }

  @override
  String get journeys_streakDaysLabel => 'ngày liên tiếp';

  @override
  String get journeys_ticketPrivate => 'HỒ SƠ RIÊNG TƯ';

  @override
  String get journeys_ticketMemory => 'VÉ KÝ ỨC';

  @override
  String get journeys_ticketChangeColor => 'Đổi màu';

  @override
  String get journeys_ticketYou => 'Bạn';

  @override
  String get journeys_ticketPartner => 'Người ấy';

  @override
  String get journeys_ticketOpenEnded => 'không hẹn ngày về';

  @override
  String journeys_ticketMilestone(String day) {
    return 'Ngày $day';
  }

  @override
  String journeys_ticketDates(String start, String end) {
    return '$start – $end';
  }

  @override
  String journeys_ticketDatesOpen(String start) {
    return 'Từ $start';
  }

  @override
  String get journeys_ticketTagQuiet => 'Chỉ mình bạn thấy. Từng chút một.';

  @override
  String get journeys_ticketTagSquad => 'Check-in mỗi ngày, cả nhóm cùng lên!';

  @override
  String get journeys_ticketTagMemory => 'Mang về thật nhiều khung hình.';

  @override
  String get journeys_ticketTagCouple =>
      'Mỗi ngày một nửa, ghép lại thành một.';

  @override
  String get journeys_ticketTagFlexer => 'Bền bỉ từng bước. Chạy tiếp.';

  @override
  String get journeys_ticketTagFlexerTrain => 'Bền bỉ từng buổi. Tập tiếp.';

  @override
  String get journeys_ticketPreview => 'Xem trước vé khởi hành';

  @override
  String get journeys_coupleYou => 'Bạn';

  @override
  String get journeys_coupleWaiting => 'Đang chờ người ấy';

  @override
  String journeys_createStepOf(int step, int total) {
    return 'Bước $step/$total';
  }

  @override
  String get journeys_createNext => 'Tiếp tục';

  @override
  String get journeys_createExit => 'Thoát tạo hành trình';

  @override
  String get journeys_createPickSubtitle => 'Chạm một kiểu để bắt đầu.';

  @override
  String get journeys_createChosen => 'Đã chọn';

  @override
  String get journeys_createDetailTitle => 'Đặt tên và mục tiêu.';

  @override
  String get journeys_createWhoTitle => 'Đi cùng ai?';

  @override
  String get journeys_kindCouple => 'Chỉ hai đứa';

  @override
  String get journeys_kindSoloBody => 'Chỉ bạn và chiếc máy ảnh.';

  @override
  String get journeys_kindGroupBody => 'Tối đa 10 người, mời bằng mã.';

  @override
  String get journeys_kindCoupleBody => 'Một cặp, một nhịp.';

  @override
  String get journeys_coupleNameYou => 'Tên bạn';

  @override
  String get journeys_coupleNameOther => 'Tên người ấy';

  @override
  String get journeys_errorCoupleNames => 'Nhập tên cả hai người.';

  @override
  String get journeys_createRhythmTitle => 'Đặt nhịp.';

  @override
  String get journeys_fieldStartDate => 'Ngày bắt đầu';

  @override
  String get journeys_calendarPrev => 'Tháng trước';

  @override
  String get journeys_calendarNext => 'Tháng sau';

  @override
  String journeys_calendarRange(String start, String end) {
    return 'Từ $start đến $end';
  }

  @override
  String get journeys_createReviewTitle => 'Vé khởi hành của bạn.';

  @override
  String get journeys_createReviewEdit => 'Sửa lại';

  @override
  String journeys_extraMinutes(int minutes) {
    return '$minutes phút';
  }

  @override
  String journeys_extraHearts(int count) {
    return '$count/5 tim';
  }

  @override
  String journeys_extraKm(String km) {
    return '$km km';
  }

  @override
  String journeys_extraPace(String pace) {
    return '$pace /km';
  }

  @override
  String journeys_extraCook(String name) {
    return '$name nấu';
  }

  @override
  String get journeys_extraMoodLight => 'Nhẹ nhõm';

  @override
  String get journeys_extraMoodNormal => 'Bình thường';

  @override
  String get journeys_extraMoodTired => 'Hơi mệt';

  @override
  String get journeys_uploaderAttachment => 'Ảnh bạn đã đính kèm vào bài này';

  @override
  String get journeys_coupleNoPhoto => 'Chưa có ảnh cho ngày này';

  @override
  String get journeys_inviteAction => 'Mời bạn';

  @override
  String get journeys_renameCouple => 'Sửa tên';

  @override
  String get journeys_renameCoupleTitle => 'Sửa tên cặp đôi';

  @override
  String get journeys_quietHidden => 'Đã ẩn';

  @override
  String journeys_quietDayTag(int day) {
    return 'NGÀY $day';
  }

  @override
  String get journeys_quietToday => 'HÔM NAY';

  @override
  String get journeys_quietWeek => 'TUẦN ĐẦU';

  @override
  String get journeys_quietHalf => 'NỬA CHẶNG';

  @override
  String get journeys_quietFinish => 'VỀ ĐÍCH';

  @override
  String get journeys_quietMilestones => 'Cột mốc';

  @override
  String get journeys_memoryToday => 'HÔM NAY · chạm để chụp';

  @override
  String get journeys_memoryEmpty => 'KHUNG TRỐNG';

  @override
  String journeys_memoryFilmRoll(int count) {
    return 'CUỘN PHIM · $count KHUNG';
  }

  @override
  String get journeys_memoryOffline => 'NGOẠI TUYẾN · chờ đồng bộ';

  @override
  String get journeys_dna_goal_title_weight => 'mục tiêu của bạn.';

  @override
  String get journeys_dna_weight_title => 'cân nặng hiện tại.';

  @override
  String get journeys_dna_goal_title_english => 'mục tiêu.';

  @override
  String get journeys_dna_minutes_title => 'mỗi ngày bao nhiêu phút.';

  @override
  String get journeys_dna_trophy_title => 'đặt tên chiếc cúp ở đích.';

  @override
  String get journeys_dna_sport_title => 'môn gì.';

  @override
  String get journeys_dna_measure_title => 'đo bằng gì.';

  @override
  String get journeys_dna_hud_title => 'kiểu HUD.';

  @override
  String get journeys_dna_place_title => 'đi đâu.';

  @override
  String get journeys_dna_dates_title => 'ngày đi – ngày về.';

  @override
  String get journeys_dna_film_title => 'cuộn phim mấy tấm.';

  @override
  String get journeys_dna_ritual_title => 'nghi thức của hai đứa.';

  @override
  String get journeys_dna_names_title => 'tên hai người.';

  @override
  String get journeys_dna_side_title => 'ai chụp nửa nào.';

  @override
  String get journeys_dna_habit_title => 'thói quen của bạn.';

  @override
  String get journeys_dna_c_goal_weight_lose => 'Giảm cân';

  @override
  String get journeys_dna_c_goal_weight_lose_hint =>
      'nhẹ đi, khỏe hơn mỗi ngày';

  @override
  String get journeys_dna_c_goal_weight_keep => 'Giữ dáng';

  @override
  String get journeys_dna_c_goal_weight_keep_hint =>
      'duy trì nhịp sống hiện tại';

  @override
  String get journeys_dna_c_goal_weight_shape => 'Thay đổi vóc dáng';

  @override
  String get journeys_dna_c_goal_weight_shape_hint =>
      'theo dõi một phiên bản mới';

  @override
  String get journeys_dna_c_goal_english_ielts => 'IELTS';

  @override
  String get journeys_dna_c_goal_english_ielts_hint =>
      'cùng nhau chạm band mục tiêu';

  @override
  String get journeys_dna_c_goal_english_talk => 'Giao tiếp';

  @override
  String get journeys_dna_c_goal_english_talk_hint =>
      'nói tự nhiên hơn mỗi ngày';

  @override
  String get journeys_dna_c_goal_english_read => 'Đọc sách';

  @override
  String get journeys_dna_c_goal_english_read_hint =>
      'đọc trọn cuốn sách đầu tiên';

  @override
  String get journeys_dna_c_minutes_15 => '15';

  @override
  String get journeys_dna_c_minutes_15_hint => '15 phút mỗi ngày';

  @override
  String get journeys_dna_c_minutes_30 => '30';

  @override
  String get journeys_dna_c_minutes_30_hint => '30 phút mỗi ngày';

  @override
  String get journeys_dna_c_minutes_45 => '45';

  @override
  String get journeys_dna_c_minutes_45_hint => '45 phút mỗi ngày';

  @override
  String get journeys_dna_c_minutes_60 => '60';

  @override
  String get journeys_dna_c_minutes_60_hint => '60 phút mỗi ngày';

  @override
  String get journeys_dna_c_sport_run => 'Chạy';

  @override
  String get journeys_dna_c_sport_run_hint => '30 ngày chạy';

  @override
  String get journeys_dna_c_sport_gym => 'Gym';

  @override
  String get journeys_dna_c_sport_gym_hint => '30 ngày gym';

  @override
  String get journeys_dna_c_sport_pilates => 'Pilates';

  @override
  String get journeys_dna_c_sport_pilates_hint => '30 ngày pilates';

  @override
  String get journeys_dna_c_sport_yoga => 'Yoga';

  @override
  String get journeys_dna_c_sport_yoga_hint => '30 ngày yoga';

  @override
  String get journeys_dna_c_sport_other => 'Khác';

  @override
  String get journeys_dna_c_sport_other_hint => '30 ngày khác';

  @override
  String get journeys_dna_c_measure_km => 'km';

  @override
  String get journeys_dna_c_measure_km_hint => 'ghi lại theo km';

  @override
  String get journeys_dna_c_measure_min => 'phút';

  @override
  String get journeys_dna_c_measure_min_hint => 'ghi lại theo phút';

  @override
  String get journeys_dna_c_measure_session => 'buổi';

  @override
  String get journeys_dna_c_measure_session_hint => 'ghi lại theo buổi';

  @override
  String get journeys_dna_c_hud_bold => 'HUD đậm';

  @override
  String get journeys_dna_c_hud_bold_hint => 'số lớn, tương phản mạnh';

  @override
  String get journeys_dna_c_hud_stamp => 'Tem tối giản';

  @override
  String get journeys_dna_c_hud_stamp_hint => 'gọn như một con tem';

  @override
  String get journeys_dna_c_hud_strip => 'Dải phim';

  @override
  String get journeys_dna_c_hud_strip_hint => 'khoảnh khắc nối tiếp nhau';

  @override
  String get journeys_dna_c_film_24 => '24 tấm';

  @override
  String get journeys_dna_c_film_24_hint => 'mỗi tấm đều được cân nhắc';

  @override
  String get journeys_dna_c_film_36 => '36 tấm';

  @override
  String get journeys_dna_c_film_36_hint => 'thêm chỗ cho điều bất ngờ';

  @override
  String get journeys_dna_c_ritual_cook => 'Nấu ăn';

  @override
  String get journeys_dna_c_ritual_cook_hint => 'cùng nhau nấu ăn';

  @override
  String get journeys_dna_c_ritual_save => 'Tiết kiệm';

  @override
  String get journeys_dna_c_ritual_save_hint => 'cùng nhau tiết kiệm';

  @override
  String get journeys_dna_c_ritual_ldr => 'Yêu xa';

  @override
  String get journeys_dna_c_ritual_ldr_hint => 'cùng nhau yêu xa';

  @override
  String get journeys_dna_c_ritual_custom => 'Tự đặt';

  @override
  String get journeys_dna_c_ritual_custom_hint => 'cùng nhau tự đặt';

  @override
  String get journeys_dna_c_side_left => 'Mình bên trái';

  @override
  String get journeys_dna_c_side_right => 'Mình bên phải';

  @override
  String journeys_dna_step_of_q(int n, int total) {
    return 'Câu $n/$total';
  }

  @override
  String get journeys_dna_weight_unit => 'kg';

  @override
  String get journeys_dna_weight_a11y => 'Cân nặng hiện tại';

  @override
  String get journeys_dna_weight_private => 'Chỉ mình bạn thấy';

  @override
  String get journeys_dna_weight_hide => 'Ẩn số kg khi chia sẻ';

  @override
  String get journeys_dna_weight_skip => 'Bỏ qua';

  @override
  String get journeys_dna_trophy_label => 'Tên chiếc cúp';

  @override
  String get journeys_dna_trophy_hint => 'Cúp 7.5';

  @override
  String get journeys_dna_place_search => 'Tìm điểm đến';

  @override
  String journeys_dna_place_limit(int max) {
    return 'Nhập tối đa $max ký tự.';
  }

  @override
  String get journeys_dna_dates_open => 'chưa hẹn ngày về';

  @override
  String get journeys_dna_dates_prompt => 'Chọn ngày đi và ngày về';

  @override
  String journeys_dna_dates_open_summary(String start) {
    return '$start · chưa hẹn ngày về';
  }

  @override
  String journeys_dna_dates_range_summary(String start, String end) {
    return '$start – $end';
  }

  @override
  String journeys_dna_dates_min_note(int days) {
    return 'Hành trình dài ít nhất $days ngày nên ngày về đã được lùi lại.';
  }

  @override
  String journeys_dna_dates_max_note(int days) {
    return 'Hành trình dài tối đa $days ngày nên ngày về đã được kéo gần lại.';
  }

  @override
  String get journeys_dna_prev_month => 'Tháng trước';

  @override
  String get journeys_dna_next_month => 'Tháng sau';

  @override
  String get journeys_dna_name_left => 'Tên bạn';

  @override
  String get journeys_dna_name_right => 'Tên người ấy';

  @override
  String get journeys_dna_habit_label => 'Thói quen';

  @override
  String get journeys_dna_habit_hint => 'Đọc 10 trang';

  @override
  String get journeys_dna_reason_label => 'vì sao.';

  @override
  String get journeys_dna_reason_hint => 'để ngủ ngon hơn';

  @override
  String get journeys_dna_forge_title => 'Đang tạo hành trình…';

  @override
  String get journeys_dna_forge_a11y => 'Đang tạo hành trình của bạn';

  @override
  String get journeys_dna_import_link => 'Kể lại hành trình đã qua';

  @override
  String get journeys_home_introQuiet => 'Nhìn lại từng chút một.';

  @override
  String get journeys_home_introSquad => 'hôm nay học bao lâu.';

  @override
  String get journeys_home_introMemory => 'Hôm nay cả bọn lạc ở đâu?';

  @override
  String get journeys_home_introCouple => 'Hôm nay hai đứa nấu gì?';

  @override
  String get journeys_home_introCoupleSave =>
      'Hôm nay hai đứa góp thêm được gì?';

  @override
  String get journeys_home_introCoupleLdr => 'Hôm nay hai đứa gửi gì cho nhau?';

  @override
  String get journeys_home_introCoupleCustom =>
      'Hôm nay hai đứa có khoảnh khắc gì cùng nhau?';

  @override
  String get journeys_home_offlineQuiet => 'Đang lưu trên máy · sẽ đồng bộ sau';

  @override
  String get journeys_home_offlineSquad =>
      'Đã lưu ảnh của bạn, có mạng sẽ gửi lên nhóm';

  @override
  String get journeys_home_offlineCouple =>
      'Đã lưu nửa ảnh của bạn, có mạng sẽ gửi cho người ấy';

  @override
  String get journeys_home_offline => 'Chưa có kết nối mạng';

  @override
  String get journeys_home_offlineMemory =>
      'Đang lưu trên máy. Có mạng sẽ tự gửi.';

  @override
  String get journeys_home_readOnlyQuiet => 'Hành trình đã kết thúc · chỉ xem';

  @override
  String get journeys_home_readOnlyFlexer => 'ĐÃ VỀ ĐÍCH · CHỈ ĐỌC';

  @override
  String get journeys_home_readOnlyMinimal => 'ĐÃ KẾT THÚC · CHỈ ĐỌC';

  @override
  String journeys_home_dayStreak(int day, int total, int streak) {
    return 'Ngày $day/$total · chuỗi $streak';
  }

  @override
  String journeys_home_dayStreakOpen(int day, int streak) {
    return 'Ngày $day · chuỗi $streak';
  }

  @override
  String journeys_home_monthStreak(int streak, String month) {
    return '$month · CHUỖI $streak NGÀY';
  }

  @override
  String get journeys_home_chartA11y => 'Đường tiến trình';

  @override
  String get journeys_home_msWeek => 'Tuần đầu';

  @override
  String get journeys_home_msHalf => 'Nửa chặng';

  @override
  String get journeys_home_msFinish => 'Về đích';

  @override
  String journeys_home_msDay(int day) {
    return 'NGÀY $day';
  }

  @override
  String get journeys_home_actionSquad => 'Nhóm hôm nay';

  @override
  String get journeys_home_actionCard => 'Tạo thiệp';

  @override
  String journeys_home_attendance(int done, int total) {
    return '$done/$total NGÀY ĐÃ CHỤP';
  }

  @override
  String get journeys_home_retake => 'Chụp thêm ảnh hôm nay';

  @override
  String get journeys_home_timelineLabel => 'Dòng thời gian';

  @override
  String get journeys_edit_title => 'cập nhật hành trình.';

  @override
  String get journeys_edit_save => 'Lưu';

  @override
  String get journeys_edit_name => 'Tên';

  @override
  String get journeys_edit_cover => 'Bìa';

  @override
  String journeys_edit_coverOption(int n) {
    return 'Bìa $n';
  }

  @override
  String get journeys_edit_layout => 'Giao diện';

  @override
  String get journeys_edit_layoutNote =>
      'Một số giao diện cần thêm dữ liệu nên không hiện.';

  @override
  String get journeys_edit_layoutInUse => 'Đang dùng';

  @override
  String journeys_edit_layoutPreviewLabel(String name) {
    return 'Xem trước giao diện $name';
  }

  @override
  String get journeys_edit_previewTag => 'XEM TRƯỚC';

  @override
  String get journeys_edit_hudPreview => 'Check-in mỗi ngày';

  @override
  String journeys_edit_dayOf(int day, int total) {
    return 'NGÀY $day/$total';
  }

  @override
  String journeys_edit_dayOpen(int day) {
    return 'NGÀY $day';
  }

  @override
  String get journeys_edit_useLayout => 'Dùng giao diện này';

  @override
  String get journeys_edit_cancel => 'Hủy';

  @override
  String get journeys_edit_discardTitle => 'Bỏ các thay đổi?';

  @override
  String get journeys_edit_discardBody =>
      'Bạn đã sửa hành trình nhưng chưa lưu. Rời đi bây giờ sẽ mất các thay đổi đó.';

  @override
  String get journeys_edit_discardConfirm => 'Bỏ thay đổi';

  @override
  String get journeys_edit_discardKeep => 'Sửa tiếp';

  @override
  String get journeys_edit_layoutApplied => 'Đã đổi giao diện cho hành trình.';

  @override
  String get journeys_edit_layoutOwnerOnly =>
      'Chủ nhóm chọn giao diện cho cả nhóm.';

  @override
  String get journeys_edit_color => 'Màu';

  @override
  String get journeys_edit_skinShort_quiet => 'Lặng lẽ';

  @override
  String get journeys_edit_skinColor_quiet_0 => 'Lục ngọc';

  @override
  String get journeys_edit_skinColor_quiet_1 => 'Xanh sage';

  @override
  String get journeys_edit_skinColor_quiet_2 => 'Sương mù';

  @override
  String get journeys_edit_skinShort_squad => 'Đội';

  @override
  String get journeys_edit_skinColor_squad_0 => 'Lửa';

  @override
  String get journeys_edit_skinColor_squad_1 => 'Tím';

  @override
  String get journeys_edit_skinColor_squad_2 => 'Phấn';

  @override
  String get journeys_edit_skinShort_memory => 'Ký ức';

  @override
  String get journeys_edit_skinColor_memory_0 => 'Sương thông';

  @override
  String get journeys_edit_skinColor_memory_1 => 'Biển muối';

  @override
  String get journeys_edit_skinColor_memory_2 => 'Phố đêm';

  @override
  String get journeys_edit_skinShort_couple => 'Đôi';

  @override
  String get journeys_edit_skinColor_couple_0 => 'Hồng';

  @override
  String get journeys_edit_skinColor_couple_1 => 'Mâm xôi';

  @override
  String get journeys_edit_skinColor_couple_2 => 'Đào';

  @override
  String get journeys_edit_skinShort_flexer => 'Khoe thẩm mỹ';

  @override
  String get journeys_edit_skinColor_flexer_0 => 'Lime neon';

  @override
  String get journeys_edit_skinColor_flexer_1 => 'San hô điện';

  @override
  String get journeys_edit_skinColor_flexer_2 => 'Băng';

  @override
  String get journeys_edit_skinShort_minimal => 'Tối giản';

  @override
  String get journeys_edit_skinColor_minimal_0 => 'Cam';

  @override
  String get journeys_edit_skinColor_minimal_1 => 'Than';

  @override
  String get journeys_edit_skinColor_minimal_2 => 'Trời';

  @override
  String get journeys_edit_trophy => 'Tên chiếc cúp';

  @override
  String get journeys_edit_film => 'Cuộn phim';

  @override
  String journeys_edit_filmReadonly(int n) {
    return '$n · chỉ xem';
  }

  @override
  String get journeys_edit_couple => 'Hai đứa mình';

  @override
  String get journeys_edit_hud => 'Kiểu HUD';

  @override
  String get journeys_edit_hudBold => 'Đậm';

  @override
  String get journeys_edit_hudStamp => 'Dấu tối giản';

  @override
  String get journeys_edit_hudStrip => 'Dải phim';

  @override
  String get journeys_edit_reminder => 'Giờ nhắc';

  @override
  String get journeys_edit_reminderHour => 'Giờ';

  @override
  String get journeys_edit_reminderMinute => 'Phút';

  @override
  String get journeys_edit_visibility => 'Ai được xem';

  @override
  String get journeys_edit_visPrivate => 'Chỉ mình tôi';

  @override
  String get journeys_edit_visLink => 'Có link xem (thu hồi được)';

  @override
  String get journeys_edit_visQuietNote =>
      'Trang xem luôn ẩn số kg và làm mờ ảnh theo mặc định.';

  @override
  String get journeys_edit_membersOnly => 'Chỉ thành viên';

  @override
  String get journeys_edit_membersOnlyHint =>
      'có thể tạo link công khai khi hành trình kết thúc và được thành viên đồng ý';

  @override
  String get journeys_edit_quietLock => 'Riêng tư';

  @override
  String get journeys_edit_endTitle => 'Kết thúc hành trình?';

  @override
  String get journeys_edit_endBody =>
      'Bạn vẫn xem lại được, nhưng không chụp thêm.';

  @override
  String get journeys_edit_endConfirm => 'Kết thúc';

  @override
  String get journeys_edit_saved => 'Đã lưu.';

  @override
  String get journeys_edit_ownerOnly => 'Chỉ chủ hành trình mới sửa được.';

  @override
  String get journeys_edit_menu => 'Sửa hành trình';

  @override
  String journeys_wrapped_eyebrowOpen(String date) {
    return 'NGÀY ĐẦU · $date';
  }

  @override
  String journeys_wrapped_openSpan(int days, String start, String end) {
    return '$days ngày, từ $start đến $end';
  }

  @override
  String journeys_wrapped_openReason(String reason) {
    return 'Ngày đầu bạn viết: \"$reason\"';
  }

  @override
  String get journeys_wrapped_eyebrowFirst => 'TẤM ĐẦU TIÊN';

  @override
  String journeys_wrapped_firstHeadline(String date) {
    return 'Lần check-in đầu tiên, ngày $date';
  }

  @override
  String journeys_wrapped_firstHeadlineImported(String date) {
    return 'Tấm ảnh đầu tiên, ngày $date';
  }

  @override
  String journeys_wrapped_firstFew(int days) {
    return '$days ngày check-in, đủ cả ở đây';
  }

  @override
  String get journeys_wrapped_eyebrowRoll => 'CẢ CUỘN ẢNH';

  @override
  String journeys_wrapped_rollBusiest(String date, int n) {
    return 'Ngày chụp nhiều nhất: $date, $n tấm';
  }

  @override
  String journeys_wrapped_rollMore(int n) {
    return '+$n';
  }

  @override
  String get journeys_wrapped_eyebrowSignature => 'DẤU ẤN CỦA CHẶNG';

  @override
  String journeys_wrapped_sigQuietWeight(int n) {
    return '$n lần bạn ghi cân nặng';
  }

  @override
  String journeys_wrapped_sigQuietWeightLess(String delta) {
    return 'Nhẹ hơn $delta so với ngày đầu';
  }

  @override
  String journeys_wrapped_sigQuietRange(String first, String last) {
    return 'Từ $first đến $last';
  }

  @override
  String journeys_wrapped_sigQuietMood(int n) {
    return '$n ngày bạn thấy người nhẹ nhõm';
  }

  @override
  String get journeys_wrapped_showKg => 'Hiện số kg';

  @override
  String get journeys_wrapped_showPhotos => 'Hiện ảnh';

  @override
  String journeys_wrapped_sigSquadTime(int hours, int minutes, int n) {
    return '$hours giờ $minutes phút học qua $n lần check-in';
  }

  @override
  String journeys_wrapped_sigSquadLongest(int minutes, String date) {
    return 'Buổi dài nhất: $minutes phút, ngày $date';
  }

  @override
  String journeys_wrapped_sigMemoryPlaces(int n, String first, String last) {
    return '$n điểm dừng, từ $first đến $last';
  }

  @override
  String journeys_wrapped_sigCoupleDays(int n) {
    return '$n ngày cả hai cùng check-in';
  }

  @override
  String journeys_wrapped_sigCoupleCook(String a, int x, String b, int y) {
    return '$a vào bếp $x lần, $b $y lần';
  }

  @override
  String journeys_wrapped_sigCoupleHearts(int n) {
    return '$n món được chấm đủ 5 tim';
  }

  @override
  String journeys_wrapped_sigFlexerKm(String km, int n) {
    return '$km km qua $n buổi chạy';
  }

  @override
  String journeys_wrapped_sigFlexerPace(String pace, String date) {
    return 'Pace nhanh nhất $pace/km, ngày $date';
  }

  @override
  String journeys_wrapped_sigFlexerMinutes(int n, int hours, int minutes) {
    return '$n buổi tập, tổng $hours giờ $minutes phút';
  }

  @override
  String journeys_wrapped_sigMinimalDays(int days) {
    return '$days ngày check-in';
  }

  @override
  String journeys_wrapped_sigMinimalDaysHabit(int days, String habit) {
    return '$days ngày check-in · $habit';
  }

  @override
  String journeys_wrapped_sigRatio(int days, int total) {
    return '$days/$total ngày';
  }

  @override
  String journeys_wrapped_sigLongestStreak(int n) {
    return 'Chuỗi dài nhất: $n ngày';
  }

  @override
  String journeys_wrapped_sigReactions(int n) {
    return '$n lượt bày tỏ cảm xúc';
  }

  @override
  String journeys_wrapped_eyebrowNote(String date) {
    return 'BẠN ĐÃ VIẾT · $date';
  }

  @override
  String get journeys_wrapped_eyebrowFinish => 'VÉ VỀ ĐÍCH';

  @override
  String journeys_wrapped_finishCount(int days, int moments) {
    return '$days ngày check-in · $moments tấm';
  }

  @override
  String journeys_wrapped_finishTrophy(String trophy) {
    return 'Cúp: $trophy';
  }

  @override
  String journeys_wrapped_finishDay(String n) {
    return 'NGÀY $n';
  }

  @override
  String get journeys_wrapped_finishStampButton => 'Đóng dấu';

  @override
  String get journeys_wrapped_finishStampHint => 'Chạm để đóng dấu vé về đích';

  @override
  String journeys_wrapped_finishStamp(String date) {
    return 'ĐÃ VỀ ĐÍCH · $date';
  }

  @override
  String get journeys_wrapped_finishSlogan => 'Góp tấm hình, giữ nhịp mình';

  @override
  String get journeys_wrapped_finishCta => 'Xem thiệp';

  @override
  String get journeys_wrapped_pause => 'Tạm dừng';

  @override
  String get journeys_wrapped_play => 'Chạy tiếp';

  @override
  String journeys_wrapped_sumMinimalCount(int days, String name) {
    return '$days NGÀY CHECK-IN · $name';
  }

  @override
  String journeys_wrapped_sumSquadCount(int days) {
    return '$days NGÀY CHECK-IN';
  }

  @override
  String get journeys_wrapped_title => 'Hành trình đã về đích';

  @override
  String get journeys_wrapped_close => 'Đóng';

  @override
  String journeys_wrapped_step(int n) {
    return 'Bước $n';
  }

  @override
  String journeys_wrapped_moments(int moments, int days) {
    return '$moments khoảnh khắc trong $days ngày';
  }

  @override
  String journeys_wrapped_sumQuiet(int total) {
    return 'NGÀY 01 vs NGÀY $total';
  }

  @override
  String journeys_wrapped_sumSquad(int done, int total) {
    return '$done/$total ĐÃ VỀ ĐÍCH';
  }

  @override
  String journeys_wrapped_sumMemory(int total, String name) {
    return '$total NGÀY · $name';
  }

  @override
  String journeys_wrapped_sumCouple(int total, int moments) {
    return '$total NGÀY BÊN NHAU · $moments KHOẢNH KHẮC';
  }

  @override
  String journeys_wrapped_sumFlexer(int total, String km) {
    return '$total NGÀY · $km KM';
  }

  @override
  String journeys_wrapped_sumMinimal(int done, int total, int pct) {
    return '$done/$total NGÀY · $pct% ĐỀU ĐẶN';
  }

  @override
  String get journeys_wrapped_hideKg => 'Ẩn số kg';

  @override
  String get journeys_wrapped_blur => 'Làm mờ ảnh';

  @override
  String get journeys_wrapped_blurLocked => 'Luôn bật với kiểu thẻ này';

  @override
  String get journeys_wrapped_on => 'Bật';

  @override
  String get journeys_wrapped_off => 'Tắt';

  @override
  String get journeys_wrapped_share => 'Chia sẻ';

  @override
  String get journeys_wrapped_editCard => 'Chỉnh thẻ';

  @override
  String get journeys_wrapped_sheetTitle => 'chia sẻ tấm thiệp.';

  @override
  String get journeys_wrapped_hideBrand => 'Ẩn chữ ourney';

  @override
  String get journeys_wrapped_saveCard => 'Lưu ảnh';

  @override
  String get journeys_wrapped_cardSaved => 'Đã lưu thẻ.';

  @override
  String journeys_create_invitingFriend(String handle) {
    return 'Sẽ gửi lời mời tới @$handle';
  }

  @override
  String get journeys_wrapped_menu => 'Câu chuyện về đích';

  @override
  String journeys_home_squadChip(String title, int days) {
    return '$title · $days NGÀY';
  }

  @override
  String journeys_home_squadChipOpen(String title) {
    return '$title · KHÔNG GIỚI HẠN';
  }

  @override
  String journeys_home_squadToday(int done, int total) {
    return '$done/$total HÔM NAY';
  }

  @override
  String get journeys_home_trophyDefault => 'CÚP';

  @override
  String journeys_home_trophyDay(int day) {
    return 'NGÀY $day';
  }

  @override
  String get journeys_home_trophyOpen => 'KHÔNG GIỚI HẠN';

  @override
  String journeys_home_filmRoll(int frames, int total) {
    return 'CUỘN PHIM $frames/$total';
  }

  @override
  String journeys_home_rollNote(int total) {
    return 'Hết cuộn $total tấm · mở cuộn mới';
  }

  @override
  String journeys_home_coupleLine(int total, String ritual) {
    return '$total NGÀY $ritual';
  }

  @override
  String get journeys_home_ritualCook => 'NẤU CHO NHAU';

  @override
  String get journeys_home_ritualSave => 'TIẾT KIỆM CÙNG NHAU';

  @override
  String get journeys_home_ritualLdr => 'XA MÀ GẦN';

  @override
  String get journeys_home_ritualOther => 'BÊN NHAU';

  @override
  String journeys_home_pairWaiting(String name) {
    return 'đang chờ $name';
  }

  @override
  String get journeys_home_pairBoth => 'cả hai đã chụp hôm nay';

  @override
  String get journeys_home_pairNeither => 'hôm nay chưa ai chụp';

  @override
  String journeys_home_flexRan(int done, int total) {
    return '$done/$total ĐÃ CHẠY';
  }

  @override
  String journeys_home_flexTrained(int done, int total) {
    return '$done/$total ĐÃ TẬP';
  }

  @override
  String journeys_home_minimalMonth(String month, int streak) {
    return 'THÁNG $month · CHUỖI $streak NGÀY';
  }

  @override
  String journeys_home_minimalDone(int done, int total) {
    return '$done/$total ĐÃ XONG';
  }

  @override
  String get journeys_home_viewWrapped => 'Xem tổng kết';

  @override
  String get journeys_addMoreTag => 'Thêm ảnh';

  @override
  String get journeys_hubTitle => 'Ourney';

  @override
  String journeys_hubGreeting(String name) {
    return 'chào $name.';
  }

  @override
  String get journeys_hubGreetingNoName => 'chào bạn.';

  @override
  String get journeys_hubOffline => 'đang lưu trên máy, có mạng sẽ tự gửi';

  @override
  String get journeys_hubResumeTitle => 'Tiếp tục tạo hành trình';

  @override
  String journeys_hubResumeStep(int n) {
    return 'bước $n/5';
  }

  @override
  String get journeys_hubSection => 'hành trình của bạn.';

  @override
  String journeys_hubRunning(int n) {
    return '$n đang chạy';
  }

  @override
  String get journeys_hubNewTitle => 'hành trình mới.';

  @override
  String get journeys_hubNewHint => 'chọn một thế giới để bắt đầu';

  @override
  String get journeys_hubEmptyTitle => 'chưa có hành trình nào.';

  @override
  String get journeys_hubEmptyBody =>
      'một tấm mỗi ngày, giữ được cả chặng đường.';

  @override
  String get journeys_hubErrorTitle => 'không tải được. thử lại?';

  @override
  String get journeys_hubLoading => 'Đang tải';

  @override
  String journeys_createDeckCard(int n, int total, String name) {
    return 'Thẻ $n trên $total, $name';
  }

  @override
  String get journeys_createDeckChosen => 'Đã chọn';

  @override
  String get journeys_deckPrivate => 'Riêng tư';

  @override
  String get journeys_deckHudStudy => '45 PHÚT';

  @override
  String get journeys_deckHudFlexer => '5,2 KM · 5:48';

  @override
  String get journeys_deckHudMemory => 'CUỘN PHIM 12/24';

  @override
  String get journeys_deckHudCouple => 'hai nửa · một ngày';

  @override
  String get journeys_createDeckPrev => 'Thẻ trước';

  @override
  String get journeys_createDeckNext => 'Thẻ sau';

  @override
  String journeys_createDeckCounter(int n, int total) {
    return '$n/$total';
  }

  @override
  String get journeys_createDeckChoose => 'Chọn kiểu này';

  @override
  String journeys_cardStreak(int days) {
    return 'Chuỗi $days ngày';
  }

  @override
  String journeys_heroSemantics(int streak, String title) {
    return '$title, chuỗi $streak ngày';
  }

  @override
  String journeys_hubDaysLogged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ngày đã ghi',
    );
    return '$_temp0';
  }

  @override
  String journeys_deadUploads(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ảnh chưa gửi được',
    );
    return '$_temp0';
  }

  @override
  String get journeys_deadRetry => 'Gửi lại';

  @override
  String get journeys_deadDiscard => 'Bỏ ảnh';

  @override
  String get journeys_createSettingsNotSaved => 'Một vài cài đặt chưa lưu được';

  @override
  String get journeys_deadDiscardTitle => 'Bỏ ảnh chưa gửi được?';

  @override
  String journeys_deadDiscardBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count ảnh sẽ bị xóa khỏi máy này và không gửi lên được nữa. Không hoàn tác được.',
    );
    return '$_temp0';
  }

  @override
  String get journeys_timelineRecent => 'Gần đây';

  @override
  String get journeys_timelineByMonth => 'Theo tháng';

  @override
  String journeys_monthSummary(int checked, int days, int photos) {
    return '$checked/$days ngày · $photos ảnh';
  }

  @override
  String journeys_monthA11y(String month, int checked, int days, int photos) {
    return '$month, $checked trên $days ngày đã check-in, $photos ảnh';
  }

  @override
  String get journeys_monthExpandHint => 'Mở rộng';

  @override
  String get journeys_monthCollapseHint => 'Thu gọn';

  @override
  String journeys_jumpToMonth(String month) {
    return 'Đi tới $month';
  }

  @override
  String journeys_jumpToYear(int year) {
    return 'Xem năm $year';
  }

  @override
  String journeys_jumpAnnounce(String month) {
    return 'Đang ở $month';
  }

  @override
  String journeys_earlierLink(int to, int checked) {
    return 'Trước đó: ngày 1–$to, $checked ngày đã check-in';
  }

  @override
  String get journeys_earlierView => 'Xem';

  @override
  String journeys_daysToGo(int days, int finish) {
    return 'Còn $days ngày · Đích là ngày $finish';
  }

  @override
  String get journeys_range30 => '30 ngày';

  @override
  String get journeys_rangeAll => 'Tất cả';

  @override
  String journeys_clearYear(int year) {
    return 'Bỏ lọc năm $year';
  }

  @override
  String journeys_startsIn(int days, int total) {
    return 'Bắt đầu sau $days ngày · $total ngày';
  }

  @override
  String get journeys_dayPrevious => 'Trước';

  @override
  String get journeys_dayNext => 'Sau';

  @override
  String journeys_dayPreviousSemantics(String date) {
    return 'Check-in trước, $date';
  }

  @override
  String journeys_dayNextSemantics(String date) {
    return 'Check-in sau, $date';
  }

  @override
  String get journeys_dayViewFull => 'Xem ảnh đầy đủ';

  @override
  String get journeys_dayOpenJourney => 'Mở hành trình';

  @override
  String journeys_dayPartnerNoPhoto(String name) {
    return '$name chưa có ảnh ngày này';
  }

  @override
  String journeys_homeMeta(int day, int total, String range) {
    return 'Ngày $day / $total · $range';
  }

  @override
  String journeys_homeMetaOpen(int day, String start) {
    return 'Ngày $day · từ $start';
  }

  @override
  String journeys_daysLeft(int n) {
    return 'Còn $n ngày';
  }

  @override
  String journeys_weekLabel(int n) {
    return 'Tuần $n';
  }

  @override
  String journeys_weekKm(int n, String km) {
    return 'Tuần $n · $km km';
  }

  @override
  String get journeys_runTotalKm => 'Tổng km';

  @override
  String get journeys_runCount => 'Buổi chạy';

  @override
  String get journeys_runAvgPace => 'Pace trung bình';

  @override
  String get journeys_sessionCount => 'Buổi tập';

  @override
  String journeys_weightTrend(String direction) {
    return 'Xu hướng · $direction';
  }

  @override
  String get journeys_trendDown => 'đang xuống nhẹ';

  @override
  String get journeys_trendFlat => 'khá đều';

  @override
  String get journeys_trendUp => 'đang lên nhẹ';

  @override
  String journeys_trendFooter(int count) {
    return '$count lần cân · đã làm mượt';
  }

  @override
  String get journeys_trendNeedMore => 'Cân thêm vài lần nữa là thấy xu hướng.';

  @override
  String journeys_trendChange(String delta, String unit) {
    return '$delta $unit từ ngày 1';
  }

  @override
  String get journeys_showNumbers => 'Hiện số';

  @override
  String get journeys_hideNumbers => 'Ẩn số';

  @override
  String journeys_firstLatest(int first, int latest) {
    return 'Ngày $first và ngày $latest';
  }

  @override
  String get journeys_viewerMetricHidden => '••,•';

  @override
  String journeys_semRunBar(int day, String km) {
    return 'Ngày $day, $km km';
  }

  @override
  String journeys_semRunBarNone(int day) {
    return 'Ngày $day, không ghi km';
  }

  @override
  String get journeys_photoLogEmpty => 'Ảnh check-in sẽ ở đây.';

  @override
  String journeys_streakOnly(int n) {
    return 'Chuỗi $n';
  }

  @override
  String get journeys_runDay => 'Ngày';

  @override
  String journeys_cellQuiet(int day, String date) {
    return 'Ngày $day, $date: không có ảnh';
  }

  @override
  String journeys_wrappedPhotoDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ngày có ảnh',
    );
    return '$_temp0';
  }
}
