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

  /// Delete dialog list item.
  ///
  /// In vi, this message translates to:
  /// **'Hồ sơ của bạn'**
  String get profile_deleteItemProfile;

  /// Delete dialog list item.
  ///
  /// In vi, this message translates to:
  /// **'Mọi hành trình và ảnh'**
  String get profile_deleteItemJourneys;

  /// Delete dialog list item.
  ///
  /// In vi, this message translates to:
  /// **'Tư cách thành viên trong các nhóm'**
  String get profile_deleteItemGroups;

  /// Title of the edit profile screen.
  ///
  /// In vi, this message translates to:
  /// **'sửa hồ sơ.'**
  String get profile_editScreenTitle;

  /// Title of the profile screen.
  ///
  /// In vi, this message translates to:
  /// **'hồ sơ.'**
  String get profile_title;

  /// Title of the profile setup screen shown after the first sign-in.
  ///
  /// In vi, this message translates to:
  /// **'hồ sơ của bạn.'**
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
  /// **'3–20 ký tự: a–z, 0–9, _ .'**
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
  /// **'Chỉ dùng a–z, 0–9, _ .'**
  String get profile_usernameInvalidChars;

  /// Server rejected the username because it is not unique.
  ///
  /// In vi, this message translates to:
  /// **'Tên này đã có người dùng'**
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
  /// **'Xong'**
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
  /// **'cài đặt'**
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

  /// Language row subtitle when Vietnamese was picked in Settings.
  ///
  /// In vi, this message translates to:
  /// **'Tiếng Việt'**
  String get profile_languageVi;

  /// Language row subtitle when English was picked in Settings.
  ///
  /// In vi, this message translates to:
  /// **'English'**
  String get profile_languageEn;

  /// Link to the safety pages (EULA, privacy, contact).
  ///
  /// In vi, this message translates to:
  /// **'Điều khoản, quyền riêng tư & liên hệ'**
  String get profile_safety;

  /// Account section header.
  ///
  /// In vi, this message translates to:
  /// **'tài khoản'**
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
  /// **'Khi đăng xuất, ảnh và dữ liệu lưu trên máy này sẽ bị xóa, kể cả các check-in chưa gửi lên. Những gì đã đồng bộ sẽ trở lại khi bạn đăng nhập lại bằng email.'**
  String get profile_signOutMessage;

  /// Delete account button (FR-A4).
  ///
  /// In vi, this message translates to:
  /// **'Xóa tài khoản'**
  String get profile_deleteAccount;

  /// Delete account confirmation title.
  ///
  /// In vi, this message translates to:
  /// **'Xóa tài khoản vĩnh viễn?'**
  String get profile_deleteTitle;

  /// Delete account consequences.
  ///
  /// In vi, this message translates to:
  /// **'Hồ sơ, hành trình, check-in và toàn bộ ảnh của bạn sẽ bị xóa khỏi máy chủ và máy này. Nhóm bạn đang tham gia được chuyển cho thành viên tham gia sớm nhất. Không thể hoàn tác.'**
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
  /// **'Xóa vĩnh viễn'**
  String get profile_deleteConfirmButton;

  /// Shown while the account is being deleted.
  ///
  /// In vi, this message translates to:
  /// **'Đang xóa…'**
  String get profile_deleting;

  /// delete-account failed (storage_* / delete_failed / internal); safe to retry.
  ///
  /// In vi, this message translates to:
  /// **'Chưa xóa xong. Thử lại để xóa nốt phần còn lại nhé.'**
  String get profile_deleteErrorRetry;

  /// delete-account returned unauthenticated.
  ///
  /// In vi, this message translates to:
  /// **'Phiên đăng nhập đã hết hạn. Đăng nhập lại rồi xóa nhé.'**
  String get profile_deleteErrorReauth;

  /// Back button tooltip.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại'**
  String get profile_back;

  /// Stat label.
  ///
  /// In vi, this message translates to:
  /// **'tổng ngày check-in'**
  String get profile_statSnaps;

  /// Stat label.
  ///
  /// In vi, this message translates to:
  /// **'chuỗi dài nhất'**
  String get profile_statLongest;

  /// Stat label.
  ///
  /// In vi, this message translates to:
  /// **'hành trình đã xong'**
  String get profile_statDone;

  /// Badge shelf heading.
  ///
  /// In vi, this message translates to:
  /// **'huy hiệu đều đặn.'**
  String get profile_badgesTitle;

  /// Badge name.
  ///
  /// In vi, this message translates to:
  /// **'Đều 7 ngày'**
  String get profile_badge7;

  /// Badge name.
  ///
  /// In vi, this message translates to:
  /// **'Đều 30 ngày'**
  String get profile_badge30;

  /// Badge name.
  ///
  /// In vi, this message translates to:
  /// **'Về đích đầu tiên'**
  String get profile_badgeFinish;

  /// Badge name.
  ///
  /// In vi, this message translates to:
  /// **'Đủ 100 ngày'**
  String get profile_badge100;

  /// Badge rule.
  ///
  /// In vi, this message translates to:
  /// **'Có mặt đủ 7 ngày liên tiếp.'**
  String get profile_badge7Rule;

  /// Badge rule.
  ///
  /// In vi, this message translates to:
  /// **'Có mặt đủ 30 ngày liên tiếp.'**
  String get profile_badge30Rule;

  /// Badge rule.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn thành hành trình đầu tiên.'**
  String get profile_badgeFinishRule;

  /// Badge rule.
  ///
  /// In vi, this message translates to:
  /// **'Check-in đủ 100 ngày.'**
  String get profile_badge100Rule;

  /// Badge semantics.
  ///
  /// In vi, this message translates to:
  /// **'đã mở khóa'**
  String get profile_badgeUnlocked;

  /// Badge semantics.
  ///
  /// In vi, this message translates to:
  /// **'chưa mở khóa'**
  String get profile_badgeLocked;

  /// Delete step 1 checkbox.
  ///
  /// In vi, this message translates to:
  /// **'Tôi hiểu việc này không thể hoàn tác.'**
  String get profile_deleteUnderstand;

  /// Delete step 1 note.
  ///
  /// In vi, this message translates to:
  /// **'Nếu bạn là chủ nhóm, quyền chủ nhóm chuyển cho người vào sớm nhất.'**
  String get profile_deleteOwnerNote;

  /// Delete step 1 cancel.
  ///
  /// In vi, this message translates to:
  /// **'Giữ tài khoản'**
  String get profile_deleteKeep;

  /// Delete step 1 continue.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục'**
  String get profile_deleteContinue;

  /// Delete step 2 title.
  ///
  /// In vi, this message translates to:
  /// **'xác nhận bằng mã.'**
  String get profile_deleteOtpTitle;

  /// Delete step 2 lead.
  ///
  /// In vi, this message translates to:
  /// **'Mã gồm 6 số vừa gửi tới email hoặc số điện thoại của tài khoản này.'**
  String get profile_deleteOtpLead;

  /// OTP semantics.
  ///
  /// In vi, this message translates to:
  /// **'Mã xác nhận xóa tài khoản gồm 6 số'**
  String get profile_deleteOtpLabel;

  /// Delete OTP error.
  ///
  /// In vi, this message translates to:
  /// **'Mã chưa đúng. Kiểm tra lại nhé.'**
  String get profile_deleteOtpWrong;

  /// Resend.
  ///
  /// In vi, this message translates to:
  /// **'Gửi lại mã'**
  String get profile_deleteResend;

  /// Resend cooldown.
  ///
  /// In vi, this message translates to:
  /// **'Gửi lại sau {seconds}s'**
  String profile_deleteResendIn(int seconds);

  /// Resend info.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi mã mới.'**
  String get profile_deleteCodeSent;

  /// Delete step 3 done title.
  ///
  /// In vi, this message translates to:
  /// **'Đã xóa tài khoản.'**
  String get profile_deleteDoneTitle;

  /// Delete step 3 done body.
  ///
  /// In vi, this message translates to:
  /// **'Cảm ơn bạn đã dùng Ourney.'**
  String get profile_deleteDoneBody;

  /// Delete step 3 done button.
  ///
  /// In vi, this message translates to:
  /// **'Về màn đầu'**
  String get profile_deleteDoneButton;

  /// Delete step 3 error button.
  ///
  /// In vi, this message translates to:
  /// **'Về cài đặt'**
  String get profile_deleteBackToSettings;

  /// Delete steps.
  ///
  /// In vi, this message translates to:
  /// **'Bước {current} trên {total}'**
  String profile_deleteStepSemantics(int current, int total);

  /// Status under the username field when it can be used.
  ///
  /// In vi, this message translates to:
  /// **'Dùng được'**
  String get profile_usernameAvailable;

  /// No description provided for @profile_settings_title.
  ///
  /// In vi, this message translates to:
  /// **'cài đặt.'**
  String get profile_settings_title;

  /// No description provided for @profile_settings_back.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại'**
  String get profile_settings_back;

  /// No description provided for @profile_settings_secAccount.
  ///
  /// In vi, this message translates to:
  /// **'tài khoản'**
  String get profile_settings_secAccount;

  /// No description provided for @profile_settings_editProfile.
  ///
  /// In vi, this message translates to:
  /// **'Sửa hồ sơ'**
  String get profile_settings_editProfile;

  /// No description provided for @profile_settings_secReminders.
  ///
  /// In vi, this message translates to:
  /// **'nhắc nhở'**
  String get profile_settings_secReminders;

  /// No description provided for @profile_settings_remindersRow.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc nhở hằng ngày'**
  String get profile_settings_remindersRow;

  /// No description provided for @profile_settings_remindersSub.
  ///
  /// In vi, this message translates to:
  /// **'Giờ nhắc từng hành trình và báo trước khi chuỗi đứt'**
  String get profile_settings_remindersSub;

  /// No description provided for @profile_settings_secTheme.
  ///
  /// In vi, this message translates to:
  /// **'giao diện'**
  String get profile_settings_secTheme;

  /// No description provided for @profile_settings_themeLight.
  ///
  /// In vi, this message translates to:
  /// **'Sáng'**
  String get profile_settings_themeLight;

  /// No description provided for @profile_settings_themeDark.
  ///
  /// In vi, this message translates to:
  /// **'Tối'**
  String get profile_settings_themeDark;

  /// No description provided for @profile_settings_themeSystem.
  ///
  /// In vi, this message translates to:
  /// **'Theo máy'**
  String get profile_settings_themeSystem;

  /// No description provided for @profile_settings_themeLabel.
  ///
  /// In vi, this message translates to:
  /// **'Chế độ giao diện'**
  String get profile_settings_themeLabel;

  /// No description provided for @profile_settings_language.
  ///
  /// In vi, this message translates to:
  /// **'Ngôn ngữ'**
  String get profile_settings_language;

  /// No description provided for @profile_settings_langVi.
  ///
  /// In vi, this message translates to:
  /// **'Việt'**
  String get profile_settings_langVi;

  /// No description provided for @profile_settings_langEn.
  ///
  /// In vi, this message translates to:
  /// **'English'**
  String get profile_settings_langEn;

  /// No description provided for @profile_settings_appIcon.
  ///
  /// In vi, this message translates to:
  /// **'Icon ứng dụng'**
  String get profile_settings_appIcon;

  /// No description provided for @profile_settings_appIconNote.
  ///
  /// In vi, this message translates to:
  /// **'Đổi icon trên màn hình chính. Trên một số máy Android, ứng dụng có thể tự đóng hoặc tải lại khi đổi icon.'**
  String get profile_settings_appIconNote;

  /// No description provided for @profile_settings_iconDefault.
  ///
  /// In vi, this message translates to:
  /// **'Mặc định'**
  String get profile_settings_iconDefault;

  /// No description provided for @profile_settings_iconYellow.
  ///
  /// In vi, this message translates to:
  /// **'Vàng hội'**
  String get profile_settings_iconYellow;

  /// No description provided for @profile_settings_iconGreen.
  ///
  /// In vi, this message translates to:
  /// **'Xanh ngọc'**
  String get profile_settings_iconGreen;

  /// No description provided for @profile_settings_iconCoral.
  ///
  /// In vi, this message translates to:
  /// **'Hồng đôi'**
  String get profile_settings_iconCoral;

  /// No description provided for @profile_settings_iconViolet.
  ///
  /// In vi, this message translates to:
  /// **'Tím tập'**
  String get profile_settings_iconViolet;

  /// No description provided for @profile_settings_iconSky.
  ///
  /// In vi, this message translates to:
  /// **'Xanh trời'**
  String get profile_settings_iconSky;

  /// No description provided for @profile_settings_iconDark.
  ///
  /// In vi, this message translates to:
  /// **'Đêm tối'**
  String get profile_settings_iconDark;

  /// No description provided for @profile_settings_iconMinimal.
  ///
  /// In vi, this message translates to:
  /// **'Tối giản'**
  String get profile_settings_iconMinimal;

  /// No description provided for @profile_settings_iconSemantic.
  ///
  /// In vi, this message translates to:
  /// **'Icon ứng dụng {name}'**
  String profile_settings_iconSemantic(String name);

  /// No description provided for @profile_settings_secPrivacy.
  ///
  /// In vi, this message translates to:
  /// **'riêng tư'**
  String get profile_settings_secPrivacy;

  /// No description provided for @profile_settings_hideKg.
  ///
  /// In vi, this message translates to:
  /// **'Ẩn số kg khi chia sẻ'**
  String get profile_settings_hideKg;

  /// No description provided for @profile_settings_blurPhotos.
  ///
  /// In vi, this message translates to:
  /// **'Làm mờ ảnh khi chia sẻ'**
  String get profile_settings_blurPhotos;

  /// No description provided for @profile_settings_blocked.
  ///
  /// In vi, this message translates to:
  /// **'Người bị chặn'**
  String get profile_settings_blocked;

  /// No description provided for @profile_settings_blockedSub.
  ///
  /// In vi, this message translates to:
  /// **'Xem và bỏ chặn'**
  String get profile_settings_blockedSub;

  /// No description provided for @profile_settings_secInfo.
  ///
  /// In vi, this message translates to:
  /// **'thông tin'**
  String get profile_settings_secInfo;

  /// No description provided for @profile_settings_featureRequests.
  ///
  /// In vi, this message translates to:
  /// **'Góp ý & đề xuất tính năng'**
  String get profile_settings_featureRequests;

  /// No description provided for @profile_settings_featureRequestsSub.
  ///
  /// In vi, this message translates to:
  /// **'Bình chọn ý tưởng hoặc gửi đề xuất mới'**
  String get profile_settings_featureRequestsSub;

  /// No description provided for @profile_settings_eula.
  ///
  /// In vi, this message translates to:
  /// **'Điều khoản sử dụng (EULA)'**
  String get profile_settings_eula;

  /// No description provided for @profile_settings_privacyPolicy.
  ///
  /// In vi, this message translates to:
  /// **'Chính sách riêng tư'**
  String get profile_settings_privacyPolicy;

  /// No description provided for @profile_settings_contact.
  ///
  /// In vi, this message translates to:
  /// **'Liên hệ'**
  String get profile_settings_contact;

  /// No description provided for @profile_settings_version.
  ///
  /// In vi, this message translates to:
  /// **'Phiên bản'**
  String get profile_settings_version;

  /// No description provided for @profile_settings_signOut.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất'**
  String get profile_settings_signOut;

  /// No description provided for @profile_settings_delete.
  ///
  /// In vi, this message translates to:
  /// **'Xóa tài khoản'**
  String get profile_settings_delete;

  /// No description provided for @profile_settingsEntry.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt'**
  String get profile_settingsEntry;

  /// No description provided for @profile_settingsEntrySub.
  ///
  /// In vi, this message translates to:
  /// **'Giao diện, ngôn ngữ, riêng tư, thông tin'**
  String get profile_settingsEntrySub;

  /// Warning in the sign-out sheet when check-ins are still waiting to upload.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{Còn {count} ảnh chưa gửi lên. Ourney sẽ thử gửi trước khi đăng xuất; ảnh nào chưa gửi được sẽ mất.}}'**
  String profile_signOutPending(int count);
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
