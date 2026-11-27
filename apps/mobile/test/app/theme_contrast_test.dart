import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/config.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/features/journeys/data/journeys_providers.dart';
import 'package:ourney/features/journeys/l10n/generated/journeys_localizations.dart';
import 'package:ourney/features/journeys/ui/journey_detail_screen.dart';
import 'package:ourney/features/journeys/ui/widgets/departure_ticket.dart';
import 'package:ourney/l10n/generated/app_localizations.dart';
import 'package:ourney/shared/color_utils.dart';
import 'package:ourney/ui/ui.dart';
import 'package:ourney_core/ourney_core.dart';

import '../features/journeys/journeys_fakes.dart' show FakeJourneyRepository;
import 'test_helpers.dart';

double contrast(Color a, Color b) => contrastRatio(a, b);

PersonaSkinId _personaForSkinId(String id) => switch (id) {
  'quiet' => PersonaSkinId.quietTransformer,
  'squad' => PersonaSkinId.accountabilitySquad,
  'memory' => PersonaSkinId.memoryCollectors,
  'couple' => PersonaSkinId.coupleRituals,
  'flexer' => PersonaSkinId.aestheticFlexer,
  _ => PersonaSkinId.minimalistHabit,
};

TemplateId _templateForSkinId(String id) => switch (id) {
  'quiet' => TemplateId.weightLoss,
  'squad' => TemplateId.englishDaily,
  'memory' => TemplateId.travel,
  'flexer' => TemplateId.workout30,
  _ => TemplateId.custom,
};

