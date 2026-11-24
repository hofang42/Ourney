import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'feedback_localizations_en.dart';
import 'feedback_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of FeedbackL10n
/// returned by `FeedbackL10n.of(context)`.
///
/// Applications need to include `FeedbackL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/feedback_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: FeedbackL10n.localizationsDelegates,
///   supportedLocales: FeedbackL10n.supportedLocales,
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
/// be consistent with the languages listed in the FeedbackL10n.supportedLocales
/// property.
abstract class FeedbackL10n {
  FeedbackL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static FeedbackL10n of(BuildContext context) {
    return Localizations.of<FeedbackL10n>(context, FeedbackL10n)!;
  }

  static const LocalizationsDelegate<FeedbackL10n> delegate =
      _FeedbackL10nDelegate();

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

  /// Title of the feature requests board screen.
  ///
  /// In vi, this message translates to:
  /// **'đề xuất.'**
  String get feedback_title;

  /// Title of the feature request detail screen.
  ///
  /// In vi, this message translates to:
  /// **'chi tiết.'**
  String get feedback_detailTitle;

  /// Tooltip of the header add button.
  ///
  /// In vi, this message translates to:
  /// **'Gửi đề xuất mới'**
  String get feedback_newAction;

  /// Tooltip of the detail overflow menu button.
  ///
  /// In vi, this message translates to:
  /// **'Thêm tùy chọn'**
  String get feedback_moreOptions;

  /// Board tab: most voted active ideas.
  ///
  /// In vi, this message translates to:
  /// **'Phổ biến'**
  String get feedback_tabPopular;

  /// Board tab: newest ideas.
  ///
  /// In vi, this message translates to:
  /// **'Mới'**
  String get feedback_tabNew;

  /// Board tab: planned and in-progress ideas.
  ///
  /// In vi, this message translates to:
  /// **'Đã lên kế hoạch'**
  String get feedback_tabPlanned;

  /// Board tab: shipped ideas.
  ///
  /// In vi, this message translates to:
  /// **'Đã ra mắt'**
  String get feedback_tabShipped;

  /// Filter chip showing all requests authored by the current user.
  ///
  /// In vi, this message translates to:
  /// **'Của tôi'**
  String get feedback_chipMine;

  /// Category filter: all categories.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get feedback_catAll;

  /// Category: camera and check-in.
  ///
  /// In vi, this message translates to:
  /// **'Máy ảnh & Check-in'**
  String get feedback_catCamera;

  /// Category: journeys.
  ///
  /// In vi, this message translates to:
  /// **'Hành trình'**
  String get feedback_catJourneys;

  /// Category: squads.
  ///
  /// In vi, this message translates to:
  /// **'Nhóm'**
  String get feedback_catSquad;

  /// Category: sharing.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ'**
  String get feedback_catSharing;

  /// Category: design and UI.
  ///
  /// In vi, this message translates to:
  /// **'Giao diện'**
  String get feedback_catDesign;

  /// Category: other.
  ///
  /// In vi, this message translates to:
  /// **'Khác'**
  String get feedback_catOther;

  /// Status tag: new.
  ///
  /// In vi, this message translates to:
  /// **'Mới'**
  String get feedback_statusNew;

  /// Status tag: under review.
  ///
  /// In vi, this message translates to:
  /// **'Đang xem xét'**
  String get feedback_statusUnderReview;

  /// Status tag: planned.
  ///
  /// In vi, this message translates to:
  /// **'Đã lên kế hoạch'**
  String get feedback_statusPlanned;

  /// Status tag: in progress.
  ///
  /// In vi, this message translates to:
  /// **'Đang làm'**
  String get feedback_statusInProgress;

  /// Status tag: shipped.
  ///
  /// In vi, this message translates to:
  /// **'Đã ra mắt'**
  String get feedback_statusShipped;

  /// Status tag: not planned / declined.
  ///
  /// In vi, this message translates to:
  /// **'Chưa phù hợp'**
  String get feedback_statusDeclined;

  /// Accessibility label for the search field.
  ///
  /// In vi, this message translates to:
  /// **'Tìm đề xuất'**
  String get feedback_searchLabel;

  /// Hint text inside the search field.
  ///
  /// In vi, this message translates to:
  /// **'Tìm ý tưởng hoặc tính năng…'**
  String get feedback_searchHint;

  /// Clear search button tooltip.
  ///
  /// In vi, this message translates to:
  /// **'Xóa tìm kiếm'**
  String get feedback_searchClear;

