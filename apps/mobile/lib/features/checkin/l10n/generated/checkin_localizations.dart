import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'checkin_localizations_en.dart';
import 'checkin_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of CheckinL10n
/// returned by `CheckinL10n.of(context)`.
///
/// Applications need to include `CheckinL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/checkin_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: CheckinL10n.localizationsDelegates,
///   supportedLocales: CheckinL10n.supportedLocales,
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
/// be consistent with the languages listed in the CheckinL10n.supportedLocales
/// property.
abstract class CheckinL10n {
  CheckinL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static CheckinL10n of(BuildContext context) {
    return Localizations.of<CheckinL10n>(context, CheckinL10n)!;
  }

  static const LocalizationsDelegate<CheckinL10n> delegate =
      _CheckinL10nDelegate();

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

  /// Title of the checkin feature's main screen.
  ///
  /// In vi, this message translates to:
  /// **'Check-in'**
  String get checkin_title;

  /// Screen reader label of the photo preview.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh check-in vừa chụp'**
  String get checkin_photoSemantics;

  /// Badge on a check-in whose photo was picked from the library instead of taken live (FR-C3).
  ///
  /// In vi, this message translates to:
  /// **'Từ thư viện'**
  String get checkin_fromLibrary;

  /// No description provided for @checkin_captionLabel.
  ///
  /// In vi, this message translates to:
  /// **'Chú thích'**
  String get checkin_captionLabel;

  /// No description provided for @checkin_captionHint.
  ///
  /// In vi, this message translates to:
  /// **'Viết vài dòng (không bắt buộc)'**
  String get checkin_captionHint;

  /// Caption length counter (FR-C4, max 140).
  ///
  /// In vi, this message translates to:
  /// **'{count}/{max}'**
  String checkin_captionCounter(int count, int max);

  /// No description provided for @checkin_captionCounterSemantics.
  ///
  /// In vi, this message translates to:
  /// **'Đã nhập {count} trên {max} ký tự'**
  String checkin_captionCounterSemantics(int count, int max);

  /// No description provided for @checkin_metricInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Nhập một số hợp lệ'**
  String get checkin_metricInvalid;

  /// Shown under the metric field when the member hides metric values from others (weight-loss default, FR-B7).
  ///
  /// In vi, this message translates to:
  /// **'Chỉ mình bạn thấy số này'**
  String get checkin_metricPrivate;

  /// Primary button that posts the check-in (FR-C4).
  ///
  /// In vi, this message translates to:
  /// **'Đăng'**
  String get checkin_post;

  /// No description provided for @checkin_posting.
  ///
  /// In vi, this message translates to:
  /// **'Đang đăng…'**
  String get checkin_posting;

  /// Confirmation when a check-in already exists today for this journey (FR-C7).
  ///
  /// In vi, this message translates to:
  /// **'Thay ảnh hôm nay?'**
  String get checkin_replaceTitle;

  /// No description provided for @checkin_replaceMessage.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay bạn đã check-in cho hành trình này. Ảnh mới sẽ thay ảnh cũ.'**
  String get checkin_replaceMessage;

  /// No description provided for @checkin_replaceConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Thay ảnh'**
  String get checkin_replaceConfirm;

  /// No description provided for @checkin_errorPhoto.
  ///
  /// In vi, this message translates to:
  /// **'Không xử lý được ảnh này. Thử ảnh khác nhé.'**
  String get checkin_errorPhoto;

  /// No description provided for @checkin_errorEnded.
  ///
  /// In vi, this message translates to:
  /// **'Hành trình đã kết thúc nên không check-in thêm được.'**
  String get checkin_errorEnded;

  /// No description provided for @checkin_missingPhoto.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy ảnh. Quay lại và chụp lại nhé.'**
  String get checkin_missingPhoto;

  /// No description provided for @checkin_missingJourney.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy hành trình này.'**
  String get checkin_missingJourney;

  /// Text of the stamp shown after posting (FR-C8).
  ///
  /// In vi, this message translates to:
  /// **'Đã check-in!'**
  String get checkin_stamp;

  /// No description provided for @checkin_streakPlusOne.
  ///
  /// In vi, this message translates to:
  /// **'+1 ngày'**
  String get checkin_streakPlusOne;

  /// No description provided for @checkin_replaced.
  ///
  /// In vi, this message translates to:
  /// **'Đã thay ảnh hôm nay'**
  String get checkin_replaced;

  /// No description provided for @checkin_milestone7.
  ///
  /// In vi, this message translates to:
  /// **'7 ngày liên tục!'**
  String get checkin_milestone7;

  /// No description provided for @checkin_milestone30.
  ///
  /// In vi, this message translates to:
  /// **'30 ngày liên tục!'**
  String get checkin_milestone30;

  /// No description provided for @checkin_milestoneFinish.
  ///
  /// In vi, this message translates to:
  /// **'Về đích rồi!'**
  String get checkin_milestoneFinish;

  /// No description provided for @checkin_milestoneMessage.
  ///
  /// In vi, this message translates to:
  /// **'Khoe thành tích với bạn bè nhé.'**
  String get checkin_milestoneMessage;

  /// No description provided for @checkin_share.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ'**
  String get checkin_share;

  /// No description provided for @checkin_done.
  ///
  /// In vi, this message translates to:
  /// **'Xong'**
  String get checkin_done;

  /// Eyebrow of the success screen.
  ///
  /// In vi, this message translates to:
  /// **'Đã đăng khoảnh khắc'**
  String get checkin_posted;

  /// Headline of the success screen without a milestone.
  ///
  /// In vi, this message translates to:
  /// **'Giữ được chuỗi.'**
  String get checkin_chainKept;

  /// Unit after the big streak number.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{ngày}}'**
  String checkin_daysUnit(int count);

  /// Left action of the compose header: close and go back to the camera.
  ///
  /// In vi, this message translates to:
  /// **'Chụp lại'**
  String get checkin_retake;

  /// Privacy tag under the journey name on the compose screen: solo journey.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ mình bạn'**
  String get checkin_privacyPrivate;

  /// Privacy tag on the compose screen: journey shared with one partner.
  ///
  /// In vi, this message translates to:
  /// **'Cặp đôi'**
  String get checkin_privacyCouple;

  /// Privacy tag on the compose screen: group journey.
  ///
  /// In vi, this message translates to:
  /// **'Nhóm'**
  String get checkin_privacySquad;

  /// Rubber stamp on the Moment posted calendar with the day number of the journey.
  ///
  /// In vi, this message translates to:
  /// **'NGÀY {day}'**
  String checkin_dayStamp(int day);

  /// Semantics label of the mini calendar on the success screen.
  ///
  /// In vi, this message translates to:
  /// **'Lịch {days} ngày gần nhất, hôm nay có ảnh'**
  String checkin_calendarSemantics(int days);
}

class _CheckinL10nDelegate extends LocalizationsDelegate<CheckinL10n> {
  const _CheckinL10nDelegate();

  @override
  Future<CheckinL10n> load(Locale locale) {
    return SynchronousFuture<CheckinL10n>(lookupCheckinL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_CheckinL10nDelegate old) => false;
}

CheckinL10n lookupCheckinL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return CheckinL10nEn();
    case 'vi':
      return CheckinL10nVi();
  }

  throw FlutterError(
    'CheckinL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
