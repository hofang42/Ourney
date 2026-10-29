import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../app/providers.dart';
import '../../../app/theme/tokens.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/chunky_button.dart';
import '../../../shared/empty_state.dart';
import '../../../shared/needs_server_view.dart';
import '../../../shared/placeholder_screen.dart';
import '../../journeys/data/journeys_providers.dart';
import '../data/groups_providers.dart';
import '../domain/invite_code.dart';
import '../l10n/generated/groups_localizations.dart';
import 'group_errors.dart';

/// `/groups/:journeyId/invite`: invite code, copy, share link
/// `ourney://join/<code>` and a QR code (FR-D1). The owner can rotate the
/// code here (FR-D6); the old code and link stop working.
class InviteScreen extends ConsumerStatefulWidget {
  const InviteScreen({required this.journeyId, super.key});

  final String journeyId;

  @override
  ConsumerState<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends ConsumerState<InviteScreen> {
  /// Code returned by `rotateInviteCode`, shown until the journey stream
  /// catches up.
  String? _rotated;
  bool _busy = false;

  Future<void> _rotate() async {
    final l10n = GroupsL10n.of(context);
    final ok = await confirmGroupAction(
      context,
      title: l10n.groups_rotateTitle,
      message: l10n.groups_rotateMessage,
      confirmLabel: l10n.groups_actionRotate,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      final code = await ref
          .read(groupRepositoryProvider)
          .rotateInviteCode(widget.journeyId);
      if (!mounted) return;
      setState(() => _rotated = code);
      showGroupSnack(context, l10n.groups_rotateDone);
    } on Object catch (e) {
      if (mounted) showGroupSnack(context, groupErrorMessage(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = GroupsL10n.of(context);
    final app = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final c = OurneyColors.of(context);

    Scaffold scaffold(Widget body) => Scaffold(
      key: const ValueKey('group-invite-screen'),
      appBar: AppBar(title: Text(l10n.groups_inviteTitle)),
      body: SafeArea(child: body),
    );

    if (ref.watch(appConfigProvider).localOnly) {
      return scaffold(const NeedsServerView());
    }
    final journeyAsync = ref.watch(journeyByIdProvider(widget.journeyId));
    if (journeyAsync.hasError) {
      if (isNotWired(journeyAsync.error!)) {
        return PlaceholderScreen(id: 'group-invite', title: l10n.groups_title);
      }
      return scaffold(
        EmptyState(
          icon: Icons.error_outline_rounded,
          title: groupErrorMessage(context, journeyAsync.error!),
        ),
      );
    }
    if (!journeyAsync.hasValue) {
      return scaffold(
        Center(
          child: CircularProgressIndicator(semanticsLabel: app.common_loading),
        ),
      );
    }
    final journey = journeyAsync.value;
    if (journey == null) {
      return scaffold(
        EmptyState(
          icon: Icons.search_off_rounded,
          title: l10n.groups_notFoundTitle,
        ),
      );
    }
    final membership = ref.watch(myMembershipProvider(widget.journeyId)).value;
    final myId = ref.watch(currentUserIdProvider);
    final isOwner = membership != null
        ? membership.role == MemberRole.owner
        : (myId != null && journey.ownerId == myId);
    final active = journey.status == JourneyStatus.active;
    final code = _rotated ?? journey.inviteCode;

    if (!active) {
      return scaffold(
        EmptyState(
          key: const ValueKey('group-invite-closed'),
          icon: Icons.flag_rounded,
          title: l10n.groups_inviteClosed,
        ),
      );
    }

    final link = code == null ? null : inviteLink(code);
    return scaffold(
      ListView(
        padding: const EdgeInsets.all(OurneySpacing.screenMargin),
        children: [
          Text(l10n.groups_inviteMessage, style: text.bodyLarge),
          const SizedBox(height: OurneySpacing.xl),
          if (code == null || link == null)
            Text(
              l10n.groups_noInviteCode,
              key: const ValueKey('group-invite-none'),
              style: text.bodyLarge,
            )
          else ...[
            Center(
              child: Semantics(
                label: l10n.groups_joinCodeLabel,
                value: code.split('').join(' '),
                excludeSemantics: true,
                child: SelectableText(
                  code,
                  key: const ValueKey('group-invite-code'),
                  style: text.displaySmall?.copyWith(letterSpacing: 6),
                ),
              ),
            ),
            const SizedBox(height: OurneySpacing.lg),
            Center(
              child: Container(
                decoration: BoxDecoration(
                  // The QR stays dark-on-white in dark mode too (scanners).
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(OurneyRadii.card),
                  border: Border.all(color: c.border),
                ),
                padding: const EdgeInsets.all(OurneySpacing.sm),
                child: QrImageView(
                  key: const ValueKey('group-invite-qr'),
                  data: link,
                  size: 200,
                  backgroundColor: Colors.white,
                  semanticsLabel: l10n.groups_qrSemantics,
                ),
              ),
            ),
            const SizedBox(height: OurneySpacing.xl),
            ChunkyButton(
              key: const ValueKey('group-invite-share'),
              label: l10n.groups_shareLink,
              icon: Icons.ios_share_rounded,
              variant: ChunkyVariant.accent,
              onPressed: () => ref.read(groupShareLauncherProvider)(
                text: l10n.groups_shareText(journey.title, link, code),
                subject: journey.title,
              ),
            ),
            const SizedBox(height: OurneySpacing.md),
            ChunkyButton(
              key: const ValueKey('group-invite-copy'),
              label: l10n.groups_copyCode,
              icon: Icons.copy_rounded,
              variant: ChunkyVariant.neutral,
              onPressed: () async {
                await ref.read(groupClipboardProvider)(code);
                if (context.mounted) {
                  showGroupSnack(context, l10n.groups_copied);
                }
              },
            ),
          ],
          if (isOwner) ...[
            const SizedBox(height: OurneySpacing.lg),
            TextButton.icon(
              key: const ValueKey('group-invite-rotate'),
              onPressed: _busy ? null : _rotate,
              icon: const Icon(Icons.autorenew_rounded),
              label: Text(l10n.groups_actionRotate),
            ),
          ],
        ],
      ),
    );
  }
}
