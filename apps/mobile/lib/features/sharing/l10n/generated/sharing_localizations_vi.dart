// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'sharing_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class SharingL10nVi extends SharingL10n {
  SharingL10nVi([String locale = 'vi']) : super(locale);

  @override
  String get sharing_title => 'Chia sẻ';

  @override
  String get sharing_shareThisJourney => 'Chia sẻ hành trình';

  @override
  String get sharing_editStory => 'Sửa câu chuyện';

  @override
  String get sharing_friends => 'Bạn bè';

  @override
  String get sharing_selectAll => 'Chọn tất cả';

  @override
  String get sharing_clear => 'Bỏ chọn';

  @override
  String get sharing_searchFriends => 'Tìm bạn';

  @override
  String get sharing_canSee => 'Có thể xem';

  @override
  String get sharing_remove => 'Xóa';

  @override
  String get sharing_sensitiveHelper => 'Hành trình nhạy cảm: chọn từng người';

  @override
  String get sharing_runningHelper => 'Họ sẽ thấy ảnh mới khi bạn đăng';

  @override
  String sharing_shareWith(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Chia sẻ cho $count bạn',
    );
    return '$_temp0';
  }

  @override
  String get sharing_pickFriends => 'Chọn bạn để chia sẻ';

  @override
  String get sharing_noFriends => 'Kết bạn để chia sẻ hành trình với họ';

  @override
  String sharing_sharedSnack(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã chia sẻ cho $count bạn',
    );
    return '$_temp0';
  }

  @override
  String sharing_removeFriendShare(String name) {
    return 'Gỡ $name khỏi người xem';
  }

  @override
  String get sharing_publicLink => 'Liên kết công khai';

  @override
  String get sharing_linkLockedTitle => 'Liên kết mở khi hành trình kết thúc';

  @override
  String get sharing_linkLockedSub => 'Chưa thể bật liên kết';

  @override
  String get sharing_linkOwnerOnly => 'Chủ hành trình quản lý liên kết';

  @override
  String get sharing_linkOn => 'Bật liên kết';

  @override
  String get sharing_linkOff => 'Đang tắt';

  @override
  String get sharing_under18 => 'Link công khai dành cho người từ 18 tuổi';

  @override
  String get sharing_blurredPreview => 'Ảnh được làm mờ trong bản xem trước';

  @override
  String get sharing_copyLink => 'Sao chép';

  @override
  String get sharing_linkCopied => 'Đã sao chép liên kết';

  @override
  String get sharing_resetLink => 'Đặt lại';

  @override
  String get sharing_resetConfirmTitle => 'Đặt lại liên kết?';

  @override
  String get sharing_resetConfirmBody =>
      'Liên kết cũ sẽ không mở được nữa. Số liệu đã đếm vẫn giữ.';

  @override
  String get sharing_linkHelper =>
      'Ai có liên kết cũng có thể xem và làm theo hành trình.';

  @override
  String get sharing_showCounts => 'Hiện số liệu';

  @override
  String get sharing_showCountsHint =>
      'Hiện lượt thích và số người làm theo cho người xem';

  @override
  String get sharing_letAnyoneReact => 'Cho phép mọi người tương tác';

  @override
  String get sharing_letAnyoneReactHint =>
      'Người có tài khoản Ourney có thể thích';

  @override
  String get sharing_allowRequests => 'Cho phép người xem gửi lời mời kết bạn';

  @override
  String get sharing_allowRequestsHint =>
      'Người xem có thể gửi lời mời kết bạn';

  @override
  String sharing_statsLine(String views, String likes, String started) {
    return '$views lượt xem · $likes ❤️ · $started đã bắt đầu';
  }

  @override
  String get sharing_stopSharing => 'Dừng chia sẻ';

  @override
  String get sharing_stopConfirm =>
      'Mọi người sẽ mất quyền truy cập. Người đã bắt đầu vẫn giữ hành trình của họ.';

  @override
  String get sharing_stopMineConfirm =>
      'Những người bạn đã chia sẻ sẽ mất quyền xem. Lượt chia sẻ của thành viên khác vẫn giữ.';

  @override
  String get sharing_removeMyPhotos => 'Xóa ảnh của tôi khỏi chia sẻ';

  @override
  String get sharing_removeMyPhotosConfirm =>
      'Ảnh của bạn sẽ không hiện với người ngoài nhóm nữa.';

  @override
  String get sharing_warnTitle => 'Ai có link đều xem được hành trình này';

  @override
  String get sharing_warnAnyone => 'Bất kỳ ai nhận được link đều có thể xem.';

  @override
  String get sharing_warnSelected =>
      'Chỉ ảnh bạn chọn mới hiện; bản xem trước được làm mờ.';

  @override
  String get sharing_warnUndo => 'Bạn có thể tắt link bất cứ lúc nào.';

  @override
  String get sharing_warnTurnOn => 'Bật link';

  @override
  String get sharing_warnSwitchTitle => 'Đây là một hành trình riêng tư';

  @override
  String get sharing_warnSwitchBody =>
      'Người ngoài danh sách bạn bè sẽ thấy hoặc làm được nhiều hơn. Bạn có thể tắt lại bất cứ lúc nào.';

  @override
  String get sharing_warnSwitchConfirm => 'Vẫn bật';

  @override
  String get sharing_consentTitle => 'Đồng thuận của nhóm';

  @override
  String get sharing_consentHelper =>
      'Chỉ ảnh của người đã đồng ý được chia sẻ';

  @override
  String get sharing_consentAgreed => 'Đã đồng ý';

  @override
  String get sharing_consentWaiting => 'Đang chờ';

  @override
  String get sharing_consentDeclined => 'Đã từ chối';

  @override
  String get sharing_consentWithdrawn => 'Đã rút ảnh';

  @override
  String get sharing_askGroup => 'Hỏi nhóm trước';

  @override
  String get sharing_askGroupHint =>
      'Hành trình nhóm cần hỏi mọi người trước khi chia sẻ ra ngoài.';

  @override
  String get sharing_askedSnack => 'Đã gửi yêu cầu tới nhóm';

  @override
  String get sharing_errorNotFriend => 'Chỉ chia sẻ được với bạn bè';

  @override
  String get sharing_errorRateLimited => 'Chậm lại một chút rồi thử lại nhé';

  @override
  String get sharing_storyHeader => 'Câu chuyện của bạn';

  @override
  String get sharing_storyTitleField => 'Tiêu đề câu chuyện';

  @override
  String get sharing_introField => 'Giới thiệu';

  @override
  String get sharing_introHint => 'Vì sao tôi bắt đầu…';

  @override
  String get sharing_lessonsField => 'Tôi đã học được gì';

  @override
  String get sharing_optional => 'Không bắt buộc';

  @override
  String get sharing_pickCover => 'Chọn ảnh bìa';

  @override
  String get sharing_coverTitle => 'Ảnh bìa';

  @override
  String get sharing_noPhotosYet => 'Chưa có ảnh nào';

  @override
  String get sharing_hidePhotos => 'Ẩn ảnh';

  @override
  String get sharing_hidePhotosHint => 'Chạm ảnh để ẩn khỏi mọi lượt chia sẻ';

  @override
  String sharing_photoHidden(String date) {
    return 'Ảnh ngày $date, đã ẩn khi chia sẻ';
  }

  @override
  String sharing_photoShown(String date) {
    return 'Ảnh ngày $date, đang hiện khi chia sẻ';
  }

  @override
  String get sharing_storySaved => 'Đã lưu câu chuyện';

  @override
  String get sharing_fromFriends => 'Từ bạn bè';

  @override
  String get sharing_saved => 'Đã lưu';

  @override
  String sharing_byName(String name) {
    return 'bởi $name';
  }

  @override
  String get sharing_imported => 'Kể lại';

  @override
  String get sharing_newBadge => 'Mới';

  @override
  String get sharing_savedFromLink => 'Đã thích qua liên kết';

  @override
  String get sharing_live => 'Đang diễn ra';

  @override
  String get sharing_finished => 'Đã kết thúc';

  @override
  String get sharing_emptyTitle => 'Chưa có ai chia sẻ với bạn';

  @override
  String get sharing_emptyMessage =>
      'Khi bạn bè chia sẻ một hành trình, nó sẽ hiện ở đây.';

  @override
  String sharing_removeSavedSemantics(String title) {
    return 'Xóa $title khỏi mục đã lưu';
  }

  @override
  String get sharing_privateNow => 'Hành trình này đã được đặt riêng tư';

  @override
  String get sharing_goBack => 'Quay lại';

  @override
  String get sharing_addFriend => 'Thêm bạn';

  @override
  String get sharing_requested => 'Đã gửi';

  @override
  String sharing_liveDay(int day) {
    return 'Trực tiếp · Ngày $day';
  }

  @override
  String sharing_importedRange(String range) {
    return 'Kể lại · $range · theo ngày chụp';
  }

  @override
  String sharing_moments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count khoảnh khắc',
    );
    return '$_temp0';
  }

  @override
  String get sharing_more => 'thêm';

  @override
  String get sharing_less => 'thu gọn';

  @override
  String sharing_counts(int likes, int follows) {
    return '❤️ $likes · $follows người đã làm hành trình này';
  }

  @override
  String sharing_dayN(int day) {
    return 'Ngày $day';
  }

  @override
  String get sharing_like => 'Thích';

  @override
  String get sharing_unlike => 'Bỏ thích';

  @override
  String get sharing_reply => 'Trả lời';

  @override
  String sharing_replyHint(String name) {
    return 'Chỉ $name thấy câu trả lời của bạn';
  }

  @override
  String get sharing_doThisJourney => 'Làm theo';

  @override
  String sharing_sharedBy(String name) {
    return '$name đã chia sẻ';
  }

  @override
  String get sharing_savedSnack => 'Đã lưu vào mục Đã lưu';

  @override
  String get sharing_requestSentSnack => 'Đã gửi lời mời kết bạn';

  @override
  String get sharing_photoBlurred => 'Ảnh đã được làm mờ';

  @override
  String get sharing_preview => 'Xem trước như bạn bè';

  @override
  String get sharing_followTitle => 'Làm hành trình này';

  @override
  String sharing_startYourOwn(String style) {
    return 'Bắt đầu hành trình $style của riêng bạn';
  }

  @override
  String sharing_days(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ngày',
    );
    return '$_temp0';
  }

  @override
  String get sharing_openEnded => 'Không giới hạn';

  @override
  String get sharing_daily => 'Hằng ngày';

  @override
  String get sharing_noMetrics => 'Không số liệu';

  @override
  String get sharing_whatYouGet => 'Bạn sẽ có';

  @override
  String get sharing_sameStyle => 'Cùng phong cách';

  @override
  String get sharing_sameRhythm => 'Cùng nhịp điệu';

  @override
  String get sharing_sameMetrics => 'Cùng chỉ số';

  @override
  String get sharing_startFresh =>
      'Ảnh và số liệu của bạn bắt đầu mới hoàn toàn.';

  @override
  String get sharing_squadNote => 'Hành trình nhóm — bạn sẽ mời người của mình';

  @override
  String get sharing_startThis => 'Bắt đầu hành trình';

  @override
  String get sharing_changeSomething => 'Thay đổi một chút';

  @override
  String sharing_basedOn(String name) {
    return 'Theo hành trình của $name';
  }

  @override
  String get sharing_removeBasedOn => 'Bỏ nguồn hành trình';

  @override
  String get sharing_insightsTitle => 'Thông tin chi tiết';

  @override
  String get sharing_views => 'Lượt xem';

  @override
  String get sharing_likes => 'Lượt thích';

  @override
  String get sharing_started => 'Đã bắt đầu';

  @override
  String sharing_newViewersWeek(int count) {
    return '+$count người xem mới tuần này';
  }

  @override
  String sharing_thisWeek(int count) {
    return '+$count tuần này';
  }

  @override
  String get sharing_viewsPerDay => 'Số người xem mỗi ngày';

  @override
  String get sharing_last30Days => '30 ngày qua';

  @override
  String sharing_chartSemantics(int max) {
    return 'Biểu đồ lượt xem 30 ngày qua, nhiều nhất $max người một ngày';
  }

  @override
  String sharing_likesFriends(int count) {
    return 'Bạn bè $count';
  }

  @override
  String sharing_likesOthers(int count) {
    return 'Người khác $count';
  }

  @override
  String get sharing_likersTitle => 'Ai đã thích ảnh của bạn';

  @override
  String get sharing_noLikers => 'Chưa có lượt thích nào';

  @override
  String get sharing_privacyNote =>
      'Lượt xem được đếm, không liệt kê. Không ai biết bạn đã xem hành trình của họ.';

  @override
  String get sharing_linkOffNote => 'Liên kết đang tắt · tạm dừng đếm';

  @override
  String get sharing_retellTitle => 'Kể lại một hành trình đã qua';

  @override
  String get sharing_retellIntro =>
      'Đã đi rồi? Biến ảnh cũ thành một câu chuyện';

  @override
  String get sharing_pickPhotos => 'Chọn ảnh';

  @override
  String get sharing_addPhotos => 'Thêm ảnh';

  @override
  String sharing_photosCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ảnh',
    );
    return '$_temp0';
  }

  @override
  String get sharing_photosHint => 'Ảnh tự xếp theo ngày. Chạm ngày để đổi.';

  @override
  String get sharing_journeyName => 'Tên hành trình';

  @override
  String get sharing_style => 'Phong cách';

  @override
  String get sharing_metricOptional => 'Chỉ số (không bắt buộc)';

  @override
  String get sharing_metricName => 'Tên chỉ số';

  @override
  String get sharing_metricUnit => 'Đơn vị';

  @override
  String sharing_changeDate(String date) {
    return 'Đổi ngày ảnh, hiện là $date';
  }

  @override
  String get sharing_removePhoto => 'Bỏ ảnh';

  @override
  String get sharing_sameDay => 'Trùng ngày: ảnh sau thay ảnh trước';

  @override
  String sharing_rangeLine(String range, String days) {
    return '$range · $days';
  }

  @override
  String get sharing_saveToShelf => 'Lưu lên kệ';

  @override
  String sharing_saving(int done, int total) {
    return 'Đang lưu $done/$total ảnh…';
  }

  @override
  String get sharing_errorTitleEmpty => 'Đặt tên cho hành trình';

  @override
  String get sharing_errorRange => 'Tối đa 366 ngày từ ảnh đầu đến ảnh cuối';

  @override
  String get sharing_errorFuture => 'Ngày ảnh không thể ở tương lai';

  @override
  String get sharing_errorNoPhotos => 'Chọn ít nhất một ảnh';

  @override
  String sharing_retellFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ảnh chưa lưu được',
    );
    return '$_temp0';
  }

  @override
  String get sharing_retry => 'Thử lại';

  @override
  String get sharing_openJourney => 'Mở hành trình';
}
