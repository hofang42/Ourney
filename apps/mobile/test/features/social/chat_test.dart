import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/features/social/social_paths.dart';
import 'package:ourney_core/ourney_core.dart';

import 'social_fakes.dart';

ChatMessage msg(
  String id, {
  String sender = 'nam',
  String? body,
  MessageKind kind = MessageKind.text,
  String? mediaPath,
  String? replyThumb,
}) => ChatMessage(
  id: id,
  conversationId: 'c1',
  senderId: sender,
  kind: kind,
  createdAt: DateTime.now(),
  body: body,
  mediaPath: mediaPath,
  replyToCheckInId: replyThumb == null ? null : 'ci1',
  replyToThumbPath: replyThumb,
);

SocialFakes chatFakes({bool readOnly = false}) => SocialFakes(
  chat: FakeChatRepository(
    conversations: [conversation('c1', unread: 1, readOnly: readOnly)],
    messages: {
      'c1': [
        msg(
          'm1',
          kind: MessageKind.photo,
          mediaPath: 'messages/c1/nam/m1.jpg',
          body: 'which chapter?',
          replyThumb: 'thumbs/ci1.jpg',
        ),
        msg('m2', sender: me, body: 'chapter 6'),
      ],
    },
  ),
);

void main() {
  testWidgets('header, thread and mark read on open', (tester) async {
    final fakes = chatFakes();
    await pumpSocial(tester, location: SocialPaths.chat('c1'), fakes: fakes);

    expect(find.byKey(const ValueKey('chat-title-name')), findsOneWidget);
    expect(find.text('Daily Reading'), findsOneWidget);
    expect(find.text('which chapter?'), findsOneWidget);
    expect(find.text('chapter 6'), findsOneWidget);
    expect(find.byKey(const ValueKey('message-photo')), findsOneWidget);
    expect(find.byKey(const ValueKey('message-reply-context')), findsOneWidget);
    expect(fakes.chat.calls, contains('read:c1'));
  });

  testWidgets('send text', (tester) async {
    final fakes = chatFakes();
    await pumpSocial(tester, location: SocialPaths.chat('c1'), fakes: fakes);
    await tester.enterText(find.byKey(const ValueKey('chat-input')), ' hi! ');
    await tester.tap(find.byKey(const ValueKey('chat-send')));
    await tester.pumpAndSettle();
    expect(fakes.chat.calls, contains('text:hi!'));
    expect(find.text('hi!'), findsOneWidget);
    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('chat-input')),
    );
    expect(field.controller!.text, isEmpty);
  });

  testWidgets('empty text is not sent', (tester) async {
    final fakes = chatFakes();
    await pumpSocial(tester, location: SocialPaths.chat('c1'), fakes: fakes);
    await tester.tap(find.byKey(const ValueKey('chat-send')));
    await tester.pumpAndSettle();
    expect(fakes.chat.calls.where((c) => c.startsWith('text:')), isEmpty);
  });

  testWidgets('send a photo from the library and the camera', (tester) async {
    final fakes = chatFakes();
    await pumpSocial(tester, location: SocialPaths.chat('c1'), fakes: fakes);
    await tester.tap(find.byKey(const ValueKey('chat-library')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('chat-camera')));
    await tester.pumpAndSettle();
    expect(fakes.picker.picks, [false, true]);
    expect(fakes.chat.photos, hasLength(2));
    expect(fakes.chat.photos.first, [1, 2, 3, 4]);
    expect(find.byKey(const ValueKey('message-photo')), findsNWidgets(3));
  });

  testWidgets('long press → Delete for me hides the message', (tester) async {
    final fakes = chatFakes();
    await pumpSocial(tester, location: SocialPaths.chat('c1'), fakes: fakes);
    await tester.longPress(find.byKey(const ValueKey('message-m2')));
    await tester.pumpAndSettle();
    // My own message: no Report.
    expect(find.byKey(const ValueKey('message-report')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('message-delete')));
    await tester.pumpAndSettle();
    expect(fakes.chat.calls, contains('hide:m2'));
    expect(find.text('chapter 6'), findsNothing);
  });

  testWidgets('long press on their message offers Report and Copy', (
    tester,
  ) async {
    final fakes = chatFakes();
    await pumpSocial(tester, location: SocialPaths.chat('c1'), fakes: fakes);
    await tester.longPress(find.byKey(const ValueKey('message-m1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('message-report')), findsOneWidget);
    // Photo message: nothing to copy.
    expect(find.byKey(const ValueKey('message-copy')), findsNothing);
  });

  testWidgets('read-only conversation replaces the composer', (tester) async {
    await pumpSocial(
      tester,
      location: SocialPaths.chat('c1'),
      fakes: chatFakes(readOnly: true),
    );
    expect(find.byKey(const ValueKey('chat-read-only')), findsOneWidget);
    expect(find.text("You can't reply to this conversation"), findsOneWidget);
    expect(find.byKey(const ValueKey('chat-input')), findsNothing);
  });

  testWidgets('Delete conversation asks, clears and leaves', (tester) async {
    final fakes = chatFakes();
    await pumpSocial(tester, location: SocialPaths.inbox, fakes: fakes);
    await tester.tap(find.byKey(const ValueKey('inbox-conversation-c1')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('chat-menu')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('chat-menu-report')), findsOneWidget);
    expect(find.byKey(const ValueKey('chat-menu-block')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('chat-menu-delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('social-confirm')));
    await tester.pumpAndSettle();

    expect(fakes.chat.calls, contains('clear:c1'));
    expect(find.byKey(const ValueKey('chat-screen')), findsNothing);
    expect(find.byKey(const ValueKey('inbox-screen')), findsOneWidget);
  });

  testWidgets('local-only chat shows NeedsServerView', (tester) async {
    final fakes = chatFakes();
    await pumpSocial(
      tester,
      location: SocialPaths.chat('c1'),
      fakes: fakes,
      localOnly: true,
    );
    expect(find.byKey(const ValueKey('needs-server')), findsOneWidget);
    expect(fakes.chat.calls, isEmpty);
  });
}
