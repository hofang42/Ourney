import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/app/router.dart';
import 'package:ourney/app/theme/persona_theme.dart';
import 'package:ourney/features/camera/camera_providers.dart';
import 'package:ourney_core/ourney_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/journeys/journeys_fakes.dart';
import 'test_helpers.dart';

final _running = testJourney(id: 'run', templateId: TemplateId.workout30);
final _trip = testJourney(id: 'trip', templateId: TemplateId.travel);
final _diet = testJourney(id: 'diet', templateId: TemplateId.weightLoss);

Future<(ProviderContainer, SharedPreferencesWithCache)> _container({
  List<Journey> journeys = const [],
  Map<String, Object> prefs = const {},
  bool wired = true,
}) async {
  final store = await testPrefs(prefs);
  final c = ProviderContainer.test(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(store),
      if (wired)
        journeyRepositoryProvider.overrideWithValue(
          FakeJourneyRepository(journeys: journeys),
        ),
    ],
  );
  // Providers are keepAlive; hold the stream open like the app does.
  c.listen(activePersonaSkinProvider, (_, _) {});
  return (c, store);
}

Future<PersonaSkinId?> _skin(ProviderContainer c) async {
  await c.read(activeJourneyProvider.future);
  return c.read(activePersonaSkinProvider);
}

void main() {
  group('activeJourneyIdProvider (F2)', () {
    test('starts from the id the camera remembered', () async {
      final (c, _) = await _container(
        prefs: {CameraPrefs.lastJourneyId: 'trip'},
      );
      expect(c.read(activeJourneyIdProvider), 'trip');
    });

    test('starts empty on a fresh install', () async {
      final (c, _) = await _container();
      expect(c.read(activeJourneyIdProvider), isNull);
    });

    test(
      'select updates the state and saves it in camera.lastJourneyId',
      () async {
        final (c, store) = await _container();
        await c.read(activeJourneyIdProvider.notifier).select('trip');
        expect(c.read(activeJourneyIdProvider), 'trip');
        expect(store.getString('camera.lastJourneyId'), 'trip');
        expect(CameraPrefs.readLastJourneyId(store), 'trip');
      },
    );
  });

  group('activePersonaSkinProvider (F2)', () {
    test('is the neutral base (null) with no journey', () async {
      final (c, _) = await _container();
      expect(await _skin(c), isNull);
    });

    test('follows the first active journey until one is picked', () async {
      final (c, _) = await _container(journeys: [_running, _trip]);
      expect(await _skin(c), PersonaSkinId.aestheticFlexer);
    });

    test('switching journey changes the skin', () async {
      final (c, _) = await _container(journeys: [_running, _trip, _diet]);
      expect(await _skin(c), PersonaSkinId.aestheticFlexer);

      await c.read(activeJourneyIdProvider.notifier).select('trip');
      expect(await _skin(c), PersonaSkinId.memoryCollectors);

      await c.read(activeJourneyIdProvider.notifier).select('diet');
      expect(await _skin(c), PersonaSkinId.quietTransformer);
    });

    test('a remembered journey that is gone falls back to the first', () async {
      final (c, _) = await _container(
        journeys: [_running, _trip],
        prefs: {CameraPrefs.lastJourneyId: 'deleted'},
      );
      expect(await _skin(c), PersonaSkinId.aestheticFlexer);
    });

    test('an ended journey no longer themes the app', () async {
      final ended = testJourney(
        id: 'old',
        templateId: TemplateId.travel,
        status: JourneyStatus.ended,
      );
      final (c, _) = await _container(
        journeys: [ended, _running],
        prefs: {CameraPrefs.lastJourneyId: 'old'},
      );
      expect(await _skin(c), PersonaSkinId.aestheticFlexer);
    });

    test('is null, not an error, while the data layer is not wired', () async {
      final (c, _) = await _container(wired: false);
      expect(c.read(activePersonaSkinProvider), isNull);
    });
  });

  group('app theme follows the active journey (F2)', () {
    testWidgets('colors morph in place: same router, no route reload', (
      tester,
    ) async {
      final repo = FakeJourneyRepository(journeys: [_running, _trip]);
      final container = await pumpOurneyApp(
        tester,
        overrides: [journeyRepositoryProvider.overrideWithValue(repo)],
      );
      OurneyPersonaTheme persona() =>
          OurneyPersonaTheme.of(tester.element(find.byType(Scaffold).first));
      Future<void> settle() => tester.pump(const Duration(milliseconds: 400));

      await settle();
      expect(persona().skinId, PersonaSkinId.aestheticFlexer);

      final router = container.read(routerProvider);
      final location = router.state.uri.toString();

      await container.read(activeJourneyIdProvider.notifier).select('trip');
      // One frame for the new stream value, one to start the animation.
      await tester.pump();
      await tester.pump();
      // 320ms theme animation: half way the colors are in between.
      await tester.pump(const Duration(milliseconds: 160));
      final mid = persona().primaryAccent;
      final from = OurneyPersonaTheme.forSkin(
        PersonaSkinId.aestheticFlexer,
        Brightness.light,
      ).primaryAccent;
      final to = OurneyPersonaTheme.forSkin(
        PersonaSkinId.memoryCollectors,
        Brightness.light,
      ).primaryAccent;
      expect(mid, isNot(from));
      expect(mid, isNot(to));

      await settle();
      expect(persona().skinId, PersonaSkinId.memoryCollectors);
      expect(persona().primaryAccent, to);
      expect(container.read(routerProvider), same(router));
      expect(router.state.uri.toString(), location);
    });
  });
}
