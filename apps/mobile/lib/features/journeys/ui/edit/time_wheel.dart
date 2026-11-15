import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../ui/ui.dart';

/// Hour / minute wheels for the reminder time (`HH:MM`, 24 h). Two snapping
/// [ListWheelScrollView]s with a highlighted centre band; every row is at
/// least 48dp tall and grows with the text size.
class UiTimeWheel extends StatefulWidget {
  const UiTimeWheel({
    required this.hour,
    required this.minute,
    required this.onChanged,
    required this.hourLabel,
    required this.minuteLabel,
    super.key,
  });

  final int hour;
  final int minute;
  final void Function(int hour, int minute) onChanged;
  final String hourLabel;
  final String minuteLabel;

  @override
  State<UiTimeWheel> createState() => _UiTimeWheelState();
}

class _UiTimeWheelState extends State<UiTimeWheel> {
  late final _h = FixedExtentScrollController(initialItem: widget.hour);
  late final _m = FixedExtentScrollController(initialItem: widget.minute);
  late int _hour = widget.hour;
  late int _minute = widget.minute;

  @override
  void dispose() {
    _h.dispose();
    _m.dispose();
    super.dispose();
  }

  Widget _wheel({
    required FixedExtentScrollController controller,
    required int count,
    required int value,
    required String label,
    required ValueChanged<int> onSelected,
    required Key wheelKey,
  }) {
    final ui = context.ui;
    final scale = MediaQuery.textScalerOf(context);
    return Expanded(
      child: Semantics(
        label: label,
        value: value.toString().padLeft(2, '0'),
        child: ListWheelScrollView.useDelegate(
          key: wheelKey,
          controller: controller,
          itemExtent: scale.scale(32).clamp(48, 64),
          perspective: 0.003,
          diameterRatio: 2.2,
          physics: const FixedExtentScrollPhysics(),
          onSelectedItemChanged: (i) {
            unawaited(HapticFeedback.selectionClick());
            onSelected(i);
            setState(() {});
            widget.onChanged(_hour, _minute);
          },
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: count,
            builder: (context, i) => Center(
              child: Text(
                i.toString().padLeft(2, '0'),
                style: UiText.h2(
                  color: i == value ? ui.ink : ui.inkMuted,
                  size: 24,
                ).copyWith(height: 1.3),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return Container(
      key: const ValueKey('reminder-wheel'),
      height: 160,
      decoration: BoxDecoration(
        color: ui.surface,
        borderRadius: BorderRadius.circular(UiRadius.menu),
        border: Border.all(color: ui.border),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          IgnorePointer(
            child: Container(
              height: 48,
              margin: const EdgeInsets.symmetric(horizontal: UiSpace.md),
              decoration: BoxDecoration(
                color: ui.fill,
                borderRadius: BorderRadius.circular(UiRadius.input),
              ),
            ),
          ),
          Row(
            children: [
              _wheel(
                controller: _h,
                count: 24,
                value: _hour,
                label: widget.hourLabel,
                wheelKey: const ValueKey('wheel-hour'),
                onSelected: (i) => _hour = i,
              ),
              Text(':', style: UiText.h2(color: ui.ink)),
              _wheel(
                controller: _m,
                count: 60,
                value: _minute,
                label: widget.minuteLabel,
                wheelKey: const ValueKey('wheel-minute'),
                onSelected: (i) => _minute = i,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
