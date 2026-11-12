import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'social_localizations_en.dart';
import 'social_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of SocialL10n
/// returned by `SocialL10n.of(context)`.
///
/// Applications need to include `SocialL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/social_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: SocialL10n.localizationsDelegates,
///   supportedLocales: SocialL10n.supportedLocales,
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
/// be consistent with the languages listed in the SocialL10n.supportedLocales
/// property.
abstract class SocialL10n {
  SocialL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static SocialL10n of(BuildContext context) {
    return Localizations.of<SocialL10n>(context, SocialL10n)!;
  }

  static const LocalizationsDelegate<SocialL10n> delegate =
      _SocialL10nDelegate();

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

  /// Title of the friends screen (SCR-80) and the friends list heading.
  ///
  /// In vi, this message translates to:
  /// **'Bạn bè'**
  String get social_friendsTitle;

  /// Friends screen subtitle: friend count, visible only to the account owner (S4).
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{{count} người bạn}} · chỉ bạn thấy'**
  String social_friendsSubtitle(int count);

  /// Header action on the friends screen opening Add friends (SCR-81).
  ///
  /// In vi, this message translates to:
  /// **'Thêm'**
  String get social_add;

  /// Section heading for pending friend requests.
  ///
  /// In vi, this message translates to:
  /// **'Lời mời'**
  String get social_requests;

  /// Shown under Requests when there are none.
  ///
  /// In vi, this message translates to:
  /// **'Không có lời mời mới'**
  String get social_noRequests;

  /// Accept a friend request.
  ///
  /// In vi, this message translates to:
  /// **'Chấp nhận'**
  String get social_accept;

  /// Decline a friend request or a share consent request.
  ///
  /// In vi, this message translates to:
  /// **'Từ chối'**
  String get social_decline;

  /// Label on an outgoing friend request / search result already requested.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi'**
  String get social_requested;

  /// Cancel an outgoing friend request.
  ///
  /// In vi, this message translates to:
  /// **'Hủy'**
  String get social_cancelRequest;

  /// Filter field on the friends list (more than 10 friends).
  ///
  /// In vi, this message translates to:
  /// **'Tìm bạn'**
  String get social_searchFriends;

  /// Empty friends screen title.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ hành trình với những người đã ở đó'**
  String get social_emptyFriendsTitle;

  /// Title of SCR-81 and the empty-state call to action.
  ///
  /// In vi, this message translates to:
  /// **'Thêm bạn'**
  String get social_addFriends;

  /// Friend sheet action opening the conversation.
  ///
  /// In vi, this message translates to:
  /// **'Nhắn tin'**
  String get social_message;

  /// Friend sheet action: unfriend.
  ///
  /// In vi, this message translates to:
  /// **'Xóa bạn'**
  String get social_removeFriend;

  /// Remove friend confirmation title.
  ///
  /// In vi, this message translates to:
  /// **'Xóa {name} khỏi bạn bè?'**
  String social_removeFriendTitle(String name);

  /// Remove friend confirmation message (SCR-80).
  ///
  /// In vi, this message translates to:
  /// **'Hai bạn sẽ không còn thấy hành trình đã chia sẻ cho nhau.'**
  String get social_removeFriendBody;

  /// Snack bar after removing a friend.
  ///
  /// In vi, this message translates to:
  /// **'Đã xóa {name} khỏi bạn bè'**
  String social_removed(String name);

  /// Block a person.
  ///
  /// In vi, this message translates to:
  /// **'Chặn'**
  String get social_block;

  /// Report a person or message.
  ///
  /// In vi, this message translates to:
  /// **'Báo cáo'**
  String get social_report;

  /// Sub-line of a request that came from a public journey (S27).
  ///
  /// In vi, this message translates to:
  /// **'Đã xem {title}'**
  String social_sawJourney(String title);

  /// SCR-81 block: share my invite link.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ liên kết mời'**
  String get social_inviteLinkTitle;

  /// Shown under the invite link block before the link exists.
  ///
  /// In vi, this message translates to:
  /// **'Ai mở liên kết sẽ thành bạn của bạn'**
  String get social_inviteLinkHint;

  /// Open the system share sheet with the invite link.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ'**
  String get social_share;

  /// Copy a link or a message.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép'**
  String get social_copy;

  /// Snack bar after copying the invite link.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép liên kết'**
  String get social_linkCopied;

  /// Snack bar after copying a message.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép'**
  String get social_copied;

  /// Text shared with the invite link.
  ///
  /// In vi, this message translates to:
  /// **'Kết bạn với mình trên Ourney nhé: {link}'**
  String social_inviteShareText(String link);

  /// SCR-81 block: my QR code.
  ///
  /// In vi, this message translates to:
  /// **'Mã QR của tôi'**
  String get social_qrTitle;

  /// QR block hint before the invite link exists.
  ///
  /// In vi, this message translates to:
  /// **'Chạm để hiện mã'**
  String get social_qrShow;

  /// QR block hint: tap to enlarge.
  ///
  /// In vi, this message translates to:
  /// **'Chạm để phóng to'**
  String get social_qrEnlarge;

  /// Screen reader label of the invite QR code.
  ///
  /// In vi, this message translates to:
  /// **'Mã QR của liên kết mời'**
  String get social_qrSemantics;

  /// SCR-81 username search heading.
  ///
  /// In vi, this message translates to:
  /// **'Tìm bằng tên người dùng'**
  String get social_findByUsername;

  /// Placeholder of the username field (do not translate).
  ///
  /// In vi, this message translates to:
  /// **'@username'**
  String get social_usernameHint;

  /// Search button of the username field.
  ///
  /// In vi, this message translates to:
  /// **'Tìm'**
  String get social_search;

  /// Hint under the username field (S3: exact match only).
  ///
  /// In vi, this message translates to:
  /// **'Chỉ hiện khi khớp đúng tên người dùng'**
  String get social_exactMatchHint;

  /// Username search: no exact match (also shown for blocked users).
  ///
  /// In vi, this message translates to:
  /// **'Không có ai với tên người dùng này'**
  String get social_noOne;

  /// Send a friend request from a search result.
  ///
  /// In vi, this message translates to:
  /// **'Thêm bạn'**
  String get social_addFriend;

  /// Search result state: already friends.
  ///
  /// In vi, this message translates to:
  /// **'Bạn bè'**
  String get social_alreadyFriends;

  /// Search result state: the caller's own username.
  ///
  /// In vi, this message translates to:
  /// **'Đây là bạn'**
  String get social_thatsYou;

  /// Error rate_limited.
  ///
  /// In vi, this message translates to:
  /// **'Bạn thao tác hơi nhanh. Thử lại sau nhé.'**
  String get social_rateLimited;

  /// Error forbidden.
  ///
  /// In vi, this message translates to:
  /// **'Bạn không thể làm việc này'**
  String get social_errorForbidden;

  /// Error not_found.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy'**
  String get social_errorNotFound;

  /// Error blocked (also invite link from a blocked person).
  ///
  /// In vi, this message translates to:
  /// **'Không thể kết bạn với người này'**
  String get social_errorBlocked;

  /// Title of the invite deep link screen (/f/:token).
  ///
  /// In vi, this message translates to:
  /// **'Lời mời kết bạn'**
  String get social_inviteTitle;

  /// Invite deep link: in progress.
  ///
  /// In vi, this message translates to:
  /// **'Đang kết bạn…'**
  String get social_inviteAccepting;

  /// Invite deep link: success.
  ///
  /// In vi, this message translates to:
  /// **'Bạn và {name} đã là bạn bè'**
  String social_inviteDone(String name);

  /// Invite deep link: not_found (unknown or rotated token).
  ///
  /// In vi, this message translates to:
  /// **'Liên kết mời này đã hết hạn hoặc không tồn tại'**
  String get social_inviteNotFound;

  /// Invite deep link: invalid (the caller's own token).
  ///
  /// In vi, this message translates to:
  /// **'Đây là liên kết mời của chính bạn'**
  String get social_inviteOwn;

  /// Invite deep link: hint under the own-link message.
  ///
  /// In vi, this message translates to:
  /// **'Gửi liên kết này cho bạn bè để kết bạn.'**
  String get social_inviteOwnHint;

  /// Invite deep link: open the friends list.
  ///
  /// In vi, this message translates to:
  /// **'Xem bạn bè'**
  String get social_seeFriends;

  /// Title of the inbox (SCR-85) and the inbox button tooltip.
  ///
  /// In vi, this message translates to:
  /// **'Hộp thư'**
  String get social_inboxTitle;

  /// Inbox button tooltip when the red dot is shown.
  ///
  /// In vi, this message translates to:
  /// **'Hộp thư, có mục mới'**
  String get social_inboxNew;

  /// Inbox filter chip: all.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get social_filterAll;

  /// Inbox filter chip: conversations.
  ///
  /// In vi, this message translates to:
  /// **'Trả lời'**
  String get social_filterReplies;

  /// Inbox filter chip: friend requests, share requests and new shares.
  ///
  /// In vi, this message translates to:
  /// **'Lời mời'**
  String get social_filterInvites;

  /// Inbox section heading.
  ///
  /// In vi, this message translates to:
  /// **'Lời mời kết bạn'**
  String get social_sectionFriendRequests;

  /// Inbox row: incoming friend request.
  ///
  /// In vi, this message translates to:
  /// **'Lời mời kết bạn từ {name}'**
  String social_friendRequestFrom(String name);

  /// Inbox section heading: group share consent requests (S29).
  ///
  /// In vi, this message translates to:
  /// **'Yêu cầu chia sẻ'**
  String get social_sectionConsents;

  /// Inbox row: a squad member asks to share a group journey.
  ///
  /// In vi, this message translates to:
  /// **'{name} muốn chia sẻ {title} ra ngoài nhóm'**
  String social_consentRequest(String name, String title);

  /// Agree to a share consent request.
  ///
  /// In vi, this message translates to:
  /// **'Đồng ý'**
  String get social_agree;

  /// Inbox section heading: conversations.
  ///
  /// In vi, this message translates to:
  /// **'Trò chuyện'**
  String get social_sectionConversations;

  /// Last message preview of a photo message.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi một ảnh'**
  String get social_photoMessage;

  /// Inbox section heading: journeys shared with me.
  ///
  /// In vi, this message translates to:
  /// **'Được chia sẻ với bạn'**
  String get social_sectionNewShares;

  /// Inbox row: unseen journeys shared with me (opens the Hub).
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{{count} hành trình mới được chia sẻ với bạn}}'**
  String social_newShares(int count);

  /// Open the shared journeys in the Hub.
  ///
  /// In vi, this message translates to:
  /// **'Xem'**
  String get social_view;

  /// Inbox section: friend requests from viewers of public journeys (S27, no red dot).
  ///
  /// In vi, this message translates to:
  /// **'Từ hành trình công khai của bạn'**
  String get social_sectionPublic;

  /// Collapsed row of public-journey friend requests.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{{count} lời mời từ người đã xem {title}}}'**
  String social_publicSummary(int count, String title);

  /// Used in social_publicSummary when the journey title is unknown.
  ///
  /// In vi, this message translates to:
  /// **'hành trình công khai'**
  String get social_publicJourneyFallback;

  /// Decline every public-journey request of one journey.
  ///
  /// In vi, this message translates to:
  /// **'Từ chối tất cả'**
  String get social_declineAll;

  /// Empty inbox.
  ///
  /// In vi, this message translates to:
  /// **'Câu trả lời và lời mời từ bạn bè sẽ ở đây'**
  String get social_inboxEmpty;

  /// Unread badge label for screen readers.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{{count} tin chưa đọc}}'**
  String social_unread(int count);

  /// Chat composer placeholder.
  ///
  /// In vi, this message translates to:
  /// **'Tin nhắn'**
  String get social_messageHint;

  /// Send a chat message.
  ///
  /// In vi, this message translates to:
  /// **'Gửi'**
  String get social_send;

  /// Chat composer: take a photo.
  ///
  /// In vi, this message translates to:
  /// **'Chụp ảnh'**
  String get social_camera;

  /// Chat composer: pick from the photo library.
  ///
  /// In vi, this message translates to:
  /// **'Thư viện ảnh'**
  String get social_library;

  /// Overflow menu tooltip.
  ///
  /// In vi, this message translates to:
  /// **'Thêm tùy chọn'**
  String get social_more;

  /// Chat overflow menu: delete conversation for me (S37).
  ///
  /// In vi, this message translates to:
  /// **'Xóa cuộc trò chuyện'**
  String get social_deleteConversation;

  /// Delete conversation confirmation.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ xóa phía bạn. {name} vẫn giữ lịch sử trò chuyện.'**
  String social_deleteConversationBody(String name);

  /// Confirm a delete.
  ///
  /// In vi, this message translates to:
  /// **'Xóa'**
  String get social_delete;

  /// Message long-press action: hide it for me.
  ///
  /// In vi, this message translates to:
  /// **'Xóa phía tôi'**
  String get social_deleteForMe;

  /// Chat banner when the conversation is read-only.
  ///
  /// In vi, this message translates to:
  /// **'Bạn không thể trả lời cuộc trò chuyện này'**
  String get social_readOnly;

  /// Context above a reply: the check-in photo being replied to.
  ///
  /// In vi, this message translates to:
  /// **'Trả lời ảnh này'**
  String get social_replyingTo;

  /// Empty conversation.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có tin nhắn'**
  String get social_chatEmpty;

  /// Chat opened for an unknown or deleted conversation.
  ///
  /// In vi, this message translates to:
  /// **'Cuộc trò chuyện này không còn'**
  String get social_conversationGone;

  /// Picking or compressing a chat photo failed.
  ///
  /// In vi, this message translates to:
  /// **'Không dùng được ảnh này'**
  String get social_photoFailed;

  /// Screen reader label of a photo message.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh trong tin nhắn'**
  String get social_photoSemantics;

  /// Status under my last message.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi'**
  String get social_sent;

  /// Profile row opening the friends list (count visible only to me).
  ///
  /// In vi, this message translates to:
  /// **'Bạn bè · {count}'**
  String social_profileFriends(int count);

  /// Profile row sub-line: pending incoming requests.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{{count} lời mời đang chờ}}'**
  String social_profileRequests(int count);
}

class _SocialL10nDelegate extends LocalizationsDelegate<SocialL10n> {
  const _SocialL10nDelegate();

  @override
  Future<SocialL10n> load(Locale locale) {
    return SynchronousFuture<SocialL10n>(lookupSocialL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_SocialL10nDelegate old) => false;
}

SocialL10n lookupSocialL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return SocialL10nEn();
    case 'vi':
      return SocialL10nVi();
  }

  throw FlutterError(
    'SocialL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
