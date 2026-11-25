import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/features/share_card/ui/share_card.dart';
import 'package:ourney_core/ourney_core.dart';

import 'share_card_fakes.dart';

Finder _key(String k) => find.byKey(ValueKey(k));

Journey _journeyFor(String skin) => switch (skin) {
  'quiet' => weightLossJourney(),
  'squad' => testJourney(templateId: TemplateId.englishDaily, emoji: '📚'),
  'memory' => testJourney(templateId: TemplateId.travel, emoji: '✈'),
  'couple' => testJourney(
    templateId: TemplateId.custom,
    kind: JourneyKind.group,
    emoji: '💞',
    visibility: JourneyVisibility.group,
    maxMembers: 2,
  ),
  'flexer' => testJourney(),
  _ => testJourney(templateId: TemplateId.custom, emoji: '✨'),
};

void main() {
  for (final skin in shareCardSkins) {
    for (final dark in [false, true]) {
      testWidgets('$skin card: both ratios, 320dp, 1.35x, '
          '${dark ? 'dark' : 'light'}, no overflow', (tester) async {
        tester.platformDispatcher.platformBrightnessTestValue = dark
            ? Brightness.dark
            : Brightness.light;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        final j = _journeyFor(skin);
        await pumpShare(
          tester,
          journey: j,
          checkIns: streakCheckIns(j.id),
          photos: true,
          textScale: 1.35,
          size: const Size(320, 900),
        );
        expect(_key('share-card-skin-$skin'), findsOneWidget);
        expect(tester.getSize(_key('share-card-story')), const Size(360, 640));
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(_key('share-card-format-4:5'));
        await tester.tap(_key('share-card-format-4:5'));
        await tester.pumpAndSettle();
        expect(_key('share-card-skin-$skin'), findsOneWidget);
        expect(tester.getSize(_key('share-card-feed')), const Size(360, 450));
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('poster sheet toggles the wordmark and closes', (tester) async {
    final j = testJourney();
    await pumpShare(tester, journey: j, checkIns: streakCheckIns(j.id));
    await tester.tap(_key('share-card-share'));
    await tester.pumpAndSettle();
    expect(_key('share-card-sheet-title'), findsOneWidget);
    expect(find.text('Tin nhắn'), findsOneWidget);
    expect(find.text('Lưu ảnh'), findsOneWidget);
    expect(find.text('Tắt'), findsOneWidget);
    await tester.tap(_key('share-card-sheet-brand'));
    await tester.pumpAndSettle();
    expect(find.text('Bật'), findsOneWidget);
    await tester.tap(_key('share-card-sheet-close'));
    await tester.pumpAndSettle();
    expect(_key('share-card-sheet-title'), findsNothing);
    expect(_key('share-card-logo'), findsNothing);
  });
}
