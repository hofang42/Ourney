import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../ui/ui.dart';
import '../../journeys/data/journeys_providers.dart';
import '../../profile/profile_entry_button.dart';
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

  @override
  void dispose() {
    _codeFocus.dispose();
    super.dispose();
  }

  void _openJoin() {
    setState(() => _joinOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _codeFocus.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
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

    final Widget today;
    if (groups.hasValue) {
      final list = groups.value!;
      today = list.isEmpty
          ? _EmptySquad(onEnterCode: _openJoin)
          : SquadTodayStrip(groups: list);
    } else if (groups.hasError) {
      today = UiEmptyState(
        key: const ValueKey('groups-error'),
        glyph: const OurneyIcon(name: 'error', size: 30),
        title: l10n.groups_loadError,
        body: groupErrorMessage(context, groups.error!),
        actionLabel: app.common_retry,
        onAction: () => ref.invalidate(groupJourneysProvider),
      );
    } else {
      today = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UiListHeading(title: l10n.groups_todayHeading),
          const SquadTodaySkeleton(),
        ],
      );
    }
    final Widget joinSection = _joinOpen
        ? SquadJoinInline(enabled: true, focusNode: _codeFocus)
        : UiButton.secondary(
            key: const ValueKey('squad-join-open'),
            label: l10n.groups_joinWithCode,
            glyph: const OurneyIcon(name: 'plus'),
            onPressed: _openJoin,
          );
    return frame(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          today,
          const SquadPendingInvites(),
          const SizedBox(height: UiSpace.xl),
          if (MediaQuery.disableAnimationsOf(context))
            joinSection
          else
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: joinSection,
            ),
        ],
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
