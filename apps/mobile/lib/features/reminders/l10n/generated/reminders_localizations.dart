import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'reminders_localizations_en.dart';
import 'reminders_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of RemindersL10n
/// returned by `RemindersL10n.of(context)`.
///
/// Applications need to include `RemindersL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/reminders_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: RemindersL10n.localizationsDelegates,
///   supportedLocales: RemindersL10n.supportedLocales,
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
/// be consistent with the languages listed in the RemindersL10n.supportedLocales
/// property.
abstract class RemindersL10n {
  RemindersL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static RemindersL10n of(BuildContext context) {
    return Localizations.of<RemindersL10n>(context, RemindersL10n)!;
  }

  static const LocalizationsDelegate<RemindersL10n> delegate =
      _RemindersL10nDelegate();

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

  /// Title of the reminders feature's main screen.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc nhở'**
  String get reminders_title;

  /// Short explanation at the top of the reminders screen.
  ///
  /// In vi, this message translates to:
  /// **'Chọn giờ nhắc cho từng hành trình. Ourney chỉ nhắc vào những ngày bạn chưa check-in.'**
  String get reminders_intro;

  /// Section header above the per-journey reminder list.
  ///
  /// In vi, this message translates to:
  /// **'Hành trình'**
  String get reminders_journeysHeader;

  /// Accessibility label of the on/off switch of one journey's reminder.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc cho {journey}'**
  String reminders_toggleLabel(String journey);

  /// Subtitle of a journey whose reminder is on.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc lúc {time} mỗi ngày'**
  String reminders_timeOn(String time);

  /// Subtitle of a journey whose reminder is off.
  ///
  /// In vi, this message translates to:
  /// **'Đang tắt'**
  String get reminders_timeOff;

  /// Button that opens the time picker; shows the current time.
  ///
  /// In vi, this message translates to:
  /// **'Đổi giờ nhắc ({time})'**
  String reminders_changeTime(String time);

  /// Help text at the top of the time picker dialog.
  ///
  /// In vi, this message translates to:
  /// **'Giờ nhắc check-in'**
  String get reminders_pickTimeHelp;

  /// Title of the switch for the 21:00 streak-about-to-break alert.
  ///
  /// In vi, this message translates to:
  /// **'Cảnh báo streak lúc 21:00'**
  String get reminders_streakAlertTitle;

  /// Subtitle of the streak alert switch.
  ///
  /// In vi, this message translates to:
  /// **'Nếu đến 21:00 bạn vẫn chưa check-in mà đang có streak.'**
  String get reminders_streakAlertSubtitle;

  /// Empty state title when there is no active journey.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có hành trình nào'**
  String get reminders_emptyTitle;

  /// Empty state message when there is no active journey.
  ///
  /// In vi, this message translates to:
  /// **'Tạo một hành trình rồi quay lại đây để đặt giờ nhắc.'**
  String get reminders_emptyMessage;

  /// Shown when the journeys could not be loaded.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được danh sách hành trình. Thử lại sau nhé.'**
  String get reminders_loadError;

  /// Retry button after a loading error.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get reminders_retry;

  /// Banner title when the OS notification permission is denied.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo đang tắt'**
  String get reminders_deniedTitle;

  /// Banner message when the OS notification permission is denied.
  ///
  /// In vi, this message translates to:
  /// **'Giờ nhắc vẫn được lưu, nhưng cần bật thông báo cho Ourney trong Cài đặt thì nhắc nhở mới hiện.'**
  String get reminders_deniedMessage;

  /// Button that opens the system notification settings.
  ///
  /// In vi, this message translates to:
  /// **'Mở Cài đặt'**
  String get reminders_openSettings;

  /// Title of the in-context dialog shown before the OS notification prompt.
  ///
  /// In vi, this message translates to:
  /// **'Bật thông báo nhé?'**
  String get reminders_permissionTitle;

  /// Body of the in-context dialog shown before the OS notification prompt.
  ///
  /// In vi, this message translates to:
  /// **'Ourney chỉ gửi những lời nhắc bạn đặt, và báo lúc 21:00 khi streak sắp mất. Không quảng cáo.'**
  String get reminders_permissionMessage;

  /// Button that continues to the OS notification prompt.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục'**
  String get reminders_permissionContinue;

  /// Button that dismisses the notification rationale dialog.
  ///
  /// In vi, this message translates to:
  /// **'Để sau'**
  String get reminders_permissionNotNow;

  /// Title of the daily reminder notification.
  ///
  /// In vi, this message translates to:
  /// **'Đến giờ check-in rồi'**
  String get reminders_notifTitle;

  /// Body of the daily reminder notification.
  ///
  /// In vi, this message translates to:
  /// **'{journey}: chụp một tấm cho hôm nay nào.'**
  String reminders_notifBody(String journey);

  /// Title of the 21:00 streak alert notification.
  ///
  /// In vi, this message translates to:
  /// **'Streak sắp mất'**
  String get reminders_alertTitle;

  /// Body of the 21:00 streak alert notification.
  ///
  /// In vi, this message translates to:
  /// **'{journey}: chuỗi {count} ngày sẽ mất lúc nửa đêm. Một tấm ảnh là giữ được.'**
  String reminders_alertBody(String journey, int count);

  /// Android notification channel name (shown in system settings).
  ///
  /// In vi, this message translates to:
  /// **'Nhắc check-in'**
  String get reminders_channelName;

  /// Android notification channel description.
  ///
  /// In vi, this message translates to:
  /// **'Lời nhắc check-in hằng ngày và cảnh báo streak sắp mất.'**
  String get reminders_channelDescription;
}

class _RemindersL10nDelegate extends LocalizationsDelegate<RemindersL10n> {
  const _RemindersL10nDelegate();

  @override
  Future<RemindersL10n> load(Locale locale) {
    return SynchronousFuture<RemindersL10n>(lookupRemindersL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_RemindersL10nDelegate old) => false;
}

RemindersL10n lookupRemindersL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return RemindersL10nEn();
    case 'vi':
      return RemindersL10nVi();
  }

  throw FlutterError(
    'RemindersL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
