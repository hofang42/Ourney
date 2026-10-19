import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'memory_collectors_localizations_en.dart';
import 'memory_collectors_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of
/// MemoryCollectorsL10n returned by `MemoryCollectorsL10n.of(context)`.
///
/// Falls back to Vietnamese (`MemoryCollectorsL10nVi`) if the delegate is
/// not yet registered in the ambient `Localizations` tree.
abstract class MemoryCollectorsL10n {
  MemoryCollectorsL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static MemoryCollectorsL10n of(BuildContext context) {
    final existing = Localizations.of<MemoryCollectorsL10n>(
      context,
      MemoryCollectorsL10n,
    );
    if (existing != null) return existing;
    final locale = Localizations.maybeLocaleOf(context) ?? const Locale('vi');
    return lookupMemoryCollectorsL10n(locale);
  }

  static const LocalizationsDelegate<MemoryCollectorsL10n> delegate =
      _MemoryCollectorsL10nDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// Tiêu đề đầu dòng thời gian chuyến đi có số ngày cố định (M1).
  String memory_collectors_daysHeader(String title, int days);

  /// Tiêu đề đầu dòng thời gian chuyến đi mở rộng (M1).
  String memory_collectors_openHeader(String title);

  /// Nhãn dưới ảnh Polaroid khi có chú thích (M1).
  String memory_collectors_dayCaption(String day, String caption);

  /// Nhãn dưới ảnh Polaroid ngày hôm nay khi chưa có chú thích (M1).
  String memory_collectors_dayToday(String day);

  /// Nhãn dưới ảnh Polaroid chỉ có số ngày (M1).
  String memory_collectors_dayNumber(String day);

  /// Nhãn cuộn phim trên màn hình chụp khi có tổng số ngày (M2).
  String memory_collectors_filmRollBounded(int used, int total);

  /// Nhãn cuộn phim trên màn hình chụp khi hành trình không giới hạn ngày (M2).
  String memory_collectors_filmRollOpen(int used);

  /// Dòng phụ trên thiệp chia sẻ dải phim 35mm (M3).
  String memory_collectors_contactSheetSubtitle(int count);

  /// Nút bấm chia sẻ ảnh dải phim 35mm (M3).
  String get memory_collectors_sharePosterCta;

  /// Trạng thái khi chưa có ảnh nào để dựng contact sheet.
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
  switch (locale.languageCode) {
    case 'en':
      return MemoryCollectorsL10nEn();
    case 'vi':
      return MemoryCollectorsL10nVi();
  }
  return MemoryCollectorsL10nVi();
}
