import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens.dart';
import '../typography.dart';
import 'chips.dart';
import 'pressable.dart';

class UiSegment<T> {
  const UiSegment({
    required this.value,
    required this.label,
    this.showDot = false,
    this.key,
  });

  /// Key of the tappable segment (tests, other features).
  final Key? key;

  final T value;
  final String label;

  /// `.segment-new-dot`.
  final bool showDot;
}

/// `.segments`: 48dp minimum capsule track, 4dp inset, selected tab raised on
/// [OurneyUi.fillSelected] with a >= 3:1 outline and bolder ink weight. With
/// [scrollable] (`.hub-segments`) segments take their natural width (min 92)
/// and the track scrolls horizontally; otherwise segments share the width and
/// reflow vertically when scaled labels cannot fit in narrow columns.
class UiSegmented<T> extends StatelessWidget {
  const UiSegmented({
    required this.segments,
    required this.value,
    required this.onChanged,
    this.scrollable = false,
    super.key,
  });

  final List<UiSegment<T>> segments;
  final T value;
  final ValueChanged<T> onChanged;
  final bool scrollable;

  /// Visual inset of the selected pill inside the track.
  static const double _inset = 4;

  /// Height this control takes at [maxWidth] (48dp for a single-line row;
  /// grows when scaled labels wrap to two lines or stack vertically).
  double preferredHeight(BuildContext context, double maxWidth) {
    if (scrollable || segments.isEmpty || !maxWidth.isFinite) {
      return UiSize.tap;
    }
    final ui = context.ui;
    final stacked = _needsVerticalStack(context, ui, maxWidth);
    final trackWidth = maxWidth - _inset * 2;
    final segWidth = trackWidth / segments.length;
    final hPad = stacked ? 12.0 : (segWidth < 110 ? 6.0 : 12.0);
    final scaler = MediaQuery.textScalerOf(context);
    final dir = Directionality.of(context);
    final defaultStyle = DefaultTextStyle.of(context);
    final locale = Localizations.maybeLocaleOf(context);

    double tabHeight(UiSegment<T> s) {
      final selected = s.value == value;
      final border = selected ? UiBorder.standard * 2 : 0.0;
      final dot = s.showDot ? 14.0 : 0.0;
      final avail =
          (stacked ? trackWidth : segWidth) - hPad * 2 - border - dot;
      if (avail <= 0) return UiSize.tap;
      final tp = TextPainter(
        text: TextSpan(
          text: s.label,
          style: _effectiveLabelStyle(context, ui, selected: selected),
        ),
        textScaler: scaler,
        textDirection: dir,
        textAlign: TextAlign.center,
        maxLines: stacked ? null : 2,
        ellipsis: stacked ? null : '\u2026',
        locale: locale,
        textHeightBehavior: defaultStyle.textHeightBehavior,
        textWidthBasis: defaultStyle.textWidthBasis,
      )..layout(maxWidth: avail);
      final tpHeight = tp.height;
      tp.dispose();
      final pill = (tpHeight + 12 + border).clamp(
        UiSize.tap - _inset * 2,
        double.infinity,
      );
      return (pill + _inset * 2).clamp(UiSize.tap, double.infinity);
    }

    if (stacked) {
      var total = 4.0;
      for (final s in segments) {
        total += tabHeight(s);
      }
      return total.clamp(UiSize.tap, double.infinity);
    }
    var maxH = UiSize.tap;
    for (final s in segments) {
      final h = tabHeight(s);
      if (h > maxH) maxH = h;
    }
    return maxH;
  }

  static TextStyle _labelStyle(OurneyUi ui, {required bool selected}) =>
      UiText.body(
        size: 15,
        weight: selected ? FontWeight.w700 : FontWeight.w500,
        height: 1.3,
        color: selected ? ui.ink : ui.inkMuted,
      );

  static TextStyle _effectiveLabelStyle(
    BuildContext context,
    OurneyUi ui, {
    required bool selected,
  }) {
    var style = DefaultTextStyle.of(
      context,
    ).style.merge(_labelStyle(ui, selected: selected));
    if (MediaQuery.boldTextOf(context)) {
      style = style.merge(const TextStyle(fontWeight: FontWeight.bold));
    }
    return style;
  }

