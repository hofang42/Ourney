import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ourney_core/ourney_core.dart'
    show dnaPlaceMax, durationMax, durationMin;

import '../../../../shared/places/place_picker.dart';
import '../../../../ui/ui.dart';
import '../../l10n/generated/journeys_localizations.dart';
import 'create_widgets.dart';
import 'dna_questions.dart';
import 'dna_text.dart';

/// Choice cards (`step-two-card`): sticker initial, label + hint, check.
class DnaChoiceList extends StatelessWidget {
  const DnaChoiceList({
    required this.question,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final DnaQuestion question;
  final String? value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final l10n = JourneysL10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final id in question.choiceIds)
          Padding(
            padding: const EdgeInsets.only(bottom: UiSpace.md),
            child: _card(
              context,
              ui,
              id,
              dnaText(l10n, question.labelId(id)),
              question.hints ? dnaText(l10n, question.hintId(id)) : null,
            ),
          ),
      ],
    );
  }

  Widget _card(
    BuildContext context,
    OurneyUi ui,
    String id,
    String label,
    String? hint,
  ) {
    final selected = value == id;
    return UiPressable(
      key: ValueKey('dna-choice-${question.key}-$id'),
      onPressed: () {
        unawaited(UiHaptics.selection());
        onChanged(id);
      },
      selected: selected,
      pressOffset: UiShadow.tiny,
      semanticLabel: hint == null ? label : '$label, $hint',
      excludeChildSemantics: true,
      borderRadius: BorderRadius.circular(UiRadius.card),
      child: Container(
        constraints: BoxConstraints(minHeight: question.compact ? 56 : 72),
        padding: const EdgeInsets.symmetric(
          horizontal: UiSpace.lg,
          vertical: UiSpace.md,
        ),
        decoration: BoxDecoration(
          color: selected ? createSelectedFill(ui) : ui.surface,
          borderRadius: BorderRadius.circular(UiRadius.card),
          border: Border.all(
            color: selected ? ui.outline : ui.border,
            width: selected ? 3 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: ui.fill, shape: BoxShape.circle),
              child: Text(
                label.characters.first,
                style: UiText.h2(color: ui.ink, size: 17),
              ),
            ),
            const SizedBox(width: UiSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: UiText.h2(
                      color: ui.ink,
                      size: 17,
                    ).copyWith(height: 1.3),
                  ),
                  if (hint != null)
                    Text(
                      hint,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: UiText.muted(color: ui.inkMuted)
                          .copyWith(height: 1.4),
                    ),
                ],
              ),
            ),
            if (selected) OurneyIcon(name: 'check', size: 20),
          ],
        ),
      ),
    );
  }
}

/// Weight question: 40-120 kg slider, private chip, hide-on-share switch,
/// skip link. Emits [UiHaptics.selection] on each integer-kg detent crossing.
class DnaWeightPicker extends StatefulWidget {
  const DnaWeightPicker({
    required this.weight,
    required this.hide,
    required this.onWeight,
    required this.onHide,
    required this.onSkip,
    super.key,
  });

  final num weight;
  final bool hide;
  final ValueChanged<double> onWeight;
  final ValueChanged<bool> onHide;
  final VoidCallback onSkip;

  @override
  State<DnaWeightPicker> createState() => _DnaWeightPickerState();
}

class _DnaWeightPickerState extends State<DnaWeightPicker> {
  late int _lastDetentWeight = widget.weight.round();

