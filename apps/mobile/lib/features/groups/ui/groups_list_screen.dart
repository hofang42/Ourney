import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/providers.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../ui/ui.dart';
import '../../journeys/data/journeys_providers.dart';
import '../data/groups_providers.dart';
import '../l10n/generated/groups_localizations.dart';
import 'group_errors.dart';
import 'squad_tab_sections.dart';

/// Squad tab (`/groups`, V2 `SquadScreen`): "nhập mã mời" join-inline, the
/// "hôm nay" strip (skeleton / empty card / one overview card per group) and
/// "lời mời đang chờ". Local-only: a "needs the server" state.
class GroupsListScreen extends ConsumerStatefulWidget {
  const GroupsListScreen({super.key});

  @override
  ConsumerState<GroupsListScreen> createState() => _GroupsListScreenState();
}

class _GroupsListScreenState extends ConsumerState<GroupsListScreen> {
  final _codeFocus = FocusNode();
  bool _joinOpen = false;
  bool _hasPlayedInitialEntrance = false;

  @override
  void dispose() {
    _codeFocus.dispose();
    super.dispose();
  }

  void _openJoin() {
    _hasPlayedInitialEntrance = true;
    setState(() => _joinOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _codeFocus.requestFocus();
    });
  }

  Future<void> _onRefresh() async {
    _hasPlayedInitialEntrance = true;
    ref
      ..invalidate(groupJourneysProvider)
      ..invalidate(groupInvitationsProvider);
  }

  Widget _buildStaggeredStrip(BuildContext context, List<Journey> groups) {
    final l10n = GroupsL10n.of(context);
    final active = [
      for (final g in groups)
        if (g.status == JourneyStatus.active) g,
    ];
    final finished = [
      for (final g in groups)
        if (g.status != JourneyStatus.active) g,
    ];
    var cardIndex = 0;
    Widget wrapCard(Journey g) {
      final idx = cardIndex++;
      final card = SquadTodayCard(journey: g);
      if (idx >= 4) return card;
      return UiStaggerItem(
        key: ValueKey('squad-stagger-${g.id}'),
        index: idx,
        enabled: !_hasPlayedInitialEntrance,
        child: card,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (active.isNotEmpty) UiListHeading(title: l10n.groups_todayHeading),
        for (final g in active) wrapCard(g),
        if (finished.isNotEmpty) ...[
          UiListHeading(
            key: const ValueKey('squad-finished-heading'),
            title: l10n.groups_finishedSection,
          ),
          for (final g in finished) wrapCard(g),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = GroupsL10n.of(context);
    final app = AppLocalizations.of(context);

    Widget frame(Widget body, {bool scroll = true}) => UiScaffold(
      key: const ValueKey('groups-list'),
      scroll: scroll,
      padTop: 0,
      padBottom: UiSpace.xl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Same top bar as Journeys, Activity and Profile: title only,
          // default size, no eyebrow.
          UiTopBar(
            key: const ValueKey('squad-top-bar'),
            title: l10n.groups_title,
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

    final Widget todayState;
    if (groups.hasValue) {
      final list = groups.value!;
      todayState = KeyedSubtree(
        key: const ValueKey('squad-state-content'),
        child: list.isEmpty
            ? _EmptySquad(onEnterCode: _openJoin)
            : _buildStaggeredStrip(context, list),
      );
    } else if (groups.hasError) {
      todayState = KeyedSubtree(
        key: const ValueKey('squad-state-error'),
        child: UiEmptyState(
          key: const ValueKey('groups-error'),
          glyph: const OurneyIcon(name: 'error', size: 30),
          title: l10n.groups_loadError,
          body: groupErrorMessage(context, groups.error!),
          actionLabel: app.common_retry,
          onAction: () => ref.invalidate(groupJourneysProvider),
        ),
      );
    } else {
      todayState = KeyedSubtree(
        key: const ValueKey('squad-state-skeleton'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UiListHeading(title: l10n.groups_todayHeading),
            const SquadTodaySkeleton(),
          ],
        ),
      );
    }

    final Widget today = AnimatedSwitcher(
      duration: UiMotion.fadeOf(context, UiMotion.normal),
      reverseDuration: UiMotion.fadeOf(context, UiMotion.normal),
      switchInCurve: UiCurves.easeOutStrong,
      switchOutCurve: Curves.easeOut,
      layoutBuilder: (currentChild, previousChildren) => Stack(
        alignment: Alignment.topCenter,
        children: <Widget>[
          ...previousChildren,
          ?currentChild,
        ],
      ),
      child: todayState,
    );

    final Widget joinSection = _joinOpen
        ? SquadJoinInline(enabled: true, focusNode: _codeFocus)
        : UiButton.secondary(
            key: const ValueKey('squad-join-open'),
            label: l10n.groups_joinWithCode,
            glyph: const OurneyIcon(name: 'plus'),
            onPressed: _openJoin,
          );
    return UiRefreshScaffold(
      onRefresh: _onRefresh,
      semanticsLabel: app.common_loading,
      child: NotificationListener<ScrollStartNotification>(
        onNotification: (notification) {
          if (notification.dragDetails != null && groups.hasValue) {
            _hasPlayedInitialEntrance = true;
          }
          return false;
        },
        child: frame(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              today,
              const SquadPendingInvites(),
              const SizedBox(height: UiSpace.xl),
              if (UiMotion.reduced(context))
                joinSection
              else
                AnimatedSize(
                  duration: UiMotion.normal,
                  curve: UiCurves.easeOutStrong,
                  alignment: Alignment.topCenter,
                  child: joinSection,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// V2 `.groups-empty`: sticker, "chưa có hội nào.", hint and a button that
/// focuses the code field.
class _EmptySquad extends StatelessWidget {
  const _EmptySquad({required this.onEnterCode});

  final VoidCallback onEnterCode;

  @override
  Widget build(BuildContext context) {
    final l10n = GroupsL10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UiListHeading(title: l10n.groups_todayHeading),
        UiEmptyState(
          key: const ValueKey('groups-empty'),
          glyph: const OurneyIcon(name: 'squad', size: 40),
          title: l10n.groups_emptyCardTitle,
          body: l10n.groups_emptyCardBody,
          actionLabel: l10n.groups_joinWithCode,
          actionKey: const ValueKey('groups-empty-enter-code'),
          onAction: onEnterCode,
        ),
      ],
    );
  }
}
