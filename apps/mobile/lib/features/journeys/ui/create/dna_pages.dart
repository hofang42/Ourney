import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ourney_core/ourney_core.dart' show durationMax, durationMin;

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
      onPressed: () => onChanged(id),
      selected: selected,
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
/// skip link.
class DnaWeightPicker extends StatelessWidget {
  const DnaWeightPicker({
    required this.weight,
    required this.hide,
    required this.onWeight,
    required this.onHide,
    required this.onSkip,
    super.key,
  });

  final int weight;
  final bool hide;
  final ValueChanged<int> onWeight;
  final ValueChanged<bool> onHide;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final l10n = JourneysL10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '$weight',
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
          ],
        ),
        Semantics(
          label: l10n.journeys_dna_weight_a11y,
          child: Slider(
            key: const ValueKey('dna-weight-slider'),
            value: weight.toDouble(),
            min: dnaWeightMin.toDouble(),
            max: dnaWeightMax.toDouble(),
            divisions: dnaWeightMax - dnaWeightMin,
            activeColor: ui.accent,
            onChanged: (v) => onWeight(v.round()),
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
          value: hide,
          onChanged: onHide,
        ),
        UiButton.ghost(
          key: const ValueKey('dna-weight-skip'),
          label: l10n.journeys_dna_weight_skip,
          onPressed: onSkip,
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
              decoration: BoxDecoration(
                color: ui.fill,
                borderRadius: BorderRadius.circular(UiRadius.card),
                border: Border.all(color: ui.border),
              ),
              child: CustomPaint(
                key: const ValueKey('dna-ghost-silhouette'),
                painter: _SilhouettePainter(ui.inkMuted),
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
  const _SilhouettePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final w = size.width;
    final h = size.height;
    canvas.drawCircle(Offset(w / 2, h * 0.28), w * 0.16, p);
    final body = Path()
      ..moveTo(w * 0.18, h * 0.92)
      ..quadraticBezierTo(w * 0.18, h * 0.55, w * 0.5, h * 0.52)
      ..quadraticBezierTo(w * 0.82, h * 0.55, w * 0.82, h * 0.92);
    canvas.drawPath(body, p);
  }

  @override
  bool shouldRepaint(_SilhouettePainter old) => old.color != color;
}

/// Place search with suggestion rows (`place-question`).
class DnaPlacePicker extends StatelessWidget {
  const DnaPlacePicker({
    required this.controller,
    required this.place,
    required this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final String place;
  final ValueChanged<String> onChanged;

  static const _cities = ['place_dalat', 'place_hoian', 'place_phuquoc'];

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final l10n = JourneysL10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UiTextField(
          fieldKey: const ValueKey('dna-place-field'),
          pill: true,
          label: l10n.journeys_dna_place_search,
          hint: l10n.journeys_dna_place_search,
          controller: controller,
          leading: OurneyIcon(name: 'search', size: 20),
          onChanged: onChanged,
        ),
        const SizedBox(height: UiSpace.md),
        for (final id in _cities)
          Builder(
            builder: (context) {
              final name = dnaText(l10n, id);
              final selected = place == name;
              return Padding(
                padding: const EdgeInsets.only(bottom: UiSpace.sm),
                child: UiPressable(
                  key: ValueKey('dna-$id'),
                  onPressed: () {
                    controller.text = name;
                    onChanged(name);
                  },
                  selected: selected,
                  semanticLabel: '$name, ${l10n.journeys_dna_place_country}',
                  excludeChildSemantics: true,
                  borderRadius: BorderRadius.circular(UiRadius.input),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: UiSpace.lg,
                      vertical: UiSpace.md,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? createSelectedFill(ui) : ui.surface,
                      borderRadius: BorderRadius.circular(UiRadius.input),
                      border: Border.all(
                        color: selected ? ui.outline : ui.border,
                        width: selected ? 3 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        OurneyIcon(name: 'map-pin', size: 21),
                        const SizedBox(width: UiSpace.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: UiText.h2(
                                  color: ui.ink,
                                  size: 17,
                                ).copyWith(height: 1.3),
                              ),
                              Text(
                                l10n.journeys_dna_place_country,
                                style: UiText.muted(color: ui.inkMuted)
                                    .copyWith(height: 1.4),
                              ),
                            ],
                          ),
                        ),
                        if (selected) OurneyIcon(name: 'check', size: 19),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        if (place == l10n.journeys_dna_place_dalat)
          Padding(
            padding: const EdgeInsets.only(top: UiSpace.sm),
            child: Row(
              key: const ValueKey('dna-pine'),
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OurneyIcon(name: 'pine', size: 24),
                const SizedBox(width: UiSpace.sm),
                Flexible(
                  child: Text(
                    l10n.journeys_dna_place_pine,
                    style: UiText.h2(
                      color: ui.ink,
                      size: 15,
                    ).copyWith(height: 1.4),
                  ),
                ),
              ],
            ),
          ),
      ],
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
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final l10n = JourneysL10n.of(context);
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
              ScaleTransition(
                scale: Tween<double>(
                  begin: 0.9,
                  end: 1.1,
                ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
                child: Container(
                  width: 96,
                  height: 96,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: ui.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: ui.outline, width: 3),
                  ),
                  child: OurneyIcon(name: 'trophy', size: 44),
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
