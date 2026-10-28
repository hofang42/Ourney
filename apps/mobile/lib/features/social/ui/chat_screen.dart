import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/avatar.dart';
import '../../../shared/empty_state.dart';
import '../../safety/ui/block_dialogs.dart';
import '../../safety/ui/report_form.dart';
import '../data/social_providers.dart';
import '../l10n/generated/social_localizations.dart';
import '../social_paths.dart';
import 'social_common.dart';

/// Server limit on a text message (SCR-86).
const int kChatMessageMaxLength = 500;

/// SCR-86 `/chat/:id`: 1-1 conversation tied to a journey (S17, S37).
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({required this.conversationId, super.key});

  final String conversationId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  bool _sending = false;

  /// Hidden at once while `hideMessage` reaches the stream.
  final Set<String> _hidden = {};

  @override
  void initState() {
    super.initState();
    if (!ref.read(appConfigProvider).localOnly) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _markRead());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _markRead() async {
    if (!mounted) return;
    try {
      await ref.read(chatRepositoryProvider).markRead(widget.conversationId);
    } on Object {
      // Best effort: the unread count catches up on the next open.
    }
  }

  Future<void> _sendText() async {
    final body = _controller.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    final ok = await runSocialAction(
      context,
      () => ref
          .read(chatRepositoryProvider)
          .sendText(widget.conversationId, body),
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (ok) _controller.clear();
  }

  Future<void> _sendPhoto({required bool camera}) async {
    if (_sending) return;
    final l10n = SocialL10n.of(context);
    List<int>? bytes;
    try {
      bytes = await ref.read(chatPhotoPickerProvider).pick(camera: camera);
    } on Object {
      if (mounted) showSocialSnack(context, l10n.social_photoFailed);
      return;
    }
    if (bytes == null || !mounted) return;
    setState(() => _sending = true);
    await runSocialAction(
      context,
      () => ref
          .read(chatRepositoryProvider)
          .sendPhoto(widget.conversationId, bytes!),
    );
    if (mounted) setState(() => _sending = false);
  }

  Future<void> _deleteConversation(Conversation? conv) async {
    final l10n = SocialL10n.of(context);
    final name = conv == null ? '' : displayNameOf(conv.other);
    final ok = await confirmSocialAction(
      context,
      title: l10n.social_deleteConversation,
      message: l10n.social_deleteConversationBody(name),
      confirmLabel: l10n.social_delete,
      destructive: true,
    );
    if (!ok || !mounted) return;
    final done = await runSocialAction(
      context,
      () => ref.read(chatRepositoryProvider).clear(widget.conversationId),
    );
    if (!done || !mounted) return;
    final router = GoRouter.maybeOf(context);
    if (router != null && router.canPop()) {
      router.pop();
    } else if (router != null) {
      router.go(SocialPaths.inbox);
    }
  }

  Future<void> _messageActions(ChatMessage m, Conversation? conv) async {
    final l10n = SocialL10n.of(context);
    final mine = m.senderId == ref.read(currentUserIdProvider);
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => SafeArea(
        child: Column(
          key: const ValueKey('message-actions'),
          mainAxisSize: MainAxisSize.min,
          children: [
            if (m.kind == MessageKind.text && (m.body ?? '').isNotEmpty)
              ListTile(
                key: const ValueKey('message-copy'),
                leading: const Icon(Icons.copy_rounded),
                title: Text(l10n.social_copy),
                onTap: () => Navigator.of(context).pop('copy'),
              ),
            ListTile(
              key: const ValueKey('message-delete'),
              leading: const Icon(Icons.delete_outline_rounded),
              title: Text(l10n.social_deleteForMe),
              onTap: () => Navigator.of(context).pop('delete'),
            ),
            if (!mine)
              ListTile(
                key: const ValueKey('message-report'),
                leading: const Icon(Icons.flag_outlined),
                title: Text(l10n.social_report),
                onTap: () => Navigator.of(context).pop('report'),
              ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'copy':
        await ref.read(socialClipboardProvider)(m.body ?? '');
        if (mounted) showSocialSnack(context, l10n.social_copied);
      case 'delete':
        setState(() => _hidden.add(m.id));
        final ok = await runSocialAction(
          context,
          () => ref.read(chatRepositoryProvider).hideMessage(m.id),
        );
        if (!ok && mounted) setState(() => _hidden.remove(m.id));
      case 'report':
        await showReportSheet(
          context,
          userId: m.senderId,
          name: conv == null ? null : displayNameOf(conv.other),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = SocialL10n.of(context);
    final localOnly = ref.watch(appConfigProvider).localOnly;
    if (localOnly) {
      return SocialScaffold(
        key: const ValueKey('chat-screen'),
        title: l10n.social_message,
        body: const SizedBox.shrink(),
      );
    }

    Conversation? conv;
    for (final c
        in ref.watch(conversationsProvider).value ?? const <Conversation>[]) {
      if (c.id == widget.conversationId) conv = c;
    }
    final messagesAsync = ref.watch(
      chatMessagesProvider(widget.conversationId),
    );
    final myId = ref.watch(currentUserIdProvider);

    // New incoming messages while the chat is open are read at once.
    ref.listen(chatMessagesProvider(widget.conversationId), (prev, next) {
      final before = prev?.value?.length ?? 0;
      final now = next.value;
      if (now != null && now.length > before && now.last.senderId != myId) {
        _markRead();
      }
    });

    final error = messagesAsync.hasError ? messagesAsync.error : null;
    final gone =
        error != null &&
        (socialErrorCode(error) == OurneyErrorCode.notFound ||
            socialErrorCode(error) == OurneyErrorCode.forbidden);
    final Widget body;
    // Blocked or cleared while open: drop the stale thread.
    if (messagesAsync.hasValue && !gone) {
      final messages = [
        for (final m in messagesAsync.value!)
          if (!_hidden.contains(m.id)) m,
      ];
      body = messages.isEmpty
          ? EmptyState(
              key: const ValueKey('chat-empty'),
              icon: Icons.chat_bubble_outline_rounded,
              title: l10n.social_chatEmpty,
            )
          : _thread(context, messages, myId, conv);
    } else if (error != null) {
      body = EmptyState(
        key: const ValueKey('chat-error'),
        icon: gone ? Icons.speaker_notes_off_outlined : Icons.error_outline,
        title: gone
            ? l10n.social_conversationGone
            : socialErrorMessage(context, error),
        actionLabel: gone ? null : AppLocalizations.of(context).common_retry,
        onAction: gone
            ? null
            : () => ref.invalidate(chatMessagesProvider(widget.conversationId)),
      );
    } else {
      body = const SocialLoading();
    }

    return SocialScaffold(
      key: const ValueKey('chat-screen'),
      title: conv == null ? l10n.social_message : displayNameOf(conv.other),
      body: body,
      bottom: conv?.readOnly ?? false
          ? const _ReadOnlyBanner()
          : _composer(context),
      header: conv == null ? null : _ChatTitle(conversation: conv),
      action: _menu(context, conv),
    );
  }

  Widget _menu(BuildContext context, Conversation? conv) {
    final l10n = SocialL10n.of(context);
    return PopupMenuButton<String>(
      key: const ValueKey('chat-menu'),
      tooltip: l10n.social_more,
      icon: const Icon(Icons.more_horiz_rounded),
      onSelected: (v) {
        switch (v) {
          case 'delete':
            _deleteConversation(conv);
          case 'report':
            if (conv != null) {
              showReportSheet(
                context,
                userId: conv.other.userId,
                name: displayNameOf(conv.other),
              );
            }
          case 'block':
            if (conv != null) {
              confirmBlock(
                context,
                userId: conv.other.userId,
                name: displayNameOf(conv.other),
              );
            }
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          key: const ValueKey('chat-menu-delete'),
          value: 'delete',
          child: Text(l10n.social_deleteConversation),
        ),
        if (conv != null) ...[
          PopupMenuItem(
            key: const ValueKey('chat-menu-report'),
            value: 'report',
            child: Text(l10n.social_report),
          ),
          PopupMenuItem(
            key: const ValueKey('chat-menu-block'),
            value: 'block',
            child: Text(l10n.social_block),
          ),
        ],
      ],
    );
  }

  Widget _thread(
    BuildContext context,
    List<ChatMessage> messages,
    String? myId,
    Conversation? conv,
  ) {
    final l10n = SocialL10n.of(context);
    final lastMine = messages.lastIndexWhere((m) => m.senderId == myId);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final max = width > 600 ? 520.0 : width;
        final side = (width - max) / 2 + 18;
        return ListView.builder(
          key: const ValueKey('chat-thread'),
          reverse: true,
          padding: EdgeInsets.fromLTRB(side, 24, side, 24),
          itemCount: messages.length,
          itemBuilder: (context, i) {
            final index = messages.length - 1 - i;
            final m = messages[index];
            final mine = m.senderId == myId;
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _Bubble(
                message: m,
                mine: mine,
                maxWidth: max * 0.78,
                status: mine && index == lastMine ? l10n.social_sent : null,
                onLongPress: () => _messageActions(m, conv),
              ),
            );
          },
        );
      },
    );
  }

  Widget _composer(BuildContext context) {
    final l10n = SocialL10n.of(context);
    final c = OurneyColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.divider)),
      ),
      padding: EdgeInsets.fromLTRB(
        4,
        8,
        8,
        8 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Row(
        children: [
          IconButton(
            key: const ValueKey('chat-camera'),
            tooltip: l10n.social_camera,
            icon: const Icon(Icons.photo_camera_outlined),
            onPressed: _sending ? null : () => _sendPhoto(camera: true),
          ),
          IconButton(
            key: const ValueKey('chat-library'),
            tooltip: l10n.social_library,
            icon: const Icon(Icons.image_outlined),
            onPressed: _sending ? null : () => _sendPhoto(camera: false),
          ),
          Expanded(
            child: TextField(
              key: const ValueKey('chat-input'),
              controller: _controller,
              maxLength: kChatMessageMaxLength,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendText(),
              style: const TextStyle(fontFamily: kBodyFont, height: 1.4),
              decoration: InputDecoration(
                hintText: l10n.social_messageHint,
                counterText: '',
                isDense: true,
                filled: true,
                fillColor: c.surfaceSunken,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(color: c.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(color: c.border),
                ),
              ),
            ),
          ),
          IconButton(
            key: const ValueKey('chat-send'),
            tooltip: l10n.social_send,
            icon: _sending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.send_rounded, color: c.ink),
            onPressed: _sending ? null : _sendText,
          ),
        ],
      ),
    );
  }
}

