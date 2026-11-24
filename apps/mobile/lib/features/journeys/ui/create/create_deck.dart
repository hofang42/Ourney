import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../../ui/ui.dart';
import '../../l10n/generated/journeys_localizations.dart';
import 'create_deck_previews.dart';

/// Velocity-aware snapping scroll physics for [CreateTypeDeck] powered by
/// [UiSprings.snappy]. Eliminates the post-stop `ScrollEndNotification`
/// `animateTo` double-stop hitch by resolving the target card detent
/// immediately on finger release.
class _DeckSnapScrollPhysics extends ScrollPhysics {
  const _DeckSnapScrollPhysics({
    required this.itemExtent,
    required this.itemCount,
    super.parent,
  });

  final double itemExtent;
  final int itemCount;

  @override
  _DeckSnapScrollPhysics applyTo(ScrollPhysics? ancestor) =>
      _DeckSnapScrollPhysics(
        itemExtent: itemExtent,
        itemCount: itemCount,
        parent: buildParent(ancestor),
      );

  @override
  SpringDescription get spring => UiSprings.snappy;

  double _getPage(ScrollMetrics position) =>
      itemExtent > 0 ? position.pixels / itemExtent : 0.0;

  double _getPixels(double page) => page * itemExtent;

  double _getTargetPixels(
    ScrollMetrics position,
    Tolerance tolerance,
    double velocity,
  ) {
    var page = _getPage(position);
    if (velocity < -tolerance.velocity) {
      page -= 0.5;
    } else if (velocity > tolerance.velocity) {
      page += 0.5;
    }
    final maxIndex = math.max(0, itemCount - 1).toDouble();
    final targetPage = page.roundToDouble().clamp(0.0, maxIndex);
    return _getPixels(targetPage).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    final tolerance = toleranceFor(position);
    final target = _getTargetPixels(position, tolerance, velocity);
    if ((target - position.pixels).abs() > tolerance.distance ||
        velocity.abs() > tolerance.velocity) {
      return ScrollSpringSimulation(
        spring,
        position.pixels,
        target,
        velocity,
        tolerance: tolerance,
      );
    }
    return null;
  }

  @override
  bool get allowImplicitScrolling => false;
}

/// One card of the type deck.
@immutable
class CreateDeckItem {
  const CreateDeckItem({
    required this.keyName,
    required this.skinId,
    required this.title,
    required this.tagline,
    required this.meta,
    required this.badge,
  });

  final String keyName;
  final String skinId;
  final String title;
  final String tagline;
  final String meta;

  /// `UiTypeBadge` id.
  final String badge;
}

/// Figma `CreateStepOne` deck: a horizontally swiping row of type preview
/// cards (tap to choose, "Đã chọn" on the focused one), with previous / next
/// buttons and the "n/6" counter.
class CreateTypeDeck extends StatefulWidget {
  const CreateTypeDeck({
    required this.items,
    required this.initial,
    required this.onFocus,
    required this.onChoose,
    super.key,
  });

  final List<CreateDeckItem> items;
  final int initial;
  final ValueChanged<int> onFocus;
  final ValueChanged<int> onChoose;

  @override
  State<CreateTypeDeck> createState() => _CreateTypeDeckState();
}

class _CreateTypeDeckState extends State<CreateTypeDeck> {
  static const double _gap = 12;
  final _scroll = ScrollController();
  late int _focused = widget.initial;
  double _cardWidth = 240;
  bool _placed = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  double _offsetOf(int i) => i * (_cardWidth + _gap);

  int _nearest() {
    if (!_scroll.hasClients) return _focused;
    final step = _cardWidth + _gap;
    if (step <= 0) return _focused;
    final i = (_scroll.offset / step).round();
    return i.clamp(0, widget.items.length - 1);
  }

  void _onScroll() {
    if (!mounted || !_scroll.hasClients) return;
    _setFocus(_nearest());
  }

  Future<void> _go(int i) async {
    final target = i.clamp(0, widget.items.length - 1);
    _setFocus(target);
    if (!_scroll.hasClients) return;
    final still = UiMotion.reduced(context);
    if (still) {
      _scroll.jumpTo(_offsetOf(target));
    } else {
      await _scroll.animateTo(
        _offsetOf(target),
        duration: UiMotion.medium,
        curve: UiCurves.easeOutStrong,
      );
    }
  }

