import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'memory_collectors_localizations_en.dart';
import 'memory_collectors_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of MemoryCollectorsL10n
/// returned by `MemoryCollectorsL10n.of(context)`.
///
/// Applications need to include `MemoryCollectorsL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/memory_collectors_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: MemoryCollectorsL10n.localizationsDelegates,
///   supportedLocales: MemoryCollectorsL10n.supportedLocales,
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
/// be consistent with the languages listed in the MemoryCollectorsL10n.supportedLocales
/// property.
abstract class MemoryCollectorsL10n {
  MemoryCollectorsL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static MemoryCollectorsL10n of(BuildContext context) {
    return Localizations.of<MemoryCollectorsL10n>(
      context,
      MemoryCollectorsL10n,
    )!;
  }

  static const LocalizationsDelegate<MemoryCollectorsL10n> delegate =
      _MemoryCollectorsL10nDelegate();

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

  /// Tiêu đề đầu dòng thời gian chuyến đi có số ngày cố định (M1)
  ///
  /// In vi, this message translates to:
  /// **'{title} · {days} NGÀY'**
  String memory_collectors_daysHeader(String title, int days);

  /// Tiêu đề đầu dòng thời gian chuyến đi mở rộng (M1)
  ///
  /// In vi, this message translates to:
  /// **'{title} · NHẬT KÝ HÀNH TRÌNH'**
  String memory_collectors_openHeader(String title);

  /// Nhãn dưới ảnh Polaroid khi có chú thích (M1)
  ///
  /// In vi, this message translates to:
  /// **'NGÀY {day} · {caption}'**
  String memory_collectors_dayCaption(String day, String caption);

  /// Nhãn dưới ảnh Polaroid ngày hôm nay khi chưa có chú thích (M1)
  ///
  /// In vi, this message translates to:
  /// **'NGÀY {day} · HÔM NAY'**
  String memory_collectors_dayToday(String day);

  /// Nhãn dưới ảnh Polaroid chỉ có số ngày (M1)
  ///
  /// In vi, this message translates to:
  /// **'NGÀY {day}'**
  String memory_collectors_dayNumber(String day);

  /// Nhãn cuộn phim trên màn hình chụp khi có tổng số ngày (M2)
  ///
  /// In vi, this message translates to:
  /// **'CUỘN PHIM {used}/{total}'**
  String memory_collectors_filmRollBounded(int used, int total);

  /// Nhãn cuộn phim trên màn hình chụp khi hành trình không giới hạn ngày (M2)
  ///
  /// In vi, this message translates to:
  /// **'CUỘN PHIM #{used}'**
  String memory_collectors_filmRollOpen(int used);

  /// Dòng phụ trên thiệp chia sẻ dải phim 35mm (M3)
  ///
  /// In vi, this message translates to:
  /// **'{count} KHOẢNH KHẮC · PHIM 35MM'**
  String memory_collectors_contactSheetSubtitle(int count);

  /// Nút bấm chia sẻ ảnh dải phim 35mm (M3)
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ áp phích chuyến đi'**
  String get memory_collectors_sharePosterCta;

  /// Trạng thái khi chưa có ảnh nào để dựng contact sheet
  ///
  /// In vi, this message translates to:
  /// **'Chưa có khung hình nào trong cuộn phim này.'**
  String get memory_collectors_emptyFilmStrip;
}

class _MemoryCollectorsL10nDelegate
    extends LocalizationsDelegate<MemoryCollectorsL10n> {
  const _MemoryCollectorsL10nDelegate();

  @override
  Future<MemoryCollectorsL10n> load(Locale locale) {
    return SynchronousFuture<MemoryCollectorsL10n>(
      lookupMemoryCollectorsL10n(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_MemoryCollectorsL10nDelegate old) => false;
}

MemoryCollectorsL10n lookupMemoryCollectorsL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return MemoryCollectorsL10nEn();
    case 'vi':
      return MemoryCollectorsL10nVi();
  }

  throw FlutterError(
    'MemoryCollectorsL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
