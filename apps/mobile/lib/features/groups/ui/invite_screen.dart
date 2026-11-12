import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../app/app_routes.dart';
import '../../../app/providers.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../ui/ui.dart';
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

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.groups);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = GroupsL10n.of(context);
    final app = AppLocalizations.of(context);
    final ui = context.ui;

    Widget scaffold(Widget body, {bool scroll = false}) => UiScaffold(
      key: const ValueKey('group-invite-screen'),
      scroll: scroll,
      padTop: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UiBackHeader(
            onBack: _back,
            backLabel: MaterialLocalizations.of(context).backButtonTooltip,
            title: l10n.groups_inviteTitle,
          ),
          if (scroll) body else Expanded(child: UiFillScroll(child: body)),
        ],
      ),
    );

    if (ref.watch(appConfigProvider).localOnly) {
      return scaffold(const GroupsNeedsServer());
    }
    final journeyAsync = ref.watch(journeyByIdProvider(widget.journeyId));
    if (journeyAsync.hasError) {
      if (isNotWired(journeyAsync.error!)) {
        return GroupsNotWired(id: 'group-invite', title: l10n.groups_title);
      }
      return scaffold(
        UiEmptyState(
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
        UiEmptyState(
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
        UiEmptyState(
          key: const ValueKey('group-invite-closed'),
          icon: Icons.flag_outlined,
          title: l10n.groups_inviteClosed,
        ),
      );
    }

    final link = code == null ? null : inviteLink(code);
    return scaffold(
      scroll: true,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: UiSpace.sm),
          Text(
            l10n.groups_inviteMessage,
            style: UiText.muted(color: ui.inkMuted),
          ),
          const SizedBox(height: UiSpace.xl),
          if (code == null || link == null)
            Text(
              l10n.groups_noInviteCode,
              key: const ValueKey('group-invite-none'),
              style: UiText.muted(color: ui.ink),
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
                  style: UiText.display(
                    size: 34,
                    weight: 800,
                    height: 1.3,
                    color: ui.ink,
                  ).copyWith(letterSpacing: 6),
                ),
              ),
            ),
            const SizedBox(height: UiSpace.lg),
            Center(
              child: Container(
                decoration: BoxDecoration(
                  // The QR stays dark-on-white in dark mode too (scanners).
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(UiRadius.card),
                  border: Border.all(color: ui.border),
                ),
                padding: const EdgeInsets.all(UiSpace.md),
                child: QrImageView(
                  key: const ValueKey('group-invite-qr'),
                  data: link,
                  size: 200,
                  backgroundColor: Colors.white,
                  semanticsLabel: l10n.groups_qrSemantics,
                ),
              ),
            ),
            const SizedBox(height: UiSpace.xl),
            UiButton(
              key: const ValueKey('group-invite-share'),
              label: l10n.groups_shareLink,
              icon: Icons.ios_share_rounded,
              onPressed: () => ref.read(groupShareLauncherProvider)(
                text: l10n.groups_shareText(journey.title, link, code),
                subject: journey.title,
              ),
            ),
            const SizedBox(height: UiSpace.md),
            UiButton.secondary(
              key: const ValueKey('group-invite-copy'),
              label: l10n.groups_copyCode,
              icon: Icons.copy_rounded,
              onPressed: () async {
                await ref.read(groupClipboardProvider)(code);
                if (context.mounted) {
                  showGroupSnack(context, l10n.groups_copied);
                }
              },
            ),
          ],
          if (isOwner) ...[
            const SizedBox(height: UiSpace.sm),
            UiButton.ghost(
              key: const ValueKey('group-invite-rotate'),
              label: l10n.groups_actionRotate,
              icon: Icons.autorenew_rounded,
              onPressed: _busy ? null : _rotate,
            ),
          ],
        ],
      ),
    );
  }
}
