import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'journeys_localizations_en.dart';
import 'journeys_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of JourneysL10n
/// returned by `JourneysL10n.of(context)`.
///
/// Applications need to include `JourneysL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/journeys_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: JourneysL10n.localizationsDelegates,
///   supportedLocales: JourneysL10n.supportedLocales,
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
/// be consistent with the languages listed in the JourneysL10n.supportedLocales
/// property.
abstract class JourneysL10n {
  JourneysL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static JourneysL10n of(BuildContext context) {
    return Localizations.of<JourneysL10n>(context, JourneysL10n)!;
  }

  static const LocalizationsDelegate<JourneysL10n> delegate =
      _JourneysL10nDelegate();

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

  /// Title of the journeys feature's main screen.
  ///
  /// In vi, this message translates to:
  /// **'Hành trình'**
  String get journeys_title;

  /// Hub segment: running journeys.
  ///
  /// In vi, this message translates to:
  /// **'Đang chạy'**
  String get journeys_activeSection;

  /// Hub segment: ended and archived journeys (the shelf).
  ///
  /// In vi, this message translates to:
  /// **'Trên kệ'**
  String get journeys_finishedSection;

  /// No description provided for @journeys_emptyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có hành trình nào'**
  String get journeys_emptyTitle;

  /// No description provided for @journeys_emptyMessage.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu hành trình đầu tiên: mỗi ngày một tấm ảnh.'**
  String get journeys_emptyMessage;

  /// FAB / button that starts the create flow.
  ///
  /// In vi, this message translates to:
  /// **'Hành trình mới'**
  String get journeys_newJourney;

  /// Day N of M (FR-B5).
  ///
  /// In vi, this message translates to:
  /// **'Ngày {day}/{total}'**
  String journeys_dayOf(int day, int total);

  /// Day N of an open-ended journey.
  ///
  /// In vi, this message translates to:
  /// **'Ngày {day}'**
  String journeys_dayOpen(int day);

  /// No description provided for @journeys_checkedToday.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay đã check-in'**
  String get journeys_checkedToday;

  /// No description provided for @journeys_notCheckedToday.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay chưa check-in'**
  String get journeys_notCheckedToday;

  /// No description provided for @journeys_statusEnded.
  ///
  /// In vi, this message translates to:
  /// **'Đã kết thúc'**
  String get journeys_statusEnded;

  /// No description provided for @journeys_statusArchived.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu trữ'**
  String get journeys_statusArchived;

  /// No description provided for @journeys_kindSolo.
  ///
  /// In vi, this message translates to:
  /// **'Một mình'**
  String get journeys_kindSolo;

  /// No description provided for @journeys_kindGroup.
  ///
  /// In vi, this message translates to:
  /// **'Nhóm'**
  String get journeys_kindGroup;

  /// No description provided for @journeys_loadError.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được hành trình.'**
  String get journeys_loadError;

  /// Title of the template picker.
  ///
  /// In vi, this message translates to:
  /// **'Chọn kiểu hành trình'**
  String get journeys_pickTemplateTitle;

  /// Suggested duration on a template card.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{{count} ngày}}'**
  String journeys_templateDays(int count);

  /// No description provided for @journeys_templateCustomHint.
  ///
  /// In vi, this message translates to:
  /// **'Tự đặt mọi thứ'**
  String get journeys_templateCustomHint;

  /// No description provided for @journeys_templateCoupleTitle.
  ///
  /// In vi, this message translates to:
  /// **'Nghi thức cặp đôi'**
  String get journeys_templateCoupleTitle;

  /// No description provided for @journeys_templateCoupleHint.
  ///
  /// In vi, this message translates to:
  /// **'Hai người cùng lưu khoảnh khắc mỗi ngày'**
  String get journeys_templateCoupleHint;

  /// No description provided for @journeys_personaPreviewLabel.
  ///
  /// In vi, this message translates to:
  /// **'Xem trước giao diện'**
  String get journeys_personaPreviewLabel;

  /// No description provided for @journeys_continueTemplateButton.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục với kiểu này'**
  String get journeys_continueTemplateButton;

  /// No description provided for @journeys_createTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tạo hành trình'**
  String get journeys_createTitle;

  /// No description provided for @journeys_fieldTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tên hành trình'**
  String get journeys_fieldTitle;

  /// No description provided for @journeys_fieldEmoji.
  ///
  /// In vi, this message translates to:
  /// **'Biểu tượng'**
  String get journeys_fieldEmoji;

  /// No description provided for @journeys_emojiSemantics.
  ///
  /// In vi, this message translates to:
  /// **'Biểu tượng {emoji}'**
  String journeys_emojiSemantics(String emoji);

  /// No description provided for @journeys_fieldKind.
  ///
  /// In vi, this message translates to:
  /// **'Một mình hay cùng nhóm?'**
  String get journeys_fieldKind;

  /// No description provided for @journeys_groupNeedsServer.
  ///
  /// In vi, this message translates to:
  /// **'Hành trình nhóm cần máy chủ. Bản này đang chạy chỉ trên máy.'**
  String get journeys_groupNeedsServer;

  /// No description provided for @journeys_fieldDuration.
  ///
  /// In vi, this message translates to:
  /// **'Thời lượng'**
  String get journeys_fieldDuration;

  /// No description provided for @journeys_durationCustom.
  ///
  /// In vi, this message translates to:
  /// **'Số ngày'**
  String get journeys_durationCustom;

  /// No description provided for @journeys_openEnded.
  ///
  /// In vi, this message translates to:
  /// **'Không giới hạn'**
  String get journeys_openEnded;

  /// No description provided for @journeys_fieldMetric.
  ///
  /// In vi, this message translates to:
  /// **'Theo dõi một con số'**
  String get journeys_fieldMetric;

  /// No description provided for @journeys_fieldMetricHint.
  ///
  /// In vi, this message translates to:
  /// **'Ví dụ: cân nặng, số phút học'**
  String get journeys_fieldMetricHint;

  /// No description provided for @journeys_metricName.
  ///
  /// In vi, this message translates to:
  /// **'Tên chỉ số'**
  String get journeys_metricName;

  /// No description provided for @journeys_metricUnit.
  ///
  /// In vi, this message translates to:
  /// **'Đơn vị'**
  String get journeys_metricUnit;

  /// No description provided for @journeys_hideMetric.
  ///
  /// In vi, this message translates to:
  /// **'Ẩn con số với người khác'**
  String get journeys_hideMetric;

  /// No description provided for @journeys_hideExtras.
  ///
  /// In vi, this message translates to:
  /// **'Ẩn tâm trạng, số phút và chi tiết với người khác'**
  String get journeys_hideExtras;

  /// No description provided for @journeys_pin.
  ///
  /// In vi, this message translates to:
  /// **'Ghim lên đầu'**
  String get journeys_pin;

  /// No description provided for @journeys_unpin.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ ghim'**
  String get journeys_unpin;

  /// No description provided for @journeys_blurOnShare.
  ///
  /// In vi, this message translates to:
  /// **'Làm mờ ảnh khi chia sẻ ra ngoài'**
  String get journeys_blurOnShare;

  /// No description provided for @journeys_fieldVisibility.
  ///
  /// In vi, this message translates to:
  /// **'Ai xem được?'**
  String get journeys_fieldVisibility;

  /// No description provided for @journeys_visibilityPrivate.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ mình tôi'**
  String get journeys_visibilityPrivate;

  /// No description provided for @journeys_visibilityLink.
  ///
  /// In vi, this message translates to:
  /// **'Ai có link'**
  String get journeys_visibilityLink;

  /// No description provided for @journeys_visibilityGroup.
  ///
  /// In vi, this message translates to:
  /// **'Thành viên trong nhóm'**
  String get journeys_visibilityGroup;

  /// No description provided for @journeys_linkNeedsServer.
  ///
  /// In vi, this message translates to:
  /// **'Link chia sẻ cần máy chủ.'**
  String get journeys_linkNeedsServer;

  /// No description provided for @journeys_fieldTimezone.
  ///
  /// In vi, this message translates to:
  /// **'Múi giờ'**
  String get journeys_fieldTimezone;

  /// No description provided for @journeys_createButton.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu hành trình'**
  String get journeys_createButton;

  /// No description provided for @journeys_errorTitleEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Đặt tên cho hành trình nhé.'**
  String get journeys_errorTitleEmpty;

  /// No description provided for @journeys_errorTitleTooLong.
  ///
  /// In vi, this message translates to:
  /// **'Tên dài tối đa {max} ký tự.'**
  String journeys_errorTitleTooLong(int max);

  /// No description provided for @journeys_errorDuration.
  ///
  /// In vi, this message translates to:
  /// **'Thời lượng từ {min} đến {max} ngày.'**
  String journeys_errorDuration(int min, int max);

  /// No description provided for @journeys_errorMetricName.
  ///
  /// In vi, this message translates to:
  /// **'Nhập tên chỉ số.'**
  String get journeys_errorMetricName;

  /// No description provided for @journeys_errorInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu chưa hợp lệ. Kiểm tra lại rồi thử lại nhé.'**
  String get journeys_errorInvalid;

  /// No description provided for @journeys_errorLimit.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có quá nhiều hành trình đang chạy. Kết thúc bớt một hành trình rồi thử lại nhé.'**
  String get journeys_errorLimit;

  /// No description provided for @journeys_errorNotAlone.
  ///
  /// In vi, this message translates to:
  /// **'Nhóm vẫn còn thành viên khác nên chưa xóa được. Bạn có thể kết thúc hành trình.'**
  String get journeys_errorNotAlone;

  /// No description provided for @journeys_errorForbidden.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ chủ hành trình làm được việc này.'**
  String get journeys_errorForbidden;

  /// No description provided for @journeys_errorEnded.
  ///
  /// In vi, this message translates to:
  /// **'Hành trình này đã kết thúc.'**
  String get journeys_errorEnded;

  /// No description provided for @journeys_errorSyncPending.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh vẫn đang tải lên, thử lại sau ít phút.'**
  String get journeys_errorSyncPending;

  /// No description provided for @journeys_errorNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy hành trình.'**
  String get journeys_errorNotFound;

  /// No description provided for @journeys_statCurrent.
  ///
  /// In vi, this message translates to:
  /// **'Chuỗi hiện tại'**
  String get journeys_statCurrent;

  /// No description provided for @journeys_statBest.
  ///
  /// In vi, this message translates to:
  /// **'Dài nhất'**
  String get journeys_statBest;

  /// No description provided for @journeys_statComplete.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn thành'**
  String get journeys_statComplete;

  /// No description provided for @journeys_statDay.
  ///
  /// In vi, this message translates to:
  /// **'Tiến độ'**
  String get journeys_statDay;

  /// No description provided for @journeys_percent.
  ///
  /// In vi, this message translates to:
  /// **'{value}%'**
  String journeys_percent(int value);

  /// Floating check-in button on the journey screen.
  ///
  /// In vi, this message translates to:
  /// **'Check-in'**
  String get journeys_checkInNow;

  /// No description provided for @journeys_share.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ'**
  String get journeys_share;

  /// No description provided for @journeys_openGroup.
  ///
  /// In vi, this message translates to:
  /// **'Xem nhóm'**
  String get journeys_openGroup;

  /// No description provided for @journeys_endJourney.
  ///
  /// In vi, this message translates to:
  /// **'Kết thúc hành trình'**
  String get journeys_endJourney;

  /// No description provided for @journeys_endConfirmTitle.
  ///
  /// In vi, this message translates to:
  /// **'Kết thúc hành trình?'**
  String get journeys_endConfirmTitle;

  /// No description provided for @journeys_endConfirmMessage.
  ///
  /// In vi, this message translates to:
  /// **'Sau khi kết thúc, hành trình chỉ xem được và không check-in thêm được nữa.'**
  String get journeys_endConfirmMessage;

  /// No description provided for @journeys_archive.
  ///
  /// In vi, this message translates to:
  /// **'Lưu trữ'**
  String get journeys_archive;

