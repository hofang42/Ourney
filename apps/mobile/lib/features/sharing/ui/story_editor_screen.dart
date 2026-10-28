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
import '../../../shared/needs_server_view.dart';
import '../data/sharing_providers.dart';
import '../l10n/generated/sharing_localizations.dart';
import 'sharing_widgets.dart';

const int storyTitleMax = 60;
const int storyTextMax = 300;

/// `/sharing/:journeyId/story` (SCR-83): story title, intro, lessons, cover
/// photo and which of the caller's photos are hidden in every share (S11).
class StoryEditorScreen extends ConsumerStatefulWidget {
  const StoryEditorScreen({required this.journeyId, super.key});

  final String journeyId;

  @override
  ConsumerState<StoryEditorScreen> createState() => _StoryEditorScreenState();
}

class _StoryEditorScreenState extends ConsumerState<StoryEditorScreen> {
  final _title = TextEditingController();
  final _intro = TextEditingController();
  final _lessons = TextEditingController();
  String? _coverId;
  bool _seeded = false;
  bool _saving = false;

  /// Local mirror of the hidden set (optimistic toggles).
  Set<String>? _hidden;

  @override
  void dispose() {
    _title.dispose();
    _intro.dispose();
    _lessons.dispose();
    super.dispose();
  }

