import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'safety_localizations_en.dart';
import 'safety_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of SafetyL10n
/// returned by `SafetyL10n.of(context)`.
///
/// Applications need to include `SafetyL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/safety_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: SafetyL10n.localizationsDelegates,
///   supportedLocales: SafetyL10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the SafetyL10n.supportedLocales
/// property.
abstract class SafetyL10n {
  SafetyL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static SafetyL10n of(BuildContext context) {
    return Localizations.of<SafetyL10n>(context, SafetyL10n)!;
  }

  static const LocalizationsDelegate<SafetyL10n> delegate =
      _SafetyL10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// Title of the safety feature's main screen.
  ///
  /// In vi, this message translates to:
  /// **'An toàn & hỗ trợ'**
  String get safety_title;

  /// Intro text on the safety hub.
  ///
  /// In vi, this message translates to:
  /// **'Ourney là nơi để cùng nhau giữ thói quen. Bạn có thể báo cáo nội dung xấu, chặn người khác và đọc các điều khoản ở đây.'**
  String get safety_hubIntro;

  /// Hub entry and page title: terms of use (EULA).
  ///
  /// In vi, this message translates to:
  /// **'Điều khoản sử dụng'**
  String get safety_hubEula;

  /// Hub entry and page title: privacy policy.
  ///
  /// In vi, this message translates to:
  /// **'Chính sách quyền riêng tư'**
  String get safety_hubPrivacy;

  /// Hub entry and page title: contact.
  ///
  /// In vi, this message translates to:
  /// **'Liên hệ'**
  String get safety_hubContact;

  /// Hub entry and page title: list of blocked users.
  ///
  /// In vi, this message translates to:
  /// **'Người đã chặn'**
  String get safety_hubBlocked;

  /// Heading of the how-to-report card on the hub.
  ///
  /// In vi, this message translates to:
  /// **'Cách báo cáo'**
  String get safety_hubHowToReport;

  /// Body of the how-to-report card on the hub.
  ///
  /// In vi, this message translates to:
  /// **'Trong nhóm, mở menu của một check-in hoặc của một thành viên rồi chọn \"Báo cáo\" hoặc \"Chặn\". Nội dung bạn báo cáo sẽ bị ẩn khỏi máy bạn ngay.'**
  String get safety_hubHowToReportBody;

  /// Title of the report sheet for a check-in.
  ///
  /// In vi, this message translates to:
  /// **'Báo cáo check-in'**
  String get safety_reportCheckInTitle;

  /// Title of the report sheet for a user.
  ///
  /// In vi, this message translates to:
  /// **'Báo cáo người dùng'**
  String get safety_reportUserTitle;

  /// Prompt above the report reasons.
  ///
  /// In vi, this message translates to:
  /// **'Có chuyện gì vậy? Báo cáo được giữ kín, người bị báo cáo sẽ không biết là bạn.'**
  String get safety_reportPrompt;

  /// Report reason: spam.
  ///
  /// In vi, this message translates to:
  /// **'Spam hoặc lừa đảo'**
  String get safety_reasonSpam;

  /// Report reason: nudity.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh khoả thân hoặc khiêu dâm'**
  String get safety_reasonNudity;

  /// Report reason: harassment.
  ///
  /// In vi, this message translates to:
  /// **'Quấy rối hoặc bắt nạt'**
  String get safety_reasonHarassment;

  /// Report reason: self-harm.
  ///
  /// In vi, this message translates to:
  /// **'Tự làm hại bản thân'**
  String get safety_reasonSelfHarm;

  /// Report reason: other.
  ///
  /// In vi, this message translates to:
  /// **'Lý do khác'**
  String get safety_reasonOther;

  /// Label of the optional note field in the report form.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chú (không bắt buộc)'**
  String get safety_noteLabel;

  /// Hint of the optional note field.
  ///
  /// In vi, this message translates to:
  /// **'Thêm chi tiết giúp chúng mình xử lý nhanh hơn'**
  String get safety_noteHint;

  /// Submit button of the report form.
  ///
  /// In vi, this message translates to:
  /// **'Gửi báo cáo'**
  String get safety_reportSubmit;

  /// Cancel button of the report form.
  ///
  /// In vi, this message translates to:
  /// **'Huỷ'**
  String get safety_reportCancel;

  /// Confirmation after a report was sent.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi báo cáo. Cảm ơn bạn! Nội dung này đã được ẩn khỏi máy bạn.'**
  String get safety_reportSent;