  /// No description provided for @journeys_archiveConfirmTitle.
  ///
  /// In vi, this message translates to:
  /// **'Lưu trữ hành trình?'**
  String get journeys_archiveConfirmTitle;

  /// No description provided for @journeys_archiveConfirmMessage.
  ///
  /// In vi, this message translates to:
  /// **'Hành trình sẽ được ẩn khỏi danh sách. Bạn có thể hoàn tác ngay sau khi lưu trữ.'**
  String get journeys_archiveConfirmMessage;

  /// No description provided for @journeys_archived.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu trữ hành trình'**
  String get journeys_archived;

  /// No description provided for @journeys_archiveUndo.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tác'**
  String get journeys_archiveUndo;

  /// No description provided for @journeys_archivedSection.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu trữ'**
  String get journeys_archivedSection;

  /// No description provided for @journeys_unarchive.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ lưu trữ'**
  String get journeys_unarchive;

  /// No description provided for @journeys_delete.
  ///
  /// In vi, this message translates to:
  /// **'Xóa hành trình'**
  String get journeys_delete;

  /// No description provided for @journeys_deleteConfirmTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xóa hành trình?'**
  String get journeys_deleteConfirmTitle;

  /// No description provided for @journeys_deleteConfirmMessage.
  ///
  /// In vi, this message translates to:
  /// **'Mọi ảnh của bạn trong hành trình này sẽ bị xóa. Không hoàn tác được.'**
  String get journeys_deleteConfirmMessage;

  /// No description provided for @journeys_readOnlyBanner.
  ///
  /// In vi, this message translates to:
  /// **'Hành trình đã kết thúc. Chỉ xem.'**
  String get journeys_readOnlyBanner;

  /// No description provided for @journeys_moreActions.
  ///
  /// In vi, this message translates to:
  /// **'Thêm thao tác'**
  String get journeys_moreActions;

  /// No description provided for @journeys_timelineTitle.
  ///
  /// In vi, this message translates to:
  /// **'Dòng thời gian'**
  String get journeys_timelineTitle;

  /// No description provided for @journeys_privacyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Riêng tư'**
  String get journeys_privacyTitle;

  /// Screen reader label of a timeline cell (FR-B4).
  ///
  /// In vi, this message translates to:
  /// **'Ngày {day}, {date}: đã check-in'**
  String journeys_cellChecked(int day, String date);

  /// No description provided for @journeys_cellMissed.
  ///
  /// In vi, this message translates to:
  /// **'Ngày {day}, {date}: chưa chụp'**
  String journeys_cellMissed(int day, String date);

  /// No description provided for @journeys_cellToday.
  ///
  /// In vi, this message translates to:
  /// **'Ngày {day}, {date}: hôm nay, chưa check-in'**
  String journeys_cellToday(int day, String date);

  /// No description provided for @journeys_cellFuture.
  ///
  /// In vi, this message translates to:
  /// **'Ngày {day}, {date}: sắp tới'**
  String journeys_cellFuture(int day, String date);

  /// No description provided for @journeys_cellNotCounted.
  ///
  /// In vi, this message translates to:
  /// **'Ngày {day}, {date}: trước khi bạn tham gia'**
  String journeys_cellNotCounted(int day, String date);

  /// No description provided for @journeys_today.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay'**
  String get journeys_today;

  /// No description provided for @journeys_fromLibrary.
  ///
  /// In vi, this message translates to:
  /// **'Từ thư viện'**
  String get journeys_fromLibrary;

  /// No description provided for @journeys_metricHidden.
  ///
  /// In vi, this message translates to:
  /// **'Đang ẩn'**
  String get journeys_metricHidden;

  /// No description provided for @journeys_showMetric.
  ///
  /// In vi, this message translates to:
  /// **'Hiện con số'**
  String get journeys_showMetric;

  /// No description provided for @journeys_photoUnavailable.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh chưa tải được'**
  String get journeys_photoUnavailable;

  /// No description provided for @journeys_noCheckIn.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có ảnh cho ngày này'**
  String get journeys_noCheckIn;

  /// Day viewer: which photo of the day is shown (several photos a day).
  ///
  /// In vi, this message translates to:
  /// **'{index}/{count}'**
  String journeys_dayPhotoCount(int index, int count);

  /// Screen reader label of the day viewer photo counter.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh {index} trên {count} của ngày này. Vuốt để xem ảnh khác.'**
  String journeys_dayPhotoCountSemantics(int index, int count);

  /// Hub greeting before noon.
  ///
  /// In vi, this message translates to:
  /// **'Chào buổi sáng'**
  String get journeys_greetingMorning;

  /// Hub greeting 12:00-17:59.
  ///
  /// In vi, this message translates to:
  /// **'Chào buổi chiều'**
  String get journeys_greetingAfternoon;

  /// Hub greeting from 18:00.
  ///
  /// In vi, this message translates to:
  /// **'Chào buổi tối'**
  String get journeys_greetingEvening;

  /// Greeting followed by the user's display name.
  ///
  /// In vi, this message translates to:
  /// **'{greeting}, {name}'**
  String journeys_greetingNamed(String greeting, String name);

  /// Hub prompt under the greeting.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{Còn {count} hành trình chờ ảnh hôm nay.}}'**
  String journeys_remainingToday(int count);

  /// Hub prompt when every running journey is checked in today.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay xong hết rồi. Hẹn bạn ngày mai.'**
  String get journeys_allDonePrompt;

  /// All-done card on the hub.
  ///
  /// In vi, this message translates to:
  /// **'Xong hết hôm nay'**
  String get journeys_allDoneTitle;

  /// Eyebrow of the Today card and label of today's cell.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay'**
  String get journeys_todayLabel;

  /// Compact day N/M on the Today card photo.
  ///
  /// In vi, this message translates to:
  /// **'Ngày {day}/{total}'**
  String journeys_dayShort(int day, int total);

  /// Word after the streak count on the Today card.
  ///
  /// In vi, this message translates to:
  /// **'ngày liên tiếp'**
  String get journeys_streakWord;

  /// Time left to post today, in whole hours.
  ///
  /// In vi, this message translates to:
  /// **'{hours, plural, other{Còn {hours} giờ}}'**
  String journeys_endsInHours(int hours);

  /// Less than one hour left to post today.
  ///
  /// In vi, this message translates to:
  /// **'Còn chưa tới 1 giờ'**
  String get journeys_endsSoon;

  /// Today card status on day 1.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu hôm nay'**
  String get journeys_startsToday;

  /// Semantics label of the 7-day strip.
  ///
  /// In vi, this message translates to:
  /// **'Bảy ngày gần nhất'**
  String get journeys_lastSevenDays;

  /// Primary button on the Today card.
  ///
  /// In vi, this message translates to:
  /// **'Chụp hôm nay'**
  String get journeys_snapToday;

  /// Hub list heading.
  ///
  /// In vi, this message translates to:
  /// **'Hành trình của bạn'**
  String get journeys_yourJourneys;

  /// Short status on a journey row: checked in today.
  ///
  /// In vi, this message translates to:
  /// **'Xong'**
  String get journeys_rowDone;

  /// Short status on a journey row: not checked in today.
  ///
  /// In vi, this message translates to:
  /// **'Chưa'**
  String get journeys_rowNotYet;

  /// Visibility chip: only me.
  ///
  /// In vi, this message translates to:
  /// **'Riêng tư'**
  String get journeys_privacyPrivate;

  /// Visibility chip: anyone with the link.
  ///
  /// In vi, this message translates to:
  /// **'Bật link'**
  String get journeys_privacyLink;

  /// Visibility chip: group members.
  ///
  /// In vi, this message translates to:
  /// **'Nhóm'**
  String get journeys_privacyGroup;

  /// Tooltip of the + button in the hub header.
  ///
  /// In vi, this message translates to:
  /// **'Thêm hành trình'**
  String get journeys_addJourney;

  /// Empty Shelf segment.
  ///
  /// In vi, this message translates to:
  /// **'Hành trình đã xong sẽ nằm ở đây để bạn xem lại.'**
  String get journeys_shelfEmpty;

  /// Empty Active segment.
  ///
  /// In vi, this message translates to:
  /// **'Hiện chưa có hành trình nào đang chạy.'**
  String get journeys_activeEmpty;

  /// Template card tagline: Quiet Transformer.
  ///
  /// In vi, this message translates to:
  /// **'Nhìn những thay đổi nhỏ cộng lại.'**
  String get journeys_tagWeightLoss;

  /// Template card tagline: Accountability Squad.
  ///
  /// In vi, this message translates to:
  /// **'Giữ động lực cho cả nhóm.'**
  String get journeys_tagEnglish;

  /// Template card tagline: Memory Collectors.
  ///
  /// In vi, this message translates to:
  /// **'Lưu lại từng ngày đi xa.'**
  String get journeys_tagTravel;

  /// Template card tagline: Couple Rituals.
  ///
  /// In vi, this message translates to:
  /// **'Nhớ về từng khoảnh khắc chung.'**
  String get journeys_tagCouple;

  /// Template card tagline: Aesthetic Flexer.
  ///
  /// In vi, this message translates to:
  /// **'Tiến lên qua từng buổi tập.'**
  String get journeys_tagWorkout;

  /// Template card tagline: Custom.
  ///
  /// In vi, this message translates to:
  /// **'Tạo theo cách của bạn.'**
  String get journeys_tagCustom;

  /// Template card footer: who can join.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ cá nhân'**
  String get journeys_modeSoloOnly;

  /// Template card footer: who can join.
  ///
  /// In vi, this message translates to:
  /// **'Cá nhân · Nhóm'**
  String get journeys_modeSoloGroup;

  /// Template card footer: who can join.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ cặp đôi'**
  String get journeys_modeCoupleOnly;

  /// Note under the create form's style header.
  ///
  /// In vi, this message translates to:
  /// **'Phong cách không đổi được sau khi tạo'**
  String get journeys_styleLocked;

  /// Expands the advanced create options.
  ///
  /// In vi, this message translates to:
  /// **'Tùy chọn khác'**
  String get journeys_moreOptions;

  /// Detail stat: number of photos posted.
  ///
  /// In vi, this message translates to:
  /// **'Khoảnh khắc'**
  String get journeys_statMoments;

  /// Small unit after a streak number.
  ///
  /// In vi, this message translates to:
  /// **'ngày'**
  String get journeys_daysUnit;

  /// Journey date range eyebrow.
  ///
  /// In vi, this message translates to:
  /// **'{start} — {end}'**
  String journeys_dateRange(String start, String end);

  /// Eyebrow of an open-ended journey.
  ///
  /// In vi, this message translates to:
  /// **'Từ {start}'**
  String journeys_sinceDate(String start);

  /// Floating button when today is already posted.
  ///
  /// In vi, this message translates to:
  /// **'Chụp thêm ảnh hôm nay'**
  String get journeys_addMore;

  /// Short visible label of the current-streak stat column.
  ///
  /// In vi, this message translates to:
  /// **'Hiện tại'**
  String get journeys_statCurrentShort;

  /// Hub segment: journeys others shared with me
  ///
  /// In vi, this message translates to:
  /// **'Được chia sẻ'**
  String get journeys_sharedSection;

  /// Shelf button: import an old journey from photos
  ///
  /// In vi, this message translates to:
  /// **'Kể lại hành trình đã qua'**
  String get journeys_retell;

  /// Row tag: journey retold from past photos
  ///
  /// In vi, this message translates to:
  /// **'Đã nhập'**
  String get journeys_imported;

  /// Journey menu: make an image card
  ///
  /// In vi, this message translates to:
  /// **'Tạo thẻ chia sẻ'**
  String get journeys_shareCard;

  /// Back button label on journey screens.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại'**
  String get journeys_back;

  /// Intro line above the shelf albums.
  ///
  /// In vi, this message translates to:
  /// **'Những hành trình đã xong, được giữ như album.'**
  String get journeys_shelfIntro;

  /// Empty hub body (no journeys yet).
  ///
  /// In vi, this message translates to:
  /// **'Mỗi ngày một tấm ảnh để giữ lại hành trình. Bắt đầu với điều bạn quan tâm.'**
  String get journeys_dayZeroBody;

