import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/data/data_providers.dart';
import 'package:ourney/data/dead_uploads.dart';
import 'package:ourney/features/journeys/ui/dead_uploads_banner.dart';

import '../../app/test_helpers.dart';

class _FakeDead implements DeadUploads {
  final discarded = <List<DeadUpload>>[];
  final kept = <DeadUpload>[];
  @override
  Future<void> keepPhotoOnly(DeadUpload item) async => kept.add(item);
  @override
  Future<void> discard(List<DeadUpload> items) async => discarded.add(items);
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('shows the count with retry and discard ($brightness)', (
      tester,
    ) async {
      const items = [
        DeadUpload(queueId: 1, checkInId: 'c1', journeyId: 'j'),
        DeadUpload(queueId: 2, checkInId: 'c2', journeyId: 'j'),
      ];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deadJourneyUploadsProvider.overrideWith(
              (ref, id) => Stream.value(items),
            ),
          ],
          child: testApp(
            const DeadUploadsBanner(journeyId: 'j'),
            brightness: brightness,
            locale: const Locale('en'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text("2 photos couldn't be sent"), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('dead-uploads-discard')),
        findsOneWidget,
      );
    });
  }

  for (final mixed in [false, true]) {
    testWidgets('policy recovery hides retry for policy rows (mixed=$mixed)', (
      tester,
    ) async {
      final dead = _FakeDead();
      final items = [
        const DeadUpload(
          queueId: 1,
          checkInId: 'c1',
          journeyId: 'j',
          lastError: 'OurneyException(content_policy)',
          captionPolicy: true,
        ),
        if (mixed)
          const DeadUpload(
            queueId: 2,
            checkInId: 'c2',
            journeyId: 'j',
            lastError: 'content_policy',
          ),
      ];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deadUploadsProvider.overrideWithValue(dead),
            deadJourneyUploadsProvider.overrideWith(
              (ref, id) => Stream.value(items),
            ),
          ],
          child: testApp(
            const DeadUploadsBanner(journeyId: 'j'),
            locale: const Locale('en'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Retry'), mixed ? findsOneWidget : findsNothing);
      expect(find.textContaining('because of its caption'), findsOneWidget);
      await tester.tap(find.text('Keep photo only'));
      await tester.pump();
      expect(dead.kept.map((i) => i.checkInId), ['c1']);
      expect(dead.discarded, isEmpty);
      await tester.tap(find.byKey(const ValueKey('dead-uploads-discard')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(dead.discarded, isEmpty);
      expect(
        find.byKey(const ValueKey('dead-uploads-confirm')),
        findsOneWidget,
      );
    }, timeout: const Timeout(Duration(seconds: 30)));
  }

  testWidgets('renders nothing when none failed', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deadJourneyUploadsProvider.overrideWith(
            (ref, id) => Stream.value(const <DeadUpload>[]),
          ),
        ],
        child: testApp(const DeadUploadsBanner(journeyId: 'j')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('dead-uploads-banner')), findsNothing);
  });

  testWidgets('discard asks first and states the count', (tester) async {
    const items = [
      DeadUpload(queueId: 1, checkInId: 'c1', journeyId: 'j'),
      DeadUpload(queueId: 2, checkInId: 'c2', journeyId: 'j'),
    ];
    final dead = _FakeDead();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deadUploadsProvider.overrideWithValue(dead),
          deadJourneyUploadsProvider.overrideWith(
            (ref, id) => Stream.value(items),
          ),
        ],
        child: testApp(
          const DeadUploadsBanner(journeyId: 'j'),
          locale: const Locale('en'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('dead-uploads-discard')));
    await tester.pumpAndSettle();
    expect(find.textContaining('2 photos will be deleted'), findsOneWidget);
    expect(dead.discarded, isEmpty);
    await tester.tap(find.byKey(const ValueKey('dead-uploads-confirm')));
    await tester.pumpAndSettle();
    expect(dead.discarded, hasLength(1));
  });
}
