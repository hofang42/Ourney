import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/theme/persona_theme.dart';
import 'package:ourney/app/theme/tokens.dart';
import 'package:ourney/features/groups/domain/group_today.dart';
import 'package:ourney/features/journeys/domain/journey_progress.dart';
import 'package:ourney/personas/accountability_squad/persona_widgets.dart';
import 'package:ourney/personas/accountability_squad/share_card.dart';
import 'package:ourney/personas/memory_collectors/camera_hud.dart';
import 'package:ourney/personas/memory_collectors/timeline.dart';
import 'package:ourney/personas/persona_contract.dart';
import 'package:ourney/personas/persona_switchers.dart';
import 'package:ourney_core/ourney_core.dart';

import 'pump_persona.dart';

Journey _journey(TemplateId template) => Journey(
  id: 'j-${template.name}',
  ownerId: 'me',
  kind: JourneyKind.solo,
  templateId: template,
  title: 'Hành trình',
  emoji: '🏃',
  startDate: const LocalDate(2026, 10, 1),
  durationDays: 30,
  timezone: 'Asia/Ho_Chi_Minh',
  visibility: JourneyVisibility.private,
  status: JourneyStatus.active,
);

PersonaTimelineData _timeline(Journey j) => PersonaTimelineData(
  journey: j,
  days: [
    for (var i = 1; i <= 7; i++)
      TimelineDay(
        date: const LocalDate(2026, 10, 1).addDays(i - 1),
        dayNumber: i,
        state: i == 7 ? DayState.today : DayState.missed,
        isToday: i == 7,
      ),
  ],
);

PersonaCameraData _camera(Journey j) => PersonaCameraData(
  journey: j,
  viewfinder: const ColoredBox(
    key: ValueKey('viewfinder'),
    color: Colors.black,
  ),
  capturedAt: DateTime(2026, 10, 8, 6, 15),
);

