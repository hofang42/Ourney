import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney_core/ourney_core.dart';

import 'groups_fakes.dart';

void main() {
  const code = 'ABCD1234';
  Finder submit() => find.byKey(const ValueKey('groups-join-submit'));

  group('Join preview (Figma JoinScreen)', () {
    testWidgets('shows 8 boxes and previews the group before joining', (
      tester,
    ) async {
      final invites = FakeGroupInviteRepository(preview: groupPreview());
      final h = await pumpGroups(
        tester,
        location: '/join/$code',
        invites: invites,
      );
      for (var i = 0; i < 8; i++) {
        expect(find.byKey(ValueKey('groups-join-box-$i')), findsOneWidget);
      }
      expect(find.byKey(const ValueKey('groups-join-preview')), findsOneWidget);
      expect(find.text('Hoi IELTS'), findsOneWidget);
      expect(find.text('5 of 10 people'), findsOneWidget);
      expect(find.text('Day 21 of 30'), findsOneWidget);
      expect(invites.calls, ['preview:$code']);
      expect(h.groups.calls, isEmpty, reason: 'previewing must not join');

      await tester.tap(submit());
      await tester.pumpAndSettle();
      expect(h.groups.calls, ['join:$code']);
      expect(h.location, '/groups/g1');
    });

    testWidgets('no lookup until 8 characters are typed', (tester) async {
      final invites = FakeGroupInviteRepository(preview: groupPreview());
      await pumpGroups(tester, location: '/join', invites: invites);
      await tester.enterText(
        find.byKey(const ValueKey('groups-join-code')),
        'abcd',
      );
      await tester.pump();
      expect(invites.calls, isEmpty);
      expect(find.byKey(const ValueKey('groups-join-preview')), findsNothing);
      await tester.enterText(
        find.byKey(const ValueKey('groups-join-code')),
        'abcd1234',
      );
      await tester.pumpAndSettle();
      expect(invites.calls, ['preview:$code']);
      expect(find.byKey(const ValueKey('groups-join-preview')), findsOneWidget);
    });

    testWidgets('unknown code: error shown and join disabled', (tester) async {
      final invites = FakeGroupInviteRepository()
        ..previewError = const GroupException.of(OurneyErrorCode.notFound);
      final h = await pumpGroups(
        tester,
        location: '/join/$code',
        invites: invites,
      );
      expect(
        find.byKey(const ValueKey('groups-join-preview-error')),
        findsOneWidget,
      );
      await tester.tap(submit(), warnIfMissed: false);
      await tester.pump();
      expect(h.groups.calls, isEmpty);
    });

    testWidgets('full group disables joining', (tester) async {
      final invites = FakeGroupInviteRepository(
        preview: groupPreview(state: GroupPreviewState.full),
      );
      final h = await pumpGroups(
        tester,
        location: '/join/$code',
        invites: invites,
      );
      expect(
        find.byKey(const ValueKey('groups-join-preview-state')),
        findsOneWidget,
      );
      await tester.tap(submit(), warnIfMissed: false);
      await tester.pump();
      expect(h.groups.calls, isEmpty);
    });

    testWidgets('offline preview falls back to the plain join flow', (
      tester,
    ) async {
      final invites = FakeGroupInviteRepository()
        ..previewError = const GroupException.of(OurneyErrorCode.offline);
      final h = await pumpGroups(
        tester,
        location: '/join/$code',
        invites: invites,
      );
      expect(find.byKey(const ValueKey('groups-join-preview')), findsNothing);
      await tester.tap(submit());
      await tester.pumpAndSettle();
      expect(h.groups.calls, ['join:$code']);
    });
  });
}
