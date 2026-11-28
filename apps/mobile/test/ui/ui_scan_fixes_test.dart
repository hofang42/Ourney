// Regression tests for the 2026-11-22 UI scan fixes (rounds 1 & 2): 320dp wide,
// Dynamic Type 2.0x and 1.35x (plus 1.0x regression checks), light and dark.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/localization.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/app/theme/app_theme.dart';
import 'package:ourney/features/checkin/captured_photo.dart';
import 'package:ourney/features/checkin/checkin_clock.dart';
import 'package:ourney/features/checkin/photo_compressor.dart';
import 'package:ourney/features/checkin/routes.dart';
import 'package:ourney/features/groups/ui/group_safety_hooks.dart';
import 'package:ourney/features/journeys/data/create_progress.dart';
import 'package:ourney/features/journeys/data/journeys_providers.dart';
import 'package:ourney/features/journeys/ui/create/create_deck.dart';
import 'package:ourney/features/journeys/ui/create/dna_pages.dart';
import 'package:ourney/features/journeys/ui/create/dna_questions.dart';
import 'package:ourney/features/journeys/ui/day_viewer_screen.dart';
import 'package:ourney/features/journeys/ui/home/journey_home_header.dart';
import 'package:ourney/features/journeys/ui/journey_detail_screen.dart';
import 'package:ourney/features/journeys/ui/journeys_list_screen.dart';
import 'package:ourney/features/onboarding/onboarding_quiz.dart';
import 'package:ourney/features/safety/l10n/generated/safety_localizations.dart';
import 'package:ourney/features/safety/ui/block_dialogs.dart';
import 'package:ourney/features/share_card/ui/share_skin_chrome.dart';
import 'package:ourney/features/social/social_paths.dart';
import 'package:ourney/ui/contrast.dart';
import 'package:ourney/ui/ui.dart';
import 'package:ourney_core/ourney_core.dart';

import '../app/test_helpers.dart';
import '../features/checkin/fakes.dart';
import '../features/groups/groups_fakes.dart' as groups_fakes;
import '../features/safety/safety_fakes.dart' show FakeSafetyRepository;
import '../features/social/social_fakes.dart';

const _size = Size(320, 568);
const _scales = [2.0, 1.35];

