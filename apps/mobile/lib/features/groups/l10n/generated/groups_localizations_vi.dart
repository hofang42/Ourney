// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'groups_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class GroupsL10nVi extends GroupsL10n {
  GroupsL10nVi([String locale = 'vi']) : super(locale);

  @override
  String get groups_title => 'Nhóm';

  @override
  String get groups_emptyTitle => 'Chưa có nhóm nào';

  @override
  String get groups_emptyMessage =>
      'Nhập mã mời của bạn bè, hoặc tạo hành trình nhóm ở tab Journeys.';

  @override
  String get groups_joinWithCode => 'Nhập mã mời';

  @override
  String get groups_createGroup => 'Tạo hành trình nhóm';

  @override
  String get groups_activeSection => 'Đang chạy';

  @override
  String get groups_finishedSection => 'Đã kết thúc';

  @override
  String get groups_loadError => 'Không tải được danh sách nhóm.';

  @override
  String get groups_statusEnded => 'Đã kết thúc';

  @override
  String get groups_statusArchived => 'Đã lưu trữ';

  @override
  String groups_dayOf(int day, int total) {
    return 'Ngày $day/$total';
  }

  @override
  String groups_dayOpen(int day) {
    return 'Ngày $day';
  }

  @override
  String get groups_joinTitle => 'Tham gia nhóm';

  @override
  String get groups_joinCodeLabel => 'Mã mời';

  @override
  String get groups_joinCodeHint => '8 chữ cái hoặc chữ số';

  @override
  String get groups_joinInvalidCode => 'Mã mời gồm đúng 8 chữ cái hoặc chữ số.';

  @override
  String get groups_joinPreviewTitle => 'Bạn được mời vào một hành trình nhóm';

  @override
  String get groups_joinRules =>
      'Nhóm tối đa 10 người. Tiến độ của bạn tính từ ngày tham gia, và bạn vẫn xem được lịch sử của nhóm.';

  @override
  String get groups_joinButton => 'Tham gia';

  @override
  String get groups_errorNotFound =>
      'Không có nhóm nào dùng mã này. Có thể chủ nhóm đã đổi mã, hãy xin mã mới nhé.';

  @override
  String get groups_errorFull => 'Nhóm này đã đủ 10 thành viên.';

  @override
  String get groups_errorBlocked => 'Bạn không thể tham gia nhóm này.';

  @override
  String get groups_errorLimit =>
      'Bạn đang chạy 3 hành trình. Kết thúc một hành trình rồi tham gia nhóm này nhé.';

  @override
  String get groups_errorEnded => 'Hành trình này đã kết thúc.';

  @override
  String get groups_errorForbidden => 'Bạn không có quyền làm việc này.';

  @override
  String get groups_errorNotAlone =>
      'Nhóm vẫn còn thành viên khác. Hãy kết thúc hành trình thay vì xoá.';

  @override
  String get groups_errorInvalid => 'Không thể thực hiện thao tác này.';

  @override
  String groups_todayHeader(int done, int total) {
    return 'Hôm nay $done/$total người đã check-in';
  }

  @override
  String get groups_doneSection => 'Đã check-in hôm nay';

  @override
  String get groups_pendingSection => 'Chưa check-in hôm nay';

  @override
  String get groups_statusDone => 'Xong hôm nay';

  @override
  String get groups_statusPending => 'Chưa check-in';

  @override
  String get groups_you => 'Bạn';

  @override
  String get groups_ownerBadge => 'Chủ nhóm';

  @override
  String groups_latestPhoto(String date) {
    return 'Ảnh gần nhất: $date';
  }

  @override
  String get groups_noPhotoYet => 'Chưa có check-in nào';

  @override
  String get groups_endedBanner =>
      'Hành trình đã kết thúc. Ảnh và streak chỉ còn để xem.';

  @override
  String get groups_notFoundTitle => 'Không tìm thấy nhóm';

  @override
  String get groups_notMember => 'Bạn không còn là thành viên của nhóm này.';

  @override
  String get groups_todayLoadError => 'Không tải được hoạt động hôm nay.';

  @override
  String get groups_openTimeline => 'Dòng thời gian của tôi';

  @override
  String get groups_invite => 'Mời bạn';

  @override
  String get groups_moreActions => 'Thêm thao tác';

  @override
  String groups_memberActions(String name) {
    return 'Thao tác với $name';
  }

  @override
  String groups_reactSemantics(String emoji, int count) {
    return 'Thả $emoji, $count lượt';
  }

  @override
  String get groups_actionRotate => 'Đổi mã mời';

  @override
  String get groups_rotateTitle => 'Đổi mã mời?';

  @override
  String get groups_rotateMessage =>
      'Mã và link hiện tại sẽ hết hiệu lực. Thành viên đang ở trong nhóm vẫn giữ nguyên.';

  @override
  String get groups_rotateDone => 'Đã tạo mã mời mới.';

  @override
  String get groups_actionEnd => 'Kết thúc hành trình';

  @override
  String get groups_endTitle => 'Kết thúc hành trình cho cả nhóm?';

  @override
  String get groups_endMessage =>
      'Sau đó không ai check-in được nữa. Ảnh và streak vẫn còn để mọi người xem lại.';

  @override
  String get groups_actionDelete => 'Xoá hành trình';

  @override
  String get groups_deleteTitle => 'Xoá hành trình nhóm này?';

  @override
  String get groups_deleteMessage =>
      'Bạn là thành viên duy nhất. Hành trình và ảnh của bạn sẽ bị xoá vĩnh viễn.';

  @override
  String get groups_actionLeave => 'Rời nhóm';

  @override
  String get groups_leaveTitle => 'Rời nhóm này?';

  @override
  String get groups_leaveMessage =>
      'Các check-in của bạn sẽ bị ẩn khỏi nhóm. Nếu tham gia lại bằng mã mời, chúng sẽ hiện lại.';

  @override
  String get groups_leaveOwnerNote =>
      'Bạn là chủ nhóm: quyền chủ nhóm sẽ chuyển cho người tham gia sớm nhất.';

  @override
  String get groups_leaveAloneNote =>
      'Bạn là thành viên duy nhất: hành trình sẽ được lưu trữ.';

  @override
  String get groups_leftDone => 'Bạn đã rời nhóm.';

  @override
  String get groups_actionRemove => 'Xoá khỏi nhóm';

  @override
  String groups_removeTitle(String name) {
    return 'Xoá $name khỏi nhóm?';
  }

  @override
  String get groups_removeMessage =>
      'Check-in của người này sẽ bị ẩn khỏi nhóm. Họ vẫn có thể tham gia lại bằng mã mời nếu bạn không đổi mã.';

  @override
  String groups_removedDone(String name) {
    return 'Đã xoá $name khỏi nhóm.';
  }

  @override
  String get groups_actionReport => 'Báo cáo';

  @override
  String get groups_actionBlock => 'Chặn';

  @override
  String get groups_inviteTitle => 'Mời bạn bè';

  @override
  String get groups_inviteMessage =>
      'Gửi mã hoặc link cho bạn bè. Nhóm tối đa 10 người.';

  @override
  String get groups_copyCode => 'Sao chép mã';

  @override
  String get groups_copied => 'Đã sao chép mã mời.';

  @override
  String get groups_shareLink => 'Chia sẻ link';

  @override
  String groups_shareText(String title, String link, String code) {
    return 'Cùng mình theo hành trình \"$title\" trên Ourney: $link (mã mời $code)';
  }

  @override
  String get groups_qrSemantics => 'Mã QR của link mời';

  @override
  String get groups_noInviteCode => 'Nhóm chưa có mã mời.';

  @override
  String get groups_inviteClosed =>
      'Hành trình đã kết thúc nên không mời thêm được.';
}
