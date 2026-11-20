import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../../ui/ui.dart';

/// V2 `.create-dots`: one pill per step; done = accent fill, current =
/// wider/taller with a 2dp outline, pending = empty hairline.
class CreateStepSegments extends StatelessWidget {
  const CreateStepSegments({
    required this.count,
    required this.current,
    required this.label,
    super.key,
  });

  final int count;

  /// Zero-based index of the current step.
  final int current;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final duration = UiMotion.of(context, const Duration(milliseconds: 200));
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: SizedBox(
        height: 14,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < count; i++)
              AnimatedContainer(
                key: ValueKey('create-step-$i'),
                duration: duration,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == current ? 22 : 8,
                height: i == current ? 10 : 8,
                decoration: BoxDecoration(
                  color: i <= current ? ui.brand : ui.fill,
                  border: Border.all(
                    color: i <= current ? ui.outline : ui.border,
                    width: i == current ? UiBorder.standard : UiBorder.hairline,
                  ),
                  borderRadius: BorderRadius.circular(UiRadius.capsule),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Accent mixed 42% into the surface (`color-mix(accent 42%, surface)`).
Color createSelectedFill(OurneyUi ui) =>
    Color.alphaBlend(ui.brand.withValues(alpha: 0.42), ui.surface);

/// `.duration-chips button`: 2dp outline, selected = 3dp outline and the
/// accent-42% fill, with a check glyph.
class CreateDurationChip extends StatelessWidget {
  const CreateDurationChip({
    required this.label,
    required this.selected,
    required this.onPressed,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return UiPressable(
      onPressed: onPressed,
      selected: selected,
      semanticLabel: label,
      excludeChildSemantics: true,
      borderRadius: BorderRadius.circular(UiRadius.input),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? createSelectedFill(ui) : ui.surface,
          borderRadius: BorderRadius.circular(UiRadius.input),
          border: Border.all(color: ui.outline, width: selected ? 3 : 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              OurneyIcon(name: 'check', size: 15),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(
                label,
                style: UiText.body(
                  size: 14,
                  weight: FontWeight.w700,
                  height: 1.35,
                  color: ui.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `.create-answer-card` / `.step-two-card`: a full-width answer with a
/// glyph, title, body and a "chosen" mark.
class CreateChoiceCard extends StatelessWidget {
  const CreateChoiceCard({
    required this.title,
    required this.glyph,
    required this.selected,
    required this.onPressed,
    this.body,
    this.chosenLabel,
    super.key,
  });

  final String title;
  final String? body;
  final Widget glyph;
  final bool selected;

  /// Null = disabled.
  final VoidCallback? onPressed;
  final String? chosenLabel;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final disabled = onPressed == null;
    return UiPressable(
      onPressed: onPressed,
      selected: selected,
      semanticLabel: [title, ?body].join(', '),
      excludeChildSemantics: true,
      borderRadius: BorderRadius.circular(UiRadius.menu),
      shadowColor: ui.hardShadowColor,
      shadowOffset: selected ? 4 : 0,
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.all(UiSpace.md),
        decoration: BoxDecoration(
          color: selected ? createSelectedFill(ui) : ui.surface,
          borderRadius: BorderRadius.circular(UiRadius.menu),
          border: Border.all(
            color: disabled ? ui.border : ui.outline,
            width: selected ? 3 : 2,
          ),
        ),
        child: Opacity(
          opacity: disabled ? 0.55 : 1,
          child: Row(
            children: [
              glyph,
              const SizedBox(width: UiSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: UiText.body(
                        size: 16,
                        weight: FontWeight.w700,
                        height: 1.35,
                        color: ui.ink,
                      ),
                    ),
                    if (body != null)
                      Text(
                        body!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: UiText.body(
                          size: 12,
                          height: 1.4,
                          color: ui.inkMuted,
                        ),
                      ),
                  ],
                ),
              ),
              if (selected) ...[
                const SizedBox(width: UiSpace.sm),
                OurneyIcon(name: 'check', size: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Inline month calendar (`.inline-calendar`): picks the start date and
/// highlights the whole journey range `[start, start + days - 1]`, so
/// reopening or paging months always shows the stored range.
class CreateCalendar extends StatefulWidget {
  const CreateCalendar({
    required this.today,
    required this.start,
    required this.days,
    required this.onPick,
    required this.prevLabel,
    required this.nextLabel,
    required this.locale,
    this.horizonDays = 365,
    super.key,
  });

  /// First selectable day (no start dates in the past).
  final LocalDate today;
  final LocalDate start;

  /// Journey length; null = open-ended (only the start day is marked).
  final int? days;
  final ValueChanged<LocalDate> onPick;
  final String prevLabel;
  final String nextLabel;
  final String locale;
  final int horizonDays;

  @override
  State<CreateCalendar> createState() => _CreateCalendarState();
}

class _CreateCalendarState extends State<CreateCalendar> {
  late DateTime _month = DateTime(widget.start.year, widget.start.month);

  LocalDate get _last => widget.today.addDays(widget.horizonDays);

  void _go(int delta) =>
      setState(() => _month = DateTime(_month.year, _month.month + delta));

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final first = DateTime(_month.year, _month.month);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final lead = (first.weekday + 6) % 7; // Monday first.
    final end = widget.days == null
        ? widget.start
        : widget.start.addDays(widget.days! - 1);
    final canPrev = first.isAfter(
      DateTime(widget.today.year, widget.today.month),
    );
    final canNext = DateTime(
      _month.year,
      _month.month + 1,
    ).isBefore(DateTime(_last.year, _last.month + 1));
    final weekdays = DateFormat.E(widget.locale);
    // 2024-01-01 was a Monday.
    final heads = [
      for (var i = 0; i < 7; i++) weekdays.format(DateTime(2024, 1, 1 + i)),
    ];
    final cells = lead + daysInMonth;
    final rows = (cells / 7).ceil();

    return Container(
      key: const ValueKey('create-calendar'),
      padding: const EdgeInsets.all(UiSpace.sm),
      decoration: BoxDecoration(
        color: ui.surface,
        borderRadius: BorderRadius.circular(UiRadius.menu),
        border: Border.all(color: ui.outline, width: UiBorder.hairline),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              UiIconButton(
                key: const ValueKey('create-calendar-prev'),
                glyph: OurneyIcon(
                  name: 'back',
                  size: 20,
                  color: canPrev ? null : ui.divider,
                ),
                iconSize: 20,
                color: ui.ink,
                label: widget.prevLabel,
                onPressed: canPrev ? () => _go(-1) : null,
              ),
              Expanded(
                child: Text(
                  DateFormat.yMMMM(widget.locale).format(first),
                  textAlign: TextAlign.center,
                  key: const ValueKey('create-calendar-month'),
                  style: UiText.body(
                    size: 15,
                    weight: FontWeight.w700,
                    height: 1.35,
                    color: ui.ink,
                  ),
                ),
              ),
              UiIconButton(
                key: const ValueKey('create-calendar-next'),
                glyph: Transform.rotate(
                  angle: 3.141592653589793,
                  child: OurneyIcon(
                    name: 'back',
                    size: 20,
                    color: canNext ? null : ui.divider,
                  ),
                ),
                iconSize: 20,
                color: ui.ink,
                label: widget.nextLabel,
                onPressed: canNext ? () => _go(1) : null,
              ),
            ],
          ),
          Row(
            children: [
              for (final h in heads)
                Expanded(
                  child: Text(
                    h,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: UiText.body(
                      size: 11,
                      height: 1.4,
                      color: ui.inkMuted,
                    ),
                  ),
                ),
            ],
          ),
          for (var r = 0; r < rows; r++)
            Row(
              children: [
                for (var c = 0; c < 7; c++)
                  Expanded(child: _cell(context, r * 7 + c - lead + 1, end)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _cell(BuildContext context, int day, LocalDate end) {
    final ui = context.ui;
    if (day < 1 || day > DateUtils.getDaysInMonth(_month.year, _month.month)) {
      return const SizedBox(height: 48);
    }
    final date = LocalDate(_month.year, _month.month, day);
    final enabled = !date.isBefore(widget.today) && !date.isAfter(_last);
    final isStart = date == widget.start;
    final inRange = !date.isBefore(widget.start) && !date.isAfter(end);
    return UiPressable(
      key: ValueKey('create-day-$date'),
      onPressed: enabled ? () => widget.onPick(date) : null,
      selected: isStart,
      semanticLabel: DateFormat.yMMMMd(widget.locale)
          .format(DateTime(date.year, date.month, date.day)),
      excludeChildSemantics: true,
      borderRadius: BorderRadius.circular(UiRadius.otp),
      minSize: const Size(0, 48),
      centerChild: true,
      child: Container(
        width: double.infinity,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isStart ? ui.brand : (inRange ? createSelectedFill(ui) : null),
          borderRadius: BorderRadius.circular(UiRadius.otp),
          border: isStart
              ? Border.all(color: ui.outline, width: UiBorder.standard)
              : null,
        ),
        child: Text(
          '$day',
          style: UiText.body(
            size: 14,
            weight: isStart || inRange ? FontWeight.w700 : FontWeight.w500,
            height: 1.3,
            color: !enabled
                ? ui.inkMuted.withValues(alpha: 0.5)
                : (isStart ? ui.onBrand : ui.ink),
          ),
        ),
      ),
    );
  }
}
