import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../ui/ui.dart';
import '../../l10n/generated/journeys_localizations.dart';

/// One card of the type deck.
@immutable
class CreateDeckItem {
  const CreateDeckItem({
    required this.keyName,
    required this.title,
    required this.tagline,
    required this.meta,
    required this.badge,
  });

  final String keyName;
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
    final ui = context.ui;
    return UiPressable(
      key: ValueKey('template-${item.keyName}'),
      onPressed: onTap,
      selected: focused,
      semanticLabel: '$semantic, ${item.tagline}',
      excludeChildSemantics: true,
      borderRadius: BorderRadius.circular(UiRadius.card),
      shadowColor: ui.outline,
      shadowOffset: focused ? 4 : 0,
      child: Container(
        padding: const EdgeInsets.all(UiSpace.lg),
        decoration: BoxDecoration(
          color: ui.surface,
          borderRadius: BorderRadius.circular(UiRadius.card),
          border: Border.all(color: ui.outline, width: focused ? 3 : 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                UiTypeBadge(type: item.badge, size: 56),
                const Spacer(),
                if (focused)
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const OurneyIcon(name: 'check', size: 15, flat: true),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            chosenLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: UiText.eyebrow(color: ui.ink),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: UiSpace.md),
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: UiText.h2(color: ui.ink, size: 22).copyWith(height: 1.3),
            ),
            const SizedBox(height: 4),
            Text(
              item.tagline,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: UiText.body(size: 15, height: 1.45, color: ui.inkMuted),
            ),
            const SizedBox(height: UiSpace.sm),
            Text(
              item.meta,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: UiText.eyebrow(color: ui.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}
