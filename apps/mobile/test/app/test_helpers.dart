import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ourney/app/theme/app_theme.dart';
import 'package:ourney/l10n/generated/app_localizations.dart';

const appLocalizationsForTest = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

final appSupportedLocalesForTest = AppLocalizations.supportedLocales;

Widget testApp(Widget child, {Brightness brightness = Brightness.light}) {
  return MaterialApp(
    theme: buildAppTheme(brightness),
    localizationsDelegates: appLocalizationsForTest,
    supportedLocales: appSupportedLocalesForTest,
    home: Scaffold(body: Center(child: child)),
  );
}
