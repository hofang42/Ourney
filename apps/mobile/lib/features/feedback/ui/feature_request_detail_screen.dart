import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/app_routes.dart';
import '../../../app/providers.dart';
import '../../../app/theme/motion.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../ui/ui.dart';
import '../../safety/ui/block_dialogs.dart';
import '../data/feedback_providers.dart';
import '../l10n/generated/feedback_localizations.dart';
import 'create_feature_request_sheet.dart';
import 'feedback_common.dart';
import 'report_feature_request_sheet.dart';

/// `/feedback/:id`: Feature Request Detail screen with official Ourney reply
/// card, author edit/delete controls, and UGC report/block overflow actions.
class FeatureRequestDetailScreen extends ConsumerStatefulWidget {
  const FeatureRequestDetailScreen({required this.requestId, super.key});

  final String requestId;

  @override
  ConsumerState<FeatureRequestDetailScreen> createState() =>
      _FeatureRequestDetailScreenState();
}

class _FeatureRequestDetailScreenState
    extends ConsumerState<FeatureRequestDetailScreen> {
  bool _menuOpen = false;
  bool _deleting = false;

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.feedback);
    }
  }

  Future<void> _toggleVote(FeatureRequest item) async {
    OurneyHaptics.selection();
    final err =
        await ref.read(feedbackVoteOverlayProvider.notifier).toggle(item);
    if (err != null && mounted) {
      OurneyHaptics.warning();
      showUiToast(context, feedbackErrorMessage(context, OurneyException(err)));
    }
  }

  Future<void> _edit(FeatureRequest item) async {
    setState(() => _menuOpen = false);
    final result = await showCreateFeatureRequestSheet(
      context,
      existing: item,
    );
    if (!mounted || result is! FeatureRequestSaved) return;
    ref
        .read(rawFeedbackBoardProvider.notifier)
        .replaceUpdated(result.request);
    ref.invalidate(rawFeatureRequestDetailProvider(widget.requestId));
    showUiToast(context, FeedbackL10n.of(context).feedback_updatedToast);
  }

  Future<void> _delete(FeatureRequest item) async {
    setState(() => _menuOpen = false);
    final l10n = FeedbackL10n.of(context);
    final app = AppLocalizations.of(context);
    final confirmed = await showUiConfirmSheet(
      context: context,
      title: l10n.feedback_deleteTitle,
      message: l10n.feedback_deleteBody,
      confirmLabel: l10n.feedback_deleteConfirm,
      cancelLabel: app.common_cancel,
      destructive: true,
      sheetKey: const ValueKey('feedback-delete-confirm-sheet'),
      confirmKey: const ValueKey('feedback-delete-confirm-btn'),
    );
    if (!confirmed || !mounted) return;

    setState(() => _deleting = true);
    try {
      await ref.read(featureRequestRepositoryProvider).delete(item.id);
      ref.read(hiddenFeatureRequestIdsProvider.notifier).hide(item.id);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      final toastMsg = l10n.feedback_deletedToast;
      _back();
      if (messenger != null && messenger.mounted) {
        showUiToast(messenger.context, toastMsg, messenger: messenger);
      }
    } on Object catch (e) {
      if (!mounted) return;
      showUiToast(context, feedbackErrorMessage(context, e));
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  Future<void> _report(FeatureRequest item) async {
    setState(() => _menuOpen = false);
    final l10n = FeedbackL10n.of(context);
    final sent = await showReportFeatureRequestSheet(
      context,
      requestId: item.id,
    );
    if (!sent || !mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final toastMsg = l10n.feedback_reportedToast;
    _back();
    if (messenger != null && messenger.mounted) {
      showUiToast(messenger.context, toastMsg, messenger: messenger);
    }
  }

  Future<void> _blockAuthor(FeatureRequest item) async {
    setState(() => _menuOpen = false);
    final authorId = item.authorUserId;
    if (authorId == null) return;
    final displayName = item.author?.displayName.trim().isNotEmpty == true
        ? item.author!.displayName.trim()
        : item.author?.username;
    final blocked = await confirmBlock(
      context,
      userId: authorId,
      name: displayName,
    );
    if (blocked && mounted) {
      _back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = FeedbackL10n.of(context);
    final app = AppLocalizations.of(context);
    final localOnly = ref.watch(appConfigProvider).localOnly;
    final backLabel = MaterialLocalizations.of(context).backButtonTooltip;

    if (localOnly) {
      return UiScaffold(
        key: const ValueKey('feedback-detail-screen'),
        scroll: false,
        padTop: 0,
        padBottom: 0,
        child: Column(
          children: [
            UiBackHeader(
              onBack: _back,
              backLabel: backLabel,
              title: l10n.feedback_detailTitle,
            ),
            Expanded(
              child: UiFillScroll(
                child: UiEmptyState(
                  key: const ValueKey('needs-server'),
                  glyph: const OurneyIcon(name: 'cloud-off', size: 36),
                  title: app.needsServer_title,
                  body: app.needsServer_message,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final detailAsync = ref.watch(
      featureRequestDetailProvider(widget.requestId),
    );
    final item = detailAsync.asData?.value;

    final hasMenu =
        item != null && (item.canAuthorModify || !item.isMine);

    return UiScaffold(
      key: const ValueKey('feedback-detail-screen'),
      scroll: false,
      padTop: 0,
      padBottom: 0,
      bottom: item == null
          ? null
          : _PinnedBottomVoteBar(
              item: item,
              onVote: _deleting ? null : () => _toggleVote(item),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UiBackHeader(
            onBack: _back,
            backLabel: backLabel,
            title: l10n.feedback_detailTitle,
            trailing: !hasMenu
                ? null
                : UiMenuAnchor(
                    open: _menuOpen,
                    onClose: () => setState(() => _menuOpen = false),
                    anchor: UiBarIconButton(
                      key: const ValueKey('feedback-detail-more'),
                      glyph: const OurneyIcon(name: 'more', size: 21),
                      label: l10n.feedback_moreOptions,
                      onPressed: () =>
                          setState(() => _menuOpen = !_menuOpen),
                    ),
                    menu: UiMenuSurface(
                      children: [
                        if (item.canAuthorModify) ...[
                          UiMenuItem(
                            key: const ValueKey('feedback-menu-edit'),
                            glyph: 'edit',
                            label: l10n.feedback_editAction,
                            onPressed: () => _edit(item),
                          ),
                          UiMenuItem(
                            key: const ValueKey('feedback-menu-delete'),
                            glyph: 'trash',
                            destructive: true,
                            label: l10n.feedback_deleteAction,
                            onPressed: () => _delete(item),
                          ),
                        ] else if (!item.isMine) ...[
                          UiMenuItem(
                            key: const ValueKey('feedback-menu-report'),
                            glyph: 'flag',
                            label: l10n.feedback_reportAction,
                            onPressed: () => _report(item),
                          ),
                          if (item.authorUserId != null)
                            UiMenuItem(
                              key: const ValueKey('feedback-menu-block'),
                              glyph: 'block',
                              destructive: true,
                              label: l10n.feedback_blockAuthorAction,
                              onPressed: () => _blockAuthor(item),
                            ),
                        ],
                      ],
                    ),
                  ),
          ),
          Expanded(
            child: switch (detailAsync) {
              AsyncData(value: final req) => _DetailBody(item: req),
              AsyncError(:final error)
                  when isFeedbackServerOutdated(error) =>
                UiFillScroll(
                  child: UiEmptyState(
                    key: const ValueKey('feedback-coming-soon'),
                    glyph: const OurneyIcon(
                      name: 'sparkle',
                      size: 36,
                      active: true,
                    ),
                    title: l10n.feedback_comingSoonTitle,
                    body: l10n.feedback_comingSoonBody,
                  ),
                ),
              AsyncError(:final error) => UiFillScroll(
                  child: UiStateCard(
                    key: const ValueKey('feedback-detail-error'),
                    kind: feedbackErrorCode(error) == OurneyErrorCode.offline
                        ? UiStateCardKind.offline
                        : UiStateCardKind.error,
                    title: feedbackErrorMessage(context, error),
                    actionLabel: app.common_retry,
                    onAction: () => ref.invalidate(
                      rawFeatureRequestDetailProvider(widget.requestId),
                    ),
                  ),
                ),
              _ => Semantics(
                  label: app.common_loading,
                  child: const Center(
                    child: UiSpinner(key: ValueKey('feedback-detail-loading')),
                  ),
                ),
            },
          ),
        ],
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.item});

  final FeatureRequest item;

  @override
  Widget build(BuildContext context) {
    final l10n = FeedbackL10n.of(context);
    final ui = context.ui;

    final authorHandle = (item.author != null &&
            item.author!.username.trim().isNotEmpty)
        ? '@${item.author!.username.trim()}'
        : l10n.feedback_anonymousAuthor;
    final avatarSeed = (item.author != null &&
            item.author!.displayName.trim().isNotEmpty)
        ? item.author!.displayName.trim()
        : authorHandle;
    final dateStr = formatFeedbackDate(context, item.createdAt);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: UiSpace.lg, bottom: UiSpace.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (item.duplicateOf != null) ...[
            UiCard(
              key: const ValueKey('feedback-merged-banner'),
              color: ui.fill,
              shadowOffset: 0,
              padding: const EdgeInsets.all(UiSpace.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OurneyIcon(
                        name: 'link',
                        size: 20,
                        flat: true,
                        color: ui.ink,
                      ),
                      const SizedBox(width: UiSpace.sm),
                      Expanded(
                        child: Text(
                          l10n.feedback_mergedBanner,
                          style: UiText.body(
                            size: 14,
                            weight: FontWeight.w600,
                            height: 1.4,
                            color: ui.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: UiSpace.md),
                  UiButton.secondary(
                    key: const ValueKey('feedback-merged-open-target'),
                    label: item.canonicalTitle != null &&
                            item.canonicalTitle!.trim().isNotEmpty
                        ? '${l10n.feedback_mergedOpenTarget}: ${item.canonicalTitle}'
                        : l10n.feedback_mergedOpenTarget,
                    compact: true,
                    expand: false,
                    onPressed: () => context.push(
                      AppRoutes.featureRequest(item.duplicateOf!),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: UiSpace.lg),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FeedbackStatusTag(status: item.status),
              FeedbackCategoryTag(category: item.category),
            ],
          ),
          const SizedBox(height: UiSpace.md),
          Semantics(
            header: true,
            child: Text(
              item.title,
              style: UiText.heading(
                font: 'SpaceGrotesk',
                size: 22,
                weight: 700,
                height: 1.3,
                tracking: -0.015,
                color: ui.ink,
              ),
            ),
          ),
          const SizedBox(height: UiSpace.md),
          Row(
            children: [
              UiAvatar(
                name: avatarSeed,
                colorIndex: UiAvatar.indexFor(avatarSeed),
                size: UiSize.avatar,
              ),
              const SizedBox(width: UiSpace.sm),
              Expanded(
                child: Text(
                  [
                    authorHandle,
                    dateStr,
                    if (item.wasEdited) l10n.feedback_editedBadge,
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.body(size: 13, color: ui.inkMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: UiSpace.lg),
          UiCard(
            key: const ValueKey('feedback-detail-body-card'),
            shadowOffset: 0,
            color: ui.surface,
            padding: const EdgeInsets.all(UiSpace.lg),
            child: Text(
              item.body,
              style: UiText.body(size: 15, height: 1.45, color: ui.ink),
            ),
          ),
          if (item.canAuthorModify) ...[
            const SizedBox(height: UiSpace.md),
            Text(
              l10n.feedback_authorEditHint,
              key: const ValueKey('feedback-author-edit-hint'),
              style: UiText.body(size: 13, height: 1.4, color: ui.inkMuted),
            ),
          ],
          if (item.adminReply != null) ...[
            const SizedBox(height: UiSpace.xl),
            UiCard(
              key: const ValueKey('feedback-admin-reply'),
              radius: UiRadius.card,
              borderColor: ui.brand,
              shadowOffset: UiShadow.small,
              color: ui.fill,
              padding: const EdgeInsets.all(UiSpace.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const OurneyIcon(
                        name: 'sparkle',
                        size: 20,
                        active: true,
                      ),
                      const SizedBox(width: UiSpace.sm),
                      Expanded(
                        child: UiEyebrow(
                          l10n.feedback_officialReplyEyebrow,
                          color: ui.ink,
                        ),
                      ),
                      if (item.adminRepliedAt != null) ...[
                        const SizedBox(width: UiSpace.xs),
                        Flexible(
                          child: Text(
                            formatFeedbackDate(context, item.adminRepliedAt!),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: UiText.body(size: 12, color: ui.inkMuted),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: UiSpace.sm),
                  Text(
                    item.adminReply!,
                    style: UiText.body(size: 15, height: 1.45, color: ui.ink),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PinnedBottomVoteBar extends StatelessWidget {
  const _PinnedBottomVoteBar({required this.item, required this.onVote});

  final FeatureRequest item;
  final VoidCallback? onVote;

  @override
  Widget build(BuildContext context) {
    final l10n = FeedbackL10n.of(context);
    final ui = context.ui;

    if (item.isShipped) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(0, UiSpace.sm, 0, UiSpace.md),
        child: UiCard(
          key: const ValueKey('feedback-detail-shipped-banner'),
          color: ui.successSoft,
          borderColor: ui.success,
          shadowOffset: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const UiCheckBadge(size: 28),
              const SizedBox(width: UiSpace.sm),
              Flexible(
                child: Text(
                  l10n.feedback_shippedVotes(item.voteCount),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.body(
                    size: 15,
                    weight: FontWeight.w700,
                    color: ui.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!item.canVote) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, UiSpace.sm, 0, UiSpace.md),
      child: item.votedByMe
          ? UiButton.secondary(
              key: const ValueKey('feedback-detail-vote'),
              label: l10n.feedback_votedButton(item.voteCount),
              glyph: OurneyIcon(
                name: 'check',
                flat: true,
                color: ui.brand,
              ),
              onPressed: onVote,
            )
          : UiButton(
              key: const ValueKey('feedback-detail-vote'),
              label: l10n.feedback_voteButton(item.voteCount),
              glyph: OurneyIcon(
                name: 'chevron-up',
                flat: true,
                color: ui.onBrand,
              ),
              onPressed: onVote,
            ),
    );
  }
}
