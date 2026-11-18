import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/l10n/generated/app_localizations.dart';
import 'package:ourney/shared/journey_style_name.dart';
import 'package:ourney/ui/journey_styles.dart';

void main() {
  testWidgets(
    'style names are localized, never the internal English id (U20)',
    (tester) async {
      final names = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              for (final s in uiJourneyStyles) {
                names.add(journeyStyleName(context, s));
              }
              return const SizedBox();
            },
          ),
        ),
      );
      expect(names, hasLength(uiJourneyStyles.length));
      expect(names[2], 'Người lưu giữ ký ức');
      for (var i = 0; i < names.length; i++) {
        expect(names[i], isNot(uiJourneyStyles[i].name));
      }
    },
  );
}
