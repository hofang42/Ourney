import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'sharing_localizations_en.dart';
import 'sharing_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of SharingL10n
/// returned by `SharingL10n.of(context)`.
///
/// Applications need to include `SharingL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/sharing_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: SharingL10n.localizationsDelegates,
///   supportedLocales: SharingL10n.supportedLocales,
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
/// be consistent with the languages listed in the SharingL10n.supportedLocales
/// property.
abstract class SharingL10n {
  SharingL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static SharingL10n of(BuildContext context) {
    return Localizations.of<SharingL10n>(context, SharingL10n)!;
  }

  static const LocalizationsDelegate<SharingL10n> delegate =
      _SharingL10nDelegate();

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

  /// Feature name.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ'**
  String get sharing_title;

  /// SCR-82 eyebrow and full-screen title.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ hành trình'**
  String get sharing_shareThisJourney;

  /// Opens SCR-83 from the share sheet.
  ///
  /// In vi, this message translates to:
  /// **'Sửa câu chuyện'**
  String get sharing_editStory;

  /// Friends block heading.
  ///
  /// In vi, this message translates to:
  /// **'Bạn bè'**
  String get sharing_friends;

  /// Ticks every friend.
  ///
  /// In vi, this message translates to:
  /// **'Chọn tất cả'**
  String get sharing_selectAll;

  /// Unticks every friend.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ chọn'**
  String get sharing_clear;

  /// Friend search field (more than 10 friends).
  ///
  /// In vi, this message translates to:
  /// **'Tìm bạn'**
  String get sharing_searchFriends;

  /// Label of a friend the journey is already shared with.
  ///
  /// In vi, this message translates to:
  /// **'Có thể xem'**
  String get sharing_canSee;

  /// Removes one friend share / a saved journey.
  ///
  /// In vi, this message translates to:
  /// **'Xóa'**
  String get sharing_remove;

  /// S7: nobody pre-ticked for sensitive templates.
  ///
  /// In vi, this message translates to:
  /// **'Hành trình nhạy cảm: chọn từng người'**
  String get sharing_sensitiveHelper;

  /// Shown for a running journey.
  ///
  /// In vi, this message translates to:
  /// **'Họ sẽ thấy ảnh mới khi bạn đăng'**
  String get sharing_runningHelper;

  /// Primary button with the number of newly ticked friends.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{Chia sẻ cho {count} bạn}}'**
  String sharing_shareWith(int count);

  /// Disabled primary button when no new friend is ticked.
  ///
  /// In vi, this message translates to:
  /// **'Chọn bạn để chia sẻ'**
  String get sharing_pickFriends;

  /// Friends block without friends.
  ///
  /// In vi, this message translates to:
  /// **'Kết bạn để chia sẻ hành trình với họ'**
  String get sharing_noFriends;

  /// Snack after sharing.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{Đã chia sẻ cho {count} bạn}}'**
  String sharing_sharedSnack(int count);

  /// Semantics of the Remove button on a friend row.
  ///
  /// In vi, this message translates to:
  /// **'Gỡ {name} khỏi người xem'**
  String sharing_removeFriendShare(String name);

  /// Public link block heading.
  ///
  /// In vi, this message translates to:
  /// **'Liên kết công khai'**
  String get sharing_publicLink;

  /// S9: link locked while the journey runs.
  ///
  /// In vi, this message translates to:
  /// **'Liên kết mở khi hành trình kết thúc'**
  String get sharing_linkLockedTitle;

  /// Second line of the locked link block.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thể bật liên kết'**
  String get sharing_linkLockedSub;

  /// Group member who is not the owner (S32).
  ///
  /// In vi, this message translates to:
  /// **'Chủ hành trình quản lý liên kết'**
  String get sharing_linkOwnerOnly;

  /// Public link switch.
  ///
  /// In vi, this message translates to:
  /// **'Bật liên kết'**
  String get sharing_linkOn;

  /// Subtitle of the link switch while off.
  ///
  /// In vi, this message translates to:
  /// **'Đang tắt'**
  String get sharing_linkOff;

  /// R2-07: under-18 owners cannot turn the link on.
  ///
  /// In vi, this message translates to:
  /// **'Link công khai dành cho người từ 18 tuổi'**
  String get sharing_under18;

