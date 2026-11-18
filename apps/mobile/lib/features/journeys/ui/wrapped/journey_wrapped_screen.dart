import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../../app/app_routes.dart';
import '../../../../personas/persona_contract.dart';
import '../../../../ui/ui.dart';
import '../../data/journeys_providers.dart';
import '../../domain/journey_progress.dart';
import '../../domain/wrapped_story.dart';
import '../../journeys_paths.dart';
import '../../l10n/generated/journeys_localizations.dart';
import 'wrapped_visuals.dart';

/// `/journey/:id/wrapped`, Figma `JourneyWrappedScreen` ("Hành trình đã về
/// đích"): full-screen story pages (tap right / left half or swipe), segment
/// progress at the top, then a summary card in 9:16 or 4:5 with share
/// actions. Entered after ending a journey and from the journey home.
class JourneyWrappedScreen extends ConsumerWidget {
  const JourneyWrappedScreen({required this.journeyId, super.key});

  final String journeyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = JourneysL10n.of(context);
    final journey = ref.watch(journeyByIdProvider(journeyId)).value;
    final checkIns = ref.watch(myCheckInsProvider(journeyId)).value;
    if (journey == null || checkIns == null) {
      return UiScaffold(
        key: const ValueKey('journey-wrapped-empty'),
        padTop: 0,
        child: UiBackHeader(
          onBack: () => _close(context, journeyId),
          backLabel: l10n.journeys_back,
        ),
      );
    }
    final progress = JourneyProgress.compute(
      journey: journey,
      membership: ref.watch(myMembershipProvider(journeyId)).value,
      checkIns: checkIns,
      now: ref.watch(journeysNowProvider),
    );
    return _WrappedBody(journey: journey, stats: WrappedStats.from(progress));
  }
}

void _close(BuildContext context, String id) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(JourneysPaths.home(id));
  }
}

class _WrappedBody extends StatefulWidget {
  const _WrappedBody({required this.journey, required this.stats});

  final Journey journey;
  final WrappedStats stats;

  @override
  State<_WrappedBody> createState() => _WrappedBodyState();
}

enum _Ratio { story, feed }

class _WrappedBodyState extends State<_WrappedBody> {
  int _page = 0;
  _Ratio _ratio = _Ratio.story;
  bool _hideKg = true;
  bool _blurred = true;
  late bool _hideBrand =
      personaSkinOf(widget.journey) == PersonaSkinId.quietTransformer;

  void _move(int dir, int count) =>
      setState(() => _page = (_page + dir).clamp(0, count));

