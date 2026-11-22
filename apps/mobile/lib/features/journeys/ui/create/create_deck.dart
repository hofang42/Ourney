import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../ui/ui.dart';
import '../../l10n/generated/journeys_localizations.dart';
import 'create_deck_previews.dart';

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
  bool _snapping = false;
  bool _placed = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  double _offsetOf(int i) => i * (_cardWidth + _gap);

  int _nearest() {
    if (!_scroll.hasClients) return _focused;
    final i = (_scroll.offset / (_cardWidth + _gap)).round();
    return i.clamp(0, widget.items.length - 1);
  }

  Future<void> _go(int i) async {
    final target = i.clamp(0, widget.items.length - 1);
    _setFocus(target);
    if (!_scroll.hasClients) return;
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _snapping = true;
    if (still) {
      _scroll.jumpTo(_offsetOf(target));
    } else {
      await _scroll.animateTo(
        _offsetOf(target),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
    _snapping = false;
  }

  void _setFocus(int i) {
    if (i == _focused) return;
    setState(() => _focused = i);
    widget.onFocus(i);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = JourneysL10n.of(context);
    final ui = context.ui;
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
            if (!_placed) {
              _placed = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _scroll.hasClients && _focused > 0) {
                  _scroll.jumpTo(_offsetOf(_focused));
                }
              });
            }
            return NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n is ScrollUpdateNotification && !_snapping) {
                  _setFocus(_nearest());
                } else if (n is ScrollEndNotification && !_snapping) {
                  unawaited(_go(_nearest()));
                }
                return false;
              },
              child: SingleChildScrollView(
                key: const ValueKey('create-deck-scroll'),
                controller: _scroll,
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: side),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < n; i++) ...[
                      if (i > 0) const SizedBox(width: _gap),
                      SizedBox(
                        width: _cardWidth,
                        height: cardHeight,
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
                      ),
                    ],
                  ],
                ),
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
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final duration = disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 200);
    return UiSkinScope(
      skinId: item.skinId,
      child: Builder(
        builder: (context) {
          final ui = context.ui;
          final headingFont = UiSkinScope.of(context).headingFont;
          return AnimatedScale(
            scale: focused ? 1.0 : 0.88,
            duration: duration,
            curve: Curves.easeOut,
            child: AnimatedOpacity(
              opacity: focused ? 1.0 : 0.66,
              duration: duration,
              curve: Curves.easeOut,
              child: UiPressable(
                key: ValueKey('template-${item.keyName}'),
                onPressed: onTap,
                selected: focused,
                semanticLabel: '$semantic, ${item.tagline}',
                excludeChildSemantics: true,
                borderRadius: BorderRadius.circular(UiRadius.card),
                shadowColor: ui.hardShadowColor,
                shadowOffset: focused ? 4 : 0,
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
                        maxLines: 3,
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                        style: UiText.heading(
                          font: headingFont,
                          size: 18,
                          weight: 700,
                          color: ui.ink,
                        ),
                      );
                      // Content scrolls inside the card when the text scale
                      // makes it taller than the card (min preview 110dp).
                      return SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Large text: the badge sits above the title so a
                            // word never has to break mid-word to fit.
                            if (big) ...[
                              Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: UiTypeBadge(type: item.badge, size: 40),
                              ),
                              const SizedBox(height: 6),
                              title,
                            ] else
                              Row(
                                children: [
                                  UiTypeBadge(type: item.badge, size: 48),
                                  const SizedBox(width: 10),
                                  Expanded(child: title),
                                ],
                              ),
                            Container(
                              height: math.max(110, box.maxHeight * 0.42),
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
                                      end: 8,
                                      child: _ChosenChip(label: chosenLabel),
                                    ),
                                ],
                              ),
                            ),
                            CreateDeckHud(
                              key: ValueKey('deck-hud-${item.skinId}'),
                              skinId: item.skinId,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              item.tagline,
                              maxLines: 3,
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
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: UiText.eyebrow(color: ui.inkMuted),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
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
          Text(
            label,
            maxLines: 1,
            softWrap: false,
            style: UiText.eyebrow(color: ui.ink),
          ),
        ],
      ),
    );
  }
}
