import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/app_routes.dart';
import '../../../app/providers.dart';
import '../../../app/theme/tokens.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/chunky_button.dart';
import '../../../shared/empty_state.dart';
import '../../../shared/needs_server_view.dart';
import '../../../shared/ourney_card.dart';
import '../../../shared/placeholder_screen.dart';
import '../../../shared/profile_button.dart';
import '../data/groups_providers.dart';
import '../domain/group_today.dart';
import '../groups_paths.dart';
import '../l10n/generated/groups_localizations.dart';
import 'group_errors.dart';

/// Groups tab (`/groups`): the caller's group journeys, "Join with code"
/// (FR-D1) and a shortcut to the create flow. Local-only: [NeedsServerView].
class GroupsListScreen extends ConsumerWidget {
  const GroupsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = GroupsL10n.of(context);
    if (ref.watch(appConfigProvider).localOnly) {
      return Scaffold(
        key: const ValueKey('groups-list'),
        appBar: AppBar(
          title: Text(l10n.groups_title),
          actions: const [ProfileButton()],
        ),
        body: const SafeArea(child: NeedsServerView()),
      );
    }

    final groups = ref.watch(groupJourneysProvider);
    if (groups.hasError && groupIsNotWired(groups.error!)) {
      // Data layer (B1) not wired yet.
      return PlaceholderScreen(id: 'groups', title: l10n.groups_title);
    }

    final Widget body;
    if (groups.hasValue) {
      final list = groups.value!;
      body = list.isEmpty
          ? EmptyState(
              key: const ValueKey('groups-empty'),
              icon: Icons.groups_rounded,
              title: l10n.groups_emptyTitle,
              message: l10n.groups_emptyMessage,
              actionLabel: l10n.groups_joinWithCode,
              onAction: () => context.push(GroupsPaths.joinEntry),
            )
          : _GroupList(groups: list);
    } else if (groups.hasError) {
      body = EmptyState(
        key: const ValueKey('groups-error'),
        icon: Icons.error_outline_rounded,
        title: l10n.groups_loadError,
        message: groupErrorMessage(context, groups.error!),
        actionLabel: AppLocalizations.of(context).common_retry,
        onAction: () => ref.invalidate(groupJourneysProvider),
      );
    } else {
      body = Center(
        child: CircularProgressIndicator(
          semanticsLabel: AppLocalizations.of(context).common_loading,
        ),
      );
    }

    return Scaffold(
      key: const ValueKey('groups-list'),
      appBar: AppBar(
        title: Text(l10n.groups_title),
        actions: [
          IconButton(
            key: const ValueKey('groups-join-action'),
            tooltip: l10n.groups_joinWithCode,
            icon: const Icon(Icons.qr_code_2_rounded),
            onPressed: () => context.push(GroupsPaths.joinEntry),
          ),
          const ProfileButton(),
        ],
      ),
      body: SafeArea(child: body),
    );
  }
}

class _GroupList extends StatelessWidget {
  const _GroupList({required this.groups});

  final List<Journey> groups;

  @override
  Widget build(BuildContext context) {
    final l10n = GroupsL10n.of(context);
    final active = [
      for (final g in groups)
        if (g.status == JourneyStatus.active) g,
    ];
    final finished = [
      for (final g in groups)
        if (g.status != JourneyStatus.active) g,
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        OurneySpacing.screenMargin,
        OurneySpacing.lg,
        OurneySpacing.screenMargin,
        OurneySpacing.xxl,
      ),
      children: [
        ChunkyButton(
          key: const ValueKey('groups-join'),
          label: l10n.groups_joinWithCode,
          icon: Icons.login_rounded,
          variant: ChunkyVariant.accent,
          onPressed: () => context.push(GroupsPaths.joinEntry),
        ),
        const SizedBox(height: OurneySpacing.sm),
        TextButton.icon(
          key: const ValueKey('groups-create'),
          onPressed: () => context.push(AppRoutes.journeyNew),
          icon: const Icon(Icons.add_rounded),
          label: Text(l10n.groups_createGroup),
        ),
        const SizedBox(height: OurneySpacing.md),
        if (active.isNotEmpty) ...[
          _SectionHeader(l10n.groups_activeSection),
          for (final g in active) GroupCard(journey: g),
        ],
        if (finished.isNotEmpty) ...[
          _SectionHeader(l10n.groups_finishedSection),
          for (final g in finished) GroupCard(journey: g),
        ],
      ],
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

/// One group journey on the Groups tab.
class GroupCard extends ConsumerWidget {
  const GroupCard({required this.journey, super.key});

  final Journey journey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = GroupsL10n.of(context);
    final c = OurneyColors.of(context);
    final text = Theme.of(context).textTheme;
    final today = groupLocalDate(
      journey.timezone,
      ref.watch(groupsClockProvider).now(),
    );
    var day = journey.startDate.daysUntil(today) + 1;
    if (day < 1) day = 1;
    final total = journey.durationDays;
    if (total != null && day > total) day = total;
    final subtitle = switch (journey.status) {
      JourneyStatus.active =>
        total == null
            ? l10n.groups_dayOpen(day)
            : l10n.groups_dayOf(day, total),
      JourneyStatus.ended => l10n.groups_statusEnded,
      JourneyStatus.archived => l10n.groups_statusArchived,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: OurneySpacing.md),
      child: OurneyCard(
        key: ValueKey('group-card-${journey.id}'),
        onTap: () => context.push(GroupsPaths.today(journey.id)),
        child: Row(
          children: [
            ExcludeSemantics(
              child: Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(OurneyRadii.chip),
                ),
                child: Text(
                  journey.emoji,
                  textScaler: TextScaler.noScaling,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(width: OurneySpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    journey.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleMedium,
                  ),
                  const SizedBox(height: OurneySpacing.xs),
                  Text(subtitle, style: text.bodySmall),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: c.inkMuted),
          ],
        ),
      ),
    );
  }
}