  bool _needsVerticalStack(
    BuildContext context,
    OurneyUi ui,
    double maxWidth,
  ) {
    if (scrollable || segments.length <= 1 || !maxWidth.isFinite) return false;
    final trackWidth = maxWidth - _inset * 2;
    final segWidth = trackWidth / segments.length;
    final hPad = segWidth < 110 ? 6.0 : 12.0;
    final boldStyle = _effectiveLabelStyle(context, ui, selected: true);
    final scaler = MediaQuery.textScalerOf(context);
    final dir = Directionality.of(context);
    final defaultStyle = DefaultTextStyle.of(context);
    final locale = Localizations.maybeLocaleOf(context);
    for (final s in segments) {
      final avail =
          segWidth - hPad * 2 - UiBorder.standard * 2 - (s.showDot ? 14 : 0);
      if (avail <= 0) return true;
      final tp = TextPainter(
        text: TextSpan(text: s.label, style: boldStyle),
        textScaler: scaler,
        textDirection: dir,
        maxLines: 2,
        locale: locale,
        textHeightBehavior: defaultStyle.textHeightBehavior,
        textWidthBasis: defaultStyle.textWidthBasis,
      )..layout(maxWidth: avail);
      final exceeded = tp.didExceedMaxLines;
      tp.dispose();
      if (exceeded) return true;
      for (final word in s.label.trim().split(RegExp(r'\s+'))) {
        if (word.isEmpty) continue;
        final wp = TextPainter(
          text: TextSpan(text: word, style: boldStyle),
          textScaler: scaler,
          textDirection: dir,
          maxLines: 1,
          locale: locale,
          textHeightBehavior: defaultStyle.textHeightBehavior,
          textWidthBasis: defaultStyle.textWidthBasis,
        )..layout();
        final wordW = wp.width;
        wp.dispose();
        if (wordW > avail) return true;
      }
    }
    return false;
  }

