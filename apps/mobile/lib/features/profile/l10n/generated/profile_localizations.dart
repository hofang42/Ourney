import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'profile_localizations_en.dart';
import 'profile_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of ProfileL10n
/// returned by `ProfileL10n.of(context)`.
///
/// Applications need to include `ProfileL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/profile_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: ProfileL10n.localizationsDelegates,
///   supportedLocales: ProfileL10n.supportedLocales,
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
/// be consistent with the languages listed in the ProfileL10n.supportedLocales
/// property.
abstract class ProfileL10n {
  ProfileL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static ProfileL10n of(BuildContext context) {
    return Localizations.of<ProfileL10n>(context, ProfileL10n)!;
  }

  static const LocalizationsDelegate<ProfileL10n> delegate =
      _ProfileL10nDelegate();

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

  /// Title of the profile screen.
  ///
  /// In vi, this message translates to:
  /// **'Hồ sơ'**
  String get profile_title;

  /// Title of the profile setup screen shown after the first sign-in.
  ///
  /// In vi, this message translates to:
  /// **'Hồ sơ của bạn'**
  String get profile_setupTitle;

  /// Subtitle of the profile setup screen.
  ///
  /// In vi, this message translates to:
  /// **'Bạn bè sẽ thấy tên và ảnh này khi cùng đi hành trình.'**
  String get profile_setupSubtitle;

  /// Title of the edit profile screen and the button that opens it.
  ///
  /// In vi, this message translates to:
  /// **'Sửa hồ sơ'**
  String get profile_editTitle;

  /// Username field label.
  ///
  /// In vi, this message translates to:
  /// **'Tên người dùng'**
  String get profile_usernameLabel;

  /// Helper text under the username field.
  ///
  /// In vi, this message translates to:
  /// **'3–20 ký tự: chữ thường, số, dấu _ và dấu chấm'**
  String get profile_usernameHelper;

  /// Username validation error.
  ///
  /// In vi, this message translates to:
  /// **'Tối thiểu {min} ký tự.'**
  String profile_usernameTooShort(int min);

  /// Username validation error.
  ///
  /// In vi, this message translates to:
  /// **'Tối đa {max} ký tự.'**
  String profile_usernameTooLong(int max);

  /// Username validation error.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ dùng chữ thường a–z, số, dấu _ và dấu chấm.'**
  String get profile_usernameInvalidChars;

  /// Server rejected the username because it is not unique.
  ///
  /// In vi, this message translates to:
  /// **'Tên này đã có người dùng. Chọn tên khác nhé.'**
  String get profile_usernameTaken;

  /// Display name field label.
  ///
  /// In vi, this message translates to:
  /// **'Tên hiển thị'**
  String get profile_displayNameLabel;

  /// Display name validation error.
  ///
  /// In vi, this message translates to:
  /// **'Nhập tên hiển thị.'**
  String get profile_displayNameEmpty;

  /// Display name validation error.
  ///
  /// In vi, this message translates to:
  /// **'Tối đa {max} ký tự.'**
  String profile_displayNameTooLong(int max);

  /// Button to pick an avatar when none is set.
  ///
  /// In vi, this message translates to:
  /// **'Thêm ảnh đại diện'**
  String get profile_avatarAdd;

  /// Hint that the avatar is optional.
  ///
  /// In vi, this message translates to:
  /// **'Không bắt buộc'**
  String get profile_avatarOptional;

  /// Button to change the avatar.
  ///
  /// In vi, this message translates to:
  /// **'Đổi ảnh đại diện'**
  String get profile_avatarChange;

  /// Avatar source option.
  ///
  /// In vi, this message translates to:
  /// **'Chọn từ thư viện'**
  String get profile_avatarFromGallery;

  /// Avatar source option.
  ///
  /// In vi, this message translates to:
  /// **'Chụp ảnh mới'**
  String get profile_avatarFromCamera;

  /// Avatar upload failed (the rest of the profile was saved).
  ///
  /// In vi, this message translates to:
  /// **'Không tải được ảnh đại diện lên. Thử lại nhé.'**
  String get profile_avatarError;

  /// Screen reader label of the avatar.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh đại diện của {name}'**
  String profile_avatarSemantics(String name);

  /// Save button on the edit screen.
  ///
  /// In vi, this message translates to:
  /// **'Lưu'**
  String get profile_save;

  /// Save button on the setup screen.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục'**
  String get profile_continue;

  /// Save button label while saving.
  ///
  /// In vi, this message translates to:
  /// **'Đang lưu…'**
  String get profile_saving;

  /// Generic save error.
  ///
  /// In vi, this message translates to:
  /// **'Không lưu được hồ sơ. Thử lại nhé.'**
  String get profile_saveError;

  /// Offline error.
  ///
  /// In vi, this message translates to:
  /// **'Không có mạng. Kết nối lại rồi thử nhé.'**
  String get profile_offlineError;

  /// The profile stream failed.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được hồ sơ.'**
  String get profile_loadError;

