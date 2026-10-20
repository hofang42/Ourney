import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/personas/memory_collectors/share_card.dart';
import 'package:ourney_core/ourney_core.dart';

import 'share_card_fakes.dart';

/// F3: the share screen shows the persona's board under the exportable card.
void main() {
  testWidgets('travel shows the film contact sheet and keeps the card', (
    tester,
  ) async {
    final j = testJourney(templateId: TemplateId.travel);
    await pumpShare(tester, journey: j, checkIns: streakCheckIns(j.id));
    expect(find.byKey(const ValueKey('share-card-story')), findsOneWidget);
    await tester.ensureVisible(find.byType(FilmContactSheetShareCard));
    expect(find.byType(FilmContactSheetShareCard), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a persona still being designed shows its summary card', (
    tester,
  ) async {
    final j = testJourney(templateId: TemplateId.weightLoss);
    await pumpShare(tester, journey: j, checkIns: streakCheckIns(j.id));
    expect(find.byKey(const ValueKey('share-card-story')), findsOneWidget);
    expect(find.byType(FilmContactSheetShareCard), findsNothing);
    await tester.ensureVisible(find.text('Thay đổi thầm lặng'));
    expect(tester.takeException(), isNull);
  });
}
