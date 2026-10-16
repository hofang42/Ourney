import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'share_card_localizations_en.dart';
import 'share_card_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of ShareCardL10n
/// returned by `ShareCardL10n.of(context)`.
///
/// Applications need to include `ShareCardL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/share_card_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: ShareCardL10n.localizationsDelegates,
///   supportedLocales: ShareCardL10n.supportedLocales,
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
/// be consistent with the languages listed in the ShareCardL10n.supportedLocales
/// property.
abstract class ShareCardL10n {
  ShareCardL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static ShareCardL10n of(BuildContext context) {
    return Localizations.of<ShareCardL10n>(context, ShareCardL10n)!;
  }

  static const LocalizationsDelegate<ShareCardL10n> delegate =
      _ShareCardL10nDelegate();

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

  /// Title of the share_card feature's main screen.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ'**
  String get share_card_title;

  /// Label of the story/feed size toggle.
  ///
  /// In vi, this message translates to:
  /// **'Cỡ thẻ'**
  String get share_card_sizeLabel;

  /// Story size, 1080x1920 (Instagram/Facebook stories).
  ///
  /// In vi, this message translates to:
  /// **'Story'**
  String get share_card_sizeStory;

  /// Feed post size, 1080x1350.
  ///
  /// In vi, this message translates to:
  /// **'Bài đăng'**
  String get share_card_sizeFeed;

  /// Label of the chips choosing what the big number shows.
  ///
  /// In vi, this message translates to:
  /// **'Con số lớn'**
  String get share_card_numberLabel;

  /// Chip: big number shows the streak (or finished/checked-in days).
  ///
  /// In vi, this message translates to:
  /// **'Chuỗi ngày'**
  String get share_card_numberStreak;

  /// Chip: big number shows today's day N of the journey.
  ///
  /// In vi, this message translates to:
  /// **'Ngày thứ N'**
  String get share_card_numberDay;

  /// Under the big streak number on the card.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{ngày liên tiếp}}'**
  String share_card_captionStreak(int count);

  /// Under the big number when there is no live streak: distinct days checked in.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{ngày đã check-in}}'**
  String share_card_captionCheckedIn(int count);

  /// Above the big number on a finished journey's card.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn thành'**
  String get share_card_kickerFinished;

  /// Under the big number on a finished journey's card.
  ///
  /// In vi, this message translates to:
  /// **'{done}/{total} ngày'**
  String share_card_captionFinished(int done, int total);

  /// Above the big number when it shows day N of the journey.
  ///
  /// In vi, this message translates to:
  /// **'Ngày thứ'**
  String get share_card_kickerDay;

  /// Under the big day number of a journey with a fixed duration.
  ///
  /// In vi, this message translates to:
  /// **'trên {total} ngày'**
  String share_card_captionDayOf(int total);

  /// Badge on the card on the exact day of a 7-day streak.
  ///
  /// In vi, this message translates to:
  /// **'Mốc 7 ngày!'**
  String get share_card_milestone7;

  /// Badge on the card on the exact day of a 30-day streak.
  ///
  /// In vi, this message translates to:
  /// **'Mốc 30 ngày!'**
  String get share_card_milestone30;

  /// Badge on the card when the journey is completed.
  ///
  /// In vi, this message translates to:
  /// **'Về đích!'**
  String get share_card_milestoneCompleted;

  /// Label of the photo picker strip.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh'**
  String get share_card_photoLabel;

  /// Shown when the journey has no check-in photo yet.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có ảnh check-in. Thẻ sẽ dùng hình trang trí.'**
  String get share_card_photoNone;

  /// Accessibility label of a photo thumbnail in the picker.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh ngày {date}'**
  String share_card_photoOfDay(String date);

  /// Switch: blur the photo on the shared card (FR-B7).
  ///
  /// In vi, this message translates to:
  /// **'Làm mờ ảnh'**
  String get share_card_blurPhoto;

