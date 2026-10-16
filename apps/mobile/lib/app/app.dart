import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/generated/app_localizations.dart';
import 'localization.dart';
import 'providers.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class OurneyApp extends ConsumerWidget {
  const OurneyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    // Keep the haptics toggle mirrored into OurneyHaptics.enabled.
    ref.watch(hapticsEnabledProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).app_name,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      supportedLocales: ourneySupportedLocales,
      localizationsDelegates: ourneyLocalizationsDelegates,
      builder: (context, child) =>
          OurneyTextScaleClamp(child: child ?? const SizedBox.shrink()),
    );
  }
}
