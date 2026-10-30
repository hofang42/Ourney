import 'package:ourney_core/ourney_core.dart';

import '../social_context.dart';
import '../social_mapping.dart';

/// Longest text message (`send_message` checks 1..500 chars).
const int maxMessageLength = 500;

/// [ChatRepository] over the v1.3 RPCs (S16–S17, S37). Message ids are
/// client-generated so a retried send is idempotent.
class DataChatRepository implements ChatRepository {
  DataChatRepository(this.social);

  final SocialContext social;

  void refresh() => social.changed();

  @override
  Stream<List<Conversation>> watchConversations() => social.watch(
    () => social.call('my_conversations', const {}, (json) {
      final list = [for (final r in rowsOf(json)) conversationFromJson(r)]
        ..sort((a, b) {
          final at = a.lastMessageAt, bt = b.lastMessageAt;
          if (at == null || bt == null) {
            return (bt == null ? 0 : 1) - (at == null ? 0 : 1);
          }
          return bt.compareTo(at);
        });
      return list;
    }),
    extraTriggers: () => [social.remote.watchInserts('messages')],
  );

  @override
  Stream<List<ChatMessage>> watchMessages(String conversationId) =>
      social.watch(
        () => social.call(
          'conversation_messages',
          {'p_conversation': conversationId},
          (json) =>
              [for (final r in rowsOf(json)) ?messageFromJson(r)]
                ..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
        ),
        extraTriggers: () => [
          social.remote.watchInserts(
            'messages',
            column: 'conversation_id',
            value: conversationId,
          ),
        ],
      );

  @override
  Future<String> openForReply(String journeyId, {String? checkInId}) async {
    final id = await social.call('open_conversation', {
      'p_journey': journeyId,
      'p_checkin': checkInId,
    }, (json) => json! as String);
    social.changed();
    return id;
  }

  @override
  Future<ChatMessage> sendText(
    String conversationId,
    String body, {
    String? replyToCheckInId,
  }) async {
    final text = body.trim();
    if (text.isEmpty || text.length > maxMessageLength) {
      throw const OurneyException(OurneyErrorCode.invalid, 'message length');
    }
    return _send(
      id: social.data.newId(),
      conversationId: conversationId,
      kind: MessageKind.text,
      body: text,
      replyToCheckInId: replyToCheckInId,
    );
  }

  @override
  Future<ChatMessage> sendPhoto(
    String conversationId,
    List<int> jpegBytes, {
    String? body,
    String? replyToCheckInId,
  }) async {
    if (jpegBytes.isEmpty) {
      throw const OurneyException(OurneyErrorCode.invalid, 'empty photo');
    }
    final caption = body?.trim();
    if (caption != null && caption.length > maxMessageLength) {
      throw const OurneyException(OurneyErrorCode.invalid, 'message length');
    }
    final me = social.requireUserId();
    final id = social.data.newId();
    final path = messagePhotoPath(conversationId, me, id);
    await social.remote.uploadBytes(path, jpegBytes);
    // Keep a local copy: the sender's own photo shows without a download.
    try {
      await social.data.files.writeBytes(path, jpegBytes);
    } on Object {
      // Cache only; the media store downloads it on demand otherwise.
    }
    return _send(
      id: id,
      conversationId: conversationId,
      kind: MessageKind.photo,
      body: caption == null || caption.isEmpty ? null : caption,
      mediaPath: path,
      replyToCheckInId: replyToCheckInId,
    );
  }

  Future<ChatMessage> _send({
    required String id,
    required String conversationId,
    required MessageKind kind,
    String? body,
    String? mediaPath,
    String? replyToCheckInId,
  }) async {
    final message = await social.call(
      'send_message',
      {
        'p_id': id,
        'p_conversation': conversationId,
        'p_kind': kind.wireName,
        'p_body': body,
        'p_media_path': mediaPath,
        'p_reply_to': replyToCheckInId,
      },
      (json) =>
          (json == null ? null : messageFromJson(json)) ??
          ChatMessage(
            id: id,
            conversationId: conversationId,
            senderId: social.requireUserId(),
            kind: kind,
            createdAt: social.data.now().toUtc(),
            body: body,
            mediaPath: mediaPath,
            replyToCheckInId: replyToCheckInId,
          ),
    );
    social.changed();
    return message;
  }

  @override
  Future<void> markRead(String conversationId) => social.mutate(
    'mark_conversation_read',
    {'p_conversation': conversationId},
  );

  @override
  Future<void> clear(String conversationId) =>
      social.mutate('clear_conversation', {'p_conversation': conversationId});

  @override
  Future<void> hideMessage(String messageId) =>
      social.mutate('hide_message', {'p_message': messageId});
}