  void _setFocus(int i) {
    if (i == _focused) return;
    unawaited(UiHaptics.selection());
    setState(() => _focused = i);
    widget.onFocus(i);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = JourneysL10n.of(context);
    final ui = context.ui;
    final reduced = UiMotion.reduced(context);
    final n = widget.items.length;
    final cardHeight = (MediaQuery.sizeOf(context).height * 0.52).clamp(
      340.0,
      460.0,
    );
    return Column(
      key: const ValueKey('create-deck'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, c) {
            _cardWidth = math.min(300, math.max(200, c.maxWidth * 0.68));
            final side = (c.maxWidth - _cardWidth) / 2;
            final stepExtent = _cardWidth + _gap;
            if (!_placed) {
              _placed = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _scroll.hasClients && _focused > 0) {
                  _scroll.jumpTo(_offsetOf(_focused));
                }
              });
            }
            return SingleChildScrollView(
              key: const ValueKey('create-deck-scroll'),
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              physics: _DeckSnapScrollPhysics(
                itemExtent: stepExtent,
                itemCount: n,
              ),
              padding: EdgeInsets.symmetric(horizontal: side),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < n; i++) ...[
                    if (i > 0) const SizedBox(width: _gap),
                    SizedBox(
                      width: _cardWidth,
                      height: cardHeight,
                      child: AnimatedBuilder(
                        animation: _scroll,
                        child: _DeckCard(
                          item: widget.items[i],
                          focused: i == _focused,
                          semantic: l10n.journeys_createDeckCard(
                            i + 1,
                            n,
                            widget.items[i].title,
                          ),
                          chosenLabel: l10n.journeys_createDeckChosen,
                          onTap: () => widget.onChoose(i),
                        ),
                        builder: (context, cardChild) {
                          final currentPage =
                              _scroll.hasClients &&
                                  _scroll.position.hasContentDimensions &&
                                  stepExtent > 0
                              ? (_scroll.offset / stepExtent)
                              : _focused.toDouble();
                          final signedDist = i - currentPage;
                          final dist = signedDist.abs().clamp(0.0, 1.0);
                          final opacity = reduced
                              ? (i == _focused ? 1.0 : 0.66)
                              : lerpDouble(1.0, 0.66, dist)!;
                          Widget transformed = FadeTransition(
                            opacity: AlwaysStoppedAnimation<double>(opacity),
                            child: cardChild,
                          );
                          if (!reduced && dist > 0.0001) {
                            final scale = lerpDouble(1.0, 0.90, dist)!;
                            final dy = dist * 6.0;
                            final tilt =
                                signedDist.clamp(-1.5, 1.5) * 0.022;
                            transformed = Transform.translate(
                              offset: Offset(0, dy),
                              child: Transform.rotate(
                                angle: tilt,
                                child: Transform.scale(
                                  scale: scale,
                                  child: transformed,
                                ),
                              ),
                            );
                          }
                          return transformed;
                        },
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
        const SizedBox(height: UiSpace.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            UiIconButton(
              key: const ValueKey('create-deck-prev'),
              glyph: OurneyIcon(
                name: 'chevron-left',
                size: 20,
                flat: true,
                color: _focused == 0 ? ui.inkMuted : ui.ink,
              ),
              label: l10n.journeys_createDeckPrev,
              onPressed: _focused == 0 ? null : () => _go(_focused - 1),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: UiSpace.lg),
              child: Text(
                l10n.journeys_createDeckCounter(_focused + 1, n),
                key: const ValueKey('create-deck-counter'),
                style: UiText.body(
                  size: 15,
                  weight: FontWeight.w800,
                  height: 1.4,
                  color: ui.ink,
                ),
              ),
            ),
            UiIconButton(
              key: const ValueKey('create-deck-next'),
              glyph: OurneyIcon(
                name: 'chevron-right',
                size: 20,
                flat: true,
                color: _focused == n - 1 ? ui.inkMuted : ui.ink,
              ),
              label: l10n.journeys_createDeckNext,
              onPressed: _focused == n - 1 ? null : () => _go(_focused + 1),
            ),
          ],
        ),
      ],
    );
  }
}

