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

  /// No description provided for @checkin_postMemory.
  ///
  /// In vi, this message translates to:
  /// **'Dán vào sổ'**
  String get checkin_postMemory;

  /// No description provided for @checkin_postMinimal.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ngay'**
  String get checkin_postMinimal;

  /// No description provided for @checkin_captionLabelMemory.
  ///
  /// In vi, this message translates to:
  /// **'Ghi lại một dòng'**
  String get checkin_captionLabelMemory;

  /// No description provided for @checkin_captionLabelFlexer.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay chạy thế nào?'**
  String get checkin_captionLabelFlexer;

  /// No description provided for @checkin_posting.
  ///
  /// In vi, this message translates to:
  /// **'Đang đăng…'**
  String get checkin_posting;

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

  /// Calm notice after an extra photo of a day that already counted (FR-C8). n >= 2.
  ///
  /// In vi, this message translates to:
  /// **'Đã thêm ảnh thứ {n}'**
  String checkin_photoAdded(int n);

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

  /// No description provided for @checkin_shareSkinMemory.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ poster chuyến đi'**
  String get checkin_shareSkinMemory;

  /// No description provided for @checkin_shareSkinCouple.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ câu chuyện'**
  String get checkin_shareSkinCouple;

  /// No description provided for @checkin_shareSkinFlexer.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ lên Story'**
  String get checkin_shareSkinFlexer;

  /// No description provided for @checkin_shareSkinMinimal.
  ///
  /// In vi, this message translates to:
  /// **'Xuất thẻ'**
  String get checkin_shareSkinMinimal;

  /// No description provided for @checkin_shareSkinQuiet.
  ///
  /// In vi, this message translates to:
  /// **'Tạo thiệp'**
  String get checkin_shareSkinQuiet;

  /// No description provided for @checkin_done_savedPrivate.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu. Chỉ mình bạn thấy.'**
  String get checkin_done_savedPrivate;

  /// No description provided for @checkin_done_stampChecked.
  ///
  /// In vi, this message translates to:
  /// **'ĐÃ ĐIỂM DANH'**
  String get checkin_done_stampChecked;

  /// No description provided for @checkin_done_stampWeek1.
  ///
  /// In vi, this message translates to:
  /// **'TUẦN 1 XONG'**
  String get checkin_done_stampWeek1;

  /// No description provided for @checkin_done_stampCup.
  ///
  /// In vi, this message translates to:
  /// **'CÚP VỀ TAY'**
  String get checkin_done_stampCup;

  /// No description provided for @checkin_done_memoryStamp.
  ///
  /// In vi, this message translates to:
  /// **'ĐÃ DÁN · NGÀY {day}'**
  String checkin_done_memoryStamp(int day);

  /// No description provided for @checkin_done_coupleDay.
  ///
  /// In vi, this message translates to:
  /// **'Ngày {day}'**
  String checkin_done_coupleDay(int day);

  /// No description provided for @checkin_done_coupleSent.
  ///
  /// In vi, this message translates to:
  /// **'Nửa của bạn đã được gửi.'**
  String get checkin_done_coupleSent;

  /// No description provided for @checkin_done_coupleWeek.
  ///
  /// In vi, this message translates to:
  /// **'Tuần đầu bên nhau'**
  String get checkin_done_coupleWeek;

  /// No description provided for @checkin_done_coupleFull30.
  ///
  /// In vi, this message translates to:
  /// **'Tròn 30 ngày'**
  String get checkin_done_coupleFull30;

  /// No description provided for @checkin_done_flexerDay.
  ///
  /// In vi, this message translates to:
  /// **'NGÀY {day}. {streak} NGÀY LIỀN.'**
  String checkin_done_flexerDay(int day, int streak);

  /// No description provided for @checkin_done_flexerWeek.
  ///
  /// In vi, this message translates to:
  /// **'TUẦN ĐẦU XONG'**
  String get checkin_done_flexerWeek;

  /// No description provided for @checkin_done_flexerFinish.
  ///
  /// In vi, this message translates to:
  /// **'VỀ ĐÍCH'**
  String get checkin_done_flexerFinish;

  /// No description provided for @checkin_done_minimalDone.
  ///
  /// In vi, this message translates to:
  /// **'XONG.'**
  String get checkin_done_minimalDone;

  /// No description provided for @checkin_done_minimalWeek.
  ///
  /// In vi, this message translates to:
  /// **'7 NGÀY LIỀN'**
  String get checkin_done_minimalWeek;

  /// No description provided for @checkin_done_minimalFull.
  ///
  /// In vi, this message translates to:
  /// **'ĐỦ 30 NGÀY'**
  String get checkin_done_minimalFull;

  /// No description provided for @checkin_done_chainLabel.
  ///
  /// In vi, this message translates to:
  /// **'Chuỗi'**
  String get checkin_done_chainLabel;

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

  /// Post screen per-skin input.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay bạn cảm thấy thế nào?'**
  String get checkin_extraMoodLabel;

  /// Post screen per-skin input.
  ///
  /// In vi, this message translates to:
  /// **'Nhẹ nhõm'**
  String get checkin_extraMoodLight;

  /// Post screen per-skin input.
  ///
  /// In vi, this message translates to:
  /// **'Bình thường'**
  String get checkin_extraMoodNormal;

  /// Post screen per-skin input.
  ///
  /// In vi, this message translates to:
  /// **'Hơi mệt'**
  String get checkin_extraMoodTired;

  /// Post screen per-skin input.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay học bao lâu?'**
  String get checkin_extraMinutesLabel;

  /// No description provided for @checkin_extraMinutesValue.
  ///
  /// In vi, this message translates to:
  /// **'{minutes} phút'**
  String checkin_extraMinutesValue(int minutes);

  /// Post screen per-skin input.
  ///
  /// In vi, this message translates to:
  /// **'Khác'**
  String get checkin_extraMinutesOther;

  /// Post screen per-skin input.
  ///
  /// In vi, this message translates to:
  /// **'Giảm năm phút'**
  String get checkin_extraMinutesLess;

  /// Post screen per-skin input.
  ///
  /// In vi, this message translates to:
  /// **'Tăng năm phút'**
  String get checkin_extraMinutesMore;

  /// Post screen per-skin input.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đang ở đâu?'**
  String get checkin_extraPlaceLabel;

  /// Post screen per-skin input.
  ///
  /// In vi, this message translates to:
  /// **'Tìm một nơi...'**
  String get checkin_extraPlaceHint;

  /// Post screen per-skin input.
  ///
  /// In vi, this message translates to:
  /// **'Món hôm nay'**
  String get checkin_extraDishLabel;

  /// Post screen per-skin input.
  ///
  /// In vi, this message translates to:
  /// **'Để trống cũng được'**
  String get checkin_extraDishHint;

  /// Post screen per-skin input.
  ///
  /// In vi, this message translates to:
  /// **'Ai nấu?'**
  String get checkin_extraCookLabel;

  /// Post screen per-skin input.
  ///
  /// In vi, this message translates to:
  /// **'Bạn'**
  String get checkin_extraYou;

  /// Post screen per-skin input.
  ///
  /// In vi, this message translates to:
  /// **'Người ấy'**
  String get checkin_extraPartner;

  /// Post screen per-skin input.
  ///
  /// In vi, this message translates to:
  /// **'Bữa này mấy tim?'**
  String get checkin_extraHeartsLabel;

  /// No description provided for @checkin_extraHeartsValue.
  ///
  /// In vi, this message translates to:
  /// **'{count} tim'**
  String checkin_extraHeartsValue(int count);

  /// Post screen per-skin input.
  ///
  /// In vi, this message translates to:
  /// **'Thêm ảnh của người ấy'**
  String get checkin_extraPartnerPhoto;

  /// Post screen per-skin input.
  ///
  /// In vi, this message translates to:
  /// **'Đổi ảnh của người ấy'**
  String get checkin_extraPartnerPhotoChange;

  /// Post screen per-skin input.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ ảnh của người ấy'**
  String get checkin_extraPartnerPhotoRemove;

  /// Post screen per-skin input.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh của người ấy'**
  String get checkin_extraPartnerPhotoSemantics;

  /// Post screen per-skin input.
  ///
  /// In vi, this message translates to:
  /// **'Nhịp chạy (phút/km)'**
  String get checkin_extraPaceLabel;

  /// Post screen per-skin input.
  ///
  /// In vi, this message translates to:
  /// **'Nhịp không hợp lệ, giây phải dưới 60'**
  String get checkin_extraPaceInvalid;

  /// Post screen per-skin input.
  ///
  /// In vi, this message translates to:
  /// **'Quãng đường (km)'**
  String get checkin_extraKmLabel;

  /// Post screen per-skin input.
  ///
  /// In vi, this message translates to:
  /// **'VD: 5,3'**
  String get checkin_extraKmHint;

  /// Post screen per-skin input.
  ///
  /// In vi, this message translates to:
  /// **'Quãng đường từ 0,1 đến 500 km, một chữ số thập phân'**
  String get checkin_extraKmInvalid;

  /// Post screen per-skin input.
  ///
  /// In vi, this message translates to:
  /// **'Xoá một số'**
  String get checkin_extraBackspace;

  /// No description provided for @checkin_extraCountdown.
  ///
  /// In vi, this message translates to:
  /// **'Tự đăng sau {seconds} giây'**
  String checkin_extraCountdown(int seconds);

  /// Post screen per-skin input.
  ///
  /// In vi, this message translates to:
  /// **'Chạm bất kỳ đâu để dừng'**
  String get checkin_extraCountdownStop;
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
