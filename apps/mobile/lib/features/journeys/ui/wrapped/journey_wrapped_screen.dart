import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../../app/app_routes.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../personas/persona_contract.dart';
import '../../../../ui/ui.dart';
import '../../../share_card/domain/share_card_content.dart'
    show activePublicToken;
import '../../../social/data/social_providers.dart'
    show socialShareLauncherProvider;
import '../../data/journeys_providers.dart';
import '../../domain/journey_progress.dart';
import '../../domain/wrapped_story.dart';
import '../../journeys_paths.dart';
import '../../l10n/generated/journeys_localizations.dart';
import '../journey_errors.dart';
import 'wrapped_visuals.dart';

/// Builds the text caption shared from the Wrapped summary sheet (DE-17).
String wrappedShareText(
  JourneysL10n l10n,
  Journey journey,
  PersonaSkinId skin,
  WrappedStats stats,
) {
  final summary = wrappedSummaryTitle(l10n, journey, skin, stats);
  final token = activePublicToken(journey);
  final link = token != null
      ? 'https://ourney.tech/p/$token'
      : 'https://ourney.tech';
  return '${journey.emoji} ${journey.title} — $summary\n$link';
}

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
    final app = AppLocalizations.of(context);
    final journeyAsync = ref.watch(journeyByIdProvider(journeyId));
    final checkInsAsync = ref.watch(myCheckInsProvider(journeyId));
    final journey = journeyAsync.value;
    final checkIns = checkInsAsync.value;
    if (journey == null || checkIns == null) {
      final notFound =
          !journeyAsync.isLoading && !journeyAsync.hasError && journey == null;
      final hasError =
          !notFound && (journeyAsync.hasError || checkInsAsync.hasError);
      final error = journeyAsync.error ?? checkInsAsync.error;
      final isLoading = !notFound && !hasError;
      void back() {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(
            journey != null ? JourneysPaths.home(journeyId) : AppRoutes.journeys,
          );
        }
      }

      return UiScaffold(
        key: const ValueKey('journey-wrapped-empty'),
        padTop: 0,
        child: Column(
          children: [
            UiBackHeader(
              onBack: back,
              backLabel: l10n.journeys_back,
            ),
            if (isLoading)
              Padding(
                padding: const EdgeInsets.only(top: 120),
                child: Center(
                  child: CircularProgressIndicator(
                    key: const ValueKey('journey-wrapped-loading'),
                    semanticsLabel: app.common_loading,
                  ),
                ),
              )
            else
              UiEmptyState(
                key: ValueKey(
                  hasError
                      ? 'journey-wrapped-error'
                      : 'journey-wrapped-not-found',
                ),
                glyph: OurneyIcon(
                  name: hasError ? 'error' : 'search',
                  size: 40,
                ),
                title: hasError
                    ? journeyErrorMessage(context, error!)
                    : l10n.journeys_errorNotFound,
                actionLabel: hasError ? app.common_retry : l10n.journeys_title,
                onAction: hasError
                    ? () {
                        ref.invalidate(journeyByIdProvider(journeyId));
                        ref.invalidate(myCheckInsProvider(journeyId));
                      }
                    : () => context.go(AppRoutes.journeys),
              ),
          ],
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
                  // U4: the arrow steps back a page; only the close button
                  // leaves the screen.
                  onBack: () => _page > 0
                      ? _move(-1, pages.length)
                      : _close(context, j.id),
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
                  // One extra segment for the summary page (U4).
                  count: pages.length + 1,
                  selected: _page.clamp(0, pages.length),
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
                          hideBrand: _hideBrand,
                          onRatio: (r) => setState(() => _ratio = r),
                          onHideKg: () => setState(() => _hideKg = !_hideKg),
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
                    border: Border.all(color: ui.outline, width: 1.5),
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
      // U4: one labelled node with explicit next / previous actions, so a
      // screen reader can step through the story (a double tap lands on the
      // exact centre and used to always go back).
      builder: (context, c) => Semantics(
        container: true,
        excludeSemantics: true,
        button: true,
        label: footnote == null ? headline : '$headline. $footnote',
        onTap: () => onTapSide(true),
        onScrollLeft: () => onTapSide(true),
        onScrollRight: () => onTapSide(false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) => onTapSide(d.localPosition.dx >= c.maxWidth / 2),
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
                  Text(
                    headline,
                    key: const ValueKey('wrapped-headline'),
                    textAlign: TextAlign.center,
                    style: UiText.h1(
                      color: color,
                      size: 34,
                    ).copyWith(height: 1.25),
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
      ),
    );
  }
}