  /// Sensitive template link note.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh được làm mờ trong bản xem trước'**
  String get sharing_blurredPreview;

  /// Copies the public link.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép'**
  String get sharing_copyLink;

  /// Snack after copying.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép liên kết'**
  String get sharing_linkCopied;

  /// Rotates the public token.
  ///
  /// In vi, this message translates to:
  /// **'Đặt lại'**
  String get sharing_resetLink;

  /// Confirm dialog title.
  ///
  /// In vi, this message translates to:
  /// **'Đặt lại liên kết?'**
  String get sharing_resetConfirmTitle;

  /// Confirm dialog body.
  ///
  /// In vi, this message translates to:
  /// **'Liên kết cũ sẽ không mở được nữa. Số liệu đã đếm vẫn giữ.'**
  String get sharing_resetConfirmBody;

  /// Under the link actions.
  ///
  /// In vi, this message translates to:
  /// **'Ai có liên kết cũng có thể xem và làm theo hành trình.'**
  String get sharing_linkHelper;

  /// S22 switch.
  ///
  /// In vi, this message translates to:
  /// **'Hiện số liệu'**
  String get sharing_showCounts;

  /// S22 switch hint.
  ///
  /// In vi, this message translates to:
  /// **'Hiện lượt thích và số người làm theo cho người xem'**
  String get sharing_showCountsHint;

  /// S25 switch.
  ///
  /// In vi, this message translates to:
  /// **'Cho phép mọi người tương tác'**
  String get sharing_letAnyoneReact;

  /// S25 switch hint.
  ///
  /// In vi, this message translates to:
  /// **'Người có tài khoản Ourney có thể thích'**
  String get sharing_letAnyoneReactHint;

  /// S27 switch.
  ///
  /// In vi, this message translates to:
  /// **'Cho phép người xem gửi lời mời kết bạn'**
  String get sharing_allowRequests;

  /// S27 switch hint.
  ///
  /// In vi, this message translates to:
  /// **'Người xem có thể gửi lời mời kết bạn'**
  String get sharing_allowRequestsHint;

  /// S21 owner stats line, opens SCR-88.
  ///
  /// In vi, this message translates to:
  /// **'{views} lượt xem · {likes} ❤️ · {started} đã bắt đầu'**
  String sharing_statsLine(String views, String likes, String started);

  /// Revokes every share.
  ///
  /// In vi, this message translates to:
  /// **'Dừng chia sẻ'**
  String get sharing_stopSharing;

  /// Confirm text of Stop sharing (owner).
  ///
  /// In vi, this message translates to:
  /// **'Mọi người sẽ mất quyền truy cập. Người đã bắt đầu vẫn giữ hành trình của họ.'**
  String get sharing_stopConfirm;

  /// Confirm text of Stop sharing (group member).
  ///
  /// In vi, this message translates to:
  /// **'Những người bạn đã chia sẻ sẽ mất quyền xem. Lượt chia sẻ của thành viên khác vẫn giữ.'**
  String get sharing_stopMineConfirm;

  /// S31 withdraw consent.
  ///
  /// In vi, this message translates to:
  /// **'Xóa ảnh của tôi khỏi chia sẻ'**
  String get sharing_removeMyPhotos;

  /// Confirm text of S31.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh của bạn sẽ không hiện với người ngoài nhóm nữa.'**
  String get sharing_removeMyPhotosConfirm;

  /// Warm warning sheet (sensitive template, S10).
  ///
  /// In vi, this message translates to:
  /// **'Ai có link đều xem được hành trình này'**
  String get sharing_warnTitle;

  /// Warning bullet 1.
  ///
  /// In vi, this message translates to:
  /// **'Bất kỳ ai nhận được link đều có thể xem.'**
  String get sharing_warnAnyone;

  /// Warning bullet 2.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ ảnh bạn chọn mới hiện; bản xem trước được làm mờ.'**
  String get sharing_warnSelected;

  /// Warning bullet 3.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có thể tắt link bất cứ lúc nào.'**
  String get sharing_warnUndo;

  /// Warning sheet confirm.
  ///
  /// In vi, this message translates to:
  /// **'Bật link'**
  String get sharing_warnTurnOn;

  /// Warm warning before a public switch on a sensitive template (S28).
  ///
  /// In vi, this message translates to:
  /// **'Đây là một hành trình riêng tư'**
  String get sharing_warnSwitchTitle;