  /// Empty hub primary button.
  ///
  /// In vi, this message translates to:
  /// **'Tạo hành trình đầu tiên'**
  String get journeys_dayZeroStart;

  /// Empty hub greeting.
  ///
  /// In vi, this message translates to:
  /// **'Chào {name}'**
  String journeys_greetingHi(String name);

  /// Today sheet: journeys still waiting.
  ///
  /// In vi, this message translates to:
  /// **'Còn {count}'**
  String journeys_todayLeft(int count);

  /// Today sheet group: streak about to break.
  ///
  /// In vi, this message translates to:
  /// **'Đang có chuỗi'**
  String get journeys_todayAtRisk;

  /// Today sheet group: the other journeys.
  ///
  /// In vi, this message translates to:
  /// **'Còn lại'**
  String get journeys_todayRest;

  /// Today sheet: go to the hub.
  ///
  /// In vi, this message translates to:
  /// **'Mở hành trình'**
  String get journeys_openJourneys;

  /// Today sheet progress.
  ///
  /// In vi, this message translates to:
  /// **'{done}/{total} đã xong'**
  String journeys_doneOf(int done, int total);

  /// Detail share sheet: image card option.
  ///
  /// In vi, this message translates to:
  /// **'Tạo thẻ hoặc video'**
  String get journeys_shareMakeCard;

  /// Detail share sheet: card hint.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ một khoảnh khắc'**
  String get journeys_shareMakeCardHint;

  /// Detail share sheet: share with friends option.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ hành trình này'**
  String get journeys_shareJourney;

  /// Detail share sheet: share hint.
  ///
  /// In vi, this message translates to:
  /// **'Chọn bạn bè có thể theo dõi'**
  String get journeys_shareJourneyHint;

  /// Shelf album band: photos over duration.
  ///
  /// In vi, this message translates to:
  /// **'{done}/{total} ngày'**
  String journeys_albumDays(int done, int total);

  /// Shelf album band for open-ended journeys.
  ///
  /// In vi, this message translates to:
  /// **'{count} khoảnh khắc'**
  String journeys_albumMoments(int count);

  /// Unit after a streak number on the Today sheet rows.
  ///
  /// In vi, this message translates to:
  /// **'ngày liên tiếp'**
  String get journeys_streakDaysLabel;

  /// Departure ticket preview text.
  ///
  /// In vi, this message translates to:
  /// **'HỒ SƠ RIÊNG TƯ'**
  String get journeys_ticketPrivate;

  /// Departure ticket preview text.
  ///
  /// In vi, this message translates to:
  /// **'VÉ KÝ ỨC'**
  String get journeys_ticketMemory;

  /// Departure ticket preview text.
  ///
  /// In vi, this message translates to:
  /// **'Đổi màu'**
  String get journeys_ticketChangeColor;

  /// Departure ticket preview text.
  ///
  /// In vi, this message translates to:
  /// **'Bạn'**
  String get journeys_ticketYou;

  /// Departure ticket preview text.
  ///
  /// In vi, this message translates to:
  /// **'Người ấy'**
  String get journeys_ticketPartner;

  /// Departure ticket preview text.
  ///
  /// In vi, this message translates to:
  /// **'không hẹn ngày về'**
  String get journeys_ticketOpenEnded;

  /// Departure ticket preview text.
  ///
  /// In vi, this message translates to:
  /// **'Ngày {day}'**
  String journeys_ticketMilestone(String day);

  /// Departure ticket preview text.
  ///
  /// In vi, this message translates to:
  /// **'{start} – {end}'**
  String journeys_ticketDates(String start, String end);

  /// Departure ticket preview text.
  ///
  /// In vi, this message translates to:
  /// **'Từ {start}'**
  String journeys_ticketDatesOpen(String start);

  /// Departure ticket preview text.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ mình bạn thấy. Từng chút một.'**
  String get journeys_ticketTagQuiet;

  /// Departure ticket preview text.
  ///
  /// In vi, this message translates to:
  /// **'Điểm danh mỗi ngày, cả nhóm cùng lên!'**
  String get journeys_ticketTagSquad;

  /// Departure ticket preview text.
  ///
  /// In vi, this message translates to:
  /// **'Mang về thật nhiều khung hình.'**
  String get journeys_ticketTagMemory;

  /// Departure ticket preview text.
  ///
  /// In vi, this message translates to:
  /// **'Mỗi ngày một nửa, ghép lại thành một.'**
  String get journeys_ticketTagCouple;

  /// Departure ticket preview text.
  ///
  /// In vi, this message translates to:
  /// **'Bền bỉ từng bước. Chạy tiếp.'**
  String get journeys_ticketTagFlexer;

  /// Departure ticket preview text for non-running workouts.
  ///
  /// In vi, this message translates to:
  /// **'Bền bỉ từng buổi. Tập tiếp.'**
  String get journeys_ticketTagFlexerTrain;

  /// Departure ticket preview text.
  ///
  /// In vi, this message translates to:
  /// **'Xem trước vé khởi hành'**
  String get journeys_ticketPreview;

  /// Couple timeline: label under your own half of a day.
  ///
  /// In vi, this message translates to:
  /// **'Bạn'**
  String get journeys_coupleYou;

  /// Couple timeline: placeholder where the partner photo goes.
  ///
  /// In vi, this message translates to:
  /// **'Đang chờ người ấy'**
  String get journeys_coupleWaiting;

  /// Create journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Bước {step}/{total}'**
  String journeys_createStepOf(int step, int total);

  /// Create journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục'**
  String get journeys_createNext;

  /// Create journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Thoát tạo hành trình'**
  String get journeys_createExit;

  /// Create journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Chạm một kiểu để bắt đầu.'**
  String get journeys_createPickSubtitle;

  /// Create journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Đã chọn'**
  String get journeys_createChosen;

  /// Create journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Đặt tên và mục tiêu.'**
  String get journeys_createDetailTitle;

  /// Create journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Đi cùng ai?'**
  String get journeys_createWhoTitle;

  /// Create journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ hai đứa'**
  String get journeys_kindCouple;

  /// Create journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ bạn và chiếc máy ảnh.'**
  String get journeys_kindSoloBody;

  /// Create journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Tối đa 10 người, mời bằng mã.'**
  String get journeys_kindGroupBody;

  /// Create journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Một cặp, một nhịp.'**
  String get journeys_kindCoupleBody;

  /// Create journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Tên bạn'**
  String get journeys_coupleNameYou;

  /// Create journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Tên người ấy'**
  String get journeys_coupleNameOther;

  /// Create journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Nhập tên cả hai người.'**
  String get journeys_errorCoupleNames;

  /// Create journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Đặt nhịp.'**
  String get journeys_createRhythmTitle;

  /// Create journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Ngày bắt đầu'**
  String get journeys_fieldStartDate;

  /// Create journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Tháng trước'**
  String get journeys_calendarPrev;

  /// Create journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Tháng sau'**
  String get journeys_calendarNext;

  /// Create journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Từ {start} đến {end}'**
  String journeys_calendarRange(String start, String end);

  /// Create journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Vé khởi hành của bạn.'**
  String get journeys_createReviewTitle;

  /// Create journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Sửa lại'**
  String get journeys_createReviewEdit;

  /// No description provided for @journeys_extraMinutes.
  ///
  /// In vi, this message translates to:
  /// **'{minutes} phút'**
  String journeys_extraMinutes(int minutes);

  /// No description provided for @journeys_extraHearts.
  ///
  /// In vi, this message translates to:
  /// **'{count}/5 tim'**
  String journeys_extraHearts(int count);

  /// No description provided for @journeys_extraKm.
  ///
  /// In vi, this message translates to:
  /// **'{km} km'**
  String journeys_extraKm(String km);

  /// No description provided for @journeys_extraPace.
  ///
  /// In vi, this message translates to:
  /// **'{pace} /km'**
  String journeys_extraPace(String pace);

  /// No description provided for @journeys_extraCook.
  ///
  /// In vi, this message translates to:
  /// **'{name} nấu'**
  String journeys_extraCook(String name);

  /// Check-in extras on the journey screens.
  ///
  /// In vi, this message translates to:
  /// **'Nhẹ nhõm'**
  String get journeys_extraMoodLight;

  /// Check-in extras on the journey screens.
  ///
  /// In vi, this message translates to:
  /// **'Bình thường'**
  String get journeys_extraMoodNormal;

  /// Check-in extras on the journey screens.
  ///
  /// In vi, this message translates to:
  /// **'Hơi mệt'**
  String get journeys_extraMoodTired;

  /// Check-in extras on the journey screens.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh của người ấy'**
  String get journeys_partnerPhotoSemantics;

  /// No description provided for @journeys_inviteAction.
  ///
  /// In vi, this message translates to:
  /// **'Mời bạn'**
  String get journeys_inviteAction;

  /// No description provided for @journeys_renameCouple.
  ///
  /// In vi, this message translates to:
  /// **'Sửa tên'**
  String get journeys_renameCouple;

  /// No description provided for @journeys_renameCoupleTitle.
  ///
  /// In vi, this message translates to:
  /// **'Sửa tên cặp đôi'**
  String get journeys_renameCoupleTitle;

  /// No description provided for @journeys_quietHold.
  ///
  /// In vi, this message translates to:
  /// **'Giữ để xem'**
  String get journeys_quietHold;

  /// No description provided for @journeys_quietHolding.
  ///
  /// In vi, this message translates to:
  /// **'Đang xem'**
  String get journeys_quietHolding;

  /// No description provided for @journeys_quietHoldHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhấn giữ để hiện số của bạn'**
  String get journeys_quietHoldHint;

  /// No description provided for @journeys_quietHidden.
  ///
  /// In vi, this message translates to:
  /// **'Đã ẩn'**
  String get journeys_quietHidden;

  /// No description provided for @journeys_quietAxis.
  ///
  /// In vi, this message translates to:
  /// **'{value} kg'**
  String journeys_quietAxis(String value);

  /// No description provided for @journeys_quietDayTag.
  ///
  /// In vi, this message translates to:
  /// **'NGÀY {day}'**
  String journeys_quietDayTag(int day);

  /// No description provided for @journeys_quietToday.
  ///
  /// In vi, this message translates to:
  /// **'HÔM NAY'**
  String get journeys_quietToday;

  /// No description provided for @journeys_quietWeek.
  ///
  /// In vi, this message translates to:
  /// **'TUẦN ĐẦU'**
  String get journeys_quietWeek;

  /// No description provided for @journeys_quietHalf.
  ///
  /// In vi, this message translates to:
  /// **'NỬA CHẶNG'**
  String get journeys_quietHalf;

  /// No description provided for @journeys_quietFinish.
  ///
  /// In vi, this message translates to:
  /// **'VỀ ĐÍCH'**
  String get journeys_quietFinish;

  /// No description provided for @journeys_quietMissed.
  ///
  /// In vi, this message translates to:
  /// **'Một ngày nghỉ không xóa hành trình.'**
  String get journeys_quietMissed;

  /// No description provided for @journeys_quietMilestones.
  ///
  /// In vi, this message translates to:
  /// **'Cột mốc'**
  String get journeys_quietMilestones;

  /// No description provided for @journeys_memoryToday.
  ///
  /// In vi, this message translates to:
  /// **'HÔM NAY · chạm để chụp'**
  String get journeys_memoryToday;

  /// No description provided for @journeys_memoryEmpty.
  ///
  /// In vi, this message translates to:
  /// **'KHUNG TRỐNG'**
  String get journeys_memoryEmpty;

  /// No description provided for @journeys_memoryFilmRoll.
  ///
  /// In vi, this message translates to:
  /// **'CUỘN PHIM · {count} KHUNG'**
  String journeys_memoryFilmRoll(int count);

  /// No description provided for @journeys_memoryOffline.
  ///
  /// In vi, this message translates to:
  /// **'NGOẠI TUYẾN · chờ đồng bộ'**
  String get journeys_memoryOffline;

