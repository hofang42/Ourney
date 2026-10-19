import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'accountability_squad_localizations_en.dart';
import 'accountability_squad_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AccountabilitySquadL10n
/// returned by `AccountabilitySquadL10n.of(context)`.
///
/// Applications need to include `AccountabilitySquadL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/accountability_squad_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AccountabilitySquadL10n.localizationsDelegates,
///   supportedLocales: AccountabilitySquadL10n.supportedLocales,
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
/// be consistent with the languages listed in the AccountabilitySquadL10n.supportedLocales
/// property.
abstract class AccountabilitySquadL10n {
  AccountabilitySquadL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AccountabilitySquadL10n of(BuildContext context) {
    return Localizations.of<AccountabilitySquadL10n>(
      context,
      AccountabilitySquadL10n,
    )!;
  }

  static const LocalizationsDelegate<AccountabilitySquadL10n> delegate =
      _AccountabilitySquadL10nDelegate();

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

  /// Badge số ngày tổng của hành trình trên pill đầu màn hình
  ///
  /// In vi, this message translates to:
  /// **'{days} NGÀY'**
  String accountability_squad_daysDuration(int days);

  /// Nhãn cho hành trình mở (không giới hạn ngày)
  ///
  /// In vi, this message translates to:
  /// **'HẰNG NGÀY'**
  String get accountability_squad_openDuration;

  /// Nhãn dưới chiếc cúp đích đến của con đường chữ S
  ///
  /// In vi, this message translates to:
  /// **'MỤC TIÊU NGÀY {day}'**
  String accountability_squad_dayGoalTrophy(int day);

  /// Nhãn Polaroid ngày đầu tiên
  ///
  /// In vi, this message translates to:
  /// **'NGÀY {day} · BẮT ĐẦU'**
  String accountability_squad_dayStartLabel(String day);

  /// Nhãn Polaroid của ngày hôm nay
  ///
  /// In vi, this message translates to:
  /// **'NGÀY {day} · HÔM NAY 🔥'**
  String accountability_squad_dayTodayLabel(String day);

  /// Nhãn Polaroid ở các mốc 7, 14, 21...
  ///
  /// In vi, this message translates to:
  /// **'NGÀY {day} ★ TUẦN {week}'**
  String accountability_squad_dayWeekMilestone(String day, int week);

  /// Nhãn Polaroid cho ngày thường
  ///
  /// In vi, this message translates to:
  /// **'NGÀY {day}'**
  String accountability_squad_dayRegularLabel(String day);

  /// Chú thích cho ô ngày lỡ hoặc hôm nay chưa chụp
  ///
  /// In vi, this message translates to:
  /// **'Chưa chụp'**
  String get accountability_squad_missedSlot;

  /// Phần thời gian học trên pill màn hình chụp (S2)
  ///
  /// In vi, this message translates to:
  /// **'{value} {unit} HỌC'**
  String accountability_squad_studyMetricBadge(String value, String unit);

  /// Phần chuỗi ngày trên pill màn hình chụp (S2)
  ///
  /// In vi, this message translates to:
  /// **'🔥 {streak} CHUỖI NGÀY'**
  String accountability_squad_streakBadge(int streak);

  /// Thanh tiến độ đầu màn hình Squad Polaroid Wall (S3)
  ///
  /// In vi, this message translates to:
  /// **'{done}/{total} ĐÃ CHECK-IN HÔM NAY'**
  String accountability_squad_checkedInProgress(int done, int total);

  /// Ô viền nét đứt cho thành viên chưa chụp ảnh hôm nay (S3)
  ///
  /// In vi, this message translates to:
  /// **'{name} · ĐANG CHỜ'**
  String accountability_squad_memberWaiting(String name);

  /// Dòng phụ trong ô nét đứt đang chờ
  ///
  /// In vi, this message translates to:
  /// **'Chưa check-in hôm nay'**
  String get accountability_squad_waitingHint;

  /// Trạng thái rỗng khi danh sách thành viên trống
  ///
  /// In vi, this message translates to:
  /// **'Chưa có thành viên nào trong nhóm này.'**
  String get accountability_squad_emptySquad;

  /// Nhãn trợ năng của nút mở bảng chọn cảm xúc dưới ảnh Polaroid (S3)
  ///
  /// In vi, this message translates to:
  /// **'Thả cảm xúc'**
  String get accountability_squad_addReaction;

  /// Nút tím nhắc thành viên chưa check-in trong ô chờ (S3, chỉ hiện khi bật Nudge)
  ///
  /// In vi, this message translates to:
  /// **'Nhắc {name} 👋'**
  String accountability_squad_nudge(String name);
}

class _AccountabilitySquadL10nDelegate
    extends LocalizationsDelegate<AccountabilitySquadL10n> {
  const _AccountabilitySquadL10nDelegate();

  @override
  Future<AccountabilitySquadL10n> load(Locale locale) {
    return SynchronousFuture<AccountabilitySquadL10n>(
      lookupAccountabilitySquadL10n(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AccountabilitySquadL10nDelegate old) => false;
}

AccountabilitySquadL10n lookupAccountabilitySquadL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AccountabilitySquadL10nEn();
    case 'vi':
      return AccountabilitySquadL10nVi();
  }

  throw FlutterError(
    'AccountabilitySquadL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