void _view(
  WidgetTester tester,
  double scale,
  Brightness b, {
  Size size = _size,
}) {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size
    ..padding = const FakeViewPadding(top: 59, bottom: 34);
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

      testWidgets('1 create deck keeps words whole and chosen chip inside '
          '($tag)', (tester) async {
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
        // F2: _ChosenChip stays inside the preview box without left-edge clip.
        final preview = tester.getRect(
          find.byKey(const ValueKey('deck-preview-quiet')),
        );
        final chip = tester.getRect(
          find.byKey(const ValueKey('create-deck-chosen')),
        );
        expect(chip.left, greaterThanOrEqualTo(preview.left + 8));
        expect(chip.right, lessThanOrEqualTo(preview.right - 8));
      });

      testWidgets('2 check-in caption, weight field, and photo overlays '
          'fit ($tag)', (tester) async {
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
              fromLibrary: true,
            ),
            log: RouteLog(),
            brightness: b,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        // F5: with realistic safe-area insets (top 59, bottom 34), both photo
        // overlays stay horizontally inside the 3:4 preview box.
        final photoBox = tester.getRect(find.byType(AspectRatio).first);
        final retakeBox = tester.getRect(
          find.byKey(const ValueKey('checkin-retake')),
        );
        final fromLibBox = tester.getRect(
          find.byKey(const ValueKey('checkin-from-library')),
        );
        expect(retakeBox.left, greaterThanOrEqualTo(photoBox.left + 8));
        expect(retakeBox.right, lessThanOrEqualTo(photoBox.right - 8));
        expect(fromLibBox.left, greaterThanOrEqualTo(photoBox.left + 12));
        expect(fromLibBox.right, lessThanOrEqualTo(photoBox.right - 12));
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

      testWidgets('3 share top bar pill and non-quiet titles fit ($tag)', (
        tester,
      ) async {
        _view(tester, s, b);
        await tester.pumpWidget(
          _host(
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                UiSkinScope(
                  skinId: 'quiet',
                  child: ShareTopBar(
                    skinId: 'quiet',
                    title: 'Hành trình giảm cân',
                    onBack: () {},
                    backLabel: 'Quay lại',
                  ),
                ),
                UiSkinScope(
                  skinId: 'flexer',
                  child: ShareTopBar(
                    skinId: 'flexer',
                    title: 'Hành trình tập luyện',
                    onBack: () {},
                    backLabel: 'Quay lại',
                  ),
                ),
              ],
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
        // F11: non-quiet skins also allow 2 lines at large text scales.
        final flexerTitle = find.text('HÀNH TRÌNH TẬP LUYỆN');
        expect(flexerTitle, findsOneWidget);
        expect(tester.widget<Text>(flexerTitle).maxLines, 2);
      });

      testWidgets('9 date step day cells are at least 48dp tall and fit '
          'digits ($tag)', (tester) async {
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
        // F11: two-digit day text is scaled down via FittedBox on 1 line.
        final cellRect = tester.getRect(cell);
        final textFinder = find.descendant(
          of: cell,
          matching: find.text('25'),
        );
        final textRect = tester.getRect(textFinder);
        expect(cellRect.contains(textRect.topLeft), isTrue);
        expect(cellRect.contains(textRect.bottomRight), isTrue);
        expect(tester.widget<Text>(textFinder).maxLines, 1);
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
    testWidgets('5 chat sent timestamp contrast and photo+caption message '
        'semantics (${b.name})', (tester) async {
      final fakes = SocialFakes(
        chat: FakeChatRepository(
          conversations: [conversation('c1')],
          messages: {
            'c1': [
              ChatMessage(
                id: 'm2',
                conversationId: 'c1',
                senderId: me,
                kind: MessageKind.photo,
                mediaPath: 'messages/shot.jpg',
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
      // F10: on a photo+caption message, GestureDetector excludes its own
      // semantics so the outer Semantics node carries longPress and
      // customSemanticsActions together.
      final data = tester.getSemantics(bubble).getSemanticsData();
      expect(data.hasAction(SemanticsAction.longPress), isTrue);
      expect(data.customSemanticsActionIds?.isNotEmpty ?? false, isTrue);
      handle.dispose();
    });

    testWidgets('7 friend and add-friend rows have no overflow or unlabeled '
        'tap node at 1.35x and 2.0x (${b.name})', (tester) async {
      final handle = tester.ensureSemantics();
      final friendsRepo = FakeFriendRepository([
        request('khoa', name: 'Khoa Le'),
        request('mai', direction: FriendDirection.outgoing, name: 'Mai Pham'),
        friend('nam', name: 'Nam Tran'),
      ])..directory['linh'] = person('linh', name: 'Linh Nguyen');
      final fakes = SocialFakes(friends: friendsRepo);
      for (final s in _scales) {
        await pumpSocial(
          tester,
          location: SocialPaths.friends,
          fakes: fakes,
          brightness: b,
          width: 320,
          textScale: s,
        );
        expect(tester.takeException(), isNull);
        // F3: outgoing request puts Cancel in actions:, so Mai Pham's name is
        // never crushed to 0dp width.
        expect(tester.getSize(find.text('Mai Pham')).width, greaterThan(60));
        final r = await labeledTapTargetGuideline.evaluate(tester);
        expect(r.passed, isTrue, reason: 'friends $s: ${r.reason}');

        await pumpSocial(
          tester,
          location: SocialPaths.friendsAdd,
          fakes: fakes,
          brightness: b,
          width: 320,
          textScale: s,
        );
        await tester.enterText(
          find.byKey(const ValueKey('username-field')),
          'linh',
        );
        await tester.tap(find.byKey(const ValueKey('username-search')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          tester.getSize(find.text('Linh Nguyen')).width,
          greaterThan(60),
        );
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

  testWidgets('F1 DayViewerScreen loading spinner has >= 4.5:1 contrast in '
      'Light Mode', (tester) async {
    _view(tester, 1.0, Brightness.light);
    final j = testJourney();
    final prefs = await testPrefs();
    final container = ProviderContainer(
      overrides: [
        ...baseOverrides(
          prefs: prefs,
          journeys: FakeJourneyRepository(journeys: [j]),
          checkIns: FakeCheckInRepository(),
        ),
        myCheckInsProvider.overrideWith(
          (ref, id) => const Stream<List<CheckIn>>.empty(),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _host(
          const DayViewerScreen(
            journeyId: 'j1',
            date: LocalDate(2026, 10, 12),
          ),
          Brightness.light,
        ),
      ),
    );
    await tester.pump();
    final spinner = tester.widget<UiSpinner>(find.byType(UiSpinner));
    final ui = tester.element(find.byType(UiSpinner)).ui;
    expect(spinner.color, ui.ink);
    expect(uiContrast(spinner.color!, ui.bg), greaterThanOrEqualTo(4.5));
  });

  testWidgets('F2 CreateTypeDeck 1.0x uses Expanded without clipping on '
      '320x568 or dead gap on 430x932', (tester) async {
    const item = CreateDeckItem(
      keyName: 'weight',
      skinId: 'quiet',
      title: 'Giảm cân',
      tagline: 'Theo dõi thay đổi cơ thể từng ngày một cách nhẹ nhàng',
      meta: 'Một mình · 30 ngày',
      badge: 'weightLoss',
    );
    // 1) 320x568 at 1.0x: no nested vertical SingleChildScrollView inside card,
    // and meta sits fully inside the padded card.
    _view(tester, 1.0, Brightness.light, size: const Size(320, 568));
    await tester.pumpWidget(
      _host(
        CreateTypeDeck(
          items: const [item],
          initial: 0,
          onFocus: (_) {},
          onChoose: (_) {},
        ),
        Brightness.light,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final card = find.byKey(const ValueKey('template-weight'));
    expect(
      find.descendant(of: card, matching: find.byType(SingleChildScrollView)),
      findsNothing,
    );
    final cardRectSmall = tester.getRect(card);
    final metaRectSmall = tester.getRect(find.text('Một mình · 30 ngày'));
    expect(metaRectSmall.bottom, lessThanOrEqualTo(cardRectSmall.bottom - 20));

    // 2) 430x932 at 1.0x: Expanded preview fills remaining space so meta sits
    // near the bottom border (no ~63dp dead space).
    _view(tester, 1.0, Brightness.light, size: const Size(430, 932));
    await tester.pumpWidget(
      _host(
        CreateTypeDeck(
          items: const [item],
          initial: 0,
          onFocus: (_) {},
          onChoose: (_) {},
        ),
        Brightness.light,
      ),
    );
    await tester.pumpAndSettle();
    final cardRectTall = tester.getRect(card);
    final metaRectTall = tester.getRect(find.text('Một mình · 30 ngày'));
    expect(cardRectTall.bottom - metaRectTall.bottom, lessThanOrEqualTo(28));
  });

  testWidgets('F4 tappable UiRow and hub-create-progress UiCard speak their '
      'labels once', (tester) async {
    final handle = tester.ensureSemantics();
    _view(tester, 1.0, Brightness.light);
    await tester.pumpWidget(
      _host(
        Column(
          children: [
            UiRow(
              key: const ValueKey('row-plain'),
              title: 'Cài đặt tài khoản',
              subtitle: const Text('Quản lý bảo mật'),
              onPressed: () {},
            ),
            UiRow(
              key: const ValueKey('row-trailing'),
              title: 'Thông báo',
              trailing: const Text('Bật'),
              onPressed: () {},
            ),
          ],
        ),
        Brightness.light,
      ),
    );
    final plainLabel = tester
        .getSemantics(find.byKey(const ValueKey('row-plain')))
        .getSemanticsData()
        .label;
    expect(plainLabel, 'Cài đặt tài khoản\nQuản lý bảo mật');
    final trailingLabel = tester
        .getSemantics(find.byKey(const ValueKey('row-trailing')))
        .getSemanticsData()
        .label;
    expect(
      RegExp('Thông báo').allMatches(trailingLabel).length,
      1,
      reason: 'title must not be duplicated in semantics: $trailingLabel',
    );

    // Hub "Continue creating" card (`hub-create-progress`) also reads once.
    final prefs = await testPrefs({CreateProgressPrefs.key: 2});
    final container = ProviderContainer(
      overrides: [
        ...baseOverrides(
          prefs: prefs,
          journeys: FakeJourneyRepository(journeys: [testJourney()]),
          checkIns: FakeCheckInRepository(),
        ),
        archivedJourneysProvider.overrideWith(
          (_) => Stream.value(const <Journey>[]),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _host(const JourneysListScreen(), Brightness.light),
      ),
    );
    await tester.pumpAndSettle();
    final resumeCard = find.byKey(const ValueKey('hub-create-progress'));
    expect(resumeCard, findsOneWidget);
    final resumeLabel = tester
        .getSemantics(resumeCard)
        .getSemanticsData()
        .label;
    expect(resumeLabel.contains('\n'), isFalse, reason: resumeLabel);
    handle.dispose();
  });

  testWidgets('F6 JourneyAvatarStack +N overflow disc fits on 1 line at '
      '2.0x', (tester) async {
    for (final s in _scales) {
      _view(tester, s, Brightness.light);
      await tester.pumpWidget(
        _host(
          Center(
            child: JourneyAvatarStack(
              size: 24,
              members: [
                for (var i = 1; i <= 8; i++) (id: 'u$i', name: 'Member $i'),
              ],
            ),
          ),
          Brightness.light,
        ),
      );
      final stackRect = tester.getRect(
        find.byKey(const ValueKey('journey-avatar-stack')),
      );
      final plus = find.text('+3');
      expect(plus, findsOneWidget);
      final plusRect = tester.getRect(plus);
      expect(stackRect.contains(plusRect.topLeft), isTrue);
      expect(stackRect.contains(plusRect.bottomRight), isTrue);
      final p = tester.renderObject<RenderParagraph>(plus);
      expect(
        p
            .getBoxesForSelection(
              const TextSelection(baseOffset: 0, extentOffset: 2),
            )
            .length,
        1,
      );
    }
  });

  testWidgets('F7 UiSpinner stops its ticker under Reduce Motion '
      '(disableAnimations: true)', (tester) async {
    await tester.pumpWidget(
      _host(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Center(child: UiSpinner(semanticsLabel: 'Đang tải')),
        ),
        Brightness.light,
      ),
    );
    // Would time out if AnimationController..repeat() stayed active.
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(UiSpinner),
        matching: find.byType(RotationTransition),
      ),
      findsNothing,
    );
  });

  testWidgets('F8 blockUser fallback toast checks messenger.mounted and '
      'clears UiScaffold pinned bottom CTA', (tester) async {
    _view(tester, 1.0, Brightness.light);
    final gate = Completer<void>();
    final repo = _GatedSafetyRepository(gate);
    final prefs = await testPrefs();
    final container = ProviderContainer(
      overrides: [
        ...baseOverrides(
          prefs: prefs,
          journeys: FakeJourneyRepository(),
          checkIns: FakeCheckInRepository(),
        ),
        safetyRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);

    BuildContext? sheetCtx;
    ScaffoldMessengerState? messenger;
    late SafetyL10n l10n;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildAppTheme(Brightness.light),
          locale: const Locale('vi'),
          localizationsDelegates: ourneyLocalizationsDelegates,
          supportedLocales: ourneySupportedLocales,
          home: UiScaffold(
            bottom: Padding(
              padding: const EdgeInsets.all(20),
              child: UiButton(
                key: const ValueKey('pinned-cta'),
                label: 'Tiếp tục',
                onPressed: () {},
              ),
            ),
            child: Builder(
              builder: (context) {
                messenger = ScaffoldMessenger.of(context);
                l10n = SafetyL10n.of(context);
                return TextButton(
                  onPressed: () => showUiSheet<void>(
                    context: context,
                    builder: (ctx) {
                      sheetCtx = ctx;
                      return const Text('Sheet');
                    },
                  ),
                  child: const Text('open'),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    // Start blockUser with the sheet's context, then pop the sheet before
    // the async repository call completes so toastContext.mounted is false.
    final future = blockUser(
      container,
      messenger,
      l10n,
      userId: 'u2',
      name: 'Lan',
      toastContext: sheetCtx,
    );
    Navigator.of(sheetCtx!).pop();
    await tester.pumpAndSettle();
    expect(sheetCtx!.mounted, isFalse);

    gate.complete();
    await future;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    final toastRect = tester.getRect(find.byKey(const ValueKey('ui-toast')));
    final ctaRect = tester.getRect(find.byKey(const ValueKey('pinned-cta')));
    expect(toastRect.bottom, lessThanOrEqualTo(ctaRect.top));
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    // Also verify no throw when messenger itself is unmounted.
    await tester.pumpWidget(const SizedBox.shrink());
    expect(messenger!.mounted, isFalse);
    await blockUser(
      container,
      messenger,
      l10n,
      userId: 'u3',
      name: 'Minh',
      toastContext: sheetCtx,
    );
  });

  for (final tpl in [
    TemplateId.englishDaily,
    TemplateId.weightLoss,
    TemplateId.travel,
    TemplateId.workout30,
  ]) {
    testWidgets('F9 GroupTodayScreen drops squad wall to 1 column at 360dp x '
        '2.0x and allows 2-line names (${tpl.name})', (tester) async {
      _view(tester, 2.0, Brightness.light, size: const Size(360, 780));
      final g = groups_fakes.groupJourney(templateId: tpl);
      final annToday = groups_fakes.testCheckIn(
        'g1',
        groups_fakes.testToday,
        userId: 'u2',
      );
      await groups_fakes.pumpGroups(
        tester,
        location: '/groups/g1',
        hooks: const GroupSafetyHooks(onReport: _noopReport),
        journeys: groups_fakes.FakeJourneyRepository(
          journeys: [g],
          memberships: {'g1': groups_fakes.groupMembership(g)},
        ),
        checkIns: groups_fakes.FakeCheckInRepository([annToday]),
        groups: groups_fakes.FakeGroupRepository(
          today: {
            'g1': [
              groups_fakes.memberToday(
                groups_fakes.me,
                'Minh',
                role: MemberRole.owner,
              ),
              groups_fakes.memberToday(
                'u2',
                'Nguyễn Thị Hương Giang',
                today: annToday,
                streak: 5,
              ),
            ],
          },
        ),
      );
      tester.view.physicalSize = const Size(360, 780);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      if (tpl == TemplateId.englishDaily) {
        final u2Top = tester.getTopLeft(
          find.byKey(const ValueKey('group-member-u2')),
        );
        final meTop = tester.getTopLeft(
          find.byKey(const ValueKey('group-member-${groups_fakes.me}')),
        );
        // 1-column layout: second tile stacks below first tile, not side-by-side.
        expect(meTop.dy, greaterThan(u2Top.dy + 100));
        final nameFinder = find.text('Nguyễn Thị Hương Giang');
        expect(tester.widget<Text>(nameFinder).maxLines, 2);
        expect(tester.getSize(nameFinder).width, greaterThan(150));
      } else {
        final text = find.textContaining(
          tpl == TemplateId.weightLoss
              ? 'Nguyễn Thị Hương Giang'
              : 'NGUYỄN THỊ HƯƠNG GIANG',
        );
        expect(tester.widget<Text>(text.first).maxLines, 2);
      }
    });
  }

  testWidgets('F11 UiStreakHero stacks on narrow width or large text, '
      'UiPersonRow aligns avatar to top when stacked, and JourneyDetailScreen '
      'reserves padBottom 130 at bigText', (tester) async {
    // 1) UiStreakHero stacks at 1.0x when width < 300dp, with texts before number.
    _view(tester, 1.0, Brightness.light);
    await tester.pumpWidget(
      _host(
        const SizedBox(
          width: 280,
          child: UiStreakHero(
            streak: 14,
            title: 'Còn 2 hành trình hôm nay',
            subtitle: '14 ngày đã ghi',
            semanticLabel: '14 ngày đã ghi. Còn 2 hành trình hôm nay, chuỗi 14 ngày',
          ),
        ),
        Brightness.light,
      ),
    );
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('streak-hero-subtitle'))).dy,
      lessThan(
        tester.getTopLeft(find.byKey(const ValueKey('streak-hero-title'))).dy,
      ),
    );
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('streak-hero-title'))).dy,
      lessThan(
        tester.getTopLeft(find.text('14')).dy,
      ),
    );

    // 2) UiPersonRow aligns Row to CrossAxisAlignment.start when actions wrap.
    _view(tester, 2.0, Brightness.light);
    await tester.pumpWidget(
      _host(
        UiPersonRow(
          name: 'Khoa Le',
          title: 'Khoa Le',
          subtitle: '@khoa',
          actions: [
            UiButton(
              label: 'Chấp nhận',
              compact: true,
              expand: false,
              onPressed: () {},
            ),
          ],
        ),
        Brightness.light,
      ),
    );
    final personRow = tester.widget<Row>(
      find
          .descendant(
            of: find.byType(UiPersonRow),
            matching: find.byType(Row),
          )
          .first,
    );
    expect(personRow.crossAxisAlignment, CrossAxisAlignment.start);

    // 3) JourneyDetailScreen uses padBottom 130 when bigText && !stackOverlay.
    _view(tester, 2.0, Brightness.light);
    final j = testJourney(
      templateId: TemplateId.travel,
      start: const LocalDate(2026, 10, 16),
    );
    final prefs = await testPrefs();
    final container = ProviderContainer(
      overrides: [
        ...baseOverrides(
          prefs: prefs,
          journeys: FakeJourneyRepository(
            journeys: [j],
            membership: Membership(
              journeyId: j.id,
              userId: 'me',
              role: MemberRole.owner,
              status: MemberStatus.active,
              joinedAt: testNowUtc,
            ),
          ),
          checkIns: FakeCheckInRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _host(
          const JourneyDetailScreen(journeyId: 'j1'),
          Brightness.light,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final scaffold = tester.widget<UiScaffold>(
      find.byKey(const ValueKey('journey-detail')),
    );
    expect(scaffold.padBottom, 130);
  });
}

class _GatedSafetyRepository extends FakeSafetyRepository {
  _GatedSafetyRepository(this.gate);
  final Completer<void> gate;

  @override
  Future<void> block(String userId) async {
    await gate.future;
    return super.block(userId);
  }
}

Future<void> _noopReport(
  BuildContext context, {
  required String userId,
  required String displayName,
  String? checkInId,
}) async {}
