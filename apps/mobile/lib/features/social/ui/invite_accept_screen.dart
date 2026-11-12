import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/providers.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../ui/ui.dart';
import '../data/social_providers.dart';
import '../l10n/generated/social_localizations.dart';
import '../social_paths.dart';
import 'social_common.dart';

/// `/f/:token` (`ourney://friend/<token>`, `https://ourney.app/f/<token>`):
/// accepts the invite once and shows the new friend. Errors: `not_found`
/// (unknown / rotated token), `invalid` (own token), `blocked`.
class InviteAcceptScreen extends ConsumerStatefulWidget {
  const InviteAcceptScreen({required this.token, super.key});

  final String token;

  @override
  ConsumerState<InviteAcceptScreen> createState() => _InviteAcceptState();
}

class _InviteAcceptState extends ConsumerState<InviteAcceptScreen> {
  Future<PersonSummary>? _future;

  @override
  void initState() {
    super.initState();
    if (!ref.read(appConfigProvider).localOnly) _start();
  }

  void _start() {
    _future = ref.read(friendRepositoryProvider).acceptInvite(widget.token);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = SocialL10n.of(context);
    return SocialScaffold(
      key: const ValueKey('invite-accept-screen'),
      title: l10n.social_inviteTitle,
      body: _future == null
          ? const SizedBox.shrink()
          : FutureBuilder<PersonSummary>(
              future: _future,
              builder: (context, snap) {
                if (snap.hasError) return _error(context, snap.error!);
                if (snap.hasData) return _done(context, snap.data!);
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: context.ui.ink),
                      const SizedBox(height: UiSpace.lg),
                      Text(
                        l10n.social_inviteAccepting,
                        style: UiText.muted(color: context.ui.inkMuted),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _done(BuildContext context, PersonSummary person) {
    final l10n = SocialL10n.of(context);
    final ui = context.ui;
    final name = displayNameOf(person);
    return Center(
      key: const ValueKey('invite-accepted'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(UiSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: UiAvatar(
                name: name,
                colorIndex: UiAvatar.indexFor(name),
                size: UiSize.avatarXL,
                ring: false,
              ),
            ),
            const SizedBox(height: UiSpace.lg),
            Text(
              l10n.social_inviteDone(name),
              textAlign: TextAlign.center,
              style: UiText.h2(size: 24, color: ui.ink),
            ),
            const SizedBox(height: UiSpace.xs),
            Text(
              '@${person.username}',
              textAlign: TextAlign.center,
              style: UiText.muted(color: ui.inkMuted),
            ),
            const SizedBox(height: UiSpace.xl),
            UiButton(
              key: const ValueKey('invite-see-friends'),
              label: l10n.social_seeFriends,
              onPressed: () => context.go(SocialPaths.friends),
            ),
          ],
        ),
      ),
    );
  }

  Widget _error(BuildContext context, Object error) {
    final l10n = SocialL10n.of(context);
    final code = socialErrorCode(error);
    return switch (code) {
      OurneyErrorCode.notFound => UiEmptyState(
        key: const ValueKey('invite-not-found'),
        icon: Icons.link_off_rounded,
        title: l10n.social_inviteNotFound,
        actionLabel: l10n.social_addFriends,
        onAction: () => context.go(SocialPaths.friendsAdd),
      ),
      OurneyErrorCode.invalid => UiEmptyState(
        key: const ValueKey('invite-own'),
        icon: Icons.person_outline_rounded,
        title: l10n.social_inviteOwn,
        body: l10n.social_inviteOwnHint,
        actionLabel: l10n.social_addFriends,
        onAction: () => context.go(SocialPaths.friendsAdd),
      ),
      OurneyErrorCode.blocked => UiEmptyState(
        key: const ValueKey('invite-blocked'),
        icon: Icons.block_rounded,
        title: l10n.social_errorBlocked,
      ),
      _ => UiEmptyState(
        key: const ValueKey('invite-error'),
        icon: Icons.error_outline_rounded,
        title: socialErrorMessage(context, error),
        actionLabel: AppLocalizations.of(context).common_retry,
        onAction: () => setState(_start),
      ),
    };
  }
}