  /// Warning body.
  ///
  /// In vi, this message translates to:
  /// **'Người ngoài danh sách bạn bè sẽ thấy hoặc làm được nhiều hơn. Bạn có thể tắt lại bất cứ lúc nào.'**
  String get sharing_warnSwitchBody;

  /// Warning confirm.
  ///
  /// In vi, this message translates to:
  /// **'Vẫn bật'**
  String get sharing_warnSwitchConfirm;

  /// S29 block heading.
  ///
  /// In vi, this message translates to:
  /// **'Đồng thuận của nhóm'**
  String get sharing_consentTitle;

  /// S30.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ ảnh của người đã đồng ý được chia sẻ'**
  String get sharing_consentHelper;

  /// Consent status.
  ///
  /// In vi, this message translates to:
  /// **'Đã đồng ý'**
  String get sharing_consentAgreed;

  /// Consent status.
  ///
  /// In vi, this message translates to:
  /// **'Đang chờ'**
  String get sharing_consentWaiting;

  /// Consent status.
  ///
  /// In vi, this message translates to:
  /// **'Đã từ chối'**
  String get sharing_consentDeclined;

  /// Consent status.
  ///
  /// In vi, this message translates to:
  /// **'Đã rút ảnh'**
  String get sharing_consentWithdrawn;

  /// S29 consent request button.
  ///
  /// In vi, this message translates to:
  /// **'Hỏi nhóm trước'**
  String get sharing_askGroup;

  /// Shown with Ask the group first.
  ///
  /// In vi, this message translates to:
  /// **'Hành trình nhóm cần hỏi mọi người trước khi chia sẻ ra ngoài.'**
  String get sharing_askGroupHint;

  /// Snack after asking the group.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi yêu cầu tới nhóm'**
  String get sharing_askedSnack;

  /// forbidden from share_journey.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ chia sẻ được với bạn bè'**
  String get sharing_errorNotFriend;

  /// rate_limited.
  ///
  /// In vi, this message translates to:
  /// **'Chậm lại một chút rồi thử lại nhé'**
  String get sharing_errorRateLimited;

  /// SCR-83 header.
  ///
  /// In vi, this message translates to:
  /// **'Câu chuyện của bạn'**
  String get sharing_storyHeader;

  /// SCR-83 field.
  ///
  /// In vi, this message translates to:
  /// **'Tiêu đề câu chuyện'**
  String get sharing_storyTitleField;

  /// SCR-83 field.
  ///
  /// In vi, this message translates to:
  /// **'Giới thiệu'**
  String get sharing_introField;

  /// SCR-83 intro hint.
  ///
  /// In vi, this message translates to:
  /// **'Vì sao tôi bắt đầu…'**
  String get sharing_introHint;

  /// SCR-83 field / SCR-84 section.
  ///
  /// In vi, this message translates to:
  /// **'Tôi đã học được gì'**
  String get sharing_lessonsField;

  /// Optional field marker.
  ///
  /// In vi, this message translates to:
  /// **'Không bắt buộc'**
  String get sharing_optional;

  /// Cover picker button.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ảnh bìa'**
  String get sharing_pickCover;

  /// Cover picker sheet title.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh bìa'**
  String get sharing_coverTitle;

  /// Empty photo grid.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có ảnh nào'**
  String get sharing_noPhotosYet;

  /// SCR-83 grid heading.
  ///
  /// In vi, this message translates to:
  /// **'Ẩn ảnh'**
  String get sharing_hidePhotos;

  /// SCR-83 grid hint.
  ///
  /// In vi, this message translates to:
  /// **'Chạm ảnh để ẩn khỏi mọi lượt chia sẻ'**
  String get sharing_hidePhotosHint;

  /// Semantics of a hidden photo.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh ngày {date}, đã ẩn khi chia sẻ'**
  String sharing_photoHidden(String date);

  /// Semantics of a shown photo.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh ngày {date}, đang hiện khi chia sẻ'**
  String sharing_photoShown(String date);

  /// Snack after saving.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu câu chuyện'**
  String get sharing_storySaved;

  /// Shared with me section.
  ///
  /// In vi, this message translates to:
  /// **'Từ bạn bè'**
  String get sharing_fromFriends;

