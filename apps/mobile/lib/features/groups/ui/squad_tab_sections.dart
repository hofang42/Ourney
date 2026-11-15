import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/app_routes.dart';
import '../../../ui/ui.dart';
import '../data/groups_providers.dart';
import '../domain/invite_code.dart';
import '../groups_paths.dart';
import '../l10n/generated/groups_localizations.dart';
import 'group_errors.dart';
import 'group_photo.dart' show groupAvatarImage;
import 'group_preview_card.dart' show groupTypeBadgeId;
import 'group_safety_hooks.dart';

/// Formats raw input as `XXXX-XXXX` (V2 `join-inline` input).
class _InviteCodeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = parseInviteInput(newValue.text);
    final clipped = raw.length > inviteCodeLength
        ? raw.substring(0, inviteCodeLength)
        : raw;
    final text = clipped.length > 4
        ? '${clipped.substring(0, 4)}-${clipped.substring(4)}'
        : clipped;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// V2 `.join-inline`: label, code field with a paste button and a primary
/// "Join" that opens the join screen with the code (enabled at 8 characters).
class SquadJoinInline extends StatefulWidget {
  const SquadJoinInline({
    required this.enabled,
    this.focusNode,
    this.onPasteRead,
    super.key,
  });

  final bool enabled;
  final FocusNode? focusNode;

  /// Test hook replacing the clipboard read.
  final Future<String?> Function()? onPasteRead;

  @override
  State<SquadJoinInline> createState() => _SquadJoinInlineState();
}

class _SquadJoinInlineState extends State<SquadJoinInline> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _code => parseInviteInput(_controller.text);
  bool get _valid => isValidInviteCode(_code);

  Future<void> _paste() async {
    final text =
        await (widget.onPasteRead?.call() ??
            Clipboard.getData(Clipboard.kTextPlain).then((d) => d?.text));
    if (text == null || !mounted) return;
    _controller.value = _InviteCodeFormatter().formatEditUpdate(
      TextEditingValue.empty,
      TextEditingValue(text: text),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = GroupsL10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UiTextField(
          label: l10n.groups_codeLabel,
          fieldKey: const ValueKey('squad-join-field'),
          controller: _controller,
          focusNode: widget.focusNode,
          hint: l10n.groups_codeHint,
          enabled: widget.enabled,
          autocorrect: false,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [_InviteCodeFormatter()],
          onChanged: (_) => setState(() {}),
          trailing: UiIconButton(
            key: const ValueKey('squad-join-paste'),
            glyph: const OurneyIcon(name: 'copy', flat: true),
            label: l10n.groups_pasteCode,
            onPressed: widget.enabled ? _paste : null,
          ),
        ),
        const SizedBox(height: UiSpace.md),
        UiButton(
          key: const ValueKey('squad-join-submit'),
          label: l10n.groups_joinAction,
          onPressed: widget.enabled && _valid
              ? () => context.push(AppRoutes.join(_code))
              : null,
        ),
      ],
    );
  }
}

/// V2 `.groups-today`: one overview card per group with the day's
/// check-ins, an avatar row (checked time or "not yet") and a member sheet.
class SquadTodayStrip extends StatelessWidget {
  const SquadTodayStrip({required this.groups, super.key});

  final List<Journey> groups;

  @override
  Widget build(BuildContext context) {
    final l10n = GroupsL10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UiListHeading(title: l10n.groups_todayHeading),
        for (final g in groups) SquadTodayCard(journey: g),
      ],
    );
  }
}

/// Loading placeholder of the strip (V2 `groups-skeleton`).
class SquadTodaySkeleton extends StatelessWidget {
  const SquadTodaySkeleton({super.key});

  @override
  Widget build(BuildContext context) => const Column(
    key: ValueKey('squad-skeleton'),
    children: [
      UiSkeleton(height: 112, radius: UiRadius.card),
      SizedBox(height: UiSpace.md),
      UiSkeleton(height: 112, radius: UiRadius.card),
    ],
  );
}

class SquadTodayCard extends ConsumerWidget {
  const SquadTodayCard({required this.journey, super.key});