class _DeckCard extends StatelessWidget {
  const _DeckCard({
    required this.item,
    required this.focused,
    required this.semantic,
    required this.chosenLabel,
    required this.onTap,
  });

  final CreateDeckItem item;
  final bool focused;
  final String semantic;
  final String chosenLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return UiSkinScope(
      skinId: item.skinId,
      child: Builder(
        builder: (context) {
          final ui = context.ui;
          final headingFont = UiSkinScope.of(context).headingFont;
          return UiPressable(
            key: ValueKey('template-${item.keyName}'),
            onPressed: onTap,
            selected: focused,
            semanticLabel: '$semantic, ${item.tagline}',
            excludeChildSemantics: true,
            borderRadius: BorderRadius.circular(UiRadius.card),
            shadowColor: ui.hardShadowColor,
            shadowOffset: focused ? 4 : 0,
            pressOffset: focused ? 0 : UiShadow.tiny,
            child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: ui.surface,
                    borderRadius: BorderRadius.circular(UiRadius.card),
                    border: Border.all(
                      color: ui.outline,
                      width: focused ? 3 : 2,
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, box) {
                      final big =
                          MediaQuery.textScalerOf(context).scale(16) / 16 >
                          1.35;
                      final title = Text(
                        item.title,
                        maxLines: big ? 3 : 2,
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                        style: UiText.heading(
                          font: headingFont,
                          size: 18,
                          weight: 700,
                          color: ui.ink,
                        ),
                      );
                      Widget preview({double? height}) => Container(
                        height: height,
                        margin: const EdgeInsets.symmetric(vertical: 16),
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                          color: ui.ink.withValues(alpha: 0.05),
                          border: Border.all(
                            color: ui.outline,
                            width: 1.5,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: CreateDeckPreview(
                                key: ValueKey(
                                  'deck-preview-${item.skinId}',
                                ),
                                skinId: item.skinId,
                              ),
                            ),
                            if (focused)
                              PositionedDirectional(
                                top: 8,
                                start: 8,
                                end: 8,
                                child: Align(
                                  alignment: AlignmentDirectional.topEnd,
                                  child: _ChosenChip(label: chosenLabel),
                                ),
                              ),
                          ],
                        ),
                      );
                      final footer = [
                        CreateDeckHud(
                          key: ValueKey('deck-hud-${item.skinId}'),
                          skinId: item.skinId,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          item.tagline,
                          maxLines: big ? 3 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: UiText.body(
                            size: 14,
                            weight: FontWeight.w700,
                            height: 1.35,
                            color: ui.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.meta,
                          maxLines: big ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                          style: UiText.eyebrow(color: ui.inkMuted),
                        ),
                      ];
                      if (!big) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                UiTypeBadge(type: item.badge, size: 48),
                                const SizedBox(width: 10),
                                Expanded(child: title),
                              ],
                            ),
                            Expanded(child: preview()),
                            ...footer,
                          ],
                        );
                      }
                      // Content scrolls inside the card when the text scale
                      // makes it taller than the card (min preview 110dp).
                      return SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Large text: the badge sits above the title so a
                            // word never has to break mid-word to fit.
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: UiTypeBadge(type: item.badge, size: 40),
                            ),
                            const SizedBox(height: 6),
                            title,
                            preview(
                              height: math.max(110, box.maxHeight * 0.38),
                            ),
                            ...footer,
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
        },
      ),
    );
  }
}

/// V2 `.create-focused-badge`: the "✓ Chosen" pill on the focused card.
class _ChosenChip extends StatelessWidget {
  const _ChosenChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return Container(
      key: const ValueKey('create-deck-chosen'),
      constraints: const BoxConstraints(minHeight: 30),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: ui.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: ui.outline, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const OurneyIcon(name: 'check', size: 15, flat: true),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: UiText.eyebrow(color: ui.ink),
            ),
          ),
        ],
      ),
    );
  }
}
