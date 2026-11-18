import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'import_localizations_en.dart';
import 'import_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of ImportL10n
/// returned by `ImportL10n.of(context)`.
///
/// Applications need to include `ImportL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/import_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: ImportL10n.localizationsDelegates,
///   supportedLocales: ImportL10n.supportedLocales,
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
/// be consistent with the languages listed in the ImportL10n.supportedLocales
/// property.
abstract class ImportL10n {
  ImportL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static ImportL10n of(BuildContext context) {
    return Localizations.of<ImportL10n>(context, ImportL10n)!;
  }

  static const LocalizationsDelegate<ImportL10n> delegate =
      _ImportL10nDelegate();

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

  /// Import past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'nhập hành trình cũ.'**
  String get import_headerTitle;

  /// Import past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại'**
  String get import_back;

  /// Import past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Chọn loại và giao diện.'**
  String get import_setupTitle;

  /// Import past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Giảm cân'**
  String get import_type_weight;

  /// Import past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Tiếng Anh'**
  String get import_type_study;

  /// Import past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Chuyến đi'**
  String get import_type_trip;

  /// Import past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Cặp đôi'**
  String get import_type_couple;

  /// Import past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Tập luyện'**
  String get import_type_workout;

  /// Import past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Tự đặt'**
  String get import_type_custom;

  /// Import past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Tên hoặc địa điểm'**
  String get import_placeLabel;

  /// Import past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Hành trình đã qua'**
  String get import_placeHint;

  /// Import past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Giao diện'**
  String get import_layoutHeading;

  /// Import past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Lặng lẽ'**
  String get import_layout_quiet;

  /// Import past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Ký ức'**
  String get import_layout_memory;

  /// Import past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Khoe thẩm mỹ'**
  String get import_layout_flexer;

  /// Import past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Tối giản'**
  String get import_layout_minimal;

  /// Import past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Một số giao diện cần thêm dữ liệu nên không hiện.'**
  String get import_layoutNote;

  /// Import past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'XEM TRƯỚC'**
  String get import_previewLabel;

  /// Import past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'HUD máy ảnh'**
  String get import_previewHud;

  /// Import past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ảnh cũ'**
  String get import_pickOld;

  /// Import past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ảnh cũ.'**
  String get import_libraryTitle;

  /// Import past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Chọn nhiều ảnh. Ourney đọc ngày chụp để xếp vào hành trình.'**
  String get import_libraryIntro;

  /// Import past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Chọn từ thư viện'**
  String get import_openLibrary;

  /// Import past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Thêm ảnh'**
  String get import_addMore;

  /// Import past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có ảnh nào'**
  String get import_libraryEmptyTitle;

  /// Import past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ảnh cũ từ thư viện để dựng lại hành trình.'**
  String get import_libraryEmptyBody;

  /// Import past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Không có ngày'**
  String get import_noDate;

  /// Import past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ảnh {date}'**
  String import_selectPhoto(String date);

  /// Import past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ chọn ảnh {date}'**
  String import_deselectPhoto(String date);

  /// Import past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Xem lại {count} ảnh'**
  String import_reviewButton(int count);

  /// Import past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Xem lại trong dòng thời gian.'**
  String get import_reviewTitle;

  /// Import past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Ngày {day}'**
  String import_dayLabel(int day);

  /// Import past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có ảnh'**
  String get import_noPhotos;

  /// Import past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'{date} · từ thư viện'**
  String import_fromLibrary(String date);

  /// Import past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'ảnh thêm trong ngày'**
  String get import_extraInDay;

  /// Import past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có ngày'**
  String get import_undatedTitle;

  /// Import past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Gán ngày'**
  String get import_assignDate;

  /// Import past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ'**
  String get import_drop;

  /// Import past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu'**
  String get import_startLabel;

  /// Import past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Kết thúc'**
  String get import_endLabel;

  /// Import past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Chụp tiếp'**
  String get import_continueTitle;

  /// Import past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Chuỗi bắt đầu từ ảnh chụp thật đầu tiên; ảnh nhập không tính chuỗi.'**
  String get import_continueBody;

  /// Import past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Số kg vẫn ẩn và ảnh vẫn làm mờ khi chia sẻ.'**
  String get import_privateNote;

  /// Import past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Lưu hành trình'**
  String get import_save;

  /// Import past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Đang lưu {done}/{total} ảnh…'**
  String import_saving(int done, int total);

  /// Import past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'{count} ảnh chưa lưu được'**
  String import_failed(int count);

  /// Import past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get import_retry;

  /// Import past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Mở hành trình'**
  String get import_openJourney;

  /// Import past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ít nhất một ảnh có ngày.'**
  String get import_errorNoPhotos;

  /// Import past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Gán ngày hoặc bỏ các ảnh chưa có ngày.'**
  String get import_errorUndated;

  /// Import past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Nhập tên hoặc địa điểm.'**
  String get import_errorTitle;

  /// Import past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Có ảnh nằm ngoài khoảng ngày đã chọn.'**
  String get import_errorOutside;

  /// Import past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Ngày kết thúc không thể ở tương lai.'**
  String get import_errorFuture;

  /// Import past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Hành trình tối đa 366 ngày.'**
  String get import_errorRange;

  /// Import past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Không lưu được hành trình. Thử lại nhé.'**
  String get import_errorGeneric;

  /// Import past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Không mở được thư viện ảnh.'**
  String get import_pickFailed;
}

class _ImportL10nDelegate extends LocalizationsDelegate<ImportL10n> {
  const _ImportL10nDelegate();

  @override
  Future<ImportL10n> load(Locale locale) {
    return SynchronousFuture<ImportL10n>(lookupImportL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_ImportL10nDelegate old) => false;
}

ImportL10n lookupImportL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return ImportL10nEn();
    case 'vi':
      return ImportL10nVi();
  }

  throw FlutterError(
    'ImportL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