  List<double> _measureScrollableWidths(
    BuildContext context,
    OurneyUi ui, {
    required double hPad,
  }) {
    final boldStyle = _effectiveLabelStyle(context, ui, selected: true);
    final scaler = MediaQuery.textScalerOf(context);
    final dir = Directionality.of(context);
    final defaultStyle = DefaultTextStyle.of(context);
    final locale = Localizations.maybeLocaleOf(context);
    return <double>[
      for (final s in segments)
        () {
          final tp = TextPainter(
            text: TextSpan(text: s.label, style: boldStyle),
            textScaler: scaler,
            textDirection: dir,
            maxLines: 1,
            locale: locale,
            textHeightBehavior: defaultStyle.textHeightBehavior,
            textWidthBasis: defaultStyle.textWidthBasis,
          )..layout();
          final textW = tp.width.ceilToDouble();
          tp.dispose();
          final dotW = s.showDot ? 14.0 : 0.0;
          return math.max(92.0, textW + hPad * 2 + dotW);
        }(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final borderColor = ui.isDark ? ui.fieldBorder : ui.outline;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final selectedIndex = segments.indexWhere((s) => s.value == value);

    Widget slidingPill({required double left, required double width}) {
      return AnimatedPositioned(
        key: const ValueKey('ui-segmented-pill'),
        duration: UiMotion.of(context, UiMotion.medium),
        curve: UiCurves.easeInOutStrong,
        left: left,
        top: _inset,
        bottom: _inset,
        width: width,
        child: IgnorePointer(
          child: DecoratedBox(
            key: const ValueKey('ui-segmented-pill-box'),
            decoration: BoxDecoration(
              color: ui.fillSelected,
              borderRadius: BorderRadius.circular(UiRadius.capsule),
              border: Border.all(
                color: borderColor,
                width: UiBorder.standard,
              ),
              boxShadow: UiShadow.hard(
                ui.hardShadowColor,
                UiShadow.tiny,
              ),
            ),
          ),
        ),
      );
    }

    Widget tab(
      UiSegment<T> s, {
      required bool stacked,
      required double hPad,
      bool hasSlidingPill = false,
    }) {
      final selected = s.value == value;
      final label = Flexible(
        child: Text(
          s.label,
          maxLines: stacked ? null : 2,
          overflow: stacked ? null : TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: _labelStyle(ui, selected: selected),
        ),
      );
      final child = Container(
        alignment: Alignment.center,
        constraints: BoxConstraints(
          minWidth: scrollable ? 92 : 0,
          minHeight: UiSize.tap - _inset * 2,
        ),
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 6),
        decoration: BoxDecoration(
          color: (!hasSlidingPill && selected)
              ? ui.fillSelected
              : Colors.transparent,
          borderRadius: BorderRadius.circular(UiRadius.capsule),
          border: selected
              ? Border.all(
                  color: borderColor,
                  width: hasSlidingPill ? 0 : UiBorder.standard,
                  style: hasSlidingPill ? BorderStyle.none : BorderStyle.solid,
                )
              : null,
          boxShadow: (!hasSlidingPill && selected)
              ? UiShadow.hard(ui.hardShadowColor, UiShadow.tiny)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            label,
            if (s.showDot) ...[const SizedBox(width: 6), const UiNewDot()],
          ],
        ),
      );
      final pressable = UiPressable(
        key: s.key,
        onPressed: () {
          if (!selected) {
            unawaited(UiHaptics.selection());
          }
          onChanged(s.value);
        },
        selected: selected,
        semanticLabel: s.label,
        excludeChildSemantics: true,
        pressOffset: (!hasSlidingPill && selected) ? UiShadow.tiny : 0,
        pressScale: selected ? 1.0 : UiMotion.pressScale,
        // The 40dp pill sits inside a full 48dp-tall hit area (U5): the
        // track's vertical inset belongs to the tap target.
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: _inset),
          child: child,
        ),
      );
      if (scrollable || stacked) return pressable;
      return Expanded(child: pressable);
    }

    if (scrollable) {
      const hPad = 12.0;
      final segWidths = _measureScrollableWidths(context, ui, hPad: hPad);
      var pillLeft = 0.0;
      final pillWidth =
          (selectedIndex >= 0 && selectedIndex < segWidths.length)
          ? segWidths[selectedIndex]
          : 0.0;
      if (selectedIndex >= 0 && selectedIndex < segWidths.length) {
        if (isRtl) {
          for (var i = selectedIndex + 1; i < segWidths.length; i++) {
            pillLeft += segWidths[i];
          }
        } else {
          for (var i = 0; i < selectedIndex; i++) {
            pillLeft += segWidths[i];
          }
        }
      }
      final trackStack = Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.centerLeft,
        children: [
          if (selectedIndex >= 0 && segments.isNotEmpty)
            slidingPill(left: pillLeft, width: pillWidth),
          IntrinsicHeight(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < segments.length; i++)
                  SizedBox(
                    width: segWidths[i],
                    child: tab(
                      segments[i],
                      stacked: false,
                      hPad: hPad,
                      hasSlidingPill: true,
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
      return Container(
        constraints: const BoxConstraints(minHeight: UiSize.tap),
        padding: const EdgeInsets.symmetric(horizontal: _inset),
        decoration: BoxDecoration(
          color: ui.fill,
          borderRadius: BorderRadius.circular(UiRadius.capsule),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(right: UiShadow.tiny),
          child: trackStack,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = _needsVerticalStack(
          context,
          ui,
          constraints.maxWidth,
        );
        final segWidth =
            constraints.maxWidth.isFinite && segments.isNotEmpty
            ? (constraints.maxWidth - _inset * 2) / segments.length
            : 120.0;
        final hPad = stacked ? 12.0 : (segWidth < 110 ? 6.0 : 12.0);
        return Container(
          constraints: const BoxConstraints(minHeight: UiSize.tap),
          padding: EdgeInsets.symmetric(
            horizontal: _inset,
            vertical: stacked ? 2 : 0,
          ),
          decoration: BoxDecoration(
            color: ui.fill,
            borderRadius: BorderRadius.circular(
              stacked ? UiRadius.card : UiRadius.capsule,
            ),
          ),
          child: stacked
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final s in segments) tab(s, stacked: true, hPad: hPad),
                  ],
                )
              : Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.centerLeft,
                  children: [
                    if (selectedIndex >= 0 && segments.isNotEmpty)
                      slidingPill(
                        left: isRtl
                            ? (segments.length - 1 - selectedIndex) * segWidth
                            : selectedIndex * segWidth,
                        width: segWidth,
                      ),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final s in segments)
                            tab(
                              s,
                              stacked: false,
                              hPad: hPad,
                              hasSlidingPill: true,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