  /// Primary pinned button on the board screen.
  ///
  /// In vi, this message translates to:
  /// **'Gửi đề xuất mới'**
  String get feedback_newCta;

  /// Tag on a card indicating an official team response.
  ///
  /// In vi, this message translates to:
  /// **'Phản hồi Ourney'**
  String get feedback_officialReplyBadge;

  /// Eyebrow header of the official reply card on the detail screen.
  ///
  /// In vi, this message translates to:
  /// **'PHẢN HỒI TỪ OURNEY'**
  String get feedback_officialReplyEyebrow;

  /// Detail screen primary upvote button when not yet voted.
  ///
  /// In vi, this message translates to:
  /// **'Bình chọn · {count}'**
  String feedback_voteButton(int count);

  /// Detail screen upvote button when already voted.
  ///
  /// In vi, this message translates to:
  /// **'Đã bình chọn · {count}'**
  String feedback_votedButton(int count);

  /// Screen reader label for the vote pill on a request card.
  ///
  /// In vi, this message translates to:
  /// **'{title}, {count} lượt bình chọn, {state}'**
  String feedback_voteSemantics(String title, int count, String state);

  /// Vote state spoken by screen readers when voted.
  ///
  /// In vi, this message translates to:
  /// **'đã bình chọn'**
  String get feedback_voteStateVoted;

  /// Vote state spoken by screen readers when not voted.
  ///
  /// In vi, this message translates to:
  /// **'chưa bình chọn'**
  String get feedback_voteStateNotVoted;

  /// Read-only bottom banner on a shipped request detail screen.
  ///
  /// In vi, this message translates to:
  /// **'Đã ra mắt · {count} lượt bình chọn'**
  String feedback_shippedVotes(int count);

  /// Shown next to the creation date when the author edited the request.
  ///
  /// In vi, this message translates to:
  /// **'Đã chỉnh sửa'**
  String get feedback_editedBadge;

  /// Helper note shown to the author while the request status is still new.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có thể sửa hoặc xóa đề xuất này trước khi Ourney bắt đầu xem xét.'**
  String get feedback_authorEditHint;

  /// Overflow menu item to edit own request.
  ///
  /// In vi, this message translates to:
  /// **'Sửa đề xuất'**
  String get feedback_editAction;

  /// Overflow menu item to delete own request.
  ///
  /// In vi, this message translates to:
  /// **'Xóa đề xuất'**
  String get feedback_deleteAction;

  /// Confirmation sheet title when deleting a request.
  ///
  /// In vi, this message translates to:
  /// **'Xóa đề xuất này?'**
  String get feedback_deleteTitle;

  /// Confirmation sheet body when deleting a request.
  ///
  /// In vi, this message translates to:
  /// **'Đề xuất của bạn sẽ bị xóa vĩnh viễn khỏi bảng cộng đồng.'**
  String get feedback_deleteBody;

  /// Confirm button on the delete sheet.
  ///
  /// In vi, this message translates to:
  /// **'Xóa đề xuất'**
  String get feedback_deleteConfirm;

  /// Toast after deleting own request.
  ///
  /// In vi, this message translates to:
  /// **'Đã xóa đề xuất.'**
  String get feedback_deletedToast;

  /// Title of the create request bottom sheet.
  ///
  /// In vi, this message translates to:
  /// **'gửi đề xuất.'**
  String get feedback_createSheetTitle;

  /// Title of the edit request bottom sheet.
  ///
  /// In vi, this message translates to:
  /// **'sửa đề xuất.'**
  String get feedback_editSheetTitle;

  /// Subtitle of the create/edit sheet.
  ///
  /// In vi, this message translates to:
  /// **'Đề xuất được hiển thị công khai để mọi người cùng bình chọn.'**
  String get feedback_createSheetSub;

  /// Label of the title input in the create/edit sheet.
  ///
  /// In vi, this message translates to:
  /// **'Tên đề xuất'**
  String get feedback_fieldTitleLabel;

  /// Placeholder of the title input.
  ///
  /// In vi, this message translates to:
  /// **'Ví dụ: Widget chuỗi ngày ngoài màn hình khóa'**
  String get feedback_fieldTitleHint;

  /// Label above the category chips.
  ///
  /// In vi, this message translates to:
  /// **'Danh mục'**
  String get feedback_fieldCategoryLabel;

  /// Label of the description textarea.
  ///
  /// In vi, this message translates to:
  /// **'Mô tả chi tiết'**
  String get feedback_fieldBodyLabel;