  /// No description provided for @journeys_dna_goal_title_weight.
  ///
  /// In vi, this message translates to:
  /// **'mục tiêu của bạn.'**
  String get journeys_dna_goal_title_weight;

  /// No description provided for @journeys_dna_weight_title.
  ///
  /// In vi, this message translates to:
  /// **'cân nặng hiện tại.'**
  String get journeys_dna_weight_title;

  /// No description provided for @journeys_dna_ghost_title.
  ///
  /// In vi, this message translates to:
  /// **'chụp ảnh ngày 1 làm khung căn dáng.'**
  String get journeys_dna_ghost_title;

  /// No description provided for @journeys_dna_goal_title_english.
  ///
  /// In vi, this message translates to:
  /// **'mục tiêu.'**
  String get journeys_dna_goal_title_english;

  /// No description provided for @journeys_dna_minutes_title.
  ///
  /// In vi, this message translates to:
  /// **'mỗi ngày bao nhiêu phút.'**
  String get journeys_dna_minutes_title;

  /// No description provided for @journeys_dna_trophy_title.
  ///
  /// In vi, this message translates to:
  /// **'đặt tên chiếc cúp ở đích.'**
  String get journeys_dna_trophy_title;

  /// No description provided for @journeys_dna_sport_title.
  ///
  /// In vi, this message translates to:
  /// **'môn gì.'**
  String get journeys_dna_sport_title;

  /// No description provided for @journeys_dna_measure_title.
  ///
  /// In vi, this message translates to:
  /// **'đo bằng gì.'**
  String get journeys_dna_measure_title;

  /// No description provided for @journeys_dna_hud_title.
  ///
  /// In vi, this message translates to:
  /// **'kiểu HUD.'**
  String get journeys_dna_hud_title;

  /// No description provided for @journeys_dna_place_title.
  ///
  /// In vi, this message translates to:
  /// **'đi đâu.'**
  String get journeys_dna_place_title;

  /// No description provided for @journeys_dna_dates_title.
  ///
  /// In vi, this message translates to:
  /// **'ngày đi – ngày về.'**
  String get journeys_dna_dates_title;

  /// No description provided for @journeys_dna_film_title.
  ///
  /// In vi, this message translates to:
  /// **'cuộn phim mấy tấm.'**
  String get journeys_dna_film_title;

  /// No description provided for @journeys_dna_ritual_title.
  ///
  /// In vi, this message translates to:
  /// **'nghi thức của hai đứa.'**
  String get journeys_dna_ritual_title;

  /// No description provided for @journeys_dna_names_title.
  ///
  /// In vi, this message translates to:
  /// **'tên hai người.'**
  String get journeys_dna_names_title;

  /// No description provided for @journeys_dna_side_title.
  ///
  /// In vi, this message translates to:
  /// **'ai chụp nửa nào.'**
  String get journeys_dna_side_title;

  /// No description provided for @journeys_dna_habit_title.
  ///
  /// In vi, this message translates to:
  /// **'thói quen của bạn.'**
  String get journeys_dna_habit_title;

  /// No description provided for @journeys_dna_c_goal_weight_lose.
  ///
  /// In vi, this message translates to:
  /// **'Giảm cân'**
  String get journeys_dna_c_goal_weight_lose;

  /// No description provided for @journeys_dna_c_goal_weight_lose_hint.
  ///
  /// In vi, this message translates to:
  /// **'nhẹ đi, khỏe hơn mỗi ngày'**
  String get journeys_dna_c_goal_weight_lose_hint;

  /// No description provided for @journeys_dna_c_goal_weight_keep.
  ///
  /// In vi, this message translates to:
  /// **'Giữ dáng'**
  String get journeys_dna_c_goal_weight_keep;

  /// No description provided for @journeys_dna_c_goal_weight_keep_hint.
  ///
  /// In vi, this message translates to:
  /// **'duy trì nhịp sống hiện tại'**
  String get journeys_dna_c_goal_weight_keep_hint;

  /// No description provided for @journeys_dna_c_goal_weight_shape.
  ///
  /// In vi, this message translates to:
  /// **'Thay đổi vóc dáng'**
  String get journeys_dna_c_goal_weight_shape;

  /// No description provided for @journeys_dna_c_goal_weight_shape_hint.
  ///
  /// In vi, this message translates to:
  /// **'theo dõi một phiên bản mới'**
  String get journeys_dna_c_goal_weight_shape_hint;

  /// No description provided for @journeys_dna_c_goal_english_ielts.
  ///
  /// In vi, this message translates to:
  /// **'IELTS'**
  String get journeys_dna_c_goal_english_ielts;

  /// No description provided for @journeys_dna_c_goal_english_ielts_hint.
  ///
  /// In vi, this message translates to:
  /// **'cùng nhau chạm band mục tiêu'**
  String get journeys_dna_c_goal_english_ielts_hint;

  /// No description provided for @journeys_dna_c_goal_english_talk.
  ///
  /// In vi, this message translates to:
  /// **'Giao tiếp'**
  String get journeys_dna_c_goal_english_talk;

  /// No description provided for @journeys_dna_c_goal_english_talk_hint.
  ///
  /// In vi, this message translates to:
  /// **'nói tự nhiên hơn mỗi ngày'**
  String get journeys_dna_c_goal_english_talk_hint;

  /// No description provided for @journeys_dna_c_goal_english_read.
  ///
  /// In vi, this message translates to:
  /// **'Đọc sách'**
  String get journeys_dna_c_goal_english_read;

  /// No description provided for @journeys_dna_c_goal_english_read_hint.
  ///
  /// In vi, this message translates to:
  /// **'đọc trọn cuốn sách đầu tiên'**
  String get journeys_dna_c_goal_english_read_hint;

  /// No description provided for @journeys_dna_c_minutes_15.
  ///
  /// In vi, this message translates to:
  /// **'15'**
  String get journeys_dna_c_minutes_15;

  /// No description provided for @journeys_dna_c_minutes_15_hint.
  ///
  /// In vi, this message translates to:
  /// **'15 phút mỗi ngày'**
  String get journeys_dna_c_minutes_15_hint;

  /// No description provided for @journeys_dna_c_minutes_30.
  ///
  /// In vi, this message translates to:
  /// **'30'**
  String get journeys_dna_c_minutes_30;

  /// No description provided for @journeys_dna_c_minutes_30_hint.
  ///
  /// In vi, this message translates to:
  /// **'30 phút mỗi ngày'**
  String get journeys_dna_c_minutes_30_hint;

  /// No description provided for @journeys_dna_c_minutes_45.
  ///
  /// In vi, this message translates to:
  /// **'45'**
  String get journeys_dna_c_minutes_45;

  /// No description provided for @journeys_dna_c_minutes_45_hint.
  ///
  /// In vi, this message translates to:
  /// **'45 phút mỗi ngày'**
  String get journeys_dna_c_minutes_45_hint;

  /// No description provided for @journeys_dna_c_minutes_60.
  ///
  /// In vi, this message translates to:
  /// **'60'**
  String get journeys_dna_c_minutes_60;

  /// No description provided for @journeys_dna_c_minutes_60_hint.
  ///
  /// In vi, this message translates to:
  /// **'60 phút mỗi ngày'**
  String get journeys_dna_c_minutes_60_hint;

  /// No description provided for @journeys_dna_c_sport_run.
  ///
  /// In vi, this message translates to:
  /// **'Chạy'**
  String get journeys_dna_c_sport_run;

  /// No description provided for @journeys_dna_c_sport_run_hint.
  ///
  /// In vi, this message translates to:
  /// **'30 ngày chạy'**
  String get journeys_dna_c_sport_run_hint;

  /// No description provided for @journeys_dna_c_sport_gym.
  ///
  /// In vi, this message translates to:
  /// **'Gym'**
  String get journeys_dna_c_sport_gym;

  /// No description provided for @journeys_dna_c_sport_gym_hint.
  ///
  /// In vi, this message translates to:
  /// **'30 ngày gym'**
  String get journeys_dna_c_sport_gym_hint;

  /// No description provided for @journeys_dna_c_sport_pilates.
  ///
  /// In vi, this message translates to:
  /// **'Pilates'**
  String get journeys_dna_c_sport_pilates;

  /// No description provided for @journeys_dna_c_sport_pilates_hint.
  ///
  /// In vi, this message translates to:
  /// **'30 ngày pilates'**
  String get journeys_dna_c_sport_pilates_hint;

  /// No description provided for @journeys_dna_c_sport_yoga.
  ///
  /// In vi, this message translates to:
  /// **'Yoga'**
  String get journeys_dna_c_sport_yoga;

  /// No description provided for @journeys_dna_c_sport_yoga_hint.
  ///
  /// In vi, this message translates to:
  /// **'30 ngày yoga'**
  String get journeys_dna_c_sport_yoga_hint;

  /// No description provided for @journeys_dna_c_sport_other.
  ///
  /// In vi, this message translates to:
  /// **'Khác'**
  String get journeys_dna_c_sport_other;

  /// No description provided for @journeys_dna_c_sport_other_hint.
  ///
  /// In vi, this message translates to:
  /// **'30 ngày khác'**
  String get journeys_dna_c_sport_other_hint;

  /// No description provided for @journeys_dna_c_measure_km.
  ///
  /// In vi, this message translates to:
  /// **'km'**
  String get journeys_dna_c_measure_km;

  /// No description provided for @journeys_dna_c_measure_km_hint.
  ///
  /// In vi, this message translates to:
  /// **'ghi lại theo km'**
  String get journeys_dna_c_measure_km_hint;

  /// No description provided for @journeys_dna_c_measure_min.
  ///
  /// In vi, this message translates to:
  /// **'phút'**
  String get journeys_dna_c_measure_min;

  /// No description provided for @journeys_dna_c_measure_min_hint.
  ///
  /// In vi, this message translates to:
  /// **'ghi lại theo phút'**
  String get journeys_dna_c_measure_min_hint;

  /// No description provided for @journeys_dna_c_measure_session.
  ///
  /// In vi, this message translates to:
  /// **'buổi'**
  String get journeys_dna_c_measure_session;

  /// No description provided for @journeys_dna_c_measure_session_hint.
  ///
  /// In vi, this message translates to:
  /// **'ghi lại theo buổi'**
  String get journeys_dna_c_measure_session_hint;

  /// No description provided for @journeys_dna_c_hud_bold.
  ///
  /// In vi, this message translates to:
  /// **'HUD đậm'**
  String get journeys_dna_c_hud_bold;

  /// No description provided for @journeys_dna_c_hud_bold_hint.
  ///
  /// In vi, this message translates to:
  /// **'số lớn, tương phản mạnh'**
  String get journeys_dna_c_hud_bold_hint;

  /// No description provided for @journeys_dna_c_hud_stamp.
  ///
  /// In vi, this message translates to:
  /// **'Tem tối giản'**
  String get journeys_dna_c_hud_stamp;

  /// No description provided for @journeys_dna_c_hud_stamp_hint.
  ///
  /// In vi, this message translates to:
  /// **'gọn như một con tem'**
  String get journeys_dna_c_hud_stamp_hint;

  /// No description provided for @journeys_dna_c_hud_strip.
  ///
  /// In vi, this message translates to:
  /// **'Dải phim'**
  String get journeys_dna_c_hud_strip;

  /// No description provided for @journeys_dna_c_hud_strip_hint.
  ///
  /// In vi, this message translates to:
  /// **'khoảnh khắc nối tiếp nhau'**
  String get journeys_dna_c_hud_strip_hint;

  /// No description provided for @journeys_dna_c_film_24.
  ///
  /// In vi, this message translates to:
  /// **'24 tấm'**
  String get journeys_dna_c_film_24;

  /// No description provided for @journeys_dna_c_film_24_hint.
  ///
  /// In vi, this message translates to:
  /// **'mỗi tấm đều được cân nhắc'**
  String get journeys_dna_c_film_24_hint;

  /// No description provided for @journeys_dna_c_film_36.
  ///
  /// In vi, this message translates to:
  /// **'36 tấm'**
  String get journeys_dna_c_film_36;

