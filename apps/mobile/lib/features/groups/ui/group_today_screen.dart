import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/app_routes.dart';
import '../../../app/providers.dart';
import '../../../app/theme/tokens.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../personas/active_journey_sync.dart';
import '../../../personas/persona_contract.dart';
import '../../../personas/persona_switchers.dart';
import '../../../shared/avatar.dart';
import '../../../shared/empty_state.dart';
import '../../../shared/needs_server_view.dart';
import '../../../shared/ourney_card.dart';
import '../../../shared/placeholder_screen.dart';
import '../../../shared/streak_flame.dart';
import '../../../shared/template_icons.dart';
import '../../journeys/data/journeys_providers.dart';
import '../../reminders/data/reminder_scheduler.dart';
import '../../safety/data/safety_providers.dart';
import '../data/groups_providers.dart';
import '../domain/group_today.dart';
import '../groups_paths.dart';
import '../l10n/generated/groups_localizations.dart';
import 'group_errors.dart';
import 'group_photo.dart';
import 'group_safety_hooks.dart';
import 'reaction_bar.dart';

enum GroupAction { invite, rotate, timeline, end, delete, leave }

enum _MemberAction { report, block, remove }

/// What the caller may do in a group journey (FR-D6/D7).
class GroupPermissions {
  const GroupPermissions({
    required this.journey,
    required this.membership,
    required this.currentUserId,
    required this.isAlone,
  });

  final Journey journey;
  final Membership? membership;
  final String? currentUserId;

  /// Only the caller is left among the visible active members.
  final bool isAlone;

  bool get isOwner {
    final m = membership;
    if (m != null) return m.role == MemberRole.owner;
    return currentUserId != null && journey.ownerId == currentUserId;
  }

  bool get isActive => journey.status == JourneyStatus.active;
  bool get canInvite => isActive;
  bool get canRotate => isOwner && isActive;
  bool get canEnd => isOwner && isActive;
  bool get canRemoveMembers => isOwner && isActive;

  /// Delete only when alone (SRS 3.1); otherwise the owner ends it. The
  /// server enforces it too (`not_alone`).
  bool get canDelete => isOwner && isAlone;
  bool get canLeave => membership?.isActive ?? true;
}

/// `/groups/:journeyId`: the group "Today" screen (FR-D3). Who checked in
/// today and who has not yet, each member's latest photo and streak,
/// reactions (FR-D4). Consistency only: no ranking and no metric values
/// (FR-D5). Blocked users' content is hidden (FR-F2).
class GroupTodayScreen extends ConsumerWidget {
  const GroupTodayScreen({required this.journeyId, super.key});

  final String journeyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = GroupsL10n.of(context);
    final app = AppLocalizations.of(context);
    if (ref.watch(appConfigProvider).localOnly) {
      return Scaffold(
        key: const ValueKey('group-today'),
        appBar: AppBar(title: Text(l10n.groups_title)),
        body: const SafeArea(child: NeedsServerView()),
      );
    }

    final journeyAsync = ref.watch(journeyByIdProvider(journeyId));
    final todayAsync = ref.watch(groupTodayProvider(journeyId));
    final firstError = journeyAsync.error ?? todayAsync.error;
    if (firstError != null && isNotWired(firstError)) {
      return PlaceholderScreen(id: 'group-today', title: l10n.groups_title);
    }

    final journey = journeyAsync.value;
    Widget? state;
    if (journeyAsync.hasValue && journey == null) {
      state = EmptyState(
        key: const ValueKey('group-not-found'),
        icon: Icons.search_off_rounded,
        title: l10n.groups_notFoundTitle,
        actionLabel: l10n.groups_title,
        onAction: () => context.go(AppRoutes.groups),
      );
    } else if (todayAsync.hasError || journeyAsync.hasError) {
      final e = rootError(firstError!);
      final forbidden =
          e is OurneyException && e.error == OurneyErrorCode.forbidden;
      state = EmptyState(
        key: ValueKey(forbidden ? 'group-not-member' : 'group-error'),
        icon: forbidden ? Icons.lock_outline_rounded : Icons.error_outline,
        title: forbidden ? l10n.groups_notMember : l10n.groups_todayLoadError,
        message: forbidden ? null : groupErrorMessage(context, e),
        actionLabel: forbidden ? l10n.groups_title : app.common_retry,
        onAction: forbidden
            ? () => context.go(AppRoutes.groups)
            : () {
                ref
                  ..invalidate(journeyByIdProvider(journeyId))
                  ..invalidate(groupTodayProvider(journeyId));
              },
      );
    } else if (journey == null || !todayAsync.hasValue) {
      state = Center(
        child: CircularProgressIndicator(semanticsLabel: app.common_loading),
      );
    }
    if (state != null) {
      return Scaffold(
        key: const ValueKey('group-today'),
        appBar: AppBar(title: Text(journey?.title ?? l10n.groups_title)),
        body: SafeArea(child: state),
      );
    }