  @override
  Widget build(BuildContext context) {
    final l10n = JourneysL10n.of(context);
    final j = widget.journey;
    final skin = personaSkinOf(j);
    final pages = wrappedPagesFor(l10n, j, skin, widget.stats);
    final summary = _page >= pages.length;
    final selected = _page.clamp(0, pages.length - 1);

    return UiSkinScope(
      skinId: uiSkinIdFor(skin),
      variant: j.color ?? 0,
      child: Builder(
        builder: (context) {
          final ui = context.ui;
          return UiScaffold(
            key: const ValueKey('journey-wrapped'),
            padTop: 0,
            scroll: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                UiBackHeader(
                  onBack: () => _close(context, j.id),
                  backLabel: l10n.journeys_back,
                  title: l10n.journeys_wrapped_title,
                  bordered: false,
                  trailing: UiIconButton(
                    key: const ValueKey('wrapped-close'),
                    glyph: const OurneyIcon(
                      name: 'close',
                      size: 22,
                      flat: true,
                    ),
                    label: l10n.journeys_wrapped_close,
                    onPressed: () => _close(context, j.id),
                  ),
                ),
                _Segments(
                  count: pages.length,
                  selected: selected,
                  labelOf: l10n.journeys_wrapped_step,
                  onTap: (i) => setState(() => _page = i),
                ),
                const SizedBox(height: UiSpace.lg),
                Expanded(
                  child: summary
                      ? _Summary(
                          journey: j,
                          skin: skin,
                          stats: widget.stats,
                          ratio: _ratio,
                          hideKg: _hideKg,
                          blurred: _blurred,
                          hideBrand: _hideBrand,
                          onRatio: (r) => setState(() => _ratio = r),
                          onHideKg: () => setState(() => _hideKg = !_hideKg),
                          onBlur: () => setState(() => _blurred = !_blurred),
                          onHideBrand: (v) => setState(() => _hideBrand = v),
                        )
                      : _Story(
                          key: ValueKey('wrapped-page-$_page'),
                          skin: skin,
                          stats: widget.stats,
                          page: _page,
                          headline: pages[_page],
                          footnote:
                              skin == PersonaSkinId.memoryCollectors &&
                                  _page == pages.length - 1
                              ? l10n.journeys_wrapped_memoryEnd
                              : null,
                          color: ui.ink,
                          onTapSide: (forward) =>
                              _move(forward ? 1 : -1, pages.length),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// `.wrapped-progress`: one segment per page, tappable.
class _Segments extends StatelessWidget {
  const _Segments({
    required this.count,
    required this.selected,
    required this.labelOf,
    required this.onTap,
  });

  final int count;
  final int selected;
  final String Function(int n) labelOf;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return Row(
      key: const ValueKey('wrapped-progress'),
      children: [
        for (var i = 0; i < count; i++)
          Expanded(
            child: UiPressable(
              key: ValueKey('wrapped-segment-$i'),
              onPressed: () => onTap(i),
              selected: i == selected,
              semanticLabel: labelOf(i + 1),
              excludeChildSemantics: true,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 3,
                  vertical: 21,
                ),
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: i <= selected ? ui.accent : ui.fill,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: ui.ink, width: 1.5),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Story extends StatelessWidget {
  const _Story({
    required this.skin,
    required this.stats,
    required this.page,
    required this.headline,
    required this.color,
    required this.onTapSide,
    this.footnote,
    super.key,
  });

  final PersonaSkinId skin;
  final WrappedStats stats;
  final int page;
  final String headline;
  final String? footnote;
  final Color color;
  final ValueChanged<bool> onTapSide;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return LayoutBuilder(
      builder: (context, c) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) => onTapSide(d.localPosition.dx > c.maxWidth / 2),
        onHorizontalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          if (v.abs() > 200) onTapSide(v < 0);
        },
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: c.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                WrappedVisual(skin: skin, stats: stats, page: page),
                const SizedBox(height: UiSpace.xl),
                Semantics(
                  header: true,
                  child: Text(
                    headline,
                    key: const ValueKey('wrapped-headline'),
                    textAlign: TextAlign.center,
                    style: UiText.h1(
                      color: color,
                      size: 34,
                    ).copyWith(height: 1.25),
                  ),
                ),
                if (footnote != null) ...[
                  const SizedBox(height: UiSpace.md),
                  Text(
                    footnote!,
                    textAlign: TextAlign.center,
                    style: UiText.muted(color: ui.inkMuted)
                        .copyWith(height: 1.45),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.journey,
    required this.skin,
    required this.stats,
    required this.ratio,
    required this.hideKg,
    required this.blurred,
    required this.hideBrand,
    required this.onRatio,
    required this.onHideKg,
    required this.onBlur,
    required this.onHideBrand,
  });

  final Journey journey;
  final PersonaSkinId skin;
  final WrappedStats stats;
  final _Ratio ratio;
  final bool hideKg;
  final bool blurred;
  final bool hideBrand;
  final ValueChanged<_Ratio> onRatio;
  final VoidCallback onHideKg;
  final VoidCallback onBlur;
  final ValueChanged<bool> onHideBrand;

  /// "65.2 kg - 62.0 kg" from the first and last logged metric, if any.
  static String? _weights(WrappedStats s) {
    final values = s.weights;
    if (values.length < 2) return null;
    String f(double v) => v.toStringAsFixed(1);
    return '${f(values.first)} kg  >  ${f(values.last)} kg';
  }

  String _cta(JourneysL10n l10n) => switch (skin) {
    PersonaSkinId.memoryCollectors => l10n.journeys_wrapped_ctaPoster,
    PersonaSkinId.coupleRituals => l10n.journeys_wrapped_ctaStory,
    PersonaSkinId.aestheticFlexer => l10n.journeys_wrapped_ctaFlexer,
    PersonaSkinId.minimalistHabit => l10n.journeys_wrapped_ctaMinimal,
    _ => l10n.journeys_wrapped_ctaCard,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = JourneysL10n.of(context);
    final ui = context.ui;
    final quiet = skin == PersonaSkinId.quietTransformer;
    void openShare() => context.push(AppRoutes.share(journey.id));

    return SingleChildScrollView(
      key: const ValueKey('wrapped-summary'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UiSegmented<_Ratio>(
            segments: const [
              UiSegment(value: _Ratio.story, label: '9:16'),
              UiSegment(value: _Ratio.feed, label: '4:5'),
            ],
            value: ratio,
            onChanged: onRatio,
          ),
          const SizedBox(height: UiSpace.lg),
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: ratio == _Ratio.story ? 230 : 290,
              ),
              child: AspectRatio(
                key: ValueKey('wrapped-card-${ratio.name}'),
                aspectRatio: ratio == _Ratio.story ? 9 / 16 : 4 / 5,
                child: Container(
                  padding: const EdgeInsets.all(UiSpace.md),
                  decoration: BoxDecoration(
                    color: ui.surface,
                    borderRadius: BorderRadius.circular(UiRadius.card),
                    border: Border.all(color: ui.ink, width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Flexible(
                        flex: 3,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: SizedBox(
                            width: 240,
                            child: WrappedVisual(
                              skin: skin,
                              stats: stats,
                              page: 3,
                              blurPhotos: quiet && blurred,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        wrappedSummaryTitle(l10n, journey, skin, stats),
                        key: const ValueKey('wrapped-summary-title'),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: UiText.h2(
                          color: ui.ink,
                          size: 16,
                        ).copyWith(height: 1.35),
                      ),
                      if (quiet && !hideKg && _weights(stats) != null)
                        Text(
                          _weights(stats)!,
                          key: const ValueKey('wrapped-weights'),
                          style: UiText.muted(color: ui.ink)
                              .copyWith(height: 1.4),
                        ),
                      if (!hideBrand)
                        const UiWordmark(
                          key: ValueKey('wrapped-brand'),
                          size: 30,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (quiet) ...[
            const SizedBox(height: UiSpace.md),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: UiSpace.sm,
              runSpacing: UiSpace.sm,
              children: [
                UiChip(
                  key: const ValueKey('wrapped-hide-kg'),
                  label:
                      '${l10n.journeys_wrapped_hideKg} · ${hideKg ? l10n.journeys_wrapped_on : l10n.journeys_wrapped_off}',
                  selected: hideKg,
                  glyph: OurneyIcon(
                    name: hideKg ? 'check' : 'eye',
                    size: 14,
                    flat: true,
                  ),
                  onPressed: onHideKg,
                ),
                UiChip(
                  key: const ValueKey('wrapped-blur'),
                  label:
                      '${l10n.journeys_wrapped_blur} · ${blurred ? l10n.journeys_wrapped_on : l10n.journeys_wrapped_off}',
                  selected: blurred,
                  glyph: OurneyIcon(
                    name: blurred ? 'check' : 'eye',
                    size: 14,
                    flat: true,
                  ),
                  onPressed: onBlur,
                ),
              ],
            ),
          ],
          const SizedBox(height: UiSpace.lg),
          UiButton(
            key: const ValueKey('wrapped-cta'),
            label: _cta(l10n),
            onPressed: openShare,
          ),
          const SizedBox(height: UiSpace.sm),
          Row(
            children: [
              Expanded(
                child: UiButton.secondary(
                  key: const ValueKey('wrapped-share'),
                  label: l10n.journeys_wrapped_share,
                  glyph: const OurneyIcon(name: 'share', size: 18, flat: true),
                  onPressed: () => _shareSheet(context),
                ),
              ),
              const SizedBox(width: UiSpace.sm),
              Expanded(
                child: UiButton.secondary(
                  key: const ValueKey('wrapped-save'),
                  label: l10n.journeys_wrapped_save,
                  glyph: const OurneyIcon(
                    name: 'download',
                    size: 18,
                    flat: true,
                  ),
                  onPressed: openShare,
                ),
              ),
            ],
          ),
          const SizedBox(height: UiSpace.xl),
        ],
      ),
    );
  }

  Future<void> _shareSheet(BuildContext context) {
    final l10n = JourneysL10n.of(context);
    return showUiSheet<void>(
      context: context,
      builder: (ctx) => _ShareSheet(
        l10n: l10n,
        hideBrand: hideBrand,
        onHideBrand: onHideBrand,
        onOpen: () {
          Navigator.of(ctx).pop();
          context.push(AppRoutes.share(journey.id));
        },
      ),
    );
  }
}

class _ShareSheet extends StatefulWidget {
  const _ShareSheet({
    required this.l10n,
    required this.hideBrand,
    required this.onHideBrand,
    required this.onOpen,
  });

  final JourneysL10n l10n;
  final bool hideBrand;
  final ValueChanged<bool> onHideBrand;
  final VoidCallback onOpen;

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  late bool _hide = widget.hideBrand;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final l10n = widget.l10n;
    return Column(
      key: const ValueKey('wrapped-share-sheet'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.journeys_wrapped_sheetTitle,
            style: UiText.h2(color: ui.ink),
          ),
        ),
        const SizedBox(height: UiSpace.md),
        UiSwitchRow(
          key: const ValueKey('wrapped-hide-brand'),
          label: l10n.journeys_wrapped_hideBrand,
          value: _hide,
          onChanged: (v) {
            setState(() => _hide = v);
            widget.onHideBrand(v);
          },
        ),
        const SizedBox(height: UiSpace.md),
        UiButton(
          label: l10n.journeys_wrapped_messages,
          onPressed: widget.onOpen,
        ),
        const SizedBox(height: UiSpace.sm),
        UiButton.secondary(
          label: l10n.journeys_wrapped_otherApps,
          onPressed: widget.onOpen,
        ),
      ],
    );
  }
}