  /// Subtitle of the blur switch when privacy settings turned it on.
  ///
  /// In vi, this message translates to:
  /// **'Bật sẵn theo cài đặt riêng tư của hành trình'**
  String get share_card_blurPhotoHint;

  /// Note shown when the metric (e.g. kg) is hidden on the card (FR-B7).
  ///
  /// In vi, this message translates to:
  /// **'Số đo của bạn không hiện trên thẻ.'**
  String get share_card_metricHidden;

  /// Main button: render the card and open the system share sheet.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ thẻ'**
  String get share_card_shareButton;

  /// Share button label while the image is being rendered.
  ///
  /// In vi, this message translates to:
  /// **'Đang tạo ảnh…'**
  String get share_card_preparing;

  /// Rendering, saving or sharing the card image failed.
  ///
  /// In vi, this message translates to:
  /// **'Không tạo được ảnh. Thử lại nhé.'**
  String get share_card_shareError;

  /// Text sent along with the card image in the share sheet.
  ///
  /// In vi, this message translates to:
  /// **'{emoji} {title} trên Ourney'**
  String share_card_shareText(String emoji, String title);

  /// Accessibility label of the card preview.
  ///
  /// In vi, this message translates to:
  /// **'Xem trước thẻ: {headline} {caption}, {title}'**
  String share_card_previewLabel(String headline, String caption, String title);

  /// The journey id in /share/:journeyId does not exist.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy hành trình này.'**
  String get share_card_notFound;

  /// Section title: read-only public link of a solo journey (FR-E3).
  ///
  /// In vi, this message translates to:
  /// **'Link xem công khai'**
  String get share_card_linkTitle;

  /// Explains the public link before it is created.
  ///
  /// In vi, this message translates to:
  /// **'Ai có link đều xem được hành trình này (chỉ xem). Bạn thu hồi được bất cứ lúc nào.'**
  String get share_card_linkDescription;

  /// Shown while the public link is enabled.
  ///
  /// In vi, this message translates to:
  /// **'Link đang bật. Ai có link đều xem được hành trình này.'**
  String get share_card_linkActive;

  /// Button: enable the public link and copy it.
  ///
  /// In vi, this message translates to:
  /// **'Tạo và sao chép link'**
  String get share_card_linkCreate;

  /// Button: copy the existing public link.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép link'**
  String get share_card_linkCopy;

  /// Snack bar after the link was copied.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép link'**
  String get share_card_linkCopied;

  /// Button: revoke the public link.
  ///
  /// In vi, this message translates to:
  /// **'Thu hồi link'**
  String get share_card_linkRevoke;

  /// Revoke confirmation dialog title.
  ///
  /// In vi, this message translates to:
  /// **'Thu hồi link?'**
  String get share_card_linkRevokeTitle;

  /// Revoke confirmation dialog message.
  ///
  /// In vi, this message translates to:
  /// **'Link hiện tại sẽ ngừng hoạt động ngay. Bạn có thể tạo link mới sau.'**
  String get share_card_linkRevokeMessage;

  /// Snack bar after the link was revoked.
  ///
  /// In vi, this message translates to:
  /// **'Đã thu hồi link'**
  String get share_card_linkRevoked;

  /// set_public_link answered `ended` (archived journey).
  ///
  /// In vi, this message translates to:
  /// **'Hành trình đã lưu trữ nên không tạo link được.'**
  String get share_card_linkErrorEnded;

  /// set_public_link answered `forbidden`.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ chủ hành trình mới quản lý được link.'**
  String get share_card_linkErrorForbidden;
}

class _ShareCardL10nDelegate extends LocalizationsDelegate<ShareCardL10n> {
  const _ShareCardL10nDelegate();

  @override
  Future<ShareCardL10n> load(Locale locale) {
    return SynchronousFuture<ShareCardL10n>(lookupShareCardL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_ShareCardL10nDelegate old) => false;
}

ShareCardL10n lookupShareCardL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return ShareCardL10nEn();
    case 'vi':
      return ShareCardL10nVi();
  }

  throw FlutterError(
    'ShareCardL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