  /// Button that closes the report confirmation.
  ///
  /// In vi, this message translates to:
  /// **'Xong'**
  String get safety_reportDone;

  /// Button on the report confirmation to also block the user.
  ///
  /// In vi, this message translates to:
  /// **'Chặn luôn người này'**
  String get safety_reportAlsoBlock;

  /// Title of the supportive message shown with the self-harm reason.
  ///
  /// In vi, this message translates to:
  /// **'Bạn không một mình'**
  String get safety_selfHarmTitle;

  /// Supportive message shown with the self-harm reason. No phone numbers.
  ///
  /// In vi, this message translates to:
  /// **'Nếu bạn hoặc ai đó đang gặp nguy hiểm ngay lúc này, hãy gọi dịch vụ cấp cứu tại nơi bạn ở. Chia sẻ với một người bạn tin tưởng, người thân hoặc chuyên gia tâm lý cũng có thể giúp ích rất nhiều.'**
  String get safety_selfHarmBody;

  /// Error: too many reports (20 per 24 hours).
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã gửi nhiều báo cáo trong 24 giờ qua. Vui lòng thử lại sau.'**
  String get safety_errorRateLimited;

  /// Error: reported content or user not found.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung này không còn tồn tại hoặc bạn không xem được nữa.'**
  String get safety_errorNotFound;

  /// Error: reporting or blocking yourself.
  ///
  /// In vi, this message translates to:
  /// **'Không thể thực hiện với chính bạn.'**
  String get safety_errorInvalid;

  /// Error: offline.
  ///
  /// In vi, this message translates to:
  /// **'Không có kết nối mạng. Thử lại khi có mạng nhé.'**
  String get safety_errorOffline;

  /// Generic error.
  ///
  /// In vi, this message translates to:
  /// **'Có lỗi xảy ra. Thử lại sau nhé.'**
  String get safety_errorGeneric;

  /// Shown in local-only mode instead of the report/block UI.
  ///
  /// In vi, this message translates to:
  /// **'Báo cáo và chặn cần máy chủ Ourney. Ở chế độ chỉ trên máy, không ai khác thấy nội dung của bạn.'**
  String get safety_needsAccount;

  /// Block confirmation title.
  ///
  /// In vi, this message translates to:
  /// **'Chặn {name}?'**
  String safety_blockTitle(String name);

  /// Block confirmation explanation.
  ///
  /// In vi, this message translates to:
  /// **'Hai bạn sẽ không thấy check-in và reaction của nhau nữa, và người này không thể vào nhóm có bạn. Họ sẽ không được báo là bị chặn. Bạn có thể bỏ chặn bất cứ lúc nào.'**
  String get safety_blockBody;

  /// Confirm button of the block dialog.
  ///
  /// In vi, this message translates to:
  /// **'Chặn'**
  String get safety_blockConfirm;

  /// Cancel button of the block dialog.
  ///
  /// In vi, this message translates to:
  /// **'Huỷ'**
  String get safety_blockCancel;

  /// Snack bar after blocking.
  ///
  /// In vi, this message translates to:
  /// **'Đã chặn {name}.'**
  String safety_blocked(String name);

  /// Unblock confirmation title.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ chặn {name}?'**
  String safety_unblockTitle(String name);

  /// Unblock confirmation explanation.
  ///
  /// In vi, this message translates to:
  /// **'Hai bạn sẽ lại thấy nội dung của nhau trong những nhóm chung.'**
  String get safety_unblockBody;

  /// Confirm/unblock button.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ chặn'**
  String get safety_unblockConfirm;

  /// Snack bar after unblocking.
  ///
  /// In vi, this message translates to:
  /// **'Đã bỏ chặn {name}.'**
  String safety_unblocked(String name);

  /// Fallback name for a user whose name is not known on this device.
  ///
  /// In vi, this message translates to:
  /// **'Người dùng'**
  String get safety_unknownUser;

  /// Empty state title of the blocked users list.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa chặn ai'**
  String get safety_blockedEmptyTitle;

  /// Empty state message of the blocked users list.
  ///
  /// In vi, this message translates to:
  /// **'Người bạn chặn sẽ hiện ở đây để bạn bỏ chặn khi muốn.'**
  String get safety_blockedEmptyMessage;

  /// Error loading the blocked list.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được danh sách. Thử lại sau nhé.'**
  String get safety_loadError;

  /// Retry button.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get safety_retry;

