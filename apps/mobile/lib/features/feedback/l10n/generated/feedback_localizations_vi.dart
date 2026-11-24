// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'feedback_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class FeedbackL10nVi extends FeedbackL10n {
  FeedbackL10nVi([String locale = 'vi']) : super(locale);

  @override
  String get feedback_title => 'đề xuất.';

  @override
  String get feedback_detailTitle => 'chi tiết.';

  @override
  String get feedback_newAction => 'Gửi đề xuất mới';

  @override
  String get feedback_moreOptions => 'Thêm tùy chọn';

  @override
  String get feedback_tabPopular => 'Phổ biến';

  @override
  String get feedback_tabNew => 'Mới';

  @override
  String get feedback_tabPlanned => 'Đã lên kế hoạch';

  @override
  String get feedback_tabShipped => 'Đã ra mắt';

  @override
  String get feedback_chipMine => 'Của tôi';

  @override
  String get feedback_catAll => 'Tất cả';

  @override
  String get feedback_catCamera => 'Máy ảnh & Check-in';

  @override
  String get feedback_catJourneys => 'Hành trình';

  @override
  String get feedback_catSquad => 'Nhóm';

  @override
  String get feedback_catSharing => 'Chia sẻ';

  @override
  String get feedback_catDesign => 'Giao diện';

  @override
  String get feedback_catOther => 'Khác';

  @override
  String get feedback_statusNew => 'Mới';

  @override
  String get feedback_statusUnderReview => 'Đang xem xét';

  @override
  String get feedback_statusPlanned => 'Đã lên kế hoạch';

  @override
  String get feedback_statusInProgress => 'Đang làm';

  @override
  String get feedback_statusShipped => 'Đã ra mắt';

  @override
  String get feedback_statusDeclined => 'Chưa phù hợp';

  @override
  String get feedback_searchLabel => 'Tìm đề xuất';

  @override
  String get feedback_searchHint => 'Tìm ý tưởng hoặc tính năng…';

  @override
  String get feedback_searchClear => 'Xóa tìm kiếm';

  @override
  String get feedback_newCta => 'Gửi đề xuất mới';

  @override
  String get feedback_officialReplyBadge => 'Phản hồi Ourney';

  @override
  String get feedback_officialReplyEyebrow => 'PHẢN HỒI TỪ OURNEY';

  @override
  String feedback_voteButton(int count) {
    return 'Bình chọn · $count';
  }

  @override
  String feedback_votedButton(int count) {
    return 'Đã bình chọn · $count';
  }

  @override
  String feedback_voteSemantics(String title, int count, String state) {
    return '$title, $count lượt bình chọn, $state';
  }

  @override
  String get feedback_voteStateVoted => 'đã bình chọn';

  @override
  String get feedback_voteStateNotVoted => 'chưa bình chọn';

  @override
  String feedback_shippedVotes(int count) {
    return 'Đã ra mắt · $count lượt bình chọn';
  }

  @override
  String get feedback_editedBadge => 'Đã chỉnh sửa';

  @override
  String get feedback_authorEditHint =>
      'Bạn có thể sửa hoặc xóa đề xuất này trước khi Ourney bắt đầu xem xét.';

  @override
  String get feedback_editAction => 'Sửa đề xuất';

  @override
  String get feedback_deleteAction => 'Xóa đề xuất';

  @override
  String get feedback_deleteTitle => 'Xóa đề xuất này?';

  @override
  String get feedback_deleteBody =>
      'Đề xuất của bạn sẽ bị xóa vĩnh viễn khỏi bảng cộng đồng.';

  @override
  String get feedback_deleteConfirm => 'Xóa đề xuất';

  @override
  String get feedback_deletedToast => 'Đã xóa đề xuất.';

  @override
  String get feedback_createSheetTitle => 'gửi đề xuất.';

  @override
  String get feedback_editSheetTitle => 'sửa đề xuất.';

  @override
  String get feedback_createSheetSub =>
      'Đề xuất chỉ hiển thị với người dùng đã đăng nhập để cộng đồng cùng bình chọn.';

  @override
  String get feedback_fieldTitleLabel => 'Tên đề xuất';

  @override
  String get feedback_fieldTitleHint =>
      'Ví dụ: Widget chuỗi ngày ngoài màn hình khóa';

  @override
  String get feedback_fieldCategoryLabel => 'Danh mục';

  @override
  String get feedback_fieldBodyLabel => 'Mô tả chi tiết';

  @override
  String get feedback_fieldBodyHint =>
      'Kể ngắn gọn tính năng này giúp thói quen hằng ngày của bạn dễ hơn thế nào…';

  @override
  String get feedback_similarHeading => 'Có thể đã có người đề xuất:';

  @override
  String feedback_similarVoteChip(int count) {
    return '+1 ($count)';
  }

  @override
  String get feedback_bugEmailLink =>
      'Báo lỗi riêng tư kèm ảnh chụp màn hình? Liên hệ hỗ trợ';

  @override
  String get feedback_submitAction => 'Gửi đề xuất';

  @override
  String get feedback_saveChanges => 'Lưu thay đổi';

  @override
  String get feedback_createdToast =>
      'Đã đăng đề xuất và tính 1 lượt bình chọn của bạn!';

  @override
  String get feedback_updatedToast => 'Đã lưu thay đổi đề xuất.';

  @override
  String get feedback_mergedBanner =>
      'Đề xuất này đã được gộp vào một ý tưởng tương tự cùng toàn bộ lượt bình chọn.';

  @override
  String get feedback_mergedOpenTarget => 'Xem đề xuất gốc';

  @override
  String get feedback_reportAction => 'Báo cáo đề xuất';

  @override
  String get feedback_reportTitle => 'Báo cáo đề xuất';

  @override
  String get feedback_reportedToast =>
      'Đã gửi báo cáo. Đề xuất này đã được ẩn khỏi máy bạn.';

  @override
  String get feedback_blockAuthorAction => 'Chặn người đăng';

  @override
  String get feedback_anonymousAuthor => 'Thành viên Ourney';

  @override
  String get feedback_emptyPopularTitle => 'chưa có đề xuất nào.';

  @override
  String get feedback_emptyPopularBody =>
      'Bạn muốn Ourney có thêm tính năng gì tiếp theo? Hãy là người đầu tiên chia sẻ nhé.';

  @override
  String get feedback_emptyPopularCta => 'Gửi đề xuất đầu tiên';

  @override
  String get feedback_emptyPlannedTitle => 'chưa có mục nào trong kế hoạch.';

  @override
  String get feedback_emptyPlannedBody =>
      'Những ý tưởng được bình chọn nhiều sẽ sớm được đưa vào lộ trình.';

  @override
  String get feedback_emptyShippedTitle => 'sắp có tính năng mới.';

  @override
  String get feedback_emptyShippedBody =>
      'Khi một đề xuất hoàn thành, bạn sẽ thấy thông báo tại đây.';

  @override
  String get feedback_emptyMineTitle => 'bạn chưa gửi đề xuất nào.';

  @override
  String get feedback_emptyMineBody =>
      'Những ý tưởng bạn gửi sẽ xuất hiện tại đây để bạn theo dõi tiến độ.';

  @override
  String get feedback_emptySearchTitle => 'không tìm thấy đề xuất trùng khớp.';

  @override
  String get feedback_emptySearchBody =>
      'Bạn có thể gửi ý tưởng này thành một đề xuất mới cho cộng đồng.';

  @override
  String get feedback_emptySearchCta => 'Gửi đề xuất này';

  @override
  String get feedback_loadMore => 'Xem thêm đề xuất';

  @override
  String get feedback_endOfList => 'Đã hiển thị tất cả đề xuất';

  @override
  String get feedback_offlineStrip => 'Đang xem bản đã lưu.';

  @override
  String get feedback_comingSoonTitle => 'bảng đề xuất sắp mở.';

  @override
  String get feedback_comingSoonBody =>
      'Máy chủ đang được cập nhật tính năng bình chọn đề xuất. Bạn quay lại sau ít phút nhé!';

  @override
  String get feedback_errorTitleLength => 'Tên đề xuất cần từ 6 đến 80 ký tự.';

  @override
  String get feedback_errorBodyLength => 'Mô tả cần từ 10 đến 1000 ký tự.';

  @override
  String get feedback_errorContentPolicy =>
      'Nội dung chứa từ ngữ không phù hợp với quy tắc cộng đồng của Ourney.';

  @override
  String get feedback_errorLinksNotAllowed =>
      'Vui lòng không chèn đường dẫn web vào đề xuất.';

  @override
  String get feedback_errorRateLimited =>
      'Bạn đã gửi tối đa 5 đề xuất trong 24 giờ qua. Hãy bình chọn các ý tưởng sẵn có nhé!';

  @override
  String get feedback_errorRateLimitedAction =>
      'Bạn đang thao tác quá nhanh. Vui lòng thử lại sau ít phút nhé.';

  @override
  String get feedback_errorOfflineDraftSaved =>
      'Không có mạng. Bản nháp của bạn vẫn được giữ nguyên.';

  @override
  String get feedback_errorVoteLocked => 'Đề xuất này đã khóa bình chọn.';

  @override
  String get feedback_errorNotFound =>
      'Đề xuất này không còn tồn tại hoặc đã bị ẩn.';
}
