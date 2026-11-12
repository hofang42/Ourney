// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'social_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class SocialL10nVi extends SocialL10n {
  SocialL10nVi([String locale = 'vi']) : super(locale);

  @override
  String get social_friendsTitle => 'Bạn bè';

  @override
  String social_friendsSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count người bạn',
    );
    return '$_temp0 · chỉ bạn thấy';
  }

  @override
  String get social_add => 'Thêm';

  @override
  String get social_requests => 'Lời mời';

  @override
  String get social_noRequests => 'Không có lời mời mới';

  @override
  String get social_accept => 'Chấp nhận';

  @override
  String get social_decline => 'Từ chối';

  @override
  String get social_requested => 'Đã gửi';

  @override
  String get social_cancelRequest => 'Hủy';

  @override
  String get social_searchFriends => 'Tìm bạn';

  @override
  String get social_emptyFriendsTitle =>
      'Chia sẻ hành trình với những người đã ở đó';

  @override
  String get social_addFriends => 'Thêm bạn';

  @override
  String get social_message => 'Nhắn tin';

  @override
  String get social_removeFriend => 'Xóa bạn';

  @override
  String social_removeFriendTitle(String name) {
    return 'Xóa $name khỏi bạn bè?';
  }

  @override
  String get social_removeFriendBody =>
      'Hai bạn sẽ không còn thấy hành trình đã chia sẻ cho nhau.';

  @override
  String social_removed(String name) {
    return 'Đã xóa $name khỏi bạn bè';
  }

  @override
  String get social_block => 'Chặn';

  @override
  String get social_report => 'Báo cáo';

  @override
  String social_sawJourney(String title) {
    return 'Đã xem $title';
  }

  @override
  String get social_inviteLinkTitle => 'Chia sẻ liên kết mời';

  @override
  String get social_inviteLinkHint => 'Ai mở liên kết sẽ thành bạn của bạn';

  @override
  String get social_share => 'Chia sẻ';

  @override
  String get social_copy => 'Sao chép';

  @override
  String get social_linkCopied => 'Đã sao chép liên kết';

  @override
  String get social_copied => 'Đã sao chép';

  @override
  String social_inviteShareText(String link) {
    return 'Kết bạn với mình trên Ourney nhé: $link';
  }

  @override
  String get social_qrTitle => 'Mã QR của tôi';

  @override
  String get social_qrShow => 'Chạm để hiện mã';

  @override
  String get social_qrEnlarge => 'Chạm để phóng to';

  @override
  String get social_qrSemantics => 'Mã QR của liên kết mời';

  @override
  String get social_findByUsername => 'Tìm bằng tên người dùng';

  @override
  String get social_usernameHint => '@username';

  @override
  String get social_search => 'Tìm';

  @override
  String get social_exactMatchHint => 'Chỉ hiện khi khớp đúng tên người dùng';

  @override
  String get social_noOne => 'Không có ai với tên người dùng này';

  @override
  String get social_addFriend => 'Thêm bạn';

  @override
  String get social_alreadyFriends => 'Bạn bè';

  @override
  String get social_thatsYou => 'Đây là bạn';

  @override
  String get social_rateLimited => 'Bạn thao tác hơi nhanh. Thử lại sau nhé.';

  @override
  String get social_errorForbidden => 'Bạn không thể làm việc này';

  @override
  String get social_errorNotFound => 'Không tìm thấy';

  @override
  String get social_errorBlocked => 'Không thể kết bạn với người này';

  @override
  String get social_inviteTitle => 'Lời mời kết bạn';

  @override
  String get social_inviteAccepting => 'Đang kết bạn…';

  @override
  String social_inviteDone(String name) {
    return 'Bạn và $name đã là bạn bè';
  }

  @override
  String get social_inviteNotFound =>
      'Liên kết mời này đã hết hạn hoặc không tồn tại';

  @override
  String get social_inviteOwn => 'Đây là liên kết mời của chính bạn';

  @override
  String get social_inviteOwnHint => 'Gửi liên kết này cho bạn bè để kết bạn.';

  @override
  String get social_seeFriends => 'Xem bạn bè';

  @override
  String get social_inboxTitle => 'Hộp thư';

  @override
  String get social_inboxNew => 'Hộp thư, có mục mới';

  @override
  String get social_filterAll => 'Tất cả';

  @override
  String get social_filterReplies => 'Trả lời';

  @override
  String get social_filterInvites => 'Lời mời';

  @override
  String get social_sectionFriendRequests => 'Lời mời kết bạn';

  @override
  String social_friendRequestFrom(String name) {
    return 'Lời mời kết bạn từ $name';
  }

  @override
  String get social_sectionConsents => 'Yêu cầu chia sẻ';

  @override
  String social_consentRequest(String name, String title) {
    return '$name muốn chia sẻ $title ra ngoài nhóm';
  }

  @override
  String get social_agree => 'Đồng ý';

  @override
  String get social_sectionConversations => 'Trò chuyện';

  @override
  String get social_photoMessage => 'Đã gửi một ảnh';

  @override
  String get social_sectionNewShares => 'Được chia sẻ với bạn';

  @override
  String social_newShares(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hành trình mới được chia sẻ với bạn',
    );
    return '$_temp0';
  }

  @override
  String get social_view => 'Xem';

  @override
  String get social_sectionPublic => 'Từ hành trình công khai của bạn';

  @override
  String social_publicSummary(int count, String title) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lời mời từ người đã xem $title',
    );
    return '$_temp0';
  }

  @override
  String get social_publicJourneyFallback => 'hành trình công khai';

  @override
  String get social_declineAll => 'Từ chối tất cả';

  @override
  String get social_inboxEmpty => 'Câu trả lời và lời mời từ bạn bè sẽ ở đây';

  @override
  String social_unread(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tin chưa đọc',
    );
    return '$_temp0';
  }

  @override
  String get social_messageHint => 'Tin nhắn';

  @override
  String get social_send => 'Gửi';

  @override
  String get social_camera => 'Chụp ảnh';

  @override
  String get social_library => 'Thư viện ảnh';

  @override
  String get social_more => 'Thêm tùy chọn';

  @override
  String get social_deleteConversation => 'Xóa cuộc trò chuyện';

  @override
  String social_deleteConversationBody(String name) {
    return 'Chỉ xóa phía bạn. $name vẫn giữ lịch sử trò chuyện.';
  }

  @override
  String get social_delete => 'Xóa';

  @override
  String get social_deleteForMe => 'Xóa phía tôi';

  @override
  String get social_readOnly => 'Bạn không thể trả lời cuộc trò chuyện này';

  @override
  String get social_replyingTo => 'Trả lời ảnh này';

  @override
  String get social_chatEmpty => 'Chưa có tin nhắn';

  @override
  String get social_conversationGone => 'Cuộc trò chuyện này không còn';

  @override
  String get social_photoFailed => 'Không dùng được ảnh này';

  @override
  String get social_photoSemantics => 'Ảnh trong tin nhắn';

  @override
  String get social_sent => 'Đã gửi';

  @override
  String social_profileFriends(int count) {
    return 'Bạn bè · $count';
  }

  @override
  String social_profileRequests(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lời mời đang chờ',
    );
    return '$_temp0';
  }
}
