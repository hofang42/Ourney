import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'groups_localizations_en.dart';
import 'groups_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of GroupsL10n
/// returned by `GroupsL10n.of(context)`.
///
/// Applications need to include `GroupsL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/groups_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: GroupsL10n.localizationsDelegates,
///   supportedLocales: GroupsL10n.supportedLocales,
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
/// be consistent with the languages listed in the GroupsL10n.supportedLocales
/// property.
abstract class GroupsL10n {
  GroupsL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static GroupsL10n of(BuildContext context) {
    return Localizations.of<GroupsL10n>(context, GroupsL10n)!;
  }

  static const LocalizationsDelegate<GroupsL10n> delegate =
      _GroupsL10nDelegate();

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

  /// Title of the groups feature's main screen.
  ///
  /// In vi, this message translates to:
  /// **'Nhóm'**
  String get groups_title;

  /// No description provided for @groups_emptyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có nhóm nào'**
  String get groups_emptyTitle;

  /// No description provided for @groups_emptyMessage.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã mời của bạn bè, hoặc tạo hành trình nhóm ở tab Journeys.'**
  String get groups_emptyMessage;

  /// Button opening the manual invite-code entry (FR-D1).
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã mời'**
  String get groups_joinWithCode;

  /// Opens the journey create flow.
  ///
  /// In vi, this message translates to:
  /// **'Tạo hành trình nhóm'**
  String get groups_createGroup;

  /// List section header: running group journeys.
  ///
  /// In vi, this message translates to:
  /// **'Đang chạy'**
  String get groups_activeSection;

  /// List section header: ended or archived group journeys.
  ///
  /// In vi, this message translates to:
  /// **'Đã kết thúc'**
  String get groups_finishedSection;

  /// No description provided for @groups_loadError.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được danh sách nhóm.'**
  String get groups_loadError;

  /// No description provided for @groups_statusEnded.
  ///
  /// In vi, this message translates to:
  /// **'Đã kết thúc'**
  String get groups_statusEnded;

  /// No description provided for @groups_statusArchived.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu trữ'**
  String get groups_statusArchived;

  /// Day N of M of the journey.
  ///
  /// In vi, this message translates to:
  /// **'Ngày {day}/{total}'**
  String groups_dayOf(int day, int total);

  /// Day N of an open-ended journey.
  ///
  /// In vi, this message translates to:
  /// **'Ngày {day}'**
  String groups_dayOpen(int day);

  /// No description provided for @groups_joinTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tham gia nhóm'**
  String get groups_joinTitle;

  /// No description provided for @groups_joinCodeLabel.
  ///
  /// In vi, this message translates to:
  /// **'Mã mời'**
  String get groups_joinCodeLabel;

  /// No description provided for @groups_joinCodeHint.
  ///
  /// In vi, this message translates to:
  /// **'8 chữ cái hoặc chữ số'**
  String get groups_joinCodeHint;

  /// No description provided for @groups_joinInvalidCode.
  ///
  /// In vi, this message translates to:
  /// **'Mã mời gồm đúng 8 chữ cái hoặc chữ số.'**
  String get groups_joinInvalidCode;

  /// Shown on /join/<code> before confirming.
  ///
  /// In vi, this message translates to:
  /// **'Bạn được mời vào một hành trình nhóm'**
  String get groups_joinPreviewTitle;

  /// FR-D2 + late-join rule (SRS 3.1).
  ///
  /// In vi, this message translates to:
  /// **'Nhóm tối đa 10 người. Tiến độ của bạn tính từ ngày tham gia, và bạn vẫn xem được lịch sử của nhóm.'**
  String get groups_joinRules;

  /// No description provided for @groups_joinButton.
  ///
  /// In vi, this message translates to:
  /// **'Tham gia'**
  String get groups_joinButton;

  /// No description provided for @groups_errorNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Không có nhóm nào dùng mã này. Có thể chủ nhóm đã đổi mã, hãy xin mã mới nhé.'**
  String get groups_errorNotFound;

  /// No description provided for @groups_errorFull.
  ///
  /// In vi, this message translates to:
  /// **'Nhóm này đã đủ 10 thành viên.'**
  String get groups_errorFull;

  /// No description provided for @groups_errorBlocked.
  ///
  /// In vi, this message translates to:
  /// **'Bạn không thể tham gia nhóm này.'**
  String get groups_errorBlocked;

  /// No description provided for @groups_errorLimit.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đang chạy 3 hành trình. Kết thúc một hành trình rồi tham gia nhóm này nhé.'**
  String get groups_errorLimit;

  /// No description provided for @groups_errorEnded.
  ///
  /// In vi, this message translates to:
  /// **'Hành trình này đã kết thúc.'**
  String get groups_errorEnded;

