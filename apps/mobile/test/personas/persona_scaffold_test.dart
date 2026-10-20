import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/theme/persona_theme.dart';
import 'package:ourney/features/groups/domain/group_today.dart';
import 'package:ourney/features/journeys/domain/journey_progress.dart';
import 'package:ourney/personas/persona_contract.dart';
import 'package:ourney/personas/persona_registry.dart';
import 'package:ourney_core/ourney_core.dart';

import 'pump_persona.dart';

const _start = LocalDate(2026, 10, 1);

/// Couple has no template of its own: it is `custom` with the 💞 emoji.
Journey _journey(PersonaSkinId skin) {
  final couple = skin == PersonaSkinId.coupleRituals;
  final template = couple
      ? templateFor(TemplateId.custom)
      : allTemplates.firstWhere((t) => t.personaSkinId == skin);
  return Journey(
    id: 'j-${skin.name}',
    ownerId: 'me',
    kind: JourneyKind.solo,
    templateId: template.id,
    title: 'Hành trình ${template.titleVi}',
    emoji: couple ? '💞' : template.emoji,
    startDate: _start,
    durationDays: 30,
    timezone: 'Asia/Ho_Chi_Minh',
    visibility: JourneyVisibility.private,
    status: JourneyStatus.active,
    metricName: 'Cân nặng',
    metricUnit: 'kg',
  );
}

CheckIn _checkIn(Journey j, LocalDate d, int i) => CheckIn(
  id: 'c$i',
  journeyId: j.id,
  userId: 'me',
  localDate: d,
  capturedAt: DateTime.utc(d.year, d.month, d.day, 3),
  photoPath: 'p/$i.jpg',
  thumbPath: 'p/${i}_t.jpg',
  metricValue: 70 - i * 0.5,
);

List<CheckIn> _checkIns(Journey j) => [
  for (var i = 0; i < 7; i++) _checkIn(j, _start.addDays(i), i),
];

Widget _photo(BuildContext _, Object _) => const ColoredBox(color: Colors.grey);

PersonaTimelineData _timeline(Journey j) => PersonaTimelineData.fromProgress(
  JourneyProgress.compute(
    journey: j,
    membership: null,
    checkIns: _checkIns(j),
    now: DateTime.utc(2026, 10, 8, 3),
  ),
  photoBuilder: _photo,
);

PersonaCameraData _camera(Journey j) => PersonaCameraData(
  journey: j,
  viewfinder: const ColoredBox(color: Colors.black),
  capturedAt: DateTime(2026, 10, 8, 6, 15),
  currentStreak: 7,
  checkInCount: 7,
);

PersonaShareData _share(Journey j) => PersonaShareData(
  journey: j,
  checkIns: _checkIns(j),
  currentStreak: 7,
  dayNumber: 8,
  photoBuilder: _photo,
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
);

void main() {
  test('every template maps to a skin with a style in the registry', () {
    for (final skin in allSkins) {
      expect(personaStyleFor(skin).skin, skin);
    }
    for (final skin in allSkins) {
      expect(personaSkinOf(_journey(skin)), skin);
    }
  });

  test('only the squad persona has a group wall', () {
    expect(
      {
        for (final s in allSkins)
          if (personaStyleFor(s).group != null) s,
      },
      {PersonaSkinId.accountabilitySquad},
    );
  });

  test('a two-member group journey takes the couple skin', () {
    final j = Journey(
      id: 'duo',
      ownerId: 'me',
      kind: JourneyKind.group,
      templateId: TemplateId.custom,
      title: 'Hai đứa',
      emoji: '🍳',
      startDate: _start,
      timezone: 'Asia/Ho_Chi_Minh',
      visibility: JourneyVisibility.group,
      status: JourneyStatus.active,
      maxMembers: 2,
    );
    expect(personaSkinOf(j), PersonaSkinId.coupleRituals);
  });

  test('PersonaTimelineData reads day N and the check-in count', () {
    final data = _timeline(_journey(PersonaSkinId.quietTransformer));
    expect(data.dayNumber, 8);
    expect(data.checkInCount, 7);
    expect(data.currentStreak, 7);
  });

  // The completion bar of docs/TASKS.md §2: light and dark, 320 / 390 / 430,
  // text at 1.35x, nothing overflows, for every persona and screen.
  for (final skin in allSkins) {
    for (final brightness in bothBrightness) {
      testWidgets('${skin.name} ${brightness.name}: timeline, camera and '
          'share fit 320/390/430dp at 1.35x text', (tester) async {
        final j = _journey(skin);
        final style = personaStyleFor(skin);
        final screens = <String, Widget Function(BuildContext)>{
          'timeline': (c) => style.timeline(c, _timeline(j)),
          'camera': (c) => style.camera(c, _camera(j)),
          'share': (c) => style.share(c, _share(j)),
        };
        for (final width in [320.0, 390.0, 430.0]) {
          for (final entry in screens.entries) {
            await pumpPersona(
              tester,
              Builder(builder: entry.value),
              skin: skin,
              brightness: brightness,
              width: width,
              textScale: 1.35,
            );
            await tester.pump(const Duration(milliseconds: 300));
            expect(
              tester.takeException(),
              isNull,
              reason: '${entry.key} at $width',
            );
            final pTheme = OurneyPersonaTheme.of(
              tester.element(find.byType(Scaffold)),
            );
            expect(pTheme.skinId, skin);
          }
        }
      });
    }
  }

  testWidgets('placeholder personas show their name in vi and en', (
    tester,
  ) async {
    final j = _journey(PersonaSkinId.coupleRituals);
    for (final (locale, name) in [
      (const Locale('vi'), 'Nghi thức đôi'),
      (const Locale('en'), 'Couple Rituals'),
    ]) {
      await pumpPersona(
        tester,
        Builder(
          builder: (c) =>
              personaStyleFor(PersonaSkinId.coupleRituals).share(c, _share(j)),
        ),
        skin: PersonaSkinId.coupleRituals,
        locale: locale,
      );
      expect(find.text(name), findsOneWidget);
    }
  });

  test('group data counts who checked in', () {
    final j = _journey(PersonaSkinId.accountabilitySquad);
    final data = PersonaGroupData(
      journey: j,
      members: [
        for (var i = 0; i < 3; i++)
          GroupMemberEntry(
            member: MemberToday(
              userId: 'u$i',
              displayName: 'U$i',
              role: MemberRole.member,
            ),
            isMe: i == 0,
            checkedInToday: i < 2,
            streak: i,
          ),
      ],
    );
    expect(data.doneCount, 2);
  });
}
