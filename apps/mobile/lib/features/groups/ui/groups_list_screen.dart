import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/app_routes.dart';
import '../../../app/providers.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../personas/persona_contract.dart' show personaSkinOf;
import '../../../shared/template_icons.dart';
import '../../../shared/time_zones.dart';
import '../../../ui/ui.dart';
import '../../journeys/data/journeys_providers.dart';
import '../../profile/profile_entry_button.dart';
import '../data/groups_providers.dart';
import '../groups_paths.dart';
import '../l10n/generated/groups_localizations.dart';
import 'group_errors.dart';

/// Squad tab (`/groups`, App.tsx `SquadTab`): "Join with code" and "Start a
/// group journey" actions, then one card per group journey (FR-D1).
/// Local-only: a "needs the server" state.
class GroupsListScreen extends ConsumerWidget {
  const GroupsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = GroupsL10n.of(context);
    final app = AppLocalizations.of(context);

    Widget frame(Widget body, {bool scroll = true}) => UiScaffold(
      key: const ValueKey('groups-list'),
      scroll: scroll,
      padBottom: UiSpace.xl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UiTopBar(
            eyebrow: l10n.groups_eyebrow,
            title: l10n.groups_title,
            titleSize: 30,
            actions: const [ProfileEntryButton()],
          ),
          const SizedBox(height: UiSpace.lg),
          if (scroll) body else Expanded(child: UiFillScroll(child: body)),
        ],
      ),
    );

    if (ref.watch(appConfigProvider).localOnly) {
      return frame(const GroupsNeedsServer(), scroll: false);
    }

    final groups = ref.watch(groupJourneysProvider);
    if (groups.hasError && isNotWired(groups.error!)) {
      // Data layer (B1) not wired yet.
      return GroupsNotWired(id: 'groups', title: l10n.groups_title);
    }

    if (groups.hasValue) {
      final list = groups.value!;
      if (list.isEmpty) {
        return frame(
          UiEmptyState(
            key: const ValueKey('groups-empty'),
            icon: Icons.groups_rounded,
            title: l10n.groups_emptyTitle,
            body: l10n.groups_emptyMessage,
            actionLabel: l10n.groups_joinWithCode,
            onAction: () => context.push(GroupsPaths.joinEntry),
          ),
          scroll: false,
        );
      }
      return frame(_GroupList(groups: list));
    }
    if (groups.hasError) {
      return frame(
        UiEmptyState(
          key: const ValueKey('groups-error'),
          icon: Icons.error_outline_rounded,
          title: l10n.groups_loadError,
          body: groupErrorMessage(context, groups.error!),
          actionLabel: app.common_retry,
          onAction: () => ref.invalidate(groupJourneysProvider),
        ),
        scroll: false,
      );
    }
    return frame(
      Center(
        child: CircularProgressIndicator(semanticsLabel: app.common_loading),
      ),
      scroll: false,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // `.group-actions`: two outlined tiles side by side.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 4,
                child: _ActionTile(
                  key: const ValueKey('groups-join'),
                  icon: Icons.link_rounded,
                  label: l10n.groups_joinWithCode,
                  onTap: () => context.push(GroupsPaths.joinEntry),
                ),
              ),
              const SizedBox(width: UiSpace.sm),
              Expanded(
                flex: 5,
                child: _ActionTile(
                  key: const ValueKey('groups-create'),
                  icon: Icons.add_rounded,
                  label: l10n.groups_createGroup,
                  onTap: () => context.push(AppRoutes.journeyNew),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: UiSpace.xl),
        if (active.isNotEmpty) ...[
          UiListHeading(title: l10n.groups_activeSection),
          for (final g in active) GroupCard(journey: g),
        ],
        if (finished.isNotEmpty) ...[
          UiListHeading(title: l10n.groups_finishedSection),
          for (final g in finished) GroupCard(journey: g),
        ],
      ],
    );
  }
}

/// One group journey on the Squad tab (`.group-card`): accent edge, icon
/// tile in the journey paper, style name, title and the day.
class GroupCard extends ConsumerWidget {
  const GroupCard({required this.journey, super.key});

  final Journey journey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = GroupsL10n.of(context);
    final ui = context.ui;
    final today = journeyLocalDate(
      journey.timezone,
      ref.watch(journeysClockProvider).now(),
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
    final style = uiStyleForSkin(personaSkinOf(journey));
    final radius = BorderRadius.circular(UiRadius.card);

    return Padding(
      padding: const EdgeInsets.only(bottom: UiSpace.md),
      child: UiPressable(
        key: ValueKey('group-card-${journey.id}'),
        onPressed: () => context.push(GroupsPaths.today(journey.id)),
        semanticLabel: '${journey.title}, ${style.name}, $subtitle',
        excludeChildSemantics: true,
        borderRadius: radius,
        minSize: const Size(UiSize.tap, 118),
        child: Container(
          constraints: const BoxConstraints(minHeight: 118),
          decoration: BoxDecoration(
            color: ui.surface,
            borderRadius: radius,
            border: Border.all(color: ui.divider),
            boxShadow: [
              BoxShadow(
                color: ui.shadow.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Row(
              children: [
                Container(width: 4, color: style.accent),
                Padding(
                  padding: const EdgeInsets.all(UiSpace.md),
                  child: Container(
                    width: 82,
                    height: 92,
                    decoration: BoxDecoration(
                      color: ui.isDark
                          ? style.accent.withValues(alpha: 0.18)
                          : style.paper,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      journeyIcon(journey.emoji, journey.templateId),
                      size: 30,
                      color: ui.isDark ? style.accent : style.ink,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: UiSpace.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          style.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: UiText.body(
                            size: 11,
                            height: 1.4,
                            color: ui.inkMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
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
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: UiText.body(
                            size: 12,
                            height: 1.4,
                            color: ui.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 10, left: 4),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: ui.chevron,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// `.group-actions button`: outlined tile with a glyph and a label.
class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final radius = BorderRadius.circular(UiRadius.menu);
    return UiPressable(
      onPressed: onTap,
      semanticLabel: label,
      excludeChildSemantics: true,
      borderRadius: radius,
      minSize: const Size(UiSize.tap, UiSize.button),
      child: Container(
        constraints: const BoxConstraints(minHeight: UiSize.button),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: ui.surface,
          borderRadius: radius,
          border: Border.all(color: ui.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: ui.ink),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: UiText.body(
                  size: 12,
                  weight: FontWeight.w700,
                  height: 1.3,
                  color: ui.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
