import 'dart:async';

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

  void switchTo(String id) => state = id;
}

void main() {
  Future<(WidgetRef, FakeJourneyRepository, ProviderContainer)> pump(
    WidgetTester tester, {
    FakeJourneyRepository? journeys,
    bool hideWeight = false,
    Stream<void>? serverPulls,
    bool lifecycle = false,
  }) async {
    final prefs = await tester.runAsync(
      () => testPrefs({SharePrivacyPrefs.hideWeight: hideWeight}),
    );
    final repo =
        journeys ??
        FakeJourneyRepository(
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
            return lifecycle
                ? SharePrivacyHealHook(
                    serverPulls: serverPulls,
                    child: const SizedBox(),
                  )
                : const SizedBox();
          },
        ),
      ),
    );
    return (ref, repo, container);
  }

  testWidgets('startup and resume reconcile weight without a pending failure', (
    tester,
  ) async {
    final old = Journey(
      id: 'previous-link',
      ownerId: 'user-a',
      kind: JourneyKind.solo,
      templateId: TemplateId.custom,
      title: 'Weight log',
      emoji: '📝',
      startDate: const LocalDate(2026, 10, 10),
      timezone: testTz,
      metricName: 'Reading',
      metricUnit: 'lbs',
      status: JourneyStatus.archived,
      visibility: JourneyVisibility.link,
      publicToken: 'a' * 40,
    );
    final study = testJourney(
      id: 'study',
      templateId: TemplateId.custom,
      metricName: 'Time',
      metricUnit: 'min',
    ).copyWith(layout: PersonaSkinId.quietTransformer);
    final repo = FakeJourneyRepository(
      journeys: [old, study],
      memberships: {
        old.id: testMembership(old),
        study.id: testMembership(study),
      },
    );
    final (_, _, container) = await pump(
      tester,
      journeys: repo,
      hideWeight: true,
      lifecycle: true,
    );
    await tester.pumpAndSettle();
    expect(pendingSharePrivacy(container), isEmpty);
    expect(repo.prefUpdates, [(id: old.id, hideMetric: true, blurMedia: null)]);

    repo.prefUpdates.clear();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(repo.prefUpdates, [(id: old.id, hideMetric: true, blurMedia: null)]);
  });

  testWidgets(
    'a completed startup pull also reconciles newly loaded journeys',
    (tester) async {
      final pulls = StreamController<void>();
      addTearDown(pulls.close);
      final hidden = testJourney(id: 'hidden', metricUnit: 'lb');
      final repo = FakeJourneyRepository(
        journeys: [hidden],
        memberships: {hidden.id: testMembership(hidden, hideMetric: true)},
      );
      await pump(
        tester,
        journeys: repo,
        hideWeight: true,
        lifecycle: true,
        serverPulls: pulls.stream,
      );
      await tester.pumpAndSettle();
      expect(repo.prefUpdates, isEmpty);
      final imported = await repo.create(
        JourneyDraft(
          kind: JourneyKind.solo,
          templateId: TemplateId.custom,
          title: 'Old diary',
          emoji: '📝',
          startDate: const LocalDate(2026, 10, 10),
          timezone: testTz,
          metricUnit: 'lb',
        ),
      );
      pulls.add(null);
      await tester.pumpAndSettle();
      expect(repo.prefUpdates, [
        (id: imported.id, hideMetric: true, blurMedia: null),
      ]);
    },
  );

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

  testWidgets('DE-12: switch off syncs false to memberships', (tester) async {
    final (ref, repo, container) = await pump(tester);
    await pushSharePrivacyToMemberships(
      container,
      hideWeight: false,
      blur: false,
    );
    expect(
      {for (final u in repo.prefUpdates) u.id: (u.hideMetric, u.blurMedia)},
      {
        'kg': (false, false),
        'min': (null, false),
        'old': (false, false),
      },
    );
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

  testWidgets(
    'DE-12 / M1: heal pushes false when the switch is turned OFF before heal',
    (tester) async {
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
      expect(
        {for (final u in repo.prefUpdates) u.id: u.blurMedia},
        {'min': false},
      );
      expect(pendingSharePrivacy(container), isEmpty);
    },
  );

  testWidgets(
    'DE-12 / M1: toggling Hide kg and Blur photos OFF while offline heals to '
    'false on reconnect',
    (tester) async {
      final (ref, repo, container) = await pump(tester);
      await tester.runAsync(() async {
        await ref.read(hideWeightOnShareProvider.notifier).set(false);
        await ref.read(blurPhotosOnShareProvider.notifier).set(false);
      });
      repo.prefError = const OurneyException(OurneyErrorCode.offline);
      await pushSharePrivacyToMemberships(
        container,
        hideWeight: false,
        blur: false,
      );
      expect(repo.prefUpdates, isEmpty);
      expect(pendingSharePrivacy(container), {
        'kg': (hide: true, blur: true),
        'min': (hide: false, blur: true),
        'old': (hide: true, blur: true),
      });

      repo.prefError = null;
      await healSharePrivacy(container);
      expect(
        {for (final u in repo.prefUpdates) u.id: (u.hideMetric, u.blurMedia)},
        {
          'kg': (false, false),
          'min': (null, false),
          'old': (false, false),
        },
      );
      expect(pendingSharePrivacy(container), isEmpty);
    },
  );

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

  testWidgets('a hand-set choice during a failing full push stays protected', (
    tester,
  ) async {
    final (ref, repo, container) = await pump(tester);
    await tester.runAsync(
      () => ref.read(blurPhotosOnShareProvider.notifier).set(true),
    );
    // Full push starts (marks "in flight"); the user sets 'min' by hand
    // before it finishes; then its update of 'min' fails.
    repo.prefErrorFor['min'] = const OurneyException(OurneyErrorCode.offline);
    final push = pushSharePrivacyToMemberships(container, blur: true);
    forgetSharePrivacyHeal(ref, 'min', blur: true);
    await push;
    repo.prefErrorFor.clear();
    repo.prefUpdates.clear();
    await healSharePrivacy(container);
    expect(repo.prefUpdates.map((u) => u.id), isNot(contains('min')));
  });

  testWidgets('blur on, off, on: a real later failure still heals', (
    tester,
  ) async {
    final (ref, repo, container) = await pump(tester);
    final blurSwitch = ref.read(blurPhotosOnShareProvider.notifier);
    await tester.runAsync(() => blurSwitch.set(true));
    await pushSharePrivacyToMemberships(container, blur: true); // push 1 ok
    await tester.runAsync(() => blurSwitch.set(false));
    await tester.runAsync(() => blurSwitch.set(true));
    repo.prefErrorFor['min'] = const OurneyException(OurneyErrorCode.offline);
    await pushSharePrivacyToMemberships(container, blur: true); // push 2 fails
    expect(pendingSharePrivacy(container).keys, ['min']);
    repo.prefErrorFor.clear();
    repo.prefUpdates.clear();
    await healSharePrivacy(container);
    expect(repo.prefUpdates.map((u) => u.id), ['min']);
  });

  testWidgets('another account never clears this record', (tester) async {
    final (ref, repo, container) = await pump(tester);
    await tester.runAsync(
      () => ref.read(blurPhotosOnShareProvider.notifier).set(true),
    );
    repo.prefError = const OurneyException(OurneyErrorCode.offline);
    await pushSharePrivacyToJourney(ref, 'min');
    expect(pendingSharePrivacy(container), isNotEmpty);
    final prefs = container.read(sharedPreferencesProvider);
    final before = prefs.getString(SharePrivacyPrefs.pendingHeal);
    // Another user acts: their clears must not touch the stored record.
    (container.read(currentUserIdProvider.notifier) as _User).switchTo(
      'user-b',
    );
    forgetSharePrivacyHeal(ref, 'min', blur: true);
    repo.prefError = null;
    await pushSharePrivacyToJourney(ref, 'kg');
    expect(prefs.getString(SharePrivacyPrefs.pendingHeal), before);
  });

  testWidgets('a hand-set choice during a heal is not overwritten', (
    tester,
  ) async {
    final (ref, repo, container) = await pump(tester);
    await tester.runAsync(
      () => ref.read(blurPhotosOnShareProvider.notifier).set(true),
    );
    repo.prefError = const OurneyException(OurneyErrorCode.offline);
    await pushSharePrivacyToJourney(ref, 'kg');
    await pushSharePrivacyToJourney(ref, 'min');
    repo.prefError = null;
    repo.prefUpdates.clear();
    final gate = repo.prefGate = Completer<void>();
    final heal = healSharePrivacy(container);
    await tester.pump(); // the heal is now stuck on its first update
    forgetSharePrivacyHeal(ref, 'min', blur: true);
    repo.prefGate = null;
    gate.complete();
    await heal;
    expect(repo.prefUpdates.map((u) => u.id), ['kg']);
    expect(pendingSharePrivacy(container), isEmpty);
  });

  testWidgets('overlapping pushes: a later push failure is still recorded', (
    tester,
  ) async {
    final (ref, repo, container) = await pump(tester);
    await tester.runAsync(() async {
      await ref.read(blurPhotosOnShareProvider.notifier).set(true);
      await ref.read(hideWeightOnShareProvider.notifier).set(true);
    });
    repo.prefErrorFor['min'] = const OurneyException(OurneyErrorCode.offline);
    final first = pushSharePrivacyToMemberships(container, blur: true);
    // Hand-set during push 1; push 2 (mixed flags) starts afterwards.
    forgetSharePrivacyHeal(ref, 'min', blur: true);
    final second = pushSharePrivacyToMemberships(
      container,
      hideWeight: true,
      blur: true,
    );
    await Future.wait([first, second]);
    // Push 1's failure is superseded by the hand-set; push 2's is real.
    expect(pendingSharePrivacy(container)['min'], (hide: false, blur: true));
  });
}