  @override
  void didUpdateWidget(covariant DnaWeightPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.weight.round() != oldWidget.weight.round()) {
      _lastDetentWeight = widget.weight.round();
    }
  }

  static String _formatWeight(num value, {bool vi = false}) {
    final tenths = (value * 10).round();
    if (tenths % 10 == 0) return '${tenths ~/ 10}';
    final s = (tenths / 10).toStringAsFixed(1);
    return vi ? s.replaceAll('.', ',') : s;
  }

  void _stepTenths(int deltaTenths) {
    final currentTenths = (widget.weight * 10).round();
    final nextTenths = (currentTenths + deltaTenths).clamp(
      dnaWeightMin * 10,
      dnaWeightMax * 10,
    );
    if (nextTenths == currentTenths) return;
    unawaited(UiHaptics.selection());
    widget.onWeight(nextTenths / 10.0);
  }

  void _handleSliderChanged(double v) {
    final next = v.round().clamp(dnaWeightMin, dnaWeightMax);
    if (next != _lastDetentWeight) {
      _lastDetentWeight = next;
      unawaited(UiHaptics.selection());
    }
    widget.onWeight(next.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final l10n = JourneysL10n.of(context);
    final vi = Localizations.localeOf(context).languageCode == 'vi';
    final decLabel = vi ? '-0,1' : '-0.1';
    final incLabel = vi ? '+0,1' : '+0.1';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            UiPressable(
              key: const ValueKey('dna-weight-dec'),
              onPressed: widget.weight > dnaWeightMin
                  ? () => _stepTenths(-1)
                  : null,
              semanticLabel: '$decLabel ${l10n.journeys_dna_weight_unit}',
              excludeChildSemantics: true,
              borderRadius: BorderRadius.circular(UiRadius.capsule),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: UiSpace.sm,
                  vertical: UiSpace.xs,
                ),
                child: Text(
                  decLabel,
                  style: UiText.muted(color: ui.inkMuted),
                ),
              ),
            ),
            const SizedBox(width: UiSpace.sm),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _formatWeight(widget.weight, vi: vi),
                  key: const ValueKey('dna-weight-value'),
                  style: UiText.h1(
                    color: ui.ink,
                    size: 64,
                  ).copyWith(height: 1.2),
                ),
              ),
            ),
            const SizedBox(width: UiSpace.xs),
            Text(
              l10n.journeys_dna_weight_unit,
              style: UiText.h2(color: ui.inkMuted, size: 20),
            ),
            const SizedBox(width: UiSpace.sm),
            UiPressable(
              key: const ValueKey('dna-weight-inc'),
              onPressed: widget.weight < dnaWeightMax
                  ? () => _stepTenths(1)
                  : null,
              semanticLabel: '$incLabel ${l10n.journeys_dna_weight_unit}',
              excludeChildSemantics: true,
              borderRadius: BorderRadius.circular(UiRadius.capsule),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: UiSpace.sm,
                  vertical: UiSpace.xs,
                ),
                child: Text(
                  incLabel,
                  style: UiText.muted(color: ui.inkMuted),
                ),
              ),
            ),
          ],
        ),
        Semantics(
          label: l10n.journeys_dna_weight_a11y,
          child: Slider(
            key: const ValueKey('dna-weight-slider'),
            value: widget.weight
                .toDouble()
                .clamp(dnaWeightMin.toDouble(), dnaWeightMax.toDouble()),
            min: dnaWeightMin.toDouble(),
            max: dnaWeightMax.toDouble(),
            divisions: dnaWeightMax - dnaWeightMin,
            activeColor: ui.accent,
            onChanged: _handleSliderChanged,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$dnaWeightMin', style: UiText.muted(color: ui.inkMuted)),
            Text(
              '$dnaWeightMax ${l10n.journeys_dna_weight_unit}',
              style: UiText.muted(color: ui.inkMuted),
            ),
          ],
        ),
        const SizedBox(height: UiSpace.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OurneyIcon(name: 'lock', size: 17),
            const SizedBox(width: UiSpace.sm),
            Flexible(
              child: Text(
                l10n.journeys_dna_weight_private,
                style: UiText.muted(color: ui.inkMuted).copyWith(height: 1.4),
              ),
            ),
          ],
        ),
        UiSwitchRow(
          key: const ValueKey('dna-hide-weight'),
          label: l10n.journeys_dna_weight_hide,
          value: widget.hide,
          onChanged: widget.onHide,
        ),
        UiButton.ghost(
          key: const ValueKey('dna-weight-skip'),
          label: l10n.journeys_dna_weight_skip,
          onPressed: widget.onSkip,
        ),
      ],
    );
  }
}

