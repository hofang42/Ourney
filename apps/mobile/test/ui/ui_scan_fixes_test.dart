// Regression tests for the 2026-11-22 UI scan fixes: 320dp wide, Dynamic Type
// 2.0x and 1.35x, light and dark.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/localization.dart';
import 'package:ourney/app/theme/app_theme.dart';
import 'package:ourney/features/checkin/captured_photo.dart';
import 'package:ourney/features/checkin/checkin_clock.dart';
import 'package:ourney/features/checkin/photo_compressor.dart';
import 'package:ourney/features/checkin/routes.dart';
import 'package:ourney/features/journeys/ui/create/create_deck.dart';
import 'package:ourney/features/journeys/ui/create/dna_pages.dart';
import 'package:ourney/features/journeys/ui/create/dna_questions.dart';
import 'package:ourney/features/onboarding/onboarding_quiz.dart';
import 'package:ourney/features/share_card/ui/share_skin_chrome.dart';
import 'package:ourney/features/social/social_paths.dart';
import 'package:ourney/ui/contrast.dart';
import 'package:ourney/ui/ui.dart';
import 'package:ourney_core/ourney_core.dart';

import '../app/test_helpers.dart';
import '../features/checkin/fakes.dart';
import '../features/social/social_fakes.dart';

const _size = Size(320, 568);
const _scales = [2.0, 1.35];

void _view(WidgetTester tester, double scale, Brightness b) {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = _size;
  addTearDown(tester.view.reset);
  tester.platformDispatcher
    ..textScaleFactorTestValue = scale
    ..platformBrightnessTestValue = b;
  addTearDown(tester.platformDispatcher.clearAllTestValues);
}

Widget _host(Widget child, Brightness b) => MaterialApp(
  theme: buildAppTheme(b),
  locale: const Locale('vi'),
  localizationsDelegates: ourneyLocalizationsDelegates,
  supportedLocales: ourneySupportedLocales,
  home: Scaffold(body: SafeArea(child: child)),
);

