import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'widgets_localizations_en.dart';
import 'widgets_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of WidgetsL10n
/// returned by `WidgetsL10n.of(context)`.
///
/// Applications need to include `WidgetsL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/widgets_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: WidgetsL10n.localizationsDelegates,
///   supportedLocales: WidgetsL10n.supportedLocales,
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
/// be consistent with the languages listed in the WidgetsL10n.supportedLocales
/// property.
abstract class WidgetsL10n {
  WidgetsL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static WidgetsL10n of(BuildContext context) {
    return Localizations.of<WidgetsL10n>(context, WidgetsL10n)!;
  }

  static const LocalizationsDelegate<WidgetsL10n> delegate =
      _WidgetsL10nDelegate();

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

  /// Title of the Widgets & Live Activities screen.
  ///
  /// In vi, this message translates to:
  /// **'tiện ích.'**
  String get widgets_title;

  /// Back button tooltip on the Widgets screen.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại'**
  String get widgets_back;

  /// Introductory paragraph at the top of the Widgets screen.
  ///
  /// In vi, this message translates to:
  /// **'Đặt chuỗi ngày, mục tiêu hôm nay và tiến độ nhóm ngay trên Màn hình chính hoặc Màn hình khóa. Số cân nặng (kg) và mục tiêu riêng tư không bao giờ xuất hiện trên tiện ích.'**
  String get widgets_intro;

  /// Notice on iOS when the app installation lacks a shared widget data container.
  ///
  /// In vi, this message translates to:
  /// **'Bản cài này chưa cho widget đọc dữ liệu. Widget sẽ hoạt động ở bản TestFlight/App Store hoặc khi cài qua AltStore/SideStore.'**
  String get widgets_appGroupUnavailable;

  /// Heading for the collapsible iOS widget diagnostics panel.
  ///
  /// In vi, this message translates to:
  /// **'Chẩn đoán tiện ích'**
  String get widgets_diagnosticsTitle;

  /// Shown when the iOS widget diagnostics log is empty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa ghi nhận sự kiện nào của tiện ích.'**
  String get widgets_diagnosticsEmpty;

  /// Button to copy the widget diagnostics log.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép nhật ký'**
  String get widgets_diagnosticsCopy;

  /// Confirmation after copying the widget diagnostics log.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép nhật ký tiện ích'**
  String get widgets_diagnosticsCopied;

  /// Toast shown when hidden widget diagnostics mode is unlocked.
  ///
  /// In vi, this message translates to:
  /// **'Đã bật chế độ chẩn đoán'**
  String get widgets_diagnosticsUnlocked;

  /// Section heading for the interactive widget preview gallery.
  ///
  /// In vi, this message translates to:
  /// **'xem trước tiện ích'**
  String get widgets_secPreview;

  /// Preview tab for the Today Check-In widget.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay'**
  String get widgets_tabToday;

  /// Preview tab for the Streak Sticker widget.
  ///
  /// In vi, this message translates to:
  /// **'Chuỗi'**
  String get widgets_tabStreak;

  /// Preview tab for the Squad Today widget.
  ///
  /// In vi, this message translates to:
  /// **'Đồng đội'**
  String get widgets_tabSquad;

  /// Fallback sample journey title shown in preview when the user has no active journeys.
  ///
  /// In vi, this message translates to:
  /// **'Tự học IELTS 30 ngày'**
  String get widgets_previewSampleTitle;

  /// Badge shown in widget preview when displaying sample data instead of a real journey.
  ///
  /// In vi, this message translates to:
  /// **'Xem trước mẫu'**
  String get widgets_previewSampleBadge;

  /// Label for the current user in the Squad widget preview.
  ///
  /// In vi, this message translates to:
  /// **'Bạn'**
  String get widgets_previewYou;

  /// Day N of M badge in widget preview.
  ///
  /// In vi, this message translates to:
  /// **'Ngày {day}/{total}'**
  String widgets_previewDayOf(int day, int total);

  /// Day N badge for open-ended journeys in widget preview.
  ///
  /// In vi, this message translates to:
  /// **'Ngày {day}'**
  String widgets_previewDayOpen(int day);