  /// Saved public journeys (S26).
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu'**
  String get sharing_saved;

  /// Owner line of a shared journey row.
  ///
  /// In vi, this message translates to:
  /// **'bởi {name}'**
  String sharing_byName(String name);

  /// S12 badge of a retold journey.
  ///
  /// In vi, this message translates to:
  /// **'Kể lại'**
  String get sharing_imported;

  /// Unseen share dot label.
  ///
  /// In vi, this message translates to:
  /// **'Mới'**
  String get sharing_newBadge;

  /// Saved row subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Đã thích qua liên kết'**
  String get sharing_savedFromLink;

  /// Row status of a running journey.
  ///
  /// In vi, this message translates to:
  /// **'Đang diễn ra'**
  String get sharing_live;

  /// Row status of an ended journey.
  ///
  /// In vi, this message translates to:
  /// **'Đã kết thúc'**
  String get sharing_finished;

  /// Shared with me empty state.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có ai chia sẻ với bạn'**
  String get sharing_emptyTitle;

  /// Shared with me empty state.
  ///
  /// In vi, this message translates to:
  /// **'Khi bạn bè chia sẻ một hành trình, nó sẽ hiện ở đây.'**
  String get sharing_emptyMessage;

  /// Semantics of the Remove button on a saved row.
  ///
  /// In vi, this message translates to:
  /// **'Xóa {title} khỏi mục đã lưu'**
  String sharing_removeSavedSemantics(String title);

  /// SCR-84 revoked state.
  ///
  /// In vi, this message translates to:
  /// **'Hành trình này đã được đặt riêng tư'**
  String get sharing_privateNow;

  /// Back button text.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại'**
  String get sharing_goBack;

  /// S24 stranger add owner.
  ///
  /// In vi, this message translates to:
  /// **'Thêm bạn'**
  String get sharing_addFriend;

  /// After sending a friend request.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi'**
  String get sharing_requested;

  /// Eyebrow of a running shared journey.
  ///
  /// In vi, this message translates to:
  /// **'Trực tiếp · Ngày {day}'**
  String sharing_liveDay(int day);

  /// S12 eyebrow of a retold journey.
  ///
  /// In vi, this message translates to:
  /// **'Kể lại · {range} · theo ngày chụp'**
  String sharing_importedRange(String range);

  /// Number of photos.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{{count} khoảnh khắc}}'**
  String sharing_moments(int count);

  /// Expands the intro.
  ///
  /// In vi, this message translates to:
  /// **'thêm'**
  String get sharing_more;

  /// Collapses the intro.
  ///
  /// In vi, this message translates to:
  /// **'thu gọn'**
  String get sharing_less;

  /// S22 counts line for viewers.
  ///
  /// In vi, this message translates to:
  /// **'❤️ {likes} · {follows} người đã làm hành trình này'**
  String sharing_counts(int likes, int follows);

  /// Day label of a photo.
  ///
  /// In vi, this message translates to:
  /// **'Ngày {day}'**
  String sharing_dayN(int day);

  /// Like a photo.
  ///
  /// In vi, this message translates to:
  /// **'Thích'**
  String get sharing_like;

  /// Unlike a photo.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ thích'**
  String get sharing_unlike;

  /// Reply with a photo (S13).
  ///
  /// In vi, this message translates to:
  /// **'Trả lời'**
  String get sharing_reply;

  /// Under the reply button.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ {name} thấy câu trả lời của bạn'**
  String sharing_replyHint(String name);

  /// S15 follow button.
  ///
  /// In vi, this message translates to:
  /// **'Làm theo'**
  String get sharing_doThisJourney;

  /// Group journey sharer line.
  ///
  /// In vi, this message translates to:
  /// **'{name} đã chia sẻ'**
  String sharing_sharedBy(String name);

  /// S26 after a stranger like.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu vào mục Đã lưu'**
  String get sharing_savedSnack;

  /// Snack after Add friend.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi lời mời kết bạn'**
  String get sharing_requestSentSnack;

  /// Semantics of a blurred photo.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh đã được làm mờ'**
  String get sharing_photoBlurred;

  /// Preview strip.
  ///
  /// In vi, this message translates to:
  /// **'Xem trước như bạn bè'**
  String get sharing_preview;

