import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/app_routes.dart';
import 'package:ourney/features/journeys/journeys_paths.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/test_helpers.dart';
import 'journeys_fakes.dart';

Finder _key(String k) => find.byKey(ValueKey(k));

bool _switchValue(WidgetTester tester, String key) =>
    tester.widget<SwitchListTile>(_key(key)).value;

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  group('Create journey (FR-B1/B2/B7)', () {
    testWidgets('picker lists the 4 templates and Custom', (tester) async {
      await pumpJourneys(
        tester,
        location: AppRoutes.journeyNew,
        locale: const Locale('en'),
      );
      for (final t in TemplateId.values) {
        expect(_key('template-${t.wireName}'), findsOneWidget);
      }
      expect(find.text('Weight loss'), findsOneWidget);
    });

    testWidgets('weight loss: hides kg and blurs shares by default', (
      tester,
    ) async {
      final h = await pumpJourneys(
        tester,
        location: AppRoutes.journeyNew,
        locale: const Locale('en'),
      );
      await _tap(tester, _key('template-weight_loss'));
      expect(h.location, JourneysPaths.newFromTemplate(TemplateId.weightLoss));

      final title = tester.widget<TextField>(_key('journey-title'));
      expect(title.controller!.text, 'Weight loss');
      expect(_switchValue(tester, 'journey-metric'), isTrue);
      expect(
        tester.widget<TextField>(_key('journey-metric-unit')).controller!.text,
        'kg',
      );
      expect(_switchValue(tester, 'journey-hide-metric'), isTrue);
      expect(_switchValue(tester, 'journey-blur'), isTrue);
      expect(tester.widget<Text>(_key('journey-timezone')).data, testTz);

      await _tap(tester, _key('journey-create'));

      expect(h.journeys.created, hasLength(1));
      final draft = h.journeys.created.single;
      expect(draft.templateId, TemplateId.weightLoss);
      expect(draft.kind, JourneyKind.solo);
      expect(draft.durationDays, 30);
      expect(draft.metricUnit, 'kg');
      expect(draft.hideMetricDefault, isTrue);
      expect(draft.visibility, JourneyVisibility.private);
      expect(draft.timezone, testTz);
      expect(draft.startDate, testToday);
      expect(h.journeys.prefUpdates.single, (
        id: 'new-1',
        hideMetric: true,
        blurMedia: true,
      ));
      expect(h.location, AppRoutes.journey('new-1'));
    });

    testWidgets('other templates use their own defaults, no blur', (
      tester,
    ) async {
      final h = await pumpJourneys(
        tester,
        location: JourneysPaths.newFromTemplate(TemplateId.travel),
        locale: const Locale('en'),
      );
      final travel = templateFor(TemplateId.travel);
      expect(
        tester.widget<TextField>(_key('journey-title')).controller!.text,
        travel.titleEn,
      );
      expect(_switchValue(tester, 'journey-blur'), isFalse);
      expect(_switchValue(tester, 'journey-metric'), isFalse);
      expect(_key('journey-duration-open'), findsOneWidget);

      await _tap(tester, _key('journey-duration-open'));
      await _tap(tester, _key('journey-create'));

      final draft = h.journeys.created.single;
      expect(draft.durationDays, isNull);
      expect(draft.metricName, isNull);
      expect(h.journeys.prefUpdates, isEmpty);
    });

    testWidgets('custom: validates title, duration and metric name', (
      tester,
    ) async {
      final h = await pumpJourneys(
        tester,
        location: JourneysPaths.newFromTemplate(TemplateId.custom),
        locale: const Locale('en'),
      );
      expect(
        tester.widget<TextField>(_key('journey-title')).controller!.text,
        isEmpty,
      );

      await _tap(tester, _key('journey-create'));
      expect(find.text('Give your journey a name.'), findsOneWidget);
      expect(h.journeys.created, isEmpty);

      await tester.enterText(
        _key('journey-title'),
        'x' * (journeyTitleMax + 1),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Names can be up to $journeyTitleMax characters.'),
        findsOneWidget,
      );

      await tester.enterText(_key('journey-title'), 'Uống nước');
      await tester.enterText(_key('journey-duration'), '${durationMax + 1}');
      await tester.pumpAndSettle();
      expect(
        find.text('Duration must be $durationMin to $durationMax days.'),
        findsOneWidget,
      );

      await tester.enterText(_key('journey-duration'), '21');
      await _tap(tester, _key('journey-metric'));
      await _tap(tester, _key('journey-create'));
      expect(find.text('Enter a metric name.'), findsOneWidget);
      expect(h.journeys.created, isEmpty);

      await tester.enterText(_key('journey-metric-name'), 'Lít');
      await tester.pumpAndSettle();
      await _tap(tester, _key('journey-create'));

      final draft = h.journeys.created.single;
      expect(draft.title, 'Uống nước');
      expect(draft.durationDays, 21);
      expect(draft.metricName, 'Lít');
      expect(draft.metricUnit, isNull);
      expect(h.location, AppRoutes.journey('new-1'));
    });

    testWidgets('local-only: group and link are unavailable', (tester) async {
      final h = await pumpJourneys(
        tester,
        location: JourneysPaths.newFromTemplate(TemplateId.workout30),
        locale: const Locale('en'),
      );
      expect(
        find.text(
          'Group journeys need a server. This build runs on this device only.',
        ),
        findsOneWidget,
      );
      await _tap(tester, _key('journey-kind-group'));
      await _tap(tester, _key('journey-visibility-link'));
      await _tap(tester, _key('journey-create'));
      final draft = h.journeys.created.single;
      expect(draft.kind, JourneyKind.solo);
      expect(draft.visibility, JourneyVisibility.private);
    });

    testWidgets('with a server: group journeys use fixed group visibility', (
      tester,
    ) async {
      final h = await pumpJourneys(
        tester,
        config: testBackendConfig,
        userId: 'u1',
        location: JourneysPaths.newFromTemplate(TemplateId.workout30),
        locale: const Locale('en'),
      );
      await _tap(tester, _key('journey-visibility-link'));
      await _tap(tester, _key('journey-kind-group'));
      expect(_key('journey-visibility-link'), findsNothing);
      expect(find.text('Group members'), findsOneWidget);
      await _tap(tester, _key('journey-create'));
      final draft = h.journeys.created.single;
      expect(draft.kind, JourneyKind.group);
      expect(draft.visibility, JourneyVisibility.group);
    });

    testWidgets('solo link visibility with a server', (tester) async {
      final h = await pumpJourneys(
        tester,
        config: testBackendConfig,
        userId: 'u1',
        location: JourneysPaths.newFromTemplate(TemplateId.englishDaily),
      );
      await _tap(tester, _key('journey-visibility-link'));
      await _tap(tester, _key('journey-create'));
      expect(h.journeys.created.single.visibility, JourneyVisibility.link);
    });

    testWidgets('server limit error shows the friendly limit dialog', (
      tester,
    ) async {
      final repo = FakeJourneyRepository()
        ..createError = const OurneyException(OurneyErrorCode.limit);
      final h = await pumpJourneys(
        tester,
        journeys: repo,
        location: JourneysPaths.newFromTemplate(TemplateId.workout30),
        locale: const Locale('en'),
      );
      await _tap(tester, _key('journey-create'));
      expect(_key('journeys-limit-dialog'), findsOneWidget);
      expect(h.location, JourneysPaths.newFromTemplate(TemplateId.workout30));
    });

    testWidgets('unknown template in the URL falls back to Custom', (
      tester,
    ) async {
      await pumpJourneys(tester, location: '${AppRoutes.journeyNew}/nope');
      expect(_key('journeys-create'), findsOneWidget);
      expect(
        tester.widget<TextField>(_key('journey-title')).controller!.text,
        isEmpty,
      );
    });
  });
}
