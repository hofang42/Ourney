import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/features/share_card/ui/share_card.dart';
import 'package:ourney/features/share_card/ui/share_skin_chrome.dart';
import 'package:ourney/ui/ui.dart';
import 'package:ourney_core/ourney_core.dart';

import 'share_card_fakes.dart';

double _relativeLuminance(Color c) {
  double chan(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * chan(c.r) + 0.7152 * chan(c.g) + 0.0722 * chan(c.b);
}

double uiContrast(Color a, Color b) {
  final la = _relativeLuminance(a);
  final lb = _relativeLuminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

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
    expect(_key('share-card-sheet-share'), findsOneWidget);
    expect(find.text('Lưu ảnh'), findsOneWidget);
    expect(find.text('Tắt'), findsOneWidget);
    await tester.tap(_key('share-card-sheet-brand'));
    await tester.pumpAndSettle();
    expect(find.text('Bật'), findsOneWidget);
    final closeSize = tester.getSize(_key('share-card-sheet-close'));
    expect(closeSize.width, greaterThanOrEqualTo(48));
    expect(closeSize.height, greaterThanOrEqualTo(48));
    await tester.tap(_key('share-card-sheet-close'));
    await tester.pumpAndSettle();
    expect(_key('share-card-sheet-title'), findsNothing);
    expect(_key('share-card-logo'), findsNothing);
  });

  testWidgets(
    'F-18: ShareRatioTabs selected label and ShareActionButton meet WCAG 4.5:1 text and 3:1 UI contrast across all skins, variants, and modes',
    (tester) async {
      for (final skin in uiSkins) {
        for (var v = 0; v < skin.variants.length; v++) {
          for (final brightness in Brightness.values) {
            await tester.pumpWidget(
              MaterialApp(
                theme: OurneyTheme.build(brightness),
                home: UiSkinScope(
                  skinId: skin.id,
                  variant: v,
                  child: Scaffold(
                    body: Column(
                      children: [
                        ShareRatioTabs<String>(
                          skinId: skin.id,
                          values: const [('9:16', '9:16'), ('4:5', '4:5')],
                          value: '9:16',
                          onChanged: (_) {},
                        ),
                        ShareActionButton(
                          key: const ValueKey('test-share-action'),
                          skinId: skin.id,
                          label: 'Share',
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            final tabContainer = tester.widget<Container>(
              find
                  .descendant(
                    of: _key('share-card-format-9:16'),
                    matching: find.byType(Container),
                  )
                  .first,
            );
            final tabText = tester.widget<Text>(
              find
                  .descendant(
                    of: _key('share-card-format-9:16'),
                    matching: find.byType(Text),
                  )
                  .first,
            );
            final tabDeco = tabContainer.decoration! as BoxDecoration;
            final ui = skin.apply(
              brightness == Brightness.dark ? OurneyUi.dark : OurneyUi.light,
              variantIndex: v,
            );
            final tabBg = tabDeco.color ?? ui.bg;
            expect(
              uiContrast(tabText.style!.color!, tabBg),
              greaterThanOrEqualTo(4.5),
              reason: 'ShareRatioTabs ${skin.id} v$v ${brightness.name}',
            );

            final btnContainer = tester.widget<Container>(
              find
                  .descendant(
                    of: _key('test-share-action'),
                    matching: find.byType(Container),
                  )
                  .first,
            );
            final btnText = tester.widget<Text>(
              find
                  .descendant(
                    of: _key('test-share-action'),
                    matching: find.byType(Text),
                  )
                  .first,
            );
            final btnDeco = btnContainer.decoration! as BoxDecoration;
            final btnFill = btnDeco.color!;
            expect(
              uiContrast(btnText.style!.color!, btnFill),
              greaterThanOrEqualTo(4.5),
              reason: 'ShareActionButton text ${skin.id} v$v ${brightness.name}',
            );
            if (btnDeco.border == null) {
              expect(
                uiContrast(btnFill, ui.bg),
                greaterThanOrEqualTo(3.0),
                reason:
                    'ShareActionButton fill vs bg ${skin.id} v$v ${brightness.name}',
              );
            }
          }
        }
      }
    },
  );
}