  /// Intro of the contact page.
  ///
  /// In vi, this message translates to:
  /// **'Cần giúp đỡ, muốn góp ý hay báo cáo một vấn đề an toàn khẩn cấp? Viết cho chúng mình. Báo cáo nội dung được xem xét trong vòng 24 giờ.'**
  String get safety_contactIntro;

  /// Label above the support email address.
  ///
  /// In vi, this message translates to:
  /// **'Email hỗ trợ'**
  String get safety_contactEmailLabel;

  /// Button that opens the mail app.
  ///
  /// In vi, this message translates to:
  /// **'Gửi email'**
  String get safety_contactSend;

  /// Button that copies the email address.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép địa chỉ'**
  String get safety_contactCopy;

  /// Snack bar after copying the email.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép địa chỉ email.'**
  String get safety_contactCopied;

  /// Subject line of the support email.
  ///
  /// In vi, this message translates to:
  /// **'Ourney - hỗ trợ'**
  String get safety_contactSubject;

  /// Error when no mail app can be opened.
  ///
  /// In vi, this message translates to:
  /// **'Không mở được ứng dụng email. Hãy sao chép địa chỉ và gửi từ ứng dụng bạn dùng.'**
  String get safety_contactNoMailApp;

  /// Title of the EULA acceptance screen.
  ///
  /// In vi, this message translates to:
  /// **'Trước khi bắt đầu'**
  String get safety_eulaAcceptTitle;

  /// Intro of the EULA acceptance screen.
  ///
  /// In vi, this message translates to:
  /// **'Ourney không dung thứ nội dung phản cảm hay hành vi lạm dụng. Hãy đọc và đồng ý với điều khoản sử dụng để tiếp tục.'**
  String get safety_eulaAcceptIntro;

  /// Checkbox label on the EULA acceptance screen.
  ///
  /// In vi, this message translates to:
  /// **'Tôi đã đọc và đồng ý với Điều khoản sử dụng và Chính sách quyền riêng tư.'**
  String get safety_eulaAcceptCheckbox;

  /// Accept button on the EULA acceptance screen.
  ///
  /// In vi, this message translates to:
  /// **'Đồng ý và tiếp tục'**
  String get safety_eulaAcceptButton;

  /// Last updated line on legal pages.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật lần cuối: {date}'**
  String safety_lastUpdated(String date);

  /// EULA section heading.
  ///
  /// In vi, this message translates to:
  /// **'1. Đồng ý điều khoản'**
  String get safety_eula1Title;

  /// EULA section body.
  ///
  /// In vi, this message translates to:
  /// **'Khi tạo tài khoản hoặc dùng Ourney, bạn đồng ý với các điều khoản này. Nếu không đồng ý, vui lòng không sử dụng ứng dụng.'**
  String get safety_eula1Body;

  /// EULA section heading.
  ///
  /// In vi, this message translates to:
  /// **'2. Không dung thứ nội dung phản cảm'**
  String get safety_eula2Title;

  /// EULA section body: zero tolerance.
  ///
  /// In vi, this message translates to:
  /// **'Ourney không chấp nhận bất kỳ nội dung phản cảm hay người dùng lạm dụng nào. Bạn không được đăng hoặc gửi: ảnh khoả thân, khiêu dâm; nội dung quấy rối, bắt nạt, đe doạ; phát ngôn thù ghét hoặc phân biệt đối xử; bạo lực; nội dung cổ vũ tự làm hại bản thân; spam, lừa đảo; nội dung vi phạm pháp luật hoặc quyền của người khác.'**
  String get safety_eula2Body;

  /// EULA section heading.
  ///
  /// In vi, this message translates to:
  /// **'3. Nội dung của bạn'**
  String get safety_eula3Title;

  /// EULA section body.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh, chú thích và số liệu bạn đăng vẫn thuộc về bạn. Bạn cho phép Ourney lưu trữ và hiển thị chúng cho những người bạn chọn chia sẻ (thành viên nhóm, người có link công khai). Bạn chịu trách nhiệm về nội dung mình đăng.'**
  String get safety_eula3Body;

  /// EULA section heading.
  ///
  /// In vi, this message translates to:
  /// **'4. Báo cáo, chặn và kiểm duyệt'**
  String get safety_eula4Title;

  /// EULA section body.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có thể báo cáo check-in hoặc người dùng và chặn bất kỳ ai. Chúng mình xem xét báo cáo trong vòng 24 giờ, gỡ nội dung vi phạm và khoá tài khoản của người vi phạm.'**
  String get safety_eula4Body;