  /// Placeholder of the description textarea.
  ///
  /// In vi, this message translates to:
  /// **'Kể ngắn gọn tính năng này giúp thói quen hằng ngày của bạn dễ hơn thế nào…'**
  String get feedback_fieldBodyHint;

  /// Heading of the live duplicate suggestion card.
  ///
  /// In vi, this message translates to:
  /// **'Có thể đã có người đề xuất:'**
  String get feedback_similarHeading;

  /// Quick upvote chip on a duplicate suggestion row.
  ///
  /// In vi, this message translates to:
  /// **'+1 ({count})'**
  String feedback_similarVoteChip(int count);

  /// Helper link to the support contact screen for private bug reports.
  ///
  /// In vi, this message translates to:
  /// **'Báo lỗi riêng tư kèm ảnh chụp màn hình? Liên hệ hỗ trợ'**
  String get feedback_bugEmailLink;

  /// Primary submit button in the create sheet.
  ///
  /// In vi, this message translates to:
  /// **'Gửi đề xuất'**
  String get feedback_submitAction;

  /// Primary save button in the edit sheet.
  ///
  /// In vi, this message translates to:
  /// **'Lưu thay đổi'**
  String get feedback_saveChanges;

  /// Toast shown after creating a feature request.
  ///
  /// In vi, this message translates to:
  /// **'Đã đăng đề xuất và tính 1 lượt bình chọn của bạn!'**
  String get feedback_createdToast;

  /// Toast shown after editing a feature request.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu thay đổi đề xuất.'**
  String get feedback_updatedToast;

  /// Banner shown on a request that was merged into a canonical duplicate.
  ///
  /// In vi, this message translates to:
  /// **'Đề xuất này đã được gộp vào một ý tưởng tương tự cùng toàn bộ lượt bình chọn.'**
  String get feedback_mergedBanner;

  /// Button on the merged duplicate banner.
  ///
  /// In vi, this message translates to:
  /// **'Xem đề xuất gốc'**
  String get feedback_mergedOpenTarget;

  /// Overflow menu item to report a feature request.
  ///
  /// In vi, this message translates to:
  /// **'Báo cáo đề xuất'**
  String get feedback_reportAction;

  /// Heading of the report sheet for a feature request.
  ///
  /// In vi, this message translates to:
  /// **'Báo cáo đề xuất'**
  String get feedback_reportTitle;

  /// Toast shown after reporting a feature request.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi báo cáo. Đề xuất này đã được ẩn khỏi máy bạn.'**
  String get feedback_reportedToast;

  /// Overflow menu item to block the request author.
  ///
  /// In vi, this message translates to:
  /// **'Chặn người đăng'**
  String get feedback_blockAuthorAction;

  /// Fallback author name when the author account was deleted.
  ///
  /// In vi, this message translates to:
  /// **'Thành viên Ourney'**
  String get feedback_anonymousAuthor;

  /// Empty state title for Popular/New tab.
  ///
  /// In vi, this message translates to:
  /// **'chưa có đề xuất nào.'**
  String get feedback_emptyPopularTitle;

  /// Empty state body for Popular/New tab.
  ///
  /// In vi, this message translates to:
  /// **'Bạn muốn Ourney có thêm tính năng gì tiếp theo? Hãy là người đầu tiên chia sẻ nhé.'**
  String get feedback_emptyPopularBody;

  /// Empty state action for Popular/New tab.
  ///
  /// In vi, this message translates to:
  /// **'Gửi đề xuất đầu tiên'**
  String get feedback_emptyPopularCta;

  /// Empty state title for Planned tab.
  ///
  /// In vi, this message translates to:
  /// **'chưa có mục nào trong kế hoạch.'**
  String get feedback_emptyPlannedTitle;

  /// Empty state body for Planned tab.
  ///
  /// In vi, this message translates to:
  /// **'Những ý tưởng được bình chọn nhiều sẽ sớm được đưa vào lộ trình.'**
  String get feedback_emptyPlannedBody;

  /// Empty state title for Shipped tab.
  ///
  /// In vi, this message translates to:
  /// **'sắp có tính năng mới.'**
  String get feedback_emptyShippedTitle;

  /// Empty state body for Shipped tab.
  ///
  /// In vi, this message translates to:
  /// **'Khi một đề xuất hoàn thành, bạn sẽ thấy thông báo tại đây.'**
  String get feedback_emptyShippedBody;