  /// SCR-87 title.
  ///
  /// In vi, this message translates to:
  /// **'Làm hành trình này'**
  String get sharing_followTitle;

  /// SCR-87 card title.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu hành trình {style} của riêng bạn'**
  String sharing_startYourOwn(String style);

  /// Duration chip.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{{count} ngày}}'**
  String sharing_days(int count);

  /// Open-ended duration chip.
  ///
  /// In vi, this message translates to:
  /// **'Không giới hạn'**
  String get sharing_openEnded;

  /// Rhythm chip.
  ///
  /// In vi, this message translates to:
  /// **'Hằng ngày'**
  String get sharing_daily;

  /// Metric chip when none.
  ///
  /// In vi, this message translates to:
  /// **'Không số liệu'**
  String get sharing_noMetrics;

  /// SCR-87 list heading.
  ///
  /// In vi, this message translates to:
  /// **'Bạn sẽ có'**
  String get sharing_whatYouGet;

  /// SCR-87 list item.
  ///
  /// In vi, this message translates to:
  /// **'Cùng phong cách'**
  String get sharing_sameStyle;

  /// SCR-87 list item.
  ///
  /// In vi, this message translates to:
  /// **'Cùng nhịp điệu'**
  String get sharing_sameRhythm;

  /// SCR-87 list item.
  ///
  /// In vi, this message translates to:
  /// **'Cùng chỉ số'**
  String get sharing_sameMetrics;

  /// SCR-87 note.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh và số liệu của bạn bắt đầu mới hoàn toàn.'**
  String get sharing_startFresh;

  /// S35.
  ///
  /// In vi, this message translates to:
  /// **'Hành trình nhóm — bạn sẽ mời người của mình'**
  String get sharing_squadNote;

  /// SCR-87 primary.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu hành trình'**
  String get sharing_startThis;

  /// SCR-87 secondary.
  ///
  /// In vi, this message translates to:
  /// **'Thay đổi một chút'**
  String get sharing_changeSomething;

  /// S36 chip on the prefilled quick setup.
  ///
  /// In vi, this message translates to:
  /// **'Theo hành trình của {name}'**
  String sharing_basedOn(String name);

  /// Semantics of the chip close button.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ nguồn hành trình'**
  String get sharing_removeBasedOn;

  /// SCR-88 title.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin chi tiết'**
  String get sharing_insightsTitle;

  /// SCR-88 tile.
  ///
  /// In vi, this message translates to:
  /// **'Lượt xem'**
  String get sharing_views;

  /// SCR-88 tile.
  ///
  /// In vi, this message translates to:
  /// **'Lượt thích'**
  String get sharing_likes;

  /// SCR-88 tile.
  ///
  /// In vi, this message translates to:
  /// **'Đã bắt đầu'**
  String get sharing_started;

  /// Views delta.
  ///
  /// In vi, this message translates to:
  /// **'+{count} người xem mới tuần này'**
  String sharing_newViewersWeek(int count);

  /// Likes / started delta.
  ///
  /// In vi, this message translates to:
  /// **'+{count} tuần này'**
  String sharing_thisWeek(int count);

  /// Chart caption.
  ///
  /// In vi, this message translates to:
  /// **'Số người xem mỗi ngày'**
  String get sharing_viewsPerDay;

  /// Chart range.
  ///
  /// In vi, this message translates to:
  /// **'30 ngày qua'**
  String get sharing_last30Days;

  /// Chart semantics.
  ///
  /// In vi, this message translates to:
  /// **'Biểu đồ lượt xem 30 ngày qua, nhiều nhất {max} người một ngày'**
  String sharing_chartSemantics(int max);

  /// Like split.
  ///
  /// In vi, this message translates to:
  /// **'Bạn bè {count}'**
  String sharing_likesFriends(int count);

  /// Like split.
  ///
  /// In vi, this message translates to:
  /// **'Người khác {count}'**
  String sharing_likesOthers(int count);

  /// S20 likers list heading.
  ///
  /// In vi, this message translates to:
  /// **'Ai đã thích ảnh của bạn'**
  String get sharing_likersTitle;

  /// Empty likers list.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có lượt thích nào'**
  String get sharing_noLikers;

  /// S20 privacy note.
  ///
  /// In vi, this message translates to:
  /// **'Lượt xem được đếm, không liệt kê. Không ai biết bạn đã xem hành trình của họ.'**
  String get sharing_privacyNote;

