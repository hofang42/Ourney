import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/app_routes.dart';
import 'package:ourney/app/router.dart';
import 'package:ourney/app/theme/tokens.dart';
import 'package:ourney/features/share_card/domain/share_card_content.dart';
import 'package:ourney/features/share_card/ui/share_card.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/test_helpers.dart';
import 'share_card_fakes.dart';

Finder _key(String k) => find.byKey(ValueKey(k));

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

String _text(WidgetTester tester, String key) =>
    tester.widget<Text>(_key(key)).data!;

/// Every string drawn by a Text / SelectableText / RichText on screen.
Iterable<String> _allText(WidgetTester tester) => tester
    .widgetList<RichText>(find.byType(RichText))
    .map((r) => r.text.toPlainText());

void main() {
  group('layout (FR-E1)', () {
    testWidgets('story by default at 360x640 (x3 = 1080x1920), toggles to '
        'feed 360x450 (x3 = 1080x1350)', (tester) async {
      final j = testJourney();
      await pumpShare(tester, journey: j, checkIns: streakCheckIns(j.id));
      expect(_key('share-card-screen'), findsOneWidget);

      expect(tester.getSize(_key('share-card-story')), const Size(360, 640));
      final boundary = find.ancestor(
        of: _key('share-card-story'),
        matching: find.byType(RepaintBoundary),
      );
      expect(tester.getSize(boundary.first), const Size(360, 640));
      // Preview is scaled to fit the screen, never wider than it.
      expect(
        tester.getRect(_key('share-card-story')).width,
        lessThanOrEqualTo(420),
      );

      await _tap(tester, _key('share-card-format-feed'));
      expect(_key('share-card-story'), findsNothing);
      expect(tester.getSize(_key('share-card-feed')), const Size(360, 450));
      expect(tester.takeException(), isNull);
    });

    testWidgets('content: streak number, caption, title + emoji, logo', (
      tester,
    ) async {
      final j = testJourney();
      await pumpShare(tester, journey: j, checkIns: streakCheckIns(j.id));
      // 10..15 checked in, today (16th) open -> 6-day streak.
      expect(_text(tester, 'share-card-number'), '6');
      expect(_text(tester, 'share-card-caption'), 'ngày liên tiếp');
      expect(_text(tester, 'share-card-title'), 'Tập mỗi ngày');
      expect(find.text('💪'), findsWidgets);
      expect(_text(tester, 'share-card-logo'), 'Ourney');
      // No photo resolvable -> illustration.
      expect(_key('share-card-illustration'), findsOneWidget);
    });

    testWidgets('day N mode and finished journeys', (tester) async {
      final j = testJourney();
      await pumpShare(
        tester,
        journey: j,
        checkIns: streakCheckIns(j.id),
        locale: const Locale('en'),
      );
      await _tap(tester, _key('share-card-number-day'));
      expect(_text(tester, 'share-card-kicker'), 'Day');
      expect(_text(tester, 'share-card-number'), '7');
      expect(_text(tester, 'share-card-caption'), 'of 14');
    });

    testWidgets('finished: Vietnamese kicker at weight 800 has room for '
        'stacked diacritics', (tester) async {
      final j = testJourney(durationDays: 6);
      await pumpShare(tester, journey: j, checkIns: streakCheckIns(j.id));
      expect(_text(tester, 'share-card-kicker'), 'Hoàn thành');
      expect(_text(tester, 'share-card-caption'), '6/6 ngày');
      expect(_text(tester, 'share-card-milestone'), 'Về đích!');
      for (final k in [
        'share-card-kicker',
        'share-card-caption',
        'share-card-title',
        'share-card-milestone',
      ]) {
        final style = tester.widget<Text>(_key(k)).style!;
        expect(style.fontWeight, FontWeight.w800, reason: k);
        expect(style.height, greaterThanOrEqualTo(1.3), reason: k);
        // The laid-out line box is at least the generous line height.
        final box = tester.getSize(_key(k));
        expect(
          box.height,
          greaterThanOrEqualTo(style.fontSize! * 1.3 - 0.5),
          reason: k,
        );
      }
    });

    testWidgets('long title, 2x text and a small phone: no overflow', (
      tester,
    ) async {
      final j = testJourney(
        title:
            'Luyện tiếng Anh mỗi ngày để đi du lịch Nhật Bản và Hàn Quốc '
            'thật tự tin',
      );
      await pumpShare(
        tester,
        journey: j,
        checkIns: streakCheckIns(j.id),
        textScale: 2,
        size: const Size(320, 640),
      );
      expect(tester.takeException(), isNull);
      // The card itself is an image: fixed size whatever the text scale.
      expect(tester.getSize(_key('share-card-story')), const Size(360, 640));
      await _tap(tester, _key('share-card-format-feed'));
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        _key('share-card-blur'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('reduced motion: size switch uses the 0.2 s fade', (
      tester,
    ) async {
      final j = testJourney();
      await pumpShare(tester, journey: j);
      final switcher = tester.widget<AnimatedSwitcher>(
        find.byType(AnimatedSwitcher).first,
      );
      expect(switcher.duration, OurneyDurations.reducedFade);
    });

    testWidgets('unknown journey -> not found state', (tester) async {
      final h = await pumpShare(tester, journey: testJourney());
      h.container.read(routerProvider).go(AppRoutes.share('missing'));
      await tester.pumpAndSettle();
      expect(_key('share-card-empty'), findsOneWidget);
      expect(find.text('Không tìm thấy hành trình này.'), findsOneWidget);
    });

    testWidgets('data layer not wired -> placeholder', (tester) async {
      final c = await pumpOurneyApp(tester);
      c.read(routerProvider).go(AppRoutes.share('j1'));
      await tester.pumpAndSettle();
      expect(_key('placeholder-share_card'), findsOneWidget);
    });
  });

  group('privacy (FR-B7)', () {
    testWidgets('weight loss: no kg anywhere, photo blurred by default', (
      tester,
    ) async {
      final j = weightLossJourney();
      await pumpShare(
        tester,
        journey: j,
        photos: true,
        checkIns: streakCheckIns(j.id, metricValue: 71.5),
      );
      expect(_key('share-card-metric'), findsNothing);
      for (final s in _allText(tester)) {
        expect(s.contains('kg'), isFalse, reason: s);
        expect(s.contains('71'), isFalse, reason: s);
      }
      expect(_key('share-card-metric-hidden'), findsOneWidget);
      expect(_key('share-card-photo'), findsOneWidget);
      final blurred = _key('share-card-photo-blurred');
      expect(blurred, findsOneWidget);
      expect(
        find.descendant(of: blurred, matching: _key('share-card-photo')),
        findsOneWidget,
      );
      final switchTile = tester.widget<SwitchListTile>(_key('share-card-blur'));
      expect(switchTile.value, isTrue);
    });

    testWidgets('feed size keeps the blur too', (tester) async {
      final j = weightLossJourney();
      await pumpShare(
        tester,
        journey: j,
        photos: true,
        checkIns: streakCheckIns(j.id),
      );
      await _tap(tester, _key('share-card-format-feed'));
      expect(
        find.descendant(
          of: _key('share-card-feed'),
          matching: _key('share-card-photo-blurred'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('membership blurMedia blurs; the switch can turn it off', (
      tester,
    ) async {
      final j = testJourney();
      await pumpShare(
        tester,
        journey: j,
        membership: testMembership(j, blurMedia: true),
        photos: true,
        checkIns: streakCheckIns(j.id),
      );
      expect(_key('share-card-photo-blurred'), findsOneWidget);
      await _tap(tester, _key('share-card-blur'));
      expect(_key('share-card-photo-blurred'), findsNothing);
      expect(_key('share-card-photo'), findsOneWidget);
    });

    testWidgets('regular journey: sharp photo and the metric is shown', (
      tester,
    ) async {
      final j = testJourney(metricName: 'Thời gian', metricUnit: 'phút');
      await pumpShare(
        tester,
        journey: j,
        photos: true,
        checkIns: streakCheckIns(j.id, metricValue: 25.5),
      );
      expect(_key('share-card-photo-blurred'), findsNothing);
      expect(_text(tester, 'share-card-metric'), '25,5 phút');
      expect(_key('share-card-metric-hidden'), findsNothing);
    });

    testWidgets('choosing another photo uses that check-in', (tester) async {
      final j = testJourney();
      await pumpShare(
        tester,
        journey: j,
        photos: true,
        checkIns: streakCheckIns(j.id),
      );
      Image photo() => tester.widget<Image>(_key('share-card-photo'));
      expect(photo().image.toString(), contains('c-2026-10-15.jpg'));
      await _tap(tester, _key('share-card-photo-c-2026-10-12'));
      expect(photo().image.toString(), contains('c-2026-10-12.jpg'));
    });
  });

  group('share sheet (FR-E2)', () {
    testWidgets('renders the selected size and opens the sharer', (
      tester,
    ) async {
      final j = testJourney();
      final h = await pumpShare(tester, journey: j, checkIns: streakCheckIns(j.id));
      await _tap(tester, _key('share-card-share'));
      expect(h.exporter.exports, hasLength(1));
      final e = h.exporter.exports.single;
      expect(e.format, ShareCardFormat.story);
      expect(e.boundarySize, const Size(360, 640));
      expect(e.baseName, 'ourney-j1-story');
      final shared = h.sharer.shared.single;
      expect(shared.path, '/tmp/ourney-j1-story.png');
      expect(shared.mimeType, 'image/png');
      expect(shared.text, '💪 Tập mỗi ngày trên Ourney');
      expect(shared.origin, isNotNull);

      await _tap(tester, _key('share-card-format-feed'));
      await _tap(tester, _key('share-card-share'));
      expect(h.exporter.exports.last.format, ShareCardFormat.feed);
      expect(h.exporter.exports.last.boundarySize, const Size(360, 450));
      expect(h.sharer.shared, hasLength(2));
    });

    testWidgets('a rendering failure shows a friendly error', (tester) async {
      final j = testJourney();
      final h = await pumpShare(tester, journey: j);
      h.exporter.error = StateError('boom');
      await _tap(tester, _key('share-card-share'));
      expect(h.sharer.shared, isEmpty);
      expect(find.text('Không tạo được ảnh. Thử lại nhé.'), findsOneWidget);
      // Button usable again.
      final label = find.descendant(
        of: _key('share-card-share'),
        matching: find.text('Chia sẻ thẻ'),
      );
      expect(label, findsOneWidget);
    });
  });

  group('public link (FR-E3)', () {
    testWidgets('group journeys never show a public link', (tester) async {
      final j = testJourney(kind: JourneyKind.group);
      await pumpShare(tester, journey: j, backend: true);
      expect(_key('share-card-screen'), findsOneWidget);
      expect(_key('share-card-link'), findsNothing);
      expect(_key('share-card-link-create'), findsNothing);
    });

    testWidgets('local-only mode hides the link section', (tester) async {
      await pumpShare(tester, journey: testJourney());
      expect(_key('share-card-link'), findsNothing);
    });

    testWidgets('create & copy, then revoke', (tester) async {
      final j = testJourney();
      final h = await pumpShare(tester, journey: j, backend: true);
      expect(_key('share-card-link'), findsOneWidget);

      await _tap(tester, _key('share-card-link-create'));
      expect(h.journeys.calls, ['setPublicLink:j1:true']);
      final expected = publicJourneyUri(
        Uri.parse(testBackendConfig.supabaseUrl),
        testToken,
      ).toString();
      expect(
        expected,
        'https://example.supabase.co/functions/v1/public-journey?token=$testToken',
      );
      expect(h.clipboard, [expected]);
      expect(find.text('Đã sao chép link'), findsOneWidget);
      expect(
        tester.widget<SelectableText>(_key('share-card-link-url')).data,
        expected,
      );

      // Copying an existing link does not rotate the token.
      await _tap(tester, _key('share-card-link-copy'));
      expect(h.journeys.calls, ['setPublicLink:j1:true']);
      expect(h.clipboard, [expected, expected]);

      await _tap(tester, _key('share-card-link-revoke'));
      await _tap(tester, _key('share-card-link-revoke-confirm'));
      expect(h.journeys.calls.last, 'setPublicLink:j1:false');
      expect(_key('share-card-link-url'), findsNothing);
      expect(_key('share-card-link-create'), findsOneWidget);
      expect(find.text('Đã thu hồi link'), findsOneWidget);
    });

    testWidgets('existing link journey: copy without calling the server', (
      tester,
    ) async {
      final j = testJourney(
        visibility: JourneyVisibility.link,
        publicToken: testToken,
      );
      final h = await pumpShare(tester, journey: j, backend: true);
      await _tap(tester, _key('share-card-link-copy'));
      expect(h.journeys.calls, isEmpty);
      expect(h.clipboard.single, contains('token=$testToken'));
    });

    testWidgets('works even when the repository stream lags behind', (
      tester,
    ) async {
      final j = testJourney();
      final h = await pumpShare(tester, journey: j, backend: true);
      h.journeys.echoLinkChanges = false;
      await _tap(tester, _key('share-card-link-create'));
      expect(_key('share-card-link-url'), findsOneWidget);
      await _tap(tester, _key('share-card-link-revoke'));
      await _tap(tester, _key('share-card-link-revoke-confirm'));
      expect(_key('share-card-link-create'), findsOneWidget);
    });

    testWidgets('server errors are mapped, nothing is copied', (tester) async {
      final j = testJourney();
      final h = await pumpShare(
        tester,
        journey: j,
        backend: true,
        locale: const Locale('en'),
      );
      h.journeys.linkError = const OurneyException(OurneyErrorCode.ended);
      await _tap(tester, _key('share-card-link-create'));
      expect(h.clipboard, isEmpty);
      expect(
        find.text("This journey is archived, so it can't get a link."),
        findsOneWidget,
      );
      expect(_key('share-card-link-create'), findsOneWidget);
    });
  });

  test('card logo constant', () => expect(shareCardLogo, 'Ourney'));
}
