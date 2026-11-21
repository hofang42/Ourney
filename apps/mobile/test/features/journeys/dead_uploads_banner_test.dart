import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/data/dead_uploads.dart';
import 'package:ourney/features/journeys/ui/dead_uploads_banner.dart';

import '../../app/test_helpers.dart';

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
}