void main() {
  group('PersonaSkinScope', () {
    testWidgets('makes OurneyPersonaTheme.of resolve to its own skin and '
        'keeps the other theme extensions', (tester) async {
      late BuildContext inner;
      await pumpPersona(
        tester,
        PersonaSkinScope(
          skin: PersonaSkinId.memoryCollectors,
          child: Builder(
            builder: (context) {
              inner = context;
              return const SizedBox();
            },
          ),
        ),
        skin: PersonaSkinId.quietTransformer,
        brightness: Brightness.dark,
      );
      final scoped = OurneyPersonaTheme.of(inner);
      expect(scoped.skinId, PersonaSkinId.memoryCollectors);
      expect(
        scoped.primaryAccent,
        OurneyPersonaTheme.forSkin(
          PersonaSkinId.memoryCollectors,
          Brightness.dark,
        ).primaryAccent,
      );
      expect(Theme.of(inner).extension<OurneyColors>(), isNotNull);
      expect(Theme.of(inner).brightness, Brightness.dark);
    });

    testWidgets('is a no-op when the ambient theme already has the skin', (
      tester,
    ) async {
      await pumpPersona(
        tester,
        const PersonaSkinScope(
          skin: PersonaSkinId.quietTransformer,
          child: SizedBox(key: ValueKey('child')),
        ),
      );
      expect(
        find.ancestor(
          of: find.byKey(const ValueKey('child')),
          matching: find.byType(Theme),
        ),
        findsNWidgets(1), // MaterialApp's own
      );
    });
  });

  group('PersonaTimelineSwitcher', () {
    Widget switcher(PersonaSkinId skin, TemplateId t) =>
        PersonaTimelineSwitcher(skin: skin, data: _timeline(_journey(t)));

    testWidgets('cross-fades over 260ms and leaves only the new layout', (
      tester,
    ) async {
      final a = find.byKey(const ValueKey('persona-timeline-quietTransformer'));
      final b = find.byKey(const ValueKey('persona-timeline-memoryCollectors'));
      await pumpPersona(
        tester,
        switcher(PersonaSkinId.quietTransformer, TemplateId.weightLoss),
      );
      expect(a, findsOneWidget);
      expect(b, findsNothing);

      // Same tree shape: the switcher keeps its state and animates.
      await pumpPersona(
        tester,
        switcher(PersonaSkinId.memoryCollectors, TemplateId.travel),
        skin: PersonaSkinId.memoryCollectors,
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(a, findsOneWidget, reason: 'old layout fades out');
      expect(b, findsOneWidget, reason: 'new layout fades in');

      await tester.pump(const Duration(milliseconds: 200));
      expect(a, findsNothing);
      expect(b, findsOneWidget);
    });

    testWidgets('under reduced motion the fade is 200ms', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await pumpPersona(
        tester,
        switcher(PersonaSkinId.quietTransformer, TemplateId.weightLoss),
      );
      await pumpPersona(
        tester,
        switcher(PersonaSkinId.memoryCollectors, TemplateId.travel),
        skin: PersonaSkinId.memoryCollectors,
      );
      await tester.pump(const Duration(milliseconds: 210));
      expect(
        find.byKey(const ValueKey('persona-timeline-quietTransformer')),
        findsNothing,
      );
    });

    testWidgets('draws each journey in its own persona colors even when the '
        'app theme is another', (tester) async {
      await pumpPersona(
        tester,
        switcher(PersonaSkinId.memoryCollectors, TemplateId.travel),
        skin: PersonaSkinId.aestheticFlexer,
      );
      final inner = tester.element(find.byType(ScrapbookThreadTimeline));
      expect(
        OurneyPersonaTheme.of(inner).skinId,
        PersonaSkinId.memoryCollectors,
      );
    });
  });

  group('PersonaCameraHudSwitcher', () {
    testWidgets('always shows the viewfinder, whichever persona wraps it', (
      tester,
    ) async {
      for (final skin in allSkins) {
        await pumpPersona(
          tester,
          SizedBox(
            width: 300,
            height: 400,
            child: PersonaCameraHudSwitcher(
              skin: skin,
              data: _camera(_journey(TemplateId.custom)),
            ),
          ),
          skin: skin,
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byKey(const ValueKey('viewfinder')), findsOneWidget);
      }
    });

    testWidgets('the film persona wraps it with its own HUD', (tester) async {
      await pumpPersona(
        tester,
        SizedBox(
          width: 300,
          height: 400,
          child: PersonaCameraHudSwitcher(
            skin: PersonaSkinId.memoryCollectors,
            data: _camera(_journey(TemplateId.travel)),
          ),
        ),
        skin: PersonaSkinId.memoryCollectors,
      );
      expect(find.byType(DisposableFilmStampHud), findsOneWidget);
    });
  });

  group('PersonaGroupSwitcher', () {
    final members = [
      for (var i = 0; i < 3; i++)
        GroupMemberEntry(
          member: MemberToday(
            userId: 'u$i',
            displayName: 'Bạn $i',
            role: MemberRole.member,
          ),
          isMe: i == 0,
          checkedInToday: i < 2,
          streak: i,
        ),
    ];

    Widget group(PersonaSkinId skin) => PersonaGroupSwitcher(
      skin: skin,
      data: PersonaGroupData(
        journey: _journey(TemplateId.englishDaily),
        members: members,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
      ),
      fallback: (_) => const Text('default list'),
      membersFooter: (_) => const Text('members with report and block'),
    );

    testWidgets('the squad persona shows its wall above the member list', (
      tester,
    ) async {
      await pumpPersona(
        tester,
        SingleChildScrollView(child: group(PersonaSkinId.accountabilitySquad)),
        skin: PersonaSkinId.accountabilitySquad,
      );
      expect(find.byType(SquadPolaroidWall), findsOneWidget);
      expect(find.text('members with report and block'), findsOneWidget);
      expect(find.text('default list'), findsNothing);
    });

    testWidgets('other personas keep the default list', (tester) async {
      await pumpPersona(
        tester,
        SingleChildScrollView(child: group(PersonaSkinId.quietTransformer)),
      );
      expect(find.text('default list'), findsOneWidget);
      expect(find.byType(SquadPolaroidWall), findsNothing);
    });
  });

  testWidgets('the last scrapbook Polaroid stays inside its timeline', (
    tester,
  ) async {
    final j = _journey(TemplateId.travel);
    await pumpPersona(
      tester,
      SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              key: const ValueKey('timeline-box'),
              child: ScrapbookThreadTimeline(
                journey: j,
                days: _timeline(j).days,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                photoBuilder: (_, _) => const ColoredBox(color: Colors.grey),
              ),
            ),
            const Text('Privacy'),
          ],
        ),
      ),
      skin: PersonaSkinId.memoryCollectors,
    );
    final timeline = tester.getRect(find.byKey(const ValueKey('timeline-box')));
    final lastCard = tester.getRect(find.byType(SquadPolaroidFrame).last);
    // The card hangs at most a few points over (its tilt), not by half its
    // height as before.
    expect(lastCard.bottom, lessThanOrEqualTo(timeline.bottom + 4));
    expect(
      tester.getTopLeft(find.text('Privacy')).dy,
      greaterThan(timeline.bottom - 1),
    );
  });
}