  /// No description provided for @groups_errorForbidden.
  ///
  /// In vi, this message translates to:
  /// **'Bạn không có quyền làm việc này.'**
  String get groups_errorForbidden;

  /// No description provided for @groups_errorNotAlone.
  ///
  /// In vi, this message translates to:
  /// **'Nhóm vẫn còn thành viên khác. Hãy kết thúc hành trình thay vì xoá.'**
  String get groups_errorNotAlone;

  /// No description provided for @groups_errorInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Không thể thực hiện thao tác này.'**
  String get groups_errorInvalid;

  /// Consistency summary (FR-D3/D5).
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay {done}/{total} người đã check-in'**
  String groups_todayHeader(int done, int total);

  /// No description provided for @groups_doneSection.
  ///
  /// In vi, this message translates to:
  /// **'Đã check-in hôm nay'**
  String get groups_doneSection;

  /// No description provided for @groups_pendingSection.
  ///
  /// In vi, this message translates to:
  /// **'Chưa check-in hôm nay'**
  String get groups_pendingSection;

  /// Member row status (icon + text, not color only).
  ///
  /// In vi, this message translates to:
  /// **'Xong hôm nay'**
  String get groups_statusDone;

  /// No description provided for @groups_statusPending.
  ///
  /// In vi, this message translates to:
  /// **'Chưa check-in'**
  String get groups_statusPending;

  /// Marks the caller's own row.
  ///
  /// In vi, this message translates to:
  /// **'Bạn'**
  String get groups_you;

  /// No description provided for @groups_ownerBadge.
  ///
  /// In vi, this message translates to:
  /// **'Chủ nhóm'**
  String get groups_ownerBadge;

  /// Caption under a member's latest (older) photo.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh gần nhất: {date}'**
  String groups_latestPhoto(String date);

  /// No description provided for @groups_noPhotoYet.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có check-in nào'**
  String get groups_noPhotoYet;

  /// No description provided for @groups_endedBanner.
  ///
  /// In vi, this message translates to:
  /// **'Hành trình đã kết thúc. Ảnh và streak chỉ còn để xem.'**
  String get groups_endedBanner;

  /// No description provided for @groups_notFoundTitle.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy nhóm'**
  String get groups_notFoundTitle;

  /// No description provided for @groups_notMember.
  ///
  /// In vi, this message translates to:
  /// **'Bạn không còn là thành viên của nhóm này.'**
  String get groups_notMember;

  /// No description provided for @groups_todayLoadError.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được hoạt động hôm nay.'**
  String get groups_todayLoadError;

  /// No description provided for @groups_openTimeline.
  ///
  /// In vi, this message translates to:
  /// **'Dòng thời gian của tôi'**
  String get groups_openTimeline;

  /// Tooltip of the invite button.
  ///
  /// In vi, this message translates to:
  /// **'Mời bạn'**
  String get groups_invite;

  /// Tooltip of an overflow menu.
  ///
  /// In vi, this message translates to:
  /// **'Thêm thao tác'**
  String get groups_moreActions;

  /// Tooltip of a member's overflow menu.
  ///
  /// In vi, this message translates to:
  /// **'Thao tác với {name}'**
  String groups_memberActions(String name);

  /// Screen-reader label of a reaction button (FR-D4).
  ///
  /// In vi, this message translates to:
  /// **'Thả {emoji}, {count} lượt'**
  String groups_reactSemantics(String emoji, int count);

  /// No description provided for @groups_actionRotate.
  ///
  /// In vi, this message translates to:
  /// **'Đổi mã mời'**
  String get groups_actionRotate;

  /// No description provided for @groups_rotateTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đổi mã mời?'**
  String get groups_rotateTitle;

  /// No description provided for @groups_rotateMessage.
  ///
  /// In vi, this message translates to:
  /// **'Mã và link hiện tại sẽ hết hiệu lực. Thành viên đang ở trong nhóm vẫn giữ nguyên.'**
  String get groups_rotateMessage;

  /// No description provided for @groups_rotateDone.
  ///
  /// In vi, this message translates to:
  /// **'Đã tạo mã mời mới.'**
  String get groups_rotateDone;

  /// No description provided for @groups_actionEnd.
  ///
  /// In vi, this message translates to:
  /// **'Kết thúc hành trình'**
  String get groups_actionEnd;

  /// No description provided for @groups_endTitle.
  ///
  /// In vi, this message translates to:
  /// **'Kết thúc hành trình cho cả nhóm?'**
  String get groups_endTitle;

  /// No description provided for @groups_endMessage.
  ///
  /// In vi, this message translates to:
  /// **'Sau đó không ai check-in được nữa. Ảnh và streak vẫn còn để mọi người xem lại.'**
  String get groups_endMessage;

  /// No description provided for @groups_actionDelete.
  ///
  /// In vi, this message translates to:
  /// **'Xoá hành trình'**
  String get groups_actionDelete;