class _ChatTitle extends StatelessWidget {
  const _ChatTitle({required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    final c = OurneyColors.of(context);
    final name = displayNameOf(conversation.other);
    return Row(
      children: [
        ExcludeSemantics(child: Avatar(name: name, size: 36)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                header: true,
                child: Text(
                  name,
                  key: const ValueKey('chat-title-name'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: displayStyle(
                    size: 17,
                    weight: 700,
                    height: 1.3,
                    color: c.ink,
                  ),
                ),
              ),
              Text(
                conversation.journeyTitle,
                key: const ValueKey('chat-title-journey'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: kBodyFont,
                  fontSize: 12,
                  height: 1.35,
                  color: c.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReadOnlyBanner extends StatelessWidget {
  const _ReadOnlyBanner();

  @override
  Widget build(BuildContext context) {
    final c = OurneyColors.of(context);
    return Container(
      key: const ValueKey('chat-read-only'),
      width: double.infinity,
      decoration: BoxDecoration(
        color: c.surfaceSunken,
        border: Border(top: BorderSide(color: c.divider)),
      ),
      padding: EdgeInsets.fromLTRB(
        OurneySpacing.screenMargin,
        OurneySpacing.lg,
        OurneySpacing.screenMargin,
        OurneySpacing.lg + MediaQuery.paddingOf(context).bottom,
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline_rounded, size: 18, color: c.inkMuted),
          const SizedBox(width: OurneySpacing.sm),
          Expanded(
            child: Text(
              SocialL10n.of(context).social_readOnly,
              style: TextStyle(
                fontFamily: kBodyFont,
                fontSize: 14,
                height: 1.4,
                color: c.inkMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.mine,
    required this.maxWidth,
    required this.onLongPress,
    this.status,
  });

  final ChatMessage message;
  final bool mine;
  final double maxWidth;
  final VoidCallback onLongPress;
  final String? status;

  @override
  Widget build(BuildContext context) {
    final l10n = SocialL10n.of(context);
    final c = OurneyColors.of(context);
    final m = message;
    final fg = mine ? c.onPrimary : c.ink;
    final muted = mine ? c.onPrimary.withValues(alpha: 0.72) : c.inkMuted;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(mine ? 16 : 4),
      bottomRight: Radius.circular(mine ? 4 : 16),
    );
    final time = socialTime(context, m.createdAt);
    final body = m.body?.trim();

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Semantics(
          onLongPressHint: MaterialLocalizations.of(context).showMenuTooltip,
          child: GestureDetector(
            key: ValueKey('message-${m.id}'),
            onLongPress: onLongPress,
            child: Container(
              padding: m.kind == MessageKind.photo || m.replyToThumbPath != null
                  ? const EdgeInsets.all(8)
                  : const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: mine ? c.primary : c.surface,
                borderRadius: radius,
                border: mine ? null : Border.all(color: c.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (m.replyToThumbPath != null) ...[
                    Row(
                      key: const ValueKey('message-reply-context'),
                      children: [
                        Expanded(
                          child: Text(
                            l10n.social_replyingTo,
                            style: TextStyle(
                              fontFamily: kBodyFont,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              height: 1.35,
                              color: muted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 56,
                          height: 56,
                          child: _MediaImage(
                            path: m.replyToThumbPath!,
                            radius: 8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                  ],
                  if (m.kind == MessageKind.photo && m.mediaPath != null) ...[
                    Semantics(
                      label: l10n.social_photoSemantics,
                      image: true,
                      child: AspectRatio(
                        aspectRatio: 4 / 3,
                        child: _MediaImage(
                          key: const ValueKey('message-photo'),
                          path: m.mediaPath!,
                          radius: 10,
                        ),
                      ),
                    ),
                    if (body != null && body.isNotEmpty)
                      const SizedBox(height: 6),
                  ],
                  if (body != null && body.isNotEmpty)
                    Padding(
                      padding:
                          m.kind == MessageKind.photo ||
                              m.replyToThumbPath != null
                          ? const EdgeInsets.symmetric(horizontal: 4)
                          : EdgeInsets.zero,
                      child: Text(
                        body,
                        style: TextStyle(
                          fontFamily: kBodyFont,
                          fontSize: 15,
                          height: 1.4,
                          color: fg,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Padding(
                    padding:
                        m.kind == MessageKind.photo ||
                            m.replyToThumbPath != null
                        ? const EdgeInsets.symmetric(horizontal: 4)
                        : EdgeInsets.zero,
                    child: Text(
                      status == null ? time : '$time · $status',
                      style: TextStyle(
                        fontFamily: kBodyFont,
                        fontSize: 11,
                        height: 1.3,
                        color: muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A chat photo or replied-to thumbnail through the [MediaStore] cache.
class _MediaImage extends ConsumerWidget {
  const _MediaImage({required this.path, required this.radius, super.key});

  final String path;
  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = OurneyColors.of(context);
    final file = ref.watch(socialMediaFileProvider(path)).value;
    final placeholder = ColoredBox(
      color: c.surfaceSunken,
      child: Center(
        child: Icon(Icons.image_outlined, color: c.inkMuted, size: 22),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: file == null
          ? placeholder
          : Image.file(
              File(file),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, _, _) => placeholder,
            ),
    );
  }
}