  final Journey journey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = GroupsL10n.of(context);
    final ui = context.ui;
    final blocked = ref.watch(groupBlockedIdsProvider).asData?.value ?? {};
    final members = [
      for (final m
          in ref.watch(groupTodayProvider(journey.id)).asData?.value ??
              const <MemberToday>[])
        if (!blocked.contains(m.userId)) m,
    ];
    final done = members.where((m) => m.checkedIn).length;
    final radius = BorderRadius.circular(UiRadius.card);
    final shown = members.take(5).toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: UiSpace.md),
      child: Container(
        key: ValueKey('squad-today-${journey.id}'),
        decoration: BoxDecoration(
          color: ui.surface,
          borderRadius: radius,
          border: ui.stickerBorder(),
          boxShadow: ui.hardShadow(UiShadow.small),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UiPressable(
              key: ValueKey('squad-today-open-${journey.id}'),
              onPressed: () => context.push(GroupsPaths.today(journey.id)),
              semanticLabel: l10n.groups_openTodayOf(journey.title),
              excludeChildSemantics: true,
              borderRadius: radius,
              minSize: const Size(UiSize.tap, UiSize.tap),
              child: Padding(
                padding: const EdgeInsets.all(UiSpace.md),
                child: Row(
                  children: [
                    UiTypeBadge(
                      type: groupTypeBadgeId(journey.templateId.wireName),
                      size: 44,
                    ),
                    const SizedBox(width: UiSpace.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            journey.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: UiText.body(
                              size: 16,
                              weight: FontWeight.w700,
                              height: 1.35,
                              color: ui.ink,
                            ),
                          ),
                          Text(
                            l10n.groups_checkedInCount(
                              done,
                              members.isEmpty ? 0 : members.length,
                            ),
                            style: UiText.body(
                              size: 12,
                              height: 1.4,
                              color: ui.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (shown.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  UiSpace.sm,
                  0,
                  UiSpace.sm,
                  UiSpace.md,
                ),
                child: Row(
                  children: [
                    for (final m in shown)
                      Expanded(
                        child: _MemberChip(journey: journey, member: m),
                      ),
                    if (members.length > 5)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          l10n.groups_overflowMore(members.length - 5),
                          style: UiText.body(
                            size: 12,
                            weight: FontWeight.w800,
                            height: 1.3,
                            color: ui.inkMuted,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _hhmm(DateTime t) {
  final l = t.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(l.hour)}:${two(l.minute)}';
}

class _MemberChip extends ConsumerWidget {
  const _MemberChip({required this.journey, required this.member});

  final Journey journey;
  final MemberToday member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = GroupsL10n.of(context);
    final ui = context.ui;
    final checked = member.checkedIn;
    final caption = checked
        ? _hhmm(member.todayCheckIn!.capturedAt)
        : l10n.groups_memberWaiting;
    return UiPressable(
      key: ValueKey('squad-member-${member.userId}'),
      onPressed: () => showSquadMemberSheet(context, member),
      semanticLabel: '${member.displayName}, $caption',
      excludeChildSemantics: true,
      borderRadius: BorderRadius.circular(UiRadius.input),
      minSize: const Size(UiSize.tap, UiSize.tap),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: checked ? 1 : 0.55,
              child: UiAvatar(
                name: member.displayName,
                colorIndex: UiAvatar.indexFor(member.userId),
                size: UiSize.avatarLarge,
                image: groupAvatarImage(ref, member.avatarPath),
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OurneyIcon(
                  name: checked ? 'check' : 'clock',
                  size: 12,
                  flat: true,
                  color: checked ? ui.ink : ui.inkMuted,
                ),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: UiText.body(
                      size: 11,
                      height: 1.3,
                      color: checked ? ui.ink : ui.inkMuted,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// V2 `MemberSheet` (member view): avatar, name, handle and the two safety
/// actions, which hand over to the safety feature's report and block flows.
Future<void> showSquadMemberSheet(BuildContext context, MemberToday member) {
  return showUiSheet<void>(
    context: context,
    builder: (sheetContext) =>
        _MemberSheet(member: member, hostContext: context),
  );
}

class _MemberSheet extends ConsumerWidget {
  const _MemberSheet({required this.member, required this.hostContext});

  final MemberToday member;
  final BuildContext hostContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = GroupsL10n.of(context);
    final ui = context.ui;
    final hooks = ref.watch(groupSafetyHooksProvider);
    final username = member.username;
    void close() => Navigator.of(context).pop();
    return Padding(
      padding: const EdgeInsets.fromLTRB(UiSpace.xl, 0, UiSpace.xl, UiSpace.xl),
      child: Column(
        key: const ValueKey('squad-member-sheet'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: UiAvatar(
              name: member.displayName,
              colorIndex: UiAvatar.indexFor(member.userId),
              size: UiSize.avatarXL,
              image: groupAvatarImage(ref, member.avatarPath),
            ),
          ),
          const SizedBox(height: UiSpace.md),
          Semantics(
            header: true,
            child: Text(
              member.displayName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: UiText.heading(
                font: 'Space Grotesk',
                size: 24,
                height: 1.3,
                color: ui.ink,
              ),
            ),
          ),
          if (username != null && username.isNotEmpty)
            Text(
              l10n.groups_memberHandle(username),
              textAlign: TextAlign.center,
              style: UiText.muted(color: ui.inkMuted, size: 14),
            ),
          const SizedBox(height: UiSpace.xl),
          if (hooks.onReport != null)
            UiButton.secondary(
              key: const ValueKey('squad-member-report'),
              glyph: const OurneyIcon(name: 'warning', flat: true),
              label: l10n.groups_memberReport,
              onPressed: () async {
                close();
                await hooks.onReport!(
                  hostContext,
                  userId: member.userId,
                  displayName: member.displayName,
                  checkInId: member.todayCheckIn?.id,
                );
              },
            ),
          if (hooks.onReport != null && hooks.onBlock != null)
            const SizedBox(height: UiSpace.sm),
          if (hooks.onBlock != null)
            UiButton.secondary(
              key: const ValueKey('squad-member-block'),
              glyph: const OurneyIcon(name: 'lock', flat: true),
              label: l10n.groups_memberBlock,
              onPressed: () async {
                close();
                await hooks.onBlock!(
                  hostContext,
                  userId: member.userId,
                  displayName: member.displayName,
                );
              },
            ),
        ],
      ),
    );
  }
}

/// V2 `.pending-invites`: "{inviter} invited you to {group}" with Join/Skip.
class SquadPendingInvites extends ConsumerStatefulWidget {
  const SquadPendingInvites({super.key});

  @override
  ConsumerState<SquadPendingInvites> createState() =>
      _SquadPendingInvitesState();
}

class _SquadPendingInvitesState extends ConsumerState<SquadPendingInvites> {
  final _busy = <String>{};

  Future<void> _respond(GroupInvitation inv, {required bool accept}) async {
    if (!_busy.add(inv.id)) return;
    final repo = ref.read(groupInviteRepositoryProvider);
    try {
      if (accept) {
        final id = await repo.accept(inv.id);
        ref.invalidate(groupInvitationsProvider);
        if (mounted) context.go(GroupsPaths.today(id));
      } else {
        await repo.decline(inv.id);
        ref.invalidate(groupInvitationsProvider);
      }
    } on Object catch (e) {
      if (mounted) showGroupSnack(context, groupErrorMessage(context, e));
    } finally {
      _busy.remove(inv.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = GroupsL10n.of(context);
    final ui = context.ui;
    final invites =
        ref.watch(groupInvitationsProvider).asData?.value ??
        const <GroupInvitation>[];
    if (invites.isEmpty) return const SizedBox.shrink();
    final radius = BorderRadius.circular(UiRadius.card);
    return Column(
      key: const ValueKey('squad-pending-invites'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UiListHeading(title: l10n.groups_pendingInvitesHeading),
        for (final inv in invites)
          Padding(
            padding: const EdgeInsets.only(bottom: UiSpace.md),
            child: Container(
              key: ValueKey('squad-invite-${inv.id}'),
              padding: const EdgeInsets.all(UiSpace.md),
              decoration: BoxDecoration(
                color: ui.surface,
                borderRadius: radius,
                border: ui.stickerBorder(),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.groups_inviteLine(
                      inv.inviter.displayName.isEmpty
                          ? inv.inviter.username
                          : inv.inviter.displayName,
                      inv.title,
                    ),
                    style: UiText.body(
                      size: 14,
                      weight: FontWeight.w700,
                      height: 1.4,
                      color: ui.ink,
                    ),
                  ),
                  const SizedBox(height: UiSpace.sm),
                  Row(
                    children: [
                      Expanded(
                        child: UiButton(
                          key: ValueKey('squad-invite-accept-${inv.id}'),
                          compact: true,
                          label: l10n.groups_inviteAccept,
                          onPressed: () => _respond(inv, accept: true),
                        ),
                      ),
                      const SizedBox(width: UiSpace.sm),
                      Expanded(
                        child: UiButton.secondary(
                          key: ValueKey('squad-invite-skip-${inv.id}'),
                          compact: true,
                          label: l10n.groups_inviteSkip,
                          onPressed: () => _respond(inv, accept: false),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