  /// No description provided for @journeys_dna_c_film_36_hint.
  ///
  /// In vi, this message translates to:
  /// **'thêm chỗ cho điều bất ngờ'**
  String get journeys_dna_c_film_36_hint;

  /// No description provided for @journeys_dna_c_ritual_cook.
  ///
  /// In vi, this message translates to:
  /// **'Nấu ăn'**
  String get journeys_dna_c_ritual_cook;

  /// No description provided for @journeys_dna_c_ritual_cook_hint.
  ///
  /// In vi, this message translates to:
  /// **'cùng nhau nấu ăn'**
  String get journeys_dna_c_ritual_cook_hint;

  /// No description provided for @journeys_dna_c_ritual_save.
  ///
  /// In vi, this message translates to:
  /// **'Tiết kiệm'**
  String get journeys_dna_c_ritual_save;

  /// No description provided for @journeys_dna_c_ritual_save_hint.
  ///
  /// In vi, this message translates to:
  /// **'cùng nhau tiết kiệm'**
  String get journeys_dna_c_ritual_save_hint;

  /// No description provided for @journeys_dna_c_ritual_ldr.
  ///
  /// In vi, this message translates to:
  /// **'Yêu xa'**
  String get journeys_dna_c_ritual_ldr;

  /// No description provided for @journeys_dna_c_ritual_ldr_hint.
  ///
  /// In vi, this message translates to:
  /// **'cùng nhau yêu xa'**
  String get journeys_dna_c_ritual_ldr_hint;

  /// No description provided for @journeys_dna_c_ritual_custom.
  ///
  /// In vi, this message translates to:
  /// **'Tự đặt'**
  String get journeys_dna_c_ritual_custom;

  /// No description provided for @journeys_dna_c_ritual_custom_hint.
  ///
  /// In vi, this message translates to:
  /// **'cùng nhau tự đặt'**
  String get journeys_dna_c_ritual_custom_hint;

  /// No description provided for @journeys_dna_c_side_left.
  ///
  /// In vi, this message translates to:
  /// **'Mình bên trái'**
  String get journeys_dna_c_side_left;

  /// No description provided for @journeys_dna_c_side_right.
  ///
  /// In vi, this message translates to:
  /// **'Mình bên phải'**
  String get journeys_dna_c_side_right;

  /// No description provided for @journeys_dna_step_of_q.
  ///
  /// In vi, this message translates to:
  /// **'Câu {n}/{total}'**
  String journeys_dna_step_of_q(int n, int total);

  /// No description provided for @journeys_dna_weight_unit.
  ///
  /// In vi, this message translates to:
  /// **'kg'**
  String get journeys_dna_weight_unit;

  /// No description provided for @journeys_dna_weight_a11y.
  ///
  /// In vi, this message translates to:
  /// **'Cân nặng hiện tại'**
  String get journeys_dna_weight_a11y;

  /// No description provided for @journeys_dna_weight_private.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ mình bạn thấy'**
  String get journeys_dna_weight_private;

  /// No description provided for @journeys_dna_weight_hide.
  ///
  /// In vi, this message translates to:
  /// **'Ẩn số kg khi chia sẻ'**
  String get journeys_dna_weight_hide;

  /// No description provided for @journeys_dna_weight_skip.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ qua'**
  String get journeys_dna_weight_skip;

  /// No description provided for @journeys_dna_ghost_body.
  ///
  /// In vi, this message translates to:
  /// **'Hiện khung bóng mờ trong máy ảnh để ngày nào chụp cũng khớp một góc.'**
  String get journeys_dna_ghost_body;

  /// No description provided for @journeys_dna_ghost_now.
  ///
  /// In vi, this message translates to:
  /// **'Bật khung căn dáng'**
  String get journeys_dna_ghost_now;

  /// No description provided for @journeys_dna_ghost_later.
  ///
  /// In vi, this message translates to:
  /// **'Tắt đi, để bật sau.'**
  String get journeys_dna_ghost_later;

  /// No description provided for @journeys_dna_trophy_label.
  ///
  /// In vi, this message translates to:
  /// **'Tên chiếc cúp'**
  String get journeys_dna_trophy_label;

  /// No description provided for @journeys_dna_trophy_hint.
  ///
  /// In vi, this message translates to:
  /// **'Cúp 7.5'**
  String get journeys_dna_trophy_hint;

  /// No description provided for @journeys_dna_place_search.
  ///
  /// In vi, this message translates to:
  /// **'Nhập điểm đến...'**
  String get journeys_dna_place_search;

  /// No description provided for @journeys_dna_place_country.
  ///
  /// In vi, this message translates to:
  /// **'Việt Nam'**
  String get journeys_dna_place_country;

  /// No description provided for @journeys_dna_place_dalat.
  ///
  /// In vi, this message translates to:
  /// **'Đà Lạt'**
  String get journeys_dna_place_dalat;

  /// No description provided for @journeys_dna_place_hoian.
  ///
  /// In vi, this message translates to:
  /// **'Hội An'**
  String get journeys_dna_place_hoian;

  /// No description provided for @journeys_dna_place_phuquoc.
  ///
  /// In vi, this message translates to:
  /// **'Phú Quốc'**
  String get journeys_dna_place_phuquoc;

  /// No description provided for @journeys_dna_place_pine.
  ///
  /// In vi, this message translates to:
  /// **'Rừng thông và sương'**
  String get journeys_dna_place_pine;

  /// No description provided for @journeys_dna_dates_open.
  ///
  /// In vi, this message translates to:
  /// **'chưa hẹn ngày về'**
  String get journeys_dna_dates_open;

  /// No description provided for @journeys_dna_dates_prompt.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ngày đi và ngày về'**
  String get journeys_dna_dates_prompt;

  /// No description provided for @journeys_dna_dates_open_summary.
  ///
  /// In vi, this message translates to:
  /// **'{start} · chưa hẹn ngày về'**
  String journeys_dna_dates_open_summary(String start);

  /// No description provided for @journeys_dna_dates_range_summary.
  ///
  /// In vi, this message translates to:
  /// **'{start} – {end}'**
  String journeys_dna_dates_range_summary(String start, String end);

  /// No description provided for @journeys_dna_dates_min_note.
  ///
  /// In vi, this message translates to:
  /// **'Hành trình dài ít nhất {days} ngày nên ngày về đã được lùi lại.'**
  String journeys_dna_dates_min_note(int days);

  /// No description provided for @journeys_dna_dates_max_note.
  ///
  /// In vi, this message translates to:
  /// **'Hành trình dài tối đa {days} ngày nên ngày về đã được kéo gần lại.'**
  String journeys_dna_dates_max_note(int days);

  /// No description provided for @journeys_dna_prev_month.
  ///
  /// In vi, this message translates to:
  /// **'Tháng trước'**
  String get journeys_dna_prev_month;

  /// No description provided for @journeys_dna_next_month.
  ///
  /// In vi, this message translates to:
  /// **'Tháng sau'**
  String get journeys_dna_next_month;

  /// No description provided for @journeys_dna_name_left.
  ///
  /// In vi, this message translates to:
  /// **'Tên bạn'**
  String get journeys_dna_name_left;

  /// No description provided for @journeys_dna_name_right.
  ///
  /// In vi, this message translates to:
  /// **'Tên người ấy'**
  String get journeys_dna_name_right;

  /// No description provided for @journeys_dna_habit_label.
  ///
  /// In vi, this message translates to:
  /// **'Thói quen'**
  String get journeys_dna_habit_label;

  /// No description provided for @journeys_dna_habit_hint.
  ///
  /// In vi, this message translates to:
  /// **'Đọc 10 trang'**
  String get journeys_dna_habit_hint;

  /// No description provided for @journeys_dna_reason_label.
  ///
  /// In vi, this message translates to:
  /// **'vì sao.'**
  String get journeys_dna_reason_label;

  /// No description provided for @journeys_dna_reason_hint.
  ///
  /// In vi, this message translates to:
  /// **'để ngủ ngon hơn'**
  String get journeys_dna_reason_hint;

  /// No description provided for @journeys_dna_forge_title.
  ///
  /// In vi, this message translates to:
  /// **'đang đúc DNA…'**
  String get journeys_dna_forge_title;

  /// No description provided for @journeys_dna_forge_a11y.
  ///
  /// In vi, this message translates to:
  /// **'Đang tạo hành trình của bạn'**
  String get journeys_dna_forge_a11y;

  /// No description provided for @journeys_dna_import_link.
  ///
  /// In vi, this message translates to:
  /// **'Kể lại hành trình đã qua'**
  String get journeys_dna_import_link;

  /// No description provided for @journeys_home_introQuiet.
  ///
  /// In vi, this message translates to:
  /// **'Nhìn lại từng chút một.'**
  String get journeys_home_introQuiet;

  /// No description provided for @journeys_home_introSquad.
  ///
  /// In vi, this message translates to:
  /// **'hôm nay học bao lâu.'**
  String get journeys_home_introSquad;

  /// No description provided for @journeys_home_introMemory.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay cả bọn lạc ở đâu?'**
  String get journeys_home_introMemory;

  /// No description provided for @journeys_home_introCouple.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay hai đứa nấu gì?'**
  String get journeys_home_introCouple;

  /// No description provided for @journeys_home_introCoupleSave.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay hai đứa góp thêm được gì?'**
  String get journeys_home_introCoupleSave;

  /// No description provided for @journeys_home_introCoupleLdr.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay hai đứa gửi gì cho nhau?'**
  String get journeys_home_introCoupleLdr;

  /// No description provided for @journeys_home_introCoupleCustom.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay hai đứa có khoảnh khắc gì cùng nhau?'**
  String get journeys_home_introCoupleCustom;

  /// No description provided for @journeys_home_offlineQuiet.
  ///
  /// In vi, this message translates to:
  /// **'Đang lưu trên máy · sẽ đồng bộ sau'**
  String get journeys_home_offlineQuiet;

  /// No description provided for @journeys_home_offlineSquad.
  ///
  /// In vi, this message translates to:
  /// **'CHỜ ĐỒNG BỘ · ĐÃ LƯU TRÊN MÁY'**
  String get journeys_home_offlineSquad;

  /// No description provided for @journeys_home_offlineMemory.
  ///
  /// In vi, this message translates to:
  /// **'Đang lưu trên máy. Có mạng sẽ tự gửi.'**
  String get journeys_home_offlineMemory;

  /// No description provided for @journeys_home_readOnlyQuiet.
  ///
  /// In vi, this message translates to:
  /// **'Hành trình đã kết thúc · chỉ xem'**
  String get journeys_home_readOnlyQuiet;

  /// No description provided for @journeys_home_readOnlyFlexer.
  ///
  /// In vi, this message translates to:
  /// **'ĐÃ VỀ ĐÍCH · CHỈ ĐỌC'**
  String get journeys_home_readOnlyFlexer;

  /// No description provided for @journeys_home_readOnlyMinimal.
  ///
  /// In vi, this message translates to:
  /// **'ĐÃ KẾT THÚC · CHỈ ĐỌC'**
  String get journeys_home_readOnlyMinimal;

  /// No description provided for @journeys_home_dayStreak.
  ///
  /// In vi, this message translates to:
  /// **'Ngày {day}/{total} · chuỗi {streak}'**
  String journeys_home_dayStreak(int day, int total, int streak);

  /// No description provided for @journeys_home_dayStreakOpen.
  ///
  /// In vi, this message translates to:
  /// **'Ngày {day} · chuỗi {streak}'**
  String journeys_home_dayStreakOpen(int day, int streak);

  /// No description provided for @journeys_home_monthStreak.
  ///
  /// In vi, this message translates to:
  /// **'{month} · CHUỖI {streak} NGÀY'**
  String journeys_home_monthStreak(int streak, String month);

  /// No description provided for @journeys_home_holdReveal.
  ///
  /// In vi, this message translates to:
  /// **'Giữ để xem'**
  String get journeys_home_holdReveal;

  /// No description provided for @journeys_home_viewing.
  ///
  /// In vi, this message translates to:
  /// **'Đang xem'**
  String get journeys_home_viewing;

