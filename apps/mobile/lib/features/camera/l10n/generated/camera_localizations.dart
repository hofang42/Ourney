import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'camera_localizations_en.dart';
import 'camera_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of CameraL10n
/// returned by `CameraL10n.of(context)`.
///
/// Applications need to include `CameraL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/camera_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: CameraL10n.localizationsDelegates,
///   supportedLocales: CameraL10n.supportedLocales,
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
/// be consistent with the languages listed in the CameraL10n.supportedLocales
/// property.
abstract class CameraL10n {
  CameraL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static CameraL10n of(BuildContext context) {
    return Localizations.of<CameraL10n>(context, CameraL10n)!;
  }

  static const LocalizationsDelegate<CameraL10n> delegate =
      _CameraL10nDelegate();

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

  /// Title of the camera feature's main screen.
  ///
  /// In vi, this message translates to:
  /// **'Chụp check-in'**
  String get camera_title;

  /// VoiceOver/TalkBack label of the big shutter button (NFR-5).
  ///
  /// In vi, this message translates to:
  /// **'Chụp ảnh check-in'**
  String get camera_shutter;

  /// Shutter button label naming the selected journey.
  ///
  /// In vi, this message translates to:
  /// **'Chụp ảnh check-in cho {journey}'**
  String camera_shutterFor(String journey);

  /// Flash toggle, current state off. Tap cycles off, auto, on.
  ///
  /// In vi, this message translates to:
  /// **'Đèn flash: tắt'**
  String get camera_flashOff;

  /// No description provided for @camera_flashAuto.
  ///
  /// In vi, this message translates to:
  /// **'Đèn flash: tự động'**
  String get camera_flashAuto;

  /// No description provided for @camera_flashOn.
  ///
  /// In vi, this message translates to:
  /// **'Đèn flash: bật'**
  String get camera_flashOn;

  /// Button that switches between the front and back camera.
  ///
  /// In vi, this message translates to:
  /// **'Đổi camera trước/sau'**
  String get camera_switchLens;

  /// Button that picks a photo from the library. The check-in is then labelled 'from library' (FR-C3).
  ///
  /// In vi, this message translates to:
  /// **'Chọn ảnh từ thư viện'**
  String get camera_gallery;

  /// Semantics label of the journey chip row.
  ///
  /// In vi, this message translates to:
  /// **'Chọn hành trình'**
  String get camera_journeyPicker;

  /// No description provided for @camera_journeysError.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được hành trình'**
  String get camera_journeysError;

  /// Empty state on the camera when the user has no active journey.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu hành trình đầu tiên'**
  String get camera_noJourneyTitle;

  /// No description provided for @camera_noJourneyMessage.
  ///
  /// In vi, this message translates to:
  /// **'Tạo một hành trình, rồi mỗi ngày chụp một tấm để giữ chuỗi.'**
  String get camera_noJourneyMessage;

  /// No description provided for @camera_noJourneyAction.
  ///
  /// In vi, this message translates to:
  /// **'Tạo hành trình'**
  String get camera_noJourneyAction;

  /// Friendly pre-prompt shown before the OS camera permission dialog.
  ///
  /// In vi, this message translates to:
  /// **'Mỗi ngày một tấm ảnh'**
  String get camera_prePromptTitle;

  /// No description provided for @camera_prePromptMessage.
  ///
  /// In vi, this message translates to:
  /// **'Ourney cần camera để bạn chụp ảnh check-in. Ảnh chỉ được đăng khi bạn bấm Đăng.'**
  String get camera_prePromptMessage;

  /// No description provided for @camera_prePromptAction.
  ///
  /// In vi, this message translates to:
  /// **'Cho phép camera'**
  String get camera_prePromptAction;

  /// No description provided for @camera_deniedTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có quyền camera'**
  String get camera_deniedTitle;

  /// No description provided for @camera_deniedMessage.
  ///
  /// In vi, this message translates to:
  /// **'Bật quyền camera để chụp check-in. Bạn vẫn có thể chọn ảnh từ thư viện.'**
  String get camera_deniedMessage;

  /// Shown on Android, where the app cannot open its Settings page directly.
  ///
  /// In vi, this message translates to:
  /// **'Vào Cài đặt › Ứng dụng › Ourney › Quyền › Camera, bật lên rồi quay lại.'**
  String get camera_deniedSettingsPath;

  /// No description provided for @camera_openSettings.
  ///
  /// In vi, this message translates to:
  /// **'Mở Cài đặt'**
  String get camera_openSettings;

  /// No description provided for @camera_restrictedMessage.
  ///
  /// In vi, this message translates to:
  /// **'Camera đang bị giới hạn trên máy này. Bạn vẫn có thể chọn ảnh từ thư viện.'**
  String get camera_restrictedMessage;

  /// No description provided for @camera_unavailableTitle.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy camera'**
  String get camera_unavailableTitle;

  /// No description provided for @camera_unavailableMessage.
  ///
  /// In vi, this message translates to:
  /// **'Máy này không có camera dùng được. Hãy chọn ảnh từ thư viện.'**
  String get camera_unavailableMessage;

  /// No description provided for @camera_failedTitle.
  ///
  /// In vi, this message translates to:
  /// **'Camera chưa mở được'**
  String get camera_failedTitle;

  /// No description provided for @camera_starting.
  ///
  /// In vi, this message translates to:
  /// **'Đang mở camera…'**
  String get camera_starting;

  /// No description provided for @camera_captureFailed.
  ///
  /// In vi, this message translates to:
  /// **'Chụp chưa được. Thử lại nhé.'**
  String get camera_captureFailed;

  /// Tooltip of the button that toggles the 3x3 framing grid over the viewfinder.
  ///
  /// In vi, this message translates to:
  /// **'Lưới căn khung'**
  String get camera_grid;

  /// Pill on the viewfinder showing the day number of the selected journey.
  ///
  /// In vi, this message translates to:
  /// **'Ngày {day}'**
  String camera_dayHud(int day);

  /// Hint at the bottom of the viewfinder when there is more than one journey.
  ///
  /// In vi, this message translates to:
  /// **'Vuốt để sang hành trình khác'**
  String get camera_swipeHint;

  /// Semantics label of the streak counter chip at the top of the camera.
  ///
  /// In vi, this message translates to:
  /// **'Chuỗi {days} ngày'**
  String camera_streakChip(int days);
}

class _CameraL10nDelegate extends LocalizationsDelegate<CameraL10n> {
  const _CameraL10nDelegate();

  @override
  Future<CameraL10n> load(Locale locale) {
    return SynchronousFuture<CameraL10n>(lookupCameraL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_CameraL10nDelegate old) => false;
}

CameraL10n lookupCameraL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return CameraL10nEn();
    case 'vi':
      return CameraL10nVi();
  }

  throw FlutterError(
    'CameraL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
