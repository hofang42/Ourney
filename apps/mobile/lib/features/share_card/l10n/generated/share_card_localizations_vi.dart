// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'share_card_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class ShareCardL10nVi extends ShareCardL10n {
  ShareCardL10nVi([String locale = 'vi']) : super(locale);

  @override
  String get share_card_title => 'Chia sẻ';

  @override
  String get share_card_sizeLabel => 'Cỡ thẻ';

  @override
  String get share_card_sizeStory => 'Story';

  @override
  String get share_card_sizeFeed => 'Bài đăng';

  @override
  String get share_card_numberLabel => 'Con số lớn';

  @override
  String get share_card_numberStreak => 'Chuỗi ngày';

  @override
  String get share_card_numberDay => 'Ngày thứ N';

  @override
  String share_card_captionStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ngày liên tiếp',
    );
    return '$_temp0';
  }

  @override
  String share_card_captionCheckedIn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ngày đã check-in',
    );
    return '$_temp0';
  }

  @override
  String get share_card_kickerFinished => 'Hoàn thành';

  @override
  String share_card_captionFinished(int done, int total) {
    return '$done/$total ngày';
  }

  @override
  String get share_card_kickerDay => 'Ngày thứ';

  @override
  String share_card_captionDayOf(int total) {
    return 'trên $total ngày';
  }

  @override
  String get share_card_milestone7 => 'Mốc 7 ngày!';

  @override
  String get share_card_milestone30 => 'Mốc 30 ngày!';

  @override
  String get share_card_milestoneCompleted => 'Về đích!';

  @override
  String get share_card_photoLabel => 'Ảnh';

  @override
  String get share_card_photoNone =>
      'Chưa có ảnh check-in. Thẻ sẽ dùng hình trang trí.';

  @override
  String share_card_photoOfDay(String date) {
    return 'Ảnh ngày $date';
  }

  @override
  String get share_card_blurPhoto => 'Làm mờ ảnh';

  @override
  String get share_card_blurPhotoHint =>
      'Bật sẵn theo cài đặt riêng tư của hành trình';

  @override
  String get share_card_metricHidden => 'Số đo của bạn không hiện trên thẻ.';

  @override
  String get share_card_shareButton => 'Chia sẻ thẻ';

  @override
  String get share_card_preparing => 'Đang tạo ảnh…';

  @override
  String get share_card_shareError => 'Không tạo được ảnh. Thử lại nhé.';

  @override
  String share_card_shareText(String emoji, String title) {
    return '$emoji $title trên Ourney';
  }

  @override
  String share_card_previewLabel(
    String headline,
    String caption,
    String title,
  ) {
    return 'Xem trước thẻ: $headline $caption, $title';
  }

  @override
  String get share_card_notFound => 'Không tìm thấy hành trình này.';

  @override
  String get share_card_linkTitle => 'Link xem công khai';

  @override
  String get share_card_linkDescription =>
      'Ai có link đều xem được hành trình này (chỉ xem). Bạn thu hồi được bất cứ lúc nào.';

  @override
  String get share_card_linkActive =>
      'Link đang bật. Ai có link đều xem được hành trình này.';

  @override
  String get share_card_linkCreate => 'Tạo và sao chép link';

  @override
  String get share_card_linkCopy => 'Sao chép link';

  @override
  String get share_card_linkCopied => 'Đã sao chép link';

  @override
  String get share_card_linkRevoke => 'Thu hồi link';

  @override
  String get share_card_linkRevokeTitle => 'Thu hồi link?';

  @override
  String get share_card_linkRevokeMessage =>
      'Link hiện tại sẽ ngừng hoạt động ngay. Bạn có thể tạo link mới sau.';

  @override
  String get share_card_linkRevoked => 'Đã thu hồi link';

  @override
  String get share_card_linkErrorEnded =>
      'Hành trình đã lưu trữ nên không tạo link được.';

  @override
  String get share_card_linkErrorForbidden =>
      'Chỉ chủ hành trình mới quản lý được link.';
}
