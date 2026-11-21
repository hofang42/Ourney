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
class _User extends CurrentUserId {
  @override
  String? build() => 'user-a';
}

void main() {
  Future<(WidgetRef, FakeJourneyRepository, ProviderContainer)> pump(
    WidgetTester tester,
  ) async {
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
    late ProviderContainer container;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          journeyRepositoryProvider.overrideWithValue(repo),
          sharedPreferencesProvider.overrideWithValue(prefs!),
          currentUserIdProvider.overrideWith(_User.new),
        ],
        child: Consumer(
          builder: (context, r, _) {
            ref = r;
            container = ProviderScope.containerOf(context);
            return const SizedBox();
          },
        ),
      ),
    );
    return (ref, repo, container);
  }

  testWidgets('switch on: only kg journeys get hide-kg, archived included', (
    tester,
  ) async {
    final (ref, repo, container) = await pump(tester);
    await tester.runAsync(
      () => ref.read(hideWeightOnShareProvider.notifier).set(true),
    );
    await pushSharePrivacyToMemberships(container, hideWeight: true);
    expect(
      {for (final u in repo.prefUpdates) u.id: u.hideMetric},
      {'kg': true, 'old': true},
    );
  });

  testWidgets('blur on reaches every journey', (tester) async {
    final (ref, repo, container) = await pump(tester);
    await tester.runAsync(
      () => ref.read(blurPhotosOnShareProvider.notifier).set(true),
    );
    await pushSharePrivacyToMemberships(container, blur: true);
    expect(repo.prefUpdates.map((u) => u.id).toSet(), {'kg', 'min', 'old'});
    expect(repo.prefUpdates.every((u) => u.blurMedia == true), isTrue);
  });

  testWidgets('switch off leaves per-journey choices alone', (tester) async {
    final (ref, repo, container) = await pump(tester);
    await pushSharePrivacyToMemberships(
      container,
      hideWeight: false,
      blur: false,
    );
    expect(repo.prefUpdates, isEmpty);
  });

  testWidgets('a switch turned off again before the push writes nothing', (
    tester,
  ) async {
    final (ref, repo, container) = await pump(tester);
    await tester.runAsync(
      () => ref.read(hideWeightOnShareProvider.notifier).set(true),
    );
    final push = pushSharePrivacyToMemberships(container, hideWeight: true);
    await tester.runAsync(
      () => ref.read(hideWeightOnShareProvider.notifier).set(false),
    );
    await push;
    expect(repo.prefUpdates, isEmpty);
  });

  testWidgets('a new membership only updates its own journey', (tester) async {
    final (ref, repo, container) = await pump(tester);
    await tester.runAsync(
      () => ref.read(blurPhotosOnShareProvider.notifier).set(true),
    );
    await pushSharePrivacyToJourney(ref, 'min');
    expect(repo.prefUpdates.map((u) => u.id), ['min']);
  });

  testWidgets('still applies the switches when the caller is disposed', (
    tester,
  ) async {
    final (ref, repo, container) = await pump(tester);
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

  testWidgets('heal re-applies only the failed flag of the failed journey', (
    tester,
  ) async {
    final (ref, repo, container) = await pump(tester);
    await tester.runAsync(
      () => ref.read(blurPhotosOnShareProvider.notifier).set(true),
    );
    // New group membership 'min' fails; 'kg' was set OFF by the user.
    repo.prefError = const OurneyException(OurneyErrorCode.offline);
    await pushSharePrivacyToJourney(ref, 'min');
    expect(pendingSharePrivacy(container), {'min': (hide: false, blur: true)});
    repo.prefError = null;
    await healSharePrivacy(container);
    expect(repo.prefUpdates.map((u) => u.id), ['min']);
    expect(repo.prefUpdates.single.hideMetric, isNull);
    expect(pendingSharePrivacy(container), isEmpty);
  });

  testWidgets('heal skips a flag whose switch is OFF again and forgets it', (
    tester,
  ) async {
    final (ref, repo, container) = await pump(tester);
    await tester.runAsync(
      () => ref.read(blurPhotosOnShareProvider.notifier).set(true),
    );
    repo.prefError = const OurneyException(OurneyErrorCode.offline);
    await pushSharePrivacyToJourney(ref, 'min');
    repo.prefError = null;
    await tester.runAsync(
      () => ref.read(blurPhotosOnShareProvider.notifier).set(false),
    );
    await healSharePrivacy(container);
    expect(repo.prefUpdates, isEmpty);
    expect(pendingSharePrivacy(container), isEmpty);
  });

  testWidgets(
    'a toggle turned OFF while the push runs writes nothing (container read)',
    (tester) async {
      final (ref, repo, container) = await pump(tester);
      await tester.runAsync(
        () => ref.read(blurPhotosOnShareProvider.notifier).set(true),
      );
      final push = pushSharePrivacyToMemberships(container, blur: true);
      await tester.runAsync(
        () => container.read(blurPhotosOnShareProvider.notifier).set(false),
      );
      await push;
      expect(repo.prefUpdates, isEmpty);
    },
  );

  testWidgets('a hand-set journey choice forgets the waiting heal', (
    tester,
  ) async {
    final (ref, repo, container) = await pump(tester);
    await tester.runAsync(
      () => ref.read(blurPhotosOnShareProvider.notifier).set(true),
    );
    repo.prefError = const OurneyException(OurneyErrorCode.offline);
    await pushSharePrivacyToJourney(ref, 'min');
    expect(pendingSharePrivacy(container), isNotEmpty);
    forgetSharePrivacyHeal(ref, 'min', blur: true);
    expect(pendingSharePrivacy(container), isEmpty);
    repo.prefError = null;
    await healSharePrivacy(container);
    expect(repo.prefUpdates, isEmpty);
  });

  testWidgets('a later successful push drops the waiting heal', (tester) async {
    final (ref, repo, container) = await pump(tester);
    await tester.runAsync(
      () => ref.read(blurPhotosOnShareProvider.notifier).set(true),
    );
    repo.prefError = const OurneyException(OurneyErrorCode.offline);
    await pushSharePrivacyToJourney(ref, 'min');
    repo.prefError = null;
    await pushSharePrivacyToJourney(ref, 'min');
    expect(pendingSharePrivacy(container), isEmpty);
  });

  testWidgets('a failed journey list is recorded and healed for all', (
    tester,
  ) async {
    final (ref, repo, container) = await pump(tester);
    await tester.runAsync(
      () => ref.read(blurPhotosOnShareProvider.notifier).set(true),
    );
    repo.listError = const OurneyException(OurneyErrorCode.offline);
    await pushSharePrivacyToMemberships(container, blur: true);
    expect(pendingSharePrivacy(container).keys, ['*']);
    repo.listError = null;
    await healSharePrivacy(container);
    expect(repo.prefUpdates.map((u) => u.id).toSet(), {'kg', 'min', 'old'});
    expect(pendingSharePrivacy(container), isEmpty);
  });

  testWidgets('an expired session records nothing', (tester) async {
    final (ref, repo, container) = await pump(tester);
    await tester.runAsync(
      () => ref.read(blurPhotosOnShareProvider.notifier).set(true),
    );
    repo.prefError = const OurneyException(OurneyErrorCode.unauthenticated);
    await pushSharePrivacyToJourney(ref, 'min');
    expect(pendingSharePrivacy(container), isEmpty);
  });

  testWidgets('the all-marker skips a journey set by hand meanwhile', (
    tester,
  ) async {
    final (ref, repo, container) = await pump(tester);
    await tester.runAsync(
      () => ref.read(blurPhotosOnShareProvider.notifier).set(true),
    );
    repo.listError = const OurneyException(OurneyErrorCode.offline);
    await pushSharePrivacyToMemberships(container, blur: true);
    repo.listError = null;
    forgetSharePrivacyHeal(ref, 'min', blur: true);
    await healSharePrivacy(container);
    expect(repo.prefUpdates.map((u) => u.id).toSet(), {'kg', 'old'});
    expect(pendingSharePrivacy(container), isEmpty);
  });

  testWidgets('the all-marker survives one journey that left (notFound)', (
    tester,
  ) async {
    final (ref, repo, container) = await pump(tester);
    await tester.runAsync(
      () => ref.read(blurPhotosOnShareProvider.notifier).set(true),
    );
    repo.listError = const OurneyException(OurneyErrorCode.offline);
    await pushSharePrivacyToMemberships(container, blur: true);
    repo.listError = null;
    repo.prefErrorFor['kg'] = const OurneyException(OurneyErrorCode.notFound);
    await healSharePrivacy(container);
    expect(repo.prefUpdates.map((u) => u.id).toSet(), {'min', 'old'});
    expect(pendingSharePrivacy(container), isEmpty);
  });

  testWidgets('a full push that succeeds clears the all-marker', (
    tester,
  ) async {
    final (ref, repo, container) = await pump(tester);
    await tester.runAsync(
      () => ref.read(blurPhotosOnShareProvider.notifier).set(true),
    );
    repo.listError = const OurneyException(OurneyErrorCode.offline);
    await pushSharePrivacyToMemberships(container, blur: true);
    repo.listError = null;
    await pushSharePrivacyToMemberships(container, blur: true);
    expect(pendingSharePrivacy(container), isEmpty);
  });
}