  /// SCR-88 link off state.
  ///
  /// In vi, this message translates to:
  /// **'Liên kết đang tắt · tạm dừng đếm'**
  String get sharing_linkOffNote;

  /// SCR-28 title.
  ///
  /// In vi, this message translates to:
  /// **'Kể lại một hành trình đã qua'**
  String get sharing_retellTitle;

  /// SCR-28 intro.
  ///
  /// In vi, this message translates to:
  /// **'Đã đi rồi? Biến ảnh cũ thành một câu chuyện'**
  String get sharing_retellIntro;

  /// Opens the photo library (multi select).
  ///
  /// In vi, this message translates to:
  /// **'Chọn ảnh'**
  String get sharing_pickPhotos;

  /// Adds more photos.
  ///
  /// In vi, this message translates to:
  /// **'Thêm ảnh'**
  String get sharing_addPhotos;

  /// Number of picked photos.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{{count} ảnh}}'**
  String sharing_photosCount(int count);

  /// SCR-28 grid hint.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh tự xếp theo ngày. Chạm ngày để đổi.'**
  String get sharing_photosHint;

  /// SCR-28 field.
  ///
  /// In vi, this message translates to:
  /// **'Tên hành trình'**
  String get sharing_journeyName;

  /// SCR-28 style picker.
  ///
  /// In vi, this message translates to:
  /// **'Phong cách'**
  String get sharing_style;

  /// SCR-28 metric heading.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ số (không bắt buộc)'**
  String get sharing_metricOptional;

  /// SCR-28 field.
  ///
  /// In vi, this message translates to:
  /// **'Tên chỉ số'**
  String get sharing_metricName;

  /// SCR-28 field.
  ///
  /// In vi, this message translates to:
  /// **'Đơn vị'**
  String get sharing_metricUnit;

  /// Semantics of a photo date button.
  ///
  /// In vi, this message translates to:
  /// **'Đổi ngày ảnh, hiện là {date}'**
  String sharing_changeDate(String date);

  /// Removes a picked photo.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ ảnh'**
  String get sharing_removePhoto;

  /// Two photos on one date.
  ///
  /// In vi, this message translates to:
  /// **'Trùng ngày: ảnh sau thay ảnh trước'**
  String get sharing_sameDay;

  /// Date range of the picked photos and its length.
  ///
  /// In vi, this message translates to:
  /// **'{range} · {days}'**
  String sharing_rangeLine(String range, String days);

  /// SCR-28 primary.
  ///
  /// In vi, this message translates to:
  /// **'Lưu lên kệ'**
  String get sharing_saveToShelf;

  /// SCR-28 progress.
  ///
  /// In vi, this message translates to:
  /// **'Đang lưu {done}/{total} ảnh…'**
  String sharing_saving(int done, int total);

  /// SCR-28 validation.
  ///
  /// In vi, this message translates to:
  /// **'Đặt tên cho hành trình'**
  String get sharing_errorTitleEmpty;

  /// SCR-28 validation.
  ///
  /// In vi, this message translates to:
  /// **'Tối đa 366 ngày từ ảnh đầu đến ảnh cuối'**
  String get sharing_errorRange;

  /// SCR-28 validation.
  ///
  /// In vi, this message translates to:
  /// **'Ngày ảnh không thể ở tương lai'**
  String get sharing_errorFuture;

  /// SCR-28 validation.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ít nhất một ảnh'**
  String get sharing_errorNoPhotos;

  /// SCR-28 partial failure.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{{count} ảnh chưa lưu được}}'**
  String sharing_retellFailed(int count);

  /// Retry button.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get sharing_retry;

  /// Opens the journey anyway.
  ///
  /// In vi, this message translates to:
  /// **'Mở hành trình'**
  String get sharing_openJourney;
}

class _SharingL10nDelegate extends LocalizationsDelegate<SharingL10n> {
  const _SharingL10nDelegate();

  @override
  Future<SharingL10n> load(Locale locale) {
    return SynchronousFuture<SharingL10n>(lookupSharingL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_SharingL10nDelegate old) => false;
}

SharingL10n lookupSharingL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return SharingL10nEn();
    case 'vi':
      return SharingL10nVi();
  }

  throw FlutterError(
    'SharingL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
