import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/app_routes.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/persona_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../personas/persona_contract.dart';
import '../../../shared/empty_state.dart';
import '../../../shared/needs_server_view.dart';
import '../../../shared/placeholder_screen.dart';
import '../../../shared/profile_button.dart';
import '../../../shared/template_icons.dart';
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
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _SquadHeader(
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
            Expanded(child: body),
          ],
        ),
      ),
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
        // V1.0 `.group-actions`: two outlined tiles side by side.
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
              const SizedBox(width: OurneySpacing.sm),
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
        const SizedBox(height: 20),
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

    final skin = personaSkinOf(journey);
    final style = OurneyPersonaTheme.forSkin(
      skin,
      Theme.of(context).brightness,
    );
    final radius = BorderRadius.circular(OurneyRadii.card);

    return Padding(
      padding: const EdgeInsets.only(bottom: OurneySpacing.md),
      child: Semantics(
        button: true,
        label: '${journey.title}, ${personaStyleName(skin)}, $subtitle',
        excludeSemantics: true,
        child: Material(
          color: c.surface,
          borderRadius: radius,
          child: InkWell(
            key: ValueKey('group-card-${journey.id}'),
            borderRadius: radius,
            onTap: () => context.push(GroupsPaths.today(journey.id)),
            child: Container(
              constraints: const BoxConstraints(minHeight: 118),
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(color: c.divider),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A111114),
                    blurRadius: 16,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: radius,
                child: Row(
                  children: [
                    Container(width: 4, color: style.primaryAccent),
                    Padding(
                      padding: const EdgeInsets.all(OurneySpacing.md),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 82,
                          height: 92,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? style.surfaceElevated
                              : style.background,
                          child: Icon(
                            journeyIcon(journey.emoji, journey.templateId),
                            size: 30,
                            color: style.ink,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: OurneySpacing.md,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              personaStyleName(skin),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: kBodyFont,
                                fontSize: 10,
                                height: 1.3,
                                color: c.inkMuted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              journey.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: text.titleMedium?.copyWith(height: 1.35),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: text.bodySmall?.copyWith(
                                color: c.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: c.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "YOUR PEOPLE / Squad" header with trailing actions.
class _SquadHeader extends StatelessWidget {
  const _SquadHeader({required this.actions});

  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final l10n = GroupsL10n.of(context);
    final c = OurneyColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        OurneySpacing.screenMargin,
        OurneySpacing.md,
        OurneySpacing.screenMargin - 8,
        OurneySpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.groups_eyebrow.toUpperCase(),
                  style: eyebrowStyle(color: c.inkMuted),
                ),
                Semantics(
                  header: true,
                  child: Text(
                    l10n.groups_title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ),
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

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
    final c = OurneyColors.of(context);
    final radius = BorderRadius.circular(OurneyRadii.menu);
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: c.border),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: OurneySizes.button),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 17, color: c.ink),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: kBodyFont,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                      color: c.ink,
                    ),
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