  /// Streak count subtitle in widget preview.
  ///
  /// In vi, this message translates to:
  /// **'{count} ngày liên tiếp'**
  String widgets_previewStreakDays(int count);

  /// Primary CTA button label inside the widget preview.
  ///
  /// In vi, this message translates to:
  /// **'Chụp ngay'**
  String get widgets_previewSnapCta;

  /// Badge shown in widget preview when today's check-in is complete.
  ///
  /// In vi, this message translates to:
  /// **'Đã chụp hôm nay'**
  String get widgets_previewDoneBadge;

  /// Urgent badge shown in widget preview when streak is at risk.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay vẫn còn kịp'**
  String get widgets_previewAtRiskBadge;

  /// Status badge in widget preview when today is still pending.
  ///
  /// In vi, this message translates to:
  /// **'Chưa chụp hôm nay'**
  String get widgets_previewPendingBadge;

  /// Squad progress line in Squad widget preview.
  ///
  /// In vi, this message translates to:
  /// **'{done}/{total} đã check-in hôm nay'**
  String widgets_previewSquadCount(int done, int total);

  /// Placeholder text when photoMode is off.
  ///
  /// In vi, this message translates to:
  /// **'Đã ẩn ảnh trên tiện ích'**
  String get widgets_previewPhotoHiddenNote;

  /// Badge text when photoMode blurs thumbnails.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh được làm mờ tự động'**
  String get widgets_previewPhotoBlurredNote;

  /// Badge text when photoMode shows clear thumbnails.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh hiển thị rõ trên Màn hình chính'**
  String get widgets_previewPhotoClearNote;

  /// Section heading for widget privacy controls.
  ///
  /// In vi, this message translates to:
  /// **'riêng tư & hiển thị'**
  String get widgets_secPrivacy;

  /// Eyebrow label above the 4-way photo privacy selector.
  ///
  /// In vi, this message translates to:
  /// **'ẢNH TRÊN TIỆN ÍCH MÀN HÌNH CHÍNH'**
  String get widgets_photoModeEyebrow;

  /// Smart photo mode segment.
  ///
  /// In vi, this message translates to:
  /// **'Thông minh'**
  String get widgets_photoModeSmart;

  /// Blurred photo mode segment.
  ///
  /// In vi, this message translates to:
  /// **'Làm mờ'**
  String get widgets_photoModeBlurred;

  /// No-photo mode segment.
  ///
  /// In vi, this message translates to:
  /// **'Ẩn ảnh'**
  String get widgets_photoModeOff;

  /// Clear photo mode segment.
  ///
  /// In vi, this message translates to:
  /// **'Rõ nét'**
  String get widgets_photoModeClear;

  /// Explanation of Smart photo mode.
  ///
  /// In vi, this message translates to:
  /// **'Tự động làm mờ ảnh hành trình giảm cân và chỉ hiện ảnh đại diện trong tiện ích nhóm. Số kg không bao giờ xuất hiện.'**
  String get widgets_photoModeSmartNote;

  /// Explanation of Blurred photo mode.
  ///
  /// In vi, this message translates to:
  /// **'Mọi ảnh check-in trên tiện ích Màn hình chính đều được làm mờ trước khi lưu. Số kg không bao giờ xuất hiện.'**
  String get widgets_photoModeBlurredNote;

  /// Explanation of Off photo mode.
  ///
  /// In vi, this message translates to:
  /// **'Không hiển thị bất kỳ ảnh nào trên tiện ích; chỉ hiện biểu tượng sticker, chuỗi ngày và chữ cái đại diện.'**
  String get widgets_photoModeOffNote;

  /// Explanation of Clear photo mode.
  ///
  /// In vi, this message translates to:
  /// **'Hiển thị ảnh check-in rõ nét trên Màn hình chính khi đã mở khóa máy. Màn hình khóa vẫn không bao giờ hiện ảnh hay số kg.'**
  String get widgets_photoModeClearNote;

