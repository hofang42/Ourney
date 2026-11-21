import 'package:flutter/material.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../../ui/ui.dart';
import '../../l10n/generated/journeys_localizations.dart';

/// `LayoutPreview` of the edit screen: a miniature of a skin's journey home
/// (top strip, three timeline bars, HUD row) painted with that skin's own
/// palette, so the owner sees the layout before switching.
class LayoutPreview extends StatelessWidget {
  const LayoutPreview({
    required this.skinId,
    this.journey,
    this.large = false,
    super.key,
  });

  final String skinId;
  final Journey? journey;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final l10n = JourneysL10n.of(context);
    final skin = uiSkinById(skinId);
    final dark = context.ui.isDark;
    final p = skin.palette(dark ? Brightness.dark : Brightness.light);
    final accent = skin.variant(0).accent;
    final j = journey;
    final total = j?.durationDays;
    final tag = j == null
        ? l10n.journeys_edit_previewTag
        : total == null
        ? l10n.journeys_edit_dayOpen(1)
        : l10n.journeys_edit_dayOf(1, total);
    final pad = large ? 20.0 : 10.0;
    final bar = large ? 14.0 : 8.0;
    return Container(
      key: ValueKey('layout-preview-$skinId'),
      constraints: BoxConstraints(minHeight: large ? 260 : 118),
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: BorderRadius.circular(large ? UiRadius.card : 14),
        border: Border.all(
          color: p.outlineIn(dark ? Brightness.dark : Brightness.light),
          width: skin.borderWidth,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _Dot(color: p.ink, size: large ? 10 : 6),
              Expanded(
                child: Text(
                  tag,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: p.ink,
                    fontSize: large ? 13 : 9,
                    fontWeight: FontWeight.w800,
                    height: 1.4,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              _Dot(color: p.ink, size: large ? 10 : 6),
            ],
          ),
          SizedBox(height: large ? 18 : 8),
          for (var i = 0; i < 3; i++)
            Padding(
              padding: EdgeInsets.only(bottom: large ? 10 : 5),
              child: Align(
                alignment: i.isEven
                    ? AlignmentDirectional.centerStart
                    : AlignmentDirectional.centerEnd,
                child: FractionallySizedBox(
                  widthFactor: i == 1 ? 0.55 : 0.75,
                  child: Container(
                    height: bar,
                    decoration: BoxDecoration(
                      color: i == 0 ? accent : p.surface,
                      borderRadius: BorderRadius.circular(bar),
                      border: Border.all(color: p.ink.withValues(alpha: 0.35)),
                    ),
                  ),
                ),
              ),
            ),
          SizedBox(height: large ? 8 : 2),
          Row(
            children: [
              OurneyIcon(
                name: 'camera',
                size: large ? 22 : 14,
                flat: true,
                color: p.ink,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  j == null
                      ? l10n.journeys_edit_hudPreview
                      : (j.metricName ?? j.title),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: p.muted,
                    fontSize: large ? 14 : 10,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
