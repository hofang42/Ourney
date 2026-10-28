import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/app_routes.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/persona_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../shared/color_utils.dart';
import '../../../shared/empty_state.dart';
import '../../../shared/layout.dart';
import '../../../shared/needs_server_view.dart';
import '../../../shared/template_icons.dart';
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
    if (ref.watch(appConfigProvider).localOnly) return const NeedsServerView();
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
      return EmptyState(
        key: const ValueKey('shared-with-me-empty'),
        icon: Icons.people_outline_rounded,
        title: l10n.sharing_emptyTitle,
        message: l10n.sharing_emptyMessage,
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

    Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 9),
      child: Semantics(
        header: true,
        child: Text(text, style: headingStyle(size: 17)),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final gutter = OurneyLayout.horizontalPadding(width);
        return ListView(
          key: const ValueKey('shared-with-me'),
          shrinkWrap: shrinkWrap,
          physics: physics,
          padding: padding ?? EdgeInsets.fromLTRB(gutter, 10, gutter, 32),
          children: [
            if (fromFriends.isNotEmpty) ...[
              heading(l10n.sharing_fromFriends),
              for (final s in fromFriends) ...[
                SharedJourneyRow(summary: s),
                const SizedBox(height: 9),
              ],
            ],
            if (saved.isNotEmpty) ...[
              heading(l10n.sharing_saved),
              for (final s in saved) ...[
                SharedJourneyRow(summary: s),
                const SizedBox(height: 9),
              ],
            ],
          ],
        );
      },
    );
  }
}

/// One row of [SharedWithMeList].
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
    final c = OurneyColors.of(context);
    final s = widget.summary;
    final skin = personaSkinForTemplate(
      s.templateId,
      kind: s.kind,
      emoji: s.emoji,
    );
    final style = OurneyPersonaTheme.forSkin(
      skin,
      Theme.of(context).brightness,
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
      spacing: 5,
      runSpacing: 2,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: style.primaryAccent,
            shape: BoxShape.circle,
          ),
        ),
        if (imported) ...[
          Container(
            key: ValueKey('shared-imported-${s.journeyId}'),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              border: Border.all(color: c.inkMuted),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              l10n.sharing_imported,
              style: sharingLabel(context, size: 11, color: c.ink),
            ),
          ),
          if (range != null)
            Text(
              range,
              style: sharingBody(context, size: 12, color: c.inkMuted),
            ),
        ] else
          Text(
            '${personaStyleName(skin)} · $status',
            style: sharingBody(context, size: 12, color: c.inkMuted),
          ),
      ],
    );

    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: c.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('shared-row-${s.journeyId}'),
        onTap: () => context.push(AppRoutes.sharedJourney(s.journeyId)),
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 68,
                  height: 74,
                  child: s.coverThumbPath != null
                      ? StoragePhoto(path: s.coverThumbPath!, cacheWidth: 200)
                      : ColoredBox(
                          color: style.primaryAccent,
                          child: Icon(
                            journeyIcon(s.emoji, s.templateId),
                            color: readableOn(style.primaryAccent),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),
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
                            style: sharingLabel(context, size: 15),
                          ),
                        ),
                        if (s.unseen) ...[
                          const SizedBox(width: 6),
                          _NewDot(key: ValueKey('shared-new-${s.journeyId}')),
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
                            style: sharingBody(
                              context,
                              size: 12,
                              color: c.inkMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    meta,
                  ],
                ),
              ),
              if (s.saved)
                TextButton(
                  key: ValueKey('shared-unsave-${s.journeyId}'),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    foregroundColor: c.danger,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: _removing ? null : _unsave,
                  child: Semantics(
                    label: l10n.sharing_removeSavedSemantics(s.title),
                    excludeSemantics: true,
                    child: Text(
                      l10n.sharing_remove,
                      style: sharingLabel(context, size: 13, color: c.danger),
                    ),
                  ),
                )
              else
                Icon(Icons.chevron_right_rounded, color: c.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewDot extends StatelessWidget {
  const _NewDot({super.key});

  @override
  Widget build(BuildContext context) {
    final c = OurneyColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: c.danger, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          SharingL10n.of(context).sharing_newBadge,
          style: sharingLabel(context, size: 11, color: c.inkMuted),
        ),
      ],
    );
  }
}
