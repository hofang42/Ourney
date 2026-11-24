import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/app_routes.dart';
import '../../../app/providers.dart';
import '../../../app/theme/motion.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../ui/ui.dart';
import '../data/feedback_providers.dart';
import '../l10n/generated/feedback_localizations.dart';
import 'create_feature_request_sheet.dart';
import 'feedback_common.dart';

/// `/feedback`: In-App Feature Requests & Roadmap Board.
class FeatureRequestsScreen extends ConsumerStatefulWidget {
  const FeatureRequestsScreen({super.key});

  @override
  ConsumerState<FeatureRequestsScreen> createState() =>
      _FeatureRequestsScreenState();
}

class _FeatureRequestsScreenState extends ConsumerState<FeatureRequestsScreen> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      ref.read(feedbackQueryProvider.notifier).setSearch(value);
    });
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() {});
    ref.read(feedbackQueryProvider.notifier).setSearch('');
  }

  Future<void> _openCreateSheet({String? initialTitle}) async {
    final result = await showCreateFeatureRequestSheet(
      context,
      initialTitle: initialTitle,
    );
    if (!mounted || result == null) return;
    final l10n = FeedbackL10n.of(context);
    switch (result) {
      case FeatureRequestSaved(:final request):
        ref
            .read(rawFeedbackBoardProvider.notifier)
            .prependCreated(request);
        showUiToast(context, l10n.feedback_createdToast);
      case FeatureRequestDeflected(:final requestId):
        await context.push(AppRoutes.featureRequest(requestId));
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

  @override
  Widget build(BuildContext context) {
    final l10n = FeedbackL10n.of(context);
    final app = AppLocalizations.of(context);
    final localOnly = ref.watch(appConfigProvider).localOnly;
    final backLabel = MaterialLocalizations.of(context).backButtonTooltip;

    void onBack() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.profile);
      }
    }

    if (localOnly) {
      return UiScaffold(
        key: const ValueKey('feedback-screen'),
        scroll: false,
        padTop: 0,
        padBottom: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UiBackHeader(
              onBack: onBack,
              backLabel: backLabel,
              title: l10n.feedback_title,
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

    final boardAsync = ref.watch(feedbackBoardProvider);
    final serverOutdated =
        boardAsync.hasError && isFeedbackServerOutdated(boardAsync.error!);

    return UiScaffold(
      key: const ValueKey('feedback-screen'),
      scroll: false,
      padTop: 0,
      padBottom: 0,
      bottom: serverOutdated
          ? null
          : Padding(
              padding: const EdgeInsets.fromLTRB(
                0,
                UiSpace.sm,
                0,
                UiSpace.md,
              ),
              child: UiButton(
                key: const ValueKey('feedback-create-cta'),
                label: l10n.feedback_newCta,
                glyph: const OurneyIcon(name: 'plus', flat: true),
                onPressed: _openCreateSheet,
              ),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UiBackHeader(
            onBack: onBack,
            backLabel: backLabel,
            title: l10n.feedback_title,
            trailing: serverOutdated
                ? null
                : UiBarIconButton(
                    key: const ValueKey('feedback-add-icon'),
                    glyph: const OurneyIcon(name: 'plus', size: 21),
                    label: l10n.feedback_newAction,
                    onPressed: _openCreateSheet,
                  ),
          ),
          if (serverOutdated)
            Expanded(
              child: UiFillScroll(
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
            )
          else ...[
            const SizedBox(height: UiSpace.md),
            _TabsStrip(l10n: l10n),
            const SizedBox(height: UiSpace.sm),
            _SearchField(
              controller: _searchController,
              l10n: l10n,
              onChanged: _onSearchChanged,
              onClear: _clearSearch,
            ),
            const SizedBox(height: UiSpace.sm),
            _ChipsStrip(l10n: l10n),
            const SizedBox(height: UiSpace.sm),
            Expanded(
              child: _BoardBody(
                boardAsync: boardAsync,
                onOpenCreate: _openCreateSheet,
                onVote: _toggleVote,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TabsStrip extends ConsumerWidget {
  const _TabsStrip({required this.l10n});

  final FeedbackL10n l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(feedbackQueryProvider);
    return UiSegmented<FeatureRequestTab>(
      scrollable: true,
      value: query.tab,
      onChanged: (tab) {
        OurneyHaptics.selection();
        ref.read(feedbackQueryProvider.notifier).setTab(tab);
      },
      segments: [
        UiSegment(
          key: const ValueKey('feedback-tab-popular'),
          value: FeatureRequestTab.popular,
          label: l10n.feedback_tabPopular,
        ),
        UiSegment(
          key: const ValueKey('feedback-tab-newest'),
          value: FeatureRequestTab.newest,
          label: l10n.feedback_tabNew,
        ),
        UiSegment(
          key: const ValueKey('feedback-tab-planned'),
          value: FeatureRequestTab.planned,
          label: l10n.feedback_tabPlanned,
        ),
        UiSegment(
          key: const ValueKey('feedback-tab-shipped'),
          value: FeatureRequestTab.shipped,
          label: l10n.feedback_tabShipped,
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.l10n,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FeedbackL10n l10n;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return TextField(
      key: const ValueKey('feedback-search-input'),
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      cursorColor: ui.ink,
      style: UiText.body(
        size: 15,
        weight: FontWeight.w500,
        height: 1.4,
        color: ui.ink,
      ),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: ui.fill,
        hintText: l10n.feedback_searchHint,
        hintStyle: UiText.body(size: 15, color: ui.inkMuted),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 14, right: 10),
          child: OurneyIcon(
            name: 'search',
            size: 18,
            flat: true,
            color: ui.inkMuted,
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0),
        suffixIcon: controller.text.isEmpty
            ? null
            : Padding(
                padding: const EdgeInsets.only(right: 4),
                child: UiIconButton(
                  key: const ValueKey('feedback-search-clear'),
                  glyph: OurneyIcon(
                    name: 'close',
                    size: 16,
                    flat: true,
                    color: ui.inkMuted,
                  ),
                  label: l10n.feedback_searchClear,
                  onPressed: onClear,
                ),
              ),
        suffixIconConstraints: const BoxConstraints(minWidth: 0),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        constraints: const BoxConstraints(minHeight: UiSize.tap),
        border: uiFieldBorder(ui.fieldBorder, UiBorder.thin, UiRadius.capsule),
        enabledBorder: uiFieldBorder(
          ui.fieldBorder,
          UiBorder.thin,
          UiRadius.capsule,
        ),
        focusedBorder: uiFieldBorder(
          ui.accent,
          UiBorder.standard,
          UiRadius.capsule,
        ),
      ),
    );
  }
}

class _ChipsStrip extends ConsumerWidget {
  const _ChipsStrip({required this.l10n});

  final FeedbackL10n l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(feedbackQueryProvider);
    final ui = context.ui;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: UiSize.tap),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: UiChip(
                key: const ValueKey('feedback-chip-mine'),
                label: l10n.feedback_chipMine,
                selected: query.mineOnly,
                glyph: OurneyIcon(
                  name: 'profile',
                  size: 16,
                  flat: true,
                  color: query.mineOnly ? ui.onAccent : ui.ink,
                ),
                onPressed: () {
                  OurneyHaptics.selection();
                  ref.read(feedbackQueryProvider.notifier).toggleMine();
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: UiChip(
                key: const ValueKey('feedback-filter-all'),
                label: l10n.feedback_catAll,
                selected: query.category == null,
                onPressed: () {
                  OurneyHaptics.selection();
                  ref.read(feedbackQueryProvider.notifier).setCategory(null);
                },
              ),
            ),
            for (final cat in FeatureRequestCategory.values)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: UiChip(
                  key: ValueKey('feedback-filter-${cat.wireName}'),
                  label: feedbackCategoryLabel(l10n, cat),
                  selected: query.category == cat,
                  onPressed: () {
                    OurneyHaptics.selection();
                    ref.read(feedbackQueryProvider.notifier).setCategory(cat);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BoardBody extends ConsumerWidget {
  const _BoardBody({
    required this.boardAsync,
    required this.onOpenCreate,
    required this.onVote,
  });

  final AsyncValue<FeedbackBoardData> boardAsync;
  final Future<void> Function({String? initialTitle}) onOpenCreate;
  final ValueChanged<FeatureRequest> onVote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = FeedbackL10n.of(context);
    final app = AppLocalizations.of(context);
    final query = ref.watch(feedbackQueryProvider);

    return switch (boardAsync) {
      AsyncData(:final value) => _buildData(context, ref, l10n, query, value),
      AsyncError(:final error) => UiFillScroll(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: UiSpace.lg),
            child: UiStateCard(
              key: const ValueKey('feedback-error'),
              kind: feedbackErrorCode(error) == OurneyErrorCode.offline
                  ? UiStateCardKind.offline
                  : UiStateCardKind.error,
              title: feedbackErrorMessage(context, error),
              actionLabel: app.common_retry,
              onAction: () => ref.invalidate(rawFeedbackBoardProvider),
            ),
          ),
        ),
      _ => Semantics(
          label: app.common_loading,
          child: ListView.separated(
            key: const ValueKey('feedback-loading'),
            padding: const EdgeInsets.only(top: UiSpace.xs, bottom: UiSpace.xl),
            itemCount: 4,
            separatorBuilder: (_, _) => const SizedBox(height: UiSpace.md),
            itemBuilder: (_, _) =>
                const UiSkeleton(height: 96, radius: UiRadius.menu),
          ),
        ),
    };
  }

  Widget _buildData(
    BuildContext context,
    WidgetRef ref,
    FeedbackL10n l10n,
    FeedbackBoardQuery query,
    FeedbackBoardData data,
  ) {
    final ui = context.ui;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (data.isOfflineCached)
          Padding(
            padding: const EdgeInsets.only(bottom: UiSpace.sm),
            child: Container(
              key: const ValueKey('feedback-offline-strip'),
              padding: const EdgeInsets.symmetric(
                horizontal: UiSpace.md,
                vertical: UiSpace.sm,
              ),
              decoration: BoxDecoration(
                color: ui.fill,
                borderRadius: BorderRadius.circular(UiRadius.input),
                border: ui.stickerBorder(UiBorder.thin),
              ),
              child: Row(
                children: [
                  OurneyIcon(
                    name: 'wifi-off',
                    size: 16,
                    flat: true,
                    color: ui.ink,
                  ),
                  const SizedBox(width: UiSpace.sm),
                  Expanded(
                    child: Text(
                      l10n.feedback_offlineStrip,
                      style: UiText.body(
                        size: 13,
                        weight: FontWeight.w600,
                        color: ui.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Expanded(
          child: data.items.isEmpty && !data.hasMore
              ? UiFillScroll(child: _buildEmpty(l10n, query))
              : ListView.separated(
                  key: const ValueKey('feedback-list'),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.only(
                    top: UiSpace.xs,
                    bottom: UiSpace.xl,
                  ),
                  itemCount: data.items.length + 1,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: UiSpace.md),
                  itemBuilder: (context, index) {
                    if (index == data.items.length) {
                      if (data.hasMore) {
                        return Center(
                          child: UiButton.secondary(
                            key: const ValueKey('feedback-load-more'),
                            label: l10n.feedback_loadMore,
                            compact: true,
                            expand: false,
                            loading: data.isLoadingMore,
                            onPressed: () => ref
                                .read(rawFeedbackBoardProvider.notifier)
                                .loadMore(),
                          ),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: UiSpace.sm,
                        ),
                        child: Text(
                          l10n.feedback_endOfList,
                          key: const ValueKey('feedback-end-of-list'),
                          textAlign: TextAlign.center,
                          style: UiText.body(size: 12, color: ui.inkMuted),
                        ),
                      );
                    }
                    final item = data.items[index];
                    return FeatureRequestCard(
                      item: item,
                      showNewStatus: query.mineOnly,
                      onTap: () =>
                          context.push(AppRoutes.featureRequest(item.id)),
                      onVote: () => onVote(item),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmpty(FeedbackL10n l10n, FeedbackBoardQuery query) {
    final trimmedSearch = query.search.trim();
    if (trimmedSearch.isNotEmpty) {
      return UiEmptyState(
        key: const ValueKey('feedback-empty-search'),
        glyph: const OurneyIcon(name: 'search', size: 34, active: true),
        title: l10n.feedback_emptySearchTitle,
        body: l10n.feedback_emptySearchBody,
        actionLabel: l10n.feedback_emptySearchCta,
        actionKey: const ValueKey('feedback-empty-search-cta'),
        onAction: () => onOpenCreate(initialTitle: trimmedSearch),
      );
    }
    if (query.mineOnly) {
      return UiEmptyState(
        key: const ValueKey('feedback-empty-mine'),
        glyph: const OurneyIcon(name: 'edit', size: 34, active: true),
        title: l10n.feedback_emptyMineTitle,
        body: l10n.feedback_emptyMineBody,
        actionLabel: l10n.feedback_newCta,
        actionKey: const ValueKey('feedback-empty-mine-cta'),
        onAction: onOpenCreate,
      );
    }
    return switch (query.tab) {
      FeatureRequestTab.popular || FeatureRequestTab.newest => UiEmptyState(
          key: const ValueKey('feedback-empty-popular'),
          glyph: const OurneyIcon(name: 'sparkle', size: 34, active: true),
          title: l10n.feedback_emptyPopularTitle,
          body: l10n.feedback_emptyPopularBody,
          actionLabel: l10n.feedback_emptyPopularCta,
          actionKey: const ValueKey('feedback-empty-popular-cta'),
          onAction: onOpenCreate,
        ),
      FeatureRequestTab.planned => UiEmptyState(
          key: const ValueKey('feedback-empty-planned'),
          glyph: const OurneyIcon(name: 'clock', size: 34, active: true),
          title: l10n.feedback_emptyPlannedTitle,
          body: l10n.feedback_emptyPlannedBody,
        ),
      FeatureRequestTab.shipped => UiEmptyState(
          key: const ValueKey('feedback-empty-shipped'),
          glyph: const OurneyIcon(name: 'trophy', size: 34, active: true),
          title: l10n.feedback_emptyShippedTitle,
          body: l10n.feedback_emptyShippedBody,
        ),
    };
  }
}