    final myId = ref.watch(currentUserIdProvider);
    final membership = ref.watch(myMembershipProvider(journeyId)).value;
    final view = GroupTodayView.build(
      journey: journey!,
      members: todayAsync.value!,
      now: ref.watch(journeysClockProvider).now(),
      myUserId: myId,
      blockedIds: ref.watch(groupBlockedIdsProvider).value ?? const {},
      hiddenCheckInIds: ref.watch(hiddenCheckInIdsProvider),
      checkIns:
          ref.watch(groupCheckInsProvider(journeyId)).value ??
          const <CheckIn>[],
      myMembership: membership,
    );
    final perms = GroupPermissions(
      journey: journey,
      membership: membership,
      currentUserId: myId,
      isAlone: view.isAlone,
    );

    return ActiveJourneySync(
      journeyId: journey.id,
      child: Scaffold(
        key: const ValueKey('group-today'),
        appBar: AppBar(
          title: Row(
            children: [
              Icon(journeyIcon(journey.emoji, journey.templateId), size: 24),
              const SizedBox(width: OurneySpacing.sm),
              Expanded(
                child: Text(
                  journey.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            if (perms.canInvite)
              IconButton(
                key: const ValueKey('group-invite'),
                tooltip: l10n.groups_invite,
                icon: const Icon(Icons.person_add_alt_1_rounded),
                onPressed: () => context.push(GroupsPaths.invite(journeyId)),
              ),
            _GroupMenu(perms: perms),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              OurneySpacing.screenMargin,
              OurneySpacing.lg,
              OurneySpacing.screenMargin,
              OurneySpacing.xxl,
            ),
            children: [
              if (!perms.isActive) ...[
                _EndedBanner(text: l10n.groups_endedBanner),
                const SizedBox(height: OurneySpacing.md),
              ],
              PersonaGroupSwitcher(
                skin: personaSkinOf(journey),
                data: PersonaGroupData(
                  journey: journey,
                  members: [...view.done, ...view.pending],
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                ),
                fallback: (context) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(view: view),
                    const SizedBox(height: OurneySpacing.lg),
                    _MemberSections(view: view, perms: perms),
                  ],
                ),
                membersFooter: (context) => Padding(
                  padding: const EdgeInsets.only(top: OurneySpacing.lg),
                  child: _MemberSections(view: view, perms: perms),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Done and not-yet sections with one card per member. Each card carries the
/// report, block and remove actions.
class _MemberSections extends StatelessWidget {
  const _MemberSections({required this.view, required this.perms});

  final GroupTodayView view;
  final GroupPermissions perms;

  @override
  Widget build(BuildContext context) {
    final l10n = GroupsL10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (view.done.isNotEmpty) ...[
          _SectionHeader(l10n.groups_doneSection),
          for (final e in view.done) _MemberCard(entry: e, perms: perms),
        ],
        if (view.pending.isNotEmpty) ...[
          _SectionHeader(l10n.groups_pendingSection),
          for (final e in view.pending) _MemberCard(entry: e, perms: perms),
        ],
      ],
    );
  }
}

class _GroupMenu extends ConsumerWidget {
  const _GroupMenu({required this.perms});

  final GroupPermissions perms;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = GroupsL10n.of(context);
    return PopupMenuButton<GroupAction>(
      key: const ValueKey('group-menu'),
      tooltip: l10n.groups_moreActions,
      onSelected: (a) => runGroupAction(context, ref, perms, a),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: GroupAction.timeline,
          child: Text(l10n.groups_openTimeline),
        ),
        if (perms.canRotate)
          PopupMenuItem(
            key: const ValueKey('group-action-rotate'),
            value: GroupAction.rotate,
            child: Text(l10n.groups_actionRotate),
          ),
        if (perms.canEnd)
          PopupMenuItem(
            key: const ValueKey('group-action-end'),
            value: GroupAction.end,
            child: Text(l10n.groups_actionEnd),
          ),
        if (perms.canDelete)
          PopupMenuItem(
            key: const ValueKey('group-action-delete'),
            value: GroupAction.delete,
            child: Text(l10n.groups_actionDelete),
          ),
        if (perms.canLeave)
          PopupMenuItem(
            key: const ValueKey('group-action-leave'),
            value: GroupAction.leave,
            child: Text(l10n.groups_actionLeave),
          ),
      ],
    );
  }
}

/// Runs a journey-level action with its confirmation (FR-D6/D7).
Future<void> runGroupAction(
  BuildContext context,
  WidgetRef ref,
  GroupPermissions perms,
  GroupAction action,
) async {
  final l10n = GroupsL10n.of(context);
  final id = perms.journey.id;
  final groups = ref.read(groupRepositoryProvider);
  final journeys = ref.read(journeyRepositoryProvider);
  // Ending, deleting or leaving a group changes its reminders (FR-G1).
  final reminders = ref.read(reminderSchedulerProvider);
  switch (action) {
    case GroupAction.invite:
      await context.push(GroupsPaths.invite(id));
      return;
    case GroupAction.timeline:
      // Lives in the Journeys tab: switch tabs rather than push across.
      context.go(AppRoutes.journey(id));
      return;
    case GroupAction.rotate:
      final ok = await confirmGroupAction(
        context,
        title: l10n.groups_rotateTitle,
        message: l10n.groups_rotateMessage,
        confirmLabel: l10n.groups_actionRotate,
      );
      if (!ok || !context.mounted) return;
      await _guard(context, () async {
        await groups.rotateInviteCode(id);
        if (context.mounted) showGroupSnack(context, l10n.groups_rotateDone);
      });
    case GroupAction.end:
      final ok = await confirmGroupAction(
        context,
        title: l10n.groups_endTitle,
        message: l10n.groups_endMessage,
        confirmLabel: l10n.groups_actionEnd,
        destructive: true,
      );
      if (!ok || !context.mounted) return;
      await _guard(context, () async {
        await journeys.end(id);
        unawaited(reminders.reschedule());
      });
    case GroupAction.delete:
      final ok = await confirmGroupAction(
        context,
        title: l10n.groups_deleteTitle,
        message: l10n.groups_deleteMessage,
        confirmLabel: l10n.groups_actionDelete,
        destructive: true,
      );
      if (!ok || !context.mounted) return;
      await _guard(context, () async {
        await journeys.delete(id);
        unawaited(reminders.reschedule());
        if (context.mounted) context.go(AppRoutes.groups);
      });
    case GroupAction.leave:
      final notes = [
        l10n.groups_leaveMessage,
        if (perms.isAlone)
          l10n.groups_leaveAloneNote
        else if (perms.isOwner)
          l10n.groups_leaveOwnerNote,
      ];
      final ok = await confirmGroupAction(
        context,
        title: l10n.groups_leaveTitle,
        message: notes.join('\n\n'),
        confirmLabel: l10n.groups_actionLeave,
        destructive: true,
      );
      if (!ok || !context.mounted) return;
      await _guard(context, () async {
        await groups.leave(id);
        unawaited(reminders.reschedule());
        if (!context.mounted) return;
        showGroupSnack(context, l10n.groups_leftDone);
        context.go(AppRoutes.groups);
      });
  }
}

Future<void> _guard(BuildContext context, Future<void> Function() body) async {
  try {
    await body();
  } on Object catch (e) {
    if (context.mounted) showGroupSnack(context, groupErrorMessage(context, e));
  }
}

class _EndedBanner extends StatelessWidget {
  const _EndedBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = OurneyColors.of(context);
    return Container(
      key: const ValueKey('group-ended-banner'),
      padding: const EdgeInsets.all(OurneySpacing.md),
      decoration: BoxDecoration(
        color: c.sun.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(OurneyRadii.chip),
      ),
      child: Row(
        children: [
          Icon(Icons.flag_rounded, color: c.ink),
          const SizedBox(width: OurneySpacing.sm),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.view});

  final GroupTodayView view;

  @override
  Widget build(BuildContext context) {
    final l10n = GroupsL10n.of(context);
    final text = Theme.of(context).textTheme;
    final total = view.totalDays;
    return OurneyCard(
      key: const ValueKey('group-today-header'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            total == null
                ? l10n.groups_dayOpen(view.dayNumber)
                : l10n.groups_dayOf(view.dayNumber, total),
            style: text.bodyMedium,
          ),
          const SizedBox(height: OurneySpacing.xs),
          Text(
            l10n.groups_todayHeader(view.doneCount, view.memberCount),
            style: text.titleLarge,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: OurneySpacing.sm,
        bottom: OurneySpacing.md,
      ),
      child: Semantics(
        header: true,
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}

class _MemberCard extends ConsumerWidget {
  const _MemberCard({required this.entry, required this.perms});

  final GroupMemberEntry entry;
  final GroupPermissions perms;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = GroupsL10n.of(context);
    final app = AppLocalizations.of(context);
    final c = OurneyColors.of(context);
    final text = Theme.of(context).textTheme;
    final m = entry.member;
    final photo = entry.photo;
    final hooks = ref.watch(groupSafetyHooksProvider);
    final memberActions = <_MemberAction>[
      if (!entry.isMe && hooks.onReport != null) _MemberAction.report,
      if (!entry.isMe && hooks.onBlock != null) _MemberAction.block,
      if (!entry.isMe && perms.canRemoveMembers) _MemberAction.remove,
    ];

    final tags = [
      if (entry.isMe) l10n.groups_you,
      if (m.role == MemberRole.owner) l10n.groups_ownerBadge,
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: OurneySpacing.md),
      child: OurneyCard(
        key: ValueKey('group-member-${m.userId}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Avatar(
                  name: m.displayName,
                  image: groupAvatarImage(ref, m.avatarPath),
                  checkedIn: entry.checkedInToday,
                ),
                const SizedBox(width: OurneySpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleMedium,
                      ),
                      if (tags.isNotEmpty)
                        Text(
                          tags.join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall,
                        ),
                      const SizedBox(height: OurneySpacing.xs),
                      Row(
                        key: ValueKey('group-member-status-${m.userId}'),
                        children: [
                          Icon(
                            entry.checkedInToday
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            size: 18,
                            color: entry.checkedInToday
                                ? c.success
                                : c.inkMuted,
                          ),
                          const SizedBox(width: OurneySpacing.xs),
                          Flexible(
                            child: Text(
                              entry.checkedInToday
                                  ? l10n.groups_statusDone
                                  : l10n.groups_statusPending,
                              style: text.bodySmall?.copyWith(color: c.ink),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: OurneySpacing.sm),
                StreakFlame(
                  key: ValueKey('group-member-streak-${m.userId}'),
                  days: entry.streak,
                  atRisk:
                      perms.isActive &&
                      !entry.checkedInToday &&
                      entry.streak > 0,
                  size: 24,
                  semanticLabel: app.streak_semantics(entry.streak),
                ),
                if (memberActions.isNotEmpty)
                  PopupMenuButton<_MemberAction>(
                    key: ValueKey('group-member-menu-${m.userId}'),
                    tooltip: l10n.groups_memberActions(m.displayName),
                    onSelected: (a) => _onMemberAction(context, ref, a),
                    itemBuilder: (context) => [
                      for (final a in memberActions)
                        PopupMenuItem(
                          key: ValueKey('group-member-action-${a.name}'),
                          value: a,
                          child: Text(switch (a) {
                            _MemberAction.report => l10n.groups_actionReport,
                            _MemberAction.block => l10n.groups_actionBlock,
                            _MemberAction.remove => l10n.groups_actionRemove,
                          }),
                        ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: OurneySpacing.md),
            if (photo == null)
              Text(
                l10n.groups_noPhotoYet,
                key: ValueKey('group-member-nophoto-${m.userId}'),
                style: text.bodySmall,
              )
            else ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(OurneyRadii.card),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: GroupPhoto(
                    key: ValueKey('group-member-photo-${m.userId}'),
                    checkIn: photo,
                    dimmed: !entry.photoIsToday,
                  ),
                ),
              ),
              if (!entry.photoIsToday) ...[
                const SizedBox(height: OurneySpacing.xs),
                Text(
                  l10n.groups_latestPhoto(
                    MaterialLocalizations.of(context).formatMediumDate(
                      DateTime(
                        photo.localDate.year,
                        photo.localDate.month,
                        photo.localDate.day,
                      ),
                    ),
                  ),
                  style: text.bodySmall,
                ),
              ],
              if (photo.caption case final caption?
                  when caption.trim().isNotEmpty) ...[
                const SizedBox(height: OurneySpacing.xs),
                Text(
                  caption,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium,
                ),
              ],
              const SizedBox(height: OurneySpacing.sm),
              ReactionBar(
                checkInId: photo.id,
                enabled: perms.isActive && !entry.isMe,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _onMemberAction(
    BuildContext context,
    WidgetRef ref,
    _MemberAction action,
  ) async {
    final m = entry.member;
    final hooks = ref.read(groupSafetyHooksProvider);
    switch (action) {
      case _MemberAction.report:
        await hooks.onReport?.call(
          context,
          userId: m.userId,
          displayName: m.displayName,
          checkInId: entry.photo?.id,
        );
      case _MemberAction.block:
        await hooks.onBlock?.call(
          context,
          userId: m.userId,
          displayName: m.displayName,
        );
      case _MemberAction.remove:
        final l10n = GroupsL10n.of(context);
        final repo = ref.read(groupRepositoryProvider);
        final ok = await confirmGroupAction(
          context,
          title: l10n.groups_removeTitle(m.displayName),
          message: l10n.groups_removeMessage,
          confirmLabel: l10n.groups_actionRemove,
          destructive: true,
        );
        if (!ok || !context.mounted) return;
        await _guard(context, () async {
          await repo.removeMember(perms.journey.id, m.userId);
          if (context.mounted) {
            showGroupSnack(context, l10n.groups_removedDone(m.displayName));
          }
        });
    }
  }
}