class _Summary extends ConsumerWidget {
  const _Summary({
    required this.journey,
    required this.skin,
    required this.stats,
    required this.ratio,
    required this.hideKg,
    required this.hideBrand,
    required this.onRatio,
    required this.onHideKg,
    required this.onHideBrand,
  });

  final Journey journey;
  final PersonaSkinId skin;
  final WrappedStats stats;
  final _Ratio ratio;
  final bool hideKg;
  final bool hideBrand;
  final ValueChanged<_Ratio> onRatio;
  final VoidCallback onHideKg;
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
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = JourneysL10n.of(context);
    final ui = context.ui;
    final quiet = skin == PersonaSkinId.quietTransformer;
    // U4: carry the format and privacy choices over to the card editor. The
    // photo blur is not handed over: the quiet card always blurs its portrait.
    void openShare() => context.push(
      AppRoutes.share(
        journey.id,
        format: ratio == _Ratio.story ? 'story' : 'feed',
        hideBrand: hideBrand,
        hideMetric: quiet ? hideKg : null,
      ),
    );
    void shareNow() {
      final launcher = ref.read(socialShareLauncherProvider);
      unawaited(launcher(wrappedShareText(l10n, journey, skin, stats)));
    }

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
                    border: Border.all(color: ui.outline, width: 2),
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
                              blurPhotos: quiet,
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
                // Locked: the quiet card always blurs its portrait, so the
                // chip shows that state instead of a switch that does nothing.
                UiChip(
                  key: const ValueKey('wrapped-blur'),
                  label:
                      '${l10n.journeys_wrapped_blur} · ${l10n.journeys_wrapped_on}',
                  selected: true,
                  glyph: const OurneyIcon(name: 'check', size: 14, flat: true),
                  onPressed: null,
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
                  onPressed: () => _shareSheet(context, shareNow),
                ),
              ),
              const SizedBox(width: UiSpace.sm),
              Expanded(
                child: UiButton.secondary(
                  key: const ValueKey('wrapped-edit-card'),
                  label: l10n.journeys_wrapped_editCard,
                  glyph: const OurneyIcon(name: 'pencil', size: 18, flat: true),
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

  Future<void> _shareSheet(BuildContext context, VoidCallback onShare) {
    final l10n = JourneysL10n.of(context);
    return showUiSheet<void>(
      context: context,
      builder: (ctx) => _ShareSheet(
        l10n: l10n,
        hideBrand: hideBrand,
        onHideBrand: onHideBrand,
        onShare: () {
          Navigator.of(ctx).pop();
          onShare();
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
    required this.onShare,
  });

  final JourneysL10n l10n;
  final bool hideBrand;
  final ValueChanged<bool> onHideBrand;
  final VoidCallback onShare;

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
          key: const ValueKey('wrapped-share-messages'),
          label: l10n.journeys_wrapped_messages,
          onPressed: widget.onShare,
        ),
        const SizedBox(height: UiSpace.sm),
        UiButton.secondary(
          key: const ValueKey('wrapped-share-other'),
          label: l10n.journeys_wrapped_otherApps,
          onPressed: widget.onShare,
        ),
      ],
    );
  }
}