/// Weight-loss page 3: the day-1 ghost silhouette used as an alignment
/// frame. The shutter itself lives in the camera; here it is a request.
class DnaGhostPage extends StatelessWidget {
  const DnaGhostPage({required this.onLater, super.key});

  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final l10n = JourneysL10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: ExcludeSemantics(
            child: Container(
              width: 180,
              height: 240,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: ui.fill,
                borderRadius: BorderRadius.circular(UiRadius.card),
                border: Border.all(color: ui.border),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Opacity(
                    opacity: ui.isDark ? 0.72 : 0.85,
                    child: Image.asset(
                      'assets/samples/weight_loss/03.webp',
                      key: const ValueKey('dna-ghost-photo'),
                      fit: BoxFit.cover,
                      cacheWidth: 540,
                      excludeFromSemantics: true,
                      errorBuilder: (context, error, stackTrace) =>
                          ColoredBox(color: ui.fill),
                    ),
                  ),
                  if (ui.isDark)
                    const IgnorePointer(
                      child: ColoredBox(color: Color(0x24000000)),
                    ),
                  const CustomPaint(
                    key: ValueKey('dna-ghost-silhouette'),
                    painter: _SilhouettePainter(),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: UiSpace.lg),
        Text(
          l10n.journeys_dna_ghost_body,
          textAlign: TextAlign.center,
          style: UiText.muted(color: ui.inkMuted).copyWith(height: 1.45),
        ),
        UiButton.ghost(
          key: const ValueKey('dna-ghost-later'),
          label: l10n.journeys_dna_ghost_later,
          onPressed: onLater,
        ),
      ],
    );
  }
}

class _SilhouettePainter extends CustomPainter {
  const _SilhouettePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final haloPaint = Paint()
      ..color = const Color(0x8C0F172A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.2
      ..strokeCap = StrokeCap.round;
    final linePaint = Paint()
      ..color = const Color(0xF0FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    final w = size.width;
    final h = size.height;
    // Standing body silhouette aligned to the full-body reference photo:
    // head oval at top, shoulder-and-torso guide down to the legs.
    final path = Path()
      ..addOval(
        Rect.fromCenter(
          center: Offset(w * 0.50, h * 0.085),
          width: w * 0.17,
          height: h * 0.125,
        ),
      )
      ..moveTo(w * 0.37, h * 0.94)
      ..quadraticBezierTo(w * 0.34, h * 0.56, w * 0.34, h * 0.24)
      ..quadraticBezierTo(w * 0.34, h * 0.17, w * 0.50, h * 0.17)
      ..quadraticBezierTo(w * 0.66, h * 0.17, w * 0.66, h * 0.24)
      ..quadraticBezierTo(w * 0.66, h * 0.56, w * 0.63, h * 0.94);
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        final next = math.min(d + 6, metric.length);
        final seg = metric.extractPath(d, next);
        canvas.drawPath(seg, haloPaint);
        canvas.drawPath(seg, linePaint);
        d += 11;
      }
    }
  }

  @override
  bool shouldRepaint(_SilhouettePainter old) => false;
}

