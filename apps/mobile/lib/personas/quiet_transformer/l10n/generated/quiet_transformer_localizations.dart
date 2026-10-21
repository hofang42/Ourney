import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'quiet_transformer_localizations_en.dart';
import 'quiet_transformer_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of QuietTransformerL10n
/// returned by `QuietTransformerL10n.of(context)`.
///
/// Applications need to include `QuietTransformerL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/quiet_transformer_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: QuietTransformerL10n.localizationsDelegates,
///   supportedLocales: QuietTransformerL10n.supportedLocales,
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
/// be consistent with the languages listed in the QuietTransformerL10n.supportedLocales
/// property.
abstract class QuietTransformerL10n {
  QuietTransformerL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static QuietTransformerL10n of(BuildContext context) {
    return Localizations.of<QuietTransformerL10n>(
      context,
      QuietTransformerL10n,
    )!;
  }

  static const LocalizationsDelegate<QuietTransformerL10n> delegate =
      _QuietTransformerL10nDelegate();

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
  /// **'Thay đổi thầm lặng'**
  String get quiet_transformer_name;

  /// Ngày thứ N của hành trình
  ///
  /// In vi, this message translates to:
  /// **'Ngày {day}'**
  String quiet_transformer_dayLabel(int day);

  /// Chuỗi ngày liên tiếp
  ///
  /// In vi, this message translates to:
  /// **'Chuỗi {streak} ngày'**
  String quiet_transformer_streakLabel(int streak);

  /// Số lần check-in
  ///
  /// In vi, this message translates to:
  /// **'{count} lần check-in'**
  String quiet_transformer_checkInsLabel(int count);

  /// Nhãn đầu màn chụp của phong cách 1
  ///
  /// In vi, this message translates to:
  /// **'Kho riêng tư · Ngày {day}'**
  String quiet_transformer_vaultPill(int day);

  /// Nút bật bóng mờ ngày 1 trên màn chụp
  ///
  /// In vi, this message translates to:
  /// **'Bóng mờ căn dáng: BẬT (30%)'**
  String get quiet_transformer_ghostOn;

  /// Nút tắt bóng mờ ngày 1 trên màn chụp
  ///
  /// In vi, this message translates to:
  /// **'Bóng mờ căn dáng: TẮT'**
  String get quiet_transformer_ghostOff;

  /// Nhãn thanh trượt chỉ số trên màn chụp
  ///
  /// In vi, this message translates to:
  /// **'{name} hôm nay'**
  String quiet_transformer_metricSliderLabel(String name);

  /// Tiêu đề thẻ biểu đồ đường cong chỉ số
  ///
  /// In vi, this message translates to:
  /// **'Xu hướng {name}'**
  String quiet_transformer_trendTitle(String name);

  /// Hiện khi chưa có điểm số liệu nào
  ///
  /// In vi, this message translates to:
  /// **'Ghi chỉ số khi check-in để vẽ đường biến đổi'**
  String get quiet_transformer_trendEmpty;

  /// Hiện khi mới có 1 điểm số liệu
  ///
  /// In vi, this message translates to:
  /// **'Đã ghi mốc đầu tiên · Thêm ngày tiếp theo để nối đường cong'**
  String get quiet_transformer_trendSingle;

  /// Hiện khi người dùng bật ẩn chỉ số
  ///
  /// In vi, this message translates to:
  /// **'Đã ẩn số liệu riêng tư'**
  String get quiet_transformer_metricHiddenBadge;

  /// Nhãn mốc ngày 1
  ///
  /// In vi, this message translates to:
  /// **'NGÀY 01 · KHỞI ĐẦU'**
  String get quiet_transformer_milestoneStart;

  /// Nhãn mốc ngày 7, 14, 21...
  ///
  /// In vi, this message translates to:
  /// **'NGÀY {day} · CỘT MỐC'**
  String quiet_transformer_milestoneWeek(String day);

  /// Nhãn mốc hôm nay
  ///
  /// In vi, this message translates to:
  /// **'NGÀY {day} · HÔM NAY'**
  String quiet_transformer_milestoneToday(String day);

  /// Nhãn ngày thường trên trục dọc
  ///
  /// In vi, this message translates to:
  /// **'NGÀY {day}'**
  String quiet_transformer_milestoneDay(String day);

  /// Nhãn khung ảnh bên trái trên thiệp so sánh
  ///
  /// In vi, this message translates to:
  /// **'NGÀY 01'**
  String get quiet_transformer_compareDayStart;

  /// Nhãn khung ảnh bên phải trên thiệp so sánh
  ///
  /// In vi, this message translates to:
  /// **'NGÀY {day}'**
  String quiet_transformer_compareDayNow(String day);

  /// Công tắc ẩn số cân trên thiệp chia sẻ
  ///
  /// In vi, this message translates to:
  /// **'Ẩn số cân chính xác'**
  String get quiet_transformer_hideExactWeight;

  /// Mô tả phụ của công tắc ẩn số cân
  ///
  /// In vi, this message translates to:
  /// **'Chỉ hiện độ chênh lệch hoặc chuỗi ngày khi chia sẻ'**
  String get quiet_transformer_hideExactWeightSub;

  /// Nhãn chênh lệch trên thiệp so sánh
  ///
  /// In vi, this message translates to:
  /// **'Chuyển đổi {delta}'**
  String quiet_transformer_transformationBadge(String delta);

  /// Nút chia sẻ thiệp tiến độ
  ///
  /// In vi, this message translates to:
  /// **'Xuất thiệp tiến độ'**
  String get quiet_transformer_exportCard;

  /// Ô chờ khi chưa có ảnh
  ///
  /// In vi, this message translates to:
  /// **'Chưa có ảnh'**
  String get quiet_transformer_waitingPhoto;
}

class _QuietTransformerL10nDelegate
    extends LocalizationsDelegate<QuietTransformerL10n> {
  const _QuietTransformerL10nDelegate();

  @override
  Future<QuietTransformerL10n> load(Locale locale) {
    return SynchronousFuture<QuietTransformerL10n>(
      lookupQuietTransformerL10n(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_QuietTransformerL10nDelegate old) => false;
}

QuietTransformerL10n lookupQuietTransformerL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return QuietTransformerL10nEn();
    case 'vi':
      return QuietTransformerL10nVi();
  }

  throw FlutterError(
    'QuietTransformerL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