void main() {
  const white = Color(0xFFFFFFFF);

  // V1.0: the brand coral carries ink labels, never white.
  test('ink on the brand >= 4.5:1, white on the brand is not allowed', () {
    final ui = OurneyUi.light;
    expect(contrast(ui.onBrand, ui.brand), greaterThanOrEqualTo(4.5));
    expect(contrast(white, ui.brand), lessThan(4.5));
  });

  test('B6 token discipline: Tím, Cam, flexer text, dark thumb, no pink buttons on quiet/flexer', () {
    expect(OurneyUi.light.brandText, const Color(0xFFB4470F));
    expect(OurneyUi.dark.brandText, const Color(0xFFFFC39B));
    expect(OurneyUi.dark.switchThumb, const Color(0xFF1B1916));

    final squadTimLight = uiSkinById('squad').apply(OurneyUi.light, variantIndex: 1);
    final squadTimDark = uiSkinById('squad').apply(OurneyUi.dark, variantIndex: 1);
    expect(squadTimLight.accent, const Color(0xFFA13CC9));
    expect(squadTimDark.accent, const Color(0xFFC77DE0));
    expect(squadTimLight.brand, const Color(0xFFFF9F1C));
    expect(squadTimDark.brand, const Color(0xFFFF9F1C));

    final minimalCamLight = uiSkinById('minimal').apply(OurneyUi.light, variantIndex: 0);
    final minimalCamDark = uiSkinById('minimal').apply(OurneyUi.dark, variantIndex: 0);
    expect(minimalCamLight.accent, const Color(0xFFEA580C));
    expect(minimalCamLight.brand, const Color(0xFFEA580C));
    expect(minimalCamLight.accentText, const Color(0xFFB4470F));
    expect(minimalCamDark.accentText, const Color(0xFFFFC39B));

    final flexerLight = uiSkinById('flexer').apply(OurneyUi.light, variantIndex: 0);
    final flexerDark = uiSkinById('flexer').apply(OurneyUi.dark, variantIndex: 0);
    expect(flexerLight.accent, const Color(0xFF3DE88C));
    expect(flexerLight.accentText, const Color(0xFF047857));
    expect(flexerDark.accentText, const Color(0xFF3DE88C));
    expect(flexerLight.brand, isNot(const Color(0xFFFF4D6D)));

    final quietLight = uiSkinById('quiet').apply(OurneyUi.light, variantIndex: 0);
    expect(quietLight.brand, isNot(const Color(0xFFFF4D6D)));
  });

  for (final entry in {
    'light': OurneyUi.light,
    'dark': OurneyUi.dark,
  }.entries) {
    final ui = entry.value;
    test('${entry.key}: text pairs meet 4.5:1', () {
      expect(contrast(ui.ink, ui.bg), greaterThanOrEqualTo(4.5));
      expect(contrast(ui.ink, ui.surface), greaterThanOrEqualTo(4.5));
      expect(contrast(ui.inkMuted, ui.bg), greaterThanOrEqualTo(4.5));
      expect(contrast(ui.inkMuted, ui.surface), greaterThanOrEqualTo(4.5));
      expect(contrast(ui.inkSoft, ui.bg), greaterThanOrEqualTo(4.5));
      expect(contrast(ui.inkSoft, ui.surface), greaterThanOrEqualTo(4.5));
      expect(contrast(ui.brandText, ui.bg), greaterThanOrEqualTo(4.5));
      expect(contrast(ui.brandText, ui.surface), greaterThanOrEqualTo(4.5));
      expect(contrast(ui.accentText, ui.bg), greaterThanOrEqualTo(4.5));
      expect(contrast(ui.accentText, ui.surface), greaterThanOrEqualTo(4.5));
      expect(contrast(ui.onBrand, ui.brand), greaterThanOrEqualTo(4.5));
    });

    test('${entry.key}: switch thumbs meet 3:1 on active and inactive tracks', () {
      expect(contrast(ui.switchThumb, ui.brand), greaterThanOrEqualTo(3.0));
      expect(contrast(ui.ink, ui.fill), greaterThanOrEqualTo(3.0));
    });

    test('${entry.key}: danger reads on the background (3:1)', () {
      expect(contrast(ui.danger, ui.bg), greaterThanOrEqualTo(3.0));
    });

    test('${entry.key}: warn and timeCue meet 4.5:1 on bg and surface', () {
      expect(contrast(ui.warn, ui.bg), greaterThanOrEqualTo(4.5));
      expect(contrast(ui.warn, ui.surface), greaterThanOrEqualTo(4.5));
      expect(contrast(ui.timeCue, ui.bg), greaterThanOrEqualTo(4.5));
      expect(contrast(ui.timeCue, ui.surface), greaterThanOrEqualTo(4.5));
    });
  }

  // All 18 skin variants (6 skins × 3 variants) × light/dark:
  // text >= 4.5:1, switch thumbs >= 3:1.
  for (final skin in uiSkins) {
    for (var i = 0; i < skin.variants.length; i++) {
      final variantName = skin.variant(i).name;
      for (final base in [OurneyUi.light, OurneyUi.dark]) {
        final mode = base.brightness.name;
        final ui = skin.apply(base, variantIndex: i);

        test(
          '${skin.id}[$i] ($variantName) $mode: text roles >= 4.5:1 and switch thumbs >= 3:1',
          () {
            for (final layer in [ui.bg, ui.surface]) {
              expect(
                contrast(ui.ink, layer),
                greaterThanOrEqualTo(4.5),
                reason: '${skin.id}[$i] $mode ink on $layer',
              );
              expect(
                contrast(ui.inkMuted, layer),
                greaterThanOrEqualTo(4.5),
                reason: '${skin.id}[$i] $mode inkMuted on $layer',
              );
              expect(
                contrast(ui.inkSoft, layer),
                greaterThanOrEqualTo(4.5),
                reason: '${skin.id}[$i] $mode inkSoft on $layer',
              );
              expect(
                contrast(ui.accentText, layer),
                greaterThanOrEqualTo(4.5),
                reason: '${skin.id}[$i] $mode accentText on $layer',
              );
              expect(
                contrast(ui.brandText, layer),
                greaterThanOrEqualTo(4.5),
                reason: '${skin.id}[$i] $mode brandText on $layer',
              );
            }

            // Labels on button and accent fills.
            expect(
              contrast(ui.onBrand, ui.brand),
              greaterThanOrEqualTo(4.5),
              reason: '${skin.id}[$i] $mode onBrand on brand',
            );
            expect(
              contrast(ui.onAccent, ui.accent),
              greaterThanOrEqualTo(4.5),
              reason: '${skin.id}[$i] $mode onAccent on accent',
            );

            // Switch thumbs (active on brand track, inactive on fill track).
            expect(
              contrast(ui.switchThumb, ui.brand),
              greaterThanOrEqualTo(3.0),
              reason: '${skin.id}[$i] $mode active switchThumb on brand',
            );
            expect(
              contrast(ui.ink, ui.fill),
              greaterThanOrEqualTo(3.0),
              reason: '${skin.id}[$i] $mode inactive switch thumb on fill',
            );

            final themeSwitch = OurneyTheme.fromUi(ui).switchTheme;
            const selected = {WidgetState.selected};
            const unselected = <WidgetState>{};
            expect(
              contrast(
                themeSwitch.thumbColor!.resolve(selected)!,
                themeSwitch.trackColor!.resolve(selected)!,
              ),
              greaterThanOrEqualTo(3.0),
              reason: '${skin.id}[$i] $mode SwitchTheme selected thumb',
            );
            expect(
              contrast(
                themeSwitch.thumbColor!.resolve(unselected)!,
                themeSwitch.trackColor!.resolve(unselected)!,
              ),
              greaterThanOrEqualTo(3.0),
              reason: '${skin.id}[$i] $mode SwitchTheme unselected thumb',
            );
          },
        );
      }
    }
  }

  // The journey styles: label on the accent fill, ink on the paper.
  for (final style in uiJourneyStyles) {
    test('${style.name}: onAccent on accent and ink on paper read', () {
      expect(contrast(style.onAccent, style.accent), greaterThanOrEqualTo(4.5));
      expect(contrast(style.ink, style.paper), greaterThanOrEqualTo(4.5));
    });
  }

  // Widget-level contrast across all 18 variants × light/dark:
  // 1) DepartureTicket on-accent text on the ticket band and all ticket text/icons.
  // 2) JourneyDetailScreen Check-in button camera icon and label on the brand button.
  group('B6 widget contrast across 18 variants × light/dark', () {
    for (final skin in uiSkins) {
      for (var i = 0; i < skin.variants.length; i++) {
        final variantName = skin.variant(i).name;
        for (final base in [OurneyUi.light, OurneyUi.dark]) {
          final mode = base.brightness.name;
          final ui = skin.apply(base, variantIndex: i);

          testWidgets(
            '${skin.id}[$i] ($variantName) $mode: DepartureTicket text/band & JourneyDetail Check-in button icon >= 4.5:1',
            (tester) async {
              final prefs = await testPrefs();

              // 1. Pump DepartureTicket for this skin + variant (and squad band
              // under this skin's palette when skin.id == 'squad').
              await tester.pumpWidget(
                MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: OurneyTheme.build(base.brightness),
                  home: Scaffold(
                    body: DepartureTicket(
                      skinId: skin.id,
                      variant: i,
                      title: 'Tiêu đề ${skin.id}',
                      goalLine: 'Mục tiêu ${skin.id}',
                      durationLabel: '21 ngày',
                      datesLabel: '10/10 – 30/10',
                      milestones: const ['Ngày 7', 'Ngày 14', 'Ngày 21'],
                      leftName: 'Linh',
                      rightName: 'Nam',
                      onChangeVariant: () {},
                    ),
                  ),
                ),
              );
              await tester.pumpAndSettle();

              final ticketPaper =
                  skin.id == 'memory' && !ui.isDark ? ui.bg : ui.surface;
              final ticketTexts = tester.widgetList<Text>(
                find.descendant(
                  of: find.byType(DepartureTicket),
                  matching: find.byType(Text),
                ),
              );
              expect(ticketTexts, isNotEmpty);

              for (final textWidget in ticketTexts) {
                final textColor = textWidget.style?.color;
                expect(textColor, isNotNull);
                final label = textWidget.data ?? '';
                if (skin.id == 'squad' && label == '21 NGÀY') {
                  // On-accent text on the squad ticket accent header band.
                  expect(
                    textColor,
                    ui.onAccent,
                    reason:
                        '${skin.id}[$i] $mode ticket band text must use ui.onAccent',
                  );
                  expect(
                    contrast(textColor!, ui.accent),
                    greaterThanOrEqualTo(4.5),
                    reason:
                        '${skin.id}[$i] $mode ticket band "$label" ($textColor) on accent (${ui.accent})',
                  );
                } else if (label == 'Đổi màu') {
                  expect(
                    contrast(textColor!, ui.bg),
                    greaterThanOrEqualTo(4.5),
                    reason:
                        '${skin.id}[$i] $mode "$label" ($textColor) on bg (${ui.bg})',
                  );
                } else {
                  expect(
                    contrast(textColor!, ticketPaper),
                    greaterThanOrEqualTo(4.5),
                    reason:
                        '${skin.id}[$i] $mode ticket text "$label" ($textColor) on paper ($ticketPaper)',
                  );
                }
              }

              // 2. Pump JourneyDetailScreen for this skin + variant and check
              // the Check-in button fill, label, and camera icon contrast.
              final journey = Journey(
                id: 'j-${skin.id}-$i',
                ownerId: 'u1',
                kind: skin.id == 'squad' || skin.id == 'couple'
                    ? JourneyKind.group
                    : JourneyKind.solo,
                templateId: _templateForSkinId(skin.id),
                title: 'Hành trình ${skin.id}',
                emoji: '🔥',
                startDate: const LocalDate(2026, 10, 10),
                durationDays: 21,
                timezone: 'Asia/Ho_Chi_Minh',
                visibility: JourneyVisibility.private,
                status: JourneyStatus.active,
                layout: _personaForSkinId(skin.id),
                color: i,
                coupleSelfName: skin.id == 'couple' ? 'Linh' : null,
                couplePartnerName: skin.id == 'couple' ? 'Nam' : null,
              );
              final membership = Membership(
                journeyId: journey.id,
                userId: 'u1',
                role: MemberRole.owner,
                status: MemberStatus.active,
                joinedAt: DateTime.utc(2026, 10, 10),
              );

              await tester.pumpWidget(
                ProviderScope(
                  overrides: [
                    appConfigProvider.overrideWithValue(
                      const AppConfig.localOnly(),
                    ),
                    sharedPreferencesProvider.overrideWithValue(prefs),
                    currentUserIdProvider.overrideWithValue('u1'),
                    journeysNowProvider.overrideWithValue(
                      DateTime.utc(2026, 10, 16, 5),
                    ),
                    journeyRepositoryProvider.overrideWithValue(
                      FakeJourneyRepository(
                        journeys: [journey],
                        memberships: {journey.id: membership},
                      ),
                    ),
                    journeysListProvider.overrideWith(
                      (ref) => Stream<List<Journey>>.value([journey]),
                    ),
                    journeyByIdProvider(journey.id).overrideWith(
                      (ref) => Stream<Journey?>.value(journey),
                    ),
                    myMembershipProvider(journey.id).overrideWith(
                      (ref) => Stream<Membership?>.value(membership),
                    ),
                    myCheckInsProvider(journey.id).overrideWith(
                      (ref) => Stream<List<CheckIn>>.value(const <CheckIn>[]),
                    ),
                  ],
                  child: MaterialApp(
                    debugShowCheckedModeBanner: false,
                    theme: OurneyTheme.build(base.brightness),
                    localizationsDelegates: const [
                      ...AppLocalizations.localizationsDelegates,
                      JourneysL10n.delegate,
                    ],
                    supportedLocales: AppLocalizations.supportedLocales,
                    home: JourneyDetailScreen(journeyId: journey.id),
                  ),
                ),
              );
              await tester.pump();
              await tester.pump(const Duration(milliseconds: 350));

              final checkInFinder = find.byKey(
                const ValueKey('journey-checkin'),
              );
              expect(checkInFinder, findsOneWidget);

              final btnContainer = tester
                  .widgetList<Container>(
                    find.descendant(
                      of: checkInFinder,
                      matching: find.byType(Container),
                    ),
                  )
                  .firstWhere((c) => c.decoration is BoxDecoration);
              final btnFill =
                  (btnContainer.decoration! as BoxDecoration).color!;
              expect(btnFill, ui.brand);

              final btnText = tester.widget<Text>(
                find.descendant(
                  of: checkInFinder,
                  matching: find.byType(Text),
                ),
              );
              final btnLabelColor = btnText.style!.color!;
              expect(btnLabelColor, ui.onBrand);
              expect(
                contrast(btnLabelColor, btnFill),
                greaterThanOrEqualTo(4.5),
                reason:
                    '${skin.id}[$i] $mode Check-in label ($btnLabelColor) on brand ($btnFill)',
              );

              final iconPaint = tester
                  .widgetList<CustomPaint>(
                    find.descendant(
                      of: checkInFinder,
                      matching: find.byType(CustomPaint),
                    ),
                  )
                  .firstWhere((p) => p.painter is OurneyIconPainter);
              final iconPainter = iconPaint.painter! as OurneyIconPainter;
              expect(
                iconPainter.color,
                ui.onBrand,
                reason:
                    '${skin.id}[$i] $mode Check-in camera icon must use ui.onBrand',
              );
              expect(
                contrast(iconPainter.color, btnFill),
                greaterThanOrEqualTo(4.5),
                reason:
                    '${skin.id}[$i] $mode Check-in camera icon (${iconPainter.color}) on brand ($btnFill)',
              );
            },
          );
        }
      }
    }
  });
}