  /// No description provided for @journeys_home_chartA11y.
  ///
  /// In vi, this message translates to:
  /// **'Đường tiến trình'**
  String get journeys_home_chartA11y;

  /// No description provided for @journeys_home_msWeek.
  ///
  /// In vi, this message translates to:
  /// **'Tuần đầu'**
  String get journeys_home_msWeek;

  /// No description provided for @journeys_home_msHalf.
  ///
  /// In vi, this message translates to:
  /// **'Nửa chặng'**
  String get journeys_home_msHalf;

  /// No description provided for @journeys_home_msFinish.
  ///
  /// In vi, this message translates to:
  /// **'Về đích'**
  String get journeys_home_msFinish;

  /// No description provided for @journeys_home_msDay.
  ///
  /// In vi, this message translates to:
  /// **'NGÀY {day}'**
  String journeys_home_msDay(int day);

  /// No description provided for @journeys_home_actionSquad.
  ///
  /// In vi, this message translates to:
  /// **'Nhóm hôm nay'**
  String get journeys_home_actionSquad;

  /// No description provided for @journeys_home_actionCard.
  ///
  /// In vi, this message translates to:
  /// **'Tạo thiệp'**
  String get journeys_home_actionCard;

  /// No description provided for @journeys_home_attendance.
  ///
  /// In vi, this message translates to:
  /// **'{done}/{total} NGÀY ĐÃ CHỤP'**
  String journeys_home_attendance(int done, int total);

  /// No description provided for @journeys_home_retake.
  ///
  /// In vi, this message translates to:
  /// **'Chụp thêm ảnh hôm nay'**
  String get journeys_home_retake;

  /// No description provided for @journeys_home_timelineLabel.
  ///
  /// In vi, this message translates to:
  /// **'Dòng thời gian'**
  String get journeys_home_timelineLabel;

  /// No description provided for @journeys_edit_title.
  ///
  /// In vi, this message translates to:
  /// **'cập nhật hành trình.'**
  String get journeys_edit_title;

  /// No description provided for @journeys_edit_save.
  ///
  /// In vi, this message translates to:
  /// **'Lưu'**
  String get journeys_edit_save;

  /// No description provided for @journeys_edit_name.
  ///
  /// In vi, this message translates to:
  /// **'Tên'**
  String get journeys_edit_name;

  /// No description provided for @journeys_edit_cover.
  ///
  /// In vi, this message translates to:
  /// **'Bìa'**
  String get journeys_edit_cover;

  /// No description provided for @journeys_edit_coverOption.
  ///
  /// In vi, this message translates to:
  /// **'Bìa {n}'**
  String journeys_edit_coverOption(int n);

  /// No description provided for @journeys_edit_layout.
  ///
  /// In vi, this message translates to:
  /// **'Giao diện'**
  String get journeys_edit_layout;

  /// No description provided for @journeys_edit_layoutNote.
  ///
  /// In vi, this message translates to:
  /// **'Một số giao diện cần thêm dữ liệu nên không hiện.'**
  String get journeys_edit_layoutNote;

  /// No description provided for @journeys_edit_layoutInUse.
  ///
  /// In vi, this message translates to:
  /// **'Đang dùng'**
  String get journeys_edit_layoutInUse;

  /// No description provided for @journeys_edit_layoutPreviewLabel.
  ///
  /// In vi, this message translates to:
  /// **'Xem trước giao diện {name}'**
  String journeys_edit_layoutPreviewLabel(String name);

  /// No description provided for @journeys_edit_previewTag.
  ///
  /// In vi, this message translates to:
  /// **'XEM TRƯỚC'**
  String get journeys_edit_previewTag;

  /// No description provided for @journeys_edit_hudPreview.
  ///
  /// In vi, this message translates to:
  /// **'Check-in mỗi ngày'**
  String get journeys_edit_hudPreview;

  /// No description provided for @journeys_edit_dayOf.
  ///
  /// In vi, this message translates to:
  /// **'NGÀY {day}/{total}'**
  String journeys_edit_dayOf(int day, int total);

  /// No description provided for @journeys_edit_dayOpen.
  ///
  /// In vi, this message translates to:
  /// **'NGÀY {day}'**
  String journeys_edit_dayOpen(int day);

  /// No description provided for @journeys_edit_useLayout.
  ///
  /// In vi, this message translates to:
  /// **'Dùng giao diện này'**
  String get journeys_edit_useLayout;

  /// No description provided for @journeys_edit_cancel.
  ///
  /// In vi, this message translates to:
  /// **'Hủy'**
  String get journeys_edit_cancel;

  /// No description provided for @journeys_edit_discardTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ các thay đổi?'**
  String get journeys_edit_discardTitle;

  /// No description provided for @journeys_edit_discardBody.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã sửa hành trình nhưng chưa lưu. Rời đi bây giờ sẽ mất các thay đổi đó.'**
  String get journeys_edit_discardBody;

  /// No description provided for @journeys_edit_discardConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ thay đổi'**
  String get journeys_edit_discardConfirm;

  /// No description provided for @journeys_edit_discardKeep.
  ///
  /// In vi, this message translates to:
  /// **'Sửa tiếp'**
  String get journeys_edit_discardKeep;

  /// No description provided for @journeys_edit_layoutApplied.
  ///
  /// In vi, this message translates to:
  /// **'Đã đổi giao diện cho hành trình.'**
  String get journeys_edit_layoutApplied;

  /// No description provided for @journeys_edit_layoutOwnerOnly.
  ///
  /// In vi, this message translates to:
  /// **'Chủ nhóm chọn giao diện cho cả nhóm.'**
  String get journeys_edit_layoutOwnerOnly;

  /// No description provided for @journeys_edit_color.
  ///
  /// In vi, this message translates to:
  /// **'Màu'**
  String get journeys_edit_color;

  /// No description provided for @journeys_edit_skinShort_quiet.
  ///
  /// In vi, this message translates to:
  /// **'Lặng lẽ'**
  String get journeys_edit_skinShort_quiet;

  /// No description provided for @journeys_edit_skinColor_quiet_0.
  ///
  /// In vi, this message translates to:
  /// **'Lục ngọc'**
  String get journeys_edit_skinColor_quiet_0;

  /// No description provided for @journeys_edit_skinColor_quiet_1.
  ///
  /// In vi, this message translates to:
  /// **'Xanh sage'**
  String get journeys_edit_skinColor_quiet_1;

  /// No description provided for @journeys_edit_skinColor_quiet_2.
  ///
  /// In vi, this message translates to:
  /// **'Sương mù'**
  String get journeys_edit_skinColor_quiet_2;

  /// No description provided for @journeys_edit_skinShort_squad.
  ///
  /// In vi, this message translates to:
  /// **'Đội'**
  String get journeys_edit_skinShort_squad;

  /// No description provided for @journeys_edit_skinColor_squad_0.
  ///
  /// In vi, this message translates to:
  /// **'Lửa'**
  String get journeys_edit_skinColor_squad_0;

  /// No description provided for @journeys_edit_skinColor_squad_1.
  ///
  /// In vi, this message translates to:
  /// **'Tím'**
  String get journeys_edit_skinColor_squad_1;

  /// No description provided for @journeys_edit_skinColor_squad_2.
  ///
  /// In vi, this message translates to:
  /// **'Phấn'**
  String get journeys_edit_skinColor_squad_2;

  /// No description provided for @journeys_edit_skinShort_memory.
  ///
  /// In vi, this message translates to:
  /// **'Ký ức'**
  String get journeys_edit_skinShort_memory;

  /// No description provided for @journeys_edit_skinColor_memory_0.
  ///
  /// In vi, this message translates to:
  /// **'Sương thông'**
  String get journeys_edit_skinColor_memory_0;

  /// No description provided for @journeys_edit_skinColor_memory_1.
  ///
  /// In vi, this message translates to:
  /// **'Biển muối'**
  String get journeys_edit_skinColor_memory_1;

  /// No description provided for @journeys_edit_skinColor_memory_2.
  ///
  /// In vi, this message translates to:
  /// **'Phố đêm'**
  String get journeys_edit_skinColor_memory_2;

  /// No description provided for @journeys_edit_skinShort_couple.
  ///
  /// In vi, this message translates to:
  /// **'Đôi'**
  String get journeys_edit_skinShort_couple;

  /// No description provided for @journeys_edit_skinColor_couple_0.
  ///
  /// In vi, this message translates to:
  /// **'Hồng'**
  String get journeys_edit_skinColor_couple_0;

  /// No description provided for @journeys_edit_skinColor_couple_1.
  ///
  /// In vi, this message translates to:
  /// **'Mâm xôi'**
  String get journeys_edit_skinColor_couple_1;

  /// No description provided for @journeys_edit_skinColor_couple_2.
  ///
  /// In vi, this message translates to:
  /// **'Đào'**
  String get journeys_edit_skinColor_couple_2;

  /// No description provided for @journeys_edit_skinShort_flexer.
  ///
  /// In vi, this message translates to:
  /// **'Khoe thẩm mỹ'**
  String get journeys_edit_skinShort_flexer;

  /// No description provided for @journeys_edit_skinColor_flexer_0.
  ///
  /// In vi, this message translates to:
  /// **'Lime neon'**
  String get journeys_edit_skinColor_flexer_0;

  /// No description provided for @journeys_edit_skinColor_flexer_1.
  ///
  /// In vi, this message translates to:
  /// **'San hô điện'**
  String get journeys_edit_skinColor_flexer_1;

  /// No description provided for @journeys_edit_skinColor_flexer_2.
  ///
  /// In vi, this message translates to:
  /// **'Băng'**
  String get journeys_edit_skinColor_flexer_2;

  /// No description provided for @journeys_edit_skinShort_minimal.
  ///
  /// In vi, this message translates to:
  /// **'Tối giản'**
  String get journeys_edit_skinShort_minimal;

  /// No description provided for @journeys_edit_skinColor_minimal_0.
  ///
  /// In vi, this message translates to:
  /// **'Cam'**
  String get journeys_edit_skinColor_minimal_0;

  /// No description provided for @journeys_edit_skinColor_minimal_1.
  ///
  /// In vi, this message translates to:
  /// **'Than'**
  String get journeys_edit_skinColor_minimal_1;

  /// No description provided for @journeys_edit_skinColor_minimal_2.
  ///
  /// In vi, this message translates to:
  /// **'Trời'**
  String get journeys_edit_skinColor_minimal_2;

  /// No description provided for @journeys_edit_trophy.
  ///
  /// In vi, this message translates to:
  /// **'Tên chiếc cúp'**
  String get journeys_edit_trophy;

  /// No description provided for @journeys_edit_film.
  ///
  /// In vi, this message translates to:
  /// **'Cuộn phim'**
  String get journeys_edit_film;

  /// No description provided for @journeys_edit_filmReadonly.
  ///
  /// In vi, this message translates to:
  /// **'{n} · chỉ xem'**
  String journeys_edit_filmReadonly(int n);

  /// No description provided for @journeys_edit_couple.
  ///
  /// In vi, this message translates to:
  /// **'Hai đứa mình'**
  String get journeys_edit_couple;

  /// No description provided for @journeys_edit_hud.
  ///
  /// In vi, this message translates to:
  /// **'Kiểu HUD'**
  String get journeys_edit_hud;

  /// No description provided for @journeys_edit_hudBold.
  ///
  /// In vi, this message translates to:
  /// **'Đậm'**
  String get journeys_edit_hudBold;

  /// No description provided for @journeys_edit_hudStamp.
  ///
  /// In vi, this message translates to:
  /// **'Dấu tối giản'**
  String get journeys_edit_hudStamp;

  /// No description provided for @journeys_edit_hudStrip.
  ///
  /// In vi, this message translates to:
  /// **'Dải phim'**
  String get journeys_edit_hudStrip;

  /// No description provided for @journeys_edit_reminder.
  ///
  /// In vi, this message translates to:
  /// **'Giờ nhắc'**
  String get journeys_edit_reminder;

