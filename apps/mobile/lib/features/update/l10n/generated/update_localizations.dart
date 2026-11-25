import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'update_localizations_en.dart';
import 'update_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of UpdateL10n
/// returned by `UpdateL10n.of(context)`.
///
/// Applications need to include `UpdateL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/update_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: UpdateL10n.localizationsDelegates,
///   supportedLocales: UpdateL10n.supportedLocales,
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
/// be consistent with the languages listed in the UpdateL10n.supportedLocales
/// property.
abstract class UpdateL10n {
  UpdateL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static UpdateL10n of(BuildContext context) {
    return Localizations.of<UpdateL10n>(context, UpdateL10n)!;
  }

  static const LocalizationsDelegate<UpdateL10n> delegate =
      _UpdateL10nDelegate();

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

  /// Title of the quiet inline update card on the Journeys hub.
  ///
  /// In vi, this message translates to:
  /// **'Có bản Ourney {version} mới'**
  String update_hubTitle(String version);

  /// Fallback subtitle on the Journeys hub update card when release notes are empty.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật nhẹ để trải nghiệm các cải tiến mới nhất khi bạn tiện.'**
  String get update_hubFallbackSub;

  /// Compact trailing action button on the Journeys hub update card.
  ///
  /// In vi, this message translates to:
  /// **'Xem'**
  String get update_hubAction;

  /// Accessibility label for the 48x48dp close button on the Journeys hub update card.
  ///
  /// In vi, this message translates to:
  /// **'Ẩn lời nhắc bản cập nhật này'**
  String get update_hubDismissLabel;

  /// Eyebrow label above the title in the soft update bottom sheet.
  ///
  /// In vi, this message translates to:
  /// **'BẢN MỚI · {version}'**
  String update_softEyebrow(String version);

  /// Heading in the soft update bottom sheet.
  ///
  /// In vi, this message translates to:
  /// **'Có bản Ourney {version} mới'**
  String update_softTitle(String version);

  /// Gentle autonomy-supportive subtitle in the soft update bottom sheet.
  ///
  /// In vi, this message translates to:
  /// **'Một vài điểm mới đã sẵn sàng cho hành trình của bạn. Bạn có thể cập nhật ngay hoặc để lúc khác.'**
  String get update_softSubtitle;

  /// Primary CTA button to download/open the update.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật ngay'**
  String get update_ctaUpdate;

  /// Secondary button to snooze the soft update sheet.
  ///
  /// In vi, this message translates to:
  /// **'Để sau'**
  String get update_ctaLater;

  /// Tertiary action to skip proactive prompts for this version.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ qua bản {version}'**
  String update_ctaSkipVersion(String version);

  /// Calm inline helper note shown on Android after tapping Update now.
  ///
  /// In vi, this message translates to:
  /// **'Tải xong, mở file Ourney.apk trên thanh thông báo để cài đè. Hành trình và ảnh của bạn vẫn giữ nguyên.'**
  String get update_androidInstallHint;

  /// Calm factual eyebrow on the forced update gate screen.
  ///
  /// In vi, this message translates to:
  /// **'CẬP NHẬT CẦN THIẾT · {version}'**
  String update_gateEyebrow(String version);

  /// Main heading on the forced update gate screen.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật Ourney để tiếp tục'**
  String get update_gateTitle;

  /// Body explanation on the forced update gate screen reassuring that local data stays intact.
  ///
  /// In vi, this message translates to:
  /// **'Bản {installed} trên máy cần nâng lên {latest} để đồng bộ an toàn với hệ thống mới. Mọi hành trình và ảnh đã chụp của bạn vẫn được giữ nguyên.'**
  String update_gateBody(String installed, String latest);

  /// Guidance shown on iOS when no external download URL is configured.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng cài bản Ourney {latest} mới nhất qua TestFlight hoặc công cụ cài đặt bạn đang dùng để tiếp tục.'**
  String update_gateIosManualHint(String latest);

  /// Toggle button to expand release notes on the forced update gate screen.
  ///
  /// In vi, this message translates to:
  /// **'Xem có gì mới ở bản {version}'**
  String update_gateWhatsNewToggle(String version);

  /// Offline notice banner on the forced update gate screen.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đang ngoại tuyến. Kết nối mạng để tải bản cập nhật hoặc kiểm tra lại.'**
  String get update_gateOfflineNotice;

  /// Secondary button to re-check the version policy on the forced update gate screen.
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra lại'**
  String get update_ctaRetryCheck;

  /// Quiet footer action to contact support from the forced update gate screen.
  ///
  /// In vi, this message translates to:
  /// **'Cần hỗ trợ cài đặt?'**
  String get update_ctaContactSupport;

  /// Fallback message shown if launching the external update URL fails.
  ///
  /// In vi, this message translates to:
  /// **'Không mở được trình duyệt. Bạn có thể tải trực tiếp tại ourney.tech.'**
  String get update_launchFailed;

  /// Eyebrow in the post-upgrade What's New sheet.
  ///
  /// In vi, this message translates to:
  /// **'ĐÃ CẬP NHẬT · {version}'**
  String update_whatsNewEyebrow(String version);

  /// Heading in the post-upgrade What's New sheet.
  ///
  /// In vi, this message translates to:
  /// **'Có gì mới ở Ourney {version}'**
  String update_whatsNewTitle(String version);

  /// Primary dismiss button in the post-upgrade What's New sheet.
  ///
  /// In vi, this message translates to:
  /// **'Tuyệt vời'**
  String get update_whatsNewDone;
}

class _UpdateL10nDelegate extends LocalizationsDelegate<UpdateL10n> {
  const _UpdateL10nDelegate();

  @override
  Future<UpdateL10n> load(Locale locale) {
    return SynchronousFuture<UpdateL10n>(lookupUpdateL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_UpdateL10nDelegate old) => false;
}

UpdateL10n lookupUpdateL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return UpdateL10nEn();
    case 'vi':
      return UpdateL10nVi();
  }

  throw FlutterError(
    'UpdateL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
