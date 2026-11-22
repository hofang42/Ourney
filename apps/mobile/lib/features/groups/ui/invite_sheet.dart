import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../ui/ui.dart';
import '../data/groups_providers.dart';
import '../l10n/generated/groups_localizations.dart';
import 'group_errors.dart';

/// Opens the inviter sheet of a group journey: invite a user by `@handle`
/// (`send_group_invitation`) and list / revoke the pending invitations
/// (migration 0010).
Future<void> showGroupInviteSheet(BuildContext context, String journeyId) =>
    showUiSheet<void>(
      context: context,
      builder: (_) => GroupInviteSheet(journeyId: journeyId),
    );

class GroupInviteSheet extends ConsumerStatefulWidget {
  const GroupInviteSheet({required this.journeyId, super.key});

  final String journeyId;

  @override
  ConsumerState<GroupInviteSheet> createState() => _GroupInviteSheetState();
}

class _GroupInviteSheetState extends ConsumerState<GroupInviteSheet> {
  final _handle = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _handle.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l10n = GroupsL10n.of(context);
    final handle = _handle.text.trim();
    if (handle.isEmpty) {
      showGroupSnack(context, l10n.groups_inviteNeedsHandle);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(groupInviteRepositoryProvider)
          .send(widget.journeyId, handle: handle);
      if (!mounted) return;
      _handle.clear();
      ref.invalidate(sentGroupInvitationsProvider(widget.journeyId));
      showGroupSnack(context, l10n.groups_inviteSent);
    } on Object catch (e) {
      if (mounted) showGroupSnack(context, groupErrorMessage(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _revoke(String id) async {
    final l10n = GroupsL10n.of(context);
    final ok = await confirmGroupAction(
      context,
      title: l10n.groups_inviteRevokeTitle,
      message: l10n.groups_inviteRevokeMessage,
      confirmLabel: l10n.groups_inviteRevoke,
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(groupInviteAdminRepositoryProvider).revoke(id);
      if (!mounted) return;
      ref.invalidate(sentGroupInvitationsProvider(widget.journeyId));
      showGroupSnack(context, l10n.groups_inviteRevoked);
    } on Object catch (e) {
      if (mounted) showGroupSnack(context, groupErrorMessage(context, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = GroupsL10n.of(context);
    final ui = context.ui;
    final sent = ref.watch(sentGroupInvitationsProvider(widget.journeyId));
    return SingleChildScrollView(
      key: const ValueKey('group-invite-sheet'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.groups_inviteSheetTitle,
              style: UiText.h2(color: ui.ink),
            ),
          ),
          const SizedBox(height: UiSpace.md),
          UiTextField(
            fieldKey: const ValueKey('invite-handle'),
            label: l10n.groups_inviteHandleLabel,
            controller: _handle,
            prefixText: '@',
            autocorrect: false,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _send(),
          ),
          const SizedBox(height: UiSpace.md),
          UiButton(
            key: const ValueKey('invite-send'),
            label: l10n.groups_inviteSend,
            loading: _busy,
            onPressed: _busy ? null : _send,
          ),
          const SizedBox(height: UiSpace.lg),
          UiEyebrow(l10n.groups_invitePendingTitle.toUpperCase()),
          const SizedBox(height: UiSpace.sm),
          sent.when(
            loading: () => Padding(
              padding: const EdgeInsets.all(UiSpace.md),
              child: Center(
                child: UiSpinner(
                  semanticsLabel: AppLocalizations.of(context).common_loading,
                ),
              ),
            ),
            error: (e, _) => Text(
              groupErrorMessage(context, e),
              style: UiText.body(color: ui.inkMuted),
            ),
            data: (rows) => rows.isEmpty
                ? Text(
                    l10n.groups_invitePendingEmpty,
                    key: const ValueKey('invite-pending-empty'),
                    style: UiText.body(color: ui.inkMuted),
                  )
                : Column(
                    children: [
                      for (final r in rows)
                        Padding(
                          key: ValueKey('invite-pending-${r.id}'),
                          padding: const EdgeInsets.only(bottom: UiSpace.sm),
                          child: Row(
                            children: [
                              UiAvatar(name: r.invitee.displayName, size: 36),
                              const SizedBox(width: UiSpace.md),
                              Expanded(
                                child: Text(
                                  r.invitee.displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: UiText.body(color: ui.ink),
                                ),
                              ),
                              if (r.canRevoke)
                                UiButton.ghost(
                                  key: ValueKey('invite-revoke-${r.id}'),
                                  label: l10n.groups_inviteRevoke,
                                  compact: true,
                                  expand: false,
                                  onPressed: () => _revoke(r.id),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
