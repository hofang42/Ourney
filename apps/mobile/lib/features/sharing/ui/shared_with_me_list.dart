import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/app_routes.dart';
import '../../../app/providers.dart';
import '../../../ui/ui.dart';
import '../data/sharing_providers.dart';
import '../l10n/generated/sharing_localizations.dart';
import 'sharing_widgets.dart';

/// Hub → **Shared with me** (S8, S26): journeys friends shared with the
/// caller, then the public journeys they saved by liking. Tapping a row
/// opens SCR-84 (`/shared/<id>`).
///
/// Exported for the Hub's third segment. It scrolls by itself; inside
/// another scroll view pass `shrinkWrap: true` and
/// `physics: NeverScrollableScrollPhysics()`.
class SharedWithMeList extends ConsumerWidget {
  const SharedWithMeList({
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    super.key,
  });

  /// Defaults to the responsive screen margin.
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(appConfigProvider).localOnly) {
      return const SharingNeedsServer();
    }
    final l10n = SharingL10n.of(context);
    final async = ref.watch(sharedWithMeProvider);
    final items = async.value;
    if (items == null) {
      return async.hasError
          ? SharingErrorView(
              error: async.error!,
              onRetry: () => ref.invalidate(sharedWithMeProvider),
            )
          : const SharingLoading();
    }
    if (items.isEmpty) {
      return UiEmptyState(
        key: const ValueKey('shared-with-me-empty'),
        icon: Icons.people_outline_rounded,
        title: l10n.sharing_emptyTitle,
        body: l10n.sharing_emptyMessage,
      );
    }
    final fromFriends = [
      for (final s in items)
        if (!s.saved) s,
    ];
    final saved = [
      for (final s in items)
        if (s.saved) s,
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final gutter = UiSpace.gutter(width);
        return ListView(
          key: const ValueKey('shared-with-me'),
          shrinkWrap: shrinkWrap,
          physics: physics,
          padding: padding ?? EdgeInsets.fromLTRB(gutter, 10, gutter, 32),
          children: [
            if (fromFriends.isNotEmpty) ...[
              UiListHeading(title: l10n.sharing_fromFriends),
              const SizedBox(height: UiSpace.sm),
              for (final s in fromFriends) ...[
                SharedJourneyRow(summary: s),
                const SizedBox(height: UiSpace.sm),
              ],
            ],
            if (saved.isNotEmpty) ...[
              const SizedBox(height: UiSpace.sm),
              UiListHeading(title: l10n.sharing_saved),
              const SizedBox(height: UiSpace.sm),
              for (final s in saved) ...[
                SharedJourneyRow(summary: s),
                const SizedBox(height: UiSpace.sm),
              ],
            ],
          ],
        );
      },
    );
  }
}

/// One row of [SharedWithMeList] (`.shared-compact-list > button`).
class SharedJourneyRow extends ConsumerStatefulWidget {
  const SharedJourneyRow({required this.summary, super.key});

  final SharedJourneySummary summary;

  @override
  ConsumerState<SharedJourneyRow> createState() => _SharedJourneyRowState();
}

class _SharedJourneyRowState extends ConsumerState<SharedJourneyRow> {
  bool _removing = false;

  Future<void> _unsave() async {
    setState(() => _removing = true);
    try {
      await ref
          .read(sharingRepositoryProvider)
          .unsave(widget.summary.journeyId);
    } on Object catch (e) {
      if (mounted) showSharingSnack(context, sharingErrorMessage(context, e));
    } finally {
      if (mounted) setState(() => _removing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = SharingL10n.of(context);
    final ui = context.ui;
    final s = widget.summary;
    final style = uiStyleForSkin(
      personaSkinForTemplate(s.templateId, kind: s.kind, emoji: s.emoji),
    );
    final imported = s.origin == JourneyOrigin.imported;
    final range = s.firstDate != null && s.lastDate != null
        ? formatDateRange(context, s.firstDate!, s.lastDate!)
        : null;
    final status = s.status == JourneyStatus.active
        ? l10n.sharing_live
        : l10n.sharing_finished;

    final meta = Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 2,
      children: [
        if (imported) ...[
          UiTag(
            key: ValueKey('shared-imported-${s.journeyId}'),
            label: l10n.sharing_imported,
            bordered: true,
          ),
          if (range != null)
            Text(range, style: UiText.body(size: 12, color: ui.inkMuted)),
        ] else
          UiStyleLabel(label: '${style.name} · $status', dot: style.accent),
      ],
    );

    final card = UiCard(
      key: ValueKey('shared-row-${s.journeyId}'),
      radius: UiRadius.menu,
      padding: const EdgeInsets.all(9),
      onPressed: () => context.push(AppRoutes.sharedJourney(s.journeyId)),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(UiRadius.thumb),
            child: SizedBox(
              width: 68,
              height: 74,
              child: s.coverThumbPath != null
                  ? StoragePhoto(path: s.coverThumbPath!, cacheWidth: 200)
                  : ColoredBox(
                      color: style.accent,
                      child: Icon(
                        uiJourneyIcon(s.emoji, s.templateId),
                        color: style.onAccent,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: UiSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: UiText.body(
                          size: 15,
                          weight: FontWeight.w700,
                          color: ui.ink,
                        ),
                      ),
                    ),
                    if (s.unseen) ...[
                      const SizedBox(width: 6),
                      Row(
                        key: ValueKey('shared-new-${s.journeyId}'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const UiNewDot(),
                          const SizedBox(width: 4),
                          Text(
                            l10n.sharing_newBadge,
                            style: UiText.body(
                              size: 11,
                              weight: FontWeight.w700,
                              color: ui.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    PersonAvatar(person: s.owner, size: 18),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        s.saved
                            ? l10n.sharing_savedFromLink
                            : l10n.sharing_byName(s.owner.displayName),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: UiText.body(size: 12, color: ui.inkMuted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                meta,
              ],
            ),
          ),
          if (!s.saved) Icon(Icons.chevron_right_rounded, color: ui.chevron),
        ],
      ),
    );

    if (!s.saved) return card;
    return Row(
      children: [
        Expanded(child: card),
        UiTextAction(
          key: ValueKey('shared-unsave-${s.journeyId}'),
          label: l10n.sharing_remove,
          color: ui.danger,
          size: 13,
          onPressed: _removing ? null : _unsave,
        ),
      ],
    );
  }
}