/// Trip destination field in the create flow.
class DnaPlacePicker extends StatelessWidget {
  const DnaPlacePicker({
    required this.controller,
    required this.onChanged,
    this.recent = const [],
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final List<String> recent;

  @override
  Widget build(BuildContext context) {
    final l10n = JourneysL10n.of(context);
    final label = l10n.journeys_dna_place_search;
    return PlacePicker(
      controller: controller,
      onChanged: onChanged,
      fieldKey: const ValueKey('dna-place-field'),
      label: label,
      hint: label,
      recent: recent,
      browseWhenEmpty: true,
      maxRunes: dnaPlaceMax,
      limitMessage: l10n.journeys_dna_place_limit(dnaPlaceMax),
    );
  }
}

/// Month grid to pick a departure and a return day (`InlineDateRange`),
/// with a "return date not set" shortcut.
class DnaDateRange extends StatefulWidget {
  const DnaDateRange({
    required this.today,
    required this.value,
    required this.onChanged,
    required this.locale,
    super.key,
  });

  final DateTime today;
  final DnaDates? value;
  final ValueChanged<DnaDates> onChanged;
  final String locale;

  @override
  State<DnaDateRange> createState() => _DnaDateRangeState();
}

class _DnaDateRangeState extends State<DnaDateRange> {
  late DateTime _month = DateTime(
    (widget.value?.start ?? widget.today).year,
    (widget.value?.start ?? widget.today).month,
  );

  DateTime get _today =>
      DateTime(widget.today.year, widget.today.month, widget.today.day);

  /// The last range was lengthened to the shortest journey, or cut to the
  /// longest one: say so.
  bool _lengthened = false;
  bool _shortened = false;

  void _tap(DateTime day) {
    final v = widget.value;
    // First tap, or a tap after a finished range, starts a new range.
    if (v == null || v.end != null || day.isBefore(v.start)) {
      setState(() {
        _lengthened = false;
        _shortened = false;
      });
      widget.onChanged(DnaDates(day));
    } else {
      // A journey lasts durationMin..durationMax days (bug B-B11): the
      // calendar shows the range that will really be saved.
      final end = dnaClampTripEnd(v.start, day);
      final n = dnaTripDays(v.start, day);
      setState(() {
        _lengthened = n < durationMin;
        _shortened = n > durationMax;
      });
      widget.onChanged(DnaDates(v.start, end));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final l10n = JourneysL10n.of(context);
    final fmt = DateFormat.MMMd(widget.locale);
    final first = _month;
    final days = DateUtils.getDaysInMonth(first.year, first.month);
    final offset = (first.weekday - 1) % 7; // Monday first
    final v = widget.value;
    final canPrev = first.isAfter(DateTime(_today.year, _today.month));
    final summary = v == null
        ? l10n.journeys_dna_dates_prompt
        : v.end == null
        ? l10n.journeys_dna_dates_open_summary(fmt.format(v.start))
        : l10n.journeys_dna_dates_range_summary(
            fmt.format(v.start),
            fmt.format(v.end!),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _arrow(
              ui,
              'back',
              l10n.journeys_dna_prev_month,
              canPrev
                  ? () => setState(
                      () => _month = DateTime(first.year, first.month - 1),
                    )
                  : null,
            ),
            Expanded(
              child: Center(
                child: Text(
                  DateFormat.yMMMM(widget.locale).format(first),
                  style: UiText.h2(color: ui.ink, size: 17),
                ),
              ),
            ),
            _arrow(
              ui,
              'caret-right',
              l10n.journeys_dna_next_month,
              () => setState(
                () => _month = DateTime(first.year, first.month + 1),
              ),
            ),
          ],
        ),
        const SizedBox(height: UiSpace.sm),
        LayoutBuilder(
          builder: (context, c) {
            final cell = c.maxWidth / 7;
            return Wrap(
              children: [
                for (var i = 0; i < offset; i++) SizedBox(width: cell),
                for (var d = 1; d <= days; d++)
                  _cell(ui, DateTime(first.year, first.month, d), cell, v),
              ],
            );
          },
        ),
        UiButton.ghost(
          key: const ValueKey('dna-dates-open'),
          label: l10n.journeys_dna_dates_open,
          onPressed: v == null
              ? null
              : () {
                  setState(() {
                    _lengthened = false;
                    _shortened = false;
                  });
                  widget.onChanged(DnaDates(v.start));
                },
        ),
        if (_lengthened || _shortened)
          Padding(
            padding: const EdgeInsets.only(bottom: UiSpace.xs),
            child: Text(
              _lengthened
                  ? l10n.journeys_dna_dates_min_note(durationMin)
                  : l10n.journeys_dna_dates_max_note(durationMax),
              key: ValueKey(
                _lengthened ? 'dna-dates-min-note' : 'dna-dates-max-note',
              ),
              textAlign: TextAlign.center,
              style: UiText.muted(
                color: ui.inkMuted,
                size: 13,
              ).copyWith(height: 1.4),
            ),
          ),
        Center(
          child: Text(
            summary,
            key: const ValueKey('dna-dates-summary'),
            textAlign: TextAlign.center,
            style: UiText.muted(color: ui.inkMuted).copyWith(height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _arrow(OurneyUi ui, String icon, String label, VoidCallback? onTap) =>
      Semantics(
        button: true,
        enabled: onTap != null,
        label: label,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: UiSize.tap,
            height: UiSize.tap,
            child: Center(
              child: OurneyIcon(
                name: icon,
                size: 20,
                flat: onTap == null,
                color: onTap == null ? ui.divider : null,
              ),
            ),
          ),
        ),
      );

  Widget _cell(OurneyUi ui, DateTime day, double cell, DnaDates? v) {
    final past = day.isBefore(_today);
    final isStart = v != null && day == v.start;
    final isEnd = v?.end != null && day == v!.end;
    final between =
        v?.end != null && day.isAfter(v!.start) && day.isBefore(v.end!);
    final on = isStart || isEnd;
    return SizedBox(
      width: cell,
      height: cell < UiSize.tap ? UiSize.tap : cell,
      child: Semantics(
        button: true,
        selected: on,
        enabled: !past,
        label: DateFormat.MMMMd(widget.locale).format(day),
        excludeSemantics: true,
        child: GestureDetector(
          key: ValueKey('dna-day-${day.day}'),
          behavior: HitTestBehavior.opaque,
          onTap: past ? null : () => _tap(day),
          child: Container(
            margin: const EdgeInsets.all(2),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on
                  ? ui.accent
                  : between
                  ? createSelectedFill(ui)
                  : null,
              borderRadius: BorderRadius.circular(UiRadius.thumb),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  '${day.day}',
                  maxLines: 1,
                  style: UiText.body(
                    size: 14,
                    color: past ? ui.divider : ui.ink,
                  ).copyWith(fontWeight: on ? FontWeight.w700 : null),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Step-5 "đang đúc DNA…" overlay while the journey is created: a pulsing
/// seal. Static when the OS asks for reduced motion.
class DnaForge extends StatefulWidget {
  const DnaForge({super.key});

  @override
  State<DnaForge> createState() => _DnaForgeState();
}

class _DnaForgeState extends State<DnaForge>
    with SingleTickerProviderStateMixin {
  AnimationController? _c;
  CurvedAnimation? _curved;
  Animation<double>? _scale;

  Animation<double> _ensureScale() {
    var scale = _scale;
    if (scale != null) return scale;
    final ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    final curved = CurvedAnimation(
      parent: ctrl,
      curve: UiCurves.easeInOutStrong,
    );
    scale = Tween<double>(begin: 0.9, end: 1.1).animate(curved);
    _c = ctrl;
    _curved = curved;
    _scale = scale;
    return scale;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shouldAnimate =
        !UiMotion.reduced(context) && TickerMode.valuesOf(context).enabled;
    if (!shouldAnimate) {
      _c?.stop();
    } else {
      _ensureScale();
      if (!_c!.isAnimating) {
        _c!.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _curved?.dispose();
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final l10n = JourneysL10n.of(context);
    final reduced = UiMotion.reduced(context);
    final seal = Container(
      key: const ValueKey('dna-forge-seal'),
      width: 96,
      height: 96,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ui.accent,
        shape: BoxShape.circle,
        border: Border.all(color: ui.outline, width: 3),
      ),
      child: OurneyIcon(name: 'trophy', size: 44),
    );
    return Semantics(
      liveRegion: true,
      label: l10n.journeys_dna_forge_a11y,
      child: ColoredBox(
        key: const ValueKey('dna-forge'),
        color: ui.bg.withValues(alpha: 0.94),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RepaintBoundary(
                child: reduced
                    ? seal
                    : ScaleTransition(
                        scale: _ensureScale(),
                        child: seal,
                      ),
              ),
              const SizedBox(height: UiSpace.lg),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: UiSpace.xl),
                child: Text(
                  l10n.journeys_dna_forge_title,
                  textAlign: TextAlign.center,
                  style: UiText.h2(color: ui.ink).copyWith(height: 1.3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
