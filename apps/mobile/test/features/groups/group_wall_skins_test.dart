import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney_core/ourney_core.dart';

import 'groups_fakes.dart';

/// The six Figma group walls on a 320dp phone at 1.35x text, light and dark.
void main() {
  const skins = <String, TemplateId>{
    'quiet': TemplateId.weightLoss,
    'squad': TemplateId.englishDaily,
    'memory': TemplateId.travel,
    'couple': TemplateId.custom, // custom + 2 members = couple skin
    'flexer': TemplateId.workout30,
    'minimal': TemplateId.custom,
  };

  for (final dark in [false, true]) {
    for (final e in skins.entries) {
      testWidgets('${dark ? 'dark' : 'light'}: ${e.key} wall', (tester) async {
        tester.platformDispatcher.platformBrightnessTestValue = dark
            ? Brightness.dark
            : Brightness.light;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        tester.platformDispatcher.textScaleFactorTestValue = 1.35;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final g = groupJourney(
          title: 'Một nhóm có cái tên khá là dài',
          templateId: e.value,
          maxMembers: e.key == 'couple' ? 2 : 10,
        );
        final annToday = testCheckIn('g1', testToday, userId: 'u2');
        await pumpGroups(
          tester,
          location: '/groups/g1',
          locale: const Locale('vi'),
          journeys: FakeJourneyRepository(
            journeys: [g],
            memberships: {'g1': groupMembership(g)},
          ),
          checkIns: FakeCheckInRepository([annToday]),
          groups: FakeGroupRepository(
            today: {
              'g1': [
                memberToday(me, 'Minh', role: MemberRole.owner),
                memberToday('u2', 'Ann', today: annToday, streak: 5),
                memberToday('u3', 'Bao'),
              ],
            },
          ),
        );
        tester.view.physicalSize = const Size(320, 640);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const ValueKey('group-member-photo-u2')),
          findsOneWidget,
        );
        // The couple wall only has two halves.
        expect(
          find.byKey(const ValueKey('group-member-u3')),
          e.key == 'couple' ? findsNothing : findsOneWidget,
        );
        switch (e.key) {
          case 'squad':
            expect(find.text('1/3 ĐÃ ĐIỂM DANH'), findsWidgets);
            expect(find.text('BAO · ĐANG CHỜ'), findsOneWidget);
          case 'quiet':
            expect(find.text('Nhóm hôm nay.'), findsOneWidget);
            expect(find.text('Chưa chụp'), findsNWidgets(2));
            expect(find.text('Xem ảnh'), findsOneWidget);
            await tester.tap(
              find.byKey(const ValueKey('group-quiet-toggle-u2')),
            );
            await tester.pumpAndSettle();
            expect(find.text('Ẩn ảnh'), findsOneWidget);
          case 'memory':
            expect(find.text('HÔM NAY · 1/3 ĐÃ CÓ KHUNG'), findsOneWidget);
            expect(find.text('BAO · CHƯA CÓ KHUNG'), findsOneWidget);
          case 'couple':
            expect(find.text('Hôm nay của hai đứa'), findsOneWidget);
            expect(find.textContaining('đang chờ'), findsOneWidget);
          case 'flexer':
            expect(find.text('1/3 ĐÃ CHẠY'), findsOneWidget);
            expect(find.text('CHƯA CHẠY'), findsNWidgets(2));
          case 'minimal':
            expect(find.text('1/3 ĐÃ XONG'), findsOneWidget);
            expect(find.text('CHƯA'), findsNWidgets(2));
        }
      });
    }
  }
}
