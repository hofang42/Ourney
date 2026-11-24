import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/ui/ui.dart' show OurneyTheme, UiPressable, UiTopBar;

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
        find.byWidgetPredicate(
          (w) => w is Text && (w.data ?? '').toLowerCase().contains('group'),
        ),
        findsNothing,
        reason: 'no "group(s)" wording left on the empty tab (any case)',
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
    // Six members: five chips and a "+1" overflow text.
    Future<GroupsHarness> pump(WidgetTester tester) => pumpGroups(
      tester,
      journeys: FakeJourneyRepository(journeys: [groupJourney()]),
      groups: FakeGroupRepository(
        today: {
          'g1': [
            memberToday(me, 'Linh'),
            for (var i = 2; i <= 6; i++) memberToday('u$i', 'An $i'),
          ],
        },
      ),
    );

    testWidgets('the bottom padding opens it', (tester) async {
      final h = await pump(tester);
      final r = tester.getRect(
        find.byKey(const ValueKey('squad-today-open-g1')),
      );
      await tester.tapAt(Offset(r.center.dx, r.bottom - 3));
      await tester.pumpAndSettle();
      expect(h.location, '/groups/g1');
    });

    testWidgets('the member strip margin around chips opens it', (
      tester,
    ) async {
      final h = await pump(tester);
      final r = tester.getRect(
        find.byKey(const ValueKey('squad-today-open-g1')),
      );
      final chipY = tester
          .getCenter(find.byKey(const ValueKey('squad-member-u2')))
          .dy;
      await tester.tapAt(Offset(r.left + 3, chipY));
      await tester.pumpAndSettle();
      expect(h.location, '/groups/g1');
    });

    testWidgets('the "+N" text opens it', (tester) async {
      final h = await pump(tester);
      await tester.tap(find.byKey(const ValueKey('squad-overflow-g1')));
      await tester.pumpAndSettle();
      expect(h.location, '/groups/g1');
    });

    testWidgets('member chips open their sheet, not the group', (tester) async {
      final h = await pump(tester);
      await tester.tap(find.byKey(const ValueKey('squad-member-u2')));
      await tester.pumpAndSettle();
      expect(h.location, '/groups');
      expect(find.byKey(const ValueKey('squad-member-sheet')), findsOneWidget);
    });

    testWidgets('card button + separate chip nodes; "+N" not in the label', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(tester);
      final card = find.byKey(const ValueKey('squad-today-open-g1'));
      final node = tester.getSemantics(card);
      final data = node.getSemanticsData();
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.label, contains('Chạy bộ cùng nhau'));
      expect(data.label, contains('0/6 checked in'));
      expect(data.label, isNot(contains('+1')));
      expect(data.label, isNot(contains('An 2')));
      expect(data.label, isNot(contains('\n')));
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      final size = tester.getSize(card);
      expect(size.height, greaterThanOrEqualTo(48));
      for (var i = 2; i <= 5; i++) {
        final chip = tester
            .getSemantics(find.byKey(ValueKey('squad-member-u$i')))
            .getSemanticsData();
        expect(chip.flagsCollection.isButton, isTrue, reason: 'u$i');
        expect(chip.label, contains('An $i'), reason: 'u$i');
        expect(chip.label, isNot(contains('Chạy bộ')), reason: 'u$i');
      }
      handle.dispose();
    });

    Offset translation(WidgetTester tester, Finder within) {
      final c = tester.widget<Transform>(
        find
            .descendant(
              of: within,
              matching: find.byKey(
                const ValueKey('ui-pressable-surface-translate'),
              ),
            )
            .first,
      );
      final t = c.transform.getTranslation();
      return Offset(t.x, t.y);
    }

    testWidgets('pressing the card shows its pressed state', (tester) async {
      await pump(tester);
      final card = find.byKey(const ValueKey('squad-today-open-g1'));
      expect(translation(tester, card), Offset.zero);
      final g = await tester.startGesture(
        tester.getRect(card).topRight - const Offset(8, -30),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 55));
      expect(translation(tester, card).dx, greaterThan(0));
      await g.up();
      await tester.pumpAndSettle();
    });

    testWidgets('pressing a member chip does not press the card', (
      tester,
    ) async {
      await pump(tester);
      final card = find.byKey(const ValueKey('squad-today-open-g1'));
      final chip = find.byKey(const ValueKey('squad-member-u2'));
      final g = await tester.startGesture(tester.getCenter(chip));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(translation(tester, card), Offset.zero);
      final chipScale = tester
          .widget<Transform>(
            find.descendant(
              of: chip,
              matching: find.byKey(
                const ValueKey('ui-pressable-surface-scale'),
              ),
            ),
          )
          .transform
          .storage[0];
      expect(chipScale, lessThan(1));
      await g.up();
      await tester.pumpAndSettle();
    });

    testWidgets(
      'disabled nested pressable does not suppress parent press, and '
      'unmounting a pressed child releases the parent lock',
      (tester) async {
        var showEnabledChild = true;
        late StateSetter setHost;
        await tester.pumpWidget(
          MaterialApp(
            theme: OurneyTheme.build(Brightness.light),
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  setHost = setState;
                  return UiPressable(
                    key: const ValueKey('parent-card'),
                    shadowOffset: 4,
                    onPressed: () {},
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const UiPressable(
                          key: ValueKey('disabled-child'),
                          onPressed: null,
                          child: SizedBox(width: 48, height: 48),
                        ),
                        if (showEnabledChild)
                          UiPressable(
                            key: const ValueKey('enabled-child'),
                            onPressed: () {},
                            child: const SizedBox(width: 48, height: 48),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );

        final parent = find.byKey(const ValueKey('parent-card'));
        // 1. Pressing a disabled nested UiPressable lets the parent press.
        final gDisabled = await tester.startGesture(
          tester.getCenter(find.byKey(const ValueKey('disabled-child'))),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 55));
        expect(translation(tester, parent).dx, greaterThan(0));
        await gDisabled.up();
        await tester.pumpAndSettle();
        expect(translation(tester, parent), Offset.zero);

        // 2. Pressing an enabled nested UiPressable and unmounting it mid-press
        // must release the parent lock so the next parent press works.
        final gEnabled = await tester.startGesture(
          tester.getCenter(find.byKey(const ValueKey('enabled-child'))),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 55));
        expect(translation(tester, parent), Offset.zero);
        setHost(() => showEnabledChild = false);
        await tester.pump();
        await gEnabled.up();
        await tester.pumpAndSettle();

        final gParent = await tester.startGesture(tester.getCenter(parent));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 55));
        expect(
          translation(tester, parent).dx,
          greaterThan(0),
          reason: 'parent press feedback must not stay wedged after child unmount',
        );
        await gParent.up();
        await tester.pumpAndSettle();
      },
    );
  });
}