  void _seed(JourneyShareState state, Journey journey) {
    if (_seeded) return;
    _seeded = true;
    _title.text = state.story.title ?? journey.title;
    _intro.text = state.story.intro ?? '';
    _lessons.text = state.story.lessons ?? '';
    _coverId = state.story.coverCheckInId;
    _hidden = {...state.hiddenCheckInIds};
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.shareJourney(widget.journeyId));
    }
  }

  String? _clean(String s) {
    final t = s.trim();
    return t.isEmpty ? null : t;
  }

  Future<void> _save() async {
    final l10n = SharingL10n.of(context);
    setState(() => _saving = true);
    try {
      await ref
          .read(sharingRepositoryProvider)
          .updateStory(
            widget.journeyId,
            JourneyStory(
              title: _clean(_title.text),
              intro: _clean(_intro.text),
              lessons: _clean(_lessons.text),
              coverCheckInId: _coverId,
            ),
          );
      if (!mounted) return;
      showSharingSnack(context, l10n.sharing_storySaved);
      _leave();
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showSharingSnack(context, sharingErrorMessage(context, e));
    }
  }

  Future<void> _toggleHidden(CheckIn checkIn) async {
    final hidden = _hidden!;
    final hide = !hidden.contains(checkIn.id);
    setState(() => _hidden = {...hidden}..let(hide, checkIn.id));
    try {
      await ref
          .read(sharingRepositoryProvider)
          .setHiddenInShare(checkIn.id, hidden: hide);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _hidden = {..._hidden!}..let(!hide, checkIn.id));
      showSharingSnack(context, sharingErrorMessage(context, e));
    }
  }

  Future<void> _pickCover(List<CheckIn> checkIns) async {
    final l10n = SharingL10n.of(context);
    final picked = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: OurneyColors.of(context).bg,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (context, controller) => CustomScrollView(
          controller: controller,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              sliver: SliverToBoxAdapter(
                child: Text(l10n.sharing_coverTitle, style: headingStyle()),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              sliver: SliverGrid.count(
                crossAxisCount: 3,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                children: [
                  for (final ci in checkIns)
                    Semantics(
                      button: true,
                      selected: ci.id == _coverId,
                      label: formatLocalDate(context, ci.localDate),
                      child: InkWell(
                        key: ValueKey('story-cover-option-${ci.id}'),
                        onTap: () => Navigator.of(context).pop(ci.id),
                        child: StoragePhoto(
                          path: ci.thumbPath,
                          cacheWidth: 240,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (picked != null && mounted) setState(() => _coverId = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = SharingL10n.of(context);
    final app = AppLocalizations.of(context);
    final c = OurneyColors.of(context);
    final localOnly = ref.watch(appConfigProvider).localOnly;

    Widget scaffold(Widget body, {Color? paper, bool canSave = false}) =>
        Scaffold(
          key: const ValueKey('story-editor'),
          backgroundColor: paper,
          appBar: AppBar(
            backgroundColor: paper,
            centerTitle: true,
            leadingWidth: 96,
            leading: TextButton(
              key: const ValueKey('story-cancel'),
              style: TextButton.styleFrom(foregroundColor: c.ink),
              onPressed: _leave,
              child: Text(
                app.common_cancel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: sharingLabel(context, size: 14),
              ),
            ),
            title: SharingNavTitle(title: l10n.sharing_storyHeader),
            actions: [
              TextButton(
                key: const ValueKey('story-save'),
                style: TextButton.styleFrom(
                  foregroundColor: c.ink,
                  minimumSize: const Size(64, 48),
                ),
                onPressed: canSave && !_saving ? _save : null,
                child: Text(
                  app.common_save,
                  style: sharingLabel(
                    context,
                    size: 14,
                    color: canSave && !_saving ? c.ink : c.inkMuted,
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: SafeArea(top: false, child: body),
        );

    if (localOnly) return scaffold(const NeedsServerView());

    final journeyAsync = ref.watch(sharingJourneyProvider(widget.journeyId));
    final stateAsync = ref.watch(shareStateProvider(widget.journeyId));
    final journey = journeyAsync.value;
    final state = stateAsync.value;
    if (journey == null || state == null) {
      final error = journeyAsync.error ?? stateAsync.error;
      return scaffold(
        error == null
            ? const SharingLoading()
            : SharingErrorView(
                error: error,
                onRetry: () {
                  ref.invalidate(sharingJourneyProvider(widget.journeyId));
                  ref.invalidate(shareStateProvider(widget.journeyId));
                },
              ),
      );
    }
    _seed(state, journey);

    final brightness = Theme.of(context).brightness;
    final style = OurneyPersonaTheme.forSkin(
      personaSkinOf(journey),
      brightness,
    );
    final paper = brightness == Brightness.dark ? c.bg : style.background;
    final all =
        ref.watch(sharingCheckInsProvider(widget.journeyId)).value ??
        const <CheckIn>[];
    final me = ref.watch(currentUserIdProvider);
    final coverable = [
      for (final ci in all)
        if ((me == null || ci.userId == me) &&
            !(_hidden?.contains(ci.id) ?? false))
          ci,
    ];
    final mine = [
      for (final ci in all)
        if (me == null || ci.userId == me) ci,
    ];
    final cover = all.where((ci) => ci.id == _coverId).firstOrNull;
    final hidden = _hidden!;

    Widget field(
      String key,
      String label,
      TextEditingController controller,
      int max, {
      String? hint,
      bool optional = false,
      int lines = 1,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: 17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              text: label,
              children: [
                if (optional)
                  TextSpan(
                    text: '  ${l10n.sharing_optional}',
                    style: sharingBody(context, size: 12, color: c.inkMuted),
                  ),
              ],
            ),
            style: sharingLabel(context, size: 13),
          ),
          const SizedBox(height: 6),
          TextField(
            key: ValueKey(key),
            controller: controller,
            maxLength: max,
            minLines: lines,
            maxLines: lines == 1 ? 1 : 6,
            textCapitalization: TextCapitalization.sentences,
            style: sharingBody(context, size: 15),
            decoration: InputDecoration(hintText: hint),
          ),
        ],
      ),
    );

    return scaffold(
      paper: paper,
      canSave: true,
      SharingColumn(
        builder: (context, gutter) => ListView(
          padding: EdgeInsets.fromLTRB(gutter, 22, gutter, 40),
          children: [
            field(
              'story-title',
              l10n.sharing_storyTitleField,
              _title,
              storyTitleMax,
            ),
            field(
              'story-intro',
              l10n.sharing_introField,
              _intro,
              storyTextMax,
              hint: l10n.sharing_introHint,
              lines: 3,
            ),
            field(
              'story-lessons',
              l10n.sharing_lessonsField,
              _lessons,
              storyTextMax,
              optional: true,
              lines: 3,
            ),
            _CoverPicker(
              cover: cover,
              // Only my visible photos: never a hidden or another member's.
              onTap: coverable.isEmpty ? null : () => _pickCover(coverable),
            ),
            const SizedBox(height: 22),
            Semantics(
              header: true,
              child: Text(
                l10n.sharing_hidePhotos,
                style: headingStyle(size: 18),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              mine.isEmpty
                  ? l10n.sharing_noPhotosYet
                  : l10n.sharing_hidePhotosHint,
              style: sharingBody(context, size: 13, color: c.inkMuted),
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 4,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final ci in mine)
                  _HideCell(
                    checkIn: ci,
                    hidden: hidden.contains(ci.id),
                    onTap: () => _toggleHidden(ci),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

extension on Set<String> {
  /// Adds [id] when [add], else removes it.
  void let(bool add, String id) => add ? this.add(id) : remove(id);
}

class _CoverPicker extends StatelessWidget {
  const _CoverPicker({required this.cover, required this.onTap});

  final CheckIn? cover;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = SharingL10n.of(context);
    final c = OurneyColors.of(context);
    return Semantics(
      button: true,
      label: l10n.sharing_pickCover,
      excludeSemantics: true,
      child: InkWell(
        key: const ValueKey('story-cover'),
        onTap: onTap,
        child: SizedBox(
          height: 180,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (cover != null)
                StoragePhoto(path: cover!.photoPath)
              else
                ColoredBox(color: c.surfaceSunken),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 48),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: OurneyColors.light.surface.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.image_outlined,
                          size: 16,
                          color: OurneyColors.light.ink,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            l10n.sharing_pickCover,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: sharingLabel(
                              context,
                              size: 13,
                              color: OurneyColors.light.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HideCell extends StatelessWidget {
  const _HideCell({
    required this.checkIn,
    required this.hidden,
    required this.onTap,
  });

  final CheckIn checkIn;
  final bool hidden;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = SharingL10n.of(context);
    final c = OurneyColors.of(context);
    final date = formatLocalDate(context, checkIn.localDate);
    return Semantics(
      button: true,
      toggled: hidden,
      label: hidden
          ? l10n.sharing_photoHidden(date)
          : l10n.sharing_photoShown(date),
      excludeSemantics: true,
      child: InkWell(
        key: ValueKey('story-hide-${checkIn.id}'),
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
              opacity: hidden ? 0.32 : 1,
              child: StoragePhoto(path: checkIn.thumbPath, cacheWidth: 200),
            ),
            if (hidden)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: c.bg.withValues(alpha: 0.85),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.visibility_off_rounded,
                    size: 20,
                    color: c.ink,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