  /// Switch label for redacting journey titles on the Lock Screen.
  ///
  /// In vi, this message translates to:
  /// **'Ẩn tên hành trình trên Màn hình khóa'**
  String get widgets_redactTitlesLabel;

  /// Switch subtitle for redacting journey titles on the Lock Screen (iOS).
  ///
  /// In vi, this message translates to:
  /// **'Trên Màn hình khóa, tiện ích khóa và Live Activity chỉ hiện \"Ourney\" thay vì tên hành trình cụ thể.'**
  String get widgets_redactTitlesSub;

  /// Switch subtitle for redacting journey titles on the Lock Screen (Android).
  ///
  /// In vi, this message translates to:
  /// **'Trên Màn hình khóa, cập nhật trực tiếp chỉ hiện \"Ourney\" thay vì tên hành trình cụ thể.'**
  String get widgets_redactTitlesSubAndroid;

  /// Section heading for Check-In Window Live Activity / Live Update.
  ///
  /// In vi, this message translates to:
  /// **'khung giờ buổi tối'**
  String get widgets_secLiveActivity;

  /// Switch label for enabling Live Activities (iOS).
  ///
  /// In vi, this message translates to:
  /// **'Live Activity & khung giờ chụp tối'**
  String get widgets_liveActivityLabel;

  /// Switch label for enabling Live Updates (Android).
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật trực tiếp & khung giờ thanh trạng thái'**
  String get widgets_liveActivityLabelAndroid;

  /// Switch subtitle for Live Activities (iOS).
  ///
  /// In vi, this message translates to:
  /// **'Hiện khung giờ chụp trên Dynamic Island / Màn hình khóa từ 30 phút trước giờ nhắc (hoặc từ 18:00 khi đang có chuỗi) và tự tắt ngay khi bạn chụp xong.'**
  String get widgets_liveActivitySub;

  /// Switch subtitle for Live Updates (Android).
  ///
  /// In vi, this message translates to:
  /// **'Hiện khung giờ chụp trên thanh trạng thái và Màn hình khóa từ 30 phút trước giờ nhắc (hoặc từ 18:00 khi đang có chuỗi) và tự tắt ngay khi bạn chụp xong.'**
  String get widgets_liveActivitySubAndroid;

  /// Section heading for the 3-step OS widget setup guide.
  ///
  /// In vi, this message translates to:
  /// **'cách thêm ra màn hình chính'**
  String get widgets_secSetup;

  /// Step 1 title of the widget setup instructions (iOS).
  ///
  /// In vi, this message translates to:
  /// **'1. Chạm và giữ Màn hình chính hoặc Màn hình khóa'**
  String get widgets_setupStep1Title;

  /// Step 1 title of the widget setup instructions (Android).
  ///
  /// In vi, this message translates to:
  /// **'1. Chạm và giữ Màn hình chính'**
  String get widgets_setupStep1TitleAndroid;

  /// Step 1 body of the widget setup instructions.
  ///
  /// In vi, this message translates to:
  /// **'Chạm giữ vùng trống đến khi các biểu tượng rung nhẹ, sau đó chọn Sửa hoặc Tiện ích (Widgets).'**
  String get widgets_setupStep1Body;

  /// Step 2 title of the widget setup instructions.
  ///
  /// In vi, this message translates to:
  /// **'2. Tìm Ourney trong thư viện tiện ích'**
  String get widgets_setupStep2Title;

  /// Step 2 body of the widget setup instructions.
  ///
  /// In vi, this message translates to:
  /// **'Chọn mẫu Hôm nay (2×2, 4×2, 4×4), Chuỗi sticker (2×2) hoặc Đồng đội (4×2, 4×4).'**
  String get widgets_setupStep2Body;

  /// Step 3 title of the widget setup instructions.
  ///
  /// In vi, this message translates to:
  /// **'3. Chạm \"Chụp ngay\" để mở thẳng máy ảnh'**
  String get widgets_setupStep3Title;

