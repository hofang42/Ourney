import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/app_routes.dart';
import 'package:ourney/features/onboarding/onboarding_providers.dart';
import 'package:ourney_core/ourney_core.dart';

import 'journeys_fakes.dart';

Finder _key(String k) => find.byKey(ValueKey(k));

void main() {
  testWidgets('quiz suggestion preselects the type, still overridable', (
    tester,
  ) async {
    await pumpJourneys(
      tester,
      location: AppRoutes.journeyNew,
      locale: const Locale('en'),
      extraOverrides: [
        journeySuggestionProvider.overrideWithValue(
          const JourneySuggestion(
            templateId: TemplateId.travel,
            skin: PersonaSkinId.memoryCollectors,
            kind: JourneyKind.solo,
            reminder: '07:30',
          ),
        ),
      ],
    );
    // Next is available straight away: the travel form is already seeded.
    await tester.tap(_key('create-next'));
    await tester.pumpAndSettle();
    // Travel starts with its DNA questions (place first).
    expect(_key('dna-page-place'), findsOneWidget);
    // Going back and choosing another type reseeds the form.
    await tester.tap(_key('create-back'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(_key('template-custom'));
    await tester.tap(_key('template-custom'));
    await tester.pumpAndSettle();
    expect(_key('dna-page-habit'), findsOneWidget);
    await tester.enterText(_key('dna-habit'), 'Read');
    await tester.enterText(_key('dna-reason'), 'Sleep');
    await tester.tap(_key('create-next'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(_key('journey-title')).controller!.text,
      isNot(templateFor(TemplateId.travel).titleEn),
    );
  });
}
