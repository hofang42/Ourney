import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/features/social/social_paths.dart';
import 'package:ourney_core/ourney_core.dart';

import 'chat_test.dart' show chatFakes;
import 'inbox_test.dart' show fullInbox;
import 'social_fakes.dart';

/// Every social screen at 320dp with 1.35x text, light and dark, in
/// Vietnamese (longest strings): no overflow, no exception.
void main() {
  SocialFakes friendsFakes() => SocialFakes(
    friends: FakeFriendRepository([
      request('khoa', name: 'Nguyễn Thị Phương Khoa Lê Hoàng'),
      request(
        'tuan',
        source: FriendSource.publicJourney,
        journeyId: 'j',
        journeyTitle: 'Hội An mùa đèn lồng 2024',
      ),
      request('mai', direction: FriendDirection.outgoing),
      friend('nam', name: 'Trần Nguyễn Hoàng Nam Phương'),
    ]),
  );

  final cases = <String, (String, SocialFakes Function())>{
    'friends': (SocialPaths.friends, friendsFakes),
    'add friends': (SocialPaths.friendsAdd, SocialFakes.new),
    'inbox': (SocialPaths.inbox, fullInbox),
    'chat': (SocialPaths.chat('c1'), chatFakes),
    'invite': (SocialPaths.invite('abc'), SocialFakes.new),
    'hub widgets': ('/hub', fullInbox),
  };

  for (final brightness in Brightness.values) {
    for (final entry in cases.entries) {
      testWidgets('${entry.key} at 320dp, 1.35x, ${brightness.name}', (
        tester,
      ) async {
        await pumpSocial(
          tester,
          location: entry.value.$1,
          fakes: entry.value.$2(),
          brightness: brightness,
          width: 320,
          textScale: 1.35,
          locale: const Locale('vi'),
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('inbox public requests expanded at 320dp, 1.35x', (tester) async {
    await pumpSocial(
      tester,
      location: SocialPaths.inbox,
      fakes: fullInbox(),
      width: 320,
      textScale: 1.35,
      locale: const Locale('vi'),
    );
    final summary = find.byKey(const ValueKey('inbox-public-hoi-an'));
    await tester.scrollUntilVisible(
      summary,
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(summary);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