  /// Empty state title when My requests chip is active.
  ///
  /// In vi, this message translates to:
  /// **'bạn chưa gửi đề xuất nào.'**
  String get feedback_emptyMineTitle;

  /// Empty state body when My requests chip is active.
  ///
  /// In vi, this message translates to:
  /// **'Những ý tưởng bạn gửi sẽ xuất hiện tại đây để bạn theo dõi tiến độ.'**
  String get feedback_emptyMineBody;

  /// Empty state title when search has no matches.
  ///
  /// In vi, this message translates to:
  /// **'không tìm thấy đề xuất trùng khớp.'**
  String get feedback_emptySearchTitle;

  /// Empty state body when search has no matches.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có thể gửi ý tưởng này thành một đề xuất mới cho cộng đồng.'**
  String get feedback_emptySearchBody;

  /// Empty state CTA pre-filling the create sheet with the search query.
  ///
  /// In vi, this message translates to:
  /// **'Gửi đề xuất này'**
  String get feedback_emptySearchCta;

  /// Pagination button at the end of a page.
  ///
  /// In vi, this message translates to:
  /// **'Xem thêm đề xuất'**
  String get feedback_loadMore;

  /// Footer caption when all items have been loaded.
  ///
  /// In vi, this message translates to:
  /// **'Đã hiển thị tất cả đề xuất'**
  String get feedback_endOfList;

  /// Offline banner strip above cached requests.
  ///
  /// In vi, this message translates to:
  /// **'Đang xem bản đã lưu.'**
  String get feedback_offlineStrip;

  /// Friendly state title when backend migration 0024 is not deployed yet.
  ///
  /// In vi, this message translates to:
  /// **'bảng đề xuất sắp mở.'**
  String get feedback_comingSoonTitle;

  /// Friendly state body when backend migration 0024 is not deployed yet.
  ///
  /// In vi, this message translates to:
  /// **'Máy chủ đang được cập nhật tính năng bình chọn đề xuất. Bạn quay lại sau ít phút nhé!'**
  String get feedback_comingSoonBody;

  /// Validation error when title is too short or too long.
  ///
  /// In vi, this message translates to:
  /// **'Tên đề xuất cần từ 6 đến 80 ký tự.'**
  String get feedback_errorTitleLength;

  /// Validation error when body is too short or too long.
  ///
  /// In vi, this message translates to:
  /// **'Mô tả cần từ 10 đến 1000 ký tự.'**
  String get feedback_errorBodyLength;

  /// Validation error when profanity filter rejects the submission.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung chứa từ ngữ không phù hợp với quy tắc cộng đồng của Ourney.'**
  String get feedback_errorContentPolicy;

  /// Validation error when a URL is included in title or body.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng không chèn đường dẫn web vào đề xuất.'**
  String get feedback_errorLinksNotAllowed;

  /// Error when daily creation limit (5/24h) is reached.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã gửi tối đa 5 đề xuất trong 24 giờ qua. Hãy bình chọn các ý tưởng sẵn có nhé!'**
  String get feedback_errorRateLimited;

  /// Error when vote or edit rate limit is reached.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đang thao tác quá nhanh. Vui lòng thử lại sau ít phút nhé.'**
  String get feedback_errorRateLimitedAction;

  /// Error in create sheet when offline; draft is preserved.
  ///
  /// In vi, this message translates to:
  /// **'Không có mạng. Bản nháp của bạn vẫn được giữ nguyên.'**
  String get feedback_errorOfflineDraftSaved;

  /// Toast when voting on a request that was just closed or shipped.
  ///
  /// In vi, this message translates to:
  /// **'Đề xuất này đã khóa bình chọn.'**
  String get feedback_errorVoteLocked;

  /// Error on detail screen when request is not found.
  ///
  /// In vi, this message translates to:
  /// **'Đề xuất này không còn tồn tại hoặc đã bị ẩn.'**
  String get feedback_errorNotFound;
}

class _FeedbackL10nDelegate extends LocalizationsDelegate<FeedbackL10n> {
  const _FeedbackL10nDelegate();

  @override
  Future<FeedbackL10n> load(Locale locale) {
    return SynchronousFuture<FeedbackL10n>(lookupFeedbackL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_FeedbackL10nDelegate old) => false;
}

FeedbackL10n lookupFeedbackL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return FeedbackL10nEn();
    case 'vi':
      return FeedbackL10nVi();
  }

  throw FlutterError(
    'FeedbackL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