  /// No description provided for @groups_deleteTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xoá hành trình nhóm này?'**
  String get groups_deleteTitle;

  /// No description provided for @groups_deleteMessage.
  ///
  /// In vi, this message translates to:
  /// **'Bạn là thành viên duy nhất. Hành trình và ảnh của bạn sẽ bị xoá vĩnh viễn.'**
  String get groups_deleteMessage;

  /// No description provided for @groups_actionLeave.
  ///
  /// In vi, this message translates to:
  /// **'Rời nhóm'**
  String get groups_actionLeave;

  /// No description provided for @groups_leaveTitle.
  ///
  /// In vi, this message translates to:
  /// **'Rời nhóm này?'**
  String get groups_leaveTitle;

  /// SRS 3.1: leaving hides the member's check-ins.
  ///
  /// In vi, this message translates to:
  /// **'Các check-in của bạn sẽ bị ẩn khỏi nhóm. Nếu tham gia lại bằng mã mời, chúng sẽ hiện lại.'**
  String get groups_leaveMessage;

  /// No description provided for @groups_leaveOwnerNote.
  ///
  /// In vi, this message translates to:
  /// **'Bạn là chủ nhóm: quyền chủ nhóm sẽ chuyển cho người tham gia sớm nhất.'**
  String get groups_leaveOwnerNote;

  /// No description provided for @groups_leaveAloneNote.
  ///
  /// In vi, this message translates to:
  /// **'Bạn là thành viên duy nhất: hành trình sẽ được lưu trữ.'**
  String get groups_leaveAloneNote;

  /// No description provided for @groups_leftDone.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã rời nhóm.'**
  String get groups_leftDone;

  /// No description provided for @groups_actionRemove.
  ///
  /// In vi, this message translates to:
  /// **'Xoá khỏi nhóm'**
  String get groups_actionRemove;

  /// No description provided for @groups_removeTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xoá {name} khỏi nhóm?'**
  String groups_removeTitle(String name);

  /// No description provided for @groups_removeMessage.
  ///
  /// In vi, this message translates to:
  /// **'Check-in của người này sẽ bị ẩn khỏi nhóm. Họ vẫn có thể tham gia lại bằng mã mời nếu bạn không đổi mã.'**
  String get groups_removeMessage;

  /// No description provided for @groups_removedDone.
  ///
  /// In vi, this message translates to:
  /// **'Đã xoá {name} khỏi nhóm.'**
  String groups_removedDone(String name);

  /// Member menu entry; the flow belongs to the safety feature.
  ///
  /// In vi, this message translates to:
  /// **'Báo cáo'**
  String get groups_actionReport;

  /// Member menu entry; the flow belongs to the safety feature.
  ///
  /// In vi, this message translates to:
  /// **'Chặn'**
  String get groups_actionBlock;

  /// No description provided for @groups_inviteTitle.
  ///
  /// In vi, this message translates to:
  /// **'Mời bạn bè'**
  String get groups_inviteTitle;

  /// No description provided for @groups_inviteMessage.
  ///
  /// In vi, this message translates to:
  /// **'Gửi mã hoặc link cho bạn bè. Nhóm tối đa 10 người.'**
  String get groups_inviteMessage;

  /// No description provided for @groups_copyCode.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép mã'**
  String get groups_copyCode;

  /// No description provided for @groups_copied.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép mã mời.'**
  String get groups_copied;

  /// No description provided for @groups_shareLink.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ link'**
  String get groups_shareLink;

  /// Text sent through the share sheet.
  ///
  /// In vi, this message translates to:
  /// **'Cùng mình theo hành trình \"{title}\" trên Ourney: {link} (mã mời {code})'**
  String groups_shareText(String title, String link, String code);

  /// No description provided for @groups_qrSemantics.
  ///
  /// In vi, this message translates to:
  /// **'Mã QR của link mời'**
  String get groups_qrSemantics;

  /// No description provided for @groups_noInviteCode.
  ///
  /// In vi, this message translates to:
  /// **'Nhóm chưa có mã mời.'**
  String get groups_noInviteCode;

  /// No description provided for @groups_inviteClosed.
  ///
  /// In vi, this message translates to:
  /// **'Hành trình đã kết thúc nên không mời thêm được.'**
  String get groups_inviteClosed;
}

class _GroupsL10nDelegate extends LocalizationsDelegate<GroupsL10n> {
  const _GroupsL10nDelegate();

  @override
  Future<GroupsL10n> load(Locale locale) {
    return SynchronousFuture<GroupsL10n>(lookupGroupsL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_GroupsL10nDelegate old) => false;
}

GroupsL10n lookupGroupsL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return GroupsL10nEn();
    case 'vi':
      return GroupsL10nVi();
  }

  throw FlutterError(
    'GroupsL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
