// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'safety_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class SafetyL10nVi extends SafetyL10n {
  SafetyL10nVi([String locale = 'vi']) : super(locale);

  @override
  String get safety_title => 'An toàn & hỗ trợ';

  @override
  String get safety_hubIntro =>
      'Ourney là nơi để cùng nhau giữ thói quen. Bạn có thể báo cáo nội dung xấu, chặn người khác và đọc các điều khoản ở đây.';

  @override
  String get safety_hubEula => 'Điều khoản sử dụng';

  @override
  String get safety_hubPrivacy => 'Chính sách quyền riêng tư';

  @override
  String get safety_hubContact => 'Liên hệ';

  @override
  String get safety_hubBlocked => 'Người đã chặn';

  @override
  String get safety_hubHowToReport => 'Cách báo cáo';

  @override
  String get safety_hubHowToReportBody =>
      'Trong nhóm, mở menu của một check-in hoặc của một thành viên rồi chọn \"Báo cáo\" hoặc \"Chặn\". Nội dung bạn báo cáo sẽ bị ẩn khỏi máy bạn ngay.';

  @override
  String get safety_reportCheckInTitle => 'Báo cáo check-in';

  @override
  String get safety_reportUserTitle => 'Báo cáo người dùng';

  @override
  String get safety_reportPrompt =>
      'Có chuyện gì vậy? Báo cáo được giữ kín, người bị báo cáo sẽ không biết là bạn.';

  @override
  String get safety_reasonSpam => 'Spam hoặc lừa đảo';

  @override
  String get safety_reasonNudity => 'Ảnh khoả thân hoặc khiêu dâm';

  @override
  String get safety_reasonHarassment => 'Quấy rối hoặc bắt nạt';

  @override
  String get safety_reasonSelfHarm => 'Tự làm hại bản thân';

  @override
  String get safety_reasonOther => 'Lý do khác';

  @override
  String get safety_noteLabel => 'Ghi chú (không bắt buộc)';

  @override
  String get safety_noteHint => 'Thêm chi tiết giúp chúng mình xử lý nhanh hơn';

  @override
  String get safety_reportSubmit => 'Gửi báo cáo';

  @override
  String get safety_reportCancel => 'Huỷ';

  @override
  String get safety_reportSent =>
      'Đã gửi báo cáo. Cảm ơn bạn! Nội dung này đã được ẩn khỏi máy bạn.';

  @override
  String get safety_reportDone => 'Xong';

  @override
  String get safety_reportAlsoBlock => 'Chặn luôn người này';

  @override
  String get safety_selfHarmTitle => 'Bạn không một mình';

  @override
  String get safety_selfHarmBody =>
      'Nếu bạn hoặc ai đó đang gặp nguy hiểm ngay lúc này, hãy gọi dịch vụ cấp cứu tại nơi bạn ở. Chia sẻ với một người bạn tin tưởng, người thân hoặc chuyên gia tâm lý cũng có thể giúp ích rất nhiều.';

  @override
  String get safety_errorRateLimited =>
      'Bạn đã gửi nhiều báo cáo trong 24 giờ qua. Vui lòng thử lại sau.';

  @override
  String get safety_errorNotFound =>
      'Nội dung này không còn tồn tại hoặc bạn không xem được nữa.';

  @override
  String get safety_errorInvalid => 'Không thể thực hiện với chính bạn.';

  @override
  String get safety_errorOffline =>
      'Không có kết nối mạng. Thử lại khi có mạng nhé.';

  @override
  String get safety_errorGeneric => 'Có lỗi xảy ra. Thử lại sau nhé.';

  @override
  String get safety_needsAccount =>
      'Báo cáo và chặn cần máy chủ Ourney. Ở chế độ chỉ trên máy, không ai khác thấy nội dung của bạn.';

  @override
  String safety_blockTitle(String name) {
    return 'Chặn $name?';
  }

  @override
  String get safety_blockBody =>
      'Hai bạn sẽ không thấy check-in và reaction của nhau nữa, và người này không thể vào nhóm có bạn. Họ sẽ không được báo là bị chặn. Bạn có thể bỏ chặn bất cứ lúc nào.';

  @override
  String get safety_blockConfirm => 'Chặn';

  @override
  String get safety_blockCancel => 'Huỷ';

  @override
  String safety_blocked(String name) {
    return 'Đã chặn $name.';
  }

  @override
  String safety_unblockTitle(String name) {
    return 'Bỏ chặn $name?';
  }

  @override
  String get safety_unblockBody =>
      'Hai bạn sẽ lại thấy nội dung của nhau trong những nhóm chung.';

  @override
  String get safety_unblockConfirm => 'Bỏ chặn';

  @override
  String safety_unblocked(String name) {
    return 'Đã bỏ chặn $name.';
  }

  @override
  String get safety_unknownUser => 'Người dùng';

  @override
  String get safety_blockedEmptyTitle => 'Bạn chưa chặn ai';

  @override
  String get safety_blockedEmptyMessage =>
      'Người bạn chặn sẽ hiện ở đây để bạn bỏ chặn khi muốn.';

  @override
  String get safety_loadError => 'Không tải được danh sách. Thử lại sau nhé.';

  @override
  String get safety_retry => 'Thử lại';

  @override
  String get safety_contactIntro =>
      'Cần giúp đỡ, muốn góp ý hay báo cáo một vấn đề an toàn khẩn cấp? Viết cho chúng mình. Báo cáo nội dung được xem xét trong vòng 24 giờ.';

  @override
  String get safety_contactEmailLabel => 'Email hỗ trợ';

  @override
  String get safety_contactSend => 'Gửi email';

  @override
  String get safety_contactCopy => 'Sao chép địa chỉ';

  @override
  String get safety_contactCopied => 'Đã sao chép địa chỉ email.';

  @override
  String get safety_contactSubject => 'Ourney - hỗ trợ';

  @override
  String get safety_contactNoMailApp =>
      'Không mở được ứng dụng email. Hãy sao chép địa chỉ và gửi từ ứng dụng bạn dùng.';

  @override
  String get safety_eulaAcceptTitle => 'Trước khi bắt đầu';

  @override
  String get safety_eulaAcceptIntro =>
      'Ourney không dung thứ nội dung phản cảm hay hành vi lạm dụng. Hãy đọc và đồng ý với điều khoản sử dụng để tiếp tục.';

  @override
  String get safety_eulaAcceptCheckbox =>
      'Tôi đã đọc và đồng ý với Điều khoản sử dụng và Chính sách quyền riêng tư.';

  @override
  String get safety_eulaAcceptButton => 'Đồng ý và tiếp tục';

  @override
  String safety_lastUpdated(String date) {
    return 'Cập nhật lần cuối: $date';
  }

  @override
  String get safety_eula1Title => '1. Đồng ý điều khoản';

  @override
  String get safety_eula1Body =>
      'Khi tạo tài khoản hoặc dùng Ourney, bạn đồng ý với các điều khoản này. Nếu không đồng ý, vui lòng không sử dụng ứng dụng.';

  @override
  String get safety_eula2Title => '2. Không dung thứ nội dung phản cảm';

  @override
  String get safety_eula2Body =>
      'Ourney không chấp nhận bất kỳ nội dung phản cảm hay người dùng lạm dụng nào. Bạn không được đăng hoặc gửi: ảnh khoả thân, khiêu dâm; nội dung quấy rối, bắt nạt, đe doạ; phát ngôn thù ghét hoặc phân biệt đối xử; bạo lực; nội dung cổ vũ tự làm hại bản thân; spam, lừa đảo; nội dung vi phạm pháp luật hoặc quyền của người khác.';

  @override
  String get safety_eula3Title => '3. Nội dung của bạn';

  @override
  String get safety_eula3Body =>
      'Ảnh, chú thích và số liệu bạn đăng vẫn thuộc về bạn. Bạn cho phép Ourney lưu trữ và hiển thị chúng cho những người bạn chọn chia sẻ (thành viên nhóm, người có link công khai). Bạn chịu trách nhiệm về nội dung mình đăng.';

  @override
  String get safety_eula4Title => '4. Báo cáo, chặn và kiểm duyệt';

  @override
  String get safety_eula4Body =>
      'Bạn có thể báo cáo check-in hoặc người dùng và chặn bất kỳ ai. Chúng mình xem xét báo cáo trong vòng 24 giờ, gỡ nội dung vi phạm và khoá tài khoản của người vi phạm.';

  @override
  String get safety_eula5Title => '5. Chấm dứt';

  @override
  String get safety_eula5Body =>
      'Chúng mình có thể tạm khoá hoặc xoá tài khoản vi phạm các điều khoản này mà không cần báo trước. Bạn có thể xoá tài khoản bất cứ lúc nào trong Hồ sơ.';

  @override
  String get safety_eula6Title => '6. Miễn trừ và thay đổi';

  @override
  String get safety_eula6Body =>
      'Ourney được cung cấp \"như hiện có\" và không thay thế lời khuyên y tế, dinh dưỡng hay tập luyện chuyên môn. Khi điều khoản thay đổi, chúng mình sẽ thông báo trong ứng dụng.';

  @override
  String get safety_privacy1Title => 'Chúng mình lưu gì';

  @override
  String get safety_privacy1Body =>
      'Email (để đăng nhập); tên hiển thị, username và ảnh đại diện; hành trình bạn tạo; check-in gồm ảnh, chú thích, số liệu (ví dụ cân nặng) và thời điểm chụp; reaction; báo cáo và danh sách chặn của bạn.';

  @override
  String get safety_privacy2Title => 'Ai thấy được';

  @override
  String get safety_privacy2Body =>
      'Hành trình riêng tư chỉ mình bạn thấy. Hành trình nhóm chỉ thành viên nhóm thấy. Link công khai chỉ hiện những gì bạn bật, và bạn có thể ẩn số liệu hoặc làm mờ ảnh. Ở chế độ chỉ trên máy, dữ liệu không rời khỏi điện thoại.';

  @override
  String get safety_privacy3Title => 'Chúng mình không làm gì';

  @override
  String get safety_privacy3Body =>
      'Không bán dữ liệu của bạn. Không quảng cáo. Không dùng ảnh của bạn cho mục đích nào khác ngoài hiển thị trong Ourney.';

  @override
  String get safety_privacy4Title => 'Thông báo';

  @override
  String get safety_privacy4Body =>
      'Lời nhắc check-in là thông báo cục bộ, được lên lịch ngay trên máy bạn.';

  @override
  String get safety_privacy5Title => 'Xoá dữ liệu';

  @override
  String get safety_privacy5Body =>
      'Vào Hồ sơ > Xoá tài khoản để xoá vĩnh viễn tài khoản, mọi check-in và ảnh của bạn trên máy chủ. Nếu bạn là chủ nhóm, quyền chủ nhóm được chuyển cho thành viên tham gia sớm nhất.';

  @override
  String get safety_privacy6Title => 'Liên hệ';

  @override
  String get safety_privacy6Body =>
      'Có câu hỏi về quyền riêng tư? Xem trang Liên hệ trong mục An toàn & hỗ trợ.';
}