/// Real glyph widths (the default test font is wider and would ellipsize).
Future<void> _loadFonts() async {
  const families = {
    'BeVietnamPro': [
      'BeVietnamPro-Regular.ttf',
      'BeVietnamPro-Medium.ttf',
      'BeVietnamPro-SemiBold.ttf',
      'BeVietnamPro-Bold.ttf',
    ],
    'BricolageGrotesque': ['BricolageGrotesque-Variable.ttf'],
    'SpaceGrotesk': ['SpaceGrotesk-Variable.ttf'],
    'Fraunces': ['Fraunces-Variable.ttf'],
    'PlayfairDisplay': ['PlayfairDisplay-Variable.ttf'],
    'BarlowCondensed': [
      'BarlowCondensed-Bold.ttf',
      'BarlowCondensed-ExtraBold.ttf',
    ],
    'SpaceMono': ['SpaceMono-Regular.ttf', 'SpaceMono-Bold.ttf'],
  };
  for (final MapEntry(key: family, value: files) in families.entries) {
    final loader = FontLoader(family);
    for (final f in files) {
      final bytes = File('assets/fonts/$f').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }
}

void main() {
  setUpAll(_loadFonts);

  for (final b in Brightness.values) {
    for (final s in _scales) {
      final tag = '${b.name} x$s';

      testWidgets('1 create deck keeps words whole ($tag)', (tester) async {
        _view(tester, s, b);
        await tester.pumpWidget(
          _host(
            SingleChildScrollView(
              child: CreateTypeDeck(
                items: const [
                  CreateDeckItem(
                    keyName: 'weight',
                    skinId: 'quiet',
                    title: 'Giảm cân',
                    tagline: 'Theo dõi thay đổi từng ngày',
                    meta: 'Một mình · 30 ngày',
                    badge: 'weightLoss',
                  ),
                ],
                initial: 0,
                onFocus: (_) {},
                onChoose: (_) {},
              ),
            ),
            b,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final title = find.text('Giảm cân');
        expect(title, findsOneWidget);
        final p = tester.renderObject<RenderParagraph>(title);
        // A mid-word break would add a third line for two words.
        expect(
          p
              .getBoxesForSelection(
                const TextSelection(baseOffset: 0, extentOffset: 8),
              )
              .length,
          lessThanOrEqualTo(2),
        );
        expect(p.didExceedMaxLines, isFalse);
      });

      testWidgets('2 check-in caption and weight field reachable ($tag)', (
        tester,
      ) async {
        _view(tester, s, b);
        final journeys = FakeJourneyRepository(
          journeys: [
            testJourney(
              templateId: TemplateId.weightLoss,
              metricName: 'Cân nặng',
            ),
          ],
        );
        final prefs = await testPrefs();
        final container = ProviderContainer(
          overrides: [
            ...baseOverrides(
              prefs: prefs,
              journeys: journeys,
              checkIns: FakeCheckInRepository(),
            ),
            photoCompressorProvider.overrideWithValue(FakePhotoCompressor()),
            checkinClockProvider.overrideWithValue(FakeCheckinClock()),
          ],
        );
        addTearDown(container.dispose);
        await tester.pumpWidget(
          routedTestApp(
            container: container,
            routes: checkinRoutes,
            initialLocation: '/checkin',
            initialExtra: CapturedPhoto(
              journeyId: 'j1',
              path: '/tmp/shot.jpg',
              capturedAt: testNowUtc,
            ),
            log: RouteLog(),
            brightness: b,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        // The photo leaves room: the caption starts on screen, not a sliver.
        final caption = find.byKey(const ValueKey('checkin-caption'));
        expect(caption, findsOneWidget);
        expect(tester.getTopLeft(caption).dy, lessThan(_size.height - 120));
        // The form scrolls: the weight field can be brought into view.
        final metric = find.byKey(const ValueKey('checkin-metric'));
        await tester.ensureVisible(metric);
        await tester.pumpAndSettle();
        final r = tester.getRect(metric);
        expect(r.bottom, lessThanOrEqualTo(_size.height));
        expect(r.top, greaterThanOrEqualTo(0));
      });

      testWidgets('3 share top bar pill keeps its label ($tag)', (
        tester,
      ) async {
        _view(tester, s, b);
        await tester.pumpWidget(
          _host(
            UiSkinScope(
              skinId: 'quiet',
              child: ShareTopBar(
                skinId: 'quiet',
                title: 'Hành trình giảm cân',
                onBack: () {},
                backLabel: 'Quay lại',
              ),
            ),
            b,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final pill = find.text('Riêng tư');
        expect(pill, findsOneWidget);
        expect(
          tester.renderObject<RenderParagraph>(pill).didExceedMaxLines,
          isFalse,
        );
        final title = find.text('HÀNH TRÌNH GIẢM CÂN');
        expect(title, findsOneWidget);
        // The title is not reduced to a stub.
        expect(tester.getSize(title).width, greaterThan(60));
      });

      testWidgets('9 date step day cells are at least 48dp tall ($tag)', (
        tester,
      ) async {
        _view(tester, s, b);
        await tester.pumpWidget(
          _host(
            SingleChildScrollView(
              child: DnaDateRange(
                today: DateTime(2026, 11, 15),
                value: DnaDates(DateTime(2026, 11, 20)),
                locale: 'vi',
                onChanged: (_) {},
              ),
            ),
            b,
          ),
        );
        await tester.pumpAndSettle();
        final cell = find.byKey(const ValueKey('dna-day-25'));
        expect(cell, findsOneWidget);
        expect(tester.getSize(cell).height, greaterThanOrEqualTo(48));
      });

      testWidgets('12 onboarding options scroll above the button ($tag)', (
        tester,
      ) async {
        _view(tester, s, b);
        await tester.pumpWidget(
          _host(OnboardingQuizStage(onDone: (_) {}, gutter: 16), b),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final next = find.byKey(const ValueKey('onboarding-quiz-next'));
        final nextTop = tester.getTopLeft(next).dy;
        final goal = find.byKey(const ValueKey('onboarding-goal-weight_loss'));
        await tester.ensureVisible(goal);
        await tester.pumpAndSettle();
        // The first option sits fully above the pinned button.
        expect(tester.getRect(goal).bottom, lessThanOrEqualTo(nextTop + 0.5));
        // And the viewport is not a sliver.
        final scroll = tester.getRect(find.byType(SingleChildScrollView).first);
        expect(scroll.height, greaterThan(150));
      });
    }
  }

  for (final b in Brightness.values) {
    testWidgets('5 chat sent timestamp contrast and message action '
        '(${b.name})', (tester) async {
      final fakes = SocialFakes(
        chat: FakeChatRepository(
          conversations: [conversation('c1')],
          messages: {
            'c1': [
              ChatMessage(
                id: 'm2',
                conversationId: 'c1',
                senderId: me,
                kind: MessageKind.text,
                createdAt: DateTime.now(),
                body: 'chapter 6',
              ),
            ],
          },
        ),
      );
      final handle = tester.ensureSemantics();
      await pumpSocial(
        tester,
        location: SocialPaths.chat('c1'),
        fakes: fakes,
        brightness: b,
        width: 320,
        textScale: 2,
      );
      final bubble = find.byKey(const ValueKey('message-m2'));
      final ui = tester.element(bubble).ui;
      final texts = find.descendant(of: bubble, matching: find.byType(Text));
      final stamp = tester.widget<Text>(texts.last);
      final fg = Color.alphaBlend(stamp.style!.color!, ui.brand);
      expect(uiContrast(fg, ui.brand), greaterThanOrEqualTo(4.5));
      // Long-press has a custom semantics action as its alternative.
      final node = tester.getSemantics(bubble);
      final found =
          node.getSemanticsData().customSemanticsActionIds?.isNotEmpty ?? false;
      expect(found, isTrue);
      handle.dispose();
    });

    testWidgets('7 friend rows have no unlabeled tappable node (${b.name})', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final fakes = SocialFakes(
        friends: FakeFriendRepository([
          request('khoa', name: 'Khoa Le'),
          request('mai', direction: FriendDirection.outgoing, name: 'Mai Pham'),
          friend('nam', name: 'Nam Tran'),
        ]),
      );
      for (final s in const [1.35]) {
        await pumpSocial(
          tester,
          location: SocialPaths.friends,
          fakes: fakes,
          brightness: b,
          width: 320,
          textScale: s,
        );
        final r = await labeledTapTargetGuideline.evaluate(tester);
        expect(r.passed, isTrue, reason: '$s: ${r.reason}');
      }
      handle.dispose();
    });
  }

  testWidgets('7 a labeled UiPressable leaves no unlabeled tap node', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        Center(
          child: UiPressable(
            onPressed: () {},
            semanticLabel: 'Mở hành trình',
            child: const SizedBox(width: 120, height: 60),
          ),
        ),
        Brightness.light,
      ),
    );
    final r = await labeledTapTargetGuideline.evaluate(tester);
    expect(r.passed, isTrue, reason: r.reason);
    handle.dispose();
  });
}
