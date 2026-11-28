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

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Kể lại hành trình đã qua'**
  String get import_headerTitle;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại'**
  String get import_back;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Bước {n}/3'**
  String import_stepOf(int n);

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ảnh của bạn.'**
  String get import_photosTitle;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ảnh của hành trình bạn muốn kể lại. Ourney đọc ngày chụp của từng ảnh để xếp vào dòng thời gian.'**
  String get import_photosIntro;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Mở thư viện ảnh'**
  String get import_openLibrary;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Thêm ảnh'**
  String get import_addMore;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có ảnh nào'**
  String get import_libraryEmptyTitle;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ảnh cũ trong thư viện để dựng lại hành trình.'**
  String get import_libraryEmptyBody;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Đã chọn {selected}/{total} ảnh'**
  String import_selectedCount(int selected, int total);

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Chọn tất cả'**
  String get import_selectAll;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ chọn tất cả'**
  String get import_selectNone;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ảnh {date}'**
  String import_selectPhoto(String date);

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ chọn ảnh {date}'**
  String import_deselectPhoto(String date);

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp · {count, plural, other{{count} ảnh}}'**
  String import_nextTimeline(int count);

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Một hành trình nhận tối đa {max} ảnh. Các ảnh dư đã được bỏ qua.'**
  String import_pickLimit(int max);

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{Đã bỏ qua {count} ảnh trùng}}'**
  String import_duplicatesSkipped(int count);

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Không mở được thư viện ảnh.'**
  String get import_pickFailed;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã chọn đủ {max} ảnh.'**
  String import_maxReached(int max);

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra dòng thời gian.'**
  String get import_timelineTitle;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Ngày lấy từ ảnh. Chạm vào một ảnh để đổi ngày.'**
  String get import_timelineIntro;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'{range} · {days}'**
  String import_rangeLine(String range, String days);

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{{count} ngày}}'**
  String import_days(int count);

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Ngày {day}'**
  String import_dayLabel(int day);

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{{count} ảnh}}'**
  String import_dayCount(int count);

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{{count} ngày không có ảnh}}'**
  String import_gapRow(int count);

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có ngày'**
  String get import_undatedTitle;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Hãy đặt ngày hoặc xóa các ảnh này để tiếp tục.'**
  String get import_undatedBody;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Đặt ngày cho tất cả'**
  String get import_setDateAllUndated;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Đổi ngày của ảnh này, hiện là {date}'**
  String import_editDate(String date);

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có ngày'**
  String get import_noDate;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Chọn nhiều'**
  String get import_selectMode;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Xong'**
  String get import_selectDone;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Đặt ngày · {count}'**
  String import_bulkSetDate(int count);

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Xóa · {count}'**
  String import_bulkRemove(int count);

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Xóa ảnh'**
  String get import_removePhoto;

  /// Thông báo sau khi bỏ ảnh ở bước 2.
  ///
  /// In vi, this message translates to:
  /// **'Đã bỏ {count} ảnh khỏi danh sách.'**
  String import_photoRemoved(int count);

  /// Nút hoàn tác bỏ ảnh.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tác'**
  String get import_undo;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Ngày chụp'**
  String get import_sourceExif;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Ngày của tệp'**
  String get import_sourceFile;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Bạn tự đặt'**
  String get import_sourceManual;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Một hành trình dài tối đa 366 ngày. Hãy đổi bớt ngày hoặc xóa ảnh.'**
  String get import_errorRange;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp'**
  String get import_next;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Đặt tên cho hành trình.'**
  String get import_detailsTitle;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Tên hoặc địa điểm'**
  String get import_nameLabel;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Một hành trình đã qua'**
  String get import_nameHint;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Hãy nhập tên cho hành trình.'**
  String get import_errorTitle;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Loại'**
  String get import_typeHeading;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Giảm cân'**
  String get import_type_weight;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Tiếng Anh'**
  String get import_type_study;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Chuyến đi'**
  String get import_type_trip;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Tập luyện'**
  String get import_type_workout;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Tự đặt'**
  String get import_type_custom;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Giao diện'**
  String get import_layoutHeading;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Tĩnh lặng'**
  String get import_layout_quiet;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Kỷ niệm'**
  String get import_layout_memory;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Thể thao'**
  String get import_layout_flexer;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Tối giản'**
  String get import_layout_minimal;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Một số giao diện cần thêm dữ liệu nên chỉ hiện với loại dùng chúng.'**
  String get import_layoutNote;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'XEM TRƯỚC'**
  String get import_previewLabel;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Check-in mỗi ngày'**
  String get import_previewHud;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Vẫn đang tiếp tục?'**
  String get import_continueTitle;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Giữ hành trình mở để bạn check-in tiếp. Chuỗi ngày chỉ tính các check-in mới, ảnh kể lại không được tính.'**
  String get import_continueBody;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ mình bạn thấy hành trình này cho đến khi bạn chia sẻ. Ẩn cân nặng và làm mờ ảnh khi chia sẻ theo phần Cài đặt của bạn.'**
  String get import_privacyNote;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Lưu hành trình'**
  String get import_save;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{{count} ảnh}} · {range}'**
  String import_summaryLine(int count, String range);

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Đang lưu hành trình.'**
  String get import_savingTitle;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Đang chuẩn bị ảnh… {done}/{total}'**
  String import_preparing(int done, int total);

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Đang tạo hành trình…'**
  String get import_creating;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Đang lưu {done}/{total} ảnh…'**
  String import_saving(int done, int total);

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Dừng lại'**
  String get import_pause;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có thể dừng lại. Các ảnh còn lại được giữ trên máy cho đến khi bạn tiếp tục.'**
  String get import_pauseHint;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Đã dừng.'**
  String get import_pausedTitle;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Việc lưu đã dừng. Các ảnh còn lại được giữ trên máy cho đến khi bạn tiếp tục.'**
  String get import_pausedBody;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục lưu'**
  String get import_resume;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Một số ảnh chưa được lưu.'**
  String get import_partialTitle;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ngày'**
  String get import_dateSheetTitle;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Ngày'**
  String get import_dateDay;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Tháng'**
  String get import_dateMonth;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Năm'**
  String get import_dateYear;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Hủy'**
  String get import_dateCancel;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Hành trình có thể đã được tạo. Hãy thử lại để hoàn tất, hoặc thoát ra: ảnh vẫn được giữ trên máy và việc lưu sẽ tiếp tục sau.'**
  String get import_createMaybeLanded;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ hành trình này'**
  String get import_abandon;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ hành trình này?'**
  String get import_abandonTitle;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Sẽ không lưu thêm gì nữa và các ảnh giữ trên máy sẽ bị xóa. Hành trình vẫn có thể xuất hiện trong danh sách của bạn, nhưng trống.'**
  String get import_abandonBody;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ'**
  String get import_abandonConfirm;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Đã đăng xuất.'**
  String get import_signedOutTitle;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập lại để tiếp tục lưu. Ảnh vẫn được giữ trên máy.'**
  String get import_signedOutBody;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Dùng ngày này'**
  String get import_dateConfirm;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Đang dừng…'**
  String get import_cancelling;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Đang chờ'**
  String get import_photoPending;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu'**
  String get import_photoSaved;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Chưa lưu'**
  String get import_photoFailed;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Không đọc được tệp ảnh nữa'**
  String get import_reason_unreadable;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Không có kết nối'**
  String get import_reason_offline;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Ngày không hợp lệ cho hành trình'**
  String get import_reason_badDate;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Đã có lỗi xảy ra'**
  String get import_reason_unknown;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Xong rồi.'**
  String get import_doneTitle;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{Đã lưu {count} ảnh}}'**
  String import_savedSummary(int count);

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{{count} ảnh chưa lưu}}'**
  String import_notSaved(int count);

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Mở hành trình'**
  String get import_openJourney;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại các ảnh chưa lưu'**
  String get import_retryFailed;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ các ảnh còn lại'**
  String get import_leaveRest;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get import_tryAgain;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Sửa thông tin'**
  String get import_editDetails;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin hành trình bị từ chối. Hãy kiểm tra tên và ngày.'**
  String get import_errorInvalid;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Rời đi mà chưa lưu?'**
  String get import_discardTitle;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Bản sao ảnh mà Ourney giữ trên máy sẽ bị xóa (ảnh trong thư viện của bạn vẫn còn).'**
  String get import_discardBody;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Rời đi'**
  String get import_discardConfirm;

  /// Retell a past journey flow.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục'**
  String get import_discardKeep;
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
