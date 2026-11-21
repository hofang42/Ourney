import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/features/groups/data/groups_providers.dart';
import 'package:ourney/features/groups/ui/invite_sheet.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/test_helpers.dart';
import 'groups_fakes.dart';

class _FakeAdmin implements GroupInviteAdminRepository {
  final List<SentGroupInvitation> rows = [
    SentGroupInvitation(
      id: 'i1',
      invitee: const PersonSummary(
        userId: 'u9',
        username: 'lan',
        displayName: 'Lan',
      ),
      inviter: const PersonSummary(
        userId: 'u1',
        username: 'me',
        displayName: 'Me',
      ),
      canRevoke: true,
      createdAt: DateTime(2026, 1, 1),
      expiresAt: DateTime(2026, 1, 8),
    ),
  ];
  final calls = <String>[];

  @override
  Future<List<SentGroupInvitation>> sent(String journeyId) async =>
      List.of(rows);
  @override
  Future<void> revoke(String invitationId) async {
    calls.add('revoke:$invitationId');
    rows.removeWhere((r) => r.id == invitationId);
  }

  @override
  Future<void> renameCouple(String j, String s, String p) async {}
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('invite sheet sends and revokes ($brightness)', (tester) async {
      final admin = _FakeAdmin();
      final invites = FakeGroupInviteRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupInviteAdminRepositoryProvider.overrideWithValue(admin),
            groupInviteRepositoryProvider.overrideWithValue(invites),
          ],
          child: testApp(
            Builder(
              builder: (context) => TextButton(
                onPressed: () => showGroupInviteSheet(context, 'g1'),
                child: const Text('open'),
              ),
            ),
            brightness: brightness,
            locale: const Locale('en'),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('invite-pending-i1')), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('invite-handle')),
        'minh',
      );
      await tester.tap(find.byKey(const ValueKey('invite-send')));
      await tester.pumpAndSettle();
      expect(invites.calls, contains('send:g1'));

      await tester.tap(find.byKey(const ValueKey('invite-revoke-i1')));
      await tester.pumpAndSettle();
      expect(admin.calls, isEmpty, reason: 'revoke asks first');
      await tester.tap(find.byKey(const ValueKey('groups-confirm')));
      await tester.pumpAndSettle();
      expect(admin.calls, ['revoke:i1']);
      expect(
        find.byKey(const ValueKey('invite-pending-empty')),
        findsOneWidget,
      );
    });
  }
}