  /// Shown when signed in but no profile exists yet.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tất hồ sơ'**
  String get profile_completeTitle;

  /// Shown when signed in but no profile exists yet.
  ///
  /// In vi, this message translates to:
  /// **'Chọn tên người dùng để bạn bè nhận ra bạn.'**
  String get profile_completeMessage;

  /// Name shown in local-only mode.
  ///
  /// In vi, this message translates to:
  /// **'Khách'**
  String get profile_guestName;

  /// Local-only mode badge (FR-A5).
  ///
  /// In vi, this message translates to:
  /// **'Chế độ chỉ trên máy'**
  String get profile_guestTitle;

  /// Local-only mode explanation.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu của bạn chỉ nằm trên máy này. Hành trình một mình dùng đầy đủ; đăng nhập và nhóm cần máy chủ.'**
  String get profile_guestMessage;

  /// Settings section header.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt'**
  String get profile_sectionSettings;

  /// Link to the reminders screen.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc nhở'**
  String get profile_reminders;

  /// Subtitle of the reminders link.
  ///
  /// In vi, this message translates to:
  /// **'Giờ nhắc check-in mỗi ngày'**
  String get profile_remindersSubtitle;

  /// Haptics toggle.
  ///
  /// In vi, this message translates to:
  /// **'Rung phản hồi'**
  String get profile_haptics;

  /// Language row title.
  ///
  /// In vi, this message translates to:
  /// **'Ngôn ngữ'**
  String get profile_language;

  /// The app follows the device language (vi default, en).
  ///
  /// In vi, this message translates to:
  /// **'Theo ngôn ngữ của máy. Mặc định là tiếng Việt.'**
  String get profile_languageNote;

  /// Link to the safety pages (EULA, privacy, contact).
  ///
  /// In vi, this message translates to:
  /// **'Điều khoản, quyền riêng tư & liên hệ'**
  String get profile_safety;

  /// Account section header.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản'**
  String get profile_sectionAccount;

  /// Sign-out button and dialog action.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất'**
  String get profile_signOut;

  /// Sign-out confirmation title.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất khỏi Ourney?'**
  String get profile_signOutTitle;

  /// Sign-out confirmation message.
  ///
  /// In vi, this message translates to:
  /// **'Khi đăng xuất, ảnh và dữ liệu lưu trên máy này sẽ bị xoá, kể cả các check-in chưa gửi lên. Những gì đã đồng bộ sẽ trở lại khi bạn đăng nhập lại bằng email.'**
  String get profile_signOutMessage;

  /// Delete account button (FR-A4).
  ///
  /// In vi, this message translates to:
  /// **'Xoá tài khoản'**
  String get profile_deleteAccount;

  /// Delete account confirmation title.
  ///
  /// In vi, this message translates to:
  /// **'Xoá tài khoản vĩnh viễn?'**
  String get profile_deleteTitle;

  /// Delete account consequences.
  ///
  /// In vi, this message translates to:
  /// **'Hồ sơ, hành trình, check-in và toàn bộ ảnh của bạn sẽ bị xoá khỏi máy chủ và máy này. Nhóm bạn đang tham gia được chuyển cho thành viên tham gia sớm nhất. Không thể hoàn tác.'**
  String get profile_deleteMessage;

  /// Instruction for the confirmation field.
  ///
  /// In vi, this message translates to:
  /// **'Gõ {phrase} để xác nhận'**
  String profile_deleteTypeToConfirm(String phrase);

  /// Word to type when the username is unknown. ASCII only so it is easy to type.
  ///
  /// In vi, this message translates to:
  /// **'XOA'**
  String get profile_deleteConfirmWord;

  /// Final delete button.
  ///
  /// In vi, this message translates to:
  /// **'Xoá vĩnh viễn'**
  String get profile_deleteConfirmButton;

  /// Shown while the account is being deleted.
  ///
  /// In vi, this message translates to:
  /// **'Đang xoá…'**
  String get profile_deleting;

  /// delete-account failed (storage_* / delete_failed / internal); safe to retry.
  ///
  /// In vi, this message translates to:
  /// **'Chưa xoá xong. Thử lại để xoá nốt phần còn lại nhé.'**
  String get profile_deleteErrorRetry;

  /// delete-account returned unauthenticated.
  ///
  /// In vi, this message translates to:
  /// **'Phiên đăng nhập đã hết hạn. Đăng nhập lại rồi xoá nhé.'**
  String get profile_deleteErrorReauth;

  /// Back button tooltip.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại'**
  String get profile_back;
}

class _ProfileL10nDelegate extends LocalizationsDelegate<ProfileL10n> {
  const _ProfileL10nDelegate();

  @override
  Future<ProfileL10n> load(Locale locale) {
    return SynchronousFuture<ProfileL10n>(lookupProfileL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_ProfileL10nDelegate old) => false;
}

ProfileL10n lookupProfileL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return ProfileL10nEn();
    case 'vi':
      return ProfileL10nVi();
  }

  throw FlutterError(
    'ProfileL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
