import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'minimalist_habit_localizations_en.dart';
import 'minimalist_habit_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of MinimalistHabitL10n
/// returned by `MinimalistHabitL10n.of(context)`.
///
/// Applications need to include `MinimalistHabitL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/minimalist_habit_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: MinimalistHabitL10n.localizationsDelegates,
///   supportedLocales: MinimalistHabitL10n.supportedLocales,
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
/// be consistent with the languages listed in the MinimalistHabitL10n.supportedLocales
/// property.
abstract class MinimalistHabitL10n {
  MinimalistHabitL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static MinimalistHabitL10n of(BuildContext context) {
    return Localizations.of<MinimalistHabitL10n>(context, MinimalistHabitL10n)!;
  }

  static const LocalizationsDelegate<MinimalistHabitL10n> delegate =
      _MinimalistHabitL10nDelegate();

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

  /// Tên phong cách, hiện ở nhãn đầu màn
  ///
  /// In vi, this message translates to:
  /// **'Thói quen tối giản'**
  String get minimalist_habit_name;

  /// Ngày thứ N của hành trình
  ///
  /// In vi, this message translates to:
  /// **'Ngày {day}'**
  String minimalist_habit_dayLabel(int day);

  /// Chuỗi ngày liên tiếp
  ///
  /// In vi, this message translates to:
  /// **'Chuỗi {streak} ngày'**
  String minimalist_habit_streakLabel(int streak);

  /// Số lần check-in
  ///
  /// In vi, this message translates to:
  /// **'{count} lần check-in'**
  String minimalist_habit_checkInsLabel(int count);

  /// Tiêu đề lịch chuỗi ngày của phong cách 6
  ///
  /// In vi, this message translates to:
  /// **'THÁNG {month} · CHUỖI {streak} NGÀY'**
  String minimalist_habit_monthStreakHeader(int month, int streak);

  /// Nhãn duy nhất trên màn chụp phong cách 6
  ///
  /// In vi, this message translates to:
  /// **'{title} · NGÀY {day}'**
  String minimalist_habit_cameraPill(String title, int day);

  /// Nhãn phụ tối giản dưới khung ngắm
  ///
  /// In vi, this message translates to:
  /// **'1 chạm · Không cần gõ chữ'**
  String get minimalist_habit_quickSnapHint;

  /// Dòng tổng kết khi hành trình có thời hạn
  ///
  /// In vi, this message translates to:
  /// **'{done} / {total} NGÀY HOÀN THÀNH'**
  String minimalist_habit_summaryCompleted(int done, int total);

  /// Dòng tổng kết khi hành trình không giới hạn ngày
  ///
  /// In vi, this message translates to:
  /// **'{done} NGÀY HOÀN THÀNH'**
  String minimalist_habit_summaryOpen(int done);

  /// Phần trăm đều đặn trên thiệp tối giản
  ///
  /// In vi, this message translates to:
  /// **'{percent}% ĐỀU ĐẶN'**
  String minimalist_habit_summaryConsistency(int percent);

  /// Nút xuất thiệp tối giản
  ///
  /// In vi, this message translates to:
  /// **'Xuất thiệp tối giản'**
  String get minimalist_habit_exportCardButton;

  /// Ô chờ khi chưa có ảnh
  ///
  /// In vi, this message translates to:
  /// **'Chưa có ảnh'**
  String get minimalist_habit_noPhotoYet;
}

class _MinimalistHabitL10nDelegate
    extends LocalizationsDelegate<MinimalistHabitL10n> {
  const _MinimalistHabitL10nDelegate();

  @override
  Future<MinimalistHabitL10n> load(Locale locale) {
    return SynchronousFuture<MinimalistHabitL10n>(
      lookupMinimalistHabitL10n(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_MinimalistHabitL10nDelegate old) => false;
}

MinimalistHabitL10n lookupMinimalistHabitL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return MinimalistHabitL10nEn();
    case 'vi':
      return MinimalistHabitL10nVi();
  }

  throw FlutterError(
    'MinimalistHabitL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
