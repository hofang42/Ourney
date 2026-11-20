import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/features/profile/settings_providers.dart';
import 'package:ourney/features/profile/share_privacy_sync.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/test_helpers.dart';
import '../journeys/journeys_fakes.dart';

/// C-B1: the Settings switches reach every membership, switching OFF leaves
/// explicit per-journey choices alone.
void main() {
  Future<(WidgetRef, FakeJourneyRepository)> pump(WidgetTester tester) async {
    final prefs = await tester.runAsync(() => testPrefs({}));
    final repo = FakeJourneyRepository(
      journeys: [
        testJourney(id: 'kg', metricName: 'Cân nặng', metricUnit: 'kg'),
        testJourney(id: 'min', metricName: 'Thời gian', metricUnit: 'phút'),
        testJourney(
          id: 'old',
          status: JourneyStatus.archived,
          metricName: 'Cân nặng',
          metricUnit: 'kg',
        ),
      ],
    );
    late WidgetRef ref;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          journeyRepositoryProvider.overrideWithValue(repo),
          sharedPreferencesProvider.overrideWithValue(prefs!),
        ],
        child: Consumer(
          builder: (context, r, _) {
            ref = r;
            return const SizedBox();
          },
        ),
      ),
    );
    return (ref, repo);
  }

  testWidgets('switch on: only kg journeys get hide-kg, archived included', (
    tester,
  ) async {
    final (ref, repo) = await pump(tester);
    await tester.runAsync(
      () => ref.read(hideWeightOnShareProvider.notifier).set(true),
    );
    await pushSharePrivacyToMemberships(ref, hideWeight: true);
    expect(
      {for (final u in repo.prefUpdates) u.id: u.hideMetric},
      {'kg': true, 'old': true},
    );
  });

  testWidgets('blur on reaches every journey', (tester) async {
    final (ref, repo) = await pump(tester);
    await tester.runAsync(
      () => ref.read(blurPhotosOnShareProvider.notifier).set(true),
    );
    await pushSharePrivacyToMemberships(ref, blur: true);
    expect(repo.prefUpdates.map((u) => u.id).toSet(), {'kg', 'min', 'old'});
    expect(repo.prefUpdates.every((u) => u.blurMedia == true), isTrue);
  });

  testWidgets('switch off leaves per-journey choices alone', (tester) async {
    final (ref, repo) = await pump(tester);
    await pushSharePrivacyToMemberships(ref, hideWeight: false, blur: false);
    expect(repo.prefUpdates, isEmpty);
  });

  testWidgets('a switch turned off again before the push writes nothing', (
    tester,
  ) async {
    final (ref, repo) = await pump(tester);
    await tester.runAsync(
      () => ref.read(hideWeightOnShareProvider.notifier).set(true),
    );
    final push = pushSharePrivacyToMemberships(ref, hideWeight: true);
    await tester.runAsync(
      () => ref.read(hideWeightOnShareProvider.notifier).set(false),
    );
    await push;
    expect(repo.prefUpdates, isEmpty);
  });

  testWidgets('a new membership only updates its own journey', (tester) async {
    final (ref, repo) = await pump(tester);
    await tester.runAsync(
      () => ref.read(blurPhotosOnShareProvider.notifier).set(true),
    );
    await pushSharePrivacyToJourney(ref, 'min');
    expect(repo.prefUpdates.map((u) => u.id), ['min']);
  });

  testWidgets('still applies the switches when the caller is disposed', (
    tester,
  ) async {
    final (ref, repo) = await pump(tester);
    await tester.runAsync(() async {
      await ref.read(hideWeightOnShareProvider.notifier).set(true);
      await ref.read(blurPhotosOnShareProvider.notifier).set(true);
    });
    final push = pushSharePrivacyToJourney(ref, 'kg');
    await tester.pumpWidget(const SizedBox());
    await push;
    expect(repo.prefUpdates.single.id, 'kg');
    expect(repo.prefUpdates.single.hideMetric, isTrue);
    expect(repo.prefUpdates.single.blurMedia, isTrue);
  });
}
