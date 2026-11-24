import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../ui/ui.dart';
import '../l10n/generated/import_localizations.dart';

/// Picks a day with three wheels (day, month, year) in a kit sheet, from
/// [first] to [last]. Resolves to null when dismissed.
Future<LocalDate?> showImportDateSheet(
  BuildContext context, {
  required LocalDate initial,
  required LocalDate first,
  required LocalDate last,
}) {
  var start = initial;
  if (start.isBefore(first)) start = first;
  if (start.isAfter(last)) start = last;
  return showUiSheet<LocalDate>(
    context: context,
    builder: (_) => _DateSheet(initial: start, first: first, last: last),
  );
}

class _DateSheet extends StatefulWidget {
  const _DateSheet({
    required this.initial,
    required this.first,
    required this.last,
  });

  final LocalDate initial;
  final LocalDate first;
  final LocalDate last;

  @override
  State<_DateSheet> createState() => _DateSheetState();
}

class _DateSheetState extends State<_DateSheet> {
  static const double _extent = 48;

  late LocalDate _date = widget.initial;
  late final FixedExtentScrollController _year = FixedExtentScrollController(
    initialItem: widget.initial.year - widget.first.year,
  );
  late final FixedExtentScrollController _month = FixedExtentScrollController(
    initialItem: widget.initial.month - 1,
  );
  late final FixedExtentScrollController _day = FixedExtentScrollController(
    initialItem: widget.initial.day - 1,
  );

  @override
  void dispose() {
    _year.dispose();
    _month.dispose();
    _day.dispose();
    super.dispose();
  }

  int _daysIn(int y, int m) => DateTime(y, m + 1, 0).day;

  /// Applies a wheel change; keeps the date inside the range and the wheels
  /// in step with it (a short month pulls the day back). The other wheels are
  /// moved before the rebuild, so a shorter day wheel never shows a frame with
  /// its selection past the end.
  void _set(int y, int m, int d) {
    var next = LocalDate(y, m, math.min(d, _daysIn(y, m)));
    if (next.isBefore(widget.first)) next = widget.first;
    if (next.isAfter(widget.last)) next = widget.last;
    void sync(FixedExtentScrollController c, int item) {
      if (c.hasClients && c.selectedItem != item) c.jumpToItem(item);
    }

    sync(_year, next.year - widget.first.year);
    sync(_month, next.month - 1);
    sync(_day, next.day - 1);
    setState(() => _date = next);
  }

  Widget _wheel({
    required Key key,
    required String label,
    required FixedExtentScrollController controller,
    required int count,
    required int selected,
    required String Function(int index) text,
    required ValueChanged<int> onChanged,
  }) {
    final ui = context.ui;
    String at(int i) => i < 0 || i >= count ? '' : text(i);
    void step(int by) {
      final target = (selected + by).clamp(0, count - 1);
      if (target != selected) controller.jumpToItem(target);
    }

    return Expanded(
      child: Semantics(
        container: true,
        label: label,
        value: at(selected),
        increasedValue: at(selected + 1),
        decreasedValue: at(selected - 1),
        onIncrease: selected + 1 < count ? () => step(1) : null,
        onDecrease: selected > 0 ? () => step(-1) : null,
        child: ListWheelScrollView.useDelegate(
          key: key,
          controller: controller,
          itemExtent: _extent,
          diameterRatio: 2.2,
          perspective: 0.003,
          physics: const FixedExtentScrollPhysics(),
          onSelectedItemChanged: onChanged,
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: count,
            builder: (context, i) => Center(
              child: Text(
                text(i),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: UiText.body(
                  size: 17,
                  weight: FontWeight.w700,
                  height: 1.4,
                  color: ui.ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ImportL10n.of(context);
    final ui = context.ui;
    final locale = Localizations.localeOf(context).toString();
    final years = widget.last.year - widget.first.year + 1;
    final days = _daysIn(_date.year, _date.month);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.import_dateSheetTitle,
            style: UiText.h2(size: 22, color: ui.ink).copyWith(height: 1.3),
          ),
        ),
        const SizedBox(height: UiSpace.md),
        SizedBox(
          height: _extent * 5,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // The selected row.
              IgnorePointer(
                child: Container(
                  height: _extent,
                  decoration: BoxDecoration(
                    color: ui.fill,
                    borderRadius: BorderRadius.circular(UiRadius.input),
                  ),
                ),
              ),
              Row(
                children: [
                  _wheel(
                    key: const ValueKey('import-date-day'),
                    label: l10n.import_dateDay,
                    controller: _day,
                    count: days,
                    selected: _date.day - 1,
                    text: (i) => '${i + 1}',
                    onChanged: (i) => _set(_date.year, _date.month, i + 1),
                  ),
                  _wheel(
                    key: const ValueKey('import-date-month'),
                    label: l10n.import_dateMonth,
                    controller: _month,
                    count: 12,
                    selected: _date.month - 1,
                    text: (i) =>
                        DateFormat.MMM(locale).format(DateTime(2000, i + 1)),
                    onChanged: (i) => _set(_date.year, i + 1, _date.day),
                  ),
                  _wheel(
                    key: const ValueKey('import-date-year'),
                    label: l10n.import_dateYear,
                    controller: _year,
                    count: years,
                    selected: _date.year - widget.first.year,
                    text: (i) => '${widget.first.year + i}',
                    onChanged: (i) =>
                        _set(widget.first.year + i, _date.month, _date.day),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: UiSpace.lg),
        UiButton(
          key: const ValueKey('import-date-confirm'),
          label: l10n.import_dateConfirm,
          onPressed: () => Navigator.of(context).pop(_date),
        ),
        UiButton.ghost(
          key: const ValueKey('import-date-cancel'),
          label: l10n.import_dateCancel,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