  /// No description provided for @journeys_edit_reminderHour.
  ///
  /// In vi, this message translates to:
  /// **'Giờ'**
  String get journeys_edit_reminderHour;

  /// No description provided for @journeys_edit_reminderMinute.
  ///
  /// In vi, this message translates to:
  /// **'Phút'**
  String get journeys_edit_reminderMinute;

  /// No description provided for @journeys_edit_visibility.
  ///
  /// In vi, this message translates to:
  /// **'Ai được xem'**
  String get journeys_edit_visibility;

  /// No description provided for @journeys_edit_visPrivate.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ mình tôi'**
  String get journeys_edit_visPrivate;

  /// No description provided for @journeys_edit_visLink.
  ///
  /// In vi, this message translates to:
  /// **'Có link xem (thu hồi được)'**
  String get journeys_edit_visLink;

  /// No description provided for @journeys_edit_visQuietNote.
  ///
  /// In vi, this message translates to:
  /// **'Trang xem luôn ẩn số kg và làm mờ ảnh theo mặc định.'**
  String get journeys_edit_visQuietNote;

  /// No description provided for @journeys_edit_membersOnly.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ thành viên'**
  String get journeys_edit_membersOnly;

  /// No description provided for @journeys_edit_membersOnlyHint.
  ///
  /// In vi, this message translates to:
  /// **'có thể tạo link công khai khi hành trình kết thúc và được thành viên đồng ý'**
  String get journeys_edit_membersOnlyHint;

  /// No description provided for @journeys_edit_quietLock.
  ///
  /// In vi, this message translates to:
  /// **'Riêng tư'**
  String get journeys_edit_quietLock;

  /// No description provided for @journeys_edit_endTitle.
  ///
  /// In vi, this message translates to:
  /// **'Kết thúc hành trình?'**
  String get journeys_edit_endTitle;

  /// No description provided for @journeys_edit_endBody.
  ///
  /// In vi, this message translates to:
  /// **'Bạn vẫn xem lại được, nhưng không chụp thêm.'**
  String get journeys_edit_endBody;

  /// No description provided for @journeys_edit_endConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Kết thúc'**
  String get journeys_edit_endConfirm;

  /// No description provided for @journeys_edit_saved.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu.'**
  String get journeys_edit_saved;

  /// No description provided for @journeys_edit_ownerOnly.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ chủ hành trình mới sửa được.'**
  String get journeys_edit_ownerOnly;

  /// No description provided for @journeys_edit_menu.
  ///
  /// In vi, this message translates to:
  /// **'Sửa hành trình'**
  String get journeys_edit_menu;

  /// No description provided for @journeys_wrapped_title.
  ///
  /// In vi, this message translates to:
  /// **'Hành trình đã về đích'**
  String get journeys_wrapped_title;

  /// No description provided for @journeys_wrapped_close.
  ///
  /// In vi, this message translates to:
  /// **'Đóng'**
  String get journeys_wrapped_close;

  /// No description provided for @journeys_wrapped_step.
  ///
  /// In vi, this message translates to:
  /// **'Bước {n}'**
  String journeys_wrapped_step(int n);

  /// No description provided for @journeys_wrapped_moments.
  ///
  /// In vi, this message translates to:
  /// **'{moments} khoảnh khắc trong {days} ngày'**
  String journeys_wrapped_moments(int moments, int days);

  /// No description provided for @journeys_wrapped_streak.
  ///
  /// In vi, this message translates to:
  /// **'Chuỗi {n} ngày'**
  String journeys_wrapped_streak(int n);

  /// No description provided for @journeys_wrapped_quietEnd.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã về đích.'**
  String get journeys_wrapped_quietEnd;

  /// No description provided for @journeys_wrapped_checkIns.
  ///
  /// In vi, this message translates to:
  /// **'{n} lần điểm danh'**
  String journeys_wrapped_checkIns(int n);

  /// No description provided for @journeys_wrapped_squadEnd.
  ///
  /// In vi, this message translates to:
  /// **'Về đích rồi, cả nhóm!'**
  String get journeys_wrapped_squadEnd;

  /// No description provided for @journeys_wrapped_frames.
  ///
  /// In vi, this message translates to:
  /// **'{n} khung hình'**
  String journeys_wrapped_frames(int n);

  /// No description provided for @journeys_wrapped_daysTogether.
  ///
  /// In vi, this message translates to:
  /// **'{n} ngày bên nhau'**
  String journeys_wrapped_daysTogether(int n);

  /// No description provided for @journeys_wrapped_coupleFallback.
  ///
  /// In vi, this message translates to:
  /// **'Khoảnh khắc đáng nhớ nhất'**
  String get journeys_wrapped_coupleFallback;

  /// No description provided for @journeys_wrapped_km.
  ///
  /// In vi, this message translates to:
  /// **'{km} KM'**
  String journeys_wrapped_km(String km);

  /// No description provided for @journeys_wrapped_pace.
  ///
  /// In vi, this message translates to:
  /// **'NHỊP ĐỘ {pace}'**
  String journeys_wrapped_pace(String pace);

  /// No description provided for @journeys_wrapped_flexStreak.
  ///
  /// In vi, this message translates to:
  /// **'CHUỖI {n}.'**
  String journeys_wrapped_flexStreak(int n);

  /// No description provided for @journeys_wrapped_minimalLine.
  ///
  /// In vi, this message translates to:
  /// **'{done}/{total} NGÀY · {name}'**
  String journeys_wrapped_minimalLine(int done, int total, String name);

  /// No description provided for @journeys_wrapped_memoryEnd.
  ///
  /// In vi, this message translates to:
  /// **'Cuộn phim đã hết. Mang đi in thôi.'**
  String get journeys_wrapped_memoryEnd;

  /// No description provided for @journeys_wrapped_sumQuiet.
  ///
  /// In vi, this message translates to:
  /// **'NGÀY 01 vs NGÀY {total}'**
  String journeys_wrapped_sumQuiet(int total);

  /// No description provided for @journeys_wrapped_sumSquad.
  ///
  /// In vi, this message translates to:
  /// **'{done}/{total} ĐÃ VỀ ĐÍCH'**
  String journeys_wrapped_sumSquad(int done, int total);

  /// No description provided for @journeys_wrapped_sumMemory.
  ///
  /// In vi, this message translates to:
  /// **'{total} NGÀY · {name}'**
  String journeys_wrapped_sumMemory(int total, String name);

  /// No description provided for @journeys_wrapped_sumCouple.
  ///
  /// In vi, this message translates to:
  /// **'{total} NGÀY BÊN NHAU · {moments} KHOẢNH KHẮC'**
  String journeys_wrapped_sumCouple(int total, int moments);

  /// No description provided for @journeys_wrapped_sumFlexer.
  ///
  /// In vi, this message translates to:
  /// **'{total} NGÀY · {km} KM'**
  String journeys_wrapped_sumFlexer(int total, String km);

  /// No description provided for @journeys_wrapped_sumMinimal.
  ///
  /// In vi, this message translates to:
  /// **'{done}/{total} NGÀY · {pct}% ĐỀU ĐẶN'**
  String journeys_wrapped_sumMinimal(int done, int total, int pct);

  /// No description provided for @journeys_wrapped_hideKg.
  ///
  /// In vi, this message translates to:
  /// **'Ẩn số kg'**
  String get journeys_wrapped_hideKg;

  /// No description provided for @journeys_wrapped_blur.
  ///
  /// In vi, this message translates to:
  /// **'Làm mờ ảnh'**
  String get journeys_wrapped_blur;

  /// No description provided for @journeys_wrapped_on.
  ///
  /// In vi, this message translates to:
  /// **'Bật'**
  String get journeys_wrapped_on;

  /// No description provided for @journeys_wrapped_off.
  ///
  /// In vi, this message translates to:
  /// **'Tắt'**
  String get journeys_wrapped_off;

  /// No description provided for @journeys_wrapped_ctaPoster.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ poster chuyến đi'**
  String get journeys_wrapped_ctaPoster;

  /// No description provided for @journeys_wrapped_ctaStory.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ câu chuyện'**
  String get journeys_wrapped_ctaStory;

  /// No description provided for @journeys_wrapped_ctaFlexer.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ lên Story'**
  String get journeys_wrapped_ctaFlexer;

  /// No description provided for @journeys_wrapped_ctaMinimal.
  ///
  /// In vi, this message translates to:
  /// **'Xuất thẻ'**
  String get journeys_wrapped_ctaMinimal;

  /// No description provided for @journeys_wrapped_ctaCard.
  ///
  /// In vi, this message translates to:
  /// **'Tạo thiệp'**
  String get journeys_wrapped_ctaCard;

  /// No description provided for @journeys_wrapped_share.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ'**
  String get journeys_wrapped_share;

  /// No description provided for @journeys_wrapped_editCard.
  ///
  /// In vi, this message translates to:
  /// **'Chỉnh thẻ'**
  String get journeys_wrapped_editCard;

  /// No description provided for @journeys_wrapped_sheetTitle.
  ///
  /// In vi, this message translates to:
  /// **'chia sẻ tấm thiệp.'**
  String get journeys_wrapped_sheetTitle;

  /// No description provided for @journeys_wrapped_hideBrand.
  ///
  /// In vi, this message translates to:
  /// **'Ẩn chữ ourney'**
  String get journeys_wrapped_hideBrand;

  /// No description provided for @journeys_wrapped_messages.
  ///
  /// In vi, this message translates to:
  /// **'Tin nhắn'**
  String get journeys_wrapped_messages;

  /// No description provided for @journeys_wrapped_otherApps.
  ///
  /// In vi, this message translates to:
  /// **'Ứng dụng khác'**
  String get journeys_wrapped_otherApps;

  /// No description provided for @journeys_wrapped_open.
  ///
  /// In vi, this message translates to:
  /// **'Xem hành trình đã về đích'**
  String get journeys_wrapped_open;

  /// No description provided for @journeys_wrapped_menu.
  ///
  /// In vi, this message translates to:
  /// **'Câu chuyện về đích'**
  String get journeys_wrapped_menu;

  /// No description provided for @journeys_home_squadChip.
  ///
  /// In vi, this message translates to:
  /// **'{title} · {days} NGÀY'**
  String journeys_home_squadChip(String title, int days);

  /// No description provided for @journeys_home_squadChipOpen.
  ///
  /// In vi, this message translates to:
  /// **'{title} · KHÔNG GIỚI HẠN'**
  String journeys_home_squadChipOpen(String title);

  /// No description provided for @journeys_home_squadToday.
  ///
  /// In vi, this message translates to:
  /// **'{done}/{total} HÔM NAY'**
  String journeys_home_squadToday(int done, int total);

  /// No description provided for @journeys_home_trophyDefault.
  ///
  /// In vi, this message translates to:
  /// **'CÚP'**
  String get journeys_home_trophyDefault;

  /// No description provided for @journeys_home_trophyDay.
  ///
  /// In vi, this message translates to:
  /// **'NGÀY {day}'**
  String journeys_home_trophyDay(int day);

  /// No description provided for @journeys_home_trophyOpen.
  ///
  /// In vi, this message translates to:
  /// **'KHÔNG GIỚI HẠN'**
  String get journeys_home_trophyOpen;

  /// No description provided for @journeys_home_filmRoll.
  ///
  /// In vi, this message translates to:
  /// **'CUỘN PHIM {frames}/{total}'**
  String journeys_home_filmRoll(int frames, int total);

  /// No description provided for @journeys_home_rollNote.
  ///
  /// In vi, this message translates to:
  /// **'Hết cuộn {total} tấm · mở cuộn mới'**
  String journeys_home_rollNote(int total);

  /// No description provided for @journeys_home_coupleLine.
  ///
  /// In vi, this message translates to:
  /// **'{total} NGÀY {ritual}'**
  String journeys_home_coupleLine(int total, String ritual);

  /// No description provided for @journeys_home_ritualCook.
  ///
  /// In vi, this message translates to:
  /// **'NẤU CHO NHAU'**
  String get journeys_home_ritualCook;