  /// Step 3 body of the widget setup instructions.
  ///
  /// In vi, this message translates to:
  /// **'Mỗi tiện ích mở thẳng máy ảnh của đúng hành trình đó. Muốn đổi hành trình, chạm nút Đổi ở góc trên tiện ích hoặc chọn ngay tại màn hình này.'**
  String get widgets_setupStep3Body;

  /// Section heading for placed Home Screen widgets on Android.
  ///
  /// In vi, this message translates to:
  /// **'tiện ích đang đặt'**
  String get widgets_secPlacedWidgets;

  /// Section heading for in-app widget journey pickers on iOS.
  ///
  /// In vi, this message translates to:
  /// **'đổi hành trình trên tiện ích'**
  String get widgets_secJourneyPicker;

  /// Helper text shown on Android when no widgets are currently placed on the Home Screen.
  ///
  /// In vi, this message translates to:
  /// **'Sau khi đặt tiện ích ra Màn hình chính, bạn có thể đổi hành trình cho từng ô ngay tại đây hoặc chạm nút Đổi ở góc trên phải tiện ích.'**
  String get widgets_placedEmptyNote;

  /// Label for a placed Today widget row.
  ///
  /// In vi, this message translates to:
  /// **'Ourney · Hôm nay'**
  String get widgets_placedTodayTitle;

  /// Label for a placed Streak widget row.
  ///
  /// In vi, this message translates to:
  /// **'Ourney · Chuỗi ngày'**
  String get widgets_placedStreakTitle;

  /// Label for a placed Squad widget row.
  ///
  /// In vi, this message translates to:
  /// **'Ourney · Đồng đội'**
  String get widgets_placedSquadTitle;

  /// iOS picker row title for Today and Streak widgets.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay & Chuỗi'**
  String get widgets_iosTodayStreakRowTitle;

  /// iOS picker row title for Squad and Couple widgets.
  ///
  /// In vi, this message translates to:
  /// **'Đồng đội & Cặp đôi'**
  String get widgets_iosSquadRowTitle;

  /// Title of the bottom sheet for selecting a widget journey.
  ///
  /// In vi, this message translates to:
  /// **'Đổi hành trình'**
  String get widgets_pickerSheetTodayTitle;

  /// Title of the bottom sheet for selecting a widget squad or couple journey.
  ///
  /// In vi, this message translates to:
  /// **'Đổi nhóm đồng đội'**
  String get widgets_pickerSheetSquadTitle;

  /// Subtitle inside the widget journey picker bottom sheet.
  ///
  /// In vi, this message translates to:
  /// **'Chọn hành trình hiển thị trên tiện ích này hoặc để Tự động.'**
  String get widgets_pickerSheetSubtitle;

  /// Automatic option title in the widget journey picker.
  ///
  /// In vi, this message translates to:
  /// **'Tự động'**
  String get widgets_autoOptionTitle;

  /// Automatic option subtitle for Today widgets.
  ///
  /// In vi, this message translates to:
  /// **'Ưu tiên hành trình cần chụp hôm nay'**
  String get widgets_autoTodaySubtitle;

  /// Automatic option subtitle for Streak widgets.
  ///
  /// In vi, this message translates to:
  /// **'Hiện hành trình có chuỗi ngày nổi bật nhất'**
  String get widgets_autoStreakSubtitle;

  /// Automatic option subtitle for Squad widgets.
  ///
  /// In vi, this message translates to:
  /// **'Hiện nhóm hoặc cặp đôi đang hoạt động'**
  String get widgets_autoSquadSubtitle;

  /// Short action pill label on widget rows.
  ///
  /// In vi, this message translates to:
  /// **'Đổi'**
  String get widgets_changeAction;
}

class _WidgetsL10nDelegate extends LocalizationsDelegate<WidgetsL10n> {
  const _WidgetsL10nDelegate();

  @override
  Future<WidgetsL10n> load(Locale locale) {
    return SynchronousFuture<WidgetsL10n>(lookupWidgetsL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_WidgetsL10nDelegate old) => false;
}

WidgetsL10n lookupWidgetsL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return WidgetsL10nEn();
    case 'vi':
      return WidgetsL10nVi();
  }

  throw FlutterError(
    'WidgetsL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
