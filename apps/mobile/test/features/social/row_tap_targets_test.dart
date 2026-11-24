import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/features/social/social_paths.dart';

import 'social_fakes.dart';

void main() {
  testWidgets('inbox conversation card: whole card is a labelled button', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final router = await pumpSocial(
      tester,
      location: SocialPaths.inbox,
      fakes: SocialFakes(
        chat: FakeChatRepository(
          conversations: [conversation('c1', unread: 2)],
        ),
      ),
    );
    final card = find.byKey(const ValueKey('inbox-conversation-c1'));
    final node = tester.getSemantics(card);
    final data = node.getSemanticsData();
    expect(data.flagsCollection.isButton, isTrue);
    expect(data.label, contains('Nam Tran'));
    expect(tester.getSize(card).height, greaterThanOrEqualTo(48));
    // Tap the far right edge, away from any text.
    final r = tester.getRect(card);
    await tester.tapAt(Offset(r.right - 6, r.center.dy));
    await tester.pumpAndSettle();
    expect(router.state.uri.toString(), SocialPaths.chat('c1'));
    handle.dispose();
  });

  testWidgets('friend row: whole row taps, button semantics with the name', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpSocial(
      tester,
      location: SocialPaths.friends,
      fakes: SocialFakes(
        friends: FakeFriendRepository([friend('nam', name: 'Nam Tran')]),
      ),
    );
    final row = find.byKey(const ValueKey('friend-nam'));
    final data = tester.getSemantics(row).getSemanticsData();
    expect(data.flagsCollection.isButton, isTrue);
    expect(data.label, contains('Nam Tran'));
    final r = tester.getRect(row);
    await tester.tapAt(Offset(r.right - 6, r.center.dy));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(tester.getSize(row).height, greaterThanOrEqualTo(48));
    handle.dispose();
  });
}