  /// No description provided for @journeys_home_ritualSave.
  ///
  /// In vi, this message translates to:
  /// **'TIẾT KIỆM CÙNG NHAU'**
  String get journeys_home_ritualSave;

  /// No description provided for @journeys_home_ritualLdr.
  ///
  /// In vi, this message translates to:
  /// **'XA MÀ GẦN'**
  String get journeys_home_ritualLdr;

  /// No description provided for @journeys_home_ritualOther.
  ///
  /// In vi, this message translates to:
  /// **'BÊN NHAU'**
  String get journeys_home_ritualOther;

  /// No description provided for @journeys_home_pairWaiting.
  ///
  /// In vi, this message translates to:
  /// **'đang chờ {name}'**
  String journeys_home_pairWaiting(String name);

  /// No description provided for @journeys_home_pairBoth.
  ///
  /// In vi, this message translates to:
  /// **'cả hai đã chụp hôm nay'**
  String get journeys_home_pairBoth;

  /// No description provided for @journeys_home_pairNeither.
  ///
  /// In vi, this message translates to:
  /// **'hôm nay chưa ai chụp'**
  String get journeys_home_pairNeither;

  /// No description provided for @journeys_home_flexSummary.
  ///
  /// In vi, this message translates to:
  /// **'{km} KM TỔNG · {pace} /KM NHỊP TB'**
  String journeys_home_flexSummary(String km, String pace);

  /// No description provided for @journeys_home_flexKmOnly.
  ///
  /// In vi, this message translates to:
  /// **'{km} KM TỔNG'**
  String journeys_home_flexKmOnly(String km);

  /// No description provided for @journeys_home_flexRan.
  ///
  /// In vi, this message translates to:
  /// **'{done}/{total} ĐÃ CHẠY'**
  String journeys_home_flexRan(int done, int total);

  /// No description provided for @journeys_home_flexTrained.
  ///
  /// In vi, this message translates to:
  /// **'{done}/{total} ĐÃ TẬP'**
  String journeys_home_flexTrained(int done, int total);

  /// No description provided for @journeys_home_minimalMonth.
  ///
  /// In vi, this message translates to:
  /// **'THÁNG {month} · CHUỖI {streak} NGÀY'**
  String journeys_home_minimalMonth(String month, int streak);

  /// No description provided for @journeys_home_minimalDone.
  ///
  /// In vi, this message translates to:
  /// **'{done}/{total} ĐÃ XONG'**
  String journeys_home_minimalDone(int done, int total);

  /// No description provided for @journeys_home_viewWrapped.
  ///
  /// In vi, this message translates to:
  /// **'Xem tổng kết'**
  String get journeys_home_viewWrapped;

  /// No description provided for @journeys_addMoreTag.
  ///
  /// In vi, this message translates to:
  /// **'Thêm ảnh'**
  String get journeys_addMoreTag;

  /// No description provided for @journeys_hubTitle.
  ///
  /// In vi, this message translates to:
  /// **'Ourney'**
  String get journeys_hubTitle;

  /// No description provided for @journeys_hubGreeting.
  ///
  /// In vi, this message translates to:
  /// **'chào {name}.'**
  String journeys_hubGreeting(String name);

  /// No description provided for @journeys_hubGreetingNoName.
  ///
  /// In vi, this message translates to:
  /// **'chào bạn.'**
  String get journeys_hubGreetingNoName;

  /// No description provided for @journeys_hubOffline.
  ///
  /// In vi, this message translates to:
  /// **'đang lưu trên máy, có mạng sẽ tự gửi'**
  String get journeys_hubOffline;

  /// No description provided for @journeys_hubResumeTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục tạo hành trình'**
  String get journeys_hubResumeTitle;

  /// No description provided for @journeys_hubResumeStep.
  ///
  /// In vi, this message translates to:
  /// **'bước {n}/5'**
  String journeys_hubResumeStep(int n);

  /// No description provided for @journeys_hubSection.
  ///
  /// In vi, this message translates to:
  /// **'hành trình của bạn.'**
  String get journeys_hubSection;

  /// No description provided for @journeys_hubRunning.
  ///
  /// In vi, this message translates to:
  /// **'{n} đang chạy'**
  String journeys_hubRunning(int n);

  /// No description provided for @journeys_hubNewTitle.
  ///
  /// In vi, this message translates to:
  /// **'hành trình mới.'**
  String get journeys_hubNewTitle;

  /// No description provided for @journeys_hubNewHint.
  ///
  /// In vi, this message translates to:
  /// **'chọn một thế giới để bắt đầu'**
  String get journeys_hubNewHint;

  /// No description provided for @journeys_hubEmptyTitle.
  ///
  /// In vi, this message translates to:
  /// **'chưa có hành trình nào.'**
  String get journeys_hubEmptyTitle;

  /// No description provided for @journeys_hubEmptyBody.
  ///
  /// In vi, this message translates to:
  /// **'một tấm mỗi ngày, giữ được cả chặng đường.'**
  String get journeys_hubEmptyBody;

  /// No description provided for @journeys_hubErrorTitle.
  ///
  /// In vi, this message translates to:
  /// **'không tải được. thử lại?'**
  String get journeys_hubErrorTitle;

  /// No description provided for @journeys_hubLoading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải'**
  String get journeys_hubLoading;

  /// No description provided for @journeys_createDeckCard.
  ///
  /// In vi, this message translates to:
  /// **'Thẻ {n} trên {total}, {name}'**
  String journeys_createDeckCard(int n, int total, String name);

  /// No description provided for @journeys_createDeckChosen.
  ///
  /// In vi, this message translates to:
  /// **'Đã chọn'**
  String get journeys_createDeckChosen;

  /// No description provided for @journeys_deckPrivate.
  ///
  /// In vi, this message translates to:
  /// **'Riêng tư'**
  String get journeys_deckPrivate;

  /// No description provided for @journeys_deckHudStudy.
  ///
  /// In vi, this message translates to:
  /// **'45 PHÚT'**
  String get journeys_deckHudStudy;

  /// No description provided for @journeys_deckHudFlexer.
  ///
  /// In vi, this message translates to:
  /// **'5,2 KM · 5:48'**
  String get journeys_deckHudFlexer;

  /// No description provided for @journeys_deckHudMemory.
  ///
  /// In vi, this message translates to:
  /// **'CUỘN PHIM 12/24'**
  String get journeys_deckHudMemory;

  /// No description provided for @journeys_deckHudCouple.
  ///
  /// In vi, this message translates to:
  /// **'hai nửa · một ngày'**
  String get journeys_deckHudCouple;

  /// No description provided for @journeys_createDeckPrev.
  ///
  /// In vi, this message translates to:
  /// **'Thẻ trước'**
  String get journeys_createDeckPrev;

  /// No description provided for @journeys_createDeckNext.
  ///
  /// In vi, this message translates to:
  /// **'Thẻ sau'**
  String get journeys_createDeckNext;

  /// No description provided for @journeys_createDeckCounter.
  ///
  /// In vi, this message translates to:
  /// **'{n}/{total}'**
  String journeys_createDeckCounter(int n, int total);

  /// No description provided for @journeys_createDeckChoose.
  ///
  /// In vi, this message translates to:
  /// **'Chọn kiểu này'**
  String get journeys_createDeckChoose;

  /// Streak chip spoken label on the journey card.
  ///
  /// In vi, this message translates to:
  /// **'Chuỗi {days} ngày'**
  String journeys_cardStreak(int days);

  /// Screen reader label of the Hub streak hero.
  ///
  /// In vi, this message translates to:
  /// **'Chuỗi {streak} ngày. {title}'**
  String journeys_heroSemantics(int streak, String title);

  /// Banner when check-in uploads were given up on.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{{count} ảnh chưa gửi được}}'**
  String journeys_deadUploads(int count);

  /// Retry the failed uploads.
  ///
  /// In vi, this message translates to:
  /// **'Gửi lại'**
  String get journeys_deadRetry;

  /// Discard the failed uploads and their local photos.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ ảnh'**
  String get journeys_deadDiscard;

  /// Non-fatal toast after creating a journey when the server rejected some create-flow settings.
  ///
  /// In vi, this message translates to:
  /// **'Một vài cài đặt chưa lưu được'**
  String get journeys_createSettingsNotSaved;

  /// Confirm sheet title before discarding failed uploads.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ ảnh chưa gửi được?'**
  String get journeys_deadDiscardTitle;

  /// Confirm sheet body: how many photos are deleted.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{{count} ảnh sẽ bị xóa khỏi máy này và không gửi lên được nữa. Không hoàn tác được.}}'**
  String journeys_deadDiscardBody(int count);

  /// No description provided for @journeys_timelineRecent.
  ///
  /// In vi, this message translates to:
  /// **'Gần đây'**
  String get journeys_timelineRecent;

  /// No description provided for @journeys_timelineByMonth.
  ///
  /// In vi, this message translates to:
  /// **'Theo tháng'**
  String get journeys_timelineByMonth;

  /// No description provided for @journeys_monthSummary.
  ///
  /// In vi, this message translates to:
  /// **'{checked}/{days} ngày · {photos} ảnh'**
  String journeys_monthSummary(int checked, int days, int photos);

  /// No description provided for @journeys_monthA11y.
  ///
  /// In vi, this message translates to:
  /// **'{month}, {checked} trên {days} ngày đã check-in, {photos} ảnh'**
  String journeys_monthA11y(String month, int checked, int days, int photos);

  /// No description provided for @journeys_monthExpandHint.
  ///
  /// In vi, this message translates to:
  /// **'Mở rộng'**
  String get journeys_monthExpandHint;

  /// No description provided for @journeys_monthCollapseHint.
  ///
  /// In vi, this message translates to:
  /// **'Thu gọn'**
  String get journeys_monthCollapseHint;

  /// No description provided for @journeys_jumpToMonth.
  ///
  /// In vi, this message translates to:
  /// **'Đi tới {month}'**
  String journeys_jumpToMonth(String month);

  /// No description provided for @journeys_jumpToYear.
  ///
  /// In vi, this message translates to:
  /// **'Xem năm {year}'**
  String journeys_jumpToYear(int year);

  /// No description provided for @journeys_jumpAnnounce.
  ///
  /// In vi, this message translates to:
  /// **'Đang ở {month}'**
  String journeys_jumpAnnounce(String month);

  /// No description provided for @journeys_earlierLink.
  ///
  /// In vi, this message translates to:
  /// **'Trước đó: ngày 1–{to}, {checked} ngày đã check-in'**
  String journeys_earlierLink(int to, int checked);

  /// No description provided for @journeys_earlierView.
  ///
  /// In vi, this message translates to:
  /// **'Xem'**
  String get journeys_earlierView;

  /// No description provided for @journeys_daysToGo.
  ///
  /// In vi, this message translates to:
  /// **'Còn {days} ngày · Đích là ngày {finish}'**
  String journeys_daysToGo(int days, int finish);

  /// No description provided for @journeys_range30.
  ///
  /// In vi, this message translates to:
  /// **'30 ngày'**
  String get journeys_range30;

  /// No description provided for @journeys_rangeAll.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get journeys_rangeAll;

  /// No description provided for @journeys_clearYear.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ lọc năm {year}'**
  String journeys_clearYear(int year);

  /// No description provided for @journeys_range30Pace.
  ///
  /// In vi, this message translates to:
  /// **'Ít số liệu trong 30 ngày, đang hiện số ngày check-in'**
  String get journeys_range30Pace;

  /// No description provided for @journeys_startsIn.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu sau {days} ngày · {total} ngày'**
  String journeys_startsIn(int days, int total);
}

class _JourneysL10nDelegate extends LocalizationsDelegate<JourneysL10n> {
  const _JourneysL10nDelegate();

  @override
  Future<JourneysL10n> load(Locale locale) {
    return SynchronousFuture<JourneysL10n>(lookupJourneysL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_JourneysL10nDelegate old) => false;
}

JourneysL10n lookupJourneysL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return JourneysL10nEn();
    case 'vi':
      return JourneysL10nVi();
  }

  throw FlutterError(
    'JourneysL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
