import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/ui/ui.dart' show UiTopBar;

import 'groups_fakes.dart';

void main() {
  group('Squad header and naming', () {
    testWidgets('uses the shared top bar: title only, no eyebrow (en)', (
      tester,
    ) async {
      await pumpGroups(
        tester,
        journeys: FakeJourneyRepository(journeys: [groupJourney()]),
      );
      final bar = tester.widget<UiTopBar>(
        find.byKey(const ValueKey('squad-top-bar')),
      );
      expect(bar.title, 'Squad');
      expect(bar.eyebrow, isNull);
      expect(bar.titleSize, 27, reason: 'default size, like the other tabs');
      expect(bar.leading, isNull);
      expect(find.text('Groups'), findsNothing);
    });

    testWidgets('dock label, header and empty state say the same word (en)', (
      tester,
    ) async {
      await pumpGroups(tester);
      final dockLabel = tester.getSemantics(
        find.byKey(const ValueKey('dock-groups')),
      );
      expect(dockLabel.label, 'Squad');
      expect(
        tester.widget<UiTopBar>(find.byType(UiTopBar)).title,
        dockLabel.label,
      );
      expect(find.text('no squads yet.'), findsOneWidget);
      expect(
        find.textContaining('group'),
        findsNothing,
        reason: 'no "group(s)" wording left on the empty tab',
      );
    });

    testWidgets('vi: dock and header are both "Nhóm"', (tester) async {
      await pumpGroups(tester, locale: const Locale('vi'));
      final dock = tester.getSemantics(
        find.byKey(const ValueKey('dock-groups')),
      );
      expect(dock.label, 'Nhóm');
      expect(tester.widget<UiTopBar>(find.byType(UiTopBar)).title, 'Nhóm');
      expect(find.text('chưa có nhóm nào.'), findsOneWidget);
    });
  });

  group('Squad card is one big button', () {
    Future<GroupsHarness> pump(WidgetTester tester) => pumpGroups(
      tester,
      journeys: FakeJourneyRepository(journeys: [groupJourney()]),
      groups: FakeGroupRepository(
        today: {
          'g1': [memberToday(me, 'Linh'), memberToday('u2', 'An')],
        },
      ),
    );

    testWidgets('tapping empty card space (not the name) opens it', (
      tester,
    ) async {
      final h = await pump(tester);
      final card = find.byKey(const ValueKey('squad-today-open-g1'));
      final r = tester.getRect(card);
      // Far right of the title row: nowhere near the name text.
      await tester.tapAt(Offset(r.right - 8, r.top + 30));
      await tester.pumpAndSettle();
      expect(h.location, '/groups/g1');
    });

    testWidgets('member chips still open their own sheet, not the group', (
      tester,
    ) async {
      final h = await pump(tester);
      await tester.tap(find.byKey(const ValueKey('squad-member-u2')));
      await tester.pumpAndSettle();
      expect(h.location, '/groups');
      expect(find.byKey(const ValueKey('squad-member-sheet')), findsOneWidget);
    });

    testWidgets('button semantics named after the group, >= 48dp', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(tester);
      final card = find.byKey(const ValueKey('squad-today-open-g1'));
      final node = tester.getSemantics(card);
      expect(node.getSemanticsData().flagsCollection.isButton, isTrue);
      expect(node.label, contains('Chạy bộ cùng nhau'));
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      final size = tester.getSize(card);
      expect(size.height, greaterThanOrEqualTo(48));
      expect(size.width, greaterThanOrEqualTo(48));
      handle.dispose();
    });

    testWidgets('shows a pressed state (sticker moves toward its shadow)', (
      tester,
    ) async {
      await pump(tester);
      final card = find.byKey(const ValueKey('squad-today-open-g1'));
      final moving = find.descendant(
        of: card,
        matching: find.byType(AnimatedContainer),
      );
      Offset offset() {
        final c = tester.widget<AnimatedContainer>(moving.first);
        return Offset(
          c.transform?.getTranslation().x ?? 0,
          c.transform?.getTranslation().y ?? 0,
        );
      }

      expect(offset(), Offset.zero);
      final g = await tester.startGesture(
        tester.getRect(card).topRight - const Offset(8, -30),
      );
      await tester.pump();
      expect(offset().dx, greaterThan(0));
      await g.up();
      await tester.pumpAndSettle();
    });
  });
}
