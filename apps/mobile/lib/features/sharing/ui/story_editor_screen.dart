import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/app_routes.dart';
import '../../../app/providers.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../personas/persona_contract.dart';
import '../../../ui/ui.dart';
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
    final picked = await showUiSheet<String>(
      context: context,
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.sharing_coverTitle,
            style: UiText.h2(size: 20, color: context.ui.ink),
          ),
          const SizedBox(height: UiSpace.md),
          GridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (final ci in checkIns)
                Semantics(
                  button: true,
                  selected: ci.id == _coverId,
                  label: formatLocalDate(context, ci.localDate),
                  child: UiPressable(
                    key: ValueKey('story-cover-option-${ci.id}'),
                    onPressed: () => Navigator.of(context).pop(ci.id),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(UiRadius.thumb),
                      child: StoragePhoto(path: ci.thumbPath, cacheWidth: 240),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
    if (picked != null && mounted) setState(() => _coverId = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = SharingL10n.of(context);
    final app = AppLocalizations.of(context);
    final ui = context.ui;

    Widget page(List<Widget> children, {Color? paper, bool canSave = false}) =>
        SharingPage(
          scaffoldKey: const ValueKey('story-editor'),
          background: paper,
          onBack: _leave,
          title: l10n.sharing_storyHeader,
          trailing: UiTextAction(
            key: const ValueKey('story-save'),
            label: app.common_save,
            color: canSave && !_saving ? ui.ink : ui.inkMuted,
            onPressed: canSave && !_saving ? _save : null,
          ),
          children: children,
        );

    if (ref.watch(appConfigProvider).localOnly) {
      return page(const [SharingNeedsServer()]);
    }

    final journeyAsync = ref.watch(sharingJourneyProvider(widget.journeyId));
    final stateAsync = ref.watch(shareStateProvider(widget.journeyId));
    final journey = journeyAsync.value;
    final state = stateAsync.value;
    if (journey == null || state == null) {
      final error = journeyAsync.error ?? stateAsync.error;
      return page([
        if (error == null)
          const SharingLoading()
        else
          SharingErrorView(
            error: error,
            onRetry: () {
              ref.invalidate(sharingJourneyProvider(widget.journeyId));
              ref.invalidate(shareStateProvider(widget.journeyId));
            },
          ),
      ]);
    }
    _seed(state, journey);

    final style = uiStyleForSkin(personaSkinOf(journey));
    final paper = ui.brightness == Brightness.dark ? ui.bg : style.paper;
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

    return page(paper: paper, canSave: true, [
      const SizedBox(height: UiSpace.lg),
      UiTextArea(
        label: l10n.sharing_storyTitleField,
        fieldKey: const ValueKey('story-title'),
        controller: _title,
        maxLength: storyTitleMax,
      ),
      const SizedBox(height: UiSpace.md),
      UiTextArea(
        label: l10n.sharing_introField,
        fieldKey: const ValueKey('story-intro'),
        controller: _intro,
        hint: l10n.sharing_introHint,
        maxLength: storyTextMax,
        minLines: 3,
      ),
      const SizedBox(height: UiSpace.md),
      UiTextArea(
        label: l10n.sharing_lessonsField,
        optionalLabel: l10n.sharing_optional,
        fieldKey: const ValueKey('story-lessons'),
        controller: _lessons,
        maxLength: storyTextMax,
        minLines: 3,
      ),
      const SizedBox(height: UiSpace.md),
      _CoverPicker(
        cover: cover,
        // Only my visible photos: never a hidden or another member's.
        onTap: coverable.isEmpty ? null : () => _pickCover(coverable),
      ),
      const SizedBox(height: UiSpace.xl),
      UiListHeading(title: l10n.sharing_hidePhotos),
      const SizedBox(height: 4),
      Text(
        mine.isEmpty ? l10n.sharing_noPhotosYet : l10n.sharing_hidePhotosHint,
        style: UiText.body(size: 13, color: ui.inkMuted),
      ),
      const SizedBox(height: UiSpace.sm),
      GridView.count(
        crossAxisCount: 4,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
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
    ]);
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
    final ui = context.ui;
    return Semantics(
      button: true,
      label: l10n.sharing_pickCover,
      excludeSemantics: true,
      child: UiPressable(
        key: const ValueKey('story-cover'),
        onPressed: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(UiRadius.card),
          child: SizedBox(
            height: 180,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (cover != null)
                  StoragePhoto(path: cover!.photoPath)
                else
                  ColoredBox(color: ui.fill),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: UiSpace.md),
                    child: UiGlassChip(
                      leading: Icons.image_outlined,
                      label: l10n.sharing_pickCover,
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
    final ui = context.ui;
    final date = formatLocalDate(context, checkIn.localDate);
    return Semantics(
      button: true,
      toggled: hidden,
      label: hidden
          ? l10n.sharing_photoHidden(date)
          : l10n.sharing_photoShown(date),
      excludeSemantics: true,
      child: UiPressable(
        key: ValueKey('story-hide-${checkIn.id}'),
        onPressed: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(UiRadius.otp),
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
                      color: ui.bg.withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.visibility_off_rounded,
                      size: 20,
                      color: ui.ink,
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
