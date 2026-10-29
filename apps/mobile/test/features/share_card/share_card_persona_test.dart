import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/personas/memory_collectors/share_card.dart';
import 'package:ourney/personas/quiet_transformer/share_card.dart';
import 'package:ourney_core/ourney_core.dart';

import 'share_card_fakes.dart';

/// The share screen (kit UI) shows one exportable card whatever the
/// journey's persona; the older per-persona boards are not stacked under it.
void main() {
  for (final template in [TemplateId.travel, TemplateId.weightLoss]) {
    testWidgets('${template.name}: one exportable card, kit controls', (
      tester,
    ) async {
      final j = testJourney(templateId: template);
      await pumpShare(tester, journey: j, checkIns: streakCheckIns(j.id));
      expect(find.byKey(const ValueKey('share-card-story')), findsOneWidget);
      expect(find.byType(FilmContactSheetShareCard), findsNothing);
      expect(find.byType(SideBySideArchiveShareCard), findsNothing);
      expect(find.byKey(const ValueKey('share-card-format')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
