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

  /// FR-B3: shown when the user already has 3 active journeys.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đang chạy 3 hành trình'**
  String get journeys_limitTitle;

  /// No description provided for @journeys_limitMessage.
  ///
  /// In vi, this message translates to:
  /// **'Mỗi người chạy tối đa 3 hành trình cùng lúc để việc đăng ảnh luôn nhẹ nhàng. Kết thúc một hành trình rồi bắt đầu cái mới nhé.'**
  String get journeys_limitMessage;

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

  /// No description provided for @journeys_errorVisibility.
  ///
  /// In vi, this message translates to:
  /// **'Kiểu hiển thị này không dùng được cho hành trình này.'**
  String get journeys_errorVisibility;

  /// No description provided for @journeys_errorNotAlone.
  ///
  /// In vi, this message translates to:
  /// **'Nhóm vẫn còn thành viên khác nên chưa xoá được. Bạn có thể kết thúc hành trình.'**
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

  /// No description provided for @journeys_delete.
  ///
  /// In vi, this message translates to:
  /// **'Xoá hành trình'**
  String get journeys_delete;

  /// No description provided for @journeys_deleteConfirmTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xoá hành trình?'**
  String get journeys_deleteConfirmTitle;

  /// No description provided for @journeys_deleteConfirmMessage.
  ///
  /// In vi, this message translates to:
  /// **'Mọi ảnh của bạn trong hành trình này sẽ bị xoá. Không hoàn tác được.'**
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
  /// **'Ngày {day}, {date}: bỏ lỡ'**
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
  /// **'Thêm ảnh'**
  String get journeys_addMore;

  /// Short visible label of the current-streak stat column.
  ///
  /// In vi, this message translates to:
  /// **'Hiện tại'**
  String get journeys_statCurrentShort;
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