  /// EULA section heading.
  ///
  /// In vi, this message translates to:
  /// **'5. Chấm dứt'**
  String get safety_eula5Title;

  /// EULA section body.
  ///
  /// In vi, this message translates to:
  /// **'Chúng mình có thể tạm khoá hoặc xoá tài khoản vi phạm các điều khoản này mà không cần báo trước. Bạn có thể xoá tài khoản bất cứ lúc nào trong Hồ sơ.'**
  String get safety_eula5Body;

  /// EULA section heading.
  ///
  /// In vi, this message translates to:
  /// **'6. Miễn trừ và thay đổi'**
  String get safety_eula6Title;

  /// EULA section body.
  ///
  /// In vi, this message translates to:
  /// **'Ourney được cung cấp \"như hiện có\" và không thay thế lời khuyên y tế, dinh dưỡng hay tập luyện chuyên môn. Khi điều khoản thay đổi, chúng mình sẽ thông báo trong ứng dụng.'**
  String get safety_eula6Body;

  /// Privacy section heading.
  ///
  /// In vi, this message translates to:
  /// **'Chúng mình lưu gì'**
  String get safety_privacy1Title;

  /// Privacy section body: data stored.
  ///
  /// In vi, this message translates to:
  /// **'Email (để đăng nhập); tên hiển thị, username và ảnh đại diện; hành trình bạn tạo; check-in gồm ảnh, chú thích, số liệu (ví dụ cân nặng) và thời điểm chụp; reaction; báo cáo và danh sách chặn của bạn.'**
  String get safety_privacy1Body;

  /// Privacy section heading.
  ///
  /// In vi, this message translates to:
  /// **'Ai thấy được'**
  String get safety_privacy2Title;

  /// Privacy section body: who can see.
  ///
  /// In vi, this message translates to:
  /// **'Hành trình riêng tư chỉ mình bạn thấy. Hành trình nhóm chỉ thành viên nhóm thấy. Link công khai chỉ hiện những gì bạn bật, và bạn có thể ẩn số liệu hoặc làm mờ ảnh. Ở chế độ chỉ trên máy, dữ liệu không rời khỏi điện thoại.'**
  String get safety_privacy2Body;

  /// Privacy section heading.
  ///
  /// In vi, this message translates to:
  /// **'Chúng mình không làm gì'**
  String get safety_privacy3Title;

  /// Privacy section body: no selling.
  ///
  /// In vi, this message translates to:
  /// **'Không bán dữ liệu của bạn. Không quảng cáo. Không dùng ảnh của bạn cho mục đích nào khác ngoài hiển thị trong Ourney.'**
  String get safety_privacy3Body;

  /// Privacy section heading.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo'**
  String get safety_privacy4Title;

  /// Privacy section body: notifications.
  ///
  /// In vi, this message translates to:
  /// **'Lời nhắc check-in là thông báo cục bộ, được lên lịch ngay trên máy bạn.'**
  String get safety_privacy4Body;

  /// Privacy section heading.
  ///
  /// In vi, this message translates to:
  /// **'Xoá dữ liệu'**
  String get safety_privacy5Title;

  /// Privacy section body: deletion.
  ///
  /// In vi, this message translates to:
  /// **'Vào Hồ sơ > Xoá tài khoản để xoá vĩnh viễn tài khoản, mọi check-in và ảnh của bạn trên máy chủ. Nếu bạn là chủ nhóm, quyền chủ nhóm được chuyển cho thành viên tham gia sớm nhất.'**
  String get safety_privacy5Body;

  /// Privacy section heading.
  ///
  /// In vi, this message translates to:
  /// **'Liên hệ'**
  String get safety_privacy6Title;

  /// Privacy section body: contact.
  ///
  /// In vi, this message translates to:
  /// **'Có câu hỏi về quyền riêng tư? Xem trang Liên hệ trong mục An toàn & hỗ trợ.'**
  String get safety_privacy6Body;
}

class _SafetyL10nDelegate extends LocalizationsDelegate<SafetyL10n> {
  const _SafetyL10nDelegate();

  @override
  Future<SafetyL10n> load(Locale locale) {
    return SynchronousFuture<SafetyL10n>(lookupSafetyL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_SafetyL10nDelegate old) => false;
}

SafetyL10n lookupSafetyL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return SafetyL10nEn();
    case 'vi':
      return SafetyL10nVi();
  }

  throw FlutterError(
    'SafetyL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
